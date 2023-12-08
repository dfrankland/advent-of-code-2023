const std = @import("std");
const mecha = @import("mecha");

const input = @embedFile("./input");

const partNumberParser = mecha.many(
    mecha.ascii.digit(10),
    .{ .min = 1, .collect = false },
);

const gearParser = mecha.ascii.char('*').asStr();

const newLineParser = mecha.ascii.char('\n').asStr();

const spaceParser = mecha.ascii.not(
    mecha.oneOf(.{
        partNumberParser,
        gearParser,
        newLineParser,
    }),
).asStr();

const ItemType = enum {
    gear,
    space,
    partNumber,
};

const PartNumber = struct { length: u16, value: u16, found: bool = false };

const Item = union(ItemType) {
    gear,
    space,
    partNumber: PartNumber,
};

fn toGear(_: std.mem.Allocator, _: []const u8) !Item {
    return Item.gear;
}

fn toSpace(_: std.mem.Allocator, _: []const u8) !Item {
    return Item.space;
}

fn toPartNumber(_: std.mem.Allocator, str: []const u8) mecha.Error!Item {
    return Item{
        .partNumber = PartNumber{
            .length = @intCast(str.len),
            .value = std.fmt.parseInt(u16, str, 10) catch return error.ParserFailed,
        },
    };
}

const rowParser = mecha.many(
    mecha.oneOf(.{
        gearParser.convert(toGear),
        spaceParser.convert(toSpace),
        partNumberParser.convert(toPartNumber),
    }),
    .{ .min = 1 },
);

const documentParser = mecha.many(
    rowParser,
    .{ .min = 1, .separator = newLineParser.discard() },
);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const document = (try documentParser.parse(allocator, input)).value;
    defer allocator.free(document);

    // NOTE: `AutoArrayHashMap` isn't really necessary, but it has an order
    // making debugging nicer than `AutoHashMap`.

    var gearLocations = std.AutoArrayHashMap(usize, std.AutoArrayHashMap(usize, bool)).init(allocator);
    defer gearLocations.clearAndFree();

    var partNumberLocations = std.AutoArrayHashMap(usize, std.AutoArrayHashMap(usize, *PartNumber)).init(allocator);
    defer partNumberLocations.clearAndFree();

    for (document, 0..) |row, y| {
        var x: usize = 0;
        for (row) |*item| {
            switch (item.*) {
                .gear => {
                    const ySet = try gearLocations.getOrPut(x);
                    if (!ySet.found_existing) {
                        const newYSet = std.AutoArrayHashMap(usize, bool).init(allocator);
                        ySet.value_ptr.* = newYSet;
                    }
                    try ySet.value_ptr.put(y, true);
                    x = x + 1;
                },
                .space => {
                    x = x + 1;
                },
                .partNumber => {
                    const xEndExclusive = x + item.partNumber.length;
                    for (x..xEndExclusive) |partNumberX| {
                        var yMap = try partNumberLocations.getOrPut(partNumberX);
                        if (!yMap.found_existing) {
                            const newYMap = std.AutoArrayHashMap(usize, *PartNumber).init(allocator);
                            yMap.value_ptr.* = newYMap;
                        }
                        try yMap.value_ptr.put(y, &item.partNumber);
                    }
                    x = xEndExclusive;
                },
            }
        }
    }

    var res: usize = 0;
    var gearLocationsIterator = gearLocations.iterator();
    while (gearLocationsIterator.next()) |xMapEntry| {
        const gearX = xMapEntry.key_ptr.*;
        const ySet = xMapEntry.value_ptr.*;
        defer xMapEntry.value_ptr.clearAndFree();

        var ySetIterator = ySet.iterator();
        while (ySetIterator.next()) |ySetEntry| {
            const gearY = ySetEntry.key_ptr.*;

            const xStartInclusive: usize = if (gearX == 0) 0 else gearX - 1;
            const xEndExclusive: usize = gearX + 2;
            const yStartInclusive: usize = if (gearY == 0) 0 else gearY - 1;
            const yEndExclusive: usize = gearY + 2;

            var gearRatioPartNumbers = try std.ArrayList(usize).initCapacity(allocator, 2);
            defer gearRatioPartNumbers.deinit();

            for (xStartInclusive..xEndExclusive) |x| {
                for (yStartInclusive..yEndExclusive) |y| {
                    if (y == gearY and x == gearX) {
                        continue;
                    }

                    if (partNumberLocations.getPtr(x)) |partNumberLocationsYMap| {
                        if (partNumberLocationsYMap.getPtr(y)) |partNumber| {
                            if (!partNumber.*.found) {
                                partNumber.*.found = true;
                                try gearRatioPartNumbers.append(partNumber.*.value);
                            }
                        }
                    }
                }
            }

            if (gearRatioPartNumbers.items.len == 2) {
                res += gearRatioPartNumbers.items[0] * gearRatioPartNumbers.items[1];
            }
        }
    }

    std.debug.print("{any}\n", .{res});

    // clean up

    for (document) |row| {
        defer allocator.free(row);
    }

    for (partNumberLocations.values()) |*yMap| {
        yMap.clearAndFree();
    }
}
