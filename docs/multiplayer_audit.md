# Multiplayer Audit — Pickaxe Pioneer (Godot 4.5)

**Audit date:** 2026-03-03
**Scope:** LAN co-op via ENetMultiplayerPeer (Steam path is a stub and not evaluated)
**Codebase snapshot:** ~1,685 lines of multiplayer-specific GDScript across 8 files

---

## Executive Summary

Pickaxe Pioneer has a **functional two-player LAN co-op system** built on Godot 4.5's
high-level `MultiplayerAPI` with `ENetMultiplayerPeer`. The architecture is intentionally
simple: host-authority, peer-to-peer, manual RPCs — no `MultiplayerSynchronizer` or
`MultiplayerSpawner` nodes are used. This approach is appropriate for a 2-player LAN
product but carries some hand-coded-sync risks.

**Two critical bugs were found** that would cause guest players to be stranded with no
recourse when the host disconnects, and a double-load race condition in the normal game
start flow. Several major issues affect fairness (guest sprint is free energy) and
security (RPC spam, chat spoofing). The system is otherwise coherent and well-structured.

---

## 1. Architecture & Netcode Review

### MultiplayerAPI Usage

| Check | Status | Notes |
|-------|--------|-------|
| Single `MultiplayerPeer` assigned to `multiplayer.multiplayer_peer` | ✅ | `NetworkManager.gd` owns it cleanly |
| `_reset_peer()` clears signals and closes the socket before re-use | ✅ | All 4 signals explicitly disconnected |
| `peer_connected` handled | ✅ | `NetworkManager._on_peer_connected` |
| `peer_disconnected` handled (host side) | ✅ | Emits `guest_disconnected` |
| `peer_disconnected` handled (guest side) | ❌ | `if is_host` guard means guest gets no signal — see **C1** |
| `connected_to_server` handled | ✅ | `CONNECT_ONE_SHOT` on `join_host()` |
| `connection_failed` handled | ✅ | `CONNECT_ONE_SHOT` on `join_host()` |
| **`server_disconnected` handled** | ❌ | **Never connected anywhere — see C1** |
| `multiplayer.get_unique_id()` used for authority checks | ✅ | `MiningLevel._setup_multiplayer_players()` |

### RPC Design

| Check | Status | Notes |
|-------|--------|-------|
| `@rpc` annotations present on all sync methods | ✅ | |
| `"authority"` used for host → guest messages | ✅ | All game-state RPCs |
| `"any_peer"` used for guest → host requests | ✅ | `rpc_request_mine`, `_deliver_chat_message` |
| `"reliable"` for critical events | ✅ | Tile breaks, run end, game over, damage |
| `"unreliable"` for high-frequency resources | ⚠️ | Should be `"unreliable_ordered"` — see **M3** |
| `"unreliable_ordered"` for position sync | ✅ | `rpc_sync_transform` |
| `any_peer` RPCs validated with sender checks | ❌ | `rpc_request_mine` has no rate limit; `_deliver_chat_message` has no sender validation — see **M2**, **M5** |
| RPC channel separation | N/A | Godot 4 ENet uses single default channel; acceptable for 2-player |
| `@rpc` used sparingly (not over-relied on) | ✅ | Position sync, tile sync, resource sync, damage — all appropriate |

### MultiplayerSpawner / MultiplayerSynchronizer

Not used. The second `PlayerProbe` is instantiated manually in
`MiningLevel._setup_multiplayer_players()` and driven via `rpc_sync_transform`. This is
correct for a 2-player game where the guest node must be created conditionally. The
absence of `MultiplayerSynchronizer` means there is no delta compression or automatic
resync on late join — these are handled by the custom drop-in RPC system.

### Authority Model

