---
description: Create a new UI panel or menu screen
---

# Add UI Panel

Create a new UI panel for Pickaxe Pioneer following the established UI/UX design patterns.

## Panel Details
- **Name:** [e.g., "Research Tree Panel"]
- **Purpose:** [What does this panel do?]
- **Location:** [Where is it accessed from?]
- **Complexity:** [Simple/Medium/Complex]
- **Interactive Elements:** [Buttons, sliders, displays, etc.]

## Implementation Checklist

### 1. Scene Setup
- [ ] Create `src/ui/[PanelName].tscn`
- [ ] Create `src/ui/[PanelName].gd` script
- [ ] Set up as Control node (or PopupPanel if overlay)
- [ ] Configure anchors and margins for responsive design
- [ ] Set up theme/style

### 2. Visual Structure
- [ ] Add background panel (with theme styling)
- [ ] Add title/header
- [ ] Add close button (X in corner)
- [ ] Organize layout with containers:
  - [ ] VBoxContainer for vertical layouts
  - [ ] HBoxContainer for horizontal layouts
  - [ ] GridContainer for grid layouts
  - [ ] MarginContainer for padding

### 3. Interactive Elements
For each button/control:
- [ ] Add visual element
- [ ] Set up signals (pressed, toggled, value_changed)
- [ ] Add hover effects
- [ ] Add sound effects
- [ ] Implement functionality

### 4. Data Binding
- [ ] Connect to relevant manager (GameManager, UpgradeManager, etc.)
- [ ] Display current values/state
- [ ] Update UI when data changes
- [ ] Save user interactions

### 5. Animations & Polish
- [ ] Add open/close animations (fade, slide, scale)
- [ ] Add hover effects on buttons
- [ ] Add selection highlights
- [ ] Add transition effects
- [ ] Add particle effects (if appropriate)

### 6. Audio Integration
- [ ] Button hover sound
- [ ] Button click sound
- [ ] Panel open/close sound
- [ ] Success/error feedback sounds

### 7. Accessibility
- [ ] Keyboard navigation support (Tab, Enter, Esc)
- [ ] Controller support (if applicable)
- [ ] Tooltips for all interactive elements
- [ ] Readable text sizes
- [ ] High contrast mode compatibility

### 8. Testing
- [ ] Test all button interactions
- [ ] Test with different screen resolutions
- [ ] Test edge cases (empty data, max values)
- [ ] Test keyboard/controller navigation
- [ ] Test open/close animations

## Code Template

```gdscript
# src/ui/[PanelName].gd
extends Control
class_name [PanelName]

signal panel_closed

@onready var close_button = %CloseButton
@onready var content_container = %ContentContainer

var is_open: bool = false

func _ready():
    # Hide initially
    visible = false
    modulate.a = 0.0

    # Connect signals
    close_button.pressed.connect(_on_close_pressed)

    # Setup
    _initialize_content()

func open():
    if is_open:
        return

    is_open = true
    visible = true

    # Refresh data
    _refresh_display()

    # Animate in
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.3)
    tween.tween_property(self, "scale", Vector2.ONE, 0.2).from(Vector2(0.9, 0.9))

    # Sound
    SoundManager.play_ui_sound("panel_open")

func close():
    if not is_open:
        return

    is_open = false

    # Animate out
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.2)
    tween.finished.connect(func(): visible = false)

    # Sound
    SoundManager.play_ui_sound("panel_close")

    # Signal
    panel_closed.emit()

func _on_close_pressed():
    close()

func _input(event):
    # Close on ESC
    if event.is_action_pressed("ui_cancel") and is_open:
        close()
        get_viewport().set_input_as_handled()

func _initialize_content():
    # Create UI elements dynamically if needed
    pass

func _refresh_display():
    # Update displayed data
    pass
```

## Example: Button with Hover Effect

```gdscript
# In panel script or separate button script
@onready var my_button = %MyButton

func _ready():
    my_button.mouse_entered.connect(_on_button_hover)
    my_button.pressed.connect(_on_button_pressed)

func _on_button_hover():
    SoundManager.play_ui_sound("button_hover")
    # Visual effect
    var tween = create_tween()
    tween.tween_property(my_button, "modulate", Color(1.2, 1.2, 1.2), 0.1)

func _on_button_pressed():
    SoundManager.play_ui_sound("button_click")
    # Action
    _do_something()
```

## Responsive Design Pattern

```gdscript
# Adjust layout based on screen size
func _ready():
    get_viewport().size_changed.connect(_on_viewport_resized)
    _on_viewport_resized()

func _on_viewport_resized():
    var viewport_size = get_viewport_rect().size

    # Adjust for small screens
    if viewport_size.x < 1280:
        content_container.custom_minimum_size.x = viewport_size.x * 0.9
    else:
        content_container.custom_minimum_size.x = 800
```

Please create this UI panel with proper theming, animations, and user feedback.
