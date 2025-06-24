const std = @import("std");
const player = @import("player.zig");

pub const Player = player.Player;
pub const Position = player.Position;

pub const Stack = struct {
    game_id: []const u8,
    team: []const u8,
    player_count: u8,
};

pub const Lineup = struct {
    players: [9]Player, // 1 QB, 2 RB, 3 WR, 1 TE, 1 FLEX, 1 DST
    total_salary: u32,
    projected_points: f64,
    stacks: []Stack, // Tracking of game/team stacks

    pub fn init(players: [9]Player, allocator: std.mem.Allocator) !Lineup {
        var total_salary: u32 = 0;
        var projected_points: f64 = 0.0;

        for (players) |p| {
            total_salary += p.salary;
            projected_points += p.projected_points;
        }

        const stacks = try calculateStacks(players, allocator);

        return Lineup{
            .players = players,
            .total_salary = total_salary,
            .projected_points = projected_points,
            .stacks = stacks,
        };
    }

    pub fn deinit(self: *Lineup, allocator: std.mem.Allocator) void {
        allocator.free(self.stacks);
    }

    pub fn isValidRoster(self: Lineup) bool {
        var position_counts = std.EnumArray(Position, u8).initFill(0);
        
        for (self.players) |p| {
            position_counts.set(p.position, position_counts.get(p.position) + 1);
        }

        // Check DraftKings lineup requirements: 1 QB, 2 RB, 3 WR, 1 TE, 1 FLEX, 1 DST
        const qb_count = position_counts.get(.QB);
        const rb_count = position_counts.get(.RB);
        const wr_count = position_counts.get(.WR);
        const te_count = position_counts.get(.TE);
        const dst_count = position_counts.get(.DST);
        
        // Must have exactly these counts
        if (qb_count != 1 or dst_count != 1) {
            return false;
        }
        
        // Must have at least minimum required positions
        if (rb_count < 2 or wr_count < 3 or te_count < 1) {
            return false;
        }
        
        // Total flex-eligible positions should be exactly 7 (2 RB + 3 WR + 1 TE + 1 FLEX)
        // The FLEX position can be an additional RB, WR, or TE
        const flex_total = rb_count + wr_count + te_count;
        if (flex_total != 7) {
            return false;
        }

        // Check team diversity constraint (minimum 2 teams) and max 8 per team
        if (!self.hasTeamDiversity()) {
            return false;
        }
        
        // Check for duplicate players
        if (!self.hasNoDuplicatePlayers()) {
            return false;
        }
        
        // Check player availability (no bye weeks, no OUT players)
        if (!self.hasAllPlayersAvailable()) {
            return false;
        }
        
        return true;
    }

    pub fn isSalaryValid(self: Lineup) bool {
        return self.total_salary <= 50000;
    }
    
    pub fn isSalaryExact(self: Lineup) bool {
        return self.total_salary == 50000;
    }

    pub fn hasTeamDiversity(self: Lineup) bool {
        var unique_teams: u8 = 0;
        var seen_teams: [32][]const u8 = undefined; // Max 32 NFL teams
        var team_counts: [32]u8 = std.mem.zeroes([32]u8);
        
        for (self.players) |p| {
            var found = false;
            var team_index: usize = 0;
            for (seen_teams[0..unique_teams], 0..) |team, i| {
                if (std.mem.eql(u8, team, p.team)) {
                    found = true;
                    team_index = i;
                    break;
                }
            }
            if (!found) {
                seen_teams[unique_teams] = p.team;
                team_index = unique_teams;
                unique_teams += 1;
            }
            team_counts[team_index] += 1;
            
            // Check max 8 players per team constraint
            if (team_counts[team_index] > 8) {
                return false;
            }
        }
        
        return unique_teams >= 2; // Must have at least 2 different teams
    }

    pub fn getPlayer(self: Lineup, position: Position, index: u8) ?Player {
        var count: u8 = 0;
        for (self.players) |p| {
            if (p.position == position) {
                if (count == index) {
                    return p;
                }
                count += 1;
            }
        }
        return null;
    }

    pub fn hasPlayer(self: Lineup, player_id: []const u8) bool {
        for (self.players) |p| {
            if (std.mem.eql(u8, p.id, player_id)) {
                return true;
            }
        }
        return false;
    }

    pub fn hasNoDuplicatePlayers(self: Lineup) bool {
        for (self.players, 0..) |player1, i| {
            for (self.players[i+1..]) |player2| {
                if (std.mem.eql(u8, player1.id, player2.id)) {
                    return false;
                }
            }
        }
        return true;
    }
    
    pub fn hasAllPlayersAvailable(self: Lineup) bool {
        for (self.players) |p| {
            if (!p.isAvailable()) {
                return false;
            }
        }
        return true;
    }
    
    pub fn pointsPerDollar(self: Lineup) f64 {
        if (self.total_salary == 0) return 0.0;
        return self.projected_points / @as(f64, @floatFromInt(self.total_salary));
    }

    pub fn format(self: Lineup, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("Lineup{{ salary: ${}, points: {d:.2}, stacks: {}, players: [", .{
            self.total_salary,
            self.projected_points,
            self.stacks.len,
        });
        
        for (self.players, 0..) |p, i| {
            if (i > 0) try writer.print(", ");
            try writer.print("{s}({s})", .{ p.name, @tagName(p.position) });
        }
        try writer.print("] }}");
    }

    fn calculateStacks(players: [9]Player, allocator: std.mem.Allocator) ![]Stack {
        var game_counts = std.HashMap([]const u8, u8, std.hash_map.StringContext, std.hash_map.default_max_load_percentage).init(allocator);
        defer game_counts.deinit();

        var team_counts = std.HashMap([]const u8, u8, std.hash_map.StringContext, std.hash_map.default_max_load_percentage).init(allocator);
        defer team_counts.deinit();

        // Count players by game and team
        for (players) |p| {
            if (p.game_info) |game_id| {
                const game_result = try game_counts.getOrPut(game_id);
                if (!game_result.found_existing) {
                    game_result.value_ptr.* = 0;
                }
                game_result.value_ptr.* += 1;
            }

            const team_result = try team_counts.getOrPut(p.team);
            if (!team_result.found_existing) {
                team_result.value_ptr.* = 0;
            }
            team_result.value_ptr.* += 1;
        }

        var stacks = std.ArrayList(Stack).init(allocator);
        
        // Add game stacks (2+ players from same game)
        var game_iter = game_counts.iterator();
        while (game_iter.next()) |entry| {
            if (entry.value_ptr.* >= 2) {
                try stacks.append(Stack{
                    .game_id = entry.key_ptr.*,
                    .team = "",
                    .player_count = entry.value_ptr.*,
                });
            }
        }

        // Add team stacks (2+ players from same team)
        var team_iter = team_counts.iterator();
        while (team_iter.next()) |entry| {
            if (entry.value_ptr.* >= 2) {
                try stacks.append(Stack{
                    .game_id = "",
                    .team = entry.key_ptr.*,
                    .player_count = entry.value_ptr.*,
                });
            }
        }

        return stacks.toOwnedSlice();
    }
};

