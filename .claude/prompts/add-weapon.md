---
description: [DEPRECATED — see add-consumable.md or add-zone.md]
---

# Note: Pickaxe Pioneer Has No Weapons

This game uses **cursor-based mining** (left-click within 4.5-tile range), not a
weapon/loadout system. There are no projectiles, fire rates, or weapon components.

**If you want to add:**
- A new consumable item (settlement shop or wandering trader) → use `add-consumable.md`
- A new upgrade track (Pelt/Paws/Claws/Whiskers equivalent) → see `UpgradeMenu.gd`
- A new boss encounter at a depth milestone → use `add-boss.md`
- A new depth zone / biome band → use `add-zone.md`

The mining "tool" is always the cat's Claws. Mining power is governed by
`GameManager.get_claws_power()` (driven by the Sharpen Claws upgrade track).
Consumables like the Claw Whetstone (+1 claw power for one run) are the closest
equivalent to weapon upgrades and are handled via settlement/trader shops.
