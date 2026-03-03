const std = @import("std");

const targets: std.Target.Query =
    .{
        .cpu_arch = .mipsel,
        .cpu_model = .{ .explicit = &std.Target.mips.cpu.mips1 },
        .os_tag = .freestanding,
        .abi = .eabi,
    };

pub fn addModule(b: *std.Build, name: []const u8, root_source_file: std.Build.LazyPath) *std.Build.Module {
    const module = b.addModule(name, .{
        .root_source_file = root_source_file,
        .target = b.resolveTargetQuery(targets),
        .optimize = .ReleaseSmall,
    });

    return module;
}

pub fn addStaticLibrary(b: *std.Build, lib_name: []const u8, root_module: *std.Build.Module) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = lib_name,
        .linkage = .static,
        .root_module = root_module,
    });

    lib.setLinkerScript(b.path("psx-zig/psx.ld"));

    return lib;
}

pub fn psx_exe(b: *std.Build, name: []const u8, src_file: []const u8, debug: bool) void {
    const start_obj = b.addObject(.{
        .name = "psx_start",
        .root_module = b.addModule("psx_start", .{ .root_source_file = b.path("psx-zig/psx_start.zig"), .target = b.resolveTargetQuery(targets), .optimize = .ReleaseSmall }),
    });

    const exe_module = b.createModule(.{ .root_source_file = b.path(src_file), .target = b.resolveTargetQuery(targets), .optimize = .ReleaseSmall, .single_threaded = true });
    const exe = b.addExecutable(.{
        .name = name,
        .root_module = exe_module,
        .use_llvm = true,
        .use_lld = true,
    });
    exe.setLinkerScript(b.path("psx-zig/psx.ld"));
    exe_module.addObject(start_obj);

    const psx_module = addModule(b, "psxZig", b.path("psx-zig/psx.zig"));

    exe_module.linkLibrary(addStaticLibrary(b, "psxZig", psx_module));
    exe_module.addImport("psxZig", psx_module);

    if (debug) {
        const install_bc = b.addInstallFile(exe.getEmittedLlvmIr(), "hello.ir");
        b.getInstallStep().dependOn(&install_bc.step);

        const asm_bc = b.addInstallFile(exe.getEmittedAsm(), "hello.asm");
        b.getInstallStep().dependOn(&asm_bc.step);
    }

    b.installArtifact(exe);
}
