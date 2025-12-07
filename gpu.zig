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

    pub const SVector = packed struct { x: u16, y: u16 };

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

        port.ctrl.* - 0x4000002; // DMA to GP0
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

    fn setDisplayStart(x: u10, y: u9) void {
        const DisplayStartCommand = packed struct(u32) { x: u10, y: u9, reserved: u5, command: u8 };

        port.ctrl.* = @bitCast(DisplayStartCommand{ .x = x, .y = y, .command = 0x05, .reserved = 0 });
    }

    fn resetCommandBuffer() void {
        const ResetCommandBuffer = packed struct(u32) { reserved: u30 = 0, command: u2 = 0x02 };
        port.ctrl.* = @bitCast(ResetCommandBuffer{});
    }

    fn enableDisplay() void {
        const DisplayEnable = packed struct { enable: enum(u1) { On = 0, Off = 1 } = .On, reserved: u23 = 0, cmd: u8 = 0x03 };

        port.ctrl.* = @bitCast(DisplayEnable{});
    }

    pub fn quickFill(color: Color, position: SVector, size: SVector) void {
        const QuickFillCommand = packed struct { color: Color, command: u8 = 0x02 };

        port.data.* = @bitCast(QuickFillCommand{ .color = color });

        port.data.* = @bitCast(position);
        port.data.* = @bitCast(size);
    }

    pub fn wait_vsync() void {
        const imask = Cpu.imask.*;

        Cpu.imask.* = imask | @intFromEnum(Cpu.IrqChannels.VBlank);

        while ((Cpu.ireg.* & @intFromEnum(Cpu.IrqChannels.VBlank)) == 0) {
            // asm volatile (
            //     \\ nop
            // );
        }

        Cpu.ireg.* &= ~@intFromEnum(Cpu.IrqChannels.VBlank);
        Cpu.imask.* = imask;
    }

    pub fn vblank() void {
        const target = vblank_counter + 1;

        while (vblank_counter != target) {
            asm volatile (
                \\ nop
            );
        }
    }

    pub fn init(comptime cfg: Cfg) !void {
        SysCalls.EnterCriticalSection();

        reset();
        fifoPollingMode();
        displayMode(cfg);
        setHorizontalRange();
        setVerticalRange(cfg);
        setDisplayStart(0, 0);

        Timers.timers[1].mode = 0x100;
        Timers.timers[1].value = 0;

        // resetCommandBuffer();
        port.ctrl.* = 0x02000000; // Reset IRQ
        port.ctrl.* = 0x04000000; // Disable DMA
        enableDisplay();

        vblank_counter = 0xdeadbeef;
        const gpuEvent = SysCalls.OpenEvent(SysCalls.EventClass.TimerVBlank, 2, SysCalls.EventMode.Callback, vblank_handler);
        SysCalls.EnableEvent(gpuEvent);
        SysCalls.EnableTimerIRQ(3);
        SysCalls.SetTimerAutoAck(3, 1);

        //   Kernel.EnableDMA(Kernel.DMA.GPU, 7);
        //   Kernel.EnableDMA(Kernel.DMA.OTC, 7);

        port.ctrl.* = 0x04000001; // Disable DMA

        SysCalls.ExitCriticalSection();

        // initTexPage();
        // initTextureWindow();
        // initDrawingArea(cfg.w, cfg.h);
        // initDrawingAreaOffset(cfg.x, cfg.y);
        // enableDisplay();
    }
};
