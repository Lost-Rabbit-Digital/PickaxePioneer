class_name BossRenderer
extends RefCounted

# ---------------------------------------------------------------------------
# Boss tile-type constants (must stay in sync with MiningLevel.TileType)
# ---------------------------------------------------------------------------
const BOSS_SEGMENT = 23
const BOSS_CORE    = 24

# ---------------------------------------------------------------------------
# References set once via setup()
# ---------------------------------------------------------------------------
var _boss: BossSystem
var _grid: Array
var _cell_size: int

func setup(boss_system: BossSystem, grid: Array, cell_size: int) -> void:
	_boss      = boss_system
	_grid      = grid
	_cell_size = cell_size

# ---------------------------------------------------------------------------
# Entry point — called from MiningLevel._draw() with viewport tile bounds
# ---------------------------------------------------------------------------

## Draw all boss visual overlays onto `canvas` (must be called from _draw()).
## Renders: per-segment pulse fills, boss-type creature shapes, warning vignettes.
func draw_to(
		canvas: Node2D,
		min_col: int, max_col: int,
		min_row: int, max_row: int) -> void:

	if not _boss or not _boss.boss_active:
		return
	if _boss.boss_tile_positions.is_empty() and _boss.boss_segments.is_empty():
		return

	var boss_pulse := sin(_boss.boss_pulse_time * 4.5) * 0.5 + 0.5

	# Choose colour palette based on boss type
	var core_fill   := Color(1.0, 0.05, 0.05, 0.28 + boss_pulse * 0.28)
	var core_border := Color(1.0, 0.80, 0.10, 0.50 + boss_pulse * 0.30)
	var seg_fill    := Color(0.85, 0.15, 0.05, 0.18 + boss_pulse * 0.18)
	var seg_border  := Color(0.70, 0.20, 0.05, 0.40 + boss_pulse * 0.25)

	match _boss.boss_type:
		BossSystem.BOSS_TYPE_MOLE:
			core_fill   = Color(0.50, 0.30, 0.08, 0.30 + boss_pulse * 0.28)
			core_border = Color(0.80, 0.60, 0.20, 0.55 + boss_pulse * 0.30)
			seg_fill    = Color(0.40, 0.25, 0.05, 0.18 + boss_pulse * 0.18)
			seg_border  = Color(0.60, 0.40, 0.10, 0.40 + boss_pulse * 0.25)
		BossSystem.BOSS_TYPE_ANCIENT:
			var ancient_phase_colors: Array = [
				[Color(0.10, 0.60, 0.80), Color(0.30, 0.90, 1.00)],
				[Color(0.55, 0.10, 0.80), Color(0.78, 0.40, 1.00)],
				[Color(0.90, 0.90, 1.00), Color(1.00, 1.00, 0.60)],
			]
			var ap := clampi(_boss.ancient_phase, 0, ancient_phase_colors.size() - 1)
			var apc0: Color = ancient_phase_colors[ap][0]
			var apc1: Color = ancient_phase_colors[ap][1]
			core_fill   = Color(apc0, 0.35 + boss_pulse * 0.30)
			core_border = Color(apc1, 0.60 + boss_pulse * 0.30)
			seg_fill    = Color(apc0, 0.20 + boss_pulse * 0.20)
			seg_border  = Color(apc1, 0.45 + boss_pulse * 0.25)
		BossSystem.BOSS_TYPE_GOLEM:
			var phase_colors: Array = [
				[Color(0.80, 0.50, 0.20), Color(0.95, 0.70, 0.40)],
				[Color(0.55, 0.55, 0.65), Color(0.75, 0.75, 0.90)],
				[Color(1.00, 0.85, 0.10), Color(1.00, 1.00, 0.50)],
			]
			var pi := clampi(_boss.golem_phase, 0, phase_colors.size() - 1)
			var gpc0: Color = phase_colors[pi][0]
			var gpc1: Color = phase_colors[pi][1]
			core_fill   = Color(gpc0, 0.30 + boss_pulse * 0.28)
			core_border = Color(gpc1, 0.55 + boss_pulse * 0.30)
			seg_fill    = Color(gpc0, 0.18 + boss_pulse * 0.18)
			seg_border  = Color(gpc1, 0.40 + boss_pulse * 0.25)

	# Creature shapes
	_draw_boss_creatures(canvas, min_col, max_col, min_row, max_row,
		boss_pulse, core_fill, core_border, seg_fill, seg_border)

	# Energy-drain warning vignette
	if boss_pulse > 0.75:
		var va := (boss_pulse - 0.75) / 0.25 * 0.12
		canvas.draw_rect(Rect2(min_col * _cell_size, min_row * _cell_size,
			(max_col - min_col + 1) * _cell_size, 4), Color(1.0, 0.0, 0.0, va))
		canvas.draw_rect(Rect2(min_col * _cell_size, max_row * _cell_size,
			(max_col - min_col + 1) * _cell_size, 4), Color(1.0, 0.0, 0.0, va))

	# Blind Mole tremor warning
	if _boss.boss_type == BossSystem.BOSS_TYPE_MOLE and _boss.mole_tremor_warning_active:
		_draw_edge_vignette(canvas, min_col, max_col, min_row, max_row,
			1.0 - (_boss.mole_tremor_warning_timer / BossSystem.MOLE_TREMOR_WARNING),
			0.35, Color(0.55, 0.30, 0.05), 8)

	# Giant Rat charge warning
	if _boss.boss_type == BossSystem.BOSS_TYPE_GIANT_RAT and _boss.rat_charge_warning_active:
		_draw_edge_vignette(canvas, min_col, max_col, min_row, max_row,
			1.0 - (_boss.rat_charge_warning_timer / BossSystem.RAT_CHARGE_WARNING),
			0.40, Color(0.90, 0.20, 0.05), 8)

	# Void Spider web warning + target zone
	if _boss.boss_type == BossSystem.BOSS_TYPE_SPIDER and _boss.spider_web_warning_active:
		_draw_edge_vignette(canvas, min_col, max_col, min_row, max_row,
			1.0 - (_boss.spider_web_warning_timer / BossSystem.SPIDER_WEB_WARNING),
			0.40, Color(0.30, 0.80, 0.20), 8)
		var wt := _boss.spider_web_target_pos
		if wt.x >= 0:
			var web_pulse := sin(_boss.boss_pulse_time * 8.0) * 0.5 + 0.5
			var wr := BossSystem.SPIDER_WEB_RADIUS
			canvas.draw_rect(Rect2(
				(wt.x - wr) * _cell_size, (wt.y - wr) * _cell_size,
				(wr * 2 + 1) * _cell_size, (wr * 2 + 1) * _cell_size),
				Color(0.30, 0.80, 0.20, 0.15 + web_pulse * 0.20), false, 2.0)

	# Stone Golem: required ore type label
	if _boss.boss_type == BossSystem.BOSS_TYPE_GOLEM \
			and _boss.golem_phase < BossSystem.GOLEM_PHASE_ORES.size():
		var golem_label := "Mine: " + BossSystem.GOLEM_PHASE_ORES[_boss.golem_phase].capitalize()
		var label_px := _find_core_label_px(Vector2(-40.0, -22.0))
		if label_px.x > -9000.0:
			canvas.draw_string(ThemeDB.fallback_font, label_px, golem_label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.95, 0.50, 0.90))

	# Ancient One: void-pulse warning (phase 2)
	if _boss.boss_type == BossSystem.BOSS_TYPE_ANCIENT and _boss.ancient_void_warning_active:
		_draw_edge_vignette(canvas, min_col, max_col, min_row, max_row,
			1.0 - (_boss.ancient_void_warning_timer / BossSystem.ANCIENT_VOID_PULSE_WARNING),
			0.45, Color(0.50, 0.05, 0.80), 8)

	# Ancient One: core recharge warning ring
	if _boss.boss_type == BossSystem.BOSS_TYPE_ANCIENT and _boss.ancient_core_recharge_warning:
		for seg in _boss.boss_segments:
			if seg.is_core:
				var ra := (sin(_boss.boss_pulse_time * 9.0) * 0.5 + 0.5) * 0.50
				canvas.draw_rect(Rect2(
					seg.pos.x - 2.5 * _cell_size, seg.pos.y - 2.5 * _cell_size,
					5 * _cell_size, 5 * _cell_size),
					Color(1.0, 1.0, 0.80, ra), false, 3.0)
				break

	# Ancient One: phase label
	if _boss.boss_type == BossSystem.BOSS_TYPE_ANCIENT:
		var labels: Array[String] = ["SHELL PHASE", "CRYSTAL PHASE", "CORE PHASE"]
		var al := labels[clampi(_boss.ancient_phase, 0, labels.size() - 1)]
		var label_px2 := _find_core_label_px(Vector2(-44.0, -22.0))
		if label_px2.x > -9000.0:
			canvas.draw_string(ThemeDB.fallback_font, label_px2, al,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.80, 0.55, 1.00, 0.90))

