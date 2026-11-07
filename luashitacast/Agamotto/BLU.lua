local profile = {}

-- [[ Custom State Variables ]] --
local acc_mode = 'Med'      -- Tiers: 'Low', 'Med', 'High'
local is_learning = false   -- Toggles spell learning gear locks
local breath_mode = false   -- Toggles Max HP / Breath Idle mode

-- [[ Town Zones ]] --
local town_zones = {
    'Jeuno', 'Windurst', 'San d\'Oria', 'Bastok',
    'Rabao', 'Tavnazia', 'Whitegate', 'Al Zahbi', 'Nashmau',
    'Selbina', 'Mhaura', 'Norg', 'Kazham',
}

local function is_town(area)
    if not area then return false end
    for _, town in ipairs(town_zones) do
        if string.match(area, town) then return true end
    end
    return false
end

-- [[ Gear Sets ]] --
profile.sets = {
    idle = {
        main = 'Devil Slayer',
        sub = 'Demon Slayer',
        range = 'Junior Musketeer\'s Chakram +2',
        head = '',
        body = 'Vermillion Cloak',
        hands = 'Creek M Mitts',
        legs = 'Blood Cuisses',
        feet = 'Magus Charuqs',
        neck = 'Peacock Amulet',
        waist = 'Swift Belt',
        ear1 = 'Insomnia Earring',
        ear2 = 'Velocity Earring',
        ring1 = 'Toreador\'s Ring',
        ring2 = 'Toreador\'s Ring',
        back = 'Night Cape'
    },

    precast = {},

    engaged_high = {
        range = 'Junior Musketeer\'s Chakram +2',
        head = 'Optical Hat',
        body = 'Scp. Harness +1',
        hands = 'Creek M Mitts',
        legs = 'Magus Shalwar',
        feet = 'Magus Charuqs',
        neck = 'Peacock Amulet',
        waist = 'Swift Belt',
        ear1 = 'Insomnia Earring',
        ear2 = 'Velocity Earring',
        ring1 = 'Toreador\'s Ring',
        ring2 = 'Toreador\'s Ring',
        back = 'Amemet Mantle +1'
    },

    engaged_med = {
        range = 'Junior Musketeer\'s Chakram +2',
        head = 'Optical Hat',
        body = 'Scp. Harness +1',
        hands = 'Creek M Mitts',
        legs = 'Magus Shalwar',
        feet = 'Magus Charuqs',
        neck = 'Peacock Amulet',
        waist = 'Swift Belt',
        ear1 = 'Insomnia Earring',
        ear2 = 'Velocity Earring',
        ring1 = 'Triumph Ring',
        ring2 = 'Triumph Ring',
        back = 'Amemet Mantle +1'
    },

    engaged_low = {
        range = 'Junior Musketeer\'s Chakram +2',
        head = 'Optical Hat',
        body = 'Scp. Harness +1',
        hands = 'Creek M Mitts',
        legs = 'Magus Shalwar',
        feet = 'Wonder Clomps',
        neck = 'Spike Necklace',
        waist = 'Swift Belt',
        ear1 = 'Insomnia Earring',
        ear2 = 'Velocity Earring',
        ring1 = 'Triumph Ring',
        ring2 = 'Triumph Ring',
        back = 'Amemet Mantle +1'
    },

    resting = {
        neck = 'Checkered Scarf',
        ear1 = 'Relaxing Earring',
        legs = 'Baron\'s Slops'
    },

    -- Dedicated Max HP Set used when Breath Mode toggle is ON
    breath_idle = {
        head = 'Magus Keffiyeh',
        neck = 'Checkered Scarf',
        ring1 = 'Saintly Ring',
        ring2 = 'Saintly Ring',
        back = 'Prism Cape',
    },

    ws = {
        ['Seraph Blade'] = {
            neck = 'Justice Badge',
            ring1 = 'Saintly Ring',
            ring2 = 'Saintly Ring',
            back = 'Amemet Mantle +1'
        },
        ['Vorpal Blade'] = {
            head = 'Empress Hairpin',
            neck = 'Spike Necklace',
            ear1 = 'Insomnia Earring',
            ear2 = 'Velocity Earring',
            body = 'Scp. Harness +1',
            hands = 'Creek M Mitts',
            legs = 'Magus Shalwar',
            feet = 'Wonder Clomps',
            ring1 = 'Triumph Ring',
            ring2 = 'Triumph Ring',
            waist = 'Swift Belt',
            back = 'Amemet Mantle +1'
        },
        ['Savage Blade'] = {
            head = 'Optical Hat',
            neck = 'Spike Necklace',
            ear1 = 'Insomnia Earring',
            ear2 = 'Velocity Earring',
            body = 'Scp. Harness +1',
            hands = 'Creek M Mitts',
            legs = 'Magus Shalwar',
            feet = 'Wonder Clomps',
            ring1 = 'Triumph Ring',
            ring2 = 'Triumph Ring',
            waist = 'Warwolf Belt',
            back = 'Amemet Mantle +1'
        }
    },

    blue_magic = {
        physical_high = {
            range = 'Junior Musketeer\'s Chakram +2',
            head = 'Optical Hat',
            body = 'Scp. Harness +1',
            hands = 'Creek M Mitts',
            legs = 'Magus Shalwar',
            neck = 'Peacock Amulet',
            waist = 'Life Belt',
            ring1 = 'Toreador\'s Ring',
            ring2 = 'Toreador\'s Ring',
            back = 'Amemet Mantle +1'
        },
        physical_med = {
            range = 'Junior Musketeer\'s Chakram +2',
            head = 'Optical Hat',
            body = 'Magus Jubbah',
            hands = 'Creek M Mitts',
            legs = 'Magus Shalwar',
            neck = 'Peacock Amulet',
            waist = 'Steppe Sash',
            ring1 = 'Toreador\'s Ring',
            ring2 = 'Toreador\'s Ring',
            back = 'Amemet Mantle +1'
        },
        physical_low = {
            range = 'Junior Musketeer\'s Chakram +2',
            head = 'Optical Hat',
            body = 'Magus Jubbah',
            hands = 'Creek M Mitts',
            legs = 'Magus Shalwar',
            feet = 'Wonder Clomps',
            neck = 'Spike Necklace',
            waist = 'Swordbelt +1',
            ring1 = 'Triumph Ring',
            ring2 = 'Triumph Ring',
            back = 'Amemet Mantle +1'
        },
        magical = {
            head = 'Magus Keffiyeh',
            body = 'Magus Jubbah',
            neck = 'Justice Badge',
            ear1 = 'Morion Earring',
            ear2 = 'Morion Earring',
            ring1 = 'Eremite\'s Ring',
            ring2 = 'Eremite\'s Ring'
        },
        buff = {
            body = 'Magus Jubbah'
        },
        cure = {
            head = 'Magus Keffiyeh',
            body = 'Magus Jubbah',
            neck = 'Justice Badge',
            ring1 = 'Saintly Ring',
            ring2 = 'Saintly Ring'
        }
    },

    town = { body = 'Ducal Aketon' },
    safe = {
        main = 'Warp Cudgel',
        head = 'Shaded Specs.',
        body = 'Goldsmith\'s Apron',
        feet = 'Powder Boots',
        ear1 = 'Reraise Earring',
        ear2 = 'Reraise Earring',
        ring1 = 'Chariot Band',
        ring2 = 'Chariot Band',
    }
}

