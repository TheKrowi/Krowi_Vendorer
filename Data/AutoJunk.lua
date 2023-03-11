-- [[ Namespaces ]] --
local addonName, addon = ...;
addon.Data.AutoJunk = {};
local autoJunk = addon.Data.AutoJunk;
local instanceType = addon.Objects.InstanceType;

local cachedExpansion, cachedInstanceType,  cachedInstanceIds;
local function RegisterAutoJunkOptions(expansion, _instanceType, journalInstanceId, instanceId)
    local expansionDisplayName = _G["EXPANSION_NAME" .. expansion];
    expansion = "EXPANSION_NAME" .. expansion;
    local instanceTypeDisplayName;
    if _instanceType == instanceType.Raid then
        instanceTypeDisplayName = addon.L["Raids"];
        _instanceType = "Raids";
    elseif _instanceType == instanceType.Dungeon then
        instanceTypeDisplayName = addon.L["Dungeons"];
        _instanceType = "Dungeons";
    else
        return;
    end
    local instanceDisplayName = addon.GetInstanceInfoName(journalInstanceId);
    KrowiV_RegisterAutoJunkOptions(expansion, expansionDisplayName, _instanceType, instanceTypeDisplayName, instanceId, instanceDisplayName, false);
    cachedExpansion = expansion;
    cachedInstanceType = _instanceType;
    cachedInstanceIds = cachedInstanceIds or {};
    tinsert(cachedInstanceIds, instanceId);
end

local function RegisterDeSelectAllEventOptions()
    KrowiAF_RegisterDeSelectAllEventOptions(cachedExpansion, cachedInstanceType, cachedInstanceIds);
    cachedExpansion, cachedInstanceType, cachedInstanceIds = nil, nil, nil;
end

local qualityCache;
local validations = {
    function(itemId) return KrowiV_SavedData.IgnoredItems[itemId] end,
    function(itemId) return not qualityCache or not addon.Options.db.AutoJunk.Quality[qualityCache + 1] end
};

local cachedInstanceId;
local function AddToJunkIfComply(loot)
    if not loot then -- Other than gold
        return 1;
    end

    local itemId = GetItemInfoInstant(loot);
    if not itemId then
        return 2;
    end

    local quality = (select(3, GetItemInfo(itemId)));
    qualityCache = quality;
    for i, validation in next, validations do
        if validation(itemId) then -- If true, DO NOT mark item as junk
            return 2 + i; -- Osset from the hardcoded ones
        end
    end

    print("I should junk this", itemId, loot);
    KrowiV_SavedData.JunkItems[itemId] = cachedInstanceId;
    return -1;
end


local loadHelper = CreateFrame("Frame");
loadHelper:RegisterEvent("PLAYER_ENTERING_WORLD");

function autoJunk.EnableForInstanceId()
    cachedInstanceId = nil;
    loadHelper:UnregisterEvent("LOOT_READY");

    local _instanceType = (select(2, IsInInstance()));
    if not _instanceType == "party" and not _instanceType == "raid" then
        return;
    end

    cachedInstanceId = (select(8, GetInstanceInfo()));
    if addon.Options.db.AutoJunk.Instances[cachedInstanceId] then
        loadHelper:RegisterEvent("LOOT_READY");
    end
end

function loadHelper:OnEvent(event, arg1, arg2)
    if event == "PLAYER_ENTERING_WORLD" then
        autoJunk.EnableForInstanceId();
    elseif event == "LOOT_READY" then -- GOLD = NIL
        local slots = GetNumLootItems();
        for i = 1, slots, 1 do
            local loot = GetLootSlotLink(i);
            print(AddToJunkIfComply(loot), loot);
        end
    end
end
loadHelper:SetScript("OnEvent", loadHelper.OnEvent);

