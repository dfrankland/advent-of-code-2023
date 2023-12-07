const std = @import("std");
const mecha = @import("mecha");
const Zigstr = @import("zigstr");

const input = @embedFile("./input");

pub const BagCubeColors = enum {
    red,
    blue,
    green,
};

const BagContents = std.EnumMap(BagCubeColors, usize);

const actualBagContents = BagContents.init(.{
    .red = 12,
    .blue = 14,
    .green = 13,
});

const cubeRevealParser = mecha.combine(.{
    mecha.int(usize, .{ .parse_sign = false }),
    mecha.ascii.char(' ').discard(),
    mecha.enumeration(BagCubeColors),
});

const subsetCubeRevealParser = mecha.many(
    cubeRevealParser,
    .{ .min = 1, .separator = mecha.string(", ").discard() },
);

const subsetsCubeRevealParser = mecha.many(
    subsetCubeRevealParser,
    .{ .min = 1, .separator = mecha.string("; ").discard() },
);

const gameIdParser = mecha.combine(.{
    mecha.string("Game ").discard(),
    mecha.int(usize, .{ .parse_sign = false }),
});

const rowParser = mecha.combine(.{
    gameIdParser,
    mecha.string(": ").discard(),
    subsetsCubeRevealParser,
});

const documentParser = mecha.many(
    rowParser,
    .{ .min = 1, .separator = mecha.ascii.char('\n').discard() },
);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const document = (try documentParser.parse(allocator, input)).value;
    defer allocator.free(document);

    var res: usize = 0;
    for (document) |row| {
        const gameId, const subsets = row;
        defer allocator.free(subsets);

        var validGame = true;
        for (subsets) |subset| {
            defer allocator.free(subset);

            if (!validGame) continue;

            var subsetBagContents = BagContents.init(.{
                .red = 0,
                .blue = 0,
                .green = 0,
            });

            for (subset) |cubeReveal| {
                const cubeCount, const color = cubeReveal;
                subsetBagContents.put(color, subsetBagContents.get(color).? + cubeCount);
            }

            var subsetBagContentsIterator = subsetBagContents.iterator();
            while (subsetBagContentsIterator.next()) |entry| {
                if (entry.value.* > actualBagContents.get(entry.key).?) {
                    validGame = false;
                    break;
                }
            }
        }

        if (validGame) {
            res = res + gameId;
        }
    }

    std.debug.print("{any}\n", .{res});
}
