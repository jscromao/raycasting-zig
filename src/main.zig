//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const Allocator = std.mem.Allocator;
const vec3 = @import("modules/vec3.zig");
const ray = @import("modules/ray.zig");
const common = @import("modules/common.zig");
const Camera = @import("modules/camera.zig");
const mem = std.mem;
const io = std.io;
const fs = std.fs;
const File = fs.File;

// const Vec2 = packed struct { x: f32, y: f32 };
// const VertexDataF1 = packed struct { position: Vec3, normal: Vec3, tex: Vec2 };
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Color = vec3.Color;
const Ray = ray.Ray;

const HitRecord = @import("modules/HitRecord.zig");
const Hittable = @import("modules/hittable.zig");
const Sphere = @import("modules/sphere.zig");
const material = @import("modules/material.zig");
const Material = material.Material;
const MaterialSharedPointer = material.MaterialSharedPointer;

// const rcsp = @import("packages/rcsp.zig");
// const AllocatorPointer = rcsp.RcSharedPointer(Allocator, rcsp.NonAtomic);
// const TestMe = struct {
//     p: Point3,
//     normal: Vec3,
//     mat: ?AllocatorPointer,
//     t: f64,
//     front_face: bool,
//     pub fn init() TestMe {
//         return .{ .p = Point3.init(0.0, 0.0, 0.0), .normal = Vec3.init(0.0, 0.0, 0.0), .t = 0.0, .front_face = true, .mat = AllocatorPointer.init(std.heap.page_allocator, std.heap.page_allocator) };
//     }
// };

const HittableArrayList = std.ArrayList(Hittable);

