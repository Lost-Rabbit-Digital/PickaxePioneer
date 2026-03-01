# Pickaxe Pioneer — Architecture Document

## 1. Project Structure

```
res://
├── assets/                 # Art, Audio, Fonts
├── docs/                   # Documentation
├── notes/                  # Development notes
└── src/                    # Source Code & Scenes
    ├── autoload/           # Global Singletons
    ├── components/         # Reusable Component Nodes
    ├── entities/           # Game Objects (Player, NPCs, Loot, Overworld tokens)
    ├── levels/             # Game Scenes (Overworld, MiningLevel, CityLevel, SettlementLevel)
    ├── systems/            # Extracted subsystems (all RefCounted)
    └── ui/                 # User Interface
```

---

## 2. Core Autoloads (`src/autoload/`)

All singletons are registered in `project.godot`.

### 2.1 GameManager
- **Responsibility:** Global game state (MENU, PLAYING, PAUSED, GAME_OVER), scene transitions, mineral currency, upgrade levels, energy, settlement carry-over bonuses, planet metadata.
- **Pattern:** Singleton (Autoload).
- **Key State:**
    - `mineral_currency` — persistently banked minerals (saved to disk)
    - `run_mineral_currency` — minerals collected in the current run (lost on death/energy-out)
    - `pelt_level` / `legs_level` / `claws_level` / `mineral_sense_level` — upgrade levels 0–10
      *(Internal vars still named `carapace_level` / `mandibles_level` pending Task 2.4 refactor)*
    - `current_energy` — cat's energy reserve for the current run
    - `current_planet_color: Color` — atmosphere color of the selected mine node; set from `Overworld.mine_metadata` on entry; `MiningLevel._draw()` uses it for sky and underground gradient tinting
    - `allowed_ore_types` / `allowed_hazard_types` — filter arrays set from `MapNode` on entry
    - Settlement carry-over fields: `settlement_energy_bonus`, `settlement_shroom_charges`, `settlement_mandible_bonus`
    - Spaceship upgrade flags: `warp_drive_built`, `cargo_bay_built`, `long_scanner_built`, `gem_refinery_built`, `trade_amplifier_built`
    - Cumulative milestone trackers: `total_minerals_banked`, `bosses_defeated_total`, `total_fossils`, `deepest_row_reached`

### 2.2 EventBus
- **Responsibility:** Decoupled cross-system communication. All inter-system signals go here; direct node references are never passed across system boundaries.
- **Pattern:** Observer / Signal Bus.
- **Key Signals:**
    - `game_state_changed(new_state)` — state transitions
    - `minerals_changed(amount)` — run mineral total updated (HUD refresh)
    - `minerals_earned(amount)` — individual tile mined (popup animation trigger)
    - `dollars_changed(amount)` — secondary currency updated
    - `energy_changed(current, max)` — energy bar refresh
    - `player_health_changed(current, max)` — health squares refresh
    - `player_died` — cat killed signal

### 2.3 SoundManager
- **Responsibility:** Procedural SFX via `AudioStreamGenerator`.
- **Key methods:** `play_drill_sound()`, `play_explosion_sound()`, `play_pickup_sound()`

### 2.4 MusicManager
- **Responsibility:** Adaptive music playback with crossfading between scenes.

### 2.5 SettingsManager
- **Responsibility:** Graphics, audio, controls, and accessibility settings persistence.

### 2.6 SceneTransition
- **Responsibility:** Animated scene transitions (fade, wipe).

### 2.7 SaveManager
- **Responsibility:** Slot-based save/load coordination. Persists all `GameManager` state to `user://save_data.json` as JSON. On first boot, migrates legacy single-slot saves.
- **Key methods:** `save_slot()`, `load_slot()`, `get_planet_config()`, `save_planet_config()`

### 2.8 QuestManager
- **Responsibility:** Quest tracking stub — imported as autoload but cleared on mine entry. Not yet active. Either connect to real quest data or remove before Steam release.

---

## 3. Component System (`src/components/`)

Godot node composition pattern. Entities are assembled from small, single-responsibility components.

| Component | Responsibility |
|-----------|---------------|
| `VelocityComponent` | Physics movement, acceleration, friction |
| `HealthComponent` | HP, damage intake, death signal |
| `HurtboxComponent` | Receives incoming damage from Hitbox areas |
| `HitboxComponent` | Deals damage; value driven by `GameManager.get_claws_power()` |
| `MiningToolComponent` | Tool/weapon firing logic (legacy; pre-dates cursor mining) |
| `CameraShake` | Trauma-based camera shake |
| `StateMachine` / `State` | Generic state machine (defined; underutilised in MiningLevel — uses ad-hoc flags instead) |

