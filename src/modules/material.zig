const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;
const Color = vec3.Color;
const Ray = @import("ray.zig").Ray;

const Material = @This(); //TODO: implement Material trait/interface

// fn scatter(
//     &self,
//     r_in: &Ray,
//     rec: &HitRecord,
//     attenuation: &mut Color,
//     scattered: &mut Ray,
// ) -> bool;
