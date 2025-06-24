# DFS Optimizer Development TODO

## Phase 1: Core Data Structures

### 1.1 Player Data Model
- [x] Define `Player` struct with fields:
  - `id`: player identifier
  - `name`: player name
  - `position`: position (QB, RB, WR, TE, K, DST)
  - `salary`: DraftKings salary
  - `projected_points`: fantasy point projection
  - `team`: team abbreviation
  - `opponent`: opponent team
  - `game_info`: game metadata reference

### 1.2 Game Data Model
- [ ] Define `Game` struct with fields:
  - `id`: unique game identifier
  - `home_team`: home team abbreviation
  - `away_team`: away team abbreviation
  - `game_time`: kickoff time
  - `vegas_total`: over/under line
  - `spread`: point spread
  - `weather`: weather conditions (if applicable)

### 1.3 Lineup Data Model
- [ ] Define `Lineup` struct with fields:
  - `players`: array of 9 players (1 QB, 2 RB, 3 WR, 1 TE, 1 FLEX, 1 K, 1 DST)
  - `total_salary`: sum of all player salaries
  - `projected_points`: sum of all player projections
  - `stacks`: tracking of game/team stacks

## Phase 2: CSV Processing

### 2.1 CSV Parsing Infrastructure
- [ ] Implement generic CSV parser using Zig's allocator system
- [ ] Add error handling for malformed CSV data
- [ ] Create CSV field mapping utilities

### 2.2 Input File Parsers
- [ ] Player pool CSV parser (DraftKings format)
- [ ] Game metadata CSV parser
- [ ] Rules/constraints CSV parser
- [ ] Validation for required fields and data types

### 2.3 Output File Writers
- [ ] Lineup CSV writer (DraftKings submission format)
- [ ] Exposure summary CSV writer
- [ ] Diagnostic log CSV writer

## Phase 3: Optimization Engine

### 3.1 Constraint System
- [ ] Salary cap constraint (≤ $50,000)
- [ ] Position requirements constraint (exact roster composition)
- [ ] Player pool filtering (remove injured/inactive players)
- [ ] Duplicate player prevention across lineups

### 3.2 Stacking Logic
- [ ] Game stack implementation (players from same game)
- [ ] Team stack implementation (multiple players from same team)
- [ ] Anti-correlation logic (avoid opposing defenses)
- [ ] Configurable stacking parameters

### 3.3 Optimization Algorithms
- [ ] Greedy optimization (highest points per dollar)
- [ ] Linear programming solver for optimal lineup generation
- [ ] Multi-lineup generation with diversity constraints
- [ ] Simulation-based optimization with variance consideration

## Phase 4: CLI Interface

### 4.1 Command Line Argument Parsing
- [ ] Input file path arguments
- [ ] Output directory specification
- [ ] Number of lineups to generate
- [ ] Optimization strategy selection
- [ ] Verbosity/logging level control

### 4.2 Configuration Management
- [ ] Default parameter configuration
- [ ] User-configurable optimization settings
- [ ] Stack percentage settings
- [ ] Salary utilization targets

### 4.3 Progress Reporting
- [ ] Real-time optimization progress display
- [ ] Performance metrics reporting
- [ ] Error and warning message handling

## Phase 5: Advanced Features

### 5.1 Ownership Projection Integration
- [ ] Player ownership percentage data ingestion
- [ ] GPP (tournament) optimization considering ownership
- [ ] Contrarian lineup generation
- [ ] Leverage calculation and reporting

### 5.2 Simulation Engine
- [ ] Monte Carlo simulation for lineup scoring
- [ ] Variance-based lineup ranking
- [ ] Risk/reward analysis
- [ ] Tournament finish probability calculations

### 5.3 Research Tools
- [ ] Correlation analysis between players
- [ ] Historical performance backtesting
- [ ] Slate analysis and metrics
- [ ] Player consistency scoring

## Phase 6: Performance & Quality

### 6.1 Memory Optimization
- [ ] Efficient data structure allocation
- [ ] Memory pool management for large player pools
- [ ] Garbage collection optimization
- [ ] Memory usage profiling and optimization

### 6.2 Performance Optimization
- [ ] Algorithm complexity analysis
- [ ] Parallel processing for multiple lineup generation
- [ ] Caching for repeated calculations
- [ ] Benchmark suite development

### 6.3 Testing Suite
- [ ] Unit tests for all core functions
- [ ] Integration tests with sample CSV data
- [ ] Fuzz testing for CSV parsing
- [ ] Performance regression tests
- [ ] Constraint validation tests

## Phase 7: Documentation & Deployment

### 7.1 User Documentation
- [ ] Usage examples and tutorials
- [ ] CSV format specifications
- [ ] Configuration option documentation
- [ ] Troubleshooting guide

### 7.2 Developer Documentation
- [ ] Code architecture documentation
- [ ] API reference
- [ ] Contributing guidelines
- [ ] Build and deployment instructions

## Implementation Priority

**Phase 1-2**: Core foundation (data structures + CSV processing)
**Phase 3**: Basic optimization engine
**Phase 4**: CLI interface for usability
**Phase 5**: Advanced features for competitive edge
**Phase 6-7**: Polish and documentation

## Current Status

- [x] Project structure setup
- [x] Build configuration
- [ ] All other items pending

## Next Steps

1. Start with Phase 1.1: Define core Player data structure
2. Implement basic CSV parsing for player pool data
3. Create simple lineup generation logic
4. Add CLI interface for file input/output
5. Iterate and add advanced features
