const std = @import("std");
const HomeController = @import("../controllers/home_controller.zig").HomeController;
const Http = @import("../utils/http.zig").Http;

pub const Server = struct {
    allocator: std.mem.Allocator,
    port: u16,
    server: std.net.Server,
    home_controller: HomeController,

    pub fn init(allocator: std.mem.Allocator, port: u16) !Server {
        const addr = std.net.Address.initIp4(.{ 0, 0, 0, 0 }, port);
        const server = try addr.listen(.{});

        return Server{
            .allocator = allocator,
            .port = port,
            .server = server,
            .home_controller = HomeController.init(allocator),
        };
    }

    pub fn deinit(self: *Server) void {
        self.server.stream.close();
    }

    pub fn start(self: *Server) !void {
        std.log.info("Server listening on port {d}", .{self.port});

        while (true) {
            var client = try self.server.accept();
            defer client.stream.close();

            // Handle a single request and then close the connection
            if (self.handleClient(client)) |_| {
                std.log.info("Request handled successfully", .{});
            } else |err| {
                // Log the error but don't crash the server
                std.log.err("Error handling client: {}", .{err});
            }
        }
    }

    fn handleClient(self: *Server, client: std.net.Server.Connection) !void {
        const reader = client.stream.reader();
        const writer = client.stream.writer();

        // Read the HTTP request line (method, path, and version)
        const request_line = try reader.readUntilDelimiterOrEofAlloc(self.allocator, '\n', 65536) orelse return error.EmptyRequest;
        defer self.allocator.free(request_line);

        // Log the request line
        std.log.info("Received request line: {s}", .{request_line});

        // Parse the request line
        var tokens = std.mem.split(u8, request_line, " ");
        const method_str = tokens.next() orelse return error.InvalidRequest;
        const path = tokens.next() orelse return error.InvalidRequest;

        const method = Http.parseMethod(method_str) orelse return error.InvalidMethod;

        // Handle the request based on the method
        switch (method) {
            Http.Method.GET => {
                try self.home_controller.handleGetRequest(writer, path);
            },
            Http.Method.POST => {
                try self.home_controller.handlePostRequest(writer, path);
            },
            // Http.Method.PUT => {
            //     try self.home_controller.handlePutRequest(writer, reader, path);
            // },
        }
    }
};
