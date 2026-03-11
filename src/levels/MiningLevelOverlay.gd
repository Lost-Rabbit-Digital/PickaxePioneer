class_name MiningLevelOverlay
extends Node2D

## Overlay renderer for MiningLevel.
## Draws all HUD-style overlays that must appear on top of TileMapLayer tiles:
## impact flashes, cursor highlight, ladder ghost, sonar ping, boss visuals,
## station coloured borders, ladder primitives, and level particles.
##
## z_index = 1 (set in scene) ensures this renders after TileMapLayer nodes (z=0).

# TileType mirror constants — kept in sync with MiningLevel.TileType
const _T_EMPTY            = 0
const _T_SURFACE          = 20
const _T_SURFACE_GRASS    = 21
const _T_EXIT_STATION     = 22
const _T_REENERGY_STATION = 19
const _T_UPGRADE_STATION  = 25
const _T_SMELTERY_STATION = 26
const _T_CAT_TAVERN       = 28
const _T_LADDER           = 27
const _T_ORE_COAL         = 3
const _T_ORE_COPPER       = 4
const _T_ORE_IRON         = 5
const _T_ORE_GOLD         = 6
const _T_ORE_DIAMOND      = 7
const _T_ENERGY_NODE      = 17
const _T_ENERGY_NODE_FULL = 18

## Reference to the owning MiningLevel (set by MiningLevel._ready via setup()).
var level: Node = null

func setup(mining_level: Node) -> void:
	level = mining_level


