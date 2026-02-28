
# What is Pickaxe Pioneer?
Pickaxe Pioneer is a Terraria-style side-scrolling underground mining roguelite where you play as a mining cat digging for minerals deep in the earth. Inspired by [Motherlode](https://www.miniclip.com/games/motherlode/en/) and [Supermotherlode](https://store.steampowered.com/app/269110/Super_Motherload/), the game combines physics-based movement with cursor-driven mining, depth-based risk/reward, and permanent Clowder upgrades between runs.

You select a mine from the overworld map, descend into procedurally generated tunnels, and dig through layers of dirt, stone, and increasingly rare ore. Energy is finite — go too deep and you'll be stranded. Successfully surfacing banks your minerals for permanent upgrades: thicken your Pelt, strengthen your Paws, sharpen your Claws, and refine your Whiskers.

The game draws design inspiration from [Dwarf Fortress](http://www.bay12games.com/dwarves/), [Path of Exile](https://store.steampowered.com/app/238960/Path_of_Exile/), [ADOM](https://www.adom.de/home/index.html), and [Noita](https://store.steampowered.com/app/881100/Noita/) — particularly their systems of *permanent progression*, *resource management*, *usage-based skill growth*, and *depth-based risk/reward*.

---

## Current Architecture (as of Feb 2026)
Understanding what's actually built prevents re-implementing or mis-scoping tasks.

**Game loop:** MainMenu → Overworld map → Mine/Settlement/City selection modal → MiningLevel (or SettlementLevel / CityLevel) → Run Summary → Overworld

**Scenes and systems that exist:**
- `Overworld.gd` — clickable map with 1–2 randomised mine nodes, 2 settlement nodes, city node, caravan movement, ore/hazard filtering per mine node
- `CityLevel.gd` — banks currency on entry; hosts UpgradeMenu; minimal stub (return button only)
- `SettlementLevel.gd` — rest stop between runs; spends banked `mineral_currency` on 4 pre-run consumables: Energy Cache (+50 starting energy), Forager Rations (+20 forager carry cap), Mining Shroom (12 ore-yield charges), Claw Whetstone (+1 claw power). Bonuses persist via `GameManager` settlement fields, applied on mine entry and cleared.
- `MiningLevel.gd` — 96×128 tile grid; Terraria-style CharacterBody2D physics; cursor mining; multi-hit system; energy drain by depth; zone banners; sonar ping; smelting chains; fossil forgiveness; pheromone trails; wandering trader; scout cat companion; random cave rooms
- `RunSummary.gd` — end-of-run screen; handles mineral banking and overworld return
- `LevelInfoModal.gd` — location info panel shown on overworld node click before entering
- `ChatterManager.gd` + `ChatBubble.gd` — ambient cat NPC chatter bubbles (flavor, tips, lore)
- `GameManager.gd` — save/load; upgrades (Pelt, Paws, Claws, Whiskers); energy; currency; scene transitions; settlement carry-over fields
- `UpgradeMenu.gd` — 4 upgrade tracks with escalating mineral costs
- `HUD.gd` — health squares, segmented energy bar, depth meter, popup system, milestone banners, low-energy/low-hp warnings
- `StateMachine.gd` + `State.gd` — generic state machine component (used but underutilised)
- `QuestManager.gd` + `QuestNPC.gd` — quest stub (cleared on mine entry; not active)
- `FarmAnimalNPC.gd` — chicken/sheep/pig surface NPCs (pettable, no gameplay role)
- `SoundManager`, `MusicManager`, `EventBus`, `SceneTransition` — core autoloads

**Key design facts for new tasks:**
- Player movement is **Terraria-style physics** (gravity, jump, horizontal run). Not grid-based. All boss and companion designs must account for this.
- Mining is **cursor-based**: left-click within range to mine; `mine_range` is flat 4.5 tiles.
- `MapNode.NodeType` has four values: `EMPTY` (0), `MINE` (1), `STATION` (2), `SETTLEMENT` (3). Settlement nodes load `SettlementLevel.tscn`; mine nodes load `MiningLevel.tscn`; city loads `CityLevel.tscn`.
- `Legs` upgrade increases **both** max energy capacity (+25/level) **and** move speed (+30 px/s per level).
- The **Scout Cat** is a programmatic entity rendered in `MiningLevel._draw()` — not a separate scene. It takes 40% of ore yield, carries up to 30 minerals (base), returns to surface and banks directly into `mineral_currency` when full.
- **Cave rooms** are generated via `_generate_cave_rooms()` after `_generate_grid()` each run: 6–10 elliptical open chambers with ore-rich walls scaled to depth.
- `MiningLevel.gd` is now ~1,970 lines. All planned subsystem extractions are complete: `SmeltingSystem`, `FossilSystem`, `SonarSystem`, `ForagerSystem`, and `BossSystem` all live in `src/systems/` as `RefCounted` classes.

---

## High Priority

### Core Gameplay Depth
- [x] **Implement single Scout Cat companion** — follows player, auto-collects 40% of ore yield, returns to surface when carry capacity (30 minerals) is full, deposits directly to banked `mineral_currency` (safe from death). Rendered as amber circle with carry bar in MiningLevel._draw(). See docs/mining_game_design_lessons.md §3.4
- [x] **Add underground boss encounters** — milestone rooms at specific depth rows. No separate combat system; defeated using existing mining tools. Energy drains 2.5× while a boss is alive; defeating one rewards 100 minerals + 30 energy. See docs/mining_game_design_lessons.md §4
  - *Giant Rat King (row 32):* [x] two-row horizontal body (12 segments + core); mine through the body to reach and destroy the core; energy pressure increases during encounter
  - *Cave Spider Matriarch (row 64):* [x] diamond/cross pattern body spawned below player; mine segments to reach and destroy the core
  - *The Blind Mole (row 96):* [x] tremor AoE collapses nearby empty tiles; warning overlay telegraphs incoming tremor; brown screen-edge pulse on warning
  - *Stone Golem (row 112):* [x] three ore-phase armor (copper → iron → gold); resists damage until player last-mined the required ore; phase label drawn near core; ARMOR CRACKED banner on phase advance
  - *The Ancient Hound (row 128):* [x] three-phase final boss — Phase 1: outer stone-shell ring (12 segments, teal); Phase 2: crystalline inner ring (8 segments, purple) with periodic void pulses that reseal mined tunnels; Phase 3: exposed core (white/gold) that regenerates every 8 s if not mined down quickly. 2× energy drain throughout.
- [x] **Gem socketing system** — ORE_GEM/ORE_GEM_DEEP tiles now award 1–2 gem items immediately on mining (primary value; mineral yield reduced to 5/8). `GameManager.gem_count` tracks stockpile. Four permanent gem socket slots in UpgradeMenu (cost: 3 gems each): Fur Gem (+1 Max HP), Swift Paw Gem (+25 Energy, +15 Speed), Razor Claw Gem (+4 Mining Power), Whisker Gem (+3 Sonar Radius). Socketed bonuses apply via updated stat getters; saved/loaded with game data.
- [x] **Develop Clowder passive skill tree** — Clowder Chamber system (see Medium Priority) provides the first tier of milestone-gated passive progression: 5 buildable rooms with distinct run-wide bonuses, each unlocked by a gameplay milestone. Gem socketing adds a second orthogonal layer (4 socket slots across upgrade tracks).

### Overworld Polish
- [x] **Populate overworld settlement nodes** — `settlement_node_3` and `settlement_node_4` now launch `SettlementLevel.tscn`. Players spend banked minerals on Energy Cache (+50 starting energy), Pelt Patch (+1 HP), Mining Shroom (12 charges), and Claw Whetstone (+1 claw power). Bonuses persist via `GameManager` into the next mine run.
- [x] **Wandering Trader at depth milestone rows** — appears at rows 32, 64, 96, 128 during a mine run, offering tier-scaled items (Energy Cache, Pelt Patch, Mining Shroom, Lucky Compass, Ancient Map). Turns depth goals into in-world events. See docs/mining_game_design_lessons.md §2.
- [x] **Rename `NodeType.ASTEROID` to `NodeType.MINE`** and update mine node visuals — now uses the cat_miner sprite with a gold tint instead of the Godot editor icon.

### Known Display Bug
- [x] **Fix Legs upgrade description in UpgradeMenu** — button now shows both energy capacity and move speed increases.

---

## Medium Priority

### Progression Systems
- [x] **Implement Colony Chamber system** — buildable rooms in the Colony hub, each gated behind milestone conditions. UI panel in CityLevel shows locked/unlocked/built state per chamber. `GameManager` tracks total minerals banked, bosses defeated, fossils found, and deepest row for unlock checks. Five chambers implemented:
  - *Fungus Garden* (500 minerals banked, cost 200): +10% mineral yield from all tiles (via `get_mineral_yield_mult()`)
  - *Brood Chamber* (first boss defeated, cost 150): Forager carry cap +20 (via `get_forager_carry_bonus()`)
  - *Armory* (1000 minerals banked, cost 300): explosive blast radius +1 tile (via `get_explosive_radius_bonus()`)
  - *Nursery Vault* (10 fossils found, cost 250): +5% fossil base find rate (via `get_fossil_rate_bonus()`)
  - *Deep Antenna Array* (reach row 96, cost 200): sonar ping radius +3 (via updated `get_sonar_ping_radius()`)
  - *Royal Archive* / *Queen's Sanctum*: deferred — require content (lore system, Tier 3 Research Tree) not yet built.
- [ ] **Expand Scout Cat system to profession types** — Hunter, Digger, Lookout — after Forager companion is stable. Requires pheromone trail data (done) + zone assignment. Do not implement before Forager is working. See docs/mining_game_design_lessons.md §3.1
- [ ] **Make some fossils discoverable only via specific mining patterns** — not random drops. Examples: a 2×3 cluster of gem tiles, mining three energy nodes in sequence. Rewards attentive play. See docs/mining_game_design_lessons.md §3.6

### World and Environment
- [x] **Add random open cave rooms** — 6–10 elliptical chambers per run carved into the underground grid, with ore-rich walls scaled to depth (iron/copper in shallow zones, gold/gem deep). Implemented via `_generate_cave_rooms()` in MiningLevel after initial grid generation.
- [ ] **Add tools that reduce specific hazards** — consumables or upgrades that counter lava (fire-resistant gel), explosives (blast dampener), etc. Expands build diversity.
- [ ] **Implement a dynamic weather system affecting surface layers** — rain softens topsoil tile hardness; heat bakes stone. Scoped to the surface zone (rows 0–15) to limit implementation scope.

---

## Low Priority

### Economy and NPC
- [ ] **Allow selling ore types individually or in batches to different NPCs** — overworld settlement traders buy specific ore types at premium prices, creating routing decisions.
- [ ] **Add a gambling mini-game** — bet run minerals on ore quality predictions at a settlement. Small scope, adds texture to overworld stops.
- [ ] **Implement cat appearance customisation** — fur colour, pattern, collar unlocks. Purely cosmetic; can be unlocked through fossil collection or milestone rewards.

### Colony Workshop Expansion
- [ ] **Expand Colony Workshop** — add Energy Sac upgrade track (energy capacity, separate from Legs which currently handles both speed and energy). Decoupling these into separate tracks gives the player more meaningful choice.

### Polish
- [ ] **Create a splash screen for Lost Rabbit using Splashy** — branding task, low gameplay impact.
- [ ] **QuestManager integration** — `QuestManager.gd` and `QuestNPC.gd` exist but are cleared on mine entry and serve no active function. Either connect them to real quest data or remove the dead code.

---

## Ongoing Improvements

- [x] **Extract MiningLevel.gd into focused subsystems** — `SmeltingSystem.gd`, `FossilSystem.gd`, `SonarSystem.gd`, `ForagerSystem.gd`, and `BossSystem.gd` all extracted to `src/systems/` as standalone `RefCounted` classes with clean interfaces; MiningLevel delegates to them via public state reads (for draw) and method calls. MiningLevel reduced from ~2300 to ~1970 lines.
- [ ] **Activate the existing StateMachine component in MiningLevel** — `StateMachine.gd` and `State.gd` exist but MiningLevel uses ad-hoc `_hub_visible / _game_over / _energy_shop_visible` flags instead. Migrating would clean up the `_process` guard chain significantly.
- [x] **Fix the "No energy for ping" popup** — HUD now omits the "+0" prefix when `amount == 0`, treating it as a pure notification string.

---

## Bugs to Fix

- [x] Investigate and fix menu music playing in-game after resetting save data
- [x] Resolve intermittent mining system failures

---

## Shelved / Far Future
*These ideas have merit but are out of scope until the core loop is polished and the game is approaching a shippable state. Keeping them here prevents re-adding them to active lists.*

- **Multiplayer co-op** — two cats in the same mine. Requires independent energy pools per player (Super Motherload lesson). No engine infrastructure for this yet.
- **Rival cat clowders competing for mine shafts** — needs AI opponent system and overworld territory logic.
- **User-run mining consortiums (guilds)** — shared clowder resource tracking across players. Requires server infrastructure.
- **Connect Steamworks API** — achievements, chat overlays. Appropriate once the game is on Steam.
- **NoobHub with AWS Lambda for global colony chat** — server infrastructure; not needed for a single-player prototype.
- **Day/night cycle** — the game is set underground; the surface is 3 rows. The gameplay impact does not justify the scope.
- **Implement territory control** — claim mine nodes for passive income. Overworld needs to be much more developed first.
- **Alchemy system** — distil rare minerals into colony buffs. Needs harvestable fungi/roots tile types first, which don't exist.
- **Harvestable fungi and roots** — requires new tile types, art, and collection mechanics.
- **Introduce rival cat clowders competing** — needs AI pathfinding and contested-resource systems.
- **Cargo/abdomen capacity** — separate carry limit on top of energy. The design doc (§3.7) explicitly defers this until after the Forager Ant is implemented; the Forager changes the risk calculus entirely.
- **ADOM-style overworld with cavern networks** — an overworld exists; cavern networks connecting mine nodes would be a major structural redesign.

---

## Ideas for Future Consideration
*Rough ideas worth remembering but not yet scoped.*

- [ ] Create story-driven quests from the Matriarch with cliffhangers
- [ ] Implement a fossil and rare mineral museum for collection rewards — ties into fossil forgiveness system
- [ ] Create clowder-driven economies with cat-to-cat mineral trading
- [x] Add special event mines with boosted ore richness for limited times
- [ ] Pet/companion system — a non-cat creature (mouse, bird) that provides a passive bonus distinct from the Scout Cat. Lower scope than the full Scout Cat system.
- [ ] Fishing/foraging mini-game on the surface between runs — requires surface content expansion first