local function LoadClassic()
    RegisterAutoJunkOptions(0, instanceType.Raid, 741, 409); -- Molten Core
    RegisterAutoJunkOptions(0, instanceType.Raid, 742, 469); -- Blackwing Lair
    RegisterAutoJunkOptions(0, instanceType.Raid, 743, 509); -- Ruins of Ahn'Qiraj
    RegisterAutoJunkOptions(0, instanceType.Raid, 744, 531); -- Temple of Ahn'Qiraj
    RegisterDeSelectAllEventOptions();

    RegisterAutoJunkOptions(0, instanceType.Dungeon, 226, 389); -- Ragefire Chasm
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 63, 36); -- Deadmines
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 240, 43); -- Wailing Caverns
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 64, 33); -- Shadowfang Keep
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 238, 34); -- Stormwind Stockade
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 227, 48); -- Blackfathom Deeps
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 231, 90); -- Gnomeregan
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 234, 47); -- Razorfen Kraul
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 232, 349); -- Maraudon
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 233, 129); -- Razorfen Downs
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 230, 429); -- Dire Maul
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 239, 70); -- Uldaman
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 236, 329); -- Stratholme
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 241, 209); -- Zul'Farrak
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 228, 48); -- Blackrock Depths
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 237, 109); -- The Temple of Atal'hakkar
    RegisterAutoJunkOptions(0, instanceType.Dungeon, 229, 229); -- Lower Blackrock Spire
    RegisterDeSelectAllEventOptions();
end

local function LoadTheBurningCrusade()
    RegisterAutoJunkOptions(1, instanceType.Raid, 745, 532); -- Karazhan
    RegisterAutoJunkOptions(1, instanceType.Raid, 746, 565); -- Gruul's Lair
    RegisterAutoJunkOptions(1, instanceType.Raid, 747, 544); -- Magtheridon's Lair
    RegisterAutoJunkOptions(1, instanceType.Raid, 748, 548); -- Serpentshrine Cavern
    RegisterAutoJunkOptions(1, instanceType.Raid, 749, 550); -- The Eye
    RegisterAutoJunkOptions(1, instanceType.Raid, 750, 534); -- The Battle for Mount Hyjal
    RegisterAutoJunkOptions(1, instanceType.Raid, 751, 564); -- Black Temple
    RegisterAutoJunkOptions(1, instanceType.Raid, 752, 580); -- Sunwell Plateau
    RegisterDeSelectAllEventOptions();

    RegisterAutoJunkOptions(1, instanceType.Dungeon, 248, 543) -- Hellfire Ramparts
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 256, 542) -- The Blood Furnace
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 260, 547) -- The Slave Pens
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 262, 546) -- The Underbog
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 250, 557) -- Mana-Tombs
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 247, 558) -- Auchenai Crypts
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 251, 560) -- Old Hillsbrad Foothills
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 252, 556) -- Sethekk Halls
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 253, 555) -- Shadow Labyrinth
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 259, 540) -- The Shattered Halls
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 257, 553) -- The Botanica
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 258, 554) -- The Mechanar
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 261, 545) -- The Steamvault
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 249, 585) -- Magisters' Terrace
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 255, 269) -- The Black Morass    
    RegisterAutoJunkOptions(1, instanceType.Dungeon, 254, 552) -- The Arcatraz
    RegisterDeSelectAllEventOptions();
end

local function LoadWrathOfTheLichKing()
    RegisterAutoJunkOptions(2, instanceType.Raid, 754, 533) -- Naxxramas
    RegisterAutoJunkOptions(2, instanceType.Raid, 755, 615) -- The Obsidian Sanctum
    RegisterAutoJunkOptions(2, instanceType.Raid, 753, 624) -- Vault of Archavon
    RegisterAutoJunkOptions(2, instanceType.Raid, 756, 616) -- The Eye of Eternity
    RegisterAutoJunkOptions(2, instanceType.Raid, 759, 603) -- Ulduar
    RegisterAutoJunkOptions(2, instanceType.Raid, 757, 649) -- Trial of the Crusader
    RegisterAutoJunkOptions(2, instanceType.Raid, 760, 249) -- Onyxia's Lair
    RegisterAutoJunkOptions(2, instanceType.Raid, 758, 631) -- Icecrown Citadel
    RegisterAutoJunkOptions(2, instanceType.Raid, 761, 724) -- The Ruby Sanctum
    RegisterDeSelectAllEventOptions();

    RegisterAutoJunkOptions(2, instanceType.Dungeon, 285, 574) -- Utgarde Keep
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 281, 576) -- The Nexus
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 272, 601) -- Azjol-Nerub
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 271, 619) -- Ahn'kahet: The Old Kingdom
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 273, 600) -- Drak'Tharon Keep
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 283, 608) -- The Violet Hold
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 274, 604) -- Gundrak
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 277, 599) -- Halls of Stone
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 275, 602) -- Halls of Lightning
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 282, 578) -- The Oculus
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 286, 575) -- Utgarde Pinnacle
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 279, 595) -- The Culling of Stratholme
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 284, 650) -- Trial of the Champion
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 276, 668) -- Halls of Reflection
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 278, 658) -- Pit of Saron
    RegisterAutoJunkOptions(2, instanceType.Dungeon, 280, 632) -- The Forge of Souls
    RegisterDeSelectAllEventOptions();
