const std = @import("std");
const mecha = @import("mecha");
const zigfsm = @import("zigfsm");

const input = @embedFile("./input");

fn toIntString(_: std.mem.Allocator, str: []const u8) mecha.Error![]const u8 {
    if (std.mem.eql(u8, str, "one")) return "1";
    if (std.mem.eql(u8, str, "two")) return "2";
    if (std.mem.eql(u8, str, "three")) return "3";
    if (std.mem.eql(u8, str, "four")) return "4";
    if (std.mem.eql(u8, str, "five")) return "5";
    if (std.mem.eql(u8, str, "six")) return "6";
    if (std.mem.eql(u8, str, "seven")) return "7";
    if (std.mem.eql(u8, str, "eight")) return "8";
    if (std.mem.eql(u8, str, "nine")) return "9";
    return error.ParserFailed;
}

const numberWordParser = mecha.oneOf(.{
    mecha.string("one"),
    mecha.string("two"),
    mecha.string("three"),
    mecha.string("four"),
    mecha.string("five"),
    mecha.string("six"),
    mecha.string("seven"),
    mecha.string("eight"),
    mecha.string("nine"),
}).convert(toIntString);

const numberOrNumberWordParser = mecha.oneOf(.{
    mecha.ascii.range('1', '9').asStr(),
    numberWordParser,
});

const garbageParser = mecha.many(
    mecha.ascii.not(mecha.oneOf(.{
        numberOrNumberWordParser,
        mecha.ascii.char('\n').asStr(),
    })),
    .{ .collect = false },
).discard();

const validOrGarbageParser = mecha.combine(.{
    garbageParser,
    numberOrNumberWordParser,
    garbageParser,
});

const rowParser = mecha.many(
    validOrGarbageParser,
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

    const parsedCalibrationDocument = (try documentParser.parse(allocator, input)).value;
    defer allocator.free(parsedCalibrationDocument);

    var res: usize = 0;
    for (parsedCalibrationDocument) |parsedCalibrationRow| {
        defer allocator.free(parsedCalibrationRow);

        var calibrationValueString = try std.ArrayList(u8).initCapacity(allocator, 2);
        defer calibrationValueString.deinit();

        const firstDigit = parsedCalibrationRow[0];
        const lastDigit = parsedCalibrationRow[parsedCalibrationRow.len - 1];

        try calibrationValueString.appendSlice(firstDigit);
        try calibrationValueString.appendSlice(lastDigit);

        const calibrationValue = try std.fmt.parseUnsigned(usize, calibrationValueString.items, 10);
        res = res + calibrationValue;
    }

    std.debug.print("{any}\n", .{res});
}
