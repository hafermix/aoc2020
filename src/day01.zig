const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;

const target = 2020;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true, .enable_memory_limit = true }){};
    const allocator = &gpa.allocator;
    defer {
        const bytesUsed = gpa.total_requested_bytes;
        const info = gpa.deinit();
        std.log.info("\n\t[*] Leaked: {}\n\t[*] Bytes leaked: {}", .{ info, bytesUsed });
    }

    var list = try parse_file_args(allocator);
    defer list.deinit();
    var numbers = list.items;

    var solution1: u32 = 0;
    for (numbers) |num1, x| {
        for (numbers[x..]) |num2| {
            if (num1 + num2 == target) {
                solution1 = num1 * num2;
                std.log.info("The solution for part 1 is {} from numbers {} and {}.",
                    .{solution1, num1, num2});
                break;
            }
        }
    }

    var solution2: u32 = 0;
    for (numbers) |num1, x| {
        for (numbers[x..]) |num2, y| {
            for (numbers[y..]) |num3| {
                if (num1 + num2 + num3 == target) {
                    solution2 = num1 * num2 * num3;
                    std.log.info("The solution for part 2 is {} from numbers {}, {} and {}.",
                        .{solution2, num1, num2, num3});
                    break;
                }
            }
        }
    }
}

/// Parses the file from the arguments into an ArrayList
/// Needs to be freed by the caller
fn parse_file_args(allocator: *mem.Allocator) !std.ArrayList(u32) { 
    // Parse input file location
    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Default is read = true, write = false
    const input_file = try std.fs.cwd().openFile(args[1], .{});
    defer input_file.close();

    var input = try input_file.readToEndAlloc(allocator, 1000000);
    defer allocator.free(input);

    //std.log.info("Input contents:\n{}\n", .{input});

    var list = std.ArrayList(u32).init(allocator);

    var split = mem.split(input, "\n");
    while (split.next()) |line| {
        //std.log.info("Line: {}", .{line});
        const num = std.fmt.parseInt(u32, line, 10) catch |err| {
            if (err == error.InvalidCharacter) {
                break;
            }
            return err;
        };
        try list.append(num);
    }
    
    return list;
}