# ---------------------------------------------------------------------------
# Creature drawing — dispatches by boss type
# ---------------------------------------------------------------------------

func _draw_boss_creatures(
		canvas: Node2D,
		min_col: int, max_col: int, min_row: int, max_row: int,
		pulse: float,
		core_fill: Color, core_border: Color,
		seg_fill: Color, seg_border: Color) -> void:
	var t := _boss.boss_pulse_time
	match _boss.boss_type:
		BossSystem.BOSS_TYPE_GIANT_RAT:
			_draw_rat(canvas, min_col, max_col, min_row, max_row, t, pulse, core_fill, core_border, seg_fill, seg_border)
		BossSystem.BOSS_TYPE_SPIDER:
			_draw_spider(canvas, min_col, max_col, min_row, max_row, t, pulse, core_fill, core_border, seg_fill, seg_border)
		BossSystem.BOSS_TYPE_MOLE:
			_draw_mole(canvas, min_col, max_col, min_row, max_row, t, pulse, core_fill, core_border, seg_fill, seg_border)
		BossSystem.BOSS_TYPE_GOLEM:
			_draw_golem(canvas, min_col, max_col, min_row, max_row, t, pulse, core_fill, core_border, seg_fill, seg_border)
		BossSystem.BOSS_TYPE_ANCIENT:
			_draw_ancient(canvas, min_col, max_col, min_row, max_row, t, pulse, core_fill, core_border, seg_fill, seg_border)

