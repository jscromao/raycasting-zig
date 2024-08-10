const rcsp = @import("../packages/rcsp.zig");

const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;
const Color = vec3.Color;
const Ray = @import("ray.zig").Ray;
const HitRecord = @import("HitRecord.zig");

//const Material = @This();

// fn scatter(
//     &self,
//     r_in: &Ray,
//     rec: &HitRecord,
//     attenuation: &mut Color,
//     scattered: &mut Ray,
// ) -> bool;

pub const Material = struct {
    ptr: *anyopaque,

    //got_hit_fn: *const fn (ctx: *anyopaque, r: *Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool,
    vtable: *const VTable,

    pub const VTable = struct { scatter_fn: *const fn (ctx: *anyopaque, r_in: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray) bool };

    pub fn init(ptr: anytype) Material {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn scatter_fn(pointer: *anyopaque, r_in: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray) bool {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.Pointer.child.scatter(self, r_in, rec, attenuation, scattered);
            }
        };

        return .{
            .ptr = ptr,
            .vtable = &.{ .scatter_fn = gen.scatter_fn },
            //.writeAllFn = gen.writeAll,
        };
    }

    pub fn scatter(self: Material, r_in: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray) bool {
        return self.vtable.scatter_fn(self.ptr, r_in, rec, attenuation, scattered);
    }
};

pub const MaterialSharedPointer = rcsp.RcSharedPointer(Material, rcsp.NonAtomic);

pub const Lambertian = struct {
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

        var scatter_direction = rec.normal.add_vec(Vec3.random_unit_vector() catch Vec3.init(0.0, 0.0, 0.0));

        // Catch degenerate scatter direction
        if (scatter_direction.near_zero()) {
            scatter_direction = rec.normal;
        }

        //*attenuation = self.albedo;
        //*scattered = Ray.init(rec.p, scatter_direction);
        attenuation.* = self.albedo;
        scattered.* = Ray.init(rec.p, scatter_direction);

        return true;
    }
};

pub const Metal = struct {
    albedo: Color,
    fuzz: f64,

    pub fn init(alb: Color, f: f64) Metal {
        return .{ .albedo = alb, .fuzz = if (f < 1.0) f else 1.0 };
    }

    pub fn material(self: *Metal) Material {
        return Material.init(self); //Material{ .ptr = self, .vtable = .{ .scatter_fn = scatter } };
    }

    pub fn scatter(ctx: *anyopaque, r_in: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray) bool {
        const self: *Metal = @ptrCast(@alignCast(ctx));

        const reflected = Vec3.reflect(Vec3.unit_vector(r_in.direction()), rec.normal);

        attenuation.* = self.albedo;
        //scattered.* = Ray.init(rec.p, reflected);
        const fuzzed_rando = (Vec3.init_random_in_unit_sphere() catch Vec3.init(0.0, 0.0, 0.0)).mul_scalar(self.fuzz);
        scattered.* = Ray.init(rec.p, reflected.add_vec(fuzzed_rando));

        return Vec3.dot(scattered.direction(), rec.normal) > 0.0;
    }
};
