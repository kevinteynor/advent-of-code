const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub fn run(input: std.fs.File, allocator: Allocator) !void {
    try common.printLn("Day 5: Supply Stacks");
    var buffered = std.io.bufferedReader(input.reader());
    var reader = buffered.reader();

    // part 1
    var output: [16]u8 = undefined;
    var tops = try getTopOfStacksCM9000(reader, &output, allocator);
    try common.printLnFmt("Stack Tops (CM 9000): {s}", .{tops});

    try input.seekTo(0);

    // part 2
    tops = try getTopOfStacksCM9001(reader, &output, allocator);
    try common.printLnFmt("Stack Tops (CM 9001): {s}", .{tops});
}

fn getTopOfStacksCM9000(reader: anytype, buffer: []u8, allocator: Allocator) ![]u8 {
    var cargo = try parseInitialStacks(reader, allocator);
    defer cargo.deinit();

    var line_buffer: [32]u8 = undefined;
    while (try common.readLine(reader, &line_buffer)) |line| {
        var step = try parseStep(line);
        while (step.count > 0) {
            var i = cargo.pop(step.source);
            try cargo.push(step.target, i);
            step.count -= 1;
        }
    }

    for (cargo.stacks) |_, i| {
        buffer[i] = cargo.back(@intCast(u8,i)).?;
    }

    return buffer[0..cargo.stacks.len];
}

test "Get Top of Stacks (CM 9000)" {
    var input = std.io.fixedBufferStream(
        \\    [D]    
        \\[N] [C]    
        \\[Z] [M] [P]
        \\ 1   2   3 
        \\
        \\move 1 from 2 to 1
        \\move 3 from 1 to 3
        \\move 2 from 2 to 1
        \\move 1 from 1 to 2
    );
    var reader = input.reader();
    var output: [3]u8 = undefined;
    var result = try getTopOfStacksCM9000(reader, &output, std.testing.allocator);
    try std.testing.expectEqualStrings("CMZ", result);
}


fn getTopOfStacksCM9001(reader: anytype, buffer: []u8, allocator: Allocator) ![]u8 {
    var cargo = try parseInitialStacks(reader, allocator);
    defer cargo.deinit();

    var line_buffer: [32]u8 = undefined;
    while (try common.readLine(reader, &line_buffer)) |line| {
        var step = try parseStep(line);
        var count = step.count;
        while (count > 0) {
            var i = cargo.pop(step.source);
            try cargo.push(step.target, i);
            count -= 1;
        }

        const target_len = cargo.stacks[step.target].items.len;
        std.mem.reverse(u8, cargo.stacks[step.target].items[target_len-step.count..]);
    }

    for (cargo.stacks) |_, i| {
        buffer[i] = cargo.back(@intCast(u8,i)).?;
    }

    return buffer[0..cargo.stacks.len];
}

test "Get Top of Stacks (CM 9001)" {
    var input = std.io.fixedBufferStream(
        \\    [D]    
        \\[N] [C]    
        \\[Z] [M] [P]
        \\ 1   2   3 
        \\
        \\move 1 from 2 to 1
        \\move 3 from 1 to 3
        \\move 2 from 2 to 1
        \\move 1 from 1 to 2
    );
    var reader = input.reader();
    var output: [3]u8 = undefined;
    var result = try getTopOfStacksCM9001(reader, &output, std.testing.allocator);
    try std.testing.expectEqualStrings("MCD", result);
}


const Cargo = struct {
    const Self = @This();

    allocator: Allocator,
    stacks: []std.ArrayList(u8),

    fn init(allocator: Allocator, stack_count: usize) !Self {
        var self = Self{
            .allocator = allocator,
            .stacks = try allocator.alloc(std.ArrayList(u8), stack_count),
        };

        var i: usize = 0;
        while (i < stack_count) {
            self.stacks[i] = std.ArrayList(u8).init(self.allocator);
            i += 1;
        }

        return self;
    }
    fn deinit(self: Self) void {
        for (self.stacks) |stack| {
            stack.deinit();
        }
        self.allocator.free(self.stacks);
    }
    fn pop(self: Self, stack: u8) u8 {
        return self.stacks[stack].pop();
    }
    fn push(self: Self, stack: u8, value: u8) !void {
        try self.stacks[stack].append(value);
    }
    fn back(self: Self, stack: u8) ?u8 {
        const stack_len = self.stacks[stack].items.len;
        if (stack_len > 0) {
            return self.stacks[stack].items[stack_len - 1];
        } else {
            return null;
        }
    }
};

