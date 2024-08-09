const std = @import("std");

pub const INFINITY: f64 = std.math.inf(f64);

pub fn degrees_to_radians(degrees: f64) f64 {
    return degrees * std.math.rad_per_deg;
}

/// Return a random f64 in [0.0, 1.0)
pub fn random_double() f64 {
    const rnd = std.rand.DefaultPrng.init(@as(u64, @bitCast(std.time.milliTimestamp())));
    const num = rnd.random().float(f64);
    return num;
}

/// Return a random f64 in [min, max)
pub fn random_double_range(min: f64, max: f64) f64 {
    return min + (max - min) * random_double();
}
