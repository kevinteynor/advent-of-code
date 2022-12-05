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

pub fn readLines(reader: anytype, buf: []u8) !?[]u8 {
    var index: usize = 0;
    while (true) {
        if (index >= buf.len) return error.StreamTooLong;

        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => {
                if (index == 0) {
                    return null;
                } else {
                    return buf[0..index];
                }
            },
            else => |e| return e,
        };

        buf[index] = byte;
        index += 1;

        // not great, order of these matter so we can detect \r\n before just \n
        const delimiters = [_][]const u8{"\r\n", "\n"};
        for (delimiters) |d| {
            if (index >= d.len and std.mem.eql(u8, buf[index-d.len..index], d)) {
                return buf[0..index-d.len];
            }
        }
    }
}
