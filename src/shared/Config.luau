--!strict
-- Central tunables for Leap of Legends (M1 validate).
-- Everything lives here so balance can be tweaked in one place.

local Config = {}

-- ── Continuous jump (hold Space to keep jumping, time-limited) ──
-- JUMP HEIGHT (initial): a fresh jump rises exactly this high above the platform
-- you left. Below Roblox's ~7.2 default. The jump TIME below is DERIVED from this
-- so the starting jump is limited to exactly this height.
Config.BASE_JUMP_HEIGHT = 5          -- studs above launch platform at LegPower 0 (< 7.2 default)

-- JUMP TIME governs the jump: the rise lasts this long. The initial time is
-- derived to match BASE_JUMP_HEIGHT, and it GROWS with LegPower, so the more you
-- press the LONGER (and higher) each jump — capped by MAX_JUMP_TIME.
Config.LEGPOWER_JUMPTIME_BONUS_PER_PRESS = 0.01 -- +1000% jump time at 1000 presses (before the cap)
Config.MAX_JUMP_TIME = 1.5           -- cap on how long a single jump's rise may last

-- SPEED: how fast you rise and fall. Scales with LegPower (this rise-speed growth
-- is on top of the jump-time growth above).
Config.JUMP_RISE_SPEED = 120          -- base upward speed (studs/s) at LegPower 0 (snappy)
Config.BASE_FALL_SPEED = 90           -- base fall speed (studs/s) at LegPower 0
Config.LEGPOWER_SPEED_BONUS_PER_PRESS = 0.004 -- +100% speed @250 presses, +400% @1000
Config.MAX_VERTICAL_SPEED = 240       -- safety clamp so very high LegPower can't tunnel through platforms

Config.AIR_MOVE_SPEED = 18            -- horizontal speed while airborne (steer mid-jump)
Config.LEGPOWER_TICK_INTERVAL = 0.15  -- how often holding counts as a press for LegPower growth
Config.JUMP_BAR_DRAIN_RATE = 1.2      -- max speed the jump-power bar may visually drain (fraction/s); lower = slower

-- ── LegPower (account-permanent, UNCAPPED) ──────────────────────
Config.LEGPOWER_PER_JUMP = 1

-- Visual leg/body girth by tier. Applied only when the tier changes (never
-- every frame) so the avatar doesn't re-fit its rig and jitter.
Config.LEGPOWER_TIER_PRESSES = { 0, 250, 1000, 4000, 15000 }
Config.LEGPOWER_TIER_GIRTH = { 1.0, 1.2, 1.4, 1.6, 1.8 }

-- ── Charge Bonus (run-scoped loop reward — wired in a later milestone) ──
Config.CHARGE_BONUS_PER_LOOP = 0.05
Config.CHARGE_BONUS_CAP = 0.50

-- ── Stomp (M2): step on a weaker-legged player to push them down ──
Config.STOMP_CHECK_INTERVAL = 0.1   -- server check cadence (seconds)
Config.STOMP_RADIUS = 3.5           -- horizontal distance (studs) to count as "on top of" them
Config.STOMP_MIN_DY = 1.5           -- stomper must be at least this far above the victim
Config.STOMP_MAX_DY = 6             -- ...and at most this far above
Config.STOMP_PUSH_SPEED = 130       -- downward speed applied to the stomped victim
Config.STOMP_STUN = 0.6             -- seconds the victim is knocked down (can't jump)
Config.STOMP_COOLDOWN = 1.0         -- per-victim cooldown so it can't retrigger every frame

-- ── Economy ─────────────────────────────────────────────────────
Config.COINS_PER_STUD = 1           -- Leap Coins earned per new stud of height

-- ── Persistence ─────────────────────────────────────────────────
Config.DATASTORE_NAME = "LeapProfiles_v1"

return Config
