# Leap of Legends — Game Design Document (GDD)

| Field | Detail |
|---|---|
| Title | Leap of Legends |
| Genre | Endless vertical climber + idle/growth progression + optional PvP stomp |
| Platform | Roblox (PC / mobile / console, touch-adapted) |
| Mode | Always solo-playable; multiplayer on shared servers (suggested 8–16 players) |
| Camera | Third person |
| Doc version | v0.3 (draft) |
| Last updated | 2026-06-01 |

---

## 1. Elevator Pitch

> Hold space to keep jumping — but you only have so many seconds of jump time before you fall, so manage it well. Every press permanently thickens your legs, so the more you play the higher you can leap. Climb a procedurally generated, never-ending tower — loop back through a zone to stack temporary charge bonuses and push higher than anyone else. There is no finish line: your score is how high you climb, shown against every other player. Earn coins by climbing, buy wings to save yourself mid-fall, and watch your legs grow legendary.

---

## 2. Design Pillars

1. **Every Press Counts, Forever** — Each spacebar press grows account-permanent LegPower. Players feel themselves getting stronger across every session.
2. **Power is Risk** — Thicker legs jump higher but fall faster and take more fall damage. Power and fragility are bound together, especially near death zones.
3. **Manage Your Jump Time** — Holding Space jumps continuously but burns a limited jump-time meter; run out and you fall. Knowing when to bounce and when to land to recharge is the core skill.
4. **Climb, Loop, Climb Higher** — Looping back through a cleared zone resets it and grants a run-scoped charge bonus, turning a few procedural zones into an endless, replayable ascent.
5. **Easy to Learn, Hard to Master** — One key (space) to play; jump-time management, precise landings, and dodging death zones take real practice.

---

## 3. Core Loop

```
Enter game (solo or shared server) → spawn at the base
   ↓
Hold Space to keep jumping up (burns jump time; each hop: +LegPower permanently; thicker legs = higher hop + faster fall) → land to instantly refill jump time
   ↓
Run out of jump time mid-air → fall automatically until you land
   ↓
Gain new max height → earn Leap Coins (money) for new height only
   ↓
Reach a zone's top gate → optionally LOOP BACK to its start
   └─ Zone resets + grants a run-scoped Charge Bonus → climb even higher this run
   ↓
(If others share the server) stomp weaker-legged players from above → double jump
   ↓
Touch a death zone / fall too far → respawn at last checkpoint (run continues, nothing lost)
   ↓
Spend Leap Coins (temp boosts, basic wings) / Robux (premium wings, jump upgrades, glide charges)
   ↓
Push for a new personal-best height, compare against the global leaderboard
```

There is **no win condition** — the goal is maximum height. Sessions are open-ended.

---

## 4. Core Mechanics in Detail

### 4.1 Jump: height + speed (hold to rise & hover) — implemented (M1)

**Design** — jump **height** and jump **speed** are separate stats, both growing with LegPower:
- **Press Space to jump up — one jump per press.** You rise to **exactly** your **jump height** (no momentum overshoot past it), and you **fall immediately** the instant you stop rising — whether that's because you **released Space** or the **bar/peak was reached**. No hover/float. After landing, a *held* key does nothing — you must **release and press Space again** to jump.
- The **progress bar tracks the jump arc itself**: it starts full at launch, drains as you rise, and is **empty exactly at the climax** (the peak). So the bar always matches your jump height — a low jump empties it quickly, a high jump takes longer.
- **Each jump grows LegPower** (one jump = one "press"). More jumps → higher & faster jumps **and** thicker legs. Growth happens per jump, not while just holding the key.
- **Jump height starts LOW** — `5 studs`, below Roblox's default `7.2` — and grows with LegPower. So a fresh player is weak; the higher you can jump, the bigger the gaps you can clear.
- **Rise & fall speed are separate and fast**, and also scale with LegPower: the higher you can jump, the faster you rise to that height and the faster you fall back down.
- **Full air control**: horizontal movement follows your input (`MoveDirection × Air Move Speed`) every frame — steer while rising or falling.
- **No animation glitch**: the Humanoid `Jumping` state is disabled (airborne uses a stable Freefall pose), girth only updates on LegPower **tier** change, and a `MAX_VERTICAL_SPEED` clamp prevents tunneling through platforms.

