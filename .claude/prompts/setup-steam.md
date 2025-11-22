---
description: Set up Steamworks integration for Pickaxe Pioneer
---

# Setup Steamworks Integration

Please help me integrate Steamworks SDK into Pickaxe Pioneer using GodotSteam.

## Setup Tasks

### 1. GodotSteam Plugin Installation
- [ ] Download GodotSteam for Godot 4.x from GitHub
- [ ] Extract to `res://addons/godotsteam/`
- [ ] Enable plugin in Project Settings
- [ ] Verify plugin loaded correctly

### 2. Steam App Configuration
- [ ] Create `steam_appid.txt` in project root
- [ ] Add your Steam App ID (or 480 for testing)
- [ ] Add to .gitignore
- [ ] Create steam_api.dll symlink (Windows) or equivalent

### 3. Initialize Steam in Code
```gdscript
# In src/autoload/SteamManager.gd (create if not exists)
extends Node

var is_steam_enabled: bool = false
var steam_id: int = 0
var steam_username: String = ""

func _ready():
    _initialize_steam()

func _initialize_steam():
    # Check if Steam is available
    if not OS.has_feature("Steam"):
        push_warning("Steam not available")
        return

    # Initialize Steam
    var initialize_response: Dictionary = Steam.steamInitEx()
    prints("Steam initialization:", initialize_response)

    if initialize_response['status'] != 1:
        push_error("Failed to initialize Steam: " + str(initialize_response))
        return

    is_steam_enabled = true
    steam_id = Steam.getSteamID()
    steam_username = Steam.getPersonaName()

    prints("Steam initialized for user:", steam_username, steam_id)

    # Set up callbacks
    Steam.current_stats_received.connect(_on_stats_received)
```

### 4. Achievement System Integration
- [ ] Create AchievementManager autoload (if not exists)
- [ ] Implement Steam achievement unlock
- [ ] Implement Steam stats tracking
- [ ] Add achievement list
- [ ] Test with development build

```gdscript
# In AchievementManager.gd
func unlock_achievement(achievement_id: String):
    if SteamManager.is_steam_enabled:
        Steam.setAchievement(achievement_id)
        Steam.storeStats()
        print("Steam achievement unlocked: ", achievement_id)
```

### 5. Cloud Save Integration
- [ ] Enable Steam Cloud in Steamworks settings
- [ ] Configure file paths to sync
- [ ] Implement cloud save upload
- [ ] Implement cloud save download
- [ ] Handle conflicts

```gdscript
# In GameManager.gd or SaveSystem
func save_to_cloud():
    if not SteamManager.is_steam_enabled:
        return

    var save_data = _get_save_data()
    var json_string = JSON.stringify(save_data)

    # Write to Steam Cloud
    Steam.fileWrite("save_slot_1.sav", json_string.to_utf8_buffer())
    print("Saved to Steam Cloud")

func load_from_cloud():
    if not SteamManager.is_steam_enabled:
        return null

    if Steam.fileExists("save_slot_1.sav"):
        var file_size = Steam.getFileSize("save_slot_1.sav")
        var save_buffer = Steam.fileRead("save_slot_1.sav", file_size)
        var json_string = save_buffer.get_string_from_utf8()
        var save_data = JSON.parse_string(json_string)
        return save_data

    return null
```

### 6. Rich Presence
- [ ] Set up rich presence strings in Steamworks
- [ ] Update presence based on game state

```gdscript
# Update rich presence
func update_presence(status: String, details: String = ""):
    if not SteamManager.is_steam_enabled:
        return

    Steam.setRichPresence("status", status)
    if details:
        Steam.setRichPresence("details", details)

# Example usage:
# In Hub: update_presence("In Hub", "Upgrading vehicle")
# In Zone: update_presence("In Combat", "Zone 3 - Toxic Wastes")
```

### 7. Testing
- [ ] Test with Steam running
- [ ] Test achievements unlock
- [ ] Test cloud saves sync
- [ ] Test rich presence
- [ ] Test offline mode fallback
- [ ] Test with multiple Steam accounts

### 8. Build Configuration
- [ ] Set up export presets for Steam
- [ ] Include steam_api.dll / .so / .dylib
- [ ] Configure depots in Steamworks
- [ ] Test Steam build pipeline

## Important Notes

**Development Testing:**
- Use Steam App ID 480 (Spacewar) for testing
- Replace with actual App ID before release
- Keep steam_appid.txt in .gitignore

**Steamworks Partner Requirements:**
- Must have Steamworks partner account
- Must have app ID assigned
- Must configure achievements in Steamworks dashboard
- Must upload depot builds through Steamworks

**GodotSteam Documentation:**
- https://godotsteam.com/
- Check compatibility with Godot 4.5

Please help me implement Steamworks integration step by step.
