const std = @import("std");
const common = @import("common.zig");

// https://adventofcode.com/2022/day/3

pub fn run(input: std.fs.File) !void {    
    try common.printLn("Day 3: Rucksack Reorganization");

    const prioritySum = try getPrioritySum(input);
    try common.printLnFmt("priority sum: {}", .{prioritySum});
}

pub fn getPrioritySum(input: std.fs.File) !i32 {
    try input.seekTo(0);
    var buffered = std.io.bufferedReader(input.reader());
    var reader = buffered.reader();
    var buf: [1024]u8 = undefined;
    var total: i32 = 0;
    outer: while (try common.readLines(reader, &buf)) |line| {
        // split string in half
        const mid = line.len / 2;
        var a = line[0..mid];
        var b = line[mid..];

        // detect element present in both halves
        for (a) |ca| {
            for (b) |cb| {
                if (ca == cb) {
                    // found the duplicate
                    const prio = try itemPriority(ca);
                    try common.printLnFmt("duplicate: {c} ({})\n", .{ca, prio});
                    total += prio;
                    continue :outer;
                }
            }
        }
    }

    return total;
}

pub fn itemPriority(item: u8) !i32 {
    return switch(item) {
        'a'...'z' => item - 'a' + 1,
        'A'...'Z' => item - 'A' + 27,
        else => error.InvalidInput,
    };
}

test "Item Priority" {
    try std.testing.expect(try itemPriority('a') == 1);
    try std.testing.expect(try itemPriority('b') == 2);
    try std.testing.expect(try itemPriority('y') == 25);
    try std.testing.expect(try itemPriority('z') == 26);

    try std.testing.expect(try itemPriority('A') == 27);
    try std.testing.expect(try itemPriority('B') == 28);
    try std.testing.expect(try itemPriority('Y') == 51);
    try std.testing.expect(try itemPriority('Z') == 52);

    _ = itemPriority(0) catch |err| {
        try std.testing.expect(err == error.InvalidInput);
    };

    _ = itemPriority('%') catch |err| {
        try std.testing.expect(err == error.InvalidInput);
    };
}
