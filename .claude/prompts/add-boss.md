---
description: Implement a boss fight with multi-phase mechanics
---

# Add Boss Enemy

Create a boss fight for Pickaxe Pioneer with multiple phases and unique mechanics.

> **Game context:** The player character is a **mining cat** from the **Clowder** civilization. Upgrades are Pelt (HP), Paws (speed/fuel), Claws (mining power), and Whiskers (sonar). The companion is the **Scout Cat**. Bosses should fit a cat-vs-underground-menace theme. Existing bosses: Giant Rat King (row 32), Cave Spider Matriarch (row 64), Blind Mole (row 96), Stone Golem (row 112), The Ancient Hound (row 128). Use cat terminology in all names, banners, and flavor text.

## Boss Details
- **Name:** [e.g., "The Scrap King"]
- **Zone:** [Which zone this boss appears in]
- **HP:** [Total health pool]
- **Phases:** [Number of phases, typically 2-3]
- **Unique Mechanics:** [Special attacks, patterns, environmental interactions]
- **Reward:** [Unlocks, story progression]
- **Visual Design:** [Size, color, intimidation factor]

## Implementation Checklist

### 1. Boss Entity
- [ ] Create `src/entities/bosses/Boss_[Name].tscn`
- [ ] Create `src/entities/bosses/Boss_[Name].gd`
- [ ] Set up large sprite/visual (2-3x player size)
- [ ] Add multiple collision shapes for weak points
- [ ] Configure components (Health, AI, Hitbox, Hurtbox)

### 2. Phase System
- [ ] Implement phase state machine
- [ ] Define HP thresholds for phase transitions
- [ ] Create transition animations/effects
- [ ] Phase-specific attack patterns
- [ ] Invulnerability during transitions

### 3. Attack Patterns
For each phase, implement 2-4 unique attacks:
- [ ] **Attack 1:** [Name and description]
  - [ ] Telegraph/warning indicator
  - [ ] Execution animation
  - [ ] Hitbox/projectile spawning
  - [ ] Cooldown timing
- [ ] **Attack 2:** [Name and description]
- [ ] **Attack 3:** [Name and description]
- [ ] **Ultimate Attack:** [Devastating move in final phase]

### 4. Environmental Integration
- [ ] Design boss arena (clear of obstacles)
- [ ] Add destructible cover (if applicable)
- [ ] Implement arena hazards
- [ ] Camera zoom out for boss intro
- [ ] Arena boundaries

### 5. Visual Effects
- [ ] Boss intro cinematic/animation
- [ ] Phase transition effects (screen shake, particles)
- [ ] Attack telegraphs (warning indicators)
- [ ] Damage effects (hit flash, particle bursts)
- [ ] Death animation (epic explosion)
- [ ] Weak point indicators (if applicable)

### 6. Audio
- [ ] Unique boss music track
- [ ] Phase transition stingers
- [ ] Attack sound effects (each attack unique)
- [ ] Damage/hurt sounds
- [ ] Death sound/fanfare

### 7. UI & Feedback
- [ ] Boss health bar at top of screen
- [ ] Boss name display
- [ ] Phase indicator
- [ ] Damage numbers
- [ ] Warning text for major attacks

### 8. Rewards & Progression
- [ ] Guaranteed legendary artifact drop
- [ ] Large scrap reward
- [ ] Unlock next zone
- [ ] Unlock new weapon/vehicle (if applicable)
- [ ] Story log drop
- [ ] Achievement trigger

### 9. Balance & Testing
- [ ] Test fight difficulty (should take 3-5 minutes)
- [ ] Ensure attacks are telegraphed and fair
- [ ] Verify all phases trigger correctly
- [ ] Test with different player loadouts
- [ ] Verify reward drops

## Code Template

