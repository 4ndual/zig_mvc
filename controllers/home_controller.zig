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

    pub fn handleGetRequest(self: *HomeController, writer: anytype, path: []const u8) !void {
        if (std.mem.eql(u8, path, "/")) {
            const html_content = HomeView.render();
            try Http.sendHtmlResponse(self.allocator, writer, html_content);
        } else if (std.mem.eql(u8, path, "/about")) {
            const html_content = HomeView.render();
            try Http.sendHtmlResponse(self.allocator, writer, html_content);
        } else {
            const html_content = "404 Not Found";
            try Http.sendHtmlResponse(self.allocator, writer, html_content);
        }
    }

    pub fn handlePostRequest(self: *HomeController, writer: anytype, path: []const u8, body: ?[]const u8) !void {
        if (std.mem.eql(u8, path, "/submit")) {
            if (body) |data| {
                std.log.info("Received POST data: {s}", .{data});

                // const parsed = try std.json.parse(Struct, &std.json.TokenStream.init(data));

                const response_content = "{\"status\": \"success\", \"message\": \"POST data received!\"}";
                try Http.sendJsonResponse(self.allocator, writer, response_content);
            } else {
                const response_content = "{\"status\": \"error\", \"message\": \"No body received\"}";
                try Http.sendJsonResponse(self.allocator, writer, response_content);
            }
        } else {
            const response_content = "{\"status\": \"error\", \"message\": \"404 Not Found\"}";
            try Http.sendJsonResponse(self.allocator, writer, response_content);
        }
    }

    // pub fn handlePutRequest(self: *HomeController, writer: anytype, reader: anytype, path: []const u8) !void {
    //     if (std.mem.eql(u8, path, "/update")) {
    //         // Read the request body from the reader
    //         const body = try reader.readUntilDelimiterOrEofAlloc(self.allocator, '\n', 65536);
    //         defer self.allocator.free(body);

    //         // Handle update data
    //         const response_content = "PUT data received!";
    //         try Http.sendHtmlResponse(self.allocator, writer, response_content);
    //     } else {
    //         const html_content = "404 Not Found";
    //         try Http.sendHtmlResponse(self.allocator, writer, html_content);
    //     }
    // }
};
