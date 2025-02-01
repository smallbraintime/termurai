const std = @import("std");
const at = @import("asciitecture");

const Player = @This();

body_collider: at.math.Shape,
attack_collider: at.math.Shape,
velocity: at.math.Vec2,
jump_force: f32,
dash_force: f32,
health: u8,
run_right_anim: at.sprite.Animation,
run_left_anim: at.sprite.Animation,
idle_sprite: at.sprite.Sprite,
attack_effect: at.ParticleEmitter,
dash_effect: at.ParticleEmitter,

// pub fn init(allocator: std.mem.Allocator, color: at.style.Color) Player {}
//
// pub fn deinit(self: *Player) void {}
//
// pub fn update(delta_time: f32, input: *const at.input.Input) void {}
//
// pub fn draw(painter: *at.Painter) void {}
