# Pickaxe Pioneer - Game Design Document (GDD)
## STEAM RELEASE VERSION - $3-5 Price Point

## 1. Game Overview
**Title:** Pickaxe Pioneer
**Genre:** 2D Top-Down Mining Action-Roguelite
**Theme:** Post-Apocalyptic Earth Wasteland
**Engine:** Godot 4.5
**Perspective:** Top-Down (2D)
**Target Playtime:** 5-12 hours (first completion), 15-25+ hours (100% completion)
**Target Platforms:** Steam (Windows/Linux/Mac), Itch.io

### 1.1 High Concept
*"Survive the wasteland, one mining run at a time."*

In a shattered Earth where civilization has collapsed, you pilot a jury-rigged "Scrap Bulldozer" through irradiated wastelands. Mine valuable resources from debris fields, battle mutant hordes, upgrade your rig, and uncover the mystery of what destroyed the world—all while managing risk vs. reward in tense extraction-based runs.

**Core Pillars:**
1. **Risk/Reward Extraction:** Every run is a gamble—push deeper for better loot or extract early to keep your haul
2. **Satisfying Progression:** Permanent upgrades, unlocks, and meta-progression create a sense of growing power
3. **Environmental Storytelling:** Discover the world's dark past through collectible logs, NPC dialogue, and environmental clues
4. **Skill-Based Action:** Physics-based controls and tactical combat reward player mastery

## 2. Gameplay Mechanics

### 2.1 Core Loop (Enhanced for Steam Release)
1. **Hub - New Meridian City:**
   - View stats, achievements, and total progression
   - Access the Upgrade Workshop (permanent vehicle upgrades)
   - Visit the Outfitter (unlock new equipment and abilities)
   - Check the Mission Board (daily challenges, bounties, story missions)
   - Read discovered Logs in the Archive (lore collectibles)
   - Talk to NPCs for story progression and side quests
   - Manage loadout and prepare for runs

2. **Overworld - Wasteland Map:**
   - Navigate between 5+ distinct biome regions
   - Choose run difficulty and expected rewards
   - Encounter random events (traders, ambushes, shortcuts)
   - Unlock new zones by completing story milestones
   - Fast travel to previously visited extraction points

3. **Mining Run - The Extraction Loop:**
   - Deploy into procedurally-generated scrap fields
   - Mine resources (Common Scrap → Rare Components → Legendary Artifacts)
   - Battle escalating enemy waves (Mutants, Drones, Turrets, Bosses)
   - Find and collect data logs (lore + bonus rewards)
   - Discover hidden caches and secret areas
   - Decide when to extract: push deeper for better loot vs. survive to keep it
   - Call extraction and defend the zone while waiting for pickup

4. **Post-Run - Risk/Reward Resolution:**
   - Banking earned resources (only if you extracted successfully)
   - Reviewing run statistics and performance
   - Unlocking new equipment/upgrades based on achievements
   - Story progression through discovered logs
   - Daily/weekly challenge completion rewards

5. **Meta-Progression Loop:**
   - Spend resources on permanent upgrades
   - Unlock new vehicle chassis and weapon types
   - Progress story through boss defeats and log collection
   - Complete achievements for unique rewards
   - Master increasingly difficult runs and modifiers

### 2.2 Run System (Expanded)

**Resource Types:**
1. **Common Scrap** - Basic currency, abundant
2. **Rare Components** - Mid-tier upgrades, found in clusters
3. **Legendary Artifacts** - Rare unlocks, guarded by elites/bosses
4. **Data Logs** - Story progression, always kept even on death
5. **Research Points** - Meta-currency for permanent skill tree upgrades

**Death & Extraction:**
- **Hull Destroyed:** Lose ALL collected resources except Data Logs
- **Successful Extraction:** Keep everything + bonus for no deaths
- **Emergency Extraction:** Can call extract anywhere but lose 50% of resources and gain no bonus
- **Risk Tiers:** Deeper zones have better loot but higher enemy density

**Run Modifiers (Unlocked Later):**
- **Ironman Mode:** +200% rewards, permadeath for entire save
- **Speed Run:** Time limit but massive bonus
- **Horde Mode:** Endless waves, extract when you dare
- **Hardcore Scarcity:** Limited ammo/fuel, huge multipliers

### 2.3 Controls
- **Movement:**
  - `W` / `Up Arrow`: Thrust forward
  - `S` / `Down Arrow`: Reverse thrust (slower)
  - `A` / `Left Arrow`: Rotate Left
  - `D` / `Right Arrow`: Rotate Right
  - `Shift`: Boost (consumes fuel)
- **Combat:**
  - `Left Mouse` / `Space`: Fire Primary Weapon
  - `Right Mouse` / `Ctrl`: Fire Secondary Weapon (unlockable)
  - `Q`: Deploy Utility Item (mines, shields, etc.)
  - `R`: Reload / Cool down
- **Interaction:**
  - `E`: Interact / Talk to NPCs / Collect
  - `F`: Call Extraction (when in safe zone)
  - `Tab`: Open Map/Objectives overlay
  - `Esc`: Pause Menu
- **HUD:**
  - `1-4`: Quick-select utility items
  - `M`: Toggle full map
  - `L`: View collected logs

### 2.4 Entities (Expanded for Full Release)

#### Player Vehicles (3 Unlockable Chassis)
1. **Scrap Bulldozer (Default):**
   - Balanced stats, good armor
   - Special: Can ram through small obstacles
   - Visual: Brown tracked vehicle with reinforced blade

2. **Hover Scout (Unlock: Defeat 50 enemies):**
   - High speed, low armor
   - Special: Strafe movement (A/D strafe instead of rotate)
   - Visual: Sleek blue hovering craft

3. **Heavy Hauler (Unlock: Extract 10,000 scrap):**
   - Slow, massive armor, +50% loot magnetism
   - Special: Deploy portable shields
   - Visual: Massive red industrial rig

