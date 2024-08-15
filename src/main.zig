const std = @import("std");
const FloatMode = std.builtin.FloatMode;

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
const HittableList = @import("modules/HittableList.zig");
const material = @import("modules/material.zig");
const Material = material.Material;
const MaterialSharedPointer = material.MaterialSharedPointer;
const Lambertian = material.Lambertian;
const Metal = material.Metal;
const Dielectric = material.Dielectric;

fn ray_color(r: *Ray, world: *HittableList, depth: i32) !Color {
    comptime @setFloatMode(.optimized);
    // If we've exceeded the ray bounce limit, no more light is gathered
    if (depth <= 0) {
        return Color.init(0.0, 0.0, 0.0);
    }

    var rec = HitRecord.init();
    if (HittableList.got_hit(world, r, 0.001, common.INFINITY, &rec)) {
        var attenuation = Color.init(0.0, 0.0, 0.0);
        var scattered = Ray.init(Point3.init(0.0, 0.0, 0.0), Vec3.init(0.0, 0.0, 0.0));

        if (rec.mat) |mat| {
            if (mat.unsafePtr().scatter(r, &rec, &attenuation, &scattered)) {
                return attenuation.mul_vec(try ray_color(&scattered, world, depth - 1));
            }
        }

        return Color.init(0.0, 0.0, 0.0);
    }

    const unit_direction = Vec3.unit_vector(r.direction());
    const t: f64 = 0.5 * (unit_direction.y() + 1.0);
    return Color.init(0.5, 0.7, 1.0).mul_scalar(t).add_vec(Color.init(1.0, 1.0, 1.0).mul_scalar(1.0 - t));
}

pub const OurWriterType = std.io.GenericWriter(File, File.WriteError, File.write);
fn write_color(out_buf: OurWriterType, pixel_color: Color, samples_per_pixel: i32) !void {
    comptime @setFloatMode(.optimized);
    var r = pixel_color.x();
    var g = pixel_color.y();
    var b = pixel_color.z();

    const scale: f64 = 1.0 / @as(f64, @floatFromInt(samples_per_pixel));
    r = std.math.sqrt(r * scale);
    g = std.math.sqrt(g * scale);
    b = std.math.sqrt(b * scale);

    const ir: i64 = std.math.lossyCast(i64, @as(f64, common.clamp_double(r, 0.0, 0.99) * 256.0));
    const ig: i64 = std.math.lossyCast(i64, @as(f64, common.clamp_double(g, 0.0, 0.99) * 256.0));
    const ib: i64 = std.math.lossyCast(i64, @as(f64, common.clamp_double(b, 0.0, 0.99) * 256.0));
    //std.debug.print("Out: {} {} {}\n", .{ ir, ig, ib });

    try out_buf.print("{} {} {}\n", .{ ir, ig, ib });
}

fn hit_sphere(center: Point3, radius: f64, r: *Ray) f64 {
    comptime @setFloatMode(.optimized);
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
    // Does ray intersect the sphere?, discrim < 0 means 0 intersection points, == 0 means 1 intersection point, > 0 means 2 intersection points
    // So discriminant >= 0 means there is some level of intersection, return discriminant >= 0.0;
    return if (discriminant < 0.0) -1.0 else (-b - @sqrt(discriminant)) / (2.0 * a);
}

fn generate_scene(our_allocator: std.mem.Allocator) ![]Sphere {
    comptime @setFloatMode(.optimized);
    var spheres = try our_allocator.alloc(Sphere, 400);

    for (0..spheres.len) |i| {
        const center_x: f64 = 5.0 * common.freshest_random_double();
        const center_y: f64 = 5.0 * common.freshest_random_double();
        const center_z: f64 = 5.0 * common.freshest_random_double();
        const center = Point3{ .x = center_x, .y = center_y, .z = center_z };
        //spheres[i] = try sphere_create(center, 0.2, @constCast(&our_allocator));
        spheres[i] = Sphere.init(center, 0.2);
    }

    return spheres;
}

fn gen_material(comptime T: type, allocator: std.mem.Allocator, mat: T) !Material {
    const og_mat: *T = try allocator.create(T);
    og_mat.* = mat;
    return og_mat.material();
}

fn gen_sphere_hittable(allocator: std.mem.Allocator, center: Point3, radius: f64, mat: Material) !Hittable {
    const mat_shrptr = try allocator.create(MaterialSharedPointer);
    mat_shrptr.* = try MaterialSharedPointer.init(mat, allocator);
    var sphere = try allocator.create(Sphere);
    sphere.* = Sphere.init(center, radius, mat_shrptr.*);
    return sphere.hittable();
}