| Check | Status |
|-------|--------|
| Host-authoritative (peer 1 owns game state) | ✅ |
| `set_multiplayer_authority()` called on guest PlayerProbe | ✅ |
| `is_multiplayer_authority()` checked before `_physics_process` simulation | ✅ |
| Guest cannot execute server-only logic (energy drain, game-over) | ✅ |
| Guest station interactions blocked on non-host | ✅ |

---

## 2. ENet Deep Dive

### Peer Configuration

| Check | Status | Notes |
|-------|--------|-------|
| `create_server(port, MAX_CLIENTS)` called correctly | ✅ | `MAX_CLIENTS = 1` (host + 1 guest) |
| `create_client(ip, port)` called correctly | ✅ | |
| Compression configured | ❌ | No `.compress()` call; acceptable on LAN — see **m2** |
| Bandwidth limits set | ❌ | Default (uncapped); acceptable for 2-player LAN |
| DTLS configured | ❌ | No encryption; documented LAN-only — see **m9** |

### Host Discovery & Session Management

Discovery method: **manual IP entry**. Players share their LAN IP out-of-band (e.g.,
verbally) and enter it in the join field. There is no LAN broadcast/autodiscovery.

| Check | Status | Notes |
|-------|--------|-------|
| Host creation flow | ✅ | Select save → start — 3 clicks |
| Join flow with IP + port | ✅ | Input validated; range-checked |
| Late-join / drop-in to active mine | ✅ | Full state sent on `guest_connected` |
| Drop-in to overworld | ✅ | Planet config synced via `rpc_apply_planet_config` |
| Host migration | ❌ | No migration; session ends on host exit |
| `server_disconnected` → return to menu | ❌ | Signal never connected — see **C1** |
| Full-session-state snapshot on join | ✅ | Kit state, energy, sky colour, ore/hazard filter, animal type |

### Latency & Responsiveness

**Position sync:** `rpc_sync_transform` is sent every frame (`_physics_process`) with
`unreliable_ordered`. On a LAN (< 5ms RTT) this is effectively real-time.

**Resource sync:** `rpc_sync_resources` fires every 150ms (`RESOURCE_SYNC_INTERVAL`).
Guest HUD can lag up to 150ms behind host's actual mineral/energy values.

**Tile sync:** `rpc_tile_broken` and `rpc_tile_hit` are `reliable` — they arrive in
order, no visual tearing.

**Client-side prediction:** None implemented. Guest position is entirely driven by the
received `rpc_sync_transform` frames. On LAN this is imperceptible. At > 50ms RTT
(WAN) the guest's remote copy would visibly lag — acceptable given the LAN-only scope.

**Latency tolerance:** Not formally tested. Estimated:
- < 10ms: Indistinguishable from singleplayer
- 50ms: Acceptable; remote player position slightly behind
- 100ms+: Remote player noticeably delayed; tile breaks would feel laggy on guest mining
- 200ms+: Experience degrades significantly; guest mining via reliable RPC round-trip
  adds ~400ms perceived latency per swing

### Bandwidth Efficiency

| Data stream | Rate | Mode | Notes |
|-------------|------|------|-------|
| Position + animation | ~60 Hz | `unreliable_ordered` | ~30–50 bytes/frame per player |
| Resource sync (minerals + energy) | ~7 Hz | `unreliable` | 2 integers; minimal |
| Tile break | On event | `reliable` | ~20 bytes per break |
| Tile hit (partial) | On event | `reliable` | ~20 bytes per hit |
| Chat | On event | `reliable` | Variable |
| Kit/scene load RPCs | On scene change | `reliable` | ~200 bytes, infrequent |

**Estimated peak bandwidth:** ~5–10 KB/s per direction during active mining. Well within
LAN capacity and typical consumer home network upload limits.

### Reliability & Error Handling

