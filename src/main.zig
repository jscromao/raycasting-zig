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

pub const HitRecord = struct {
    p: Point3,
    normal: Vec3,
    t: f64,

    pub fn init() HitRecord {
        return .{ .p = Point3.init(0.0, 0.0, 0.0), .normal = Vec3.init(0.0, 0.0, 0.0), .t = 0.0 };
    }
};

pub const Hittable = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        got_hit: *const fn (ctx: *anyopaque, r: *Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool,
    };
};

pub const Sphere = struct {
    center: Point3,
    radius: f64,

    pub fn init(cen: Point3, r: f64) Sphere {
        return Sphere{ .center = cen, .radius = r };
    }

    fn got_hit(ctx: *anyopaque, r: *Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        const self: *Sphere = @ptrCast(@alignCast(ctx));

        const oc = r.origin().sub_vec(self.center);
        const a = r.direction().length_squared();
        const half_b = Vec3.dot(oc, r.direction());
        const c: f64 = oc.length_squared() - self.radius * self.radius;
        const discriminant: f64 = half_b * half_b - a * c;
        if (discriminant < 0.0) {
            return false;
        }

        const sqrt_d: f64 = @sqrt(discriminant);

        // Find the nearest root that lies in the acceptable range
        var root: f64 = (-half_b - sqrt_d) / a;
        if ((root <= t_min) || (root >= t_max)) {
            root = (-half_b + sqrt_d) / a;
            if ((root <= t_min) || (root >= t_max)) {
                return false;
            }
        }

        rec.t = root;
        rec.p = r.at(rec.t);
        rec.normal = (rec.p.sub_vec(self.center)) / self.radius;
        return true;
    }

    pub fn hittable(self: *Sphere) Hittable {
        return Hittable{ .ptr = self, .vtable = .{
            .got_hit = got_hit,
        } };
    }
};

fn ray_color(r: *Ray) Color {
    const tnorm = hit_sphere(Point3.init(0.0, 0.0, -1.0), 0.5, r);
    if (tnorm > 0.0) {
        const n = Vec3.unit_vector(r.*.at(tnorm).sub_vec(Vec3.init(0.0, 0.0, -1.0)));
        //return Color.init(1.0, 0.0, 0.0);
        return Color.init(n.x() + 1.0, n.y() + 1.0, n.z() + 1.0).mul_scalar(0.5);
    }

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

fn hit_sphere(center: Point3, radius: f64, r: *Ray) f64 {
    const dray = r.*;
    const orig_to_center = dray.origin().sub_vec(center);
    const squared_otc_len = Vec3.dot(orig_to_center, orig_to_center);
    const dir = dray.direction();
    const squared_dir_len = Vec3.dot(dir, dir);
    const how_aligned_otc_dir = Vec3.dot(orig_to_center, dir);

    const a: f64 = squared_dir_len;
    const b: f64 = 2.0 * how_aligned_otc_dir;
    const c: f64 = squared_otc_len - radius * radius;

    // t = (-b +- sqrt(discriminant)) / 2a
    // discriminant = b^2 - 4ac
    const discriminant: f64 = b * b - 4.0 * a * c;

    // does ray intersect the sphere?
    // discriminant < 0 means 0 intersection points
    // discriminant == 0 means 1 intersection point
    // discriminant > 0 means 2 intersection points
    // So discriminant >= 0 means there is some level of intersection
    //return discriminant >= 0.0;

    if (discriminant < 0.0) {
        return -1.0;
    } else {
        return (-b - @sqrt(discriminant)) / (2.0 * a);
    }
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    //std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    //const stdout_file = std.io.getStdOut().writer();
    //var bw = std.io.bufferedWriter(stdout_file);
    //const stdout = bw.writer();
    const stdout = io.getStdOut().writer();

    //const stderr_file = ;
    //var stderr_buffer = std.io.bufferedWriter(std.io.getStdErr().writer());
    //const stderr = stderr_buffer.writer();
    const stderr = io.getStdErr().writer();

    // Image
    const aspect_ratio: f64 = 16.0 / 9.0;
    const image_width: u32 = 400;
    const image_height: u32 = @as(u32, @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio));

    // Camera - yep
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
        try stderr.print("\rProgress - {} ", .{j});

        for (0..image_width) |i| {
            const u: f64 = @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(image_width - 1));
            const v: f64 = @as(f64, @floatFromInt(j)) / @as(f64, @floatFromInt(image_height - 1));
            const r = Ray.init(origin, lower_left_corner.add_vec(horizontal.mul_scalar(u)).add_vec(vertical.mul_scalar(v)).sub_vec(origin));
            const pixel_color = ray_color(@constCast(&r));

            try write_color(stdout, pixel_color);
        }
    }

    try stderr.print("\rProgress - Done! \n", .{});

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
