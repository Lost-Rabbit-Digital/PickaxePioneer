# Pickaxe Pioneer

A 2D Terraria-style underground mining roguelite where you play as a red ant digging for minerals deep in the earth.

**Engine:** Godot 4.5 | **Genre:** Mining Roguelite | **Target:** Steam / Itch.io ($3–5)

---

## Concept

You are a red forager ant venturing out from your colony into the earth below. Each expedition takes you deeper underground through procedurally generated layers of dirt, stone, and precious ore. Manage your fuel carefully — go too deep without energy and you'll be stranded. Mine rare gems from the deepest veins, upgrade your Carapace, Legs, Mandibles, and Mineral Sense back at the colony, and unravel the mysteries buried beneath the surface.

Inspired by [Motherload](https://www.miniclip.com/games/motherlode/en/), [Super Motherload](https://store.steampowered.com/app/269110/Super_Motherload/), [Dwarf Fortress](http://www.bay12games.com/dwarves/), [Path of Exile](https://store.steampowered.com/app/238960/Path_of_Exile/), [ADOM](https://www.adom.de/home/index.html), and [Noita](https://store.steampowered.com/app/881100/Noita/).

---

## Gameplay Loop

1. **Colony (Hub)** — Bank minerals, purchase permanent upgrades (Carapace / Legs / Mandibles / Mineral Sense), talk to NPCs
2. **Overworld Map** — Navigate between mine entrances, settlement rest stops, and the colony
3. **Settlement** — Spend banked minerals on pre-run consumables (Fuel Cache, Field Repair, Mining Shroom, Whetstone)
4. **Mining Run** — Descend into a 96×128-tile procedural mine; Terraria-style physics; cursor-based mining; fuel depletes with depth; sonar ping, smelting chains, fossil finds, boss encounters
5. **Run Summary** — Bank collected minerals on successful exit; lose run minerals if fuel runs out or HP hits 0

---

## Controls

| Action | Input |
|--------|-------|
| Move | `WASD` / Arrow Keys |
| Jump | `W` / `Up Arrow` / `Space` |
| Mine tile | Left-click (within 4.5-tile range) |
| Sonar ping | `Q` |
| Pheromone marker | `F` |
| Interact / Refuel | `E` |
| Pause | `Esc` |

---

## Project Structure

```
res://
├── assets/                 # Art, Audio, Fonts
├── docs/                   # Design documentation
│   ├── architecture.md          — system design reference
│   ├── game_design_document.md  — full GDD (mechanics, world, story)
│   ├── godot_best_practices.md  — coding standards
│   └── mining_game_design_lessons.md — genre research & design decisions
├── notes/
│   └── development_notes.md     — task list & current architecture snapshot
└── src/
    ├── autoload/           # Global singletons (GameManager, EventBus, SoundManager, …)
    ├── components/         # Reusable node components (HealthComponent, StateMachine, …)
    ├── entities/           # Game objects (PlayerProbe, MapNode, Caravan, NPCs, loot)
    ├── levels/             # Scenes (Overworld, MiningLevel, CityLevel, SettlementLevel)
    ├── systems/            # Extracted subsystems (SmeltingSystem, FossilSystem, SonarSystem, ForagerSystem, BossSystem)
    └── ui/                 # Interface (HUD, MainMenu, UpgradeMenu, RunSummary, …)
```

---

## Key Systems

| System | File | Description |
|--------|------|-------------|
| GameManager | `src/autoload/GameManager.gd` | Game state, save/load, mineral currency, upgrade levels, fuel |
| EventBus | `src/autoload/EventBus.gd` | Global signal bus for decoupled communication |
| MiningLevel | `src/levels/MiningLevel.gd` | Core gameplay — physics movement, cursor mining, grid world, all run logic |
| SmeltingSystem | `src/systems/SmeltingSystem.gd` | Consecutive ore chain bonuses and alloy combos |
| FossilSystem | `src/systems/FossilSystem.gd` | Fossil drops with forgiveness pity mechanic |
| SonarSystem | `src/systems/SonarSystem.gd` | Sonar ping — radial ore detection through solid rock |
| ForagerSystem | `src/systems/ForagerSystem.gd` | Forager ant companion — auto-collects ore, banks when full |
| BossSystem | `src/systems/BossSystem.gd` | Boss encounter logic for all five depth-milestone bosses |
| UpgradeMenu | `src/ui/UpgradeMenu.gd` | Colony Workshop — 4 upgrade tracks with escalating costs |
| HUD | `src/ui/HUD.gd` | In-run display — minerals, health, fuel bar, depth meter, banners |

---

## Upgrade Tracks

| Track | Effect per Level | Base Cost |
|-------|-----------------|-----------|
| Harden Carapace | +1 max HP | 50 minerals |
| Strengthen Legs | +30 px/s move speed **and** +25 max fuel | 50 minerals |
| Sharpen Mandibles | +3 mining power | 50 minerals |
| Mineral Sense | Larger sonar ping radius, lower fuel cost per ping | 50 minerals |

All tracks scale by +25 minerals per level; max level 10.

---

## Bosses

Five depth-milestone encounters, all defeated using the player's existing tools (no separate combat system):

| Boss | Depth Row | Mechanic |
|------|-----------|----------|
| Centipede King | 32 | Mine through segments to destroy the core |
| Cave Spider Matriarch | 64 | Mine web segments to reach the core |
| The Blind Mole | 96 | Dodge tremor AoE collapses, use warning overlay |
| Stone Golem | 112 | Break armor phases by last-mining the required ore type |
| The Ancient One | 128 | Three-phase final boss (pending) |

---

## Documentation

- **[Game Design Document](docs/game_design_document.md)** — full mechanics, world design, story, progression
- **[Architecture](docs/architecture.md)** — code structure, patterns, data flow
- **[Godot Best Practices](docs/godot_best_practices.md)** — coding standards for this project
- **[Mining Game Design Lessons](docs/mining_game_design_lessons.md)** — genre research and design decisions
- **[Development Notes](notes/development_notes.md)** — task backlog and architecture snapshot

---

## Development

Built with **Godot 4.5**. Open `project.godot` to get started.

```
Lost Rabbit Digital
```
