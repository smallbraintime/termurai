const std = @import("std");
const Game = @import("Game.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("memory leak occured");
    var game = try Game.init(gpa.allocator());
    defer game.deinit() catch unreachable;
    try game.run(gpa.allocator());
}
