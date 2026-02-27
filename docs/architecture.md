# Pickaxe Pioneer - Architecture Document

## 1. Project Structure

```
res://
├── assets/                 # Art, Audio, Fonts
├── docs/                   # Documentation
├── notes/                  # Development notes
├── src/                    # Source Code & Scenes
│   ├── autoload/           # Global Singletons
│   ├── components/         # Reusable Component Nodes
│   ├── entities/           # Game Objects (Player, NPCs, Loot, Overworld tokens)
│   ├── levels/             # Game Scenes (Overworld, MiningLevel, CityLevel, SettlementLevel)
│   ├── systems/            # Extracted subsystems (Smelting, Fossil, Sonar, Forager, Boss)
│   └── ui/                 # User Interface
└── tests/                  # Unit Tests (GUT)
```

## 2. Core Systems

### 2.1 GameManager (`src/autoload/GameManager.gd`)
-   **Responsibility:** Manages global game state (MENU, PLAYING, PAUSED, GAME_OVER), scene transitions, mineral currency tracking, and ant upgrade levels.
-   **Pattern:** Singleton (Autoload).
-   **Key State:**
    -   `mineral_currency` — persistently banked minerals (saved to disk)
    -   `run_mineral_currency` — minerals collected in the current run (lost on death/energy-out)
    -   `carapace_level`, `legs_level`, `mandibles_level`, `mineral_sense_level` — upgrade levels (0–10)
    -   `current_energy`, `max_energy` — ant's energy reserves for the current run
    -   Settlement carry-over fields — consumable bonuses applied on mine entry and cleared after use

### 2.2 EventBus (`src/autoload/EventBus.gd`)
-   **Responsibility:** Facilitates decoupled communication between systems.
-   **Pattern:** Observer / Signal Bus.
-   **Key Signals:**
    -   `game_state_changed(new_state)` — game state transitions
    -   `minerals_changed(amount)` — run mineral total updated (UI refresh)
    -   `minerals_earned(amount)` — individual tile mined (popup animation trigger)
    -   `energy_changed(current, max)` — energy bar refresh
    -   `player_health_changed(current, max)` — health squares refresh
    -   `player_died` — ant killed signal
    -   `ore_mined(type, amount)` — deprecated, kept for compatibility

### 2.3 SoundManager (`src/autoload/SoundManager.gd`)
-   **Responsibility:** Handles audio playback and procedural sound generation.
-   **Implementation:** Uses `AudioStreamGenerator` for dynamic SFX.
-   **Key Sounds:** `play_drill_sound()` (mining SFX), `play_explosion_sound()`, `play_pickup_sound()`

### 2.4 MusicManager (`src/autoload/MusicManager.gd`)
-   **Responsibility:** Adaptive music playback with crossfading between scenes.

### 2.5 QuestManager (`src/autoload/QuestManager.gd`)
-   **Responsibility:** Quest tracking stub — exists but is cleared on mine entry and not yet active.

### 2.6 SettingsManager (`src/autoload/SettingsManager.gd`)
-   **Responsibility:** Graphics, audio, controls, and accessibility settings.

### 2.7 SceneTransition (`src/autoload/SceneTransition.gd`)
-   **Responsibility:** Animated transitions between scenes.

## 3. Entity Component System (ECS-lite)

We use Godot's node composition to mimic ECS patterns. Entities are composed of small, single-responsibility components.

### 3.1 Components (`src/components/`)
-   **`VelocityComponent`:** Handles physics movement, acceleration, and friction.
-   **`HealthComponent`:** Manages HP, damage taking, and death signals.
-   **`HurtboxComponent`:** Detects incoming damage areas.
-   **`HitboxComponent`:** Delivers damage; damage value driven by `GameManager.get_mandibles_power()`.
-   **`MiningToolComponent`:** Handles weapon/tool firing logic (legacy, for non-grid combat).
-   **`CameraShake`:** Applies trauma-based camera shake.
-   **`StateMachine` / `State`:** Reusable state machine components (defined, underutilised in MiningLevel).

### 3.2 Entities (`src/entities/`)
-   **`PlayerProbe` (the Ant):** The player `CharacterBody2D` in mining levels. Terraria-style physics (gravity, jump, horizontal run). Mining is cursor-based (left-click within 4.5-tile range).
-   **`ScrapLoot` / `OreChunk`:** Collectible mineral items.
-   **`QuestNPC` / `QuestItem`:** Colony NPC and associated quest item entities (stub).
-   **`FarmAnimalNPC`:** Chicken/sheep/pig surface NPCs (pettable, no gameplay role).
-   **`Caravan`:** Player token on the Overworld map.
-   **`MapNode`:** Individual mine entrance, settlement, or colony node on the Overworld. `NodeType` enum: `EMPTY(0)`, `MINE(1)`, `STATION(2)`, `SETTLEMENT(3)`.
-   **`ExtractionZone`:** Zone entity for designating safe exit areas.

## 4. Level Design

### 4.1 Overworld (`src/levels/Overworld.gd / .tscn`)
-   **Purpose:** Node-based navigation map showing mine entrances, settlement rest stops, and the colony.
-   **Nodes:** Colony Hub (STATION), mine shaft nodes (MINE), settlement nodes (SETTLEMENT).
-   **Player Token:** `Caravan` entity traverses connections between nodes.
-   **On Node Click:** `LevelInfoModal` shows node details and the Enter button before loading a scene.