end

local function LoadCataclysm()
    RegisterAutoJunkOptions(3, instanceType.Raid, 75, 757) -- Baradin Hold
    RegisterAutoJunkOptions(3, instanceType.Raid, 72, 671) -- The Bastion of Twilight
    RegisterAutoJunkOptions(3, instanceType.Raid, 74, 754) -- Throne of the Four Winds
    RegisterAutoJunkOptions(3, instanceType.Raid, 73, 669) -- Blackwing Descent
    RegisterAutoJunkOptions(3, instanceType.Raid, 78, 720) -- Firelands
    RegisterAutoJunkOptions(3, instanceType.Raid, 187, 967) -- Dragon Soul
    RegisterDeSelectAllEventOptions();

    RegisterAutoJunkOptions(3, instanceType.Dungeon, 65, 643) -- Throne of the Tides
    RegisterAutoJunkOptions(3, instanceType.Dungeon, 66, 645) -- Blackrock Caverns
    RegisterAutoJunkOptions(3, instanceType.Dungeon, 67, 725) -- The Stonecore
    RegisterAutoJunkOptions(3, instanceType.Dungeon, 68, 657) -- The Vortex Pinnacle
    RegisterAutoJunkOptions(3, instanceType.Dungeon, 71, 670) -- Grim Batol
    RegisterAutoJunkOptions(3, instanceType.Dungeon, 70, 644) -- Halls of Origination
    RegisterAutoJunkOptions(3, instanceType.Dungeon, 69, 755) -- Lost City of the Tol'vir
    RegisterAutoJunkOptions(3, instanceType.Dungeon, 77, 568) -- Zul'Aman
    RegisterAutoJunkOptions(3, instanceType.Dungeon, 76, 859) -- Zul'Gurub
    RegisterAutoJunkOptions(3, instanceType.Dungeon, 184, 938) -- End Time
    RegisterAutoJunkOptions(3, instanceType.Dungeon, 185, 939) -- Well of Eternity
    RegisterAutoJunkOptions(3, instanceType.Dungeon, 186, 940) -- Hour of Twilight
    RegisterDeSelectAllEventOptions();
end

local function LoadMistsOfPandaria()
    RegisterAutoJunkOptions(4, instanceType.Raid, 317, 1008) -- Mogu'shan Vaults
    RegisterAutoJunkOptions(4, instanceType.Raid, 330, 1009) -- Heart of Fear
    RegisterAutoJunkOptions(4, instanceType.Raid, 320, 996) -- Terrace of Endless Spring
    RegisterAutoJunkOptions(4, instanceType.Raid, 362, 1098) -- Throne of Thunder
    RegisterAutoJunkOptions(4, instanceType.Raid, 369, 1136) -- Siege of Orgrimmar
    RegisterDeSelectAllEventOptions();

    RegisterAutoJunkOptions(4, instanceType.Dungeon, 311, 1001) -- Scarlet Halls
    RegisterAutoJunkOptions(4, instanceType.Dungeon, 316, 1004) -- Scarlet Monastery
    RegisterAutoJunkOptions(4, instanceType.Dungeon, 246, 1007); -- Scholomance
    RegisterAutoJunkOptions(4, instanceType.Dungeon, 302, 961) -- Stormstout Brewery
    RegisterAutoJunkOptions(4, instanceType.Dungeon, 313, 960) -- Temple of the Jade Serpent
    RegisterAutoJunkOptions(4, instanceType.Dungeon, 321, 994) -- Mogu'shan Palace
    RegisterAutoJunkOptions(4, instanceType.Dungeon, 312, 959) -- Shado-Pan Monastery
    RegisterAutoJunkOptions(4, instanceType.Dungeon, 303, 962) -- Gate of the Setting Sun
    RegisterAutoJunkOptions(4, instanceType.Dungeon, 324, 1011) -- Siege of Niuzao Temple
    RegisterDeSelectAllEventOptions();
end

