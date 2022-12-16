const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const common = @import("common.zig");

pub fn run(input: anytype, allocator: Allocator) !void {
    try common.printLn("Day 12: Hill Climbing Algorithm");

    {
        var buffered = std.io.bufferedReader(input.reader());
        var reader = buffered.reader();
        var grid = try parseGrid(reader, allocator);
        defer grid.deinit();
        var start = grid.findIndex('S').?;
        var end = grid.findIndex('E').?;
        grid.atUnchecked(start).* = 'a';
        grid.atUnchecked(end).* = 'z';
        var bfs = try BFS().init(&grid, start, end, allocator);
        defer bfs.deinit();
        var dist = try bfs.findPathLength();
        try common.printLnFmt("Minimum distance from S -> E: {}", .{dist});
    }
}

const Coord = struct { x: isize, y: isize };

fn Grid(comptime Cell: type) type {
    return struct {
        const Self = @This();
        pub const CellSlice = []Cell;

        raw_cells: CellSlice, // 1D access to cells within grid
        cells: []CellSlice, // 2D access to cells within grid
        width: usize,
        height: usize,
        allocator: Allocator,

        pub const Error = error{ InvalidSize, InvalidIndex };

        pub fn init(height: usize, width: usize, allocator: Allocator) (Error || Allocator.Error)!Self {
            if (width == 0 or height == 0) {
                return Error.InvalidSize;
            }

            var self = Self{
                .width = width,
                .height = height,
                .allocator = allocator,
                .raw_cells = &[_]Cell{},
                .cells = &[_][]Cell{},
            };

            self.raw_cells = try self.allocator.alignedAlloc(Cell, null, self.width * self.height);
            self.cells = try self.allocator.alignedAlloc([]Cell, null, self.height);
            for (self.cells) |*slice, row| {
                slice.* = self.raw_cells[row * self.width .. (row + 1) * self.width];
            }

            return self;
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.cells);
            self.cells = &[_][]Cell{};
            self.allocator.free(self.raw_cells);
            self.raw_cells = &[_]Cell{};
            self.width = 0;
            self.height = 0;
        }

        pub fn fill(self: *Self, value: Cell) void {
            std.mem.set(Cell, self.raw_cells, value);
        }

        pub fn at(self: *Self, pos: Coord) Error!*Cell {
            if (pos.x >= self.width or pos.y >= self.height) {
                return Error.InvalidIndex;
            }
            return &self.raw_cells[@intCast(usize, pos.y) * self.width + @intCast(usize, pos.x)];
        }

        pub fn atUnchecked(self: *Self, pos: Coord) *Cell {
            std.debug.assert(pos.x >= 0 and pos.y >= 0 and pos.x < self.width and pos.y < self.height);
            return &self.raw_cells[@intCast(usize, pos.y) * self.width + @intCast(usize, pos.x)];
        }

        pub fn findIndex(self: Self, item: Cell) ?Coord {
            for (self.cells) |row, row_index| {
                for (row) |cell, col_index| {
                    if (cell == item) {
                        return .{ .x = @intCast(isize, col_index), .y = @intCast(isize, row_index) };
                    }
                }
            }
            return null;
        }
    };
}

