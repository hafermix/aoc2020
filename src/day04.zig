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

    const Fields = struct {
        birth_year: bool = false,
        issue_year: bool = false,
        expir_year: bool = false,
        height: bool = false,
        hair_color: bool = false,
        eye_color: bool = false,
        passport_id: bool = false,
        country_id: bool = false,
    };

    var current = Fields{};
    var valid: u32 = 0;
    var buf: [128]u8 = undefined;
    while (try input_reader.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        if (line.len == 0) {
            // new entry starts now
            if (current.birth_year == true and
                current.issue_year == true and
                current.expir_year == true and
                current.height == true and
                current.hair_color == true and
                current.eye_color == true and
                current.passport_id == true) {
                valid += 1;
                std.log.debug("Valid entry {}", .{valid});
            }
            std.log.debug("{}", .{current});
            current = Fields{};
            continue;
        }

        var tokens = std.mem.tokenize(line, " ");
        
        while (tokens.next()) |entry| {
            var pair = std.mem.tokenize(entry, ":");
            const hash = std.hash_map.hashString;
            switch (hash(pair.next().?)) {
                hash("byr") => current.birth_year = true,
                hash("iyr") => current.issue_year = true,
                hash("eyr") => current.expir_year = true,
                hash("hgt") => current.height = true,
                hash("hcl") => current.hair_color = true,
                hash("ecl") => current.eye_color = true,
                hash("pid") => current.passport_id = true,
                hash("cid") => current.country_id = true,
                else => return error.UnhandledKey,
            }
        }
    }

    std.log.info("The solution for part 1 is {}.", .{valid});
}
