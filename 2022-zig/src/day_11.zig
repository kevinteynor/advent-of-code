const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const common = @import("common.zig");

pub fn run(input: anytype, allocator: Allocator) !void {
    try common.printLn("Day 11: Monkey in the Middle");

    {
        var buffered = std.io.bufferedReader(input.reader());
        var reader = buffered.reader();
        var state = MonkeysState.init(try parseMonkeys(reader, allocator), .div);
        try state.executeRounds(20);
        try common.printLnFmt("Monkey Buisiness: @20 {}", .{state.getMonkeyBuisiness()});
    }

    {
        try input.seekTo(0);
        var buffered = std.io.bufferedReader(input.reader());
        var reader = buffered.reader();
        var state = MonkeysState.init(try parseMonkeys(reader, allocator), .mod);
        try state.executeRounds(10000);
        try common.printLnFmt("Monkey Buisiness: @10000 {}", .{state.getMonkeyBuisiness()});
    }
}

const WorryOpTag = enum {
    add,
    mul,
    sqr,
};
const WorryOp = union(WorryOpTag) { add: i32, mul: i32, sqr: void };
const ThrowCheck = struct {
    divisor: i32,
    divisibleTarget: u8,
    indivisibleTarget: u8,
};


const WorryLevel = i64;

const Monkey = struct {
    const Self = @This();
    items: ArrayList(WorryLevel),
    worry: WorryOp,
    throw: ThrowCheck,
    totalInspected: i32 = 0,
};

const WorryReductionOpTag = enum {
    div,
    mod,
};
const WorryReductionOp = union(WorryReductionOpTag) { div: i32, mod: i32 };

const MonkeysState = struct {
    const Self = @This();

    worryReduction: WorryReductionOp,
    monkeys: ArrayList(Monkey),

    pub fn init(monkeys: ArrayList(Monkey), worryOp: WorryReductionOpTag) Self {
        var self = Self {
            .worryReduction = undefined,
            .monkeys = monkeys,
        };

        switch (worryOp) {
            .div => self.worryReduction = .{ .div = 3 },
            .mod => {
                var d: i32 = 1;
                for (monkeys.items) |monkey| {
                    d *= monkey.throw.divisor;
                }
                self.worryReduction = .{ .mod = d };
            },
        }
        
        return self;
    }

    pub fn deinit(self: *Self) void {
        for (self.monkeys.items) |*monkey| {
            monkey.items.deinit();
        }
        self.monkeys.deinit();
    }

    fn executeRounds(self: *Self, rounds: usize) !void {
        var rnd: usize = 0;
        while (rnd < rounds) : (rnd += 1) {
            try self.executeRound();
        }
    }

    fn executeRound(self: *Self) !void {
        for (self.monkeys.items) |*monkey| {
            for (monkey.items.items) |*item| {
                // inspect item
                switch (monkey.worry) {
                    .add => |val| item.* += val,
                    .mul => |val| item.* *= val,
                    .sqr => item.* *= item.*,
                }
                monkey.totalInspected += 1;

                // reduce worry
                switch (self.worryReduction) {
                    .div => |val| item.* = @divTrunc(item.*, val),
                    .mod => |val| item.* = @rem(item.*, val),
                }

                // toss item
                const target = if (@rem(item.*, monkey.throw.divisor) == 0) monkey.throw.divisibleTarget else monkey.throw.indivisibleTarget;
                try self.monkeys.items[target].items.append(item.*);
            }
            monkey.items.clearRetainingCapacity();
        }
    }

    fn getMonkeyBuisiness(self: *Self) WorryLevel {
        var highest = [_]WorryLevel{ 1, 1 };
        for (self.monkeys.items) |*monkey| {
            highest[1] = std.math.max(highest[1], monkey.totalInspected);
            if (highest[1] > highest[0]) {
                std.mem.swap(WorryLevel, &highest[0], &highest[1]);
            }
        }

        return highest[0] * highest[1];
    }
};