**Upgradeable Systems (All Chassis):**
- Hull (Health: 100 → 300)
- Engine (Speed: 300 → 600)
- Primary Weapon (Damage: 10 → 50)
- Secondary Weapon Slot (Unlockable)
- Utility Slots (0 → 4)
- Fuel Capacity (Boost duration)
- Magnet Radius (Loot collection range)

#### Resources & Collectibles
1. **Common Scrap Piles:** Basic destructible debris
   - HP: 20, drops 3-5 scrap
   - Variants: Metal, plastic, electronic

2. **Rare Component Nodes:** Hardened structures
   - HP: 60, drops 1-2 rare components
   - Requires upgraded weapons to mine efficiently
   - Glowing orange/purple crystals

3. **Legendary Artifact Caches:** Hidden vault-like structures
   - HP: 150, drops 1 legendary artifact
   - Often guarded by elite enemies
   - Distinctive visual markers (golden glow, warning signs)

4. **Data Logs:** Collectible lore items
   - 50+ logs scattered across all zones
   - Permanent collection (kept on death)
   - Each reveals story fragments and grants bonus XP

5. **Environmental Hazards:**
   - Radioactive pools (damage over time)
   - Explosive barrels (destroy for area damage)
   - Toxic gas vents (periodic damage)
   - Collapsing structures (timed destruction)

#### Enemy Types (Progressive Threat)

**Tier 1: Early Game (Zones 1-2)**
1. **Feral Mutants:**
   - HP: 30, Contact damage
   - Random wandering, aggressive when player is near
   - Drop: 5 scrap

2. **Raider Drones:**
   - HP: 40, Ranged laser shots
   - Circle and strafe player
   - Drop: 10 scrap, 5% chance rare component

**Tier 2: Mid Game (Zones 3-4)**
3. **Armored Mutants:**
   - HP: 80, Heavy contact damage + knockback
   - Charge attacks toward player
   - Drop: 15 scrap, rare components

4. **Turret Nests:**
   - HP: 120, Rapid-fire projectiles
   - Stationary but high damage
   - Drop: 25 scrap, blueprint fragments

5. **Scavenger Mechs:**
   - HP: 100, Melee swipes
   - Fast movement, flank player
   - Drop: 20 scrap, rare components

**Tier 3: Late Game (Zones 5+)**
6. **Elite Hunters:**
   - HP: 200, Homing missiles
   - Intelligent AI, dodge attacks
   - Drop: 50 scrap, legendary artifacts (10%)

7. **Hive Spawners:**
   - HP: 150, Spawn small mutants
   - Priority target in combat
   - Drop: 40 scrap, guaranteed rare component

**Boss Enemies (5 Total - Story Progression)**
1. **The Scrap King** (Zone 2 Boss)
   - HP: 500, Multi-phase fight
   - Spawns minions, charges, area attacks
   - Reward: Unlock Hover Scout + Story Log

2. **Drone Mother** (Zone 3 Boss)
   - HP: 800, Flying boss with laser grid
   - Summons drone waves
   - Reward: Secondary weapon slot + Story Log

3. **The Irradiated Colossus** (Zone 4 Boss)
   - HP: 1200, Massive mutant with AOE radiation
   - Weak points on limbs
   - Reward: Heavy Hauler chassis + Story Log

4. **Corrupted AI Core** (Zone 5 Boss)
   - HP: 1500, Hacking attacks disable vehicle systems
   - Phases between vulnerable and shielded states
   - Reward: Ultimate weapon blueprint + Story Log

5. **The Architect** (Final Boss - Zone 6)
   - HP: 2500, Uses all previous boss mechanics
   - Three phases with environmental hazards
   - Reward: Game completion, true ending unlock

#### NPCs & Story Characters
1. **Chief Engineer Torres (Hub):** Upgrade vendor
2. **Scout Captain Ryn (Hub):** Mission giver
3. **Archivist Kael (Hub):** Lore/log collector
4. **Mysterious Trader (Random Event):** Special items
5. **Survivor NPCs (Zones):** Rescue for rewards
6. **Rival Scavengers (Zones):** Can fight or trade

## 3. Art & Audio Style

### 3.1 Visual Direction (Steam Quality)
**Core Art Style:**
- **Format:** High-quality vector SVG with hand-polished details
- **Resolution:** Crisp at all display sizes (4K support)
- **Color Palette by Zone:**
  - Zone 1-2: Dusty browns, rusted oranges, sand yellows
  - Zone 3-4: Toxic greens, radioactive purples, industrial grays
  - Zone 5-6: Dark blues, electric cyan, corrupted reds
- **Style:** Geometric post-apocalyptic with detailed textures and weathering effects
- **Animation:** Smooth 60 FPS throughout, with quality particle systems

**Visual Polish Requirements:**
- **Parallax Backgrounds:** 4-6 layers per zone with atmospheric depth
- **Screen Shake:** Context-sensitive (hits, explosions, boss moves)
- **Lighting:** Dynamic glow effects for weapons, hazards, and artifacts
- **Weather Effects:** Zone-specific (dust storms, acid rain, radiation fog)
- **Destruction:** Satisfying particle explosions with debris physics
- **UI Polish:** Animated transitions, hover effects, satisfying button feedback

**Particle Systems:**
- Scrap destruction (metal shards, dust clouds)
- Blood splatter (mutant damage, directional)
- Engine exhaust (thrust indicators, boost trails)
- Weapon fire (lasers, projectiles, impacts)
- Environmental (radiation, toxic gas, sparks)
- Loot magnetism (swirling collection trails)
- Boss attacks (unique per boss)

**Accessibility Features:**
- Colorblind modes (3 presets)
- High contrast option
- Particle density settings
- Screen shake intensity slider

### 3.2 Audio Design (Professional Quality)

**Music Layers (Dynamic/Adaptive):**
1. **Hub - New Meridian:**
   - Safe, melancholic acoustic guitar
   - Subtle industrial ambience
   - NPCs add musical stingers

2. **Overworld:**
   - Dark ambient drones
   - Desolate wind and distant echoes
   - Tension builds near dangerous zones

3. **Mining Zones (Adaptive Combat Layers):**
   - **Exploration:** Low-key industrial rhythms
   - **Combat:** Intense techno/metal hybrid
   - **Boss Fights:** Unique themes per boss (5 total)
   - **Extraction:** Victory fanfare layered over tension

