---
description: Add a new Steam achievement with tracking and unlock logic
---

# Implement Achievement

Add a new achievement to Pickaxe Pioneer with Steam integration.

## Achievement Details
- **ID:** [snake_case_id, e.g., "first_extraction"]
- **Name:** [Display name, e.g., "Safe Return"]
- **Description:** [Player-facing description]
- **Category:** [Story, Combat, Collection, Skill, Secret]
- **Rarity:** [Common, Uncommon, Rare, Epic]
- **Unlock Condition:** [Specific trigger]
- **Icon:** [32x32 and 64x64 image description]

## Implementation Checklist

### 1. Achievement Definition
- [ ] Add to `src/autoload/AchievementManager.gd`
- [ ] Define achievement ID constant
- [ ] Add to achievements dictionary
- [ ] Set up tracking variables

### 2. Icon Creation
- [ ] Design 32x32 icon (locked state)
- [ ] Design 32x32 icon (unlocked state)
- [ ] Design 64x64 icon (locked state)
- [ ] Design 64x64 icon (unlocked state)
- [ ] Save to `assets/ui/achievements/`
- [ ] Upload to Steamworks partner site

### 3. Tracking Logic
- [ ] Identify where progress is made
- [ ] Add progress tracking code
- [ ] Add unlock check
- [ ] Call AchievementManager.unlock()

### 4. Steam Integration
- [ ] Add achievement to Steamworks app settings
- [ ] Set achievement name and description
- [ ] Upload icons
- [ ] Set hidden/visible status
- [ ] Configure rarity percentage goal

### 5. UI Display
- [ ] Add to achievements panel
- [ ] Show progress bar (if incremental)
- [ ] Display unlock notification
- [ ] Add to statistics screen

### 6. Save System
- [ ] Ensure unlock state saves to file
- [ ] Sync with Steam Cloud
- [ ] Handle offline unlocks

### 7. Testing
- [ ] Test unlock condition
- [ ] Verify Steam popup appears
- [ ] Test with multiple users
- [ ] Verify save persistence

## Code Examples

### 1. Add to AchievementManager.gd

```gdscript
# src/autoload/AchievementManager.gd
extends Node

# Achievement IDs
const ACHIEVEMENT_[ID_CAPS] = "[achievement_id]"

# Achievement definitions
var achievements = {
    ACHIEVEMENT_[ID_CAPS]: {
        "name": "[Achievement Name]",
        "description": "[Description]",
        "icon_locked": "res://assets/ui/achievements/[id]_locked.png",
        "icon_unlocked": "res://assets/ui/achievements/[id]_unlocked.png",
        "unlocked": false,
        "hidden": false,
        "progress": 0,  # For incremental achievements
        "max_progress": 1,  # Set to 1 for binary achievements
    },
}

func unlock_achievement(achievement_id: String):
    if not achievements.has(achievement_id):
        push_error("Achievement not found: " + achievement_id)
        return

    if achievements[achievement_id].unlocked:
        return  # Already unlocked

    # Mark as unlocked
    achievements[achievement_id].unlocked = true

    # Steam integration
    if Steam.is_init():
        Steam.setAchievement(achievement_id)
        Steam.storeStats()

    # Visual notification
    _show_achievement_popup(achievement_id)

    # Sound effect
    SoundManager.play_ui_sound("achievement_unlocked")

    # Save
    GameManager.save_game()

    # Signal for other systems
    achievement_unlocked.emit(achievement_id)

func add_achievement_progress(achievement_id: String, amount: int = 1):
    if not achievements.has(achievement_id):
        return

    var ach = achievements[achievement_id]

    if ach.unlocked:
        return

    # Increment progress
    ach.progress += amount

    # Check for unlock
    if ach.progress >= ach.max_progress:
        unlock_achievement(achievement_id)
    else:
        # Update Steam stat (for incremental achievements)
        if Steam.is_init():
            Steam.setStatInt(achievement_id + "_progress", ach.progress)
            Steam.storeStats()

func _show_achievement_popup(achievement_id: String):
    # Create popup notification
    var popup = preload("res://src/ui/AchievementPopup.tscn").instantiate()
    popup.set_achievement(achievements[achievement_id])
    get_tree().current_scene.add_child(popup)

signal achievement_unlocked(achievement_id: String)
```

### 2. Usage in Game Code

```gdscript
# Example: Unlock on first extraction
# In ExtractionZone.gd or GameManager.gd

func _on_extraction_complete():
    # ... extraction logic ...

    # Check if this is the player's first extraction
    if GameManager.stats.total_extractions == 1:
        AchievementManager.unlock_achievement(
            AchievementManager.ACHIEVEMENT_FIRST_EXTRACTION
        )
```

### 3. Incremental Achievement Example

```gdscript
# In AchievementManager.gd, define incremental achievement
var achievements = {
    ACHIEVEMENT_KILL_100_ENEMIES: {
        "name": "Wasteland Hunter",
        "description": "Defeat 100 enemies",
        "max_progress": 100,
        "progress": 0,
        # ... other fields ...
    }
}

# In enemy death code
func _on_enemy_died():
    AchievementManager.add_achievement_progress(
        AchievementManager.ACHIEVEMENT_KILL_100_ENEMIES,
        1
    )
```

### 4. Achievement Popup UI

```gdscript
# src/ui/AchievementPopup.gd
extends Control

@onready var icon = %Icon
@onready var title_label = %TitleLabel
@onready var description_label = %DescriptionLabel

func set_achievement(achievement_data: Dictionary):
    title_label.text = achievement_data.name
    description_label.text = achievement_data.description
    icon.texture = load(achievement_data.icon_unlocked)

    # Animate in
    modulate.a = 0.0
    position.y = -100

    var tween = create_tween()
    tween.set_parallel()
    tween.tween_property(self, "modulate:a", 1.0, 0.3)
    tween.tween_property(self, "position:y", 20, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

    # Wait and animate out
    await get_tree().create_timer(5.0).timeout

    var tween_out = create_tween()
    tween_out.tween_property(self, "modulate:a", 0.0, 0.3)
    tween_out.finished.connect(queue_free)
```

### 5. Achievements Panel

```gdscript
# src/ui/AchievementsPanel.gd
extends Control

@onready var achievement_grid = %AchievementGrid

func _ready():
    _populate_achievements()

func _populate_achievements():
    # Clear existing
    for child in achievement_grid.get_children():
        child.queue_free()

    # Add achievement entries
    for achievement_id in AchievementManager.achievements:
        var ach_data = AchievementManager.achievements[achievement_id]

        # Skip hidden unocked achievements
        if ach_data.hidden and not ach_data.unlocked:
            continue

        var entry = preload("res://src/ui/AchievementEntry.tscn").instantiate()
        entry.set_data(ach_data)
        achievement_grid.add_child(entry)
```

## Steam Setup Checklist

1. **Steamworks Partner:**
   - Log in to Steamworks partner site
   - Navigate to your app
   - Go to "Stats & Achievements" section

2. **Achievement Configuration:**
   - Click "Add New Achievement"
   - Set Achievement ID (must match code)
   - Set Display Name
   - Set Description
   - Upload icons (32x32 and 64x64, both states)
   - Set visibility (visible/hidden)
   - Save and publish changes

3. **GodotSteam Integration:**
   - Ensure GodotSteam plugin is installed
   - Configure steam_appid.txt
   - Test achievement unlocks in development

Please implement this achievement with proper Steam integration and visual feedback.
