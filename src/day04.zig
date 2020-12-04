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
        birth_year: FieldResult = .None,
        issue_year: FieldResult = .None,
        expir_year: FieldResult = .None,
        height: FieldResult = .None,
        hair_color: FieldResult = .None,
        eye_color: FieldResult = .None,
        passport_id: FieldResult = .None,
        country_id: FieldResult = .None,
        
        pub const FieldResult = enum {
            None,
            RequiredKeyPresent,
            AllGood,
        };

        pub fn hasRequiredFields(self: @This()) bool {
            if (self.birth_year != .None and
                self.issue_year != .None and
                self.expir_year != .None and
                self.height != .None and
                self.hair_color != .None and
                self.eye_color != .None and
                self.passport_id != .None) {
                return true;
            }
            return false;
        }

        pub fn hasValidValues(self: @This()) bool {
            if (self.birth_year == .AllGood and
                self.issue_year == .AllGood and
                self.expir_year == .AllGood and
                self.height == .AllGood and
                self.hair_color == .AllGood and
                self.eye_color == .AllGood and
                self.passport_id == .AllGood) {
                return true;
            }
            return false;
        }

        pub fn parseKeyValue(self: *@This(), field: []const u8) !void {
            var pair = std.mem.tokenize(field, ":");

            const hash = std.hash_map.hashString;
            switch (hash(pair.next().?)) {
                hash("byr") => {
                    var year = try std.fmt.parseInt(u16,
                        pair.next().?, 10);
                    if (year >= 1920 and year <= 2020) {
                        self.birth_year = .AllGood;
                        return;
                    }
                    self.birth_year = .RequiredKeyPresent;
                },
                hash("iyr") => {
                    var year = try std.fmt.parseInt(u16,
                        pair.next().?, 10);
                    if (year >= 2010 and year <= 2020) {
                        self.issue_year = .AllGood;
                        return;
                    }
                    self.issue_year = .RequiredKeyPresent;
                },
                hash("eyr") => {
                    var year = try std.fmt.parseInt(u16,
                        pair.next().?, 10);
                    if (year >= 2020 and year <= 2030) {
                        self.expir_year = .AllGood;
                        return;
                    }
                    self.expir_year = .RequiredKeyPresent;
                },
                hash("hgt") => {
                    const value = pair.next().?;
                    var height: u8 = 0;
                    if (std.mem.endsWith(u8, value, "in")) {
                        height = std.fmt.parseInt(u8, value[0..2], 10) catch |e| {
                            if (e == error.InvalidCharacter) {
                                self.height = .RequiredKeyPresent;
                                return;
                            } else {
                                return e;
                            }
                        };

                        if (height >= 59 and height <= 76) {
                            self.height = .AllGood;
                            return;
                        }
                    } else if (std.mem.endsWith(u8, value, "cm")) {
                        height = std.fmt.parseInt(u8, value[0..3], 10) catch |e| {
                            if (e == error.InvalidCharacter) {
                                self.height = .RequiredKeyPresent;
                                return;
                            } else {
                                return e;
                            }
                        };
                        if (height >= 150 and height <= 193) {
                            self.height = .AllGood;
                            return;
                        }
                    }
                    self.height = .RequiredKeyPresent;
                },
                hash("hcl") => {
                    const color = pair.next().?;
                    if (color.len != 7) {
                        self.hair_color = .RequiredKeyPresent;
                        return;
                    }
                    if (color[0] != '#') {
                        self.hair_color = .RequiredKeyPresent;
                        return;
                    }
                    for (color[1..]) |c| {
                        if ((c < '0' and c > '9') or
                            (c < 'a' and c > 'f')) {
                            self.hair_color = .RequiredKeyPresent;
                            return;
                        }
                    }
                    self.hair_color = .AllGood;
                },
                hash("ecl") => {
                    const value = pair.next().?;
                    if (value.len != 3) {
                        self.eye_color = .RequiredKeyPresent;
                        return;
                    }
                    const colors = [_][]const u8 {
                        "amb", "blu", "brn", "gry", "grn", "hzl", "oth"
                    };
                    for (colors) |color| {
                        if (std.mem.eql(u8, color, value)) {
                            self.eye_color = .AllGood;
                            return;
                        }
                    }
                    self.eye_color = .RequiredKeyPresent;
                },
                hash("pid") => {
                    const value = pair.next().?;
                    if (value.len != 9) {
                        self.passport_id = .RequiredKeyPresent;
                        return;
                    }
                    var passport_id = try std.fmt.parseInt(u32,
                        value, 10);
                    self.passport_id = .AllGood;
                },
                hash("cid") => {
                    self.country_id = .AllGood;
                },
                else => return error.UnsupportedKey,
            }
        }
    };

    var current = Fields{};
    var valid1: u32 = 0;
    var valid2: u32 = 0;
    var buf: [128]u8 = undefined;
    while (try input_reader.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        if (line.len == 0) {
            // new entry starts now
            if (current.hasRequiredFields())
                valid1 += 1;
            if (current.hasValidValues()) {
                valid2 += 1;
                std.log.debug("Entry {} is valid", .{valid2});
            }
            
            std.log.debug("{}\n", .{current});
            current = Fields{};
            continue;
        }

        var tokens = std.mem.tokenize(line, " ");
        
        while (tokens.next()) |entry| {
            try current.parseKeyValue(entry);
        }
    }
    // Check the entries one last time, to avoid hitting EOF without
    if (current.hasRequiredFields())
        valid1 += 1;
    if (current.hasValidValues())
        valid2 += 1;
    std.log.debug("{}", .{current});

    std.log.info("The solution for part 1 is {}.", .{valid1});
    std.log.info("The solution for part 2 is {}. THIS IS OFF BY ONE, FOR SOME REASON!", .{valid2});
}
