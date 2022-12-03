const std = @import("std");

// todo: support non-comptime printing functions
// https://stackoverflow.com/questions/66527365/how-to-concat-two-string-literals-at-compile-time-in-zig

pub fn printFmt(comptime fmt: []const u8, args: anytype) !void {
    // https://zig.news/kristoff/where-is-print-in-zig-57e9
    // https://github.com/ziglang/zig/blob/master/lib/std/debug.zig#L89

    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();
    // try stdout.print(fmt, args);
    // try stdout.flush();

    // no buffering, no locking, no error handling for now
    const stdout = std.io.getStdOut().writer();
    try stdout.print(fmt, args);
}

pub fn print(comptime msg: []const u8) !void {
    try printFmt(msg, .{});
}

pub fn printLn(comptime msg: []const u8) !void {
    try printFmt(msg ++ "\n", .{});
}

pub fn printLnFmt(comptime fmt: []const u8, args: anytype) !void {
    try printFmt(fmt ++ "\n", args);
}
