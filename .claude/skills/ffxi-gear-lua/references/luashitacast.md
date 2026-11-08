# LuAshitacast (Ashita v4) authoring reference

Upstream: https://github.com/ThornyFFXI/LuAshitacast. Full API docs as markdown live in the private
repo `horizonxi-luashitacast/docs/` (gfunc.md, gdata.md, gsettings.md, profile.md, commands.md,
tutorial.md). This file is the part you need while writing, plus the quirks the docs leave out.

## Where things live

- Addon code: `Game\addons\luashitacast\*.lua` (`equip.lua` and `func.lua` are the ones to read).
- Profiles: `Game\config\addons\luashitacast\<Name>_<Id>\<JOB>.lua`, loaded on job change.
  `settings.lua` beside them holds the addon's settings for that character.
- Shared code: `Game\config\addons\luashitacast\common\`, loaded with `gFunc.LoadFile('common\\x.lua')`.
- Backups of every `addset`: `backups/` next to the profile.

## Handlers a profile may define

| Handler | When | Typical content |
|---|---|---|
| `OnLoad` / `OnUnload` | profile load/unload, `/lac reload`, job change | `gSettings.AllowAddSet = true`, aliases, binds, macro book; delete every alias and bind in `OnUnload` |
| `HandleDefault` | continuously when not acting | idle / engaged / resting by `gData.GetPlayer().Status`; pet actions arrive here only, check `gData.GetPetAction()` first and `return` |
| `HandlePrecast` | before the spell packet | fast cast, or the full set for sub-second casts |
| `HandleMidcast` | after the packet | potency; `gData.GetAction()` gives Name, Skill, Element, CastTime (ms), MppAftercast |
| `HandleAbility` | job abilities, Blood Pacts, Ready | |
| `HandleWeaponskill` | weaponskills | `gData.GetAction().Name` |
| `HandleItem` | usable items | |
| `HandlePreshot` / `HandleMidshot` | ranged attacks | |
| `HandleCommand(args)` | anything typed as `/lac fwd <args>` | toggles; alias `/blu` to `/lac fwd` in OnLoad |

## API you will actually use

- `gFunc.EquipSet(setOrName)` merges a set into the pending buffer (later calls overwrite per slot).
  `gFunc.Equip(slot, item)` one slot. `gFunc.Combine(a, b)` returns a merged set.
- `gFunc.EvaluateLevels(sets, level)` collapses `*_Priority` sets (lists best-first) to the first
  entry at or below the level. `gFunc.SetMidDelay(ms)` + `gFunc.InterimEquipSet(set)` for a DT set
  during the cast before the potency set.
- `gFunc.Message(text)` prints to chat. `gFunc.LoadFile(path)` loads shared Lua.
- `gData.GetPlayer()` (Status, TP, HP, MP, MainJob, SubJob, MainJobSync), `gData.GetAction()`,
  `gData.GetPetAction()`, `gData.GetEnvironment()` (Area, DayElement, WeatherElement, Time),
  `gData.GetBuffCount(name)`, `gData.GetEquipment()` (per slot: Name, Container, Index).
- `gSettings`: `AllowAddSet`, `Debug`, `HorizonMode` (parse HandleDefault once per action instead of
  continuously), `EquipBags`.

## Slot values

| Value | Meaning |
|---|---|
| `'Item Name'` | equip that item (short display name, case-insensitive match) |
| `{ Name = 'Item', Priority = 10, AugPath = ..., AugRank = ..., AugTrial = ... }` | item with priority (higher first; `remove` defaults to -100) and augment match |
| `'remove'` | unequip the slot |
| `'displaced'` | another item in this set will empty this slot; do not fight it |
| `'ignore'` | leave the slot alone (same as not naming it) |
| `''` | does nothing at all; a trap, never what was meant |
| `{'A', 'B'}` | ignored unless the set name ends in `_Priority` |

Slot names are case-insensitive; `Ear1/Ear2`, `Ring1/Ring2`. Set keys accessed as `sets.Name` are
case-sensitive and a typo equips nothing silently; `gFunc.EquipSet('name')` by string is
case-insensitive.

## How the equip buffer behaves (equip.lua)

- `EquipSet` flags items already equipped and skips them, locates the rest in inventory bags, sends
  one equipset packet (0x51) for 9+ slots or single packets otherwise. A `remove` on an already empty
  slot is a no-op.
- `UnequipConflicts` only handles an item already worn in another slot. It does not know the server's
  Range/Ammo rule; see ffxi-invariants.md.
- Items worn by hand that are not in the set stay on. "Lockable" gear is therefore a profile-level table
  that re-asserts the item when `gData.GetEquipment()` shows it.

## `/lac addset` and the sets block

`/lac addset <Name>` writes the currently worn gear into the file by text replacement of the block
between `local sets = {` and its closing `}`. Keep that block flat (one level of PascalCase set names),
keep braces balanced, keep computed sets outside it with `NoWrite = true`. Mismatched braces can eat
the file; `AddSetBackups` keeps a copy. The game folder is the working copy after an addset and the repo
is the working copy after a hand edit; pull or deploy between them, never edit both.

## Commands for the verification loop

`/lac reload`, `/lac load <File>`, `/lac debug on|off` (every swap printed with the calling handler),
`/lac list gui` (browse sets), `/lac disable` (freeze swaps while dressing for addset), `/lac safecall`
(show real Lua errors instead of swallowing them), `/lac fwd <args>` (reach HandleCommand).

## Composition pattern used in the Agamotto BLU profiles

```lua
local Settings = { Acc = false, Learning = false, UseStaff = false, TpThreshold = 2000 }
local sets = { Idle = {...}, TP = {...}, TP_Acc = {...}, BluePhys = {...}, Mod_STR = {...}, ... }
local BlueMagic = { ['Disseverment'] = { kind = 'phys', mods = {'STR','DEX'}, hits = 5, tp = 'acc' }, ... }

local function EquipBlueMagic(spell)
    local info = BlueMagic[spell.Name]
    gFunc.EquipSet(sets.BluePhys)
    if info.hits >= 2 then gFunc.EquipSet(sets.BluePhys_MultiHit) end
    for _, stat in ipairs(info.mods) do gFunc.EquipSet(sets['Mod_' .. stat]) end
    if Settings.Acc then gFunc.EquipSet(sets.BluePhys_Acc) end
    LockSafeGear()
end
```

Load-time self-checks (Range/Ammo pairing) print through `gFunc.Message` from `OnLoad`, so a bad edit
is seen at `/lac reload`, not in a fight.

## Horizon notes

HorizonXI pre-installs Ashita v4 with LuAshitacast and the Sequencer plugin (fixes equip packet
ordering; leave it on). Horizon forbids automation that initiates actions; swapping gear on your own
actions is approved. Installed addon versions and known upstream fixes are logged in
`horizonxi-luashitacast/README.md`.
