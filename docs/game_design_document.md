# Pickaxe Pioneer - Game Design Document (GDD)
## STEAM RELEASE VERSION - $7.99 Price Point

## 1. Game Overview
**Title:** Pickaxe Pioneer
**Genre:** 2D Side-Scrolling Mining Roguelite
**Theme:** Underground Cat Civilization Mining Adventure
**Engine:** Godot 4.5
**Perspective:** Side-Scrolling 2D (Terraria-style physics)
**Inspiration:** Motherlode, Supermotherlode, Dwarf Fortress, Path of Exile, ADOM, Noita
**Target Playtime:** 5-12 hours (first completion), 15-25+ hours (100% completion)
**Target Platforms:** Steam (Windows/Linux/Mac), Itch.io

### 1.1 High Concept
*"Dig deep, gather minerals, return to the Clowder."*

You are a mining cat from the Clowder, venturing into the earth below. Armed with razor-sharp Claws and impossibly sensitive Whiskers, each expedition takes you deeper underground through layers of dirt, stone, and precious ore. Manage your energy carefully — go too deep without energy and you'll be stranded. Mine rare gems from the deepest veins, upgrade your Pelt, Paws, Claws, and Whiskers back at the Clowder, and unravel the mysteries hidden beneath the surface.

**Core Pillars:**
1. **Risk/Reward Depth Diving:** Every tunnel is a gamble — dig deeper for richer ore or surface early to bank your haul
2. **Satisfying Progression:** Permanent cat upgrades, Clowder unlocks, and meta-progression create a sense of growing power
3. **Environmental Storytelling:** Discover the underground world's secrets through collectible fossils, Clowder lore, and hidden chambers
4. **Strategic Exploration:** Physics-based movement and energy management reward careful planning over recklessness

## 2. Gameplay Mechanics

### 2.1 Core Loop
1. **Hub — The Clowder (Surface):**
   - View stats, achievements, and total progression
   - Access the Clowder Workshop (permanent cat upgrades: Pelt, Paws, Claws, Whiskers)
   - Check the Mission Board (daily challenges, bounties, discovery missions)
   - Read collected Fossils and Ancient Inscriptions in the Archive
   - Interact with Clowder NPCs for quests and lore

2. **Overworld — The Clowder Warren:**
   - Node-based navigation between mine entrances, settlement rest stops, and the Clowder
   - Multiple mines with varying depth, ore richness, and hazard profiles
   - Each mine node has a name and unique composition (Iron Mine, Gold Vein, Gem Cavern, etc.)
   - Settlement nodes offer pre-run consumables for banked minerals

3. **Settlement — Rest Stop:**
   - Spend banked minerals on run-scoped consumables before entering a mine
   - Available items: Energy Cache (+50 starting energy), Pelt Patch (+1 HP), Mining Shroom (12 ore-yield charges), Claw Whetstone (+1 claw power)

4. **Mining Run — The Descent:**
   - Spawn at the surface entrance of a mine shaft (96×128 tile grid)
   - Terraria-style physics: gravity, jump, horizontal run; cursor-based mining (left-click within 4.5 tiles)
   - Energy depletes with depth; surface movement is free
   - Ore value increases dramatically with depth
   - Hazards: lava flows, explosive gas pockets, unstable rock
   - Energy Nodes restore energy; the Reenergy Station (midpoint) reenergys for minerals
   - Reach the Exit Station to complete the run and bank your minerals

5. **Post-Run — Return to Colony:**
   - Successful surface return: bank all collected minerals (+ any forager-banked minerals)
   - Out of energy or HP → 0: lose all run minerals, return empty to colony
   - Review run statistics and depth reached
   - Unlock new upgrades based on mineral wealth

6. **Meta-Progression Loop:**
   - Spend minerals on permanent carapace, legs, and mandibles upgrades
   - Unlock new mine locations on the overworld
   - Progress colony story through boss encounters and fossil collection
   - Complete achievements for unique colony rewards