test "Lineup creation and basic operations" {
    const allocator = std.testing.allocator;

    const qb = Player.init("1", "QB Player", .QB, 8000, 20.0, "KC", "LV", "KC@LV");
    const rb1 = Player.init("2", "RB1 Player", .RB, 7000, 15.0, "KC", "LV", "KC@LV");
    const rb2 = Player.init("3", "RB2 Player", .RB, 6000, 14.0, "DAL", "NYG", "DAL@NYG");
    const wr1 = Player.init("4", "WR1 Player", .WR, 8500, 18.0, "KC", "LV", "KC@LV");
    const wr2 = Player.init("5", "WR2 Player", .WR, 7500, 16.0, "DAL", "NYG", "DAL@NYG");
    const wr3 = Player.init("6", "WR3 Player", .WR, 6500, 14.0, "MIA", "BUF", "MIA@BUF");
    const te = Player.init("7", "TE Player", .TE, 5500, 12.0, "KC", "LV", "KC@LV");
    const flex = Player.init("8", "FLEX Player", .RB, 5000, 11.0, "MIA", "BUF", "MIA@BUF");
    const dst = Player.init("9", "DST Player", .DST, 4000, 8.0, "DAL", "NYG", "DAL@NYG");

    const players = [9]Player{ qb, rb1, rb2, wr1, wr2, wr3, te, flex, dst };
    
    var lineup = try Lineup.init(players, allocator);
    defer lineup.deinit(allocator);

    try std.testing.expect(lineup.total_salary == 58000);
    try std.testing.expect(lineup.projected_points == 128.0);
    try std.testing.expect(lineup.players.len == 9);
}

