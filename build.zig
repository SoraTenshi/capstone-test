const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const capstone = b.dependency("capstone", .{
        .target = target,
        .optimize = optimize,
    });

    const cs_test = b.addExecutable(.{
        .name = "main",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    cs_test.linkLibC();

    const compiled_capstone = capstone.artifact("capstone");
    cs_test.addIncludePath(compiled_capstone.getEmittedIncludeTree());
    cs_test.addLibraryPath(compiled_capstone.getEmittedBin().dirname());
    cs_test.linkSystemLibrary("capstone");

    b.default_step.dependOn(capstone.builder.default_step);

    b.installArtifact(cs_test);

    const run_cmd = b.addRunArtifact(cs_test);
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

    const cs_test2 = b.addExecutable(.{
        .name = "main2",
        .root_source_file = b.path("src/main2.zig"),
        .target = target,
        .optimize = optimize,
    });
    cs_test2.root_module.addImport("capstone-z", cs_bindings.module("capstone-bindings-zig"));

    b.installArtifact(cs_test2);

    const cs_test3 = b.addExecutable(.{
        .name = "main3",
        .root_source_file = b.path("src/main3.zig"),
        .target = target,
        .optimize = optimize,
    });
    cs_test3.root_module.addImport("capstone-z", cs_bindings.module("capstone-bindings-zig"));

    b.installArtifact(cs_test3);
}
