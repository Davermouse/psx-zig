pub inline fn EnterCriticalSection() void {
    asm volatile (
        \\ li $a0, 0x01
        \\ syscall 0
        ::: .{ .r2 = true, .r4 = true, .memory = true });
}

pub inline fn ExitCriticalSection() void {
    asm volatile (
        \\ li $a0, 0x02
        \\ syscall 0
        ::: .{ .r2 = true, .r4 = true, .memory = true });
}

// pub inline fn FastEnterCriticalSection() void {
//     const v = 0x40000000;

//     asm volatile (
//         \\ mtc0 %[val], $12
//         \\ nop
//         \\ nop
//         :
//         : [val] "a0" (v),
//     );
// }

// pub inline fn FastExitCriticalSection() void {
//     asm volatile (
//         \\ mtc0 $a0, $12
//         :
//         : [val] "a0" (0x40000401),
//     );
// }

pub const EventClass = enum(u32) {
    VBlank = 0xf0000001,
    Gpu = 0xf0000002,
    CDRom = 0xf0000003,
    DMA = 0xf0000004,
    RTC0 = 0xf0000005,
    RTC1 = 0xf0000006,
    Controller = 0xf0000008,
    SPU = 0xf0000009,
    PIO = 0xf000000a,
    SIO = 0xf000000b,
    Card = 0xf0000011,
    BU = 0xf4000001,
    Timer0 = 0x2000000,
    Timer1 = 0x2000001,
    Timer2 = 0x2000002,
    TimerVBlank = 0xf2000003,
};

pub const EventMode = enum(u32) {
    Callback = 0x1000,
    NoCallback = 0x2000,
};

const NoParamSysCall = *const fn () callconv(.c) void;
const OneParamSysCall = *const fn (a: u32) callconv(.c) void;
const TwoParamSysCall = *const fn (a: u32, b: u32) callconv(.c) void;

const OpenEventSysCall = *const fn (classId: u32, spec: u32, mode: u32, handler: u32) callconv(.c) u32;
const EventId = u32;
const IrqHandler = *const fn () void;

const SyscallA = @as(OpenEventSysCall, @ptrFromInt(0xa0));
const SyscallB = @as(OpenEventSysCall, @ptrFromInt(0xb0));
const SyscallC = @as(OpenEventSysCall, @ptrFromInt(0xc0));

pub fn FlushCache() void {
    _ = asm volatile (
        \\ li $t1, 0x44
        ::: .{ .r9 = true, .r1 = true, .r2 = true, .r3 = true, .memory = true });

    @as(NoParamSysCall, @ptrFromInt(0xa0))();
}

pub fn EnableTimerIRQ(timer: u32) void {
    asm volatile (
        \\ li $t1, 0x04
        ::: .{
            .r9 = true,
        });

    @as(OneParamSysCall, @ptrFromInt(0xb0))(timer);
}

// If this is inlined we end up with invalid ASM and a bad EventClass is set
pub fn OpenEvent(classId: EventClass, spec: u32, mode: EventMode, handler: IrqHandler) EventId {
    asm volatile (
        \\ li $t1, 0x08
        ::: .{
            .r9 = true,
        });

    const eventId = SyscallB(@intFromEnum(classId), spec, @intFromEnum(mode), @intFromPtr(handler));

    return eventId;
}

pub fn EnableEvent(eventId: EventId) void {
    asm volatile (
        \\ li $t1, 0x0c
        ::: .{
            .r9 = true,
        });

    @as(OneParamSysCall, @ptrFromInt(0xb0))(eventId);
}

pub fn SetDefaultExceptionJmpbuf() void {
    asm volatile (
        \\ li $t1, 0x18
    );

    @as(NoParamSysCall, @ptrFromInt(0xb0))();
}

pub fn EnqueueRcntIrqs(prio: u32) void {
    _ = asm volatile (
        \\ li $t1, 0x00
        ::: .{ .r9 = true, .r1 = true, .r2 = true, .r3 = true, .memory = true });

    @as(OneParamSysCall, @ptrFromInt(0xc0))(prio);
}

pub fn EnqueueSyscallHandler(prio: u32) void {
    asm volatile (
        \\ li $t1, 0x01
        ::: .{
            .r9 = true,
        });

    @as(OneParamSysCall, @ptrFromInt(0xc0))(prio);
}

pub fn SetTimerAutoAck(timer: u32, value: u32) void {
    asm volatile (
        \\ li $t1, 0x0a
        ::: .{
            .r9 = true,
        });

    @as(TwoParamSysCall, @ptrFromInt(0xc0))(timer, value);
}

pub fn EnqueueIrqHandler(prio: u32) void {
    asm volatile (
        \\ li $t1, 0x0c
        ::: .{
            .r9 = true,
        });

    @as(OneParamSysCall, @ptrFromInt(0xc0))(prio);
}