```
JumpHeight = BaseJumpHeight × (1 + LegPowerHeightBonus) × (1 + ChargeBonus)   ← how high (starts < default)
RiseSpeed  = BaseRiseSpeed  × (1 + LegPowerSpeedBonus)  × (1 + ChargeBonus)   ← how fast up
FallSpeed  = BaseFallSpeed  × (1 + LegPowerSpeedBonus)                        ← how fast down (thicker = faster)
```

| Parameter | Initial value | Notes |
|---|---|---|
| Base jump height | 5 studs | Above the launch platform, at LegPower 0 (< 7.2 default) |
| LegPower height bonus | +20% per jump | grows very fast (≈2× every ~4 jumps) |
| Base rise speed | 120 studs/s | Snappy; scales with LegPower |
| Base fall speed | 90 studs/s | Scales with LegPower (thicker = faster) |
| LegPower speed bonus | +0.4% per press, uncapped | +100% at 250 presses, +400% at 1000 |
| Max vertical speed | 240 studs/s | Safety clamp (prevents platform tunneling) |
| Air move speed | 18 studs/s | Horizontal steering while airborne |
| Max airborne time | 2.0s | Safety only (stop rising if blocked under a ledge) |
| LegPower per jump | +1 press | One jump = one press (grows account-permanent LegPower) |

### 4.2 LegPower (Leg Muscle) — prototype exists, now account-permanent

**Current**: `UpdateMuscle:FireServer(numPressed)` is wired, but server logic is empty.

**Target design**:
- **`LegPower`** is a server-authoritative, **account-permanent** stat saved via DataStore. Every spacebar press increments it; it **never resets**. The longer a player plays, the thicker their legs.
- LegPower drives:
  1. **Visual**: leg mesh/scale thickens by tier (`UpdateMuscle`).
  2. **Jump & fall speed**: higher LegPower → faster rising *and* faster falling (and thus higher reach), scaling **continuously with no cap** — long-term players keep getting stronger.
  3. **Stomp resolution**: decides stomp outcome when other players are present (see 4.3).
  4. **Fall cost (the counter)**: thicker legs fall faster and have a **lower fall-damage threshold**. Big legs stay genuinely risky near death zones. *(Confirmed kept.)*

| LegPower tier | Cumulative presses (approx) | Jump/fall speed bonus (no cap) | Fall accel | Visual leg girth |
|---|---|---|---|---|
| 1 | 0–250 | +0% | ×1.0 | 100% |
| 2 | 250–1k | +25% | ×1.2 | 130% |
| 3 | 1k–4k | +60% | ×1.5 | 170% |
| 4 | 4k–15k | +120% | ×1.8 | 220% |
| 5 | 15k+ | +200%, keeps scaling | ×2.0 | 260% |

> **Anti-trivialization safeguards:** (1) **higher zones require a minimum LegPower** to be passable, so there is always somewhere to grow into; (2) the **fall-risk counter** — thicker legs jump higher but fall faster and take more fall damage — keeps big legs genuinely dangerous near death zones.

### 4.3 Stomp & Double Jump — opportunistic PvP bonus

When other players share the server, stomping adds a competitive layer. With solo play it simply never triggers.

> **Implemented (M2):** the push-down half. The server detects when you're on top of another player (within `STOMP_RADIUS` horizontally, `STOMP_MIN_DY..STOMP_MAX_DY` above, not jumping up into them); if your LegPower is higher, it sends `Stomped` to the victim, who is driven downward for `STOMP_STUN` seconds (jump input ignored). The stomper's **double-jump reward is not wired yet** — see below for the planned full design.

