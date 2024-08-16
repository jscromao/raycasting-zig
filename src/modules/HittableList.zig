const std = @import("std");
comptime {
    @setFloatMode(.optimized);
}

const Allocator = std.mem.Allocator;
const Hittable = @import("./hittable.zig");
const Ray = @import("./ray.zig").Ray;
const HitRecord = @import("./HitRecord.zig");

const HittableList = @This();

//pub const HittableList = struct {
objects: std.ArrayList(Hittable),

pub fn init(allocator: Allocator) HittableList {
    return HittableList{ .objects = std.ArrayList(Hittable).init(allocator) };
}

pub fn initCapacity(allocator: Allocator, new_capacity: usize) !HittableList {
    return HittableList{ .objects = try std.ArrayList(Hittable).initCapacity(allocator, new_capacity) };
}

pub fn deinit(self: *HittableList) void {
    self.objects.deinit();
}

pub fn add(self: *HittableList, object: Hittable) !void {
    try self.objects.append(object);
}

pub fn hittable(self: *HittableList) Hittable {
    return Hittable.init(self); //Hittable{ .ptr = self, .vtable = .{ .got_hit = got_hit } };
}

pub fn got_hit(ctx: *anyopaque, r: *Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
    const self: *HittableList = @ptrCast(@alignCast(ctx));

    var temp_rec = HitRecord.init();
    var hit_anything = false;
    var closest_so_far = t_max;

    for (self.objects.items, 0..) |*obj, i| {
        _ = i;

        //const obj: *Hittable = @ptrCast(@alignCast(&object));
        if (obj.got_hit(r, t_min, closest_so_far, &temp_rec)) {
            hit_anything = true;
            closest_so_far = temp_rec.t;
            //*rec = temp_rec.clone();
            // rec.*.p = temp_rec.p;
            // rec.*.normal = temp_rec.normal;
            // rec.*.t = temp_rec.t;
            // rec.*.front_face = temp_rec.front_face;
            //const as_bytes: []u8 = std.mem.asBytes(rec);
            //@memcpy(as_bytes, std.mem.asBytes(&temp_rec));
            std.mem.copyForwards(u8, std.mem.asBytes(rec), std.mem.asBytes(&temp_rec));
            //rec.* = temp_rec;
        }
    }

    return hit_anything;
}
//};
