# Leap of Legends — Game Design Document (GDD)

| Field | Detail |
|---|---|
| Title | Leap of Legends |
| Genre | Vertical climb race + light PvP (Tower of Hell style + stomp combat) |
| Platform | Roblox (PC / mobile / console, touch-adapted) |
| Mode | Multiplayer single-server rounds (suggested 8–16 players per server) |
| Camera | Third person |
| Doc version | v0.1 (draft) |
| Last updated | 2026-05-31 |

---

## 1. Elevator Pitch

> Inside a randomly generated, time-limited tower, "hold space to charge" decides how high you jump. The more you jump, the thicker your legs get — and thick-legged players can stomp thin-legged ones off the tower, then ride the stomp into a double jump toward the summit. First to the top wins, but every charge makes you stronger *and* more fragile.

---

## 2. Design Pillars

1. **Charge is Risk** — Every jump makes your legs thicker and your jump higher, but it also makes you fall faster and take more fall damage. Players constantly trade "climb fast" against "climb safe."
2. **Mass Matters** — Muscle isn't just cosmetic; it decides who wins a stomp. The stronger player can stomp the weaker one and gain a double jump, enabling comebacks and aggressive play.
3. **Easy to Learn, Hard to Master** — One key (space) to play; but charge timing, stomp landing, and dodging death zones take real practice.
4. **Always a New Tower** — Procedurally assembled levels guarantee replayability and shareability (great for short-form video / streaming).

---

## 3. Core Loop

```
Enter round → spawn at tower base
   ↓
Charge-jump upward (each jump: legs thicker + jump higher + fall faster)
   ↓
Meet another player → stomp from above → compare leg thickness
   ├─ I'm thicker: they get stomped down, I gain a double jump, ride it higher
   └─ I'm thinner: I bounce off / get stomped down instead
   ↓
Touch a death zone / fall too far → take damage or return to checkpoint
   ↓
Reach summit or timer ends → results → rewards → new tower restarts
```

Target round length: **5–8 minutes**.

---

## 4. Core Mechanics in Detail

### 4.1 Charged Jump — prototype exists

**Current** (`src/character/JumpHeightWMuscleGrowthWFallingSpeed.client.luau`):
- Each jump does `numPressed += 1`, firing `UpdateJumpHeight` / `UpdateMuscle` / `StartFalling`.
- `MAX_JUMPS = 1`, `TIME_BETWEEN_JUMPS = 0.2`, `numJUMPS` resets on landing.

**Target design**:
- Player **holds space to charge, releases to jump**. Charge duration (0 → full) maps to jump height.
- Also keep the "accumulation" reading: consecutive successful jumps raise `numPressed`, making legs thicker and the single-jump ceiling higher over time.
- During charge the character shows a visible "crouch + leg swell" wind-up, giving opponents read-able information.

| Parameter | Initial value | Notes |
|---|---|---|
| Base jump height | 7.2 (Roblox default) | Uncharged minimum jump |
| Full-charge height multiplier | ×3.5 | Jump height at full charge |
| Time to full charge | 0.8s | Hold space to max |
| Move speed while charging | ×0.3 | Slowed while charging, creates a tradeoff |

### 4.2 Leg Muscle / Leg Power — prototype exists

**Current**: `UpdateMuscle:FireServer(numPressed)` is wired, but server logic is empty.

**Target design**:
- Define a character stat **`LegPower`** (server-authoritative, stored as a Humanoid Attribute).
- `LegPower` grows with cumulative jump count and drives:
  1. **Visual**: leg mesh/scale thickens by tier (`UpdateMuscle`).
  2. **Jump ceiling**: thicker legs → higher possible full-charge jump.
  3. **Stomp resolution**: decides stomp combat outcome (see 4.3).
  4. **Fall cost**: thicker legs → faster fall acceleration and a lower fall-damage threshold (inherits `StartFalling` logic) — this is `LegPower`'s natural counter.