### 2.2 Run System

**Mineral Types (by tile yield):**
1. **Soil/Grass** (1 mineral) — Surface layer, no energy cost
2. **Dirt/Dark Dirt** (1 mineral) — Shallow ground
3. **Stone/Dark Stone** (2 minerals) — Mid-depth rock
4. **Copper Ore / Deep Copper** (3–5 minerals) — Early ore deposits
5. **Iron Ore / Deep Iron** (5–8 minerals) — Mid-depth deposits
6. **Gold Ore / Deep Gold** (10–15 minerals) — Deep veins
7. **Gem Ore / Deep Gem** (20–30 minerals) — Rarest and deepest

**Hazard Tiles (no mineral yield):**
- **Explosive / Armed Explosive** — Detonates in a 3×3 radius, deals damage
- **Lava / Lava Flow** — Instant damage on contact; cannot be mined
- **Energy Node / Full Energy Node** — Restores 10 energy when mined (bonus resource)
- **Reenergy Station** — Refills energy to max for a mineral cost (interact with E)

**Death & Extraction:**
- **Pelt Shredded (HP → 0):** Lose ALL collected run minerals, return to Clowder
- **Out of Energy:** Lose ALL collected run minerals, stranded (transported back)
- **Successful Exit:** Keep everything + depth bonus
- **Risk Tiers:** Deeper tiles yield far better ore but more hazards and higher energy cost

**Run Modifiers (Unlocked Later):**
- **Ironworker Mode:** +200% mineral yield, permadeath for entire save
- **Speed Dig:** Time limit but massive depth bonus
- **Dark Tunnels:** No minimap, huge mineral multiplier
- **Lean Rations:** Limited energy capacity, enormous mineral multipliers

### 2.3 Controls
- **Movement (Terraria-style physics):**
  - `A` / `D` / Left Arrow / Right Arrow: Horizontal movement
  - `W` / `Up Arrow` / `Space`: Jump
- **Mining:**
  - Left-click: Mine the tile under the cursor (within 4.5-tile range)
- **Abilities:**
  - `Q`: Sonar ping (costs energy; reveals ore in radius through solid rock)
  - `F`: Place pheromone marker (directs Scout Cat companion)
- **Interaction:**
  - `E`: Interact with Reenergy Station or NPC
  - `Esc`: Pause Menu
- **HUD Indicators:**
  - Upper-left: Minerals collected this run
  - Upper-right: Health squares (pelt HP), segmented energy bar, depth meter

### 2.4 Entities

#### The Cat (Player Character)
You are a mining cat from the Clowder. Armed with razor-sharp Claws and impossibly sensitive Whiskers, you land on alien planets and dig for minerals. Movement is Terraria-style physics — gravity, jump, horizontal run. Mining is cursor-based: left-click within 4.5-tile range.

**Cat Stats (affected by upgrades):**
- **Pelt (Health):** Base 3 HP; +1 per Pelt upgrade level
- **Paws (Speed/Energy):** +30 px/s move speed **and** +25 max energy per level
- **Claws (Mining Power):** +3 mining power per level; affects damage to tough tiles and boss weak points
- **Whiskers:** Increases sonar ping radius and reduces energy cost per activation

#### Upgrades (Clowder Workshop)
Four permanent upgrade tracks, each with scaling mineral costs (+25 per level):

1. **Thicken Pelt** (base cost: 50 minerals)
   - Thickens the cat's protective fur and hide
   - Effect: +1 max HP per level (base: 3 HP)

2. **Strengthen Paws** (base cost: 50 minerals)
   - Builds paw endurance for faster movement and greater energy stamina
   - Effect: +30 px/s move speed **and** +25 max energy per level

3. **Sharpen Claws** (base cost: 50 minerals)
   - Hones the cat's retractable claws to a razor edge
   - Effect: +3 mining power per level (used for tough tiles and boss armor)

