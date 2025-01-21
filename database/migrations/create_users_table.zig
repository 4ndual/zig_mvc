const Migration = @import("migration.zig").Migration;

pub const CreateUsersTable = Migration{
    .name = "create_users_table",
    .up =
    \\CREATE TABLE users (
    \\    id INTEGER PRIMARY KEY AUTOINCREMENT,
    \\    name TEXT NOT NULL,
    \\    email TEXT NOT NULL UNIQUE,
    \\    created_at INTEGER NOT NULL
    \\)
    ,
    .down = "DROP TABLE users",
};