**Trigger**: Player A lands on player B's head hitbox **from above**. The **server** compares `A.LegPower` vs `B.LegPower`.

| Case | For A (stomper) | For B (stomped) |
|---|---|---|
| A.LegPower > B.LegPower | Gains **one double jump** + a small upward bounce | Knocked downward, 0.5s stun |
| A.LegPower = B.LegPower | Both bounce apart | Both bounce apart |
| A.LegPower < B.LegPower | Bounced up/sideways, no double jump | Acts as a "bounce pad" |

**Double jump**: normally `MAX_JUMPS = 1`; a stomp temporarily grants `+1` (cleared on landing). Double-jump height = current charged height ×0.8 → "stomp to climb higher" combos.

**Fairness notes**: stomped player gets 0.3s invuln (no stomp-locking); stomping near death zones is high-risk. ⚠️ Because LegPower is now account-permanent, veterans will out-stomp newcomers — acceptable since stomp is **secondary content**, but flagged in Risks for later (e.g., optional current-run delta or LegPower-bracketed servers).

### 4.4 Falling & Fall Damage — prototype exists

**Current**: a fall distance `>= 600` triggers `FallDamage:FireServer()`; `StartFalling/StopFalling` are wired.

**Target design**:
- Fall-damage threshold **lowers as LegPower rises** (thicker legs fall harder) — this is the core counter to permanent growth.
- Damage = (amount over threshold) × coefficient; can be lethal → respawn at checkpoint.
- `StartFalling(numPressed)` increases fall acceleration based on leg thickness for a weighty feel.

### 4.5 Death Zone & Respawn — prototype exists

**Current**: the `DeadZone` script sets `Humanoid.Health = 0` on touch.

**Target design**:
- Death zones = the void below, lava gaps, spinning blades, swinging hammers, etc.
- On death, **respawn at the nearest checkpoint** — the run continues and nothing is permanently lost (LegPower, coins, and max height are all banked).
- Checkpoints: a safe platform every N sections.

### 4.6 Wings (replaces Flight) — paid glide/ability system

Persistent flight is removed (it conflicted with the charge-jump key and trivialized climbing). It is replaced by **Wings**: an equippable item that grants a save-yourself ability, activated mid-fall by spending a **Glide Charge**.

**Two-part model:**
- **Wing type** = the visual + ability. Owned permanently. Basic tiers buyable with **Leap Coins**; premium tiers (stronger abilities) buyable with **Robux**. Better ability = higher price.
- **Glide Charge** = consumable fuel. Each activation spends 1 charge. Bought as a **Robux Developer Product** (the chosen monetization model). Rare free charge pickups may appear in levels.

**Wing ability tiers (initial):**

| Tier | Wing | Ability | Acquire |
|---|---|---|---|
| 1 | Basic Feather | 3s slow descent (save yourself) | Leap Coins |
| 2 | (TBD) | Longer slow descent (e.g. 5–6s) | Leap Coins / Robux |
| 3 | (TBD) | Ability to **fly up** for a short burst | Robux |

> 📝 **Reminder for development:** when we start building Wings, brainstorm more ability types beyond "slow descent" and "fly up" (e.g. horizontal dash, hover, anti-knockback, brief death-zone immunity). Pricing scales with power. — *Leila to revisit at implementation time.*

⚠️ **Detail to confirm at dev time:** whether premium wings are activation-charge-based (Dev Product) or cooldown-based (Game Pass). Current plan = own the wing + spend Glide Charges.

---

## 5. Level Design: Procedural Endless Tower

- The tower is an endless stack of standardized **Sections** (Roblox Models) with aligned entry/exit interfaces, weighted harder with height.
- **Section archetypes**: variable-width gap jumps, moving platforms, crumbling platforms, death-zone hazards (lava gaps, spinning blades, swinging hammers), bounce pads (free height), wind zones (where Wings shine), narrow precision ledges, and **optional high-LegPower side routes**.
- **Themed zones by height** (each gated by a minimum LegPower): Grassland → Caverns → Industrial → Sky → Space, switching skybox/palette/gravity. Zone gating is what keeps the permanent-growth curve meaningful.
- Sections tagged via CollectionService; the generator runs **server-side** and replicates so everyone on a server sees the same tower.
- **Generator input**: a per-server random seed (logged for reproducibility / leaderboards).