| LegPower tier | Cumulative jumps | Jump multiplier bonus | Fall acceleration | Visual leg girth |
|---|---|---|---|---|
| 1 | 0–4 | +0% | ×1.0 | 100% |
| 2 | 5–11 | +15% | ×1.2 | 130% |
| 3 | 12–24 | +35% | ×1.5 | 170% |
| 4 | 25+ | +60% | ×2.0 | 220% |

> **Balance core**: thick legs = jump higher + stomp harder, but = fall faster and get punished more easily by death zones / fall damage. Strength and fragility are bound together to avoid snowballing.

### 4.3 Stomp & Double Jump — **new core mechanic**

This is the soul mechanic that sets the game apart from a plain Tower of Hell.

**Trigger conditions**:
- Player A lands on player B's head hitbox **from above** (A's feet / downward velocity).
- The **server** compares `A.LegPower` vs `B.LegPower`.

**Resolution**:

| Case | For A (stomper) | For B (stomped) |
|---|---|---|
| A.LegPower > B.LegPower | Immediately gains **one double jump** (can jump again mid-air) + a small upward bounce | Knocked downward (loses height), 0.5s stun |
| A.LegPower = B.LegPower | Both bounce apart (nobody benefits) | Both bounce apart |
| A.LegPower < B.LegPower | Bounced up/sideways, no double jump | Unaffected; acts as a "bounce pad" |

**Double jump details**:
- Normally `MAX_JUMPS = 1`; a successful stomp temporarily sets `MAX_JUMPS += 1` (cleared on landing).
- Double-jump height = current charged height ×0.8, encouraging "stomp → ride higher" combos.
- Design intent: turn "stomping" from pure griefing into an **offensive mobility tool** — strong players actively seek out weaker ones to stomp as a way to accelerate to the top.

**Counterplay & fairness**:
- The stomped player gets 0.3s of invulnerability to prevent stomp-locking.
- Stomping near a death zone is extremely risky (botch your own landing and you fall too) — high risk, high reward.
- `LegPower` **resets every round**, preventing cross-round dominance.

### 4.4 Falling & Fall Damage — prototype exists

**Current**: a fall distance `>= 600` triggers `FallDamage:FireServer()`; `StartFalling/StopFalling` are wired.

**Target design**:
- The fall-damage threshold lowers as `LegPower` rises (thicker legs fall harder).
- Damage = (amount over threshold) × coefficient, can be lethal (health to zero → return to checkpoint).
- `StartFalling(numPressed)` increases fall acceleration based on leg thickness, reinforcing the sense of "weight."

### 4.5 Death Zone & Respawn — prototype exists

**Current**: the `DeadZone` script sets `Humanoid.Health = 0` on touch.

**Target design**:
- Death zones = the void at the tower base / lava / spinning blades and other hazard surfaces.
- On death, **return to the nearest checkpoint** (not the classic Tower of Hell "back to the base," since with PvP added a full restart is too punishing).
- Checkpoints: a safe platform every N sections; touching one records it.
- Optional "casual/hardcore" toggle: hardcore mode removes checkpoints for players who want the challenge.

### 4.6 Press to Fly — to be decided

**Current**: the `PressToFly` script exists; hold space to fly, fly time accumulates with charge.

**Decision**: in this design, **flight conflicts with the charged-jump key** (both use space), and unlimited flight breaks the climbing challenge. Recommend choosing one:
- **Option A (recommended)**: remove persistent flight; replace with a **rare item/ability** — pick up a "feather" on the tower for 3s of timed glide, used to save yourself.
- **Option B**: as a paid/unlockable special-character passive, balanced separately.

---

## 5. Level Design: Procedural Tower

- The tower is assembled bottom-to-top from prefabricated **Sections**. Each section is an independent Roblox Model with a standardized entry/exit interface (bottom entry aligned to top exit).
- The section library is graded by difficulty (Easy / Medium / Hard / Insane), weighted toward harder picks as height increases.
- Each section contains: jump gaps, moving platforms, death-zone hazards, optional checkpoints.
- Target tower height: **150–250 sections** / roughly 5–8 minutes to summit (for skilled players).
- Sections are tagged with CollectionService; the generator runs on the server and replicates the result to all clients, guaranteeing the same tower on the same server.

