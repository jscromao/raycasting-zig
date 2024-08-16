comptime {
    @setFloatMode(.optimized);
}

const Ray = @import("ray.zig").Ray;
const HitRecord = @import("HitRecord.zig");

const Hittable = @This();
//pub const Hittable = struct {
ptr: *anyopaque,

//got_hit_fn: *const fn (ctx: *anyopaque, r: *Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool,
vtable: *const VTable,

pub const VTable = struct { got_hit_fn: *const fn (ctx: *anyopaque, r: *Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool };

pub fn init(ptr: anytype) Hittable {
    const T = @TypeOf(ptr);
    const ptr_info = @typeInfo(T);

    const gen = struct {
        pub fn got_hit_fn(pointer: *anyopaque, r: *Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
            const self: T = @ptrCast(@alignCast(pointer));
            return ptr_info.Pointer.child.got_hit(self, r, t_min, t_max, rec);
        }
    };

    return .{
        .ptr = ptr,
        .vtable = &.{ .got_hit_fn = gen.got_hit_fn },
        //.writeAllFn = gen.writeAll,
    };
}

pub fn got_hit(self: Hittable, r: *Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
    return self.vtable.got_hit_fn(self.ptr, r, t_min, t_max, rec);
}
//};
