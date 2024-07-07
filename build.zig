const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const capstone = b.dependency("capstone", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();

    const compiled_capstone = capstone.artifact("capstone");
    exe.addIncludePath(compiled_capstone.getEmittedIncludeTree());
    exe.addLibraryPath(compiled_capstone.getEmittedBin().dirname());
    exe.linkSystemLibrary("capstone");

    b.default_step.dependOn(capstone.builder.default_step);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const cs_bindings = b.dependency("capstone-bindings-zig", .{
        .target = target,
        .optimize = optimize,
    });

    const cs_test = b.addExecutable(.{
        .name = "main2",
        .root_source_file = b.path("src/main2.zig"),
        .target = target,
        .optimize = optimize,
    });
    cs_test.root_module.addImport("capstone-z", cs_bindings.module("capstone-bindings-zig"));

    b.default_step.dependOn(capstone.builder.default_step);

    b.installArtifact(cs_test);
}