local function LoadWarlordsOfDraenor()
    RegisterAutoJunkOptions(5, instanceType.Raid, 477, 1228) -- Highmaul
    RegisterAutoJunkOptions(5, instanceType.Raid, 457, 1205) -- Blackrock Foundry
    RegisterAutoJunkOptions(5, instanceType.Raid, 669, 1448) -- Hellfire Citadel
    RegisterDeSelectAllEventOptions();

    RegisterAutoJunkOptions(5, instanceType.Dungeon, 385, 1175) -- Bloodmaul Slag Mines
    RegisterAutoJunkOptions(5, instanceType.Dungeon, 558, 1195) -- Iron Docks
    RegisterAutoJunkOptions(5, instanceType.Dungeon, 547, 1182) -- Auchindoun
    RegisterAutoJunkOptions(5, instanceType.Dungeon, 476, 1209) -- Skyreach
    RegisterAutoJunkOptions(5, instanceType.Dungeon, 536, 1208) -- Grimrail Depot
    RegisterAutoJunkOptions(5, instanceType.Dungeon, 537, 1176) -- Shadowmoon Burial Grounds
    RegisterAutoJunkOptions(5, instanceType.Dungeon, 556, 1279) -- The Everbloom
    RegisterAutoJunkOptions(5, instanceType.Dungeon, 559, 1358) -- Upper Blackrock Spire
    RegisterDeSelectAllEventOptions();
end

local function LoadLegion()
    RegisterAutoJunkOptions(6, instanceType.Raid, 768, 1520) -- The Emerald Nightmare
    RegisterAutoJunkOptions(6, instanceType.Raid, 861, 1648) -- Trial of Valor
    RegisterAutoJunkOptions(6, instanceType.Raid, 786, 1530) -- The Nighthold
    RegisterAutoJunkOptions(6, instanceType.Raid, 875, 1676) -- Tomb of Sargeras
    RegisterAutoJunkOptions(6, instanceType.Raid, 946, 1712) -- Antorus, the Burning Thron
    RegisterDeSelectAllEventOptions();

    RegisterAutoJunkOptions(6, instanceType.Dungeon, 716, 1456) -- Eye of Azshara
    RegisterAutoJunkOptions(6, instanceType.Dungeon, 762, 1466) -- Darkheart Thicket
    RegisterAutoJunkOptions(6, instanceType.Dungeon, 767, 1458) -- Neltharion's Lair
    RegisterAutoJunkOptions(6, instanceType.Dungeon, 721, 1477) -- Halls of Valor
    RegisterAutoJunkOptions(6, instanceType.Dungeon, 777, 1544) -- Assault on Violet Hold
    RegisterAutoJunkOptions(6, instanceType.Dungeon, 707, 1493) -- Vault of the Wardens
    RegisterAutoJunkOptions(6, instanceType.Dungeon, 740, 1501) -- Black Rook Hold
    RegisterAutoJunkOptions(6, instanceType.Dungeon, 727, 1492) -- Maw of Souls
    RegisterAutoJunkOptions(6, instanceType.Dungeon, 726, 1516) -- The Arcway
    RegisterAutoJunkOptions(6, instanceType.Dungeon, 800, 1571) -- Court of Stars
    RegisterAutoJunkOptions(6, instanceType.Dungeon, 860, 1651) -- Return to Karazhan
    RegisterAutoJunkOptions(6, instanceType.Dungeon, 900, 1677) -- Cathedral of Eternal Night
    RegisterAutoJunkOptions(6, instanceType.Dungeon, 945, 1753) -- Seat of the Triumvirate
    RegisterDeSelectAllEventOptions();
end

