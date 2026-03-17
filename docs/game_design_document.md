# Pickaxe Pioneer - Game Design Document (GDD)
## STEAM RELEASE VERSION - $7.99 Price Point

## 1. Game Overview
**Title:** Pickaxe Pioneer
**Genre:** 2D Side-Scrolling Mining Roguelite
**Theme:** Underground Cat Civilization Mining Adventure
**Engine:** Godot 4.5
**Perspective:** Side-Scrolling 2D (Terraria-style physics)
**Inspiration:** Motherlode, Supermotherlode, Coal LLC, Dwarf Fortress, Path of Exile, ADOM, Noita
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

### 1.2 Design Philosophy

**Difficulty Model: All-or-Nothing (Coal LLC Style)**
Runs are high-stakes. If you die or run out of energy, you lose ALL collected run minerals. There is no mercy mechanic, no partial banking, and no insurance. This creates genuine tension on every dive and makes successful extractions feel earned. The game never punishes permanently (upgrades persist), but each run is a real bet.

**Emotional Tone: Tension-First Progression (A+B Hybrid, Leaning B)**
The moment-to-moment feel is tension — energy ticking down, hazards closing in, the choice to push deeper or surface. But the session-to-session feel is progression — every banked haul buys permanent power, unlocks new systems, and opens new planets. Players should feel the squeeze during runs and the relief/reward between them.

**Experienced Player Shortcut: "Launch Again"**
The Run Summary screen offers a "Launch Again" button that returns the player directly to the Star Chart, bypassing the Clowder hub. This lets experienced players who know their upgrade path chain runs efficiently. New players are expected to return to the Clowder to explore upgrades, NPCs, and story. The hub is never skipped on first visit.

## 2. Gameplay Mechanics

### 2.1 Core Loop

