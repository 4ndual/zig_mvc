// tests/server_test.zig
const std = @import("std");
const testing = std.testing;
const Server = @import("server/server.zig").Server;

fn setupTestServer() !Server {
    return Server.init(testing.allocator, 3667);
}

fn sendRequest(allocator: std.mem.Allocator, request: []const u8) ![]u8 {
    const socket = try std.net.tcpConnectToHost(allocator, "localhost", 3667);
    defer socket.close();

    try socket.writer().writeAll(request);
    var buffer: [8192]u8 = undefined;
    const bytes_read = try socket.reader().read(&buffer);
    return try allocator.dupe(u8, buffer[0..bytes_read]);
}

test "Basic HTTP GET request" {
    var server = try setupTestServer();
    defer server.deinit();

    // Start server in a separate thread
    const thread = try std.Thread.spawn(.{}, Server.start, .{&server});
    defer thread.detach();

    // Wait a moment for the server to start
    std.time.sleep(100 * std.time.ns_per_ms);

    const response = try sendRequest(testing.allocator, "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n");
    defer testing.allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 200 OK") != null);
}

test "Malformed requests" {
    var server = try setupTestServer();
    defer server.deinit();

    const thread = try std.Thread.spawn(.{}, Server.start, .{&server});
    defer thread.detach();
    std.time.sleep(100 * std.time.ns_per_ms);

    const malformed_requests = [_][]const u8{
        "", // Empty request
        "GET", // Incomplete request
        "GET / INVALID\r\n\r\n", // Invalid HTTP version
        "GET / HTTP/1.1\r\n" ** 1000, // Very long headers
        "\x00\x01\x02\x03", // Binary garbage
        "GET / HTTP/1.1\r\n\r" ** 65537, // Exceeds max buffer
        "POST / HTTP/1.1\r\nContent-Length: -1\r\n\r\n", // Invalid content length
        "GET / HTTP/1.1\r\nHost: localhost:65536\r\n\r\n", // Invalid port
    };

    for (malformed_requests) |request| {
        const response = sendRequest(testing.allocator, request) catch |err| {
            // Expect either a valid error response or connection closed
            try testing.expect(err == error.ConnectionResetByPeer or
                // tests/server_test.zig (continued)
                err == error.BrokenPipe or
                err == error.WouldBlock or
                err == error.ConnectionRefused);
            continue;
        };
        defer testing.allocator.free(response);
        try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 400 Bad Request") != null);
    }
}

// test "Concurrent connections" {
//     var server = try setupTestServer();
//     defer server.deinit();

//     const thread = try std.Thread.spawn(.{}, Server.start, .{&server});
//     defer thread.detach();
//     std.time.sleep(100 * std.time.ns_per_ms);

//     const num_connections = 100;
//     var threads: [num_connections]std.Thread = undefined;

//     for (threads, 0..) |*t, i| {
//         t.* = try std.Thread.spawn(.{}, struct {
//             fn run(id: usize) !void {
//                 const response = try sendRequest(testing.allocator,
//                     "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n"
//                 );
//                 defer testing.allocator.free(response);
//                 try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 200 OK") != null);
//             }
//         }.run, .{i});
//     }

//     for (threads) |t| {
//         t.join();
//     }
// }

test "Slow clients" {
    var server = try setupTestServer();
    defer server.deinit();

    const thread = try std.Thread.spawn(.{}, Server.start, .{&server});
    defer thread.detach();
    std.time.sleep(100 * std.time.ns_per_ms);

    const socket = try std.net.tcpConnectToHost(testing.allocator, "localhost", 3667);
    defer socket.close();

    // Send request byte by byte with delays
    const request = "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n";
    for (request) |byte| {
        try socket.writer().writeByte(byte);
        std.time.sleep(100 * std.time.ns_per_ms);
    }

    var buffer: [8192]u8 = undefined;
    const bytes_read = try socket.reader().read(&buffer);
    try testing.expect(std.mem.indexOf(u8, buffer[0..bytes_read], "HTTP/1.1 200 OK") != null);
}

test "Large requests" {
    var server = try setupTestServer();
    defer server.deinit();

    const thread = try std.Thread.spawn(.{}, Server.start, .{&server});
    defer thread.detach();
    std.time.sleep(100 * std.time.ns_per_ms);

    var large_headers = std.ArrayList(u8).init(testing.allocator);
    defer large_headers.deinit();

    try large_headers.appendSlice("GET / HTTP/1.1\r\nHost: localhost\r\n");
    // Add many custom headers
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        try std.fmt.format(large_headers.writer(), "X-Custom-Header-{d}: value{d}\r\n", .{ i, i });
    }
    try large_headers.appendSlice("\r\n");

    const response = try sendRequest(testing.allocator, large_headers.items);
    defer testing.allocator.free(response);
    try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1") != null);
}

test "Connection handling" {
    var server = try setupTestServer();
    defer server.deinit();

    const thread = try std.Thread.spawn(.{}, Server.start, .{&server});
    defer thread.detach();
    std.time.sleep(100 * std.time.ns_per_ms);

    // Test keep-alive connection
    {
        const socket = try std.net.tcpConnectToHost(testing.allocator, "localhost", 3667);
        defer socket.close();

        // Send multiple requests on the same connection
        const requests = [_][]const u8{
            "GET / HTTP/1.1\r\nHost: localhost\r\nConnection: keep-alive\r\n\r\n",
            "GET / HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n",
        };

        for (requests) |request| {
            try socket.writer().writeAll(request);
            var buffer: [8192]u8 = undefined;
            const bytes_read = try socket.reader().read(&buffer);
            try testing.expect(std.mem.indexOf(u8, buffer[0..bytes_read], "HTTP/1.1 200 OK") != null);
        }
    }
}

test "Memory leaks" {
    var server = try setupTestServer();
    defer server.deinit();

    const thread = try std.Thread.spawn(.{}, Server.start, .{&server});
    defer thread.detach();
    std.time.sleep(100 * std.time.ns_per_ms);

    // Create and destroy many connections rapidly
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const socket = try std.net.tcpConnectToHost(testing.allocator, "localhost", 3667);
        try socket.writer().writeAll("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n");
        socket.close();
    }
}

test "Invalid HTTP methods" {
    var server = try setupTestServer();
    defer server.deinit();

    const thread = try std.Thread.spawn(.{}, Server.start, .{&server});
    defer thread.detach();
    std.time.sleep(100 * std.time.ns_per_ms);

    const invalid_methods = [_][]const u8{
        "INVALID / HTTP/1.1\r\n\r\n",
        "POST / HTTP/1.1\r\n\r\n", // If your server only supports GET
        "PUT / HTTP/1.1\r\n\r\n",
        "DELETE / HTTP/1.1\r\n\r\n",
        "PATCH / HTTP/1.1\r\n\r\n",
    };

    for (invalid_methods) |method| {
        const response = try sendRequest(testing.allocator, method);
        defer testing.allocator.free(response);
        try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 405 Method Not Allowed") != null or
            std.mem.indexOf(u8, response, "HTTP/1.1 400 Bad Request") != null);
    }
}