4. **Refine Whiskers** (base cost: 50 minerals)
   - Tunes the cat's whisker sensitivity for deeper sonar reads
   - Effect: Larger sonar ping radius and lower energy cost per activation per level

#### Mine Tiles
See Section 2.2 for full tile breakdown. Tile richness is depth-weighted:
- Shallow (rows 3–30): Mostly dirt, occasional copper
- Mid-depth (rows 30–70): Stone, iron, explosive hazards increase
- Deep (rows 70–128): Gold, gems, heavy hazards, energy nodes become critical

#### NPCs
1. **The Matriarch** (Clowder Hub): Faction leader, upgrade vendor, story guide
2. **Elder Miner** (Clowder Hub): Mission giver, experienced mining cat
3. **Clowder Archivist** (Clowder Hub): Fossil and lore collector
4. **Wandering Trader** (Random Mine Event): Rare item exchange
5. **Stray Mining Cats** (Mine Events): Rescue for Clowder rewards

## 3. Art & Audio Style

### 3.1 Visual Direction
**Core Art Style:**
- **Format:** Pixel art tiles, animated cat character sprite
- **Tile System:** Individual block sprites with geological variety
- **Color Palette by Depth (planet-tinted):**
  - Surface (rows 0–3): Planet atmosphere color (set per mine node)
  - Shallow (rows 3–30): Darkened planet color (darkened 75%)
  - Deep (rows 70–128): Near-void black with faint planet hue (darkened 96%)
- **Style:** Clean pixel art with distinct tile silhouettes for readability
- **Animation:** Cat walk/idle/jump cycle, mining particle dust (future)

**Visual Polish:**
- Sky blue background for surface rows
- Dark near-black background for underground
- White border highlights on interactable tiles (Reenergy Station, Exit Station)
- Green EXIT label on Exit Station
- Health: Red squares (filled) / dark grey (lost HP)
- Energy: 10-segment green bar, greying out as energy depletes

**Particle Systems (Planned):**
- Dirt spray when digging
- Mineral sparkle on ore collection
- Explosion debris cloud
- Lava glow effect

**Accessibility Features:**
- Colorblind modes (3 presets)
- High contrast option for tile outlines
- Adjustable auto-repeat speed

### 3.2 Audio Design

**Music:**
1. **Clowder Hub:** Calm ambient, cozy space-station atmosphere, gentle percussion
2. **Overworld Map:** Light adventurous theme, wind through space
3. **Mining Level:** Rhythmic underground ambience; tension rises at depth
4. **Boss Fights:** Intense unique themes per encounter
5. **Menu:** Minimal ambient

**Sound Effects (Procedural + Library):**
- **Digging:** Crunching, grinding claw scratch — `play_drill_sound()`
- **Mineral Pickup:** Satisfying "clink" chime
- **Explosion:** Deep impact boom — `play_explosion_sound()`
- **Energy Restore:** Bubbly replenishment tone
- **Damage:** Thud and cat yowl
- **Energy Low Warning:** Anxious cat meow

**Audio Mix:**
- Clear priority: critical SFX > music > ambient
- Volume sliders: Master, Music, SFX

## 4. World Design

### 4.1 The Hub: The Clowder Space Station
**Layout:**
- **Clowder Workshop (Left):** The Matriarch — Pelt/Paws/Claws/Whiskers upgrades
- **Mission Board (Center):** Elder Miner — Daily challenges, bounties, discovery missions
- **Fossil Archive (Right):** Clowder Archivist — View collected fossils and Clowder lore
- **Docking Bay (Bottom):** Deploy to Star Chart
- **Stats Chamber:** View Clowder wealth, depth records, achievements

**Atmosphere:**
- Bustling cat space station humming with activity
- Corridors lined with cat-clan memorabilia and glowing mineral samples
- Clowder members with idle animations and ambient chatter
- Safe zone — no energy cost, no hazards

**NPC Interactions:**
- Story-driven dialogue about the Clowder's need for minerals to fuel the next jump
- Relationship system (unlocks special missions and upgrade discounts)
- Rotating daily quests tied to ore types and depths

