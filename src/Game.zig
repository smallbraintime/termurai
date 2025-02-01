const std = @import("std");
const at = @import("asciitecture");
const Player = @import("Player.zig");
const Hud = @import("tui/Hud.zig");
const Menu = @import("tui/Menu.zig");
const TreeAssets = @import("assets.zig").TreeAssets;
const PlayerAssets = @import("assets.zig").PlayerAssets;

const Arena = std.ArrayList(at.math.Shape);

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
running: bool,
arena: Arena,
players: [2]Player,
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
        .emission_rate = 100 / 2,
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

    var term = try at.Terminal(at.LinuxTty).init(allocator, 60, .{ .height = 35, .width = 105 });
    term.setBg(.{ .rgb = .{ 238, 232, 213 } });

    const left = @as(f32, @floatFromInt(term._screen.buffer.size.width / 2)) * -1;
    const right = @as(f32, @floatFromInt(term._screen.buffer.size.width / 2));
    const top = @as(f32, @floatFromInt(term._screen.buffer.size.height / 2)) * -1;
    const bottom = @as(f32, @floatFromInt(term._screen.buffer.size.height / 2));

    const vleft = at.math.Shape{
        .line = .{
            .p1 = at.math.vec2(left, top),
            .p2 = at.math.vec2(left, bottom),
        },
    };

    const vright = at.math.Shape{
        .line = .{
            .p1 = at.math.vec2(right, top),
            .p2 = at.math.vec2(right, bottom),
        },
    };

    const htop = at.math.Shape{
        .line = .{
            .p1 = at.math.vec2(left, top),
            .p2 = at.math.vec2(right, top),
        },
    };

    const hbottom = at.math.Shape{
        .line = .{
            .p1 = at.math.vec2(left, bottom),
            .p2 = at.math.vec2(right, bottom),
        },
    };

    var arena = Arena.init(allocator);
    try arena.appendSlice(&[_]at.math.Shape{ vleft, vright, htop, hbottom });

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
        .arena = arena,
        .running = false,
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
}

pub fn run(self: *Game) !void {
    self.running = true;
    while (self.running) {
        if (self.input.contains(.escape)) self.running = false;
        if (self.input.contains(.up)) self.menu.previous();
        if (self.input.contains(.down)) self.menu.next();

        switch (self.menu.selected_item) {
            0 => {},
            1 => {},
            2 => self.running = false,
            else => unreachable,
        }

        const menu_pos = at.math.vec2(
            @as(f32, @floatFromInt(self.terminal._screen.buffer.size.width)) / 5,
            @as(f32, @floatFromInt(self.terminal._screen.buffer.size.height / 3)) * -1,
        );
        try self.menu.draw(&self.painter, &menu_pos);
        try self.terminal.draw();

        try self.tree.draw(&self.painter, &at.math.vec2(-50, -10));
        try self.tree_crown.draw(&self.painter, &at.math.vec2(-50, -10));
        self.blossom.draw(&self.painter, self.terminal.delta_time);

        self.fire.draw(&self.painter, self.terminal.delta_time);
        self.painter.setCell(&.{ .bg = at.style.IndexedColor.bright_black });
        self.painter.drawLine(&self.fire.config.pos.add(&at.math.vec2(-3, 0)), &self.fire.config.pos.add(&at.math.vec2(3, 0)));

        try at.sprite.spriteFromStr(PlayerAssets.PLAYER_RUN_LEFT_1, .{ .fg = .{ .rgb = .{ 102, 51, 153 } } }).draw(&self.painter, &at.math.vec2(6, 13));
        self.zzz.draw(&self.painter, self.terminal.delta_time);

        self.painter.setCell(&.{ .bg = .{ .rgb = .{ 133, 153, 0 } } });
        for (self.arena.items) |*shape| {
            self.painter.drawLineShape(&shape.line);
        }
    }
}

// pub fn run_match(self: *Game) void {}
