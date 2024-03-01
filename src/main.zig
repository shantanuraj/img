const std = @import("std");

const c = @cImport({
    @cInclude("stb_image.h");
});

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file_name = "fixtures/norway_hut.jpg";

    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    const file_size = try file.getEndPos();

    const file_contents = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(file_contents);

    std.debug.print("Bytes read: {}\n", .{file_contents.len});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const global = struct {
        fn testOne(input: []const u8) anyerror!void {
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(global.testOne, .{});
}