| Check | Status | Notes |
|-------|--------|-------|
| Packet loss tolerance (ENet reliable channels) | ✅ | ENet retransmits reliable packets |
| Heartbeat / stall detection | ❌ | No application-level ping or timeout — see **m6** |
| Reconnection flow | ❌ | No rejoin mechanism; must start a new session |
| `connection_failed` → user feedback | ✅ | Status label updated in MainMenu |
| `server_disconnected` → user feedback | ❌ | Signal not handled — see **C1** |
| Guest disconnect → host feedback | ✅ | "PARTNER DISCONNECTED" banner |
| Host disconnect → guest feedback | ❌ | No signal, no banner, no return to menu — see **C1** |

---

## 3. Steam Multiplayer

**Status: Not implemented.** The Steam button in the multiplayer UI is visible but
disabled with a "Coming Soon" tooltip. No GodotSteam or custom `MultiplayerPeerExtension`
exists in the codebase. Not evaluated further.

---

## 4. Player Experience & UX

### Lobby / Pre-Game

| Check | Status | Notes |
|-------|--------|-------|
| Main menu → hosting < 3 clicks | ✅ | Multiplayer → Host → Select Save → Start |
| Connection progress shown | ✅ | Status labels update on each signal |
| Guest sees waiting state | ✅ | "Connected! Waiting for host to start..." |
| Host sees guest arrival | ✅ | "Player 2 connected!" + Start button appears |
| Can host configure while guest waits | ✅ | Host picks save slot before starting |

### In-Game

| Check | Status | Notes |
|-------|--------|-------|
| Remote player visible and animated | ✅ | `rpc_sync_transform` |
| Visual differentiation (host vs guest) | ✅ | Host = white, Guest = orange |
| In-game chat | ✅ | T to open, Enter to send, Esc to cancel |
| Shared mineral / energy HUD | ✅ | Synced every 150ms |
| Tile state consistent across peers | ✅ | All breaks synced via reliable RPC |
| Cosmetic desyncs (particles, sounds) | Acceptable | Each peer spawns their own particles; minor desync is invisible |
| Guest station interaction blocked | ✅ | Host-only gates on upgrade/smeltery stations |

### Disconnection & Endgame

| Check | Status | Notes |
|-------|--------|-------|
| Guest disconnects mid-mine → host banner | ✅ | "PARTNER DISCONNECTED" |
| Guest node cleaned up on disconnect | ❌ | `guest_player_node` not freed — see **m7** |
| Host disconnects mid-mine → guest feedback | ❌ | No signal; guest is stuck — see **C1** |
| Run completion → both see RunSummary | ✅ | `rpc_complete_run_as_guest` |
| Run failure → both return to Overworld | ✅ | `rpc_trigger_game_over` |
| Return to lobby after run without restart | ✅ | Both peers transition to Overworld |

---

## 5. Security Considerations

| Check | Status | Notes |
|-------|--------|-------|
| Guest mining range validated on host | ✅ | `rpc_request_mine` checks distance against synced position |
| Guest mining rate limited | ❌ | No server-side rate limit — see **M2** |
| `any_peer` RPC sender validated | ❌ | `_deliver_chat_message` has no sender check — see **M5** |
| Host-only logic guarded with `is_host` | ✅ | Energy drain, game-over, run-end |
| Guest cannot call host-only RPCs | ✅ | `"authority"` mode prevents it |
| Peer-to-peer RPC injection (ENet star topology) | N/A | ENet routes all traffic through host; client-to-client not possible |
| IP/port input sanitized | ✅ | `is_valid_int()` + range check |
| Crash from malformed RPC | Low risk | `rpc_tile_broken` bounds-checks; `rpc_tile_hit` does not — see **m4** |

---

## 6. Debugging & Observability

| Check | Status | Notes |
|-------|--------|-------|
| Godot Network Profiler usage documented | ❌ | Not mentioned in codebase or docs |
| Peer ID / topology printed on connect | ✅ | `print()` calls in NetworkManager |
| In-game network debug overlay | ❌ | None |
| Structured logging (timestamps, peer IDs) | ❌ | Only bare `print()` calls |
| Headless server mode tested | Unknown | No CI/headless test scripts |
| State snapshot / desync reproduction | ❌ | None |

