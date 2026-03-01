# Pickaxe Pioneer — Cat Theme Pivot: Development Tasks

## Design Brief

Playtester feedback is unanimous: **replace the ant theme with cats**. This document outlines the complete redesign from ant colony to cat civilization, organized as actionable implementation tasks ordered by priority.

The mechanical core stays entirely intact — only terminology, art, and narrative change. Zero systems need to be rewritten.

---

## The New Identity: The Clowder

**Old concept:** Red ant from a subterranean ant colony, mining for the Queen.

**New concept:** A mining cat from the **Clowder** — a proud feline civilization that has channeled their legendary curiosity into a thriving underground economy. Cats are natural hunters with retractable claws (perfect mining tools), hypersensitive whiskers (natural sonar), thick protective fur (natural armor), and tireless padded paws (built for underground traversal). The Clowder's Matriarch sends you into the mines; return with minerals or lose them to the dark.

**High Concept (replaces current):**
> *"Dig deep, gather minerals, return to the Clowder."*
>
> You are a mining cat from the Clowder. Armed with razor-sharp Claws and impossibly sensitive Whiskers, venture into the earth to bring back precious ore. Manage your stamina carefully — go too deep without energy and you'll be stranded. Strengthen your Pelt, Paws, Claws, and Whiskers back at the Clowder, and uncover the ancient secrets buried in the deep.

---

## Complete Terminology Map

| Old (Ant) | New (Cat) | Context |
|-----------|-----------|---------|
| Red Ant | Mining Cat | Player character |
| Colony | Clowder / Den | Hub world and faction name |
| Colony Workshop | Clowder Workshop | Upgrade hub location |
| Anthill Map | Clowder Warren | Overworld map name |
| Carapace | Pelt | HP/armor upgrade track |
| Mandibles | Claws | Mining power upgrade track |
| Legs | Paws | Speed + energy capacity upgrade track |
| Mineral Sense | Whiskers | Sonar/ore-detection upgrade track |
| Forager Ant | Scout Cat | Companion system |
| Queen | Matriarch | Faction leader NPC |
| Brood Chamber | Kitten Den | Colony room (forager carry bonus) |
| Fungus Garden | Fishmonger's Larder | Colony room (mineral yield bonus) |
| Armory | Claw Sharpening Post | Colony room (blast radius bonus) |
| Nursery Vault | Heritage Vault | Colony room (fossil rate bonus) |
| Deep Antenna Array | Whisker Array | Colony room (sonar radius bonus) |
| Harden Carapace | Thicken Pelt | Upgrade button label |
| Sharpen Mandibles | Sharpen Claws | Upgrade button label |
| Strengthen Legs | Strengthen Paws | Upgrade button label |
| Mineral Sense | Refine Whiskers | Upgrade button label |
| Carapace Patch | Pelt Patch | HUD notification + trader item |
| Whetstone | Claw Whetstone | Settlement consumable |
| Forager Rations | Scout Snacks | Settlement consumable |
| Chitin Gem | Fur Gem | Gem socket (+1 Max HP) |
| Quickstride Gem | Swift Paw Gem | Gem socket (+25 Energy, +15 Speed) |
| Fracture Gem | Razor Claw Gem | Gem socket (+4 Mining Power) |
| Echo Gem | Whisker Gem | Gem socket (+3 Sonar Radius) |
| Centipede King | Giant Rat King | Boss 1 (row 32) — classic cat nemesis ✅ |
| Cave Spider Matriarch | Void Spider Matriarch | Boss 2 (row 64) — sci-fi name retained ✅ |
| Blind Mole | Blind Mole | Boss 3 (row 96) — keep, cats vs moles is perfect ✅ |
| Stone Golem | Stone Golem | Boss 4 (row 112) — keep, universal ✅ |
| Ancient One | The Ancient Star Beast | Boss 5 (row 128) — sci-fi name retained ✅ |

---

## Priority 1 — Critical (Blocks Playtesting)

