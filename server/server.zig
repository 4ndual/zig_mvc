const std = @import("std");
const GenericController = @import("../controllers/generic_controller.zig").GenericController;
const Http = @import("../utils/http.zig").Http;
const DatabaseConfig = @import("../config/database.zig").DatabaseConfig;
const Database = @import("../database/connection.zig");
const sqlite = @import("sqlite");

pub const Server = struct {
    allocator: std.mem.Allocator,
    port: u16,
    server: std.net.Server,
    generic_controller: GenericController,
    db: sqlite.Db,

    pub fn init(allocator: std.mem.Allocator, port: u16, db_config: DatabaseConfig) !Server {
        const addr = std.net.Address.initIp4(.{ 0, 0, 0, 0 }, port);
        var db = try Database.init(db_config.path);
        const server = try addr.listen(.{});

        return Server{
            .allocator = allocator,
            .port = port,
            .server = server,
            .generic_controller = GenericController.init(allocator, &db),
            .db = db,
        };
    }

    pub fn deinit(self: *Server) void {
        std.debug.print("[{s}] Server.deinit called from:\n", .{"2025-01-20 13:37:45"});
        std.debug.dumpCurrentStackTrace(@returnAddress());
        self.server.deinit();
        self.db.deinit();
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

        // Read the HTTP request line
        const request_line = try reader.readUntilDelimiterOrEofAlloc(self.allocator, '\n', 65536) orelse return error.EmptyRequest;
        defer self.allocator.free(request_line);

        // Parse the request line
        var tokens = std.mem.split(u8, request_line, " ");
        const method_str = tokens.next() orelse return error.InvalidRequest;
        const path = tokens.next() orelse return error.InvalidRequest;

        const method = Http.parseMethod(method_str) orelse return error.InvalidMethod;

        // Read headers
        var content_length: usize = 0;
        while (true) {
            const header_line = try reader.readUntilDelimiterOrEofAlloc(self.allocator, '\n', 65536) orelse break;
            defer self.allocator.free(header_line);

            const trimmed_line = std.mem.trim(u8, header_line, "\r\n");
            if (trimmed_line.len == 0) break; // Empty line indicates end of headers

            // Parse Content-Length header
            if (std.ascii.startsWithIgnoreCase(trimmed_line, "Content-Length:")) {
                const len_str = std.mem.trim(u8, trimmed_line["Content-Length:".len..], " \t");
                content_length = try std.fmt.parseInt(usize, len_str, 10);
            }
        }

        // Read body if present
        var body: ?[]u8 = null;
        defer if (body) |b| self.allocator.free(b);

        if (content_length > 0) {
            body = try self.allocator.alloc(u8, content_length);
            const bytes_read = try reader.readAll(body.?);
            if (bytes_read != content_length) {
                return error.InvalidBodyLength;
            }
        }

        // Handle the request based on the method
        switch (method) {
            Http.Method.GET => {
                try self.generic_controller.handleGetRequest(writer, path);
            },
            Http.Method.POST => {
                try self.generic_controller.handlePostRequest(writer, path, body);
            },
            Http.Method.PUT => {
                try self.generic_controller.handlePutRequest(writer, path, body);
            },
        }
    }
};