# ---------------------------------------------------------------------------
# Giant Rat King
# ---------------------------------------------------------------------------

func _draw_rat(canvas: Node2D, min_col: int, max_col: int, min_row: int, max_row: int,
		t: float, pulse: float,
		core_fill: Color, core_border: Color, seg_fill: Color, seg_border: Color) -> void:
	var vp_left  := float(min_col * _cell_size - _cell_size)
	var vp_right := float((max_col + 2) * _cell_size)
	var vp_top   := float(min_row * _cell_size - _cell_size)
	var vp_bot   := float((max_row + 2) * _cell_size)

	for seg in _boss.boss_segments:
		var sp: Vector2 = seg.pos
		if sp.x < vp_left or sp.x > vp_right or sp.y < vp_top or sp.y > vp_bot:
			continue

		var cx := sp.x
		var cy := sp.y + sin(t * 3.5 + cx * 0.01) * 6.0

		# HP-based damage tint — segments get redder as they take damage
		var hp_ratio := float(seg.hp) / float(seg.max_hp)
		var damage_tint := 1.0 - hp_ratio  # 0 = full HP, 1 = almost dead

		if seg.is_core:
			var hw := 26.0 + pulse * 3.0
			var hh := 22.0 + pulse * 4.0
			var pts := PackedVector2Array()
			for i in 12:
				var a := float(i) / 12.0 * TAU
				pts.append(Vector2(cx + cos(a) * hw, cy + sin(a) * hh))
			var cf := Color(core_fill.r + damage_tint * 0.3, core_fill.g, core_fill.b, core_fill.a)
			canvas.draw_polygon(pts, PackedColorArray([cf]))
			canvas.draw_polyline(pts + PackedVector2Array([pts[0]]), core_border, 2.5)
			# Ears
			var ec := Color(core_border.r, core_border.g, core_border.b, 0.90)
			canvas.draw_polygon(PackedVector2Array([
				Vector2(cx - 18, cy - 20), Vector2(cx - 10, cy - 34), Vector2(cx - 4, cy - 20)
			]), PackedColorArray([ec]))
			canvas.draw_polygon(PackedVector2Array([
				Vector2(cx + 4, cy - 20), Vector2(cx + 10, cy - 34), Vector2(cx + 18, cy - 20)
			]), PackedColorArray([ec]))
			# Eyes
			var eye_bright := Color(1.0, 0.85, 0.0, 0.7 + pulse * 0.3)
			canvas.draw_circle(Vector2(cx - 9, cy - 5), 5.0 + pulse * 2.0, eye_bright)
			canvas.draw_circle(Vector2(cx + 9, cy - 5), 5.0 + pulse * 2.0, eye_bright)
			# Whiskers
			var wc := Color(1.0, 0.9, 0.6, 0.55)
			for side in [-1.0, 1.0]:
				canvas.draw_line(Vector2(cx + side * 8, cy + 4), Vector2(cx + side * 28, cy + 1), wc, 1.5)
				canvas.draw_line(Vector2(cx + side * 8, cy + 8), Vector2(cx + side * 28, cy + 8), wc, 1.5)
		else:
			var sw := 20.0 + pulse * 3.0
			var sh := 16.0 + sin(t * 2.8 + seg.angle) * 4.0
			var spts := PackedVector2Array()
			for i in 8:
				var a := float(i) / 8.0 * TAU
				spts.append(Vector2(cx + cos(a) * sw, cy + sin(a) * sh))
			var sf := Color(seg_fill.r + damage_tint * 0.4, seg_fill.g * (1.0 - damage_tint * 0.3), seg_fill.b, seg_fill.a)
			canvas.draw_polygon(spts, PackedColorArray([sf]))
			canvas.draw_polyline(spts + PackedVector2Array([spts[0]]), seg_border, 1.5)

