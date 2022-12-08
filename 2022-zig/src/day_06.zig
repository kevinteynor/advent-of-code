const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const common = @import("common.zig");

pub fn run(input: std.fs.File) !void {
    try common.printLn("Day 6: Tuning Trouble");

    var buffered = std.io.bufferedReader(input.reader());
    var reader = buffered.reader();

    const sopOffset = findSOPMarker(reader).?;
    try common.printLnFmt("SOP marker index: {}", .{sopOffset});
}

fn findSOPMarker(reader: anytype) ?usize {

    var buf: [4]u8 = undefined;

    buf[0] = reader.readByte() catch return null;
    buf[1] = reader.readByte() catch return null;
    buf[2] = reader.readByte() catch return null;
    buf[3] = reader.readByte() catch return null;
    var idx: usize = 4;
    var window = buf[0..];

    while (!isUnique(u8,  window)) {
        buf[idx % 4] = reader.readByte() catch return null;
        if (buf[idx % 4] == '\n') {
            return null;
        }

        idx += 1;
    }

    return idx;
}

test "Find SOP Marker" {
    var input = std.io.fixedBufferStream("mjqjpqmgbljsphdztnvjfqwrcgsmlb");
    try expectEqual(@as(usize, 7), findSOPMarker(input.reader()).?);
    input = std.io.fixedBufferStream("bvwbjplbgvbhsrlpgdmjqwftvncz");
    try expectEqual(@as(usize, 5), findSOPMarker(input.reader()).?);
    input = std.io.fixedBufferStream("nppdvjthqldpwncqszvftbrmjlhg");
    try expectEqual(@as(usize, 6), findSOPMarker(input.reader()).?);
    input = std.io.fixedBufferStream("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg");
    try expectEqual(@as(usize, 10), findSOPMarker(input.reader()).?);
    input = std.io.fixedBufferStream("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw");
    try expectEqual(@as(usize, 11), findSOPMarker(input.reader()).?);
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
