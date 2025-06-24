# Project Overview and Todo list.

The goal of this project is to build a NFL daily fantasy sports optimizer for draftkings.com.

## Tech Stack
- Zig for backend Logic
- Zig for CSV parsing
- Web interface
- CLI Tools & Utilities

## Data Flow
- The optimizer relies on CSV (Comma-Seperated Values) for both input and output.

## CSV FILES
- Player Pool CSV
- Game Metadata
- Rules & Constraints

## Processing In Zig
- Zig parses these CSVs into memory-efficient data structures.
- It applies optimization logic—filtering, simulating, stacking, solving for constraints, and maximizing projected value.
- Results are then written back out to CSV with high performance and minimal overhead.

## Output Data (CSV)
- The primary output is a lineup file: rows of player IDs/names representing full DFS lineups.

- Additional exports might include:

    - Exposure summaries by player.

    - Salary usage and projection totals.

    - Diagnostic logs (e.g., number of valid lineups generated, constraints hit, etc.).
