const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const googletest_dep = b.dependency("googletest", .{});
    const benchmark_dep = b.dependency("benchmark", .{});

    var flags = std.ArrayList([]const u8){};
    defer flags.deinit(b.allocator);
    try flags.appendSlice(b.allocator, &.{
        "-std=c++20",
        "-fno-exceptions",
        "-Wall",
        "-Wextra",
        "-Werror",
    });
    if (optimize == .Debug) try flags.append(b.allocator, "-fstack-protector-all");

    const lib = b.addLibrary(.{
        .name = "lib",
        .root_module = b.createModule(.{ .target = target, .optimize = optimize }),
    });
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

    const gtest_exe = b.addExecutable(.{
        .name = "gtest",
        .root_module = b.createModule(.{ .target = target, .optimize = optimize }),
    });
    gtest_exe.root_module.addCSourceFiles(.{
        // Test files go here.
        .files = &.{
            "src/test.cpp",
        },
        .flags = flags.items,
    });
    gtest_exe.linkLibrary(lib);
    gtest_exe.linkLibrary(googletest_dep.artifact("gtest"));
    gtest_exe.linkLibrary(googletest_dep.artifact("gtest_main"));
    const gtest_step = b.step("gtest", "Run gtest");
    const gtest_run = b.addRunArtifact(gtest_exe);
    gtest_run.addArg("--gtest_brief=1");
    if (b.args) |args| gtest_run.addArgs(args);
    gtest_step.dependOn(&gtest_run.step);

    const gbench_exe = b.addExecutable(.{
        .name = "gbench",
        .root_module = b.createModule(.{ .target = target, .optimize = optimize }),
    });
    gbench_exe.root_module.addCSourceFiles(.{
        // Benchmark files go here.
        .files = &.{
            "src/benchmark.cpp",
        },
        .flags = flags.items,
    });
    gbench_exe.linkLibrary(lib);
    gbench_exe.linkLibrary(benchmark_dep.artifact("benchmark"));
    gbench_exe.linkLibrary(benchmark_dep.artifact("benchmark_main"));
    const gbench_step = b.step("gbench", "Run gbench benchmarks");
    const gbench_run = b.addRunArtifact(gbench_exe);
    if (b.args) |args| gbench_run.addArgs(args);
    gbench_step.dependOn(&gbench_run.step);

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&gtest_run.step);
    const gbench_run_fast = b.addRunArtifact(gbench_exe);
    gbench_run_fast.addArgs(&.{"--benchmark_min_time=0s"}); // only one iteration per benchmark
    test_step.dependOn(&gbench_run_fast.step);
}
