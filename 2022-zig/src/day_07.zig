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
    try common.printLn("Day 7: No Space Left on Device");

    var buffered = std.io.bufferedReader(input.reader());
    var reader = buffered.reader();

    // part 1
    const sum = try sum1(reader, allocator);
    try common.printLnFmt("sum of dirs <=100000: {}", .{sum});

    try input.seekTo(0);
    buffered = std.io.bufferedReader(input.reader());
    reader = buffered.reader();

    // part 2
    const delSize = try deleteSize(reader, allocator);
    try common.printLnFmt("min size to delete: {}", .{delSize});
}

fn sum1(reader: anytype, allocator: Allocator) !usize {
    var root = try parseFileSystem(reader, allocator);
    defer root.deinit();

    var sum: usize = recursiveSum(&root, 100000);
    return sum;
}

fn recursiveSum(dir: *Directory, threshold: usize) usize {
    // @root: check size
    //  check children sizes
    //  recurse until ____
    var size: usize = 0;
    var dir_size = dir.getSize();
    if (dir_size <= threshold) {
        size += dir_size;
    }

    var it = dir.children.iterator();
    while (it.next()) |child| {
        switch (child.value_ptr.*) {
            .directory => |*subdir| size += recursiveSum(subdir, threshold),
            else => {},
        }
    }

    return size;
}

test "recursive sum" {
    var root = try Directory.init("/", null, std.testing.allocator);
    defer root.deinit();

    var current: *Directory = &root;
    try current.ensureDir("a");
    try current.ensureDir("b");

    current = current.getChildDir("a").?;
    try current.ensureFile("w.f", 100);
    try current.ensureDir("c");
    current = current.getChildDir("c").?;
    try current.ensureFile("x.f", 300);
    current = &root;
    current = current.getChildDir("b").?;
    try current.ensureFile("y.f", 200);

    // try root.printTree(0);

    const sum = recursiveSum(&root, 300);
    try expectEqual(@as(usize, 500), sum);
}

fn deleteSize(reader: anytype, allocator: Allocator) !usize {
    var root = try parseFileSystem(reader, allocator);
    defer root.deinit();

    const total_size = root.getSize();
    const free_size = 70000000 - total_size;
    const needed_size = 30000000 - free_size;   // how much space is need to be freed

    // find smallest dir that is at least `needed_size` big
    return recursiveMin(&root, needed_size).?;
}

fn recursiveMin(dir: *Directory, minThreshold: usize) ?usize {
    var size = dir.getSize();
    if (size < minThreshold) {
        // current dir too small
        return null;
    }

    var it = dir.children.iterator();
    while (it.next()) |child| {
        switch (child.value_ptr.*) {
            .directory => |*subdir| {
                const subsize = recursiveMin(subdir, minThreshold) orelse continue;
                size = std.math.min(size, subsize);
            },
            else => {},
        }
    }

    return size;
}

test "recursive min" {
    var root = try Directory.init("/", null, std.testing.allocator);
    defer root.deinit();

    var current: *Directory = &root;
    try current.ensureDir("a");
    try current.ensureDir("b");

    current = current.getChildDir("a").?;
    try current.ensureFile("w.f", 100);
    try current.ensureDir("c");
    current = current.getChildDir("c").?;
    try current.ensureFile("x.f", 300);
    current = &root;
    current = current.getChildDir("b").?;
    try current.ensureFile("y.f", 401);

    const min = recursiveMin(&root, 400).?;
    try expectEqual(@as(usize, 400), min);
}


