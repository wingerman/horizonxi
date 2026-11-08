-- TEMPLATE.lua : starter LuAshitacast profile for HorizonXI (75 era)
-- Copy to luashitacast/<Name>_<Id>/<JOB>.lua, then fill sets in game with /lac addset <SetName>.
--
-- How LuAshitacast calls this file:
--   OnLoad / OnUnload      profile loaded or unloaded (job change, /lac reload, /lac unload)
--   HandleDefault          runs continuously while you are not acting: idle, engaged, resting, pet actions
--   HandlePrecast/Midcast  spells: before the packet (fast cast) and after (potency, recast)
--   HandleAbility          job abilities, including Blood Pacts and Ready
--   HandleWeaponskill      weaponskills
--   HandleItem             usable items
--   HandlePreshot/Midshot  ranged attacks
--   HandleCommand(args)    anything typed as /lac fwd <args>
--
-- Rules that bite (learned from the addon source, not the docs):
--   Slot = ''                       does nothing; the slot is left as is
--   Slot = 'remove'                 unequips the slot
--   Slot = 'displaced'              tells LAC another item will empty this slot
--   Range + Ammo                    the server empties one when their skill types differ (bow/arrow, xbow/bolt,
--                                   gun/bullet are the only pairs; stat ammo like Happy Egg pairs with nothing).
--                                   LAC then re-equips it and the two flicker. A set that names either names both,
--                                   the other 'remove'. See Agamotto_112818/BLU_inv.lua CheckRangedPairs().
--   Slot = {'A','B'}                IGNORED unless the set name ends in _Priority (see below)
--   sets.tp vs sets.TP              different keys; typos equip nothing and say nothing
--   /lac addset rewrites the block between "local sets = {" and its closing "};" by text. Keep
--   computed sets out of it, and keep braces balanced.

local profile = {};

-- Item names must match the inventory display exactly, abbreviations included.
local sets = {
    Idle = {
    },
    Resting = {
    },
    TP = {
    },
    TP_Acc = {
    },
    Precast = {
        -- fast cast gear only
    },
    Weaponskill = {
    },
    -- Level sync: suffix _Priority and list options best-first. gFunc.EvaluateLevels picks the
    -- first entry at or below your current level and writes the result to sets.TPLeveled.
    -- TPLeveled_Priority = {
    --     Head = { 'Optical Hat', 'Empress Hairpin' },
    -- },
};
profile.Sets = sets;

-- Toggles the player can flip with commands. Keep state here, never in sets.
local Settings = {
    CurrentLevel = 0,
    TpMode = 'TP',          -- 'TP' or 'TP_Acc'
};

local Towns = T{'Southern San d\'Oria','Northern San d\'Oria','Port San d\'Oria','Chateau d\'Oraguille',
    'Bastok Mines','Bastok Markets','Port Bastok','Metalworks',
    'Windurst Waters','Windurst Walls','Port Windurst','Windurst Woods','Heavens Tower',
    'Ru\'Lude Gardens','Upper Jeuno','Lower Jeuno','Port Jeuno',
    'Rabao','Selbina','Mhaura','Kazham','Norg','Tavnazian Safehold'};

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    -- aliases are global to Ashita; every one made here is deleted in OnUnload
    AshitaCore:GetChatManager():QueueCommand(-1, '/alias /tpmode /lac fwd tpmode');
end

profile.OnUnload = function()
    AshitaCore:GetChatManager():QueueCommand(-1, '/alias delete /tpmode');
end

profile.HandleCommand = function(args)
    if (args[1] == 'tpmode') then
        if (Settings.TpMode == 'TP') then Settings.TpMode = 'TP_Acc'; else Settings.TpMode = 'TP'; end
        gFunc.Message('TP mode: ' .. Settings.TpMode);
    end
end

profile.HandleDefault = function()
    -- pet actions arrive here, not in HandleAbility; handle them first and return
    local petAction = gData.GetPetAction();
    if (petAction ~= nil) then
        return;
    end

    local player = gData.GetPlayer();

    -- re-evaluate _Priority sets whenever level (or sync) changes
    if (player.MainJobSync ~= Settings.CurrentLevel) then
        gFunc.EvaluateLevels(sets, player.MainJobSync);
        Settings.CurrentLevel = player.MainJobSync;
    end

    if (player.Status == 'Engaged') then
        gFunc.EquipSet(sets[Settings.TpMode]);
    elseif (player.Status == 'Resting') then
        gFunc.EquipSet(sets.Resting);
    else
        gFunc.EquipSet(sets.Idle);
    end

    -- later EquipSet calls layer over earlier ones, so overrides go after the base set
    -- if Towns:contains(gData.GetEnvironment().Area) then gFunc.EquipSet(sets.Town); end
end

profile.HandlePrecast = function()
    gFunc.EquipSet(sets.Precast);
end

profile.HandleMidcast = function()
    local spell = gData.GetAction();
    -- branch on spell.Skill ('Enfeebling Magic', 'Elemental Magic', ...) and spell.Name
end

profile.HandleAbility = function()
    local action = gData.GetAction();
end

profile.HandleItem = function()
end

profile.HandlePreshot = function()
end

profile.HandleMidshot = function()
end

profile.HandleWeaponskill = function()
    gFunc.EquipSet(sets.Weaponskill);
end

return profile;
