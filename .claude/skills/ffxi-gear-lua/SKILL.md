---
name: ffxi-gear-lua
description: Author, review, fix or optimize Final Fantasy XI gear-swap profiles - LuAshitacast (Ashita v4, HorizonXI and other private servers) and GearSwap (Windower, retail) - including per-spell or per-ability gear sets, idle/TP/weaponskill/precast/midcast sets, toggles, and the research into what gear exists and what the server's formulas reward. Use this whenever the user mentions a .lua gear profile, LuAshitacast, lac, GearSwap, gs, Ashita, Windower, HorizonXI, "gear sets", "swap sets", "best in slot for <job>", a FindAll inventory export, or wants to know what gear to wear for a job on a 75-era server, even when they do not say "lua".
---

# FFXI gear-swap profiles

A gear-swap profile is a Lua file the client addon runs: on each action it composes a set and sends
equip packets. The addon API differs between LuAshitacast and GearSwap, but the game rules, the
design moves and the ways a profile silently fails are the same. This skill carries the method; the
server- and character-specific facts live in the repo that owns them.

Worked example to read before building anything: `luashitacast/Agamotto_112818/BLU_inv.lua` in
wingerman-horizonxi, with its README and `docs/gear-research/blu-75/`. It shows every pattern below.

## 1. Identify the platform first

Ask or infer three things, because they change the API, the item stats and the formulas:

| | LuAshitacast | GearSwap |
|---|---|---|
| Client / addon | Ashita v4, `/lac` | Windower, `//gs` |
| Servers | HorizonXI and other private servers | retail |
| Profile location | `Game\config\addons\luashitacast\<Name>_<Id>\<JOB>.lua` | `Windower4\addons\GearSwap\data\<Name>\<JOB>.lua` |
| Reference | `references/luashitacast.md` | `references/gearswap.md` |

A private server is a rebase of an open-source emulator with its own tuning. Item stats, job
lists, drop sources and even formulas differ from retail. Read `references/research.md` before
trusting any wiki.

## 2. Source-of-truth order

1. The addon's own source, for what a slot value means and when handlers fire. Docs omit the
   quirks that bite (`''` is a no-op in LuAshitacast, lists are ignored, `addset` rewrites by text).
2. The server's source, for formulas. HorizonXI runs on LandSandBoat: `scripts/globals/*.lua`
   holds the damage formulas, `sql/item_*.sql` the item data, `src/map/utils/charutils.cpp` the
   equip rules. Retail has no source; use BG-Wiki testing pages and in-game tests.
3. The server's own wiki or item database, for item stats, job lists and availability.
4. Retail wikis last, and only for things the server has not touched.

When two sources disagree, the lower-numbered one wins. When research rules an item out, record
the reason and the URL; a player's inventory later proving it wrong is cheap to fix if the reason
is written down (the Mirage relic lesson in the Agamotto README).

## 3. Design moves that hold across addons

- **Base set plus overlays.** One base per situation (Idle, TP, WS, physical spell, magical
  spell), then small overlays laid on top in a fixed order: multi-hit, stat modifier, crit,
  accuracy, TP or buff state. Last write wins per slot. A new spell needs a table row, not a set.
- **Data-driven ability table.** Classify each spell or ability once (kind, stat modifiers, hit
  count, what TP changes) and compose from that. Derive the table from the server's scripts.
- **Toggles are on/off.** Players will not cycle three accuracy tiers mid-fight. One `acc`
  toggle, one `learn` lock, one idle mode. Expose a `status` command that prints them.
- **Spell sets never change Main or Sub.** A weapon swap zeroes TP. Elemental staves are wired
  but off by default, opt-in by toggle.
- **Range and Ammo are one decision.** The server empties one when the other's skill type differs,
  and the addon re-equips it: endless flicker. Every set that names either names both, the other
  `'remove'`. Validate at load time. Details and the legal pairs: `references/ffxi-invariants.md`.
- **Sub-second casts go on in precast.** The server reads stats at completion; a midcast packet
  sent after a 0.5 s spell can miss.
- **Max-HP and max-MP swaps need priority ordering** so the HP+ piece is not equipped after the
  piece that lowers HP (and vice versa on the way back).
- **Resting gear waits** for the first tick in normal gear, then swaps.
- **Lockable safe gear is a table**, not a special case per item: warp rings, reraise, exp bands
  stay on if the player put them on by hand.
- **Item names are the inventory display names**, abbreviations included (`Scp. Harness +1`).
  Get them from a FindAll export or the Windower item resource, not from a wiki title.

## 4. Build

Start from `luashitacast/_template/TEMPLATE.lua` (LuAshitacast) or the GearSwap reference. Keep the
header honest: what the file assumes, what is unverified, which server quirks it encodes, and the
command list. Comment every non-obvious item with the stat it brings. Fill sets from a verified
inventory when one exists:

```bash
python3 scripts/parse-findall.py <Name_Id.bin> --items items.lua --job BLU --md inventory.md
```

(`items.lua` is `resources_data/items.lua` from github.com/Windower/Resources.) Keep the owned-gear
file and the best-in-slot file separate; the gap between them is the farming list.

## 5. Validate before deploy

```bash
python3 scripts/check-profile.py path/to/JOB.lua
```

Balanced braces and blocks, every `sets.X` reference defined, Range/Ammo pairing, slot names,
duplicate slots, `''` no-ops, lists outside priority sets. Exit 1 means do not deploy. Then read
the diff once more as the player would: does each overlay still make sense on top of its base?

## 6. Deploy and verify in game

Deploy with the repo's script, `/lac reload` (or `//gs reload`), then the checklist with
`/lac debug on` (`//gs showswaps`):

1. Load message is clean and the pairing check prints OK.
2. Idle, engage, rest: the right sets land and nothing flickers for ten seconds.
3. One cast of each kind in the ability table; confirm the overlay order in the log.
4. One weaponskill, one ability, one item use.
5. Toggle every command and read `status`.

Anything the author cannot test (another player's character) goes in the README as an open item
for that player, phrased as what to watch for.

## 7. Document

Per-character README: which file to load, what changed and why, sources table with URLs, items
ruled out and the reason, open items. A `docs/gear-research/<job>-<level>/` table per research
pass with an URL column. The profile header repeats the rules that bite, so the next editor who
only opens the lua still sees them.

## What does not belong here

Server item customizations, formula tables, per-character gear calls and inventories are facts
about one server or one player. They live in the repo that owns them (for HorizonXI,
wingerman-horizonxi `docs/`), and this skill points at them. Add to this skill only what would be
true on the next server and the next addon too.
