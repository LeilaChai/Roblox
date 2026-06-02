--!strict
-- Central tunables for Leap of Legends (M1 validate).
-- Everything lives here so balance can be tweaked in one place.

local Config = {}

-- ── Continuous jump (hold Space to keep jumping, time-limited) ──
Config.JUMP_RISE_SPEED = 90           -- base upward speed (studs/s) while holding, at LegPower 0
Config.BASE_FALL_SPEED = 110          -- base minimum fall speed (studs/s) at LegPower 0 (heavier than rise)
Config.MAX_VERTICAL_SPEED = 240       -- safety clamp so very high LegPower can't tunnel through platforms
Config.AIR_MOVE_SPEED = 16            -- horizontal speed while airborne (lets you steer mid-jump)
Config.MAX_JUMP_TIME = 2.0            -- seconds of airborne jumping per burst (refills fully on landing)
Config.LEGPOWER_TICK_INTERVAL = 0.15 -- how often a held jump counts as a press for LegPower growth

-- ── LegPower (account-permanent, UNCAPPED) ──────────────────────
Config.LEGPOWER_PER_JUMP = 1
-- Higher LegPower => DRAMATICALLY faster jumping AND falling (and thus higher reach). Uncapped.
-- 0.0015 => +150% jump/fall speed at 1000 presses (then clamped by MAX_VERTICAL_SPEED).
Config.LEGPOWER_SPEED_BONUS_PER_PRESS = 0.0015

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
