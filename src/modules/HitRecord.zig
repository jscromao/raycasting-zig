const Ray = @import("ray.zig").Ray;
const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;

const HitRecord = @This();

//pub const HitRecord = struct {
p: Point3,
normal: Vec3,
t: f64,
front_face: bool,

pub fn init() HitRecord {
    return .{ .p = Point3.init(0.0, 0.0, 0.0), .normal = Vec3.init(0.0, 0.0, 0.0), .t = 0.0, .front_face = false };
}

pub fn set_face_normal(self: *HitRecord, r: *Ray, outward_normal: Vec3) void {
    self.front_face = Vec3.dot(r.direction(), outward_normal) < 0.0;
    self.normal = if (self.front_face) outward_normal else outward_normal.mul_scalar(-1.0);
}
//};
