---
description: Create a new enemy type with complete implementation
---

# Add New Enemy Type

Please implement a new enemy type for Pickaxe Pioneer following these specifications:

## Enemy Details (to be filled by user)
- **Name:** [Enemy name, e.g., "Armored Mutant"]
- **Tier:** [1-3, determines difficulty]
- **HP:** [Health points]
- **Damage:** [Contact or projectile damage]
- **Movement Pattern:** [e.g., "Charges toward player", "Circles and shoots", "Stationary turret"]
- **Attack Type:** [Contact, Ranged, Melee Swipe, etc.]
- **Drops:** [Scrap amount, rare component chance]
- **Visual Description:** [Color scheme, shape, special effects]

## Implementation Checklist

### 1. Entity Creation
- [ ] Create `src/entities/enemies/[EnemyName].tscn` scene
- [ ] Create `src/entities/enemies/[EnemyName].gd` script
- [ ] Set up proper node hierarchy (Sprite, CollisionShape, components)

### 2. Components
- [ ] Add HealthComponent with specified HP
- [ ] Add VelocityComponent (if moves)
- [ ] Add AIComponent with state machine (Idle, Patrol, Chase, Attack, Death)
- [ ] Add HitboxComponent for damage dealing
- [ ] Add HurtboxComponent for receiving damage
- [ ] Configure collision layers (Layer 3, Mask: Player + Terrain + Projectiles)

### 3. AI Behavior
- [ ] Implement movement pattern in AI states
- [ ] Add attack logic (contact, projectile spawning, etc.)
- [ ] Add player detection radius
- [ ] Add pursuit/aggro logic
- [ ] Add death animation and loot drop

### 4. Visual & Audio
- [ ] Create SVG sprite or colored shape placeholder
- [ ] Add particle effects (death explosion, attack telegraphs)
- [ ] Hook up sound effects (movement, attack, death)
- [ ] Add blood particles on hit (if biological enemy)

### 5. Integration
- [ ] Add to appropriate zone spawner(s)
- [ ] Configure spawn weight/frequency
- [ ] Test in-game and balance HP/damage
- [ ] Add to GameManager enemy type tracking (for stats)

### 6. Documentation
- [ ] Document in code comments
- [ ] Add to enemy design spreadsheet (if exists)

## Code Template

```gdscript
# src/entities/enemies/[EnemyName].gd
extends CharacterBody2D
class_name [EnemyName]

@onready var health: HealthComponent = $HealthComponent
@onready var ai: AIComponent = $AIComponent
@onready var velocity_comp: VelocityComponent = $VelocityComponent

const SPEED = [value]
const DAMAGE = [value]
const DETECTION_RADIUS = [value]

var player: Node2D = null

func _ready():
    health.max_health = [HP_VALUE]
    health.died.connect(_on_death)
    ai.set_state("patrol")

func _physics_process(delta):
    if player:
        _update_ai()
    velocity = velocity_comp.velocity
    move_and_slide()

func _update_ai():
    match ai.current_state:
        "patrol":
            # Wander logic
            pass
        "chase":
            # Chase player
            var direction = (player.global_position - global_position).normalized()
            velocity_comp.apply_force(direction * SPEED)
        "attack":
            # Attack logic
            pass

func _on_death():
    # Drop loot
    LootManager.spawn_loot(global_position, [SCRAP_AMOUNT])
    # Particle effect
    # Queue free
    queue_free()
```

Please create this enemy following the GDD specifications and the template above.