func _draw() -> void:
	if not level:
		return

	var camera: Camera2D = level.camera
	var cam_x: float
	var cam_y: float
	var VIEWPORT_W: int = level.VIEWPORT_W
	var VIEWPORT_H: int = level.VIEWPORT_H
	var GRID_COLS: int  = level.GRID_COLS
	var GRID_ROWS: int  = level.GRID_ROWS
	var CELL_SIZE: int  = level.CELL_SIZE

	if camera:
		cam_x = clamp(camera.position.x, VIEWPORT_W * 0.5, GRID_COLS * CELL_SIZE - VIEWPORT_W * 0.5)
		cam_y = clamp(camera.position.y, VIEWPORT_H * 0.5, GRID_ROWS * CELL_SIZE - VIEWPORT_H * 0.5)
	else:
		cam_x = VIEWPORT_W * 0.5
		cam_y = VIEWPORT_H * 0.5

	var half_w: float = float(VIEWPORT_W) * 0.5 + float(CELL_SIZE)
	var half_h: float = float(VIEWPORT_H) * 0.5 + float(CELL_SIZE)

	var min_col: int = maxi(0,           int((cam_x - half_w) / float(CELL_SIZE)))
	var max_col: int = mini(GRID_COLS - 1, int((cam_x + half_w) / float(CELL_SIZE)))
	var min_row: int = maxi(0,           int((cam_y - half_h) / float(CELL_SIZE)))
	var max_row: int = mini(GRID_ROWS - 1, int((cam_y + half_h) / float(CELL_SIZE)))

	var grid: Array        = level.grid
	var exit_pulse: float  = level._exit_pulse_time

	# -------------------------------------------------------------------------
	# Per-tile overlays: station borders, exit pulse, ladder primitives
	# -------------------------------------------------------------------------
	for col in range(min_col, max_col + 1):
		for row in range(min_row, max_row + 1):
			var tile: int = grid[col][row]
			if tile == _T_EMPTY or tile == _T_SURFACE:
				continue

			if tile == _T_EXIT_STATION:
				var pulse: float = sin(exit_pulse * 3.0) * 0.5 + 0.5
				draw_rect(Rect2(col * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE),
					Color(0.10 + pulse * 0.10, 0.40 + pulse * 0.20, 0.10 + pulse * 0.10))
				var border_alpha := 0.55 + pulse * 0.45
				draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4),
					Color(border_alpha, border_alpha, border_alpha), false, 2.0)
				if pulse > 0.6:
					var glow_alpha: float = (pulse - 0.6) / 0.4 * 0.35
					draw_rect(Rect2(col * CELL_SIZE - 3, row * CELL_SIZE - 3, CELL_SIZE + 6, CELL_SIZE + 6),
						Color(0.20, 0.90, 0.20, glow_alpha), false, 3.0)
				var exit_font := ThemeDB.fallback_font
				draw_string(exit_font,
					Vector2(col * CELL_SIZE, row * CELL_SIZE + CELL_SIZE / 2 + 5),
					"EXIT",
					HORIZONTAL_ALIGNMENT_CENTER, CELL_SIZE, 13,
					Color(0.35 + pulse * 0.45, 1.0, 0.35 + pulse * 0.20))
				continue

			if tile == _T_LADDER:
				var lx := col * CELL_SIZE
				var ly := row * CELL_SIZE
				draw_rect(Rect2(lx + 10, ly + 2, 8, CELL_SIZE - 4), Color(0.80, 0.60, 0.15, 0.90))
				draw_rect(Rect2(lx + CELL_SIZE - 18, ly + 2, 8, CELL_SIZE - 4), Color(0.80, 0.60, 0.15, 0.90))
				for rung in 3:
					draw_rect(Rect2(lx + 10, ly + 10 + rung * 18, CELL_SIZE - 20, 5),
						Color(0.70, 0.50, 0.10, 0.90))
				continue

			if tile == _T_REENERGY_STATION:
				draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4),
					Color.WHITE, false, 2.0)

			if tile == _T_UPGRADE_STATION:
				draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4),
					Color(0.40, 1.00, 0.60), false, 2.0)

			if tile == _T_SMELTERY_STATION:
				draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4),
					Color(1.0, 0.55, 0.0), false, 2.0)

			if tile == _T_CAT_TAVERN:
				draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4),
					Color(0.75, 0.35, 0.90), false, 2.0)
				var cfont := ThemeDB.fallback_font
				draw_string(cfont,
					Vector2(col * CELL_SIZE + 4, row * CELL_SIZE + CELL_SIZE / 2 + 5),
					"CAT", HORIZONTAL_ALIGNMENT_CENTER, CELL_SIZE - 8, 11, Color(0.90, 0.70, 1.00))

	# -------------------------------------------------------------------------
	# Impact flashes
	# -------------------------------------------------------------------------
	for pk in level._flash_cells:
		var fc: int = pk.x
		var fr: int = pk.y
		if fc >= min_col and fc <= max_col and fr >= min_row and fr <= max_row:
			draw_rect(Rect2(fc * CELL_SIZE, fr * CELL_SIZE, CELL_SIZE, CELL_SIZE),
				Color(1.0, 1.0, 1.0, level._flash_cells[pk]))

	# -------------------------------------------------------------------------
	# Cursor highlight — mining outline or ladder ghost
	# -------------------------------------------------------------------------
	if GameManager.selected_hotbar_slot == 1:
		if level._ladder_ghost_pos.x >= 0 and level._ladder_ghost_pos.y >= 0:
			var lx: int = level._ladder_ghost_pos.x * CELL_SIZE
			var ly: int = level._ladder_ghost_pos.y * CELL_SIZE
			const GHOST_ALPHA := 0.45
			var pole_c: Color
			var rung_c: Color
			var border_c: Color
			if level._ladder_ghost_valid:
				pole_c   = Color(0.20, 0.90, 0.20, GHOST_ALPHA)
				rung_c   = Color(0.15, 0.80, 0.15, GHOST_ALPHA)
				border_c = Color(0.20, 0.90, 0.20, 0.65)
			else:
				pole_c   = Color(0.90, 0.15, 0.10, GHOST_ALPHA)
				rung_c   = Color(0.80, 0.10, 0.08, GHOST_ALPHA)
				border_c = Color(0.90, 0.15, 0.10, 0.65)
			draw_rect(Rect2(lx + 10, ly + 2, 8, CELL_SIZE - 4), pole_c)
			draw_rect(Rect2(lx + CELL_SIZE - 18, ly + 2, 8, CELL_SIZE - 4), pole_c)
			for rung in 3:
				draw_rect(Rect2(lx + 10, ly + 10 + rung * 18, CELL_SIZE - 20, 5), rung_c)
			draw_rect(Rect2(lx, ly, CELL_SIZE, CELL_SIZE), border_c, false, 2.0)
	else:
		if level._cursor_grid_pos.x >= 0 and level._cursor_grid_pos.y >= 0:
			var cursor_col: int = level._cursor_grid_pos.x
			var cursor_row: int = level._cursor_grid_pos.y
			var tile_type: int = grid[cursor_col][cursor_row]
			var is_mineable: bool = level._is_tile_mineable(tile_type)
			# Only draw the border if it's a real block (not air) and is mineable (green border),
			# or if it's a real block and not mineable (red border for shops, protected blocks, etc.)
			if tile_type != _T_EMPTY:
				var border_color: Color = Color(0.20, 0.90, 0.20) if is_mineable else Color(0.90, 0.20, 0.20)
				_draw_dotted_border(cursor_col * CELL_SIZE, cursor_row * CELL_SIZE, CELL_SIZE, CELL_SIZE, border_color, 3)

	# -------------------------------------------------------------------------
	# Boss overlays — delegated to BossRenderer
	# -------------------------------------------------------------------------
	level._boss_renderer.draw_to(self, min_col, max_col, min_row, max_row)

	# -------------------------------------------------------------------------
	# Sonar ping overlay — expanding wave reveals ore tiles through rock
	# -------------------------------------------------------------------------
	if level.sonar_system.ping_active and level.sonar_system.ping_center.x >= 0:
		var ping_alpha: float = 1.0 - level.sonar_system.ping_elapsed / SonarSystem.PING_DURATION
		var max_radius := GameManager.get_sonar_ping_radius()
		var cx: int = level.sonar_system.ping_center.x
		var cy: int = level.sonar_system.ping_center.y
		var scan_r := int(max_radius) + 2
		for sc in range(maxi(min_col, cx - scan_r), mini(max_col + 1, cx + scan_r + 1)):
			for sr in range(maxi(min_row, cy - scan_r), mini(max_row + 1, cy + scan_r + 1)):
				var stile: int = grid[sc][sr]
				if stile != _T_ORE_COAL and stile != _T_ORE_COPPER \
				and stile != _T_ORE_IRON \
				and stile != _T_ORE_GOLD \
				and stile != _T_ORE_DIAMOND \
				and stile != _T_ENERGY_NODE and stile != _T_ENERGY_NODE_FULL:
					continue
				var dist := Vector2(sc - cx, sr - cy).length()
				if dist > level.sonar_system.wave_radius:
					continue
				var glow_age: float = level.sonar_system.wave_radius - dist
				var glow_alpha := maxf(0.0, ping_alpha - glow_age * 0.12) * 0.80
				if glow_alpha <= 0.02:
					continue
				var glow_color := Color(0.20, 1.0, 0.40, glow_alpha)
				if GameManager.mineral_sense_level >= 2:
					if stile == _T_ORE_DIAMOND:
						glow_color = Color(0.10, 0.90, 1.00, glow_alpha)
					elif stile == _T_ORE_GOLD:
						glow_color = Color(1.00, 0.85, 0.10, glow_alpha)
					elif stile == _T_ORE_IRON:
						glow_color = Color(0.65, 0.65, 1.00, glow_alpha)
					elif stile == _T_ORE_COPPER:
						glow_color = Color(0.90, 0.60, 0.25, glow_alpha)
					elif stile == _T_ENERGY_NODE or stile == _T_ENERGY_NODE_FULL:
						glow_color = Color(0.30, 1.00, 0.30, glow_alpha)
				draw_rect(Rect2(sc * CELL_SIZE, sr * CELL_SIZE, CELL_SIZE, CELL_SIZE), glow_color)
		var wave_px: float = level.sonar_system.wave_radius * CELL_SIZE
		var center_px := Vector2(cx * CELL_SIZE + CELL_SIZE * 0.5, cy * CELL_SIZE + CELL_SIZE * 0.5)
		if wave_px > 0:
			draw_arc(center_px, wave_px, 0.0, TAU, 48, Color(0.40, 1.0, 0.60, ping_alpha * 0.55), 2.0)

	# -------------------------------------------------------------------------
	# Level particles — mining sparks, lava embers, ore bursts
	# -------------------------------------------------------------------------
	for p: Dictionary in level._level_particles:
		var sz: float = p["size"]
		var alpha: float = p["life"] / p["max_life"]
		var c: Color = p["color"]
		c.a = alpha
		draw_rect(Rect2(p["pos"].x - sz * 0.5, p["pos"].y - sz * 0.5, sz, sz), c)