---

## 7. Godot 4.5-Specific Notes

- The codebase correctly uses `@rpc` annotation syntax (Godot 4 style, not `remote` etc.).
- `set_multiplayer_authority()` / `is_multiplayer_authority()` used correctly.
- No `SceneReplicationConfig` resources or `.tres` replication configs — all sync is
  code-driven, which is simpler and easier to version-control for this game's scope.
- No GDExtension/GodotSteam bindings; the only Godot 4.5-specific consideration is that
  any future Steam integration should be compiled against the 4.5 API hash.
- Static typing is used consistently in multiplayer code, matching the project standard.

---

## Summary of Findings

### Critical

| ID | Description | File(s) | Repro |
|----|-------------|---------|-------|
| **C1** | Guest has no notification when host disconnects — `server_disconnected` never connected; `_on_peer_disconnected` only processes `is_host` branch | `NetworkManager.gd:40-54, 84-88` | Host closes game mid-mine → guest is stuck with no banner, no return to menu, session appears to hang |
| **C2** | Double Overworld load in normal start flow — `start_game()` sends `rpc_start_game_as_guest` (which loads Overworld) AND `load_overworld()` which sends `rpc_load_overworld_as_guest` (which also loads Overworld) | `GameManager.gd:157-165, 363-366` | Start a hosted session → guest loads Overworld scene twice; potential flicker or planet config desync |

### Major

| ID | Description | File(s) |
|----|-------------|---------|
| **M1** | Guest sprint costs no energy from shared pool — guest calls `GameManager.consume_energy()` locally but host's 150ms sync overwrites it | `PlayerProbe.gd:184-192`, `MiningLevel.gd:2246-2251` |
| **M2** | `rpc_request_mine` has no server-side rate limit — guest can bypass `MINE_INTERVAL` and mine at unbounded speed | `MiningLevel.gd:2209-2222` |
| **M3** | `rpc_sync_resources` uses `"unreliable"` not `"unreliable_ordered"` — out-of-order packets can display stale HUD values | `MiningLevel.gd:2246` |
| **M4** | Planet config race in drop-in flow — host sends `rpc_apply_planet_config` before guest's Overworld is instantiated; if the RPC arrives before `_ready()`, it is silently dropped | `GameManager.gd:213-218` |
| **M5** | `_deliver_chat_message` is `any_peer` without sender ID validation — a client can spoof the sender name (e.g., impersonate "Host") | `NetworkManager.gd:110-112` |

### Minor

| ID | Description | File(s) |
|----|-------------|---------|
| **m1** | `_on_coop_peer_disconnected` connected for both host and guest (lines 609-612), but `guest_disconnected` only fires when `is_host` is true — dead code on guest | `MiningLevel.gd:608-612` |
| **m2** | ENet compression not configured — no `.compress()` call | `NetworkManager.gd:25-30` |
| **m3** | No ENet bandwidth caps — default uncapped; acceptable for 2-player LAN | `NetworkManager.gd:26` |
| **m4** | `rpc_tile_hit` does not bounds-check the grid position before calling `_update_breaking_overlay`; `rpc_tile_broken` does check | `MiningLevel.gd:2239-2243` |
| **m5** | No multiplayer GUT tests — no test coverage for any network path | `tests/` |
| **m6** | No heartbeat or stall detection — a silent network freeze is undetectable | `NetworkManager.gd` |
| **m7** | `guest_player_node` not freed on disconnect — `_on_coop_peer_disconnected` shows a banner but does not `queue_free()` the orphaned node | `MiningLevel.gd:638-640` |
| **m8** | Default port 25565 conflicts with Minecraft Java Edition — minor UX friction | `NetworkManager.gd:13` |
| **m9** | No DTLS / transport encryption — acceptable for documented LAN-only scope | `NetworkManager.gd` |
| **m10** | No reconnect flow — disconnected players must restart entirely | `NetworkManager.gd` |