pub const HittableList = struct {
    objects: HittableArrayList,

    pub fn init(allocator: Allocator) HittableList {
        return HittableList{ .objects = HittableArrayList.init(allocator) };
    }

    pub fn deinit(self: *HittableList) void {
        self.objects.deinit();
    }

    pub fn add(self: *HittableList, object: Hittable) !void {
        try self.objects.append(object);
    }

    pub fn hittable(self: *HittableList) Hittable {
        return Hittable.init(self); //Hittable{ .ptr = self, .vtable = .{ .got_hit = got_hit } };
    }

    fn got_hit(ctx: *anyopaque, r: *Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        const self: *HittableList = @ptrCast(@alignCast(ctx));

        var temp_rec = HitRecord.init();
        var hit_anything = false;
        var closest_so_far = t_max;

        for (self.objects.items, 0..) |*obj, i| {
            _ = i;

            //const obj: *Hittable = @ptrCast(@alignCast(&object));
            if (obj.got_hit(r, t_min, closest_so_far, &temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                //*rec = temp_rec.clone();
                // rec.*.p = temp_rec.p;
                // rec.*.normal = temp_rec.normal;
                // rec.*.t = temp_rec.t;
                // rec.*.front_face = temp_rec.front_face;
                //const as_bytes: []u8 = std.mem.asBytes(rec);
                //@memcpy(as_bytes, std.mem.asBytes(&temp_rec));
                std.mem.copyForwards(u8, std.mem.asBytes(rec), std.mem.asBytes(&temp_rec));
                //rec.* = temp_rec;
            }
        }

        return hit_anything;
    }
};

//fn ray_color(r: *Ray) Color {
fn ray_color(r: *Ray, world: *HittableList, depth: i32) !Color {
    // const tnorm = hit_sphere(Point3.init(0.0, 0.0, -1.0), 0.5, r);
    // if (tnorm > 0.0) {
    //     const n = Vec3.unit_vector(r.*.at(tnorm).sub_vec(Vec3.init(0.0, 0.0, -1.0)));
    //     return Color.init(n.x() + 1.0, n.y() + 1.0, n.z() + 1.0).mul_scalar(0.5);
    // }

    // If we've exceeded the ray bounce limit, no more light is gathered
    if (depth <= 0) {
        return Color.init(0.0, 0.0, 0.0);
    }

    var rec = HitRecord.init();
    if (HittableList.got_hit(world, r, 0.001, common.INFINITY, &rec)) {
        const direction = rec.normal.add_vec(try Vec3.random_unit_vector());
        const other_r = Ray.init(rec.p, direction);
        const new_color = try ray_color(@constCast(&other_r), world, depth - 1);
        return new_color.mul_scalar(0.5);
        //return Color.init(1.0, 1.0, 1.0).add_vec(rec.normal).mul_scalar(0.5);
    }

    const unit_direction = Vec3.unit_vector(r.direction());
    const t: f64 = 0.5 * (unit_direction.y() + 1.0);
    return Color.init(0.5, 0.7, 1.0).mul_scalar(t).add_vec(Color.init(1.0, 1.0, 1.0).mul_scalar(1.0 - t));
}

pub const OurWriterType = std.io.GenericWriter(File, File.WriteError, File.write);
fn write_color(out_buf: OurWriterType, pixel_color: Color, samples_per_pixel: i32) !void {
    var r = pixel_color.x();
    var g = pixel_color.y();
    var b = pixel_color.z();
    //std.debug.print("Pre: {} {} {}\n", .{ r, g, b });

    const scale: f64 = 1.0 / @as(f64, @floatFromInt(samples_per_pixel));
    r = std.math.sqrt(r * scale);
    g = std.math.sqrt(g * scale);
    b = std.math.sqrt(b * scale);
    // r = r * scale;
    // g = g * scale;
    // b = b * scale;
    //std.debug.print("Scaled: {} {} {}\n", .{ r, g, b });

    // const ir = @as(i32, @intFromFloat(255.999 * pixel_color.x()));
    // const ig = @as(i32, @intFromFloat(255.999 * pixel_color.y()));
    // const ib = @as(i32, @intFromFloat(255.999 * pixel_color.z()));

    const ir: i32 = @intFromFloat(common.clamp_double(r, 0.0, 0.99999) * 255.999);
    const ig: i32 = @intFromFloat(common.clamp_double(g, 0.0, 0.99999) * 255.999);
    const ib: i32 = @intFromFloat(common.clamp_double(b, 0.0, 0.99999) * 255.999);
    //std.debug.print("Out: {} {} {}\n", .{ ir, ig, ib });

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

const Lambertian = struct {
    albedo: Color,

    pub fn init(alb: Color) Lambertian {
        return .{ .albedo = alb };
    }

    pub fn material(self: *Lambertian) Material {
        return Material.init(self); //Material{ .ptr = self, .vtable = .{ .scatter_fn = scatter } };
    }

    pub fn scatter(ctx: *anyopaque, r_in: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray) bool {
        _ = r_in; // discard r_in as we don't require its use
        const self: *Lambertian = @ptrCast(@alignCast(ctx));

        const scatter_direction = rec.normal.add_vec(Vec3.random_unit_vector() catch Vec3.init(0.0, 0.0, 0.0));

        //*attenuation = self.albedo;
        //*scattered = Ray.init(rec.p, scatter_direction);
        attenuation.* = self.albedo;
        scattered.* = Ray.init(rec.p, scatter_direction);

        return true;
    }
};

pub fn main() !void {
    //const our_allocator = std.heap.GeneralPurposeAllocator(.{}).allocator();
    //var our_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const our_allocator = std.heap.page_allocator;

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
    const samples_per_pixel: i32 = 100;
    const max_depth: i32 = 50;

    var world = HittableList.init(our_allocator);
    defer world.deinit();
    // world.add(Box::new(Sphere::new(Point3::new(0.0, 0.0, -1.0), 0.5)));
    // world.add(Box::new(Sphere::new(Point3::new(0.0, -100.5, -1.0), 100.0)));

    const lamb = Lambertian.init(Color.init(0.0, 0.999, 0.0));
    const lamb_mat = Lambertian.material(@constCast(&lamb));
    const sphere_mat = try MaterialSharedPointer.init(lamb_mat, our_allocator);
    defer _ = MaterialSharedPointer.deinit(@constCast(&sphere_mat));

    const spheres = try our_allocator.alloc(Sphere, 2);
    defer our_allocator.free(spheres);
    spheres[0] = Sphere.init(Point3.init(0.0, 0.0, -1.0), 0.5, sphere_mat.strongClone());
    spheres[1] = Sphere.init(Point3.init(0.0, -100.5, -1.0), 100.0, sphere_mat);
    try world.add(spheres[0].hittable());
    try world.add(spheres[1].hittable());

    // Camera - yep
    // const viewport_height: f64 = 2.0;
    // const viewport_width = aspect_ratio * viewport_height;
    // const focal_length: f64 = 1.0;

    // const origin = Point3.init(0.0, 0.0, 0.0);
    // const horizontal = Vec3.init(viewport_width, 0.0, 0.0);
    // const vertical = Vec3.init(0.0, viewport_height, 0.0);
    // const focal = Vec3.init(0.0, 0.0, focal_length);
    // const half_horizontal = horizontal.div_scalar(2.0);
    // const half_vertical = vertical.div_scalar(2.0);
    // //const lower_left_corner = origin - half_horizontal - half_vertical - focal;
    // const lower_left_corner = origin.sub_vec(half_horizontal).sub_vec(half_vertical).sub_vec(focal);

    var cam = Camera.init(aspect_ratio);

    // Render

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    for (0..image_height) |asc_j| {
        const j: usize = image_height - 1 - asc_j;
        try stderr.print("\rProgress - {} ", .{j});

        for (0..image_width) |i| {
            // const u: f64 = @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(image_width - 1));
            // const v: f64 = @as(f64, @floatFromInt(j)) / @as(f64, @floatFromInt(image_height - 1));
            // const r = Ray.init(origin, lower_left_corner.add_vec(horizontal.mul_scalar(u)).add_vec(vertical.mul_scalar(v)).sub_vec(origin));
            // //const pixel_color = ray_color(@constCast(&r));
            // const pixel_color = ray_color(@constCast(&r), @constCast(&world));

            // try write_color(stdout, pixel_color, samples_per_pixel);

            var pixel_color = Color.init(0.0, 0.0, 0.0);
            for (0..samples_per_pixel) |_| {
                const u: f64 = (@as(f64, @floatFromInt(i)) + try common.random_double()) / @as(f64, @floatFromInt(image_width - 1));
                const v: f64 = (@as(f64, @floatFromInt(j)) + try common.random_double()) / @as(f64, @floatFromInt(image_height - 1));
                const r = cam.get_ray(u, v);

                //const pixel_color = ray_color(@constCast(&r));
                //const pixel_color = ray_color(@constCast(&r), @constCast(&world));
                pixel_color = pixel_color.add_vec(try ray_color(@constCast(&r), @constCast(&world), max_depth));
            }
            try write_color(stdout, pixel_color, samples_per_pixel);
        }
    }

    try stderr.print("\rProgress - Done! \n", .{});

    //try bw.flush(); // Don't forget to flush!
    //try stderr_buffer.flush();
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
