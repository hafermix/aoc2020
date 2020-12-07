const std = @import("std");
const assert = std.debug.assert;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = &gpa.allocator;

const Form = struct {
    answers: [26]bool = [1]bool{false} ** 26,

    pub fn parse(self: *@This(), questions: []const u8) void {
        for (questions) |question| {
            const base = 'a';
            var i: usize = base;
            while (i <= 'z') : (i += 1) {
                if (question == i) {
                    self.answers[i - base] = true;
                }
            }
        }
    }

    pub fn countYes(self: @This()) u32 {
        var sum: u32 = 0;
        for (self.answers) |answer| {
            if (answer == true) {
                sum += 1;
            }
        }
        return sum;
    }
};

pub fn main() !void {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.log.err("Please provide an input file path.", .{});
        return;
    }

    const input_file = try std.fs.cwd().openFile(args[1], .{});
    defer input_file.close();
    const input_reader = input_file.reader();

    const buf = try input_reader.readAllAlloc(allocator, 10000000);
    defer allocator.free(buf);

    std.log.info("The solution for part 1 is {}.", .{part1(buf)});
    std.log.info("The solution for part 2 is {}.", .{part2(buf)});
}

pub fn part1(buf: []u8) u32 {
    var sum: u32 = 0;

    var it = std.mem.split(buf, "\n\n");
    while (it.next()) |group| {
        var positive: Form = .{};
        positive.parse(group);
        sum += positive.countYes();
    }
    return sum;
}

pub fn part2(buf: []u8) !u32 {
    var sum: u32 = 0;

    var group_it = std.mem.split(buf, "\n\n");
    while (group_it.next()) |group| {
        var answers = std.ArrayList(Form).init(allocator);

        var member_it = std.mem.tokenize(buf, "\n");
        while (member_it.next()) |member| {
            var form: Form = .{};
            form.parse(group);
            try answers.append(form);
        }

        var sum_of_answers: [26]u32 = [1]u32{0} ** 26;
        for (answers.items) |answer| {
            
        }
    }

    return sum;
}
