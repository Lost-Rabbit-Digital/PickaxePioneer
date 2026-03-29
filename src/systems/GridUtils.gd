class_name GridUtils
extends RefCounted

## Grid utility functions shared across mining systems.

## Returns true if the given column and row are within grid bounds.
static func is_valid(col: int, row: int, grid_cols: int, grid_rows: int) -> bool:
	return col >= 0 and col < grid_cols and row >= 0 and row < grid_rows

## Clamp a grid position to valid bounds.
static func clamp_pos(col: int, row: int, grid_cols: int, grid_rows: int) -> Vector2i:
	return Vector2i(clampi(col, 0, grid_cols - 1), clampi(row, 0, grid_rows - 1))

## Manhattan distance between two grid positions.
static func manhattan_distance(c1: int, r1: int, c2: int, r2: int) -> int:
	return absi(c1 - c2) + absi(r1 - r2)

## Euclidean distance between two grid positions.
static func grid_distance(c1: int, r1: int, c2: int, r2: int) -> float:
	return Vector2(c1 - c2, r1 - r2).length()
