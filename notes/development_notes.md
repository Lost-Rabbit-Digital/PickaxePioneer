
# What is Pickaxe Pioneer? 
Pickaxe Pioneer is a prospecting-based simulation game that allows users to explore a mining-centric world that draws inspiration from [Dwarf Fortress](http://www.bay12games.com/dwarves/?), [Escape from Tarkov](https://www.escapefromtarkov.com/?utm_source=launcher&utm_medium=menu&utm_campaign=head&utm_term=expansions_link), [Entropia Universe](https://www.entropiauniverse.com/), [Path of Exile](https://store.steampowered.com/app/238960/Path_of_Exile/), and [Morrowind](https://store.steampowered.com/app/22320/The_Elder_Scrolls_III_Morrowind_Game_of_the_Year_Edition/). 

The key design goal is to explore the systems that make these games so satisfying for users, and creating new systems inspired by their successes.

Path of Exile's skill gem representation lends itself well to this type of game if we use affixes to influence gameplay elements, skill gain rates, or flat skill amounts.

[Noita's](https://store.steampowered.com/app/881100/Noita/) presentation of the world and gathering of gold could serve as a basis for a timed-mining minigame. Could be PvP or PvE. 

These games have unique systems that deal with *permanent loss*, with *decay* of gear and skills, with *incremental progression* of skills, with *separating* class and skills, with making skills *usage-based*, and more. 

[ADOM's](https://www.adom.de/home/index.html) presentation of the overworld with villages, towns, rivers, forests, caves, ruins featured. Sometimes find entrances to ruins in caves or on Overworld.

[Iter Vehemens Ad Necem's](https://attnam.com/) limb-based damage systems are an excellent inspiration. 

Through the development of these systems for Pickaxe Pioneer, the developers at Lost Rabbit aim to learn more about progression for users, and providing feedback and mechanisms that make that progression feel deep and fulfilling.

## High Priority
- [ ] Adapt the asteroids style minigame to take place on a blue background representing dropping a probe into hydrothermal water and breaking up clusters of minerals
- [ ] Implement ADOM-style overworld system with villages, towns, rivers, forests, caves, and ruins
- [ ] Develop an extensive passive skill tree for deep character customization
- [ ] Implement a smelting system for refining ores into ingots
- [ ] Develop a geology skill for identifying ore veins and rock formations
- [ ] Implement a dynamic weather system affecting gameplay (e.g., rain slows mining, storms cause cave-ins)
- [ ] Implement a pet system for combat and skill assistance
- [ ] Create "technique gems" that can be socketed into tools for special mining abilities
- [ ] Introduce a reputation system with different factions and rewards
- [ ] Add explosives mini-game for bonus ore extraction
- [ ] Add mining bosses and ore encounters requiring strategic actions
- [x] Add a raiding system to attack and defend against other miners' resource stockpiles
- [x] Implement daily and weekly challenges with unique rewards
- [x] Create a happy hour event system boosting mining speed at specific times
- [x] Enhance the mining system with difficulty checks based on ore value
- [x] Develop a crafting system to combine ores and create valuable items

## Medium Priority
- [ ] Add random world generation for exploration and replayability
- [ ] Create user-run corporations or guilds for resource sharing and management
- [ ] Implement a user housing system for customization and storage
- [ ] Add a gambling mini-game for additional income and risk-taking
- [ ] Introduce a day/night cycle with different ore spawns and events
- [ ] Implement territory control or resource ownership mechanics
- [ ] Add tools that reduce dangers in certain areas
- [ ] Introduce rival miners competing for resources and territory
- [ ] Implement an alchemy system
- [ ] Add harvesting of plants for crafting and alchemy
- [x] Implement resource decay and tool durability system

## Low Priority
- [ ] Expand shop inventory with more tools and items
- [ ] Implement character customization for appearance
- [ ] Add a fishing mini-game for relaxation and resource gathering
- [ ] Create a splash screen for Lost Rabbit using Splashy
- [ ] Implement voice or text chat for multiplayer communication
- [ ] Allow selling ores individually or in batches

## Ongoing Improvements
- [ ] Re-organize code into Entity, Component, System sections
- [ ] Rewrite state machine for cleaner, more understandable flow
- [ ] Connect Steamworks API for chat overlays and achievements
- [ ] Implement NoobHub with AWS Lambda for global chat
- [x] Use BinSer/Ser or SmallFolk to serialize user data

## Bugs to Fix
- [x] Investigate and fix menu music playing in-game after resetting save data
- [x] Resolve intermittent mining system failures

## Ideas for Future Consideration
- [ ] Create story-driven quests with cliffhangers to encourage continued play
- [ ] Implement multiplayer co-op features
- [ ] Implement an artifact and fossil museum for collection rewards
- [ ] Create user-driven economies with trading and markets
- [x] Add special event mines with boosted rewards for limited times