# ---------------------------------------------------------------------------
# Void Spider Matriarch
# ---------------------------------------------------------------------------

func _draw_spider(canvas: Node2D, min_col: int, max_col: int, min_row: int, max_row: int,
		t: float, pulse: float,
		core_fill: Color, core_border: Color, seg_fill: Color, seg_border: Color) -> void:
	var vp_left  := float(min_col * _cell_size - _cell_size * 2)
	var vp_right := float((max_col + 3) * _cell_size)
	var vp_top   := float(min_row * _cell_size - _cell_size * 2)
	var vp_bot   := float((max_row + 3) * _cell_size)

	# Find core position for leg-to-core connections
	var core_pos := _boss.boss_center_pos
	for seg in _boss.boss_segments:
		if seg.is_core:
			core_pos = seg.pos
			break

	for seg in _boss.boss_segments:
		var sp: Vector2 = seg.pos
		if sp.x < vp_left or sp.x > vp_right or sp.y < vp_top or sp.y > vp_bot:
			continue

		var hp_ratio := float(seg.hp) / float(seg.max_hp)
		var damage_tint := 1.0 - hp_ratio

		if seg.is_core:
			var ctr := sp
			var r_out := 26.0 + pulse * 5.0
			var r_in  := 14.0
			var pts_out := PackedVector2Array()
			var pts_in  := PackedVector2Array()
			for i in 16:
				var a := float(i) / 16.0 * TAU + t * 0.4
				pts_out.append(ctr + Vector2(cos(a) * r_out, sin(a) * r_out * 0.75))
				pts_in.append(ctr + Vector2(cos(a) * r_in, sin(a) * r_in * 0.75))
			var cf := Color(core_fill.r + damage_tint * 0.3, core_fill.g, core_fill.b, core_fill.a)
			canvas.draw_polygon(pts_out, PackedColorArray([cf]))
			canvas.draw_polyline(pts_out + PackedVector2Array([pts_out[0]]), core_border, 2.5)
			canvas.draw_polygon(pts_in, PackedColorArray([Color(core_border, 0.35 + pulse * 0.30)]))
			# Fangs — oriented toward facing direction
			var fa := _boss._spider_facing_angle
			var fang_dir := Vector2(cos(fa), sin(fa))
			var fang_perp := Vector2(-fang_dir.y, fang_dir.x)
			var fang_base := ctr + fang_dir * 16.0
			var fc := Color(core_border.r * 1.2, core_border.g * 0.5, core_border.b * 0.5, 0.90)
			canvas.draw_polygon(PackedVector2Array([
				fang_base + fang_perp * 8.0,
				fang_base + fang_dir * 14.0 + fang_perp * 4.0,
				fang_base - fang_perp * 2.0,
			]), PackedColorArray([fc]))
			canvas.draw_polygon(PackedVector2Array([
				fang_base - fang_perp * 8.0,
				fang_base + fang_dir * 14.0 - fang_perp * 4.0,
				fang_base + fang_perp * 2.0,
			]), PackedColorArray([fc]))
		else:
			# Leg — tapered quadrilateral from core to leg tip
			var wave := sin(t * 4.5 + seg.angle * 3.0) * 8.0
			var leg_tip := sp + Vector2(0, wave)
			var leg_color := Color(seg_border.r + damage_tint * 0.3,
				seg_border.g * (1.0 - damage_tint * 0.2),
				seg_border.b, 0.75 + pulse * 0.20)

			var dir := (leg_tip - core_pos)
			if dir.length() > 1.0:
				dir = dir.normalized()
				var perp := Vector2(-dir.y, dir.x)
				var base := core_pos + dir * 14.0
				var pts := PackedVector2Array([
					base + perp * 8.0, leg_tip + perp * 3.0,
					leg_tip - perp * 3.0, base - perp * 8.0,
				])
				var sf := Color(seg_fill.r + damage_tint * 0.3, seg_fill.g, seg_fill.b, seg_fill.a)
				canvas.draw_polygon(pts, PackedColorArray([sf]))
				canvas.draw_polyline(pts + PackedVector2Array([pts[0]]), leg_color, 1.5)
			canvas.draw_circle(leg_tip, 5.0, Color(seg_border.r, seg_border.g, seg_border.b, 0.80))

