const std = @import("std");

const common = @import("common.zig");
const day_01 = @import("day_01.zig");
const day_02 = @import("day_02.zig");
const day_03 = @import("day_03.zig");
const day_04 = @import("day_04.zig");
const day_05 = @import("day_05.zig");
const day_06 = @import("day_06.zig");
const day_07 = @import("day_07.zig");
const day_08 = @import("day_08.zig");
const day_09 = @import("day_09.zig");
const day_10 = @import("day_10.zig");
const day_11 = @import("day_11.zig");
const day_12 = @import("day_12.zig");

pub fn main() !void {
    try common.printLn("Advent of Code 2022 - Zig");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var input = try parseInput(allocator);
    defer input.deinit();

    switch (input.day) {
        1 => try day_01.run(input.inputFile.?),
        2 => try day_02.run(input.inputFile.?),
        3 => try day_03.run(input.inputFile.?),
        4 => try day_04.run(input.inputFile.?),
        5 => try day_05.run(input.inputFile.?, allocator),
        6 => try day_06.run(input.inputFile.?),
        7 => try day_07.run(input.inputFile.?, allocator),
        8 => try day_08.run(input.inputFile.?, allocator),
        9 => try day_09.run(input.inputFile.?, allocator),
        10 => try day_10.run(input.inputFile.?, allocator),
        11 => try day_11.run(input.inputFile.?, allocator),
        12 => try day_12.run(input.inputFile.?, allocator),
        else => {},
    }
}

const Inputs = struct {
    const Self = @This();
    day: i32,
    inputFile: ?std.fs.File,

    fn init(day: i32, inputFilePath: ?[]const u8) !Self {
        var self = Self{
            .day = day,
            .inputFile = null,
        };

        if (inputFilePath) |ifp| {
            self.inputFile = try std.fs.cwd().openFile(ifp, .{});
        }

        return self;
    }

    fn deinit(self: *Self) void {
        if (self.inputFile != null) {
            self.inputFile.?.close();
            self.inputFile = null;
        }
    }
};

fn parseInput(allocator: std.mem.Allocator) !Inputs {
    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        return error.InvalidArgs;
    }

    return Inputs.init(
        try std.fmt.parseInt(i32, args[1], 10),
        if (args.len > 2) args[2] else null);
}
