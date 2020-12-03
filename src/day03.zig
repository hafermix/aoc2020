const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

const Row = []bool;
const open = '.';
const tree = '#';
const Slope = struct { right: u16, down: u16 = 1 };

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

    var forest = std.ArrayList(Row).init(allocator);
    defer {
        for (forest.items) |item| {
            allocator.destroy(item.ptr);
        }
        forest.deinit();
    }

    var buf: [64]u8 = undefined;
    var row_width: u16 = 0;
    while (try input_reader.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        if (row_width == 0) {
            row_width = @intCast(@TypeOf(row_width), line.len);
        }
        
        const row: Row = try allocator.alloc(bool, row_width);

        var pos: u16 = 0;
        while (pos < row_width) {
            if (line[pos] == open) {
                row[pos] = false;
            } else {
                row[pos] = true;
            }
            pos += 1;
        }

        try forest.append(row);
    }

    std.log.info("The solution for part 1 is {}.", .{part1(forest)});

    const slopes = [_]Slope{
        .{ .right = 1 },
        .{ .right = 3 },
        .{ .right = 5 },
        .{ .right = 7 },
        .{ .right = 1, .down = 2 },
    };
    var solution2: u32 = 1;
    for (slopes) |slope| {
        solution2 *= part2(forest, slope);
    }
    std.log.info("The solution for part 2 is {}.", .{solution2});
}

fn part1(forest: std.ArrayList(Row)) u32 {
    return part2(forest, Slope{ .right = 3});
}

fn part2(forest: std.ArrayList(Row), slope: Slope) u32 {
    var row_width = forest.items[0].len;
    var column_index: u16 = 0;
    var row_index: u16 = 0;
    
    var hits: u32 = 0;
    for (forest.items) |row| {
        if (@mod(row_index, slope.down) != 0) {
            row_index += 1;
            continue;
        }

        if (row[column_index] == true) {
            hits += 1;
        }

        column_index = @mod(column_index + slope.right,
            @intCast(@TypeOf(column_index), row_width));
        row_index += 1;
    }
    return hits;
}
