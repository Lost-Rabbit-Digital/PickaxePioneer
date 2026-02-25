# Pickaxe Pioneer - Architecture Document

## 1. Project Structure
The project follows a modular, component-based structure to ensure scalability and maintainability.

```
res://
├── assets/                 # Art, Audio, Fonts
├── docs/                   # Documentation
├── notes/                  # Development notes
├── src/                    # Source Code & Scenes
│   ├── autoload/           # Global Singletons
│   ├── components/         # Reusable Component Nodes
│   ├── entities/           # Game Objects (Ant/Player, Minerals/Loot, NPCs)
│   ├── levels/             # Game Scenes (Overworld, MiningLevel, Colony/CityLevel)
│   ├── systems/            # Systems (ChatterManager)
│   └── ui/                 # User Interface
└── tests/                  # Unit Tests (GUT)
```

## 2. Core Systems

### 2.1 GameManager (`src/autoload/GameManager.gd`)
-   **Responsibility:** Manages global game state (MENU, PLAYING, PAUSED, GAME_OVER), scene transitions, mineral currency tracking, and ant upgrade levels.
-   **Pattern:** Singleton (Autoload).
-   **Key State:**
    -   `mineral_currency` — persistently banked minerals (saved to disk)
    -   `run_mineral_currency` — minerals collected in the current run (lost on death/fuel-out)
    -   `carapace_level`, `legs_level`, `mandibles_level` — ant upgrade levels (0–10)
    -   `current_fuel`, `max_fuel` — ant's energy reserves for the current run

### 2.2 EventBus (`src/autoload/EventBus.gd`)
-   **Responsibility:** Facilitates decoupled communication between systems.
-   **Pattern:** Observer / Signal Bus.
-   **Key Signals:**
    -   `game_state_changed(new_state)` — game state transitions
    -   `minerals_changed(amount)` — run mineral total updated (UI refresh)
    -   `minerals_earned(amount)` — individual tile mined (popup animation trigger)
    -   `fuel_changed(current, max)` — fuel bar refresh
    -   `player_health_changed(current, max)` — health squares refresh
    -   `player_died` — ant killed signal
    -   `ore_mined(type, amount)` — deprecated, kept for compatibility

### 2.3 SoundManager (`src/autoload/SoundManager.gd`)
-   **Responsibility:** Handles audio playback and procedural sound generation.
-   **Implementation:** Uses `AudioStreamGenerator` for dynamic SFX.
-   **Key Sounds:** `play_drill_sound()` (mandible dig), `play_explosion_sound()`, `play_pickup_sound()`

### 2.4 MusicManager (`src/autoload/MusicManager.gd`)
-   **Responsibility:** Adaptive music playback with crossfading between scenes.

### 2.5 QuestManager (`src/autoload/QuestManager.gd`)
-   **Responsibility:** Active quest tracking, colony mission system, reward distribution.

### 2.6 SettingsManager (`src/autoload/SettingsManager.gd`)
-   **Responsibility:** Graphics, audio, controls, and accessibility settings.

## 3. Entity Component System (ECS-lite)
We use Godot's node composition to mimic ECS patterns. Entities are composed of small, single-responsibility components.

### 3.1 Components (`src/components/`)
-   **`VelocityComponent`:** Handles physics movement, acceleration, and friction (used in non-grid entities).
-   **`HealthComponent`:** Manages HP, damage taking, and death signals (carapace HP for the ant).
-   **`HurtboxComponent`:** Detects incoming damage areas.
-   **`HitboxComponent`:** Delivers damage; damage value driven by `GameManager.get_mandibles_power()`.
-   **`MiningToolComponent`:** Handles weapon/tool firing logic (legacy, for non-grid combat).
-   **`CameraShake`:** Applies trauma-based camera shake; triggered by `EventBus.minerals_changed`.
-   **`StateMachine` / `State`:** Reusable state machine for entity AI.

