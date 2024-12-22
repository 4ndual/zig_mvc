const std = @import("std");
const HomeController = @import("../controllers/home_controller.zig").HomeController;

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

        // Read the HTTP request
        const request = try reader.readUntilDelimiterOrEofAlloc(self.allocator, '\n', 65536) orelse return error.EmptyRequest;
        defer self.allocator.free(request);

        // Log the request
        std.log.info("Received request: {s}", .{request});

        // Handle the request
        try self.home_controller.handleRequest(writer);
    }
};
