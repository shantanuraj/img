const std = @import("std");

const c = @cImport({
    @cInclude("stb_image.h");
});

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);

    const file =
        if (args.len > 1) try std.fs.openFileAbsolute(args[1], .{ .mode = .read_only })
        else try std.fs.cwd().openFile("./src/fixtures/norway_hut.jpg", .{});
    defer file.close();

    const file_size = try file.getEndPos();

    const file_contents = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(file_contents);

    std.debug.print("Bytes read: {}\n", .{file_contents.len});

    var width: c_int = 0;
    var height: c_int = 0;
    var channels: c_int = 0;

    const file_size_c: c_int = @intCast(file_size);

    const img = c.stbi_load_from_memory(file_contents.ptr, file_size_c, &width, &height, &channels, 0);
    defer c.stbi_image_free(img);

    if (img == null) {
        return std.debug.print("Failed to load image\n", .{});
    }

    std.debug.print("Image dimensions: {}x{} (channels: {})\n", .{width, height, channels});
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
