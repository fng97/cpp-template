const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var flags = std.ArrayList([]const u8){};
    defer flags.deinit(b.allocator);
    try flags.appendSlice(b.allocator, &.{
        "-std=c++20",
        "-fno-exceptions",
        "-Wall",
        "-Wextra",
        "-Werror",
    });

    const lib = b.addLibrary(.{
        .name = "lib",
        .root_module = b.createModule(.{ .target = target, .optimize = optimize }),
    });
    if (optimize == .Debug) try flags.append(b.allocator, "-fstack-protector-all");
    lib.root_module.addCSourceFiles(.{
        // Source files go here.
        .files = &.{
            "src/lib.cpp",
        },
        .flags = flags.items,
    });
    // To link standard libraries:
    // lib.linkLibCpp();
    // lib.linkLibC();

    const exe = b.addExecutable(.{
        .name = "main",
        .root_module = b.createModule(.{ .target = target, .optimize = optimize }),
    });
    exe.root_module.addCSourceFiles(.{ .files = &.{"src/main.cpp"}, .flags = flags.items });
    exe.linkLibrary(lib);
    b.installArtifact(exe);
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
}
