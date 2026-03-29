class_name UIHelper
extends RefCounted

## Shared UI construction helpers used across menus, summaries, and shop panels.
## Consolidates repeated backdrop, border, label, and separator creation.


## Create a full-screen dark backdrop ColorRect.
## If animate is true, fades in from transparent over fade_duration seconds.
static func create_backdrop(parent: Node, alpha: float = 0.72, animate: bool = false, fade_duration: float = 0.3) -> ColorRect:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if animate:
		backdrop.color = Color(0, 0, 0, 0.0)
		parent.add_child(backdrop)
		var tween := parent.create_tween()
		tween.tween_property(backdrop, "color:a", alpha, fade_duration)
	else:
		backdrop.color = Color(0.0, 0.0, 0.0, alpha)
		parent.add_child(backdrop)
	return backdrop


## Create a dim overlay rect that blocks mouse input (used by shop panels).
static func create_dim_rect(parent: Node, vw: int = 1280, vh: int = 720, alpha: float = 0.72) -> ColorRect:
	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(vw, vh)
	dim.color = Color(0, 0, 0, alpha)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(dim)
	return dim


## Create a panel background with an outer border.
## Returns a Dictionary with keys "border" and "panel" for later reference.
static func create_bordered_panel(parent: Node, px: float, py: float, pw: float, ph: float,
		border_color: Color, bg_color: Color, border_thickness: int = 3) -> Dictionary:
	var bt := border_thickness
	var border := ColorRect.new()
	border.position = Vector2(px - bt, py - bt)
	border.size = Vector2(pw + bt * 2, ph + bt * 2)
	border.color = border_color
	parent.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(px, py)
	panel.size = Vector2(pw, ph)
	panel.color = bg_color
	parent.add_child(panel)
	return {"border": border, "panel": panel}


## Generate 4 thin border ColorRects (top, bottom, left, right) for a rectangular region.
## Returns an Array of Dictionaries with keys: position, size, color.
static func border_rects(x: float, y: float, w: float, h: float, thickness: int, color: Color) -> Array:
	return [
		{"position": Vector2(x, y), "size": Vector2(w, thickness), "color": color},
		{"position": Vector2(x, y + h - thickness), "size": Vector2(w, thickness), "color": color},
		{"position": Vector2(x, y), "size": Vector2(thickness, h), "color": color},
		{"position": Vector2(x + w - thickness, y), "size": Vector2(thickness, h), "color": color},
	]


## Add border ColorRects to a parent node from border_rects() output.
static func add_borders(parent: Node, x: float, y: float, w: float, h: float, thickness: int, color: Color) -> void:
	for spec in border_rects(x, y, w, h, thickness, color):
		var rect := ColorRect.new()
		rect.position = spec.position
		rect.size = spec.size
		rect.color = spec.color
		parent.add_child(rect)


## Create a Label with common theme overrides.
static func create_label(parent: Node, text: String, lx: float, ly: float,
		w: float, h: float, font_size: int, color: Color,
		h_align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(lx, ly)
	lbl.size = Vector2(w, h)
	lbl.horizontal_alignment = h_align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl


## Create a horizontal separator line.
static func create_separator(parent: Node, px: float, y: float, width: float,
		color: Color = Color(0.3, 0.3, 0.35, 0.6), thickness: int = 1) -> ColorRect:
	var sep := ColorRect.new()
	sep.position = Vector2(px, y)
	sep.size = Vector2(width, thickness)
	sep.color = color
	parent.add_child(sep)
	return sep


## Create a small colored square icon (used in ore summary rows).
static func create_colour_icon(parent: Node, px: float, row_y: float,
		color: Color, icon_size: int = 14) -> ColorRect:
	var icon := ColorRect.new()
	icon.position = Vector2(px, row_y + 3)
	icon.size = Vector2(icon_size, icon_size)
	icon.color = color
	parent.add_child(icon)
	return icon


## Check if an item is unlocked based on required level vs player's global level.
static func is_unlocked(required_level: int) -> bool:
	return GameManager.global_player_level >= required_level


## Apply standard locked/unlocked styling to a button and optional label.
static func apply_lock_style(btn: Button, locked: bool, locked_text: String = "") -> void:
	btn.disabled = locked
	if locked and locked_text != "":
		btn.text = locked_text
