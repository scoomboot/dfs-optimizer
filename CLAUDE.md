# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NFL daily fantasy sports optimizer for DraftKings built in Zig. The project processes CSV files containing player pool data, game metadata, and constraints to generate optimized DFS lineups.

## Architecture

The project uses a dual-module architecture with organized submodules:

### Core Architecture
- **Library module** (`src/root.zig`): Main library entry point that re-exports all submodules
- **Executable module** (`src/main.zig`): CLI entry point that imports and uses the library

The executable module imports the library via `@import("dfs_optimizer_lib")` as configured in `build.zig`.

### Project Structure
```
src/
├── main.zig              # CLI entry point
├── root.zig              # Library module entry point (re-exports all submodules)
├── models/               # Core data structures
│   ├── player.zig        # Player data model
│   ├── game.zig          # Game data model
│   ├── lineup.zig        # Lineup data model
│   └── models.zig        # Models module re-exports
├── parser/               # CSV parsing and I/O
│   ├── csv.zig           # Generic CSV parsing infrastructure
│   ├── player_parser.zig # DraftKings player pool parser
│   ├── game_parser.zig   # Game metadata parser
│   ├── rules_parser.zig  # Rules/constraints parser
│   ├── lineup_writer.zig # Lineup output writer
│   ├── exposure_writer.zig # Exposure summary writer
│   ├── diagnostics_writer.zig # Diagnostic logs writer
│   └── parser.zig        # Parser module re-exports
├── optimizer/            # Optimization algorithms and logic
│   ├── constraints.zig   # Salary cap and position constraints
│   ├── filters.zig       # Player pool filtering
│   ├── validation.zig    # Lineup validation
│   ├── stacking.zig      # Game/team stacking logic
│   ├── correlations.zig  # Anti-correlation logic
│   ├── greedy.zig        # Greedy optimization algorithm
│   ├── linear_programming.zig # Linear programming solver
│   ├── simulation.zig    # Monte Carlo simulation
│   ├── multi_lineup.zig  # Multi-lineup generation
│   └── optimizer.zig     # Optimizer module re-exports
├── cli/                  # Command line interface
│   ├── args.zig          # Argument parsing
│   ├── config.zig        # Configuration management
│   ├── progress.zig      # Progress reporting
│   └── cli.zig           # CLI module re-exports
├── advanced/             # Advanced features
│   ├── ownership.zig     # Ownership projection integration
│   ├── simulation.zig    # Advanced simulation engine
│   └── research.zig      # Research and analysis tools
├── performance/          # Performance optimization
│   ├── memory.zig        # Memory management utilities
│   ├── profiling.zig     # Performance profiling
│   └── benchmarks.zig    # Benchmark suite
└── utils/                # Utility functions
    ├── allocator.zig     # Memory management helpers
    ├── errors.zig        # Error handling utilities
    ├── time.zig          # Time/date utilities
    └── math.zig          # Mathematical helpers
```

### Module Organization
Each directory contains a module file (e.g., `models.zig`, `parser.zig`) that re-exports the public interfaces from that module's components. The main `root.zig` file re-exports all major modules for easy access.

## Data Flow

1. **Input**: CSV files containing player pool, game metadata, and rules/constraints
2. **Processing**: Zig parses CSVs into memory-efficient data structures, applies optimization logic (filtering, simulating, stacking, constraint solving)
3. **Output**: Lineup CSV files with player IDs/names, plus optional exposure summaries and diagnostic logs

## Development Commands

### Build and Run
```bash
# Build the project (default step)
zig build

# Build and run the executable
zig build run

# Run with arguments
zig build run -- arg1 arg2
```

### Testing
```bash
# Run all unit tests (both library and executable modules)
zig build test

# Run with fuzzing
zig build test --fuzz

# Run tests for a specific file
zig test src/models/player.zig

# Run tests for a specific module directory
zig test src/models/models.zig

# Run tests with verbose output
zig test src/models/player.zig --verbose
```

### Key Files
- `build.zig`: Build configuration with library and executable targets
- `build.zig.zon`: Package manifest (minimum Zig version: 0.14.1)
- `src/main.zig`: Executable entry point with CLI interface
- `src/root.zig`: Library module entry point that re-exports all submodules
- `TODO.md`: Detailed implementation roadmap with step-by-step tasks
- `OVERVIEW.md`: Project roadmap and technical requirements

### Implementation Guidelines
- **Follow TODO.md**: All development should follow the phase-by-phase plan in TODO.md
- **Modular Design**: Each module should have a clear, single responsibility
- **Re-export Pattern**: Use module files (e.g., `models.zig`) to re-export components
- **Test Coverage**: Every module should have corresponding unit tests
- **Clean Separation**: Keep data models, parsing, optimization, and CLI concerns separated

## Key Technical Details

- **Language**: Zig (minimum version 0.14.1)
- **Build System**: Zig build system with static library linking
- **Data Format**: CSV input/output for maximum compatibility
- **Performance Focus**: Memory-efficient data structures and minimal overhead
- **Testing**: Comprehensive unit tests including fuzz testing capabilities
