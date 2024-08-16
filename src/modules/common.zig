const std = @import("std");
comptime {
    @setFloatMode(.optimized);
}
pub const INFINITY: f64 = std.math.inf(f64);

const earliest = std.time.Instant{ .timestamp = @as(u64, 0) };
var rng: ?std.Random.Xoshiro256 = null;
var last_rng_created: std.time.Instant = std.time.Instant{ .timestamp = @as(u64, 0) };
var rnd: ?std.Random.Xoshiro256 = null;
var iter: u64 = 0;

const NRndGen = std.Random.DefaultPrng;
var n_rnd: ?std.Random.Xoshiro256 = null;
var n_rando: ?std.Random = null;

pub fn degrees_to_radians(degrees: f64) f64 {
    return degrees * std.math.rad_per_deg;
}

pub fn random_double() f64 {
    @setFloatMode(.optimized);
    // if (n_rnd == null) {
    //     n_rnd = NRndGen.init(@bitCast(std.time.milliTimestamp()));
    // }
    // if ((n_rnd != null) and (n_rando == null)) {
    //     n_rando = n_rnd.?.random();
    // }

    if (n_rando) |v| {
        return v.float(f64);
    } else {
        //std.debug.print("ERM EXCUSE ME", .{});
        n_rnd = NRndGen.init(@bitCast(std.time.milliTimestamp()));
        n_rando = n_rnd.?.random();
        return n_rando.?.float(f64);
    }
    return @as(f64, 0.4999);
}

// /// Return a random f64 in [0.0, 1.0)
// pub fn random_double() !f64 {
//     // const now = try std.time.Instant.now();

//     // if (last_rng_created.since(earliest) == 0) {
//     //     last_rng_created = now;
//     //     rng = std.Random.DefaultPrng.init(0);
//     // } else {
//     //     const diff = now.since(last_rng_created);
//     //     if (diff > 0) {
//     //         last_rng_created = now;
//     //         rng = std.Random.DefaultPrng.init(diff);
//     //     }
//     // }

//     // return rng.random().float(f64);

//     if (rnd) |*v| {
//         v.seed(v.next());
//         return v.random().float(f64);
//     } else {
//         std.debug.print("Generating rnd again?!", .{});
//         rnd = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
//         //const rando = rng.?.random();
//         return rnd.?.random().float(f64);
//     }
// }

// pub fn fresh_random_double() !f64 {
//     const now = try std.time.Instant.now();

//     if (last_rng_created.since(earliest) == 0) {
//         last_rng_created = now;
//         rng = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
//     } else {
//         //const diff = now.since(last_rng_created);
//         //if (diff > 0) {
//         last_rng_created = now;
//         iter += 1;
//         rng = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
//         //}
//     }

//     return rng.?.random().float(f64);
// }

/// Return a random f64 in [min, max)
pub fn random_double_range(min: f64, max: f64) f64 {
    return min + (max - min) * random_double();
}

pub fn clamp_double(value: f64, min: f64, max: f64) f64 {
    if (value <= min) {
        return min;
    } else if (value >= max) {
        return max;
    } else {
        return value;
    }
}
