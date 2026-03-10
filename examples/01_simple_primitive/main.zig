const std = @import("std");

const PsxZig = @import("psxZig");
const Gpu = PsxZig.gpu.Gpu;
const Debug = PsxZig.debug;
const Kernel = PsxZig.kernel;

export fn main() noreturn {
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

        Gpu.shadedTriangle([_]Gpu.SVector{ Gpu.SVector{ .x = x, .y = 10 }, Gpu.SVector{ .x = x + 10, .y = 100 }, Gpu.SVector{ .x = x + 50, .y = 75 } }, [_]Gpu.Color{ Gpu.Color{ .r = 128, .g = 0, .b = 0 }, Gpu.Color{ .r = 0, .g = 128, .b = 0 }, Gpu.Color{ .r = 0, .g = 0, .b = 128 } });

        x += 1;

        x = x % 100;

        Gpu.vblank();
    }
}
