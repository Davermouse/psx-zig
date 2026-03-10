const std = @import("std");

const PsxZig = @import("psxZig");
const Gpu = PsxZig.gpu.Gpu;
const Debug = PsxZig.debug;
const Kernel = PsxZig.kernel;

const screenWidth: i16 = 320;
const screenHeight: i16 = 240;

pub export fn main() noreturn {
    _ = Debug.puts("Part 2 - Double buffering");

    Kernel.Install();

    const cfg = Gpu.Cfg{ .hResolution = Gpu.HResolution.H320, .vResolution = Gpu.VResolution.V240, .interlace = false, .mode = Gpu.VideoMode.PAL, .colourDepth = Gpu.ColourDepth.B15 };
    Gpu.init(cfg) catch {
        _ = Debug.puts("gpu init fail");
    };

    _ = Debug.puts("gpu init ok");

    var usingSecondFrame = false;

    var x: i16 = 0;
    var y: i16 = 0;

    var xVelocity: i16 = 1;
    var yVelocity: i16 = 1;

    while (true) {
        const frameX: u10 = if (usingSecondFrame) screenWidth else 0;
        const frameY: u9 = 0;

        usingSecondFrame = !usingSecondFrame;

        Gpu.waitForReady();
        Gpu.port.data.* = Gpu.texPage(0, 1, 0);
        Gpu.port.data.* = Gpu.setDrawingStartGP0(frameX, frameY);
        Gpu.port.data.* = Gpu.setDrawingEndGP0(@intCast(frameX + screenWidth - 1), @intCast(frameY + screenHeight - 2));
        Gpu.port.data.* = Gpu.setDrawingOffsetGP0(frameX, frameY);

        Gpu.waitForReady();
        Gpu.port.data.* = @bitCast(Gpu.QuickFillCommand{ .color = .{ .r = 64, .g = 64, .b = 64 } });
        Gpu.port.data.* = @bitCast(Gpu.SVector{ .x = frameX, .y = frameY });
        Gpu.port.data.* = @bitCast(Gpu.SVector{ .x = screenWidth, .y = screenHeight });

        Gpu.waitForReady();
        Gpu.port.data.* = @bitCast(Gpu.RectangleCommand{ .color = .{ .r = 255, .g = 255, .b = 0 }, .rawTex = false, .semiTrans = false, .textured = false, .size = Gpu.RectangleSize.Variable, .cmd = 3 });
        Gpu.port.data.* = @bitCast(Gpu.SVector{ .x = @bitCast(x), .y = @bitCast(y) });
        Gpu.port.data.* = @bitCast(Gpu.SVector{ .x = 32, .y = 32 });

        x += xVelocity;
        y += yVelocity;

        if (x <= 0 or (x >= (@as(u16, screenWidth - 32))))
            xVelocity = -xVelocity;

        if (y <= 0 or (y >= (@as(u16, screenHeight - 32))))
            yVelocity = -yVelocity;

        Gpu.waitForReady();
        Gpu.vblank();

        Gpu.port.ctrl.* = @bitCast(Gpu.FrameBufferOffsetCommand{ .x = frameX, .y = frameY, .pad = 0, .cmd = 5 });

        asm volatile (
            \\ nop
        );
    }
}