```
┌─────────────────────────────────────────────────────────────────┐
│  CLOWDER HUB ──► STAR CHART ──► SETTLEMENT ──► MINING RUN     │
│       ▲              │              (optional)       │          │
│       │              │                               ▼          │
│       │              └──────── "Launch Again" ◄── RUN SUMMARY  │
│       └──────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

1. **Hub — The Clowder (Spatial, Walkable):**
   - A side-scrolling space station the player physically walks through as their cat
   - **Clowder Workshop (Left):** The Matriarch — Pelt/Paws/Claws/Whiskers upgrades
   - **Mission Board (Center):** Elder Miner — daily challenges, bounties, discovery missions
   - **Fossil Archive (Right):** Clowder Archivist — collected fossils and Clowder lore
   - **Docking Bay (Bottom):** Deploy to Star Chart
   - **Stats Chamber:** Clowder wealth, depth records, achievements
   - NPC interactions, ambient chatter, and lore discovery through exploration
   - Safe zone — no energy cost, no hazards

2. **Overworld — The Star Chart:**
   - Node-based navigation between mine planets, settlement stations, and the Clowder
   - Multiple planets with varying depth, ore richness, and hazard profiles
   - Each planet node has a unique name, atmosphere color, ore mix, and hazard profile
   - Settlement nodes offer pre-run consumables for banked minerals
   - Ship upgrades (Warp Drive, Long Scanner, etc.) affect overworld traversal

3. **Settlement — Rest Stop:**
   - Spend banked minerals on run-scoped consumables before entering a mine
   - Available items: Energy Cache (+50 starting energy), Pelt Patch (+1 HP), Mining Shroom (12 ore-yield charges), Claw Whetstone (+1 claw power)

4. **Mining Run — The Descent:**
   - Spawn at the surface entrance of a mine shaft (96×128 tile grid)
   - Terraria-style physics: gravity, jump, horizontal run; cursor-based mining (left-click within 4.5 tiles)
   - **Scout Cat companion** follows and auto-collects ore (see Section 2.5)
   - Energy depletes with depth; surface movement is free
   - Ore value increases dramatically with depth
   - Hazards: lava flows, explosive gas pockets, unstable rock
   - Energy Nodes restore energy; the Reenergy Station (midpoint) refills for minerals
   - Smelting chain bonuses reward consecutive same-ore mining (see Section 2.6)
   - Wandering Trader appears at milestone depths with rare items
   - Reach the Exit Station to complete the run and bank your minerals

5. **Post-Run — Run Summary:**
   - **Successful exit:** Bank all collected minerals + Scout Cat's banked minerals + depth bonus
   - **Out of energy or HP → 0:** Lose ALL run minerals (all-or-nothing). Failure Summary shows loss recap and contextual tips
   - Review run statistics: ore breakdown, depth reached, chain bonuses, fossils found
   - **"Launch Again" button:** Experienced players skip the Clowder and return directly to Star Chart
   - **"Return to Clowder" button:** Visit hub for upgrades, quests, story progression

6. **Meta-Progression Loop:**
   - Spend minerals on permanent Pelt/Paws/Claws/Whiskers upgrades at the Clowder Workshop
   - Invest perk points in the 6-branch Perk Tree for deeper specialization
   - Build ship upgrades (Warp Drive, Cargo Bay, etc.) for overworld advantages
   - Pay down Father's Debt to advance the story
   - Equip trinkets for passive run bonuses
   - Unlock cosmetics (cat colors, companion followers) via global level
   - Unlock new mine locations on the Star Chart
   - Progress Clowder story through boss encounters and fossil collection

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
  - `F`: Place waypoint marker (directs Scout Cat companion)
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
4. **Wandering Trader** (Random Mine Event): Rare item exchange at milestone depths
5. **Stray Mining Cats** (Mine Events): Rescue for Clowder rewards

### 2.5 Scout Cat Companion (ForagerSystem)

The Scout Cat is an AI-controlled companion that follows the player underground and automatically collects ore chunks from mining.

**Behavior States:**
- **Follow:** Hovers 1.2 tiles behind and 0.5 tiles above the player; sweeps ore chunks within 80px radius every 0.25 seconds
- **Return:** When carry capacity is full (30 minerals), rushes to the surface deposit point at 1.8× normal speed (252 px/s)
- **Deposit:** Waits 1.8 seconds at the surface, banks minerals safely, then returns to follow the player

**Key Stats:**
| Stat | Value |
|------|-------|
| Base carry capacity | 30 minerals |
| Move speed | 140 px/s (252 px/s returning) |
| Collection radius | 80 px |
| Sweep interval | 0.25 seconds |
| Deposit delay | 1.8 seconds |

**Design Intent:** The Scout Cat creates a "safety net" — minerals it banks at the surface are saved even if the player dies. This rewards staying alive long enough for the Scout Cat to make trips, without removing the all-or-nothing tension of the player's own inventory. Bonus capacity from settlement consumables increases its carry cap.

### 2.6 Smelting System (SmeltingSystem)

Mining consecutive tiles of the same ore type builds a **smelting chain** that awards bonus minerals. The chain resets when you mine a different ore type or stop mining for too long.

**Chain Bonuses:**
- Chain 3: +10% mineral yield
- Chain 5: +25% mineral yield
- Chain 8+: +50% mineral yield (cap)

**Alloy Combos:** Mining specific ore sequences (e.g., Iron → Gold → Iron) triggers alloy discovery bonuses — one-time mineral bursts that reward exploration of mixed ore deposits.

### 2.7 Trinket System (TrinketSystem)

Trinkets are equippable one-off items that provide passive bonuses (and sometimes penalties) during mining runs. Each trinket is an independent toggle — equip as many as you want.

**13 Trinkets:**

| ID | Name | Effect | Category |
|----|------|--------|----------|
| paraglider | Paraglider | Slow fall, extended air control | Movement |
| jet_boots | Jet Boots | Short hover burst in midair | Movement |
| spring_boots | Spring Boots | Higher jump height | Movement |
| sneakers | Sneakers | Faster horizontal movement | Movement |
| gecko_gloves | Gecko Gloves | Wall cling and wall jump | Movement |
| boots_of_sprinting | Boots of Sprinting | Sprint speed boost | Movement |
| jumping_bean | Jumping Bean | +20% mining power | Combat |
| magnet | Magnet | Attract ore chunks within 4 tiles | Combat |
| stone_of_regen | Stone of Regeneration | +1 HP every 4 seconds | Survival |
| cube_of_curing | Cube of Curing | Immune to plasma damage | Survival |
| scuba_helmet | Scuba Helmet | Immune to gas pockets | Survival |
| cosmic_radiation | Cosmic Radiation | Random HP/energy swaps every 15s | Chaos |
| curse_of_core | Curse of the Core | -1 HP every 8s underground | Chaos |

**Design Intent:** Trinkets let players customize their run style without permanent commitment. Chaos trinkets appeal to roguelite veterans seeking high-risk modifiers.

### 2.8 Class System (ClassSelectionMenu)

Players choose a starting class when beginning a new game. Classes determine initial stat bonuses and starting equipment.

**10 Classes:**

| # | Class | Unlock |
|---|-------|--------|
| 1 | Pioneer | Level 1 (default) |
| 2 | Prospector | Level 1 |
| 3 | Brawler | Level 1 |
| 4 | Veteran | Level 1 |
| 5 | Scout | Level 1 |
| 6 | Engineer | Level 2 |
| 7 | Alchemist | Level 2 |
| 8 | Sentinel | Level 2 |
| 9 | Wanderer | Level 2 |
| 10 | Phantom | Level 2 |

Classes 1–5 are available immediately; classes 6–10 unlock at global player level 2+. Class selection is shown as a horizontal scrollable row of 10 cards after save slot selection.

### 2.9 Inventory System (InventoryScreen)

Toggled via `I` key during mining runs. Three-section panel:

1. **Slot Grid (10 columns):**
   - First 2 slots: Pickaxe (power scales with Claws) and Ladders (placeable, count tracked)
   - Remaining slots: Ore stacks (max 32 per stack)
   - Drag-and-drop to rearrange slots; hover for tooltip (name, type, stat, description)
   - Base capacity: 20 slots (+25 from Cargo Bay ship upgrade, +2 per Claws level)

2. **Equipment Column:**
   - Pelt / Paws / Claws / Whiskers upgrade levels displayed with level bars

3. **Wallet & Trinkets Column:**
   - Persistent coins, run coins, equipped trinkets list

**Ore Display Order (shallow → deep):**
Space Coal → Lunar Copper → Meteor Iron → Star Gold → Cosmic Diamond

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

### 4.1 The Hub: The Clowder Space Station (Spatial Hub)

The Clowder is a **walkable side-scrolling space station** — the player physically walks through it as their cat character (same controls as mining, minus mining). This grounds the hub in the same world as the mines.

**Layout (Left to Right):**
- **Clowder Workshop:** The Matriarch — Pelt/Paws/Claws/Whiskers upgrades, Perk Tree access
- **Debt Office:** Pay down Father's Debt (see Section 5.5)
- **Mission Board:** Elder Miner — Daily challenges, bounties, discovery missions
- **Ship Hangar:** Ship upgrades (Warp Drive, Cargo Bay, etc.)
- **Fossil Archive:** Clowder Archivist — Collected fossils and Clowder lore
- **Gem Socketing Altar:** Socket gems into Pelt/Paws/Claws/Whiskers for permanent bonuses
- **Stats Chamber:** Clowder wealth, depth records, achievements
- **Docking Bay (Far Right):** Deploy to Star Chart

**Atmosphere:**
- Bustling cat space station humming with activity
- Corridors lined with cat-clan memorabilia and glowing mineral samples
- Clowder NPC members with idle animations and ambient chatter (ChatterManager)
- Safe zone — no energy cost, no hazards
- Cats walk past in the background, reinforcing a living world

**NPC Interactions:**
- Story-driven dialogue about the Clowder's need for minerals to fuel the next jump
- Rotating daily quests tied to ore types and depths
- Quest NPCs placed at fixed stations the player walks to (spatial discovery)

**Progressive Disclosure:**
The Clowder reveals new areas and NPCs as the player progresses:
- **First visit:** Only Workshop, Mission Board, and Docking Bay accessible
- **After first boss:** Fossil Archive unlocks
- **After banking 50,000 minerals:** Ship Hangar unlocks
- **After finding first gem:** Gem Socketing Altar appears
- Systems are introduced one at a time to avoid overwhelming new players

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
**Primary Currency: Minerals (Copper)**
- Collected by mining tiles underground
- Lost if the cat dies or runs out of energy (all-or-nothing)
- Banked permanently on successful exit
- Used for all Clowder upgrades, ship modules, and debt payments
- Internal unit: copper (100 copper = 1 gold display)

**Secondary Currencies:**
- **Gems:** Rare drops from deep gem ore; used for gem socketing (3 gems per socket)
- **Fossils:** Permanent story collectibles, never lost; 50 total across all depths
- **XP:** Earned from mining, depth milestones, and playtime; levels up for perk points

**Milestone Trackers (Persistent):**
- `total_coins_banked` — cumulative minerals ever banked (unlocks ship upgrades)
- `bosses_defeated_total` — total boss encounters won
- `deepest_row_reached` — deepest grid row ever reached (caps at 128)

### 5.2 Upgrade System

**Clowder Workshop — Four Core Tracks:**

| Upgrade | Stat | Base Cost | Per Level | Max Levels |
|---------|------|-----------|-----------|-----------|
| Thicken Pelt | +1 Max HP | 50 minerals | +25 minerals | 10 |
| Strengthen Paws | +30 px/s speed & +25 max energy | 50 minerals | +25 minerals | 10 |
| Sharpen Claws | +3 mining power | 50 minerals | +25 minerals | 10 |
| Refine Whiskers | Larger sonar radius, lower energy/ping | 50 minerals | +25 minerals | 10 |

**Gem Socketing (4 Sockets, 3 Gems Each):**

| Socket | Effect |
|--------|--------|
| Pelt Socket | +1 Max HP |
| Paws Socket | +25 Max Energy, +15 Move Speed |
| Claws Socket | +4 Mining Power |
| Whiskers Socket | +3 Sonar Radius |

### 5.3 Perk Tree (6-Branch, Diablo II Style)

Players earn 1 perk point per level (XP scaling: `level × 100` XP per level). Each perk has prerequisites, max rank, and mineral cost per rank.

**Branch 1 — PELT (Survival):**
| Perk | Effect/Rank | Max Rank | Tier |
|------|-------------|----------|------|
| Pelt | +1 Max HP | 5 | 1 |
| Paws | +25 Max Energy, +30 Move Speed | 5 | 1 |
| Iron Hide | -10% boss energy drain | 5 | 2 |
| Nine Lives | +2 Max HP | 3 | 3 |

**Branch 2 — CLAWS (Mining):**
| Perk | Effect/Rank | Max Rank | Tier |
|------|-------------|----------|------|
| Claws | +3 Mining Power | 5 | 1 |
| Reach | +0.75 Mining Range (tiles) | 5 | 1 |
| Deep Veins | +5% Lucky Strike chance | 5 | 2 |
| Motherlode | +10% ore mineral yield | 3 | 3 |

**Branch 3 — WHISKERS (Utility):**
| Perk | Effect/Rank | Max Rank | Tier |
|------|-------------|----------|------|
| Whiskers | +3 Sonar Radius, -1 ping energy cost | 5 | 1 |
| Cargo Claws | +2 Ore Slots | 5 | 1 |
| Ladder Mastery | +50 Ladder Climb Speed | 5 | 2 |
| Master Scavenger | +10% Fossil find rate | 3 | 3 |

**Branch 4 — SHIP (Overworld):**
| Perk | Effect/Rank | Max Rank | Tier |
|------|-------------|----------|------|
| Thrusters | +15% caravan travel speed | 5 | 1 |
| Nav Charts | +1 extra mining planet per 2 ranks | 4 | 1 |
| Ore Scanner | Preview +1 ore type before landing | 5 | 2 |
| Warp Mastery | -15% warp energy cost & travel time | 3 | 3 |

**Branch 5 — MOVEMENT (Mobility):**
| Perk | Effect/Rank | Max Rank | Tier |
|------|-------------|----------|------|
| Agility | +10% jump height | 5 | 1 |
| Double Jump | +1 air jump | 3 | 1 |
| Soft Landing | -10% fall damage | 5 | 2 |
| Momentum | +20% sprint speed | 3 | 3 |

**Branch 6 — INVENTORY (Storage):**
| Perk | Effect/Rank | Max Rank | Tier |
|------|-------------|----------|------|
| Satchel | +3 inventory slots | 5 | 1 |
| Stack Mastery | +8 max stack size | 5 | 1 |
| Deep Satchel | +5 inventory slots | 5 | 2 |
| Packrat | +3 slots & +10 max stack | 3 | 3 |

**Prerequisite System:** Tier 2 perks require their parent perk at a minimum rank. Tier 3 perks require their Tier 2 parent at a minimum rank. Each rank costs minerals (300–3000 depending on tier).

### 5.4 Ship Upgrades (Spaceship System)

Five permanent ship modules purchased at the Ship Hangar in the Clowder:

| Module | Cost | Unlock Condition | Effect |
|--------|------|------------------|--------|
| Warp Drive | 20,000 copper (200g) | 50,000 total banked | 2× caravan travel speed |
| Cargo Bay | 15,000 copper (150g) | 1 boss defeated | +25 ore carrying capacity |
| Long Scanner | 30,000 copper (300g) | 100,000 total banked | Always show both asteroid mines on overworld |
| Gem Refinery | 25,000 copper (250g) | — | +1 bonus gem per gem ore mined |
| Trade Amplifier | 20,000 copper (200g) | Reached row 96 | +25% payout when selling bars |

### 5.5 Father's Debt

**Total Debt:** 50,000,000 copper (5,000 gold)

The central story arc. Your father left you his ship, his routes, and a massive debt to the Clowder. Pay it off incrementally via the Debt Office in the Clowder hub. Debt progress unlocks story beats, NPC dialogue changes, and new Clowder areas.

### 5.6 Cosmetic Progression

**Cat Customization (CustomizationMenu — X key):**
- Two independent color layers: BASE tint (multiply shader) and OUTLINE replacement
- **52 color swatches:** 4 free at Level 1; remaining 48 unlock gradually (every ~2 global levels up to Level 100)
- Applied via `cat_color.gdshader` with live preview (idle animations, clickable "scared" reaction)
- Persisted across saves via `cat_color` and `cat_outline_color` in GameManager

**Companion Followers (HatMenu — C key):**
- 20 cosmetic companion creatures that follow the Mining Cat during runs
- Displayed in a paginated 3×2 grid (6 per page)
- Unlock by global player level (2 per level, from Level 1 to Level 10)
- Companions: Leaf Elemental, Ice Elemental, Baby Observer, Magic Book, Bulldog, Cactus, Goblin Carrier, Cherub, Dog Chest, Magic Cloud, Draco, Doppelganger Egg, Hive, Stubby Lizard, Elemental Orbs, Rolling Stone, Shadow, Flying Skull, Sprite, Enchanted Sword

**Global Level System:**
- `global_player_xp` and `global_player_level` stored in a separate file (`global_progress.json`)
- Progression persists across all save slots
- Unlocks cosmetic colors, companion followers, and advanced classes
- Playtime XP: +1% of next level every 25 minutes of play (afk-friendly)

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

Each fossil reveals lore about the planet's deep history and grants bonus XP toward global level progression.

### 6.3 Boss Encounters (5 Total — Depth Milestones)
All bosses are defeated using the player's existing tools — no separate combat system. Energy drains 2.5× while a boss is alive; defeating one rewards 100 minerals + 30 energy.

1. **Giant Rat King** (row 32) — multi-segment horizontal body; mine through segments to reach and destroy the core
2. **Void Spider Matriarch** (row 64) — diamond/cross body spawned below player; mine void-web segments to reach the core
3. **The Blind Mole** (row 96) — tremor AoE collapses nearby empty tiles; warning overlay telegraphs incoming tremor
4. **Stone Golem** (row 112) — three ore-phase armor (copper → iron → gold); player must last-mine the required ore type to crack each phase
5. **The Ancient Star Beast** (row 128) — three-phase final boss: outer stone-shell ring (phase 1), crystalline inner ring with void pulses that reseal mined tunnels (phase 2), exposed regenerating core (phase 3); 2× energy drain throughout

### 6.4 Intro Sequence (First-Time Only)

A skippable **3-card narrative intro** establishing the mining-cat fantasy. Shown once on first new game before the Overworld loads. Press any key to advance; ESC skips.

**Story Cards:**
1. *"Your father never came back from the frontier. He left you his ship, his routes... and a debt to the Clowder you didn't ask for."*
2. *"The Clowder always collects. Fourteen days. Not a moment more."*
3. *"Somewhere out there, ore waits in the dark. Mine it. Sell it. Survive. The rest you'll figure out."*

**Timing:** 0.8s fade in → 4.5s hold → 0.5s fade out per card (5.8s total per card). Sets `has_seen_intro = true` after completing.

### 6.5 Failure Summary (Death Screen)

When the player dies or runs out of energy, a contextual failure screen appears:

- **Header:** "OUT OF ENERGY" or "LOST IN SPACE" (red title)
- **Ore table:** Material breakdown with icon, count, and lost coins
- **Total loss line:** Shows total minerals lost
- **Contextual tip:** Random tip from a pool of 5 energy tips or 5 death tips
- **"Return to Station" button:** Dismisses and returns player to Clowder

**Example Tips:**
- Energy: "Watch your energy bar — surface before it's too late"
- Death: "Upgrade your Pelt to survive more hits"

## 7. Technical Design

### 7.1 Architecture Overview
```
res://
├── assets/           # Art, Audio, Fonts
├── docs/             # Documentation (GDD, architecture, best practices)
├── notes/            # Living development backlog
└── src/
    ├── autoload/     # Global Singletons
    │   ├── GameManager.gd      # Game state, save/load, currency, upgrades, energy
    │   ├── EventBus.gd         # Global signal bus for cross-system communication
    │   ├── SoundManager.gd     # Procedural SFX via AudioStreamGenerator
    │   ├── MusicManager.gd     # Adaptive music with scene crossfading
    │   ├── SettingsManager.gd  # Graphics, audio, controls, accessibility
    │   ├── SceneTransition.gd  # Animated scene transitions
    │   ├── SaveManager.gd      # Save/load coordination (JSON)
    │   └── QuestManager.gd     # Quest system (cleared on mine entry)
    ├── components/   # Reusable node components
    ├── entities/     # Game objects (player, NPCs, loot, overworld tokens)
    ├── levels/       # Scene controllers (Overworld, MiningLevel, CityLevel, SettlementLevel)
    ├── systems/      # Extracted subsystems (all RefCounted)
    │   ├── SmeltingSystem.gd        # Consecutive ore chain bonuses and alloy combos
    │   ├── FossilSystem.gd          # Fossil drops with forgiveness/pity counter
    │   ├── SonarSystem.gd           # Sonar ping — radial ore shimmer, energy cost
    │   ├── ForagerSystem.gd         # Scout Cat companion — auto-collects and banks ore
    │   ├── BossSystem.gd            # Five depth-milestone boss encounters
    │   ├── BossRenderer.gd          # Draw calls for BossSystem
    │   ├── TrinketSystem.gd         # 13 equippable passive trinkets
    │   ├── PerkSystem.gd            # 6-branch perk tree (24 perks)
    │   ├── CatSystem.gd             # Cat-specific behaviors and stat helpers
    │   ├── ChatterManager.gd        # Ambient NPC chatter bubble text pool
    │   ├── MiningTerrainGenerator.gd # Procedural tile grid generation
    │   └── VoronoiBGSystem.gd       # Procedural darkness strata (Voronoi noise)
    └── ui/           # UI controllers
        ├── HUD, RunSummary, FailureSummary
        ├── UpgradeMenu, PerkTree
        ├── InventoryScreen, HatMenu, CustomizationMenu
        ├── ClassSelectionMenu, IntroSequence
        └── LevelInfoModal, SettingsMenu