```gdscript
# src/entities/bosses/Boss_[Name].gd
extends CharacterBody2D
class_name Boss[Name]

enum Phase { PHASE_1, PHASE_2, PHASE_3, DEAD }

@onready var health: HealthComponent = $HealthComponent
@onready var ai: AIComponent = $AIComponent
@onready var sprite: Sprite2D = $Sprite2D

const MAX_HEALTH = [value]
const PHASE_2_THRESHOLD = 0.66  # 66% HP
const PHASE_3_THRESHOLD = 0.33  # 33% HP

var current_phase: Phase = Phase.PHASE_1
var attack_cooldown: float = 0.0
var is_transitioning: bool = false

# Attack patterns per phase
var phase_1_attacks = ["slam", "charge", "projectile"]
var phase_2_attacks = ["slam", "charge", "projectile", "summon_minions"]
var phase_3_attacks = ["slam", "charge", "projectile", "summon_minions", "ultimate"]

func _ready():
    health.max_health = MAX_HEALTH
    health.current_health = MAX_HEALTH
    health.damage_taken.connect(_on_damage_taken)
    health.died.connect(_on_death)

    # Boss intro
    _play_intro()

    # Start boss music
    MusicManager.play_boss_theme("[boss_name]")

func _physics_process(delta):
    if is_transitioning:
        return

    # Update attack cooldown
    attack_cooldown -= delta

    # AI logic
    match current_phase:
        Phase.PHASE_1:
            _update_phase_1(delta)
        Phase.PHASE_2:
            _update_phase_2(delta)
        Phase.PHASE_3:
            _update_phase_3(delta)

    move_and_slide()

func _on_damage_taken(amount: float):
    # Check for phase transitions
    var health_percent = health.current_health / health.max_health

    if health_percent <= PHASE_2_THRESHOLD and current_phase == Phase.PHASE_1:
        _transition_to_phase_2()
    elif health_percent <= PHASE_3_THRESHOLD and current_phase == Phase.PHASE_2:
        _transition_to_phase_3()

func _update_phase_1(delta):
    if attack_cooldown <= 0:
        var attack = phase_1_attacks.pick_random()
        _execute_attack(attack)
        attack_cooldown = 3.0

func _update_phase_2(delta):
    if attack_cooldown <= 0:
        var attack = phase_2_attacks.pick_random()
        _execute_attack(attack)
        attack_cooldown = 2.5  # Faster attacks

func _update_phase_3(delta):
    if attack_cooldown <= 0:
        var attack = phase_3_attacks.pick_random()
        _execute_attack(attack)
        attack_cooldown = 2.0  # Even faster

func _transition_to_phase_2():
    is_transitioning = true
    current_phase = Phase.PHASE_2

    # Visual effects
    _play_transition_effect()

    # Become briefly invulnerable
    health.invulnerable = true
    await get_tree().create_timer(2.0).timeout
    health.invulnerable = false
    is_transitioning = false

func _transition_to_phase_3():
    is_transitioning = true
    current_phase = Phase.PHASE_3

    # More intense transition
    _play_transition_effect()
    CameraShake.shake(1.0, 0.5)

    health.invulnerable = true
    await get_tree().create_timer(2.0).timeout
    health.invulnerable = false
    is_transitioning = false

func _execute_attack(attack_name: String):
    match attack_name:
        "slam":
            _attack_slam()
        "charge":
            _attack_charge()
        "projectile":
            _attack_projectile_barrage()
        "summon_minions":
            _attack_summon_minions()
        "ultimate":
            _attack_ultimate()

# Attack implementations
func _attack_slam():
    # Telegraph
    await get_tree().create_timer(0.5).timeout
    # Create shockwave hitbox
    # Damage players in area
    pass

func _attack_charge():
    # Rush toward player
    # Create damage trail
    pass

func _attack_projectile_barrage():
    # Spawn multiple projectiles in pattern
    pass

func _attack_summon_minions():
    # Spawn enemy adds
    pass

func _attack_ultimate():
    # Screen-filling devastating attack
    # Show warning text: "ULTIMATE ATTACK!"
    pass

func _on_death():
    # Epic death animation
    _play_death_animation()

    # Drop rewards
    LootManager.spawn_legendary_artifact(global_position)
    LootManager.spawn_loot(global_position, [large_scrap_amount])

    # Unlock progression
    GameManager.unlock_zone([next_zone])
    GameManager.unlock_[reward]()

    # Achievement
    AchievementManager.unlock("[boss_name]_defeated")

    # Clean up
    await get_tree().create_timer(3.0).timeout
    queue_free()

func _play_intro():
    # Cinematic camera zoom
    # Boss name appears
    # Roar/taunt
    pass

func _play_transition_effect():
    # Particle burst
    # Screen flash
    # Phase announcement
    pass

func _play_death_animation():
    # Epic explosion sequence
    # Fade out
    pass
```

Please implement this boss with exciting, fair, and memorable mechanics.
