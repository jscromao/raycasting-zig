const common = @import("common.zig");

pub const Vec3 = struct {
    e: [3]f64,

    pub fn init(e0: f64, e1: f64, e2: f64) Vec3 {
        return .{ .e = .{ e0, e1, e2 } };
    }

    pub fn init_random() !Vec3 {
        return Vec3.init(
            try common.random_double(),
            try common.random_double(),
            try common.random_double(),
        );
    }

    pub fn init_random_range(min: f64, max: f64) !Vec3 {
        return Vec3.init(
            try common.random_double_range(min, max),
            try common.random_double_range(min, max),
            try common.random_double_range(min, max),
        );
    }

    pub fn init_random_in_unit_sphere() !Vec3 {
        while (true) {
            const p = try Vec3.init_random_range(-1.0, 1.0);
            if (p.length_squared() >= 1.0) {
                continue;
            }
            return p;
        }
    }

    pub fn x(self: Vec3) f64 {
        return self.e[0];
    }

    pub fn y(self: Vec3) f64 {
        return self.e[1];
    }

    pub fn z(self: Vec3) f64 {
        return self.e[2];
    }

    pub fn length_squared(self: Vec3) f64 {
        return self.e[0] * self.e[0] + self.e[1] * self.e[1] + self.e[2] * self.e[2];
    }

    pub fn length(self: Vec3) f64 {
        return @sqrt(self.length_squared());
    }

    pub fn dot(u: Vec3, v: Vec3) f64 {
        return u.e[0] * v.e[0] + u.e[1] * v.e[1] + u.e[2] * v.e[2];
    }

    pub fn cross(u: Vec3, v: Vec3) Vec3 {
        return Vec3.init(
            u.e[1] * v.e[2] - u.e[2] * v.e[1],
            u.e[2] * v.e[0] - u.e[0] * v.e[2],
            u.e[0] * v.e[1] - u.e[1] * v.e[0],
        );
    }

    pub fn unit_vector(v: Vec3) Vec3 {
        return Vec3.div_scalar(v, v.length());
    }

    /// Adds another Vec3 to self, returns new Vec3
    pub fn add_vec(self: Vec3, other: Vec3) Vec3 {
        return Vec3.init(self.x() + other.x(), self.y() + other.y(), self.z() + other.z());
    }

    /// Subtracts another Vec3 from self, returns new Vec3
    pub fn sub_vec(self: Vec3, other: Vec3) Vec3 {
        return Vec3.init(self.x() - other.x(), self.y() - other.y(), self.z() - other.z());
    }

    /// Multiplies another Vec3 with self, returns new Vec3
    pub fn mul_vec(self: Vec3, other: Vec3) Vec3 {
        return Vec3.init(self.x() * other.x(), self.y() * other.y(), self.z() * other.z());
    }

    /// Divides self by another Vec3, returns new Vec3
    pub fn div_vec(self: Vec3, other: Vec3) Vec3 {
        return Vec3.init(self.x() / other.x(), self.y() / other.y(), self.z() / other.z());
    }

    /// Adds a scalar value to self, returns new Vec3
    pub fn add_scalar(self: Vec3, value: f64) Vec3 {
        return Vec3.init(self.x() + value, self.y() + value, self.z() + value);
    }

    /// Subtracts a scalar value from self, returns new Vec3
    pub fn sub_scalar(self: Vec3, value: f64) Vec3 {
        return Vec3.init(self.x() - value, self.y() - value, self.z() - value);
    }

    /// Multiplies self by a scalar value, returns new Vec3
    pub fn mul_scalar(self: Vec3, value: f64) Vec3 {
        return Vec3.init(self.x() * value, self.y() * value, self.z() * value);
    }

    /// Divides self by a scalar value, returns new Vec3
    pub fn div_scalar(self: Vec3, value: f64) Vec3 {
        return Vec3.init(self.x() / value, self.y() / value, self.z() / value);
    }
};