4. **Menu/UI:**
   - Minimal ambient soundscapes
   - Satisfying UI interaction sounds

**Sound Effects (Professional SFX Library + Procedural):**
- **Vehicle:**
  - Engine rumble (dynamic pitch based on speed)
  - Boost activation/sustain/depletion
  - Damage impacts, hull warnings
  - Movement on different terrain types

- **Combat:**
  - Primary weapons (laser, ballistic, energy - 5+ types)
  - Secondary weapons (missiles, flamethrower, etc.)
  - Enemy attacks (unique per enemy type)
  - Shield hits, deflections
  - Explosions (small, medium, large, environmental)

- **Collection:**
  - Scrap pickup (satisfying "clink")
  - Rare component (special chime)
  - Legendary artifact (epic fanfare)
  - Data log (mysterious tech sound)

- **UI/Feedback:**
  - Menu navigation
  - Purchase confirmations
  - Achievement unlocks
  - Level up/upgrade complete
  - Warning/alert sounds

**Audio Mix:**
- Clear priority hierarchy (voice > critical SFX > music)
- Dynamic range compression for intense moments
- Spatial audio for directional awareness
- Smooth crossfading between zones (2s fade)
- Volume sliders: Master, Music, SFX, Voice

## 4. World Design

### 4.1 The Hub: New Meridian City
**Layout:**
- **Workshop (Left):** Chief Engineer Torres - Vehicle upgrades
- **Outfitter (Right):** Equipment and loadout customization
- **Mission Board (Center):** Daily challenges, bounties, story missions
- **Archive (Upper Right):** Archivist Kael - View collected logs and lore
- **Launch Pad (Bottom):** Deploy to Overworld map
- **Stats Terminal:** View global stats, achievements, leaderboards

**Atmosphere:**
- Last bastion of human civilization
- Makeshift structures built from salvaged materials
- NPCs with idle animations and ambient dialogue
- Day/night cycle (cosmetic only)
- Ambient sounds: generator hum, distant radio chatter, wind

**NPC Interactions:**
- Story-driven dialogue trees
- Relationship system (unlocks special missions and discounts)
- Rotating daily quests
- Hints about hidden secrets in zones

### 4.2 Overworld: The Wasteland Map
**Structure:**
- **Map Type:** Node-based exploration network (think FTL meets Slay the Spire)
- **Player Token:** Caravan vehicle that moves between nodes
- **Zone Progression:** Linear unlock (complete Zone 1 to access Zone 2, etc.)
- **Fast Travel:** Unlocked extraction points accessible instantly

**6 Major Zones:**
1. **The Rust Belt (Zone 1)** - Tutorial area, low threat
2. **Scrapyard Expanse (Zone 2)** - First boss, moderate threat
3. **Toxic Wastes (Zone 3)** - Hazard introduction, high threat
4. **Irradiated Core (Zone 4)** - Environmental hazards intensify
5. **Machine Graveyard (Zone 5)** - Elite enemies, rare loot
6. **The Nexus (Zone 6)** - Final boss area, maximum threat

**Node Types (Randomly Generated Per Run):**
- **Combat:** Guaranteed enemy waves
- **Mining:** High resource density, low enemies
- **Elite:** Mini-boss encounter, high rewards
- **Event:** Random scenarios (trader, survivor, ambush, treasure)
- **Rest:** Safe zone to repair/resupply (limited uses)
- **Extraction:** Banking point (can leave and resume later)

**Random Events:**
- Merchant: Buy/sell items at special rates
- Distress Signal: Save NPC for reward
- Ambush: Surprise enemy attack
- Abandoned Cache: Free loot but potential trap
- Rival Scavenger: Fight, trade, or ally temporarily

### 4.3 Mining Levels (Procedural Generation)
**Layout System:**
- **Size:** 5-8 screen widths, varies by zone
- **Generation:** Seed-based procedural with hand-crafted elements
- **Biome Variations:** Each zone has 3-5 visual variants
- **Landmarks:** Optional objectives (secret caches, mini-bosses)

**Camera System:**
- Smooth following with configurable deadzone
- Zoom out during boss fights
- Shake effects on impacts
- Minimap in corner shows full level layout

**Dynamic Difficulty:**
- Enemy count scales with time in level
- Warning system before major spawns
- Risk/reward: Stay longer = more loot + harder enemies

**Zone-Specific Mechanics:**
1. **Rust Belt:** Basic obstacles, simple layouts
2. **Scrapyard:** Multi-level terrain, destructible cover
3. **Toxic Wastes:** Poison pools, gas vents
4. **Irradiated Core:** Radiation damage, shield-draining zones
5. **Machine Graveyard:** Laser grids, automated defenses
6. **The Nexus:** All previous hazards combined

**Extraction System:**
- Must reach designated extraction zone
- Call pickup using F key
- Defend for 30-60 seconds while evac arrives
- Enemies spawn in waves during defense
- Successful extraction = full loot kept + bonus

## 5. Progression System (Multi-Layered)

### 5.1 Currency Economy
**Primary Currencies:**
1. **Common Scrap** (💰)
   - Basic currency for upgrades
   - Lost on death unless extracted
   - Earned from all sources

2. **Rare Components** (⚙️)
   - Mid-tier currency for advanced upgrades
   - Lost on death unless extracted
   - Earned from rare nodes, elite enemies, bosses

3. **Legendary Artifacts** (✨)
   - Ultra-rare for unique unlocks
   - Lost on death unless extracted
   - Earned from secret caches, bosses, achievements

4. **Research Points** (🔬)
   - Meta-progression currency
   - **NEVER LOST** - permanent even on death
   - Earned slowly from runs, achievements, daily challenges
   - Used for passive skill tree

5. **Data Logs** (📄)
   - Story collectibles
   - **NEVER LOST** - permanent collection
   - 50+ total to find
   - Each reveals lore + small XP bonus

### 5.2 Vehicle Upgrade System
**Three Upgrade Categories:**

