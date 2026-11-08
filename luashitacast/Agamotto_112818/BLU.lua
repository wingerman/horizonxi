-- BLU.lua : Agamotto (Tim Peterson), HorizonXI 75 era
-- v2, 2026-11-07. Rebuilt on Tim's v1 with per-spell gear composition.
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
    Idle = {
        Main = 'Devil Slayer',
        Sub = 'Demon Slayer',
        Range = 'Junior Musketeer\'s Chakram +2',
        Ammo = 'remove',                    -- a ranged weapon locks out stat ammo
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

    -- TP: base set; TP_Acc lays over it when /blu acc is on.
    TP = {
        Range = 'Junior Musketeer\'s Chakram +2',
        Ammo = 'remove',                    -- a ranged weapon locks out stat ammo
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
    TP_Acc = {
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
    WS_Acc = {
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
        Ammo = 'remove',                    -- a ranged weapon locks out stat ammo
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
    BluePhys_Acc = {            -- maximum accuracy (VT/IT)
        Body = 'Scp. Harness +1',
        Waist = 'Life Belt',
    },
    BluePhys_MultiHit = {           -- 2+ hit spells: every hit rolls accuracy, fTP is low, so acc first
        Waist = 'Life Belt',
    },
    BluePhys_Crit = {               -- Foot Kick, Power Attack, Screwdriver, Sickle Slash (35% base crit)
    },
    BluePhys_TP = {                 -- TP is high or Chain Affinity is up: fTP or accuracy now scales with TP.
        Waist = 'Warwolf Belt',     -- For 'acc'-type spells (Disseverment, Bludgeon, Jet Stream, Frypan, Spinal Cleave,
    },                              -- Terror Touch) the TP supplies accuracy, so this overlay can lean STR instead of acc.
    BluePhys_TP_Acc = {             -- 'acc'-type spell with TP active: shift accuracy slots back to STR/modifier pieces
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
    BlueMag_Acc = {                 -- magic accuracy, used when /blu acc is on
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
    BlueSkill = {                   -- Blue Magic skill: Magus Jubbah +15, Immortal's Earring +5, Ksi Sash +3 (Mirage relic does not drop on Horizon yet)
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
