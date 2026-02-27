class_name HUD
extends CanvasLayer

# HUD — displays Minerals total (upper-left), health squares and fuel gauge (upper-right).

@onready var scrap_label: Label = $Control/ScrapLabel
@onready var health_container: HBoxContainer = $Control/HealthContainer
@onready var fuel_label: Label = $Control/FuelLabel
@onready var fuel_bar_container: HBoxContainer = $Control/FuelBarContainer

var fuel_segments: Array[ColorRect] = []

# Vertical health bars
const HEALTH_BAR_W: int = 18
const HEALTH_BAR_H: int = 60
var health_bars: Array[Control] = []
var health_bar_fills: Array[ColorRect] = []
var health_bar_highlights: Array[ColorRect] = []
var _displayed_health: float = 10.0
var _health_drain_tween: Tween

var scrap_panel: ColorRect
var earnings_label: Label
var _pickup_panel: ColorRect
var depth_label: Label
var depth_panel: ColorRect
var _earnings_tween: Tween

# Low fuel warning
var _low_fuel_warning: Label
var _low_fuel_tween: Tween

# Depth milestone banner
var _milestone_label: Label
var _milestone_tween: Tween
var _next_milestone: int = 20

# Surface exit hint — bottom-right, pulses when player is on surface
var _exit_hint_label: Label
var _exit_hint_panel: ColorRect
var _exit_hint_tween: Tween

# Low HP danger warning — bottom-centre, pulses red when HP == 1
var _low_hp_warning: Label
var _low_hp_tween: Tween

# Ore colour mapping for the earnings popup
const ORE_COLORS: Dictionary = {
	"Copper":      Color(0.80, 0.50, 0.20),
	"Deep Copper": Color(0.70, 0.40, 0.10),
	"Iron":        Color(0.65, 0.65, 0.72),
	"Deep Iron":   Color(0.55, 0.55, 0.65),
	"Gold":        Color(1.00, 0.85, 0.10),
	"Deep Gold":   Color(0.90, 0.75, 0.05),
	"Gem":         Color(0.15, 0.85, 0.75),
	"Deep Gem":    Color(0.10, 0.75, 0.65),
	"Fuel":        Color(0.20, 0.90, 0.20),
	"LUCKY!":          Color(1.0,  1.0,  0.30),   # Bright yellow for lucky double-strikes
	"Discovery!":      Color(0.20, 0.90, 0.90),   # Teal for first zone visit
	"Streak!":         Color(1.0,  0.60, 0.10),   # Orange for consecutive dig milestones
	# Smelting chain / combo events (name + "!" suffix)
	"Bronze Ingot!":    Color(0.80, 0.55, 0.20),
	"Steel Ingot!":     Color(0.70, 0.70, 0.80),
	"Pure Gold!":       Color(1.00, 0.90, 0.10),
	"Faceted Gem!":     Color(0.10, 0.95, 0.85),
	"Alloy Ore!":       Color(0.85, 0.60, 0.35),
	"Gilded Steel!":    Color(1.00, 0.80, 0.30),
	"Fool's Gold!":     Color(0.90, 0.75, 0.20),
	# Sonar ping / system notifications
	"No fuel for ping":     Color(0.80, 0.20, 0.10),
	# Wandering Trader events
	"Wandering Trader!":    Color(1.00, 0.75, 0.10),
	"Fuel Pack!":           Color(0.20, 0.90, 0.20),
	"Carapace Patched!":    Color(0.85, 0.08, 0.08),
	"Mining Shroom!":       Color(0.50, 0.90, 0.20),
	"Lucky Compass!":       Color(1.00, 0.90, 0.10),
	"Ancient Map!":         Color(0.20, 0.90, 1.00),
	"Not enough minerals":  Color(0.80, 0.20, 0.10),
	"Already at full HP":   Color(0.60, 0.60, 0.60),
	# Fossil finds — name + " Fossil!" suffix, warm amber/teal tones
	"Ancient Root Fossil!":    Color(0.85, 0.65, 0.30),
	"Root Fossil Fossil!":     Color(0.85, 0.65, 0.30),
	"Trilobite Fossil!":       Color(0.90, 0.75, 0.40),
	"Ammonite Fossil!":        Color(0.90, 0.75, 0.40),
	"Mineralite Fossil!":      Color(0.80, 0.60, 0.90),
	"Deep Mineralite Fossil!": Color(0.80, 0.60, 0.90),
	"Iron Fossil Fossil!":     Color(0.65, 0.65, 0.90),
	"Gilded Fossil Fossil!":   Color(1.00, 0.85, 0.20),
	"Crystal Fossil Fossil!":  Color(0.20, 0.95, 1.00),
}