```

### 7.2 Key Systems

**Autoloads (Global Singletons):**
- **GameManager:** Central game state, save/load, mineral currency, all upgrade tracks, energy, ship upgrades, debt tracking, class selection, settlement carry-overs
- **EventBus:** Decoupled signals — `game_state_changed`, `minerals_changed`, `minerals_earned`, `energy_changed`, `player_health_changed`, `player_died`
- **SoundManager / MusicManager:** Procedural SFX generation + adaptive music with crossfading
- **SaveManager:** JSON save/load coordination (`user://save_data.json` per slot + `global_progress.json` cross-slot)
- **QuestManager:** Quest tracking, cleared on mine entry to prevent stale quest state

**Mining Systems (RefCounted, instantiated per run):**
- **SmeltingSystem:** Consecutive ore chain bonuses (3/5/8+ chains) and alloy combo discovery
- **FossilSystem:** Fossil drop probability with forgiveness pity counter per block type
- **SonarSystem:** Sonar ping — radial ore detection, energy cost per activation, Whiskers-scaled
- **ForagerSystem:** Scout Cat companion — follows player, auto-collects ore, banks at surface
- **BossSystem + BossRenderer:** Five depth-milestone encounters with phase management and energy drain
- **VoronoiBGSystem:** 55-seed Voronoi noise generates organic darkness strata per planet
- **MiningTerrainGenerator:** Procedural tile grid generation (depth-weighted ore distribution)

