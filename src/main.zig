const std = @import("std");
const asciitecture = @import("asciitecture");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("memory leak occured");

    var term = try asciitecture.Terminal(asciitecture.LinuxTty).init(gpa.allocator(), 60, .{ .height = 35, .width = 105 });
    defer term.deinit() catch |err| @panic(@errorName(err));

    var painter = term.painter();

    while (true) {
        painter.setCell(&.{ .bg = asciitecture.style.IndexedColor.white });
        painter.drawEllipse(&asciitecture.math.vec2(0, 0), 5, &asciitecture.math.vec2(0, 0.5), true);
        try term.draw();
    }
}
