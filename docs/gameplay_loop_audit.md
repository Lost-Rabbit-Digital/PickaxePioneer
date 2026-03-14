# Pickaxe Pioneer — Gameplay Loop & First 10 Minutes Audit

**Date:** 2026-03-10
**Auditor:** Claude (Game Design + Godot Dev Audit)
**Version audited:** v0.3.5 (cat-themed)
**Engine:** Godot 4.5 | GDScript

---

## Context

**Genre:** 2D side-scrolling mining roguelite (Motherload/Super Motherload lineage)
**Core Mechanic:** Cursor-based mining with Terraria-style physics, energy-as-fuel risk/reward
**Target Audience:** Indie roguelite fans, Motherload nostalgists, players who enjoy short-session progression loops. Price point $3-5 suggests casual-to-mid-core players seeking 5-12 hours of content.

---

## Part 1: The 2-Minute Core Loop

### 1A: Identify the Loop

**Intended core loop (from GDD):**
> Star Chart -> land on planet -> mine run -> bank minerals -> buy upgrades -> next planet

This is the *macro* loop (10-30 minutes). The *micro* loop — the atomic unit of fun — is the mining run itself.

**Actual core loop (from code):**
The implemented micro loop maps to:

```
[OBSERVE]  Scan terrain — see ore colors, depth meter, energy bar, sonar ping results
    |
[DECIDE]  Pick a direction: mine left/right/down; use sonar; risk going deeper vs. surface to bank
    |
[ACT]     Click to mine tiles; move/jump to reposition; Q to sonar ping
    |
[OUTCOME] Ore collected (HUD popup + currency), energy drains, tile breaks (particles + shake + sound)
    |
[OBSERVE] ...updated game state (less energy, more minerals, new terrain revealed)
```

**Do they match?** Largely yes. The micro-loop is well-implemented. The *macro* loop has a gap: the Overworld and City (Clowder hub) feel like menus rather than places with agency. The GDD envisions NPCs, quests, mission boards, and relationship systems — most are stubs or absent. The hub is currently two info panels (Perk Tree + Spaceship Upgrades) without spatial exploration. The settlement is closer to the vision but gated behind progression.

### 1B: Evaluate Each Phase

#### OBSERVE — How does the player read the game state?

**HUD elements present:**
- Upper-left: Ore capacity (slots X/20), depth meter ("Orbit" / "Depth: Xm"), coins counter
- Upper-right: Energy bar (10 segments, green->red), health bars (red chambers)
- Bottom-center: 10-slot hotbar (pickaxe slot 1, ladders slot 2)
- Dynamic overlays: ore pickup popups (left, colored), low-energy warning (pulsing red), low-HP warning, boss hint panel, depth milestone banners, exit hint arrow

**Readability issues:**
- **Tile differentiation relies heavily on color.** Copper, iron, gold, gem ores need distinct silhouettes or symbols for colorblind players. Three colorblind modes exist in SettingsManager but tile art itself may still be ambiguous.
- **Energy bar is small (10 segments, upper-right).** At 1280x720, this critical survival resource could be missed by new players focused on the center of the screen.
- **No minimap.** For a 96x128 grid (6,144x8,192 px), players can easily lose orientation. Sonar partly compensates but costs energy.
- **Depth meter is text-only** ("Depth: 200m" in upper-left). A visual sidebar showing depth relative to boss rows / resource tiers would add strategic information.

**Audio/visual cues for state changes:**
- Energy low warning sound at 25% threshold — good
- Health damage sound + screen shake — good
- Ore pickup has pop sounds (3 variations) — good
- Boss stinger on encounter — good
- Depth zone banners with sound — good
- **Missing:** No audio cue when energy is draining (ambient hum/beep that intensifies with depth). No heartbeat or tension sound as HP gets low.

**Score: 6/10** — Core info is visible but could be more readable. Missing minimap and ambient tension audio.

#### DECIDE — Does the player have meaningful choices?

**Options at any moment during mining:**
1. Which tile to mine (directional choice — left/right/down/up affects depth and ore access)
2. Whether to go deeper (richer ore but more energy drain, more hazards)
3. Whether to use sonar ping (spend energy now for information)
4. Whether to surface and bank (safety vs. greed)
5. Whether to use ladders (vertical mobility vs. limited supply)
6. Whether to sprint (speed vs. energy cost)
7. How to handle bosses (engage vs. descend past)
8. When to use the reenergy station (spend minerals to refill energy)

