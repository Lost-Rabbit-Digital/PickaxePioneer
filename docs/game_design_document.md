# Pickaxe Pioneer - Game Design Document (GDD)

## 1. Game Overview
**Title:** Pickaxe Pioneer  
**Genre:** 2D Top-Down Mining & Exploration / Roguelite  
**Theme:** Post-Apocalyptic Earth Wasteland  
**Engine:** Godot 4.5  
**Perspective:** Top-Down (2D)

### 1.1 High Concept
Navigate a desolate, post-apocalyptic earth in your customized "Scrap Bulldozer" ship. Travel between wasteland nodes, mine scrap piles, avoid or fight mutants, complete quests, and gather resources to upgrade your vehicle and survive the harsh environment.

## 2. Gameplay Mechanics

### 2.1 Core Loop
1. **Main Menu:** Start game or quit
2. **Explore:** Navigate the Overworld Map to choose your next destination
3. **Mining Run:**
   - Enter a Scrap Field (Mining Level)
   - Pilot your ship using physics-based thrust and rotation
   - Destroy Scrap Piles using your mining laser
   - Collect Scrap Loot chunks (magnetism)
   - Avoid or fight wandering Mutants
   - Optional: Accept and complete fetch quests from NPCs
   - Reach the Extraction Zone to complete the run
4. **Return to Base:**
   - Bank your collected scrap currency
   - Purchase upgrades (Hull, Engine, Laser)
   - Listen to ambient city chatter
5. **Repeat:** Continue runs to earn more scrap and upgrades

### 2.2 Run System
- **Run Currency:** Scrap collected during a mining run
- **Banking:** Must extract successfully to keep scrap
- **Loss Condition:** Touching a mutant loses all run scrap
- **Extraction Zone:** Green zone that completes the run and shows summary

### 2.3 Controls
- **Movement:**
  - `W` / `Up Arrow`: Thrust forward
  - `A` / `Left Arrow`: Rotate Left
  - `D` / `Right Arrow`: Rotate Right
- **Combat:**
  - `Space`: Fire Mining Laser
- **Interaction:**
  - `E`: Talk to NPCs / Accept quests

### 2.4 Entities

#### Player
- **Scrap Bulldozer:** Physics-based vehicle with tracks
- **Stats:** Health, Speed, Laser Damage (upgradeable)
- **Visual:** Brown/tan tracked vehicle with blade

#### Mining
- **Scrap Piles:** Destructible junk piles that drop loot
- **Scrap Loot:** Magnetic resource chunks (1 scrap each)
- **Particle Effects:** Dust clouds on destruction

#### Combat
- **Mutants:** Wandering hostile enemies
  - Random movement patterns
  - Contact = instant run loss
  - Can be killed with 3 laser hits (30 HP)
  - Knockback and blood particles on hit
- **Mining Laser:** Rotates with ship, damages mutants and scrap piles

#### Quests
- **Quest NPCs:** Hooded scavengers (50% spawn chance)
  - Offer fetch quests for random items
  - Reward: 50 scrap
  - Despawn after completion
- **Quest Items:** Glowing artifacts with pulsing animation
  - Spawn randomly in level
  - Golden particle effects on collection

#### City
- **Shopkeeper:** Animated NPC with rotating dialogue
- **Chatter System:** Floating text bubbles with tips and ambient dialogue
- **Upgrade Menu:** Purchase Hull, Engine, and Laser upgrades

## 3. Art & Audio Style

### 3.1 Visuals
- **Format:** Vector-based SVG art
- **Palette:** Dusty browns, oranges, rust, metallic greys, dark reds (blood)
- **Style:** Clean geometric shapes with gritty post-apocalyptic theme
- **Parallax:** Multi-layer backgrounds with wasteland and dust
- **Particles:** 
  - Dust (brown) for scrap pile destruction
  - Blood (red) for mutant damage
  - Engine exhaust (grey) for player thrust
  - Golden sparkles for quest items

### 3.2 Audio
- **Music:** (ElevenLabs generated)
  - **City:** Acoustic guitar, rusty metal, safe haven vibe
  - **Overworld:** Dark ambient drone, desolate wind
  - **Mining:** Industrial techno, metallic clanking, tense atmosphere
  - **Crossfading:** Smooth 1.5s transitions between scenes
- **SFX:** (Procedurally generated)
  - Engine rumble (pitch varies with speed)
  - Laser fire (retro "pew" sound)
  - Explosions (noise burst)
  - Pickup (high-pitched ding)

