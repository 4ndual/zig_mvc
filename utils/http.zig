const std = @import("std");

pub const Http = struct {
    pub fn sendHtmlResponse(allocator: std.mem.Allocator, writer: anytype, content: []const u8) !void {
        const response = try std.fmt.allocPrint(allocator, "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: text/html\r\nContent-Length: {d}\r\n\r\n{s}", .{ content.len, content });
        defer allocator.free(response);

        try writer.writeAll(response);
        std.log.info("Response sent successfully", .{});
    }
};