### 4.2 Overworld: The Star Chart
**Structure:**
- **Map Type:** Node-based navigation network
- **Player Token:** The cat's ship (Caravan) moving between planets
- **Planet Unlock:** Progress through planets to unlock deeper/richer ones
- **Route:** Connected paths between nodes; ship travels each segment visually

**Planet Nodes (Randomly Generated Per Run):**
- **Mine Planets** — Procedurally named (e.g. "Ruby Sector", "Obsidian Rift"); each has a unique atmosphere color, ore mix, and hazard profile
- **Settlement Stations** — Rest stops; spend minerals on pre-run consumables
- **Clowder Space Station** — Hub; permanent upgrades and gem socketing

**Planet Node Types:**
- **Rich Vein:** High ore density, low hazards
- **Hazard Zone:** High hazards, bonus mineral multiplier
- **Ancient Site:** Special fossil collectibles, moderate mining
- **Supply Cache:** Energy nodes abundant, prepare for deep dive
- **Boss Encounter:** Elite creature guarding legendary rewards

### 4.3 Mining Level (Procedural Generation)
**Grid:** 96 columns × 128 rows at 64 px per tile
- **Right 2 columns:** Exit zone (spawn point and return corridor)
- **Row 0–2:** Surface layer (sky blue, free movement)
- **Row 3:** Grass surface row (1 mineral each)
- **Rows 4–127:** Underground (1 energy per tile entered)
- **Mid-column:** Reenergy Station on surface row
- **Far-right surface:** Exit Station (ends run, banks minerals)

**Procedural Tile Distribution:**
- Depth-weighted: rarer ores become significantly more common deeper
- Hazard rate: 10% at surface edge, grows to 15% at max depth
- Energy Nodes: ~3% of tiles throughout, critical for deep runs
- Stone density increases with depth (more resistant to quick clear)

**Camera System:**
- Camera2D follows the cat with clamped map boundaries
- Viewport culling renders only visible tiles for performance

**Extraction System:**
- Reach the Exit Station on the surface layer to complete run
- All collected minerals are banked via the Run Summary screen
- Die or run out of energy → lose run minerals, return to overworld

## 5. Progression System

### 5.1 Mineral Economy
**Primary Currency: Minerals**
- Collected by mining tiles underground
- Lost if the cat dies or runs out of energy
- Banked permanently on successful exit
- Used for all Clowder upgrades

**Secondary Collectibles (Planned):**
- **Fossils:** Permanent story collectibles, never lost
- **Rare Crystals:** Mid-tier crafting material, found in deep gem clusters
- **Ancient Artifacts:** Ultra-rare, unlocks special colony chambers

### 5.2 Upgrade System

**Clowder Workshop — Four Tracks:**

| Upgrade | Stat | Base Cost | Per Level | Max Levels |
|---------|------|-----------|-----------|-----------|
| Thicken Pelt | +1 Max HP | 50 minerals | +25 minerals | 10 |
| Strengthen Paws | +30 px/s speed & +25 max energy | 50 minerals | +25 minerals | 10 |
| Sharpen Claws | +3 mining power | 50 minerals | +25 minerals | 10 |
| Refine Whiskers | Larger sonar radius, lower energy/ping | 50 minerals | +25 minerals | 10 |

**Future Upgrade Tracks (Planned):**
- **Energy Sac:** Increases max energy capacity (separate from Paws)
- **Clowder Bond:** Buffs earned near other rescued stray cats

### 5.3 Research Tree (Meta-Progression, Planned)

**Tier 1** (1–5 Clowder Points Each):
- Cat Nose: +10% mineral yield from all tiles
- Thick Pelt: +5% max HP
- Efficient Paws: −5% energy consumption
- Quick Claws: −10% between-tile dig delay
- Lucky Find: +2% chance to find Rare Crystals

