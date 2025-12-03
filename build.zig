const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const contract = b.addModule("contract", .{
        .root_source_file = b.path("src/contract.zig"),
    });

    const tests_mod = b.createModule(.{
        .root_source_file = b.path("tests/tests.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "contract", .module = contract },
        },
    });
    const tests = b.addTest(.{
        .root_module = tests_mod,
    });
    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    const check_mod = b.addTest(.{
        .root_module = tests_mod,
    });

    const check_tests = b.addTest(.{
        .root_module = tests_mod,
    });

    const check_step = b.step("check", "Check for compile errors");
    check_step.dependOn(&check_tests.step);
    check_step.dependOn(&check_mod.step);

    // Export the module so other projects can use it
}
