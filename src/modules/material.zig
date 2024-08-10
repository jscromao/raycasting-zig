const rcsp = @import("../packages/rcsp.zig");
const math = @import("std").math;
const common = @import("common.zig");

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

pub fn material_reflectance(cosine: f64, ref_idx: f64) f64 {
    // Use Schlick's approximation for reflectance
    var r0: f64 = (1.0 - ref_idx) / (1.0 + ref_idx);
    r0 = r0 * r0;
    return r0 + (1.0 - r0) * math.pow(f64, 1.0 - cosine, 5.0);
}

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

pub const Dielectric = struct {
    ir: f64,

    pub fn init(index_of_refraction: f64) Dielectric {
        return .{ .ir = index_of_refraction };
    }

    pub fn material(self: *Dielectric) Material {
        return Material.init(self); //Material{ .ptr = self, .vtable = .{ .scatter_fn = scatter } };
    }

    pub fn scatter(ctx: *anyopaque, r_in: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray) bool {
        const self: *Dielectric = @ptrCast(@alignCast(ctx));

        const refraction_ratio = if (rec.front_face) @as(f64, 1.0 / self.ir) else self.ir;

        const unit_direction = Vec3.unit_vector(r_in.direction());
        const cos_theta: f64 = @min(Vec3.dot(unit_direction.mul_scalar(-1.0), rec.normal), 1.0);
        const sin_theta: f64 = @sqrt(1.0 - (cos_theta * cos_theta));

        const cannot_refract: bool = (refraction_ratio * sin_theta) > 1.0;
        const should_reflect: bool = cannot_refract or material_reflectance(cos_theta, refraction_ratio) > (common.random_double() catch 0.499);
        const direction = if (should_reflect) Vec3.reflect(unit_direction, rec.normal) else Vec3.refract(unit_direction, rec.normal, refraction_ratio);

        attenuation.* = Color.init(1.0, 1.0, 1.0);
        scattered.* = Ray.init(rec.p, direction);
        return true;
    }
};
