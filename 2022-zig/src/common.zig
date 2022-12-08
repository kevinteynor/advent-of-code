const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;
const builtin = @import("builtin");

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

pub fn readLine(reader: anytype, buffer: []u8) !?[]u8 {
    var line = try reader.readUntilDelimiterOrEof(buffer, '\n') orelse return null;
    if (builtin.os.tag == .windows and line.len > 0 and line[line.len - 1] == '\r') {
        line = line[0..line.len - 1];
    }
    return line;
}

pub fn readNLines(comptime N: usize, reader: anytype, buffer: []u8) !?[N][]u8 {
    var lines: [N][]u8 = undefined;
    var offset: usize = 0;
    var count: usize = 0;
    while (count < N) {
        const line = try readLine(reader, buffer[offset..]) orelse return null;
        lines[count] = line;
        offset += line.len;
        count += 1;
    }
    return lines;
}

test "read line" {
    var src = std.io.fixedBufferStream("one\ntwo\nthree");
    const reader = src.reader();
    var buffer: [16]u8 = undefined;

    var read = try readLine(reader, &buffer) orelse unreachable;
    try expectEqualStrings("one", read);
    read = try readLine(reader, &buffer) orelse unreachable;
    try expectEqualStrings("two", read);
    read = try readLine(reader, &buffer) orelse unreachable;
    try expectEqualStrings("three", read);
}

test "read N lines" {
    var src = std.io.fixedBufferStream(
        \\one
        \\two
        \\three
        \\four
        \\five
    );
    const reader = src.reader();
    var buffer: [16]u8 = undefined;

    const first = try readNLines(2, reader, &buffer) orelse unreachable;
    try expectEqualStrings("one", first[0]);
    try expectEqualStrings("two", first[1]);

    const second = try readNLines(2, reader, &buffer) orelse unreachable;
    try expectEqualStrings("three", second[0]);
    try expectEqualStrings("four", second[1]);
    
    const third = try readNLines(2, reader, &buffer);
    try expect(third == null);
}

pub fn readLinesUntilBlank(reader: anytype, buffer: []u8, allocator: std.mem.Allocator) !std.ArrayList([]u8) {
    var lines = std.ArrayList([]u8).init(allocator);
    var offset: usize = 0;
    // var count: usize = 0;
    while (true) {
        const line = try readLine(reader, buffer[offset..]) orelse break;

        // check for empty line
        if (line.len == 0) break;
        if (line.len == 1 and line[0] == '\n') break;
        if (line.len == 2 and line[0] == '\r' and line[1] == '\n') break;

        try lines.append(line);
        offset += line.len;
        // count += 1;
    }
    return lines;
}

test "read lines until blank" {
    var src = std.io.fixedBufferStream(
        \\one
        \\two
        \\three
        \\
        \\four
        \\five
    );
    const reader = src.reader();
    var buffer: [128]u8 = undefined;

    const first = try readLinesUntilBlank(reader, &buffer, std.testing.allocator);
    defer first.deinit();
    try expectEqualStrings("one", first.items[0]);
    try expectEqualStrings("two", first.items[1]);
    try expectEqualStrings("three", first.items[2]);

    const second = try readLinesUntilBlank(reader, &buffer, std.testing.allocator);
    defer second.deinit();
    try expectEqualStrings("four", second.items[0]);
    try expectEqualStrings("five", second.items[1]);
    
    const third = try readLinesUntilBlank(reader, &buffer, std.testing.allocator);
    defer third.deinit();
    try expect(third.items.len == 0);
}