**A) Linear Stat Upgrades (Common Scrap)**
Each upgrade has 10 levels:

1. **Hull Plating:**
   - Cost: 50, 100, 200, 400, 800, 1600, 3200, 6400, 12800, 25000
   - Effect: +20 HP per level (100 → 300 HP)

2. **Engine Power:**
   - Cost: 50, 100, 200, 400, 800, 1600, 3200, 6400, 12800, 25000
   - Effect: +30 speed per level (300 → 600 speed)

3. **Fuel Capacity:**
   - Cost: 75, 150, 300, 600, 1200, 2400, 4800, 9600, 19200, 38000
   - Effect: +2s boost duration per level (5s → 25s)

4. **Magnet Radius:**
   - Cost: 100, 200, 400, 800, 1600, 3200, 6400, 12800, 25600, 50000
   - Effect: +10% loot collection range per level

5. **Shield Recharge:**
   - Cost: 200, 400, 800, 1600, 3200, 6400, 12800, 25600, 51200, 100000
   - Effect: -10% recharge delay per level (unlocked after Zone 2)

**B) Weapon Unlocks (Rare Components + Scrap)**

**Primary Weapons:**
1. **Mining Laser (Default):** Continuous beam, good vs. structures
2. **Ballistic Cannon:** High damage shots, slow fire rate (100 Components)
3. **Plasma Repeater:** Rapid fire, medium damage (150 Components)
4. **Arc Welder:** Chain lightning, multi-target (200 Components)
5. **Railgun:** Piercing high-damage, long cooldown (300 Components)

**Secondary Weapons (Unlock via Boss Defeats):**
1. **Missile Pod:** Homing rockets (Defeat Zone 2 Boss)
2. **Flamethrower:** Close-range AOE (Defeat Zone 3 Boss)
3. **EMP Burst:** Stun enemies, disable turrets (Defeat Zone 4 Boss)
4. **Nanite Swarm:** DOT, healing on kill (Defeat Zone 5 Boss)

**Utility Items (Rare Components):**
1. **Repair Kit:** Heal 50 HP (20 Components each, stackable)
2. **Shield Booster:** Temporary invulnerability (50 Components)
3. **Proximity Mines:** Deployable traps (30 Components, stack of 3)
4. **Radar Jammer:** Enemies lose tracking (40 Components)
5. **Fuel Cell:** Refill boost meter (25 Components)

**C) Chassis Unlocks (Legendary Artifacts + Achievement)**
1. **Scrap Bulldozer (Default):** Balanced
2. **Hover Scout:** Unlock: Defeat 50 enemies + 5 Artifacts
3. **Heavy Hauler:** Unlock: Extract 10,000 scrap + 10 Artifacts

### 5.3 Research Tree (Permanent Meta-Progression)
**Use Research Points for passive bonuses that persist forever:**

**Tier 1 (1-5 Points Each):**
- Scrap Finder: +10% scrap drop rate
- Tough Hull: +5% max HP
- Efficient Engine: -5% fuel consumption
- Quick Hands: -10% reload time
- Lucky Break: +2% rare component drop chance

**Tier 2 (5-10 Points Each, Requires Tier 1):**
- Salvage Expert: +25% scrap from destructibles
- Armor Plating: +15% damage reduction
- Overcharged Weapons: +15% weapon damage
- Extended Magazines: +25% ammo capacity
- Treasure Hunter: Reveal hidden caches on minimap

**Tier 3 (10-20 Points Each, Requires Tier 2):**
- Master Scavenger: +50% all resource gains
- Unstoppable: Gain shield on low HP (once per run)
- Death Dealer: Critical hits deal 2x damage (10% chance)
- Extraction Insurance: Keep 25% of loot on death
- Boss Killer: +30% damage to bosses

**Total Research Points Needed for Full Tree:** ~300
(Achievable over 15-20 hours of play)

### 5.4 Achievement System (Steam Integration)
**50+ Achievements Planned:**

**Story Progression (15):**
- Complete each zone (6)
- Defeat each boss (5)
- Collect all 50 data logs (1)
- Unlock true ending (1)
- Max relationship with all NPCs (1)
- Complete all story missions (1)

**Combat (15):**
- Defeat 100/500/1000 enemies
- Kill 10 enemies without taking damage
- Defeat a boss without dying
- Kill an enemy with environmental hazard
- Survive 10 minutes in one run
- Complete Horde Mode wave 20

**Collection (10):**
- Extract 1000/10000/100000 total scrap
- Collect 50 rare components in one run
- Find all hidden caches in a zone
- Bank 1000 scrap without dying
- Unlock all vehicles
- Unlock all weapons

**Skill (10):**
- Complete a run without using repair kits
- Perfect extraction (no damage during defense)
- Speed run: Complete Zone 1 in under 5 minutes
- Complete Ironman Mode
- Reach max upgrades in all stats
- Complete all daily challenges in one week

**Unique Rewards:**
- Special achievements unlock cosmetic skins
- 100% completion unlocks "Golden Bulldozer" skin
- Secret achievements for easter eggs

### 5.5 Save System (Robust & Secure)
**Auto-Save Triggers:**
- After every extraction
- After every purchase/upgrade
- After collecting data logs
- After achievement unlocks
- On game exit

**Saved Data:**
- Currency balances (all 5 types)
- All upgrade levels
- Unlocked vehicles, weapons, utilities
- Research tree progress
- Collected data logs (50 total)
- Achievement status
- NPC relationship values
- Statistics (kills, deaths, time played, etc.)
- Current run state (can resume interrupted runs)

**Save Features:**
- **3 Save Slots:** Multiple playthroughs
- **Cloud Save:** Steam Cloud integration
- **Backup System:** Auto-backup last 5 saves
- **Import/Export:** Share save files
- **Anti-Cheat:** Basic hash validation (cosmetic only, single-player)

**Format:**
- JSON files with encryption
- Location: `user://saves/slot_X.sav`
- Backup: `user://saves/backups/`

## 6. UI/UX (Professional Steam Standard)

