const std = @import("std");

pub const ScoringSystem = enum {
    DraftKingsPPR,
    DraftKingsStandard,
    FanDuelPPR,
    // Future platforms can be added here
};

pub const StatLine = struct {
    // Rushing stats
    rushing_yards: f64 = 0.0,
    rushing_tds: f64 = 0.0,
    
    // Receiving stats
    receiving_yards: f64 = 0.0,
    receiving_tds: f64 = 0.0,
    receptions: f64 = 0.0,
    
    // Passing stats
    passing_yards: f64 = 0.0,
    passing_tds: f64 = 0.0,
    interceptions: f64 = 0.0,
    
    // Other stats
    fumbles_lost: f64 = 0.0,
    
    // Defense/Special Teams stats
    defensive_tds: f64 = 0.0,
    sacks: f64 = 0.0,
    interceptions_def: f64 = 0.0,
    fumble_recoveries: f64 = 0.0,
    safeties: f64 = 0.0,
    blocked_kicks: f64 = 0.0,
    points_allowed: f64 = 0.0,
    yards_allowed: f64 = 0.0,
    
    pub fn init() StatLine {
        return StatLine{};
    }
};

pub fn calculateFantasyPoints(stats: StatLine, system: ScoringSystem) f64 {
    return switch (system) {
        .DraftKingsPPR => calculateDraftKingsPPR(stats),
        .DraftKingsStandard => calculateDraftKingsStandard(stats),
        .FanDuelPPR => calculateFanDuelPPR(stats),
    };
}

fn calculateDraftKingsPPR(stats: StatLine) f64 {
    var points: f64 = 0.0;
    
    // Rushing
    points += stats.rushing_yards * 0.1; // 1 point per 10 rushing yards
    points += stats.rushing_tds * 6.0; // 6 points per rushing TD
    
    // Receiving
    points += stats.receiving_yards * 0.1; // 1 point per 10 receiving yards  
    points += stats.receiving_tds * 6.0; // 6 points per receiving TD
    points += stats.receptions * 1.0; // 1 point per reception (PPR)
    
    // Passing
    points += stats.passing_yards * 0.04; // 1 point per 25 passing yards
    points += stats.passing_tds * 4.0; // 4 points per passing TD
    
    // Penalties
    points -= stats.interceptions * 1.0; // -1 point per interception
    points -= stats.fumbles_lost * 1.0; // -1 point per fumble lost
    
    // Defense/Special Teams (only apply if any defensive stats are present)
    const has_defensive_stats = stats.defensive_tds > 0.0 or stats.sacks > 0.0 or 
                               stats.interceptions_def > 0.0 or stats.fumble_recoveries > 0.0 or 
                               stats.safeties > 0.0 or stats.blocked_kicks > 0.0 or 
                               stats.points_allowed > 0.0 or stats.yards_allowed > 0.0;
    
    if (has_defensive_stats) {
        points += stats.defensive_tds * 6.0; // 6 points per defensive TD
        points += stats.sacks * 1.0; // 1 point per sack
        points += stats.interceptions_def * 2.0; // 2 points per interception
        points += stats.fumble_recoveries * 2.0; // 2 points per fumble recovery
        points += stats.safeties * 2.0; // 2 points per safety
        points += stats.blocked_kicks * 2.0; // 2 points per blocked kick
        
        // Defense points allowed scoring
        if (stats.points_allowed == 0.0) {
            points += 10.0;
        } else if (stats.points_allowed <= 6.0) {
            points += 7.0;
        } else if (stats.points_allowed <= 13.0) {
            points += 4.0;
        } else if (stats.points_allowed <= 20.0) {
            points += 1.0;
        } else if (stats.points_allowed <= 27.0) {
            points += 0.0;
        } else if (stats.points_allowed <= 34.0) {
            points -= 1.0;
        } else {
            points -= 4.0;
        }
    }
    
    // Yardage bonuses (3 bonus points for certain thresholds)
    if (stats.rushing_yards >= 100.0) points += 3.0;
    if (stats.receiving_yards >= 100.0) points += 3.0;
    if (stats.passing_yards >= 300.0) points += 3.0;
    
    return points;
}

fn calculateDraftKingsStandard(stats: StatLine) f64 {
    var points: f64 = 0.0;
    
    // Same as PPR but no reception points
    points += stats.rushing_yards * 0.1;
    points += stats.rushing_tds * 6.0;
    points += stats.receiving_yards * 0.1;
    points += stats.receiving_tds * 6.0;
    // No receptions points in standard scoring
    points += stats.passing_yards * 0.04;
    points += stats.passing_tds * 4.0;
    points -= stats.interceptions * 1.0;
    points -= stats.fumbles_lost * 1.0;
    
    // Defense/Special Teams (only apply if any defensive stats are present)
    const has_defensive_stats = stats.defensive_tds > 0.0 or stats.sacks > 0.0 or 
                               stats.interceptions_def > 0.0 or stats.fumble_recoveries > 0.0 or 
                               stats.safeties > 0.0 or stats.blocked_kicks > 0.0 or 
                               stats.points_allowed > 0.0 or stats.yards_allowed > 0.0;
    
    if (has_defensive_stats) {
        points += stats.defensive_tds * 6.0;
        points += stats.sacks * 1.0;
        points += stats.interceptions_def * 2.0;
        points += stats.fumble_recoveries * 2.0;
        points += stats.safeties * 2.0;
        points += stats.blocked_kicks * 2.0;
        
        // Same defense points allowed scoring
        if (stats.points_allowed == 0.0) {
            points += 10.0;
        } else if (stats.points_allowed <= 6.0) {
            points += 7.0;
        } else if (stats.points_allowed <= 13.0) {
            points += 4.0;
        } else if (stats.points_allowed <= 20.0) {
            points += 1.0;
        } else if (stats.points_allowed <= 27.0) {
            points += 0.0;
        } else if (stats.points_allowed <= 34.0) {
            points -= 1.0;
        } else {
            points -= 4.0;
        }
    }
    
    // Same yardage bonuses
    if (stats.rushing_yards >= 100.0) points += 3.0;
    if (stats.receiving_yards >= 100.0) points += 3.0;
    if (stats.passing_yards >= 300.0) points += 3.0;
    
    return points;
}

