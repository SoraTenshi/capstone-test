const std = @import("std");
const cs = @import("capstone-z");

const CODE = "\x55\x48\x8b\x05\xb8\x13\x00\x00\xe9\xea\xbe\xad\xde\xff\x25\x23\x01\x00\x00\xe8\xdf\xbe\xad\xde\x74\xff";

pub fn main() !void {
    try cs.setup.initCapstone(std.heap.page_allocator);

    var handle = try cs.open(cs.Arch.X86, cs.Mode.@"64");
    defer cs.close(&handle) catch |e| {
        std.debug.print("handle not closed cuz: {any}\n", .{e});
        unreachable;
    };

    const disass = try cs.disasm(handle, CODE, 0x1000, 0);
    defer cs.free(disass);

    for (disass, 0..) |insn, i| {
        std.debug.print("{d}: {*}: 0x{x}\t{s}\t{s}\n", .{ i, &disass.ptr[i], insn.address, insn.mnemonic, insn.op_str });
    }
}