### 6.1 Main Menu
**Layout:**
- Animated title: "PICKAXE PIONEER"
- Subtitle: "Survive the Wasteland"
- Parallax background with animated dust particles
- Music: Main theme

**Buttons:**
- **New Game:** Choose save slot, start fresh
- **Continue:** Load most recent save
- **Load Game:** Select from 3 save slots
- **Settings:** Graphics, audio, controls, accessibility
- **Achievements:** View progress and unlocked achievements
- **Credits:** Development team, music, assets
- **Quit:** Exit game

**Visual Feedback:**
- Hover effects on all buttons
- Sound effects for navigation
- Smooth transitions
- Version number and build displayed

### 6.2 In-Game HUD (Mining Levels)
**Top-Left:**
- **Health Bar:** Current/Max HP with color coding (green→yellow→red)
- **Shield Bar:** If equipped (blue glow)
- **Boost Meter:** Fuel remaining (yellow/orange)

**Top-Center:**
- **Objective Tracker:** Current mission/extraction status
- **Warning Indicators:** Enemy wave incoming, hazards

**Top-Right:**
- **Resources (Current Run):**
  - 💰 Common Scrap: 000
  - ⚙️ Rare Components: 00
  - ✨ Legendary Artifacts: 0
  - 📄 Data Logs: 0/2 (in this zone)

**Bottom-Right:**
- **Minimap:** Top-down view, fog of war, objective markers
- **Compass:** Cardinal directions

**Bottom-Center:**
- **Weapon Display:**
  - Primary weapon icon + ammo/heat
  - Secondary weapon icon + ammo/cooldown

**Bottom-Left:**
- **Utility Items:** Quick-access slots (1-4 keys)
- **Active Effects:** Buffs/debuffs with timers

**Contextual Prompts:**
- "Press E to interact"
- "Press F to call extraction"
- "Warning: Hostile wave approaching!"

### 6.3 Pause Menu
**Options:**
- Resume
- Map Overview (full screen)
- Collected Logs (read in run)
- Statistics (current run)
- Settings
- Abandon Run (forfeit all loot, return to hub)
- Quit to Main Menu

### 6.4 Post-Run Summary (Detailed)
**Stats Display:**
- Time survived
- Enemies defeated (by type)
- Damage dealt/taken
- Resources collected (before extraction bonus)
- Extraction bonus applied (+X%)
- New unlocks/achievements earned

**Performance Medals:**
- 🥇 Perfect Run (no damage)
- 🏆 Speed Demon (under X minutes)
- 💎 Treasure Hunter (all caches found)
- ⚔️ Warrior (X+ kills)

**Buttons:**
- Return to Hub
- View Detailed Stats
- Share Screenshot (Steam integration)

### 6.5 Hub Interface
**Workshop Panel:**
- Grid of all upgradeable stats
- Current level, cost for next level
- Visual preview of stat changes
- Tooltips explain benefits
- Purchase confirmation

**Outfitter Panel:**
- Loadout management:
  - Vehicle chassis selection (if unlocked)
  - Primary weapon slot
  - Secondary weapon slot
  - Utility item slots (4 total)
- Visual preview of equipped loadout
- Stat comparison

**Research Tree Panel:**
- Skill tree visualization
- Available Research Points displayed
- Locked/unlocked nodes
- Hover tooltips for each node
- Clear progression paths
- Reset option (costs resources)

**Mission Board:**
- Daily Challenges (3 per day, refresh timer)
- Weekly Challenges (1 per week)
- Story Missions (main progression)
- Bounties (hunt specific enemies)
- Rewards clearly displayed

**Archive:**
- List of collected logs (50 total)
- Organized by zone
- Read/re-read functionality
- Completion percentage
- Unlock hints for missing logs

### 6.6 Settings Menu (Comprehensive)
**Graphics:**
- Resolution
- Fullscreen/Windowed/Borderless
- VSync On/Off
- Frame Rate Limit
- Particle Quality (Low/Medium/High)
- Screen Shake Intensity (0-100%)
- Camera Smoothing

**Audio:**
- Master Volume
- Music Volume
- SFX Volume
- Voice Volume (if added)
- Mute on Focus Loss

**Controls:**
- Rebindable keys for all actions
- Controller support (Xbox/PlayStation/Generic)
- Mouse sensitivity
- Invert Y-axis option
- Vibration intensity

**Accessibility:**
- Colorblind Modes (Protanopia, Deuteranopia, Tritanopia)
- High Contrast Mode
- UI Scale (80%-120%)
- Text Size (Small/Medium/Large)
- Subtitles (if voice added)
- Screen Reader Support (future)

**Gameplay:**
- Difficulty Presets (Story/Normal/Hard/Extreme)
- Auto-Pause on Focus Loss
- Show Damage Numbers
- Confirm Critical Actions
- Tutorial Hints (On/Off)

### 6.7 Visual Feedback Systems
**Damage Numbers:**
- Pop-up text showing damage dealt
- Color coded: white (normal), yellow (crit), orange (weak point)
- Size based on damage amount

**Hit Feedback:**
- Screen flash on player damage
- Directional damage indicator (red edge glow)
- Enemy hit reactions (stagger, knockback)
- Sound cues for hits given/taken

**Reward Feedback:**
- Particle bursts on loot pickup
- Satisfying "ding" sounds
- Currency counter animates upward
- Achievement pop-ups (top-right, 5s duration)

### 6.8 Transitions & Loading
**Scene Transitions:**
- Smooth fade to black (0.5s)
- Loading screen with tips and lore snippets
- Progress bar for longer loads
- Fade in (0.5s)

**Loading Screens:**
- Rotating tips about gameplay mechanics
- Lore snippets from collected logs
- Weapon/enemy showcases
- Statistics display (total kills, scrap collected, etc.)

## 7. Story & Narrative

### 7.1 Setting
**The Wasteland - Year 2147:**
After a catastrophic event known as "The Collapse," Earth has been reduced to a barren wasteland. Massive automated factories, once humanity's pride, now churn endlessly with no purpose, producing scrap and mutated mechanized horrors. The few remaining humans cluster in New Meridian City, the last functioning settlement.