test "Lineup roster validation" {
    const allocator = std.testing.allocator;

    // Valid lineup: 1 QB, 2 RB, 3 WR, 1 TE, 1 FLEX(WR), 1 DST = 9 total
    const qb = Player.init("1", "QB Player", .QB, 8000, 20.0, "KC", "LV", null);
    const rb1 = Player.init("2", "RB1 Player", .RB, 7000, 15.0, "KC", "LV", null);
    const rb2 = Player.init("3", "RB2 Player", .RB, 6000, 14.0, "DAL", "NYG", null);
    const wr1 = Player.init("4", "WR1 Player", .WR, 8500, 18.0, "KC", "LV", null);
    const wr2 = Player.init("5", "WR2 Player", .WR, 7500, 16.0, "DAL", "NYG", null);
    const wr3 = Player.init("6", "WR3 Player", .WR, 6500, 14.0, "MIA", "BUF", null);
    const te = Player.init("7", "TE Player", .TE, 5500, 12.0, "KC", "LV", null);
    const flex = Player.init("8", "FLEX Player", .WR, 5000, 11.0, "MIA", "BUF", null);
    const dst = Player.init("9", "DST Player", .DST, 3000, 10.0, "MIA", "BUF", null);

    const valid_players = [9]Player{ qb, rb1, rb2, wr1, wr2, wr3, te, flex, dst };
    var valid_lineup = try Lineup.init(valid_players, allocator);
    defer valid_lineup.deinit(allocator);

    try std.testing.expect(valid_lineup.isValidRoster());
    try std.testing.expect(!valid_lineup.isSalaryValid()); // Over $50k

    // Test salary validation with cheaper lineup
    const cheap_players = [9]Player{
        Player.init("1", "QB", .QB, 5000, 15.0, "KC", "LV", null),
        Player.init("2", "RB1", .RB, 4000, 10.0, "KC", "LV", null),
        Player.init("3", "RB2", .RB, 4000, 10.0, "DAL", "NYG", null),
        Player.init("4", "WR1", .WR, 5000, 12.0, "KC", "LV", null),
        Player.init("5", "WR2", .WR, 5000, 12.0, "DAL", "NYG", null),
        Player.init("6", "WR3", .WR, 4000, 10.0, "MIA", "BUF", null),
        Player.init("7", "TE", .TE, 4000, 8.0, "KC", "LV", null),
        Player.init("8", "FLEX", .RB, 4000, 8.0, "MIA", "BUF", null),
        Player.init("9", "DST", .DST, 3000, 8.0, "MIA", "BUF", null),
    };
    
    var cheap_lineup = try Lineup.init(cheap_players, allocator);
    defer cheap_lineup.deinit(allocator);

    try std.testing.expect(cheap_lineup.isValidRoster());
    try std.testing.expect(cheap_lineup.isSalaryValid()); // Under $50k
}