**Quality of choices:**
- **The depth-vs-safety tension is excellent.** This is the core risk/reward and it works. Energy drain scaling with depth (0.25 + depth_ratio * 0.5 per second) creates genuine pressure.
- **Sonar is a good information-for-resources trade.** Costs energy, reveals ore — meaningful.
- **Smelting chains add a secondary optimization layer** — mining same-ore consecutively for bonuses rewards deliberate pathing.
- **Boss encounters (50% spawn chance) add unpredictability.** The "do I fight or go around" choice is interesting.
- **Weakness:** Early game (rows 0-30) has low decision density. Mostly dirt/stone, few ores, minimal hazards. The first 2-3 minutes of mining feel like "just dig down."

**Score: 7/10** — Strong risk/reward core. Early game lacks decision density.

#### ACT — Does acting feel good?

**Input-to-response:**
- Mining interval: 0.21s between hits — responsive but not instant. Tiles can take 1-3 hits depending on type and mining power.
- Movement uses `_physics_process` (60Hz tick) — standard and responsive.
- Pickaxe throw animation: 0.06-0.18s tween from player to tile — adds visual weight without delay.

**Juice inventory:**
- Screen shake on mine hit (1.5 intensity, 0.07s) — subtle and correct
- Screen shake on explosion (12.0, 0.55s) — dramatic and impactful
- Particle burst on tile destruction (8-20 particles, tile-colored) — good
- Mining sparks (8-14 per ore, 4 per impact) — good
- 3-frame breaking overlay animation on multi-hit tiles — good
- Flash white on hit tile (0.2s fade) — good
- Ore chunk scatter on destruction — satisfying
- Landing poof particles (14 particles) — good
- Walking dust at feet — good
- Lava ember particles — atmospheric
- **Sound effects are well-layered:** drill hit (pitch-varied 0.85-1.15), pop pickups (3 variations, pitch-varied 0.8-1.2), explosions, sonar pings, jump/land
- **Procedural audio fallback** if sample files missing — robust

**What's missing:**
- No animation squash/stretch on the cat character during jump/land
- No tween on the HUD mineral counter when it increases (just updates)
- No "crunchy" feeling when breaking a high-value ore vs. dirt — same hit feel
- Ore pickup text popups could use a slight scale-bounce on appear

**Controls rebindable?** SettingsManager exists and references accessibility settings. Input actions are defined in project.godot InputMap. However, there is **no in-game rebinding UI** found — settings seem limited to audio/graphics/accessibility toggles.

**Score: 7/10** — Good juice foundation. Needs differentiation between low-value and high-value mining feedback.

#### OUTCOME/FEEDBACK — Does the player understand what happened?

**Success communication:**
- Ore mined: colored popup text "+X Name" with mineral amount — clear
- Chain bonus: popup text with chain name ("Astro Alloy!") + sound — good
- Fossil find: popup + instant minerals — good
- Lucky strike: sound + bonus minerals — good
- Depth zone discovery: colored banner + 20 energy bonus — good and rewarding
- Boss defeat: 100 minerals + 30 energy restored — clear reward

**Failure communication:**
- Health damage: screen shake + sound + visual HP bar change — clear
- Explosion: big shake + knockback + sound — dramatic and clear
- Energy depletion: "OUT OF ENERGY" text + 2.5s wait — clear but punishing (all run minerals lost)
- Death: "LOST IN SPACE" text + 2.5s wait — clear

**Reward signals:**
- Mineral currency is immediate and visible (HUD counter + popups)
- Smelting chains provide escalating bonuses (50-200%)
- XP + leveling system with perk points
- Run Summary screen with animated ore tally — satisfying

**What's missing:**
- **No "near miss" feedback.** When energy hits 10%, there's a warning, but there's no dramatic tension ramp — no screen darkening, no heartbeat audio, no vignette.
- **Run failure is all-or-nothing.** Losing 100% of minerals on energy death feels harsh for new players. No partial banking, no "consolation prize."
- **No post-death recap.** On failure, it's just "OUT OF ENERGY" and back to overworld. A "you collected X minerals but lost them" screen would teach the player what went wrong.

**Score: 6/10** — Clear moment-to-moment feedback. Failure states need more drama and teaching.

### 1C: Loop Timing

