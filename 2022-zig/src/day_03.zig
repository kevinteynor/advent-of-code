const std = @import("std");
const common = @import("common.zig");

// https://adventofcode.com/2022/day/3

pub fn run(input: std.fs.File) !void {    
    try common.printLn("Day 3: Rucksack Reorganization");

    const prioritySum = try getPrioritySum(input);
    try common.printLnFmt("priority sum: {}", .{prioritySum});

    const groupPrioritySum = try getGroupPrioritySum(input);
    try common.printLnFmt("group priority sum: {}", .{groupPrioritySum});
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
                    total += prio;
                    continue :outer;
                }
            }
        }
    }

    return total;
}

pub fn getGroupPrioritySum(input: std.fs.File) !i32 {

    try input.seekTo(0);
    var buffered = std.io.bufferedReader(input.reader());
    var reader = buffered.reader();
    var buf: [1024]u8 = undefined;
    var total: i32 = 0;
    const ascu8 = std.sort.asc(u8);
    while (try common.readNLines(3, reader, &buf)) |lines| {

        for (lines) |line| {
            std.sort.sort(u8, line, {}, ascu8);
        }

        var _i0: usize = 0;
        var _i1: usize = 0;
        var _i2: usize = 0;

        while (_i0 < lines[0].len and _i1 < lines[1].len and _i2 < lines[2].len) {
            const c0 = lines[0][_i0];
            const c1 = lines[1][_i1];
            const c2 = lines[2][_i2];
            if (c0 == c1 and c1 == c2) {
                total += try itemPriority(c0);
                break;     
            }
            
            if (c0 < c1 or c0 < c2) {
                _i0 += 1;
            } else if (c1 < c2) {
                _i1 += 1;
            } else {
                _i2 += 1;
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