local function LoadBattleForAzeroth()
    RegisterAutoJunkOptions(7, instanceType.Raid, 1031, 1861) -- Uldir
    RegisterAutoJunkOptions(7, instanceType.Raid, 1176, 2070) -- Battle of Dazar'alor
    RegisterAutoJunkOptions(7, instanceType.Raid, 1177, 2096) -- Crucible of Storms
    RegisterAutoJunkOptions(7, instanceType.Raid, 1179, 2164) -- The Eternal Palace
    RegisterAutoJunkOptions(7, instanceType.Raid, 1180, 2217) -- Ny'alotha, the Waking City
    RegisterDeSelectAllEventOptions();

    RegisterAutoJunkOptions(7, instanceType.Dungeon, 1001, 1754) -- Freehold
    RegisterAutoJunkOptions(7, instanceType.Dungeon, 1021, 1862) -- Waycrest Manor
    RegisterAutoJunkOptions(7, instanceType.Dungeon, 1036, 1864) -- Shrine of the Storm
    RegisterAutoJunkOptions(7, instanceType.Dungeon, 968, 1763) -- Atal'Dazar
    RegisterAutoJunkOptions(7, instanceType.Dungeon, 1022, 1841) -- The Underrot
    RegisterAutoJunkOptions(7, instanceType.Dungeon, 1030, 1877) -- Temple of Sethraliss
    RegisterAutoJunkOptions(7, instanceType.Dungeon, 1002, 1771) -- Tol Dagor
    RegisterAutoJunkOptions(7, instanceType.Dungeon, 1012, 1594) -- The MOTHERLODE!!
    RegisterAutoJunkOptions(7, instanceType.Dungeon, 1023, 1822) -- Siege of Boralus
    RegisterAutoJunkOptions(7, instanceType.Dungeon, 1041, 1762) -- Kings' Rest
    RegisterAutoJunkOptions(7, instanceType.Dungeon, 1178, 2097) -- Operation: Mechagon
    RegisterDeSelectAllEventOptions();
end

local function LoadShadowlands()
    RegisterAutoJunkOptions(8, instanceType.Raid, 1190, 2296) -- Castle Nathria
    RegisterAutoJunkOptions(8, instanceType.Raid, 1193, 2450) -- Sanctum of Domination
    RegisterAutoJunkOptions(8, instanceType.Raid, 1195, 2481) -- Sepulcher of the First Ones
    RegisterDeSelectAllEventOptions();

    RegisterAutoJunkOptions(8, instanceType.Dungeon, 1182, 2286) -- The Necrotic Wake
    RegisterAutoJunkOptions(8, instanceType.Dungeon, 1183, 2289) -- Plaguefall
    RegisterAutoJunkOptions(8, instanceType.Dungeon, 1184, 2290) -- Mists of Tirna Scithe
    RegisterAutoJunkOptions(8, instanceType.Dungeon, 1185, 2287) -- Halls of Atonement
    RegisterAutoJunkOptions(8, instanceType.Dungeon, 1186, 2285) -- Spires of Ascension
    RegisterAutoJunkOptions(8, instanceType.Dungeon, 1187, 2293) -- Theater of Pain
    RegisterAutoJunkOptions(8, instanceType.Dungeon, 1188, 2291) -- De Other Side
    RegisterAutoJunkOptions(8, instanceType.Dungeon, 1189, 2284) -- Sanguine Depths
    RegisterAutoJunkOptions(8, instanceType.Dungeon, 1194, 2441) -- Tazavesh, the Veiled Market
    RegisterDeSelectAllEventOptions();
end

local function LoadDragonflight()
    RegisterAutoJunkOptions(9, instanceType.Raid, 1200, 2522) -- Vault of the Incarnates
    RegisterDeSelectAllEventOptions();

    RegisterAutoJunkOptions(9, instanceType.Dungeon, 1202, 2521) -- Ruby Life Pools
    RegisterAutoJunkOptions(9, instanceType.Dungeon, 1199, 2519) -- Neltharus
    RegisterAutoJunkOptions(9, instanceType.Dungeon, 1198, 2516) -- The Nokhud Offensive
    RegisterAutoJunkOptions(9, instanceType.Dungeon, 1196, 2520) -- Brackenhide Hollow
    RegisterAutoJunkOptions(9, instanceType.Dungeon, 1203, 2515) -- The Azure Vault
    RegisterAutoJunkOptions(9, instanceType.Dungeon, 1201, 2526) -- Algeth'ar Academy
    RegisterAutoJunkOptions(9, instanceType.Dungeon, 1204, 2527) -- Halls of Infusion
    RegisterAutoJunkOptions(9, instanceType.Dungeon, 1197, 2451) -- Uldaman: Legacy of Tyr
    RegisterDeSelectAllEventOptions();
end

function autoJunk.Load()
    LoadClassic();
    LoadTheBurningCrusade();
    LoadWrathOfTheLichKing();
    LoadCataclysm();
    LoadMistsOfPandaria();
    LoadWarlordsOfDraenor();
    LoadLegion();
    LoadBattleForAzeroth();
    LoadShadowlands();
    LoadDragonflight();
end