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
const Lambertian = material.Lambertian;
const Metal = material.Metal;
const Dielectric = material.Dielectric;

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
    // If we've exceeded the ray bounce limit, no more light is gathered
    if (depth <= 0) {
        return Color.init(0.0, 0.0, 0.0);
    }

    var rec = HitRecord.init();
    if (HittableList.got_hit(world, r, 0.001, common.INFINITY, &rec)) {
        // const direction = rec.normal.add_vec(try Vec3.random_unit_vector());
        // const other_r = Ray.init(rec.p, direction);
        // const new_color = try ray_color(@constCast(&other_r), world, depth - 1);
        // return new_color.mul_scalar(0.5);

        var attenuation = Color.init(0.0, 0.0, 0.0);
        var scattered = Ray.init(Point3.init(0.0, 0.0, 0.0), Vec3.init(0.0, 0.0, 0.0));

        if (rec.mat) |mat| {
            //std.debug.print("ray color, rec has a mat sharedpointer\n", .{});
            if (mat.unsafePtr().scatter(r, &rec, &attenuation, &scattered)) {
                //std.debug.print("that mat shared_ptr scattered\n", .{});
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

const SphereList = std.ArrayList(Sphere);
const LambertianList = std.ArrayList(Lambertian);
const MetalList = std.ArrayList(Metal);
const DielectricList = std.ArrayList(Dielectric);
//const MaterialPointerList = std.ArrayList(MaterialSharedPointer);
const MaterialList = std.ArrayList(Material);

//fn random_scene(our_allocator: Allocator) !HittableList {
//fn random_scene(our_allocator: Allocator) !struct { world: HittableList, spheres: SphereList, lambertians: LambertianList, metals: MetalList, dielectrics: DielectricList, mats: MaterialPointerList } {
//    return .{ .world = world, .spheres = spheres, .lambertians = lambertians, .metals = metals, .dielectrics = dielectrics, .mats = mats };
//}

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
    const aspect_ratio: f64 = 3.0 / 2.0;
    const image_width: u32 = 400;
    const image_height: u32 = @as(u32, @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio));
    const samples_per_pixel: i32 = 100;
    const max_depth: i32 = 50;

    // World

    // var world = HittableList.init(our_allocator);
    // defer world.deinit();

    // var mat_ground = try MaterialSharedPointer.init(@constCast(&Lambertian.init(Color.init(0.8, 0.8, 0.0))).material(), our_allocator);
    // var mat_center = try MaterialSharedPointer.init(@constCast(&Lambertian.init(Color.init(0.1, 0.2, 0.5))).material(), our_allocator);
    // var mat_left = try MaterialSharedPointer.init(@constCast(&Dielectric.init(1.5)).material(), our_allocator);
    // var mat_right = try MaterialSharedPointer.init(@constCast(&Metal.init(Color.init(0.8, 0.6, 0.2), 0.0)).material(), our_allocator);
    // defer {
    //     _ = mat_ground.deinit();
    //     _ = mat_center.deinit();
    //     _ = mat_left.deinit();
    //     _ = mat_right.deinit();
    // }

    // const spheres = try our_allocator.alloc(Sphere, 5);
    // defer our_allocator.free(spheres);
    // spheres[0] = Sphere.init(Point3.init(0.0, -100.5, -1.0), 100.0, mat_ground);
    // spheres[1] = Sphere.init(Point3.init(0.0, 0.0, -1.0), 0.5, mat_center);
    // spheres[2] = Sphere.init(Point3.init(-1.0, 0.0, -1.0), 0.5, mat_left.strongClone());
    // spheres[3] = Sphere.init(Point3.init(-1.0, 0.0, -1.0), -0.45, mat_left);
    // spheres[4] = Sphere.init(Point3.init(1.0, 0.0, -1.0), 0.5, mat_right);
    // try world.add(spheres[0].hittable());
    // try world.add(spheres[1].hittable());
    // try world.add(spheres[2].hittable());
    // try world.add(spheres[3].hittable());
    // try world.add(spheres[4].hittable());

    //const the_stuff = try random_scene(our_allocator);
    //const world = the_stuff.world;

    var world = HittableList.init(our_allocator);
    var spheres = SphereList.init(our_allocator);

    var lambertians = LambertianList.init(our_allocator);
    var metals = MetalList.init(our_allocator);
    var dielectrics = DielectricList.init(our_allocator);

    //var mats = MaterialPointerList.init(our_allocator);
    var mats = MaterialList.init(our_allocator);

    try lambertians.append(Lambertian.init(Color.init(0.5, 0.5, 0.5)));
    //try mats.append(try MaterialSharedPointer.init(@constCast(&(lambertians.getLast())).material(), our_allocator));
    try mats.append(@constCast(&(lambertians.getLast())).material());
    try spheres.append(Sphere.init(Point3.init(0.0, -1000.0, 0.0), 1000.0, try MaterialSharedPointer.init(mats.getLast(), our_allocator)));
    try world.add(@constCast(&spheres.getLast()).hittable());
    std.debug.print("Ground Lambertian refs: {} vs {}\n", .{ &(lambertians.items[lambertians.items.len - 1]), &(lambertians.getLast()) });

    var a: i32 = -11;
    while (a < 11) : (a += 1) {
        var b: i32 = -11;
        while (b < 11) : (b += 1) {
            const choose_mat = try common.random_double();
            const center = Point3.init(@as(f64, @floatFromInt(a)) + 0.9 * try common.random_double(), 0.2, @as(f64, @floatFromInt(b)) + 0.9 * try common.random_double());

            if (center.sub_vec(Point3.init(4.0, 0.2, 0.0)).length() > 0.9) {
                if (choose_mat < 0.8) {
                    // Diffuse
                    const albedo: Color = (try Color.init_random()).mul_vec(try Color.init_random());
                    try lambertians.append(Lambertian.init(albedo));
                    try mats.append(@constCast(&lambertians.getLast()).material());
                    try spheres.append(Sphere.init(center, 0.2, try MaterialSharedPointer.init(mats.getLast(), our_allocator)));
                    try world.add(@constCast(&spheres.getLast()).hittable());

                    //const albedo: Color = (try Color.init_random()).mul_vec(try Color.init_random());
                    //const sphere_mat = try MaterialSharedPointer.init(@constCast(&Lambertian.init(albedo)).material(), our_allocator);
                    // try spheres.append(Sphere.init(center, 0.2, &(mats.getLast())));
                    // const the_sphere: *Sphere = &spheres.getLast();
                    // @memcpy(std.mem.asBytes(the_sphere), std.mem.asBytes(&Sphere.init(center, 0.2, sphere_mat)));
                    // world.add(Box::new(Sphere::new(center, 0.2, sphere_material)));
                    // try world.add(the_sphere.hittable());
                } else if (choose_mat < 0.95) {
                    // Metal
                    const albedo: Color = try Color.init_random_range(0.5, 1.0);
                    const fuzz = try common.random_double_range(0.0, 0.5);
                    try metals.append(Metal.init(albedo, fuzz));
                    try mats.append(@constCast(&metals.getLast()).material());
                    try spheres.append(Sphere.init(center, 0.2, try MaterialSharedPointer.init(mats.getLast(), our_allocator)));
                    try world.add(@constCast(&spheres.getLast()).hittable());
                    //const sphere_material = Rc::new(Metal::new(albedo, fuzz));
                    // const sphere_mat = try MaterialSharedPointer.init(@constCast(&Metal.init(albedo, fuzz)).material(), our_allocator);
                    // try mats.append(sphere_mat);
                    // //world.add(Box::new(Sphere::new(center, 0.2, sphere_material)));
                    // const the_sphere: *Sphere = try spheres.addOne();
                    // @memcpy(std.mem.asBytes(the_sphere), std.mem.asBytes(&Sphere.init(center, 0.2, mats.getLast().strongClone())));
                    // try world.add(the_sphere.hittable());
                } else {
                    // Glass
                    // //const sphere_material = Rc::new(Dielectric::new(1.5));
                    // const sphere_mat = try MaterialSharedPointer.init(@constCast(&Dielectric.init(1.5)).material(), our_allocator);
                    // //world.add(Box::new(Sphere::new(center, 0.2, sphere_material)));
                    // const the_sphere: *Sphere = try spheres.addOne();
                    // @memcpy(std.mem.asBytes(the_sphere), std.mem.asBytes(&Sphere.init(center, 0.2, sphere_mat)));
                    // try world.add(the_sphere.hittable());
                    try dielectrics.append(Dielectric.init(1.5));
                    try mats.append(@constCast(&dielectrics.getLast()).material());
                    try spheres.append(Sphere.init(center, 0.2, try MaterialSharedPointer.init(mats.getLast(), our_allocator)));
                    try world.add(@constCast(&spheres.getLast()).hittable());
                }
            }
        }
    }

    try dielectrics.append(Dielectric.init(1.5));
    //try mats.append(try MaterialSharedPointer.init(@constCast(&(dielectrics.getLast())).material(), our_allocator));
    try mats.append(@constCast(&(dielectrics.getLast())).material());
    try spheres.append(Sphere.init(Point3.init(0.0, 1.0, 0.0), 1.0, try MaterialSharedPointer.init(mats.getLast(), our_allocator)));
    try world.add(@constCast(&spheres.getLast()).hittable());

    try lambertians.append(Lambertian.init(Color.init(0.4, 0.2, 0.1)));
    //try mats.append(try MaterialSharedPointer.init(@constCast(&(lambertians.getLast())).material(), our_allocator));
    try mats.append(@constCast(&(lambertians.getLast())).material());
    try spheres.append(Sphere.init(Point3.init(-4.0, 1.0, 0.0), 1.0, try MaterialSharedPointer.init(mats.getLast(), our_allocator)));
    try world.add(@constCast(&spheres.getLast()).hittable());

    try metals.append(Metal.init(Color.init(0.7, 0.6, 0.5), 0.0));
    //try mats.append(try MaterialSharedPointer.init(@constCast(&(metals.getLast())).material(), our_allocator));
    try mats.append(@constCast(&(metals.getLast())).material());
    try spheres.append(Sphere.init(Point3.init(4.0, 1.0, 0.0), 1.0, try MaterialSharedPointer.init(mats.getLast(), our_allocator)));
    try world.add(@constCast(&spheres.getLast()).hittable());

    // Camera
    //var cam = Camera.init(aspect_ratio, 90.0);
    const vfov_degrees: f64 = 100.0;
    const zoom_multiplier: f64 = 5.0;

    const look_from = Point3.init(13.0, 2.0, 3.0); //Point3.init(-2.0, 2.0, 1.0);
    const look_at = Point3.init(0.0, 0.0, 0.0); //Point3.init(0.0, 0.0, -1.0);
    const vup = Vec3.init(0.0, 1.0, 0.0);
    const dist_to_focus: f64 = 10.0; //look_from.sub_vec(look_at).length();
    const aperture: f64 = 0.1; //2.0;

    //var cam = Camera.init(Point3.init(-2.0, 2.0, 1.0), Point3.init(0.0, 0.0, -1.0), Vec3.init(0.0, 1.0, 0.0), vfov_degrees, zoom_multiplier, aspect_ratio);
    var cam = Camera.init(look_from, look_at, vup, vfov_degrees, zoom_multiplier, aspect_ratio, aperture, dist_to_focus);

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
