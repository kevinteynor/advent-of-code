const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub fn run(input: std.fs.File, allocator: Allocator) !void {
    try common.printLn("Day 9: Rope Bridge");
    
    // part 1
    var buffered = std.io.bufferedReader(input.reader());
    var reader = buffered.reader();
    var count = try simulateRope(reader, allocator);
    try common.printLnFmt("Unique tail positions count: {}", .{count});
}

const Coordinate = [2]isize;

fn absOffset(from: Coordinate, to: Coordinate) Coordinate {
    return .{
        std.math.absInt(from[0] - to[0]) catch 0,
        std.math.absInt(from[1] - to[1]) catch 0,
    };
}

test "Coordinate offset" {
    const a = Coordinate{ 1, 1 };
    var b = absOffset(a, .{ 2, 2 });
    try expectEqual(Coordinate{ 1, 1 }, b);
    b = absOffset(a, .{ 0, 0 });
    try expectEqual(Coordinate{ 1, 1 }, b);
    b = absOffset(a, .{ 10, -6 });
    try expectEqual(Coordinate{ 9, 7 }, b);
}

const RopeState = struct {
    const Self = @This();
    const History = std.AutoHashMap([2]isize, void);

    head: Coordinate,
    tail: Coordinate,
    history: History,

    fn init(allocator: Allocator) !Self {
        var self = Self{
            .head = Coordinate{ 0, 0 },
            .tail = Coordinate{ 0, 0 },
            .history = History.init(allocator),
        };
        try self.history.put(self.tail, {});
        return self;
    }

    fn deinit(self: *Self) void {
        self.history.deinit();
    }

    fn move(self: *Self, dx: i2, dy: i2) !void {
        const new_head = .{self.head[0] + dx, self.head[1] + dy};
        const offset = absOffset(self.tail, new_head);
        if (offset[0] > 1 or offset[1] > 1) {
            self.tail = self.head;
            try self.history.put(self.tail, {});
        }
        self.head = new_head;
    }

    fn historyCount(self: *const Self) usize {
        return self.history.count();
    }
};


test "Rope State" {
    var rope = try RopeState.init(std.testing.allocator);
    defer rope.deinit();

    try expectEqual(Coordinate{ 0, 0 }, rope.head);
    try expectEqual(Coordinate{ 0, 0 }, rope.tail);

    try rope.move(1, 0); // H: 1,0
    try rope.move(1, 0); // H: 2,0
    try rope.move(1, 0); // H: 3,0
    try expectEqual(Coordinate{ 2, 0 }, rope.tail);

    try rope.move(0, 1); // H: 3,1
    try expectEqual(Coordinate{ 2, 0 }, rope.tail);

    try rope.move(0, 1); // H: 3,2
    try expectEqual(Coordinate{ 3, 1 }, rope.tail);

    try rope.move(0, -1); // H: 3,1
    try expectEqual(Coordinate{ 3, 1 }, rope.tail);

    try rope.move(-1, 0); // H: 2,1
    try rope.move(-1, 0); // H: 1,1
    try expectEqual(Coordinate{ 2, 1 }, rope.tail);

    try expectEqual(@as(usize, 5), rope.historyCount());
}

fn simulateRope(reader: anytype, allocator: Allocator) !usize {
    var rope = try RopeState.init(allocator);
    defer rope.deinit();
    
    var buffer: [8]u8 = undefined;
    while (try common.readLine(reader, &buffer)) |line| {
        var count = try std.fmt.parseInt(usize, line[2..], 10);
        var dx: i2 = 0;
        var dy: i2 = 0;
        switch (line[0]) {
            'R' => dx += 1,
            'L' => dx -= 1,
            'U' => dy += 1,
            'D' => dy -= 1,
            else => return error.InvalidInput,
        }

        while (count > 0) : (count -= 1) {
            try rope.move(dx, dy);
        }
    }

    return rope.historyCount();
}

test "Rope Simulation" {
    var input = std.io.fixedBufferStream(
        \\R 4
        \\U 4
        \\L 3
        \\D 1
        \\R 4
        \\D 1
        \\L 5
        \\R 2
    );
    var reader = input.reader();
    const count = try simulateRope(reader, std.testing.allocator);
    try expectEqual(@as(usize, 13), count);
}
