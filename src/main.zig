const std = @import("std");

const cs = @cImport({
    @cInclude("capstone/capstone.h");
});

const CODE = "\x55\x48\x8b\x05\xb8\x13\x00\x00\xe9\xea\xbe\xad\xde\xff\x25\x23\x01\x00\x00\xe8\xdf\xbe\xad\xde\x74\xff";

// malloc: cs_malloc_t = @import("std").mem.zeroes(cs_malloc_t),
// calloc: cs_calloc_t = @import("std").mem.zeroes(cs_calloc_t),
// realloc: cs_realloc_t = @import("std").mem.zeroes(cs_realloc_t),
// free: cs_free_t = @import("std").mem.zeroes(cs_free_t),
// vsnprintf: cs_vsnprintf_t = @import("std").mem.zeroes(cs_vsnprintf_t),

pub extern "c" fn calloc(usize, usize) callconv(.C) ?*anyopaque;
pub extern "c" fn vsnprintf([*c]u8, usize, [*c]const u8, [*c]cs.struct___va_list_tag_1) callconv(.C) c_int;

pub fn main() !void {
    const sys_mem = cs.cs_opt_mem{
        .malloc = &std.c.malloc,
        .realloc = &std.c.realloc,
        .free = &std.c.free,
        .calloc = &calloc,
        .vsnprintf = &vsnprintf,
    };

    std.debug.print("\noption: {d}\n", .{cs.cs_option(0, cs.CS_OPT_MEM, @intFromPtr(&sys_mem))});

    var handle: cs.csh = 0;
    var insn: [*c]cs.cs_insn = undefined;

    const err = cs.cs_open(cs.CS_ARCH_X86, cs.CS_MODE_64, &handle);
    if (err != cs.CS_ERR_OK) {
        std.debug.print("Failed with: {d}\n", .{err});
        return error.CSOpenFailed;
    }

    const count = cs.cs_disasm(handle, CODE, CODE.len, 0x1000, 0, @ptrCast(&insn));
    if (count > 0) {
        for (0..count) |j| {
            std.debug.print("{d}: {*}: 0x{x}\t{s}\t{s}\n", .{ j, &insn[j], insn[j].address, insn[j].mnemonic, insn[j].op_str });
        }
        cs.cs_free(insn, count);
    } else {
        std.debug.print("ERROR: Failed to disassemble given code!\n", .{});
    }
    _ = cs.cs_close(&handle);
}