fn calculateFanDuelPPR(stats: StatLine) f64 {
    var points: f64 = 0.0;
    
    // FanDuel scoring (placeholder - would need actual FanDuel rules)
    points += stats.rushing_yards * 0.1;
    points += stats.rushing_tds * 6.0;
    points += stats.receiving_yards * 0.1;
    points += stats.receiving_tds * 6.0;
    points += stats.receptions * 0.5; // FanDuel is typically 0.5 PPR
    points += stats.passing_yards * 0.04;
    points += stats.passing_tds * 4.0;
    points -= stats.interceptions * 1.0;
    points -= stats.fumbles_lost * 1.0;
    
    return points;
}

// Utility functions for common scoring scenarios
pub fn calculateQBPoints(passing_yards: f64, passing_tds: f64, interceptions: f64, rushing_yards: f64, rushing_tds: f64, fumbles_lost: f64, system: ScoringSystem) f64 {
    const stats = StatLine{
        .passing_yards = passing_yards,
        .passing_tds = passing_tds,
        .interceptions = interceptions,
        .rushing_yards = rushing_yards,
        .rushing_tds = rushing_tds,
        .fumbles_lost = fumbles_lost,
    };
    return calculateFantasyPoints(stats, system);
}

pub fn calculateSkillPlayerPoints(rushing_yards: f64, rushing_tds: f64, receiving_yards: f64, receiving_tds: f64, receptions: f64, fumbles_lost: f64, system: ScoringSystem) f64 {
    const stats = StatLine{
        .rushing_yards = rushing_yards,
        .rushing_tds = rushing_tds,
        .receiving_yards = receiving_yards,
        .receiving_tds = receiving_tds,
        .receptions = receptions,
        .fumbles_lost = fumbles_lost,
    };
    return calculateFantasyPoints(stats, system);
}

pub fn calculateDefensePoints(defensive_tds: f64, sacks: f64, interceptions_def: f64, fumble_recoveries: f64, safeties: f64, blocked_kicks: f64, points_allowed: f64, system: ScoringSystem) f64 {
    const stats = StatLine{
        .defensive_tds = defensive_tds,
        .sacks = sacks,
        .interceptions_def = interceptions_def,
        .fumble_recoveries = fumble_recoveries,
        .safeties = safeties,
        .blocked_kicks = blocked_kicks,
        .points_allowed = points_allowed,
    };
    return calculateFantasyPoints(stats, system);
}

test "DraftKings PPR QB scoring" {
    // Test QB with 300 yards, 2 TDs, 1 INT, 50 rushing yards, 1 rushing TD
    const points = calculateQBPoints(300.0, 2.0, 1.0, 50.0, 1.0, 0.0, .DraftKingsPPR);
    // Expected: (300 * 0.04) + (2 * 4) + (-1 * 1) + (50 * 0.1) + (1 * 6) + 3 (300+ passing bonus)
    // = 12 + 8 - 1 + 5 + 6 + 3 = 33
    try std.testing.expect(points == 33.0);
}

test "DraftKings PPR skill player scoring" {
    // Test RB with 100 rushing yards, 1 rushing TD, 50 receiving yards, 1 receiving TD, 5 receptions
    const points = calculateSkillPlayerPoints(100.0, 1.0, 50.0, 1.0, 5.0, 0.0, .DraftKingsPPR);
    // Expected: (100 * 0.1) + (1 * 6) + (50 * 0.1) + (1 * 6) + (5 * 1) + 3 (100+ rushing bonus)
    // = 10 + 6 + 5 + 6 + 5 + 3 = 35
    try std.testing.expect(points == 35.0);
}

test "DraftKings defense scoring" {
    // Test defense with 1 TD, 3 sacks, 2 INTs, 1 fumble recovery, 0 points allowed
    const points = calculateDefensePoints(1.0, 3.0, 2.0, 1.0, 0.0, 0.0, 0.0, .DraftKingsPPR);
    // Expected: (1 * 6) + (3 * 1) + (2 * 2) + (1 * 2) + 10 (shutout bonus)
    // = 6 + 3 + 4 + 2 + 10 = 25
    try std.testing.expect(points == 25.0);
}

test "PPR vs Standard scoring difference" {
    // Test same stats with both scoring systems
    const ppr_points = calculateSkillPlayerPoints(50.0, 0.0, 80.0, 1.0, 8.0, 0.0, .DraftKingsPPR);
    const std_points = calculateSkillPlayerPoints(50.0, 0.0, 80.0, 1.0, 8.0, 0.0, .DraftKingsStandard);
    
    // PPR should be 8 points higher due to 8 receptions
    try std.testing.expect(ppr_points - std_points == 8.0);
}

test "Yardage bonus calculations" {
    // Test 100+ yard bonuses
    const stats = StatLine{
        .rushing_yards = 150.0,
        .receiving_yards = 120.0,
        .passing_yards = 350.0,
    };
    
    const points = calculateFantasyPoints(stats, .DraftKingsPPR);
    // Should include 9 bonus points (3 each for rushing, receiving, passing 100+ thresholds)
    const base_points = (150.0 * 0.1) + (120.0 * 0.1) + (350.0 * 0.04);
    const expected_points = base_points + 9.0; // 3 bonuses
    
    try std.testing.expect(points == expected_points);
}