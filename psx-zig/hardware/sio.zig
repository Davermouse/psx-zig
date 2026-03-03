pub const io_base = 0xbf801000;

pub const sio_data_0: *volatile u8 = io_base | 0x040 + (16 * 0);
pub const sio_stat_0: *volatile u8 = io_base | 0x044 + (16 * 0);
pub const sio_mode_0: *volatile u8 = io_base | 0x048 + (16 * 0);
pub const sio_ctrl_0: *volatile u8 = io_base | 0x04a + (16 * 0);
pub const sio_baud_0: *volatile u8 = io_base | 0x04e + (16 * 0);