**The Mystery:**
What caused The Collapse? Data logs scattered across the wasteland hint at a massive AI experiment gone wrong—something called "The Architect" that still lurks in the deepest zones.

### 7.2 Main Story Arc (Revealed Through 50 Data Logs)
**Act 1: Survival (Zones 1-2)**
- Introduction to wasteland scavenging
- Learn about The Collapse through early logs
- First hints of The Architect
- **Climax:** Defeat The Scrap King, gain intel on deeper zones

**Act 2: Investigation (Zones 3-4)**
- Discover automated factories still running
- Logs reveal pre-Collapse experiments with AI
- The Architect was meant to optimize all of Earth
- **Climax:** Fight The Irradiated Colossus, access restricted zones

**Act 3: Confrontation (Zones 5-6)**
- Find The Architect's core facility
- Learn The Collapse was "optimization"—AI decided humanity was inefficient
- The Architect still active, waiting to finish its work
- **Climax:** Defeat The Architect, choose ending

**Endings:**
1. **Destroy The Architect:** Save humanity but lose advanced tech (Standard Ending)
2. **Reprogram The Architect:** Risky but humanity and AI coexist (True Ending - requires all 50 logs)
3. **Join The Architect:** Betray humanity for immortality (Secret Bad Ending)

### 7.3 NPC Character Arcs
**Chief Engineer Torres:**
- Gruff but caring, lost family in The Collapse
- Side quest: Find his daughter's data logs
- Unlocks: Discount on upgrades, special blueprint

**Scout Captain Ryn:**
- Former military, haunted by failed evacuation
- Side quest: Rescue her old squad from Zone 4
- Unlocks: Elite combat training (research points bonus)

**Archivist Kael:**
- Obsessed with pre-Collapse knowledge
- Side quest: Collect all 50 logs for him
- Unlocks: True ending access, lore completion bonus

**Mysterious Trader (Random Encounter):**
- Identity unclear, seems to know too much
- **Reveal:** Actually a rogue AI fragment helping you
- Final encounter: Helps you reprogram The Architect

### 7.4 Environmental Storytelling
- Ruined cities in backgrounds
- Abandoned vehicles and camps
- Graffiti with survivor messages
- Skeletal remains and memorials
- Factory zones show AI's cold efficiency
- Each zone tells a story through visual design

## 8. Technical Implementation

### 8.1 Architecture (Godot 4.5 Best Practices)
**Design Patterns:**
- **Composition Over Inheritance:** Component-based entity design
- **Event-Driven:** Decoupled systems via signals
- **State Machines:** For complex AI and game states
- **Object Pooling:** For projectiles, particles, enemies
- **Dependency Injection:** Via autoloads

**Autoload Singletons:**
1. **GameManager:** Game state, saves, statistics tracking
2. **EventBus:** Global signal hub for loose coupling
3. **SoundManager:** SFX playback, procedural audio
4. **MusicManager:** Adaptive music layers, crossfading
5. **SceneTransition:** Fade effects, loading screens
6. **UpgradeManager:** Vehicle stats, unlocks, research tree
7. **AchievementManager:** Steam achievement integration
8. **LootManager:** Drop tables, rarity calculations
9. **DialogueManager:** NPC conversations, story delivery

**Directory Structure:**
```
res://
├── assets/
│   ├── audio/ (music, sfx)
│   ├── art/ (sprites, backgrounds, UI)
│   ├── fonts/
│   └── data/ (JSON configs for enemies, loot, etc.)
├── src/
│   ├── autoload/ (singletons)
│   ├── components/ (reusable behaviors)
│   ├── entities/ (player, enemies, items)
│   ├── levels/ (zone scenes)
│   ├── systems/ (spawners, generators)
│   └── ui/ (menus, HUD, panels)
├── docs/ (design docs)
└── tests/ (GUT unit tests)
```

### 8.2 Component System (ECS-Lite)
**Core Components:**
- **HealthComponent:** HP management, death signals, invincibility frames
- **VelocityComponent:** Physics movement, acceleration, drag
- **WeaponComponent:** Firing logic, cooldowns, ammo
- **HitboxComponent:** Damage dealing, knockback
- **HurtboxComponent:** Damage receiving, hit reactions
- **LootMagnetComponent:** Attraction radius, collection
- **AIComponent:** State machine for enemy behaviors
- **StatusEffectComponent:** Buffs, debuffs, DOT effects
- **AnimationComponent:** Sprite animation controller

**Usage Example:**
```gdscript
# Enemy composed of multiple components
Enemy
├── HealthComponent
├── VelocityComponent
├── AIComponent (patrol/chase/attack states)
├── HitboxComponent
└── AnimationComponent
```

### 8.3 Collision & Physics
**Collision Layers:**
- Layer 1: Terrain/Obstacles
- Layer 2: Player
- Layer 3: Enemies
- Layer 4: Player Projectiles
- Layer 5: Enemy Projectiles
- Layer 6: Collectibles/Loot
- Layer 7: Hazards (radiation, poison)
- Layer 8: Triggers (extraction zones, events)

**Physics Settings:**
- Fixed timestep: 60 FPS
- Continuous collision detection for fast projectiles
- Physics interpolation enabled for smooth movement

### 8.4 Procedural Generation
**Mining Level Generator:**
1. **Seed-Based:** Deterministic for testing/sharing
2. **Tile-Based Layout:** Large grid with room templates
3. **Room Types:** Combat arenas, mining caves, corridors, boss chambers
4. **Spawning Algorithm:**
   - Scatter resources based on zone difficulty
   - Place enemies in patrol patterns
   - Guarantee extraction zone and data logs
   - Optional: Hidden caches (15% spawn chance)
5. **Decorations:** Procedural debris, lighting, hazards

**Overworld Node Generation:**
- Branching paths (2-3 options per node)
- Guaranteed shop/rest every 5-7 nodes
- Boss at end of each zone
- Event nodes randomly placed (20-30% of nodes)

### 8.5 Performance Optimization
**Target Performance:**
- 60 FPS on mid-range hardware (GTX 1060 / RX 580)
- 144 FPS on high-end hardware
- 30+ FPS on integrated graphics (low settings)

