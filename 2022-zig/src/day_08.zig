const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const StringArrayHashMap = std.StringArrayHashMap;
const common = @import("common.zig");

pub fn run(input: std.fs.File, allocator: Allocator) !void {
    try common.printLn("Day 8: Treetop Tree House");

    try input.seekTo(0);
    var buffered = std.io.bufferedReader(input.reader());
    var reader = buffered.reader();

    const numVisible = try getVisibleTreeCount(reader, allocator);
    try common.printLnFmt("Number of visible trees: {}", .{numVisible});

    try input.seekTo(0);
    buffered = std.io.bufferedReader(input.reader());
    reader = buffered.reader();

    const bestScore = try getBestScenicScore(reader, allocator);
    try common.printLnFmt("Best scenic score: {}", .{bestScore});
}

fn getVisibleTreeCount(reader: anytype, allocator: Allocator) !usize {
    //
    var grid = try parseTreeGrid(reader, allocator);
    try grid.calcNeighborHeights();
    return grid.numVisible();
}

fn getBestScenicScore(reader: anytype, allocator: Allocator) !usize {
    var grid = try parseTreeGrid(reader, allocator);
    return try grid.maxScenicScore();
}

const Grid = struct {
    const Self = @This();
    width: usize,
    height: usize,
    allocator: Allocator,
    cells: []Cell,

    fn init(width: usize, height: usize, allocator: Allocator) !Self {
        var self = Self{
            .allocator = allocator,
            .width = width,
            .height = height,
            .cells = &[_]Cell{},
        };
        self.cells = try self.allocator.alignedAlloc(Cell, null, width * height);
        return self;
    }

    fn deinit(self: Self) void {
        self.allocator.free(self.cells);
    }

    fn fill(self: *Self, heights: []const i8) !void {
        if (heights.len != self.width * self.height) {
            return error.InvalidInput;
        }

        var y: usize = 0;
        while (y < self.height) : (y += 1) {
            var x: usize = 0;
            while (x < self.width) : (x += 1) {
                const i = y * self.width + x;
                self.cells[i] = Cell{
                    .height = heights[i],
                    .left = 0,
                    .up = 0,
                    .right = 0,
                    .down = 0,
                };
            }
        }
    }

    fn calcNeighborHeights(self: *Self) !void {
        // left + right heights processed row-by-row
        var row: usize = 0;
        while (row < self.height) : (row += 1) {
            var tallest: i8 = -1;
            var leftIt = try self.rowIterator(row);
            while (leftIt.next()) |cell| {
                cell.left = tallest;
                tallest = std.math.max(cell.height, tallest);
            }

            tallest = -1;
            var rightIt = try self.reverseRowIterator(row);
            while (rightIt.next()) |cell| {
                cell.right = tallest;
                tallest = std.math.max(cell.height, tallest);
            }
        }

        // top + bottom heights processed col-by-col
        var col: usize = 0;
        while (col < self.width) : (col += 1) {
            var tallest: i8 = -1;
            var upIt = try self.columnIterator(col);
            while (upIt.next()) |cell| {
                cell.up = tallest;
                tallest = std.math.max(cell.height, tallest);
            }

            tallest = -1;
            var downIt = try self.reverseColumnIterator(col);
            while (downIt.next()) |cell| {
                cell.down = tallest;
                tallest = std.math.max(cell.height, tallest);
            }
        }
    }

    fn numVisible(self: Self) usize {
        var total: usize = 0;
        var y: usize = 0;
        while (y < self.height) : (y += 1) {
            var x: usize = 0;
            while (x < self.width) : (x += 1) {
                if (self.cells[y * self.width + x].isVisible()) {
                    total += 1;
                }
            }
        }
        return total;
    }

    fn maxScenicScore(self: Self) !usize {
        var best: usize = 0;

        // don't need to check outermost trees, they will all be 0
        var y: usize = 1;
        while (y < self.height - 1) : (y += 1) {
            var x: usize = 1;
            while (x < self.width - 1) : (x += 1) {
                var cell = try self.at(x, y);
                cell.left = 0;
                cell.up = 0;
                cell.right = 0;
                cell.down = 0;
                var i: isize = @intCast(isize, x) - 1;
                while (i >= 0) : (i -= 1) {
                    cell.left += 1;
                    if ((try self.at(@intCast(usize, i), y)).height >= cell.height) break;
                }
                i = @intCast(isize, x) + 1;
                while (i < self.width) : (i += 1) {
                    cell.right += 1;
                    if ((try self.at(@intCast(usize, i), y)).height >= cell.height) break;
                }
                i = @intCast(isize, y) - 1;
                while (i >= 0) : (i -= 1) {
                    cell.up += 1;
                    if ((try self.at(x, @intCast(usize, i))).height >= cell.height) break;
                }
                i = @intCast(isize, y) + 1;
                while (i < self.height) : (i += 1) {
                    cell.down += 1;
                    if ((try self.at(x, @intCast(usize, i))).height >= cell.height) break;
                }

                const score: usize = @intCast(usize, cell.left) * @intCast(usize, cell.up) * @intCast(usize, cell.right) * @intCast(usize, cell.down);
                best = std.math.max(best, score);
            }
        }

        return best;
    }

    fn at(self: Self, x: usize, y: usize) !*Cell {
        if (x >= self.width or y >= self.height) {
            return error.InvalidIndex;
        }

        return &self.cells[y * self.width + x];
    }

    // iterates over a single row inside the grid
    const RowIterator = struct {
        grid: *Grid,
        row: usize,
        index: isize,
        step: isize,

        fn next(self: *RowIterator) ?*Cell {
            if (self.index < 0 or self.index >= self.grid.width) return null;
            defer self.index += self.step;
            return &self.grid.cells[self.row * self.grid.width + @intCast(usize, self.index)];
        }
    };

    fn rowIterator(self: *Self, row: usize) !RowIterator {
        if (row >= self.height) {
            return error.InvalidIndex;
        }
        return RowIterator{
            .grid = self,
            .row = row,
            .index = 0,
            .step = 1,
        };
    }

    fn reverseRowIterator(self: *Self, row: usize) !RowIterator {
        if (row >= self.height) {
            return error.InvalidIndex;
        }
        return RowIterator{
            .grid = self,
            .row = row,
            .index = @intCast(isize, self.width) - 1,
            .step = -1,
        };
    }

    const ColumnIterator = struct {
        grid: *Grid,
        column: usize,
        index: isize,
        step: isize,

        fn next(self: *ColumnIterator) ?*Cell {
            if (self.index < 0 or self.index >= self.grid.height) return null;
            defer self.index += self.step;
            return &self.grid.cells[@intCast(usize, self.index) * self.grid.width + self.column];
        }
    };

    fn columnIterator(self: *Self, col: usize) !ColumnIterator {
        if (col >= self.width) {
            return error.InvalidIndex;
        }
        return ColumnIterator{
            .grid = self,
            .column = col,
            .index = 0,
            .step = 1,
        };
    }

    fn reverseColumnIterator(self: *Self, col: usize) !ColumnIterator {
        if (col >= self.width) {
            return error.InvalidIndex;
        }
        return ColumnIterator{
            .grid = self,
            .column = col,
            .index = @intCast(isize, self.height) - 1,
            .step = -1,
        };
    }
};

