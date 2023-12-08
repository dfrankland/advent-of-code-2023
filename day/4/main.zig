const std = @import("std");
const mecha = @import("mecha");

const input = @embedFile("./input");

const emptySpaceParser = mecha.many(
    mecha.ascii.char(' '),
    .{ .min = 1, .collect = false },
).discard();

const numberListParser = mecha.many(
    mecha.int(usize, .{ .parse_sign = false }),
    .{
        .min = 1,
        .separator = emptySpaceParser,
    },
);

const cardNumbersParser = mecha.combine(.{
    numberListParser,
    mecha.string(" |").discard(),
    emptySpaceParser,
    numberListParser,
});

const cardIdParser = mecha.combine(.{
    mecha.string("Card").discard(),
    emptySpaceParser,
    mecha.int(usize, .{ .parse_sign = false }),
});

const rowParser = mecha.combine(.{
    cardIdParser.discard(),
    mecha.string(":").discard(),
    emptySpaceParser,
    cardNumbersParser,
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
        const winningNumbersArray, const numbersYouHaveArray = row;
        defer allocator.free(winningNumbersArray);
        defer allocator.free(numbersYouHaveArray);

        var winningNumbersHashMap = std.AutoHashMap(usize, bool).init(allocator);
        defer winningNumbersHashMap.deinit();

        for (winningNumbersArray) |winningNumber| {
            try winningNumbersHashMap.put(winningNumber, true);
        }

        var possibleExponent: ?usize = null;
        for (numbersYouHaveArray) |numberYouHave| {
            if (winningNumbersHashMap.contains(numberYouHave)) {
                possibleExponent = if (possibleExponent) |exponent|
                    exponent + 1
                else
                    0;
            }
        }

        const cardPoints: usize = if (possibleExponent) |exponent|
            std.math.pow(usize, 2, exponent)
        else
            0;

        res += cardPoints;
    }

    std.debug.print("{any}\n", .{res});
}
