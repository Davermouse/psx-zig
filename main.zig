// I do not know why, but even if _start is the entry point it
// must be placed into a separate section...
extern var __bss_start: u8;
extern var __bss_end: u8;

export fn __start() linksection(".main") callconv(.c) noreturn {
    asm volatile (
        \\ li $29, 0x801fff00
        \\ li $k1, 0x1f800000
        \\ la $gp, _gp
    );

    {
        const sz = @intFromPtr(&__bss_end) - @intFromPtr(&__bss_start);
        @memset(@as([*]volatile u8, @ptrCast(&__bss_start))[0..sz], 0);
    }

    main();
}

const Gpu = @import("gpu.zig").Gpu;
const Debug = @import("Debug.zig").Debug;

fn main() noreturn {
    _ = Debug.puts("hello world!");

    //  const gpu: Gpu = undefined;
    const cfg = Gpu.Cfg{ .w = 320, .h = 240 };
    Gpu.init(cfg) catch {
        _ = Debug.puts("gpu init fail");
    };

    _ = Debug.puts("gpu init ok");

    while (true) {}
}
