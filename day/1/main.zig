const std = @import("std");
const mecha = @import("mecha");
const zigfsm = @import("zigfsm");

const input = @embedFile("./input");

const calibrationValuesParser = mecha.many(mecha.many(mecha.combine(.{
    mecha.many(mecha.ascii.alphabetic, .{ .collect = false }).discard(),
    mecha.many(mecha.ascii.digit(10), .{ .collect = false, .min = 1, .max = 1 }),
    mecha.many(mecha.ascii.alphabetic, .{ .collect = false }).discard(),
}), .{ .min = 1 }), .{ .min = 1, .separator = mecha.ascii.char('\n').discard() });

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const parsedCalibrationDocument = (try calibrationValuesParser.parse(allocator, input)).value;
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
