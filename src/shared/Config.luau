--!strict
-- Central tunables for Leap of Legends (M1 validate).
-- Everything lives here so balance can be tweaked in one place.

local Config = {}

-- ── Continuous jump (hold Space to keep jumping, time-limited) ──
Config.JUMP_RISE_SPEED = 42           -- base upward speed (studs/s) while holding, at LegPower 0
Config.BASE_FALL_SPEED = 55           -- minimum fall speed (studs/s) at LegPower 0
Config.MAX_JUMP_TIME = 2.0            -- seconds of airborne jumping per burst (refills fully on landing)
Config.LEGPOWER_TICK_INTERVAL = 0.15 -- how often a held jump counts as a press for LegPower growth

-- ── LegPower (account-permanent, UNCAPPED) ──────────────────────
Config.LEGPOWER_PER_JUMP = 1
-- Higher LegPower => faster jumping AND falling (and thus higher reach). Uncapped.
-- 0.0005 => +50% jump/fall speed at 1000 presses.
Config.LEGPOWER_SPEED_BONUS_PER_PRESS = 0.0005

-- Visual leg/body girth growth (soft-capped so avatars stay sane).
Config.GIRTH_PER_PRESS = 0.00015
Config.GIRTH_MAX_SCALE = 2.6

-- ── Charge Bonus (run-scoped loop reward — wired in a later milestone) ──
Config.CHARGE_BONUS_PER_LOOP = 0.05
Config.CHARGE_BONUS_CAP = 0.50

-- ── Economy ─────────────────────────────────────────────────────
Config.COINS_PER_STUD = 1           -- Leap Coins earned per new stud of height

-- ── Persistence ─────────────────────────────────────────────────
Config.DATASTORE_NAME = "LeapProfiles_v1"

return Config
