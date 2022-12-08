const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const common = @import("common.zig");

pub fn run(input: std.fs.File) !void {
    try common.printLn("Day 6: Tuning Trouble");

    var buffered = std.io.bufferedReader(input.reader());
    var reader = buffered.reader();

    // part 1
    const sopOffset = findFirstUniqueRangeEnd(4, reader).?;
    try common.printLnFmt("SOP marker index: {}", .{sopOffset});

    try input.seekTo(0);
    buffered = std.io.bufferedReader(input.reader());
    reader = buffered.reader();

    // part 2
    const messageOffset = findFirstUniqueRangeEnd(14, reader).?;
    try common.printLnFmt("message marker index: {}", .{messageOffset});
}

fn isUnique(comptime T: type, slice: []const T) bool {
    if (slice.len == 0) {
        return true;
    }

    var o: usize = 0;
    while(o < slice.len - 1) {
        var i: usize = o + 1;
        while (i < slice.len) {
            if (slice[o] == slice[i]) {
                return false;
            }
            i += 1;
        }
        o += 1;
    }

    return true;
}

test "Is Unique" {
    try expect(isUnique(u8, "ABCDEFG"));
    try expect(!isUnique(u8, "AA"));
    try expect(isUnique(u8, "A"));
    try expect(isUnique(u8, ""));
}

fn findFirstUniqueRangeEnd(comptime N: usize, reader: anytype) ?usize {

    var buf: [N]u8 = undefined;

    for (buf) |*i| {
        i.* = reader.readByte() catch return null;
    }

    var idx: usize = N;
    var window = buf[0..];
    var index: i32 = @intCast(i32,N);

    while (!isUnique(u8,  window)) {
        buf[idx % N] = reader.readByte() catch return null;
        if (buf[idx % N] == '\n') {
            return null;
        }

        idx += 1;
        index += 1;
    }

    return idx;
}

test "Find First Unique Range End" {
    var input = std.io.fixedBufferStream("mjqjpqmgbljsphdztnvjfqwrcgsmlb");
    try expectEqual(@as(usize, 7), findFirstUniqueRangeEnd(4, input.reader()).?);
    input = std.io.fixedBufferStream("bvwbjplbgvbhsrlpgdmjqwftvncz");
    try expectEqual(@as(usize, 5), findFirstUniqueRangeEnd(4, input.reader()).?);
    input = std.io.fixedBufferStream("nppdvjthqldpwncqszvftbrmjlhg");
    try expectEqual(@as(usize, 6), findFirstUniqueRangeEnd(4, input.reader()).?);
    input = std.io.fixedBufferStream("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg");
    try expectEqual(@as(usize, 10), findFirstUniqueRangeEnd(4, input.reader()).?);
    input = std.io.fixedBufferStream("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw");
    try expectEqual(@as(usize, 11), findFirstUniqueRangeEnd(4, input.reader()).?);


    input = std.io.fixedBufferStream("mjqjpqmgbljsphdztnvjfqwrcgsmlb");
    try expectEqual(@as(usize, 19), findFirstUniqueRangeEnd(14, input.reader()).?);
    input = std.io.fixedBufferStream("bvwbjplbgvbhsrlpgdmjqwftvncz");
    try expectEqual(@as(usize, 23), findFirstUniqueRangeEnd(14, input.reader()).?);
    input = std.io.fixedBufferStream("nppdvjthqldpwncqszvftbrmjlhg");
    try expectEqual(@as(usize, 23), findFirstUniqueRangeEnd(14, input.reader()).?);
    input = std.io.fixedBufferStream("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg");
    try expectEqual(@as(usize, 29), findFirstUniqueRangeEnd(14, input.reader()).?);
    input = std.io.fixedBufferStream("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw");
    try expectEqual(@as(usize, 26), findFirstUniqueRangeEnd(14, input.reader()).?);
}
