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