**Micro-loop (mine a tile):** ~0.5-1.5 seconds. Click, hit 1-3 times, collect. This is tight and correct.

**Meso-loop (one mining expedition):** ~3-8 minutes for a new player. Energy starts at 100, drains at 0.25-0.75/s depending on depth. At moderate depth (row 40, depth_ratio ~0.31), drain is ~0.41/s, giving roughly 4 minutes of underground time. With energy nodes restoring 10 each and reenergy stations, runs can extend to 6-8 minutes.

**Macro-loop (mine -> bank -> upgrade -> mine):** ~10-15 minutes. This includes run + overworld navigation + possible city visit.

**Assessment:** Loop timing is well-calibrated for the genre. The meso-loop is the right length (3-8 min) — long enough to build tension, short enough to not feel wasted on death. The micro-loop at 0.5-1.5s per tile is fast enough to maintain flow state.

**Variation:** Procedural terrain generation (Perlin-like ore veins, drunkard-walk tunnels, cave rooms, varying hazard density) provides good run-to-run variation. Boss encounters (50% chance, 5 distinct types) add surprise. Smelting chains reward different pathing strategies.

**Score: 8/10** — Well-paced. Natural variation through procedural generation and boss encounters.

### 1D: Loop Scoring

| Aspect | Score | Biggest Issue |
|---|---|---|
| Clarity (can the player read the game state?) | 6 | No minimap; energy bar too small; no ambient depth-tension audio |
| Agency (do choices matter?) | 7 | Early game (rows 0-30) has low decision density — mostly "dig down" |
| Feel (does acting feel responsive and juicy?) | 7 | Good foundation; needs high-value ore to feel different from dirt |
| Feedback (does the player understand outcomes?) | 6 | Failure states need more drama and teaching; no near-miss escalation |
| Pacing (is the loop the right length?) | 8 | Well-calibrated 3-8 minute runs with good tension curve |
| Variation (does the loop stay fresh?) | 7 | Strong procedural generation; boss variety good; early depth is samey |

**Loop Average: 6.8/10**

---

## Part 2: The First 10 Minutes

### 2A: Minute-by-Minute Walkthrough

#### 0:00 - 0:30 — Launch to Main Menu

**Entry scene:** `res://src/ui/MainMenu.tscn`
**What the player sees:** Title "PICKAXE PIONEER", subtitle "Mine the Cosmos", buttons: SINGLEPLAYER, MULTIPLAYER, SETTINGS, QUIT. Character sprite on left with CUSTOMIZE button. Version label, Discord button.

- No splash screens, no unskippable logos — immediate menu. **Good.**
- Menu is clean and minimal with 4 clear options. **Good.**
- MULTIPLAYER button visible on first launch may confuse solo players but is not harmful.
- CUSTOMIZE button next to character sprite is a nice touch but may distract from "start playing."

#### 0:30 - 1:00 — New Game Flow

Player clicks SINGLEPLAYER -> "New Game" -> Save slot popup (3 slots) -> Select empty slot.

- Save slot selection is a brief extra click but standard for the genre.
- No difficulty selection, no character creation, no name entry. **Good — minimal friction.**
- No intro cutscene or narrative setup. Player goes straight to gameplay. **Good for retention, but misses opportunity to establish the "mining cat in space" fantasy.**

`GameManager.start_game()` -> `load_overworld()` -> SceneTransition fade (1.1s total).

#### 1:00 - 2:00 — Overworld (Star Chart)

Player arrives at the Overworld star chart. Camera on Caravan (ship) at City Node.

**First impression issues:**
- **No guidance on what to do.** Player sees nodes (Mine, Settlement, City) connected by paths. No tooltip, no NPC prompt, no tutorial text saying "Click a mine to begin."
- **Node types may not be obvious.** Mine vs. Settlement vs. City node — are they visually distinct enough?
- **The Caravan (ship) doesn't clearly indicate "you are here."**
- Player must click a mine node. LevelInfoModal shows mine name, biome, hazards.
- "Launch" button takes them to the mine. ~5-10 seconds if they understand; potentially 30+ seconds of confusion if they don't.

#### 2:00 - 3:00 — Entering First Mine

SceneTransition (1.1s) -> MiningLevel loads.

