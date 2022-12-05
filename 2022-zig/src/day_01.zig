const std = @import("std");
const common = @import("common.zig");

// p1:
//  Find the elf carrying the most calories.
//  input contains emtpy-line-delimited list of
//  newline-delimited lists of calories per elf.
// p2:
//  Find the sum-total calories of the top 3 elves
//  carrying the most calories


pub fn run(input: std.fs.File) !void {
    try common.printLn("Day 1: Calorie Counting");
    
    const max = try getMaxCalories(input);
    try common.printLnFmt("max calories: {}", .{max});

    const max3 = try getTopThreeCalories(input);
    try common.printLnFmt("sum of top three calories: {}", .{max3});
}

fn getMaxCalories(input: std.fs.File) !i32 {
    // sum line counts until empty line
    // keep max of previous and current total
    // return final max

    try input.seekTo(0);
    var buffered = std.io.bufferedReader(input.reader());
    var reader = buffered.reader();
    var buf: [1024]u8 = undefined;
    var current: i32 = 0;
    var max: i32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // account for possible '\r\n' line endings
        var trimmed = if (line.len > 0 and line[line.len-1] == '\r') line[0..line.len-1] else line;

        const val = std.fmt.parseInt(i32, trimmed, 10) catch {
            // reached end of a set, compare current with max
            max = std.math.max(current, max);
            current = 0;
            continue;
        };
        current += val;
    }

    max = std.math.max(current, max);    
    
    return max;
}

fn getTopThreeCalories(input: std.fs.File) !i32 {
    // sum line counts until empty line
    // keep max of previous and current total
    // return final max

    try input.seekTo(0);
    var buffered = std.io.bufferedReader(input.reader());
    var reader = buffered.reader();
    var buf: [1024]u8 = undefined;
    var current: i32 = 0;
    var max = [3]i32{0,0,0};
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // account for possible '\r\n' line endings
        var trimmed = if (line.len > 0 and line[line.len-1] == '\r') line[0..line.len-1] else line;

        const val = std.fmt.parseInt(i32, trimmed, 10) catch {
            // reached end of a set, compare (lowest) top 3 with current
            max[0] = std.math.max(current, max[0]);
            std.sort.sort(i32, &max, {}, std.sort.asc(i32));
            current = 0;
            continue;
        };
        current += val;
    }
    max[0] = std.math.max(current, max[0]);
    
    // return max;
    var sum: i32 = 0;
    for (max) |val| { sum += val; }
    return sum;
}
