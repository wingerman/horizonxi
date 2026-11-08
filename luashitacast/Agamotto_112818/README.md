# Agamotto_112818 (Tim Peterson)

Character id 112818, read from Tim's FindAll cache export on 2026-11-07. Deploy with:

```bash
scripts/deploy.sh Agamotto_112818 /path/to/Game
```

Three profiles live here:

- `BLU.lua`: Tim's gear as he had it in v1, with the v2 per-spell composition logic. The everyday file.
- `BLU_bis.lua`: the same logic filled with the best in-era gear on Horizon, whether or not Tim owns it. A shopping list.
- `BLU_inv.lua`: the same logic filled only from gear Tim actually owns, per `inventory-2026-11-07.md`. Load this one first.

## v3 (2026-11-07, after Tim's first play test)

Two changes, applied to all three files:

- **Range and Ammo are decided together.** Tim saw the chakram and the Happy Egg flickering: the server
  (LandSandBoat `charutils.cpp`, `EquipItem`) empties the other slot whenever a Range or Ammo item's skill type
  differs from what is there. Bows take only arrows, crossbows only bolts, guns only bullets, and stat ammo
  (eggs, Tathlums, Hedgehog Bomb, Bomb Core, Tiphia Sting) has no skill at all, so it cannot sit beside any
  ranged weapon, chakram or stat crossbow included. LuAshitacast only re-equips what it finds missing, so the
  two items swap each other out forever. Rule now: a set that names Range or Ammo names both, the other one
  `'remove'` unless the pair is legal. Idle, Resting and MaxHP wear an egg with Range empty; TP, WS and BluePhys
  wear the chakram with Ammo empty; INT and magic sets wear the Tathlum with Range empty. A `RangedKind`
  table classifies the items and `CheckRangedPairs()` runs on load (and on `/blu ranged`), printing every set
  that breaks the rule, so a bad `/lac addset` is caught at load rather than in a fight.
- **Accuracy is on or off.** The Low / Med / High cycle (and the Low "attack" variant) is gone. `/blu acc`
  toggles `Settings.Acc`; when on, `TP_Acc`, `WS_Acc`, `BluePhys_Acc` and `BlueMag_Acc` lay over their bases.
  Fewer items to cycle through, and the status line reads `acc=true/false`.

## BLU.lua (v2, 2026-11-07)

Tim's v1 (git history, first commit) had three accuracy tiers, a learning lock, a breath max-HP idle mode and
a safe-gear lock. v2 keeps all of that and adds per-spell gear composition, built on Rag's layering idea and
on reading the server formulas. Deploy, then `/lac debug on` and cast a few things to watch the layers land.

What changed and why:

- **Every blue spell is classified** in a `BlueMagic` table (kind, stat modifiers, hit count, TP behaviour,
  dStat), parsed from the LandSandBoat spell scripts HorizonXI runs on. Full table in
  [docs/blue-magic-75.md](../../docs/blue-magic-75.md).
- **Physical spells compose** `BluePhys` + `BluePhys_MultiHit` (2+ hits) + `Mod_STR`/`Mod_DEX`/... per the
  spell's modifiers + `BluePhys_Crit` + `BluePhys_Acc` when `/blu acc` is on + `BluePhys_TP` when TP is high or Chain Affinity is up. Fill the
  `Mod_*` overlays with a piece or two each and every spell gets the right stat without its own set.
- **Physical set goes on in precast.** Physical blue magic casts in 0.5 s and the server reads stats at
  completion; a midcast swap sent after the spell packet can miss. Toggle with `/blu fastphys` if it misbehaves.
- **Breath spells swap to max HP midcast.** The server reads current HP when the cast completes, and HP+ gear
  raises current HP, so the `MaxHP` set is applied on cast. The `/blu breath` idle mode remains for people who
  like standing in it. Note the `MaxHP` set names a Head while Idle wears Vermillion Cloak, which displaces
  head; give `MaxHP` a Body too or the Keffiyeh will not go on.
- **Magical spells split by dStat**: INT for most, CHR for Eyes On Me and Mysterious Light, MND for Mind Blast
  and Magic Hammer. Burst Affinity up adds `BlueMag_MB`. `/blu acc` on adds `BlueMag_Acc`.
- **Magus Jubbah is in the physical base set.** Blue Magic skill feeds both the base D and the base attack of
  every physical spell in the server formula. Scp. Harness +1 is the alternative in `BluePhys_Acc`.
- **Elemental staves and obis** are wired for magical, breath, drain, enfeeble and cure casts. Staves are off
  by default (`/blu staff`) because swapping main hand dumps TP. Comment out staves you do not own.
