# Blue magic, 75 era, as HorizonXI's base implements it

Parsed on 2026-11-07 from LandSandBoat `scripts/actions/spells/blue/*.lua` (branch `base`), the server code HorizonXI is rebased on and the source the HorizonXI wiki cites on its spell pages. Horizon's own deltas are in the last column, from https://horizonffxi.wiki/Blue_Magic and the Blupedia compendium. Treat anything not marked as retail-identical until seen in game.

How to read it: **WSC** is the spell's stat modifier mix (STR20 DEX20 = 20% each). **fTP** is the damage multiplier at 0 / 1500 / 3000 TP, which only moves under Chain Affinity. **tpMod** says what TP changes under Chain Affinity. **dStat** is the stat compared against the target for magical spells. **hpMod** is the divisor in `HP / hpMod` for breath damage, smaller is stronger. **Use** is the formula family.

## Gear that matters, by family

| Family | What scales it | Gear stats to stack |
|---|---|---|
| Physical | base D from Blue Magic skill (capped per spell) + fSTR + WSC; attack = 8 + skill + STR, and Horizon's BLU Primer states gear attack does not apply; hit rate = main-hand accuracy with no +100 first-hit bonus on Horizon; per hit for multi-hit. Horizon 2.0: held TP scales tpMod spells without Chain Affinity (LSB base needs CA) | STR, Blue Magic skill, the spell's WSC stats, accuracy (every hit), crit on tpMod CRITICAL spells, Store TP / TP holding |
| Magical | ((lvl+2) + WSC) * fTP + (your dStat - target's) * mult; then MAB, magic accuracy, elemental staff, day/weather | INT (or CHR / MND per spell), MAB, magic accuracy, matching staff and obi |
| Breath | current HP / hpMod (+ lvl term), staff, day/weather, resist | max HP at cast completion, matching staff and obi, magic accuracy |
| Drain | dark magic style, resist on INT | INT, magic accuracy, dark staff / Anrin Obi |
| Cure | 3*MND + VIT + 3*floor(healing skill/5) | MND, VIT, cure potency, light staff |
| Enfeeble | resist rate on INT and Blue Magic skill | INT, magic accuracy, Blue Magic skill, matching staff |
| Buff | fixed, except Diamondhide and Metallic Body (stoneskin power from skill) and Occultation (shadows from skill) | Blue Magic skill for those three |

## Spells

| Lv | Spell | Type | Use | Hits | fTP 0/1500/3000 | WSC | tpMod | dStat | hpMod | Trait | Horizon |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Foot Kick | Physical (Slashing) | Physical | 1 | 1.0/1.0/1.0 | STR10 DEX10 | CRITICAL |  |  | Lizard Killer |  |
| 1 | Pollen | Magical (Light) | Curing | 1 |  |  |  |  |  | Resist Sleep |  |
| 1 | Sandspin | Magical (Earth) | Magical | 1 | 1.0// | INT20 |  | INTx1.0 |  | None |  |
| 4 | Power Attack | Physical (Blunt) | Physical | 1 | 1.125/1.125/1.125 | STR10 VIT10 | CRITICAL |  |  | Plantoid Killer |  |
| 4 | Sprout Smack | Physical (Blunt) | Physical | 1 | 1.5/1.5/1.5 | VIT30 | DURATION |  |  | Beast Killer |  |
| 4 | Wild Oats | Physical (Piercing) | Physical | 1 | 1.8359375/1.8359375/1.8359375 | AGI30 | DURATION |  |  | Beast Killer |  |
| 8 | Cocoon | Magical (Earth) | - | 1 |  |  |  |  |  | None | VIT+3 set bonus removed |
| 8 | Metallic Body | Magical (Earth) | - | 1 |  |  |  |  |  | Max MP Boost | trait Max MP Boost -> Conserve MP, 3 set pts |
| 8 | Queasyshroom | Physical (Piercing) | Physical | 1 | 1.75/1.75/1.75 | INT20 | DURATION |  |  | None |  |
| 12 | Battle Dance | Physical (Slashing) | Physical | 1 | 2.0/2.0/2.0 | STR30 | DURATION |  |  | Attack Bonus |  |
| 12 | Feather Storm | Physical (Piercing) | Physical | 1 | 2/2/2 | AGI30 | DURATION |  |  | Rapid Shot |  |
| 12 | Head Butt | Physical (Blunt) | Physical | 1 | 1.75/2.125/2.25 | STR20 INT20 | DAMAGE |  |  | None |  |
| 16 | Healing Breeze | Magical (Wind) | Curing | 1 |  |  |  |  |  | Auto Regen |  |
| 16 | Helldive | Physical (Blunt) | Physical | 1 | 1.25/1.625/2.00 | AGI30 | DAMAGE |  |  | None |  |
| 16 | Sheep Song | Magical (Light) | Enfeebling | 1 |  |  |  |  |  | Auto Regen |  |
| 18 | Blastbomb | Magical (Fire) | Magical | 1 | 1.375// | INT20 |  | INTx1.0 |  | None |  |
| 18 | Bludgeon | Physical (Blunt) | Physical | 3 | 1.0/1.0/1.0 | CHR30 | ACC |  |  | Undead Killer |  |
| 18 | Cursed Sphere | Magical (Water) | Magical | 1 | 1.50// | INT30 |  | INTx1.0 |  | Magic Attack Bonus |  |
| 20 | Blood Drain | Magical (Dark) | Drain | 1 |  |  |  |  |  | None |  |
| 20 | Claw Cyclone | Physical (Slashing) | Physical | 2 | 1.4375/1.4375/1.4375 | DEX30 | ATTACK |  |  | Lizard Killer |  |
| 22 | Poison Breath | Magical (Water) | Breath | 1 |  |  |  |  | 10 | Clear Mind |  |
| 24 | Soporific | Magical (Dark) | Enfeebling | 1 |  |  |  |  |  | Clear Mind |  |
| 26 | Screwdriver | Physical (Piercing) | Physical | 1 | 1.375/1.375/1.375 | STR20 MND20 | CRITICAL |  |  | Evasion Bonus |  |
| 28 | Bomb Toss | Magical (Fire) | Magical | 1 | 1.625// | INT20 |  | INTx1.0 |  | None |  |
| 30 | Grand Slam | Physical (Blunt) | Physical | 1 | 1.0/1.0/1.0 | VIT30 | ATTACK |  |  | Defense Bonus |  |
| 30 | Wild Carrot | Magical (Light) | Curing | 1 |  |  |  |  |  | Resist Sleep |  |
| 32 | Chaotic Eye | Magical (Wind) | Enfeebling | 1 |  |  |  |  |  | Conserve MP |  |
| 32 | Sound Blast | Magical (Fire) | Enfeebling | 1 |  |  |  |  |  | Magic Attack Bonus |  |
| 34 | Death Ray | Magical (Dark) | Magical | 1 | 1.625// | INT20 MND10 |  | INTx1.0 |  | None |  |
| 34 | Smite of Rage | Physical (Slashing) | Physical | 1 | 1.5/2.25/2.5 | STR20 DEX20 | DAMAGE |  |  | Undead Killer |  |
| 36 | Digest | Magical (Dark) | Drain | 1 |  |  |  |  |  | None | counts toward Conserve MP |
| 36 | Pinecone Bomb | Physical (Piercing) | Physical | 1 | 2.25/2.25/2.25 | STR20 AGI20 | DURATION |  |  | None |  |
| 38 | Blank Gaze | Magical (Light) | - | 1 |  |  |  |  |  | None |  |
| 38 | Jet Stream | Physical (Blunt) | Physical | 3 | 1.125/1.125/1.125 | AGI30 | ACC |  |  | Rapid Shot |  |
| 38 | Uppercut | Physical (Blunt) | Physical | 1 | 1.5/1.5/1.5 | STR35 | ATTACK |  |  | Attack Bonus |  |
| 40 | Mysterious Light | Magical (Wind) | Magical | 1 | 2.0// | CHR30 |  | CHRx1.0 |  | Max MP Boost |  |
| 40 | Terror Touch | Physical (Blunt) | Physical | 1 | 1.5/1.5/1.5 | DEX20 INT20 | ACC |  |  | Defense Bonus |  |
| 42 | MP Drainkiss | Magical (Dark) | Drain | 1 |  |  |  | INT |  | None |  |
| 42 | Venom Shell | Magical (Water) | Enfeebling | 1 |  |  |  |  |  | Clear Mind |  |
| 44 | Blitzstrahl | Magical (Lightning) | Magical | 1 | 1.5625// | INT30 MND10 |  | INTx1.0 |  | None |  |
| 44 | Mandibular Bite | Physical (Slashing) | Physical | 1 | 2.0/2.0/2.0 | STR20 INT20 | ATTACK |  |  | Plantoid Killer |  |
| 44 | Stinking Gas | Magical (Wind) | Enfeebling | 1 |  |  |  |  |  | Auto Refresh |  |
| 46 | Awful Eye | Magical (Water) | Enfeebling | 1 |  |  |  |  |  | Clear Mind |  |
| 46 | Geist Wall | Magical (Dark) | - | 1 |  |  |  |  |  | None |  |
| 46 | Magnetite Cloud | Magical (Earth) | Breath | 1 |  |  |  |  | 6 | Magic Defense Bonus |  |
| 48 | Blood Saber | Magical (Dark) | Drain | 1 |  |  |  |  |  | None |  |
| 48 | Jettatura | Magical (Dark) | Enfeebling | 1 |  |  |  |  |  | None |  |
| 48 | Refueling | Magical (Wind) | - | 1 |  |  |  |  |  | None |  |
| 48 | Sickle Slash | Physical (Blunt) | Physical | 1 | 1.5/1.5/1.5 | DEX50 | CRITICAL |  |  | Store TP |  |
| 50 | Frightful Roar | Magical (Wind) | Enfeebling | 1 |  |  |  |  |  | Auto Refresh |  |
| 50 | Ice Break | Magical (Ice) | Magical | 1 | 2.25// | INT30 |  | INTx1.0 |  | Magic Defense Bonus |  |
| 50 | Self-Destruct | Magical (Fire) | - | 1 |  |  |  |  |  | Auto Refresh |  |
| 52 | Cold Wave | Magical (Ice) | - | 1 |  |  |  | INT |  | Auto Refresh |  |
| 52 | Filamented Hold | Magical (Earth) | Enfeebling | 1 |  |  |  |  |  | Clear Mind |  |
| 54 | Hecatomb Wave | Magical (Wind) | Breath | 1 |  |  |  |  | 4 | Max MP Boost |  |
| 54 | Radiant Breath | Magical (Light) | Breath | 1 |  |  |  |  | 5 | None |  |
| 56 | Feather Barrier | Magical (Wind) | - | 1 |  |  |  |  |  | Resist Gravity |  |
| 58 | Flying Hip Press | Magical (Wind) | Breath | 1 |  |  |  |  | 3 | Max HP Boost |  |
| 58 | Light of Penance | Magical (Light) | - | 1 |  |  |  |  |  | Auto Refresh |  |
| 58 | Magic Fruit | Magical (Light) | Curing | 1 |  |  |  |  |  | Resist Sleep |  |
| 60 | Death Scissors | Physical (Slashing) | Physical | 1 | 1.5/2.75/3.25 | STR60 | DAMAGE |  |  | Attack Bonus |  |
| 60 | Dimensional Death | Physical (Blunt) | Physical | 1 | 2.25/2.25/2.25 | STR50 | ATTACK |  |  | Accuracy Bonus |  |
| 61 | Bad Breath | Magical (Earth) | Breath | 1 |  |  |  |  | 8 | Fast Cast |  |
| 61 | Eyes On Me | Magical (Dark) | Magical | 1 | 2.625// | CHR40 |  | CHRx1.5 |  | Magic Attack Bonus |  |
| 61 | Maelstrom | Magical (Water) | Magical | 1 | 2.375// | INT30 MND10 |  | INTx1.5 |  | Clear Mind |  |
| 62 | 1000 Needles | Magical (Light) | - | 1 | 1.5/1.5/1.5 | STR100 DEX150 INT200 MND100 CHR100 | DAMAGE |  |  | Beast Killer |  |
| 62 | Body Slam | Physical (Blunt) | Physical | 1 | 1.5/1.5/1.5 | VIT40 | ATTACK |  |  | Max HP Boost |  |
| 62 | Memento Mori | Magical (Ice) | - | 1 |  |  |  |  |  | Magic Attack Bonus |  |
| 63 | Frenetic Rip | Physical (Blunt) | Physical | 3 | 1.359375/2.0703125/2.359375 | STR20 DEX20 | DAMAGE |  |  | Accuracy Bonus |  |
| 63 | Frypan | Physical (Blunt) | Physical | 1 | 1.7734375/1.7734375/1.7734375 | STR20 MND20 | ACC |  |  | Max HP Boost |  |
| 63 | Hydro Shot | Physical (Blunt) | Physical | 1 | 1.25/1.25/1.25 | AGI30 | EFFECT_CHANCE |  |  | Rapid Shot |  |
| 63 | Spinal Cleave | Physical (Slashing) | Physical | 1 | 3.0/3.0/3.0 | STR30 | ACC |  |  | Attack Bonus |  |
| 64 | Feather Tickle | Magical (Wind) | - | 1 |  |  |  |  |  | Clear Mind |  |
| 64 | Yawn | Magical (Light) | Enfeebling | 1 |  |  |  |  |  | Resist Sleep |  |
| 65 | Infrasonics | Magical (Ice) | Enfeebling | 1 |  |  |  |  |  | None |  |
| 65 | Zephyr Mantle | Magical (Wind) | - | 1 |  |  |  |  |  | Conserve MP |  |
| 66 | Frost Breath | Magical (Ice) | Breath | 1 |  |  |  |  | 3 | Conserve MP |  |
| 66 | Sandspray | Magical (Dark) | Enfeebling | 1 |  |  |  |  |  | Clear Mind |  |
| 67 | Diamondhide | Magical (Earth) | - | 1 |  |  |  |  |  | None |  |
| 67 | Enervation | Magical (Dark) | - | 1 |  |  |  |  |  | Counter |  |
| 68 | Firespit | Magical (Fire) | Magical | 1 | 3.0// | INT20 MND20 |  | INTx1.5 |  | Conserve MP |  |
| 69 | Hysteric Barrage | Physical (Hand-to-Hand) | Physical | 5 | 1.25/1.625/1.75 | DEX30 | DAMAGE |  |  | Evasion Bonus |  |
| 69 | Tail Slap | Physical (Blunt) | Physical | 1 | 1.625/1.625/1.625 | STR20 VIT50 | ATTACK | INT |  | Store TP |  |
| 70 | Amplification | Magical (Water) | - | 1 |  |  |  |  |  | None |  |
| 70 | Cannonball | Physical (Blunt) | Physical | 1 | 1.75/2.125/2.75 | STR50 VIT50 | DAMAGE |  |  | None |  |
| 71 | Heat Breath | Magical (Fire) | Breath | 1 |  |  |  |  | 2 | Magic Attack Bonus |  |
| 71 | Lowing | Magical (Fire) | Enfeebling | 1 |  |  |  |  |  | Clear Mind |  |
| 72 | Disseverment | Physical (Piercing) | Physical | 5 | 1.5/1.5/1.5 | STR20 DEX20 | ACC |  |  | Accuracy Bonus |  |
| 72 | Saline Coat | Magical (Light) | - | 1 |  |  |  |  |  | Defense Bonus |  |
| 72 | Voracious Trunk | Magical (Wind) | - | 1 |  |  |  |  |  | Auto Refresh |  |
| 73 | Mind Blast | Magical (Lightning) | Magical | 1 | 2.08// | MND30 |  | MNDx1.5 |  | Clear Mind |  |
| 73 | Ram Charge | Physical (Blunt) | Physical | 1 | 1.0/1.375/1.75 | STR30 MND50 | DAMAGE |  |  | Lizard Killer |  |
| 73 | Temporal Shift | Magical (Lightning) | Enfeebling | 1 |  |  |  |  |  | Attack Bonus |  |
| 74 | Actinic Burst | Magical (Light) | Enfeebling | 1 |  |  |  |  |  | Auto Refresh |  |
| 74 | Magic Hammer | Magical (Light) | Magical | 1 | 1.5// | MND30 |  | MNDx1.0 |  | Magic Attack Bonus |  |
| 74 | Reactor Cool | Magical (Ice) | - | 1 |  |  |  |  |  | Magic Attack Bonus |  |
| 75 | Exuviation | Magical (Fire) | Curing | 1 |  |  |  |  |  | Resist Sleep |  |
| 75 | Plasma Charge | Magical (Lightning) | - | 1 |  |  |  |  |  | Auto Refresh |  |
| 75 | Vertical Cleave | Physical (Slashing) | Physical | 1 | 3.0/3.0/3.0 | STR50 | ATTACK |  |  | Defense Bonus |  |
| 42 | Auroral Drape | Magical (Wind) | Enfeebling | 1 |  |  |  |  |  | Fast Cast | learn 84 -> 42 |
| 54 | Quadratic Continuum | Physical (Piercing) | Physical | 4 | 1.25/1.5/1.75 | STR32 VIT32 | DAMAGE |  |  | Dual Wield | learn 85 -> 54 |
| 34 | Empty Thrash | Physical (Slashing) | Physical | 1 | 2.0/2.0/2.0 | STR50 | ACC |  |  | Doule Attack, Triple Attack | trait Double Attack -> Max HP Boost |
| 38 | Occultation | Magical (Wind) | - | 1 |  |  |  |  |  | Evasion Bonus | learn 88 -> 38; shadows per 75 skill not 50 |

Not in LandSandBoat `base` and so absent above: Vanity Dive (Horizon lv 28) and Everyone's Grudge (Horizon lv 65). Vanity Dive is treated as a single-hit STR spell in the profile until verified.
