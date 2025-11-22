---
description: Add a new primary or secondary weapon to the game
---

# Add New Weapon

Implement a new weapon for Pickaxe Pioneer following the weapon system design.

## Weapon Details
- **Name:** [e.g., "Plasma Repeater"]
- **Type:** [Primary or Secondary]
- **Unlock Cost:** [Rare Components + Scrap]
- **Unlock Condition:** [e.g., "Defeat Zone 2 Boss" or "Purchase with 150 Components"]
- **Fire Rate:** [Shots per second or cooldown]
- **Damage:** [Per shot/tick]
- **Special Mechanics:** [e.g., "Piercing", "Chain lightning", "Homing", "AOE"]
- **Visual:** [Color, projectile shape, particle effects]
- **Sound:** [Description of firing sound]

## Implementation Checklist

### 1. Weapon Component
- [ ] Create `src/components/weapons/[WeaponName]Component.gd`
- [ ] Extend WeaponComponent base class
- [ ] Implement firing logic
- [ ] Configure cooldown/fire rate
- [ ] Set damage values

### 2. Projectile (if applicable)
- [ ] Create `src/entities/projectiles/[WeaponName]Projectile.tscn`
- [ ] Create `src/entities/projectiles/[WeaponName]Projectile.gd`
- [ ] Implement movement behavior
- [ ] Add hitbox and damage dealing
- [ ] Add visual (sprite/particle trail)
- [ ] Add impact effects
- [ ] Configure collision layers (Layer 4 for player projectiles)

### 3. Visual Effects
- [ ] Create muzzle flash particle effect
- [ ] Create projectile trail (if applicable)
- [ ] Create impact/explosion effect
- [ ] Add weapon glow/charge effect (for secondary weapons)

### 4. Audio
- [ ] Create or generate firing sound effect
- [ ] Add reload/cooldown sound (if applicable)
- [ ] Add impact sound

### 5. UI Integration
- [ ] Create weapon icon (32x32, 64x64)
- [ ] Add to weapon selection UI in Outfitter
- [ ] Display ammo/heat/cooldown in HUD
- [ ] Add tooltip description

### 6. Unlock System
- [ ] Add to UpgradeManager weapon unlock list
- [ ] Implement unlock condition check
- [ ] Add purchase logic in Outfitter
- [ ] Save unlock state in save file

### 7. Balance & Testing
- [ ] Test DPS against different enemy types
- [ ] Test feel and feedback
- [ ] Adjust damage/fire rate based on playtesting
- [ ] Ensure it fits the intended tier (early/mid/late game)

## Code Template

```gdscript
# src/components/weapons/[WeaponName]Component.gd
extends WeaponComponent
class_name [WeaponName]Component

const PROJECTILE = preload("res://src/entities/projectiles/[WeaponName]Projectile.tscn")

@export var damage: float = [value]
@export var fire_rate: float = [value]  # shots per second
@export var projectile_speed: float = [value]

var cooldown: float = 0.0

func _process(delta):
    if cooldown > 0:
        cooldown -= delta

func fire(direction: Vector2) -> bool:
    if cooldown > 0:
        return false

    # Spawn projectile
    var projectile = PROJECTILE.instantiate()
    projectile.global_position = global_position
    projectile.direction = direction
    projectile.speed = projectile_speed
    projectile.damage = damage
    get_tree().current_scene.add_child(projectile)

    # Visual & audio feedback
    _spawn_muzzle_flash()
    SoundManager.play_sound("[weapon_fire_sound]")

    # Reset cooldown
    cooldown = 1.0 / fire_rate
    return true

func _spawn_muzzle_flash():
    # Particle effect at weapon position
    pass
```

```gdscript
# src/entities/projectiles/[WeaponName]Projectile.gd
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: float = 10.0
var lifetime: float = 3.0

func _ready():
    # Set collision layers
    collision_layer = 0b00010000  # Layer 4
    collision_mask = 0b00000101   # Enemies + Terrain

    # Connect signals
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)

func _physics_process(delta):
    position += direction * speed * delta
    lifetime -= delta
    if lifetime <= 0:
        queue_free()

func _on_body_entered(body):
    # Hit terrain
    _explode()
    queue_free()

func _on_area_entered(area):
    # Hit enemy hurtbox
    if area is HurtboxComponent:
        area.take_damage(damage)
        _explode()
        queue_free()

func _explode():
    # Spawn impact particles
    # Play impact sound
    pass
```

Please implement this weapon with proper integration into the loadout and progression systems.
