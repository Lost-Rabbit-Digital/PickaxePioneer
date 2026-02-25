# Pickaxe Pioneer - Game Design Document (GDD)
## STEAM RELEASE VERSION - $3-5 Price Point

## 1. Game Overview
**Title:** Pickaxe Pioneer
**Genre:** 2D Grid-Based Mining Roguelite
**Theme:** Underground Ant Colony Mining Adventure
**Engine:** Godot 4.5
**Perspective:** Top-Down Grid (2D)
**Inspiration:** Motherlode, Supermotherlode, Dwarf Fortress, Path of Exile, ADOM
**Target Playtime:** 5-12 hours (first completion), 15-25+ hours (100% completion)
**Target Platforms:** Steam (Windows/Linux/Mac), Itch.io

### 1.1 High Concept
*"Dig deep, gather minerals, return to the colony."*

You are a red ant venturing out from the colony into the earth below. Each expedition takes you deeper underground through layers of dirt, stone, and precious ore. Manage your energy carefully — go too deep without fuel and you'll be stranded. Mine rare gems from the deepest veins, upgrade your carapace, legs, and mandibles back at the colony, and unravel the mysteries hidden beneath the surface.

**Core Pillars:**
1. **Risk/Reward Depth Diving:** Every tunnel is a gamble — dig deeper for richer ore or surface early to bank your haul
2. **Satisfying Progression:** Permanent ant upgrades, colony unlocks, and meta-progression create a sense of growing power
3. **Environmental Storytelling:** Discover the underground world's secrets through collectible fossils, colony lore, and hidden chambers
4. **Strategic Exploration:** Grid-based movement and fuel management reward careful planning over recklessness

## 2. Gameplay Mechanics

### 2.1 Core Loop
1. **Hub — The Colony (Surface):**
   - View stats, achievements, and total progression
   - Access the Colony Workshop (permanent ant upgrades)
   - Check the Mission Board (daily challenges, bounties, discovery missions)
   - Read collected Fossils and Ancient Inscriptions in the Archive
   - Interact with colony NPCs for quests and lore

2. **Overworld — The Anthill Map:**
   - Node-based navigation between different mine entrances
   - Multiple mines with varying depth, ore richness, and hazard profiles
   - Each mine node has a name and unique composition (Iron Mine, Gold Vein, Gem Cavern, etc.)

3. **Mining Run — The Descent:**
   - Spawn at the surface entrance of a mine shaft (32×128 tile grid)
   - Dig left and down through the grid, mining tiles by moving into them
   - Each underground tile costs 1 fuel to enter; surface movement is free
   - Ore value increases dramatically with depth
   - Hazards: lava flows, explosive gas pockets, unstable rock
   - Fuel Nodes restore energy; the Refuel Station (midpoint) refuels for minerals
   - Reach the Exit Station to complete the run and bank your minerals

4. **Post-Run — Return to Colony:**
   - Successful surface return: bank all collected minerals
   - Out of fuel: lose all run minerals, return empty to colony
   - Review run statistics and depth reached
   - Unlock new upgrades based on mineral wealth

5. **Meta-Progression Loop:**
   - Spend minerals on permanent carapace, legs, and mandibles upgrades
   - Unlock new mine locations on the overworld
   - Progress colony story through boss encounters and fossil collection
   - Complete achievements for unique colony rewards

### 2.2 Run System

**Mineral Types (by tile yield):**
1. **Soil/Grass** (1 mineral) — Surface layer, no fuel cost
2. **Dirt/Dark Dirt** (1 mineral) — Shallow ground
3. **Stone/Dark Stone** (2 minerals) — Mid-depth rock
4. **Copper Ore / Deep Copper** (3–5 minerals) — Early ore deposits
5. **Iron Ore / Deep Iron** (5–8 minerals) — Mid-depth deposits
6. **Gold Ore / Deep Gold** (10–15 minerals) — Deep veins
7. **Gem Ore / Deep Gem** (20–30 minerals) — Rarest and deepest

