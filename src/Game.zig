const std = @import("std");
const at = @import("asciitecture");
const Player = @import("Player.zig");
const Arena = @import("Arena.zig");

const Game = @This();

players: [2]Player,
arena: Arena,
colliders: std.ArrayList(at.math.Shape),

pub fn init() Game {}

pub fn run() void {}
