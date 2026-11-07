-- BLU.lua : Agamotto (Tim Peterson), HorizonXI 75 era
-- v2, 2026-11-07. Rebuilt on Tim's v1 with per-spell gear composition.
--
-- How sets are chosen (Rag's composition idea: a base set, then overlays laid on top):
--   Physical blue magic : BluePhys -> BluePhys_MultiHit -> Mod_<STAT>... -> BluePhys_Crit -> acc tier -> BluePhys_CA
--   Magical blue magic  : BlueMag  -> BlueMag_<INT|MND|CHR> -> BlueMag_Acc (High tier) -> BlueMag_MB (Burst Affinity up) -> staff/obi
--   Breath              : MaxHP -> BlueBreath -> staff/obi
--   Drains              : BlueDrain -> dark staff/obi
--   Cures               : BlueCure -> light staff
--   Enfeebles           : BlueEnfeeble -> BlueMag_Acc (High tier) -> staff/obi
--   Buffs               : BlueBuff (+ BlueSkill for Diamondhide / Metallic Body / Occultation, which scale with skill)
--   Every blue cast     : Learning lock if /blu learn is on, then lockable safe gear re-asserted.
--
-- Why these overlays (from the LandSandBoat source HorizonXI is rebased on, scripts/globals/bluemagic.lua):
--   Physical: D = (floor(skill*0.11)*2+3, capped per spell) + fSTR + WSC. WSC is the spell's stat modifiers
--             (e.g. Disseverment STR 20% DEX 20%) times a level factor. Base attack is 8 + Blue Magic skill + STR.
--             Hit rate is your main-hand accuracy. So: STR/mods for D, attack and accuracy per hit, and Blue
--             Magic skill helps D and attack too. Without Chain Affinity TP does nothing; with it, TP feeds fTP
--             or accuracy depending on the spell and the Chain Affinity overlay goes on.
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
--   acc        cycle accuracy tier Low -> Med -> High (TP, WS and physical blue magic)
--   learn      toggle spell-learning lock (Magus Jubbah + Bazubands on every blue cast)
--   breath     toggle max-HP idle mode (breath spells already swap to max HP midcast; this is for standing around)
--   staff      toggle elemental staff swaps on magical/breath/drain/enfeeble/cure casts (costs TP; off by default)
--   fastphys   toggle equipping the physical set in precast for 0.5 s casts (on by default)
--   status     print current toggles
--
-- Rules that bite: '' in a slot does nothing, 'remove' clears it, 'displaced' marks a slot another item will
-- empty. Set keys are case sensitive. /lac addset rewrites the "local sets = {" block, keep braces balanced.

local profile = {}

-- ---------------------------------------------------------------------------------------------------------------
-- Toggles
-- ---------------------------------------------------------------------------------------------------------------
local AccTiers = { [1] = 'Low', [2] = 'Med', [3] = 'High' }

local Settings = {
    AccTier      = 2,       -- index into AccTiers
    Learning     = false,
    BreathIdle   = false,
    UseStaff     = false,   -- swapping main hand for a staff dumps TP; opt in
    FastPhysical = true,    -- equip physical blue set in precast for sub-second casts
    RestingAfter = 16,      -- seconds of resting before resting gear goes on (lets a regen tick land first)
}

-- ---------------------------------------------------------------------------------------------------------------
-- Sets. Flat so /lac addset works. Overlays only name the slots they change.
-- Fill overlays by dressing in game and running /lac addset <SetName>, or by hand.
-- ---------------------------------------------------------------------------------------------------------------
local sets = {
    Idle = {
        Main = 'Devil Slayer',
        Sub = 'Demon Slayer',
        Range = 'Junior Musketeer\'s Chakram +2',
        Body = 'Vermillion Cloak',
        Hands = 'Creek M Mitts',
        Legs = 'Blood Cuisses',
        Feet = 'Magus Charuqs',
        Neck = 'Peacock Amulet',
        Waist = 'Swift Belt',
        Ear1 = 'Insomnia Earring',
        Ear2 = 'Velocity Earring',
        Ring1 = 'Toreador\'s Ring',
        Ring2 = 'Toreador\'s Ring',
        Back = 'Night Cape',
    },
    -- Vermillion Cloak displaces head. If you idle in something else, add Head here.
    Resting = {
        Neck = 'Checkered Scarf',
        Ear1 = 'Relaxing Earring',
        Legs = 'Baron\'s Slops',
    },
    Town = {
        Body = 'Ducal Aketon',
    },
    -- Max HP. Used by /blu breath idle mode and as the base for breath spells.
    MaxHP = {
        Head = 'Magus Keffiyeh',
        Neck = 'Checkered Scarf',
        Ring1 = 'Saintly Ring',
        Ring2 = 'Saintly Ring',
        Back = 'Prism Cape',
    },

    -- TP: base is the low-accuracy set. Med and High lay over it.
    TP = {
        Range = 'Junior Musketeer\'s Chakram +2',
        Head = 'Optical Hat',
        Body = 'Scp. Harness +1',
        Hands = 'Creek M Mitts',
        Legs = 'Magus Shalwar',
        Feet = 'Wonder Clomps',
        Neck = 'Spike Necklace',
        Waist = 'Swift Belt',
        Ear1 = 'Insomnia Earring',
        Ear2 = 'Velocity Earring',
        Ring1 = 'Triumph Ring',
        Ring2 = 'Triumph Ring',
        Back = 'Amemet Mantle +1',
    },
    TP_MedAcc = {
        Feet = 'Magus Charuqs',
        Neck = 'Peacock Amulet',
    },
    TP_HighAcc = {
        Ring1 = 'Toreador\'s Ring',
        Ring2 = 'Toreador\'s Ring',
    },

    -- Weaponskills
    WS = {
        Head = 'Optical Hat',
        Neck = 'Spike Necklace',
        Ear1 = 'Insomnia Earring',
        Ear2 = 'Velocity Earring',
        Body = 'Scp. Harness +1',
        Hands = 'Creek M Mitts',
        Legs = 'Magus Shalwar',
        Feet = 'Wonder Clomps',
        Ring1 = 'Triumph Ring',
        Ring2 = 'Triumph Ring',
        Waist = 'Warwolf Belt',
        Back = 'Amemet Mantle +1',
    },
    WS_HighAcc = {
        Neck = 'Peacock Amulet',
        Ring1 = 'Toreador\'s Ring',
        Ring2 = 'Toreador\'s Ring',
    },
    WS_SeraphBlade = {          -- MND
        Neck = 'Justice Badge',
        Ring1 = 'Saintly Ring',
        Ring2 = 'Saintly Ring',
    },
    WS_VorpalBlade = {          -- DEX, crit
        Head = 'Empress Hairpin',
        Waist = 'Swift Belt',
    },
    WS_SavageBlade = {          -- STR MND
    },

    Precast = {
        -- Fast cast. Candidates to verify on horizonxi.com/items: Loquac. Earring, Homam pieces.
    },

    -- ---- Physical blue magic --------------------------------------------------------------------------------
    -- Base: attack and accuracy, the per-hit stats. Mirrors Tim's physical_med.
    BluePhys = {
        Range = 'Junior Musketeer\'s Chakram +2',
        Head = 'Optical Hat',
        Body = 'Magus Jubbah',          -- +15 Blue Magic skill: +D and +attack on every physical spell. Scp. Harness +1 is the acc/atk alternative.
        Hands = 'Creek M Mitts',
        Legs = 'Magus Shalwar',
        Neck = 'Peacock Amulet',
        Waist = 'Steppe Sash',
        Ring1 = 'Toreador\'s Ring',
        Ring2 = 'Toreador\'s Ring',
        Back = 'Amemet Mantle +1',
    },
    BluePhys_LowAcc = {             -- STR/attack over accuracy (easy prey)
        Body = 'Scp. Harness +1',
        Feet = 'Wonder Clomps',
        Neck = 'Spike Necklace',
        Waist = 'Swordbelt +1',
        Ring1 = 'Triumph Ring',
        Ring2 = 'Triumph Ring',
    },
    BluePhys_HighAcc = {            -- maximum accuracy (VT/IT)
        Body = 'Scp. Harness +1',
        Waist = 'Life Belt',
    },
    BluePhys_MultiHit = {           -- 2+ hit spells: every hit rolls accuracy, fTP is low, so acc first
        Waist = 'Life Belt',
    },
    BluePhys_Crit = {               -- Foot Kick, Power Attack, Screwdriver, Sickle Slash (35% base crit)
    },
    BluePhys_CA = {                 -- Chain Affinity is up: TP now scales fTP or acc, treat like a WS
        Waist = 'Warwolf Belt',
    },
    -- Stat modifier overlays. Applied in the spell's modifier order, strongest last.
    -- Candidates (verify on Horizon): STR Flame/Sun Ring, Spike Necklace, Warwolf Belt. DEX Spike Necklace.
    -- AGI Drone Earring. INT Morion Earring, Phtm. Tathlum. MND Justice Badge, Saintly Ring.
    -- CHR Bird Whistle, Noble's Ribbon, Hope Ring, Flower Necklace.
    Mod_STR = {
        Neck = 'Spike Necklace',
    },
    Mod_DEX = {
    },
    Mod_VIT = {
    },
    Mod_AGI = {
    },
    Mod_INT = {
    },
    Mod_MND = {
        Neck = 'Justice Badge',
    },
    Mod_CHR = {
    },

    -- ---- Magical blue magic ---------------------------------------------------------------------------------
    BlueMag = {                     -- INT and MAB base
        Head = 'Magus Keffiyeh',
        Body = 'Magus Jubbah',
        Neck = 'Justice Badge',
        Ear1 = 'Morion Earring',
        Ear2 = 'Morion Earring',
        Ring1 = 'Eremite\'s Ring',
        Ring2 = 'Eremite\'s Ring',
    },
    BlueMag_INT = {
    },
    BlueMag_MND = {                 -- Mind Blast, Magic Hammer
        Neck = 'Justice Badge',
        Ring1 = 'Saintly Ring',
        Ring2 = 'Saintly Ring',
    },
    BlueMag_CHR = {                 -- Eyes On Me, Mysterious Light
    },
    BlueMag_Acc = {                 -- magic accuracy, used in High acc tier
    },
    BlueMag_MB = {                  -- Burst Affinity is up
    },

    -- ---- Breath, drains, cures, enfeebles, buffs ------------------------------------------------------------
    BlueBreath = {                  -- max HP. MaxHP set is laid under this automatically.
    },
    BlueDrain = {                   -- Blood Drain, Digest, MP Drainkiss, Blood Saber: INT, magic accuracy, dark
        Ear1 = 'Morion Earring',
        Ear2 = 'Morion Earring',
    },
    BlueCure = {                    -- MND, VIT, cure potency
        Head = 'Magus Keffiyeh',
        Body = 'Magus Jubbah',
        Neck = 'Justice Badge',
        Ring1 = 'Saintly Ring',
        Ring2 = 'Saintly Ring',
    },
    BlueEnfeeble = {                -- INT, magic accuracy, Blue Magic skill
        Body = 'Magus Jubbah',
        Ear1 = 'Morion Earring',
        Ear2 = 'Morion Earring',
    },
    BlueBuff = {
        Body = 'Magus Jubbah',
    },
    BlueSkill = {                   -- Blue Magic skill: Magus Jubbah +15, Immortal's Earring +5, Mirage Keffiyeh +5, Ksi Sash +3
        Body = 'Magus Jubbah',
    },
    Learning = {                    -- locked on every blue cast while /blu learn is on
        Body = 'Magus Jubbah',
        Hands = 'Magus Bazubands',
    },

    -- Elemental staves and obis. Comment out what you do not own. Staves need /blu staff on.
    Staff_Fire = { Main = 'Fire Staff' },
    Staff_Ice = { Main = 'Ice Staff' },
    Staff_Wind = { Main = 'Wind Staff' },
    Staff_Earth = { Main = 'Earth Staff' },
    Staff_Thunder = { Main = 'Thunder Staff' },
    Staff_Water = { Main = 'Water Staff' },
    Staff_Light = { Main = 'Light Staff' },
    Staff_Dark = { Main = 'Dark Staff' },
    Obi_Fire = { },      -- Waist = 'Karin Obi'
    Obi_Ice = { },       -- Waist = 'Hyorin Obi'
    Obi_Wind = { },      -- Waist = 'Furin Obi'
    Obi_Earth = { },     -- Waist = 'Dorin Obi'
    Obi_Thunder = { },   -- Waist = 'Rairin Obi'
    Obi_Water = { },     -- Waist = 'Suirin Obi'
    Obi_Light = { },     -- Waist = 'Korin Obi'
    Obi_Dark = { },      -- Waist = 'Anrin Obi'
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

local function AccTier()
    return AccTiers[Settings.AccTier]
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
        if AccTier() == 'Low' then
            gFunc.EquipSet(sets.BluePhys_LowAcc)
        elseif AccTier() == 'High' then
            gFunc.EquipSet(sets.BluePhys_HighAcc)
        end
        if gData.GetBuffCount('Chain Affinity') > 0 then gFunc.EquipSet(sets.BluePhys_CA) end

    elseif info.kind == 'mag' then
        gFunc.EquipSet(sets.BlueMag)
        gFunc.EquipSet(sets['BlueMag_' .. (info.dstat or 'INT')])
        if AccTier() == 'High' then gFunc.EquipSet(sets.BlueMag_Acc) end
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
        if AccTier() == 'High' then gFunc.EquipSet(sets.BlueMag_Acc) end
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
        Settings.AccTier = Settings.AccTier + 1
        if Settings.AccTier > #AccTiers then Settings.AccTier = 1 end
        gFunc.Message('BLU accuracy: ' .. AccTier())
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
    elseif cmd == 'status' or cmd == 'blu' then
        gFunc.Message(string.format('BLU acc=%s learn=%s breathidle=%s staff=%s fastphys=%s',
            AccTier(), tostring(Settings.Learning), tostring(Settings.BreathIdle),
            tostring(Settings.UseStaff), tostring(Settings.FastPhysical)))
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
        if AccTier() ~= 'Low' then gFunc.EquipSet(sets.TP_MedAcc) end
        if AccTier() == 'High' then gFunc.EquipSet(sets.TP_HighAcc) end
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
    if AccTier() == 'High' then gFunc.EquipSet(sets.WS_HighAcc) end
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
