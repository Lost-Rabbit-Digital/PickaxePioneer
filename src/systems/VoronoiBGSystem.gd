## VoronoiBGSystem
## Generates a Voronoi-based darkness map for the BackgroundTileMapLayer.
## Returns a flat Array[float] (row-major: index = row * cols + col) where
## each value is 0.0 (edge / no darkening) → 1.0 (cell centre / max dark).
## MiningLevel._populate_background_tilemaplayer() uses this to choose
## between normal and dark tile atlas variants, creating organic rock-strata
## patches that are unique per planet (seeded from GameManager.terrain_seed).
class_name VoronoiBGSystem
extends RefCounted

## Number of Voronoi seed points spread across the grid.
const NUM_SEEDS: int = 55
## Minimum and maximum cell radius in tiles.
const MIN_RADIUS: float = 10.0
const MAX_RADIUS: float = 18.0


## Build and return the darkness map for a grid of (cols × rows) tiles.
## Values range from 0.0 (no darkening, outside any cell) to 1.0 (cell centre).
static func build_darkness_map(rng_seed: int, cols: int, rows: int) -> Array[float]:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed

	# Scatter seed points in tile-space.
	var seeds: PackedVector2Array = PackedVector2Array()
	var radii: PackedFloat32Array = PackedFloat32Array()
	seeds.resize(NUM_SEEDS)
	radii.resize(NUM_SEEDS)
	for i: int in NUM_SEEDS:
		seeds[i] = Vector2(
			rng.randf_range(0.0, float(cols)),
			rng.randf_range(0.0, float(rows))
		)
		radii[i] = rng.randf_range(MIN_RADIUS, MAX_RADIUS)

	# For each tile centre, find nearest seed and compute normalised darkness.
	var map: Array[float] = []
	map.resize(cols * rows)
	for row: int in rows:
		for col: int in cols:
			var pos := Vector2(float(col) + 0.5, float(row) + 0.5)
			var min_dist: float = INF
			var nearest_radius: float = MAX_RADIUS
			for j: int in NUM_SEEDS:
				var d: float = pos.distance_to(seeds[j])
				if d < min_dist:
					min_dist = d
					nearest_radius = radii[j]
			# Normalised distance 0..1 within the cell radius; clamp outside.
			if min_dist >= nearest_radius:
				map[row * cols + col] = 0.0
			else:
				var t: float = 1.0 - (min_dist / nearest_radius)
				# Quadratic ease-in: gradual fade from edges, concentrated at centre.
				map[row * cols + col] = t * t
	return map
