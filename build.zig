const std = @import("std");
const PSXBuild = @import("psx-zig/build/psxBuild.zig");

pub fn build(b: *std.Build) void {
    PSXBuild.psx_exe(b, "01_single_primitive", "examples/01_simple_primitive/main.zig", false);
    PSXBuild.psx_exe(b, "02_double_buffer", "examples/02_double_buffer/main.zig", false);
}
