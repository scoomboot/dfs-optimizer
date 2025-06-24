# DraftKings NFL Classic Slate Constraints

This document defines all constraints and rules for DraftKings NFL classic slate daily fantasy lineups.

## Roster Construction

### Positions Required
- **1 QB** (Quarterback)
- **2 RB** (Running Back) 
- **3 WR** (Wide Receiver)
- **1 TE** (Tight End)
- **1 FLEX** (RB, WR, or TE)
- **1 DST** (Defense/Special Teams)

**Total**: 9 players per lineup

### Position Flexibility
- FLEX position can be filled by:
  - Running Back (RB)
  - Wide Receiver (WR) 
  - Tight End (TE)

## Financial Constraints

### Salary Cap
- **Maximum salary**: $50,000
- Must use entire salary cap (no unused salary allowed)
- Player salaries are fixed per slate

## Team and Game Constraints

### Team Limits
- **Maximum 8 players** from any single NFL team
- No minimum team representation required

### Game Limits
- No specific limits on players from same game
- Can roster entire game (both teams) if desired

### Bye Week Restrictions
- Players on bye weeks are not available
- All rostered players must be playing in current week's games

## Player Availability

### Injury Status
- **OUT**: Player not available for selection
- **DOUBTFUL**: Player available but at high risk
- **QUESTIONABLE**: Player available with moderate risk
- **PROBABLE/ACTIVE**: Player fully available

### Late Swap Rules
- Can substitute players up until their game kickoff
- Cannot swap players after their game has started
- Must maintain roster construction rules during swaps

## Lineup Validation

### Required Checks
1. Exactly 9 players selected
2. Correct position distribution (1 QB, 2 RB, 3 WR, 1 TE, 1 FLEX, 1 DST)
3. FLEX position filled with eligible position (RB/WR/TE)
4. Total salary ≤ $50,000
5. Maximum 8 players per team
6. No duplicate players
7. All players have active status
8. All players playing in current week

### Edge Cases
- **Multi-position players**: Use primary position unless specifically eligible for FLEX
- **Team changes**: Player team affiliation based on current roster
- **Salary changes**: Use most recent salary data for slate

## Contest-Specific Rules

### Classic Contests
- Standard rules as defined above
- Most common contest type

### Showdown/Single Game
- Different constraints (not covered in this document)
- Separate captain/MVP mechanics

### Tiers/Draft Contests
- Different constraints (not covered in this document)
- Position-based draft mechanics

## Implementation Notes

### Data Validation Priority
1. **Critical**: Roster construction, salary cap, team limits
2. **Important**: Player availability, bye weeks
3. **Warning**: Injury status flags

### Error Handling
- **Hard errors**: Invalid roster construction, salary violations
- **Soft warnings**: Questionable player status, sub-optimal builds

### Performance Considerations
- Pre-filter unavailable players before optimization
- Cache team/game mappings for efficient constraint checking
- Validate incrementally during lineup construction