### Cosmetic

| ID | Description | File(s) |
|----|-------------|---------|
| **c1** | Chat key `T` is hardcoded via `event.keycode == KEY_T`, not an input action — cannot be rebound | `ChatBox.gd:98` |
| **c2** | Chat sender names hardcoded as `"Host"` / `"Guest"` — no player name support | `NetworkManager.gd:102` |
| **c3** | Guest minerals banked to their own local `GameManager.mineral_currency` — shared pool semantics unclear across sessions | `GameManager.gd:247-261` |

---

## Network Performance Profile

| Metric | Value | Source |
|--------|-------|--------|
| Position sync rate | ~60 Hz (per-frame) | `PlayerProbe.gd:236-237` |
| Resource sync rate | ~6.7 Hz (every 150ms) | `MiningLevel.gd:462, 1109` |
| Tile break sync | On event, `reliable` | `MiningLevel.gd:2225` |
| Max clients | 1 guest (2 players total) | `NetworkManager.gd:14` |
| Estimated idle bandwidth | < 1 KB/s | Position + resource sync only |
| Estimated peak bandwidth | ~5–10 KB/s | Active mining, both players moving |
| Sync properties per synchronizer | N/A (manual RPC) | No `MultiplayerSynchronizer` used |
| Latency tolerance (estimated) | < 100ms comfortable | Not formally tested |
| `on_change` mode for resources | N/A | Manual timer-based sync |

---

## Risk Assessment

| Rank | Issue | Severity | Likelihood at Launch |
|------|-------|----------|---------------------|
| 1 | **C1** — Guest stranded on host disconnect | Critical | High — any host crash or rage-quit triggers this |
| 2 | **C2** — Double Overworld load at session start | Critical | High — every multiplayer session start exercises this path |
| 3 | **M4** — Planet config race condition (drop-in) | Major | Medium — only triggers when guest joins while host is on Overworld |
| 4 | **M1** — Guest sprint exploit | Major | Low — requires guest to notice the energy doesn't drain |
| 5 | **M2** — Mining rate exploit | Major | Low — only exploitable on LAN by motivated bad actor |
| 6 | **m7** — Ghost player node after disconnect | Minor | High — any disconnect mid-mine leaves the orphan |
| 7 | **M3** — Stale HUD values from unordered packets | Major | Low — very rare on LAN |
| 8 | **M5** — Chat sender spoofing | Major | Low — LAN context reduces threat |

---

## Recommended Fixes

### C1 — Guest stranded on host disconnect (Complexity: Low)

In `NetworkManager.join_host()`, connect `multiplayer.server_disconnected`:

```gdscript
# NetworkManager.gd — add signal
signal host_disconnected

# In join_host(), after connecting peer_disconnected:
multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_server_disconnected() -> void:
    print("NetworkManager: host disconnected")
    is_multiplayer_session = false
    host_disconnected.emit()
```

In `MiningLevel._setup_multiplayer_players()`, replace the dead-code branch (lines 609-612):

```gdscript
if NetworkManager.is_host:
    NetworkManager.guest_disconnected.connect(_on_coop_peer_disconnected)
else:
    NetworkManager.host_disconnected.connect(_on_coop_peer_disconnected)
```

In `GameManager` (and/or `MainMenu`), handle `host_disconnected` to return to the main
menu with an appropriate message.

---

### C2 — Double Overworld load (Complexity: Low)

`rpc_start_game_as_guest` should not load the scene itself — that responsibility belongs
to the host's `load_overworld()` → `rpc_load_overworld_as_guest` call. Remove the
`await _transition_to_scene(...)` from `rpc_start_game_as_guest` and keep it as a
state-only sync RPC:

