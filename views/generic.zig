pub const GenericView = struct {
    pub fn init() GenericView {
        return .{};
    }

    pub fn render() []const u8 {
        return 
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\    <title>Hello from Zig</title>
        \\</head>
        \\<body>
        \\    <h1>Hello, World!</h1>
        \\    <p>This is a simple HTML page served by Zig.</p>
        \\</body>
        \\</html>
        ;
    }
};