test "Grid" {
    var grid = try Grid(u8).init(4, 2, std.testing.allocator);
    defer grid.deinit();

    (try grid.at(.{ .y = 0, .x = 0 })).* = 'A';
    (try grid.at(.{ .y = 0, .x = 1 })).* = 'B';
    try expectError(error.InvalidIndex, grid.at(.{ .y = 0, .x = 2 }));

    (try grid.at(.{ .y = 2, .x = 0 })).* = 'Y';
    (try grid.at(.{ .y = 3, .x = 0 })).* = 'Z';
    try expectError(error.InvalidIndex, grid.at(.{ .y = 4, .x = 0 }));

    try expectEqual(@as(u8, 'A'), grid.cells[0][0]);
    try expectEqual(@as(u8, 'B'), grid.cells[0][1]);
    try expectEqual(@as(u8, 'Y'), grid.cells[2][0]);
    try expectEqual(@as(u8, 'Z'), grid.cells[3][0]);
    if (grid.at(.{ .y = 0, .x = 0 })) |c| try expectEqual(@as(u8, 'A'), c.*) else |_| unreachable;
    if (grid.at(.{ .y = 0, .x = 1 })) |c| try expectEqual(@as(u8, 'B'), c.*) else |_| unreachable;
    if (grid.at(.{ .y = 2, .x = 0 })) |c| try expectEqual(@as(u8, 'Y'), c.*) else |_| unreachable;
    if (grid.at(.{ .y = 3, .x = 0 })) |c| try expectEqual(@as(u8, 'Z'), c.*) else |_| unreachable;

    grid.cells[1][1] = 'M';
    grid.cells[2][1] = 'N';
    try expectEqual(@as(u8, 'M'), grid.cells[1][1]);
    try expectEqual(@as(u8, 'N'), grid.cells[2][1]);

    var coord = grid.findIndex('N').?;
    try expectEqual(@as(isize, 1), coord.x);
    try expectEqual(@as(isize, 2), coord.y);

    grid.fill('#');
    for (grid.raw_cells) |cell| {
        try expectEqual(@as(u8, '#'), cell);
    }
}

fn parseGrid(reader: anytype, allocator: Allocator) !Grid(u8) {
    var buffer: [4096]u8 = undefined;
    var lines = try common.readLinesUntilBlank(reader, &buffer, allocator);
    defer lines.deinit();

    var grid = try Grid(u8).init(lines.items.len, lines.items[0].len, allocator);

    for (lines.items) |line, i| {
        std.mem.copy(u8, grid.cells[i], line);
    }

    return grid;
}

test "Parse Grid" {
    var input = std.io.fixedBufferStream(
        \\Sabqponm
        \\abcryxxl
        \\accszExk
        \\acctuvwj
        \\abdefghi
    );
    var reader = input.reader();
    const allocator = std.testing.allocator;

    var grid = try parseGrid(reader, allocator);
    defer grid.deinit();

    try expectEqual(@as(u8, 'E'), grid.cells[2][5]);
    try expectEqual(@as(u8, 'S'), grid.cells[0][0]);
    try expectEqual(@as(usize, 8), grid.width);
    try expectEqual(@as(usize, 5), grid.height);
}