## Draw a dotted border around a rectangle.
## Draws 6px solid segments with 4px gaps to create a dotted effect.
func _draw_dotted_border(x: float, y: float, w: float, h: float, color: Color, line_width: float) -> void:
	const DOT_SIZE: int = 6
	const GAP_SIZE: int = 4

	# Top border
	var pos = x
	while pos < x + w:
		var end_pos = mini(pos + DOT_SIZE, x + w)
		draw_line(Vector2(pos, y), Vector2(end_pos, y), color, line_width)
		pos += DOT_SIZE + GAP_SIZE

	# Bottom border
	pos = x
	while pos < x + w:
		var end_pos = mini(pos + DOT_SIZE, x + w)
		draw_line(Vector2(pos, y + h), Vector2(end_pos, y + h), color, line_width)
		pos += DOT_SIZE + GAP_SIZE

	# Left border
	pos = y
	while pos < y + h:
		var end_pos = mini(pos + DOT_SIZE, y + h)
		draw_line(Vector2(x, pos), Vector2(x, end_pos), color, line_width)
		pos += DOT_SIZE + GAP_SIZE

	# Right border
	pos = y
	while pos < y + h:
		var end_pos = mini(pos + DOT_SIZE, y + h)
		draw_line(Vector2(x + w, pos), Vector2(x + w, end_pos), color, line_width)
		pos += DOT_SIZE + GAP_SIZE