# ---------------------------------------------------------------------------
# Blind Mole
# ---------------------------------------------------------------------------

func _draw_mole(canvas: Node2D, min_col: int, max_col: int, min_row: int, max_row: int,
		t: float, pulse: float,
		core_fill: Color, core_border: Color, seg_fill: Color, seg_border: Color) -> void:
	# Segments invisible while the mole is underground
	if _boss.mole_burrowed:
		return

	var vp_left  := float(min_col * _cell_size - _cell_size * 2)
	var vp_right := float((max_col + 3) * _cell_size)
	var vp_top   := float(min_row * _cell_size - _cell_size * 2)
	var vp_bot   := float((max_row + 3) * _cell_size)

	for seg in _boss.boss_segments:
		var sp: Vector2 = seg.pos
		if sp.x < vp_left or sp.x > vp_right or sp.y < vp_top or sp.y > vp_bot:
			continue

		var hp_ratio := float(seg.hp) / float(seg.max_hp)
		var damage_tint := 1.0 - hp_ratio
		var ctr := sp

		if seg.is_core:
			var hw := 24.0 + pulse * 4.0
			var hh := 20.0
			var fpts := PackedVector2Array()
			for i in 12:
				var a := float(i) / 12.0 * TAU
				fpts.append(ctr + Vector2(cos(a) * hw, sin(a) * hh))
			var cf := Color(core_fill.r + damage_tint * 0.2, core_fill.g, core_fill.b, core_fill.a)
			canvas.draw_polygon(fpts, PackedColorArray([cf]))
			canvas.draw_polyline(fpts + PackedVector2Array([fpts[0]]), core_border, 2.5)
			# Snout
			var sc2 := Color(core_fill.r + 0.12, core_fill.g + 0.08, core_fill.b, core_fill.a)
			canvas.draw_circle(ctr + Vector2(0, 8), 10.0, sc2)
			canvas.draw_circle(ctr + Vector2(0, 8), 10.0, Color(core_border, 0.5), false, 1.5)
			# Eyes (small — mole is blind)
			canvas.draw_circle(ctr + Vector2(-10, -5), 4.0, Color(0.05, 0.05, 0.05, 0.90))
			canvas.draw_circle(ctr + Vector2(10, -5), 4.0, Color(0.05, 0.05, 0.05, 0.90))
			canvas.draw_circle(ctr + Vector2(-9, -6), 1.5, Color(1.0, 1.0, 1.0, 0.70))
			canvas.draw_circle(ctr + Vector2(11, -6), 1.5, Color(1.0, 1.0, 1.0, 0.70))
			# Digging claws extending from body
			var cc := Color(0.30, 0.20, 0.05, 0.85)
			for side in [-1.0, 1.0]:
				canvas.draw_polygon(PackedVector2Array([
					ctr + Vector2(side * 18, 14),
					ctr + Vector2(side * 28, 28 + pulse * 5.0),
					ctr + Vector2(side * 34, 22),
					ctr + Vector2(side * 24, 10),
				]), PackedColorArray([cc]))
		elif seg.get("is_claw", false):
			# Claw segment — larger, more angular
			var cw := 22.0 + sin(t * 2.5 + seg.angle) * 4.0
			var ch := 18.0 + pulse * 3.0
			var cpts := PackedVector2Array()
			for i in 6:
				var a := float(i) / 6.0 * TAU + seg.angle * 0.5
				cpts.append(ctr + Vector2(cos(a) * cw, sin(a) * ch))
			var sf := Color(seg_fill.r + damage_tint * 0.3, seg_fill.g * (1.0 - damage_tint * 0.2), seg_fill.b, seg_fill.a)
			canvas.draw_polygon(cpts, PackedColorArray([sf]))
			canvas.draw_polyline(cpts + PackedVector2Array([cpts[0]]), seg_border, 2.0)
			# Claw tip
			var clc := Color(seg_border.r * 0.6, seg_border.g * 0.5, 0.02, 0.75)
			var tip_dir := (ctr - _boss.boss_center_pos).normalized()
			canvas.draw_polygon(PackedVector2Array([
				ctr + tip_dir * 12.0 + Vector2(-4, 0),
				ctr + tip_dir * (22.0 + pulse * 5.0),
				ctr + tip_dir * 12.0 + Vector2(4, 0),
			]), PackedColorArray([clc]))
		else:
			# Body segment — rounded bumps
			var bw := 18.0 + sin(t * 2.1 + seg.angle * 2.0) * 4.0
			var bh := 16.0 + sin(t * 1.7 + seg.angle) * 3.0
			var bpts := PackedVector2Array()
			for i in 8:
				var a := float(i) / 8.0 * TAU
				bpts.append(ctr + Vector2(cos(a) * bw, sin(a) * bh))
			var sf := Color(seg_fill.r + damage_tint * 0.3, seg_fill.g * (1.0 - damage_tint * 0.2), seg_fill.b, seg_fill.a)
			canvas.draw_polygon(bpts, PackedColorArray([sf]))
			canvas.draw_polyline(bpts + PackedVector2Array([bpts[0]]), seg_border, 1.5)

