
# What is Pickaxe Pioneer?
Pickaxe Pioneer is a grid-based underground mining roguelite where you play as a red ant digging for minerals deep in the earth. Inspired by [Motherlode](https://www.miniclip.com/games/motherlode/en/) and [Supermotherlode](https://store.steampowered.com/app/269110/Super_Motherload/), the game combines the satisfying tile-by-tile mining loop with roguelite progression and ant colony theming.

You venture out from The Colony, descend into mine shafts, and dig through layers of dirt, stone, and increasingly rare ore. Fuel (energy) is finite — go too deep and you'll be stranded. Successfully surfacing banks your minerals for permanent upgrades: harden your Carapace, strengthen your Legs, and sharpen your Mandibles.

The game also draws design inspiration from [Dwarf Fortress](http://www.bay12games.com/dwarves/), [Path of Exile](https://store.steampowered.com/app/238960/Path_of_Exile/), [ADOM](https://www.adom.de/home/index.html), and [Noita](https://store.steampowered.com/app/881100/Noita/) — particularly their systems of *permanent progression*, *resource management*, *usage-based skill growth*, and *depth-based risk/reward*.

Path of Exile's affix system lends itself to ore gem enhancements. Noita's gold-gathering through procedural environments is a direct touchstone for the mining run structure.

Through developing these systems, the team at Lost Rabbit aims to explore what makes mining games satisfying at a deep mechanical level — the feedback loops of extraction, loss, and reinvestment.

## High Priority
- [ ] Adapt the asteroids-style minigame to a hydrothermal probe variant (mineral clusters in water)
- [ ] Implement ADOM-style overworld with multiple mine entrances, cavern networks, and surface features
- [ ] Develop a colony passive skill tree for deep progression customization
- [ ] Implement a smelting/refining system: combine raw ores into ingots for bonus minerals
- [ ] Add a geology skill — ant learns to identify ore veins at a distance
- [ ] Implement a dynamic weather system affecting surface layers (rain softens soil, heat hardens stone)
- [ ] Implement a pet/companion system (a small beetle assistant, etc.)
- [ ] Create "gem socketing" system: slot found gems into ant upgrades for special effects
- [ ] Introduce a colony reputation system with rewards for mining milestones
- [ ] Add explosive digging mini-game for bonus ore extraction
- [ ] Add underground boss encounters requiring strategic movement
- [x] Implement daily and weekly challenges with unique colony rewards
- [x] Create a happy hour event system boosting mineral yield at specific depths
- [x] Enhance mining difficulty checks based on ore value and tile hardness
- [x] Develop a crafting/combining system for rare mineral combinations

## Medium Priority
- [ ] Add random cave generation for exploration and replayability beyond the main grid
- [ ] Create user-run mining consortiums (guilds) for shared colony resource tracking
- [ ] Implement a colony housing/storage system for mineral stockpiling
- [ ] Add a gambling mini-game — bet minerals on ore quality predictions
- [ ] Introduce a day/night cycle with different ore spawns and surface events
- [ ] Implement territory control — claim mine nodes on the overworld for passive income
- [ ] Add tools that reduce specific hazards (lava-proof carapace gel, etc.)
- [ ] Introduce rival ant colonies competing for the same mine shafts
- [ ] Implement an alchemy system — distill rare minerals into colony buffs
- [ ] Add harvestable fungi and roots for crafting and alchemy
- [x] Implement resource decay and tool durability system

## Low Priority
- [ ] Expand Colony Workshop with more upgrade tracks (Fuel Sac, Mineral Sense, etc.)
- [ ] Implement ant appearance customization (carapace color, mandible shape)
- [ ] Add a fishing/foraging mini-game on the surface between runs
- [ ] Create a splash screen for Lost Rabbit using Splashy
- [ ] Allow selling ore types individually or in batches to different NPCs
- [ ] Implement voice or text chatter for colony NPC ambience

## Ongoing Improvements
- [ ] Re-organize code into Entity, Component, System sections
- [ ] Rewrite state machine for cleaner, more understandable flow
- [ ] Connect Steamworks API for chat overlays and achievements
- [ ] Implement NoobHub with AWS Lambda for global colony chat
- [x] Use BinSer/Ser or SmallFolk to serialize user data

## Bugs to Fix
- [x] Investigate and fix menu music playing in-game after resetting save data
- [x] Resolve intermittent mining system failures

## Ideas for Future Consideration
- [ ] Create story-driven quests from the Queen with cliffhangers
- [ ] Implement multiplayer co-op (two ants in the same mine)
- [ ] Implement a fossil and rare mineral museum for collection rewards
- [ ] Create colony-driven economies with ant-to-ant mineral trading
- [x] Add special event mines with boosted ore richness for limited times
