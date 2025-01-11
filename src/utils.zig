const std = @import("std");

pub fn generateUUID64() !u64 {
    var rng = std.rand.DefaultPrng.init(@intCast(std.time.microTimestamp()));
    return rng.random().int(u64);
}
