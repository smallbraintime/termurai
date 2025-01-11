const std = @import("std");
const at = @import("asciitecture");
const Collider = @import("PhysicsEngine.zig").Collider;

const Arena = @This();

const Object = struct {
    collider: Collider,
    style: at.style.Cell,
};

objects: std.ArrayList(Object),

pub fn init() Arena {}
pub fn deinit() Arena {}
