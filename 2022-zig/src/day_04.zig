const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const common = @import("common.zig");

pub fn run(input: std.fs.File) !void {
    try common.printLn("Day 4: Camp Cleanup");
    var buffered = std.io.bufferedReader(input.reader());
    var reader = buffered.reader();

    // part 1
    const subsets = try getFullyContainedAssignments(reader);
    try common.printLnFmt("Fully contained assignments: {}", .{subsets});

    try input.seekTo(0);

    // part 2
    const overlaps = try getOverlappingAssignments(reader);
    try common.printLnFmt("Overlapping assignments: {}", .{overlaps});
}

fn getFullyContainedAssignments(reader: anytype) !u32 {
    var buf: [1024]u8 = undefined;
    var count: u32 = 0;
    while (try common.readLine(reader, &buf)) |line| {
        const assignments = try parseAssignments(line);
        if (assignmentIsSubset(assignments[0], assignments[1])) {
            count += 1;
        }
    }

    return count;
}

test "Fully Contained Assignments" {
    var input = std.io.fixedBufferStream(
        \\2-4,6-8
        \\2-3,4-5
        \\5-7,7-9
        \\2-8,3-7
        \\6-6,4-6
        \\2-6,4-8
        \\5-5,5-94
    );
    var reader = input.reader();

    const count = try getFullyContainedAssignments(reader);
    try expectEqual(@as(u32, 3), count);
}

fn getOverlappingAssignments(reader: anytype) !u32 {
    var buf: [1024]u8 = undefined;
    var count: u32 = 0;
    while (try common.readLine(reader, &buf)) |line| {
        const assignments = try parseAssignments(line);
        if (assignmentOverlaps(assignments[0], assignments[1])) {
            count += 1;
        }
    }

    return count;
}

test "Overlapping Assignments" {
    var input = std.io.fixedBufferStream(
        \\2-4,6-8
        \\2-3,4-5
        \\5-7,7-9
        \\2-8,3-7
        \\6-6,4-6
        \\2-6,4-8
    );
    var reader = input.reader();

    const count = try getOverlappingAssignments(reader);
    try expectEqual(@as(u32, 4), count);
}

const Assignment = struct {
    min: u32,
    max: u32,
};

fn parseAssignments(input: []const u8) ![2]Assignment {
    var assignments: [2]Assignment = undefined;

    // find 4 number slices in input
    var it = std.mem.split(u8, input, ",");

    var e1It = std.mem.split(u8, it.first(), "-");
    assignments[0].min = try std.fmt.parseInt(u32, e1It.first(), 10);
    assignments[0].max = try std.fmt.parseInt(u32, e1It.next().?, 10);

    var e2It = std.mem.split(u8, it.next().?, "-");
    assignments[1].min = try std.fmt.parseInt(u32, e2It.first(), 10);
    assignments[1].max = try std.fmt.parseInt(u32, e2It.next().?, 10);

    return assignments;
}

test "Parse Assignments" {
    var assignments = try parseAssignments("2-4,6-8");
    try expectEqual(@as(u32, 2), assignments[0].min);
    try expectEqual(@as(u32, 4), assignments[0].max);
    try expectEqual(@as(u32, 6), assignments[1].min);
    try expectEqual(@as(u32, 8), assignments[1].max);

    assignments = try parseAssignments("25-400,395-800000000");
    try expectEqual(@as(u32, 25), assignments[0].min);
    try expectEqual(@as(u32, 400), assignments[0].max);
    try expectEqual(@as(u32, 395), assignments[1].min);
    try expectEqual(@as(u32, 800000000), assignments[1].max);
}

fn assignmentIsSubset(a: Assignment, b: Assignment) bool {
    if (a.min <= b.min and a.max >= b.max) {
        // |...45678.|
        // |.....67..|
        return true;
    } else if (a.min >= b.min and a.max <= b.max) {
        // |.....67..|
        // |...45678.|
        return true;
    }

    return false;
}

test "Assignment is Subset" {
    var a = Assignment{ .min = 2, .max = 4, };
    var b = Assignment{ .min = 6, .max = 8, };
    try expect(!assignmentIsSubset(a, b));

    // a contains b
    a = Assignment{ .min = 2, .max = 8 };
    b = Assignment{ .min = 3, .max = 7 };
    try expect(assignmentIsSubset(a, b));

    // b contains a
    a = Assignment{ .min = 5, .max = 5 };
    b = Assignment{ .min = 5, .max = 94 };
    try expect(assignmentIsSubset(a, b));

    // a == b
    a = Assignment{ .min = 1, .max = 3 };
    b = Assignment{ .min = 1, .max = 3 };
    try expect(assignmentIsSubset(a, b));
}

fn assignmentOverlaps(a: Assignment, b: Assignment) bool {
    if (assignmentIsSubset(a, b)) {
        return true;
    } else if (a.min <= b.min and a.max >= b.min) {
        // |...456...|
        // |.....67..|
        return true;
    } else if (b.min <= a.min and b.max >= a.min) {
        // |.....67..|
        // |...456...|
        return true;
    }

    return false;
}

test "Assignments Overlap" {
    var a = Assignment{ .min = 2, .max = 4, };
    var b = Assignment{ .min = 6, .max = 8, };
    try expect(!assignmentOverlaps(a, b));

    // a contains b
    a = Assignment{ .min = 2, .max = 8 };
    b = Assignment{ .min = 3, .max = 7 };
    try expect(assignmentOverlaps(a, b));

    // a b overlap
    a = Assignment{ .min = 3, .max = 5 };
    b = Assignment{ .min = 4, .max = 6 };
    try expect(assignmentOverlaps(a, b));

    // a b intersect
    a = Assignment{ .min = 7, .max = 20 };
    b = Assignment{ .min = 20, .max = 60 };
    try expect(assignmentOverlaps(a, b));

    // a b intersect
    a = Assignment{ .min = 3, .max = 20 };
    b = Assignment{ .min = 2, .max = 30 };
    try expect(assignmentOverlaps(a, b));
}
