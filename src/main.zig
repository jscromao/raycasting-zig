//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const vec3 = @import("modules/vec3.zig");
const ray = @import("modules/ray.zig");
const mem = std.mem;
const io = std.io;
const fs = std.fs;
const File = fs.File;

// const Vec2 = packed struct { x: f32, y: f32 };
// const VertexDataF1 = packed struct { position: Vec3, normal: Vec3, tex: Vec2 };
const Vec3 = vec3.Vec3;
const Point3 = Vec3;
const Color = Vec3;
const Ray = ray.Ray;

fn ray_color(r: *Ray) Color {
    const unit_direction = Vec3.unit_vector(r.direction());
    const t: f64 = 0.5 * (unit_direction.y() + 1.0);
    return Color.init(0.5, 0.7, 1.0).mul_scalar(t).add_vec(Color.init(1.0, 1.0, 1.0).mul_scalar(1.0 - t));
}

fn write_color(out_buf: std.io.GenericWriter(File, File.WriteError, File.write), pixel_color: Color) !void {
    const ir = @as(i32, @intFromFloat(255.999 * pixel_color.x()));
    const ig = @as(i32, @intFromFloat(255.999 * pixel_color.y()));
    const ib = @as(i32, @intFromFloat(255.999 * pixel_color.z()));

    try out_buf.print("{} {} {}\n", .{ ir, ig, ib });
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    //std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    //const stdout_file = std.io.getStdOut().writer();
    //var bw = std.io.bufferedWriter(stdout_file);
    //const stdout = bw.writer();
    const stdout = io.getStdOut().writer();

    //const stderr_file = ;
    //var stderr_buffer = std.io.bufferedWriter(std.io.getStdErr().writer());
    //const stderr = stderr_buffer.writer();
    const stderr = io.getStdErr().writer();

    // const v = Vec3.init(0.5, 0.25, 0.3);
    // const vx = v.x();
    // try stderr.print("\nVx is {}\n", .{vx});

    // const IMAGE_WIDTH = 256;
    // const IMAGE_HEIGHT = 256;

    // Image
    const aspect_ratio: f64 = 16.0 / 9.0;
    const image_width: u32 = 400;
    const image_height: u32 = @as(u32, @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio));

    // Camera
    const viewport_height: f64 = 2.0;
    const viewport_width = aspect_ratio * viewport_height;
    const focal_length: f64 = 1.0;

    const origin = Point3.init(0.0, 0.0, 0.0);
    const horizontal = Vec3.init(viewport_width, 0.0, 0.0);
    const vertical = Vec3.init(0.0, viewport_height, 0.0);
    const focal = Vec3.init(0.0, 0.0, focal_length);
    const half_horizontal = horizontal.div_scalar(2.0);
    const half_vertical = vertical.div_scalar(2.0);
    //const lower_left_corner = origin - half_horizontal - half_vertical - focal;
    const lower_left_corner = origin.sub_vec(half_horizontal).sub_vec(half_vertical).sub_vec(focal);

    // Render

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    for (0..image_height) |asc_j| {
        const j: usize = image_height - 1 - asc_j;
        try stderr.print("\rScanlines remaining: {} ", .{j});

        for (0..image_width) |i| {
            // const r: f64 = @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(image_width - 1));
            // const g: f64 = @as(f64, @floatFromInt(j)) / @as(f64, @floatFromInt(image_height - 1));
            // const b: f64 = 0.25;
            // const pixel_color = Color.init(r, g, b);

            const u: f64 = @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(image_width - 1));
            const v: f64 = @as(f64, @floatFromInt(j)) / @as(f64, @floatFromInt(image_height - 1));
            const r = Ray.init(origin, lower_left_corner.add_vec(horizontal.mul_scalar(u)).add_vec(vertical.mul_scalar(v)).sub_vec(origin));
            const pixel_color = ray_color(@constCast(&r));

            try write_color(stdout, pixel_color);
        }
    }

    try stderr.print("\nDone.\n", .{});

    //try bw.flush(); // Don't forget to flush!
    //try stderr_buffer.flush();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    // Try passing `--fuzz` to `zig build` and see if it manages to fail this test case!
    const input_bytes = std.testing.fuzzInput(.{});
    try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input_bytes));
}
