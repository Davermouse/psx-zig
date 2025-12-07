const std = @import("std");

// TODO: We can't use .mips1 here as we can an error from llvm
const targets: std.Target.Query =
    .{
        .cpu_arch = .mipsel,
        .cpu_model = .{ .explicit = &std.Target.mips.cpu.mips1 },
        .os_tag = .freestanding,
        .abi = .eabi,
    };

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "hello-psx",
        .root_module = b.createModule(.{ .root_source_file = b.path("main.zig"), .target = b.resolveTargetQuery(targets), .optimize = .ReleaseSmall, .single_threaded = true }),
        .use_llvm = true,
        .use_lld = true,
    });

    exe.setLinkerScript(b.path("psx.ld"));

    const install_bc = b.addInstallFile(exe.getEmittedLlvmIr(), "hello.ir");
    b.getInstallStep().dependOn(&install_bc.step);

    const asm_bc = b.addInstallFile(exe.getEmittedAsm(), "hello.asm");
    b.getInstallStep().dependOn(&asm_bc.step);

    b.installArtifact(exe);
}