### TASK 1.1 — Create Cat Character Spritesheet ✅ DONE
**Type:** Art asset
**Status:** Animated cat spritesheet is in place; player sprite is now a cat.

~~The player sprite is the most visible ant reference. The new sheet must match the existing frame layout used by `PlayerProbe.gd` (loaded in `MiningLevel.gd`) and also serve as the Caravan token on the overworld map (`Caravan.tscn`).~~

**Spec:**
- Match current ant spritesheet frame dimensions and animation layout (idle, walk left/right, jump)
- Character: a stocky orange or grey tabby cat holding a pickaxe
- Maintain the same pixel art style as existing tileset
- The mine node overworld icon currently uses a gold-tinted version of this sprite — the cat version must also read clearly at small size with a gold tint

**Files to update after art is ready:**
- `assets/creatures/red_ant_spritesheet.png` — replace in place (or add `cat_spritesheet.png` and update references)
- `src/levels/MiningLevel.gd` — update `load("res://assets/creatures/red_ant_spritesheet.png")` path
- `src/entities/overworld/Caravan.tscn` — update sprite texture reference
- `src/levels/Overworld.gd` — update mine node gold-tinted icon reference

---

### TASK 1.2 — Update Upgrade Track Names in UI
**Type:** Code (UI strings)
**Files:** `src/ui/UpgradeMenu.gd`, `src/levels/CityLevel.gd`

Apply the terminology map to all user-facing upgrade buttons and descriptions.

**Changes in `UpgradeMenu.gd`:**
- `"Harden Carapace"` → `"Thicken Pelt"`
- `"Sharpen Mandibles"` → `"Sharpen Claws"`
- `"Strengthen Legs"` → `"Strengthen Paws"`
- `"Upgrade Mineral Sense"` → `"Refine Whiskers"`
- All description strings referencing carapace/mandibles/legs/antennae → pelt/claws/paws/whiskers
- Gem socket labels: Chitin Gem → Fur Gem, Quickstride Gem → Swift Paw Gem, Fracture Gem → Razor Claw Gem, Echo Gem → Whisker Gem

**Changes in `CityLevel.gd`:**
- Colony chamber names in UI panel:
  - `"Fungus Garden"` → `"Fishmonger's Larder"`
  - `"Brood Chamber"` → `"Kitten Den"`
  - `"Armory"` → `"Claw Sharpening Post"`
  - `"Nursery Vault"` → `"Heritage Vault"` (can keep as-is or update)
  - `"Deep Antenna Array"` → `"Whisker Array"`
- Any button or panel label that says "Colony" → "Clowder"
- Upgrade track labels in chamber unlock/build UI

---

### TASK 1.3 — Update HUD Labels
**Type:** Code (UI strings)
**File:** `src/ui/HUD.gd`

- `"Carapace Patch"` popup text → `"Pelt Patch"`
- Any low-HP warning that says "carapace" → "pelt"
- Any HUD string referencing "mandibles," "antennae," or "colony" → apply terminology map

---

### TASK 1.4 — Rewrite ChatterManager Dialogue
**Type:** Code (content strings)
**File:** `src/systems/ChatterManager.gd`

Replace the `messages` array with cat-civilization dialogue. Full replacement:

