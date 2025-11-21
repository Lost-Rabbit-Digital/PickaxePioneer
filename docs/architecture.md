# Pickaxe Pioneer - Architecture Document

## 1. Project Structure
The project follows a modular, component-based structure to ensure scalability and maintainability.

```
res://
├── assets/                 # Art, Audio, Fonts
├── docs/                   # Documentation
├── src/                    # Source Code & Scenes
│   ├── autoload/           # Global Singletons
│   ├── components/         # Reusable Component Nodes
│   ├── entities/           # Game Objects (Player, Enemies, Loot)
│   ├── levels/             # Game Scenes (Overworld, MiningLevel)
│   ├── systems/            # Systems (Spawners, Managers)
│   └── ui/                 # User Interface
└── tests/                  # Unit Tests (GUT)
```

## 2. Core Systems

### 2.1 GameManager (`src/autoload/GameManager.gd`)
-   **Responsibility:** Manages global game state (MENU, PLAYING, PAUSED), scene transitions, and global currency tracking.
-   **Pattern:** Singleton (Autoload).

### 2.2 EventBus (`src/autoload/EventBus.gd`)
-   **Responsibility:** Facilitates decoupled communication between systems.
-   **Pattern:** Observer / Signal Bus.
-   **Key Signals:** `game_state_changed`, `ore_mined` (deprecated/refactored to direct collection), etc.

### 2.3 SoundManager (`src/autoload/SoundManager.gd`)
-   **Responsibility:** Handles audio playback and procedural sound generation.
-   **Implementation:** Uses `AudioStreamGenerator` for dynamic SFX.

## 3. Entity Component System (ECS-lite)
We use Godot's node composition to mimic ECS patterns. Entities are composed of small, single-responsibility components.

### 3.1 Components (`src/components/`)
-   **`VelocityComponent`:** Handles physics movement, acceleration, and friction.
-   **`HealthComponent`:** Manages HP, damage taking, and death signals.
-   **`HurtboxComponent`:** Detects incoming damage areas.
-   **`HitboxComponent`:** Delivers damage (if applicable).
-   **`MiningToolComponent`:** Handles weapon/tool firing logic.

### 3.2 Entities (`src/entities/`)
-   **`PlayerProbe`:** The player character. Composed of Velocity, Health, MiningTool components.
-   **`ScrapPile`:** Destructible object. Composed of Health, Hurtbox components.
-   **`ScrapLoot`:** Collectible item. Handles simple physics and magnetism logic.

## 4. Level Design
-   **`Overworld`:** Node-based navigation map. Uses `MapNode` instances to define the graph.
-   **`MiningLevel`:** The main gameplay arena. Contains `PlayerProbe`, `AsteroidSpawner` (spawns ScrapPiles), and `ParallaxBackground`.

## 5. Data Flow
1.  **Input:** Player input is handled in `PlayerProbe._physics_process`.
2.  **Action:** Input triggers `VelocityComponent` (move) or `MiningToolComponent` (fire).
3.  **Interaction:** 
    -   Laser (Area2D) hits ScrapPile (RigidBody/Area2D).
    -   ScrapPile takes damage via `HealthComponent`.
    -   On death, ScrapPile spawns `ScrapLoot`.
4.  **Collection:** 
    -   Player moves near `ScrapLoot`.
    -   Loot magnetizes and collides with Player.
    -   `ScrapLoot` calls `GameManager.add_currency()` and `SoundManager.play_pickup_sound()`.