test "Lineup team diversity validation" {
    const allocator = std.testing.allocator;

    // Invalid lineup: all players from same team (should fail team diversity)
    const same_team_players = [9]Player{
        Player.init("1", "QB", .QB, 5000, 15.0, "KC", "LV", null),
        Player.init("2", "RB1", .RB, 4000, 10.0, "KC", "LV", null),
        Player.init("3", "RB2", .RB, 4000, 10.0, "KC", "LV", null),
        Player.init("4", "WR1", .WR, 5000, 12.0, "KC", "LV", null),
        Player.init("5", "WR2", .WR, 5000, 12.0, "KC", "LV", null),
        Player.init("6", "WR3", .WR, 4000, 10.0, "KC", "LV", null),
        Player.init("7", "TE", .TE, 4000, 8.0, "KC", "LV", null),
        Player.init("8", "FLEX", .RB, 4000, 8.0, "KC", "LV", null),
        Player.init("9", "DST", .DST, 3000, 8.0, "KC", "LV", null),
    };
    
    var same_team_lineup = try Lineup.init(same_team_players, allocator);
    defer same_team_lineup.deinit(allocator);

    try std.testing.expect(!same_team_lineup.isValidRoster()); // Should fail due to team diversity
    try std.testing.expect(!same_team_lineup.hasTeamDiversity()); // Only 1 team
}

test "Lineup player operations" {
    const allocator = std.testing.allocator;

    const qb = Player.init("1", "QB Player", .QB, 8000, 20.0, "KC", "LV", null);
    const rb1 = Player.init("2", "RB1 Player", .RB, 7000, 15.0, "KC", "LV", null);
    const rb2 = Player.init("3", "RB2 Player", .RB, 6000, 14.0, "DAL", "NYG", null);
    const wr1 = Player.init("4", "WR1 Player", .WR, 8500, 18.0, "KC", "LV", null);
    const wr2 = Player.init("5", "WR2 Player", .WR, 7500, 16.0, "DAL", "NYG", null);
    const wr3 = Player.init("6", "WR3 Player", .WR, 6500, 14.0, "MIA", "BUF", null);
    const te = Player.init("7", "TE Player", .TE, 5500, 12.0, "KC", "LV", null);
    const flex = Player.init("8", "FLEX Player", .RB, 5000, 11.0, "MIA", "BUF", null);
    const dst = Player.init("9", "DST Player", .DST, 3000, 10.0, "MIA", "BUF", null);

    const players = [9]Player{ qb, rb1, rb2, wr1, wr2, wr3, te, flex, dst };
    var lineup = try Lineup.init(players, allocator);
    defer lineup.deinit(allocator);

    // Test hasPlayer
    try std.testing.expect(lineup.hasPlayer("1"));
    try std.testing.expect(lineup.hasPlayer("5"));
    try std.testing.expect(!lineup.hasPlayer("99"));

    // Test getPlayer
    const qb_player = lineup.getPlayer(.QB, 0);
    try std.testing.expect(qb_player != null);
    try std.testing.expect(std.mem.eql(u8, qb_player.?.id, "1"));

    const first_rb = lineup.getPlayer(.RB, 0);
    try std.testing.expect(first_rb != null);
    try std.testing.expect(std.mem.eql(u8, first_rb.?.id, "2") or std.mem.eql(u8, first_rb.?.id, "3") or std.mem.eql(u8, first_rb.?.id, "8"));
}

test "Lineup points per dollar calculation" {
    const allocator = std.testing.allocator;

    const players = [9]Player{
        Player.init("1", "QB", .QB, 5000, 20.0, "KC", "LV", null),
        Player.init("2", "RB1", .RB, 5000, 15.0, "KC", "LV", null),
        Player.init("3", "RB2", .RB, 5000, 15.0, "DAL", "NYG", null),
        Player.init("4", "WR1", .WR, 5000, 15.0, "KC", "LV", null),
        Player.init("5", "WR2", .WR, 5000, 15.0, "DAL", "NYG", null),
        Player.init("6", "WR3", .WR, 5000, 15.0, "MIA", "BUF", null),
        Player.init("7", "TE", .TE, 5000, 15.0, "KC", "LV", null),
        Player.init("8", "FLEX", .RB, 5000, 15.0, "MIA", "BUF", null),
        Player.init("9", "DST", .DST, 5000, 10.0, "MIA", "BUF", null),
    };

    var lineup = try Lineup.init(players, allocator);
    defer lineup.deinit(allocator);

    const ppd = lineup.pointsPerDollar();
    try std.testing.expect(ppd == 0.003); // 135.0 / 45000 = 0.003
}

