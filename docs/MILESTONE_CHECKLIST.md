# Milestone Progress Checklist

Tracks what's **developed** vs **still to do** across **all milestones (M1–M5)**.
`[x]` = developed & in the game · `[ ]` = not yet · `[~]` = partial.

> **Rule:** Keep this updated as features land, for current **and future** milestones.
> It must always reflect the **newest version of the GDD** (§14 milestones) — when the
> GDD changes, re-sync this list. Verify items against the actual code in `src/`.

---

## M1 — Validate

Based on GDD §14 MVP.

## ✅ Developed (done)

- [x] **Core jump system** — `src/client/JumpController.luau`
  - Note: evolved past the GDD's original "jump-time meter" wording. Current behavior: press Space + hold to rise toward **max height = presses × `BASE_JUMP_HEIGHT`**, release or hit the peak → fall immediately, **no auto-jump** (must release + press again), rises to the exact height (no momentum overshoot).
- [x] **LegPower — account-permanent, +1 per jump** — `src/server/Services/LegPowerService.luau`
- [x] **Persistence (DataStore + in-memory fallback)** — `src/server/Services/Profile.luau`
- [x] **Rise & fall speed scale with LegPower** — `Config` + `JumpController`
- [x] **Leg visual: per-leg ballooning, grows with LegPower** — `src/server/Services/LegVisual.luau`
- [x] **Height tracking → Leap Coins (new-height-only)** — `HeightTracker` + `EconomyService`
- [x] **HUD (height / best / LegPower / coins) + jump bar** — `src/client/HUD.luau` + bar in `JumpController`
- [x] **Hand-built fixed test tower** — built in Studio (lives in the `.rbxlx`, not in git)

## ⬜ Still underdeveloped (remaining for M1)

- [ ] **Loop-and-prestige Charge Bonus** — only a placeholder `ChargeBonus` attribute exists (always `0`, read in `JumpController`); no zone-loop / prestige mechanic yet.
- [ ] **Death zone + checkpoint respawn** — the old `src/workspace/Floor/DeadZone.server.luau` is just an unwired backup; no checkpoint system.
- [ ] **Basic Feather wing (3s glide) + Glide Charge consumption (stub purchase)** — not started (the old `PressToFly` prototype was removed).

## 🐞 Bugs (M1)

- [x] **Airborne animation** — The FALL anim used to show the whole airborne time. A custom looped jump-anim track was tried, but it **glitched on tall jumps** (short clip looping over a long rise). **Final fix:** removed the custom track and switched to **Roblox's default animation system** — leave the Jumping state enabled and trigger `humanoid:ChangeState(Jumping)` on each launch, so the default jump anim plays on launch and the default looping fall anim plays while airborne. Jump *behavior* (velocity-driven height = presses × base) unchanged.

---

## M2 — Content

From GDD §14 milestone table (+ §4.3 stomp).

- [~] **Stomp** — push-down half built (`src/server/Services/StompService.luau`: stronger LegPower knocks weaker players down). Full stomp + **double-jump reward** still to do (GDD §4.3 / Task #1).
- [ ] **Procedural tower generation** (server-side, replicated)
- [ ] **Section library** (prefab segments, difficulty-graded)
- [ ] **Themed zones** (grassland → caverns → industrial → sky → space)
- [ ] **Zone LegPower gating** (higher zones need more LegPower)
- [ ] **Checkpoints** (shared with the M1 death-zone item)

### 🐞 Bugs (M2)
- _(none yet)_

## M3 — Economy & Wings

- [ ] **Leap Coins sinks** (what coins buy)
- [ ] **Wing tiers** (basic = coins, premium = Robux; abilities)
- [ ] **Glide Charges** (consumable fuel; shares the M1 feather item)
- [ ] **Temporary boosts** (2× coins / charge, etc.)
- [ ] **MarketplaceService** (Robux products & game passes)

### 🐞 Bugs (M3)
- _(none yet)_

## M4 — Social & Retention

- [ ] **Leaderboards** (live server + global all-time height)
- [ ] **Ghost markers** (where top players / friends reached)
- [ ] **Daily quests**
- [ ] **Stomp PvP polish** (invuln frames, fairness, feedback FX)

### 🐞 Bugs (M4)
- _(none yet)_

## M5 — Launch

- [ ] **Robux monetization** (premium wings, jump-power upgrades)
- [ ] **Launch event**
- [ ] **Telemetry & iteration**

### 🐞 Bugs (M5)
- _(none yet)_
