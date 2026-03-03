const std = @import("std");

const PsxZig = @import("psxZig");
const Gpu = PsxZig.gpu;
const Debug = PsxZig.debug;
const Kernel = PsxZig.kernel;

pub export fn main() noreturn {
    _ = Debug.puts("Part 2 - Double buffering");

    while (true) {
        asm volatile (
            \\ nop
        );
    }
}
