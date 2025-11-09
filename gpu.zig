pub const Pos = u16;
pub const VRAM_W: Pos = 1024;
pub const VRAM_H: Pos = 512;
const fmt = @import("fmt/fmt.zig");

const Debug = @import("Debug.zig");

pub const Gpu = struct {
    const port = @import("gpu/ports.zig");

    pub const Cfg = struct { x: Pos = 0, y: Pos = 0, w: Pos, h: Pos };

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

    fn reset() void {
        port.ctrl.* = 0;
    }

    fn enableDisplay() void {
        const DisplayEnable = packed struct { enable: enum(u1) { On = 0, Off = 1 } = .On, reserved: u23 = 0, cmd: u8 = 0x03 };

        port.ctrl.* = @bitCast(DisplayEnable{});
    }

    fn quickFill(color: Color, position: SVector, size: SVector) void {
        const QuickFillCommand = packed struct { color: Color, command: u8 = 0x02 };

        port.data.* = @bitCast(QuickFillCommand{ .color = color });

        port.data.* = @bitCast(position);
        port.data.* = @bitCast(size);
    }

    pub fn init(comptime cfg: Cfg) !void {
        comptime {
            const screen_widths = [_]Pos{ 320, 368 };
            const screen_heights = [_]Pos{240};

            blk: {
                for (screen_widths) |width| {
                    if (width == cfg.w) {
                        break :blk;
                    }
                }
                @compileError("Invalid width");
            }

            blk: {
                for (screen_heights) |height| {
                    if (height == cfg.h) {
                        break :blk;
                    }
                }
                @compileError("Invalid height");
            }
        }

        reset();
        port.ctrl.* = 0x01000000; // Reset command buffer
        port.ctrl.* = 0x02000000; // Reset IRQ
        port.ctrl.* = 0x04000000; // Disable DMA
        enableDisplay();

        quickFill(Color{ .r = 0, .g = 0, .b = 0xff }, SVector{ .x = 0x04, .y = 0x40 }, SVector{ .x = 0x40, .y = 0x40 });

        // initTexPage();
        // initTextureWindow();
        // initDrawingArea(cfg.w, cfg.h);
        // initDrawingAreaOffset(cfg.x, cfg.y);
        // enableDisplay();
    }
};
