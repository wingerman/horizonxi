-- BLU_bis.lua : Agamotto (Tim Peterson), HorizonXI 75 era. TARGET GEAR EDITION.
-- Same logic as BLU.lua (v2, 2026-11-07); every set filled with the best gear a BLU can actually get on
-- HorizonXI as of 2026-11-07. Every item below was checked against its horizonffxi.wiki page (stats, jobs,
-- source, out-of-era status); the tables with URLs are in docs/gear-research/blu-75/. Load with
-- /lac load BLU_bis, or copy sets into BLU.lua piece by piece as the gear arrives.
--
-- Availability rules applied: CoP-era endgame plus the ToAU zones released 2026-08-07. Nothing from Assault,
-- Nyzul, Salvage, ISNM, ZNM, Besieged or Imperial Standing (all out of era on Horizon). Mirage relic does not
-- drop in Horizon's Dynamis. Magus +1 is available via Sagheera. Hofud depends on Odin being live (unsure).
-- Three mutually exclusive CoP 8-4 rings: this file assumes Rajas Ring (Store TP matters on Horizon); Tamas
-- is the casting alternative, Sattva the defensive one.
--
-- Weapon rule: no spell set changes Main or Sub. Swapping a weapon zeroes TP, and on Horizon held TP is a
-- large part of physical spell damage. Elemental staves are wired but off (/blu staff) for the same reason.
-- Weapon DMG and attack do not feed physical spells, so Main/Sub are picked for melee TP and their stats.
--
-- Item names are in-game display names (abbreviated where the game abbreviates: Scp. Harness +1, Mahatma Hpl.,
-- Alky. Bracelets, Loquac. Earring, Phtm. Tathlum). If a swap does not happen, /lac debug on and compare the
-- name the log prints with the one here.
--
--
-- How sets are chosen (Rag's composition idea: a base set, then overlays laid on top):
--   Physical blue magic : BluePhys -> BluePhys_MultiHit -> Mod_<STAT>... -> BluePhys_Crit -> BluePhys_Acc (acc on) -> BluePhys_TP (TP high or Chain Affinity)
--   Magical blue magic  : BlueMag  -> BlueMag_<INT|MND|CHR> -> BlueMag_Acc (acc on) -> BlueMag_MB (Burst Affinity up) -> staff/obi
--   Breath              : MaxHP -> BlueBreath -> staff/obi
--   Drains              : BlueDrain -> dark staff/obi
--   Cures               : BlueCure -> light staff
--   Enfeebles           : BlueEnfeeble -> BlueMag_Acc (acc on) -> staff/obi
--   Buffs               : BlueBuff (+ BlueSkill for Diamondhide / Metallic Body / Occultation, which scale with skill)
--   Every blue cast     : Learning lock if /blu learn is on, then lockable safe gear re-asserted.
--
-- Why these overlays (from the LandSandBoat source HorizonXI is rebased on, scripts/globals/bluemagic.lua):
--   Physical: D = (floor(skill*0.11)*2+3, capped per spell) + fSTR + WSC. WSC is the spell's stat modifiers
--             (e.g. Disseverment STR 20% DEX 20%) times a level factor. Attack comes from Blue Magic skill + STR;
--             Horizon's BLU Primer is explicit that GEAR ATTACK DOES NOT AFFECT PHYSICAL SPELLS. Hit rate is your
--             main-hand accuracy and Horizon currently lacks the +100 first-hit bonus, so accuracy counts on every
--             hit. Priorities: STR, Blue Magic skill, the spell's modifier stats, accuracy.
--             TP: in LandSandBoat base, TP only matters under Chain Affinity. On Horizon as of patch 2.0 held TP
--             scales TP-modifier spells on its own (the "3K TP meta", near double damage at 3000 TP), and the
--             Primer expects 2.1 to change it. The profile treats TP >= TpThreshold or Chain Affinity as "TP active".
--   Magical : D = ((level+2) + WSC) * fTP + (your dStat - target dStat) * mult, then MAB, magic accuracy,
--             elemental staff, day/weather. dStat is INT for most, CHR for Eyes On Me and Mysterious Light,
--             MND for Mind Blast and Magic Hammer.
--   Breath  : damage = current HP / divisor (+ level term), then staff, day/weather, resist. HP is read when
--             the cast completes, so a max-HP midcast set counts. Tim's v1 assumed it did not.
--   Cures   : power = 3*MND + VIT + 3*floor(healing skill/5). MND and VIT.
--   Enfeeble: resist check uses INT and Blue Magic skill. INT, magic accuracy, skill.
--
-- Horizon-specific: Horizon's wiki spell pages cite LandSandBoat as their source. Known Horizon changes are
-- learn levels and trait points (Vanity Dive 28, Empty Thrash 34, Occultation 38, Auroral Drape 42,
-- Quad. Continuum 54, Winds of Promyvion 56), Occultation shadows per 75 skill, Metallic Body -> Conserve MP.
-- Verify any item's stats at https://horizonxi.com/items before trusting a retail wiki.
--
-- Commands (type /blu <cmd>, or /lac fwd <cmd>):
--   acc        toggle accuracy gear on/off (TP_Acc, WS_Acc, BluePhys_Acc, BlueMag_Acc)
--   ranged     re-run the Range/Ammo pair check (it also runs on load)
--   learn      toggle spell-learning lock (Magus Jubbah + Bazubands on every blue cast)
--   breath     toggle max-HP idle mode (breath spells already swap to max HP midcast; this is for standing around)
--   staff      toggle elemental staff swaps on magical/breath/drain/enfeeble/cure casts (costs TP; off by default)
--   fastphys   toggle equipping the physical set in precast for 0.5 s casts (on by default)
--   tp <n>     set the TP threshold for the TP overlay (default 2000; 9999 disables it, 0 forces it)
--   status     print current toggles
--
-- Rules that bite: '' in a slot does nothing, 'remove' clears it, 'displaced' marks a slot another item will
-- empty. Range and Ammo are set together in every set that names either (see "Range and Ammo travel together").
-- Set keys are case sensitive. /lac addset rewrites the "local sets = {" block, keep braces balanced.

local profile = {}

-- ---------------------------------------------------------------------------------------------------------------
-- Toggles
-- ---------------------------------------------------------------------------------------------------------------
local Settings = {
    Acc          = false,   -- accuracy gear on for TP, WS, physical and magical blue magic (/blu acc)
    Learning     = false,
    BreathIdle   = false,
    UseStaff     = false,   -- swapping main hand for a staff dumps TP; opt in
    FastPhysical = true,    -- equip physical blue set in precast for sub-second casts
    RestingAfter = 16,      -- seconds of resting before resting gear goes on (lets a regen tick land first)
    TpThreshold  = 2000,    -- TP at or above this counts as "TP active" for BluePhys_TP (Horizon 2.0 behaviour)
}

-- ---------------------------------------------------------------------------------------------------------------
-- Sets. Flat so /lac addset works. Overlays only name the slots they change.
-- Fill overlays by dressing in game and running /lac addset <SetName>, or by hand.
-- ---------------------------------------------------------------------------------------------------------------
local sets = {
    -- ---- Idle / resting / town ------------------------------------------------------------------------------
    Idle = {
        Main = 'Martial Anelace',           -- TP weapon stays on at idle
        Sub = 'Devil Slayer',               -- /NIN dual wield; Genbu's Shield (PDT -10%, Eva +10) if not /NIN
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Fenrir\'s Stone',           -- day HP +30 / night Eva +10
        Body = 'Vermillion Cloak',          -- Refresh; displaces head, so no Head here
        Neck = 'Peacock Charm',
        Ear1 = 'Ethereal Earring',          -- HP +15, 3% damage to MP
        Ear2 = 'Brutal Earring',
        Hands = 'Homam Manopolas',
        Ring1 = 'Jelly Ring',               -- PDT -5%
        Ring2 = 'Rajas Ring',
        Back = 'Boxer\'s Mantle',           -- Eva skill +10; Shadow Mantle if you ever hold one
        Waist = 'Speed Belt',               -- Horizon: Haste +5%
        Legs = 'Blood Cuisses',             -- Movement +12%
        Feet = 'Homam Gambieras',
    },
    Resting = {
        Main = 'Pluto\'s Staff',            -- hMP +10. Costs TP; comment out if holding TP matters more than MP
        Sub = 'displaced',
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Hedgehog Bomb',             -- MP +30
        Neck = 'Checkered Scarf',           -- Horizon: hMP +1, HP -12
        Ear1 = 'Relaxing Earring',          -- hMP +2
        Ear2 = 'Loquac. Earring',           -- MP +30
        Body = 'Errant Hpl.',               -- hMP +5
        Waist = 'Hierarch Belt',            -- hMP +2, MP +48
        Legs = 'Baron\'s Slops',            -- hMP +1
    },
    Town = {
        Body = 'Ducal Aketon',              -- Horizon custom, Movement +12% in the three nations
    },
    -- Max HP. Breath spells read HP at cast completion; also /blu breath idle mode.
    MaxHP = {
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Happy Egg',                 -- HP +1% (event item); Fenrir's Stone by day otherwise
        Head = 'Homam Zucchetto',           -- HP +22
        Neck = 'Bloodbead Amulet',          -- HP +15
        Ear1 = 'Bloodbead Earring',         -- HP +25
        Ear2 = 'Novio Earring',             -- MAB +7, breath is MAB-scaled on Horizon for now
        Body = 'Dusk Jerkin',               -- HP +40 (movement penalty, fine mid-cast)
        Hands = 'Dusk Gloves',              -- HP +20
        Ring1 = 'Bomb Queen Ring',          -- HP +75
        Ring2 = 'Bloodbead Ring',           -- HP +50
        Back = 'Gigant Mantle',             -- HP +80
        Legs = 'Dusk Trousers',             -- HP +35
        Feet = 'Homam Gambieras',           -- HP +31
    },

    -- ---- TP ------------------------------------------------------------------------------------------------
    -- Full Homam (Limbus Omega) is the backbone: 12% haste and accuracy on four slots. Speed Belt takes it to 17%.
    TP = {
        Main = 'Martial Anelace',           -- Hofud (DMG 42, MND/CHR +5) if Odin is up; Devil Slayer otherwise
        Sub = 'Devil Slayer',
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Bomb Core',                 -- Attack +12 (melee only; attack does nothing for spells)
        Head = 'Homam Zucchetto',
        Neck = 'Peacock Charm',
        Ear1 = 'Brutal Earring',
        Ear2 = 'Stealth Earring',           -- Horizon moved Dual Wield here from Suppanomimi. Not /NIN: Hollow Earring
        Body = 'Homam Corazza',             -- Acc +15, Triple Attack
        Hands = 'Homam Manopolas',
        Ring1 = 'Rajas Ring',
        Ring2 = 'Toreador\'s Ring',
        Back = 'Amemet Mantle +1',
        Waist = 'Speed Belt',               -- Swift Belt (+4%) until then
        Legs = 'Homam Cosciales',
        Feet = 'Homam Gambieras',
    },
    TP_Acc = {
        Head = 'Optical Hat',
        Waist = 'Life Belt',
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Tiphia Sting',
    },

    -- ---- Weaponskills ---------------------------------------------------------------------------------------
    -- Soil Gorget covers Vorpal, Savage and Seraph Blade (all Scission) on Horizon's page.
    WS = {
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Tiphia Sting',
        Head = 'Maat\'s Cap',               -- all stats +7
        Neck = 'Soil Gorget',
        Ear1 = 'Brutal Earring',
        Ear2 = 'Triumph Earring',           -- STR +2; Bushinomimi is the other STR +2 ear
        Body = 'Magus Jubbah +1',           -- STR +5 DEX +5
        Hands = 'Alky. Bracelets',          -- STR +11 (DEX -6 AGI -6)
        Ring1 = 'Rajas Ring',
        Ring2 = 'Flame Ring',               -- STR +5
        Back = 'Cerberus Mantle +1',        -- STR +4; Forager's Mantle STR +3 is the cheap one
        Waist = 'Warwolf Belt',             -- STR DEX VIT +5
        Legs = 'Magus Shalwar +1',          -- DEX VIT AGI +5, Haste +2%; no STR legs exist for BLU
        Feet = 'Homam Gambieras',           -- Acc +6; no STR feet exist for BLU
    },
    WS_Acc = {
        Head = 'Optical Hat',
        Neck = 'Peacock Charm',
        Hands = 'Homam Manopolas',
        Ring2 = 'Toreador\'s Ring',
    },
    WS_SeraphBlade = {          -- MND
        Ring2 = 'Aqua Ring',                -- MND +5
        Waist = 'Penitent\'s Rope',         -- INT MND +5
    },
    WS_VorpalBlade = {          -- STR with TP-scaled crit; base WS set is right
    },
    WS_SavageBlade = {          -- STR MND
        Ring2 = 'Aqua Ring',
    },

    Precast = {                             -- fast cast and haste
        Head = 'Homam Zucchetto',
        Ear2 = 'Loquac. Earring',           -- Fast Cast
        Body = 'Nashira Manteel',           -- Haste +3%
        Hands = 'Homam Manopolas',
        Back = 'Warlock\'s Mantle',         -- latent Fast Cast (latent condition not on the page; test it)
        Waist = 'Speed Belt',
        Legs = 'Homam Cosciales',           -- Fast Cast + Haste +3%
        Feet = 'Homam Gambieras',
    },

    -- ---- Physical blue magic --------------------------------------------------------------------------------
    -- STR, Blue Magic skill, modifier stats, then accuracy. Attack is ignored by the formula on Horizon.
    BluePhys = {
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Tiphia Sting',              -- Acc +2
        Head = 'Maat\'s Cap',               -- STR +7 and every modifier +7
        Neck = 'Justice Torque',            -- STR +5 (Sea). Modifier overlays swap in the matching torque
        Ear1 = 'Triumph Earring',           -- STR +2
        Ear2 = 'Bushinomimi',               -- STR +2
        Body = 'Magus Jubbah +1',           -- Blue Magic skill +15 (base D and attack), STR +5 DEX +5
        Hands = 'Alky. Bracelets',          -- STR +11; DEX/AGI overlays replace it
        Ring1 = 'Rajas Ring',               -- STR +5 DEX +5
        Ring2 = 'Flame Ring',               -- STR +5
        Back = 'Cerberus Mantle +1',        -- STR +4
        Waist = 'Warwolf Belt',             -- STR DEX VIT +5
        Legs = 'Homam Cosciales',           -- Acc +3; Magus Shalwar +1 when the spell wants DEX/VIT/AGI
        Feet = 'Homam Gambieras',           -- Acc +6
    },
    BluePhys_Acc = {            -- about +77 accuracy over base from verified pieces
        Head = 'Optical Hat',               -- Acc +10
        Neck = 'Peacock Charm',             -- Acc +10
        Ear2 = 'Hollow Earring',            -- Acc +3 DEX +2
        Body = 'Homam Corazza',             -- Acc +15; costs the Jubbah's skill, so only when hits are missing
        Hands = 'Homam Manopolas',          -- Acc +4
        Ring2 = 'Toreador\'s Ring',         -- Acc +7
        Waist = 'Life Belt',                -- Acc +10
    },
    BluePhys_MultiHit = {           -- 2+ hits: every hit rolls accuracy and fTP is low, so acc before STR
        Hands = 'Homam Manopolas',          -- drops Alky's DEX -6 too
        Ring2 = 'Toreador\'s Ring',
        Waist = 'Life Belt',
    },
    BluePhys_Crit = {               -- Foot Kick, Power Attack, Screwdriver, Sickle Slash: crit comes from DEX
        Ring2 = 'Thunder Ring',             -- DEX +5. Dissector (crit +6%) is a main-hand swap, so not used here
    },
    BluePhys_TP = {                 -- TP active: fTP scales, so STR matters even more; base already is STR
    },
    BluePhys_TP_Acc = {             -- acc-type spell with TP active: TP supplies the accuracy, go back to STR
        Head = 'Maat\'s Cap',
        Neck = 'Justice Torque',
        Hands = 'Alky. Bracelets',
        Ring2 = 'Flame Ring',
        Waist = 'Warwolf Belt',
    },
    -- Modifier overlays. The seven Sea Jailer torques are +5 to one stat each on Horizon, and the Lv74 element
    -- rings cover every stat; Magus Shalwar +1 covers DEX, VIT and AGI legs.
    Mod_STR = {
    },
    Mod_DEX = {
        Neck = 'Love Torque',               -- DEX +5
        Hands = 'Homam Manopolas',          -- avoids Alky's DEX -6
        Ring2 = 'Thunder Ring',             -- DEX +5
        Legs = 'Magus Shalwar +1',          -- DEX +5
    },
    Mod_VIT = {
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Bibiki Seashell',           -- VIT +4
        Neck = 'Fortitude Torque',          -- VIT +5 and Sword skill +7 (accuracy)
        Ring2 = 'Soil Ring',                -- VIT +5
        Legs = 'Magus Shalwar +1',          -- VIT +5
    },
    Mod_AGI = {
        Neck = 'Hope Torque',               -- AGI +5
        Ear2 = 'Drone Earring',             -- AGI +3
        Hands = 'Homam Manopolas',          -- avoids Alky's AGI -6
        Ring2 = 'Breeze Ring',              -- AGI +5
        Legs = 'Magus Shalwar +1',          -- AGI +5
    },
    Mod_INT = {
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Phtm. Tathlum',             -- INT +2
        Neck = 'Prudence Torque',           -- INT +5
        Hands = 'Magus Bazubands +1',       -- STR +3 INT +3
        Ring2 = 'Snow Ring',                -- INT +5
    },
    Mod_MND = {
        Neck = 'Faith Torque',              -- MND +5
        Ring2 = 'Aqua Ring',                -- MND +5
    },
    Mod_CHR = {
        Neck = 'Temperance Torque',         -- CHR +5
        Ring2 = 'Light Ring',               -- CHR +5
    },

    -- ---- Magical blue magic ---------------------------------------------------------------------------------
    BlueMag = {                     -- INT, MAB, magic accuracy
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Phtm. Tathlum',             -- INT +2
        Head = 'Maat\'s Cap',               -- INT +7 beats Magus Keffiyeh +1 (INT +5)
        Neck = 'Prudence Torque',           -- INT +5; Uggalepih Pendant (latent MAB) when MP is under 50%
        Ear1 = 'Novio Earring',             -- MAB +7 (Jailer of Love, in era)
        Ear2 = 'Moldavite Earring',         -- MAB +5
        Body = 'Mahatma Hpl.',              -- INT +11
        Hands = 'Mahatma Cuffs',            -- INT +6
        Ring1 = 'Snow Ring',                -- INT +5
        Ring2 = 'Omniscient Ring',          -- INT +5; Tamas Ring (INT/MND +5, Macc +5) if you chose it over Rajas
        Back = 'Prism Cape',                -- INT MND CHR +4
        Waist = 'Penitent\'s Rope',         -- INT MND +5; the matching obi replaces it on day/weather
        Legs = 'Mahatma Slops',             -- INT +8
        Feet = 'Nashira Crackows',          -- Macc +2; no INT feet exist for BLU
    },
    BlueMag_INT = {
    },
    BlueMag_MND = {                 -- Mind Blast, Magic Hammer
        Neck = 'Faith Torque',              -- MND +5
        Ring1 = 'Aqua Ring',                -- MND +5
        Feet = 'Mahatma Pigaches',          -- MND +6
    },
    BlueMag_CHR = {                 -- Eyes On Me, Mysterious Light
        Neck = 'Temperance Torque',         -- CHR +5
        Ring1 = 'Light Ring',               -- CHR +5
    },
    BlueMag_Acc = {                 -- acc on: Nashira magic accuracy where it beats the INT piece
        Head = 'Nashira Turban',            -- Macc +5 (about equal to Maat's INT +7; take it when resists hurt)
    },
    BlueMag_MB = {                  -- Burst Affinity up
        Ear2 = 'Static Earring',            -- bonus magic burst damage (Apocalypse Nigh)
    },

    -- ---- Breath, drains, cures, enfeebles, buffs ------------------------------------------------------------
    BlueBreath = {                  -- laid over MaxHP
        Ear1 = 'Moldavite Earring',         -- MAB +5 outweighs Bloodbead's HP +25 at Heat Breath's HP/2
    },
    BlueDrain = {                   -- Blood Drain, Digest, MP Drainkiss, Blood Saber: INT, Macc, MAB, skill
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Phtm. Tathlum',
        Head = 'Maat\'s Cap',
        Neck = 'Prudence Torque',
        Ear1 = 'Novio Earring',
        Ear2 = 'Moldavite Earring',
        Body = 'Magus Jubbah +1',           -- skill feeds drains per the Primer
        Hands = 'Mahatma Cuffs',
        Ring1 = 'Snow Ring',
        Ring2 = 'Omniscient Ring',
        Back = 'Prism Cape',
        Waist = 'Penitent\'s Rope',
        Legs = 'Mahatma Slops',
        Feet = 'Nashira Crackows',
    },
    BlueCure = {                    -- 3*MND + VIT; Apollo's Staff is cure potency +10% but costs TP (/blu staff)
        Head = 'Maat\'s Cap',               -- MND +7
        Neck = 'Promise Badge',             -- MND +5 HP +10
        Ear1 = 'Static Earring',            -- MND +2
        Body = 'Mahatma Hpl.',              -- MND +11 (VIT -8, still net positive)
        Ring1 = 'Aqua Ring',                -- MND +5
        Back = 'Prism Cape',                -- MND +4
        Waist = 'Penitent\'s Rope',         -- MND +5
        Legs = 'Mahatma Slops',             -- MND +8
        Feet = 'Mahatma Pigaches',          -- MND +6
    },
    BlueEnfeeble = {                -- resist check on INT and Blue Magic skill
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Phtm. Tathlum',
        Head = 'Maat\'s Cap',
        Neck = 'Prudence Torque',
        Ear1 = 'Phantom Earring +1',        -- INT +2
        Ear2 = 'Morion Earring +1',         -- INT +2
        Body = 'Magus Jubbah +1',           -- skill +15
        Hands = 'Mahatma Cuffs',
        Ring1 = 'Snow Ring',
        Ring2 = 'Omniscient Ring',
        Back = 'Prism Cape',
        Waist = 'Penitent\'s Rope',
        Legs = 'Mahatma Slops',
        Feet = 'Nashira Crackows',
    },
    BlueBuff = {
        Body = 'Magus Jubbah +1',
    },
    BlueSkill = {                   -- the Jubbah is the only Blue Magic skill gear a Horizon BLU can wear
        Body = 'Magus Jubbah +1',
    },
    Learning = {
        Body = 'Magus Jubbah +1',
        Hands = 'Magus Bazubands +1',
    },

    -- Elemental staves (HQ) and obis. All exist on Horizon, All Jobs. Staves need /blu staff on and cost TP.
    Staff_Fire = { Main = 'Vulcan\'s Staff', Sub = 'displaced' },
    Staff_Ice = { Main = 'Aquilo\'s Staff', Sub = 'displaced' },
    Staff_Wind = { Main = 'Auster\'s Staff', Sub = 'displaced' },
    Staff_Earth = { Main = 'Terra\'s Staff', Sub = 'displaced' },
    Staff_Thunder = { Main = 'Jupiter\'s Staff', Sub = 'displaced' },
    Staff_Water = { Main = 'Neptune\'s Staff', Sub = 'displaced' },
    Staff_Light = { Main = 'Apollo\'s Staff', Sub = 'displaced' },
    Staff_Dark = { Main = 'Pluto\'s Staff', Sub = 'displaced' },
    Obi_Fire = { Waist = 'Karin Obi' },
    Obi_Ice = { Waist = 'Hyorin Obi' },
    Obi_Wind = { Waist = 'Furin Obi' },
    Obi_Earth = { Waist = 'Dorin Obi' },
    Obi_Thunder = { Waist = 'Rairin Obi' },
    Obi_Water = { Waist = 'Suirin Obi' },
    Obi_Light = { Waist = 'Korin Obi' },
    Obi_Dark = { Waist = 'Anrin Obi' },
}
profile.Sets = sets

-- ---------------------------------------------------------------------------------------------------------------
-- Blue magic data, from LandSandBoat spell scripts (HorizonXI's base). kind: phys mag breath drain cure enf buff.
-- mods: WSC stats in weight order. hits: number of hits. tp: what TP changes under Chain Affinity
-- (dmg acc atk crit dur eff). dstat: the stat compared against the target for magical spells.
-- Full table with fTP and percentages: docs/blue-magic-75.md in this repo.
-- ---------------------------------------------------------------------------------------------------------------
local BlueMagic = {
    -- physical
    ['Foot Kick']           = { kind = 'phys', mods = { 'STR', 'DEX' }, hits = 1, tp = 'crit' },
    ['Power Attack']        = { kind = 'phys', mods = { 'STR', 'VIT' }, hits = 1, tp = 'crit' },
    ['Sprout Smack']        = { kind = 'phys', mods = { 'VIT' },        hits = 1, tp = 'dur' },
    ['Wild Oats']           = { kind = 'phys', mods = { 'AGI' },        hits = 1, tp = 'dur' },
    ['Queasyshroom']        = { kind = 'phys', mods = { 'INT' },        hits = 1, tp = 'dur' },
    ['Battle Dance']        = { kind = 'phys', mods = { 'STR' },        hits = 1, tp = 'dur' },
    ['Feather Storm']       = { kind = 'phys', mods = { 'AGI' },        hits = 1, tp = 'dur' },
    ['Head Butt']           = { kind = 'phys', mods = { 'STR', 'INT' }, hits = 1, tp = 'dmg' },
    ['Helldive']            = { kind = 'phys', mods = { 'AGI' },        hits = 1, tp = 'dmg' },
    ['Bludgeon']            = { kind = 'phys', mods = { 'CHR' },        hits = 3, tp = 'acc' },
    ['Claw Cyclone']        = { kind = 'phys', mods = { 'DEX' },        hits = 2, tp = 'atk' },
    ['Screwdriver']         = { kind = 'phys', mods = { 'STR', 'MND' }, hits = 1, tp = 'crit' },
    ['Vanity Dive']         = { kind = 'phys', mods = { 'STR' },        hits = 1, tp = 'dmg' }, -- Horizon lv28; modifiers unverified, not in LSB base
    ['Grand Slam']          = { kind = 'phys', mods = { 'VIT' },        hits = 1, tp = 'atk' },
    ['Empty Thrash']        = { kind = 'phys', mods = { 'STR' },        hits = 1, tp = 'acc' }, -- Horizon lv34
    ['Smite of Rage']       = { kind = 'phys', mods = { 'STR', 'DEX' }, hits = 1, tp = 'dmg' },
    ['Pinecone Bomb']       = { kind = 'phys', mods = { 'STR', 'AGI' }, hits = 1, tp = 'dur' },
    ['Jet Stream']          = { kind = 'phys', mods = { 'AGI' },        hits = 3, tp = 'acc' },
    ['Uppercut']            = { kind = 'phys', mods = { 'STR' },        hits = 1, tp = 'atk' },
    ['Terror Touch']        = { kind = 'phys', mods = { 'DEX', 'INT' }, hits = 1, tp = 'acc' },
    ['Mandibular Bite']     = { kind = 'phys', mods = { 'STR', 'INT' }, hits = 1, tp = 'atk' },
    ['Sickle Slash']        = { kind = 'phys', mods = { 'DEX' },        hits = 1, tp = 'crit' },
    ['Quadratic Continuum'] = { kind = 'phys', mods = { 'STR', 'VIT' }, hits = 4, tp = 'dmg' }, -- Horizon lv54; in-game name may read "Quad. Continuum"
    ['Quad. Continuum']     = { kind = 'phys', mods = { 'STR', 'VIT' }, hits = 4, tp = 'dmg' },
    ['Death Scissors']      = { kind = 'phys', mods = { 'STR' },        hits = 1, tp = 'dmg' },
    ['Dimensional Death']   = { kind = 'phys', mods = { 'STR' },        hits = 1, tp = 'atk' },
    ['Body Slam']           = { kind = 'phys', mods = { 'VIT' },        hits = 1, tp = 'atk' },
    ['Frenetic Rip']        = { kind = 'phys', mods = { 'STR', 'DEX' }, hits = 3, tp = 'dmg' },
    ['Frypan']              = { kind = 'phys', mods = { 'STR', 'MND' }, hits = 1, tp = 'acc' },
    ['Hydro Shot']          = { kind = 'phys', mods = { 'AGI' },        hits = 1, tp = 'eff' },
    ['Spinal Cleave']       = { kind = 'phys', mods = { 'STR' },        hits = 1, tp = 'acc' },
    ['Hysteric Barrage']    = { kind = 'phys', mods = { 'DEX' },        hits = 5, tp = 'dmg' },
    ['Tail Slap']           = { kind = 'phys', mods = { 'STR', 'VIT' }, hits = 1, tp = 'atk' },
    ['Cannonball']          = { kind = 'phys', mods = { 'STR', 'VIT' }, hits = 1, tp = 'dmg' },
    ['Disseverment']        = { kind = 'phys', mods = { 'STR', 'DEX' }, hits = 5, tp = 'acc' },
    ['Ram Charge']          = { kind = 'phys', mods = { 'STR', 'MND' }, hits = 1, tp = 'dmg' },
    ['Vertical Cleave']     = { kind = 'phys', mods = { 'STR' },        hits = 1, tp = 'atk' },
    -- magical
    ['Sandspin']            = { kind = 'mag', dstat = 'INT' },
    ['Blastbomb']           = { kind = 'mag', dstat = 'INT' },
    ['Cursed Sphere']       = { kind = 'mag', dstat = 'INT' },
    ['Bomb Toss']           = { kind = 'mag', dstat = 'INT' },
    ['Death Ray']           = { kind = 'mag', dstat = 'INT' },
    ['Mysterious Light']    = { kind = 'mag', dstat = 'CHR' },
    ['Blitzstrahl']         = { kind = 'mag', dstat = 'INT' },
    ['Ice Break']           = { kind = 'mag', dstat = 'INT' },
    ['Self-Destruct']       = { kind = 'mag', dstat = 'INT' },
    ['Eyes On Me']          = { kind = 'mag', dstat = 'CHR' },
    ['Maelstrom']           = { kind = 'mag', dstat = 'INT' },
    ['1000 Needles']        = { kind = 'mag', dstat = 'INT' }, -- fixed 1000 split by targets, only macc matters
    ['Firespit']            = { kind = 'mag', dstat = 'INT' },
    ['Mind Blast']          = { kind = 'mag', dstat = 'MND' },
    ['Magic Hammer']        = { kind = 'mag', dstat = 'MND' },
    -- drains
    ['Blood Drain']         = { kind = 'drain' },
    ['Digest']              = { kind = 'drain' },
    ['MP Drainkiss']        = { kind = 'drain' },
    ['Blood Saber']         = { kind = 'drain' },
    -- breath
    ['Poison Breath']       = { kind = 'breath' },
    ['Magnetite Cloud']     = { kind = 'breath' },
    ['Hecatomb Wave']       = { kind = 'breath' },
    ['Radiant Breath']      = { kind = 'breath' },
    ['Flying Hip Press']    = { kind = 'breath' },
    ['Bad Breath']          = { kind = 'breath' },
    ['Frost Breath']        = { kind = 'breath' },
    ['Heat Breath']         = { kind = 'breath' },
    -- cures
    ['Pollen']              = { kind = 'cure' },
    ['Healing Breeze']      = { kind = 'cure' },
    ['Wild Carrot']         = { kind = 'cure' },
    ['Magic Fruit']         = { kind = 'cure' },
    ['Exuviation']          = { kind = 'cure' },
    -- enfeebles (anything resisted on INT + skill)
    ['Sheep Song']          = { kind = 'enf' },
    ['Soporific']           = { kind = 'enf' },
    ['Chaotic Eye']         = { kind = 'enf' },
    ['Sound Blast']         = { kind = 'enf' },
    ['Blank Gaze']          = { kind = 'enf' },
    ['Venom Shell']         = { kind = 'enf' },
    ['Auroral Drape']       = { kind = 'enf' }, -- Horizon lv42
    ['Stinking Gas']        = { kind = 'enf' },
    ['Awful Eye']           = { kind = 'enf' },
    ['Geist Wall']          = { kind = 'enf' },
    ['Jettatura']           = { kind = 'enf' },
    ['Frightful Roar']      = { kind = 'enf' },
    ['Cold Wave']           = { kind = 'enf' },
    ['Filamented Hold']     = { kind = 'enf' },
    ['Light of Penance']    = { kind = 'enf' },
    ['Feather Tickle']      = { kind = 'enf' },
    ['Voracious Trunk']     = { kind = 'enf' },
    ['Yawn']                = { kind = 'enf' },
    ['Infrasonics']         = { kind = 'enf' },
    ['Sandspray']           = { kind = 'enf' },
    ['Enervation']          = { kind = 'enf' },
    ['Lowing']              = { kind = 'enf' },
    ['Temporal Shift']      = { kind = 'enf' },
    ['Actinic Burst']       = { kind = 'enf' },
    -- buffs
    ['Cocoon']              = { kind = 'buff' },
    ['Metallic Body']       = { kind = 'buff', skill = true },  -- stoneskin power 0.375*skill+12.5
    ['Occultation']         = { kind = 'buff', skill = true },  -- shadows per skill (Horizon: per 75)
    ['Refueling']           = { kind = 'buff' },
    ['Winds of Promyvion']  = { kind = 'buff' },
    ['Winds of Promy.']     = { kind = 'buff' },
    ['Feather Barrier']     = { kind = 'buff' },
    ['Memento Mori']        = { kind = 'buff' },
    ['Zephyr Mantle']       = { kind = 'buff' },
    ['Diamondhide']         = { kind = 'buff', skill = true },  -- stoneskin power skill/3*2
    ['Warm-Up']             = { kind = 'buff' },
    ['Amplification']       = { kind = 'buff' },
    ['Saline Coat']         = { kind = 'buff' },
    ['Reactor Cool']        = { kind = 'buff' },
    ['Plasma Charge']       = { kind = 'buff' },
    ['Battery Charge']      = { kind = 'buff' },
}

-- gData element names -> set suffix
local ElementSuffix = {
    ['Fire'] = 'Fire', ['Ice'] = 'Ice', ['Wind'] = 'Wind', ['Earth'] = 'Earth',
    ['Thunder'] = 'Thunder', ['Water'] = 'Water', ['Light'] = 'Light', ['Dark'] = 'Dark',
}

-- Gear that stays on if you put it on by hand (warp, reraise, exp bands, crafting). Same idea as Tim's v1
-- LockSafeGear, table driven like Rag's LockableEquipment.
local LockableGear = {
    Main  = T{ 'Warp Cudgel', 'Treat Staff II', 'Trick Staff II', 'Sapara of Trials' },
    Head  = T{ 'Shaded Specs.', 'Reraise Hairpin' },
    Body  = T{ 'Goldsmith\'s Apron' },
    Feet  = T{ 'Powder Boots' },
    Neck  = T{ 'Reraise Gorget' },
    Ear1  = T{ 'Reraise Earring' },
    Ear2  = T{ 'Reraise Earring' },
    Ring1 = T{ 'Chariot Band', 'Emperor Band', 'Empress Band', 'Anniversary Ring' },
    Ring2 = T{ 'Chariot Band', 'Emperor Band', 'Empress Band', 'Anniversary Ring' },
}

local TownZones = T{ 'Jeuno', 'Windurst', 'San d\'Oria', 'Bastok', 'Rabao', 'Tavnazia', 'Whitegate', 'Al Zahbi',
    'Nashmau', 'Selbina', 'Mhaura', 'Norg', 'Kazham' }

-- ---------------------------------------------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------------------------------------------
local function IsTown(area)
    if not area then return false end
    for _, town in ipairs(TownZones) do
        if string.find(area, town, 1, true) then return true end
    end
    return false
end

local function LockSafeGear()
    local eq = gData.GetEquipment()
    for slot, names in pairs(LockableGear) do
        local item = eq[slot]
        if item and names:contains(item.Name) then
            gFunc.Equip(slot, item.Name)
        end
    end
end

-- ---------------------------------------------------------------------------------------------------------------
-- Range and Ammo travel together
-- ---------------------------------------------------------------------------------------------------------------
-- The server (LandSandBoat charutils.cpp, EquipItem) empties the other slot whenever a Range or Ammo item's
-- skill type differs from what is already there: a bow tolerates only arrows, a crossbow only bolts, a gun only
-- bullets. Stat ammo (Happy Egg, Tathlums, Hedgehog Bomb, Bomb Core, Tiphia Sting...) has no skill at all, so
-- it cannot share with ANY ranged weapon, chakram and stat crossbow included. LuAshitacast does not know this:
-- it re-equips the slot the server emptied, the server empties the other one, and the two items flicker forever.
-- Rule for this file: a set that names Range or Ammo names both, the other as 'remove' unless the pair is legal.
-- CheckRangedPairs() runs on load (and on /blu ranged) and prints every set that breaks the rule.
local RangedKind = {
    -- stat ammo, skill none: only with an empty Range slot
    ['happy egg'] = 'stat', ['fortune egg'] = 'stat', ['phtm. tathlum'] = 'stat', ['morion tathlum'] = 'stat',
    ['white tathlum'] = 'stat', ['hedgehog bomb'] = 'stat', ['bomb core'] = 'stat', ['fenrir\'s stone'] = 'stat',
    ['tiphia sting'] = 'stat', ['bibiki seashell'] = 'stat', ['olibanum sachet'] = 'stat', ['fire bomblet'] = 'stat',
    -- throwing weapons (Range slot); only shuriken-type ammo may sit beside them
    ['jr.msk.chakram +2'] = 'throw', ['jr.msk.chakram +1'] = 'throw', ['jr.msk.chakram'] = 'throw',
    ['junior musketeer\'s chakram +2'] = 'throw', ['ungur boomerang'] = 'throw', ['rising sun'] = 'throw',
    ['boomerang'] = 'throw', ['chakram'] = 'throw', ['smart grenade'] = 'throw',
    -- bows, crossbows, guns, instruments (Range slot)
    ['rapid bow'] = 'bow', ['lightning bow'] = 'bow', ['hamayumi'] = 'bow',
    ['thug\'s zamburak'] = 'xbow', ['zamburak'] = 'xbow', ['velocity bow'] = 'xbow', ['othinus\' bow'] = 'xbow',
    ['donderbuss'] = 'gun',
    ['gjallarhorn'] = 'instrument', ['nursemaid\'s harp'] = 'instrument',
    -- real ammunition (Ammo slot)
    ['crossbow bolt'] = 'bolt', ['acid bolt'] = 'bolt', ['sleep bolt'] = 'bolt', ['bloody bolt'] = 'bolt',
    ['holy bolt'] = 'bolt', ['blind bolt'] = 'bolt', ['venom bolt'] = 'bolt',
    ['antlion arrow'] = 'arrow', ['nokizaru shuriken'] = 'shuriken',
}
local RangedPairAllowed = { bow = 'arrow', xbow = 'bolt', gun = 'bullet', throw = 'shuriken' }

local function RangedKindOf(name)
    if type(name) ~= 'string' or name == '' or name == 'remove' or name == 'displaced' then return nil end
    return RangedKind[string.lower(name)] or 'unknown'
end

local function CheckRangedPairs()
    local problems = 0
    for setName, set in pairs(sets) do
        if type(set) == 'table' then
            local r = set.Range or set.range
            local a = set.Ammo or set.ammo
            local msg = nil
            if r ~= nil and a == nil then
                msg = 'names Range but not Ammo; add Ammo = \'remove\''
            elseif a ~= nil and r == nil then
                msg = 'names Ammo but not Range; add Range = \'remove\''
            elseif r ~= nil and a ~= nil then
                local rk, ak = RangedKindOf(r), RangedKindOf(a)
                if rk == 'unknown' then
                    msg = 'Range item "' .. r .. '" is not in RangedKind; add it'
                elseif ak == 'unknown' then
                    msg = 'Ammo item "' .. a .. '" is not in RangedKind; add it'
                elseif rk ~= nil and ak ~= nil and RangedPairAllowed[rk] ~= ak then
                    msg = string.format('%s (%s) and %s (%s) cannot be worn together', r, rk, a, ak)
                end
            end
            if msg ~= nil then
                problems = problems + 1
                gFunc.Message('BLU set ' .. setName .. ': ' .. msg)
            end
        end
    end
    if problems == 0 then
        gFunc.Message('BLU: Range/Ammo pairs OK')
    else
        gFunc.Message('BLU: ' .. problems .. ' Range/Ammo problem(s); fix them or the two slots will flicker')
    end
end

local function EquipStaffAndObi(element)
    local suffix = ElementSuffix[element]
    if suffix == nil then return end
    if Settings.UseStaff then
        gFunc.EquipSet(sets['Staff_' .. suffix])
    end
    local env = gData.GetEnvironment()
    if env.WeatherElement == element or env.DayElement == element then
        gFunc.EquipSet(sets['Obi_' .. suffix])
    end
end

-- Builds the full set for a blue magic spell into the equip buffer.
local function EquipBlueMagic(spell)
    local info = BlueMagic[spell.Name]
    if info == nil then
        gFunc.Message('BLU: unknown spell "' .. spell.Name .. '", using BluePhys')
        info = { kind = 'phys', mods = {}, hits = 1 }
    end

    if info.kind == 'phys' then
        gFunc.EquipSet(sets.BluePhys)
        if (info.hits or 1) >= 2 then gFunc.EquipSet(sets.BluePhys_MultiHit) end
        for _, stat in ipairs(info.mods or {}) do
            gFunc.EquipSet(sets['Mod_' .. stat])
        end
        if info.tp == 'crit' then gFunc.EquipSet(sets.BluePhys_Crit) end
        if Settings.Acc then gFunc.EquipSet(sets.BluePhys_Acc) end
        local tpActive = gData.GetBuffCount('Chain Affinity') > 0 or gData.GetPlayer().TP >= Settings.TpThreshold
        if tpActive and info.tp ~= nil and info.tp ~= 'dur' and info.tp ~= 'eff' then
            gFunc.EquipSet(sets.BluePhys_TP)
            if info.tp == 'acc' then gFunc.EquipSet(sets.BluePhys_TP_Acc) end
        end

    elseif info.kind == 'mag' then
        gFunc.EquipSet(sets.BlueMag)
        gFunc.EquipSet(sets['BlueMag_' .. (info.dstat or 'INT')])
        if Settings.Acc then gFunc.EquipSet(sets.BlueMag_Acc) end
        if gData.GetBuffCount('Burst Affinity') > 0 then gFunc.EquipSet(sets.BlueMag_MB) end
        EquipStaffAndObi(spell.Element)

    elseif info.kind == 'breath' then
        gFunc.EquipSet(sets.MaxHP)
        gFunc.EquipSet(sets.BlueBreath)
        EquipStaffAndObi(spell.Element)

    elseif info.kind == 'drain' then
        gFunc.EquipSet(sets.BlueDrain)
        EquipStaffAndObi('Dark')

    elseif info.kind == 'cure' then
        gFunc.EquipSet(sets.BlueCure)
        if Settings.UseStaff then gFunc.EquipSet(sets.Staff_Light) end

    elseif info.kind == 'enf' then
        gFunc.EquipSet(sets.BlueEnfeeble)
        if Settings.Acc then gFunc.EquipSet(sets.BlueMag_Acc) end
        EquipStaffAndObi(spell.Element)

    elseif info.kind == 'buff' then
        gFunc.EquipSet(sets.BlueBuff)
        if info.skill then gFunc.EquipSet(sets.BlueSkill) end
    end

    if Settings.Learning then gFunc.EquipSet(sets.Learning) end
    LockSafeGear()
end

-- ---------------------------------------------------------------------------------------------------------------
-- Lifecycle and commands
-- ---------------------------------------------------------------------------------------------------------------
profile.OnLoad = function()
    gSettings.AllowAddSet = true
    CheckRangedPairs()
    AshitaCore:GetChatManager():QueueCommand(-1, '/alias /blu /lac fwd')
    ashita.tasks.once(5.0, function()
        AshitaCore:GetChatManager():QueueCommand(1, '/macro book 10')
        AshitaCore:GetChatManager():QueueCommand(1, '/macro set 1')
        AshitaCore:GetChatManager():QueueCommand(1, '/lockstyleset 1')
    end)
end

profile.OnUnload = function()
    AshitaCore:GetChatManager():QueueCommand(-1, '/alias delete /blu')
end

profile.HandleCommand = function(args)
    local cmd = args[1]
    if cmd == 'acc' then
        Settings.Acc = not Settings.Acc
        gFunc.Message('BLU accuracy gear: ' .. tostring(Settings.Acc))
    elseif cmd == 'ranged' then
        CheckRangedPairs()
    elseif cmd == 'learn' then
        Settings.Learning = not Settings.Learning
        gFunc.Message('BLU learning lock: ' .. tostring(Settings.Learning))
    elseif cmd == 'breath' then
        Settings.BreathIdle = not Settings.BreathIdle
        gFunc.Message('BLU max-HP idle: ' .. tostring(Settings.BreathIdle))
    elseif cmd == 'staff' then
        Settings.UseStaff = not Settings.UseStaff
        gFunc.Message('BLU staff swaps: ' .. tostring(Settings.UseStaff))
    elseif cmd == 'fastphys' then
        Settings.FastPhysical = not Settings.FastPhysical
        gFunc.Message('BLU physical set in precast: ' .. tostring(Settings.FastPhysical))
    elseif cmd == 'tp' then
        if tonumber(args[2]) then
            Settings.TpThreshold = tonumber(args[2])
        end
        gFunc.Message('BLU TP threshold: ' .. tostring(Settings.TpThreshold))
    elseif cmd == 'status' or cmd == 'blu' then
        gFunc.Message(string.format('BLU acc=%s learn=%s breathidle=%s staff=%s fastphys=%s tp>=%d',
            tostring(Settings.Acc), tostring(Settings.Learning), tostring(Settings.BreathIdle),
            tostring(Settings.UseStaff), tostring(Settings.FastPhysical), Settings.TpThreshold))
    end
end

-- ---------------------------------------------------------------------------------------------------------------
-- Handlers
-- ---------------------------------------------------------------------------------------------------------------
local restStarted = nil

profile.HandleDefault = function()
    local player = gData.GetPlayer()
    local env = gData.GetEnvironment()

    if player.Status == 'Engaged' then
        gFunc.EquipSet(sets.TP)
        if Settings.Acc then gFunc.EquipSet(sets.TP_Acc) end
    elseif player.Status == 'Resting' then
        if restStarted == nil then restStarted = os.clock() end
        gFunc.EquipSet(sets.Idle)
        if os.clock() - restStarted >= Settings.RestingAfter then
            gFunc.EquipSet(sets.Resting)
        end
    else
        gFunc.EquipSet(sets.Idle)
        if Settings.BreathIdle then gFunc.EquipSet(sets.MaxHP) end
        if IsTown(env.Area) then gFunc.EquipSet(sets.Town) end
    end

    if player.Status ~= 'Resting' then restStarted = nil end

    LockSafeGear()
end

profile.HandlePrecast = function()
    local spell = gData.GetAction()
    -- Physical blue magic casts in 0.5 s. The server reads your stats when the cast completes, and a midcast
    -- swap sent after the spell packet may not land in time. So put the real set on before the packet.
    if Settings.FastPhysical and spell.Skill == 'Blue Magic' and (spell.CastTime or 0) <= 1000 then
        EquipBlueMagic(spell)
        return
    end
    gFunc.EquipSet(sets.Precast)
    LockSafeGear()
end

profile.HandleMidcast = function()
    local spell = gData.GetAction()
    if spell.Skill == 'Blue Magic' then
        EquipBlueMagic(spell)
        return
    end
    -- sub job spells (/WHM cures, /NIN utsusemi, ...)
    if spell.Skill == 'Healing Magic' then
        gFunc.EquipSet(sets.BlueCure)
    end
    LockSafeGear()
end

profile.HandleAbility = function()
    LockSafeGear()
end

profile.HandleItem = function()
    LockSafeGear()
end

profile.HandleWeaponskill = function()
    local action = gData.GetAction()
    gFunc.EquipSet(sets.WS)
    if Settings.Acc then gFunc.EquipSet(sets.WS_Acc) end
    if action.Name == 'Seraph Blade' then
        gFunc.EquipSet(sets.WS_SeraphBlade)
    elseif action.Name == 'Vorpal Blade' then
        gFunc.EquipSet(sets.WS_VorpalBlade)
    elseif action.Name == 'Savage Blade' then
        gFunc.EquipSet(sets.WS_SavageBlade)
    end
    LockSafeGear()
end

return profile
