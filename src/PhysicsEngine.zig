const std = @import("std");
const at = @import("asciitecture");

pub const Collider = struct {
    id: u64,
    shape: at.math.Shape,
    velocity: at.math.Vec2,
    immovable: bool,
};

const PhysicsEngine = @This();

colliders: std.ArrayList(Collider),
gravity: at.math.Vec2,

pub fn init() PhysicsEngine {}
pub fn deinit() void {}
pub fn addObject() void {}
pub fn update() PhysicsEngine {}
