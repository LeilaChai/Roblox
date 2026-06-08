--!strict
-- Central tunables for Leap of Legends (M1 validate).
-- Everything lives here so balance can be tweaked in one place.

local Config = {}

-- ── Jump ─────────────────────────────────────────────────────────
-- JUMP HEIGHT = (number of jumps / LegPower) × BASE_JUMP_HEIGHT.
-- Each spacebar press adds BASE_JUMP_HEIGHT studs. The first jump is exactly
-- BASE_JUMP_HEIGHT (below Roblox's ~7.2 default).
Config.BASE_JUMP_HEIGHT = 5                   -- studs added per jump (also the first jump's height; < 7.2 default)

-- SPEED: how fast you rise to your jump height and how fast you fall. Both scale
-- hard with LegPower, so the higher you can jump, the faster you reach/leave it.
Config.JUMP_RISE_SPEED = 120          -- base upward speed (studs/s) at LegPower 0 (snappy)
Config.BASE_FALL_SPEED = 90           -- base fall speed (studs/s) at LegPower 0
Config.LEGPOWER_SPEED_BONUS_PER_PRESS = 0.004 -- +100% speed @250 presses, +400% @1000
Config.MAX_VERTICAL_SPEED = 240       -- safety clamp so very high LegPower can't tunnel through platforms

Config.AIR_MOVE_SPEED = 18            -- horizontal speed while airborne (steer mid-jump)
Config.MAX_JUMP_TIME = 25             -- safety cap on a single jump's rise time (lets very tall jumps finish)
Config.JUMP_BAR_DRAIN_RATE = 1.2     -- max speed the jump-power bar may visually drain (fraction/s); lower = slower

-- ── LegPower (account-permanent, UNCAPPED) ──────────────────────
Config.LEGPOWER_PER_JUMP = 1

-- Visual leg/body girth grows with LegPower (number of jumps): more presses =
-- thicker legs, same idea as jump height. Re-applied only when it moves by
-- GIRTH_UPDATE_STEP so the rig doesn't re-fit every frame and jitter.
Config.GIRTH_PER_PRESS = 0.02   -- body width/depth added per jump
Config.GIRTH_MAX_SCALE = 3.0    -- cap so the avatar doesn't get absurd
Config.GIRTH_UPDATE_STEP = 0.1  -- only re-apply the scale after it changes this much

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