**Generator input**: a random seed (one per round, written to the leaderboard for reproducibility / competitive play).

---

## 6. Round Structure & Win Condition

| Phase | Duration | Notes |
|---|---|---|
| Prep | 10s | Generate new tower, gather players at base, show the seed |
| Climb | 6 min (cap) | Main gameplay |
| Finish | 30s after first summit | Lets remaining players sprint |
| Results | 10s | Ranking, rewards, stats display |

**Win / ranking**:
- 1st place = **first to summit**; if nobody summits, rank by **highest height reached**.
- Side boards: stomp count, biggest single jump, no-death clears and other achievement boards.

---

## 7. Progression & Meta

`LegPower` resets within a round, but there is permanent cross-round growth:

- **Currency**: earn "Leap Coins" from summiting / ranking / stomping.
- **Unlocks**:
  - Cosmetic skins (leg styles, jump-launch effects, stomp effects).
  - Jump/land sound effects.
  - Character trails.
- **Level system**: cumulative play XP raises account level, unlocking challenge modes.
- **Daily quests**: e.g. "stomp 5 players," "climb 50 sections with no deaths," to boost retention.

> Permanent growth grants **cosmetics and challenge content only, never stat advantages**, keeping the race fair (avoid P2W undermining leaderboard credibility).

---

## 8. Multiplayer & Networking

> **Critical**: the current prototype is **client-authoritative** (the client directly sets `humanoid.Health`, judges jumps locally). Once PvP stomping is added, it must migrate to **server-authoritative**, or cheating becomes trivial (teleport to summit, fake LegPower, invulnerability).

**Server responsibilities (authoritative)**:
- Maintain each player's `LegPower`, validate positions, record height.
- Stomp resolution (compare LegPower, apply knockback, grant double jump).
- Death / respawn / checkpoints.
- Tower generation, round state machine, leaderboard.
- Anti-cheat: validate move-speed/displacement caps, recompute fall damage server-side.

**Client responsibilities**:
- Input capture (charge, jump, move).
- Presentation (animation, effects, UI, prediction).
- Report intent (jump, charge value) to the server for confirmation.

---

## 9. Technical Implementation Mapping

### Existing RemoteEvents (reuse)

| Remote | Current | Role in new design |
|---|---|---|
| `UpdateJumpHeight` | wired | Client reports charged-jump intent → server confirms jump height |
| `UpdateMuscle` | wired | Server pushes leg-girth visual updates based on `LegPower` |
| `StartFalling` / `StopFalling` | wired | Control fall acceleration and fall timing |
| `FallDamage` | wired | Change to **server-recomputed** fall damage; client only triggers |

### To add

| Name | Type | Purpose |
|---|---|---|
| `StompResolved` | RemoteEvent (S→C) | Notify stomp result (who got stomped, double-jump grant, effects) |
| `GrantDoubleJump` | RemoteEvent (S→C) | Server grants temporary double-jump allowance |
| `TowerGenerated` | RemoteEvent (S→C) | Push the round's tower seed/structure |
| `RoundState` | RemoteEvent (S→C) | Sync round phase and countdown |
| `CheckpointReached` | RemoteEvent (C→S→C) | Record/confirm checkpoints |
| `RequestJump` | RemoteEvent (C→S) | Report charged-jump intent (server validates) |

### Suggested module structure (Rojo mapping)

```
src/
  server/        → ServerScriptService (server-authoritative logic)
    TowerGenerator/
    RoundManager/
    StompResolver/
    LegPowerService/
    AntiCheat/
  client/        → StarterPlayerScripts (input & presentation)
  character/     → StarterCharacterScripts (character-mounted scripts)
  shared/        → ReplicatedStorage (shared config, Remote definitions, constants)
    Config/      → all numeric constants centralized (easy balance tuning)
    Remotes/     → RemoteEvent definitions
```

---

## 10. UI / UX

