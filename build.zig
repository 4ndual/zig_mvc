const std = @import("std");

pub fn build(b: *std.Build) void {

    // Like "scripts", build options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-mvc",
        .root_source_file = b.path("main.zig"),
        .target = target,
        .optimize = optimize,
    });

    //  "dependencies"  but for C libraries
    // exe.linkLibC();
    // exe.linkSystemLibrary("sqlite3");

    const sqlite = b.dependency("sqlite", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("sqlite", sqlite.module("sqlite"));

    b.installArtifact(exe);

    // This adds a "run" command (zig build run)
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // Defines the "run" command
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
