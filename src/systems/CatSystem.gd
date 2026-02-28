class_name CatSystem
extends Node2D

## CatSystem — manages all hired Mining Cats and Collecting Cats.
##
## Mining Cats (orange tint): autonomously patrol near their hire point, find
## ore tiles in the grid, and mine them — dropping ore chunks for collecting cats.
## Collecting Cats (cyan-green tint): sweep ore chunks from the ground, carry
## them to the surface deposit, bank minerals, then return underground.
##
## Both cat types use the player sprite sheet (res://assets/player_cat_spritesheet.png)
## tinted by role. CatSystem is added as a Node2D child of MiningLevel so each
## HiredCat can have an AnimatedSprite2D child with proper frame animation.

const CAT_SPRITE_PATH := "res://assets/player_cat_spritesheet.png"

const MINING_CAT_TINT    := Color(1.00, 0.50, 0.12)   # orange — mining cats
const COLLECTING_CAT_TINT := Color(0.25, 0.95, 0.60)  # cyan-green — collecting cats

const CAT_MOVE_SPEED     := 110.0   # px/s
const CAT_MINE_INTERVAL  := 0.35    # seconds between mining hits
const CAT_COLLECT_RADIUS := 100.0   # px — collecting cat sweep radius
const CAT_COLLECT_INTERVAL := 0.40  # seconds between sweep passes
const CAT_CARRY_CAPACITY := 20      # ore value units before heading to surface
const CAT_PATROL_RADIUS  := 8       # tiles from anchor that mining cat will search
const CAT_DEPOSIT_DELAY  := 1.6     # seconds spent at surface before returning
const CAT_SPRITE_SCALE   := Vector2(2.5, 2.5)
const CELL_SIZE          := 64

enum CatRole { MINING, COLLECTING }

class HiredCat:
	var role: CatRole
	var sprite: AnimatedSprite2D
	var node: Node2D             # parent node added to CatSystem
	var world_pos: Vector2
	var anchor_pos: Vector2      # where it was hired (mining patrol centre)
	var state: String = "idle"   # "idle"|"moving"|"mining"|"collecting"|"returning"|"depositing"
	var target_tile: Vector2i = Vector2i(-1, -1)
	var carry: int = 0
	var mine_timer: float = 0.0
	var collect_timer: float = 0.0
	var deposit_timer: float = 0.0
	var facing_left: bool = true
	var surface_return_pos: Vector2 = Vector2.ZERO

var _cats: Array = []        # Array[HiredCat]
var _grid: Array = []
var _grid_cols: int = 96
var _grid_rows: int = 128
var _surface_rows: int = 3
var _player_pos: Vector2 = Vector2.ZERO
var _mining_level: Node = null   # set by MiningLevel for grid access

var _cat_sprite_frames: SpriteFrames = null


func setup(mining_level: Node, grid: Array, grid_cols: int, grid_rows: int, surface_rows: int) -> void:
	_mining_level = mining_level
	_grid = grid
	_grid_cols = grid_cols
	_grid_rows = grid_rows
	_surface_rows = surface_rows
	_cat_sprite_frames = _build_sprite_frames()


## Hire a new cat of the given role at world_pos.
func hire(role: CatRole, world_pos: Vector2) -> void:
	var cat := HiredCat.new()
	cat.role = role
	cat.world_pos = world_pos
	cat.anchor_pos = world_pos
	cat.surface_return_pos = Vector2(
		46.0 * CELL_SIZE,
		(_surface_rows - 1) * CELL_SIZE + CELL_SIZE * 0.5
	)

	# Build the cat node with AnimatedSprite2D
	var n := Node2D.new()
	n.position = world_pos
	add_child(n)

	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = _cat_sprite_frames
	spr.scale = CAT_SPRITE_SCALE
	spr.offset = Vector2(0, -8)
	spr.texture_filter = TEXTURE_FILTER_NEAREST
	spr.modulate = MINING_CAT_TINT if role == CatRole.MINING else COLLECTING_CAT_TINT
	spr.play(&"idle")
	n.add_child(spr)

	cat.node = n
	cat.sprite = spr
	cat.state = "idle"
	_cats.append(cat)
	EventBus.ore_mined_popup.emit(
		0,
		"Mining Cat hired!" if role == CatRole.MINING else "Collecting Cat hired!"
	)


func get_cat_count() -> int:
	return _cats.size()


