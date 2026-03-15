## VoronoiBackgroundLayer
## Draws a semi-transparent dark overlay on top of the BackgroundTileMapLayer,
## using Voronoi cell patterns to create organic rock-strata patches.
## Each cell has a darkened centre that fades outward, giving the background
## depth without touching the TileMap tile atlas.
##
## Usage: call setup() once after terrain generation, passing the level seed
## and grid dimensions so the pattern is unique per planet.
class_name VoronoiBackgroundLayer
extends Node2D

## Number of Voronoi seed points scattered across the grid.
const NUM_SEEDS: int = 55
## Minimum cell radius in tiles.
const MIN_RADIUS: float = 10.0
## Maximum cell radius in tiles.
const MAX_RADIUS: float = 18.0
## Maximum overlay alpha at a cell centre.
## Derived from: bg_brightness * (1 - alpha) = target_brightness
##   0.344 * (1 - 0.564) ≈ 0.150  →  centre appears ~0.15 brightness.
const CENTRE_ALPHA: float = 0.564

var _texture: ImageTexture
var _draw_rect: Rect2


## Generate the Voronoi darkness map and prepare it for rendering.
## Call once after terrain generation in MiningLevel.
func setup(rng_seed: int, cols: int, rows: int, cell_size: int) -> void:
	# Override the NEAREST filter inherited from MiningLevel so the
	# low-res darkness texture interpolates smoothly when stretched.
	texture_filter = TEXTURE_FILTER_LINEAR
	_draw_rect = Rect2(Vector2.ZERO, Vector2(cols * cell_size, rows * cell_size))

	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed

	# Scatter seed points across the grid (tile-space coordinates).
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

	# Build a one-pixel-per-tile image storing the overlay alpha per tile.
	var img := Image.create(cols, rows, false, Image.FORMAT_RGBA8)

	for row: int in rows:
		for col: int in cols:
			var pos := Vector2(float(col) + 0.5, float(row) + 0.5)

			# Find the nearest Voronoi seed and its radius.
			var min_dist: float = INF
			var nearest_radius: float = MAX_RADIUS
			for j: int in NUM_SEEDS:
				var d: float = pos.distance_to(seeds[j])
				if d < min_dist:
					min_dist = d
					nearest_radius = radii[j]

			# Map distance to alpha: dark at centre, transparent at edge.
			if min_dist >= nearest_radius:
				img.set_pixel(col, row, Color(0.0, 0.0, 0.0, 0.0))
			else:
				var t: float = 1.0 - (min_dist / nearest_radius)
				# Quadratic ease-in: gradual fade from edge, sharper at centre.
				t = t * t
				img.set_pixel(col, row, Color(0.0, 0.0, 0.0, t * CENTRE_ALPHA))

	# Bilinear filtering on the small image produces smooth gradients when
	# stretched to full world-space size — no per-tile stepping artefacts.
	_texture = ImageTexture.create_from_image(img)
	queue_redraw()


func _draw() -> void:
	if _texture == null:
		return
	# Stretch the low-res darkness map over the entire grid with linear filtering.
	draw_texture_rect(_texture, _draw_rect, false)
