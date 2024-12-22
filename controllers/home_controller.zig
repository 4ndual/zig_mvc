const std = @import("std");
const HomeView = @import("../views/home.zig").HomeView;
const Http = @import("../utils/http.zig").Http;

pub const HomeController = struct {
    allocator: std.mem.Allocator,
    view: HomeView,

    pub fn init(allocator: std.mem.Allocator) HomeController {
        return .{
            .allocator = allocator,
            .view = HomeView.init(),
        };
    }

    pub fn handleRequest(self: *HomeController, writer: anytype) !void {
        const html_content = HomeView.render();
        try Http.sendHtmlResponse(self.allocator, writer, html_content);
    }
};