fn parseInitialStacks(reader: anytype, allocator: Allocator) !Cargo {
    // stack format:
    //  [A]
    //  [B] [C]
    //   1   2
    //
    //  - 3 wide columns
    //  - 1 wide separator (whitespace: space or newline)
    //  - unknown number of columns
    //  - column index of box = `(i - 1) % 4`
    //  - column index of ID = `i * 4 + 1`
    //      - 0 => 1
    //      - 1 => 5
    //      - 2 => 9
    //      - 3 => 13
    //      - 4 => 17

    // read _everything_ into a buffer, until we get an empty line.
    // don't interpret anything until we've buffered entire state.
    var buffer: [1024]u8 = undefined;
    var lines = try common.readLinesUntilBlank(reader, &buffer, allocator);
    defer lines.deinit();

    // parse the lines
    const column_ids = lines.pop();
    const column_count = (column_ids.len + 1) / 4;
    // brittle, but just look at the chars at indices in the line
    var column_indices = try allocator.alloc(u8, column_count);
    defer allocator.free(column_indices);
    for (column_indices) |*ci, i| {
        ci.* = @intCast(u8, i) * 4 + 1;
    }

    var cargo = try Cargo.init(allocator, column_count);
    errdefer cargo.deinit();

    // fill stacks
    while (lines.popOrNull()) |line| {
        for (column_indices) |ci, i| {
            if (line[ci] != ' ') {
                // try cargo.stacks[i].append(line[ci]);
                try cargo.push(@intCast(u8, i), line[ci]);
            }
        }
    }

    return cargo;
}

test "Parse Initial Stacks" {
    var input = std.io.fixedBufferStream(
        \\    [D]    
        \\[N] [C]    
        \\[Z] [M] [P]
        \\ 1   2   3 
        \\
        \\ ABCD
    );
    var reader = input.reader();

    var cargo = try parseInitialStacks(reader, std.testing.allocator);
    defer cargo.deinit();

    try expectEqual(@as(usize, 2), cargo.stacks[0].items.len);
    try expectEqual(@as(usize, 3), cargo.stacks[1].items.len);
    try expectEqual(@as(usize, 1), cargo.stacks[2].items.len);

    try expectEqual(@as(u8, 'N'), cargo.pop(0));
    try expectEqual(@as(u8, 'Z'), cargo.pop(0));
    try expect(cargo.stacks[0].popOrNull() == null);

    try expectEqual(@as(u8, 'D'), cargo.pop(1));
    try expectEqual(@as(u8, 'C'), cargo.pop(1));
    try expectEqual(@as(u8, 'M'), cargo.pop(1));
    try expect(cargo.stacks[1].popOrNull() == null);

    try expectEqual(@as(u8, 'P'), cargo.pop(2));
    try expect(cargo.stacks[2].popOrNull() == null);
}

const Move = struct {
    count: u8,
    source: u8,
    target: u8,
};

fn parseStep(line: []const u8) !Move {
    //format: `move ## from # to #`
    var it = std.mem.split(u8, line, " ");

    var move: Move = undefined;

    _ = it.first();
    move.count = try std.fmt.parseInt(u8, it.next().?, 10);
    _ = it.next();
    move.source = try std.fmt.parseInt(u8, it.next().?, 10) - 1;
    _ = it.next();
    move.target = try std.fmt.parseInt(u8, it.next().?, 10) - 1;

    return move;
}

test "Parse Steps" {
    var input = std.io.fixedBufferStream(
        \\move 1 from 2 to 1
        \\move 3 from 1 to 3
        \\move 2 from 2 to 1
        \\move 1 from 1 to 2
    );
    var reader = input.reader();
    var buf: [32]u8 = undefined;
    var line = try common.readLine(reader, &buf);
    var move = try parseStep(line.?);
    try expectEqual(@as(u8, 1), move.count);
    try expectEqual(@as(u8, 1), move.source);
    try expectEqual(@as(u8, 0), move.target);

    line = try common.readLine(reader, &buf);
    move = try parseStep(line.?);
    try expectEqual(@as(u8, 3), move.count);
    try expectEqual(@as(u8, 0), move.source);
    try expectEqual(@as(u8, 2), move.target);

    line = try common.readLine(reader, &buf);
    move = try parseStep(line.?);
    try expectEqual(@as(u8, 2), move.count);
    try expectEqual(@as(u8, 1), move.source);
    try expectEqual(@as(u8, 0), move.target);

    line = try common.readLine(reader, &buf);
    move = try parseStep(line.?);
    try expectEqual(@as(u8, 1), move.count);
    try expectEqual(@as(u8, 0), move.source);
    try expectEqual(@as(u8, 1), move.target);
}