test "Lineup max players per team constraint" {
    const allocator = std.testing.allocator;

    // Invalid lineup: 9 players from same team (exceeds max 8)
    const invalid_players = [9]Player{
        Player.init("1", "QB", .QB, 5000, 15.0, "KC", "LV", null),
        Player.init("2", "RB1", .RB, 4000, 10.0, "KC", "LV", null),
        Player.init("3", "RB2", .RB, 4000, 10.0, "KC", "LV", null),
        Player.init("4", "WR1", .WR, 5000, 12.0, "KC", "LV", null),
        Player.init("5", "WR2", .WR, 5000, 12.0, "KC", "LV", null),
        Player.init("6", "WR3", .WR, 4000, 10.0, "KC", "LV", null),
        Player.init("7", "TE", .TE, 4000, 8.0, "KC", "LV", null),
        Player.init("8", "FLEX", .RB, 4000, 8.0, "KC", "LV", null),
        Player.init("9", "DST", .DST, 3000, 8.0, "KC", "LV", null),
    };
    
    var invalid_lineup = try Lineup.init(invalid_players, allocator);
    defer invalid_lineup.deinit(allocator);

    try std.testing.expect(!invalid_lineup.isValidRoster()); // Should fail due to 9 players from same team
    try std.testing.expect(!invalid_lineup.hasTeamDiversity()); // Should fail team diversity
}

test "Lineup duplicate player prevention" {
    const allocator = std.testing.allocator;

    // Invalid lineup: duplicate player IDs
    const duplicate_players = [9]Player{
        Player.init("1", "QB", .QB, 5000, 15.0, "KC", "LV", null),
        Player.init("1", "RB1", .RB, 4000, 10.0, "KC", "LV", null), // Duplicate ID
        Player.init("3", "RB2", .RB, 4000, 10.0, "DAL", "NYG", null),
        Player.init("4", "WR1", .WR, 5000, 12.0, "KC", "LV", null),
        Player.init("5", "WR2", .WR, 5000, 12.0, "DAL", "NYG", null),
        Player.init("6", "WR3", .WR, 4000, 10.0, "MIA", "BUF", null),
        Player.init("7", "TE", .TE, 4000, 8.0, "KC", "LV", null),
        Player.init("8", "FLEX", .RB, 4000, 8.0, "MIA", "BUF", null),
        Player.init("9", "DST", .DST, 3000, 8.0, "MIA", "BUF", null),
    };
    
    var duplicate_lineup = try Lineup.init(duplicate_players, allocator);
    defer duplicate_lineup.deinit(allocator);

    try std.testing.expect(!duplicate_lineup.isValidRoster()); // Should fail due to duplicate players
    try std.testing.expect(!duplicate_lineup.hasNoDuplicatePlayers()); // Should detect duplicates
}

