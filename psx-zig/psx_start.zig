extern var __bss_start: u8;
extern var __bss_end: u8;

extern fn main() void;

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

    while (true) {
        asm volatile (
            \\ nop
        );
    }
}
