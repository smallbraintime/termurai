const std = @import("std");
const at = @import("asciitecture");
const Player = @import("Player.zig");
const Hud = @import("tui/Hud.zig");
const Menu = @import("tui/Menu.zig");
const TreeAssets = @import("assets.zig").TreeAssets;
const PlayerAssets = @import("assets.zig").PlayerAssets;

pub const Arena = std.ArrayList(at.math.Shape);

const Game = @This();

terminal: at.Terminal(at.LinuxTty),
painter: at.Painter,
input: at.input.Input,
menu: at.widgets.Menu,
tree: at.sprite.Sprite,
tree_crown: at.sprite.Sprite,
fire: at.ParticleEmitter,
blossom: at.ParticleEmitter,
zzz: at.ParticleEmitter,
bubble: at.widgets.Paragraph,
menu_running: bool = false,
match_running: bool = false,
arena: Arena,
players: ?[2]Player,
gravity: at.math.Vec2,
// hud: Hud,

pub fn init(allocator: std.mem.Allocator) !Game {
    const menu_config = at.widgets.Menu.MenuConfig{
        .width = 30,
        .height = 21,
        .orientation = .vertical,
        .padding = 1,
        .border = .{
            .border = .rounded,
            .style = .{
                .fg = .{ .rgb = .{ 101, 123, 131 } },
            },
            .filling = false,
        },
        .element = .{
            .style = .{
                .fg = .{ .rgb = .{ 101, 123, 131 } },
            },
            .filling = false,
        },
        .selection = .{
            .element_style = .{
                .fg = .{ .rgb = .{ 203, 75, 22 } },
            },
            .text_style = .{
                .fg = .{ .rgb = .{ 203, 75, 22 } },
                .attr = .bold,
            },
            .filling = false,
        },
        .text_style = .{
            .fg = .{ .rgb = .{ 101, 123, 131 } },
        },
    };
    var main_menu = at.widgets.Menu.init(allocator, menu_config);
    try main_menu.items.appendSlice(&[_][]const u8{ "play", "controls", "exit" });

    const fire = try at.ParticleEmitter.init(allocator, .{
        .pos = at.math.vec2(0, 16),
        .amount = 100,
        .chars = &[_]u21{' '},
        .fg_color = null,
        .bg_color = .{
            .start = .{ .rgb = .{ 190, 60, 30 } },
            .end = .{ .rgb = .{ 50, 50, 50 } },
        },
        .color_var = 0,
        .start_angle = 30,
        .end_angle = 150,
        .life = 1,
        .life_var = 1,
        .speed = 5,
        .speed_var = 2,
        .emission_rate = 100 / 1,
        .gravity = at.math.vec2(0, 0),
        .duration = std.math.inf(f32),
    });

    const blossom = try at.ParticleEmitter.init(allocator, .{
        .pos = at.math.vec2(-25, -8),
        .amount = 100,
        .chars = &[_]u21{' '},
        .fg_color = null,
        .bg_color = .{
            .start = .{ .rgb = .{ 255, 102, 153 } },
            .end = .{ .rgb = .{ 255, 255, 255 } },
        },
        .color_var = 0,
        .start_angle = 240,
        .end_angle = 360,
        .life = 20,
        .life_var = 1,
        .speed = 2,
        .speed_var = 1,
        .emission_rate = 100 / 20,
        .gravity = at.math.vec2(0.5, 0),
        .duration = std.math.inf(f32),
    });

    const zzz = try at.ParticleEmitter.init(allocator, .{
        .pos = at.math.vec2(8, 12),
        .amount = 10,
        .chars = &[_]u21{ 'Z', 'z' },
        .bg_color = null,
        .fg_color = .{
            .start = .{ .rgb = .{ 0, 0, 0 } },
            .end = .{ .rgb = .{ 255, 255, 255 } },
        },
        .color_var = 0,
        .start_angle = 60,
        .end_angle = 120,
        .life = 4,
        .life_var = 0,
        .speed = 0.5,
        .speed_var = 0,
        .emission_rate = 10 / 4,
        .gravity = at.math.vec2(0, 0),
        .duration = std.math.inf(f32),
    });

    const bubble = try at.widgets.Paragraph.init(
        allocator,
        &[_][]const u8{ "[->] - right", "[<-] - left", "[c] - jump", "[x] - dash" },
        .{
            .border_style = .{
                .border = .rounded,
                .style = .{
                    .fg = .{ .rgb = .{ 101, 123, 131 } },
                    .attr = .bold,
                },
            },
            .text_style = .{
                .fg = .{ .rgb = .{ 101, 123, 131 } },
                .attr = .bold,
            },
            .filling = true,
            .animation = .{
                .speed = 10,
                .looping = false,
            },
        },
    );

    var term = try at.Terminal(at.LinuxTty).init(allocator, 60, .{ .height = 35, .width = 105 });
    term.setBg(.{ .rgb = .{ 238, 232, 213 } });

    var arena = Arena.init(allocator);
    try load_walls(&arena, @floatFromInt(term._screen.buffer.size.width), @floatFromInt(term._screen.buffer.size.height));

    return .{
        .terminal = term,
        .painter = term.painter(),
        .input = try at.input.Input.init(),
        .menu = main_menu,
        .tree = at.sprite.spriteFromStr(TreeAssets.TREE, .{
            .bg = .{ .rgb = .{ 150, 75, 0 } },
            .fg = .{ .rgb = .{ 150, 75, 0 } },
        }),
        .tree_crown = at.sprite.spriteFromStr(TreeAssets.TREE_CROWN, .{
            .bg = .{ .rgb = .{ 255, 102, 153 } },
            .fg = .{ .rgb = .{ 255, 102, 153 } },
        }),
        .fire = fire,
        .blossom = blossom,
        .zzz = zzz,
        .bubble = bubble,
        .arena = arena,
        .players = null,
        .gravity = at.math.vec2(0, 30),
    };
}

