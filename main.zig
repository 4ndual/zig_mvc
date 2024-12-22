const std = @import("std");
const Server = @import("server/server.zig").Server;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var server = try Server.init(allocator, 3668);
    defer server.deinit();

    try server.start();
}