**First moments in the mine:**
- Player spawns at row 0 (surface) at column ~48.
- HUD appears with all elements (capacity, depth, coins, energy, health, hotbar).
- **No tutorial. No control hints. No "click to mine" prompt.**
- Player must discover controls through experimentation or prior knowledge of the genre.
- Bottom-right shows pulsing "Walk right to exit ->" hint — but this tells them how to *leave*, not how to *play*.

**Critical gap:** A new player who has never played Motherload or Terraria has zero guidance. They see a grid of colored blocks and a cat. They might:
1. Try WASD and discover movement — okay
2. Try clicking and discover mining — maybe (if they click within range)
3. Not realize Q does sonar, F is unused, E interacts — likely
4. Not understand energy drain mechanics — almost certainly

#### 3:00 - 5:00 — First Mining

Assuming the player figures out controls:
- Surface layer (rows 0-3): Grass/dirt, minimal ore. 1 mineral per tile. **Very low reward.**
- Rows 3-15: Mostly dirt and stone. Occasional copper ore (3-5 minerals). **Still low.**
- Energy drain begins below surface. Base rate 0.25/s at shallow depth.
- Player mines downward, collecting 20-50 minerals in the first 2 minutes of mining.

**Pacing issue:** The first 15 rows are intentionally sparse (realistic geology) but boring for the player. There's no "wow" moment in the first 2 minutes of digging. Compare to Motherload where you find copper/silver within the first 30 seconds.

**What works:**
- Mining particles and sound give satisfying feedback from the first click.
- Pickaxe throw animation makes each mine feel intentional.
- Depth zone banner at row 16 ("Shallow Veins" or similar) gives a sense of progression.

#### 5:00 - 7:00 — Depth and Discovery

- Player reaches rows 15-40. Iron ore starts appearing (5-8 minerals). Hazards increase.
- First explosive encounter — potentially surprising and punishing (3x3 blast, damage, knockback).
- Smelting chains become possible (same-type ore consecutively = bonus). Player may not notice these without prompting.
- Energy is noticeably draining. Player may start watching the energy bar.
- At row 32: 50% chance of Giant Rat King boss spawn. If it spawns, boss hint panel appears with instructions. **This is the first major "event" — could arrive as early as minute 5.**

**This is where the game starts to click.** The risk/reward tension becomes real. "Do I keep going for richer ore or surface to bank?"

#### 7:00 - 9:00 — The Decision Point

- Energy around 30-50% (depending on energy node finds and depth).
- Player has 200-1000 minerals collected.
- **Key tension:** Surface to bank, or push deeper for gold/gems?
- Low energy warning triggers at 25% — sound + visual. Good.
- If player surfaces: walks right to Exit Station -> RunSummary screen -> animated tally -> coins banked.
- If player dies or runs out of energy: all minerals lost, "LOST IN SPACE" / "OUT OF ENERGY."

#### 9:00 - 10:00 — Post-Run

**If successful exit:**
- RunSummary shows animated ore tally (very satisfying, well-polished).
- "Launch Again" or "Return to Station" buttons.
- Returning to Overworld, player can visit City for upgrades or mine again.
- **Problem:** First successful run likely yields 200-800 minerals. First upgrade costs 50 minerals (in display units). Player can probably afford 1-2 upgrades. The upgrade UI in CityLevel is a panel with locked buttons — functional but not spatially interesting.

**If failed:**
- No run summary. Just text overlay and return to overworld.
- Player lost everything. **This is the critical retention risk.** A new player who spent 5 minutes mining and loses everything may not understand why or may not want to try again.

### 2B: First 10 Minutes Scoring

| Aspect | Score | Biggest Issue |
|---|---|---|
| Time to first input (shorter = better) | 8 | Fast — no splash, 2-3 clicks to start. ~30-60 seconds. |
| Time to core loop (how fast do they "get it"?) | 4 | No tutorial. Player must discover mining, energy, and banking on their own. |
| Tutorial/onboarding quality | 2 | **No tutorial exists.** No control hints, no contextual tips, no guided first mine. |
| Pacing and escalation | 5 | First 15 rows are sparse. Takes 3-5 min before interesting decisions appear. |
| Hook strength at minute 10 | 6 | Risk/reward tension works once understood. Run Summary is satisfying. Upgrade path is visible. |
| Technical polish (no bugs, hitches, or confusion) | 6 | Solid frame; 32 print() statements in production code; no controller support; `pheromone_marker` input mapped but unhandled. |

**First 10 Minutes Average: 5.2/10**

---

## Part 3: Code & Scene Health Check

