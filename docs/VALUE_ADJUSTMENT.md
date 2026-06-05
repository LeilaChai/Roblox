# Value Adjustment Checklist

Tracks tunable values (mostly in `src/shared/Config.luau`) that are currently set
to a **temporary playtest value** and need to be adjusted later — usually tuned
back to a final/intended value once a mechanic is confirmed.

Check an item off (`[x]`) once it's been set to its intended value.

> **Rule:** Whenever a value is changed for playtest purposes, **ask Leila for
> permission before adding it to this checklist.**

## To do

- [ ] **`BASE_JUMP_HEIGHT`** — `src/shared/Config.luau`
  - Current (test): **25** — temporary high value so jump-height growth is obvious while testing (press 1 → 25 studs, press 2 → 50, press 3 → 75 …).
  - Intended: **~5** (below Roblox's 7.2 default). Tune back down once scaling is confirmed.

## Done

_(none yet)_
