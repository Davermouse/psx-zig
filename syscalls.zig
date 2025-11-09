pub const Syscalls = struct {
    fn EnterCriticalSection() void {
        asm volatile (
            \\ li $a0, 0x01
            \\ syscall 0
        );
    }

    fn ExitCriticalSection() void {
        asm volatile (
            \\ li $a0, 0x01
            \\ syscall 0
        );
    }
};
