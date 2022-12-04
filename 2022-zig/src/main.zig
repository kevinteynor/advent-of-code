const std = @import("std");

const common = @import("common.zig");
const day_01 = @import("day_01.zig");
const day_02 = @import("day_02.zig");

pub fn main() !void {
    try common.printLn("Advent of Code 2022 - Zig");

    var day = getDay() catch 0;

    switch (day) {
        1 => try day_01.run(),
        2 => try day_02.run(),
        else => {},
    }
}

fn getDay() !i32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        _ = leaked;
    }

    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        return 0;
    }

    const day = try std.fmt.parseInt(i32, args[1], 10);
    return day;
}