// breadth-first within `grid` to find shortest path from `start` to `end`
fn BFS() type {
    // metadata for each visited cell
    const VisitedInfo = struct {
        prev: ?Coord,
        dist: usize,
        val: u8,
    };

    return struct {
        const Self = @This();
        grid: *Grid(u8),
        start: Coord,
        end: Coord,
        // grid of visited cells. any cell that hasn't been visited yet is null
        visited: Grid(?VisitedInfo),
        // queue of coords for pending cells to process
        queue: std.fifo.LinearFifo(Coord, .Dynamic),

        pub fn init(grid: *Grid(u8), start: Coord, end: Coord, allocator: Allocator) !Self {
            return Self{
                .grid = grid,
                .start = start,
                .end = end,
                .visited = try Grid(?VisitedInfo).init(grid.height, grid.width, allocator),
                .queue = std.fifo.LinearFifo(Coord, .Dynamic).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.queue.deinit();
            self.visited.deinit();
        }

        pub fn findPathLength(self: *Self) !usize {
            self.visited.fill(null);

            // enqueue start cell
            self.visited.atUnchecked(self.start).* = .{
                .prev = null,
                .dist = 0,
                .val = self.grid.atUnchecked(self.start).*,
            };
            try self.queue.writeItem(self.start);

            const neighbor_offset = [_]Coord{ Coord{ .x = 1, .y = 0 }, Coord{ .x = 0, .y = -1 }, Coord{ .x = -1, .y = 0 }, Coord{ .x = 0, .y = 1 } };

            // try common.printLn("\nperforming BFS");
            // try self.printState();

            // check each pending cell
            while (self.queue.readItem()) |pos| {
                var current = self.visited.atUnchecked(pos).*.?;

                // try common.printLnFmt("processing: {any}:{any}", .{ pos, current });

                // stop looping after finding the end
                if (std.meta.eql(pos, self.end)) {
                    // try common.printLnFmt("reached end {any}", .{self.end});
                    break;
                }

                // process neighbors
                neighbors: for (neighbor_offset) |o| {
                    const next: Coord = .{ .x = pos.x + o.x, .y = pos.y + o.y };
                    // try common.printLnFmt("\tneightbor: {d},{d}", .{ next.x, next.y });
                    // constrain to grid
                    if (next.x < 0 or next.x >= self.grid.width or next.y < 0 or next.y >= self.grid.height) continue;
                    // try common.printLn("\t\tneightbor within grid...");
                    // ignore visited
                    if (self.visited.atUnchecked(next).* != null) continue;
                    // try common.printLn("\t\tneightbor not visited...");
                    // ignore pending
                    for (self.queue.readableSlice(0)) |pending| {
                        if (pending.x == next.x and pending.y == next.y) continue :neighbors;
                    }
                    // try common.printLn("\t\tneightbor not pending...");
                    // ignore unreachable
                    const nv = self.grid.atUnchecked(next).*;

                    // try common.printLnFmt("\t\tneighbor height reachable... ({d} -> {d})", .{ current.val, nv });

                    if (current.val + 1 < nv) continue;

                    // enqueue unprocessed reachable cell
                    self.visited.atUnchecked(next).* = .{
                        .prev = pos,
                        .dist = current.dist + 1,
                        .val = self.grid.atUnchecked(next).*,
                    };
                    try self.queue.writeItem(next);
                }

                // try self.printState();
            }

            if ((try self.visited.at(self.end)).*) |info| {
                return info.dist;
            } else {
                return error.NoValidPath;
            }
        }

        pub fn printState(self: *Self) !void {
            try common.printLn("");
            for (self.queue.readableSlice(0)) |pending| {
                try common.printFmt("{any}", .{pending});
            }

            for (self.visited.cells) |row, y| {
                try common.printLn("");
                for (row) |cell, x| {
                    var char: u8 = '.';

                    if (cell) |visited| {
                        // if visited print value
                        char = visited.val;

                        for (self.queue.readableSlice(0)) |pending, pi| {
                            if (pending.x == x and pending.y == y) {
                                // if pending print '#'
                                char = '#';

                                if (pi == 0) {
                                    // if current print '@'
                                    char = '@';
                                }

                                break;
                            }
                        }
                    }

                    try common.printFmt("{c}", .{char});
                }
            }

            try common.printLn("");
        }
    };
}

test "BFS" {
    var grid = try Grid(u8).init(5, 8, std.testing.allocator);
    defer grid.deinit();
    std.mem.copy(u8, grid.cells[0], "Sabqponm");
    std.mem.copy(u8, grid.cells[1], "abcryxxl");
    std.mem.copy(u8, grid.cells[2], "accszExk");
    std.mem.copy(u8, grid.cells[3], "acctuvwj");
    std.mem.copy(u8, grid.cells[4], "abdefghi");
    try expectEqual(@as(u8, 'E'), grid.cells[2][5]);
    try expectEqual(@as(u8, 'S'), grid.cells[0][0]);
    try expectEqual(@as(usize, 8), grid.width);
    try expectEqual(@as(usize, 5), grid.height);

    var start_pos = grid.findIndex('S').?;
    var end_pos = grid.findIndex('E').?;

    grid.atUnchecked(start_pos).* = 'a';
    grid.atUnchecked(end_pos).* = 'z';

    var bfs = try BFS().init(&grid, start_pos, end_pos, std.testing.allocator);
    defer bfs.deinit();
    var len = try bfs.findPathLength();

    try expectEqual(@as(usize, 31), len);
}
