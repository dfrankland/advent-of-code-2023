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
    cardIdParser,
    mecha.string(":").discard(),
    emptySpaceParser,
    cardNumbersParser,
});

const documentParser = mecha.many(
    rowParser,
    .{ .min = 1, .separator = mecha.ascii.char('\n').discard() },
);

fn getOrPutPlusN(cardCounts: *std.AutoHashMap(usize, usize), cardId: usize, n: usize) !void {
    const cardCountEntry = try cardCounts.getOrPut(cardId);
    if (!cardCountEntry.found_existing) {
        cardCountEntry.value_ptr.* = 0;
    }
    cardCountEntry.value_ptr.* += n;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const document = (try documentParser.parse(allocator, input)).value;
    defer allocator.free(document);

    var cardsWon = std.AutoHashMap(
        usize,
        usize,
    ).init(allocator);
    defer cardsWon.deinit();

    for (document) |row| {
        const cardId, const numbersLists = row;
        try getOrPutPlusN(&cardsWon, cardId, 1);

        const winningNumbersArray, const numbersYouHaveArray = numbersLists;
        defer allocator.free(winningNumbersArray);
        defer allocator.free(numbersYouHaveArray);

        var winningNumbersHashMap = std.AutoHashMap(usize, bool).init(allocator);
        defer winningNumbersHashMap.deinit();

        for (winningNumbersArray) |winningNumber| {
            try winningNumbersHashMap.put(winningNumber, true);
        }

        var cardIdWon = cardId;
        const multiplier = cardsWon.get(cardId).?;
        for (numbersYouHaveArray) |numberYouHave| {
            if (winningNumbersHashMap.contains(numberYouHave)) {
                cardIdWon += 1;
                try getOrPutPlusN(&cardsWon, cardIdWon, multiplier);
            }
        }
    }

    var res: usize = 0;
    var cardsWonValuesIterator = cardsWon.valueIterator();
    while (cardsWonValuesIterator.next()) |cards| {
        res += cards.*;
    }

    std.debug.print("{any}\n", .{res});
}
