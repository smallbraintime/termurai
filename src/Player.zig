const std = @import("std");
const at = @import("asciitecture");
const PlayerAssets = @import("assets.zig").PlayerAssets;
const Arena = @import("Game.zig").Arena;

const PlayerAnimation = enum {
    idle,
    run_right,
    run_left,
};

const Player = @This();

// config
movement_speed: f32,
jump_height: f32,
dash_speed: f32,
dash_duration: f32,
dash_cooldown: f32,
max_health: u8,

// state
pos: at.math.Vec2,
velocity: at.math.Vec2,
current_anim: PlayerAnimation = .idle,
has_attacked: bool = false,
is_grounded: bool = false,
is_dashing: bool = false,
timer: f32 = 0,
health: u8,
body_collider: at.math.Shape,
attack_collider: at.math.Shape,

// assets
assets: struct {
    run_right_anim: at.sprite.Animation,
    run_left_anim: at.sprite.Animation,
    idle_sprite: at.sprite.Sprite,
    attack_effect: at.ParticleEmitter,
    dash_effect: at.ParticleEmitter,
    // sprites: [4]at.sprite.Sprite,
},

pub fn init(
    allocator: std.mem.Allocator,
    color: at.style.Color,
    attributes: struct {
        start_pos: at.math.Vec2,
        movement_speed: f32,
        jump_height: f32,
        dash_speed: f32,
        dash_duration: f32,
        dash_cooldown: f32,
        max_health: u8,
    },
    sprites: []const at.sprite.Sprite,
) !Player {
    var run_right_anim = at.sprite.Animation.init(allocator, 1, true);
    try run_right_anim.frames.append(&sprites[0]);
    try run_right_anim.frames.append(&sprites[1]);
    var run_left_anim = at.sprite.Animation.init(allocator, 1, true);
    try run_left_anim.frames.append(&sprites[2]);
    try run_left_anim.frames.append(&sprites[3]);

    const idle = at.sprite.Sprite.init(PlayerAssets.IDLE, .{ .fg = color });

    const dash_effect = try at.ParticleEmitter.init(allocator, .{
        .pos = attributes.start_pos,
        .amount = 100,
        .chars = null,
        .bg_color = null,
        .fg_color = .{
            .start = .{ .rgb = .{ 50, 50, 50 } },
            .end = .{ .rgb = .{ 150, 150, 150 } },
        },
        .color_var = 100,
        .start_angle = 0,
        .end_angle = 0,
        .life = 3,
        .life_var = 1,
        .speed = 40,
        .speed_var = 3,
        .emission_rate = 100 / 3,
        .gravity = at.math.vec2(0, 0),
        .duration = 0,
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

    const size = comptime try calc_sprite_dims(PlayerAssets.IDLE);

    const body_collider = at.math.Shape{ .rectangle = .{
        .width = size.width,
        .height = size.height,
        .pos = attributes.start_pos,
    } };

    const attack_collider = at.math.Shape{ .rectangle = .{
        .width = size.width / 2,
        .height = size.height / 2,
        .pos = attributes.start_pos,
    } };

    return .{
        .movement_speed = attributes.movement_speed,
        .jump_height = attributes.jump_height,
        .dash_speed = attributes.dash_speed,
        .dash_duration = attributes.dash_duration,
        .dash_cooldown = attributes.dash_cooldown,
        .max_health = attributes.max_health,

        .pos = attributes.start_pos,
        .velocity = at.math.vec2(0, 0),
        .health = attributes.max_health,
        .body_collider = body_collider,
        .attack_collider = attack_collider,

        .assets = .{
            .run_right_anim = run_right_anim,
            .run_left_anim = run_left_anim,
            .idle_sprite = idle,
            .attack_effect = attack_effect,
            .dash_effect = dash_effect,
            // .sprites = sprites,
        },
    };
}

pub fn deinit(self: *Player) void {
    self.assets.run_right_anim.deinit();
    self.assets.run_left_anim.deinit();
    self.assets.attack_effect.deinit();
    self.assets.dash_effect.deinit();
}

pub fn draw(self: *Player, painter: *at.Painter, delta_time: f32) !void {
    switch (self.current_anim) {
        .idle => try self.assets.idle_sprite.draw(painter, &self.pos),
        .run_left => try self.assets.run_left_anim.draw(painter, &self.pos, delta_time),
        .run_right => try self.assets.run_right_anim.draw(painter, &self.pos, delta_time),
    }

    // self.assets.dash_effect.draw(painter, delta_time);

    // toogle booleans and normalize velocity if duration has elapsed (update asciitecture) or just draw within specific amount of time
    // self.assets.dash_effect.draw(painter, delta_time);
    // self.assets.attack_effect.draw(painter, delta_time);
    // if (self.dashed) self.assets.dash_effect.config.duration = 10;
    // if (self.attacked) self.assets.dash_effect.config.duration = 5;
}

pub fn update(self: *Player, input: *at.input.Input, arena: *Arena, gravity: *at.math.Vec2, delta_time: f32) void {
    self.handleInput(input);
    self.updateGravity(gravity, delta_time);
    self.applyMovement(delta_time);
    self.resolveCollisions(arena);
}

fn handleInput(self: *Player, input: *at.input.Input) void {
    if (input.contains(.left) and !self.is_dashing) self.run_left();
    if (input.contains(.right) and !self.is_dashing) self.run_right();
    if (!input.contains(.left) and !input.contains(.right) and !self.is_dashing) self.stop();
    if (input.contains(.c)) self.jump();
    if (input.contains(.x)) self.dash();
    // if (input.contains(.x)) self.attack(other: *Player)
}

fn updateGravity(self: *Player, gravity: *at.math.Vec2, delta_time: f32) void {
    if (!self.is_grounded) {
        self.velocity.v[1] += gravity.y() * delta_time;
    }
}

fn applyMovement(self: *Player, delta_time: f32) void {
    if (self.is_dashing) {
        self.velocity.v[0] = self.velocity.x() * self.dash_speed;

        if (self.velocity.x() > 0) {
            self.assets.dash_effect.config.start_angle = 340;
            self.assets.dash_effect.config.end_angle = 380;
        } else {
            self.assets.dash_effect.config.start_angle = 160;
            self.assets.dash_effect.config.end_angle = 200;
        }

        self.timer += delta_time;
        if (self.timer >= self.dash_duration) {
            self.velocity.v[0] = 0;
            self.timer = 0;
            self.is_dashing = false;
            self.timer = self.dash_cooldown;
        }
    } else {
        if (self.timer <= 0) {
            self.timer = 0;
        } else {
            self.timer -= delta_time;
        }
    }

    self.pos = self.pos.add(&self.velocity.mulScalar(delta_time));
    self.body_collider.rectangle.pos = self.pos;
    self.assets.dash_effect.config.pos = self.pos;
}

fn resolveCollisions(self: *Player, arena: *Arena) void {
    for (arena.items) |*collider| {
        switch (collider.*) {
            .rectangle => |*rec| {
                if (self.body_collider.rectangle.collidesWith(collider)) {
                    const player_right = self.pos.x() + self.body_collider.rectangle.width;
                    const player_bottom = self.pos.y() + self.body_collider.rectangle.height;
                    const rec_right = rec.pos.x() + rec.width;
                    const rec_bottom = rec.pos.y() + rec.height;

                    if (player_right > rec.pos.x() and self.pos.x() < rec.pos.x()) {
                        self.pos.v[0] = rec.pos.x() - self.body_collider.rectangle.width;
                    }
                    if (self.pos.x() < rec_right and player_right > rec_right) {
                        self.pos.v[0] = rec_right;
                    }
                    if (self.pos.y() < rec_bottom and player_bottom > rec_bottom) {
                        self.pos.v[1] = rec_bottom;
                    }
                    if (player_bottom > rec.pos.y() and self.pos.y() < rec.pos.y()) {
                        self.pos.v[1] = rec.pos.y() - self.body_collider.rectangle.height;
                        self.is_grounded = true;
                    }
                }
            },
            else => unreachable,
        }
    }
}

pub fn run_right(self: *Player) void {
    self.velocity.v[0] = self.movement_speed;
    self.current_anim = .run_right;
}

pub fn run_left(self: *Player) void {
    self.velocity.v[0] = -self.movement_speed;
    self.current_anim = .run_left;
}

pub fn stop(self: *Player) void {
    self.velocity.v[0] = 0;
    self.current_anim = .idle;
}

pub fn jump(self: *Player) void {
    if (self.is_grounded) {
        self.velocity.v[1] = -self.jump_height;
        self.is_grounded = false;
    }
}

pub fn dash(self: *Player) void {
    if (!self.is_dashing and self.timer <= 0) {
        self.is_dashing = true;
        self.velocity.v[0] = self.velocity.x() * self.dash_speed;
    }
}

pub fn attack(self: *Player, other: *Player) void {
    self.has_attacked = true;
    _ = other;
}

fn calc_sprite_dims(sprite: []const u8) !struct { width: f32, height: f32 } {
    var width: f32 = 0;
    var height: f32 = 1;
    var width_counter: f32 = 0;

    //this should be the part of Sprite struct
    const view = try std.unicode.Utf8View.init(sprite);
    var iter = view.iterator();
    while (iter.nextCodepoint()) |c| {
        if (c == '\n') {
            height += 1.0;
            if (width_counter > width) width = width_counter;
            width_counter = 0;
        } else {
            width_counter += 1.0;
        }
    }

    if (width_counter > width) width = width_counter;

    return .{ .width = width, .height = height };
}
