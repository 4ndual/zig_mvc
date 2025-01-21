// database/connection.zig
const std = @import("std");
const sqlite = @import("sqlite");

pub const DatabaseError = error{
    ConnectionFailed,
    QueryFailed,
};

// database/connection.zig

pub fn init(path: [:0]const u8) !sqlite.Db {
    return try sqlite.Db.init(.{
        .mode = .{ .File = path },
        .open_flags = .{
            .write = true,
            .create = true,
        },
        .threading_mode = .SingleThread,
    });
}
