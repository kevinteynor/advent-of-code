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
    var count = try simulateRope(2, reader, allocator);
    try common.printLnFmt("Unique tail positions (2 knots) count: {}", .{count});

    // part 2
    try input.seekTo(0);
    buffered = std.io.bufferedReader(input.reader());
    reader = buffered.reader();
    var c2 = try simulateRope(10, reader, allocator);
    try common.printLnFmt("Unique tail positions (10 knots) count: {}", .{c2});

}

const Coordinate = [2]isize;

fn RopeState(comptime length: usize) type {
    return struct {
        const Self = @This();
        const History = std.AutoHashMap([2]isize, void);

        knots: [length]Coordinate,

        history: History,

        fn init(allocator: Allocator) !Self {
            var self = Self{
                .knots = [_]Coordinate{Coordinate{ 0, 0 }} ** length,
                .history = History.init(allocator),
            };
            try self.history.put(Coordinate{ 0, 0 }, {});
            return self;
        }

        fn deinit(self: *Self) void {
            self.history.deinit();
        }

        fn move(self: *Self, dx: i2, dy: i2) !void {

            var k: usize = 0;
            self.knots[k][0] += dx;
            self.knots[k][1] += dy;
            k += 1;

            // pull knots towards previous
            while (k < self.knots.len) : (k += 1) {
                var offset = Coordinate{ self.knots[k - 1][0] - self.knots[k][0], self.knots[k - 1][1] - self.knots[k][1] };
                if (try std.math.absInt(offset[0]) > 1 or try std.math.absInt(offset[1]) > 1) {
                    offset[0] = std.math.clamp(offset[0], -1, 1);
                    offset[1] = std.math.clamp(offset[1], -1, 1);
                    self.knots[k][0] += offset[0];
                    self.knots[k][1] += offset[1];
                }
            }

            // store history of tail
            try self.history.put(self.knots[self.knots.len - 1], {});
        }

        fn historyCount(self: *const Self) usize {
            return self.history.count();
        }
    };
}

test "Rope State" {
    var rope = try RopeState(2).init(std.testing.allocator);
    defer rope.deinit();

    try expectEqual(Coordinate{ 0, 0 }, rope.knots[0]);
    try expectEqual(Coordinate{ 0, 0 }, rope.knots[1]);

    try rope.move(1, 0); // H: 1,0
    try rope.move(1, 0); // H: 2,0
    try rope.move(1, 0); // H: 3,0
    try expectEqual(Coordinate{ 2, 0 }, rope.knots[1]);

    try rope.move(0, 1); // H: 3,1
    try expectEqual(Coordinate{ 2, 0 }, rope.knots[1]);

    try rope.move(0, 1); // H: 3,2
    try expectEqual(Coordinate{ 3, 1 }, rope.knots[1]);

    try rope.move(0, -1); // H: 3,1
    try expectEqual(Coordinate{ 3, 1 }, rope.knots[1]);

    try rope.move(-1, 0); // H: 2,1
    try rope.move(-1, 0); // H: 1,1
    try expectEqual(Coordinate{ 2, 1 }, rope.knots[1]);

    try expectEqual(@as(usize, 5), rope.historyCount());
}

fn simulateRope(comptime length: usize, reader: anytype, allocator: Allocator) !usize {
    var rope = try RopeState(length).init(allocator);
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
    try expectEqual(@as(usize, 13), try simulateRope(2, reader, std.testing.allocator));

    reader = input.reader();
    try expectEqual(@as(usize, 1), try simulateRope(10, reader, std.testing.allocator));
}
