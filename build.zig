const std = @import("std");

pub fn build(b: *std.Build) !void {
    const run_step = b.step("run", "Run the main executable");
    const gtest_step = b.step("gtest", "Run googletest");
    const gbench_step = b.step("gbench", "Run google benchmark");
    const test_step = b.step("test", "Run all checks");
    const fmt_step = b.step("fmt", "Format C/C++ files in-place with clang-format");

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var flags: std.ArrayList([]const u8) = .empty;
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
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            // To link standard libraries:
            // .link_libc = true,
            // .link_libcpp = true,
        }),
    });
    lib.root_module.addCSourceFiles(.{
        .root = b.path("src"),
        // Source files go here.
        .files = &.{
            "lib.cpp",
        },
        .flags = flags.items,
    });

    run_step.dependOn(blk: {
        const exe = b.addExecutable(.{
            .name = "main",
            .root_module = b.createModule(.{ .target = target, .optimize = optimize }),
        });
        exe.root_module.addCSourceFiles(.{ .files = &.{"src/main.cpp"}, .flags = flags.items });
        exe.linkLibrary(lib);
        b.installArtifact(exe); // install step installs this exe to prefix/bin
        const cmd = b.addRunArtifact(exe);
        cmd.step.dependOn(b.getInstallStep()); // also install artefacts when we run `zig build run`
        break :blk &cmd.step;
    });

    const gtest_exe = blk: {
        const exe = b.addExecutable(.{
            .name = "gtest",
            .root_module = b.createModule(.{ .target = target, .optimize = optimize }),
        });
        exe.root_module.addCSourceFiles(.{
            .root = b.path("src"),
            // Test files go here.
            .files = &.{
                "test.cpp",
            },
            .flags = flags.items,
        });
        exe.linkLibrary(lib);
        const dep = b.dependency("googletest", .{ .target = target, .optimize = optimize });
        exe.linkLibrary(dep.artifact("gtest"));
        exe.linkLibrary(dep.artifact("gtest_main"));
        break :blk exe;
    };

    gtest_step.dependOn(blk: {
        const cmd = b.addRunArtifact(gtest_exe);
        cmd.addArg("--gtest_brief=1");
        if (b.args) |args| cmd.addArgs(args);
        break :blk &cmd.step;
    });

    // Also add googletest tests to `zig build test` step.
    test_step.dependOn(blk: {
        const cmd = b.addRunArtifact(gtest_exe);
        cmd.addArg("--gtest_brief=1");
        cmd.expectExitCode(0); // hides stdout when tests pass
        break :blk &cmd.step;
    });

    const gbench_exe = blk: {
        const exe = b.addExecutable(.{
            .name = "gbench",
            .root_module = b.createModule(.{ .target = target, .optimize = optimize }),
        });
        exe.root_module.addCSourceFiles(.{
            .root = b.path("src"),
            // Benchmark files go here.
            .files = &.{
                "benchmark.cpp",
            },
            .flags = flags.items,
        });
        exe.linkLibrary(lib);
        const dep = b.dependency("benchmark", .{ .target = target, .optimize = optimize });
        exe.linkLibrary(dep.artifact("benchmark"));
        exe.linkLibrary(dep.artifact("benchmark_main"));
        break :blk exe;
    };

    gbench_step.dependOn(blk: {
        const cmd = b.addRunArtifact(gbench_exe);
        if (b.args) |args| cmd.addArgs(args);
        break :blk &cmd.step;
    });

    // Also add a quick run of the Google Benchmark benchmarks to `zig build test`.
    test_step.dependOn(blk: {
        const cmd = b.addRunArtifact(gbench_exe);
        cmd.addArg("--benchmark_min_time=0s"); // fast: only one iteration per benchmark
        cmd.expectExitCode(0);
        _ = cmd.captureStdErr(); // hide stderr
        break :blk &cmd.step;
    });

    // Save list of C/C++ files to format to a file.
    const files_list = b.addSystemCommand(&.{
        "git",
        "ls-files",
        "*.[ch]pp",
        "*.[ch]",
    }).captureStdOut();

    const clang_format_exe = blk: {
        const dep = b.dependency("clang_tools", .{ .target = b.graph.host });
        const exe = dep.builder.named_lazy_paths.get("clang-format") orelse return;
        break :blk exe;
    };

    // Format the C/C++ code in-place with clang-format with `zig build fmt`.
    fmt_step.dependOn(blk: {
        const cmd = std.Build.Step.Run.create(b, "clang-format");
        cmd.addFileArg(clang_format_exe);
        cmd.addArg("-i");
        cmd.addPrefixedFileArg("--files=", files_list);
        break :blk &cmd.step;
    });

    // Add checking the C/C++ code formatting with clang-format to `zig build test`.
    test_step.dependOn(blk: {
        const cmd = std.Build.Step.Run.create(b, "clang-format");
        cmd.addFileArg(clang_format_exe);
        cmd.addArgs(&.{ "--dry-run", "--Werror" });
        cmd.addPrefixedFileArg("--files=", files_list);
        cmd.expectExitCode(0);
        _ = cmd.captureStdErr();
        break :blk &cmd.step;
    });
}
