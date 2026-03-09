class_name PerkSystem
extends RefCounted

## Perk Tree System — defines all perks, prerequisites, and stat contributions.
## Three branches in Diablo-2 style:
##   Branch 0 — PELT    (Survival)
##   Branch 1 — CLAWS   (Mining)
##   Branch 2 — WHISKERS (Utility)
## Each branch has 4 tiers; top-tier perks have 3 max ranks, others have 5.

# ---------------------------------------------------------------------------
# Perk definitions
# ---------------------------------------------------------------------------

const PERKS: Array[Dictionary] = [
	# ---- BRANCH 0: PELT (Survival) ----------------------------------------
	{
		"id": "pelt",
		"name": "Pelt",
		"branch": 0,
		"tier": 0,
		"max_rank": 5,
		"prereq_id": "",
		"prereq_rank": 0,
		"icon_color": Color(0.90, 0.25, 0.25),
		"desc": "Reinforced pelt. +1 Max HP per rank.",
	},
	{
		"id": "paws",
		"name": "Paws",
		"branch": 0,
		"tier": 1,
		"max_rank": 5,
		"prereq_id": "pelt",
		"prereq_rank": 1,
		"icon_color": Color(0.95, 0.55, 0.10),
		"desc": "Enhanced paws. +25 Max Energy and +30 Move Speed per rank.",
	},
	{
		"id": "iron_hide",
		"name": "Iron Hide",
		"branch": 0,
		"tier": 2,
		"max_rank": 5,
		"prereq_id": "paws",
		"prereq_rank": 2,
		"icon_color": Color(0.60, 0.65, 0.85),
		"desc": "Hardened hide. Reduces boss energy drain by 10% per rank.",
	},
	{
		"id": "nine_lives",
		"name": "Nine Lives",
		"branch": 0,
		"tier": 3,
		"max_rank": 3,
		"prereq_id": "iron_hide",
		"prereq_rank": 3,
		"icon_color": Color(1.00, 0.85, 0.10),
		"desc": "Legendary resilience. +2 Max HP per rank.",
	},

	# ---- BRANCH 1: CLAWS (Mining) ------------------------------------------
	{
		"id": "claws",
		"name": "Claws",
		"branch": 1,
		"tier": 0,
		"max_rank": 5,
		"prereq_id": "",
		"prereq_rank": 0,
		"icon_color": Color(0.20, 0.85, 0.35),
		"desc": "Razor-sharp claws. +3 Mining Power per rank.",
	},
	{
		"id": "reach",
		"name": "Reach",
		"branch": 1,
		"tier": 1,
		"max_rank": 5,
		"prereq_id": "claws",
		"prereq_rank": 1,
		"icon_color": Color(0.20, 0.70, 0.55),
		"desc": "Extended reach. +0.75 Mining Range tiles per rank.",
	},
	{
		"id": "deep_veins",
		"name": "Deep Veins",
		"branch": 1,
		"tier": 2,
		"max_rank": 5,
		"prereq_id": "reach",
		"prereq_rank": 2,
		"icon_color": Color(0.10, 0.60, 0.95),
		"desc": "Vein sense. +5% Lucky Strike chance per rank.",
	},
	{
		"id": "motherlode",
		"name": "Motherlode",
		"branch": 1,
		"tier": 3,
		"max_rank": 3,
		"prereq_id": "deep_veins",
		"prereq_rank": 3,
		"icon_color": Color(1.00, 0.80, 0.00),
		"desc": "Elite instinct. +10% ore mineral yield per rank.",
	},

	# ---- BRANCH 2: WHISKERS (Utility) --------------------------------------
	{
		"id": "whiskers",
		"name": "Whiskers",
		"branch": 2,
		"tier": 0,
		"max_rank": 5,
		"prereq_id": "",
		"prereq_rank": 0,
		"icon_color": Color(0.65, 0.30, 0.95),
		"desc": "Tuned whiskers. +3 Sonar Radius and -1 ping energy cost per rank.",
	},
	{
		"id": "cargo",
		"name": "Cargo Claws",
		"branch": 2,
		"tier": 1,
		"max_rank": 5,
		"prereq_id": "whiskers",
		"prereq_rank": 1,
		"icon_color": Color(0.55, 0.45, 0.85),
		"desc": "Extra cargo capacity. +2 Ore Slots per rank.",
	},
	{
		"id": "ladder_mastery",
		"name": "Ladder Mastery",
		"branch": 2,
		"tier": 2,
		"max_rank": 5,
		"prereq_id": "cargo",
		"prereq_rank": 2,
		"icon_color": Color(0.85, 0.55, 0.20),
		"desc": "Rapid climbing. +50 Ladder Climb Speed per rank.",
	},
	{
		"id": "master_scavenger",
		"name": "Master Scavenger",
		"branch": 2,
		"tier": 3,
		"max_rank": 3,
		"prereq_id": "ladder_mastery",
		"prereq_rank": 3,
		"icon_color": Color(0.90, 0.90, 0.30),
		"desc": "Elite scavenging. +10% Fossil find rate per rank.",
	},
]

# Branch display names shown above each column in the tree UI
const BRANCH_NAMES: Array[String] = ["PELT", "CLAWS", "WHISKERS"]
const BRANCH_COLORS: Array[Color] = [
	Color(0.95, 0.40, 0.40),  # Pelt — warm red
	Color(0.30, 0.90, 0.45),  # Claws — green
	Color(0.75, 0.50, 1.00),  # Whiskers — purple
]

# ---------------------------------------------------------------------------
# XP scaling — XP needed to reach next level from current level
# Level 1 → 2 needs 100 XP, level 2 → 3 needs 200 XP, etc.
# ---------------------------------------------------------------------------

static func xp_for_next_level(current_level: int) -> int:
	return current_level * 100

# ---------------------------------------------------------------------------
# Query helpers (all static — call as PerkSystem.method())
# ---------------------------------------------------------------------------

static func get_perk(id: String) -> Dictionary:
	for p: Dictionary in PERKS:
		if p["id"] == id:
			return p
	return {}

## Returns true when prerequisites are met (or perk has none).
static func is_unlocked(id: String, perk_ranks: Dictionary) -> bool:
	var p := get_perk(id)
	if p.is_empty():
		return false
	var prereq: String = p["prereq_id"]
	if prereq == "":
		return true
	return perk_ranks.get(prereq, 0) >= p["prereq_rank"]

## Returns true when the player can spend a point on this perk.
static func can_rank_up(id: String, perk_ranks: Dictionary, perk_points: int) -> bool:
	if perk_points <= 0:
		return false
	var p := get_perk(id)
	if p.is_empty():
		return false
	if perk_ranks.get(id, 0) >= p["max_rank"]:
		return false
	return is_unlocked(id, perk_ranks)

## Returns all perks belonging to a given branch, sorted by tier.
static func get_branch_perks(branch: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for p: Dictionary in PERKS:
		if p["branch"] == branch:
			result.append(p)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["tier"] < b["tier"])
	return result