-- [[ Spell Categories ]] --
local physical_spells = {
    'Bludgeon', 'Smite of Rage', 'Mandibular Bite', 'Sickle Slash',
    'Death Scissors', 'Dimensional Death', 'Quadratic Continuum',
    'Claw Cyclone', 'Foot Kick', 'Sprout Smack', 'Power Attack',
    'Head Butt', 'Battle Dance', 'Feather Storm', 'Jet Stream',
    'Screwdriver', 'Cannonball', 'Disseverment', 'Frenetic Rip'
}

local magical_spells = {
    'Bomb Toss', 'Mystic Boon', 'Cursed Sphere', 'Venom Shell',
    'Maelstrom', 'Awful Eye', 'Firespit', 'Blood Saber', 'Soporific',
    'Regurgitation', 'Eyes On Me', 'Thermal Pulse'
}

local breath_spells = {
    'Heat Breath', 'Radiant Breath', 'Bad Breath', 'Frost Breath',
    'Sand Breath', 'Lightning Breath', 'Flying Hip Press', 'Breath Blast'
}

local buff_spells = {
    'Cocoon', 'Refueling', 'Zephyr Mantle', 'Metallic Body', 'Sheep Song',
    'Blank Gaze', 'Geist Wall', 'Diamondhide', 'Magic Barrier', 'Reactor Cool',
    'Plazmachelys', 'Amplification'
}

local cure_spells = {
    'Pollen', 'Wild Carrot', 'Healing Breeze', 'Magic Fruit'
}

local function contains(t, e)
    for _, v in ipairs(t) do
        if v == e then return true end
    end
    return false
end