test "Monkey State (div)" {
    const allocator = std.testing.allocator;
    var monkeys = try ArrayList(Monkey).initCapacity(allocator, 4);

    // Monkey 0
    try monkeys.append(Monkey{
        .items = ArrayList(WorryLevel).init(allocator),
        .worry = WorryOp{ .mul = 19 },
        .throw = ThrowCheck{
            .divisor = 23,
            .divisibleTarget = 2,
            .indivisibleTarget = 3,
        },
    });

    // Monkey 1
    try monkeys.append(Monkey{
        .items = ArrayList(WorryLevel).init(allocator),
        .worry = WorryOp{ .add = 6 },
        .throw = ThrowCheck{
            .divisor = 19,
            .divisibleTarget = 2,
            .indivisibleTarget = 0,
        },
    });

    // Monkey 2
    try monkeys.append(Monkey{
        .items = ArrayList(WorryLevel).init(allocator),
        .worry = WorryOp.sqr,
        .throw = ThrowCheck{
            .divisor = 13,
            .divisibleTarget = 1,
            .indivisibleTarget = 3,
        },
    });

    // Monkey 3
    try monkeys.append(Monkey{
        .items = ArrayList(WorryLevel).init(allocator),
        .worry = WorryOp{ .add = 3 },
        .throw = ThrowCheck{
            .divisor = 17,
            .divisibleTarget = 0,
            .indivisibleTarget = 1,
        },
    });

    try monkeys.items[0].items.append(79);
    try monkeys.items[0].items.append(98);
    try monkeys.items[1].items.append(54);
    try monkeys.items[1].items.append(65);
    try monkeys.items[1].items.append(75);
    try monkeys.items[1].items.append(74);
    try monkeys.items[2].items.append(79);
    try monkeys.items[2].items.append(60);
    try monkeys.items[2].items.append(97);
    try monkeys.items[3].items.append(74);

    var state = MonkeysState.init(monkeys, .div);
    defer state.deinit();

    // actual test:

    try state.executeRound();
    try expectEqual(@as(usize, 4), monkeys.items[0].items.items.len);
    try expectEqual(@as(usize, 6), monkeys.items[1].items.items.len);
    try expectEqual(@as(usize, 0), monkeys.items[2].items.items.len);
    try expectEqual(@as(usize, 0), monkeys.items[3].items.items.len);
    try expectEqual(@as(WorryLevel, 27), monkeys.items[0].items.items[2]);
    try expectEqual(@as(WorryLevel, 167), monkeys.items[1].items.items[2]);

    try state.executeRound();
    try expectEqual(@as(usize, 5), monkeys.items[0].items.items.len);
    try expectEqual(@as(usize, 5), monkeys.items[1].items.items.len);
    try expectEqual(@as(usize, 0), monkeys.items[2].items.items.len);
    try expectEqual(@as(usize, 0), monkeys.items[3].items.items.len);
    try expectEqual(@as(WorryLevel, 695), monkeys.items[0].items.items[0]);
    try expectEqual(@as(WorryLevel, 362), monkeys.items[1].items.items[4]);

    try state.executeRounds(18);
    try expectEqual(@as(usize, 5), monkeys.items[0].items.items.len);
    try expectEqual(@as(usize, 5), monkeys.items[1].items.items.len);
    try expectEqual(@as(usize, 0), monkeys.items[2].items.items.len);
    try expectEqual(@as(usize, 0), monkeys.items[3].items.items.len);
    try expectEqual(@as(WorryLevel, 14), monkeys.items[0].items.items[2]);
    try expectEqual(@as(WorryLevel, 53), monkeys.items[1].items.items[2]);
}

test "Monkey State (mod))" {
    const allocator = std.testing.allocator;
    var monkeys = try ArrayList(Monkey).initCapacity(allocator, 4);

    // Monkey 0
    try monkeys.append(Monkey{
        .items = ArrayList(WorryLevel).init(allocator),
        .worry = WorryOp{ .mul = 19 },
        .throw = ThrowCheck{
            .divisor = 23,
            .divisibleTarget = 2,
            .indivisibleTarget = 3,
        },
    });

    // Monkey 1
    try monkeys.append(Monkey{
        .items = ArrayList(WorryLevel).init(allocator),
        .worry = WorryOp{ .add = 6 },
        .throw = ThrowCheck{
            .divisor = 19,
            .divisibleTarget = 2,
            .indivisibleTarget = 0,
        },
    });

    // Monkey 2
    try monkeys.append(Monkey{
        .items = ArrayList(WorryLevel).init(allocator),
        .worry = WorryOp.sqr,
        .throw = ThrowCheck{
            .divisor = 13,
            .divisibleTarget = 1,
            .indivisibleTarget = 3,
        },
    });

    // Monkey 3
    try monkeys.append(Monkey{
        .items = ArrayList(WorryLevel).init(allocator),
        .worry = WorryOp{ .add = 3 },
        .throw = ThrowCheck{
            .divisor = 17,
            .divisibleTarget = 0,
            .indivisibleTarget = 1,
        },
    });

    try monkeys.items[0].items.append(79);
    try monkeys.items[0].items.append(98);
    try monkeys.items[1].items.append(54);
    try monkeys.items[1].items.append(65);
    try monkeys.items[1].items.append(75);
    try monkeys.items[1].items.append(74);
    try monkeys.items[2].items.append(79);
    try monkeys.items[2].items.append(60);
    try monkeys.items[2].items.append(97);
    try monkeys.items[3].items.append(74);

    var state = MonkeysState.init(monkeys, .mod);
    defer state.deinit();

    // actual test:

    try state.executeRound();
    try expectEqual(@as(i64, 2), monkeys.items[0].totalInspected);
    try expectEqual(@as(i64, 4), monkeys.items[1].totalInspected);
    try expectEqual(@as(i64, 3), monkeys.items[2].totalInspected);
    try expectEqual(@as(i64, 6), monkeys.items[3].totalInspected);

    try state.executeRounds(19);
    try expectEqual(@as(i64, 99), monkeys.items[0].totalInspected);
    try expectEqual(@as(i64, 97), monkeys.items[1].totalInspected);
    try expectEqual(@as(i64, 8), monkeys.items[2].totalInspected);
    try expectEqual(@as(i64, 103), monkeys.items[3].totalInspected);

    try state.executeRounds(9980);
    try expectEqual(@as(i32, 52166), monkeys.items[0].totalInspected);
    try expectEqual(@as(i32, 47830), monkeys.items[1].totalInspected);
    try expectEqual(@as(i32, 1938), monkeys.items[2].totalInspected);
    try expectEqual(@as(i32, 52013), monkeys.items[3].totalInspected);
    try expectEqual(@as(WorryLevel, 2713310158), state.getMonkeyBuisiness());
}

