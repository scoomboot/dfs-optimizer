const std = @import("std");

pub const Position = enum {
    QB,
    RB,
    WR,
    TE,
    DST,
};

pub const InjuryStatus = enum {
    ACTIVE,
    PROBABLE, 
    QUESTIONABLE,
    DOUBTFUL,
    OUT,
};

pub const Player = struct {
    id: []const u8,
    name: []const u8,
    position: Position,
    salary: u32,
    projected_points: f64,
    team: []const u8,
    opponent: []const u8,
    game_info: ?[]const u8, // Optional reference to game metadata
    injury_status: InjuryStatus,
    is_on_bye: bool,

    pub fn init(
        id: []const u8,
        name: []const u8,
        position: Position,
        salary: u32,
        projected_points: f64,
        team: []const u8,
        opponent: []const u8,
        game_info: ?[]const u8,
    ) Player {
        return Player{
            .id = id,
            .name = name,
            .position = position,
            .salary = salary,
            .projected_points = projected_points,
            .team = team,
            .opponent = opponent,
            .game_info = game_info,
            .injury_status = .ACTIVE,
            .is_on_bye = false,
        };
    }
    
    pub fn initWithStatus(
        id: []const u8,
        name: []const u8,
        position: Position,
        salary: u32,
        projected_points: f64,
        team: []const u8,
        opponent: []const u8,
        game_info: ?[]const u8,
        injury_status: InjuryStatus,
        is_on_bye: bool,
    ) Player {
        return Player{
            .id = id,
            .name = name,
            .position = position,
            .salary = salary,
            .projected_points = projected_points,
            .team = team,
            .opponent = opponent,
            .game_info = game_info,
            .injury_status = injury_status,
            .is_on_bye = is_on_bye,
        };
    }

    pub fn pointsPerDollar(self: Player) f64 {
        if (self.salary == 0) return 0.0;
        return self.projected_points / @as(f64, @floatFromInt(self.salary));
    }

    pub fn isFlexEligible(self: Player) bool {
        return self.position == .RB or self.position == .WR or self.position == .TE;
    }
    
    pub fn isAvailable(self: Player) bool {
        // Players on bye weeks are not available
        if (self.is_on_bye) {
            return false;
        }
        
        // OUT players are not available
        if (self.injury_status == .OUT) {
            return false;
        }
        
        return true;
    }

    pub fn format(self: Player, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("Player{{ id: {s}, name: {s}, position: {}, salary: {}, projected_points: {d:.2}, team: {s} }}", .{
            self.id,
            self.name,
            self.position,
            self.salary,
            self.projected_points,
            self.team,
        });
    }
};

test "Player creation and basic operations" {
    const player = Player.init(
        "12345",
        "John Doe",
        .QB,
        8000,
        20.5,
        "KC",
        "LV",
        null,
    );

    try std.testing.expect(std.mem.eql(u8, player.id, "12345"));
    try std.testing.expect(std.mem.eql(u8, player.name, "John Doe"));
    try std.testing.expect(player.position == .QB);
    try std.testing.expect(player.salary == 8000);
    try std.testing.expect(player.projected_points == 20.5);
    try std.testing.expect(std.mem.eql(u8, player.team, "KC"));
    try std.testing.expect(std.mem.eql(u8, player.opponent, "LV"));
}

test "Player points per dollar calculation" {
    const player = Player.init(
        "12345",
        "John Doe",
        .QB,
        8000,
        20.0,
        "KC",
        "LV",
        null,
    );

    const ppd = player.pointsPerDollar();
    try std.testing.expect(ppd == 0.0025); // 20.0 / 8000 = 0.0025
}

test "Player FLEX eligibility" {
    const rb = Player.init("1", "RB Player", .RB, 6000, 15.0, "KC", "LV", null);
    const wr = Player.init("2", "WR Player", .WR, 7000, 16.0, "KC", "LV", null);
    const te = Player.init("3", "TE Player", .TE, 5000, 12.0, "KC", "LV", null);
    const qb = Player.init("4", "QB Player", .QB, 8000, 20.0, "KC", "LV", null);
    const dst = Player.init("5", "DST Player", .DST, 3000, 10.0, "KC", "LV", null);

    try std.testing.expect(rb.isFlexEligible());
    try std.testing.expect(wr.isFlexEligible());
    try std.testing.expect(te.isFlexEligible());
    try std.testing.expect(!qb.isFlexEligible());
    try std.testing.expect(!dst.isFlexEligible());
}