**Hazard Tiles (no mineral yield):**
- **Explosive / Armed Explosive** — Detonates in a 3×3 radius, deals damage
- **Lava / Lava Flow** — Instant damage on contact; cannot be mined
- **Fuel Node / Full Fuel Node** — Restores 10 fuel when mined (bonus resource)
- **Refuel Station** — Refills fuel to max for a mineral cost (interact with E)

**Death & Extraction:**
- **Carapace Destroyed (HP → 0):** Lose ALL collected run minerals, return to colony
- **Out of Fuel:** Lose ALL collected run minerals, stranded (transported back)
- **Successful Exit:** Keep everything + depth bonus
- **Risk Tiers:** Deeper tiles yield far better ore but more hazards and higher fuel cost

**Run Modifiers (Unlocked Later):**
- **Ironworker Mode:** +200% mineral yield, permadeath for entire save
- **Speed Dig:** Time limit but massive depth bonus
- **Dark Tunnels:** No minimap, huge mineral multiplier
- **Lean Rations:** Limited fuel capacity, enormous mineral multipliers

### 2.3 Controls
- **Movement:**
  - `W` / `Up Arrow` / `A` / `D` / `S`: Move the ant one tile in that direction
  - Hold direction key: Auto-repeat movement after 0.15s delay
- **Interaction:**
  - `E`: Interact with Refuel Station
  - `Esc`: Pause Menu
- **HUD Indicators:**
  - Upper-left: Minerals collected this run
  - Upper-right: Health squares (carapace HP) and fuel bar

### 2.4 Entities

#### The Ant (Player Character)
The ant is a red forager from the colony, controlled directly by the player. Movement is grid-based — each keypress moves one tile. Entering a tile with ore mines it instantly and adds its minerals to the run total.

**Ant Stats (affected by upgrades):**
- **Carapace (Health):** Base 3 HP; +1 per Carapace upgrade level
- **Legs (Speed/Efficiency):** Affects auto-repeat speed and future fuel efficiency upgrades
- **Mandibles (Mining Power):** Affects damage to special tough tiles and future armored hazards

#### Upgrades (Colony Workshop)
Three permanent upgrade tracks, each with scaling mineral costs (+25 per level):

1. **Harden Carapace** (base cost: 50 minerals)
   - Toughens the ant's exoskeleton
   - Effect: +1 max HP per level (base: 3 HP)
   - Visual: Darker, more armored ant sprite (future)

2. **Strengthen Legs** (base cost: 50 minerals)
   - Builds leg muscle for more efficient underground travel
   - Effect: +30 max movement speed per level (future fuel efficiency)
   - Visual: Longer, more powerful legs (future)

3. **Sharpen Mandibles** (base cost: 50 minerals)
   - Hones the ant's digging claws to a razor edge
   - Effect: +3 mining power per level (used for special tile damage)
   - Visual: Larger, more prominent mandibles (future)

#### Mine Tiles
See Section 2.2 for full tile breakdown. Tile richness is depth-weighted:
- Shallow (rows 3–30): Mostly dirt, occasional copper
- Mid-depth (rows 30–70): Stone, iron, explosive hazards increase
- Deep (rows 70–128): Gold, gems, heavy hazards, fuel nodes become critical

#### NPCs
1. **The Queen** (Colony Hub): Main upgrade vendor, story guide
2. **Elder Forager** (Colony Hub): Mission giver, experienced miner
3. **Colony Archivist** (Colony Hub): Fossil and lore collector
4. **Wandering Trader** (Random Mine Event): Rare item exchange
5. **Lost Worker Ants** (Mine Events): Rescue for colony rewards

## 3. Art & Audio Style

### 3.1 Visual Direction
**Core Art Style:**
- **Format:** Pixel art tiles, crisp sprite-based ant character
- **Tile System:** Individual block sprites with geological variety
- **Color Palette by Depth:**
  - Surface (rows 0–3): Sky blue, green grass
  - Shallow (rows 3–30): Browns and warm soil tones
  - Mid-depth (rows 30–70): Cool greys, stone, orange-copper
  - Deep (rows 70–128): Dark purples, glowing cyan gems, warm gold