const Cell = struct {
    const Self = @This();
    height: i8,
    left: i8 = 0,
    up: i8 = 0,
    right: i8 = 0,
    down: i8 = 0,

    fn isVisible(self: Self) bool {
        return self.height > self.left or
            self.height > self.up or
            self.height > self.right or
            self.height > self.down;
    }
};

test "Grid Visibility" {
    var grid = try Grid.init(5, 5, std.testing.allocator);
    defer grid.deinit();

    const input = [_]i8{
        3, 0, 3, 7, 3,
        2, 5, 5, 1, 2,
        6, 5, 3, 3, 2,
        3, 3, 5, 4, 9,
        3, 5, 3, 9, 0,
    };
    try grid.fill(&input);
    try grid.calcNeighborHeights();

    try common.printLn("");
    const numVisible = grid.numVisible();
    try expectEqual(@as(usize, 21), numVisible);
}

test "Grid Scenic Score" {
    var grid = try Grid.init(5, 5, std.testing.allocator);
    defer grid.deinit();

    const input = [_]i8{
        3, 0, 3, 7, 3,
        2, 5, 5, 1, 2,
        6, 5, 3, 3, 2,
        3, 3, 5, 4, 9,
        3, 5, 3, 9, 0,
    };
    try grid.fill(&input);

    try common.printLn("");
    const maxScore = try grid.maxScenicScore();

    try common.printLnFmt("Max scenic score: {}", .{maxScore});
    try expectEqual(@as(usize, 8), maxScore);
}

