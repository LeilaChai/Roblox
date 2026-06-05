# M1 (Validate) — Feature Checklist

Based on the GDD §14 MVP list, verified against the actual code in `src/`.
`[x]` = developed & in the game · `[ ]` = still to do for M1.

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

## Note — beyond M1

- **Stomp push-down (M2 feature)** is partially built already — `src/server/Services/StompService.luau` (stronger LegPower knocks weaker players down). The full stomp + double-jump design is tracked separately (GDD §4.3 / Task #1).
