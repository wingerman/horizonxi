# Agamotto (Tim Peterson)

Character ID not yet known. LuAshitacast loads from `<Name>_<Id>`, so on install this folder is
copied as `Agamotto_<Id>`; get the id from `/lac newlua` in game and pass it to the deploy script:

```bash
scripts/deploy.sh Agamotto /path/to/Game Agamotto_123456
```

Once known, rename this folder to the full name and drop the third argument.

## BLU.lua (v2, 2026-11-07)

Tim's v1 (git history, first commit) had three accuracy tiers, a learning lock, a breath max-HP idle mode and
a safe-gear lock. v2 keeps all of that and adds per-spell gear composition, built on Rag's layering idea and
on reading the server formulas. Deploy, then `/lac debug on` and cast a few things to watch the layers land.

What changed and why:

- **Every blue spell is classified** in a `BlueMagic` table (kind, stat modifiers, hit count, TP behaviour,
  dStat), parsed from the LandSandBoat spell scripts HorizonXI runs on. Full table in
  [docs/blue-magic-75.md](../../docs/blue-magic-75.md).
- **Physical spells compose** `BluePhys` + `BluePhys_MultiHit` (2+ hits) + `Mod_STR`/`Mod_DEX`/... per the
  spell's modifiers + `BluePhys_Crit` + the accuracy tier + `BluePhys_CA` when Chain Affinity is up. Fill the
  `Mod_*` overlays with a piece or two each and every spell gets the right stat without its own set.
- **Physical set goes on in precast.** Physical blue magic casts in 0.5 s and the server reads stats at
  completion; a midcast swap sent after the spell packet can miss. Toggle with `/blu fastphys` if it misbehaves.
- **Breath spells swap to max HP midcast.** The server reads current HP when the cast completes, and HP+ gear
  raises current HP, so the `MaxHP` set is applied on cast. The `/blu breath` idle mode remains for people who
  like standing in it. Note the `MaxHP` set names a Head while Idle wears Vermillion Cloak, which displaces
  head; give `MaxHP` a Body too or the Keffiyeh will not go on.
- **Magical spells split by dStat**: INT for most, CHR for Eyes On Me and Mysterious Light, MND for Mind Blast
  and Magic Hammer. Burst Affinity up adds `BlueMag_MB`. High tier adds `BlueMag_Acc`.
- **Magus Jubbah is in the physical base set.** Blue Magic skill feeds both the base D and the base attack of
  every physical spell in the server formula. Scp. Harness +1 is the alternative in the Low and High tiers.
- **Elemental staves and obis** are wired for magical, breath, drain, enfeeble and cure casts. Staves are off
  by default (`/blu staff`) because swapping main hand dumps TP. Comment out staves you do not own.
- **Skill-scaling buffs** (Diamondhide, Metallic Body, Occultation) get `BlueSkill`.
- **Resting gear waits 16 s** so the first regen tick lands in normal gear, a Rag convention.
- **Safe gear is table driven** (`LockableGear`): Warp Cudgel, reraise pieces, exp bands, Shaded Specs.,
  Goldsmith's Apron and Powder Boots stay on if you put them on by hand.
- Sets are now flat under `local sets = {` and PascalCase, so `/lac addset <Name>` and `/lac set <Name>` work.

Commands: `/blu acc`, `/blu learn`, `/blu breath`, `/blu staff`, `/blu fastphys`, `/blu status`
(`/blu` is an alias for `/lac fwd`).

Open items for Tim:

- Fill the `Mod_*`, `BluePhys_Crit`, `BlueMag_CHR`, `BlueMag_Acc`, `BlueMag_MB`, `BlueBreath` and `Precast`
  overlays. Candidates are commented next to each; check stats on https://horizonxi.com/items.
- Vanity Dive (Horizon lv 28) is not in the LandSandBoat base scripts, so it is guessed as a single-hit STR
  spell. Everyone's Grudge is absent for the same reason.
- Confirm the 0.5 s precast behaviour with `/lac debug on`. If the physical set shows in the log before the
  spell packet and the damage looks right, leave `fastphys` on.