```gdscript
@rpc("authority", "call_remote", "reliable")
func rpc_start_game_as_guest(carapace_lvl: int, ...) -> void:
    carapace_level = carapace_lvl
    # ... apply all kit fields ...
    EventBus.multiplayer_guest_kit_updated.emit()
    change_state(GameState.PLAYING)
    # Scene loading is handled separately by rpc_load_overworld_as_guest
```

`rpc_load_overworld_as_guest` already handles the transition. In `start_game()`, the
host sends both RPCs in sequence; `rpc_start_game_as_guest` sets state, then
`rpc_load_overworld_as_guest` (sent by `load_overworld()`) triggers the scene change.

The `rpc_drop_in_to_mine_as_guest` path is already correct (single combined RPC for
kit + scene load), so it does not need this change.

---

### M1 — Guest sprint exploit (Complexity: Medium)

Sprint should be gated through the host's energy pool. Options:

**Option A (Simpler):** Disable sprint for the guest entirely while in multiplayer.
Add an early return to the sprint block when the guest is not the host:

```gdscript
# PlayerProbe.gd — in _physics_process, sprint block:
var can_sprint := not (NetworkManager.is_multiplayer_session and not NetworkManager.is_host)
_sprinting = can_sprint and Input.is_action_pressed("sprint") and GameManager.current_energy > 0
```

**Option B (Correct):** Guest sends a sprint-energy-consumed RPC to the host, which
deducts from the shared pool and propagates via the next `rpc_sync_resources`. This
requires a new `rpc_consume_energy(amount: int)` RPC on MiningLevel, called by
PlayerProbe when sprint ticks over.

---

### M2 — Mining rate exploit (Complexity: Low)

Add a per-peer rate limit in `rpc_request_mine`:

```gdscript
var _guest_mine_last_time: float = 0.0
const GUEST_MINE_MIN_INTERVAL: float = 0.10  # Slightly under client's 0.12s to allow for jitter

@rpc("any_peer", "call_remote", "reliable")
func rpc_request_mine(grid_pos: Vector2i) -> void:
    if not NetworkManager.is_host:
        return
    var now := Time.get_ticks_msec() / 1000.0
    if now - _guest_mine_last_time < GUEST_MINE_MIN_INTERVAL:
        return
    _guest_mine_last_time = now
    # ... existing range check and try_mine_at ...
```

---

### M3 — `rpc_sync_resources` mode (Complexity: Trivial)

Change `"unreliable"` to `"unreliable_ordered"`:

```gdscript
@rpc("authority", "call_remote", "unreliable_ordered")
func rpc_sync_resources(minerals: int, energy: int) -> void:
```

---

### M4 — Planet config race in drop-in (Complexity: Medium)

Add a guest-side request RPC that the Overworld fires in `_ready()` when it detects
it's a guest in a multiplayer session:

```gdscript
# Overworld.gd _ready():
if NetworkManager.is_multiplayer_session and not NetworkManager.is_host:
    rpc_request_planet_config.rpc_id(1)  # Ask host to send config now that scene is ready

@rpc("any_peer", "call_remote", "reliable")
func rpc_request_planet_config() -> void:
    if not NetworkManager.is_host:
        return
    rpc_apply_planet_config.rpc_id(NetworkManager.guest_peer_id, SaveManager.get_planet_config())
```

This ensures the config is sent AFTER the guest's Overworld is instantiated, eliminating
the race.

---

### M5 — Chat sender spoofing (Complexity: Low)

Validate the sender ID in `_deliver_chat_message`:

```gdscript
@rpc("any_peer", "call_remote", "reliable")
func _deliver_chat_message(sender_name: String, text: String) -> void:
    var sender_id := multiplayer.get_remote_sender_id()
    # Validate: host sends from peer 1, guest sends from any other ID
    var expected_name := "Host" if sender_id == 1 else "Guest"
    if sender_name != expected_name:
        return  # Reject mismatched sender claim
    EventBus.chat_message_received.emit(sender_name, text)
```

---

### m4 — Missing bounds check in `rpc_tile_hit` (Complexity: Trivial)