pub fn deinit(self: *Game) !void {
    self.menu.deinit();
    try self.input.deinit();
    try self.terminal.deinit();
    self.fire.deinit();
    self.blossom.deinit();
    self.zzz.deinit();
    self.arena.deinit();
    self.bubble.deinit();
    // for (&self.players) |*player| player.deinit();
}

pub fn run(self: *Game, allocator: std.mem.Allocator) !void {
    self.menu_running = true;

    var should_zzz = true;
    while (self.menu_running) {
        if (self.input.nextEvent()) |key| {
            switch (key.key) {
                .enter => {
                    if (self.menu.selected_item == 0) try self.run_match(allocator);
                    if (self.menu.selected_item == 2) self.menu_running = false;
                },
                .down => self.menu.next(),
                .up => self.menu.previous(),
                .escape => self.menu_running = false,
                else => {},
            }
        }
        const menu_pos = at.math.vec2(
            @as(f32, @floatFromInt(self.terminal._screen.buffer.size.width)) / 5,
            @as(f32, @floatFromInt(self.terminal._screen.buffer.size.height / 3)) * -1,
        );
        try self.menu.draw(&self.painter, &menu_pos);

        try self.tree.draw(&self.painter, &at.math.vec2(-50, -10));
        try self.tree_crown.draw(&self.painter, &at.math.vec2(-50, -10));
        self.blossom.draw(&self.painter, self.terminal.delta_time);

        self.fire.draw(&self.painter, self.terminal.delta_time);
        self.painter.setCell(&.{ .bg = at.style.IndexedColor.bright_black });
        self.painter.drawLine(&self.fire.config.pos.add(&at.math.vec2(-3, 0)), &self.fire.config.pos.add(&at.math.vec2(3, 0)));

        try at.sprite.spriteFromStr(PlayerAssets.IDLE, .{ .fg = .{ .rgb = .{ 102, 51, 153 } } }).draw(&self.painter, &at.math.vec2(6, 13));
        if (should_zzz) self.zzz.draw(&self.painter, self.terminal.delta_time);

        self.painter.setCell(&.{ .bg = .{ .rgb = .{ 133, 153, 0 } } });
        for (self.arena.items) |*shape| {
            self.painter.drawRectangleShape(&shape.rectangle, true);
        }

        if (self.menu.selected_item != 1) {
            should_zzz = true;
            self.bubble.reset();
        }

        switch (self.menu.selected_item) {
            0 => {},
            1 => {
                try self.bubble.draw(&self.painter, &at.math.vec2(5, 7), self.terminal.delta_time);
                should_zzz = false;
            },
            else => {},
        }

        try self.terminal.draw();
    }
}