**Tier 2** (5–10 Points Each):
- Deep Whiskers: Reveal tile types one step ahead
- Armored Pelt: +15% damage reduction
- Razor Claws: Chain-mine explosive tiles safely
- Extended Energy Sac: +25% max energy capacity
- Treasure Instinct: Highlight fossil locations

**Tier 3** (10–20 Points Each):
- Master Hunter: +50% all mineral gains
- Indestructible Pelt: Auto-survive one fatal hit per run
- Deep Sight: Full tile map visible from surface
- Extraction Savings: Keep 25% of minerals even on energy death
- Clowder Hero: +30% minerals near the Clowder docking bay

## 6. Story & Lore

### 6.1 Premise
The Clowder drifts between star systems, a proud feline civilization aboard a great space station. Their ships need fuel — rare minerals scavenged from the crusts of dead planets. For thirty years, your father ran these mining routes: a one-cat operation, a battered ship, and an intimate knowledge of every ore vein on the star chart.

Now he's gone. The ship is yours, the routes are yours, and so are the debts.

You are a mining cat keeping a family business alive. Armed with razor-sharp Claws and impossibly sensitive Whiskers, you touch down on alien rock, dig through layers of stone and ore, and claw your way back out before your energy gives out. Every mineral you bank is one more run you can afford, one more upgrade to the ship your father left you. The deeper you go, the richer the haul — and the older, stranger, and more dangerous the things buried in the dark.

The Clowder is counting on the ore. You're counting on something harder to name.

### 6.2 Fossil Collectibles (50 Total)
Scattered across all mine depth levels:
- **Surface Fossils (10):** Small insects, leaves, ancient seeds
- **Mid-Depth Fossils (20):** Trilobites, ancient beetles, crystallized honeycomb
- **Deep Fossils (15):** Massive arthropods, unknown creatures, glowing mineral formations
- **Boss Chamber Relics (5):** Ancient star-cat artifacts, legendary specimens

Each fossil reveals lore about the earth's deep history and grants bonus colony experience.

### 6.3 Boss Encounters (5 Total — Depth Milestones)
All bosses are defeated using the player's existing tools — no separate combat system. Energy drains 2.5× while a boss is alive; defeating one rewards 100 minerals + 30 energy.

1. **Giant Rat King** (row 32) — multi-segment horizontal body; mine through segments to reach and destroy the core
2. **Void Spider Matriarch** (row 64) — diamond/cross body spawned below player; mine void-web segments to reach the core
3. **The Blind Mole** (row 96) — tremor AoE collapses nearby empty tiles; warning overlay telegraphs incoming tremor
4. **Stone Golem** (row 112) — three ore-phase armor (copper → iron → gold); player must last-mine the required ore type to crack each phase
5. **The Ancient Star Beast** (row 128) — three-phase final boss: outer stone-shell ring (phase 1), crystalline inner ring with void pulses that reseal mined tunnels (phase 2), exposed regenerating core (phase 3); 2× energy drain throughout

## 7. Technical Design

### 7.1 Architecture Overview
```
res://
├── assets/           # Art, Audio, Fonts
├── docs/             # Documentation
├── notes/            # Development notes
└── src/              # Source Code & Scenes
    ├── autoload/     # Global Singletons (GameManager, EventBus, SoundManager, MusicManager, etc.)
    ├── components/   # Reusable Component Nodes (HealthComponent, StateMachine, etc.)
    ├── entities/     # Game Objects (PlayerProbe/Ant, ScrapLoot/Minerals, NPCs, Overworld tokens)
    ├── levels/       # Game Scenes (Overworld, MiningLevel, CityLevel, SettlementLevel)
    ├── systems/      # Extracted subsystems (SmeltingSystem, FossilSystem, SonarSystem, ForagerSystem, BossSystem)
    └── ui/           # User Interface (HUD, UpgradeMenu, RunSummary, LevelInfoModal, etc.)
```