func get_mining_cat_count() -> int:
	var n := 0
	for c in _cats:
		if c.role == CatRole.MINING:
			n += 1
	return n


func get_collecting_cat_count() -> int:
	var n := 0
	for c in _cats:
		if c.role == CatRole.COLLECTING:
			n += 1
	return n


func _process(delta: float) -> void:
	for cat in _cats:
		_update_cat(cat, delta)
		# Sync node position and sprite flip
		if is_instance_valid(cat.node):
			cat.node.position = cat.world_pos
		if is_instance_valid(cat.sprite):
			cat.sprite.flip_h = not cat.facing_left


## _draw() draws carry-bar indicators above each cat.
func _draw() -> void:
	for cat in _cats:
		if cat.role == CatRole.COLLECTING and cat.carry > 0:
			var pos: Vector2 = cat.world_pos
			var ratio := float(cat.carry) / float(CAT_CARRY_CAPACITY)
			var bar_w := 24.0
			var bar_h := 4.0
			draw_rect(Rect2(pos.x - bar_w * 0.5, pos.y - 28.0, bar_w, bar_h),
				Color(0.15, 0.15, 0.15, 0.80))
			draw_rect(Rect2(pos.x - bar_w * 0.5, pos.y - 28.0, bar_w * ratio, bar_h),
				COLLECTING_CAT_TINT.darkened(0.1))


# ---------------------------------------------------------------------------
# Cat AI update
# ---------------------------------------------------------------------------

func _update_cat(cat: HiredCat, delta: float) -> void:
	match cat.role:
		CatRole.MINING:
			_update_mining_cat(cat, delta)
		CatRole.COLLECTING:
			_update_collecting_cat(cat, delta)


func _update_mining_cat(cat: HiredCat, delta: float) -> void:
	match cat.state:
		"idle":
			_play_anim(cat, &"idle")
			# Find the nearest ore tile within patrol radius
			var ore_tile := _find_nearest_ore(cat.anchor_pos, CAT_PATROL_RADIUS)
			if ore_tile.x >= 0:
				cat.target_tile = ore_tile
				cat.state = "moving"
			else:
				# No ore nearby — wait
				cat.mine_timer += delta
				if cat.mine_timer >= 2.5:
					cat.mine_timer = 0.0
					cat.target_tile = Vector2i(-1, -1)

		"moving":
			var target_world := Vector2(
				cat.target_tile.x * CELL_SIZE + CELL_SIZE * 0.5,
				cat.target_tile.y * CELL_SIZE + CELL_SIZE * 0.5
			)
			var dir := (target_world - cat.world_pos)
			var dist := dir.length()
			if dist < 8.0:
				cat.state = "mining"
				cat.mine_timer = 0.0
			else:
				_play_anim(cat, &"movement")
				cat.facing_left = dir.x > 0
				cat.world_pos += dir.normalized() * CAT_MOVE_SPEED * delta

		"mining":
			_play_anim(cat, &"paw")
			cat.mine_timer += delta
			if cat.mine_timer >= CAT_MINE_INTERVAL:
				cat.mine_timer = 0.0
				# Mine the target tile through MiningLevel's API
				if _is_valid_ore(cat.target_tile):
					if _mining_level and _mining_level.has_method("cat_mine_at"):
						_mining_level.cat_mine_at(cat.target_tile)
				else:
					# Tile is gone — pick a new one
					cat.target_tile = Vector2i(-1, -1)
					cat.state = "idle"

		_:
			cat.state = "idle"


func _update_collecting_cat(cat: HiredCat, delta: float) -> void:
	match cat.state:
		"idle", "collecting":
			_play_anim(cat, &"idle")
			cat.collect_timer += delta
			if cat.collect_timer >= CAT_COLLECT_INTERVAL:
				cat.collect_timer = 0.0
				_sweep_chunks(cat)
				if cat.carry >= CAT_CARRY_CAPACITY:
					cat.state = "returning"

		"returning":
			_play_anim(cat, &"movement")
			var dir := (cat.surface_return_pos - cat.world_pos)
			var dist := dir.length()
			if dist < 12.0:
				cat.state = "depositing"
				cat.deposit_timer = CAT_DEPOSIT_DELAY
			else:
				cat.facing_left = dir.x > 0
				cat.world_pos += dir.normalized() * CAT_MOVE_SPEED * 1.6 * delta

		"depositing":
			_play_anim(cat, &"idle")
			cat.deposit_timer -= delta
			if cat.deposit_timer <= 0.0:
				if cat.carry > 0:
					GameManager.mineral_currency += cat.carry
					EventBus.ore_mined_popup.emit(cat.carry, "Collecting Cat banked!")
					cat.carry = 0
				cat.state = "collecting"

		_:
			cat.state = "collecting"


