const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const common = @import("common.zig");

pub fn run(input: std.fs.File, allocator: Allocator) !void {
    try common.printLn("Day 10: Cathode-Ray Tube");

    var buffered = std.io.bufferedReader(input.reader());
    var reader = buffered.reader();

    var instructions = try parseInstructions(reader, allocator);
    defer instructions.deinit();

    // part 1
    const sig_sum = getSignalSum(instructions.items);
    try common.printLnFmt("Sum of signals: {}", .{sig_sum});
}

const InstructionCode = enum {
    noop,
    addx,
};

const instructionCodeMap = std.ComptimeStringMap(InstructionCode, .{
    .{ "noop", .noop },
    .{ "addx", .addx },
});

test "parse instruction codes" {
    try std.testing.expectEqual(InstructionCode.noop, instructionCodeMap.get("noop").?);
    try std.testing.expectEqual(InstructionCode.addx, instructionCodeMap.get("addx").?);
}

const Instruction = union(InstructionCode) {
    noop: void,
    addx: i32,
};

fn parseInstructions(reader: anytype, allocator: Allocator) !ArrayList(Instruction) {
    var instructions = ArrayList(Instruction).init(allocator);
    errdefer instructions.deinit();
    var buffer: [32]u8 = undefined;
    while (try common.readLine(reader, &buffer)) |line| {
        if (line.len < 4) return error.InvalidInput;
        var code = instructionCodeMap.get(line[0..4]) orelse return error.InvalidInput;
        if (code == InstructionCode.addx) {
            if (line.len < 5) return error.InvalidInput;
            const val = std.fmt.parseInt(i32, line[5..], 10) catch return error.InvalidInput;
            try instructions.append(Instruction{ .addx = val });
        } else {
            try instructions.append(Instruction.noop);
        }
    }

    return instructions;
}

test "parse instructions" {
    var input = std.io.fixedBufferStream(
        \\noop
        \\addx 3
        \\addx -5
    );
    var reader = input.reader();

    var instructions = try parseInstructions(reader, std.testing.allocator);
    defer instructions.deinit();

    try expectEqual(@as(usize, 3), instructions.items.len);
    try expectEqual(InstructionCode.noop, instructions.items[0]);
    try expectEqual(Instruction{ .addx = 3 }, instructions.items[1]);
    try expectEqual(Instruction{ .addx = -5 }, instructions.items[2]);
}

fn getSignalSum(instructions: []Instruction) isize {
    var cycle: usize = 0;
    var reg_x: isize = 1;
    var threshold: usize = 20;
    var sum: isize = 0;
    for (instructions) |inst| {
        var dc: usize = 0;
        var dx: isize = 0;
        switch (inst) {
            Instruction.noop => dc += 1,
            Instruction.addx => |val| {
                dc += 2;
                dx += val;
            },
        }

        defer cycle += dc;
        defer reg_x += dx;

        if (cycle + dc >= threshold) {
            // report current value once we hit the threshold
            sum += reg_x * @intCast(isize, threshold);
            threshold += 40;
        }
    }

    return sum;
}

test "get signals sum" {
    var input = std.io.fixedBufferStream(
        \\addx 15
        \\addx -11
        \\addx 6
        \\addx -3
        \\addx 5
        \\addx -1
        \\addx -8
        \\addx 13
        \\addx 4
        \\noop
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx -35
        \\addx 1
        \\addx 24
        \\addx -19
        \\addx 1
        \\addx 16
        \\addx -11
        \\noop
        \\noop
        \\addx 21
        \\addx -15
        \\noop
        \\noop
        \\addx -3
        \\addx 9
        \\addx 1
        \\addx -3
        \\addx 8
        \\addx 1
        \\addx 5
        \\noop
        \\noop
        \\noop
        \\noop
        \\noop
        \\addx -36
        \\noop
        \\addx 1
        \\addx 7
        \\noop
        \\noop
        \\noop
        \\addx 2
        \\addx 6
        \\noop
        \\noop
        \\noop
        \\noop
        \\noop
        \\addx 1
        \\noop
        \\noop
        \\addx 7
        \\addx 1
        \\noop
        \\addx -13
        \\addx 13
        \\addx 7
        \\noop
        \\addx 1
        \\addx -33
        \\noop
        \\noop
        \\noop
        \\addx 2
        \\noop
        \\noop
        \\noop
        \\addx 8
        \\noop
        \\addx -1
        \\addx 2
        \\addx 1
        \\noop
        \\addx 17
        \\addx -9
        \\addx 1
        \\addx 1
        \\addx -3
        \\addx 11
        \\noop
        \\noop
        \\addx 1
        \\noop
        \\addx 1
        \\noop
        \\noop
        \\addx -13
        \\addx -19
        \\addx 1
        \\addx 3
        \\addx 26
        \\addx -30
        \\addx 12
        \\addx -1
        \\addx 3
        \\addx 1
        \\noop
        \\noop
        \\noop
        \\addx -9
        \\addx 18
        \\addx 1
        \\addx 2
        \\noop
        \\noop
        \\addx 9
        \\noop
        \\noop
        \\noop
        \\addx -1
        \\addx 2
        \\addx -37
        \\addx 1
        \\addx 3
        \\noop
        \\addx 15
        \\addx -21
        \\addx 22
        \\addx -6
        \\addx 1
        \\noop
        \\addx 2
        \\addx 1
        \\noop
        \\addx -10
        \\noop
        \\noop
        \\addx 20
        \\addx 1
        \\addx 2
        \\addx 2
        \\addx -6
        \\addx -11
        \\noop
        \\noop
        \\noop
    );
    var reader = input.reader();
    var instructions = try parseInstructions(reader, std.testing.allocator);
    defer instructions.deinit();

    var s = getSignalSum(instructions.items);
    try expectEqual(@as(isize, 13140), s);
}
