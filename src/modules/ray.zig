comptime {
    @setFloatMode(.optimized);
}

const Vec3 = @import("vec3.zig").Vec3;
const Point3 = Vec3;

pub const Ray = struct {
    orig: Point3,
    dir: Vec3,

    pub fn init(orig: Point3, dir: Vec3) Ray {
        return Ray{ .orig = orig, .dir = dir };
    }

    pub fn origin(self: Ray) Point3 {
        return self.orig;
    }

    pub fn direction(self: Ray) Vec3 {
        return self.dir;
    }

    pub fn at(self: Ray, t: f64) Point3 {
        const multed = self.direction().mul_scalar(t);
        return @as(Point3, multed.add_vec(self.origin()));
    }
};
