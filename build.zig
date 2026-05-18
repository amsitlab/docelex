
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addModule("doclex", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    const tests =  b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("test/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    tests.root_module.addImport("doclex", lib);
    const runTest = b.addRunArtifact(tests);
    b.step("test", "Run all unit test")
        .dependOn(&runTest.step);


}
