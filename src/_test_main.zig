//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const io = std.io;
const common = @import("modules/common.zig");
const FloatMode = std.builtin.FloatMode;

pub fn main() !void {
    //@setFloatMode(FloatMode.optimized);
    comptime @setFloatMode(.optimized);

    //const our_allocator = std.heap.page_allocator;
    //const our_allocator = std.heap.GeneralPurposeAllocator(.{}).allocator();
    // var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // const our_allocator = arena_allocator.allocator();
    // defer arena_allocator.deinit();

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    // const stdout = io.getStdOut().writer();
    // const stderr = io.getStdErr().writer();

    // const RndGen = std.Random.DefaultPrng;
    // var rnd = RndGen.init(@bitCast(std.time.milliTimestamp()));
    // var rando = rnd.random();

    // OurRandos: -0.29280329860470816, -0.7131206168144315, -0.1053211603531886
    // OurRandos: -2.43645251565255, -0.006746890245517888, -1.3049728444939162
    // OurRandos: 1.185876184011458, 1.2539918619246457, -0.6316069317606559
    // OurRandos: -0.3255520584715379, -0.8617113779812624, -1.9462432319533063

    var a: i32 = -6;
    while (a < 6) {
        var b: i32 = -6;
        while (b < 6) {
            const num_a = common.freshest_random_double();
            const num_b: f64 = common.freshest_random_double();
            const num_c: f64 = common.freshest_random_double();
            // const num_a = rando.floatNorm(f64);
            // const num_b = rando.floatNorm(f64);
            // const num_c = rando.floatNorm(f64);

            std.debug.print("OurRandos: {d}, {d}, {d}\n", .{ num_a, num_b, num_c });
            b = b + 1;
        }
        a = a + 1;
    }

    //std.debug.print("Num Spheres: {d}\n", .{spheres.items.len});
    // std.debug.print("5th last:\n{}\n", .{spheres.items[spheres.items.len - 1 - 5]});
    // std.debug.print("4th last:\n{}\n", .{spheres.items[spheres.items.len - 1 - 4]});

    // for (world.objects.items) |*hit| {
    //     const our_sphere: *Sphere = @ptrCast(@alignCast(hit.*.ptr));
    //     std.debug.print("OurSphere: {d}, {d}, {d}\n", .{ our_sphere.center.x(), our_sphere.center.y(), our_sphere.center.z() });
    // }
}

test "simple test" {
    const list_type = std.ArrayList(i32);
    var list = list_type.init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    // Try passing `--fuzz` to `zig build` and see if it manages to fail this test case!
    const input_bytes = std.testing.fuzzInput(.{});
    try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input_bytes));
}
