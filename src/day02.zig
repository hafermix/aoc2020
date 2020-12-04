const std = @import("std");
const assert = std.debug.assert;

const Entry = struct {
    policy: struct {
        least: u16,
        most: u16,
        letter: u8,
    } = undefined,
    password: []u8 = undefined,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true, .enable_memory_limit = true }){};
    const allocator = &gpa.allocator;
    defer {
        const bytesUsed = gpa.total_requested_bytes;
        const info = gpa.deinit();
        std.log.info("\n\t[*] Leaked: {}\n\t[*] Bytes leaked: {}", .{ info, bytesUsed });
    }

    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const input_file = try std.fs.cwd().openFile(args[1], .{});
    defer input_file.close();
    const input_reader = input_file.reader();

    var entry_list = std.ArrayList(Entry).init(allocator);
    defer {
        for (entry_list.items) |item| {
            allocator.destroy(item.password.ptr);
        }
        entry_list.deinit();
    }

    var buf: [512]u8 = undefined;
    while (try input_reader.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        var entry = Entry{};
        var iter = std.mem.tokenize(line, " -");

        entry.policy.least = try std.fmt.parseInt(@TypeOf(entry.policy.least), iter.next().?, 10);
        entry.policy.most = try std.fmt.parseInt(@TypeOf(entry.policy.most), iter.next().?, 10);
        entry.policy.letter = iter.next().?[0];
        
        entry.password = try allocator.dupe(u8, iter.next().?);
        try entry_list.append(entry);
    }
    
    std.log.info("Solution to part 1 is {}.", .{part1(allocator, entry_list)});
    std.log.info("Solution to part 2 is {}.", .{part2(allocator, entry_list)});
}

fn part1(allocator: *std.mem.Allocator, entry_list: std.ArrayList(Entry)) u32 {
    var valid: u32 = 0;
    for (entry_list.items) |entry| {
        var count: u32 = 0;
        for (entry.password) |c| {
            if (c == entry.policy.letter) {
                count += 1;
            }
        }

        if (count >= entry.policy.least and count <= entry.policy.most) {
            valid += 1;
        }
    }
    return valid;
}

fn part2(allocator: *std.mem.Allocator, entry_list: std.ArrayList(Entry)) u32 {
    var valid: u32 = 0;
    for (entry_list.items) |entry| {
        if ((entry.password[entry.policy.least - 1] == entry.policy.letter) !=
            (entry.password[entry.policy.most - 1] == entry.policy.letter)) {
            valid += 1;
        }
    }
    return valid;
}