test "Lineup player availability validation" {
    const allocator = std.testing.allocator;

    // Invalid lineup: contains OUT player
    const unavailable_players = [9]Player{
        player.Player.initWithStatus("1", "QB", .QB, 5000, 15.0, "KC", "LV", null, .OUT, false), // OUT player
        Player.init("2", "RB1", .RB, 4000, 10.0, "KC", "LV", null),
        Player.init("3", "RB2", .RB, 4000, 10.0, "DAL", "NYG", null),
        Player.init("4", "WR1", .WR, 5000, 12.0, "KC", "LV", null),
        Player.init("5", "WR2", .WR, 5000, 12.0, "DAL", "NYG", null),
        Player.init("6", "WR3", .WR, 4000, 10.0, "MIA", "BUF", null),
        Player.init("7", "TE", .TE, 4000, 8.0, "KC", "LV", null),
        Player.init("8", "FLEX", .RB, 4000, 8.0, "MIA", "BUF", null),
        Player.init("9", "DST", .DST, 3000, 8.0, "MIA", "BUF", null),
    };
    
    var unavailable_lineup = try Lineup.init(unavailable_players, allocator);
    defer unavailable_lineup.deinit(allocator);

    try std.testing.expect(!unavailable_lineup.isValidRoster()); // Should fail due to OUT player
    try std.testing.expect(!unavailable_lineup.hasAllPlayersAvailable()); // Should detect unavailable player
    
    // Test bye week player
    const bye_players = [9]Player{
        player.Player.initWithStatus("1", "QB", .QB, 5000, 15.0, "KC", "LV", null, .ACTIVE, true), // On bye
        Player.init("2", "RB1", .RB, 4000, 10.0, "KC", "LV", null),
        Player.init("3", "RB2", .RB, 4000, 10.0, "DAL", "NYG", null),
        Player.init("4", "WR1", .WR, 5000, 12.0, "KC", "LV", null),
        Player.init("5", "WR2", .WR, 5000, 12.0, "DAL", "NYG", null),
        Player.init("6", "WR3", .WR, 4000, 10.0, "MIA", "BUF", null),
        Player.init("7", "TE", .TE, 4000, 8.0, "KC", "LV", null),
        Player.init("8", "FLEX", .RB, 4000, 8.0, "MIA", "BUF", null),
        Player.init("9", "DST", .DST, 3000, 8.0, "MIA", "BUF", null),
    };
    
    var bye_lineup = try Lineup.init(bye_players, allocator);
    defer bye_lineup.deinit(allocator);

    try std.testing.expect(!bye_lineup.isValidRoster()); // Should fail due to bye week player
    try std.testing.expect(!bye_lineup.hasAllPlayersAvailable()); // Should detect bye week player
}

test "Lineup exact salary cap validation" {
    const allocator = std.testing.allocator;

    // Test exact $50k salary
    const exact_salary_players = [9]Player{
        Player.init("1", "QB", .QB, 8000, 20.0, "KC", "LV", null),
        Player.init("2", "RB1", .RB, 7000, 15.0, "KC", "LV", null),
        Player.init("3", "RB2", .RB, 6000, 12.0, "DAL", "NYG", null),
        Player.init("4", "WR1", .WR, 7500, 16.0, "KC", "LV", null),
        Player.init("5", "WR2", .WR, 6500, 14.0, "DAL", "NYG", null),
        Player.init("6", "WR3", .WR, 5000, 11.0, "MIA", "BUF", null),
        Player.init("7", "TE", .TE, 4500, 9.0, "KC", "LV", null),
        Player.init("8", "FLEX", .RB, 3000, 7.0, "MIA", "BUF", null),
        Player.init("9", "DST", .DST, 2500, 6.0, "MIA", "BUF", null),
    };
    
    var exact_lineup = try Lineup.init(exact_salary_players, allocator);
    defer exact_lineup.deinit(allocator);

    try std.testing.expect(exact_lineup.total_salary == 50000);
    try std.testing.expect(exact_lineup.isSalaryValid()); // Should pass <= 50k
    try std.testing.expect(exact_lineup.isSalaryExact()); // Should pass == 50k
    
    // Test under $50k salary
    const under_salary_players = [9]Player{
        Player.init("1", "QB", .QB, 5000, 15.0, "KC", "LV", null),
        Player.init("2", "RB1", .RB, 4000, 10.0, "KC", "LV", null),
        Player.init("3", "RB2", .RB, 4000, 10.0, "DAL", "NYG", null),
        Player.init("4", "WR1", .WR, 5000, 12.0, "KC", "LV", null),
        Player.init("5", "WR2", .WR, 5000, 12.0, "DAL", "NYG", null),
        Player.init("6", "WR3", .WR, 4000, 10.0, "MIA", "BUF", null),
        Player.init("7", "TE", .TE, 4000, 8.0, "KC", "LV", null),
        Player.init("8", "FLEX", .RB, 4000, 8.0, "MIA", "BUF", null),
        Player.init("9", "DST", .DST, 3000, 8.0, "MIA", "BUF", null),
    };
    
    var under_lineup = try Lineup.init(under_salary_players, allocator);
    defer under_lineup.deinit(allocator);

    try std.testing.expect(under_lineup.total_salary == 38000);
    try std.testing.expect(under_lineup.isSalaryValid()); // Should pass <= 50k
    try std.testing.expect(!under_lineup.isSalaryExact()); // Should fail == 50k
}