# ---------------------------------------------------------------------------
# Stone Golem
# ---------------------------------------------------------------------------

func _draw_golem(canvas: Node2D, min_col: int, max_col: int, min_row: int, max_row: int,
		t: float, pulse: float,
		core_fill: Color, core_border: Color, seg_fill: Color, seg_border: Color) -> void:
	var spin := t * 0.8
	var vp_left  := float(min_col * _cell_size - _cell_size * 2)
	var vp_right := float((max_col + 3) * _cell_size)
	var vp_top   := float(min_row * _cell_size - _cell_size * 2)
	var vp_bot   := float((max_row + 3) * _cell_size)

	# Per-armor-phase colors for segment visual differentiation
	var golem_colors: Array = [
		[Color(0.80, 0.50, 0.20), Color(0.95, 0.70, 0.40)],  # copper
		[Color(0.55, 0.55, 0.65), Color(0.75, 0.75, 0.90)],  # iron
		[Color(1.00, 0.85, 0.10), Color(1.00, 1.00, 0.50)],  # gold
	]

	for seg in _boss.boss_segments:
		var sp: Vector2 = seg.pos
		if sp.x < vp_left or sp.x > vp_right or sp.y < vp_top or sp.y > vp_bot:
			continue

		var hp_ratio := float(seg.hp) / float(seg.max_hp)
		var damage_tint := 1.0 - hp_ratio
		var ctr := sp

		if seg.is_core:
			var num_pts := 8
			var r_outer := 22.0 + pulse * 6.0
			var r_inner := 11.0
			var star_pts := PackedVector2Array()
			for i in num_pts * 2:
				var a := spin + float(i) / float(num_pts * 2) * TAU
				var r := r_outer if i % 2 == 0 else r_inner
				star_pts.append(ctr + Vector2(cos(a) * r, sin(a) * r))
			var cf := Color(core_fill.r + damage_tint * 0.2, core_fill.g, core_fill.b, core_fill.a)
			canvas.draw_polygon(star_pts, PackedColorArray([cf]))
			canvas.draw_polyline(star_pts + PackedVector2Array([star_pts[0]]), core_border, 2.5)
			canvas.draw_circle(ctr, 8.0 + pulse * 4.0, Color(core_border.r, core_border.g, core_border.b, 0.60 + pulse * 0.30))
		else:
			# Color segments by their armor phase
			var armor_p: int = seg.get("armor_phase", 0)
			var gci := clampi(armor_p, 0, golem_colors.size() - 1)
			var s_fill: Color = golem_colors[gci][0]
			var s_border: Color = golem_colors[gci][1]

			# Dim segments not in the current phase
			var is_active_phase := armor_p == _boss.golem_phase
			var alpha_mult := 1.0 if is_active_phase else 0.4
			s_fill = Color(s_fill.r, s_fill.g, s_fill.b, (0.18 + pulse * 0.18) * alpha_mult)
			s_border = Color(s_border.r, s_border.g, s_border.b, (0.40 + pulse * 0.25) * alpha_mult)

			var rotate_offset := sin(t * 1.2 + seg.angle * 7.0) * 0.3
			var hw := 20.0 + pulse * 3.0
			var hpts := PackedVector2Array()
			for i in 6:
				var a := rotate_offset + float(i) / 6.0 * TAU
				hpts.append(ctr + Vector2(cos(a) * hw, sin(a) * hw * 0.75))
			var sf := Color(s_fill.r + damage_tint * 0.3, s_fill.g * (1.0 - damage_tint * 0.2), s_fill.b, s_fill.a)
			canvas.draw_polygon(hpts, PackedColorArray([sf]))
			canvas.draw_polyline(hpts + PackedVector2Array([hpts[0]]), s_border, 2.0)
			# Crack lines
			if is_active_phase:
				var lc := Color(s_border.r, s_border.g, s_border.b, 0.35)
				canvas.draw_line(ctr + Vector2(-14, 0), ctr + Vector2(14, 0), lc, 1.0)
				canvas.draw_line(ctr + Vector2(0, -14), ctr + Vector2(0, 14), lc, 1.0)

