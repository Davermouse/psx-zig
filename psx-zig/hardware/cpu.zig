pub const IrqChannels = enum(u32) {
    VBlank = 1,
    GPU = 2,
    CDRom = 4,
    DMA = 8,
};

pub const dpcr: *volatile u32 = @ptrFromInt(0x1f8010f0);
pub const dicr: *volatile u32 = @ptrFromInt(0x1f8010f4);

pub const ireg: *volatile u32 = @ptrFromInt(0x1F801070);
pub const imask: *volatile u32 = @ptrFromInt(0x1F801074);
