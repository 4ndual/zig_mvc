const std = @import("std");
const Server = @import("server/server.zig").Server;
const Database = @import("database/connection.zig").Database;
const DatabaseConfig = @import("config/database.zig").DatabaseConfig;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    // Initialize database configuration
    const db_config = DatabaseConfig{
        .path = "app.db",
    };

    // Initialize server with database
    var server = try Server.init(
        allocator,
        3668,
        db_config,
    );
    defer server.deinit();

    // Create initial database schema
    try server.db.exec(
        \\CREATE TABLE IF NOT EXISTS DOS (
        \\    id INTEGER PRIMARY KEY AUTOINCREMENT,
        \\    name TEXT NOT NULL,
        \\    email TEXT NOT NULL UNIQUE
        \\)
    , .{}, .{});

    try server.start();
}