- **Style:** Clean pixel art with distinct tile silhouettes for readability
- **Animation:** Ant walk cycle, mining particle dust (future)

**Visual Polish:**
- Sky blue background for surface rows
- Dark near-black background for underground
- White border highlights on interactable tiles (Refuel Station, Exit Station)
- Green EXIT label on Exit Station
- Health: Red squares (filled) / dark grey (lost HP)
- Fuel: 10-segment green bar, greying out as fuel depletes

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
1. **Colony Hub:** Calm ambient, soft insect/nature sounds, gentle percussion
2. **Overworld Map:** Light adventurous theme, wind through tunnels
3. **Mining Level:** Rhythmic underground ambience; tension rises at depth (crickets.mp3 currently)
4. **Boss Fights:** Intense unique themes per encounter
5. **Menu:** Minimal ambient

**Sound Effects (Procedural + Library):**
- **Digging:** Crunching, grinding tone (mandible buzz) — `play_drill_sound()`
- **Mineral Pickup:** Satisfying "clink" chime
- **Explosion:** Deep impact boom — `play_explosion_sound()`
- **Fuel Restore:** Bubbly replenishment tone
- **Damage:** Chitinous impact crack
- **Fuel Low Warning:** Anxious cricket chirp

**Audio Mix:**
- Clear priority: critical SFX > music > ambient
- Volume sliders: Master, Music, SFX

## 4. World Design

### 4.1 The Hub: The Colony
**Layout:**
- **Colony Workshop (Left):** The Queen — Carapace/Legs/Mandibles upgrades
- **Mission Board (Center):** Elder Forager — Daily challenges, bounties, discovery missions
- **Fossil Archive (Right):** Colony Archivist — View collected fossils and colony lore
- **Mine Entrance (Bottom):** Deploy to Overworld map
- **Stats Chamber:** View colony wealth, depth records, achievements

**Atmosphere:**
- Bustling ant colony at the surface
- Tunnels lined with amber and bioluminescent fungi
- Colony members with idle animations and ambient chatter
- Safe zone — no fuel cost, no hazards

**NPC Interactions:**
- Story-driven dialogue about the colony's need for deeper minerals
- Relationship system (unlocks special missions and upgrade discounts)
- Rotating daily quests tied to ore types and depths

### 4.2 Overworld: The Anthill Map
**Structure:**
- **Map Type:** Node-based exploration network
- **Player Token:** The ant moving between mine entrances
- **Mine Unlock:** Complete shallower mines to access deeper ones
- **Caravan Route:** Connected paths between nodes with distance costs

**Mine Nodes (Progressively Deeper/Richer):**
1. **Surface Mound (Node 1)** — Tutorial mine, shallow, mostly dirt and copper
2. **Iron Seam (Node 2)** — First real challenge, iron ore abundant, some explosives
3. **Gold Canyon (Node 3)** — Deep gold veins, lava appears, fuel management critical
4. **Gem Cavern (Node 4)** — Maximum depth, gem ore, high hazard density
5. **Ancient Chamber (Node 5)** — Boss encounter, legendary fossil rewards
6. **The Deep (Node 6)** — Final mine, all hazards combined, ultimate gem deposits

**Node Types (Randomly Generated Per Run):**
- **Rich Vein:** High ore density, low hazards
- **Hazard Zone:** High hazards, bonus mineral multiplier
- **Ancient Site:** Special fossil collectibles, moderate mining
- **Supply Cache:** Fuel nodes abundant, prepare for deep dive
- **Boss Encounter:** Elite creature guarding legendary rewards

### 4.3 Mining Level (Grid-Based Procedural Generation)
**Grid:** 32 columns × 128 rows at 64px per tile (viewport: 1280×720)
- **Right 2 columns:** Exit zone (spawn point and return corridor)
- **Row 0–2:** Surface layer (sky blue, free movement)
- **Row 3:** Grass surface row (1 mineral each)
- **Rows 4–127:** Underground (1 fuel per tile entered)
- **Mid-column:** Refuel Station on surface row
- **Far-right surface:** Exit Station (ends run, banks minerals)

