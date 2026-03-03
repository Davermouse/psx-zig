const std = @import("std");

pub const panic = std.debug.FullPanic(myPanic);

fn myPanic(msg: []const u8, first_trace_addr: ?usize) noreturn {
    _ = first_trace_addr;
    _ = msg; //Debug.puts(msg);
    while (true) {}
}
