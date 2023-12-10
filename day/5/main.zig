const std = @import("std");
const mecha = @import("mecha");

const input = @embedFile("./input");

const intParser = mecha.int(usize, .{ .parse_sign = false });
const spaceParser = mecha.ascii.char(' ').discard();
const newLineParser = mecha.ascii.char('\n').discard();
const doubleNewLineParser = mecha.combine(.{ newLineParser, newLineParser });

const seedsListParser = mecha.combine(.{
    mecha.string("seeds: ").discard(),
    mecha.many(
        intParser,
        .{ .min = 1, .separator = spaceParser },
    ),
});

const anyAlphabeticStringParser = mecha.many(
    mecha.ascii.alphabetic,
    .{ .min = 1, .collect = false },
);

const mapListTitleParser = mecha.combine(.{
    anyAlphabeticStringParser,
    mecha.string("-to-").discard(),
    anyAlphabeticStringParser,
    mecha.string(" map:").discard(),
    newLineParser,
});

const mapListParser = mecha.combine(.{
    mapListTitleParser.discard(),
    mecha.many(
        mecha.combine(.{
            intParser,
            spaceParser,
            intParser,
            spaceParser,
            intParser,
        }),
        .{ .min = 1, .separator = newLineParser },
    ),
});

const mapListsParser = mecha.many(
    mapListParser,
    .{ .min = 1, .separator = doubleNewLineParser },
);

const documentParser = mecha.combine(.{
    seedsListParser,
    doubleNewLineParser,
    mapListsParser,
});

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const seeds, const mapLists = (try documentParser.parse(allocator, input)).value;
    defer allocator.free(seeds);
    defer allocator.free(mapLists);

    var seedWithLowestMappedValue: std.meta.Tuple(&[_]type{ usize, usize }) =
        .{ @as(usize, 0), std.math.maxInt(usize) };
    for (seeds, 0..) |seed, seedIndex| {
        const isLastSeed = seedIndex == seeds.len - 1;
        var lastMappedValue = seed;
        for (mapLists) |mapList| {
            defer if (isLastSeed) allocator.free(mapList);
            for (mapList) |mapping| {
                const destinationRangeStart, const sourceRangeStart, const rangeLength = mapping;
                const rangeLengthZeroIndex = rangeLength - 1;
                const sourceRangeEnd = sourceRangeStart + rangeLengthZeroIndex;

                if (lastMappedValue >= sourceRangeStart and lastMappedValue <= sourceRangeEnd) {
                    lastMappedValue = if (sourceRangeStart > destinationRangeStart)
                        lastMappedValue - (sourceRangeStart - destinationRangeStart)
                    else
                        lastMappedValue + (destinationRangeStart - sourceRangeStart);
                    break;
                }
            }
        }
        if (lastMappedValue < seedWithLowestMappedValue[1]) {
            seedWithLowestMappedValue = .{ seed, lastMappedValue };
        }
    }

    std.debug.print("{any}\n", .{seedWithLowestMappedValue[1]});
}