### 3.2 Entities (`src/entities/`)
-   **`PlayerProbe` (the Ant):** The player entity in grid levels. Movement is handled directly by `MiningLevel`; this node manages carapace HP, interact prompts, and health signals.
-   **`ScrapLoot` (Mineral Pickup):** Collectible mineral item. Handles physics magnetism toward the ant and awards currency on collection. (Used in non-grid combat levels.)
-   **`QuestNPC` / `QuestItem`:** Colony NPC and associated quest item entities.
-   **`Caravan`:** Player token on the Overworld map.
-   **`MapNode`:** Individual mine entrance or colony node on the Overworld.
-   **`ExtractionZone`:** Zone entity for designating safe exit areas.

## 4. Level Design

### 4.1 Overworld (`src/levels/Overworld.gd / .tscn`)
-   **Purpose:** Node-based navigation map showing mine entrances and colony.
-   **Nodes:** Colony Hub, mine shaft nodes (Iron Seam, Gold Canyon, etc.)
-   **Player Token:** `Caravan` entity traverses connections between nodes.
-   **Input:** Arrow keys to navigate, Enter to select a mine.

### 4.2 MiningLevel (`src/levels/MiningLevel.gd / .tscn`)
-   **Purpose:** Main gameplay arena — grid-based underground mining.
-   **Grid:** 32 columns × 128 rows at 64px per cell.
-   **Layers:**
    -   Rows 0–2: Surface (sky blue, free movement)
    -   Row 3: Grass (1 mineral, free movement entry)
    -   Rows 4–127: Underground (1 fuel per tile)
-   **Key Tile Types:** EMPTY, DIRT, STONE, ORE_COPPER through ORE_GEM_DEEP, EXPLOSIVE, LAVA, FUEL_NODE, REFUEL_STATION, EXIT_STATION, SURFACE, SURFACE_GRASS
-   **Mineral Dictionary:** `TILE_MINERALS` maps TileType → mineral yield value
-   **Procedural Generation:** Depth-weighted `_random_tile()` places rarer ores deeper
-   **Camera:** `Camera2D` follows the ant with map boundary limits; viewport culling for performance

### 4.3 Colony Level (`src/levels/CityLevel.gd / .tscn`)
-   **Purpose:** Hub area for upgrades and NPC interactions between runs.
-   **On Entry:** Banks run currency; plays colony ambient music.

## 5. UI Systems (`src/ui/`)

| File | Purpose |
|------|---------|
| `MainMenu` | Title screen — New Game, Continue, Settings |
| `UpgradeMenu` | Colony Workshop — Carapace/Legs/Mandibles upgrades; Queen NPC dialogue |
| `HUD` | In-run display — Minerals counter, health squares, 10-segment fuel bar |
| `PauseMenu` | In-run pause — Resume, Settings, Abandon Run |
| `RunSummary` | Post-run — "Minerals Collected: X", return to Overworld |
| `ChatBubble` | Ambient NPC chatter bubbles (used by ChatterManager) |
| `MenuBackground` | Animated parallax background for menus |

## 6. Data Flow

1.  **Input:** Player input handled in `MiningLevel._unhandled_input` / `_process`.
2.  **Action:** Input triggers `_try_move(dc, dr)` — moves ant one tile.
3.  **Tile Interaction:**
    -   Ant enters a mineable tile → `_mine_cell()` clears it, `TILE_MINERALS` yields currency.
    -   `GameManager.add_currency(minerals)` adds to run total.
    -   `EventBus.minerals_earned.emit(minerals)` triggers HUD popup.
    -   Ant enters a hazard tile → damage or explosion.
    -   Ant enters a fuel node → `GameManager.restore_fuel(10)`.
    -   Ant reaches Exit Station → `GameManager.complete_run()` → RunSummary screen.
4.  **Fuel Depletion:**
    -   Each underground move calls `GameManager.consume_fuel(1)`.
    -   At 0 fuel → `_on_out_of_fuel()` → `GameManager.lose_run()` → lose run minerals.
5.  **Upgrade Purchase (Colony Workshop):**
    -   `UpgradeMenu` deducts `mineral_currency` and calls `upgrade_carapace/legs/mandibles()`.
    -   `GameManager.save_game()` persists to `user://save_data.json`.

## 7. Coding Standards
See `docs/godot_best_practices.md` for full guidelines. Key rules:
-   Static typing required on all variables and function signatures
-   Composition over inheritance; prefer components to deep class hierarchies
-   All cross-system communication through `EventBus` signals
-   No hardcoded scene paths; use constants
-   GUT framework for unit tests