### 5.1 Loop-and-Prestige (the "go back to start" reward)

- On reaching a zone's **top gate**, the player unlocks the option to **loop back** to that zone's start.
- Looping **resets/regenerates the zone** and grants a **run-scoped Charge Bonus** — slightly more charge per press, so jumps go higher *this run*. **This is NOT permanent jump power.**
- Charge Bonus is additive per loop and stacks up to a cap; it **resets when the player leaves the game**, keeping the loop active every session.
- Design payoff: a handful of procedural zones become endlessly replayable, players self-pace their power spikes, and we need far fewer hand-authored levels.

| Loop parameter | Initial value |
|---|---|
| Charge Bonus per loop | +5% charge |
| Charge Bonus cap | +50% (10 loops) |
| Persistence | Run-scoped (resets on leaving the game) |

### 5.2 Height Comparison

- **Live server leaderboard**: current height of everyone on the server.
- **Global all-time leaderboard**: highest height ever reached (per account).
- **Ghost height markers**: faint banners on the tower marking where top players / friends reached — motivation + shareable screenshots.

---

## 6. Session Structure (No Win Condition)

- Open-ended: a player keeps climbing until they choose to leave.
- **Score = max height reached.** Persisted per account; surfaced on leaderboards.
- Death never ends a session — it respawns at a checkpoint.
- Side boards: most loops in one run, biggest single jump, stomp count, fastest to a height milestone.

---

## 7. Progression & Economy

Two clean growth tracks (no overlap):

| Source | Grants | Scope |
|---|---|---|
| **Spacebar press** | **LegPower** | Account-permanent (DataStore) |
| **New max height climbed** | **Leap Coins** (money) | Account-permanent (DataStore) |
| **Looping a zone** | **Charge Bonus** | Run-scoped |