## 4. World Design

### 4.1 Overworld
- Node-based map with parallax background
- **Caravan:** Player representation that moves between nodes
- **Nodes:**
  - **Base City:** Safe zone for upgrades and banking
  - **Scrap Fields:** Mining encounters (Iron Mine, Gold Mine)
  - Dynamic scene loading based on node type

### 4.2 Mining Levels
- **Size:** Large explorable area (~4-5x screen size)
- **Camera:** Smooth following with position smoothing
- **Spawning:**
  - Scrap Piles: Procedural placement
  - Mutants: Random wandering AI
  - Quest NPCs: 50% chance
  - Extraction Zone: Fixed location

### 4.3 Base City
- **Upgrade Shop:** Central panel with three upgrade options
- **Shopkeeper:** Animated character with dialogue rotation
- **Chatter:** Ambient floating text around the screen
- **Return Button:** Navigate back to Overworld

## 5. Progression System

### 5.1 Currency
- **Scrap:** Primary currency
- **Run Scrap:** Temporary (lost on death)
- **Banked Scrap:** Permanent (saved)

### 5.2 Upgrades
All upgrades are permanent and saved:

- **Hull Upgrade:**
  - Cost: 50 scrap (increases by 25 per level)
  - Effect: +20 max health per level (base: 100)
- **Engine Upgrade:**
  - Cost: 50 scrap (increases by 25 per level)
  - Effect: +30 max speed per level (base: 300)
- **Laser Upgrade:**
  - Cost: 50 scrap (increases by 25 per level)
  - Effect: +5 damage per level (base: 10)

### 5.3 Save System
- **Auto-save:** Triggers on upgrade purchase
- **Saved Data:**
  - Scrap currency
  - Hull level
  - Engine level
  - Laser level
- **Format:** JSON file (`user://save_data.json`)
- **Load:** Automatic on game start

## 6. UI/UX

### 6.1 Main Menu
- Title: "PICKAXE PIONEER"
- Subtitle: "Scavenge the Wastes"
- Buttons: START, QUIT
- Theme: Dark wasteland colors with gold accents

### 6.2 HUD (Mining Level)
- **Scrap Counter:** Top-left (run scrap only)
- **Health Bar:** (Planned)

### 6.3 Run Summary
- Displays scrap collected
- "Return to Base" button
- Banks currency automatically

### 6.4 Transitions
- **Fade to Black:** 0.5s fade out, scene change, 0.5s fade in
- Applies to all scene transitions

## 7. Visual Polish

### 7.1 Camera Effects
- **Smooth Following:** Position smoothing enabled
- **Camera Shake:** Triggered on scrap collection (subtle)
- **Bounds:** Limited to mining level area

### 7.2 Particle Systems
- **Engine Particles:** Emit when thrusting
- **Impact Particles:** Dust/blood on hits
- **Quest Particles:** Golden sparkles
- **All particles:** Auto-cleanup after animation

### 7.3 Animations
- **Shopkeeper Dialogue:** Rotates every 3 seconds
- **Quest Items:** Pulsing scale animation
- **Chat Bubbles:** Float upward with fade in/out (5s duration)
- **Laser Rotation:** Matches ship orientation

## 8. Technical Implementation

### 8.1 Architecture
- **Composition Pattern:** Component-based entity design
- **Event Bus:** Global signal system
- **Autoloads:**
  - GameManager (state, currency, upgrades, save/load)
  - EventBus (signals)
  - SoundManager (procedural audio)
  - MusicManager (crossfading)
  - SceneTransition (fade effects)
  - QuestManager (quest tracking)

### 8.2 Components
- **HealthComponent:** Reusable health system
- **VelocityComponent:** Physics-based movement
- **MiningToolComponent:** Laser firing logic
- **HitboxComponent:** Damage dealing

### 8.3 Collision Layers
- Layer 1 (Bit 0): World/Obstacles
- Layer 2 (Bit 1): Player
- Layer 3 (Bit 2): Enemies/Mutants
- Layer 4 (Bit 3): Loot/Collectibles

## 9. Future Enhancements (Planned)
- Health bar UI
- More enemy types (drones, turrets)
- More quest variety
- Additional upgrade types (magnet radius)
- Random events on overworld
- Multiple save slots
- Difficulty scaling
- Boss encounters
