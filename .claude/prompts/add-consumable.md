---
description: Add a new consumable item to the settlement shop or wandering trader
---

# Add New Consumable

Add a new pre-run or mid-run consumable item. Consumables are single-use bonuses that
persist from purchase through the next mine run, then are cleared by `GameManager`.

> **Game context:** The player is a **mining cat** from the **Clowder**. Item names and
> descriptions should fit the space-cat theme. Use cat terminology throughout:
> Pelt (HP), Paws (energy/speed), Claws (mining power), Whiskers (sonar).
> Never use ant/colony/queen/carapace/mandible terminology.

## Consumable Details

- **Name:** [e.g., "Star Ration", "Claw Oil", "Void Compass"]
- **Sold At:** [Settlement shop / Wandering Trader / both]
- **Cost:** [mineral_currency cost]
- **Effect:** [What it does, expressed as a stat delta or run modifier]
- **Duration:** [One run / N uses / permanent for run]
- **Category:** [Energy, Pelt (HP), Claws (mining), Whiskers (sonar), Navigation]

## Where Consumables Live

| Type | Where to Add |
|------|-------------|
| Pre-run (bought at Settlement before entering mine) | `SettlementLevel.gd` shop UI + `GameManager` carry-over field |
| Mid-run (bought from Wandering Trader in mine) | `TraderSystem.gd` item table |
| Both | Both of the above |

## Implementation Steps

### 1. Add carry-over field to GameManager
```gdscript
# src/autoload/GameManager.gd
var settlement_[item_name]_bonus: int = 0   # cleared after mine entry
```

### 2. Apply the bonus on mine entry
Find where `MiningLevel._ready()` reads settlement carry-over fields and add:
```gdscript
# Example: bonus energy at run start
if GameManager.settlement_star_ration_bonus > 0:
    GameManager.current_energy = min(
        GameManager.current_energy + GameManager.settlement_star_ration_bonus,
        GameManager.get_max_energy()
    )
    GameManager.settlement_star_ration_bonus = 0
```

### 3. Clear the bonus at run end
Settlement bonuses are already cleared in `MiningLevel._on_run_end()` / `_clear_settlement_bonuses()`.
Verify the new field is cleared there.

### 4a. Add to Settlement shop (if applicable)
In `SettlementLevel.gd`, add a shop entry in the consumables array:
```gdscript
{
    "name": "Star Ration",
    "description": "+50 starting energy for the next run",
    "cost": 30,
    "action": func(): GameManager.settlement_star_ration_bonus = 50,
    "can_buy": func(): return GameManager.mineral_currency >= 30
}
```

### 4b. Add to Wandering Trader (if applicable)
In `TraderSystem.gd`, add to the item pool:
```gdscript
{
    "name": "Star Ration",
    "description": "+50 energy now",
    "cost": 40,
    "tier": 1,   # 1 = early rows, 2 = mid, 3 = deep
    "action": func(): GameManager.restore_energy(50),
}
```

### 5. Update HUD / popup (if needed)
If the item has a visible in-run effect (e.g. HP restore), emit via EventBus:
```gdscript
EventBus.player_health_changed.emit(GameManager.get_current_hp(), GameManager.get_max_hp())
```

### 6. Save compatibility
If the carry-over field must survive a save/load within a session, add it to
`SaveManager`'s serialization. Most settlement bonuses are transient and do not need saving.

## Testing Checklist

- [ ] Item appears in correct shop UI with accurate name, description, cost
- [ ] Purchasing deducts `mineral_currency` correctly
- [ ] Bonus applies correctly at mine entry (or immediately if mid-run trader)
- [ ] Bonus is cleared after use — does not persist across multiple runs
- [ ] `can_buy` condition prevents purchasing when insufficient minerals
- [ ] Effect is readable in HUD if it modifies a visible stat
- [ ] Item name and description use cat terminology exclusively

## Documentation Update

After implementing:
- [ ] Add item to `notes/development_notes.md` SettlementLevel or TraderSystem description
- [ ] Update `docs/game_design_document.md` §2.1 consumables list