fn parseMonkeys(reader: anytype, allocator: Allocator) !ArrayList(Monkey) {
    var monkeys = ArrayList(Monkey).init(allocator);
    var buffer: [256]u8 = undefined;
    while (true) {
        var lines = try common.readLinesUntilBlank(reader, &buffer, allocator);
        defer lines.deinit();
        if (lines.items.len == 0) break;

        if (lines.items.len != 6) return error.InvalidInput;

        var monkey = try monkeys.addOne();

        // initial items
        monkey.items = ArrayList(WorryLevel).init(allocator);
        var item_it = std.mem.split(u8, lines.items[1][18..], ", ");
        while (item_it.next()) |item| {
            try monkey.items.append(try std.fmt.parseInt(i64, item, 10));
        }
        monkey.totalInspected = 0;

        // worry
        if (lines.items[2][23] == '+') {
            monkey.worry = WorryOp{ .add = try std.fmt.parseInt(i32, lines.items[2][25..], 10) };
        } else if (lines.items[2][23] == '*') {
            if (lines.items[2][25] == 'o') {
                monkey.worry = WorryOp.sqr;
            } else {
                monkey.worry = WorryOp{ .mul = try std.fmt.parseInt(i32, lines.items[2][25..], 10) };
            }
        }

        // test
        monkey.throw.divisor = try std.fmt.parseInt(i32, lines.items[3][21..], 10);
        monkey.throw.divisibleTarget = try std.fmt.parseInt(u8, lines.items[4][29..], 10);
        monkey.throw.indivisibleTarget = try std.fmt.parseInt(u8, lines.items[5][30..], 10);
    }

    return monkeys;
}

test "Parse Monkeys" {
    var input = std.io.fixedBufferStream(
        \\Monkey 0:
        \\  Starting items: 79, 98
        \\  Operation: new = old * 19
        \\  Test: divisible by 23
        \\    If true: throw to monkey 2
        \\    If false: throw to monkey 3
        \\
        \\Monkey 1:
        \\  Starting items: 54, 65, 75, 74
        \\  Operation: new = old + 6
        \\  Test: divisible by 19
        \\    If true: throw to monkey 2
        \\    If false: throw to monkey 0
        \\
        \\Monkey 2:
        \\  Starting items: 79, 60, 97
        \\  Operation: new = old * old
        \\  Test: divisible by 13
        \\    If true: throw to monkey 1
        \\    If false: throw to monkey 3
        \\
        \\Monkey 3:
        \\  Starting items: 74
        \\  Operation: new = old + 3
        \\  Test: divisible by 17
        \\    If true: throw to monkey 0
        \\    If false: throw to monkey 1
    );
    var reader = input.reader();
    const allocator = std.testing.allocator;

    var monkeys = try parseMonkeys(reader, allocator);
    // for (monkeys.items) |*monkey| {
    //     defer monkey.items.deinit();
    // }
    // defer monkeys.deinit();
    var state = MonkeysState.init(monkeys, .div);
    defer state.deinit();

    try state.executeRound();
    try expectEqual(@as(usize, 4), monkeys.items[0].items.items.len);
    try expectEqual(@as(usize, 6), monkeys.items[1].items.items.len);
    try expectEqual(@as(usize, 0), monkeys.items[2].items.items.len);
    try expectEqual(@as(usize, 0), monkeys.items[3].items.items.len);
    try expectEqual(@as(WorryLevel, 27), monkeys.items[0].items.items[2]);
    try expectEqual(@as(WorryLevel, 167), monkeys.items[1].items.items[2]);

    try state.executeRounds(19);
    try expectEqual(@as(usize, 5), monkeys.items[0].items.items.len);
    try expectEqual(@as(usize, 5), monkeys.items[1].items.items.len);
    try expectEqual(@as(usize, 0), monkeys.items[2].items.items.len);
    try expectEqual(@as(usize, 0), monkeys.items[3].items.items.len);
    try expectEqual(@as(WorryLevel, 14), monkeys.items[0].items.items[2]);
    try expectEqual(@as(WorryLevel, 53), monkeys.items[1].items.items[2]);

    var mb = state.getMonkeyBuisiness();
    try expectEqual(@as(WorryLevel, 10605), mb);
}
