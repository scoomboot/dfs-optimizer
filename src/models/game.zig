const std = @import("std");

pub const Game = struct {
    id: []const u8,
    home_team: []const u8,
    away_team: []const u8,
    game_time: []const u8, // ISO 8601 format or similar
    vegas_total: ?f64, // Over/under line (optional)
    spread: ?f64, // Point spread (optional, positive means home team favored)
    weather: ?[]const u8, // Weather conditions (optional)

    pub fn init(
        id: []const u8,
        home_team: []const u8,
        away_team: []const u8,
        game_time: []const u8,
        vegas_total: ?f64,
        spread: ?f64,
        weather: ?[]const u8,
    ) Game {
        return Game{
            .id = id,
            .home_team = home_team,
            .away_team = away_team,
            .game_time = game_time,
            .vegas_total = vegas_total,
            .spread = spread,
            .weather = weather,
        };
    }

    pub fn hasTeam(self: Game, team: []const u8) bool {
        return std.mem.eql(u8, self.home_team, team) or std.mem.eql(u8, self.away_team, team);
    }

    pub fn getOpponent(self: Game, team: []const u8) ?[]const u8 {
        if (std.mem.eql(u8, self.home_team, team)) {
            return self.away_team;
        } else if (std.mem.eql(u8, self.away_team, team)) {
            return self.home_team;
        }
        return null;
    }

    pub fn isHomeTeam(self: Game, team: []const u8) bool {
        return std.mem.eql(u8, self.home_team, team);
    }

    pub fn format(self: Game, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        const vegas_str = if (self.vegas_total) |total| total else 0.0;
        const spread_str = if (self.spread) |s| s else 0.0;
        const weather_str = if (self.weather) |w| w else "N/A";
        
        try writer.print("Game{{ id: {s}, matchup: {s}@{s}, time: {s}, total: {d:.1}, spread: {d:.1}, weather: {s} }}", .{
            self.id,
            self.away_team,
            self.home_team,
            self.game_time,
            vegas_str,
            spread_str,
            weather_str,
        });
    }
};

test "Game creation and basic operations" {
    const game = Game.init(
        "KC@LV_2024",
        "LV",
        "KC",
        "2024-10-15T20:00:00Z",
        45.5,
        -3.5,
        "Clear, 72°F",
    );

    try std.testing.expect(std.mem.eql(u8, game.id, "KC@LV_2024"));
    try std.testing.expect(std.mem.eql(u8, game.home_team, "LV"));
    try std.testing.expect(std.mem.eql(u8, game.away_team, "KC"));
    try std.testing.expect(std.mem.eql(u8, game.game_time, "2024-10-15T20:00:00Z"));
    try std.testing.expect(game.vegas_total.? == 45.5);
    try std.testing.expect(game.spread.? == -3.5);
    try std.testing.expect(std.mem.eql(u8, game.weather.?, "Clear, 72°F"));
}

test "Game team operations" {
    const game = Game.init(
        "KC@LV_2024",
        "LV",
        "KC",
        "2024-10-15T20:00:00Z",
        45.5,
        -3.5,
        null,
    );

    // Test hasTeam
    try std.testing.expect(game.hasTeam("KC"));
    try std.testing.expect(game.hasTeam("LV"));
    try std.testing.expect(!game.hasTeam("DAL"));

    // Test getOpponent
    const kc_opponent = game.getOpponent("KC");
    try std.testing.expect(kc_opponent != null);
    try std.testing.expect(std.mem.eql(u8, kc_opponent.?, "LV"));

    const lv_opponent = game.getOpponent("LV");
    try std.testing.expect(lv_opponent != null);
    try std.testing.expect(std.mem.eql(u8, lv_opponent.?, "KC"));

    const no_opponent = game.getOpponent("DAL");
    try std.testing.expect(no_opponent == null);

    // Test isHomeTeam
    try std.testing.expect(!game.isHomeTeam("KC")); // KC is away
    try std.testing.expect(game.isHomeTeam("LV")); // LV is home
    try std.testing.expect(!game.isHomeTeam("DAL")); // DAL not in game
}

test "Game with null optional fields" {
    const game = Game.init(
        "KC@LV_2024",
        "LV",
        "KC",
        "2024-10-15T20:00:00Z",
        null,
        null,
        null,
    );

    try std.testing.expect(game.vegas_total == null);
    try std.testing.expect(game.spread == null);
    try std.testing.expect(game.weather == null);
}