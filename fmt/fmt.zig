const fmt = @import("std").fmt;

var buffer: [64]u8 = undefined;

pub fn fmtZ(comptime s: []const u8, n: anytype) [*:0]const u8 {
    const formatted = fmt.bufPrint(&buffer, s ++ "\n\x00", n) catch "fmtZ error\n\x00";
    return @ptrCast(formatted.ptr);
}