### 3A: Scene Architecture

**Scene flow:**
```
MainMenu.tscn
  -> [SINGLEPLAYER] -> Save slot popup -> GameManager.start_game()
  -> SceneTransition.fade (1.1s)
  -> Overworld.tscn
     -> [Click Mine Node] -> LevelInfoModal popup -> [Launch]
     -> SceneTransition.fade (1.1s)
     -> MiningLevel.tscn + HUD instantiated
        -> [Exit / Death / Energy Out]
        -> RunSummary.tscn (overlay, on success)
        -> SceneTransition.fade (1.1s)
        -> Overworld.tscn
           -> [Click City Node] -> CityLevel.tscn (perk tree + upgrades)
           -> [Click Settlement] -> SettlementLevel.tscn (consumables shop)
```

**Transitions:** All use SceneTransition with 0.5s fade-to-black, 0.1s hold, 0.5s fade-back. Clean and consistent. No jarring cuts.

**Dead time:** Two transitions to reach first mine from menu (menu->overworld, overworld->mine) = 2.2s of fades. Acceptable but noticeable. No unnecessary intermediate scenes.

### 3B: Input & Controls

**Defined input actions (project.godot):**
| Action | Mapping | Status |
|---|---|---|
| `move_left` | A, Left Arrow | Active |
| `move_right` | D, Right Arrow | Active |
| `jump` | Space, W, Up Arrow | Active |
| `mine` | Left Mouse Button | Active |
| `sonar_ping` | Q | Active |
| `interact` | E | Active |
| `sprint` | Shift | Active |
| `toggle_inventory` | I, Tab | Active |
| `toggle_companions_menu` | C | Active |
| `toggle_trinket_menu` | G | Active |
| `toggle_customization_menu` | X | Active |
| `toggle_perk_tree` | P | Active |
| `toggle_chat` | T | Active (multiplayer) |
| `music_prev` | [ | Active |
| `music_next` | ] | Active |
| `music_toggle` | = | Active |
| `ui_accept` | Enter, E, Joypad Button 0 | Active |

**Issues found:**
- **`pheromone_marker` (F):** Listed in CLAUDE.md and GDD but **not found in project.godot input mappings and no handler in code.** Dead feature reference.
- **Zero gamepad/controller support.** No joypad_motion or joy_button events in any input mapping except ui_accept. This is a significant gap for a Steam release.
- **No in-game key rebinding UI.** SettingsManager exists but no rebinding screen was found.
- **`toggle_chat` (T):** Multiplayer chat — may confuse solo players if visible.

### 3C: State Management

**State architecture:** Clean autoload singleton pattern (GameManager, EventBus, SaveManager, SettingsManager). State flows through EventBus signals. Well-structured.

**Save/load:**
- SaveManager handles 3 save slots via JSON to `user://save_data.json`.
- `new_game()` resets GameManager state and saves blank slot.
- `load_slot()` restores all persistent state (coins, upgrades, progression).
- Save triggers on key events (run completion, upgrade purchase, overworld travel).

**First-10-minutes save risk:**
- If a player quits mid-mine-run, progress is NOT saved (run minerals are volatile). This is intended (roguelite design). However, if they quit at the overworld or city, state IS saved. Acceptable.
- **Potential issue:** GDD mentions `carapace_level` and `mandibles_level` variable names in save data. If the cat-theme rename (Task 2.4 in development_tasks.md) hasn't fully propagated to save serialization, loading old saves could break. (This is a technical debt item, not a first-10-minutes blocker.)

**Race conditions:** SceneTransition's fade-to-black with 0.1s hold before scene change provides a natural guard against scene-load race conditions. No obvious issues found.

### 3D: Performance Red Flags

**`_process()` / `_physics_process()` concerns:**
- `MiningLevel.gd` at ~1,970 lines runs particle updates, flash decay, camera shake, energy drain, boss logic, gravity tiles all in `_process()`. This is a lot of per-frame work but uses early-exit patterns and delta-based timing.
- `PlayerProbe.gd` runs trinket timers, follower trail updates, walking dust emission in `_physics_process()`. Standard and necessary.
- Particle pool (300 particles) in MiningLevel with per-frame position/lifetime updates — acceptable for the scope.

