# FFXI rules that shape every gear-swap profile

Game and server behaviour, independent of addon. Sources are the LandSandBoat emulator (which HorizonXI
and most private servers rebase) and retail behaviour where it is known to match.

## Range and Ammo are one slot pair

`src/map/utils/charutils.cpp`, `EquipItem`, cases `SLOT_RANGED` and `SLOT_AMMO`: when the item being
equipped is a weapon and the item in the other slot is a weapon with a different skill type (or a
different sub-skill, except archery where long and short bows share arrows), the server unequips the
other slot. Both directions. `sql/item_weapon.sql` gives the skill types:

| Skill | Items | Legal partner |
|---|---|---|
| 25 Archery | bows (Rapid Bow, Lightning Bow, Hamayumi) | arrows (25) |
| 26 Marksmanship, sub 0 | crossbows (Zamburak, Thug's Zamburak, Velocity Bow, Othinus' Bow) | bolts (26, sub 0) |
| 26 Marksmanship, sub 1 | guns (Donderbuss) | bullets (26, sub 1) |
| 27 Throwing | chakrams, boomerangs, Rising Sun, Smart Grenade (Range slot) | shuriken (27, Ammo slot), pointless |
| 42 and other instrument skills | Gjallarhorn, harps, flutes | nothing |
| 0 None | stat ammo: Happy Egg, Fortune Egg, Tathlums, Hedgehog Bomb, Bomb Core, Fenrir's Stone, Tiphia Sting, Bibiki Seashell, Olibanum Sachet, Fire Bomblet | nothing |

Consequences: stat ammo needs an empty Range slot; a chakram or a stat crossbow needs an empty Ammo
slot or matching ammunition. A set that names one slot without the other inherits whatever was there
and the server resolves the conflict by unequipping, which the addon then undoes. Because Range is also
a TP-resetting slot (next section), the working pattern is: Range fixed for the whole profile by a toggle
outside the sets, Ammo chosen per set from stat ammo only. `scripts/check-profile.py` enforces both the
pairing and the one-Range rule; the Agamotto BLU_inv profile also checks at load in Lua (`CheckRanged`).

Also in the same function: Range and Ammo cannot change during a ranged attack, and Main, Sub, Range
and Ammo cannot change during a weaponskill.

## Weapon swaps zero TP, and Range is a weapon slot

Changing Main, Sub or Range resets TP to 0; Ammo does not. Source: `charutils.cpp`, `UnequipItem` (case
`SLOT_RANGED` sets `health.tp = 0` unless the outgoing item is an instrument or handbell; `SLOT_MAIN` and
`SLOT_SUB` always) and the block at the end of `EquipItem` that resets TP when `equipSlotID` is
`SLOT_MAIN`, `SLOT_RANGED` or `SLOT_SUB` and the new item is not an instrument. Retail behaves the same.
Spell sets therefore never touch any of the three; elemental staves and hMP staves are opt-in toggles with
the cost spelled out in the header, and a thrown weapon or bow in Range is a profile-wide choice, not a
per-set one. Found the hard way on 2026-11-08: Agamotto's v3 wore a chakram in TP/WS/physical sets and
stat ammo (Range empty) in magic, breath and idle sets, so every magical cast dumped TP.

## Stats are read when the action resolves

Spell damage, cure power and enfeeble resist checks use the caster's stats at cast completion, so the
midcast set is what counts. For casts of about half a second the midcast packet can arrive late; put
the real set on in precast for those. Breath damage reads current HP at completion, and HP+ gear
raises current HP, so a max-HP midcast set works for breath spells.

## HP and MP swaps need ordering

Equipping a piece that lowers max HP while current HP is near max costs HP that the later HP+ piece does
not refund; the opposite order on the way back has the same effect. Use the addon's priority mechanism
so HP+ goes on first and comes off last.

## Resting ticks

The first hMP tick comes about 20 s after sitting (Horizon shortens it); swapping to resting gear right
away gains nothing and costs the swap. Rag's convention: swap after the first tick lands.

## Slot names and bit order

Slots 0..15: Main, Sub, Range, Ammo, Head, Body, Hands, Legs, Feet, Neck, Waist, Ear1, Ear2, Ring1,
Ring2, Back. Item resources (Windower `items.lua`, Ashita resources) expose this as a bitmask in
`slots`. Both addons match items by the short display name (`en`), which is what the inventory shows.

## Level sync and level snapshots

Gear above the synced level is unequipped by the server. Profiles that are used while levelling keep
level-aware fallbacks (LuAshitacast `*_Priority` sets collapsed by `gFunc.EvaluateLevels`).

## Day and weather

Elemental obis and elemental staves depend on the spell's element matching day or weather. Read the
environment at midcast, not at load.

## Movement speed

Movement-speed items do not stack with each other; pick the one and leave the rest to Idle.

## Things that are server-specific and must be looked up

Whether gear attack affects a job's spells, how TP scales spells, which Dual Wield or Haste items were
moved or nerfed, which content is out of era, and every item's job list. For HorizonXI these are
recorded in wingerman-horizonxi `docs/` and in each profile header.
