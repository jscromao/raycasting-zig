const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const ray = @import("ray.zig");
const Ray = ray.Ray;

const Camera = @This();

//pub const Camera = struct {
origin: Point3,
lower_left_corner: Point3,
horizontal: Vec3,
vertical: Vec3,

pub fn init(aspect_ratio: f64) Camera {
    // const aspect_ratio: f64 = 16.0 / 9.0;
    // const viewport_height: f64 = 2.0;
    // const viewport_width: f64 = aspect_ratio * viewport_height;
    // const focal_length: f64 = 1.0;

    // const origin = Point3.init(0.0, 0.0, 0.0);
    // const horizontal = Vec3.init(viewport_width, 0.0, 0.0);
    // const vertical = Vec3.init(0.0, viewport_height, 0.0);
    // //const lower_left_corner: Point3 = origin - horizontal / 2.0 - vertical / 2.0 - Vec3.init(0.0, 0.0, focal_length);
    // const lower_left_corner: Point3 = origin.sub_vec(horizontal.div_scalar(2.0)).sub_vec(vertical.div_scalar(2.0)).sub_vec(Vec3.init(0.0, 0.0, focal_length));

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

    return Camera{
        .origin = origin,
        .lower_left_corner = lower_left_corner,
        .horizontal = horizontal,
        .vertical = vertical,
    };
}

pub fn get_ray(self: *Camera, u: f64, v: f64) Ray {
    return Ray.init(
        self.origin,
        self.lower_left_corner.add_vec(self.horizontal.mul_scalar(u)).add_vec(self.vertical.mul_scalar(v)).sub_vec(self.origin),
    );
}
//};