**Loading concerns:**
- MiningTerrainGenerator generates a 96x128 grid (12,288 tiles) synchronously on scene load. This could cause a hitch on low-end hardware. No `ResourceLoader` async usage detected for terrain generation.
- `preload()` used for breaking_animation.tscn, ore chunk scenes — appropriate small assets.
- Music auto-discovered from filesystem and streamed — no preload of large audio assets.

**Debug print() statements:**
- **32 `print()` calls across 7 files** in production code (GameManager: 14, NetworkManager: 8, QuestManager: 3, MusicManager: 3, SaveManager: 1, ChatterManager: 2, ExtractionZone: 1). These should be removed or gated behind a debug flag for release.

---

## Part 4: GDD vs Reality Gap Analysis

### 4A: Intended vs Implemented

| GDD Feature | Implemented? | Quality | Notes |
|---|---|---|---|
| **Core Mining (click-to-mine, physics movement)** | Yes | Polished | Solid Terraria-style physics, good juice |
| **Energy drain with depth** | Yes | Polished | Tuned scaling formula, energy nodes, reenergy station |
| **Mineral collection & banking** | Yes | Polished | Clear HUD, run summary, persistent wallet |
| **4 Upgrade Tracks (Pelt/Paws/Claws/Whiskers)** | Partial | WIP | Perk tree system exists but uses different structure (branching perks, not 4 linear tracks). Variable names still use old terminology in places. |
| **Overworld Star Chart** | Yes | WIP | Functional node-based map with mine/settlement/city. Planet variety (ore mix, hazards) works. Visual polish limited. |
| **Settlement Rest Stops** | Yes | Functional | Consumable shop with 4 items. Gated behind progression. |
| **Clowder Hub (City Level)** | Partial | Placeholder | Two info panels (Perk Tree + Spaceship Upgrades). GDD envisions spatial exploration with NPCs, mission board, fossil archive. Currently a menu screen. |
| **5 Boss Encounters** | Yes | Polished | All 5 bosses implemented with distinct mechanics, visual rendering, hint system. Impressive. |
| **Smelting Chains** | Yes | Polished | Chain bonuses (50-100%) and combo bonuses (100-200%) with named alloys. |
| **Fossil System** | Yes | Polished | Pity counter, depth-weighted drops, 5 fossil types tied to tile types. |
| **Sonar Ping** | Yes | Polished | Expandable radius, energy cost, visual overlay. |
| **Scout Cat Companion** | Replaced | Functional | ForagerSystem deprecated. CatSystem replaces it with hireable Mining Cats and Collecting Cats from Cat Tavern. Different from GDD's single companion model. |
| **Wandering Trader** | Yes | Functional | TraderSystem at milestone depth rows. |
| **Procedural Terrain** | Yes | Polished | MiningTerrainGenerator with Perlin-like ore veins, cave rooms, drunkard-walk tunnels. Good variety. |
| **HUD (minerals, health, energy, depth)** | Yes | Functional | All critical info present. Hotbar system adds complexity beyond GDD. |
| **Run Summary Screen** | Yes | Polished | Animated tally with staggered ore rows, count-up, clear banking. |
| **Save/Load** | Yes | Functional | 3-slot JSON save system. |
| **Adaptive Music** | Yes | Functional | Auto-discovers tracks, crossfade, shuffled playlists. |
| **Procedural SFX** | Yes | Polished | Sample-based with procedural fallback. Good variety. |
| **Mission Board / Daily Challenges** | No | Not started | QuestManager is a stub ("cleared on mine entry"). |
| **Fossil Archive** | No | Not started | No archive viewing UI. |
| **NPC Relationships** | No | Not started | ChatterManager provides ambient flavor text only. |
| **Run Modifiers (Ironworker, Speed Dig, Dark Tunnels)** | No | Not started | |
| **Achievements** | No | Not started | |
| **Tutorial / Onboarding** | No | Not started | **Critical gap.** |
| **Controller Support** | No | Not started | **Critical for Steam.** |
| **Key Rebinding** | No | Not started | Settings UI exists but no rebinding. |
| **Particle Polish (dirt spray, sparkle, lava glow)** | Partial | WIP | Mining particles exist. Dirt spray, mineral sparkle, lava glow effects not yet specialized. |
| **Research Tree (Meta-Progression)** | Partial | Different | Perk Tree exists but structured differently from GDD's 3-tier research tree. |
| **Trinket System** | Yes | Functional | 13 trinkets with unique effects. Not in original GDD — scope addition. |
| **Multiplayer** | Partial | WIP | NetworkManager + RPC sync exists. Not in original GDD scope. |
| **Ladders** | Yes | Functional | Placeable, climbable. Not prominently in GDD. |
| **Cat Tavern** | Yes | Functional | Underground hireable cats. Not in original GDD. |

