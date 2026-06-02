--!strict
-- Central tunables for Leap of Legends (M1 validate).
-- Everything lives here so balance can be tweaked in one place.

local Config = {}

-- ── Continuous jump (hold Space to keep jumping, time-limited) ──
-- JUMP HEIGHT: how high a single jump lifts you above the platform you left.
-- Starts LOWER than Roblox's default (~7.2) and grows with LegPower. You rise to
-- this height fast, then HOVER there (steering) until your jump time runs out.
Config.BASE_JUMP_HEIGHT = 6                   -- studs above launch platform at LegPower 0 (< 7.2 default)
Config.LEGPOWER_HEIGHT_BONUS_PER_PRESS = 0.002 -- +200% jump height at 1000 presses

-- SPEED: how fast you rise to your jump height and how fast you fall. Both scale
-- hard with LegPower, so the higher you can jump, the faster you reach/leave it.
Config.JUMP_RISE_SPEED = 120          -- base upward speed (studs/s) at LegPower 0 (snappy)
Config.BASE_FALL_SPEED = 90           -- base fall speed (studs/s) at LegPower 0
Config.LEGPOWER_SPEED_BONUS_PER_PRESS = 0.004 -- +100% speed @250 presses, +400% @1000
Config.MAX_VERTICAL_SPEED = 240       -- safety clamp so very high LegPower can't tunnel through platforms

Config.AIR_MOVE_SPEED = 18            -- horizontal speed while airborne (steer mid-jump / hover)
Config.MAX_JUMP_TIME = 2.0            -- seconds you can stay airborne per burst (refills on landing)
Config.LEGPOWER_TICK_INTERVAL = 0.15 -- how often holding counts as a press for LegPower growth
Config.JUMP_BAR_DRAIN_RATE = 1.2     -- max speed the jump-power bar may visually drain (fraction/s); lower = slower

-- ── LegPower (account-permanent, UNCAPPED) ──────────────────────
Config.LEGPOWER_PER_JUMP = 1

-- Visual leg/body girth by tier. Applied only when the tier changes (never
-- every frame) so the avatar doesn't re-fit its rig and jitter.
Config.LEGPOWER_TIER_PRESSES = { 0, 250, 1000, 4000, 15000 }
Config.LEGPOWER_TIER_GIRTH = { 1.0, 1.2, 1.4, 1.6, 1.8 }

-- ── Charge Bonus (run-scoped loop reward — wired in a later milestone) ──
Config.CHARGE_BONUS_PER_LOOP = 0.05
Config.CHARGE_BONUS_CAP = 0.50

-- ── Economy ─────────────────────────────────────────────────────
Config.COINS_PER_STUD = 1           -- Leap Coins earned per new stud of height

-- ── Persistence ─────────────────────────────────────────────────
Config.DATASTORE_NAME = "LeapProfiles_v1"

return Config