func _ready() -> void:
	EventBus.minerals_changed.connect(_on_minerals_changed)
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.fuel_changed.connect(_on_fuel_changed)
	EventBus.ore_mined_popup.connect(_on_ore_mined_popup)
	EventBus.depth_changed.connect(_on_depth_changed)

	# Semi-transparent black background panel behind the minerals label
	scrap_panel = ColorRect.new()
	scrap_panel.color = Color(0.0, 0.0, 0.0, 0.55)
	scrap_panel.position = Vector2(8, 8)
	scrap_panel.size = Vector2(148, 34)
	scrap_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Control.add_child(scrap_panel)
	$Control.move_child(scrap_panel, 0)  # Draw behind everything else

	# Background panel behind the item pickup popup
	_pickup_panel = ColorRect.new()
	_pickup_panel.color = Color(0.0, 0.0, 0.0, 0.55)
	_pickup_panel.position = Vector2(8, 42)
	_pickup_panel.size = Vector2(200, 30)
	_pickup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pickup_panel.modulate.a = 0.0  # Starts invisible, fades in with earnings label
	$Control.add_child(_pickup_panel)

	# Earnings popup label — appears below the minerals panel when a tile is mined
	earnings_label = Label.new()
	earnings_label.position = Vector2(16, 46)
	earnings_label.custom_minimum_size = Vector2(220, 22)
	earnings_label.modulate = Color(1.0, 0.88, 0.2, 0.0)  # Gold, starts invisible
	$Control.add_child(earnings_label)

	# Background panel behind the depth meter label
	depth_panel = ColorRect.new()
	depth_panel.color = Color(0.0, 0.0, 0.0, 0.55)
	depth_panel.position = Vector2(4, 68)
	depth_panel.size = Vector2(164, 30)
	depth_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Control.add_child(depth_panel)

	# Depth indicator — shows how far underground the ant is
	depth_label = Label.new()
	depth_label.position = Vector2(8, 72)
	depth_label.custom_minimum_size = Vector2(148, 22)
	depth_label.text = "Surface"
	depth_label.modulate = Color(0.6, 0.85, 1.0, 1.0)  # Light blue tint
	$Control.add_child(depth_label)

	# Low fuel warning — bottom-centre, pulses red when fuel <= 20 %
	_low_fuel_warning = Label.new()
	_low_fuel_warning.position = Vector2(540, 656)
	_low_fuel_warning.custom_minimum_size = Vector2(200, 28)
	_low_fuel_warning.text = "! LOW FUEL !"
	_low_fuel_warning.modulate = Color(1.0, 0.2, 0.1, 0.0)  # Red, starts invisible
	_low_fuel_warning.add_theme_font_size_override("font_size", 18)
	$Control.add_child(_low_fuel_warning)

	# Depth milestone banner — top-centre, fades in/out on each 20 m milestone
	_milestone_label = Label.new()
	_milestone_label.position = Vector2(440, 10)
	_milestone_label.custom_minimum_size = Vector2(400, 28)
	_milestone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_milestone_label.modulate = Color(1.0, 0.85, 0.2, 0.0)  # Gold, starts invisible
	_milestone_label.add_theme_font_size_override("font_size", 18)
	$Control.add_child(_milestone_label)

	# Surface exit hint — bottom-right corner, visible when on surface
	_exit_hint_panel = ColorRect.new()
	_exit_hint_panel.color = Color(0.0, 0.0, 0.0, 0.55)
	_exit_hint_panel.position = Vector2(1044, 650)
	_exit_hint_panel.size = Vector2(228, 32)
	_exit_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exit_hint_panel.modulate.a = 0.0
	$Control.add_child(_exit_hint_panel)

	_exit_hint_label = Label.new()
	_exit_hint_label.text = "Walk right to exit  ->"
	_exit_hint_label.position = Vector2(1048, 655)
	_exit_hint_label.custom_minimum_size = Vector2(218, 22)
	_exit_hint_label.modulate = Color(0.30, 1.0, 0.40, 0.0)  # Green, starts invisible
	_exit_hint_label.add_theme_font_size_override("font_size", 14)
	$Control.add_child(_exit_hint_label)

	# Low HP danger warning — bottom-centre above the fuel warning, pulses red at 1 HP
	_low_hp_warning = Label.new()
	_low_hp_warning.position = Vector2(490, 628)
	_low_hp_warning.custom_minimum_size = Vector2(300, 24)
	_low_hp_warning.text = "! CRITICAL DAMAGE — return to surface !"
	_low_hp_warning.modulate = Color(1.0, 0.10, 0.05, 0.0)  # Red, starts invisible
	_low_hp_warning.add_theme_font_size_override("font_size", 14)
	$Control.add_child(_low_hp_warning)

	# Initialize hearts immediately since PlayerProbe emits before HUD connects
	var max_hp := GameManager.get_max_health()
	_on_health_changed(max_hp, max_hp)
	# Initialize fuel display after all UI elements are created
	_on_fuel_changed(GameManager.current_fuel, GameManager.get_max_fuel())

