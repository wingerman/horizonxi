# GearSwap (Windower, retail) reference: STUB

Not yet exercised in this skill. Written from general knowledge of the addon; verify each point against
the GearSwap source (`Windower4/addons/GearSwap/`) and its `README.md` / `docs/` on the first retail
task, then replace this note with what was confirmed.

## Where things live

- Profiles: `Windower4\addons\GearSwap\data\<CharacterName>\<JOB>.lua`, or `data\<JOB>.lua` for all
  characters. Loaded automatically on job change.
- Mote libraries (`Mote-Include.lua`, `Mote-Mappings.lua`, `Mote-Utility.lua`) in `data\libs\` give a
  common structure (`sets.precast.FC`, `sets.midcast.Cure`, state toggles with `//gs c cycle`).

## Handlers

`get_sets()` (build `sets` tables), `precast(spell)`, `midcast(spell)`, `aftercast(spell)`,
`pet_midcast`, `pet_aftercast`, `status_change(new, old)`, `buff_change(name, gain)`,
`self_command(cmd)` (reached by `//gs c <cmd>`), `file_unload()`.

## Sets

Nested tables are normal: `sets.precast.WS['Savage Blade']`, `sets.midcast['Blue Magic']`.
`equip(set)` queues a set; `set_combine(base, overlay)` returns the merge (later wins per slot);
`empty` clears a slot; priorities via `{ name = 'Item', priority = 10 }`. Slot names are lowercase
(`main, sub, range, ammo, head, neck, ear1, ear2, body, hands, ring1, ring2, back, waist, legs, feet`).
`disable('main','sub')` locks slots.

## Commands for the loop

`//gs reload`, `//gs load <file>`, `//gs showswaps`, `//gs debugmode`, `//gs validate` (reports items
in sets that are not in inventory), `//gs export` (writes current gear as a set), `//gs c <cmd>`.

## What transfers from LuAshitacast work unchanged

Range/Ammo pairing, weapon swaps zeroing TP, precast-for-fast-casts, HP/MP priority ordering, the
base-plus-overlay composition, the data-driven ability table, on/off toggles, the verification
checklist, and short display names for items (GearSwap also accepts the long name, but the short name
is what inventory shows and what tools export).
