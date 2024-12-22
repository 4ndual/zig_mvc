// src/config/config.zig
const std = @import("std");

pub const Config = struct {
    port: u16,
    host: []const u8,
    max_connections: u32,

    // Add defaults
    pub const default = Config{
        .port = 3668,
        .host = "127.0.0.1",
        .max_connections = 1000,
    };

    pub fn loadFromEnvFile(allocator: std.mem.Allocator, filepath: []const u8) !Config {
        const file = try std.fs.cwd().openFile(filepath, .{});
        defer file.close();

        const content = try file.readToEndAlloc(allocator, 1024 * 1024);
        defer allocator.free(content);

        var config = Config.default;

        var lines = std.mem.split(u8, content, "\n");
        while (lines.next()) |line| {
            var tokens = std.mem.split(u8, line, "=");
            const key = tokens.next() orelse continue;
            const value = tokens.next() orelse continue;

            if (std.mem.eql(u8, std.mem.trim(u8, key, " "), "PORT")) {
                config.port = try std.fmt.parseInt(u16, std.mem.trim(u8, value, " \r"), 10);
            } else if (std.mem.eql(u8, std.mem.trim(u8, key, " "), "HOST")) {
                config.host = try allocator.dupe(u8, std.mem.trim(u8, value, " \r"));
            } else if (std.mem.eql(u8, std.mem.trim(u8, key, " "), "MAX_CONNECTIONS")) {
                config.max_connections = try std.fmt.parseInt(u32, std.mem.trim(u8, value, " \r"), 10);
            }
        }

        return config;
    }

    pub fn loadFromJson(allocator: std.mem.Allocator, filepath: []const u8) !Config {
        const file = try std.fs.cwd().openFile(filepath, .{});
        defer file.close();

        const content = try file.readToEndAlloc(allocator, 1024 * 1024);
        defer allocator.free(content);

        var parser = std.json.Parser.init(allocator, false);
        defer parser.deinit();

        var tree = try parser.parse(content);
        defer tree.deinit();

        const root = tree.root.Object;

        return Config{
            .port = @intCast(root.get("port").?.Integer),
            .host = try allocator.dupe(u8, root.get("host").?.String),
            .max_connections = @intCast(root.get("max_connections").?.Integer),
        };
    }

    pub fn loadFromYaml(allocator: std.mem.Allocator, filepath: []const u8) !Config {
        const file = try std.fs.cwd().openFile(filepath, .{});
        defer file.close();

        const content = try file.readToEndAlloc(allocator, 1024 * 1024);
        defer allocator.free(content);

        var config = Config.default;

        var lines = std.mem.split(u8, content, "\n");
        while (lines.next()) |line| {
            var tokens = std.mem.split(u8, std.mem.trim(u8, line, " "), ":");
            const key = tokens.next() orelse continue;
            const value = tokens.next() orelse continue;

            if (std.mem.eql(u8, key, "port")) {
                config.port = try std.fmt.parseInt(u16, std.mem.trim(u8, value, " \"\r"), 10);
            } else if (std.mem.eql(u8, key, "host")) {
                config.host = try allocator.dupe(u8, std.mem.trim(u8, value, " \"\r"));
            } else if (std.mem.eql(u8, key, "max_connections")) {
                config.max_connections = try std.fmt.parseInt(u32, std.mem.trim(u8, value, " \"\r"), 10);
            }
        }

        return config;
    }
};
