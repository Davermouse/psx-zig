const Cpu = @import("hardware/cpu.zig");
const SysCalls = @import("syscalls.zig");
const Debug = @import("Debug.zig").Debug;

const KernelData = packed struct { data: [*]u8, length: u32 };

pub const DMA = enum(u3) { MDECin, MDECout, GPU, CDRom, SPU, EXP1, OTC };

fn dmaCallback() void {
    Cpu.ireg.* = Cpu.ireg.* & ~@intFromEnum(Cpu.IrqChannels.DMA);

    //var dicr = Cpu.dicr.*;
}

pub fn Install() void {
    Cpu.imask.* = 0;
    Cpu.ireg.* = 0;

    Cpu.dpcr.* = 0;
    const dicr = Cpu.dicr.*;
    Cpu.dicr.* = dicr;
    Cpu.dicr.* = 0;

    SysCalls.FlushCache();

    const handlerData = @as(*KernelData, @ptrFromInt(0x100));
    const handlerSlice = handlerData.data[0..handlerData.length];
    @memset(handlerSlice, 0);

    const eventsData = @as(*KernelData, @ptrFromInt(0x120));
    const eventsSlice = eventsData.data[0..eventsData.length];
    @memset(eventsSlice, 0);

    SysCalls.SetDefaultExceptionJmpbuf();
    SysCalls.EnqueueSyscallHandler(0);
    SysCalls.EnqueueIrqHandler(3);
    SysCalls.EnqueueRcntIrqs(1);

    const dmaEvent = SysCalls.OpenEvent(SysCalls.EventClass.DMA, 0x1000, SysCalls.EventMode.Callback, dmaCallback);
    SysCalls.EnableEvent(dmaEvent);
}

pub fn EnableDMA(channel: DMA, priority: u3) void {
    // const DMASettings = packed struct(u4) { priority: u3, enabled: u1 };

    var dpcr = Cpu.dpcr.*;
    if (priority > 7) priority = 7;
    const shift: u4 = @intFromEnum(channel) * 4;

    const mask = @as(u32, 15) << shift;
    dpcr &= ~mask;

    var val = @as(u32, priority);
    val |= 8;
    val <<= shift;
    dpcr |= mask;

    Cpu.dpcr.* = dpcr;

    // const settings = DMASettings{ .enabled = 1, .priority = priority };
    // const narrowSettings: u4 = @bitCast(settings);
    // const update: u32 = @as(u32, narrowSettings) << shift;

    // dpcr |= update;

    // Cpu.dpcr.* = dpcr;

    _ = Debug.puts("DMA Enabled");
}

pub fn HandleIrq() void {}
