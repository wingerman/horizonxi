# Agamotto (Tim Peterson)

Character ID not yet known. LuAshitacast loads from `<Name>_<Id>`, so on install this folder is
copied as `Agamotto_<Id>`; get the id from `/lac newlua` in game and pass it to the deploy script:

```bash
scripts/deploy.sh Agamotto /path/to/Game Agamotto_123456
```

Once known, rename this folder to the full name and drop the third argument.

## BLU.lua

Authored by Tim, received 2026-11-07. Reviewed against LuAshitacast 2.12 source; it is sound.

- Three accuracy tiers for engaged and physical blue magic, cycled with `/lac fwd acc`.
- `/lac fwd learn` locks Magus Jubbah and Bazubands during blue magic casts for spell learning.
- `/lac fwd breath` parks you in a max-HP idle set so breath spells snapshot high HP.
- `LockSafeGear()` re-asserts Warp Cudgel, Powder Boots, Reraise Earrings and Chariot Bands if
  you have manually equipped them, so swaps never knock them off. Nice pattern, worth copying.
- Town detection uses `string.match` on partial zone names ('Jeuno' matches all four Jeuno zones).

Things to know when editing it:

- Sets live in `profile.sets` (lowercase) with nested tables for `ws` and `blue_magic`. That works
  for table-based `gFunc.EquipSet`, but `/lac addset` and `/lac set <name>` need `profile.Sets`
  with flat sets, so this profile is edited by hand, not with addset.
- `precast = {}` is empty; there is no fast cast gear yet.
- `head = ''` in idle is a no-op (slot left as is), which is fine here.
- No `OnUnload` and no aliases, so nothing to clean up. Commands are typed as `/lac fwd <cmd>`;
  macros can wrap them.
