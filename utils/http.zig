const std = @import("std");

pub const Http = struct {
    pub const Method = enum {
        GET,
        POST,
        PUT,
    };

    pub fn parseMethod(method_str: []const u8) ?Method {
        if (std.mem.eql(u8, method_str, "GET")) {
            return Method.GET;
        } else if (std.mem.eql(u8, method_str, "POST")) {
            return Method.POST;
        } else if (std.mem.eql(u8, method_str, "PUT")) {
            return Method.PUT;
        } else {
            return null;
        }
    }

    pub fn sendJsonResponse(allocator: std.mem.Allocator, writer: anytype, content: []const u8) !void {
        const response = try std.fmt.allocPrint(allocator, "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: application/json\r\nContent-Length: {d}\r\n\r\n{s}", .{ content.len, content });
        defer allocator.free(response);

        try writer.writeAll(response);
        std.log.info("JSON Response sent successfully", .{});
    }

    pub fn sendHtmlResponse(allocator: std.mem.Allocator, writer: anytype, content: []const u8) !void {
        const response = try std.fmt.allocPrint(allocator, "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: text/html\r\nContent-Length: {d}\r\n\r\n{s}", .{ content.len, content });
        defer allocator.free(response);

        try writer.writeAll(response);
        std.log.info("Response sent successfully", .{});
    }
};
