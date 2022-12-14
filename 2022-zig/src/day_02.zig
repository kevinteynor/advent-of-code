const std = @import("std");
const expectEqual = std.testing.expectEqual;
const common = @import("common.zig");

// A, X = rock
// B, Y = paper
// C, Z = scissors

// scoring per round:
//  - selection:
//      - rock      +1
//      - paper     +2
//      - scissors  +3
//  - outcome:
//      - loss:     +0
//      - draw:     +3
//      - win:      +6

pub fn run(input: std.fs.File) !void {
    try common.printLn("Day 2: Calorie Counting");
    var buffered = std.io.bufferedReader(input.reader());
    var reader = buffered.reader();

    var score1 = try getScore1(reader);
    try common.printLnFmt("part 1: total player score: {}", .{score1});

    try input.seekTo(0);

    var score2 = try getScore2(reader);
    try common.printLnFmt("part 2: total player score: {}", .{score2});
}

fn getScore1(reader: anytype) !u32 {
    // read input file
    // loop over each input line, parse opponent + player selections, calculate + aggregate score
    var buf: [1024]u8 = undefined;
    var total: u32 = 0;
    while (try common.readLine(reader, &buf)) |line| {
        var it = std.mem.tokenize(u8, line, " ");

        const opponent = try parseSelection(it.next().?[0]);
        const player = try parseSelection(it.next().?[0]);

        total += getScore(player, opponent);
    }
    
    return total;
}

test "Get Score 1" {
    var input = std.io.fixedBufferStream(
        \\A Y
        \\B X
        \\C Z
    );
    var reader = input.reader();
    const sum = try getScore1(reader);
    try expectEqual(@as(u32, 15), sum);
}

fn getScore2(reader: anytype) !u32 {
    // read input file
    // loop over each input line, parse opponent + player selections, calculate + aggregate score
    var buf: [1024]u8 = undefined;
    var total: u32 = 0;
    while (try common.readLine(reader, &buf)) |line| {
        var it = std.mem.tokenize(u8, line, " ");

        const opponent = try parseSelection(it.next().?[0]);
        const result = try parseGameResult(it.next().?[0]);

        const player = getPlayerChoice(opponent, result);

        total += getScore(player, opponent);
    }

    return total;
}

test "Get Score 2" {
    var input = std.io.fixedBufferStream(
        \\A Y
        \\B X
        \\C Z
    );
    var reader = input.reader();
    const sum = try getScore2(reader);
    try expectEqual(@as(u32, 12), sum);
}

const Selection = enum(u32) {
    rock = 1,
    paper = 2,
    scissors = 3,
};

fn parseSelection(code: u8) error{InvalidInput}!Selection {
    return switch (code) {
        'A', 'X' => Selection.rock,
        'B', 'Y' => Selection.paper,
        'C', 'Z' => Selection.scissors,
        else => error.InvalidInput,
    };
}

test "selection parsing" {
    const a = parseSelection('A') catch unreachable;
    try std.testing.expect(a == Selection.rock);

    const b = parseSelection('B') catch unreachable;
    try std.testing.expect(b == Selection.paper);

    const c = parseSelection('C') catch unreachable;
    try std.testing.expect(c == Selection.scissors);

    _ = parseSelection('D') catch |err| {
        try std.testing.expect(err == error.InvalidInput);
    };

    const x = parseSelection('X') catch unreachable;
    try std.testing.expect(x == Selection.rock);

    const y = parseSelection('Y') catch unreachable;
    try std.testing.expect(y == Selection.paper);

    const z = parseSelection('Z') catch unreachable;
    try std.testing.expect(z == Selection.scissors);

    _ = parseSelection('W') catch |err| {
        try std.testing.expect(err == error.InvalidInput);
    };
}

const GameResult = enum(u32) {
    lose = 1,
    tie = 2,
    win = 3,
};

fn parseGameResult(code: u8) error{InvalidInput}!GameResult {
    return switch (code) {
        'X' => GameResult.lose,
        'Y' => GameResult.tie,
        'Z' => GameResult.win,
        else => error.InvalidInput,
    };
}

test "game result parsing" {
    const x = parseGameResult('X') catch unreachable;
    try std.testing.expect(x == GameResult.lose);

    const y = parseGameResult('Y') catch unreachable;
    try std.testing.expect(y == GameResult.tie);

    const z = parseGameResult('Z') catch unreachable;
    try std.testing.expect(z == GameResult.win);

    _ = parseGameResult('W') catch |err| {
        try std.testing.expect(err == error.InvalidInput);
    };
}

// get score for 'a', given opponent 'b'
fn getScore(a: Selection, b: Selection) u32 {
    var score: u32 = switch (a) {
        .rock => 1,
        .paper => 2,
        .scissors => 3,
    };

    score += switch (a) {
        .rock => switch (b) {
            .rock => 3,
            .paper => 0,
            .scissors => 6,
        },
        .paper => switch (b) {
            .rock => 6,
            .paper => 3,
            .scissors => 0,
        },
        .scissors => switch (b) {
            .rock => 0,
            .paper => 6,
            .scissors => 3,
        },
    };

    return score;
}

test "score calculation" {
    try std.testing.expect(getScore(Selection.paper, Selection.rock) == 8);
    try std.testing.expect(getScore(Selection.rock, Selection.paper) == 1);
    try std.testing.expect(getScore(Selection.scissors, Selection.scissors) == 6);
    try std.testing.expect(getScore(Selection.scissors, Selection.paper) == 9);
}

fn getPlayerChoice(opponent: Selection, result: GameResult) Selection {
    return switch (result) {
        .lose => switch (opponent) {
            .rock => .scissors,
            .paper => .rock,
            .scissors => .paper,
        },
        .tie => opponent,
        .win => switch (opponent) {
            .rock => .paper,
            .paper => .scissors,
            .scissors => .rock,
        },
    };
}

test "get player choice" {
    try std.testing.expect(getPlayerChoice(Selection.rock, GameResult.lose) == Selection.scissors);
    try std.testing.expect(getPlayerChoice(Selection.paper, GameResult.tie) == Selection.paper);
    try std.testing.expect(getPlayerChoice(Selection.scissors, GameResult.win) == Selection.rock);
}
