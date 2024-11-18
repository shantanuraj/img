const std = @import("std");

const c = @cImport({
    @cInclude("stb_image.h");
});

const stubImage = @embedFile("fixtures/norway_hut.jpg");

const File = struct {
    allocator:  ?std.mem.Allocator,
    contents: []const u8,

    pub fn deinit(self: *const File) void {
        if (self.allocator == null) return;
        const allocator = self.allocator.?;
        allocator.free(self.contents);
    }
};

fn get_file_contents(allocator: std.mem.Allocator, args: []const []const u8) !File {
    if (args.len < 2) {
        return File{
            .allocator = null,
            .contents = std.mem.sliceAsBytes(stubImage),
        };
    }

    const file = try std.fs.cwd().openFile(args[1], .{ .mode = .read_only });
    defer file.close();

    const file_size = try file.getEndPos();

    const file_contents = try file.readToEndAlloc(allocator, file_size);
    return File{
        .allocator = allocator,
        .contents = file_contents,
    };
}

const Image = struct {
    width: i64,
    height: i64,
    channels: i4,
    size: usize,
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);

    const file = try get_file_contents(allocator, args);
    defer file.deinit();

    const file_contents = file.contents;
    const file_size = file_contents.len;

    var width: c_int = 0;
    var height: c_int = 0;
    var channels: c_int = 0;

    const file_size_c: c_int = @intCast(file_size);

    const img = c.stbi_load_from_memory(file_contents.ptr, file_size_c, &width, &height, &channels, 0);
    defer c.stbi_image_free(img);

    if (img == null) {
        return std.debug.print("Failed to load image\n", .{});
    }

    const image = Image{
        .width = width,
        .height = height,
        .channels = @intCast(channels),
        .size = file_size,
    };

    const json = try std.json.stringifyAlloc(allocator, image, .{ .whitespace = .minified });
    defer allocator.free(json);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{json});
}
