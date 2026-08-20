-- Quick Crafting :: scale how long a crafting action takes.
--
-- Durations are scaled proportionally rather than clamped to a fixed value, so
-- the relative cost of recipes survives: at 10%, a 40 second recipe becomes 4
-- seconds while a 4 second one becomes 0.4. A flat ceiling would have made
-- both finish at the same moment and flattened that distinction away.
--
-- Every timed action runs its duration through adjustMaxTime() inside
-- ISBaseTimedAction:create(). That call is made through self, so overriding the
-- method on ISCraftAction alone affects crafting and nothing else - reading,
-- foraging, digging and medical actions keep their vanilla timings.
--
-- Scaling here rather than in getDuration() matters: adjustMaxTime is where the
-- game multiplies the duration for unhappiness, drunkenness and pain. Scaling
-- before those multipliers would let a miserable character undo the reduction,
-- so this runs last and the result is final.

require "TimedActions/ISCraftAction"

if not ISCraftAction then
    print("[QuickCrafting] ISCraftAction not found - mod inactive.")
    return
end

-- Timed action durations are counted in ticks. The base game puts the
-- conversion at 10 ms per tick (TICKS_TO_MILLIS in ISDryMyself), which makes
-- 100 ticks roughly one second. Sandbox options are expressed in seconds
-- because that is what a server admin actually wants to reason about.
local TICKS_PER_SECOND = 100

-- The game's own convention for "instant", used by isTimedActionInstant().
local INSTANT = 1

local function scale(duration)
    local sv = SandboxVars.QuickCrafting
    if not sv or not sv.Enabled then return duration end

    -- A negative duration means "no fixed length"; leave it alone.
    if duration < 0 then return duration end

    -- Already instant, or shorter than instant: nothing worth scaling.
    if duration <= INSTANT then return duration end

    local percent = sv.TimePercent or 10
    local scaled = duration * (percent / 100)

    -- Optional ceiling on top of the scale, for admins who want long recipes
    -- reined in regardless of proportion. Zero disables it.
    local capSeconds = sv.MaxSeconds or 0
    if capSeconds > 0 then
        local capTicks = capSeconds * TICKS_PER_SECOND
        if scaled > capTicks then scaled = capTicks end
    end

    -- Never go below the value the game itself treats as instant.
    if scaled < INSTANT then scaled = INSTANT end

    return scaled
end

-- Resolve through the metatable chain rather than naming ISBaseTimedAction
-- directly, so a mod that already customised this for crafting still runs.
local previousAdjustMaxTime = ISCraftAction.adjustMaxTime

function ISCraftAction:adjustMaxTime(maxTime)
    return scale(previousAdjustMaxTime(self, maxTime))
end

print("[QuickCrafting] crafting duration scaling active")
