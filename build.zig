const std = @import("std");

const targets: std.Target.Query =
    .{ .cpu_arch = .mipsel, .os_tag = .freestanding, .abi = .eabi };

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "hello-psx",
        .root_module = b.createModule(.{ .root_source_file = b.path("main.zig"), .target = b.resolveTargetQuery(targets), .optimize = .ReleaseSmall, .single_threaded = true }),
        .use_llvm = true,
        .use_lld = true,
    });

    exe.setLinkerScript(b.path("psx.ld"));

    b.installArtifact(exe);
}
