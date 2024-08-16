comptime {
    @setFloatMode(.optimized);
}

const rcsp = @import("../packages/rcsp.zig");

const material = @import("material.zig");
const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Ray = @import("ray.zig").Ray;
const HitRecord = @import("HitRecord.zig");
const Hittable = @import("hittable.zig");

const Material = material.Material;
const MaterialSharedPointer = material.MaterialSharedPointer;

const Sphere = @This();
//pub const Sphere = struct {

//center: Point3,
center: Point3,
radius: f64,
mat: MaterialSharedPointer,

pub fn init(cen: Point3, r: f64, m: MaterialSharedPointer) Sphere {
    return Sphere{ .center = cen, .radius = r, .mat = m };
}

pub fn got_hit(ctx: *anyopaque, r: *Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
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
    if ((root <= t_min) or (root >= t_max)) {
        root = (-half_b + sqrt_d) / a;
        if ((root <= t_min) or (root >= t_max)) {
            return false;
        }
    }

    rec.t = root;
    rec.p = r.at(rec.t);
    //rec.normal = (rec.p.sub_vec(self.center)) / self.radius;
    const outward_normal = rec.p.sub_vec(self.center).div_scalar(self.radius);
    rec.set_face_normal(r, outward_normal);
    rec.mat = self.mat.strongClone();
    return true;
}

pub fn hittable(self: *Sphere) Hittable {
    return Hittable.init(self); //Hittable{ .ptr = self, .vtable = .{ .got_hit = got_hit } };
}
//};
