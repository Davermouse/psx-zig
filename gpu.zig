pub const Pos = u16;
pub const VRAM_W: Pos = 1024;
pub const VRAM_H: Pos = 512;
const fmt = @import("fmt/fmt.zig");

const Debug = @import("Debug.zig");

const Kernel = @import("kernel.zig");
const SysCalls = @import("syscalls.zig");
const Timers = @import("hardware/timers.zig");
const port = @import("hardware/gpu.zig");
const Cpu = @import("hardware/cpu.zig");

pub const Gpu = struct {
    pub const Cfg = struct { hResolution: HResolution, vResolution: VResolution, mode: VideoMode, interlace: bool, colourDepth: ColourDepth };

    pub const Color = packed struct { r: u8, g: u8, b: u8 };
    pub const ColorCmd = packed struct { color: Color, pad: u8 };
    pub const SVector = packed struct { x: u16, y: u16 };

    pub const Rect = packed struct { x: u16, y: u16, w: u16, h: u16 };

    pub const DispEnv = struct {
        display: Rect,
        screen: Rect,
    };

    pub const DrawEnv = struct {
        clip: Rect,
    };

    pub const RenderBuffer = struct {
        displayEnv: DispEnv,
        drawEnv: DrawEnv,
    };

    pub const RenderContext = struct { buffers: [2]RenderBuffer, active_buffer: usize };

    // const Self = @This();

    // const DrawEnv = struct { width: Pos, height: Pos };

    // fn initTexPage() void {
    //     const TexPage = packed struct {
    //         x_base: u4 = 0,
    //         y_base: enum(u1) { YBase0 = 0, YBase256 = 1 } = .YBase0,
    //         transparency: u2 = 0,
    //         tpage_colors: u2 = 0,
    //         dither: u1 = 0,
    //         draw_to_display: enum(u1) { Prohibited = 0, Allowed = 1 } = .Prohibited,
    //         texture_disable: enum(u1) {
    //             Normal = 0,
    //             Disable = 1, // If GP1(09h).Bit0 == 1
    //         } = .Normal,
    //         x_flip: u1 = 0,
    //         y_flip: u1 = 0,
    //         reserved: u10 = 0,
    //         command: u8 = 0xE1,
    //     };

    //     //    port.data.cmd = .GP0;
    //     //    port.ctrl.* = @bitCast(TexPage{});
    // }

    // fn initTextureWindow() void {
    //     const TexWindow = packed struct { x: u5 = 0, y: u5 = 0, x_offset: u5 = 0, y_offset: u5 = 0, reserved: u4 = 0, cmd: u8 = 0 };

    //     //   port.data.cmd = .GP0;
    //     //   port.ctrl.* = @bitCast(TexWindow{});
    // }

    // fn initDrawingArea(comptime w: Pos, comptime h: Pos) void {
    //     comptime {
    //         if (w >= VRAM_W) {
    //             @compileError("screen width exceeds VRAM width");
    //         } else if (h >= VRAM_H) {
    //             @compileError("screen height exceeds VRAM height");
    //         }
    //     }

    //     const DrawingArea = packed struct { x: u10 = 0, y: u9 = 0, reserved: u5 = 0, cmd: u8 };

    //     const top_left = DrawingArea{ .cmd = 0xE3 };

    //     const bottom_right = DrawingArea{ .x = @truncate(w), .y = @truncate(h), .cmd = 0xE4 };

    //     // port.data.cmd = .GP0;
    //     // port.ctrl.* = @bitCast(top_left);

    //     // port.data.cmd = .GP0;
    //     // port.ctrl.* = @bitCast(bottom_right);
    // }

    // fn initDrawingAreaOffset(comptime x: Pos, comptime y: Pos) void {
    //     comptime {
    //         if (x >= VRAM_W) {
    //             @compileError("invalid drawing area X offset");
    //         } else if (y >= VRAM_H) {
    //             @compileError("invalid drawing area Y offset");
    //         }
    //     }

    //     const DrawingAreaOffset = packed struct { x: u11 = x, y: u11 = y, reserved: u2 = 0, cmd: u8 = 0xE5 };

    //     // port.data.cmd = .GP0;
    //     // port.ctrl.* = @bitCast(DrawingAreaOffset{});
    // }

    const DrawOpType = enum { Dma, GpuIrq };

    var drawOpType = DrawOpType.Dma;

    fn setDrawOpType(opType: DrawOpType) void {
        drawOpType = opType;
    }

    fn sendBuffer(opType: DrawOpType) void {
        setDrawOpType(opType);

        port.ctrl.* = 0x4000002; // DMA to GP0
    }

    var vblank_counter: u32 = 0;

    fn vblank_handler() void {
        vblank_counter = vblank_counter + 1;
    }

    fn reset() void {
        port.ctrl.* = 0;
    }

    fn fifoPollingMode() void {
        port.ctrl.* = 0x04000001;
    }

    pub const HResolution = enum(u2) { H256, H320, H512, H640 };
    pub const VResolution = enum(u1) { V240, V480 };
    pub const VideoMode = enum(u1) { NTSC, PAL };
    pub const ColourDepth = enum(u1) { B15, B24 };

    fn displayMode(comptime cfg: Cfg) void {
        const DisplayModeCommand = packed struct(u32) { hResolution: HResolution, vResolution: VResolution, mode: VideoMode, colourDepth: ColourDepth, interlace: bool, hResolution2: bool, flip: bool, reserved: u16, command: u8 };

        port.ctrl.* = @bitCast(DisplayModeCommand{ .hResolution = cfg.hResolution, .vResolution = cfg.vResolution, .mode = cfg.mode, .interlace = cfg.interlace, .colourDepth = cfg.colourDepth, .hResolution2 = false, .flip = false, .reserved = 0, .command = 0x08 });
    }

    fn setHorizontalRange() void {
        const HorizontalRangeCommand = packed struct(u32) { x1: u12, x2: u12, command: u8 };

        port.ctrl.* = @bitCast(HorizontalRangeCommand{ .x1 = 0x260, .x2 = 0xc60, .command = 0x06 });
    }

    fn setVerticalRange(comptime _: Cfg) void {
        //       const VerticalRangeCommand = packed struct(u32) { v1: u10, v2: u10, reserved: u4, command: u8 };

        //        const v1 = if (cfg.mode == VideoMode.NTSC) 16 else 0x2b;
        //       const v2 = if (cfg.mode == VideoMode.NTSC) 255 else 0x9b;

        port.ctrl.* = 0x07046c2b; //@bitCast(VerticalRangeCommand{ .v1 = v1, .v2 = v2, .command = 0x07, .reserved = 0 });
    }

    // fn setDisplayArea(x: u10, y: u9) u32 {
    //     const DisplayAreaCommand = packed struct(u32) {};
    // }

    const DisplayPosCommand = packed struct(u32) { x: u10, y: u9, reserved: u5, command: u8 };

    fn setDrawingStartGP0(x: u10, y: u9) u32 {
        return @bitCast(DisplayPosCommand{ .x = x, .y = y, .command = 0xe4, .reserved = 0 });
    }

    fn setDrawingEndGP0(x: u10, y: u9) u32 {
        return @bitCast(DisplayPosCommand{ .x = x, .y = y, .command = 0xe5, .reserved = 0 });
    }

    fn setDrawingOffsetGP0(x: u10, y: u9) u32 {
        const SetDrawingOffsetCommand = packed struct(u32) { x: u11, y: u11, reserved: u2, command: u8 };

        return @bitCast(SetDrawingOffsetCommand{ .x = x, .y = y, .reserved = 0, .command = 0xe5 });
    }

    fn resetCommandBufferGP1() void {
        const ResetCommandBuffer = packed struct(u32) { reserved: u30 = 0, command: u2 = 0x02 };
        port.ctrl.* = @bitCast(ResetCommandBuffer{});
    }

    fn enableDisplayGP1() u32 {
        const DisplayEnable = packed struct { enable: enum(u1) { On = 0, Off = 1 } = .On, reserved: u23 = 0, cmd: u8 = 0x03 };

        return @bitCast(DisplayEnable{});
    }

    fn texPage(page: u8, dither: u1, unlockFB: u1) u32 {
        const TexPage = packed struct { page: u8, dither: u1, unlockFB: u1, pad: u14, cmd: u8 };

        return @bitCast(TexPage{ .page = page, .dither = dither, .unlockFB = unlockFB, .pad = 0, .cmd = 0xe1 });
    }

    fn vramfill() u32 {
        return 2 << 24;
    }

    fn clockMultiplier(res: HResolution) u32 {
        if (res == HResolution.H256) {
            return 10;
        } else if (res == HResolution.H320) {
            return 8;
        } else if (res == HResolution.H512) {
            return 5;
        } else if (res == HResolution.H640) {
            return 4;
        }

        return 0;
    }

    fn clockDivider(res: VResolution) u32 {
        if (res == VResolution.V240) {
            return 1;
        } else if (res == VResolution.V480) {
            return 2;
        }

        return 0;
    }

    const QuickFillCommand = packed struct { color: Color, command: u8 = 0x02 };

    pub fn quickFill(color: Color, position: SVector, size: SVector) void {
        port.data.* = @bitCast(QuickFillCommand{ .color = color });

        port.data.* = @bitCast(position);
        port.data.* = @bitCast(size);
    }

    const TriangleCommand = packed struct { color: Color, rawTex: bool, semiTrans: bool, textured: bool, fourVerts: bool, gourand: bool, cmd: u3 };

    pub fn shadedTriangle(vs: [3]SVector, cs: [3]Color) void {
        port.data.* = @bitCast(TriangleCommand{ .color = cs[0], .rawTex = false, .semiTrans = false, .textured = false, .fourVerts = false, .gourand = true, .cmd = 1 });
        port.data.* = @bitCast(vs[0]);
        port.data.* = @bitCast(ColorCmd{ .color = cs[1], .pad = 0 });
        port.data.* = @bitCast(vs[1]);
        port.data.* = @bitCast(ColorCmd{ .color = cs[2], .pad = 0 });
        port.data.* = @bitCast(vs[2]);
    }

    // TODO: This hasn't been tested - the simpler counter based vblank should be fine though
    // pub fn wait_vsync() void {
    //     const imask = Cpu.imask.*;

    //     Cpu.imask.* = imask | @intFromEnum(Cpu.IrqChannels.VBlank);

    //     while ((Cpu.ireg.* & @intFromEnum(Cpu.IrqChannels.VBlank)) == 0) {
    //         // asm volatile (
    //         //     \\ nop
    //         // );
    //     }

    //     Cpu.ireg.* &= ~@intFromEnum(Cpu.IrqChannels.VBlank);
    //     Cpu.imask.* = imask;
    // }

    pub fn vblank() void {
        const target = vblank_counter + 1;

        while (vblank_counter != target) {
            asm volatile (
                \\ nop
            );
        }
    }

    pub const GP1StatusFlags = enum(u32) { CMDReady = 1 << 26 };

    pub fn waitForReady() void {
        while (!(port.ctrl.* & GP1StatusFlags.CMDReady)) {
            asm volatile (
                \\ nop
            );
        }
    }

    pub fn sendData(data: u32) void {
        port.data.* = data;
    }

    pub fn sendCmd(cmd: u32) void {
        port.ctrl = cmd;
    }

    var context: RenderContext = .{ .active_buffer = 0, .buffers = .{
        RenderBuffer{ .displayEnv = DispEnv{ .display = Rect{ .x = 0, .y = 0, .w = 0, .h = 0 }, .screen = Rect{ .x = 0, .y = 0, .w = 0, .h = 0 } }, .drawEnv = DrawEnv{ .clip = Rect{ .x = 0, .y = 0, .w = 0, .h = 0 } } },
        RenderBuffer{ .displayEnv = DispEnv{ .display = Rect{ .x = 0, .y = 0, .w = 0, .h = 0 }, .screen = Rect{ .x = 0, .y = 0, .w = 0, .h = 0 } }, .drawEnv = DrawEnv{ .clip = Rect{ .x = 0, .y = 0, .w = 0, .h = 0 } } },
    } };

    pub fn init(comptime cfg: Cfg) !void {
        SysCalls.EnterCriticalSection();

        reset();

        fifoPollingMode();
        displayMode(cfg);
        setHorizontalRange();
        setVerticalRange(cfg);
        port.ctrl.* = setDrawingStartGP0(0, 0);

        Timers.timers[1].mode = 0x100;
        Timers.timers[1].value = 0;

        // resetCommandBuffer();
        port.ctrl.* = 0x02000000; // Reset IRQ
        port.ctrl.* = 0x04000000; // Disable DMA
        port.ctrl.* = enableDisplayGP1();

        vblank_counter = 0xdeadbeef;
        const gpuEvent = SysCalls.OpenEvent(SysCalls.EventClass.TimerVBlank, 2, SysCalls.EventMode.Callback, vblank_handler);
        SysCalls.EnableEvent(gpuEvent);
        SysCalls.EnableTimerIRQ(3);
        SysCalls.SetTimerAutoAck(3, 1);

        //   Kernel.EnableDMA(Kernel.DMA.OTC, 6);
        Kernel.EnableDMA(Kernel.DMA.GPU, 7);

        port.ctrl.* = 0x04000001; // Enable DMA

        SysCalls.ExitCriticalSection();

        // context.buffers[0].drawEnv.clip.x = 0;
        // context.buffers[0].drawEnv.clip.y = 0;
        // context.buffers[0].drawEnv.clip.w = 320;
        // context.buffers[0].drawEnv.clip.h = 240;

        // initTexPage();
        // initTextureWindow();
        // initDrawingArea(cfg.w, cfg.h);
        // initDrawingAreaOffset(cfg.x, cfg.y);
        // enableDisplay();
    }

    pub fn swap() void {
        const screenWidth = 320;
        const screenHeight = 240;

        const frameX: u32 = if (context.active_buffer) 320 else 0;
        const frameY: u32 = 0;

        context.active_buffer = !context.active_buffer;

        waitForReady();
        port.data.* = texPage(0, true, false);
        port.data.* = setDrawingStartGP0(frameX, frameY);
        port.data.* = setDrawingEndGP0(frameX + screenWidth - 1, frameY + screenHeight - 2);
        // port.data.* = setDisplayAreaGP0(x, y);
    }
};
