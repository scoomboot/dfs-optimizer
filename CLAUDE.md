# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NFL daily fantasy sports optimizer for DraftKings built in Zig. The project processes CSV files containing player pool data, game metadata, and constraints to generate optimized DFS lineups.

## Architecture

The project uses a dual-module architecture:
- **Library module** (`src/root.zig`): Contains core optimization logic and utility functions
- **Executable module** (`src/main.zig`): CLI entry point that imports and uses the library

The executable module imports the library via `@import("dfs_optimizer_lib")` as configured in `build.zig`.

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
```

### Project Structure
- `build.zig`: Build configuration with library and executable targets
- `build.zig.zon`: Package manifest (minimum Zig version: 0.14.1)
- `src/main.zig`: Executable entry point with CLI interface
- `src/root.zig`: Library module with core optimization functions
- `OVERVIEW.md`: Project roadmap and technical requirements

## Key Technical Details

- **Language**: Zig (minimum version 0.14.1)
- **Build System**: Zig build system with static library linking
- **Data Format**: CSV input/output for maximum compatibility
- **Performance Focus**: Memory-efficient data structures and minimal overhead
- **Testing**: Comprehensive unit tests including fuzz testing capabilities
