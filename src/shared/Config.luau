--!strict
-- Central tunables for Leap of Legends (M1 validate).
-- Everything lives here so balance can be tweaked in one place.

local Config = {}

-- ── Continuous jump (hold Space to keep jumping, time-limited) ──
Config.JUMP_APEX_HEIGHT = 9          -- studs per hop, before LegPower scaling
Config.MAX_JUMP_TIME = 2.0           -- seconds of continuous jumping per burst
Config.JUMP_TIME_RECHARGE_RATE = 1.5 -- jump-seconds restored per grounded second
Config.HOP_REJUMP_VELOCITY = 0.5     -- re-hop once upward velocity drops below this

-- ── LegPower (account-permanent, UNCAPPED jump bonus) ───────────
Config.LEGPOWER_PER_JUMP = 1
-- Jump-height bonus per accumulated press. 0.0006 => ~+60% at 1000 presses.
Config.LEGPOWER_JUMP_BONUS_PER_PRESS = 0.0006

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