- **Skill-scaling buffs** (Diamondhide, Metallic Body, Occultation) get `BlueSkill`.
- **Resting gear waits 16 s** so the first regen tick lands in normal gear, a Rag convention.
- **Safe gear is table driven** (`LockableGear`): Warp Cudgel, reraise pieces, exp bands, Shaded Specs.,
  Goldsmith's Apron and Powder Boots stay on if you put them on by hand.
- Sets are now flat under `local sets = {` and PascalCase, so `/lac addset <Name>` and `/lac set <Name>` work.

Commands: `/blu acc`, `/blu ranged`, `/blu learn`, `/blu breath`, `/blu staff`, `/blu fastphys`, `/blu tp <n>`, `/blu status`
(`/blu` is an alias for `/lac fwd`).

Open items for Tim:

- Fill the `Mod_*`, `BluePhys_Crit`, `BlueMag_CHR`, `BlueMag_Acc`, `BlueMag_MB`, `BlueBreath` and `Precast`
  overlays. Candidates are commented next to each; check stats on https://horizonxi.com/items.
- Vanity Dive (Horizon lv 28) is not in the LandSandBoat base scripts, so it is guessed as a single-hit STR
  spell. Everyone's Grudge is absent for the same reason.
- Confirm the 0.5 s precast behaviour with `/lac debug on`. If the physical set shows in the log before the
  spell packet and the damage looks right, leave `fastphys` on.

## BLU_bis.lua (target gear edition, 2026-11-07)

Same code as BLU.lua with every set filled with the best gear a BLU can actually obtain on HorizonXI right
now. About 300 item pages on horizonffxi.wiki were checked for stats, job list, source and out-of-era status;
the full tables with URLs are in [docs/gear-research/blu-75/](../../docs/gear-research/blu-75/). Load with
`/lac load BLU_bis`, or move sets into BLU.lua as pieces arrive.

Where the gear comes from, roughly in order of impact:

| Source | Pieces |
|---|---|
| Limbus (Omega, Wilhelm in Mhaura) | Homam Zucchetto, Corazza, Manopolas, Cosciales, Gambieras: the TP, precast, accuracy and max-HP backbone |
| Limbus (Ultima) | Nashira Turban, Manteel, Gages, Seraweels, Crackows: magic accuracy and haste for casting |
| Sagheera, Port Jeuno (Ancient Beastcoins) | Magus +1 (Jubbah +1 is the physical body; Shalwar +1 has Horizon-added Haste +2%), Brutal Earring, Stealth Earring (Dual Wield lives here on Horizon), Loquacious Earring, Boxer's Mantle |
| Sea (Al'Taieu and Ru'Hmet) | Jailer torques, +5 to one stat each: Justice STR, Love DEX, Fortitude VIT, Hope AGI, Prudence INT, Faith MND, Temperance CHR. Novio Earring (MAB +7). Soil Gorget and the eight obis via "In the Name of Science" |
| CoP missions and quests | Rajas Ring (8-4; Tamas or Sattva are the alternatives), Static and Hollow Earring (Apocalypse Nigh), Fenrir's Stone, Bushinomimi, Suppanomimi |
| Maat | Maat's Cap, +7 to every stat, in half the physical and casting sets |
| Crafted / AH | Mahatma Hpl., Cuffs, Slops, Pigaches; Errant Hpl.; Prism Cape; Flame, Thunder, Soil, Breeze, Snow, Aqua, Light, Omniscient Ring; Scp. Harness +1; Dusk Jerkin, Gloves, Trousers; Alky. and Pallas's Bracelets (Delkfutt NMs); Cerberus Mantle +1; Warwolf Belt; Penitent's Rope; Devil and Demon Slayer; elemental staves |
| NMs, BCNM, ENM, KSNM | Speed Belt (King Arthro and Horizon KSNMs), Swift Belt (Sacrarium), Optical Hat (Hakutaku), Peacock Charm (Argus), Martial Anelace (ENM Brothers), Toreador's Ring, Life Belt, Bomb Queen Ring, Bloodbead pieces, Gigant Mantle, Hierarch Belt, Relaxing Earring, Jelly Ring |
| ToAU quests | Magus AF, Immortal's Scimitar (Horizon added Macc +5 / MAB +4) |

