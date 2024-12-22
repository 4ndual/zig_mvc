// src/config/config_test.zig
const std = @import("std");
const testing = std.testing;
const Config = @import("config.zig").Config;

// Helper function to create/manage .env file
fn setupTestEnvFile(content: []const u8) !void {
    const test_env_path = ".env";

    // Create new .env file
    const file = try std.fs.cwd().createFile(test_env_path, .{});
    defer file.close();
    try file.writeAll(content);
}

fn cleanupTestEnvFile() void {
    // Remove test env file
    std.fs.cwd().deleteFile(".env") catch {};
}

test "Load from .env file" {
    const allocator = testing.allocator;

    // Setup test env content with the current timestamp
    const env_content = try std.fmt.allocPrint(allocator,
        \\PORT=8080
        \\HOST=0.0.0.0
        \\MAX_CONNECTIONS=2000
        \\# Test configuration created at {d}
        \\# Test user: {s}
    , .{ std.time.timestamp(), "4ndual" });
    defer allocator.free(env_content);

    // Create test env file
    try setupTestEnvFile(allocator, env_content);
    defer cleanupTestEnvFile();

    // Test loading configuration
    var config = try Config.loadFromEnvFile(allocator, ".env");
    defer config.deinit(allocator);

    try testing.expectEqual(@as(u16, 8080), config.port);
    try testing.expectEqualStrings("0.0.0.0", config.host);
    try testing.expectEqual(@as(u32, 2000), config.max_connections);
}

test "Missing .env file should error" {
    const allocator = testing.allocator;

    // Ensure .env doesn't exist
    cleanupTestEnvFile();

    try testing.expectError(error.FileNotFound, Config.loadFromEnvFile(allocator, ".env"));
}

test "Invalid values in .env file" {
    const allocator = testing.allocator;

    // Setup test env with invalid values
    const invalid_env_content =
        \\PORT=invalid_port
        \\HOST=0.0.0.0
        \\MAX_CONNECTIONS=not_a_number
    ;

    try setupTestEnvFile(allocator, invalid_env_content);
    defer cleanupTestEnvFile();

    // Should return error for invalid port
    try testing.expectError(error.InvalidCharacter, Config.loadFromEnvFile(allocator, ".env"));
}

test "Partial configuration in .env" {
    const allocator = testing.allocator;

    // Setup test env with only some values
    const partial_env_content =
        \\PORT=9090
        \\# Other values missing
    ;

    try setupTestEnvFile(allocator, partial_env_content);
    defer cleanupTestEnvFile();

    var config = try Config.loadFromEnvFile(allocator, ".env");
    defer config.deinit(allocator);

    // Should use provided value for PORT
    try testing.expectEqual(@as(u16, 9090), config.port);
    // Should use defaults for missing values
    try testing.expectEqualStrings(Config.default.host, config.host);
    try testing.expectEqual(Config.default.max_connections, config.max_connections);
}
