const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.log.err("Please provide an input file path.", .{});
        return;
    }

    const input_file = try std.fs.cwd().openFile(args[1], .{});
    defer input_file.close();
    const input_reader = input_file.reader();

    const Pass = struct {
        row: u7 = 0,
        column: u3 = 0,

        pub fn seat_id(self: @This()) u32 {
            return @as(u32, self.row) * 8 + self.column;
        }
        
        pub fn setFromBSP(self: *@This(), bsp: []const u8) !void {
            var row_range = [_]u7{ 0, 127 };
            var col_range = [_]u3{ 0, 7   };
            for (bsp) |c| {
                switch (c) {
                    // lower half of row range
                    'F' => row_range[1] = row_range[1] / 2 + row_range[0] / 2,
                    // higher half of row range
                    'B' => row_range[0] = row_range[1] / 2 + row_range[0] / 2 + 1,
                    // lower half of column range
                    'L' => col_range[1] = col_range[1] / 2 + col_range[0] / 2,
                    // higher half of column range
                    'R' => col_range[0] = col_range[1] / 2 + col_range[0] / 2 + 1,
                    else => return error.UnhandledCharacter,
                }
            }
            assert(row_range[0] == row_range[1]);
            assert(col_range[0] == col_range[1]);

            self.row = row_range[0];
            self.column = col_range[0];
        }
    };

    var ids_present = std.AutoHashMap(usize, bool).init(allocator);
    defer ids_present.deinit();
    var current = Pass{};
    var highest_id: u32 = 0;
    var buf: [10]u8 = undefined;
    while (try input_reader.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        try current.setFromBSP(line);
        var id = current.seat_id();
        
        try ids_present.put(id, true);

        if (highest_id < id) {
            highest_id = id;
        }
    }

    var seat: u32 = 0;
    var i = highest_id;
    while (i > 0) : (i -= 1) {
        _ = ids_present.get(i) orelse break;
    }

    std.log.info("The highest seat ID on a pass is {}.", .{highest_id});
    std.log.info("The seat ID is {}.", .{i});
}