fn gen_world(our_allocator: std.mem.Allocator) !HittableList {
    comptime @setFloatMode(.optimized);
    var world = try HittableList.initCapacity(our_allocator, 400);

    try world.add(try gen_sphere_hittable(our_allocator, Point3.init(0.0, -1000.0, 0.0), 1000.0, try gen_material(Lambertian, our_allocator, Lambertian.init(Color.init(0.5, 0.5, 0.5)))));

    var a: i32 = -6;
    while (a < 6) : (a += 1) {
        var b: i32 = -6;

        while (b < 6) : (b += 1) {
            const choose_mat = common.freshest_random_double();
            //const center = Point3.init(@as(f64, @floatFromInt(a)) + 0.9 * try common.random_double(), 0.2, @as(f64, @floatFromInt(b)) + 0.9 * try common.random_double());
            var center_x: f64 = 0.9 * common.freshest_random_double();
            center_x += @floatFromInt(a);
            var center_z: f64 = 0.9 * common.freshest_random_double();
            center_z += @floatFromInt(b);
            const center = Point3.init(center_x, 0.2, center_z);

            if (center.sub_vec(Point3.init(4.0, 0.2, 0.0)).length() > 0.9) {
                if (choose_mat < 0.8) {
                    // Diffuse
                    const albedo: Color = Color.init_random().mul_vec(Color.init_random());
                    try world.add(try gen_sphere_hittable(our_allocator, Point3.init(center_x, 0.2, center_z), 0.2, try gen_material(Lambertian, our_allocator, Lambertian.init(albedo))));
                } else if (choose_mat < 0.95) {
                    // Metal
                    const albedo: Color = Color.init_random_range(0.5, 1.0);
                    const fuzz = common.random_double_range(0.0, 0.5);
                    try world.add(try gen_sphere_hittable(our_allocator, Point3.init(center_x, 0.2, center_z), 0.2, try gen_material(Metal, our_allocator, Metal.init(albedo, fuzz))));
                } else {
                    // Glass
                    try world.add(try gen_sphere_hittable(our_allocator, Point3.init(center_x, 0.2, center_z), 0.2, try gen_material(Dielectric, our_allocator, Dielectric.init(1.5))));
                }
            }
        }
    }

    try world.add(try gen_sphere_hittable(our_allocator, Point3.init(0.0, 1.0, 0.0), 1.0, try gen_material(Dielectric, our_allocator, Dielectric.init(1.5))));
    try world.add(try gen_sphere_hittable(our_allocator, Point3.init(-4.0, 1.0, 0.0), 1.0, try gen_material(Lambertian, our_allocator, Lambertian.init(Color.init(0.4, 0.2, 0.1)))));
    try world.add(try gen_sphere_hittable(our_allocator, Point3.init(4.0, 1.0, 0.0), 1.0, try gen_material(Metal, our_allocator, Metal.init(Color.init(0.7, 0.6, 0.5), 0.0))));

    return world;
}

pub fn main() !void {
    comptime @setFloatMode(.optimized);

    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const our_allocator = arena_allocator.allocator();

    const stdout = io.getStdOut().writer();
    const stderr = io.getStdErr().writer();

    // World
    var world = try gen_world(our_allocator);

    // Image
    const aspect_ratio: f64 = 3.0 / 2.0;
    const image_width: u32 = 1200;
    const image_height: u32 = @as(u32, @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio));
    const samples_per_pixel: i32 = 500;
    const max_depth: i32 = 50;

    // Camera
    const vfov_degrees: f64 = 100.0;
    const zoom_multiplier: f64 = 5.0;
    const look_from = Point3.init(13.0, 2.0, 3.0);
    const look_at = Point3.init(0.0, 0.0, 0.0);
    const vup = Vec3.init(0.0, 1.0, 0.0);
    const dist_to_focus: f64 = 10.0;
    const aperture: f64 = 0.1;
    var cam = Camera.init(look_from, look_at, vup, vfov_degrees, zoom_multiplier, aspect_ratio, aperture, dist_to_focus);

    // Debug
    //std.debug.print("Rejected Spheres: {d}\n", .{rejected});
    //std.debug.print("Num Spheres: {d}\n", .{spheres.items.len});
    std.debug.print("Num World Hittables: {d}\n", .{world.objects.items.len});
    // std.debug.print("5th last:\n{}\n", .{spheres.items[spheres.items.len - 1 - 5]});
    // std.debug.print("4th last:\n{}\n", .{spheres.items[spheres.items.len - 1 - 4]});
    for (world.objects.items) |*hit| {
        const our_sphere: *Sphere = @ptrCast(@alignCast(hit.*.ptr));
        std.debug.print("OurSphere: {d}, {d}, {d}, {d}\n", .{ our_sphere.center.x(), our_sphere.center.y(), our_sphere.center.z(), our_sphere.radius });
    }

    // Render
    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });
    for (0..image_height) |asc_j| {
        const j: usize = image_height - 1 - asc_j;
        try stderr.print("\rProgress - {} ", .{j});

        for (0..image_width) |i| {
            var pixel_color = Color.init(0.0, 0.0, 0.0);

            for (0..samples_per_pixel) |_| {
                const u: f64 = (@as(f64, @floatFromInt(i)) + common.freshest_random_double()) / @as(f64, @floatFromInt(image_width - 1));
                const v: f64 = (@as(f64, @floatFromInt(j)) + common.freshest_random_double()) / @as(f64, @floatFromInt(image_height - 1));
                const r = cam.get_ray(u, v);
                pixel_color = pixel_color.add_vec(try ray_color(@constCast(&r), @constCast(&world), max_depth));
            }

            try write_color(stdout, pixel_color, samples_per_pixel);
        }
    }
    try stderr.print("\rProgress - Done! \n", .{});
}

test "scene generation holds" {
    comptime @setFloatMode(.optimized);
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const our_allocator = arena_allocator.allocator();

    // var spheres = try our_allocator.alloc(Sphere, 400);
    // for (0..spheres.len) |i| {
    //     const center_x: f64 = 5.0 * common.freshest_random_double();
    //     const center_y: f64 = 5.0 * common.freshest_random_double();
    //     const center_z: f64 = 5.0 * common.freshest_random_double();
    //     const center = Point3{ .x = center_x, .y = center_y, .z = center_z };
    //     //spheres[i] = try sphere_create(center, 0.2, @constCast(&our_allocator));
    //     spheres[i] = Sphere.init(center, 0.2);
    // }

    const spheres = try generate_scene(our_allocator);

    // Debug
    for (spheres, 0..) |sphere, i| {
        std.debug.print("Sphere {} center: ({d}, {d}, {d})\n", .{ i, sphere.center.x, sphere.center.y, sphere.center.z });
    }
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