**Progression Systems (RefCounted):**
- **PerkSystem:** 6-branch skill tree with 24 perks, prerequisite validation, mineral cost per rank
- **TrinketSystem:** 13 toggleable passive trinkets with bonus/penalty effects
- **CatSystem:** Cat stat aggregation from upgrades, perks, gems, trinkets, and class bonuses

**UI Systems:**
- **InventoryScreen:** 3-section drag/drop inventory with ore stacks, equipment, and trinkets
- **HatMenu:** 20 cosmetic companion followers (paginated grid, level-gated)
- **CustomizationMenu:** 52-swatch cat color picker (base tint + outline, shader-based)
- **ClassSelectionMenu:** 10-class horizontal card selector for new games
- **IntroSequence:** 3-card skippable narrative intro (first play only)
- **FailureSummary:** Death/energy-loss recap with contextual tips

### 7.3 Save System
**Per-Slot Save** (`user://save_data.json`):
- `mineral_currency` — banked minerals
- `carapace_level` / `legs_level` / `mandibles_level` / `mineral_sense_level` — upgrade levels (0–10)
- `gem_count`, `carapace_gem_socketed`, `legs_gem_socketed`, `mandibles_gem_socketed`, `sense_gem_socketed` — gem state
- `warp_drive_built`, `cargo_bay_built`, `long_scanner_built`, `gem_refinery_built`, `trade_amplifier_built` — ship modules
- `debt_paid` — copper paid toward Father's Debt (of 50,000,000 total)
- `total_coins_banked`, `bosses_defeated_total`, `deepest_row_reached` — milestone trackers
- `player_class`, `player_xp`, `player_level`, `perk_points`, `perk_ranks` — class and perk state
- `trinket_<id>` booleans — equipped trinkets
- `cat_color`, `cat_outline_color` — customization
- `equipped_companions` — companion follower selection

