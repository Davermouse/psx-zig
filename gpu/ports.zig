pub const Data = packed struct { reserved: u24, cmd: enum(u8) { GP0, GP1 } };

pub const data: *volatile u32 = @ptrFromInt(0x1f801810);
pub const ctrl: *volatile u32 = @ptrFromInt(0x1f801814);
