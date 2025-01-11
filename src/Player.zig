const std = @import("std");
const Collider = @import("PhysicsEngine.zig").Collider;
const at = @import("asciitecture");

const Player = @This();

collider: Collider,
animations: struct {
    sprites: std.ArrayList(at.sprite.Sprite),
    animations: std.ArrayList(at.sprite.Animation),
},

pub fn init() Player {}
pub fn deinit() void {}
pub fn update() void {}
