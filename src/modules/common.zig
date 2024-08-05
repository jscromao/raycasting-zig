const std = @import("std");
pub const INFINITY: f64 = std.math.inf(f64);

pub fn degrees_to_radians(degrees: f64) f64 {
    return degrees * std.math.rad_per_deg;
}
