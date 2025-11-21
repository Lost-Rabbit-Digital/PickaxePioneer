# Godot 4.5 Best Practices & AI Assistant Guide

This document serves as a reference for maintaining code quality, avoiding anti-patterns, and leveraging Godot 4.5 features effectively.

## 1. GDScript Style & Typing

### 1.1 Static Typing
**ALWAYS** use static typing. It improves performance, readability, and autocomplete.
```gdscript
# BAD
var health = 100
func take_damage(amount):
    health -= amount

# GOOD
var health: int = 100
func take_damage(amount: int) -> void:
    health -= amount
```

### 1.2 Naming Conventions
-   **Classes/Nodes:** `PascalCase` (e.g., `PlayerProbe`, `GameManager`).
-   **Variables/Functions:** `snake_case` (e.g., `current_speed`, `_on_body_entered`).
-   **Constants:** `SCREAMING_SNAKE_CASE` (e.g., `MAX_SPEED`).
-   **Private Members:** Prefix with `_` (e.g., `_internal_state`).

## 2. Architecture Patterns

### 2.1 Composition over Inheritance
Avoid deep inheritance trees. Use composition with Nodes/Components.
-   **Do:** Create a `HealthComponent` node and add it to `Player`, `Enemy`, `Crate`.
-   **Don't:** Create a `DestructibleEntity` class and have everything inherit from it.

### 2.2 Signal Bus (EventBus)
Use a global `EventBus` autoload for events that affect unrelated parts of the system (e.g., UI updates when player dies).
-   **Do:** `EventBus.player_died.emit()`
-   **Don't:** `get_parent().get_parent().get_node("HUD").update_health()`

### 2.3 Dependency Injection / "Call Down, Signal Up"
-   **Call Down:** Parents call functions on children.
    -   `$Component.do_something()`
-   **Signal Up:** Children emit signals to notify parents.
    -   `signal died` -> Parent connects to this.
-   **Avoid:** Children accessing parents directly (`get_parent()`). This breaks modularity.

## 3. Godot 4.5 Specifics

### 3.1 @export vs const
Use `@export` for values designers might need to tweak in the Inspector.
```gdscript
@export var speed: float = 300.0
```

### 3.2 @onready
Use `@onready` to cache node references.
```gdscript
@onready var sprite: Sprite2D = $Sprite2D
```

### 3.3 Tweens
Use the new `create_tween()` API instead of the old `Tween` node unless necessary.
```gdscript
var tween = create_tween()
tween.tween_property(self, "position", target_pos, 1.0)
```

### 3.4 File Structure
Co-locate related assets.
```
entities/player/
    Player.tscn
    Player.gd
    player_sprite.svg
    player_jump.wav
```

## 4. Anti-Patterns to Avoid
-   **God Objects:** Don't put all logic in `GameManager` or `Player.gd`. Split logic into Components or Systems.
-   **Hardcoded Paths:** Avoid `get_node("root/Main/Player")`. Use exports or the EventBus.
-   **Busy Waiting:** Don't use `while` loops for delays. Use `await get_tree().create_timer(time).timeout`.
-   **Unused Variables:** Clean up unused variables (warnings are there for a reason).

## 5. Testing
-   Use **GUT (Godot Unit Test)** for unit testing logic, especially Components.
-   Write tests for critical game logic (e.g., Health calculation, Inventory management).