Mirror the bounds check already present in `rpc_tile_broken`:

```gdscript
@rpc("authority", "call_remote", "reliable")
func rpc_tile_hit(grid_pos: Vector2i, damage_ratio: float) -> void:
    if grid_pos.x < 0 or grid_pos.x >= GRID_COLS or grid_pos.y < 0 or grid_pos.y >= GRID_ROWS:
        return
    _update_breaking_overlay(grid_pos, damage_ratio)
    _flash_cells[grid_pos] = 1.0
    SoundManager.play_impact_sound()
```

---

### m7 — Orphaned guest node on disconnect (Complexity: Low)

Free the guest node in `_on_coop_peer_disconnected`:

```gdscript
func _on_coop_peer_disconnected() -> void:
    _show_zone_banner("PARTNER DISCONNECTED", Color(1.0, 0.4, 0.2), -1)
    if guest_player_node:
        guest_player_node.queue_free()
        guest_player_node = null
```

---

## Test Matrix

All tests are **untested** (no automated multiplayer tests exist). The following checklist
should be executed manually before each release candidate.

### ENet Path

| Scenario | Expected | Status |
|----------|----------|--------|
| Host starts; guest joins before game starts | Both load Overworld; planet config matches | ☐ |
| Host starts; guest joins after game starts (on Overworld) | Guest sees correct planet chart | ☐ |
| Host starts; guest joins mid-mine (drop-in) | Guest enters same mine; kit banner shown | ☐ |
| Both players mine same tile simultaneously | Tile destroyed once; minerals awarded once | ☐ |
| Guest mines out-of-range tile | Request rejected silently | ☐ |
| Both players reach exit station | Both see RunSummary | ☐ |
| Energy depletes to zero | Both see game-over overlay; both return to Overworld | ☐ |
| Guest disconnects mid-mine | Host sees banner; continues solo; guest node freed | ☐ |
| **Host disconnects mid-mine** | **Guest sees banner; returns to main menu** | ☐ *(C1)* |
| Host closes game from Overworld | Guest returns to main menu | ☐ *(C1)* |
| Guest sends chat message | Both see `[Guest] message` | ☐ |
| Host sends chat message | Both see `[Host] message` | ☐ |
| Session ends; host re-hosts same save | Both can join a new session without restarting | ☐ |
| Full session at max activity (both mining, boss active) | No frame-rate collapse; sync stays coherent | ☐ |
| Port already in use on `create_server` | Error shown in lobby status | ☐ |
| Wrong IP on join | "Connection failed" status; no hang | ☐ |

### Steam Path

| Scenario | Expected | Status |
|----------|----------|--------|
| Steam invite flow | N/A — not implemented | — |

### Platform Matrix

| Platform | ENet Host | ENet Guest | Notes |
|----------|-----------|------------|-------|
| Windows | ☐ | ☐ | Primary target |
| Linux | ☐ | ☐ | Steam Deck / native |
| macOS | ☐ | ☐ | |
| Web (WebSocket) | N/A | N/A | Not implemented |

---

## Prioritised Fix Order

1. **C1** — Host disconnect handling (Low complexity, Critical severity) — fix first
2. **C2** — Double Overworld load (Low complexity, Critical severity) — fix second
3. **m7** — Free orphaned guest node on disconnect (Low complexity) — bundle with C1
4. **m4** — Bounds check in `rpc_tile_hit` (Trivial) — bundle with any PR
5. **M3** — `unreliable_ordered` for resource sync (Trivial) — bundle with any PR
6. **M4** — Planet config race fix (Medium complexity) — fix before Steam launch
7. **M2** — Mining rate limit (Low complexity) — fix before public release
8. **M5** — Chat sender validation (Low complexity) — fix before public release
9. **M1** — Guest sprint energy exploit (Medium complexity) — fix before public release
10. **m5** — Write multiplayer GUT tests — ongoing