**Global Progress** (`user://global_progress.json` — cross-slot):
- `global_player_xp`, `global_player_level` — unlocks cosmetics and advanced classes across all saves
- Playtime XP: +1% of next level every 25 minutes

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
- Complete all Clowder quests

**Mining Mastery (15):**
- Mine 100/500/1000 total tiles
- Reach max depth (row 128) in a single run
- Mine a gem ore tile for the first time
- Complete a run without using the Reenergy Station
- Mine 10 tiles in a single second (Claws speed)

**Survival (10):**
- Complete a run with 1 HP remaining
- Complete a run without taking any damage
- Survive an explosion (be adjacent to one)
- Escape with 0 energy remaining
- Complete 10 runs in a row without dying

**Collection (10):**
- Bank 1,000/10,000/100,000 total minerals
- Max out Pelt upgrades
- Max out Paws upgrades
- Max out Claws upgrades
- Find a fossil at max depth

## 10. Progressive Disclosure

Systems are introduced gradually to avoid overwhelming new players:

| Milestone | System Unlocked |
|-----------|----------------|
| Game start | Core mining, basic upgrades (Pelt/Paws/Claws/Whiskers), Star Chart |
| First successful extraction | Mission Board, Run Summary "Launch Again" button |
| First boss defeated (row 32) | Fossil Archive, Boss lore entries |
| 50,000 total minerals banked | Ship Hangar (Warp Drive available) |
| First gem found | Gem Socketing Altar |
| Global Level 2 | Advanced classes (6–10), additional companion followers |
| First perk point earned | Perk Tree (6 branches revealed progressively) |
| First trinket found | Trinket slots in Inventory Screen |

