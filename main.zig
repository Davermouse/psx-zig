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

pub const panic = std.debug.FullPanic(myPanic);

fn myPanic(msg: []const u8, first_trace_addr: ?usize) noreturn {
    _ = first_trace_addr;
    _ = msg; //Debug.puts(msg);
    while (true) {}
}

const std = @import("std");

const Gpu = @import("gpu.zig").Gpu;
const Debug = @import("Debug.zig").Debug;
const Kernel = @import("kernel.zig");

fn main() noreturn {
    _ = Debug.puts("hello world!");

    Kernel.Install();

    const cfg = Gpu.Cfg{ .hResolution = Gpu.HResolution.H320, .vResolution = Gpu.VResolution.V240, .interlace = false, .mode = Gpu.VideoMode.PAL, .colourDepth = Gpu.ColourDepth.B15 };
    Gpu.init(cfg) catch {
        _ = Debug.puts("gpu init fail");
    };

    _ = Debug.puts("gpu init ok");

    var x: u16 = 0;

    while (true) {
        Gpu.quickFill(Gpu.Color{ .r = 0, .g = 0, .b = 0 }, Gpu.SVector{ .x = 0, .y = 0 }, Gpu.SVector{ .x = 100 + 0x40, .y = 240 });

        Gpu.shadedTriangle([_]Gpu.SVector{ Gpu.SVector{ .x = 10, .y = 10 }, Gpu.SVector{ .x = 10, .y = 100 }, Gpu.SVector{ .x = 50, .y = 75 } }, [_]Gpu.Color{ Gpu.Color{ .r = 128, .g = 0, .b = 0 }, Gpu.Color{ .r = 0, .g = 128, .b = 0 }, Gpu.Color{ .r = 0, .g = 0, .b = 128 } });

        x += 1;

        x = x % 100;

        Gpu.vblank();
    }
}
