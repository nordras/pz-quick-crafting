# Quick Crafting

A Project Zomboid mod for **Build 42**. Scales down how long crafting takes.

Profession recipes in Build 42 can eat minutes of real time. This mod runs hand crafting at a percentage of its normal duration: at the default 10%, a 40 second recipe takes 4 seconds.

Recipes keep their **relative** cost. A quick recipe stays quicker than an elaborate one, which is the point of scaling rather than clamping everything to the same value.

---

## Options

Under **Sandbox Options → Quick Crafting**:

| Option | Default | Effect |
|---|---|---|
| Scale crafting duration | on | Enables the mod |
| Crafting time (% of normal) | `10` | Range `1`–`100`. At `10`, crafting takes a tenth of the time. At `100`, nothing changes |
| Hard ceiling (seconds, 0 = none) | `0` | Optional limit applied *after* the scaling |

The percentage is the main control. The ceiling is there for admins who want very long recipes reined in regardless of proportion — for instance 25% scaling with a 10 second ceiling keeps short recipes feeling different from long ones, while guaranteeing nothing ever drags.

---

## Scope

**Only hand crafting is affected.** Reading, foraging, digging, sawing and medical actions keep their vanilla timings.

This is deliberate. Every timed action runs its duration through `adjustMaxTime()`, so patching that method on the base class would have rescaled the entire game. Instead the override lives on `ISCraftAction` alone.

---

## How it works

`ISBaseTimedAction:create()` finalises an action's duration like this:

```lua
self.maxTime = self:adjustMaxTime(self.maxTime)
```

The call goes through `self`, so defining `adjustMaxTime` on `ISCraftAction` overrides it for crafting and leaves every other action untouched.

### Why the scaling goes here and not in `getDuration()`

`adjustMaxTime` is where the base game multiplies a duration for unhappiness, drunkenness and pain. Scaling the value *before* those multipliers would let a miserable, injured character undo most of the reduction. Applying it last makes the result final.

### Units

Durations are counted in ticks. The base game puts the conversion at 10 ms per tick (`TICKS_TO_MILLIS` in `ISDryMyself.lua`), which makes **100 ticks roughly one second**. The percentage needs no conversion; the optional ceiling is expressed in seconds because that is what an admin wants to reason about.

The game's own definition of instant is `maxTime = 1`, returned by `isTimedActionInstant()` in about two dozen places, so the result never drops below that.

### Known limitation

Craft benches and processors — forges, kilns and similar Build 42 stations — are **not affected**.

Those run their progress through `CraftLogic` in Java, which Lua cannot reach: `CraftRecipe` exposes `getTime()` but no setter, `CraftLogic` has no speed control, and the method that lists in-progress crafts is package-private. `ISCraftAnimAction:getDuration()` returns `-1` precisely because those actions have no fixed Lua duration.

Most profession crafting in Build 42 goes through the hand crafting path and is covered.

---

## Languages

English, Português (BR and PT), Español (ES, MX, CL).

Translations live in `Contents/mods/QuickCrafting/42/media/lua/shared/Translate/<CODE>/Sandbox.json`. Pull requests adding a language are welcome; copy the `EN` file and keep the same seven keys.

---

## Install

**Steam Workshop** — subscribe, then enable *Quick Crafting* in the Mods menu.

**Manually** — copy `Contents/mods/QuickCrafting` into `%USERPROFILE%/Zomboid/mods/`, then enable it in the Mods menu.

Safe to add to or remove from an existing save.

---

## Compatibility

Built for **Build 42.20**. Tested in singleplayer; multiplayer should work but has not been verified.

The override chains to whatever `adjustMaxTime` was already resolving to, so a mod that customised crafting duration before this one still runs. Two mods that both replace `ISCraftAction.adjustMaxTime` outright would conflict, as usual.

---

## Licence

MIT — see [LICENSE](LICENSE).