```gdscript
var messages: Array[String] = [
    # Flavor
    "Nice haul!",
    "The clowder needs more minerals...",
    "The deep tunnels are dangerous.",
    "Seen any rats down there?",
    "My claws are getting dull.",
    "Gem prices are going up.",
    "Stay safe in the tunnels.",
    "Found gold ore yesterday!",
    "Watch out for lava flows.",
    "My paws are killing me.",
    "I miss the upper galleries.",
    "Who digs these side tunnels?",
    "My whiskers are tingling...",
    "Anyone got a spare energy cell?",
    "The Matriarch wants more.",
    "Just one more run...",
    "Did you hear that rumbling?",
    "Sensing mineral veins ahead...",
    "Back to the digging.",
    "Hope the deposit is rich.",
    "Curiosity didn't kill this cat...",
    "Nine lives, but I'd rather not use them.",
    "Keep your claws sharp, your whiskers sharper.",

    # Tips
    "Don't step on lava!",
    "You have to surface to keep your minerals.",
    "Thicken your pelt to survive longer.",
    "The exit station is your only way out.",
    "Watch your pelt integrity!",
    "Sharper claws dig faster.",
    "Stronger paws let you dig deeper.",
    "Minerals are life out here.",
    "Don't get greedy, get out alive.",
    "Different mines have different ore richness.",

    # Lore
    "The clowder grows ever deeper.",
    "How far does the earth go?",
    "They say there's a gem vein nearby.",
    "I found a strange crystal yesterday.",
    "The deep rocks are shifting.",
    "My paws were made for digging.",
    "Ancient tunnels... something old lives down here.",
    "The Matriarch's whiskers never lie.",
]
```

---

### TASK 1.5 — Update Settlement Consumable Labels
**Type:** Code (UI strings)
**File:** `src/levels/SettlementLevel.gd`

- `"Whetstone"` → `"Claw Whetstone"` (description: "+1 claw power for this run")
- `"Forager Rations"` → `"Scout Snacks"` (description: "+20 Scout Cat carry cap for this run")
- `"Field Repair"` — can stay or rename to `"Field Grooming Kit"`; mechanic unchanged
- Any settlement NPC dialogue referencing "ants," "mandibles," "antennae," "colony" → update to cat terms

---

### TASK 1.6 — Update Overworld and Modal Descriptions
**Type:** Code (content strings)
**Files:** `src/levels/Overworld.gd`, `src/ui/LevelInfoModal.gd`

- `"Your home colony"` → `"Your home den"` or `"The Clowder"`
- Mine node description that mentions "ants" → remove or update
- Any location flavor text referencing ant anatomy → cat anatomy
- Map name if displayed: update to "Clowder Warren" or similar

---

## Priority 2 — High (Complete Before First External Demo)

### TASK 2.1 — Update Wandering Trader Item Names
**Type:** Code (content strings)
**File:** `src/levels/MiningLevel.gd` (trader item table)

- `"Carapace Patch"` → `"Pelt Patch"` (mechanic: +1 HP, unchanged)
- Any trader dialogue lines referencing "colony," "queen," "mandibles" → update

---

### TASK 2.2 — Rename Boss 1 and Boss 5
**Type:** Code (content strings)
**File:** `src/systems/BossSystem.gd`

**Priority renames (for thematic fit):**
- Boss 1 (row 32): `"Centipede King"` → `"Giant Rat King"` — cats vs rats is immediately legible and charming. Retain the multi-segment body mechanic; just update displayed name, banner text, and any flavor strings.
- Boss 5 (row 128): `"The Ancient One"` → `"The Ancient Hound"` — dogs as the ancient underground rival civilization adds cat-vs-dog flavor to the final encounter. Retain all mechanics.

**Optional (lower priority):**
- Boss 2 (row 64): `"Cave Spider Matriarch"` → `"Cave Bat Matriarch"` — cats hunting bats is fitting; spiders work fine too.
- Boss 3: `"Blind Mole"` — keep as-is. Cats hunting moles is perfect lore.
- Boss 4: `"Stone Golem"` — keep as-is.

Update any milestone banner strings (e.g., `"CENTIPEDE KING DEFEATED"` → `"GIANT RAT KING DEFEATED"`).

---

### TASK 2.3 — Update ForagerSystem Flavor Text
**Type:** Code (comments + any UI strings)
**File:** `src/systems/ForagerSystem.gd`

- The Forager Ant class can be renamed `ScoutCat` internally for coherence, or kept as-is (internal name, not player-facing)
- Any string or comment referring to "forager ant" as visible text → `"Scout Cat"`
- The colored-circle draw representation in `MiningLevel._draw()` can optionally get a cat silhouette or paw icon instead of a circle — defer to art polish phase if sprite work is in scope
- The `mineral_currency` banking message if displayed → no ant references expected here