---

## 4. Entities (`src/entities/`)

### 4.1 Player
- **`PlayerProbe`** (`src/entities/player/`) — The cat player as a `CharacterBody2D`. Terraria-style physics (gravity, jump, horizontal run). Mining is cursor-based: left-click within 4.5-tile `mine_range`. Animated cat spritesheet; loaded by `MiningLevel.gd`.

### 4.2 Overworld Tokens
- **`MapNode`** — Individual planet/settlement/station node. `NodeType` enum: `EMPTY(0)`, `MINE(1)`, `STATION(2)`, `SETTLEMENT(3)`. Emits `node_clicked` signal.
- **`Caravan`** — Cat's ship token on the Overworld; traverses node connections via BFS path.

### 4.3 NPCs & World Objects
- **`FarmAnimalNPC`** — Chicken/sheep/pig surface NPCs; pettable, no gameplay role.
- **`QuestNPC`** / **`QuestItem`** — Quest NPC and item entities (stub; not active).
- **`ExtractionZone`** — Designates safe exit areas underground.

### 4.4 Loot
- **`OreChunk`** / **`ScrapLoot`** — Collectible mineral items spawned on tile destruction.

---

## 5. Level Controllers (`src/levels/`)

### 5.1 Overworld
**File:** `src/levels/Overworld.gd / .tscn`
- Node-based star chart: mine planets (MINE), settlement rest stops (SETTLEMENT), Clowder Space Station (STATION).
- `mine_metadata` dictionary keys every mine name to `{difficulty, ores, hazards, color}`. The `color` field is read by `GameManager.current_planet_color` on mine entry and used to tint the mining level sky and underground gradient.
- `LevelInfoModal` shows node details before loading a scene.

### 5.2 MiningLevel
**File:** `src/levels/MiningLevel.gd / .tscn` (~1,970 lines)
- Core gameplay arena. **Do not add logic here** — extract new systems to `src/systems/` as `RefCounted` classes.
- **Movement:** `CharacterBody2D` with gravity, jump, and horizontal run. Not grid-based.
- **Mining:** Cursor-driven left-click within 4.5-tile range; multi-hit system for tougher tiles.
- **Grid:** 96 columns × 128 rows at 64 px/cell.
- **Background:** `_draw()` derives sky color and underground gradient from `GameManager.current_planet_color`; gradient uses `darkened(0.75)` → `darkened(0.96)` across 32 horizontal strips.
- **Boss rows:** 32, 64, 96, 112, 128 — energy drains 2.5× during boss.
- **Also handles:** `MiningShopSystem` (in-level shop logic), ladder placement, zone banner display.

### 5.3 SettlementLevel
**File:** `src/levels/SettlementLevel.gd / .tscn`
- Rest stop between runs. Players spend `mineral_currency` on pre-run consumables.
- Consumables: Energy Cache (+50 energy), Pelt Patch (+1 HP), Mining Shroom (12 ore-yield charges), Claw Whetstone (+1 claw power).
- Bonuses stored in `GameManager` settlement fields, applied on mine entry, then cleared.

### 5.4 CityLevel
**File:** `src/levels/CityLevel.gd / .tscn`
- Clowder Space Station hub. Banks `run_mineral_currency` on entry. Hosts `UpgradeMenu` for permanent Pelt/Paws/Claws/Whiskers upgrades, gem socketing, and spaceship chamber unlocks.

---

## 6. Extracted Subsystems (`src/systems/`)

All implemented as `RefCounted` classes with clean interfaces. `MiningLevel` delegates to them and reads public state for `_draw()` calls.