### 7.2 Key Systems
- **GameManager:** Game state, scene transitions, mineral currency, 4 upgrade tracks, energy, settlement carry-overs
- **EventBus:** Decoupled signals (minerals_changed, minerals_earned, energy_changed, player_health_changed, player_died)
- **MiningLevel:** Terraria-style physics world, procedural tile generation, cursor mining, energy logic; delegates to subsystems below
- **SmeltingSystem:** Consecutive ore chain bonuses and alloy combos
- **FossilSystem:** Fossil drop probability with forgiveness pity counter per block type
- **SonarSystem:** Sonar ping — radial ore detection, energy cost per activation
- **ForagerSystem:** Scout Cat companion — collects 40% ore yield, auto-banks when full
- **BossSystem:** Five depth-milestone boss encounters; energy pressure, phase management
- **UpgradeMenu:** Clowder Workshop UI — Pelt / Paws / Claws / Whiskers upgrades
- **HUD:** Minerals counter, health squares, segmented energy bar, depth meter, milestone banners

### 7.3 Save System
Persistent save via JSON (`user://save_data.json`):
- `mineral_currency` — banked Clowder minerals
- `carapace_level` — pelt upgrade level (0–10) *(var rename to `pelt_level` pending Task 2.4)*
- `legs_level` — paws upgrade level (0–10)
- `mandibles_level` — claws upgrade level (0–10) *(var rename to `claws_level` pending Task 2.4)*
- `mineral_sense_level` — whiskers upgrade level (0–10)
- `gem_count`, `carapace_gem_socketed`, `legs_gem_socketed`, `mandibles_gem_socketed`, `sense_gem_socketed` — gem socket state
- Spaceship upgrade flags, cumulative milestone trackers, planet config

## 8. Glossary

| Term | Definition |
|------|-----------|
| **Minerals** | Primary currency — what the cat collects by mining tiles |
| **Pelt** | Cat's protective fur and hide; determines max HP |
| **Paws** | Cat's movement and endurance; determines speed and energy capacity |
| **Claws** | Cat's retractable mining claws; determines mining power |
| **Whiskers** | Cat's sonar sense; determines sonar ping radius and energy cost |
| **Energy** | The cat's energy reserve; depletes with depth while underground |
| **Run** | One mining expedition: land on planet → mine → return to ship |
| **Clowder** | The cat civilization's space station; hub where upgrades are purchased |
| **Star Chart** | The overworld map of planets, settlements, and the Clowder station |
| **Exit Station** | The mine exit (airlock) on the surface layer; reach it to complete the run |
| **Reenergy Station** | Mid-mine surface point; refills energy for a mineral cost |
| **Energy Node** | Underground tile that restores 10 energy when mined |
| **Depth** | How many rows below surface the cat has reached; higher depth = richer ore |
| **Fossil** | Permanent story collectible found underground; never lost on death |
| **Planet Node** | A mine node on the Star Chart; each has unique ore, hazards, and atmosphere color |
| **Boss** | Elite underground creature encountered at depth milestone rows (32/64/96/112/128) |
| **Scout Cat** | Companion that takes 40% ore yield and auto-banks when carry cap is full |

## 9. Achievements (50+ Planned)

**Story (15):**
- Complete each mine zone (6)
- Defeat each boss (5)
- Collect all 50 fossils
- Unlock true ending
- Complete all colony quests

**Mining Mastery (15):**
- Mine 100/500/1000 total tiles
- Reach max depth (row 128) in a single run
- Mine a gem ore tile for the first time
- Complete a run without using the Reenergy Station
- Mine 10 tiles in a single second (mandibles speed)

**Survival (10):**
- Complete a run with 1 HP remaining
- Complete a run without taking any damage
- Survive an explosion (be adjacent to one)
- Escape with 0 energy remaining
- Complete 10 runs in a row without dying

**Collection (10):**
- Bank 1,000/10,000/100,000 total minerals
- Max out Carapace upgrades
- Max out Legs upgrades
- Max out Mandibles upgrades
- Find a fossil at max depth