const Directory = struct {
    const Self = @This();
    allocator: Allocator,
    name: []u8,
    parent: ?*Directory,
    children: StringArrayHashMap(Item),

    fn init(name: []const u8, parent: ?*Directory, allocator: Allocator) !Self {
        return Self{
            .allocator = allocator,
            .name = try allocator.dupe(u8, name),
            .parent = parent,
            .children = StringArrayHashMap(Item).init(allocator),
        };
    }

    fn deinit(self: *Self) void {
        var it = self.children.iterator();
        while (it.next()) |child_entry| {
            switch (child_entry.value_ptr.*) {
                .directory => |*subdir| {
                    subdir.deinit();
                },
                .file => |*file| {
                    file.deinit();
                },
            }
        }
        self.children.deinit();
        self.allocator.free(self.name);
    }

    fn printTree(self: Self, indent: usize) !void {
        try common.printLnFmt("{[name]s: >[indent]}", .{ .name = self.name, .indent = indent + self.name.len });
        const indent_step = 2;
        var it = self.children.iterator();
        while (it.next()) |child_entry| {
            switch (child_entry.value_ptr.*) {
                .directory => |*subdir| try subdir.printTree(indent + indent_step),
                .file => |*file| {
                    try common.printLnFmt("{[name]s: >[indent]} ({[size]})", .{ .name = file.name, .indent = indent + indent_step + file.name.len, .size = file.size });
                },
            }
        }
    }

    fn ensureDir(self: *Self, name: []const u8) !void {
        const result = try self.children.getOrPut(name);
        if (!result.found_existing) {
            result.value_ptr.* = .{ .directory = try Directory.init(name, self, self.allocator) };
        } else if (result.value_ptr.* != Item.directory) {
            return error.IncorrectItemType;
        }
    }

    fn ensureFile(self: *Self, name: []const u8, size: usize) !void {
        const result = try self.children.getOrPut(name);
        if (!result.found_existing) {
            result.value_ptr.* = .{ .file = try File.init(name, size, self.allocator) };
        } else if (result.value_ptr.* != Item.file) {
            return error.IncorrectItemType;
        }
    }

    fn getChildDir(self: *Self, name: []const u8) ?*Directory {
        const result = self.children.getPtr(name) orelse return null;
        return switch (result.*) {
            .directory => |*subdir| return subdir,
            .file => return null,
        };
    }

    fn getSize(self: Self) usize {
        var size: usize = 0;

        var it = self.children.iterator();
        while (it.next()) |child_entry| {
            size += switch (child_entry.value_ptr.*) {
                .directory => |*subdir| subdir.getSize(),
                .file => |*file| file.size,
            };
        }

        return size;
    }
};

const File = struct {
    const Self = @This();

    allocator: Allocator,
    name: []u8,
    size: usize,

    fn init(name: []const u8, size: usize, allocator: Allocator) !Self {
        return Self{
            .allocator = allocator,
            .name = try allocator.dupe(u8, name),
            .size = size,
        };
    }

    fn deinit(self: *Self) void {
        self.allocator.free(self.name);
    }
};

const ItemType = enum { file, directory };
const Item = union(ItemType) {
    file: File,
    directory: Directory,
};

test "FileSystem Size" {
    var root = try Directory.init("/", null, std.testing.allocator);
    defer root.deinit();

    var current: *Directory = &root;
    try current.ensureDir("a");
    try current.ensureDir("b");
    try current.ensureDir("c");
    current = current.getChildDir("b").?;
    try current.ensureDir("d");
    try current.ensureDir("e");
    current = current.parent.?;
    try current.ensureDir("f");
    current = current.getChildDir("f").?;
    try current.ensureFile("1.txt", 1024);

    // try root.printTree(0);

    try expectEqual(@as(usize, 1024), root.getSize());
}

// caller must deinit return value
fn parseFileSystem(reader: anytype, allocator: Allocator) !Directory {
    var buffer: [32]u8 = undefined;

    var root = try Directory.init("/", null, allocator);
    var current_dir: *Directory = &root;

    while (try common.readLine(reader, &buffer)) |line| {
        if (line.len > 5 and std.mem.eql(u8, line[0..4], "$ cd")) {
            var target_dir = line[5..];
            if (target_dir.len == 2 and std.mem.eql(u8, target_dir, "..")) {
                current_dir = current_dir.parent orelse return error.RootHasNoParent;
            } else if (target_dir.len == 1 and target_dir[0] == '/') {
                current_dir = &root;
            } else {
                try current_dir.ensureDir(target_dir);
                current_dir = current_dir.getChildDir(target_dir).?;
            }
        } else if (line.len > 3 and std.mem.eql(u8, line[0..4], "$ ls")) {
            // don't actually need to do anything for ls
        } else if (line.len > 0) {
            // ls output, either file or dir
            if (line.len > 4 and std.mem.eql(u8, line[0..4], "dir ")) {
                // parse dir info
                try current_dir.ensureDir(line[4..]);
            } else {
                // parse file info
                var it = std.mem.split(u8, line, " ");
                var size = try std.fmt.parseInt(usize, it.next().?, 10);
                var name = it.next().?;
                try current_dir.ensureFile(name, size);
            }
        }
    }

    return root;
}

test "Parse FileSystem" {
    var src = std.io.fixedBufferStream(
        \\$ cd /
        \\$ ls
        \\dir a
        \\14848514 b.txt
        \\8504156 c.dat
        \\dir d
        \\$ cd a
        \\$ ls
        \\dir e
        \\29116 f
        \\2557 g
        \\62596 h.lst
        \\$ cd e
        \\$ ls
        \\584 i
        \\$ cd ..
        \\$ cd ..
        \\$ cd d
        \\$ ls
        \\4060174 j
        \\8033020 d.log
        \\5626152 d.ext
        \\7214296 k
    );
    const reader = src.reader();

    var result = try parseFileSystem(reader, std.testing.allocator);
    defer result.deinit();

    try expectEqualStrings("/", result.name);

    // try result.printTree(0);
}
