# Researching gear and formulas for a server

## Why the order matters

A private server is a rebase of an emulator with its own balance patches. Retail wikis describe retail;
the server's item database describes the server. The emulator's source describes the formulas unless
the server patched them, and the server's own primers say where it did. Two wrong turns from the first
HorizonXI BLU pass, both caused by skipping a step: Mirage relic was ruled "no Horizon drop" from a
retail-era assumption and the player owned three pieces; a chakram and a stat egg were put in one set
because nobody read the equip rules in `charutils.cpp`.

## For a LandSandBoat-based server (HorizonXI, most private servers)

Repository: https://github.com/LandSandBoat/server. Fetch raw files with
`https://raw.githubusercontent.com/LandSandBoat/server/base/<path>`; list directories with the GitHub
contents API `https://api.github.com/repos/LandSandBoat/server/contents/<path>`.

| Question | Where |
|---|---|
| Spell damage, modifiers, hit counts, TP behaviour | `scripts/globals/<school>.lua` (e.g. `bluemagic.lua`) and `scripts/actions/spells/<school>/<spell>.lua` |
| Weaponskill modifiers | `scripts/globals/weaponskills.lua`, `scripts/actions/weaponskills/` |
| Item stats, jobs, levels, slots | `sql/item_basic.sql`, `sql/item_equipment.sql`, `sql/item_mods.sql`, `sql/item_weapon.sql` (skill and sub-skill types) |
| Equip rules (Range/Ammo, weapon locks during WS) | `src/map/utils/charutils.cpp`, `EquipItem` |
| Status effects, buff names | `scripts/globals/status.lua`, `sql/status_effects.sql` |

The server's fork may differ from base; when the server publishes a primer or patch notes (Horizon:
the BLU Primer, patch notes on horizonxi.com), those override base.

Note on filenames: LSB generates script names from spell names with abbreviations and punctuation
dropped (`quad_continuum.lua`, `self-destruct.lua`). Spells the server added itself (Horizon: Vanity
Dive, Everyone's Grudge) are absent from base; mark them as guessed in the ability table.

## Item availability and stats on HorizonXI

- https://horizonffxi.wiki/<Item_Name> is the item source of truth: stats after Horizon's changes,
  job list, drop or craft source, and an "Out of Era" tag for content Horizon has not released.
  The site returns an empty body to plain `curl`; use the WebFetch tool per page, and do not spoof a
  browser user agent to get around it.
- https://horizonxi.com/items is the in-game item database view.
- Horizon's "Out of Era" list (Assault, Nyzul, Salvage, ISNM, ZNM, Besieged, Group 2 merits, Mythics
  as of late 2026) removes whole gear families; check the tag before planning around an item.
- Verified tables with URLs live in wingerman-horizonxi `docs/gear-research/<job>-<level>/`. Add a row
  there rather than re-verifying in the next session.

## For retail (GearSwap)

No server source. Use https://www.bg-wiki.com for item stats and testing pages, FFXIAH for
availability and price, and the Windower resources (`items.lua`, `spells.lua`) for the names and
IDs the addon matches on. Mark anything taken from community testing as such.

## Recording a result

Every ruled-out item gets a reason and a URL. Every chosen item gets the stat it is there for, in a
comment next to it in the profile. Every research pass gets a table (item, level, slot, jobs, stats,
source, URL) in the repo's docs so the next pass starts from it.