-- [[ Helper Functions ]] --
local function LockSafeGear()
    local eq = gData.GetEquipment()
    if eq.Main and (eq.Main.Name == 'Warp Cudgel' or eq.Main.Name == 'Treat Staff II' or eq.Main.Name == 'Sapara of Trials') then
        gFunc.Equip('main', eq.Main.Name)
    end
    if eq.Feet and eq.Feet.Name == 'Powder Boots' then gFunc.Equip('feet', 'Powder Boots') end
    if eq.Ear1 and eq.Ear1.Name == 'Reraise Earring' then gFunc.Equip('ear1', 'Reraise Earring') end
    if eq.Ear2 and eq.Ear2.Name == 'Reraise Earring' then gFunc.Equip('ear2', 'Reraise Earring') end
    if eq.Ring1 and eq.Ring1.Name == 'Chariot Band' then gFunc.Equip('ring1', 'Chariot Band') end
    if eq.Ring2 and eq.Ring2.Name == 'Chariot Band' then gFunc.Equip('ring2', 'Chariot Band') end
end

-- [[ Profile Lifecycle & Commands ]] --
profile.OnLoad = function()
    ashita.tasks.once(5.0, function()
        AshitaCore:GetChatManager():QueueCommand(1, '/macro book 10')
        AshitaCore:GetChatManager():QueueCommand(1, '/macro set 1')
        AshitaCore:GetChatManager():QueueCommand(1, '/lockstyleset 1')
    end)
end

profile.HandleCommand = function(args)
    if args[1] == 'acc' then
        if acc_mode == 'Low' then
            acc_mode = 'Med'
            gFunc.Message('>>> ACCURACY MODE: MEDIUM (EM/T) <<<')
        elseif acc_mode == 'Med' then
            acc_mode = 'High'
            gFunc.Message('>>> ACCURACY MODE: HIGH (VT/IT) <<<')
        else
            acc_mode = 'Low'
            gFunc.Message('>>> ACCURACY MODE: LOW (STR/EP/DC) <<<')
        end
    elseif args[1] == 'learn' then
        is_learning = not is_learning
        if is_learning then
            gFunc.Message('>>> SPELL LEARNING MODE: ON (AF Body/Hands Locked) <<<')
        else
            gFunc.Message('>>> SPELL LEARNING MODE: OFF <<<')
        end
    elseif args[1] == 'breath' then
        breath_mode = not breath_mode
        if breath_mode then
            gFunc.Message('>>> BREATH HP MODE: ON (Max HP Set Locked) <<<')
        else
            gFunc.Message('>>> BREATH HP MODE: OFF <<<')
        end
    end
end

profile.HandleDefault = function()
    local player = gData.GetPlayer()
    local env = gData.GetEnvironment()

    if is_town(env.Area) then
        gFunc.EquipSet(profile.sets.town)
    else
        -- If Breath Mode toggle is active, lock the Max HP set for standing/idle
        if breath_mode then
            gFunc.EquipSet(profile.sets.breath_idle)
        else
            if player.Status == 'Engaged' then
                if acc_mode == 'High' then gFunc.EquipSet(profile.sets.engaged_high)
                elseif acc_mode == 'Med' then gFunc.EquipSet(profile.sets.engaged_med)
                else gFunc.EquipSet(profile.sets.engaged_low) end
            elseif player.Status == 'Resting' then
                gFunc.EquipSet(profile.sets.resting)
            else
                gFunc.EquipSet(profile.sets.idle)
            end
        end
    end
    LockSafeGear()
end

profile.HandlePrecast = function()
    gFunc.EquipSet(profile.sets.precast)
    LockSafeGear()
end

profile.HandleMidcast = function()
    local action = gData.GetAction()

    if action.Skill == 'Blue Magic' then
        if contains(physical_spells, action.Name) then
            if acc_mode == 'High' then gFunc.EquipSet(profile.sets.blue_magic.physical_high)
            elseif acc_mode == 'Med' then gFunc.EquipSet(profile.sets.blue_magic.physical_med)
            else gFunc.EquipSet(profile.sets.blue_magic.physical_low) end
        elseif contains(magical_spells, action.Name) then
            gFunc.EquipSet(profile.sets.blue_magic.magical)
        elseif contains(breath_spells, action.Name) then
            -- Breath spells don't swap to gear midcast (since HP snapshots before cast ends),
            -- but if casted manually while breath_mode is off, we fall back safely to magical or physical midcast
            gFunc.EquipSet(profile.sets.blue_magic.magical)
        elseif contains(cure_spells, action.Name) then
            gFunc.EquipSet(profile.sets.blue_magic.cure)
        elseif contains(buff_spells, action.Name) then
            gFunc.EquipSet(profile.sets.blue_magic.buff)
        else
            gFunc.EquipSet(profile.sets.blue_magic.physical_med)
        end

        if is_learning then
            gFunc.Equip('body', 'Magus Jubbah')
            gFunc.Equip('hands', 'Magus Bazubands')
        end
    end
    LockSafeGear()
end

profile.HandleWeaponskill = function()
    local action = gData.GetAction()
    if profile.sets.ws[action.Name] then
        gFunc.EquipSet(profile.sets.ws[action.Name])
    end
    LockSafeGear()
end

return profile