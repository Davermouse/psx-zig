pub const Debug = struct {
    pub noinline fn puts(str: [*:0]const u8) c_int {
        return asm volatile (
            \\ li $t2, 0xa0
            \\ li $t1, 0x3f
            \\ jr $t2
            : [ret] "={$2}" (-> c_int),
            : [str] "{$4}" (str),
        );
    }
};