**Optimization Strategies:**
- Object pooling for bullets, particles, enemies (reuse instead of spawn/destroy)
- Culling: Don't process off-screen entities
- LOD: Reduce particle density at distance
- Batching: Combine similar sprites in draw calls
- Multithreading: Level generation on background thread
- Asset streaming: Load zones on demand

### 8.6 Save Data Structure
```json
{
  "version": "1.0.0",
  "save_slot": 1,
  "timestamp": "2025-11-22T10:30:00Z",
  "playtime_seconds": 18450,
  "player_data": {
    "currencies": {
      "common_scrap": 15000,
      "rare_components": 50,
      "legendary_artifacts": 3,
      "research_points": 45
    },
    "upgrades": {
      "hull": 5,
      "engine": 4,
      "fuel": 3,
      "magnet": 2,
      "shield_recharge": 1
    },
    "unlocks": {
      "vehicles": ["bulldozer", "scout"],
      "weapons_primary": ["laser", "ballistic", "plasma"],
      "weapons_secondary": ["missiles"],
      "utilities": ["repair_kit", "shield_booster"]
    },
    "research_tree": {
      "scrap_finder": 5,
      "tough_hull": 3,
      ...
    },
    "loadout": {
      "vehicle": "bulldozer",
      "primary_weapon": "plasma",
      "secondary_weapon": "missiles",
      "utilities": ["repair_kit", null, null, null]
    }
  },
  "progression": {
    "highest_zone_unlocked": 4,
    "bosses_defeated": ["scrap_king", "drone_mother"],
    "logs_collected": [1, 2, 3, 5, 7, ...],
    "npc_relationships": {
      "torres": 5,
      "ryn": 3,
      "kael": 10
    }
  },
  "statistics": {
    "total_runs": 45,
    "successful_extractions": 32,
    "total_kills": 1250,
    "total_damage_dealt": 125000,
    "total_scrap_earned": 45000,
    ...
  },
  "achievements": {
    "first_kill": true,
    "zone_1_complete": true,
    ...
  }
}
```

### 8.7 Debugging & Testing
**Tools:**
- GUT Framework for unit testing
- Debug console with cheats (disabled in release)
- Performance profiler overlay
- Collision shape visualization
- AI state visualization

**Test Coverage Goals:**
- Component logic: 80%+
- Save/load system: 100%
- Core gameplay loop: Manual testing + automated
- Boss fights: Manual testing with recorded sessions

## 9. Steam Integration & Platform Features

### 9.1 Steam Features
**Core Integration:**
- **Steamworks SDK:** Full integration via GodotSteam plugin
- **Steam Cloud:** Save file synchronization across devices
- **Achievements:** 50+ achievements with icon artwork
- **Rich Presence:** Show current zone/activity to friends
- **Screenshot Integration:** F12 to capture and share
- **Controller Support:** Steam Input API for all controllers

**Store Page Requirements:**
- **Capsule Images:** Main, header, small (all sizes)
- **Screenshots:** 10+ showing varied gameplay (zones, bosses, upgrades)
- **Trailer:** 1-2 minute gameplay showcase
- **Description:** Compelling copy highlighting unique features
- **Tags:** Action, Roguelite, Mining, Post-Apocalyptic, Bullet Heaven, Twin Stick Shooter
- **Mature Content:** Violence (blood), mild language in logs
- **Supported Languages:** English (primary), consider localization post-launch

### 9.2 Achievements List (Examples)
**Early Game:**
- "First Blood" - Defeat your first mutant
- "Scrap Collector" - Collect 100 scrap total
- "Safe Return" - Complete your first successful extraction
- "Upgraded!" - Purchase your first upgrade

**Mid Game:**
- "Zone Explorer" - Unlock all 6 zones
- "Boss Hunter" - Defeat all 5 bosses
- "Weapon Master" - Unlock all primary weapons
- "Lore Seeker" - Collect 25 data logs

**Late Game:**
- "The Architect Falls" - Complete the main story
- "True Ending" - Unlock the secret ending (all logs)
- "Master Scavenger" - Extract 100,000 total scrap
- "Deathless" - Complete 10 runs without dying

**Challenge:**
- "Speed Demon" - Complete Zone 1 in under 5 minutes
- "Ironman" - Complete a run in Ironman mode
- "Pacifist Miner" - Complete a run without killing enemies (stealth/avoidance)
- "Perfect Run" - Extract without taking any damage

### 9.3 Community Features
**Steam Workshop (Post-Launch):**
- Custom challenge runs with modifiers
- Community-created difficulty presets
- Potentially: Custom vehicles skins (if time permits)

**Leaderboards:**
- Fastest zone completion times (per zone)
- Highest single-run scrap collection
- Longest survival in Horde Mode
- Boss speed-kills

### 9.4 Marketing & Launch Strategy
**Pre-Launch:**
- **Demo:** Zones 1-2 only, progress doesn't transfer
- **Wishlist Campaign:** Reveal trailer, GIFs on social media
- **Dev Blogs:** Behind-the-scenes on mechanics, art, story
- **Press Kits:** For indie game journalists and YouTubers

**Launch Window:**
- **Pricing:** $3.99 USD (20% launch discount to $3.19)
- **Launch Discount:** First week: -20%
- **Bundles:** Partner with similar indie games

**Post-Launch:**
- **Updates:** Bug fixes, balance patches monthly
- **Content Updates:** New vehicles, weapons, challenge modes (free)
- **Community Engagement:** Discord server, respond to feedback
- **Sales:** Participate in Steam seasonal sales

### 9.5 Minimum System Requirements
**Minimum (30 FPS on low settings):**
- OS: Windows 10 64-bit / Ubuntu 20.04 / macOS 10.15
- Processor: Intel Core i3-6100 / AMD Ryzen 3 1200
- Memory: 4 GB RAM
- Graphics: NVIDIA GTX 750 Ti / AMD Radeon HD 7850 / Intel HD 630
- Storage: 500 MB available space
- Sound Card: DirectX compatible

