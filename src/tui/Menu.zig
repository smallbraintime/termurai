const std = @import("std");
const at = @import("asciitecture");

const Menu = @This();

main_menu: at.widgets.Menu,
text_area: at.widgets.TextArea,

pub fn init(allocator: std.mem.Allocator) Menu {
    const menu_config = at.widgets.Menu.MenuConfig{};
    const textarea_config = at.widgets.TextArea.TextAreaConfig{};

    var main_menu = at.widgets.Menu.init(allocator, menu_config);
    main_menu.items.appendSlice(.{ "play", "controls", "exit" });

    return .{
        .main_menu = main_menu,
        .text_area = at.widgets.TextArea.init(allocator, textarea_config),
    };
}

pub fn deinit(self: *Menu) void {
    self.main_menu.deinit();
    self.text_area.deinit();
}

pub fn update() void {}

pub fn draw(self: *Menu, painter: *at.Painter, pos: *const at.math.Vec2) void {
    self.main_menu.draw(painter, pos);
}