**Leap Coins** are earned for **new height only** (climbing above your run's previous max), preventing up/down farming.

**Currency sinks:**

| Currency | Buys |
|---|---|
| **Leap Coins** (earned by climbing) | Temporary boosts (e.g. 2× coins, 2× charge, brief speed); basic Wings |
| **Robux** (real money) | Premium Wings (stronger abilities); **permanent jump-power upgrades**; Glide Charges (consumable) |

> Players who want to progress faster buy Robux to purchase high-tier wings and jump-power upgrades. Everything is reachable through play; Robux accelerates and adds flair.

---

## 8. Multiplayer & Networking

> **Critical**: the current prototype is **client-authoritative** (client sets `humanoid.Health`, judges jumps locally). This must migrate to **server-authoritative**, both for PvP stomping and to protect the account-permanent LegPower / coins / leaderboards from exploits.

**Server (authoritative)**: LegPower, Leap Coins, max height, jump-power upgrade level, owned wings, glide charges — all validated and persisted via DataStore. Also: stomp resolution, death/respawn/checkpoints, tower generation, loop/prestige grants, anti-cheat (displacement/speed caps, server-recomputed fall damage), leaderboards, Robux purchases via MarketplaceService.

**Client**: input capture, presentation/prediction, reporting intent (charge value, jump, wing activation) for server confirmation.

---

## 9. Technical Implementation Mapping

### Existing RemoteEvents (reuse)

| Remote | Current | Role |
|---|---|---|
| `UpdateJumpHeight` | wired | Client reports charged-jump intent → server confirms height |
| `UpdateMuscle` | wired | Server pushes leg-girth visual from LegPower |
| `StartFalling` / `StopFalling` | wired | Fall acceleration & timing |
| `FallDamage` | wired | **Server-recomputed** fall damage; client only triggers |

### To add

| Name | Type | Purpose |
|---|---|---|
| `RequestJump` | C→S | Report charged-jump intent (server validates) |
| `HeightUpdate` | C→S→C | Report/confirm new max height, award Leap Coins |
| `CurrencyUpdate` | S→C | Push Leap Coins balance |
| `LoopPrestige` | C→S→C | Trigger zone loop, grant run-scoped Charge Bonus |
| `ActivateWing` | C→S | Request wing glide (server checks charges/ownership) |
| `WingState` | S→C | Glide start/stop, charge count, effects |
| `StompResolved` | S→C | Stomp result + double-jump grant + effects |
| `GrantDoubleJump` | S→C | Temporary double-jump allowance |
| `TowerGenerated` | S→C | Push tower seed/structure |
| `CheckpointReached` | C→S→C | Record/confirm checkpoints |

Robux purchases (premium wings, jump-power upgrades, glide charges) go through **MarketplaceService** (Game Passes + Developer Products), not RemoteEvents.

### Suggested module structure (Rojo mapping)

```
src/
  server/        → ServerScriptService (authoritative)
    TowerGenerator/
    SessionManager/
    StompResolver/
    LegPowerService/      ← persists LegPower
    EconomyService/       ← Leap Coins, height payouts
    WingService/          ← ownership, glide charges, activation
    PurchaseService/      ← MarketplaceService handling
    DataStore/            ← profile save/load
    AntiCheat/
  client/        → StarterPlayerScripts (input & presentation)
  character/     → StarterCharacterScripts (character-mounted)
  shared/        → ReplicatedStorage
    Config/      ← all numeric constants (balance tuning)
    Remotes/     ← RemoteEvent definitions
```

---

## 10. UI / UX

- **Jump-time bar** at the bottom center; drains while jumping, refills on the ground, turns red as it empties.
- **LegPower indicator**: own leg girth + tier icon; other players show their tier above their head (stomp decision).
- **Height & rank HUD**: current height, personal best, gap to nearest ghost / leaderboard rank.
- **Currency HUD**: Leap Coins balance, +coins popups on new height.
- **Wings widget**: equipped wing, remaining glide charges, activation button (mobile long-press friendly).
- **Stomp feedback**: screen shake + "STOMP!" pop + double-jump prompt.
- **Mobile**: charge/jump button reusing the existing `TouchGui` adaptation logic.

---

## 11. Art & Audio Direction

- **Style**: bright, cartoonish, exaggerated "muscle" — thicker legs look comically powerful, reinforcing memorability/shareability.
- **Character**: standard Roblox avatar + swappable tiered leg-muscle meshes.
- **Wings**: distinct visuals per tier (feather → larger feathered wings → mechanical/energy wings), telegraphing ability strength.
- **Tower**: themed zones (grassland → caverns → industrial → sky → space) shifting skybox/palette.
- **Audio**: charge "power-up," jump "thump," stomp "boom + comedic spring," wing "whoosh," fall wind, height-milestone chime.

---

## 12. Numbers & Balance (initial tuning table)

> All constants centralized in `src/shared/Config/` for hot tuning. Starting suggestions — iterate via playtest.

| Parameter | Value |
|---|---|
| Base jump height | 6 studs (< 7.2 default), +0.2%/press |
| Base rise speed | 120 studs/s (scales with LegPower) |
| Base fall speed | 90 studs/s (scales with LegPower) |
| Max vertical speed | 240 studs/s (anti-tunneling clamp) |
| Air move speed | 18 studs/s |
| Max airborne time | 2.0s (safety only; jump ends at the peak) |
| LegPower speed bonus | +0.4% per press, uncapped (+100% @250, +400% @1000) |
| LegPower tick interval | 0.15s while holding |
| LegPower jump bonus | scales continuously, no cap |
| Charge Bonus per loop / cap | +5% / +50% |
| Double-jump height multiplier | ×0.8 |
| Stomp invuln frame / stun | 0.3s / 0.5s |
| Fall-damage threshold (LegPower 1 → 5) | 600 → 280 |
| Leap Coins per new stud of height | 1 (tune) |
| Basic Feather glide duration | 3s |
| Checkpoint interval | every 10 sections |

---

## 13. Monetization (Roblox)

**Revised principle:** This is an endless, solo-focused climber, so paid items may include **cosmetics, safety/convenience (wings, glide charges), and acceleration (jump-power upgrades)**. The one guardrail: keep a fair comparison space.

- **Robux Developer Products**: Glide Charges (consumable), Leap Coin packs, temporary boost bundles.
- **Robux purchases**: premium Wings (stronger abilities), permanent jump-power upgrades.
- **Game Passes**: cosmetic bundles, VIP perks (e.g. extra checkpoint, bonus coin rate).

> Robux can buy permanent jump-power, so paying players will rank higher on the global height board — this is intentional and accepted. No separate "free" leaderboard; one global board for everyone.

---

## 14. MVP Scope & Milestone Roadmap

### MVP (prove the core fun)
- [x] Continuous hold-to-jump with a jump-time meter (smooth rise, fall when empty, instant refill on landing)
- [x] Jump & fall speed scale with LegPower (faster the thicker your legs)
- [x] LegPower growth (account-permanent) + leg/body girth visual, persisted via DataStore (in-memory fallback)
- [x] Height tracking → Leap Coins payout (new-height-only)
- [x] HUD (height / best / LegPower / coins) + jump-time bar
- [x] One hand-built fixed test tower (30-platform zig-zag, built in Studio)
- [ ] Loop-and-prestige Charge Bonus on a single test zone
- [ ] Death zone + checkpoint respawn
- [ ] Basic Feather wing (3s glide) + Glide Charge consumption (stub purchase)

### Milestones

| Phase | Goal |
|---|---|
| M1 Validate | MVP: low-jump + LegPower growth + loop charge bonus running; test whether "press, grow, loop higher" is fun solo |
| M2 Content | Procedural tower, section library, themed zones, zone LegPower gating, checkpoints |
| M3 Economy & Wings | Leap Coins sinks, wing tiers, Glide Charges, temp boosts, MarketplaceService |
| M4 Social & Retention | Leaderboards, ghost markers, daily quests, stomp PvP polish |
| M5 Launch | Robux monetization, jump-power upgrades, launch event, telemetry & iteration |

---

## 15. Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Client authority enables cheating | Permanent stats / leaderboards corrupted | Migrate to server authority + DataStore at M1; validate displacement/damage server-side |
| Permanent LegPower trivializes levels | Game gets boring | Zone LegPower gating + fall-risk counter (no jump-bonus cap by design) |
| Veterans out-stomp newcomers (permanent LegPower) | New-player frustration | Stomp is secondary; optional current-run delta or LegPower-bracketed servers later |
| Two currencies confuse players | Onboarding friction | Strict split: spacebar→LegPower, height→coins, loops→charge; clear HUD/tutorial |
| Procedural tower dead ends | Stuck players | Standardized section interfaces + post-gen reachability check |
| Poor mobile charge feel | Mobile churn | Long-press charge + touch-specific tuning, playtest early |

---

## 16. Open Questions

1. Premium wings: charge-consumable (Dev Product) or cooldown (Game Pass)? (Current plan: own wing + spend Glide Charges.)
2. **More wing abilities to design at dev time** (see §4.6 reminder) — what's the full ability roster and pricing curve?
3. Stomp fairness with permanent LegPower — leave as-is, current-run delta, or bracketed servers?
4. Does the run-scoped Charge Bonus persist across death (within a session) or only while you don't leave? (Current: resets only on leaving the game.)
5. Exact Leap Coins payout curve and what early-game temp boosts feel best.

---

*This document is a v0.2 draft (endless-climber pivot), to be iterated on numbers and mechanics after the M1 prototype playtest.*
