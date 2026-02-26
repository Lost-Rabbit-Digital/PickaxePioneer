
# What is Pickaxe Pioneer?
Pickaxe Pioneer is a Terraria-style side-scrolling underground mining roguelite where you play as a red ant digging for minerals deep in the earth. Inspired by [Motherlode](https://www.miniclip.com/games/motherlode/en/) and [Supermotherlode](https://store.steampowered.com/app/269110/Super_Motherload/), the game combines physics-based movement with cursor-driven mining, depth-based risk/reward, and permanent colony upgrades between runs.

You select a mine from the overworld map, descend into procedurally generated tunnels, and dig through layers of dirt, stone, and increasingly rare ore. Fuel (energy) is finite — go too deep and you'll be stranded. Successfully surfacing banks your minerals for permanent upgrades: harden your Carapace, strengthen your Legs, sharpen your Mandibles, and refine your Mineral Sense.

The game draws design inspiration from [Dwarf Fortress](http://www.bay12games.com/dwarves/), [Path of Exile](https://store.steampowered.com/app/238960/Path_of_Exile/), [ADOM](https://www.adom.de/home/index.html), and [Noita](https://store.steampowered.com/app/881100/Noita/) — particularly their systems of *permanent progression*, *resource management*, *usage-based skill growth*, and *depth-based risk/reward*.

---

## Current Architecture (as of Feb 2026)
Understanding what's actually built prevents re-implementing or mis-scoping tasks.

**Game loop:** MainMenu → Overworld map → Mine selection modal → MiningLevel → Run Summary → Overworld

**Scenes and systems that exist:**
- `Overworld.gd` — clickable map with 1–2 randomised mine nodes, 2 settlement stubs, city node, caravan movement, ore/hazard filtering per node
- `CityLevel.gd` — banks currency on entry; minimal stub (return button only)
- `MiningLevel.gd` — 96×128 tile grid; Terraria-style CharacterBody2D physics; cursor mining; multi-hit system; fuel drain by depth; zone banners; sonar ping; smelting chains; fossil forgiveness; pheromone trails
- `RunSummary.gd` — end-of-run screen; handles mineral banking and overworld return
- `LevelInfoModal.gd` — mine info panel shown on overworld node click before entering
- `ChatterManager.gd` + `ChatBubble.gd` — ambient ant NPC chatter bubbles (flavor, tips, lore)
- `GameManager.gd` — save/load; upgrades (Carapace, Legs, Mandibles, Mineral Sense); fuel; currency; scene transitions
- `UpgradeMenu.gd` — 4 upgrade tracks with escalating mineral costs
- `HUD.gd` — health squares, segmented fuel bar, depth meter, popup system, milestone banners, low-fuel/low-hp warnings
- `StateMachine.gd` + `State.gd` — generic state machine component (used but underutilised)
- `QuestManager.gd` + `QuestNPC.gd` — quest stub (cleared on mine entry; not active)
- `FarmAnimalNPC.gd` — chicken/sheep/pig surface NPCs (pettable, no gameplay role)
- `SoundManager`, `MusicManager`, `EventBus`, `SceneTransition` — core autoloads

**Key design facts for new tasks:**
- Player movement is **Terraria-style physics** (gravity, jump, horizontal run). Not grid-based. All boss and companion designs must account for this.
- Mining is **cursor-based**: left-click within range to mine; range scales with nothing yet (mine_range is flat 4.5 tiles).
- `MapNode.NodeType.ASTEROID` is the mine node type — the name is a legacy artefact from an earlier space-themed design. The asteroids minigame no longer exists.
- Settlement nodes (`settlement_node_3`, `settlement_node_4`) exist on the overworld but have no associated scene. They are visual stubs only.
- `Legs` upgrade increases **both** max fuel capacity (+25 per level) **and** move speed (+30 px/s per level). The UpgradeMenu currently only describes the fuel half — this is a known display bug.

---

## High Priority

### Core Gameplay Depth
- [ ] **Implement single Forager Ant companion** — follows player, auto-collects minerals, auto-returns to surface when carry capacity full. This is the next step in the §3.4/§3.1 worker ant sequence. Pathfinding must follow pheromone trail data (already rendered). See docs/mining_game_design_lessons.md §3.4
- [ ] **Add underground boss encounters** — milestone rooms at specific depth rows (e.g., rows 32, 64, 96). Must be defeatable using only Terraria-style movement + fuel management + cursor-mining mandibles + existing hazard tools. No separate combat system. See docs/mining_game_design_lessons.md §4
  - *Centipede King (row 32):* multi-segment body blocks tunnels; mine around segments to isolate and collapse sections; fuel drain increased during encounter
  - *Cave Spider Matriarch (row 64):* web tiles spawn and block paths; mine or explosive-clear them; fuel death pressure
  - *The Blind Mole (row 96):* tremor AoE collapses map sections; use movement prediction and existing terrain to survive
  - *Stone Golem (row 112):* armoured phases require specific ore-type mining sequence to crack; integrates smelting-chain logic
  - *The Ancient One (row 128):* three-phase final boss layering all prior mechanics
- [ ] **Gem socketing system** — slot gems found during runs into upgrade slots for special passive effects (PoE affix inspiration). Requires gems to be collectible items, not just ore tiles with mineral value.
- [ ] **Develop colony passive skill tree** — deeper progression beyond the 4 current upgrade tracks. Current tracks (Carapace, Legs, Mandibles, Mineral Sense) are the first tier; the skill tree gates further specialisation behind milestone unlocks.

### Overworld Polish
- [ ] **Populate overworld settlement nodes** — `settlement_node_3` and `settlement_node_4` exist but lead nowhere. They should launch a small scene (trader encounter, rest stop, side quest) appropriate to their difficulty rating.
- [ ] **Wandering Trader at depth milestone rows** — appears at rows 32, 64, 96, 128 during a mine run, offering rare items and upgrades. Turns depth goals into in-world events. See docs/mining_game_design_lessons.md §2.
- [ ] **Rename `NodeType.ASTEROID` to `NodeType.MINE`** and update mine node visuals — currently uses a Godot editor icon as a placeholder sprite.

### Known Display Bug
- [ ] **Fix Legs upgrade description in UpgradeMenu** — button text only mentions fuel capacity increase. It also increases move speed (+30 px/s per level). Both effects should be shown.

---

## Medium Priority

### Progression Systems
- [ ] **Implement Colony Chamber system** — buildable rooms in the Colony hub unlocked by milestones, each providing a passive run-wide bonus. Drip-feed unlock timing to avoid early overwhelm. See docs/mining_game_design_lessons.md §3.8
  - *Fungus Garden* (500 minerals banked): +10% mineral yield from all tiles
  - *Brood Chamber* (first boss defeated): worker ant slots +2; workers recover faster after death
  - *Armory* (1000 minerals banked): soldier ants deal 2× damage; explosive radius +1 tile
  - *Nursery Vault* (10 fossils): fossil drop rate +15%; new fossil types enabled
  - *Deep Antenna Array* (reach row 96): sonar ping radius +3 tiles at all tiers
  - *Royal Archive* (25 fossils): lore fragments unlock; Archivist gives bounties
  - *Queen's Sanctum* (all upgrade tracks at level 5): unlock Tier 3 Research Tree
- [ ] **Expand worker ant system to profession types** — Scout, Engineer, Soldier — after Forager companion is stable. Requires pheromone trail data (done) + zone assignment. Do not implement before Forager is working. See docs/mining_game_design_lessons.md §3.1
- [ ] **Make some fossils discoverable only via specific mining patterns** — not random drops. Examples: a 2×3 cluster of gem tiles, mining three fuel nodes in sequence. Rewards attentive play. See docs/mining_game_design_lessons.md §3.6

### World and Environment
- [ ] **Add random open cave rooms** — occasional larger hollow chambers with concentrated ore pockets. Breaks up the uniform tile density and rewards exploration.
- [ ] **Add tools that reduce specific hazards** — consumables or upgrades that counter lava (fire-resistant gel), explosives (blast dampener), etc. Expands build diversity.
- [ ] **Implement a dynamic weather system affecting surface layers** — rain softens topsoil tile hardness; heat bakes stone. Scoped to the surface zone (rows 0–15) to limit implementation scope.

---

## Low Priority

### Economy and NPC
- [ ] **Allow selling ore types individually or in batches to different NPCs** — overworld settlement traders buy specific ore types at premium prices, creating routing decisions.
- [ ] **Add a gambling mini-game** — bet run minerals on ore quality predictions at a settlement. Small scope, adds texture to overworld stops.
- [ ] **Implement ant appearance customisation** — carapace colour, mandible shape. Purely cosmetic; can be unlocked through fossil collection or milestone rewards.

### Colony Workshop Expansion
- [ ] **Expand Colony Workshop** — add Fuel Sac upgrade track (fuel capacity, separate from Legs which currently handles both speed and fuel). Decoupling these into separate tracks gives the player more meaningful choice.

### Polish
- [ ] **Create a splash screen for Lost Rabbit using Splashy** — branding task, low gameplay impact.
- [ ] **QuestManager integration** — `QuestManager.gd` and `QuestNPC.gd` exist but are cleared on mine entry and serve no active function. Either connect them to real quest data or remove the dead code.

---

## Ongoing Improvements

- [ ] **Extract MiningLevel.gd into focused subsystems** — the file is approaching 1,200 lines. Mining logic, rendering, UI setup, and surface hub are all in one class. Priority extraction targets: `SmeltingSystem`, `FossilSystem`, `SonarSystem`, each as standalone scripts called from MiningLevel.
- [ ] **Activate the existing StateMachine component in MiningLevel** — `StateMachine.gd` and `State.gd` exist but MiningLevel uses ad-hoc `_hub_visible / _game_over / _fuel_shop_visible` flags instead. Migrating would clean up the `_process` guard chain significantly.
- [ ] **Fix the "No fuel for ping" popup** — currently emits `ore_mined_popup(0, "No fuel for ping")` which shows "+0 No fuel for ping". It should use a dedicated HUD notification path, not the mineral popup system.

---

## Bugs to Fix

- [x] Investigate and fix menu music playing in-game after resetting save data
- [x] Resolve intermittent mining system failures

---

## Shelved / Far Future
*These ideas have merit but are out of scope until the core loop is polished and the game is approaching a shippable state. Keeping them here prevents re-adding them to active lists.*

- **Multiplayer co-op** — two ants in the same mine. Requires independent fuel pools per player (Super Motherload lesson). No engine infrastructure for this yet.
- **Rival ant colonies competing for mine shafts** — needs AI opponent system and overworld territory logic.
- **User-run mining consortiums (guilds)** — shared colony resource tracking across players. Requires server infrastructure.
- **Connect Steamworks API** — achievements, chat overlays. Appropriate once the game is on Steam.
- **NoobHub with AWS Lambda for global colony chat** — server infrastructure; not needed for a single-player prototype.
- **Day/night cycle** — the game is set underground; the surface is 3 rows. The gameplay impact does not justify the scope.
- **Implement territory control** — claim mine nodes for passive income. Overworld needs to be much more developed first.
- **Alchemy system** — distil rare minerals into colony buffs. Needs harvestable fungi/roots tile types first, which don't exist.
- **Harvestable fungi and roots** — requires new tile types, art, and collection mechanics.
- **Introduce rival ant colonies competing** — needs AI pathfinding and contested-resource systems.
- **Cargo/abdomen capacity** — separate carry limit on top of fuel. The design doc (§3.7) explicitly defers this until after the Forager Ant is implemented; the Forager changes the risk calculus entirely.
- **ADOM-style overworld with cavern networks** — an overworld exists; cavern networks connecting mine nodes would be a major structural redesign.

---

## Ideas for Future Consideration
*Rough ideas worth remembering but not yet scoped.*

- [ ] Create story-driven quests from the Queen with cliffhangers
- [ ] Implement a fossil and rare mineral museum for collection rewards — ties into fossil forgiveness system
- [ ] Create colony-driven economies with ant-to-ant mineral trading
- [x] Add special event mines with boosted ore richness for limited times
- [ ] Pet/companion system — a non-ant creature (beetle, springtail) that provides a passive bonus distinct from worker ants. Lower scope than the full worker ant system.
- [ ] Fishing/foraging mini-game on the surface between runs — requires surface content expansion first