**Procedural Tile Distribution:**
- Depth-weighted: rarer ores become significantly more common deeper
- Hazard rate: 10% at surface edge, grows to 15% at max depth
- Fuel Nodes: ~3% of tiles throughout, critical for deep runs
- Stone density increases with depth (more resistant to quick clear)

**Camera System:**
- Camera2D follows the ant with clamped map boundaries
- Viewport culling renders only visible tiles for performance

**Extraction System:**
- Reach the Exit Station on the surface layer to complete run
- All collected minerals are banked via the Run Summary screen
- Die or run out of fuel → lose run minerals, return to overworld

## 5. Progression System

### 5.1 Mineral Economy
**Primary Currency: Minerals**
- Collected by mining tiles underground
- Lost if the ant dies or runs out of fuel
- Banked permanently on successful exit
- Used for all colony upgrades

**Secondary Collectibles (Planned):**
- **Fossils:** Permanent story collectibles, never lost
- **Rare Crystals:** Mid-tier crafting material, found in deep gem clusters
- **Ancient Artifacts:** Ultra-rare, unlocks special colony chambers

### 5.2 Upgrade System

**Colony Workshop — Three Tracks:**

| Upgrade | Stat | Base Cost | Per Level | Max Levels |
|---------|------|-----------|-----------|-----------|
| Harden Carapace | +1 Max HP | 50 minerals | +25 minerals | 10 |
| Strengthen Legs | +30 move speed | 50 minerals | +25 minerals | 10 |
| Sharpen Mandibles | +3 mining power | 50 minerals | +25 minerals | 10 |

**Future Upgrade Tracks (Planned):**
- **Fuel Sac:** Increases max fuel capacity
- **Mineral Sense:** Shows ore richness of adjacent tiles (passive)
- **Colony Bond:** Buffs near other rescued worker ants

### 5.3 Research Tree (Meta-Progression, Planned)

**Tier 1** (1–5 Colony Points Each):
- Ore Nose: +10% mineral yield from all tiles
- Thick Shell: +5% max HP
- Efficient Stride: −5% fuel consumption
- Quick Mandibles: −10% between-tile dig delay
- Lucky Find: +2% chance to find Rare Crystals

**Tier 2** (5–10 Points Each):
- Deep Sense: Reveal tile types one step ahead
- Armored Segments: +15% damage reduction
- Venom Mandibles: Chain-mine explosive tiles safely
- Extended Fuel Sac: +25% max fuel capacity
- Treasure Instinct: Highlight fossil locations

**Tier 3** (10–20 Points Each):
- Master Forager: +50% all mineral gains
- Indestructible Carapace: Auto-survive one fatal hit per run
- Deep Sight: Full tile map visible from surface
- Extraction Savings: Keep 25% of minerals even on fuel death
- Colony Hero: +30% minerals near colony entrance

## 6. Story & Lore

### 6.1 Premise
The colony has thrived for generations in the shallow earth. But a great drought has dried up the surface food supply and the Queen has decreed: the workers must dig deeper than ever before. Ancient legends speak of vast mineral deposits and bioluminescent gem caverns far below — enough to sustain the colony for centuries.

You are a red forager, one of the most experienced diggers in the colony. The deeper you go, the richer the rewards — but also the stranger the rocks, the hotter the earth, and the older the things buried in it.

### 6.2 Fossil Collectibles (50 Total)
Scattered across all mine depth levels:
- **Surface Fossils (10):** Small insects, leaves, ancient seeds
- **Mid-Depth Fossils (20):** Trilobites, ancient beetles, crystallized honeycomb
- **Deep Fossils (15):** Massive arthropods, unknown creatures, glowing mineral formations
- **Boss Chamber Relics (5):** Ancient colony artifacts, legendary specimens

Each fossil reveals lore about the earth's deep history and grants bonus colony experience.

