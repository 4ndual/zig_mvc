const std = @import("std");
const sqlite = @import("sqlite");

pub const DatabaseConfig = struct {
    path: [:0]const u8,

    pub fn init(path: [:0]const u8) DatabaseConfig {
        return .{
            .path = path,
        };
    }
};