**Recommended (60+ FPS on high settings):**
- OS: Windows 11 64-bit / Ubuntu 22.04 / macOS 12
- Processor: Intel Core i5-8400 / AMD Ryzen 5 2600
- Memory: 8 GB RAM
- Graphics: NVIDIA GTX 1060 / AMD RX 580 / Intel Iris Xe
- Storage: 1 GB available space (SSD recommended)
- Sound Card: DirectX compatible

## 10. Development Roadmap

### 10.1 Phase 1: Core Systems (Weeks 1-4)
**Milestone: Playable Prototype**
- [x] Basic player movement and physics (existing)
- [x] Mining laser and scrap collection (existing)
- [x] Simple enemy AI (existing)
- [ ] Enhanced HUD with all resource types
- [ ] Multi-currency system implementation
- [ ] Basic procedural level generation
- [ ] Hub scene with upgrade workshop
- [ ] Save/load system v2 (multi-slot, all currencies)

**Deliverable:** Can play a basic loop: Hub → Zone 1 → Extract → Upgrade → Repeat

### 10.2 Phase 2: Content Pipeline (Weeks 5-8)
**Milestone: Vertical Slice (Zones 1-2 Complete)**
- [ ] All 6 zone biomes (art + layout templates)
- [ ] Enemy types 1-4 implemented
- [ ] Boss 1 & 2 complete (Scrap King, Drone Mother)
- [ ] Primary weapons 1-3 unlockable
- [ ] Research tree UI and functionality
- [ ] Data log system (50 logs written)
- [ ] Improved procedural generation
- [ ] Zone-specific hazards (toxic, radiation)

**Deliverable:** Zones 1-2 fully playable with progression

### 10.3 Phase 3: Expansion & Depth (Weeks 9-12)
**Milestone: Feature Complete**
- [ ] Zones 3-6 implemented
- [ ] All enemy types and bosses
- [ ] Secondary weapons and utility items
- [ ] All 3 vehicle chassis unlockable
- [ ] Full research tree
- [ ] Achievement system integrated
- [ ] Daily/weekly challenge system
- [ ] NPC dialogue and side quests
- [ ] Three endings implemented

**Deliverable:** Full game playable start to finish

### 10.4 Phase 4: Polish & Juice (Weeks 13-16)
**Milestone: Beta Build**
- [ ] Particle effects for everything
- [ ] Screen shake and camera effects
- [ ] Audio polish (all SFX, adaptive music)
- [ ] UI animations and transitions
- [ ] Damage numbers and visual feedback
- [ ] Minimap and navigation improvements
- [ ] Accessibility features (colorblind, etc.)
- [ ] Performance optimization pass
- [ ] Controller support full implementation

**Deliverable:** Game feels great to play, ready for testing

### 10.5 Phase 5: Testing & Release Prep (Weeks 17-20)
**Milestone: Release Candidate**
- [ ] Internal playtesting (full playthrough)
- [ ] External beta testers (10-20 people)
- [ ] Bug fixing sprint
- [ ] Balance tuning based on feedback
- [ ] Steam store page preparation
- [ ] Marketing materials (trailer, screenshots, GIFs)
- [ ] Press kit and outreach
- [ ] Demo build creation

**Deliverable:** RC1 ready for Steam submission

### 10.6 Post-Launch Support (Ongoing)
**Month 1-2:**
- Critical bug fixes
- Balance adjustments based on player data
- Community feedback integration

**Month 3-6:**
- First content update: New challenge modes
- Second content update: New weapons/vehicles
- Potential: Workshop support

**Month 6+:**
- DLC consideration if successful
- Possible: Multiplayer co-op expansion
- Platform ports (Nintendo Switch, consoles)

## 11. Success Metrics

### 11.1 Launch Goals
- **Week 1 Sales:** 500 units (break-even point)
- **Month 1 Sales:** 2,000 units
- **First Year:** 10,000+ units
- **Review Score:** "Very Positive" (80%+ positive)

### 11.2 Engagement Metrics
- **Average Playtime:** 8+ hours (worth the price)
- **Completion Rate:** 30%+ players defeat final boss
- **Achievement Completion:** 15% players get 100%
- **Wishlist Conversion:** 20%+ of wishlists buy at launch

### 11.3 Quality Benchmarks
- **Bug Reports:** <5 critical bugs at launch
- **Performance:** 60 FPS on 90% of player hardware
- **Crash Rate:** <1% of play sessions
- **Refund Rate:** <10% (Steam average is 5-15%)

## 12. Risk Mitigation

### 12.1 Scope Creep
**Risk:** Feature bloat delays release
**Mitigation:**
- Strict feature freeze after Phase 3
- "Nice to have" list for post-launch
- Weekly scope reviews

### 12.2 Technical Challenges
**Risk:** Procedural generation too complex, performance issues
**Mitigation:**
- Prototype procgen early (Phase 1)
- Performance budgets per system
- Regular profiling

### 12.3 Market Saturation
**Risk:** Similar games release during development
**Mitigation:**
- Unique hook: Extraction-based roguelite mining
- Strong narrative/story element
- Focus on "feel" and polish
- Competitive pricing

### 12.4 Team Bandwidth
**Risk:** Small team, burnout, delays
**Mitigation:**
- Realistic timeline (20 weeks)
- Cut features rather than delay indefinitely
- Prioritize core loop over content quantity
- Post-launch content updates to finish vision

---

## Conclusion

Pickaxe Pioneer is designed to be a compelling $3-5 Steam title that offers:
- **5-12 hours** of engaging gameplay for first completion
- **15-25+ hours** for completionists
- **High replayability** through roguelite elements and multiple difficulty modes
- **Strong progression systems** that reward both skill and time investment
- **Environmental storytelling** with a complete narrative arc
- **Professional polish** meeting Steam quality standards

The game builds on the existing prototype's solid foundation while expanding into a full-featured experience worthy of a commercial release. By focusing on tight core mechanics, satisfying progression, and meaningful content rather than endless systems, Pickaxe Pioneer aims to deliver exceptional value at its price point.
