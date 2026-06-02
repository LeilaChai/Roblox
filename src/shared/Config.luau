--!strict
-- Central tunables for Leap of Legends (M1 validate).
-- Everything lives here so balance can be tweaked in one place.

local Config = {}

-- ── Charged jump ────────────────────────────────────────────────
Config.BASE_JUMP_HEIGHT = 5         -- studs at (near) zero charge — low on purpose
Config.MAX_CHARGE_JUMP_HEIGHT = 18  -- studs at full charge, before LegPower scaling
Config.FULL_CHARGE_TIME = 0.8       -- seconds to reach a full charge
Config.MIN_CHARGE_FRACTION = 0.05   -- a quick tap still hops a little
Config.CHARGE_WALKSPEED_MULT = 0.3  -- slowed while charging (tradeoff)

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