**Design Principle:** Every new system is introduced with a brief in-world prompt from an NPC or a contextual tooltip. No system is shown before the player has a reason to engage with it.

## 11. Juice & Polish

### 11.1 Visual Feedback
- **Smelting chain indicator:** Floating multiplier text above player during ore chains (×1.1, ×1.25, ×1.5)
- **Scout Cat banking animation:** Scout Cat visibly rushes to surface with sparkle trail; mineral count pops when deposited
- **Boss HP overlay:** Segmented health bar appears above boss encounter area
- **Failure screen:** Panel slides up with staggered row animation; border color pulses red
- **Run Summary:** Ore rows animate in sequence with running total counter

### 11.2 Audio Cues
- **Energy low warning:** Anxious cat meow at 20% energy
- **Smelting chain:** Ascending pitch chimes for each consecutive chain hit
- **Boss encounter:** Unique music per boss; rumble SFX on tremor attacks
- **Mineral banking:** Satisfying "ka-ching" with coin cascade SFX

### 11.3 Procedural Planet Atmosphere
Each planet's atmosphere color is automatically derived from its sprite art:
- `MapNode.get_average_pixel_color()` samples the planet sprite's average RGB
- `MiningLevel._draw()` uses this as the sky strip color
- Underground gradient darkens from 75% → 96% with depth
- Result: every planet feels unique without any hardcoded colours

### 11.4 Voronoi Background Strata
Underground darkness varies organically per planet:
- 55 Voronoi seed points scattered across the grid (seeded from `terrain_seed`)
- Each tile gets a darkness value (0.0–1.0) via quadratic ease-in from nearest seed
- Background TileMapLayer selects normal vs. dark tile atlas variants
- Creates organic rock-strata patches unique to each planet