### 4B: Scope Assessment

**Features in code but NOT in GDD (scope creep):**
- Trinket system (13 trinkets) — adds depth but complicates first-10-min cognitive load
- Multiplayer (NetworkManager, RPC sync) — significant engineering effort
- Cat Tavern + CatSystem (hireable cats) — interesting but adds complexity
- Ladder system — good utility feature
- Hotbar system (10 slots) — adds inventory management layer
- XP/Leveling system — layered on top of mineral currency
- Spaceship upgrades (5 types) — additional progression track

**Features in GDD but not started (most critical for first 10 min):**
1. **Tutorial/onboarding** — #1 priority for first 10 minutes
2. **Mission Board / Quests** — gives direction and goals
3. **Fossil Archive** — gives purpose to fossil collection
4. **Achievements** — milestone motivation

**Half-done mechanics creating worse experience than nothing:**
- **City Level (Clowder Hub):** Currently a static panel. GDD promises explorable station with NPCs. Players expect a "home" — they get a menu. Either make it spatial or lean into it being a clean menu.
- **Pheromone Marker (F key):** Referenced in docs/GDD as a control, mapped nowhere, does nothing. Dead feature reference creates confusion if players read controls.
- **QuestManager:** Registered as autoload, does nothing except clear on mine entry. Occupies brain space in code without value.

---

## Part 5: Prioritized Task List

### Tier 1: Critical (blocks a good first impression)

| # | Task | File(s) | Type | Complexity |
|---|---|---|---|---|
| 1.1 | **Add first-mine tutorial/onboarding.** Show contextual control hints on first run: "Click to mine", "WASD to move", "Q for sonar", "Watch your energy!", "Reach the exit to bank minerals." Use a simple flag (`GameManager.has_completed_first_run`) to gate. | `MiningLevel.gd`, `HUD.gd`, `GameManager.gd` | New feature | Medium |
| 1.2 | **Add a "death/failure" recap screen.** When energy runs out or HP hits 0, show what was collected and lost before returning to overworld. "You collected 450 minerals but lost them all. Tip: Watch your energy bar!" | `MiningLevel.gd`, new `FailureSummary` UI or extend `RunSummary.gd` | New feature | Medium |
| 1.3 | **Enrich the first 15 rows of terrain.** Ensure copper ore appears by row 5-8 so the first 60 seconds of mining include a meaningful reward. Currently shallow rows are too sparse. | `MiningTerrainGenerator.gd` | Fix | Small |
| 1.4 | **Add gamepad/controller input mappings.** All core actions need joypad equivalents for Steam release. | `project.godot`, potentially `MiningLevel.gd` for cursor-aim | New feature | Medium |
| 1.5 | **Remove 32 debug `print()` statements** from production code. | `GameManager.gd` (14), `NetworkManager.gd` (8), `QuestManager.gd` (3), `MusicManager.gd` (3), `SaveManager.gd` (1), `ChatterManager.gd` (2), `ExtractionZone.gd` (1) | Fix | Small |

### Tier 2: Important (significantly improves the experience)

| # | Task | File(s) | Type | Complexity |
|---|---|---|---|---|
| 2.1 | **Add tension escalation audio/visual as energy drops.** Heartbeat sound, slight screen vignette, or desaturation as energy goes below 40%, 25%, 10%. Make the "should I surface?" decision feel dramatic. | `MiningLevel.gd`, `SoundManager.gd`, `HUD.gd` | New feature | Medium |
| 2.2 | **Differentiate high-value ore mining feedback.** Gold/gem ore should have bigger particles, louder sounds, screen flash, or a brief pause (hitstop) compared to dirt/stone. Make rare finds feel special. | `MiningLevel.gd` (particle/shake section), `SoundManager.gd` | Polish | Medium |
| 2.3 | **Add a minimap or depth sidebar.** Show player position relative to surface, boss rows, and depth zones. Could be a simple vertical bar on screen edge. | `HUD.gd` or new `Minimap` component | New feature | Medium |
| 2.4 | **Make the Clowder Hub spatially interesting** — either convert to a walkable scene with NPC sprites and stations, or streamline as a polished menu with character art and atmosphere. Current "two panels" approach is neither. | `CityLevel.gd`, `CityLevel.tscn` | Redesign | Large |
| 2.5 | **Add overworld guidance for new players.** Tooltip or NPC speech bubble on first overworld visit: "Click a mine to start your expedition!" or similar. Highlight the recommended first mine. | `Overworld.gd` | New feature | Small |
| 2.6 | **Add key rebinding UI.** Required for Steam accessibility expectations. | `SettingsManager.gd`, new UI scene | New feature | Medium |
| 2.7 | **Clean up dead feature references.** Remove `pheromone_marker` from documentation. Either implement or remove `QuestManager` stub. | `CLAUDE.md`, `README.md`, `QuestManager.gd` | Fix | Small |

