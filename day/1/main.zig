const std = @import("std");
const mecha = @import("mecha");
const Zigstr = @import("zigstr");

const input = @embedFile("./input");

const ValidValue = struct {
    value: u8,
    char: []const u8,
    word: []const u8,
};

const validValues: [9]ValidValue = .{
    ValidValue{ .value = 1, .char = "1", .word = "one" },
    ValidValue{ .value = 2, .char = "2", .word = "two" },
    ValidValue{ .value = 3, .char = "3", .word = "three" },
    ValidValue{ .value = 4, .char = "4", .word = "four" },
    ValidValue{ .value = 5, .char = "5", .word = "five" },
    ValidValue{ .value = 6, .char = "6", .word = "six" },
    ValidValue{ .value = 7, .char = "7", .word = "seven" },
    ValidValue{ .value = 8, .char = "8", .word = "eight" },
    ValidValue{ .value = 9, .char = "9", .word = "nine" },
};

const CalibrationValuePart = struct {
    index: usize,
    value: ValidValue,

    fn min(self: @This(), other: @This()) @This() {
        return if (self.index < other.index) self else other;
    }

    fn max(self: @This(), other: @This()) @This() {
        return if (self.index > other.index) self else other;
    }
};

const rowParser = mecha.many(
    mecha.ascii.alphanumeric,
    .{ .min = 1 },
);

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
        defer allocator.free(row);

        var str = try Zigstr.fromConstBytes(allocator, row);
        defer str.deinit();

        var optionalFirst: ?CalibrationValuePart = null;
        var optionalLast: ?CalibrationValuePart = null;

        for (validValues) |validValue| {
            if (str.indexOf(validValue.char)) |charIndex| {
                const char = CalibrationValuePart{
                    .index = charIndex,
                    .value = validValue,
                };
                optionalFirst = if (optionalFirst) |first| first.min(char) else char;
            }

            if (str.indexOf(validValue.word)) |wordIndex| {
                const word = CalibrationValuePart{
                    .index = wordIndex,
                    .value = validValue,
                };
                optionalFirst = if (optionalFirst) |first| first.min(word) else word;
            }

            if (str.lastIndexOf(validValue.char)) |charIndex| {
                const char = CalibrationValuePart{
                    .index = charIndex,
                    .value = validValue,
                };
                optionalLast = if (optionalLast) |last| last.max(char) else char;
            }

            if (str.lastIndexOf(validValue.word)) |wordIndex| {
                const word = CalibrationValuePart{
                    .index = wordIndex,
                    .value = validValue,
                };
                optionalLast = if (optionalLast) |last| last.max(word) else word;
            }
        }

        var calibrationValueString = try std.ArrayList(u8).initCapacity(allocator, 2);
        defer calibrationValueString.deinit();

        try calibrationValueString.appendSlice(optionalFirst.?.value.char);
        try calibrationValueString.appendSlice(optionalLast.?.value.char);

        const calibrationValue = try std.fmt.parseUnsigned(usize, calibrationValueString.items, 10);

        res = res + calibrationValue;
    }

    std.debug.print("{any}\n", .{res});
}