- **Charge bar**: a charge progress ring under/above the character; release to jump.
- **LegPower indicator**: your own leg girth + a tier icon on the HUD; other players show their LegPower tier above their head, to inform the "can I stomp them?" decision.
- **Height / rank HUD**: current height, current rank, gap to 1st place.
- **Round timer**: countdown at the top.
- **Stomp feedback**: on a successful stomp, screen shake + "STOMP!" pop text + double-jump prompt.
- **Mobile**: jump/charge button (long-press to charge), reusing the existing `TouchGui` adaptation logic.

---

## 11. Art & Audio Direction

- **Style**: bright, cartoonish, slightly exaggerated "muscle" feel — the thicker the legs the more comically exaggerated, reinforcing memorability and shareability.
- **Character**: standard Roblox avatar + swappable tiered leg-muscle meshes.
- **Tower**: themed layers (grassland → industrial → sky → space), switching Skybox and palette with height.
- **Audio**: charge "power-up" sound, jump "thump," stomp "boom + comedic spring," fall wind, summit fanfare.

---

## 12. Numbers & Balance (initial tuning table)

> Keep all constants centralized in `src/shared/Config/` for hot tuning. The values below are starting suggestions and need playtest iteration.

| Parameter | Value |
|---|---|
| Time to full charge | 0.8s |
| Base jump height | 7.2 |
| Full-charge height multiplier | ×3.5 |
| Move-speed multiplier while charging | ×0.3 |
| Double-jump height multiplier | ×0.8 |
| Stomp invuln frame | 0.3s |
| Stomped stun | 0.5s |
| Fall-damage threshold (LegPower 1) | 600 |
| Fall-damage threshold (LegPower 4) | 300 |
| Single-round climb time cap | 6 min |
| Checkpoint interval | every 10 sections |

---

## 13. Monetization (Roblox)

- **Game Passes**: extra cosmetic slots, exclusive jump-launch effects, hardcore-mode entry.
- **Developer Products**: revive at checkpoint (limited/timed), skin rolls, double Leap Coins (timed).
- **Principle**: **never sell stats / jump power / stomp win-rate**, only cosmetics and convenience. Protects race fairness and community trust.

---

## 14. MVP Scope & Milestone Roadmap

### MVP (prove the core fun)
- [ ] Charged jump (server-confirmed)
- [ ] LegPower growth + leg-girth visual
- [ ] Stomp resolution + double jump (**core differentiator, validate first**)
- [ ] Death zone + checkpoint respawn
- [ ] One hand-built fixed test tower (skip procedural generation for now)
- [ ] Basic round loop + summit detection

### Milestones

| Phase | Goal |
|---|---|
| M1 Validate | MVP: fixed tower + stomp/double-jump running, internally test whether "stomp to climb" is fun |
| M2 Content | Procedural tower generation, section library, checkpoints, round system |
| M3 Retention | Meta progression, skins, daily quests, leaderboards |
| M4 Polish | Anti-cheat hardening, mobile adaptation, art/audio, performance optimization |
| M5 Launch | Monetization, launch event, telemetry and iteration |

---

## 15. Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Client authority enables cheating | PvP leaderboard loses credibility | Migrate to server authority at M1; validate displacement/damage server-side |
| Stomp snowball (rich-get-richer) | Weak players have a bad time, churn | LegPower resets each round + thick-legs-fall-harder counter + invuln frames |
| Charge vs fly key conflict | Confusing controls | Downgrade flight to a timed item (see 4.6) |
| Procedural tower produces dead ends / impassable gaps | Stuck players | Standardized section interfaces + post-generation reachability check |
| Poor mobile charge feel | Mobile users churn | Long-press charge + touch-specific tuning, playtest early |

---

## 16. Open Questions

1. Checkpoints: casual (with checkpoints) or keep classic Tower of Hell hardcore (fall → back to base)? Or both modes?
2. Stomp outcome: use "strictly greater" or does "equal also wins"? Affects same-tier combat feel.
3. Per-server player cap (8 / 16 / 24)? Affects stomp density and server load.
4. Final fate of flight (item / character passive / removed entirely)?
5. After summiting, spectate or move into next-tower warm-up?

---

*This document is a v0.1 draft, to be iterated on numbers and mechanics after the M1 prototype playtest.*