### Tier 3: Polish (makes it great)

| # | Task | File(s) | Type | Complexity |
|---|---|---|---|---|
| 3.1 | **Add HUD mineral counter tween.** When minerals increase, briefly scale up the counter and flash the text color. Small but satisfying. | `HUD.gd` | Polish | Small |
| 3.2 | **Add cat squash/stretch on jump and land.** Exaggerate the character sprite briefly on jump apex and landing for more "alive" feeling. | `PlayerProbe.gd` | Polish | Small |
| 3.3 | **Add a brief narrative intro** (skippable). 3-4 text cards: "The Clowder drifts between stars... Your ship needs fuel... You are a mining cat." Establishes fantasy in 15 seconds. | New `IntroSequence` scene, `MainMenu.gd` | New feature | Small |
| 3.4 | **Add "new depth record" celebration.** When a player reaches their deepest depth ever, show a brief fanfare + record banner. | `MiningLevel.gd`, `HUD.gd`, `GameManager.gd` | New feature | Small |
| 3.5 | **Enlarge/reposition energy bar.** Move to a more prominent position or make the segments larger. Energy is the #1 survival resource and should be unmissable. | `HUD.gd`, `HUD.tscn` | Polish | Small |
| 3.6 | **Add "near miss" energy escape reward.** If a player exits with <10% energy, give a "Narrow Escape!" bonus (+10% minerals) to reward the risk. | `MiningLevel.gd`, `RunSummary.gd` | New feature | Small |
| 3.7 | **Async terrain generation** with a brief loading indicator. Prevents potential hitch on low-end hardware when generating 12,288 tiles. | `MiningTerrainGenerator.gd`, `MiningLevel.gd` | Performance | Medium |

---

## Part 6: Summary

### 1. The Core Loop in One Sentence
The mine-deeper-or-bank-now tension driven by energy depletion is a strong roguelite core loop with satisfying feedback and good procedural variety — but it takes too long to reach the interesting decisions, and failure is too punishing for new players.

### 2. The First 10 Minutes in One Sentence
A new player reaches mining quickly (~2 min) but receives zero guidance on controls, mechanics, or goals, spends 3 minutes mining sparse shallow dirt, and may lose their entire first haul to an energy death they didn't understand was coming.

### 3. The Single Most Impactful Change
**Add a contextual first-run tutorial** that teaches mining, energy management, and the "bank at the exit" flow within the first 90 seconds of the first mine. This single change would prevent the majority of "confused quit" moments that currently gate the experience.

### 4. Overall Readiness Score: 5/10
The mechanical foundation is solid — mining feels good, bosses are impressive, progression systems are deep, and the risk/reward loop works once understood. But a stranger playing cold would likely mine dirt for 2 minutes without knowing what to do, die to energy depletion without understanding why, lose everything, and not return. The game doesn't teach itself yet.

### 5. Top 5 Tasks by Impact-per-Effort

| Rank | Task | Impact | Effort | Why |
|---|---|---|---|---|
| 1 | **1.1 First-mine tutorial/onboarding** | Critical | Medium | Prevents the #1 cause of new player dropout |
| 2 | **1.3 Enrich first 15 rows** | High | Small | Makes the first 60 seconds rewarding instead of empty |
| 3 | **1.2 Death/failure recap screen** | High | Medium | Turns punishing failure into a teaching moment |
| 4 | **2.1 Energy tension escalation** | High | Medium | Makes the core risk/reward decision feel dramatic |
| 5 | **2.5 Overworld first-visit guidance** | Medium | Small | Removes 30+ seconds of "what do I click?" confusion |
