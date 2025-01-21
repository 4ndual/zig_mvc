// controllers/generic_controller.zig
const std = @import("std");
const GenericView = @import("../views/generic.zig").GenericView;
const Http = @import("../utils/http.zig").Http;
const Database = @import("../database/connection.zig");
const sqlite = @import("sqlite");

pub const GenericController = struct {
    allocator: std.mem.Allocator,
    view: GenericView,
    db: *sqlite.Db,

    const User = struct {
        id: i64,
        name: []const u8,
        email: []const u8,
    };

    pub fn init(allocator: std.mem.Allocator, db: *sqlite.Db) GenericController {
        return .{
            .allocator = allocator,
            .view = GenericView.init(),
            .db = db,
        };
    }

    pub fn handleGetRequest(self: *GenericController, writer: anytype, path: []const u8) !void {
        if (std.mem.eql(u8, path, "/")) {
            const html_content = GenericView.render();
            try Http.sendHtmlResponse(self.allocator, writer, html_content);
        } else if (std.mem.eql(u8, path, "/about")) {
            const html_content = GenericView.render();
            try Http.sendHtmlResponse(self.allocator, writer, html_content);
        } else {
            const html_content = "404 Not Found";
            try Http.sendHtmlResponse(self.allocator, writer, html_content);
        }
    }

    pub fn insertUser(self: *GenericController, name: []const u8, email: []const u8) !void {
        // Print the type info of the database
        std.debug.print("\n=== Database Debug Info ===\n", .{});
        std.debug.print("Database type: {any}\n", .{@TypeOf(self.db)});
        std.debug.print("PRESMT: name={s}, email={s}\n", .{ name, email });
        var db = try Database.init("app.db");

        var stmt = try db.prepare("INSERT INTO users(name, email) VALUES(?1, ?2)");
        defer stmt.deinit();

        try stmt.exec(.{}, .{ name, email });
    }

    // pub fn getUsers(self: *GenericController) ![]User {
    //     const sql = "SELECT id, name, email FROM users";
    //     var stmt = try self.db.prepare(sql);
    //     defer stmt.deinit();

    //     // Using an arena allocator as recommended in the docs
    //     var arena = std.heap.ArenaAllocator.init(self.allocator);
    //     defer arena.deinit();

    //     return stmt.all(User, arena.allocator(), .{}, .{});
    // }

    pub fn handlePostRequest(self: *GenericController, writer: anytype, path: []const u8, body: ?[]const u8) !void {
        if (std.mem.eql(u8, path, "/users")) {
            if (body) |data| {
                const UserInput = struct {
                    name: []const u8,
                    email: []const u8,
                };

                std.debug.print("Reading JSON content:\n{s}\n", .{data});

                // Use the new parseFromSlice API
                var parsed = try std.json.parseFromSlice(
                    UserInput,
                    self.allocator,
                    data,
                    .{},
                );

                defer parsed.deinit();

                // Access the parsed data through .value

                std.debug.print("Parsed: name={s}, email={s}\n", .{ parsed.value.name, parsed.value.email });
                try self.insertUser(parsed.value.name, parsed.value.email);

                const response_content = "{\"status\": \"success\", \"message\": \"User created successfully!\"}";
                try Http.sendJsonResponse(self.allocator, writer, response_content);
            } else {
                const response_content = "{\"status\": \"error\", \"message\": \"No body received\"}";
                try Http.sendJsonResponse(self.allocator, writer, response_content);
            }
        }
    }

    pub fn handlePutRequest(self: *GenericController, writer: anytype, path: []const u8, body: ?[]const u8) !void {
        if (std.mem.eql(u8, path, "/update")) {
            if (body) |data| {
                std.log.info("Received PUT data: {s}", .{data});

                const response_content = "{\"status\": \"success\", \"message\": \"PUT data received!\"}";

                try Http.sendJsonResponse(self.allocator, writer, response_content);
            } else {
                const response_content = "{\"status\": \"error\", \"message\": \"No body received\"}";
                try Http.sendJsonResponse(self.allocator, writer, response_content);
            }
        } else {
            const html_content = "404 Not Found";
            try Http.sendHtmlResponse(self.allocator, writer, html_content);
        }
    }
};
// const std = @import("std");
// const GenericView = @import("../views/generic.zig").GenericView;
// const Http = @import("../utils/http.zig").Http;

// pub const GenericController = struct {
//     allocator: std.mem.Allocator,
//     view: GenericView,

//     pub fn init(allocator: std.mem.Allocator) GenericController {
//         return .{
//             .allocator = allocator,
//             .view = GenericView.init(),
//         };
//     }

//     pub fn handleGetRequest(self: *GenericController, writer: anytype, path: []const u8) !void {
//         if (std.mem.eql(u8, path, "/")) {
//             const html_content = GenericView.render();
//             try Http.sendHtmlResponse(self.allocator, writer, html_content);
//         } else if (std.mem.eql(u8, path, "/about")) {
//             const html_content = GenericView.render();
//             try Http.sendHtmlResponse(self.allocator, writer, html_content);
//         } else {
//             const html_content = "404 Not Found";
//             try Http.sendHtmlResponse(self.allocator, writer, html_content);
//         }
//     }

//     pub fn handlePostRequest(self: *GenericController, writer: anytype, path: []const u8, body: ?[]const u8) !void {
//         if (std.mem.eql(u8, path, "/submit")) {
//             if (body) |data| {
//                 std.log.info("Received POST data: {s}", .{data});

//                 // const parsed = try std.json.parse(Struct, &std.json.TokenStream.init(data));

//                 const response_content = "{\"status\": \"success\", \"message\": \"POST data received!\"}";
//                 try Http.sendJsonResponse(self.allocator, writer, response_content);
//             } else {
//                 const response_content = "{\"status\": \"error\", \"message\": \"No body received\"}";
//                 try Http.sendJsonResponse(self.allocator, writer, response_content);
//             }
//         } else {
//             const response_content = "{\"status\": \"error\", \"message\": \"404 Not Found\"}";
//             try Http.sendJsonResponse(self.allocator, writer, response_content);
//         }
//     }

// };
