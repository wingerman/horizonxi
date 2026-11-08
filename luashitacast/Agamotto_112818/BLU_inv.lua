-- BLU_inv.lua : Agamotto (Tim Peterson), HorizonXI 75 era. OWNED GEAR EDITION.
-- Same logic as BLU.lua (v2, 2026-11-07); every set filled only from gear Tim owns, per the FindAll cache
-- snapshot in inventory-2026-11-07.md. Each item's Horizon stats were read from horizonffxi.wiki
-- (docs/gear-research/blu-75/owned-agamotto.md). This is the file to load today: /lac load BLU_inv.
-- BLU_bis.lua is the shopping list; the gap between the two is what to farm next.
--
-- What Tim has that shapes this file: full Homam and full Nashira (Limbus), Mirage Keffiyeh, Mirage Jubbah +1
-- and Mirage Charuqs +1 (so BLU relic does drop on Horizon, in Dynamis Beaucedine / Xarcabard / Tavnazia),
-- Magus AF, all eight HQ elemental staves, Hope / Love / Prudence Torques, two Snow, two Triumph, two Spinel
-- and two Toreador's Rings, Sattva Ring (his CoP 8-4 choice, so no Rajas), Brutal + Stealth + Loquacious +
-- Moldavite Earrings, Shadow Mantle, Jester's Cape +1, Swift and Life Belts, Genbu's Shield, Devil + Demon
-- Slayer, and Insect Slayer (Horizon-buffed to Magic Accuracy +11 / MAB +9). Creek M Mitts and Steppe Sash are
-- Tarutaru-male items with HP +65 / HP +60. No obis, no Maat's Cap, no Rajas, no Novio, no Mahatma.
--
-- Weapon rule: no spell set changes Main or Sub. Swapping a weapon zeroes TP, and on Horizon held TP is a
-- large part of physical spell damage. Elemental staves are wired but off (/blu staff) for the same reason.
-- Weapon DMG and attack do not feed physical spells, so Main/Sub are picked for melee TP and their stats.
--
-- Item names are in-game display names from the FindAll cache (Scp. Harness +1, Errant Hpl., Loquac. Earring,
-- Phtm. Tathlum, Ryl.Kgt. Belt, Jr.Msk.Chakram +2). If a swap does not happen, /lac debug on and compare.
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
        Main = 'Devil Slayer',              -- TP weapons stay on at idle
        Sub = 'Demon Slayer',               -- /NIN; Genbu's Shield (PDT -10%, Eva +10) when not /NIN
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Fortune Egg',               -- MP +1%
        Head = 'Homam Zucchetto',
        Neck = 'Peacock Amulet',
        Ear1 = 'Brutal Earring',
        Ear2 = 'Stealth Earring',
        Body = 'Mirage Jubbah +1',          -- Refresh, Acc +12, no headgear block
        Hands = 'Homam Manopolas',
        Ring1 = 'Sattva Ring',              -- Horizon: damage taken -5%
        Ring2 = 'Toreador\'s Ring',
        Back = 'Shadow Mantle',             -- occasionally annuls physical damage
        Waist = 'Swift Belt',
        Legs = 'Blood Cuisses',             -- Movement +12%
        Feet = 'Homam Gambieras',
    },
    Resting = {
        Main = 'Pluto\'s Staff',            -- hMP +10. Costs TP; comment out if holding TP matters more than MP
        Sub = 'displaced',
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Fortune Egg',
        Neck = 'Checkered Scarf',           -- hMP +1
        Ear1 = 'Relaxing Earring',          -- hMP +2
        Ear2 = 'Magnetic Earring',          -- hMP +1, MP +20
        Body = 'Errant Hpl.',               -- hMP +5
        Waist = 'Hierarch Belt',            -- hMP +2, MP +48
        Legs = 'Baron\'s Slops',            -- hMP +1
    },
    Town = {
        -- no Aketon owned; Blood Cuisses in Idle already give movement
    },
    -- Max HP. Breath spells read HP at cast completion; also /blu breath idle mode.
    MaxHP = {
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Happy Egg',                 -- HP +1%
        Head = 'Homam Zucchetto',           -- HP +22 (breath overlay swaps in Mirage Keffiyeh)
        Neck = 'Shield Pendant',            -- HP +20
        Ear1 = 'Crimson Earring',           -- HP +20
        Ear2 = 'Insomnia Earring',          -- HP +15
        Body = 'Homam Corazza',             -- HP +28
        Hands = 'Creek M Mitts',            -- HP +65
        Ring1 = 'Bomb Queen Ring',          -- HP +75
        Ring2 = 'Bloodbead Ring',           -- HP +50
        Back = 'Gigant Mantle',             -- HP +80
        Waist = 'Steppe Sash',              -- HP +60
        Legs = 'Blood Cuisses',             -- HP +27
        Feet = 'Homam Gambieras',           -- HP +31
    },

    -- ---- TP ------------------------------------------------------------------------------------------------
    TP = {
        Main = 'Devil Slayer',
        Sub = 'Demon Slayer',
        Range = 'Jr.Msk.Chakram +2',        -- STR +3 outside own-nation areas
        Ammo = 'remove',                    -- a ranged weapon locks out stat ammo
        Head = 'Homam Zucchetto',
        Neck = 'Peacock Amulet',
        Ear1 = 'Brutal Earring',
        Ear2 = 'Stealth Earring',           -- Dual Wield (Horizon moved it here). Not /NIN: Merman's Earring
        Body = 'Homam Corazza',             -- Acc +15, Triple Attack
        Hands = 'Homam Manopolas',
        Ring1 = 'Toreador\'s Ring',
        Ring2 = 'Triumph Ring',             -- STR +5; TP_Acc swaps the second Toreador's in
        Back = 'Forager\'s Mantle',         -- STR +3 Attack +15
        Waist = 'Swift Belt',               -- Haste +4%
        Legs = 'Homam Cosciales',
        Feet = 'Homam Gambieras',
    },
    TP_Acc = {
        Head = 'Optical Hat',
        Ring2 = 'Toreador\'s Ring',
        Waist = 'Life Belt',
    },

    -- ---- Weaponskills ---------------------------------------------------------------------------------------
    WS = {
        Range = 'Jr.Msk.Chakram +2',        -- STR +3 outside own-nation areas
        Ammo = 'remove',                    -- a ranged weapon locks out stat ammo
        Head = 'Homam Zucchetto',
        Neck = 'Spike Necklace',            -- STR +3 DEX +3
        Ear1 = 'Brutal Earring',
        Ear2 = 'Merman\'s Earring',         -- Attack +6 (attack counts for weaponskills)
        Body = 'Homam Corazza',
        Hands = 'Creek M Mitts',            -- STR +6
        Ring1 = 'Triumph Ring',             -- STR +5
        Ring2 = 'Triumph Ring',             -- STR +5
        Back = 'Forager\'s Mantle',
        Waist = 'Swordbelt +1',             -- Attack +12
        Legs = 'Homam Cosciales',
        Feet = 'Homam Gambieras',
    },
    WS_Acc = {
        Head = 'Optical Hat',
        Neck = 'Peacock Amulet',
        Ring2 = 'Toreador\'s Ring',
        Waist = 'Life Belt',
    },
    WS_SeraphBlade = {          -- MND
        Neck = 'Justice Badge',             -- MND +3 (Spike Necklace is MND -6)
        Body = 'Errant Hpl.',               -- MND +10
        Waist = 'Ryl.Kgt. Belt',            -- all stats +2
    },
    WS_VorpalBlade = {
    },
    WS_SavageBlade = {          -- STR MND
        Waist = 'Ryl.Kgt. Belt',
    },

    Precast = {                             -- fast cast and haste
        Head = 'Homam Zucchetto',
        Ear2 = 'Loquac. Earring',           -- Fast Cast
        Body = 'Nashira Manteel',           -- Haste +3%
        Hands = 'Homam Manopolas',
        Back = 'Warlock\'s Mantle',         -- latent Fast Cast
        Waist = 'Swift Belt',
        Legs = 'Homam Cosciales',           -- Fast Cast + Haste +3%
        Feet = 'Homam Gambieras',
    },

    -- ---- Physical blue magic --------------------------------------------------------------------------------
    -- STR, Blue Magic skill, modifier stats, then accuracy. Attack is ignored by the formula on Horizon.
    -- Ears are left alone so Brutal/Stealth stay on.
    BluePhys = {
        Range = 'Jr.Msk.Chakram +2',        -- STR +3 away from home nation
        Ammo = 'remove',                    -- a ranged weapon locks out stat ammo
        Head = 'Mirage Keffiyeh',           -- Blue Magic skill +5
        Neck = 'Spike Necklace',            -- STR +3 DEX +3 (MND -6: Mod_MND swaps it out)
        Body = 'Magus Jubbah',              -- Blue Magic skill +15, STR +3 DEX +3
        Hands = 'Creek M Mitts',            -- STR +6
        Ring1 = 'Triumph Ring',             -- STR +5
        Ring2 = 'Triumph Ring',             -- STR +5
        Back = 'Forager\'s Mantle',         -- STR +3
        Waist = 'Ryl.Kgt. Belt',            -- all stats +2
        Legs = 'Homam Cosciales',           -- Acc +3
        Feet = 'Homam Gambieras',           -- Acc +6
    },
    BluePhys_Acc = {
        Head = 'Optical Hat',               -- Acc +10
        Neck = 'Peacock Amulet',            -- Acc +10
        Body = 'Homam Corazza',             -- Acc +15, drops the Jubbah's skill: only when hits are missing
        Hands = 'Homam Manopolas',          -- Acc +4
        Ring1 = 'Toreador\'s Ring',         -- Acc +7
        Ring2 = 'Toreador\'s Ring',         -- Acc +7
        Waist = 'Life Belt',                -- Acc +10
    },
    BluePhys_MultiHit = {           -- 2+ hits: accuracy before STR
        Hands = 'Homam Manopolas',
        Ring2 = 'Toreador\'s Ring',
        Waist = 'Life Belt',
    },
    BluePhys_Crit = {               -- crit comes from DEX
        Ring2 = 'Spinel Ring',              -- DEX +4
    },
    BluePhys_TP = {
    },
    BluePhys_TP_Acc = {             -- acc-type spell with TP active: TP supplies accuracy, go back to STR
        Head = 'Mirage Keffiyeh',
        Neck = 'Spike Necklace',
        Body = 'Magus Jubbah',
        Hands = 'Creek M Mitts',
        Ring1 = 'Triumph Ring',
        Ring2 = 'Triumph Ring',
        Waist = 'Ryl.Kgt. Belt',
    },
    Mod_STR = {
    },
    Mod_DEX = {
        Neck = 'Love Torque',               -- DEX +5
        Ring2 = 'Spinel Ring',              -- DEX +4
    },
    Mod_VIT = {
        Waist = 'Steppe Sash',              -- VIT +4
        Legs = 'Magus Shalwar',             -- VIT +3 AGI +3
    },
    Mod_AGI = {
        Neck = 'Hope Torque',               -- AGI +5
        Hands = 'Homam Manopolas',          -- Creek M Mitts are AGI -3
        Waist = 'Scouter\'s Rope',          -- AGI +4 (HP -40)
        Legs = 'Magus Shalwar',             -- AGI +3
        Feet = 'Mirage Charuqs +1',         -- AGI +4 INT +4
    },
    Mod_INT = {
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Phtm. Tathlum',             -- INT +2
        Neck = 'Prudence Torque',           -- INT +5
        Ring2 = 'Snow Ring',                -- INT +5
        Feet = 'Mirage Charuqs +1',         -- INT +4
    },
    Mod_MND = {
        Neck = 'Justice Badge',             -- MND +3, and removes Spike's MND -6
    },
    Mod_CHR = {
        Neck = 'Star Necklace',             -- CHR +3
        Ring2 = 'Angel\'s Ring',            -- CHR +4
        Back = 'Jester\'s Cape +1',         -- CHR +10
    },

    -- ---- Magical blue magic ---------------------------------------------------------------------------------
    BlueMag = {                     -- INT, MAB, magic accuracy
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Phtm. Tathlum',             -- INT +2
        Head = 'Magus Keffiyeh',            -- INT +3 MND +3
        Neck = 'Prudence Torque',           -- INT +5. Uggalepih Pendant (MAB +8 under 51% MP) is the manual swap
        Ear1 = 'Moldavite Earring',         -- MAB +5
        Body = 'Errant Hpl.',               -- INT +10
        Hands = 'Nashira Gages',            -- Magic Accuracy +3
        Ring1 = 'Snow Ring',                -- INT +5
        Ring2 = 'Snow Ring',                -- INT +5
        Waist = 'Ryl.Kgt. Belt',            -- INT +2; an obi would replace it on day/weather
        Legs = 'Nashira Seraweels',         -- Magic Accuracy +3
        Feet = 'Mirage Charuqs +1',         -- INT +4
    },
    BlueMag_INT = {
    },
    BlueMag_MND = {                 -- Mind Blast, Magic Hammer
        Neck = 'Justice Badge',             -- MND +3
    },
    BlueMag_CHR = {                 -- Eyes On Me, Mysterious Light
        Neck = 'Star Necklace',             -- CHR +3
        Ring1 = 'Angel\'s Ring',            -- CHR +4
        Back = 'Jester\'s Cape +1',         -- CHR +10
    },
    BlueMag_Acc = {                 -- acc on: Nashira magic accuracy
        Head = 'Nashira Turban',            -- Magic Accuracy +5
        Feet = 'Nashira Crackows',          -- Magic Accuracy +2
    },
    BlueMag_MB = {                  -- no magic burst gear owned
    },

    -- ---- Breath, drains, cures, enfeebles, buffs ------------------------------------------------------------
    BlueBreath = {                  -- laid over MaxHP
        Head = 'Mirage Keffiyeh',           -- breath damage +10% beats Homam's HP +7 difference
        Ear2 = 'Moldavite Earring',         -- MAB +5 (breath is MAB-scaled on Horizon for now)
    },
    BlueDrain = {                   -- Blood Drain, Digest, MP Drainkiss, Blood Saber: INT, Macc, MAB, skill
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Phtm. Tathlum',
        Head = 'Magus Keffiyeh',
        Neck = 'Prudence Torque',
        Ear1 = 'Moldavite Earring',
        Body = 'Magus Jubbah',              -- skill feeds drains per the Primer
        Hands = 'Nashira Gages',
        Ring1 = 'Snow Ring',
        Ring2 = 'Snow Ring',
        Waist = 'Ryl.Kgt. Belt',
        Legs = 'Nashira Seraweels',
        Feet = 'Mirage Charuqs +1',
    },
    BlueCure = {                    -- 3*MND + VIT
        Head = 'Magus Keffiyeh',            -- MND +3
        Neck = 'Justice Badge',             -- MND +3
        Body = 'Errant Hpl.',               -- MND +10 (VIT -7, still net positive)
        Waist = 'Ryl.Kgt. Belt',            -- MND +2
    },
    BlueEnfeeble = {                -- resist check on INT and Blue Magic skill
        Range = 'remove',                   -- stat ammo needs an empty Range slot (see Range and Ammo below)
        Ammo = 'Phtm. Tathlum',
        Head = 'Magus Keffiyeh',
        Neck = 'Prudence Torque',
        Body = 'Magus Jubbah',              -- skill +15
        Hands = 'Nashira Gages',
        Ring1 = 'Snow Ring',
        Ring2 = 'Snow Ring',
        Waist = 'Ryl.Kgt. Belt',
        Legs = 'Nashira Seraweels',
        Feet = 'Nashira Crackows',
    },
    BlueBuff = {
        Body = 'Magus Jubbah',
    },
    BlueSkill = {                   -- Diamondhide, Metallic Body, Occultation scale with skill
        Head = 'Mirage Keffiyeh',           -- skill +5
        Body = 'Magus Jubbah',              -- skill +15
    },
    Learning = {
        Body = 'Magus Jubbah',
        Hands = 'Magus Bazubands',
    },

    -- Elemental staves (all eight HQ owned). Need /blu staff on and cost TP. No obis owned yet.
    Staff_Fire = { Main = 'Vulcan\'s Staff', Sub = 'displaced' },
    Staff_Ice = { Main = 'Aquilo\'s Staff', Sub = 'displaced' },
    Staff_Wind = { Main = 'Auster\'s Staff', Sub = 'displaced' },
    Staff_Earth = { Main = 'Terra\'s Staff', Sub = 'displaced' },
    Staff_Thunder = { Main = 'Jupiter\'s Staff', Sub = 'displaced' },
    Staff_Water = { Main = 'Neptune\'s Staff', Sub = 'displaced' },
    Staff_Light = { Main = 'Apollo\'s Staff', Sub = 'displaced' },
    Staff_Dark = { Main = 'Pluto\'s Staff', Sub = 'displaced' },
    Obi_Fire = { },
    Obi_Ice = { },
    Obi_Wind = { },
    Obi_Earth = { },
    Obi_Thunder = { },
    Obi_Water = { },
    Obi_Light = { },
    Obi_Dark = { },
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
    Ring1 = T{ 'Chariot Band', 'Emperor Band', 'Empress Band', 'Anniversary Ring', 'Altep Ring', 'Dem Ring', 'Mea Ring', 'Yhoat Ring', 'Tavnazian Ring' },
    Ring2 = T{ 'Chariot Band', 'Emperor Band', 'Empress Band', 'Anniversary Ring', 'Altep Ring', 'Dem Ring', 'Mea Ring', 'Yhoat Ring', 'Tavnazian Ring' },
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
