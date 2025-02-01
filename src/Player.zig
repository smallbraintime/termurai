const std = @import("std");
const at = @import("asciitecture");
const PlayerAssets = @import("assets.zig").PlayerAssets;

const PlayerAnimation = enum {
    idle,
    run_right,
    run_left,
};

const Player = @This();

pos: at.math.Vec2,
velocity: at.math.Vec2,
speed: at.math.Vec2,
jump_force: f32,
dash_force: f32,
health: u8,
body_collider: at.math.Shape,
attack_collider: at.math.Shape,
graphics: struct {
    run_right_anim: at.sprite.Animation,
    run_left_anim: at.sprite.Animation,
    idle_sprite: at.sprite.Sprite,
    attack_effect: at.ParticleEmitter,
    dash_effect: at.ParticleEmitter,
},
current_anim: PlayerAnimation = .idle,
has_attacked: bool = false,
has_dashed: bool = false,

pub fn init(
    allocator: std.mem.Allocator,
    color: at.style.Color,
    attributes: struct {
        start_pos: at.math.Vec2,
        speed: at.math.Vec2,
        jump_force: f32,
        dash_force: f32,
        health: u8,
    },
) Player {
    var run_right_anim = at.sprite.Animation.init(allocator, 1, true);
    run_right_anim.frames.appendSlice(&[_][]const u8{
        &at.sprite.Sprite.init(PlayerAssets.PLAYER_RUN_RIGHT_1, .{ .fg = color }),
        &at.sprite.Sprite.init(PlayerAssets.PLAYER_RUN_RIGHT_2, .{ .fg = color }),
    });

    var run_left_anim = at.sprite.Animation.init(allocator, 1, true);
    run_left_anim.frames.appendSlice(&[_][]const u8{
        &at.sprite.Sprite.init(PlayerAssets.PLAYER_RUN_LEFT_1, .{ .fg = color }),
        &at.sprite.Sprite.init(PlayerAssets.PLAYER_RUN_LEFT_2, .{ .fg = color }),
    });

    const idle = at.sprite.Sprite.init(PlayerAssets.IDLE, .{ .fg = color });

    const dash_effect = try at.ParticleEmitter.init(allocator, .{
        .pos = attributes.start_pos,
        .amount = 100,
        .chars = null,
        .bg_color = null,
        .fg_color = .{
            .start = .{ .rgb = .{ 0, 0, 0 } },
            .end = .{ .rgb = .{ 255, 255, 255 } },
        },
        .color_var = 10,
        .start_angle = 0,
        .end_angle = 0,
        .life = 5,
        .life_var = 1,
        .speed = 4,
        .speed_var = 1,
        .emission_rate = 100 / 5,
        .gravity = at.math.vec2(0, 0),
        .duration = 10,
    });

    const attack_effect = try at.ParticleEmitter.init(allocator, .{
        .pos = attributes.start_pos,
        .amount = 100,
        .chars = &[_]u21{' '},
        .fg_color = null,
        .bg_color = .{
            .start = .{ .rgb = .{ 255, 102, 153 } },
            .end = .{ .rgb = .{ 255, 255, 255 } },
        },
        .color_var = 0,
        .start_angle = 0,
        .end_angle = 0,
        .life = 20,
        .life_var = 1,
        .speed = 2,
        .speed_var = 1,
        .emission_rate = 100 / 20,
        .gravity = at.math.vec2(0.5, 0),
        .duration = 5,
    });

    var width: f32 = 0;
    var height: f32 = 0;
    var width_counter = 0;
    inline for (PlayerAssets.IDLE) |c| {
        width_counter += 1;
        if (c == '\n') {
            height += 1;
            if (width_counter > width) width = width_counter;
            width_counter = 0;
        }
    }

    const body_collider = at.math.Shape{ .rectangle = .{
        .width = width,
        .height = height,
        .pos = attributes.start_pos,
    } };

    const attack_collider = at.math.Shape{ .rectangle = .{
        .width = width / 2,
        .height = height / 2,
        .pos = attributes.start_pos,
    } };

    return .{
        .pos = attributes.start_pos,
        .speed = attributes.speed,
        .jump_force = attributes.jump_force,
        .dash_force = attributes.dash_force,
        .health = attributes.health,
        .body_collider = body_collider,
        .attack_collider = attack_collider,
        .graphics = .{
            .run_right_anim = run_right_anim,
            .run_left_anim = run_left_anim,
            .idle_sprite = idle,
            .attack_effect = attack_effect,
            .dash_effect = dash_effect,
        },
    };
}

pub fn deinit(self: *Player) void {
    self.graphics.run_right_anim.deinit();
    self.graphics.run_left_anim.deinit();
    self.graphics.attack_effect.deinit();
    self.graphics.dash_effect.deinit();
}

pub fn run_right(self: *Player) void {
    self.velocity = self.velocity.add(&self.speed.x(), 0);
}

pub fn run_left(self: *Player) void {
    self.velocity = self.velocity.add(&-self.speed.x(), 0);
}

pub fn jump(self: *Player) void {
    self.velocity = self.velocity.add(0, self.jump_force);
}

pub fn dash(self: *Player) void {
    self.velocity = self.velocity.mul(2, 0);
    self.has_dashed = true;
}

pub fn attack(self: *Player, other: *Player) void {
    self.has_attacked = true;
    _ = other;
}

pub fn update(self: *Player, delta_time: f32) void {
    self.pos.add(&self.velocity.mulScalar(delta_time));
}

pub fn draw(self: *Player, painter: *at.Painter, delta_time: f32) void {
    switch (self.current_anim) {
        .idle => self.graphics.idle_sprite.draw(painter, &self.pos),
        .run_left => self.graphics.run_left_anim.draw(painter, &self.pos, delta_time),
        .run_right => self.graphics.run_right_anim.draw(painter, &self.pos, delta_time),
    }

    // toogle booleans and normalize velocity if duration has elapsed (update asciitecture)
    self.graphics.dash_effect.draw(painter, delta_time);
    self.graphics.attack_effect.draw(painter, delta_time);
    if (self.dashed) self.graphics.dash_effect.config.duration = 10;
    if (self.attacked) self.graphics.dash_effect.config.duration = 5;
}
