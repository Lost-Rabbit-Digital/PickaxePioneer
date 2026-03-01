# Pickaxe Pioneer — CLAUDE.md

## WHY — What This Project Is

**Pickaxe Pioneer** is a 2D Terraria-style underground mining roguelite built in Godot 4.5.
The player is a **mining cat** from the **Clowder** — a feline civilization that mines for
minerals deep underground. Inspired by Motherload / Super Motherload.

- **Genre:** Mining roguelite (side-scrolling, physics-based)
- **Core loop:** Overworld map → mine run → bank minerals → buy permanent upgrades → repeat
- **Platforms:** Steam (Windows/Linux/Mac) + Itch.io | **Price:** $3–5
- **Engine:** Godot 4.5 | **Language:** GDScript (static typing required, no C#)
- **Addons:** GUT (unit testing framework)

**Mandatory terminology** — use these exclusively in all code strings, comments, and docs:

| Concept | Correct Term | Never Use |
|---------|-------------|-----------|
| Player character | Mining Cat / Cat | Ant, Red Ant |
| Hub world | Clowder / The Clowder | Colony, Anthill |
| HP upgrade | Pelt | Carapace, Spacesuit |
| Speed/energy upgrade | Paws | Legs, Jet Boots |
| Mining power upgrade | Claws | Mandibles, Pickaxe (as upgrade name) |
| Sonar upgrade | Whiskers | Mineral Sense, Antennae |
| Companion | Scout Cat | Forager Ant |
| Faction leader NPC | Matriarch | Queen |
| Overworld map | Clowder Warren | Anthill Map |

---

## WHAT — Project Layout

```
res://
├── assets/           # Art, Audio, Fonts
├── docs/             # Design docs (GDD, architecture, best practices)
├── notes/            # Living development backlog (development_notes.md)
├── src/
│   ├── autoload/     # Global singletons (all registered in project.godot)
│   ├── components/   # Reusable node components
│   ├── entities/     # Game objects (player, NPCs, loot, overworld tokens)
│   ├── levels/       # Scene controllers (Overworld, MiningLevel, CityLevel, SettlementLevel)
│   ├── systems/      # Extracted subsystems (RefCounted classes)
│   └── ui/           # UI controllers
└── tests/            # GUT unit tests
```

### Autoloads (registered singletons)

| Autoload | File | Responsibility |
|----------|------|----------------|
| `GameManager` | `src/autoload/GameManager.gd` | Game state, save/load, mineral currency, upgrade levels, energy |
| `EventBus` | `src/autoload/EventBus.gd` | Global signal bus — all cross-system communication goes here |
| `SoundManager` | `src/autoload/SoundManager.gd` | Procedural SFX via AudioStreamGenerator |
| `MusicManager` | `src/autoload/MusicManager.gd` | Adaptive music with scene crossfading |
| `SettingsManager` | `src/autoload/SettingsManager.gd` | Graphics, audio, controls, accessibility |
| `SceneTransition` | `src/autoload/SceneTransition.gd` | Animated scene transitions |
| `SaveManager` | `src/autoload/SaveManager.gd` | Save/load coordination (JSON → `user://save_data.json`) |
| `QuestManager` | `src/autoload/QuestManager.gd` | Quest stub — not yet active (cleared on mine entry) |

### Key EventBus signals

`game_state_changed(new_state)` · `minerals_changed(amount)` · `minerals_earned(amount)` ·
`energy_changed(current, max)` · `player_health_changed(current, max)` · `player_died`

### Key Systems (`src/systems/` — all `RefCounted`)

| System | Responsibility |
|--------|---------------|
| `SmeltingSystem.gd` | Consecutive ore chain bonuses and alloy combos |
| `FossilSystem.gd` | Fossil drops with forgiveness/pity counter |
| `SonarSystem.gd` | Sonar ping — radial ore shimmer, energy cost per use |
| `ForagerSystem.gd` | Scout Cat companion — 40% ore yield, auto-banks at 30 minerals |
| `BossSystem.gd` | Five depth-milestone boss encounters |
| `BossRenderer.gd` | Draw calls for BossSystem (separated for MiningLevel cleanliness) |
| `ChatterManager.gd` | Ambient cat NPC chatter bubble text pool |
| `MiningTerrainGenerator.gd` | Procedural tile grid generation (extracted from MiningLevel) |
| `TraderSystem.gd` | Wandering Trader at milestone depth rows |
| `CatSystem.gd` | Cat-specific behaviors and stat helpers |

### Critical MiningLevel facts

- Grid: **96 columns × 128 rows** at 64 px/tile
- Player movement: **Terraria-style physics** (gravity, jump, horizontal run) — NOT grid-based
- Mining: **cursor-based** left-click within 4.5-tile `mine_range`
- `MapNode.NodeType` enum: `EMPTY(0)`, `MINE(1)`, `STATION(2)`, `SETTLEMENT(3)`
- `MiningLevel.gd` is ~1,970 lines; do not add logic — extract to `src/systems/` instead
- Bosses trigger at rows: **32, 64, 96, 112, 128** (energy drains 2.5× during boss)
- Boss names: Giant Rat King · Cave Spider Matriarch · Blind Mole · Stone Golem · The Ancient Hound

### Input map actions (defined in project.godot)

`move_left` · `move_right` · `jump` · `mine` (left-click) · `sonar_ping` (Q) ·
`pheromone_marker` (F) · `interact` (E) · `pause` (Esc)

---

## HOW — Build, Run, and Verify

**Run the game:** Open `project.godot` in Godot 4.5, press F5.

**Run tests:** `Godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/`
(or use the GUT panel in the editor)

**Export:** Project → Export → select Windows/Linux/Mac preset.

**Verify a change works:**
1. Open the affected scene in the editor
2. Run the game (F5), navigate to the changed feature
3. If logic change: write or update a GUT test in `tests/`

**Branch strategy:** Feature branches off `main`, named `feature/short-description`.
PRs require at least one review before merge.

**Commit style:** Imperative present tense, 50-char subject.
`Fix Scout Cat banking when carry cap upgraded`

**Code standards:** See `docs/godot_best_practices.md`.
TL;DR: static typing everywhere, EventBus for cross-system signals, composition over
inheritance, no hardcoded scene paths, `RefCounted` for stateless systems.

**Documentation to consult:**
- `docs/game_design_document.md` — full GDD (note: GDD body is being updated to cat theme; some ant terminology remains — ignore it, follow this file's terminology table instead)
- `docs/architecture.md` — system design and data flow
- `notes/development_notes.md` — living task backlog and current architecture snapshot
- `development_tasks.md` — cat theme pivot task list (ant → cat rename work)
