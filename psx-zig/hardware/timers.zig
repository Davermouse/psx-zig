pub const Timer = packed struct { padding3: u32, padding4: u16, target: u16, padding2: u16, mode: u16, padding1: u16, value: u16 };

pub const timers: *volatile [3]Timer = @ptrFromInt(0x1F801100);
