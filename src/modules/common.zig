const std = @import("std");

pub const INFINITY: f64 = std.math.inf(f64);

const earliest = std.time.Instant{ .timestamp = @as(u64, 0) };
var rng: std.Random.Xoshiro256 = undefined;
var last_rng_created: std.time.Instant = std.time.Instant{ .timestamp = @as(u64, 0) };

pub fn degrees_to_radians(degrees: f64) f64 {
    return degrees * std.math.rad_per_deg;
}

/// Return a random f64 in [0.0, 1.0)
pub fn random_double() !f64 {
    //var rnd = std.Random.DefaultPrng.init(@as(u64, @bitCast(std.time.microTimestamp())));
    //var rnd = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
    //const curr_micro_ts = @as(u64, @bitCast(std.time.microTimestamp()));
    const now = try std.time.Instant.now();

    if (last_rng_created.since(earliest) == 0) {
        last_rng_created = now;
        rng = std.Random.DefaultPrng.init(0);
    } else {
        const diff = now.since(last_rng_created);
        if (diff > 0) {
            last_rng_created = now;
            rng = std.Random.DefaultPrng.init(diff);
        }
    }

    //var rnd = std.Random.DefaultPrng.init(0);
    const num = rng.random().float(f64);
    //std.debug.print("Random double: {d}\n", .{num});
    return num;
}

/// Return a random f64 in [min, max)
pub fn random_double_range(min: f64, max: f64) !f64 {
    return min + (max - min) * try random_double();
}

pub fn clamp_double(value: f64, min: f64, max: f64) f64 {
    if (value < min) {
        return min;
    }
    if (value > max) {
        return max;
    }
    return value;
}
