const common = @import("common.zig");
const math = @import("std").math;
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
u: Vec3,
v: Vec3,
lens_radius: f64,

pub fn init(look_from: Point3, look_at: Point3, v_up: Vec3, v_fov_degrees: f64, zoom_multiplier: f64, aspect_ratio: f64, aperture: f64, focus_dist: f64) Camera {
    // const aspect_ratio: f64 = 16.0 / 9.0;
    // const viewport_height: f64 = 2.0;
    // const viewport_width: f64 = aspect_ratio * viewport_height;
    // const focal_length: f64 = 1.0;

    // const origin = Point3.init(0.0, 0.0, 0.0);
    // const horizontal = Vec3.init(viewport_width, 0.0, 0.0);
    // const vertical = Vec3.init(0.0, viewport_height, 0.0);
    // //const lower_left_corner: Point3 = origin - horizontal / 2.0 - vertical / 2.0 - Vec3.init(0.0, 0.0, focal_length);
    // const lower_left_corner: Point3 = origin.sub_vec(horizontal.div_scalar(2.0)).sub_vec(vertical.div_scalar(2.0)).sub_vec(Vec3.init(0.0, 0.0, focal_length));

    const zoomed_vfov_degrees = v_fov_degrees * (1.0 / zoom_multiplier);

    const theta = common.degrees_to_radians(zoomed_vfov_degrees);
    const h: f64 = @tan(theta / 2.0); //math.tan(f64, );
    const viewport_height: f64 = 2.0 * h;
    const viewport_width: f64 = aspect_ratio * viewport_height;
    //const focal_length: f64 = 1.0;

    const w = Vec3.unit_vector(look_from.sub_vec(look_at));
    const u = Vec3.unit_vector(Vec3.cross(v_up, w));
    const v = Vec3.cross(w, u);

    // const origin = Point3.init(0.0, 0.0, 0.0);
    // const horizontal = Vec3.init(viewport_width, 0.0, 0.0);
    // const vertical = Vec3.init(0.0, viewport_height, 0.0);
    const origin = look_from;
    const horizontal = u.mul_scalar(viewport_width).mul_scalar(focus_dist);
    const vertical = v.mul_scalar(viewport_height).mul_scalar(focus_dist);
    //const focal = Vec3.init(0.0, 0.0, focal_length);
    const half_horizontal = horizontal.div_scalar(2.0);
    const half_vertical = vertical.div_scalar(2.0);
    //const lower_left_corner = origin - half_horizontal - half_vertical - focal;
    //const lower_left_corner = origin.sub_vec(half_horizontal).sub_vec(half_vertical).sub_vec(focal);
    const lower_left_corner = origin.sub_vec(half_horizontal).sub_vec(half_vertical).sub_vec(w.mul_scalar(focus_dist));

    const lens_radius: f64 = aperture / 2.0;

    return Camera{ .origin = origin, .lower_left_corner = lower_left_corner, .horizontal = horizontal, .vertical = vertical, .u = u, .v = v, .lens_radius = lens_radius };
}

pub fn get_ray(self: *Camera, s: f64, t: f64) Ray {
    const rd = Vec3.random_in_unit_disk().mul_scalar(self.lens_radius);
    const offset = self.u.mul_scalar(rd.x()).add_vec(self.v.mul_scalar(rd.y()));

    return Ray.init(
        //self.origin,
        self.origin.add_vec(offset),
        //self.lower_left_corner.add_vec(self.horizontal.mul_scalar(s)).add_vec(self.vertical.mul_scalar(t)).sub_vec(self.origin),
        //self.lower_left_corner.add_vec(self.horizontal.mul_scalar(s)).add_vec(self.vertical.mul_scalar(t)).sub_vec(self.origin),
        self.lower_left_corner.add_vec(self.horizontal.mul_scalar(s)).add_vec(self.vertical.mul_scalar(t)).sub_vec(self.origin).sub_vec(offset),
    );
}
//};