func _sweep_chunks(cat: HiredCat) -> void:
	if not _mining_level:
		return
	var chunks := _mining_level.get_tree().get_nodes_in_group("ore_chunk")
	for chunk in chunks:
		if not is_instance_valid(chunk):
			continue
		if cat.world_pos.distance_to(chunk.global_position) > CAT_COLLECT_RADIUS:
			continue
		cat.carry = mini(cat.carry + chunk.value, CAT_CARRY_CAPACITY)
		chunk.collect_silent()
		if cat.carry >= CAT_CARRY_CAPACITY:
			cat.state = "returning"
			return


func _play_anim(cat: HiredCat, anim: StringName) -> void:
	if is_instance_valid(cat.sprite) and cat.sprite.animation != anim:
		cat.sprite.play(anim)


func _find_nearest_ore(anchor: Vector2, radius_tiles: int) -> Vector2i:
	var anchor_col := int(anchor.x / CELL_SIZE)
	var anchor_row := int(anchor.y / CELL_SIZE)
	var best := Vector2i(-1, -1)
	var best_dist := INF
	for dc in range(-radius_tiles, radius_tiles + 1):
		for dr in range(-radius_tiles, radius_tiles + 1):
			var col := anchor_col + dc
			var row := anchor_row + dr
			if col < 0 or col >= _grid_cols or row < _surface_rows or row >= _grid_rows:
				continue
			if _is_ore_tile(_grid[col][row]):
				var dist := float(dc * dc + dr * dr)
				if dist < best_dist:
					best_dist = dist
					best = Vector2i(col, row)
	return best


func _is_ore_tile(tile: int) -> bool:
	# matches ORE_TILES in MiningLevel
	return tile in [3, 4, 5, 6, 7, 8, 9, 10]  # ORE_COPPER..ORE_GEM_DEEP


func _is_valid_ore(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= _grid_cols or pos.y < 0 or pos.y >= _grid_rows:
		return false
	if _grid.is_empty():
		return false
	return _is_ore_tile(_grid[pos.x][pos.y])


# ---------------------------------------------------------------------------
# Sprite frames builder — programmatically replicates PlayerProbe.tscn frames
# using the same atlas texture so both cats and player share the same artwork.
# ---------------------------------------------------------------------------

func _build_sprite_frames() -> SpriteFrames:
	var tex := load(CAT_SPRITE_PATH) as Texture2D
	if not tex:
		return SpriteFrames.new()

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	# Helper to make one atlas slice
	var _make := func(x: int, y: int) -> AtlasTexture:
		var a := AtlasTexture.new()
		a.atlas = tex
		a.region = Rect2(x, y, 32, 32)
		return a

	# idle — row y=0, 8 frames across
	var idle_frames: Array[Texture2D] = []
	for i in 4:
		idle_frames.append(_make.call(i * 32, 0))
	for i in 4:
		idle_frames.append(_make.call(i * 32, 32))
	_add_anim(frames, &"idle", idle_frames, 5.0)

	# movement — row y=128 & 160, 8+8 frames
	var move_frames: Array[Texture2D] = []
	for i in 8:
		move_frames.append(_make.call(i * 32, 128))
	for i in 8:
		move_frames.append(_make.call(i * 32, 160))
	_add_anim(frames, &"movement", move_frames, 5.0)

	# jump — row y=256, 7 frames
	var jump_frames: Array[Texture2D] = []
	for i in 7:
		jump_frames.append(_make.call(i * 32, 256))
	_add_anim(frames, &"jump", jump_frames, 8.0)

	# paw — row y=224, 6 frames
	var paw_frames: Array[Texture2D] = []
	for i in 6:
		paw_frames.append(_make.call(i * 32, 224))
	_add_anim(frames, &"paw", paw_frames, 5.0)

	return frames


func _add_anim(frames: SpriteFrames, name: StringName, textures: Array[Texture2D], speed: float) -> void:
	frames.add_animation(name)
	frames.set_animation_loop(name, true)
	frames.set_animation_speed(name, speed)
	for tex in textures:
		frames.add_frame(name, tex)