Things the research ruled out, so you do not chase them: Joyeuse, Ridill, Justice Sword and the other
multi-hit swords (not BLU on Horizon); Rostrum Pumps, Zenith Mitts, Kirin's Osode, Byakko's Haidate,
Hecatomb, Dalmatica (not BLU on Horizon); Potent Belt, Chivalrous Chain, Ksi Sash, Wightslayer, Walahra
Turban (Assault, Nyzul or Imperial Standing, or nerfed); Sorcerer's Ring (page lists BLM only). Correction
2026-11-07: Mirage relic DOES drop on Horizon (Dynamis Beaucedine / Xarcabard / Tavnazia, +1 at Sagheera for 26
Ordelle Bronzepieces); Tim owns three pieces. The earlier "no Horizon drop" ruling was wrong and BLU_bis.lua now
uses Mirage Keffiyeh (breath +10%, skill +5) and Mirage Charuqs +1 (AGI/INT +4) where they win. Hofud (Odin) is the one "maybe": the page has no out-of-era tag but Odin's Chamber is
Einherjar content.

Judgement calls baked into the file: Rajas over Tamas; spell sets never touch Main or Sub (a weapon swap
zeroes TP); Magus Jubbah +1 stays on for physical spells and only `BluePhys_Acc` (`/blu acc` on) swaps in Homam
Corazza; Maat's Cap over Magus Keffiyeh +1 for casting; Moldavite over a second Bloodbead earring for breath.
The Blue Mage pages on the wiki warn the job "is expected to change drastically", so re-check the Primer
after each Horizon patch.

## BLU_inv.lua (owned gear edition, 2026-11-07)

Same logic, filled only from what Tim owns per [inventory-2026-11-07.md](inventory-2026-11-07.md), which was
parsed from his FindAll plugin cache (`Game\config\plugins\findall\cache\Agamotto_112818.bin`: 16-byte
name, 4-byte id, then 15 containers of 81 item records at 44 bytes, then a 4096-byte key-item bitmap). The
cache covered Inventory, Safe, Safe2, Storage, Locker, Case, Wardrobe 2 and Wardrobe 7, so Mog House gear is
in. Every owned item's Horizon stats were checked on the wiki
([docs/gear-research/blu-75/owned-agamotto.md](../../docs/gear-research/blu-75/owned-agamotto.md)).

**This is the file to load.** `/lac load BLU_inv`, then `/lac debug on` and cast one of each kind.

What it does differently from BLU.lua (Tim's own v1 gear):

- Homam everywhere for TP, precast and accuracy; Mirage Jubbah +1 is the idle body (Refresh without blocking
  the head slot, which Vermillion Cloak did).
- Physical spells: Mirage Keffiyeh (skill +5) + Magus Jubbah (skill +15) + Creek M Mitts (STR +6) + two Triumph
  Rings (STR +10) + Forager's Mantle + Spike Necklace. The Jr.Msk.Chakram +2 rides in the ranged slot for STR +3
  away from his home nation, with Ammo emptied; the eggs and the Tathlum go on only when Range is empty (see v3).
- Per-modifier overlays from what he has: Love Torque + Spinel Ring (DEX), Hope Torque + Scouter's Rope +
  Mirage Charuqs +1 (AGI), Prudence Torque + Snow Ring (INT), Justice Badge (MND, also undoes Spike's MND -6),
  Star Necklace + Angel's Ring + Jester's Cape +1 (CHR), Steppe Sash (VIT).
- Magical: Errant Hpl., two Snow Rings, Prudence Torque, Moldavite, Nashira for magic accuracy, Mirage
  Charuqs +1 for INT. Drains and enfeebles use Magus Jubbah for the skill.
- Breath: the MaxHP set reaches roughly +500 HP from Creek M Mitts, Steppe Sash, Bomb Queen, Bloodbead,
  Gigant Mantle and Homam, with Mirage Keffiyeh (breath +10%) and Moldavite laid on top.
- Sattva Ring is his CoP ring (damage taken -5% on Horizon), so it sits in Idle; there is no Rajas.
- Teleport rings and Chariot Band are in the lockable list so they stay on when he puts them on by hand.

Gap to BLU_bis.lua, in rough order of value: Maat's Cap; the eight obis and Soil Gorget (Sea quest "In the Name
of Science"); Justice, Fortitude, Faith and Temperance Torques (Sea); Novio and Static Earrings; Speed Belt;
Warwolf Belt; Flame, Thunder, Soil, Breeze, Aqua, Light Rings; Mahatma or Errant Cuffs / Slops / Pigaches;
Penitent's Rope; Prism Cape; Alky. or Pallas's Bracelets; Cerberus Mantle +1; Dusk Jerkin / Trousers; Magus +1
pieces; Martial Anelace.

Known gaps in the owned file: no obis (tables are empty), no magic-burst piece, no fast-cast feet. Insect Slayer
(Horizon-buffed Macc +11 / MAB +9) is not used because it would mean a main-hand swap; it is a good casting-mode
weapon if he is not holding TP.