| System | File | Responsibility |
|--------|------|---------------|
| SmeltingSystem | `SmeltingSystem.gd` | Consecutive ore chain bonuses and alloy combos (Super Motherload–inspired) |
| FossilSystem | `FossilSystem.gd` | Fossil drop probability with forgiveness pity counter per block type |
| SonarSystem | `SonarSystem.gd` | Sonar ping — radial ore shimmer through solid rock, energy cost per activation |
| ForagerSystem | `ForagerSystem.gd` | Scout Cat companion — takes 40% ore yield, carries up to 30 minerals, auto-banks when full |
| BossSystem | `BossSystem.gd` | Five depth-milestone boss encounters: Giant Rat King (32) · Void Spider Matriarch (64) · Blind Mole (96) · Stone Golem (112) · The Ancient Star Beast (128) |
| BossRenderer | `BossRenderer.gd` | Draw calls for BossSystem (separated for MiningLevel cleanliness) |
| ChatterManager | `ChatterManager.gd` | Ambient cat NPC chatter bubble text pool and timing |
| MiningTerrainGenerator | `MiningTerrainGenerator.gd` | Procedural tile grid generation — depth-weighted tile placement and cave room carving (extracted from MiningLevel) |
| TraderSystem | `TraderSystem.gd` | Wandering Trader at depth milestone rows (32, 64, 96, 128); offers tier-scaled consumables |
| CatSystem | `CatSystem.gd` | Cat-specific stat helpers and behaviour utilities |
| MiningShopSystem | `src/levels/MiningShopSystem.gd` | In-level upgrade shop logic (lives in levels/ not systems/ — candidate for extraction) |

---

## 7. UI Systems (`src/ui/`)

| File | Purpose |
|------|---------|
| `MainMenu` | Title screen — New Game, Continue, Settings; animated parallax background |
| `UpgradeMenu` | Clowder Workshop — Pelt/Paws/Claws/Whiskers upgrades, gem socket slots |
| `HUD` | In-run display — minerals counter, health squares, segmented energy bar, depth meter, milestone banners, low-energy/low-HP warnings |
| `PauseMenu` | In-run pause — Resume, Settings, Abandon Run |
| `RunSummary` | Post-run — minerals collected/banked, return to Overworld |
| `LevelInfoModal` | Overworld node info panel shown before entering a planet, settlement, or station |
| `HatMenu` | Cat cosmetic hat selection screen |
| `InventoryScreen` | In-run inventory/hotbar display |
| `ChatBubble` | Ambient NPC chatter bubbles (used by ChatterManager) |
| `MenuBackground` | Animated parallax background for menus |
| `social_buttons` | Social/platform link buttons on main menu |

---

## 8. Data Flow

1. **Input:** Player movement via `CharacterBody2D` physics in `MiningLevel._physics_process`. Mining via left-click cursor within `mine_range` (4.5 tiles).
2. **Tile Interaction:**
    - Cat mines a tile → `_mine_cell()` clears it, applies `TILE_MINERALS` base value, SmeltingSystem applies chain bonuses.
    - `GameManager.add_currency(minerals)` adds to run total.
    - `EventBus.minerals_earned.emit(minerals)` triggers HUD popup.
    - FossilSystem rolls for fossil drop on each mined tile.
    - Hazard tiles deal damage or trigger explosions.
    - Energy nodes call `GameManager.restore_energy(10)`.
    - Exit Station reached → `GameManager.complete_run()` → RunSummary screen.
3. **Energy Depletion:**
    - Underground movement drains energy by depth.
    - At 0 energy → `_on_out_of_energy()` → `GameManager.lose_run()` → lose run minerals.
4. **Scout Cat (ForagerSystem):**
    - Takes 40% of each ore yield; carries up to 30 minerals (base; +20 with Kitten Den built).
    - When full, returns to surface and banks directly into `mineral_currency` (safe from death).
5. **Boss Encounters:**
    - BossSystem triggers at milestone rows (32, 64, 96, 112, 128).
    - Energy drains 2.5× while boss is alive; defeating rewards 100 minerals + 30 energy.
6. **Upgrade Purchase (Clowder Workshop):**
    - `UpgradeMenu` deducts `mineral_currency` and calls upgrade methods on `GameManager`.
    - `GameManager.save_game()` → `SaveManager` persists to `user://save_data.json`.
7. **Planet Selection:**
    - Overworld confirms a mine node → `GameManager.current_planet_color` set from `mine_metadata["color"]` → `MiningLevel._draw()` uses color for sky and gradient on next run.

---

## 9. Coding Standards

See `docs/godot_best_practices.md` for full guidelines. Key rules:
- Static typing required on all variables and function signatures
- Composition over inheritance; prefer components over deep class hierarchies
- All cross-system communication through `EventBus` signals — no direct node references across system boundaries
- No hardcoded scene paths; use constants or exported variables
- `RefCounted` for all stateless extracted systems in `src/systems/`
- `MiningLevel.gd` is ~1,970 lines — **do not add logic**; extract to `src/systems/` instead
- GUT framework for unit tests (`tests/`)