test "Grid Iterators" {
    var grid = try Grid.init(5, 5, std.testing.allocator);
    defer grid.deinit();
    const input = [_]i8{
        3, 0, 3, 7, 3,
        2, 5, 5, 1, 2,
        6, 5, 3, 3, 2,
        3, 3, 5, 4, 9,
        3, 5, 3, 9, 0,
    };
    try grid.fill(&input);

    var rowIt = try grid.rowIterator(2);
    try expectEqual(@as(i8, 6), rowIt.next().?.height);
    try expectEqual(@as(i8, 5), rowIt.next().?.height);
    try expectEqual(@as(i8, 3), rowIt.next().?.height);
    try expectEqual(@as(i8, 3), rowIt.next().?.height);
    try expectEqual(@as(i8, 2), rowIt.next().?.height);
    try expect(rowIt.next() == null);

    rowIt = try grid.reverseRowIterator(3);
    try expectEqual(@as(i8, 9), rowIt.next().?.height);
    try expectEqual(@as(i8, 4), rowIt.next().?.height);
    try expectEqual(@as(i8, 5), rowIt.next().?.height);
    try expectEqual(@as(i8, 3), rowIt.next().?.height);
    try expectEqual(@as(i8, 3), rowIt.next().?.height);
    try expect(rowIt.next() == null);

    var colIt = try grid.columnIterator(0);
    try expectEqual(@as(i8, 3), colIt.next().?.height);
    try expectEqual(@as(i8, 2), colIt.next().?.height);
    try expectEqual(@as(i8, 6), colIt.next().?.height);
    try expectEqual(@as(i8, 3), colIt.next().?.height);
    try expectEqual(@as(i8, 3), colIt.next().?.height);
    try expect(colIt.next() == null);

    colIt = try grid.reverseColumnIterator(3);
    try expectEqual(@as(i8, 9), colIt.next().?.height);
    try expectEqual(@as(i8, 4), colIt.next().?.height);
    try expectEqual(@as(i8, 3), colIt.next().?.height);
    try expectEqual(@as(i8, 1), colIt.next().?.height);
    try expectEqual(@as(i8, 7), colIt.next().?.height);
    try expect(colIt.next() == null);
}

fn parseTreeGrid(reader: anytype, allocator: Allocator) !Grid {
    // parse input lines return grid of tree heights
    var buf: [1024]u8 = undefined;
    var grid: ?Grid = null;
    var row: usize = 0;
    while (try common.readLine(reader, &buf)) |line| {
        if (grid == null) {
            grid = try Grid.init(line.len, line.len, allocator);
        }

        var col: usize = 0;
        var it = try grid.?.rowIterator(row);
        while (it.next()) |cell| {
            cell.height = try std.fmt.parseInt(i8, line[col .. col + 1], 10);
            col += 1;
        }

        row += 1;
    }

    return grid orelse error.FailedToParseGrid;
}

test "Parse Grid" {
    var input = std.io.fixedBufferStream(
        \\30373
        \\25512
        \\65332
        \\33549
        \\35390
    );
    var reader = input.reader();
    var grid = try parseTreeGrid(reader, std.testing.allocator);
    defer grid.deinit();

    try expectEqual(@as(usize, 5), grid.width);
    try expectEqual(@as(usize, 5), grid.height);

    try expectEqual(@as(i8, 6), (try grid.at(0, 2)).height);
    try expectEqual(@as(i8, 7), (try grid.at(3, 0)).height);
    try expectEqual(@as(i8, 9), (try grid.at(4, 3)).height);
    try expectEqual(@as(i8, 5), (try grid.at(1, 4)).height);
}