# ---------------------------------------------------------------------------
# Ancient Star Beast
# ---------------------------------------------------------------------------

func _draw_ancient(canvas: Node2D, min_col: int, max_col: int, min_row: int, max_row: int,
		t: float, pulse: float,
		core_fill: Color, core_border: Color, seg_fill: Color, seg_border: Color) -> void:
	var spin_a := t * 1.1
	var spin_b := t * -0.7
	var vp_left  := float(min_col * _cell_size - _cell_size * 3)
	var vp_right := float((max_col + 4) * _cell_size)
	var vp_top   := float(min_row * _cell_size - _cell_size * 3)
	var vp_bot   := float((max_row + 4) * _cell_size)

	for seg in _boss.boss_segments:
		var sp: Vector2 = seg.pos
		if sp.x < vp_left or sp.x > vp_right or sp.y < vp_top or sp.y > vp_bot:
			continue

		var hp_ratio := float(seg.hp) / float(seg.max_hp)
		var damage_tint := 1.0 - hp_ratio
		var ctr := sp

		if seg.is_core:
			for ring in 2:
				var spin_r := spin_a if ring == 0 else spin_b
				var r_out := (28.0 if ring == 0 else 16.0) + pulse * 5.0
				var r_in  := r_out * 0.45
				var num   := 6 if ring == 0 else 4
				var spts := PackedVector2Array()
				for i in num * 2:
					var a := spin_r + float(i) / float(num * 2) * TAU
					var rv := r_out if i % 2 == 0 else r_in
					spts.append(ctr + Vector2(cos(a) * rv, sin(a) * rv))
				var fc := core_fill if ring == 0 else Color(core_border, core_border.a * 0.65)
				var cf := Color(fc.r + damage_tint * 0.2, fc.g, fc.b, fc.a)
				canvas.draw_polygon(spts, PackedColorArray([cf]))
				canvas.draw_polyline(spts + PackedVector2Array([spts[0]]), core_border, 2.0 - float(ring) * 0.5)
			canvas.draw_circle(ctr, 8.0 + pulse * 3.0, Color(0.0, 0.0, 0.0, 0.85))
			canvas.draw_circle(ctr, 5.0, Color(core_border.r, core_border.g, core_border.b, 0.65 + pulse * 0.30))
		else:
			# Dim segments not in the current active ring
			var seg_ring: int = seg.get("ring", 0)
			var is_active_ring := seg_ring == _boss.ancient_phase
			var alpha_mult := 1.0 if is_active_ring else 0.4

			var shard_len := 22.0 + pulse * 6.0
			var shard_w   := 9.0
			var oscillate := sin(t * 3.0 + seg.angle * 3.0) * 5.0
			var pts := PackedVector2Array([
				ctr + Vector2(0, -shard_len - oscillate),
				ctr + Vector2(shard_w, 0),
				ctr + Vector2(0, shard_len * 0.35),
				ctr + Vector2(-shard_w, 0),
			])
			var sf := Color(seg_fill.r + damage_tint * 0.3, seg_fill.g, seg_fill.b, seg_fill.a * alpha_mult)
			var sb := Color(seg_border.r, seg_border.g, seg_border.b, seg_border.a * alpha_mult)
			canvas.draw_polygon(pts, PackedColorArray([sf]))
			canvas.draw_polyline(pts + PackedVector2Array([pts[0]]), sb, 1.5)
			if is_active_ring:
				canvas.draw_line(ctr + Vector2(0, -shard_len * 0.7 - oscillate),
					ctr + Vector2(0, shard_len * 0.25),
					Color(1.0, 1.0, 1.0, (0.20 + pulse * 0.20) * alpha_mult), 2.0)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _tile_center(col: int, row: int) -> Vector2:
	return Vector2(col * _cell_size + _cell_size * 0.5, row * _cell_size + _cell_size * 0.5)