### 4.2 MiningLevel (`src/levels/MiningLevel.gd / .tscn`)
-   **Purpose:** Main gameplay arena — Terraria-style underground mining.
-   **Player Movement:** `CharacterBody2D` with gravity, jump, and horizontal run. **Not grid-based.**
-   **Mining:** Cursor-driven — left-click within 4.5-tile range to mine; multi-hit system for tougher tiles.
-   **Grid:** 96 columns × 128 rows at 64 px per cell.
-   **Layers:**
    -   Rows 0–2: Surface (sky blue, free movement)
    -   Row 3: Grass (1 mineral, free movement)
    -   Rows 4–127: Underground (energy depletes by depth)
-   **Key Tile Types:** EMPTY, DIRT, STONE, ORE_COPPER through ORE_GEM_DEEP, EXPLOSIVE, LAVA, ENERGY_NODE, REENERGY_STATION, EXIT_STATION, SURFACE, SURFACE_GRASS
-   **Procedural Generation:** `_generate_grid()` depth-weighted tile placement + `_generate_cave_rooms()` carves 6–10 elliptical open chambers with ore-rich walls
-   **Camera:** `Camera2D` follows the ant with map boundary limits; viewport culling for performance
-   **Size:** ~1,970 lines. All major subsystems extracted to `src/systems/`.

### 4.3 SettlementLevel (`src/levels/SettlementLevel.gd / .tscn`)
-   **Purpose:** Rest stop between runs. Players spend banked `mineral_currency` on pre-run consumables.
-   **Consumables:** Energy Cache (+50 starting energy), Field Repair (+1 HP), Mining Shroom (12 ore-yield charges), Whetstone (+1 mandible power).
-   **On Purchase:** Bonuses stored in `GameManager` settlement fields, applied on mine entry and cleared.

### 4.4 Colony Level (`src/levels/CityLevel.gd / .tscn`)
-   **Purpose:** Hub area for permanent upgrades between runs.
-   **On Entry:** Banks run currency; plays colony ambient music; hosts UpgradeMenu.

## 5. Extracted Subsystems (`src/systems/`)

All implemented as `RefCounted` classes with clean interfaces. `MiningLevel` delegates to them and reads public state for draw calls.

| System | File | Responsibility |
|--------|------|---------------|
| SmeltingSystem | `SmeltingSystem.gd` | Consecutive ore chain bonuses and alloy combos (Super Motherload–inspired) |
| FossilSystem | `FossilSystem.gd` | Fossil drop probability with forgiveness pity mechanic (drought counter per block type) |
| SonarSystem | `SonarSystem.gd` | Sonar ping — radial ore shimmer through solid rock, energy-cost per activation |
| ForagerSystem | `ForagerSystem.gd` | Forager ant companion: takes 40% ore yield, carries up to 30 minerals, auto-banks on return |
| BossSystem | `BossSystem.gd` | Boss encounter logic — five depth-milestone bosses, energy-drain pressure, phase management |
| ChatterManager | `ChatterManager.gd` | Ambient NPC chatter bubble text pool and timing |

## 6. UI Systems (`src/ui/`)

| File | Purpose |
|------|---------|
| `MainMenu` | Title screen — New Game, Continue, Settings; animated parallax background |
| `UpgradeMenu` | Colony Workshop — Carapace/Legs/Mandibles/Mineral Sense upgrades |
| `HUD` | In-run display — minerals counter, health squares, segmented energy bar, depth meter, milestone banners, low-energy/low-HP warnings |
| `PauseMenu` | In-run pause — Resume, Settings, Abandon Run |
| `RunSummary` | Post-run — minerals collected, return to Overworld |
| `LevelInfoModal` | Overworld node info panel shown before entering a mine, settlement, or city |
| `InventoryScreen` | In-run inventory display |
| `ChatBubble` | Ambient NPC chatter bubbles (used by ChatterManager) |
| `MenuBackground` | Animated parallax background for menus |

## 7. Data Flow

1.  **Input:** Player movement via `CharacterBody2D` physics in `MiningLevel._physics_process`. Mining via left-click cursor within `mine_range` (4.5 tiles).
2.  **Tile Interaction:**
    -   Ant mines a tile → `_mine_cell()` clears it, applies `TILE_MINERALS` base value, SmeltingSystem applies chain bonuses.
    -   `GameManager.add_currency(minerals)` adds to run total.
    -   `EventBus.minerals_earned.emit(minerals)` triggers HUD popup.
    -   FossilSystem rolls for fossil drop on each mined tile.
    -   Hazard tiles deal damage or trigger explosions.
    -   Energy nodes call `GameManager.restore_energy(10)`.
    -   Exit Station reached → `GameManager.complete_run()` → RunSummary screen.
3.  **Energy Depletion:**
    -   Underground movement drains energy by depth.
    -   At 0 energy → `_on_out_of_energy()` → `GameManager.lose_run()` → lose run minerals.
4.  **Forager Ant:**
    -   ForagerSystem takes 40% of each ore yield; carries up to 30 minerals (base).
    -   When full, forager returns to surface and banks directly into `mineral_currency` (safe from death).
5.  **Boss Encounters:**
    -   BossSystem triggers at milestone rows (32, 64, 96, 112, 128).
    -   Energy drains 2.5× while a boss is alive; defeating rewards 100 minerals + 30 energy.
6.  **Upgrade Purchase (Colony Workshop):**
    -   `UpgradeMenu` deducts `mineral_currency` and calls `upgrade_carapace/legs/mandibles/mineral_sense()`.
    -   `GameManager.save_game()` persists to `user://save_data.json`.

## 8. Coding Standards

See `docs/godot_best_practices.md` for full guidelines. Key rules:
-   Static typing required on all variables and function signatures
-   Composition over inheritance; prefer components to deep class hierarchies
-   All cross-system communication through `EventBus` signals
-   No hardcoded scene paths; use constants
-   GUT framework for unit tests