func _on_minerals_changed(amount: int) -> void:
	scrap_label.text = "Minerals: %d" % amount

# Called when a tile is mined — shows a coloured "+X OreName" popup.
func _on_ore_mined_popup(amount: int, ore_name: String) -> void:
	var popup_color: Color = ORE_COLORS.get(ore_name, Color(1.0, 0.88, 0.2))
	# amount == 0 means a pure notification (no mineral award) — omit the "+" prefix
	earnings_label.text = "+%d %s" % [amount, ore_name] if amount > 0 else ore_name
	earnings_label.modulate = Color(popup_color.r, popup_color.g, popup_color.b, 1.0)
	_pickup_panel.modulate.a = 1.0  # Show panel immediately

	if _earnings_tween:
		_earnings_tween.kill()
	_earnings_tween = create_tween()
	_earnings_tween.tween_interval(0.8)
	_earnings_tween.tween_property(earnings_label, "modulate:a", 0.0, 0.45)
	_earnings_tween.parallel().tween_property(_pickup_panel, "modulate:a", 0.0, 0.45)

func _rebuild_health_bars(count: int) -> void:
	for bar in health_bars:
		bar.queue_free()
	health_bars.clear()
	health_bar_fills.clear()
	health_bar_highlights.clear()

	for i in range(count):
		var bar := Control.new()
		bar.custom_minimum_size = Vector2(HEALTH_BAR_W, HEALTH_BAR_H)
		bar.clip_contents = true
		bar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

		# Dark chamber background
		var bg := ColorRect.new()
		bg.color = Color(0.12, 0.12, 0.12, 0.88)
		bg.position = Vector2.ZERO
		bg.size = Vector2(HEALTH_BAR_W, HEALTH_BAR_H)
		bar.add_child(bg)

		# Red fill — anchored to bottom, drains from top
		var fill := ColorRect.new()
		fill.color = Color(0.85, 0.08, 0.08, 1.0)
		fill.position = Vector2.ZERO
		fill.size = Vector2(HEALTH_BAR_W, HEALTH_BAR_H)
		bar.add_child(fill)

		# Bright shine line at the top edge of the fill
		var shine := ColorRect.new()
		shine.color = Color(1.0, 0.55, 0.55, 0.75)
		shine.position = Vector2.ZERO
		shine.size = Vector2(HEALTH_BAR_W, 3)
		bar.add_child(shine)

		health_container.add_child(bar)
		health_bars.append(bar)
		health_bar_fills.append(fill)
		health_bar_highlights.append(shine)

	_update_health_bar_fills()

func _set_displayed_health(value: float) -> void:
	_displayed_health = value
	_update_health_bar_fills()

func _update_health_bar_fills() -> void:
	for i in range(health_bar_fills.size()):
		# Bar i (0-indexed) represents the health range (i, i+1)
		var fill_ratio: float
		if _displayed_health >= float(i + 1):
			fill_ratio = 1.0
		elif _displayed_health <= float(i):
			fill_ratio = 0.0
		else:
			fill_ratio = _displayed_health - float(i)

		var fill_h: float = fill_ratio * float(HEALTH_BAR_H)
		health_bar_fills[i].size.y = fill_h
		health_bar_fills[i].position.y = float(HEALTH_BAR_H) - fill_h

		# Shine tracks the top surface of the fill
		var shine: ColorRect = health_bar_highlights[i]
		shine.visible = fill_ratio > 0.02
		if shine.visible:
			shine.size.y = minf(3.0, fill_h)
			shine.position.y = float(HEALTH_BAR_H) - fill_h

func _on_health_changed(current: int, max_hp: int) -> void:
	# Rebuild bar nodes when count changes (first call or stat upgrade)
	if health_bar_fills.size() != max_hp:
		_displayed_health = float(current)
		_rebuild_health_bars(max_hp)
		# Fall through to update low-HP warning below

	else:
		# Animate drain (damage) or fill (healing)
		if _health_drain_tween:
			_health_drain_tween.kill()

		var is_healing := float(current) > _displayed_health
		var bars_changing := absf(float(current) - _displayed_health)
		var speed := 0.15 if is_healing else 0.40
		var duration := clampf(bars_changing * speed, 0.20, 1.0)

		_health_drain_tween = create_tween()
		_health_drain_tween.tween_method(_set_displayed_health, _displayed_health, float(current), duration)

	# Flash danger warning when critically low HP
	if current == 1:
		if not _low_hp_tween or not _low_hp_tween.is_running():
			_low_hp_tween = create_tween()
			_low_hp_tween.set_loops()
			_low_hp_tween.tween_property(_low_hp_warning, "modulate:a", 1.0, 0.25)
			_low_hp_tween.tween_interval(0.1)
			_low_hp_tween.tween_property(_low_hp_warning, "modulate:a", 0.1, 0.25)
			_low_hp_tween.tween_interval(0.1)
	else:
		if _low_hp_tween:
			_low_hp_tween.kill()
			_low_hp_tween = null
		_low_hp_warning.modulate.a = 0.0