fn run_match(self: *Game, allocator: std.mem.Allocator) !void {
    const sprites = .{
        at.sprite.Sprite.init(PlayerAssets.PLAYER_RUN_RIGHT_1, .{ .fg = at.style.IndexedColor.black }),
        at.sprite.Sprite.init(PlayerAssets.PLAYER_RUN_RIGHT_2, .{ .fg = at.style.IndexedColor.black }),
        at.sprite.Sprite.init(PlayerAssets.PLAYER_RUN_LEFT_1, .{ .fg = at.style.IndexedColor.black }),
        at.sprite.Sprite.init(PlayerAssets.PLAYER_RUN_LEFT_2, .{ .fg = at.style.IndexedColor.black }),
    };

    const player1 = try Player.init(allocator, at.style.IndexedColor.black, .{
        .start_pos = at.math.vec2(6, 13),
        .movement_speed = 20,
        .jump_height = 30,
        .dash_speed = 2,
        .dash_duration = 0.09,
        .dash_cooldown = 0.7,
        .max_health = 3,
    }, &sprites);

    self.players = .{ player1, undefined };
    defer self.players.?[0].deinit();

    self.match_running = true;
    while (self.match_running) {
        if (self.input.contains(.escape)) self.match_running = false;

        self.players.?[0].update(&self.input, &self.arena, &self.gravity, self.terminal.delta_time);

        try self.tree.draw(&self.painter, &at.math.vec2(-50, -10));
        try self.tree_crown.draw(&self.painter, &at.math.vec2(-50, -10));
        self.blossom.draw(&self.painter, self.terminal.delta_time);

        try self.players.?[0].draw(&self.painter, self.terminal.delta_time);

        self.painter.setCell(&.{ .bg = .{ .rgb = .{ 133, 153, 0 } } });
        for (self.arena.items) |*shape| {
            self.painter.drawRectangleShape(&shape.rectangle, false);
        }

        try self.terminal.draw();
    }
}

fn load_walls(arena: *Arena, width: f32, height: f32) !void {
    const left = (@floor(width) / -2) + 0.5;
    const right = (@floor(width) / 2) - 0.5;
    const top = (@floor(height) / -2) + 0.5;
    const bottom = (@floor(height) / 2) - 0.5;

    const vleft = at.math.Shape{
        .rectangle = .{
            .pos = at.math.vec2(left, top),
            .width = 1,
            .height = height,
        },
    };

    const vright = at.math.Shape{
        .rectangle = .{
            .pos = at.math.vec2(right, top),
            .width = 1,
            .height = height,
        },
    };

    const htop = at.math.Shape{
        .rectangle = .{
            .pos = at.math.vec2(left, top),
            .width = width,
            .height = 1,
        },
    };

    const hbottom = at.math.Shape{
        .rectangle = .{
            .pos = at.math.vec2(left, bottom),
            .width = width,
            .height = 1,
        },
    };

    const lplatform = at.math.Shape{
        .rectangle = .{
            .pos = at.math.vec2(@floor(width / 4), @floor(height / 4)),
            .width = 15,
            .height = 1,
        },
    };

    const rplatform = at.math.Shape{
        .rectangle = .{
            .pos = at.math.vec2(@floor(-width / 4) - 15, @floor(height / 4)),
            .width = 15,
            .height = 1,
        },
    };

    try arena.appendSlice(&[_]at.math.Shape{
        vleft,
        vright,
        htop,
        hbottom,
        lplatform,
        rplatform,
    });
}