func _is_valid(bp: Vector2i) -> bool:
	return bp.x >= 0 and bp.x < _grid.size() \
		and bp.y >= 0 and bp.y < _grid[bp.x].size()

func _in_viewport(bp: Vector2i, min_col: int, max_col: int, min_row: int, max_row: int) -> bool:
	return bp.x >= min_col and bp.x <= max_col and bp.y >= min_row and bp.y <= max_row

func _find_core_label_px(offset: Vector2) -> Vector2:
	# Use free-floating segment positions
	for seg in _boss.boss_segments:
		if seg.is_core:
			return Vector2(seg.pos.x + offset.x, seg.pos.y + offset.y)
	return Vector2(-9999.0, -9999.0)

func _draw_edge_vignette(
		canvas: Node2D,
		min_col: int, max_col: int, min_row: int, max_row: int,
		ratio: float, max_alpha: float,
		base_color: Color,
		thickness: int) -> void:
	var a := ratio * max_alpha
	var c := Color(base_color.r, base_color.g, base_color.b, a)
	var cs := _cell_size
	canvas.draw_rect(Rect2(min_col * cs, min_row * cs, (max_col - min_col + 1) * cs, thickness), c)
	canvas.draw_rect(Rect2(min_col * cs, max_row * cs, (max_col - min_col + 1) * cs, thickness), c)
	canvas.draw_rect(Rect2(min_col * cs, min_row * cs, thickness, (max_row - min_row + 1) * cs), c)
	canvas.draw_rect(Rect2(max_col * cs, min_row * cs, thickness, (max_row - min_row + 1) * cs), c)