---

### TASK 2.4 — Update GameManager Variable Names (Optional Refactor)
**Type:** Code (internal variables — low player visibility)
**File:** `src/autoload/GameManager.gd`

Internal variable names currently use ant terminology. Renaming them improves code readability and prevents future confusion. This is optional but recommended during a refactor pass:

| Old Variable | New Variable |
|--------------|-------------|
| `carapace_level` | `pelt_level` |
| `mandibles_level` | `claws_level` |
| `carapace_gem_socketed` | `fur_gem_socketed` |
| `mandibles_gem_socketed` | `razor_claw_gem_socketed` |
| `brood_chamber_built` | `kitten_den_built` |
| `settlement_mandible_bonus` | `settlement_claw_bonus` |

**Note:** This is a find-and-replace across all files that reference these variables. Do not do partial renames — update all read and write sites together. Leg/Paws and mineral_sense/Whiskers can be left as-is since `legs` and `mineral_sense` are generic enough.

---

## Priority 3 — Medium (Before Steam Release)

### TASK 3.1 — Rewrite Game Design Document Theme Sections
**Type:** Documentation
**File:** `docs/game_design_document.md`

- Section 1 (Game Overview): Update Theme field from `"Underground Ant Colony Mining Adventure"` to `"Underground Cat Civilization Mining Adventure"`
- Section 1.1 (High Concept): Replace ant high concept with cat version (see Design Brief above)
- Section 1.2 (Core Pillars): Update `"Satisfying Progression: Permanent ant upgrades..."` → `"Permanent cat upgrades..."`
- Section 2.1 (Core Loop): Rename all hub/workshop/map references to cat terms
- All upgrade track names throughout the document → apply terminology map
- All NPC and faction references (Queen → Matriarch, colony → Clowder)
- Section covering gem sockets: update gem names
- Boss encounter descriptions: update Boss 1 and Boss 5 names

---

### TASK 3.2 — Update README.md
**Type:** Documentation
**File:** `README.md`

- First line: `"...where you play as a red ant digging..."` → `"...where you play as a mining cat digging..."`
- Concept paragraph: full rewrite using cat terminology
- Gameplay Loop section: update hub/upgrade track names inline
- Any other ant references

---

### TASK 3.3 — Update Development Notes
**Type:** Documentation
**File:** `notes/development_notes.md`

- Header description: `"...you play as a red ant..."` → `"...you play as a mining cat..."`
- Upgrade track references throughout: carapace/mandibles → pelt/claws
- Architecture notes: `ChatterManager.gd — ambient ant NPC chatter` → `ambient cat NPC chatter`
- `GameManager.gd` description: update upgrade track names
- Colony chamber descriptions: apply full rename map
- Shelved ideas: remove ant-specific shelved items that no longer apply; add cat-equivalent concepts

---

### TASK 3.4 — Update Shelved / Ideas Section for Cat Theme
**Type:** Documentation
**File:** `notes/development_notes.md` (Shelved + Ideas sections)

Remove ant-specific shelved ideas that don't translate and replace with cat equivalents:

**Remove or reframe:**
- "Rival ant colonies competing for mine shafts" → "Rival cat clowders competing for mine shafts"
- "Implement ant appearance customisation — carapace colour, mandible shape" → "Implement cat appearance customisation — fur colour, pattern, collar unlocks"
- "Create colony-driven economies with ant-to-ant mineral trading" → "Create clowder-driven economies with cat-to-cat mineral trading"
- "Expand worker ant system to profession types — Scout, Engineer, Soldier" → "Expand Scout Cat system to profession types — Hunter, Digger, Lookout"
- "Pet/companion system — a non-ant creature (beetle, springtail)" → "Pet/companion system — a non-cat creature (mouse, bird) that provides a passive bonus"
- "Create story-driven quests from the Queen with cliffhangers" → "Create story-driven quests from the Matriarch with cliffhangers"