func _on_depth_changed(depth_rows: int) -> void:
	if depth_rows <= 0:
		depth_label.text = "Surface"
		depth_label.modulate = Color(0.6, 0.85, 1.0, 1.0)
		_next_milestone = 20  # Reset milestone tracking each time player surfaces
		# Show pulsing exit hint to guide player toward the EXIT station
		if not _exit_hint_tween or not _exit_hint_tween.is_running():
			_exit_hint_tween = create_tween()
			_exit_hint_tween.set_loops()
			_exit_hint_tween.tween_property(_exit_hint_label, "modulate:a", 1.0, 0.5)
			_exit_hint_tween.parallel().tween_property(_exit_hint_panel, "modulate:a", 1.0, 0.5)
			_exit_hint_tween.tween_interval(1.2)
			_exit_hint_tween.tween_property(_exit_hint_label, "modulate:a", 0.30, 0.5)
			_exit_hint_tween.parallel().tween_property(_exit_hint_panel, "modulate:a", 0.30, 0.5)
			_exit_hint_tween.tween_interval(0.4)
	else:
		# Underground — hide exit hint
		if _exit_hint_tween:
			_exit_hint_tween.kill()
			_exit_hint_tween = null
		_exit_hint_label.modulate.a = 0.0
		_exit_hint_panel.modulate.a = 0.0

		depth_label.text = "Depth: %dm" % (depth_rows * 12)

	# Colour shifts from light blue → orange-red as player goes deeper
		var t: float = clampf(float(depth_rows) / 80.0, 0.0, 1.0)
		depth_label.modulate = Color(0.6 + t * 0.4, 0.85 - t * 0.55, 1.0 - t * 0.8, 1.0)

		# Show a milestone banner at every 20 blocks of new depth
		if depth_rows >= _next_milestone:
			_show_milestone_banner("Depth: %dm" % (_next_milestone * 12))
			_next_milestone += 20

func _on_fuel_changed(current_fuel: int, max_fuel: int) -> void:
	fuel_label.text = "Fuel: %d/%d" % [current_fuel, max_fuel]

	var fuel_ratio := float(current_fuel) / float(max_fuel)
	var is_low_fuel := current_fuel > 0 and fuel_ratio <= 0.2

	# Clear previous segments
	for segment in fuel_segments:
		segment.queue_free()
	fuel_segments.clear()

	# Rebuild fuel bar with 10 segments (each = 10 fuel)
	var segments := 10
	for i in range(segments):
		var segment := ColorRect.new()
		segment.custom_minimum_size = Vector2(20, 20)
		var filled: bool = i < (current_fuel / 10)
		if filled:
			# Orange-red tint when fuel is critically low
			segment.color = Color(1.0, 0.30, 0.05, 1.0) if is_low_fuel else Color(0.20, 0.80, 0.20, 1.0)
		else:
			segment.color = Color(0.25, 0.25, 0.25, 0.6)
		fuel_bar_container.add_child(segment)
		fuel_segments.append(segment)

	# Pulsing "! LOW FUEL !" warning
	if is_low_fuel:
		if not _low_fuel_tween or not _low_fuel_tween.is_running():
			_low_fuel_tween = create_tween()
			_low_fuel_tween.set_loops()
			_low_fuel_tween.tween_property(_low_fuel_warning, "modulate:a", 1.0, 0.4)
			_low_fuel_tween.tween_interval(0.15)
			_low_fuel_tween.tween_property(_low_fuel_warning, "modulate:a", 0.15, 0.4)
			_low_fuel_tween.tween_interval(0.15)
	else:
		if _low_fuel_tween:
			_low_fuel_tween.kill()
			_low_fuel_tween = null
		_low_fuel_warning.modulate.a = 0.0

func _show_milestone_banner(text: String) -> void:
	_milestone_label.text = text
	if _milestone_tween:
		_milestone_tween.kill()
	_milestone_tween = create_tween()
	_milestone_tween.tween_property(_milestone_label, "modulate:a", 1.0, 0.3)
	_milestone_tween.tween_interval(1.8)
	_milestone_tween.tween_property(_milestone_label, "modulate:a", 0.0, 0.5)