### 6.3 Boss Encounters (5 Total — Mine Progression)
1. **The Centipede King** (Iron Seam) — HP: 500, multi-segment body
   - Reward: Unlock Gold Canyon + Deep Mine Sense ability
2. **Cave Spider Matriarch** (Gold Canyon) — HP: 800, web-laying ranged attacks
   - Reward: Unlock Gem Cavern + Extended Fuel Sac upgrade
3. **The Blind Mole** (Gem Cavern) — HP: 1200, massive AOE tremor attacks
   - Reward: Unlock Ancient Chamber + Venom Mandibles upgrade
4. **Stone Golem** (Ancient Chamber) — HP: 1500, rock-armored phases
   - Reward: Unlock The Deep + Indestructible Carapace upgrade
5. **The Ancient One** (The Deep — Final Boss) — HP: 2500, three phases
   - Reward: Colony saved, true ending, Legend of the Deep Forager title

## 7. Technical Design

### 7.1 Architecture Overview
```
res://
├── assets/           # Art, Audio, Fonts
├── docs/             # Documentation
├── notes/            # Development notes
└── src/              # Source Code & Scenes
    ├── autoload/     # Global Singletons (GameManager, EventBus, etc.)
    ├── components/   # Reusable Component Nodes
    ├── entities/     # Game Objects (PlayerProbe/Ant, ScrapLoot/Minerals, NPCs)
    ├── levels/       # Game Scenes (Overworld, MiningLevel, CityLevel/Colony)
    ├── systems/      # Systems (ChatterManager, etc.)
    └── ui/           # User Interface (HUD, UpgradeMenu, RunSummary)
```

### 7.2 Key Systems
- **GameManager:** Game state, scene transitions, mineral currency, upgrade levels
- **EventBus:** Decoupled signals (minerals_changed, minerals_earned, fuel_changed, player_health_changed)
- **MiningLevel:** Grid-based world, tile generation, player movement, fuel logic
- **UpgradeMenu:** Colony Workshop UI, carapace/legs/mandibles upgrades
- **HUD:** Minerals counter, health squares, 10-segment fuel bar

### 7.3 Save System
Persistent save via JSON (`user://save_data.json`):
- `mineral_currency` — banked colony minerals
- `carapace_level` — carapace upgrade level (0–10)
- `legs_level` — legs upgrade level (0–10)
- `mandibles_level` — mandibles upgrade level (0–10)

## 8. Glossary

| Term | Definition |
|------|-----------|
| **Minerals** | Primary currency — what the ant collects by mining tiles |
| **Carapace** | Ant's exoskeleton; determines max HP |
| **Legs** | Ant's movement system; determines speed and future fuel efficiency |
| **Mandibles** | Ant's digging claws; determines mining power |
| **Fuel** | The ant's energy reserve; depletes by 1 per underground tile entered |
| **Run** | One mining expedition from colony surface → underground → return |
| **Colony** | The hub area; safe zone where upgrades are purchased |
| **Overworld** | The map of mine entrances and paths between them |
| **Exit Station** | The mine exit on the surface layer; completing a run requires reaching it |
| **Refuel Station** | Mid-mine surface point; refuels for a mineral cost |
| **Fuel Node** | Underground tile that restores 10 fuel when mined |
| **Depth** | How many rows below surface the ant has reached; higher depth = richer ore |
| **Fossil** | Permanent story collectible found underground; never lost on death |
| **Mine Shaft** | A specific mine node on the overworld map |
| **Boss** | Elite underground creature guarding a new mine zone |

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
- Complete a run without using the Refuel Station
- Mine 10 tiles in a single second (mandibles speed)

**Survival (10):**
- Complete a run with 1 HP remaining
- Complete a run without taking any damage
- Survive an explosion (be adjacent to one)
- Escape with 0 fuel remaining
- Complete 10 runs in a row without dying

**Collection (10):**
- Bank 1,000/10,000/100,000 total minerals
- Max out Carapace upgrades
- Max out Legs upgrades
- Max out Mandibles upgrades
- Find a fossil at max depth