---

## Priority 4 — Polish (Pre-Launch)

### TASK 4.1 — Cat-Specific Visual Polish for Companion
**Type:** Art / Code
**File:** `src/levels/MiningLevel.gd` (`_draw()` method, forager draw block)

The Scout Cat companion is currently rendered as a colored circle with a carry bar. Options:
- **Option A (low effort):** Keep circle rendering; update the amber color to be more distinctly "cat" (e.g., add a small ear silhouette drawn programmatically above the circle)
- **Option B (medium effort):** Draw a simple cat silhouette using Godot's `draw_*` primitives — two circles for head/body, triangles for ears
- **Option C (full art):** Create a `scout_cat_spritesheet.png` similar to the player sprite; render using a Sprite2D node within the MiningLevel scene instead of procedural draw

Recommendation: Ship with Option A, plan Option C for v1.1.

---

### TASK 4.2 — FarmAnimalNPC Flavor Update
**Type:** Code (minor content)
**File:** `src/entities/FarmAnimalNPC.gd`

Surface chickens, sheep, and pigs are currently pettable flavor NPCs. With a cat protagonist, there's an opportunity for gentle humor — cats chasing chickens, eyeing the sheep, etc. Add one or two idle interaction lines per animal type that reflect a cat's predatory interest, played for comedy rather than violence.

Examples:
- Chicken: "You eye the chicken. It runs. You resist... for now."
- Sheep: "Warm. Fluffy. You briefly consider curling up on it."

This is low priority — do not implement before all Priority 1–3 tasks are complete.

---

### TASK 4.3 — Update `.claude/prompts/` Templates
**Type:** Documentation
**Files:** `.claude/prompts/*.md`

The AI prompt templates for adding bosses, enemies, weapons, and zones reference "ant" and "colony" in their context sections. Update these so future AI-assisted development uses cat terminology by default.

Files to review and update:
- `.claude/prompts/add-boss.md`
- `.claude/prompts/add-enemy.md`
- `.claude/prompts/add-zone.md`
- `.claude/prompts/review-gdd.md`

---

## Implementation Order Summary

```
Week 1 (Unblock Playtesting):
  [ ] 1.1 Cat spritesheet (art)
  [ ] 1.2 Upgrade track UI labels
  [ ] 1.3 HUD labels
  [ ] 1.4 ChatterManager dialogue
  [ ] 1.5 Settlement consumable labels
  [ ] 1.6 Overworld/modal descriptions

Week 2 (Demo-Ready):
  [ ] 2.1 Wandering Trader item names
  [ ] 2.2 Boss 1 + Boss 5 renames
  [ ] 2.3 ForagerSystem flavor text
  [ ] 2.4 GameManager variable refactor (if time permits)

Week 3 (Documentation Pass):
  [ ] 3.1 GDD rewrite
  [ ] 3.2 README update
  [ ] 3.3 development_notes.md update
  [ ] 3.4 Shelved/Ideas section update

Pre-Launch Polish:
  [ ] 4.1 Scout Cat visual upgrade
  [ ] 4.2 FarmAnimalNPC flavor
  [ ] 4.3 Prompt template updates
```

---

## What Does NOT Change

The following systems are mechanically sound and need zero changes — only their labels/strings need updating where noted above:

- All mining mechanics (cursor mining, energy drain, depth zones)
- Smelting chain system (`SmeltingSystem.gd`)
- Fossil system (`FossilSystem.gd`)
- Sonar/ping system (`SonarSystem.gd`)
- Boss combat mechanics (`BossSystem.gd`)
- Forager/Scout companion mechanics (`ForagerSystem.gd`)
- Gem socketing mechanics
- Colony chamber unlock/build mechanics
- Overworld navigation and map logic
- All tile types and ore values
- Sound effects and music
- Save/load system structure (variable renames in Task 2.4 are optional)
- Hazard tile behavior (lava, explosives, gas)
