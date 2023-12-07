const std = @import("std");
const mecha = @import("mecha");

const input = @embedFile("./input");

pub const BagCubeColors = enum {
    red,
    blue,
    green,
};

const BagContents = std.EnumMap(BagCubeColors, usize);

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
        _, const subsets = row;
        defer allocator.free(subsets);

        var maxBagContents = BagContents.init(.{
            .red = 0,
            .blue = 0,
            .green = 0,
        });

        for (subsets) |subset| {
            defer allocator.free(subset);

            for (subset) |cubeReveal| {
                const cubeCount, const color = cubeReveal;
                if (cubeCount > maxBagContents.get(color).?) {
                    maxBagContents.put(color, cubeCount);
                }
            }
        }

        var power: usize = 1;
        var subsetBagContentsIterator = maxBagContents.iterator();
        while (subsetBagContentsIterator.next()) |entry| {
            power = power * entry.value.*;
        }

        res = res + power;
    }

    std.debug.print("{any}\n", .{res});
}
