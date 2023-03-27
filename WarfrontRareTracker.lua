local LibStub = _G.LibStub
local WarfrontRareTracker = LibStub("AceAddon-3.0"):NewAddon("WarfrontRareTracker", "AceBucket-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
--local WarfrontRareTracker = WarfrontRareTracker

local L = LibStub("AceLocale-3.0"):GetLocale("WarfrontRareTracker")
local LDB = LibStub("LibDataBroker-1.1")
local MinimapIcon = LibStub("LibDBIcon-1.0")

local LibQTip = LibStub("LibQTip-1.0")
local HBD = LibStub("HereBeDragons-2.0")
local HBDPins = LibStub("HereBeDragons-Pins-2.0")


-----------------------------------------------
-- Local references to wow's provided functions
-----------------------------------------------
local _G = _G
local floor, mod, format, strsplit, table, tonumber, type, pairs, next = floor, mod, format, strsplit, table, tonumber, type, pairs, next
local UnitName, GetRealmName, IsInInstance, GetItemInfo, GetServerTime, GetUnit, IsQuestFlaggedCompleted, PlayerHasToy, UnitAffectingCombat, UnitCanAttack, UnitCreatureType, UnitFactionGroup, UnitGUID, UnitIsPlayer, UnitIsPVP, UnitLevel = UnitName, GetRealmName, IsInInstance, GetItemInfo, GetServerTime, GetUnit, IsQuestFlaggedCompleted, PlayerHasToy, UnitAffectingCombat, UnitCanAttack, UnitCreatureType, UnitFactionGroup, UnitGUID, UnitIsPlayer, UnitIsPVP, UnitLevel
local C_QuestLog, C_ContributionCollector, C_Map, C_MountJournal, C_PetJournal, C_TransmogCollection, C_Timer, GameTooltip, MouseIsOver = C_QuestLog, C_ContributionCollector, C_Map, C_MountJournal, C_PetJournal, C_TransmogCollection, C_Timer, GameTooltip, MouseIsOver

------------
-- Constants
------------
local PLAYER_WARFRONT_LEVEL = 50
local SECONDS_IN_MIN = 60
local SECONDS_IN_HOUR = SECONDS_IN_MIN * 60
local SECONDS_IN_DAY = SECONDS_IN_HOUR * 24
local SOUND_GOODNEWS = "Interface\\AddOns\\WarfrontRareTracker\\Sounds\\goodnews.ogg"
local SOUND_BADNEWS = "Interface\\AddOns\\WarfrontRareTracker\\Sounds\\badnews.ogg"
local BROKER_ICON_ALLIANCE = "Interface\\Icons\\INV_AllianceWarEffort"
local BROKER_ICON_HORDE = "Interface\\Icons\\INV_HordeWarEffort"
local BROKER_ICON_SHADOWLANDS = "Interface\\Icons\\spell_warlock_demonsoul"
local BROKER_ICON_DRAGONFLIGHT = "Interface\\Icons\\Ability_dragonriding_upwardflap01"
local BROKER_ICON_UNKNOWN = "Interface\\Icons\\ability_ensnare"
local CAVE_TYPE_INFO = "info"
local CAVE_TYPE_CAVE = "cave"
local DB_ZONE_TYPE_UNKNOWN = -1
local DB_ZONE_TYPE_UNTRACKED = 0
local DB_ZONE_TYPE_TRACKED = 1
local DB_ZONE_TYPE_ASSAULT = 2
local WARFRONT_PINNAME = "WarfrontRareTrackerPin"
local FACTION = {
    ALL = "all",
    ALLIANCE = "Alliance",
    HORDE = "Horde",
}
local RARETYPE = {
    GOLIATH = "Goliath",
    ANCIENT = "Ancient",
    WORLDBOSS = "WorldBoss",
    ELITE = "Elite",
    RARE = "Rare",
    UNCOMMON = "Uncommon",
}
local DROPTYPE = {
    ITEM = "Item",
    MOUNT = "Mount",
    PET = "Pet",
    TOY = "Toy",
    QUEST = "Quest",
    BLUEPRINT = "Blueprint",
    GEAR_ONLY = "Gear only",
    ANIMA_ONLY = "Anima Only",
    TRANSMOG = "Transmog",
    UNKNOWN = "Unknown",
    SCROLL = "Scroll",
}
local EXPANSION = {
    BFA = "Battle For Azeroth",
    SHADOWLANDS = "Shadowlands",
    DRAGONFLIGHT = "Dragonflight",
}
local COVENANTS = {
    NONE = 0,
    KYRIAN = 1, -- covenantData: ID=1, name=Kyrian
    VENTHYR  = 2, -- covenantData: ID=2, name=Venthyr
    NIGHTFAE = 3, -- covenantData: ID=3, name=Night Fae
    NECROLORD = 4, -- covenantData: ID=4, name=Necrolord
}

---------
-- Locals
---------
-- GameToolTip
local npcToolTip = CreateFrame("GameTooltip", "__WarfrontRareTracker_ScanTip", nil, "GameTooltipTemplate")
npcToolTip:SetOwner(WorldFrame, "ANCHOR_NONE")
-- Timers
local updateBrokerTimer, newPetAdedTimer
-- Tooltips
local lootTooltip, menuTooltip, warfrontStatusTooltip, worldmapTooltip
local isWarfrontSelectionMenuCollapsed = true
local selectedWarfrontSelectionMenuExpansion = nil
local tooltipBackDrop = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", 
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
    tile = true, tileSize = 16, edgeSize = 16, 
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
    --backdropColor = { r=0.2, g=0.2, b=0.2, a=1 }
}
local assaultType = { unknown = 0, blackEmpire = 1, amathet = 2, aqir = 3, mantid = 4, mogu = 5, all = 6 }
-- Other vars
local isTomTomloaded = false
local autoChangeZone = nil
local autoChangeZoneTimestamp = 0
local manualTimestamp = 0
local playerIsInInstance = false
local currentPlayerMapid = 0
local currentPlayerParentMapid = 0
local currentPlayerLevel = 0
local currentPlayerCovenant = 0
local currentPlayerName = ""
local currentPlayerFaction = ""
local currentPlayerRealm = ""

-- Rare Database
local sortedRareDB = {}
local rareDB = {
    [14] = {
        expansion = EXPANSION.BFA,
        zonename = "Arathi Highlands",
        scenarioname = "Battle for Stromgarde",
        gatheringname = "Contributing",
        hidden = false,
        zoneType = DB_ZONE_TYPE_TRACKED,
        zonephaseID = 1137, -- ArtID
        zoneContributionMapID = 11,
        allianceContributionMapID = 116,
        hordeContributionMapID = 11,
        homeCoord = { 50505050, 30703070 }, -- change both
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 1,
        rares = { -- cave = { coord = { COORD }, note =  "CAVENOTE", infoOnly = true }
            [138122] = { name = L["dooms_howl"], npcid = 138122, questId = { 53002 }, type = RARETYPE.WORLDBOSS, faction = FACTION.ALLIANCE, coord = { 38624096 }, bothphases = false, note = "Alliance only", warning = "Unavailable under Horde Control", loot = { { droptype = DROPTYPE.TOY, itemID = 163828, isKnown = false } } },
            [137374] = { name = L["the_lions_roar"], npcid = 137374, questId = { 53001 }, type = RARETYPE.WORLDBOSS, faction = FACTION.HORDE, coord = { 38624096 }, bothphases = false, note = "Horde only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROPTYPE.TOY, itemID = 163829, isKnown = false } } },
            [141618] = { name = L["cresting_goliath"], npcid = 141618, questId = { 53018, 53531 }, type = RARETYPE.GOLIATH, faction = FACTION.ALL, coord = { 62093158 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 163700, isKnown = false } } },
            [141615] = { name = L["burning_goliath"], npcid = 141615, questId = { 53017, 53506 }, type = RARETYPE.GOLIATH, faction = FACTION.ALL, coord = { 30664478 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 163691, isKnown = false } } },
            [141620] = { name = L["rumbling_goliath"], npcid = 141620, questId = { 53021, 53523 }, type = RARETYPE.GOLIATH, faction = FACTION.ALL, coord = { 29885974 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 163701, isKnown = false } } },
            [141616] = { name = L["thundering_goliath"], npcid = 141616, questId = { 53023, 53527 }, type = RARETYPE.GOLIATH, faction = FACTION.ALL, coord = { 46325212 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 163698, isKnown = false } } },
            [142709] = { name = L["beastrider_kama"], npcid = 142709, questId = { 53083, 53504 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 65347116 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 163644, mountID = 1180, isKnown = false } } },
            [142692] = { name = L["nimar_the_slayer"], npcid = 142692, questId = { 53091, 53517 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 67616086 }, loot = { { droptype = DROPTYPE.MOUNT, itemID = 163706, mountID = 1185, isKnown = false } } },
            [142423] = { name = L["overseer_krix"], npcid = 142423, questId = { 53014, 53518 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 32923847, 27405722 }, cave = { coord = { 33693676, 27385601 } }, bothphases = true, note = "Inside cave", loot = { { droptype = DROPTYPE.MOUNT, itemID = 163646, mountID = 1182, isKnown = false } } },
            [142437] = { name = L["skullripper"], npcid = 142437, questId = { 53022, 53526 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 57154575 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 163645, mountID = 1183, isKnown = false } } },
            [142739] = { name = L["knight_captain_aldrin"], npcid = 142739, questId = { 53088 }, type = RARETYPE.UNCOMMON, faction = FACTION.HORDE, coord = { 48894001 }, bothphases = false, note = "Horde only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROPTYPE.MOUNT, itemID = 163578, mountID = 1173, isKnown = false } } },
            [142741] = { name = L["doomrider_helgrim"], npcid = 142741, questId = { 53085 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALLIANCE, coord = { 53565764 }, bothphases = false, note = "Alliance only", warning = "Unavailable under Horde Control", loot = { { droptype = DROPTYPE.MOUNT, itemID = 163579, mountID = 1174, isKnown = false } } },
            [142508] = { name = L["branchlord_aldrus"], npcid = 142508, questId = { 53013, 53505 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 22602135 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 163650, petID = 143503, speciesID = 2433, isKnown = false } } },
            [142688] = { name = L["darbel_montrose"], npcid = 142688, questId = { 53084, 53507 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 50673675, 50756121 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 163652, petID = 143507, speciesID = 2434, isKnown = false } } },
            [141668] = { name = L["echo_of_myzrael"], npcid = 141668, questId = { 53059, 53508 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 57073506 }, note = "Spawns after defeating all 4 Goliaths.\nAfter defeating the Goliaths there will be\na broadcast when she spawns.", loot = { { droptype = DROPTYPE.PET, itemID = 163677, petID = 143515, speciesID = 2435, isKnown = false } } },
            [142433] = { name = L["fozruk"], npcid = 142433, questId = { 53019, 53510 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 59422773 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 163711, petID = 143627, speciesID = 2440, isKnown = false } } },
            [142716] = { name = L["man_hunter_rog"], npcid = 142716, questId = { 53090, 53515 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 52277674 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 163712, petID = 143628, speciesID = 2441, isKnown = false } } },
            [142435] = { name = L["plaguefeather"], npcid = 142435, questId = { 53020, 53519 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 35606435 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 163690, petID = 143564, speciesID = 2438, isKnown = false } } },
            [142436] = { name = L["ragebeak"], npcid = 142436, questId = { 53016, 53522 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 18412794, 11905220 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 163689, petID = 143563, speciesID = 2437, isKnown = false } } },
            [142438] = { name = L["venomarus"], npcid = 142438, questId = { 53024, 53528 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 56945330 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 163648, petID = 143499, speciesID = 2432, isKnown = false } } },
            [142440] = { name = L["yogursa"], npcid = 142440, questId = { 53015, 53529 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 13063622 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 163684, petID = 143533, speciesID = 2436, isKnown = false } } },
            [142686] = { name = L["foulbelly"], npcid = 142686, questId = { 53086, 53509 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 22305106 }, cave = { coord = { 28804557 } }, bothphases = true, note = "Inside cave", loot = { { droptype = DROPTYPE.TOY, itemID = 163735, isKnown = false } } },
            [142662] = { name = L["geomancer_flintdagger"], npcid = 142662, questId = { 53060, 53511 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 79452939 }, cave = { coord = { 78143689 } }, bothphases = true, note = "Inside cave", loot = { { droptype = DROPTYPE.TOY, itemID = 163713, isKnown = false } } },
            [142725] = { name = L["horrific_apparition"], npcid = 142725, questId = { 53087, 53512 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 26723278, 19446123 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 163736, isKnown = false } } },
            [142112] = { name = L["korgresh_coldrage"], npcid = 142112, questId = { 53058, 53513 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 49178409 }, cave = { coord = { 48007941 } }, bothphases = true, note = "Inside cave", loot = { { droptype = DROPTYPE.TOY, itemID = 163744, isKnown = false } } },
            [142684] = { name = L["kovork"], npcid = 142684, questId = { 53089, 53514 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 25404872 }, cave = { coord = { 28804557 } }, bothphases = true, note = "Inside cave", loot = { { droptype = DROPTYPE.TOY, itemID = 163750, isKnown = false } } },
            [141942] = { name = L["molok_the_crusher"], npcid = 141942, questId = { 53057, 53516 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 47657800 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 163775, isKnown = false } } },
            [142683] = { name = L["ruul_onestone"], npcid = 142683, questId = { 53092, 53524 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 42905660 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 163741, isKnown = false } } },
            [142690] = { name = L["singer"], npcid = 142690, questId = { 53093, 53525 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 51213999, 50595746 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 163738, isKnown = false } } },
            [142682] = { name = L["zalas_witherbark"], npcid = 142682, questId = { 53094, 53530 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 62868112 }, bothphases = true, cave = { coord = { 63277708 } }, note = "Inside cave", loot = { { droptype = DROPTYPE.TOY, itemID = 163745, isKnown = false } } },
        },
    },
    [62] = {
        expansion = EXPANSION.BFA,
        zonename = "Darkshore",
        scenarioname = "Battle for Darkshore",
        gatheringname = "Contributing",
        hidden = false,
        zoneType = DB_ZONE_TYPE_TRACKED,
        zonephaseID = 1176, -- ArtID
        zoneContributionMapID = 118,
        allianceContributionMapID = 117,
        hordeContributionMapID = 118,
        homeCoord = { 48023628, 38033628 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 2,
        rares = {-- cave = { coord = { COORD }, note =  "CAVENOTE", infoOnly = true }
            -- Worldbosses
            [148295] = { name = L["ivus_the_decayed"], npcid = 148295, questId = { 54895 }, type = RARETYPE.WORLDBOSS, faction = FACTION.ALLIANCE, coord = { 41253597 }, bothphases = false, note = "Alliance Only", warning = "Unavailable under Horde Control", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [144946] = { name = L["ivus_the_forest_lord"], npcid = 144946, questId = { 54896 }, type = RARETYPE.WORLDBOSS, faction = FACTION.HORDE, coord = { 41253597 }, bothphases = false, note = "Horde Only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            -- Mounts
            [148787] = { name = L["alash_anir"], npcid = 148787, questId = { 54695, 54696 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 56473076 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 166432, mountID = 1200, isKnown = false } } }, -- Mount: Ashenvale Chimaera
            [148790] = { name = L["frightened_kodo"], npcid = 148790, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 41316547 }, bothphases = true, note = "Friendly Rare. Click it to receive the mount. Only 1 person can click him at a time.", loot = { { droptype = DROPTYPE.MOUNT, itemID = 166433, mountID = 1201, isKnown = false } } }, -- Mount: Frightened Kodo
            [149652] = { name = L["agathe_wyrmwood"], npcid = 149652, questId = { 54883 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALLIANCE, coord = { 49522495 }, bothphases = false, note = "Alliance Only", warning = "Unavailable under Horde Control", loot = { { droptype = DROPTYPE.MOUNT, itemID = 166438, mountID = 1199, isKnown = false } } }, -- Mount: Blackpaw (Caged Bear)
            [149655] = { name = L["croz_bloodrage"], npcid = 149655, questId = { 54886 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALLIANCE, coord = { 50633241 }, bothphases = false, note = "Alliance Only", warning = "Unavailable under Horde Control", loot = { { droptype = DROPTYPE.MOUNT, itemID = 166437, mountID = 1205, isKnown = false } } }, -- Mount: Kaldorei Nightsaber (Captured Kaldorei Nightsaber)
            [147701] = { name = L["moxo_the_beheader"], npcid = 147701, questId = { 54277 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALLIANCE, coord = { 66981881 }, bothphases = true, note = "Alliance Only", loot = { { droptype = DROPTYPE.MOUNT, itemID = 166434, mountID = 1203, isKnown = false } } }, -- Mount: Umber Nightsaber (Captured Umber Nightsaber)
            [149660] = { name = L["blackpaw"], npcid = 149660, questId = { 54890 }, type = RARETYPE.UNCOMMON, faction = FACTION.HORDE, coord = { 49522495 }, bothphases = false, note = "Horde Only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROPTYPE.MOUNT, itemID = 166438, mountID = 1199, isKnown = false } } }, -- Mount: Blackpaw (Caged Bear)
            [149663] = { name = L["shadowclaw"], npcid = 149663, questId = { 54892 }, type = RARETYPE.UNCOMMON, faction = FACTION.HORDE, coord = { 39693341 }, bothphases = false, note = "Horde Only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROPTYPE.MOUNT, itemID = 166437, mountID = 1205, isKnown = false } } }, -- Mount: Kaldorei Nightsaber (Captured Kaldorei Nightsaber)
            [148037] = { name = L["athil_dewfire"], npcid = 148037, questId = { 54431 }, type = RARETYPE.UNCOMMON, faction = FACTION.HORDE, coord = { 41657594 }, bothphases = false, note = "Horde Only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROPTYPE.MOUNT, itemID = 166434, mountID = 1203, isKnown = false }, { droptype = DROPTYPE.PET, itemID = 166449, petID = 148781, speciesID = 2544, isKnown = false } } }, -- Mount: Umber Nightsaber, Pet: Darkshore Sentinel
            -- Pets
            [147260] = { name = L["conflagros"], npcid = 147260, questId = { 54232, 54233 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 39206200 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 166451, petID = 148825, speciesID = 2546, isKnown = false } } }, -- Detective Ray
            [147241] = { name = L["cyclarus"], npcid = 147241, questId = { 54229, 54230 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 43705350 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 166448, petID = 148784, speciesID = 2545, isKnown = false } } }, -- Gust of Cyclarus
            [147240] = { name = L["hydrath"], npcid = 147240, questId = { 54227, 54228 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 52403210 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 166452, petID = 148841, speciesID = 2547, isKnown = false } } }, -- Hydrath Droplet
            [147897] = { name = L["soggoth_the_slitherer"], npcid = 147897, questId = { 54320, 54321 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 40508510 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 166454, petID = 148844, speciesID = 2549, isKnown = false } } }, -- Void Jelly
            [147942] = { name = L["twilight_prophet_graeme"], npcid = 147942, questId = { 54397, 54398 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 40608260 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 166455, petID = 148846, speciesID = 2550, isKnown = false } } }, -- Zur'aj the Depleted
            [147664] = { name = L["zim_kaga"], npcid = 147664, questId = { 54274 }, type = RARETYPE.ELITE, faction = FACTION.ALLIANCE, coord = { 62300980 }, bothphases = true, note = "Alliance Only", loot = { { droptype = DROPTYPE.PET, itemID = 166453, petID = 148843, speciesID = 2548, isKnown = false } } }, -- Everburning Treant
            [149659] = { name = L["orwell_stevenson"], npcid = 149659, questId = { 54889 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALLIANCE, coord = { 39673329 }, bothphases = false, note = "Alliance Only", warning = "Unavailable under Horde Control", loot = { { droptype = DROPTYPE.PET, itemID = 166528, petID = 149205, speciesID = 2563, isKnown = false } } }, -- Nightwreathed Watcher
            [147758] = { name = L["onu"], npcid = 147758, questId = { 54291 }, type = RARETYPE.ELITE, faction = FACTION.HORDE, coord = { 45207490 }, bothphases = true, note = "Horde Only", loot = { { droptype = DROPTYPE.PET, itemID = 166453, petID = 148843, speciesID = 2548, isKnown = false } } }, -- Everburning Treant
            [149662] = { name = L["grimhorn"], npcid = 149662, questId = { 54891 }, type = RARETYPE.UNCOMMON, faction = FACTION.HORDE, coord = { 50603240 }, bothphases = false, note = "Horde Only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROPTYPE.PET, itemID = 166528, petID = 149205, speciesID = 2563, isKnown = false } } },-- Nightwreathed Watcher
            -- Toys
            [148031] = { name = L["gren_tornfur"], npcid = 148031, questId = { 54428, 54429 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 40905640 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 166785, isKnown = false } } },
            [147708] = { name = L["athrikus_narassin"], npcid = 147708, questId = { 54278, 54279 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 58402430 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 166784, isKnown = false } } },
            [148025] = { name = L["commander_ral_esh"], npcid = 148025, questId = { 54426, 54427 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 37907620 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 166787, isKnown = false } } },
            [147845] = { name = L["commander_drald"], npcid = 147845, questId = { 54309 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALLIANCE, coord = { 46408590 }, bothphases = true, note = "Alliance Only", loot = { { droptype = DROPTYPE.TOY, itemID = 166790, isKnown = false } } }, -- Highborne Memento
            [149141] = { name = L["burninator_mark_v"], npcid = 149141, questId = { 54768 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALLIANCE, coord = { 41507640 }, bothphases = false, note = "Alliance Only", warning = "Unavailable under Horde Control", loot = { { droptype = DROPTYPE.TOY, itemID = 166788, isKnown = false }, { droptype = DROPTYPE.PET, itemID = 166449, petID = 148781, speciesID = 2544, isKnown = false } } }, -- Toy: Widdle Twirler: Shredder Blade, Pet: Darkshore Sentinel
            [147435] = { name = L["thelar_moonstrike"], npcid = 147435, questId = { 54252 }, type = RARETYPE.UNCOMMON, faction = FACTION.HORDE, coord = { 62101650 }, bothphases = true, note = "Horde Only", loot = { { droptype = DROPTYPE.TOY, itemID = 166790, isKnown = false } } }, -- Highborne Memento
            [148103] = { name = L["sapper_odette"], npcid = 148103, questId = { 54452 }, type = RARETYPE.UNCOMMON, faction = FACTION.HORDE, coord = { 33008380 }, bothphases = false, note = "Horde Only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROPTYPE.TOY, itemID = 166788, isKnown = false } } }, -- widdle Twirler: Shredder Blade
            -- Unknown
            [147966] = { name = L["aman"], npcid = 147966, questId = { 54405, 54406 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 37808470 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [147970] = { name = L["mrggr_marr"], npcid = 147970, questId = { 54408, 54409 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 35808180 }, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [147332] = { name = L["stonebinder_ssra_vess"], npcid = 147332, questId = { 54247, 54248 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 45505900 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [147261] = { name = L["granokk"], npcid = 147261, questId = { 54234, 54235 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 47995575 }, bothphases = true, cave = { coord = { 47125599 } }, note = "Inside cave", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [149657] = { name = L["madfeather"], npcid = 149657, questId = { 54887, 54888 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 44004820 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [149665] = { name = L["scalefiend"], npcid = 149665, questId = { 54893, 54894 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 47604450 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [147751] = { name = L["shattershard"], npcid = 147751, questId = { 54289, 54290 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 43402930 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [149654] = { name = L["glimmerspine"], npcid = 149654, questId = { 54884, 54885 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 43401960 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [147744] = { name = L["amberclaw"], npcid = 147744, questId = { 54285, 54286 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 57301560 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
        },
    },
    -- Begin New Zones --
    [1355] = {
        expansion = EXPANSION.BFA,
        zonename = "Nazjatar",
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_UNTRACKED,
        zonephaseID = 1186, -- ArtID
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!     116?
        hordeContributionMapID = 0, -- Change!        11?
        homeCoord = { 39965257, 10205301 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 3,
        rares = {-- cave = { coord = { COORD }, note =  "CAVENOTE", infoOnly = true }
            -- Bosses:
            [152566] = { name = "Anemonar", npcid = 152566, questId = { 56281 }, type = RARETYPE.ANCIENT, faction = FACTION.ALL, coord = { 58605320 }, bothphases = true, note = "You need to kite a \"Colossal Sky Ray\" and kill it in front of Anemonar.", loot = { { droptype = DROPTYPE.ITEM, itemID = 170184, isKnown = false } } },
            [152567] = { name = "Kelpwillow", npcid = 152567, questId = { 56287 }, type = RARETYPE.ANCIENT, faction = FACTION.ALL, coord = { 50206950 }, bothphases = true, note = "You need to charm a \"Muck Slug\" by using a \"Prismatic Crystal\" and then bring the charmed Muck Slug to Kelpwillow's foot.", loot = { { droptype = DROPTYPE.ITEM, itemID = 170184, isKnown = false } } },
            [152397] = { name = "Oronu", npcid = 152397, questId = { 56288 }, type = RARETYPE.ANCIENT, faction = FACTION.ALL, coord = { 78102490 }, bothphases = true, note = "You need to bring a \"Drowned Hatchling\" and summon the battle pet on top of him.", loot = { { droptype = DROPTYPE.ITEM, itemID = 170184, isKnown = false } } },
            [152568] = { name = "Urduu", npcid = 152568, questId = { 56299 }, type = RARETYPE.ANCIENT, faction = FACTION.ALL, coord = { 31302940 }, bothphases = true, note = "You need to kite a \"Staghorn Reefwalker\" to Urduu's location, then kill it in front of Urduu.", loot = { { droptype = DROPTYPE.ITEM, itemID = 170184, isKnown = false } } },

            -- Mount Drops:
            [152290] = { name = "Soundless", npcid = 152290, questId = { 56298 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 57605220 }, bothphases = true, note = "Can spawn in multiple parts of Coral Forest on top of the Coral Reefs. (Center to South-East)", loot = { { droptype = DROPTYPE.MOUNT, itemID = 169163, mountID = 1257, isKnown = false } } }, -- Silent Glider
        
            -- Pet Drop:
            [152794] = { name = "Amethyst Spireshell", npcid = 152794, questId = { 56268 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 72203620 }, bothphases = true, note = "Has a random chance to spawn when after killing lots of Mucks and Spireshells all over the island!", loot = { { droptype = DROPTYPE.PET, itemID = 169363, petID = 154836, speciesID = 2697, isKnown = false } } }, -- Amethyst Softshell
            [150191] = { name = "Avarius", npcid = 150191, questId = { 55584 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 36901120 }, bothphases = true, note = "You have to have finish a quest rewarding a \"Brinestone Pickaxe\" in order to summon this Rare.", loot = { { droptype = DROPTYPE.PET, itemID = 169373, petID = 154845, speciesID = 2706, isKnown = false } } }, -- Brinestone Algan
            [152712] = { name = "Blindlight", npcid = 152712, questId = { 56269 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 37378256 }, bothphases = true, cave = { coord = { 39897717 } }, note = "At the very bottom of a cave", loot = { { droptype = DROPTYPE.PET, itemID = 169372, petID = 154821, speciesID = 2682, isKnown = false } } }, -- Necrofin Tadpole
            [149653] = { name = "Carniverous Lasher", npcid = 149653, questId = { 55366 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 54714169 }, bothphases = true, note = "Feed the Lasher 10 bugs that spawn near it after a seed is planted.", loot = { { droptype = DROPTYPE.PET, itemID = 169375, petID = 154847, speciesID = 2708, isKnown = false } } }, -- Coral Lashling
            [152464] = { name = "Caverndark Terror", npcid = 152464, questId = { 56283 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 40790735 }, bothphases = true, cave = { coord = { 42261342 } }, note = "Inside cave",loot = { { droptype = DROPTYPE.PET, itemID = 169356, petID = 154829, speciesID = 2690, isKnown = false } } }, -- Caverndark Nightmare
            [152756] = { name = "Daggertooth Terror", npcid = 152756, questId = { 56271 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 39222821 }, bothphases = true, note = "Spawns in multiple places in the rivers of the island!", loot = { { droptype = DROPTYPE.PET, itemID = 169361, petID = 154834, speciesID = 2695, isKnown = false } } }, -- Daggertooth Frenzy
            [152555] = { name = "Elderspawn Nalaada", npcid = 152555, questId = { 56285 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 51757487 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 169359, petID = 154832, speciesID = 2693, isKnown = false } } }, -- Spawn of Nalaada
            [152448] = { name = "Iridescent Glimmershell", npcid = 152448, questId = { 56286 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 47205500 }, bothphases = true, note = "Spawns in multiple places at the center of the island.", loot = { { droptype = DROPTYPE.PET, itemID = 169352, petID = 154825, speciesID = 2686, isKnown = false } } }, -- Pearlescent Glimmershell
            [152323] = { name = "King Gakula", npcid = 152323, questId = { 55671 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 29442900 }, bothphases = true, note = "Click 100 Bloodfin Tadpoles  to shoo them. Every 25 Tadpoles \"King Gakula\" will yell something and after the 4th yell he becomes atackable.", loot = { { droptype = DROPTYPE.PET, itemID = 169371, petID = 154820, speciesID = 2681, isKnown = false } } }, -- Murgle
            [144644] = { name = "Mirecrawler", npcid = 144644, questId = { 56274 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 37201320 }, bothphases = true, note = "Spawns litterly everywhere on the island after killing lots of Mucks and Spireshells!", loot = { { droptype = DROPTYPE.PET, itemID = 169366, petID = 154839, speciesID = 2700, isKnown = false } } }, -- Wriggler
            [152465] = { name = "Needlespine", npcid = 152465, questId = { 56275 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 45602560 }, bothphases = true, note = "Spawns in multiple places at the northern side of the island!", loot = { { droptype = DROPTYPE.PET, itemID = 169355, petID = 154828, speciesID = 2689, isKnown = false } } }, -- Chitterspine Needler
            [152681] = { name = "Prince Typhonus", npcid = 152681, questId = { 56289 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = {  42728740 }, bothphases = true, cave = { coord = { 43488427 }, caveNote = "Path to: Prince Typhonus" }, loot = { { droptype = DROPTYPE.PET, itemID = 169367, petID = 154840, speciesID = 2701, isKnown = false } } }, -- Seafury
            [152682] = { name = "Prince Vortran", npcid = 152682, questId = { 56290 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 42807480 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 169368, petID = 154841, speciesID = 2702, isKnown = false } } }, -- Stormwrath
            [150583] = { name = "Rockweed Shambler", npcid = 150583, questId = { 56291 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 62405950 }, bothphases = true, note = "Has a random chance to spawn after killing Wayward Algans and Lost Algans.", loot = { { droptype = DROPTYPE.PET, itemID = 169374, petID = 154846, speciesID = 2707, isKnown = false } } }, -- Budding Algan
            [151870] = { name = "Sandcastle", npcid = 151870, questId = { 56276 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 78003280 }, bothphases = true, note = "Has a random chance to spawn when using Scrying Stone or opening Glimmering Chest all over the island.", loot = { { droptype = DROPTYPE.PET, itemID = 169369, petID = 154842, speciesID = 2703, isKnown = false } } }, -- Sandkeep
            [152795] = { name = "Sandclaw Stoneshell", npcid = 152795, questId = { 56277 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 73504584 }, bothphases = true, note = "Spawns in multiple places at the center and eastern side of the island, inside 'Ruined Temples'.", loot = { { droptype = DROPTYPE.PET, itemID = 169350, petID = 154823, speciesID = 2684, isKnown = false } } }, -- Glittering Diamondshell
            [152548] = { name = "Scale Matriarch Gratinax", npcid = 152548, questId = { 56292 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 36104120 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 169370, petID = 154843, speciesID = 2704, isKnown = false } } }, -- Scalebrood Hydra
            [152545] = { name = "Scale Matriarch Vynara", npcid = 152545, questId = { 56293 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 27293716 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 169370, petID = 154843, speciesID = 2704, isKnown = false } } }, -- Scalebrood Hydra
            [152553] = { name = "Scale Matriarch Zodia", npcid = 152553, questId = { 56294 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 28774669 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 169370, petID = 154843, speciesID = 2704, isKnown = false } } }, -- Scalebrood Hydra
            [150468] = { name = "Vor'koth", npcid = 150468, questId = { 55603 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 48352411 }, bothphases = true, note = "Toss some 'Chum' into the \"Eel Infested Waters\" to have a chance of summoning this Rare.", loot = { { droptype = DROPTYPE.PET, itemID = 169376, petID = 154848, speciesID = 2709, isKnown = false } } }, -- Skittering Eel
        
            -- Toy Drop:
            [152552] = { name = "Shassera", npcid = 152552, questId = { 56295 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 62740809 }, bothphases = true, cave = { coord = { 63081189 } }, loot = { { droptype = DROPTYPE.TOY, itemID = 170187, isKnown = false } } },
            [154148] = { name = "Tidemistress Leth'sindra", npcid = 154148, questId = { 56106 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 67152325 }, bothphases = true, note = "To summon Tidemistress Leth'sindra you need to click 4 eggs in the vacinity which are on a cooldown timer.", loot = { { droptype = DROPTYPE.TOY, itemID = 170196, isKnown = false } } },

            -- Gear Only:
            [152415] = { name = "Alga the Eyeless", npcid = 152415, questId = { 56279 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 52404200 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [152416] = { name = "Allseer Oma'kil", npcid = 152416, questId = { 56280 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 65433921 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Also Quest 56603?. could be horde of other mob!
            [152291] = { name = "Deepglider", npcid = 152291, questId = { 56272 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 56204360 }, bothphases = true, note = "Spawns in multiple places south of Azsh'ari Terrace. mostly in Coral Forest.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [152414] = { name = "Elder Unu", npcid = 152414, questId = { 56284 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 63803260 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [153658] = { name = "Shiz'narasz the Consumer", npcid = 153658, questId = { 56296 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 37801440 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [153898] = { name = "Tidelord Aquatus", npcid = 153898, questId = { 56122 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 62402960 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [153928] = { name = "Tidelord Dispersius", npcid = 153928, questId = { 56123 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 57602600 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [151719] = { name = "Voice in the Deeps", npcid = 151719, questId = { 56300 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 67603460 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },

            -- Item Only:
            [152561] = { name = "Banescale the Packfather", npcid = 152561, questId = { 56282 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 73995395 }, bothphases = true, note = "Has a chance to spawn after killing Siltstalker the Packmother.", loot = { { droptype = DROPTYPE.ITEM, itemID = 170179, isKnown = false } } }, -- Snapdragon Scent Gland
            [152556] = { name = "Chasm-Haunter", npcid = 152556, questId = { 56270 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 49008800 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 167077, isKnown = false } } },
            [152553] = { name = "Garnetscale", npcid = 152553, questId = { 56273 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 36003960 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 170180, isKnown = false } } }, -- Razorshell
            [152359] = { name = "Siltstalker the Packmother", npcid = 152359, questId = { 56297 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 71695489 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 170179, isKnown = false } } }, -- Snapdragon Scent Gland
            [152360] = { name = "Toxigore the Alpha", npcid = 152360, questId = { 56278 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 67804620 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 170179, isKnown = false } } }, -- Snapdragon Scent Gland, Has 3 spawn coords: 64804640, 67804620, 65205020

            -- Untrackable:
            [153309] = { name = "Alzana, Arrow of Thunder", npcid = 153309, questId = { -1 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 61202440 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- questId = 55887
            [153301] = { name = "Shirakess Starseeker", npcid = 153301, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 33203920 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- questId = 55899

            [153314] = { name = "Aldrantiss", npcid = 153314, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 60401440 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [153299] = { name = "Bonebreaker Szun", npcid = 153299, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 63805700 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [155811] = { name = "Commander Minzera", npcid = 155811, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 33402940 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [153302] = { name = "Glacier Mage Zhiela", npcid = 153302, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 43004240 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [152736] = { name = "Guardian Tannin", npcid = 152736, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 83603740 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [153300] = { name = "Iron Zoko", npcid = 153300, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 42804300 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [153312] = { name = "Kyx'zhul the Deepspeaker", npcid = 153312, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 41402400 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [152729] = { name = "Moon Priestess Liara", npcid = 152729, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 83403300 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [153310] = { name = "Qalina, Spear of Ice", npcid = 153310, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 61801220 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [153296] = { name = "Shalan'ali Stormtongue", npcid = 153296, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 33204000 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [153311] = { name = "Slitherblade Azanz", npcid = 153311, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 33403020 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [155836] = { name = "Theurgist Nitara", npcid = 155836, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 49406580 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [153304] = { name = "Undana Frostbarb", npcid = 153304, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 68203300 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [153303] = { name = "Voidblade Kassar", npcid = 153303, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 33603020 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [153305] = { name = "Zanj'ir Brutalizer", npcid = 153305, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 68403340 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
        },
    },
    [1462] = {-- cave = { coord = { COORD }, note =  "CAVENOTE", infoOnly = true }
        expansion = EXPANSION.BFA,
        zonename = "Mechagon",
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_UNTRACKED,
        zonephaseID = 1276, -- ArtID
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!     116?
        hordeContributionMapID = 0, -- Change!        11?
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 4,
        rares = {
            -- Mount Drops:
            [151934] = { name = "Arachnoid Harvester", npcid = 151934, questId = { 55512 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 51604160 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 168823, mountID = 1229, isKnown = false } } },-- mountID
            [152182] = { name = "Rustfeather", npcid = 152182, questId = { 55811 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 65877880 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 168370, mountID = 1248, isKnown = false } } }, -- Mount: Junkheap Drifter
            
            -- Pet Drops:
            [150394] = { name = "Armored Vaultbot", npcid = 150394, questId = { 55546 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 57564801 }, bothphases = true, cave = { coord = { 63123921 }, caveNote = "Kite \"Armored Vaultbot\" here to get a chance for a drop!\nYou can also unlock your loot by using a \"Armored Vaultbot Key\" on the corpse of the Rare without having to kite him.", note="Only drops the pet if kited to the Robot Cruncher Zapper at Bondo's yard or by using a \"Armored Vaultbot Key\".", infoOnly = true }, loot = { { droptype = DROPTYPE.PET, itemID = 170072, petID = 155829, speciesID = 2766, isKnown = false }, { droptype = DROPTYPE.BLUEPRINT, itemID = 167843, checkId = 55058, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 167796, checkId = 55455, isKnown = false } } }, -- pet: Snowsoft Nibbler, Blueprint: Vaultbot Key, Paint Vial: Mechagon Gold
            [152001] = { name = "Bonepicker", npcid = 152001, questId = { 55537 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 65202320 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 169392, petID = 154893, speciesID = 2719, isKnown = false } } }, -- Pet: Bonebiter
            [151933] = { name = "Malfunctioning Beastbot", npcid = 151933, questId = { 55544 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 61004120 }, bothphases = true, note = "Requires \"Beastbot Powerpack\" to activate.", loot = { { droptype = DROPTYPE.PET, itemID = 169382, petID = 154854, speciesID = 2715, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 169848, isKnown = false } } },  -- Pet: Lost Robogrip
            [151672] = { name = "Mecharantula", npcid = 151672, questId = { 55386 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 86801940 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 169393, petID = 154894, speciesID = 2720, isKnown = false } } }, -- Pet: Arachnoid Skitterbot
            [152113] = { name = "The Kleptoboss", npcid = 152113, questId = { 55858 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 68865435 }, bothphases = true, cave = { coord = { 68384814 } }, note = "Inside cave. Only available when Drill Rigs are up as a daily Construction Project. Drill Rig DR-CC88.", loot = { { droptype = DROPTYPE.PET, itemID = 169886, petID = 155600, speciesID = 2753, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 169691, checkId = 56518, isKnown = false } } }, -- Pet: Spraybot 0D, Vinyl: Depths of Ulduar

            -- Toy Drops:
            [152007] = { name = "Killsaw", npcid = 152007, questId = { 55369 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 43404900 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 167931, isKnown = false } } }, -- Mechagonian Sawblades
            [154225] = { name = "The Rusty Prince", npcid = 154225, questId = { 56182 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 58305690 }, bothphases = true, note = "Only available in the alternate future of Mechagon. Accept the daily quest \"The Other Place\" in Rustbolt or use \"Personal Time Displacer\" to displace you in time.", loot = { { droptype = DROPTYPE.TOY, itemID = 169347, isKnown = false } } }, -- Judgment of Mechagon

            -- Gear Only:
            [155060] = { name = "The Doppel Ganger", npcid = 155060, questId = { 55623 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 80902020 }, bothphases = true, note = "Requires 3 pieces of \"Pressure Relief Valve\" from the quest \"Cogfrenzy's Construction Frenzy\" to start the event.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Event
            [151702] = { name = "Paol Pondwader", npcid = 151702, questId = { 55405 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 23006860 }, bothphases = true, note = "Likely available only when Reclamation Rig daily construction project is up.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Supervolt Zapper { droptype = DROPTYPE.ITEM, itemID = 170468, isKnown = false }
            [153000] = { name = "Sparkqueen P'Emp", npcid = 153000, questId = { 55810 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 82202300 }, bothphases = true, note = "Only available when Razak Ironsides is in Rustbolt.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Yellow punchcards
            [151940] = { name = "Uncle T'Rogg", npcid = 151940, questId = { 55538 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 57002140 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Yellow punchcards
            
            -- Quest Drops:
            [153200] = { name = "Boilburn", npcid = 153200, questId = { 55857 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 51205000 }, bothphases = true, cave = { coord = { 51445025 } }, note = "Inside cave. Only available when Drill Rigs are up as a daily Construction Project. Drill Rig DR-JD41.", loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 167042, checkId = 55030, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 169691, checkId = 56518, isKnown = false } } }, -- Blueprint: Scrap Trap, Vinyl: Depths of Ulduar
            [151308] = { name = "Boggac Skullbash", npcid = 151308, questId = { 55539 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 53003300 }, bothphases = true, note = "Only available when Drill Rigs are up as a daily Construction Project. Patrols front of the Moch'k's Hole at the Scrapbone Den.", loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 168908, checkId = 56087, isKnown = false } } }, -- Blueprint: Experimental Adventurer Augment
            [154739] = { name = "Caustic Mechaslime", npcid = 154739, questId = { 56368 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 66505870 }, bothphases = true, cave = { coord = { 66405884 } }, note = "Inside cave. Only available when Drill Rigs are up as a daily Construction Project. Drill Rig DR-CC73.", loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 169170, checkId = 55078, isKnown = false } } }, -- Blueprint: Utility Mechanoclaw
            [149847] = { name = "Crazed Trogg", npcid = 149847, questId = { 55812 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 82202100 }, bothphases = true, note = "Spawns as 1 of 3 versions requiring a player to be painted Blue, Green, or Orange to activate.", loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 169167, checkId = 55075, isKnown = false }, { droptype = DROPTYPE.BLUEPRINT, itemID = 169169, checkId = 55077, isKnown = false }, { droptype = DROPTYPE.BLUEPRINT, itemID = 169168, checkId = 55076, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 167790, checkId = 55451, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 167792, checkId = 55452, isKnown = false } } }, -- Blueprint: Orange Spraybot, Blueprint: Blue Spraybot, Blueprint: Green Spraybot, Paint Vial: Fireball Red, Paint Vial: Fel Mint Green Last 2 are { droptype = DROPTYPE.QUEST, itemID = 167790, checkId = 55451, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 167792, checkId = 55452, isKnown = false }
            [151569] = { name = "Deepwater Maw", npcid = 151569, questId = { 55514 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 37334392 }, bothphases = true, note = "You need to attach \"Hundred-Fathom\" Lure to the buoy to make it spawn. You can access its blueprint by completing the fishing quest nearby.", loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 167836, checkId = 55057, isKnown = false } } }, -- Blueprint: Canned Minnows
            [150342] = { name = "Earthbreaker Gulroc", npcid = 150342, questId = { 55814 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 62802600 }, bothphases = true, cave = { coord = { 63532500 } }, note = "Inside cave. Only available when Drill Rigs are up as a daily Construction Project. Drill Rig DR-TR35.", loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 167042, checkId = 55030, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 169691, checkId = 56518, isKnown = false } } }, -- Blueprint: Scrap Trap, Vinyl: Depths of Ulduar
            [154153] = { name = "Enforcer KX-T57", npcid = 154153, questId = { 56207 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 55555555 }, bothphases = true, note = "Spawns in Junkwatt Depot when it's raining.", loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 169174, checkId = 55082, isKnown = false } } }, -- Blueprint: Rustbolt Pocket Turret,  (item Whirring Chainblade?)
            [151202] = { name = "Foul Manifestation", npcid = 151202, questId = { 55513 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 65605100 }, bothphases = true, note = "Use the Circuit Breaker at 67.31 , 55.54 then attach Alpha, Beta and Delta wires to their pylons to make the rare spawn.", loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 167871, checkId = 55063, isKnown = false }, { droptype = DROPTYPE.BLUEPRINT, itemID = 167042, checkId = 55030, isKnown = false } } }, -- Blueprint: G99.99 Landshark, Blueprint: Scrap Trap
            [151884] = { name = "Fungarian Furor", npcid = 151884, questId = { 55367 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 48704760 }, bothphases = true, note = "Pet is only available when Mylune's daily quest \"Aid From Nordrassil\" is active!", loot = { { droptype = DROPTYPE.QUEST, itemID = 167793, checkId = 55457, isKnown = false }, { droptype = DROPTYPE.PET, itemID = 169379, petID = 154851, speciesID = 2712, isKnown = false } } }, -- Paint Vial: Overload Orange, pet 
            [153228] = { name = "Gear Checker Cogstar", npcid = 153228, questId = { 55852 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 40203960 }, bothphases = true, note = "Spawns after a certain amount of Upgraded Sentry were killed. Can spawn in multiple areas.", loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 167847, checkId = 55062, isKnown = false } } }, -- Blueprint: Ultrasafe Transporter - Mechagon
            [153205] = { name = "Gemicide", npcid = 153205, questId = { 55855 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 59606730 }, bothphases = true, cave = { coord = { 59656720 } }, note = "Inside cave. Only available when Drill Rigs are up as a daily Construction Project. Drill Rig DR-JD99.", loot = { { droptype = DROPTYPE.QUEST, itemID = 169691, checkId = 56518, isKnown = false } } }, -- , Vinyl: Depths of Ulduar
            [154701] = { name = "Gorged Gear-Cruncher", npcid = 154701, questId = { 56367 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 69205340 }, bothphases = true, cave = { coord = { 72635385 } }, note = "Inside cave. Only available when Drill Rigs are up as a daily Construction Project. Drill Rig DR-CC61.", loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 167846, checkId = 55061, isKnown = false } } }, -- Blueprint: Mechano-Treat
            [151684] = { name = "Jawbreaker", npcid = 151684, questId = { 55399 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 75404400 }, bothphases = true, loot = { { droptype = DROPTYPE.QUEST, itemID = 198908, checkId = 56087, isKnown = false } } }, -- Blueprint: Experimental Adventurer Augment + Yellow punchcards
            [151124] = { name = "Mechagonian Nullifier", npcid = 151124, questId = { 55207 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 56905330 }, bothphases = true, note = "Obtain and wear \"Remote Circuit Bypasser\" to be able to hack the Frenzied Elemental in Junkwatt Depot. The punchcard drops from The Scrap King.", loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 168490, checkId = 55069, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 169688, checkId = 56515, isKnown = false } } }, -- Blueprint: Protocol Transference Device, Vinyl: Gnomeregan Forever
            [151627] = { name = "Mr. Fixthis", npcid = 151627, questId = { 55859 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 59806080 }, bothphases = true, loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 168248, checkId = 55068, isKnown = false } } }, -- Blueprint: BAWLD-371
            [153206] = { name = "Ol' Big Tusk", npcid = 153206, questId = { 55853 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 56103600 }, bothphases = true, cave = { coord = { 56153632 } }, note = "Inside cave. Only available when Drill Rigs are up as a daily Construction Project. Drill Rig DR-TR28.", loot = { { droptype = DROPTYPE.QUEST, itemID = 169691, checkId = 56518, isKnown = false } } }, -- Vinyl: Depths of Ulduar
            [151296] = { name = "OOX-Avenger/MG", npcid = 151296, questId = { 55515 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 56803990 }, bothphases = true, note = "Only available, when Oglethorpe Obnoticus is in the town. Find and kill OOX-Fleetfoot/MG to make the overstuffed rare chicken spawn.", loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 168492, checkId = 55071, isKnown = false } } }, -- Blueprint: Emergency Rocket Chicken
            [152764] = { name = "Oxidized Leachbeast", npcid = 152764, questId = { 55856 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 57206260 }, bothphases = true, note = "When it's raining small oxidized slimes spawn in Junkwatt Depot. Kill those until the rare mob spawns.", loot = { { droptype = DROPTYPE.QUEST, itemID = 167794, checkId = 55454, isKnown = false } } }, -- Paint Vial: Lemonade Steel
            [150575] = { name = "Rumblerocks", npcid = 150575, questId = { 55368 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 38805320 }, bothphases = true, loot = { { droptype = DROPTYPE.QUEST, itemID = 168001, checkId = 55517, isKnown = false } } }, -- Paint Vial: Big-ol Bronze
            [155583] = { name = "Scrapclaw", npcid = 155583, questId = { 56737 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 82677740 }, bothphases = true, loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 168490, checkId = 55069, isKnown = false } } }, -- Blueprint: Protocol Transference Device
            [150937] = { name = "Seaspit", npcid = 150937, questId = { 55545 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 19207940 }, bothphases = true, loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 168063, checkId = 55065, isKnown = false } } }, -- Blueprint: Rustbolt Kegerator
            [153226] = { name = "Steel Singer Freza", npcid = 153226, questId = { 55854 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 24807720 }, bothphases = true, loot = { { droptype = DROPTYPE.QUEST, itemID = 168062, checkId = 55064, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 169690, checkId = 56517, isKnown = false } } }, -- Blueprint: Rustbolt Gramophone + Vinyl: Battle of Gnomeregan
            [151625] = { name = "The Scrap King", npcid = 151625, questId = { 55364 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 71204840 }, bothphases = true, loot = { { droptype = DROPTYPE.BLUEPRINT, itemID = 168908, checkId = 56087, isKnown = false } } }, -- Blueprint: Experimental Adventurer Augment

        },
    },
    --------
    [1527] = { -- Old Uldum: 249
        expansion = EXPANSION.BFA,
        zonename = "Uldum",
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_ASSAULT,
        currentAssault = 0,
        zonephaseID = 1343, -- ArtID, Old Uldum: 289
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!     116?
        hordeContributionMapID = 0, -- Change!        11?
        --homeCoord = { 39965257, 10205301 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 5,
        rares = {-- cave = { coord = { COORD }, note =  "CAVENOTE", infoOnly = true }
            -- Bosses:
            -- Mount Drops:
            [162147] = { name = L["corpse_eater"], npcid = 162147, questId = { 58696 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 30854971 }, bothphases = true, assault = assaultType.aqir, loot = { { droptype = DROPTYPE.MOUNT, itemID = 174769, mountID = 1319, isKnown = false } } }, -- Corpse Eater | Invasion Type: Aqir
            [157134] = { name = L["ishak_of_the_four_winds"], npcid = 157134, questId = { 57259 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 73918364 }, bothphases = true, assault = assaultType.all, loot = { { droptype = DROPTYPE.MOUNT, itemID = 174641, mountID = 1314, isKnown = false } } }, -- Ishak of the Four Winds | Invasion Type: Black Empire
            [157146] = { name = L["rotfeaster"], npcid = 157146, questId = { 57273 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 68593204 }, bothphases = true, assault = assaultType.amathet, loot = { { droptype = DROPTYPE.MOUNT, itemID = 174753, mountID = 1317, isKnown = false } } }, -- Rotfeaster | Invasion Type: Amathet
            -- Pet Drops:
            [157593] = { name = L["amalgamation_of_flesh"], npcid = 157593, questId = { 57667 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 59907230 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.PET, itemID = 174478, petID = 162012, speciesID = 2851, isKnown = false } } }, -- Amalgamation of Flesh | Invasion Type: Black Empire !Coords
            [154604] = { name = L["lord_ajqirai"], npcid = 154604, questId = { 56340 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 34741885 }, bothphases = true, assault = assaultType.aqir, cave = { coord = { 36852093 } }, note = "Located inside the Obelisk of the Moon.", loot = { { droptype = DROPTYPE.PET, itemID = 174475, petID = 161997, speciesID = 2847, isKnown = false } } }, -- Lord Aj'qirai | Invasion Type: Aqir
            [162140] = { name = L["skikxtraz"], npcid = 162140, questId = { 58697 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 21236105 }, bothphases = true, assault = assaultType.aqir, note = "Patrols in a big area around Ankhaten Harbor.", loot = { { droptype = DROPTYPE.PET, itemID = 174476, petID = 162004, speciesID = 2848, isKnown = false } } }, -- Skikx'traz | Invasion Type: Aqir
            -- Toy Drops:
            [158633] = { name = L["gaze_of_nzoth"], npcid = 158633, questId = { 57680 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 55005300 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.TOY, itemID = 175140, note = "Toy is crafted with an 'All-Seeing Right Eye' and an 'All-Seeing Left Eye'.", isKnown = false } } }, -- Gaze of N'Zoth | Invasion Type: Black Empire
            [158636] = { name = L["the_grand_executor"], npcid = 158636, questId = { 57688 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 49358229 }, bothphases = true, assault = assaultType.blackEmpire, note = "Spawns on the platforms atop Neferset.", loot = { { droptype = DROPTYPE.TOY, itemID = 169303, isKnown = false } } }, -- The Grand Executor | Invasion Type: Black Empire
            [157473] = { name = L["yiphrim_the_will_ravager"], npcid = 157473, questId = { 57438 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 50907866 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.TOY, itemID = 174874, isKnown = false } } }, -- Yiphrim the Will Ravager | Invasion Type: Black Empire !Coords !Neferset Shared Rares!
            -- Item Only:
            [152788] = { name = L["uat_ka_the_suns_wrath"], npcid = 152788, questId = { 55716 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 67606360 }, bothphases = true, assault = assaultType.amathet, note = "To spawn, bring 3 people with  Suntouched Amulet and activate the machine at the area.", loot = { { droptype = DROPTYPE.ITEM, itemID = 174875, isKnown = false } } }, -- Uat-ka the Sun's Wrath
            -- Gear Only:
            [157170] = { name = L["acolyte_taspu"], npcid = 157170, questId = { 57281 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 64572623 }, bothphases = true, assault = assaultType.amathet, note = "Located on the underground level of the Obelisk of the Stars.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Acolyte Taspu
            [158557] = { name = L["actiss_the_deceiver"], npcid = 158557, questId = { 57669 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 66917436 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Actiss the Deceiver (Weak Rare)
            [151883] = { name = L["anaua"], npcid = 151883, questId = { 55468 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 69205059 }, bothphases = true, assault = assaultType.amathet, note = "Flies high around the Halls of Origination.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Anaua
            [155703] = { name = L["anquri_the_titanic"], npcid = 155703, questId = { 56834 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 32436446 }, bothphases = true, assault = assaultType.all, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Anq'uri the Titanic
            [162370] = { name = L["armagedillo"], npcid = 162370, questId = { 58718 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 44814267 }, bothphases = true, assault = assaultType.all, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Armagedillo
            [152757] = { name = L["atekhramun"], npcid = 152757, questId = { 55710 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 65035129 }, bothphases = true, assault = assaultType.amathet, note = "To spawn, stomp on the mini scorpids around the crack on the ground.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Atekhramun
            [162171] = { name = L["captain_dunewalker"], npcid = 162171, questId = { 58699 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 45565782 }, bothphases = true, assault = assaultType.aqir, note = "Located at the inner level of the Obelisk of the Sun.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Captain Dunewalker
            [158594] = { name = L["doomsayer_vathiris"], npcid = 158594, questId = { 57672 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 49403819 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Doomsayer Vathiris
            [158491] = { name = L["falconer_amenophis"], npcid = 158491, questId = { 57662 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 44247856 }, bothphases = true, assault = assaultType.blackEmpire, note = "Patrols around the outskirts of Neferset.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Falconer Amenophis
            [157120] = { name = L["fangtaker_orsa"], npcid = 157120, questId = { 57258 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 75076812 }, bothphases = true, assault = assaultType.amathet, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Fangtaker Orsa
            [158597] = { name = L["high_executor_yothrim"], npcid = 158597, questId = { 57675 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 54764309 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- High Executor Yothrim
            [158528] = { name = L["high_guard_reshef"], npcid = 158528, questId = { 57664 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 47687733 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- High Guard Reshef
            [151995] = { name = L["hik_ten_the_taskmaster"], npcid = 151995, questId = { 55502 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 80864755 }, bothphases = true, assault = { assaultType.blackEmpire, assaultType.amathet }, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Hik-ten the Taskmaster
            [160623] = { name = L["hungering_miasma"], npcid = 160623, questId = { 58206 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 60043952 }, bothphases = true, assault = assaultType.blackEmpire, note = "To spawn, drag nearby oozelings into the void zone located at the coordinate.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Hungering Miasma
            [156655] = { name = L["korzaran_the_slaughterer"], npcid = 156655, questId = { 57433 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 71247373 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Korzaran the Slaughterer
            [156078] = { name = L["magus_rehleth"], npcid = 156078, questId = { 56952 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 31246546 }, bothphases = true, assault = assaultType.aqir, note = "Has multiple spawns around the Ruins of Ammon.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Magus Rehleth
            [157157] = { name = L["muminah_the_incandescent"], npcid = 157157, questId = { 57277 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 67301947 }, bothphases = true, assault = assaultType.amathet, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Muminah the Incandescent
            [152677] = { name = L["nebet_the_ascended"], npcid = 152677, questId = { 55684 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 61982567 }, bothphases = true, assault = assaultType.amathet, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Nebet the Ascended
            [162196] = { name = L["obsidian_annihilator"], npcid = 162196, questId = { 58681 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 35061729 }, bothphases = true, assault = assaultType.all, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Obsidian Annihilator
            [162142] = { name = L["qho"], npcid = 162142, questId = { 58693 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 37826028 }, bothphases = true, assault = assaultType.aqir, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Qho
            [156299] = { name = L["rkhuzj_the_unfathomable"], npcid = 156299, questId = { 57430 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 57957664 }, bothphases = true, assault = { assaultType.blackEmpire, assaultType.aqir }, note ="Patrols around the Virnaal river path.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- R'khuzj The Unfathomable
            [162173] = { name = L["rkrox_the_runt"], npcid = 162173, questId = { 58864 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 28901765 }, bothphases = true, assault = assaultType.aqir, note = "", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- R'krox the Runt
            [152040] = { name = L["scoutmaster_moswen"], npcid = 152040, questId = { 55518 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 69924214 }, bothphases = true, assault = assaultType.amathet, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Scoutmaster Moswen
            [151948] = { name = L["senbu_the_pridefather"], npcid = 151948, questId = { 55496 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 74136436 }, bothphases = true, assault = assaultType.amathet, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Senbu the Pridefather
            [161033] = { name = L["shadowmaw"], npcid = 161033, questId = { 58333 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 52053798 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Shadowmaw
            [156654] = { name = L["sholthoss_the_doomspeaker"], npcid = 156654, questId = { 57432 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 58548282 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Shol'thoss the Doomspeaker
            [160532] = { name = L["shoth_the_darkened"], npcid = 160532, questId = { 58169 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 60917478 }, bothphases = true, assault = { assaultType.blackEmpire, assaultType.aqir }, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Shoth the Darkened
            [162372] = { name = L["spirit_of_cyrus_the_black"], npcid = 162372, questId = { 58715 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 66687074 }, bothphases = true, assault = { assaultType.amathet, assaultType.aqir }, note = "", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Spirit of Cyrus the Black
            [151878] = { name = L["sun_king_nahkotep"], npcid = 151878, questId = { 58613 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 79016393 }, bothphases = true, assault = assaultType.all, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Sun King Nahkotep
            [151897] = { name = L["sun_priestess_nubitt"], npcid = 151897, questId = { 55479 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 84595708 }, bothphases = true, assault = assaultType.amathet, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Sun Priestess Nubitt
            [151609] = { name = L["sun_prophet_epaphos"], npcid = 151609, questId = { 55353 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 73327463 }, bothphases = true, assault = assaultType.amathet, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Sun Prophet Epaphos
            [152657] = { name = L["sun_prophet_epaphos"], npcid = 152657, questId = { 55682 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 67073413 }, bothphases = true, assault = assaultType.amathet, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Tat the Bonechewer
            [162170] = { name = L["warcaster_xeshro"], npcid = 162170, questId = { 58702 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 33502618 }, bothphases = true, assault = assaultType.aqir, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Warcaster Xeshro
            [151852] = { name = L["watcher_rehu"], npcid = 151852, questId = { 55461 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 80185204 }, bothphases = true, assault = assaultType.amathet, note = "Patrols along the pathway leading to the Halls of Origination.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Watcher Rehu
            [157164] = { name = L["zealot_tekem"], npcid = 157164, questId = { 57279 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 79805771 }, bothphases = true, assault = assaultType.amathet, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Zealot Tekem
            [162141] = { name = L["zuythiz"], npcid = 162141, questId = { 58695 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 40864226 }, bothphases = true, assault = assaultType.aqir, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Zuythiz
            [157167] = { name = L["champion_sen_mat"], npcid = 157167, questId = { 57280 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 75495219 }, bothphases = true, assault = { assaultType.blackEmpire, assaultType.amathet }, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Champion Sen-mat  amathet too?
            [162352] = { name = L["spirit_of_dark_ritualist_zakahn"], npcid = 162352, questId = { 58716 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 50004000 }, bothphases = true, cave = { coord = { 52154012 } }, assault = { assaultType.amathet, assaultType.aqir }, note = "Can spawn in multiple locations.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Spirit of Dark Ritualist Zakahn
            [158595] = { name = L["thoughtstealer_vos"], npcid = 158595, questId = { 57673 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 65227389 }, bothphases = true, assault = assaultType.blackEmpire, note = "is stealthed.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Thoughtstealer Vos
            -- Quest Drops:
            -- Unknown:
            [157472] = { name = L["aphrom_the_guise_of_madness"], npcid = 157472, questId = { 57437 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 50007868 }, bothphases = true, assault = assaultType.unknown, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Aphrom the Guise of Madness !Neferset Shared Rares!
            [154578] = { name = L["aqir_flayer"], npcid = 154578, questId = { 58612 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 40833822 }, bothphases = true, assault = assaultType.all, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Aqir Flayer
            [154576] = { name = L["aqir_titanus"], npcid = 154576, questId = { 58614 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 41924440 }, bothphases = true, assault = assaultType.all, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Aqir Titanus
            [162172] = { name = L["aqir_warcaster"], npcid = 162172, questId = { 58694 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 40284141 }, bothphases = true, assault = assaultType.all, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Aqir Warcaster
            [162163] = { name = L["high_priest_ytaessis"], npcid = 162163, questId = { 58701 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 42405803 }, bothphases = true, assault = assaultType.aqir, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- High Priest Ytaessis
            [155531] = { name = L["infested_wastewander_captain"], npcid = 155531, questId = { 56823 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 23205852 }, bothphases = true, assault = assaultType.all, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Infested Wastewander Captain
            [157470] = { name = L["raas_the_anima_devourer"], npcid = 157470, questId = { 57436 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 50578832 }, bothphases = true, assault = assaultType.unknown, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- R'aas the Anima Devourer !Neferset Shared Rares!
            [157476] = { name = L["shugshul_the_flesh_gorger"], npcid = 157476, questId = { 57439 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 55497972 }, bothphases = true, assault = assaultType.unknown, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Shugshul the Flesh Gorger !Neferset Shared Rares!
            [152431] = { name = L["kaneb_ti"], npcid = 152431, questId = { 55629 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 77105040 }, bothphases = true, assault = assaultType.amathet, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Kaneb-ti
            [157188] = { name = L["the_tomb_widow"], npcid = 157188, questId = { 57285 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 84404720 }, bothphases = true, assault = assaultType.amathet, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- The Tomb Widow
            [158531] = { name = L["corrupted_neferset_guard"], npcid = 158531, questId = { 57665 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 50007900 }, bothphases = true, note = "To generate the corrupted creatures you must kill their normal versions", assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Corrupted Neferset Guard
            [157469] = { name = L["zothrum_the_intellect_pillager"], npcid = 157469, questId = { 57435 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 50908366 }, bothphases = true, assault = assaultType.unknown, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Zoth'rum the Intellect Pillager !Neferset Shared Rares!
            [157390] = { name = L["royolok_the_reality_eater"], npcid = 157390, questId = { 57434 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 52907866 }, bothphases = true, assault = assaultType.unknown, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- R'oyolok the Reality Eater !Neferset Shared Rares!
        },
    },
    [1530] = {
        expansion = EXPANSION.BFA,
        zonename = "Vale of Eternal Blossoms",
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_ASSAULT,
        currentAssault = 0,
        zonephaseID = 1276, -- ArtID
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!     116?
        hordeContributionMapID = 0, -- Change!        11?
        --homeCoord = { 39965257, 10205301 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 6,
        rares = {-- cave = { coord = { COORD }, note =  "CAVENOTE", infoOnly = true }
            -- Bosses:
            -- Mount Drops:
            [157160] = { name = L["houndlord_ren"], npcid = 157160, questId = { 57345 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 12592788 }, bothphases = true, assault = assaultType.mogu, note = "Patrols around the Autumnshade Ridge area.", loot = { { droptype = DROPTYPE.MOUNT, itemID = 174841, mountID = 1327, isKnown = false } } }, -- Houndlord Ren
            [157153] = { name = L["ha_li"], npcid = 157153, questId = { 57344 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 29513800 }, bothphases = true, assault = assaultType.mogu, note = "Flies around the mountain surrounding the Ruins of Guo-Lai.", loot = { { droptype = DROPTYPE.MOUNT, itemID = 173887, mountID = 1297, isKnown = false } } }, -- Ha-Li
            [163042] = { name = L["ivory_cloud_serpent"], npcid = 163042, questId = { 57349 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 42205630 }, bothphases = true, assault = assaultType.mogu, note = "NPC can be activated using a 'Zan-Tien Lasso', dropped by Dokani Bloodshapers.", loot = { { droptype = DROPTYPE.MOUNT, itemID = 174752, mountID = 1311, isKnown = false } } }, -- Ivory Cloud Serpent
            [157466] = { name = L["anh_de_the_loyal"], npcid = 157466, questId = { 57363 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 34136858 }, bothphases = true, assault = assaultType.mogu, loot = { { droptype = DROPTYPE.MOUNT, itemID = 174840, mountID = 1328, isKnown = false } } }, -- Anh-De the Loyal
            -- Pet Drops:
            [154495] = { name = L["will_of_nzoth"], npcid = 154495, questId = { 56303 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 54266272 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.PET, itemID = 174474, petID = 161992, speciesID = 2846, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 175140, note = "Toy is crafted with an 'All-Seeing Right Eye' and an 'All-Seeing Left Eye'.", isKnown = false } } }, -- Will of N'Zoth
            [157176] = { name = L["the_forgotten"], npcid = 157176, questId = { 57342 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 51884116 }, bothphases = true, assault = assaultType.blackEmpire, note = "Spawns on the platforms floating atop the Golden Pagoda.", loot = { { droptype = DROPTYPE.PET, itemID = 174473, petID = 161954, speciesID = 2845, isKnown = false } } }, -- The Forgotten
            -- Toy Drops:
            [155958] = { name = L["tashara"], npcid = 155958, questId = { 58507 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 29342238 }, bothphases = true, assault = assaultType.mogu, loot = { { droptype = DROPTYPE.TOY, itemID = 174873, isKnown = false } } }, -- Tashara
            -- Item Only:
            [157287] = { name = L["dokani_obliterator"], npcid = 157287, questId = { 57349 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 41205630 }, bothphases = true, assault = assaultType.mogu, loot = { { droptype = DROPTYPE.ITEM, itemID = 174927, checkMountID = 1311, isKnown = false } } }, -- Dokani Obliterator
            [156083] = { name = L["sanguifang"], npcid = 156083, questId = { 56954 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 46185713 }, bothphases = true, assault = assaultType.mogu, loot = { { droptype = DROPTYPE.ITEM, itemID = 174071, isKnown = false } } }, -- Sanguifang
            [157162] = { name = L["rei_lun"], npcid = 157162, questId = { 57346 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 21901234 }, bothphases = true, assault = assaultType.mogu, loot = { { droptype = DROPTYPE.ITEM, itemID = 174230, isKnown = false } } }, -- Rei Lun
            -- Gear Only:
            [154106] = { name = L["quid"], npcid = 154106, questId = { 56094 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 90164597 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Quid
            [154332] = { name = L["voidtender_malketh"], npcid = 154332, questId = { 56183 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 67082964 }, bothphases = true, assault = assaultType.blackEmpire, note = "Spawns inside the Pools of Power area, but can be seen from above ground.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Voidtender Malketh
            [154447] = { name = L["brother_meller"], npcid = 154447, questId = { 56237 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 56854136 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Brother Meller
            [154467] = { name = L["chief_mek_mek"], npcid = 154467, questId = { 56255 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 81086542 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Chief Mek-mek
            [154490] = { name = L["rijzx_the_devourer"], npcid = 154490, questId = { 56302 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 64405166 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Rijz'x the Devourer
            [154559] = { name = L["deeplord_zrihj"], npcid = 154559, questId = { 56323 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 66996658 }, bothphases = true, assault = assaultType.blackEmpire, note = "Located inside the Deep Blossom Mine.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Deeplord Zrihj
            [154600] = { name = L["teng_the_awakened"], npcid = 154600, questId = { 56332 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 47516521 }, bothphases = true, assault = assaultType.mogu, note = "Spawns inside the cave in Tu-Shen Burial Grounds.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Teng the Awakened
            [157171] = { name = L["heixi_the_stonelord"], npcid = 157171, questId = { 57347 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 28224048 }, bothphases = true, assault = assaultType.mogu, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Heixi the Stonelord
            [157266] = { name = L["kilxl_the_gaping_maw"], npcid = 157266, questId = { 57341 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 45905850 }, bothphases = true, assault = assaultType.blackEmpire, note = "Flies around the Tu-Shen Burial Ground.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Kilxl the Gaping Maw
            [157267] = { name = L["escaped_mutation"], npcid = 157267, questId = { 57343 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 46144226 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Escaped Mutation
            [157279] = { name = L["stormhowl"], npcid = 157279, questId = { 57348 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 27277432 }, bothphases = true, assault = assaultType.mogu, note = "Patrols around the target area.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Stormhowl
            [157290] = { name = L["jade_watcher"], npcid = 157290, questId = { 57350 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 26821109 }, bothphases = true, note = "Inside a cave.", assault = assaultType.mogu, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Jade Watcher
            [157291] = { name = L["spymaster_hulach"], npcid = 157291, questId = { 57351 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 17863748 }, bothphases = true, assault = assaultType.mogu, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Spymaster Hul'ach
            [157443] = { name = L["xiln_the_mountain"], npcid = 157443, questId = { 57358 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 53804886 }, bothphases = true, assault = assaultType.mogu, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Xiln the Mountain
            [157468] = { name = L["tisiphon"], npcid = 157468, questId = { 57364 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 10456907 }, bothphases = true, assault = assaultType.all, note = "To spawn it, click on the fishing rod next to the body of water.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Tisiphon
            [160810] = { name = L["harbinger_ilkoxik"], npcid = 160810, questId = { 58299 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 29065767 }, bothphases = true, assault = assaultType.mantid, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Harbinger Il'koxik
            [160825] = { name = L["amber_shaper_eshri"], npcid = 160825, questId = { 58300 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 19997468 }, bothphases = true, assault = assaultType.mantid, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Amber-Shaper Esh'ri
            [160826] = { name = L["hive_guard_nazruzek"], npcid = 160826, questId = { 58301 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 21276263 }, bothphases = true, assault = assaultType.mantid, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Hive-Guard Naz'ruzek
            [160867] = { name = L["kzitkovok"], npcid = 160867, questId = { 58302 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 27893897 }, bothphases = true, assault = assaultType.mantid, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Kzit'kovok
            [160868] = { name = L["harrier_nirverash"], npcid = 160868, questId = { 58303 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 12845130 }, bothphases = true, assault = assaultType.mantid, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Harrier Nir'verash
            [160872] = { name = L["destroyer_kroxtazar"], npcid = 160872, questId = { 58304 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 15953668 }, bothphases = true, assault = assaultType.mantid, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Destroyer Krox'tazar
            [160874] = { name = L["drone_keeper_akthet"], npcid = 160874, questId = { 58305 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 12574106 }, bothphases = true, assault = assaultType.mantid, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Drone Keeper Ak'thet
            [160876] = { name = L["enraged_amber_elemental"], npcid = 160876, questId = { 58306 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 11464062 }, bothphases = true, assault = assaultType.mantid, note = "Patrols in a circle around the area.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Enraged Amber Elemental
            [160878] = { name = L["buhgzaki_the_blasphemous"], npcid = 160878, questId = { 58307 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 6657066 }, bothphases = true, assault = assaultType.mantid, note = "Spawns on the top level of the wall.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Buh'gzaki the Blasphemous
            [160920] = { name = L["kaltik_the_blight"], npcid = 160920, questId = { 58310 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 17680998 }, bothphases = true, assault = assaultType.mantid, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Kal'tik the Blight
            [160922] = { name = L["needler_zhesalla"], npcid = 160922, questId = { 58311 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 14933998 }, bothphases = true, assault = assaultType.mantid, note = "Flies around The Five Sisters area.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Needler Zhesalla
            [160930] = { name = L["infused_amber_ooze"], npcid = 160930, questId = { 58312 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 18746346 }, bothphases = true, assault = assaultType.mantid, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Infused Amber Ooze
            [160968] = { name = L["jade_colossus"], npcid = 160968, questId = { 58295 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 17151201 }, bothphases = true, assault = assaultType.mogu, note = "Spawns deep inside the Guo-Lai Halls.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Jade Colossus
            [160893] = { name = L["captain_vorlek"], npcid = 160893, questId = { 58308 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 5986420 }, bothphases = true, assault = assaultType.mantid, note = "Patrols around the top level of the wall.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Captain Vor'lek
            [157183] = { name = L["coagulated_anima"], npcid = 157183, questId = { 58296 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 20766232 }, bothphases = true, assault = assaultType.mogu, note = "Can spawn at any blood ritual sites in the Setting Sun Garrison.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Coagulated Anima
            [154087] = { name = L["zrorum_the_infinite"], npcid = 154087, questId = { 56084 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 71644174 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Zror'um the Infinite
            [154394] = { name = L["veskan_the_fallen"], npcid = 154394, questId = { 56213 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 85934196 }, bothphases = true, assault = assaultType.blackEmpire, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Veskan the Fallen
            -- Quest Drops:
            -- Unknown:
            [159087] = { name = L["corrupted_bonestripper"], npcid = 159087, questId = { 57834 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 55714381 }, bothphases = true, assault = assaultType.unknown, note = "To generate the corrupted creatures you must kill their normal versions.", loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Corrupted Bonestripper
            [160906] = { name = L["skiver"], npcid = 160906, questId = { 58309 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 25074411 }, bothphases = true, assault = assaultType.unknown, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } }, -- Skiver No known assault
        },
    },
    -- Shadowlands
    [1565] = {
        zonename = "Ardenweald", -- NIGHTFAE
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_UNTRACKED,
        currentAssault = 0,
        zonephaseID = 1276, -- ArtID
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!     116?
        hordeContributionMapID = 0, -- Change!        11?
        --homeCoord = { 39965257, 10205301 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 7,
        expansion = EXPANSION.SHADOWLANDS,
        covenantID = COVENANTS.NIGHTFAE,
        rares = {
            [164107] = { name = L["gormtamer_tizo"], npcid = 164107, questId = { 59145 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 27885248 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 180725, mountID = 1362, isKnown = false } }, note = "Kill Bristlecone Terrors and Deranged Guardians in the area until Chompy spawns. The rare will spawn once Chompy is killed." },
            [164112] = { name = L["humongozz"], npcid = 164112, questId = { 59157 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 32423026 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 182650, mountID = 1415, isKnown = false } }, note = "Loot an Unusually Large Mushroom from mobs in Ardenweald and plant at the Damp Soil at the coordinate to summon the rare." },
            [168135] = { name = L["night_mare"], npcid = 168135, questId = { 60306 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 57874983 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 180728, mountID = 1306, isKnown = false } }, note = "Use the [Dream Catcher] in Dreamshrine Basin to see and kill this rare." },
            [168647] = { name = L["valfir_the_unrelenting"], covenantBound = COVENANTS.NIGHTFAE, npcid = 168647, questId = { 61632 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 30115536 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 180730, mountID = 1393, covenantBound = COVENANTS.NIGHTFAE, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 180154, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 182176, checkId = 62431, covenantBound = COVENANTS.NIGHTFAE, isKnown = false } }, note = "Loot a nearby Sparkling Animaseed and use [Animaseed Light] on the rare to dispell his  Misty Veil." },
            [171743] = { name = L["star_lake_amphitheater"], covenantBound = COVENANTS.NIGHTFAE, npcid = 171743, questId = { 61633 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 41254443 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 180748, mountID = 1332, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 182454, isKnown = false } }, note = "Talk to 'the Stage Director' to start one of the special encounters. The encounter changes each day." },
            [164477] = { name = L["deathbinder_hroth"], npcid = 164477, questId = { 59226 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 34606800 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 180166, isKnown = false } } },
            [164238] = { name = L["deifir_the_untamed"], npcid = 164238, questId = { 59201, 62271 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 47522845 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 180631, speciesID = 2920, isKnown = false } }, note = "Mount the Rare and his mount ability [Stunning Strike] to slow and stun him." },
            [163370] = { name = L["gormbore"], npcid = 163370, questId = { 59006 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 54067601 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 183196, speciesID = 3035, isKnown = false } } },
            [164093] = { name = L["macabre"], npcid = 164093, questId = { 59140 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 32664480 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 180644, speciesID = 2907, isKnown = false } }, note = "Requires 3 players to stand in the mushroom ring at  location and /dance with each other to summon the rare." },
            [164391] = { name = L["old_ardeite"], npcid = 164391, questId = { 59208, 62270 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 51105740 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 180643, speciesID = 2908, isKnown = false } }, note = "Flies high up in the air. Use a nearby [Basket of Enchanted Wings] or [Pinch of Faerie Dust] to fly and aggro the rare." },
            [160448] = { name = L["hunter_vivian"], npcid = 160448, questId = { 59221 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 67465147 }, bothphases = true, loot = { { droptype = DROPTYPE.QUEST, itemID = 183091, checkId = 62246, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 179596, isKnown = false } } },
            [164547] = { name = L["mystic_rainbowhorn"], npcid = 164547, questId = { 59235 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 65702809 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 179586, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 182179, checkId = 62434, covenantBound = COVENANTS.NIGHTFAE, isKnown = false } }, note = "Use the Great Horn of the Runestag nearby to summon the rare." },
            [164415] = { name = L["skuld_vit"], covenantBound = COVENANTS.NIGHTFAE, npcid = 164415, questId = { 59220 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 37675917 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 180146, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 182183, checkId = 62439, covenantBound = COVENANTS.NIGHTFAE, isKnown = false } }, note = "A Night Fae member needs to [Soulshape] inside his cave to make the rare attackable." },
            [167851] = { name = L["egg-tender_lehgo"], npcid = 167851, questId = { 60266 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 57862955 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 179539, isKnown = false } }, note = "Break the eggs inside the cave to summon the rare." },
            [171688] = { name = L["faeflayer"], npcid = 171688, questId = { 61184 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 68612765 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 180144, isKnown = false } }, note = "Can get to his cave by either dropping from above or following a path below it." },
            [165053] = { name = L["mymaen"], npcid = 165053, questId = { 59431 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 62102470 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 179502, isKnown = false } }, note = "Kill Rotbriar Scrappers in the  area to summon the rare." },
            [167726] = { name = L["rootwrithe"], npcid = 167726, questId = { 60273 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 65104430 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 179603, isKnown = false } }, note = "Interact with the 3 plants by the vignette to summon the rare." },
            [167724] = { name = L["rotbriar_boggart"], npcid = 167724, questId = { 60258 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 65702430 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 175729, isKnown = false } }, note = "Talk to 'Daffodil' in the area to start the event." },
            [171451] = { name = L["soultwister_cero"], npcid = 171451, questId = { 61177 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 72425175 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 180164, isKnown = false } } },
            [167721] = { name = L["the_slumbering_emperor"], npcid = 167721, questId = { 60290 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 59304660 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 175711, isKnown = false } }, note = "Use any targetted AOE on the Strange Cloud to dissipate it and aggro the rare. [Phial of Ravenous Slime] works well too." },
            [164147] = { name = L["wrigglemortis"], npcid = 164147, questId = { 59170 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 58306180 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 181396, isKnown = false } }, note = "Pull the Wriggling Tendrill in the area to summon the rare." },
            [163229] = { name = L["dustbrawl"], npcid = 163229, questId = { 58987 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 48397717 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
        },
    },
    [1533] = {
        zonename = "Bastion", -- KYRIAN
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_UNTRACKED,
        currentAssault = 0,
        zonephaseID = 1276, -- ArtID
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!     116?
        hordeContributionMapID = 0, -- Change!        11?
        --homeCoord = { 39965257, 10205301 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 8,
        expansion = EXPANSION.SHADOWLANDS,
        covenantID = COVENANTS.KYRIAN,
        rares = {
            [170548] = { name = L["sundancer"], npcid = 170548, questId = { -1 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 61409050 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 180773, mountID = 1307, isKnown = false } }, note = "Mount on it with a combination of [Sunrider's Blessing] (altar located near one of his spawn areas) and [Skystrider Glider] (from Path of Ascension crafting) to obtain the mount." },
            [170899] = { name = L["the_ascended_council"], npcid = 170899, questId = { 60977 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 53498868 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 183741, mountID = 1426, isKnown = false } }, note = "Ring 5 Vespers of Bastion at the same time to spawn the rares, they will be at the coordinate location. Requires 5 players to ring the Vespers. Kill all 5 rares and loot the Cache of the Ascended for the mount." },
            [170932] = { name = L["cloudfeather_guardian"], npcid = 170932, questId = { 60978, 62191 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 50435804 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 180812, speciesID = 2925, isKnown = false } }, note = "Kill Anima-Starved Cloudfeather in the area to spawn the rare." },
            [163460] = { name = L["dionae"], npcid = 163460, questId = { 62650 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 41354887 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 180856, speciesID = 2932, isKnown = false } }, note = "Talk to the nearby Stewart to start the event and summon the rare." },
            [171012] = { name = L["swelling_tear"], npcid = 171012, questId = { 61001, 61046, 61047 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 39604499 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 180869, speciesID = 2940, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 183605, isKnown = false } }, note = "Click the [Swelling Tear] to summon one of three rares. Tears can appear in multiple locations in the zone." },
            [171009] = { name = L["enforcer_aegeon"], npcid = 171009, questId = { 60998 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 51151953 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 184404, isKnown = false } }, note = "Kill enemies in the surrounding area until Aegeon spawns as a reinforcement." },
            [171008] = { name = L["unstable_memory"], npcid = 171008, questId = { 60997 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 43482524 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 184413, isKnown = false } }, note = "Bring [Unstable Memory Fragments] on top of other fragments until you get 10 stacks of Instability to spawn the rare." },
            [170659] = { name = L["basilofos_king_of_the_hill"], npcid = 170659, questId = { 60897, 62158 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 48985031 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "When approaching the area, you will be marked with purple eyes. Stay marked for ~2 minutes for the rare to spawn." },
            [171211] = { name = L["aspirant_eolis"], npcid = 171211, questId = { 61083 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 32592336 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 183607, isKnown = false } }, note = "Loot a [Fragile Humility Scroll] at the area and use it on Aspirant Eolis to save him." },
            [161527] = { name = L["beasts_of_bastion"], npcid = 161527, questId = { 58526 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 55358024 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 179485, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 179486, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 179487, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 179488, isKnown = false } }, note = "Talk to 'Orator Kloe' to trigger the rare using the hologram next to her." },
            [171189] = { name = L["bookkeeper_mnemis"], npcid = 171189, questId = { 59022 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 55826249 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 182682, isKnown = false } }, note = "Shares a spawn with the [Converted Praetors] in the area. If not up, kill Praetors for the rare to spawn." },
            [170623] = { name = L["dark_watcher"], npcid = 170623, questId = { 60883 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 27823014 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 184297, isKnown = false } }, note = "Go to the coordinate area, if you get the debuff [Ominous Gaze], the rare can be killed. Die to the nearby mobs and find the rare in Spirit form, talk to her and she will revive you, allowing you to kill her." },
            [171011] = { name = L["demi_the_relic_hoarder"], npcid = 171011, questId = { 61069, 61000 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 37004180 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 183606, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 183608, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 183613, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 183611, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 183609, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 183607, isKnown = false } }, note = "Casts [Anima Shield] starting at 99% reduction when engaged. Rare will flee around looking for help. Dealing damage to the rare reduces the effectiveness of Anima Shield." },
            [171255] = { name = L["echo_of_aella"], npcid = 171255, questId = { 61082, 61091, 62251 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 45656550 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 180062, isKnown = false } }, note = "Patrols around the coordinate area. Initially neutral, speak to her to fight it. Loot comes from a chest after she's defeated." },
            [160721] = { name = L["fallen_acolyte_erisne"], npcid = 160721, questId = { 58222 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 60427305 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 180444, isKnown = false } } },
            [160882] = { name = L["nikara_blackheart"], npcid = 160882, questId = { 58319 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 51456859 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 183608, isKnown = false } }, note = "Requires 3 players to channel on the Ancient Incense to summon the rare." },
            [160985] = { name = L["selena_the_reborn"], npcid = 160985, questId = { 58320 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 61295090 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 183608, isKnown = false } }, note = "Requires 3 players to channel on the Ancient Incense to summon the rare." },
            [167078] = { name = L["wingflayer_the_cruel"], covenantBound = COVENANTS.KYRIAN, npcid = 167078, questId = { 60314, 62197 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 40635306 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 182749, isKnown = false } }, note = "Requires a Kyrian member to channel their Anima Conductor into the Temple of Courage to spawn. Once done, use the Horn of Courage to bring the rare down." },
            [160629] = { name = L["baedos"], npcid = 160629, questId = { 58648, 62192 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 51344080 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "Bring [Purians] to the nearby [Baedos' Fruit Barrel] to start the fight. Once Baedos reaches 50%, it will return to its original spawn point and spew a chest with loot." },
            [171014] = { name = L["collector_astorestes"], npcid = 171014, questId = { 61002 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 66004367 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "Requires you to collect tomes in a specific order" },
            [171010] = { name = L["corrupted_clawguard"], npcid = 171010, questId = { 60999 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 56904778 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "Loot a [Discarded Phalynx Core] from Centurions around Bastion and insert it on the rare to trigger it." },
            [158659] = { name = L["herculon"], npcid = 158659, questId = { 57705, 57708 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 42908265 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "Loot [Weak Anima Motes] around the Vestibule of Eternity to power up the rare." },
            [171327] = { name = L["reekmonger"], npcid = 171327, questId = { -1 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 30365517 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [156339] = { name = L["orstus_and_sotiros"], covenantBound = COVENANTS.KYRIAN, npcid = 156339, questId = { 61634 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 22432285 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "Requires a Kyrian member to channel their Anima Conductor into the Citadel of Loyalty to spawn. Once done, go to the location an interact with the Black Bell to spawn the rares." },
        },
    },
    [1536] = {
        zonename = "Maldraxxus", -- NECROLORD
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_UNTRACKED,
        currentAssault = 0,
        zonephaseID = 1276, -- ArtID
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!     116?
        hordeContributionMapID = 0, -- Change!        11?
        --homeCoord = { 39965257, 10205301 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 9,
        expansion = EXPANSION.SHADOWLANDS,
        covenantID = COVENANTS.NECROLORD,
        rares = {
            [162741] = { name = L["gieger"], covenantBound = COVENANTS.NECROLORD, npcid = 162741, questId = { 58872 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 31603540 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 182080, mountID = 1411, covenantBound = COVENANTS.NECROLORD, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 184298, isKnown = false } }, note = "Requires a Necrolord member to channel their Anima Conductor into the House of Constructs to spawn. Once done, pull the Final Threaf by the rare to activate it." },
            [162690] = { name = L["nerissa_heartless"], npcid = 162690, questId = { 58851 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 66023532 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 182084, mountID = 1373, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184179, isKnown = false } } },
            [168147] = { name = L["sabriel_the_bonecleaver"], covenantBound = COVENANTS.NECROLORD, npcid = 168147, questId = { 58784 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 51744439 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 181815, mountID = 1370, covenantBound = COVENANTS.NECROLORD, isKnown = false } }, note = "Has a small chance to spawn in place of one of the common fights in the Theater of Pain. Necrolord members can force this rare to spawn by channeling their Anima Conductor to the Theater of Pain." },
            [162586] = { name = L["tahonta"], npcid = 162586, questId = { 58783 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 44215132 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 182075, mountID = 1366, covenantBound = COVENANTS.NECROLORD, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 182190, isKnown = false } } },
            [162819] = { name = L["warbringer_malkorak"], npcid = 162819, questId = { 58889 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 33718016 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 182085, mountID = 1372, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184288, isKnown = false } } },
            [157226] = { name = L["mixed_monstrosities"], npcid = 157226, questId = { 61718, 61719, 61720, 61721, 61722, 61723, 61724 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 58197421 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 182079, mountID = 1410, isKnown = false }, { droptype = DROPTYPE.PET, itemID = 181270, speciesID = 2960, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 183903, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 184155, checkId = 62804, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184302, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184301, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184300, isKnown = false } }, note = "Gather ingredients from the surrounding mobs and toss them into the pool. Once 30 ingredients have been added, one of seven rares will spawn depending on the combination used. Kill each rare once to earn the toy." },
            [162853] = { name = L["theater_of_pain"], npcid = 162853, questId = { 62786 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 50354728 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 184062, mountID = 1437, isKnown = false } }, note = "Your first boss kill each day has a chance to drop the mount." },
            [162711] = { name = L["deadly_dapperling"], npcid = 162711, questId = { 58868 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 76835707 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 181263, speciesID = 2953, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184280, isKnown = false } } },
            [159753] = { name = L["ravenomous"], npcid = 159753, questId = { 58004 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 53841877 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 181283, speciesID = 2964, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184184, isKnown = false } } },
            [158406] = { name = L["scunner"], npcid = 158406, questId = { 58006 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 62107580 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 181267, speciesID = 2957, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184287, isKnown = false } } },
            [159886] = { name = L["sister_chelicerae"], npcid = 159886, questId = { 58003 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 55502361 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 181172, speciesID = 2948, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184289, isKnown = false } }, note = "Break the [Intricate Webbing] at the entrance of the cave to spawn the rare." },
            [162528] = { name = L["smorgas_the_feaster"], npcid = 162528, questId = { 58768 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 42465345 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 181266, speciesID = 2956, isKnown = false }, { droptype = DROPTYPE.PET, itemID = 181265, speciesID = 2955, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184299, isKnown = false } } },
            [162727] = { name = L["bubbleblood"], npcid = 162727, questId = { 58870 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 52663542 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 184476, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184290, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184154, isKnown = false } } },
            [159105] = { name = L["collector_kash"], npcid = 159105, questId = { 58005 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 49012351 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 184188, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184181, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184189, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184182, isKnown = false } } },
            [157058] = { name = L["corpsecutter_moroc"], npcid = 157058, questId = { 58335 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 26392633 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 184177, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 184176, isKnown = false } } },
            [162797] = { name = L["deepscar"], npcid = 162797, questId = { 58878 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 46734550 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 182191, isKnown = false } }, note = "Can spawn in any of the 3 inner towers in the Theater of Pain area." },
            [162669] = { name = L["devourus"], npcid = 162669, questId = { 58835 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 45052842 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 184178, isKnown = false } } },
            [162588] = { name = L["gristlebeak"], npcid = 162588, questId = { 58837 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 57795155 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 182196, isKnown = false } }, note = "Flies high up in the air. Find and break [Unusual Eggs] to bring the rare down." },
            [161105] = { name = L["indomitable_schmitd"], npcid = 161105, questId = { 58332 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 38794333 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 182192, isKnown = false } }, note = "Break his Imunity Shield by throwing [Fuseless Special] bombs around his area onto him." },
            [174108] = { name = L["necromantic_anomaly"], npcid = 174108, questId = { 62369 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 72872891 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 181810, isKnown = false } } },
            [161857] = { name = L["nirvaska_the_summoner"], npcid = 161857, questId = { 58629 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 50346328 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 183700, isKnown = false } }, note = "Only available during the [Deadly Reminder] World Quest." },
            [162767] = { name = L["pesticide"], npcid = 162767, questId = { 58875 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 53726132 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 182205, isKnown = false } } },
            [160059] = { name = L["taskmaster_xox"], npcid = 160059, questId = { 58091 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 50562011 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 184186, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 184192, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 184187, isKnown = false } }, note = "Shares a spawn with Taskmaster Mortis, Taskmaster Bloata and Taskmaster Joyless. If not up, simply kill taskmaster until it spawns." },
            [162180] = { name = L["thread_mistress_leeda"], npcid = 162180, questId = { 58678 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 24184297 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 184180, isKnown = false } }, note = "Kill [Razorthread Weavers] around the coordinate area to spawn the rare." },
            [157125] = { name = L["zargox_the_reborn"], npcid = 157125, questId = { 59290 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 28965138 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 184285, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 181804, covenantBound = COVENANTS.NECROLORD, isKnown = false } }, note = "To spawn this rare, complete the quest [Ani-Matter Animator], then grab an [Ani-Matter Orb] from Synder Sixfold and use it at the bone pile at the coordinate location." },
        },
    },
    [1525] = {
        zonename = "Revendreth", -- VENTHYR
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_UNTRACKED,
        currentAssault = 0,
        zonephaseID = 1276, -- ArtID
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!     116?
        hordeContributionMapID = 0, -- Change!        11?
        --homeCoord = { 39965257, 10205301 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 10,
        expansion = EXPANSION.SHADOWLANDS,
        covenantID = COVENANTS.VENTHYR,
        rares = {
            [166521] = { name = L["famu_the_infinite"], npcid = 166521, questId = { 59869 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 62484716 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 180582, mountID = 1379, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 183739, isKnown = false } } },
            [165290] = { name = L["harika_the_horrid"], covenantBound = COVENANTS.VENTHYR, npcid = 165290, questId = { 59612 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 45847919 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 180461, mountID = 1310, covenantBound = COVENANTS.VENTHYR, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 183720, isKnown = false } }, note = "Repair and use the nearby [Dredterror Ballista] to activate the rare." },
            [166679] = { name = L["hopecrusher"], npcid = 166679, questId = { 59900 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 51985179 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 180581, mountID = 1298, covenantBound = COVENANTS.VENTHYR, isKnown = false } } },
            [166292] = { name = L["bog_beast"], npcid = 166292, questId = { 59823 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 35003230 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 180588, speciesID = 2896, isKnown = false } }, note = "During the World Quest [Muck It] Up, Using [Primordial Muck] has a chance to spawn the rare." },
            [165152] = { name = L["leeched_soul"], npcid = 165152, questId = { 59580 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 67978179 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 180585, speciesID = 2897, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 183736, isKnown = false } }, note = "Complete the RP event to earn the loot." },
            [170048] = { name = L["manifestation_of_wrath"], npcid = 170048, questId = { 60729 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 49003490 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 180585, speciesID = 2897, isKnown = false } }, note = "During the World Quest [Swarming Souls], Recovering Lost Souls has a chance to spawn the rare." },
            [160675] = { name = L["scrivener_lenua"], npcid = 160675, questId = { 58213 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 38316914 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 180587, speciesID = 2893, isKnown = false } }, note = "Grab multiple [Forbidden Tomes] in the area and bring them to the Forbidden Library to spawn the rare." },
            [155779] = { name = L["tomb_burster"], npcid = 155779, questId = { -1 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 43007910 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 180584, speciesID = 2891, isKnown = false } }, note = "Kill all [Crawler Eggs] in the area to trigger an event - Rare will spawn after a few waves of spider mobs." },
            [160857] = { name = L["sire_ladinas"], npcid = 160857, questId = { 58263 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 34045555 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 180873, isKnown = false } }, note = "Pick up a [Remnant of Light] nearby and use it on [Crazed Ash Ghoul]." },
            [165253] = { name = L["tollkeeper_varaboss"], npcid = 165253, questId = { 59595 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 66507080 }, bothphases = true, loot = { { droptype = DROPTYPE.QUEST, itemID = 179363, checkId = 60517, isKnown = false } } },
            [160821] = { name = L["worldedge_gorger"], npcid = 160821, questId = { 58259 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 38607200 }, bothphases = true, loot = { { droptype = DROPTYPE.QUEST, itemID = 180583, checkId = 61188, isKnown = false } }, note = "Obtain an [Enticing Anima] from World Reavers, Devourers and Mites in the Banewood and the Endmire. Use it to light the Worldedge Braziers and summon the rare." },
            [166393] = { name = L["amalgamation_of_filth"], npcid = 166393, questId = { 59854 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 53247300 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 183729, isKnown = false } }, note = "Only available during the World Quest [Dirty Job: Demolition Detail]." },
            [164388] = { name = L["amalgamation_of_light"], npcid = 164388, questId = { 59584 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 25304850 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 179926, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 179924, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 179653, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 179925, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 180688, isKnown = false } }, note = "Unlock the 3 Light Prisons at the vignette area to spawn the rare." },
            [170434] = { name = L["amalgamation_of_sin"], npcid = 170434, questId = { 60836 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 65782914 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 183730, isKnown = false } }, note = "During the World Quest [Summon Your Sins], pick the [Catalyst of Power] for a chance to obtain [Amalgamation of Sin], then use the item to summon the rare." },
            [166576] = { name = L["azgar"], npcid = 166576, questId = { 59893 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 35817052 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 183731, isKnown = false } } },
            [165206] = { name = L["endlurker"], npcid = 165206, questId = { 59582 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 66555946 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 179927, isKnown = false } }, note = "Loot a nearby [Anima Stake] and use it on the portal to spawn the rare." },
            [166710] = { name = L["executioner_aatron"], npcid = 166710, questId = { 59913 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 37084742 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 183737, isKnown = false } }, note = "Defeat the 3 [Stone Legion Punisher] in his area to remove his immunity shield." },
            [161310] = { name = L["executioner_adrastia"], npcid = 161310, questId = { 58441 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 43055183 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 180502, isKnown = false } } },
            [159496] = { name = L["forgemaster_madalav"], covenantBound = COVENANTS.VENTHYR, npcid = 159496, questId = { 61618 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 32641545 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 180939, isKnown = false } }, note = "Click Madalav's Hammer on the nearby anvil to summon him." },
            [167464] = { name = L["grand_arcanist_dimitri"], npcid = 167464, questId = { 60173 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 20485298 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 180503, isKnown = false } }, note = "Inside the mansion. Kill the 4 [Shrouded Ritualist] channeling the nearby corpse to spawn the rare." },
            [166993] = { name = L["huntmaster_petrus"], npcid = 166993, questId = { 60022 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 61717949 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 180705, isKnown = false } } },
            [160640] = { name = L["innervus"], npcid = 160640, questId = { 58210 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 21803590 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 183735, isKnown = false } }, note = "Inside a locked crypt. Loot [Scorched Crypt Key] from nearby 'Feral Ritualists' to unlock it." },
            [161891] = { name = L["lord_mortegore"], npcid = 161891, questId = { 58633 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 75976161 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 180501, isKnown = false } }, note = "Loot 4 [Mortegore Scrolls] from mobs in the area and use it on the sigils in the area to spawn the rare." },
            [162481] = { name = L["sinstone_hoarder"], npcid = 162481, questId = { 62252 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 67443048 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 183732, isKnown = false } }, note = "Attempt to loot the [Catacombs Cache] and the rare will reveal itself." },
            [159503] = { name = L["stonefist"], npcid = 159503, questId = { 62220 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 31312324 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 180488, isKnown = false } } },
            [160392] = { name = L["soulstalker_doina"], npcid = 160392, questId = { 58130 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 78934975 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "Inside a tower in Halls of Atonement. Will run away from you and go through Blood Mirrors at 75% and 40%, and needs to be followed." },
        },
    },
    [1543] = {
        zonename = "The Maw", -- self.phased = C_QuestLog.IsQuestFlaggedCompleted(62907)
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_UNTRACKED,
        currentAssault = 0,
        zonephaseID = 1276, -- ArtID
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!     116?
        hordeContributionMapID = 0, -- Change!        11?
        --homeCoord = { 39965257, 10205301 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 11,
        expansion = EXPANSION.SHADOWLANDS,
        --covenantID = COVENANTS.NONE,
        rares = {
            [154330] = { name = L["eternas_the_tormentor"], npcid = 154330, questId = { 57509 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 19194608 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 183407, speciesID = 3037, isKnown = false } } },
            [157833] = { name = L["borr-geth"], npcid = 157833, questId = { 57469 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 39014119 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 184312, isKnown = false } } },
            [162849] = { name = L["morguliax_lord_of_decapitation"], npcid = 162849, questId = { 60987 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 16945102 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 184292, isKnown = false } } },
            [172577] = { name = L["orophea"], npcid = 172577, questId = { 61519 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 23692139 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 181794, isKnown = false } }, note = "Pick up [Eurydea's Necklace] to the southeast and it to activate the Rare." },
            [170303] = { name = L["exos_herald_of_domination"], npcid = 170303, questId = { 62260 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 20586935 }, bothphases = true, loot = { { droptype = DROPTYPE.QUEST, itemID = 183066, checkId = 63160, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 183067, checkId = 63161, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 183068, checkId = 63162, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 184108, isKnown = false } }, note = "Kill the other three Heralds of Grief, Pain and Loss to collect their etchings. Combine all three etchings to create the [Domination's Calling], which can be used to summon the rare at the Altar of Domination." },
            [170634] = { name = L["shadeweaver_zeris"], npcid = 170634, questId = { 60884 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 32946646 }, bothphases = true, loot = { { droptype = DROPTYPE.QUEST, itemID = 183066, checkId = 63160, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 183067, checkId = 63161, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 183068, checkId = 63162, isKnown = false } } },
            [170301] = { name = L["apholeias_herald_of_loss"], npcid = 170301, questId = { 60788 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 19324172 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 184106, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 182327, isKnown = false } }, note = "With 3 other players, stand on the corners of the platform and cast [Convocation of Loss] to summon the rare." },
            [171317] = { name = L["conjured_death"], npcid = 171317, questId = { 61106 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 27731305 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 183887, isKnown = false } } },
            [169827] = { name = L["ekphoras_herald_of_grief"], npcid = 169827, questId = { 60666 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 42342108 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 184105, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 182328, isKnown = false } }, note = "With 3 other players, stand on the corners of the platform and cast [Convocation of Grief] to summon the rare." },
            [170302] = { name = L["talaporas_herald_of_pain"], npcid = 170302, questId = { 60789 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 28701204 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 184107, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 182326, isKnown = false } } },
            [157964] = { name = L["adjutant_dekaris"], npcid = 157964, questId = { 57482 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 25923116 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "On top of a large jutting rock." },
            [160770] = { name = L["darithis_the_bleak"], npcid = 160770, questId = { 62281 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 60964805 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "In cave" },
            [158025] = { name = L["darklord_taraxis"], npcid = 158025, questId = { 62282 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 49128175 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [170711] = { name = L["dolos_deaths_knife"], npcid = 170711, questId = { 60909 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 28086058 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [170774] = { name = L["eketra_the_impaler"], npcid = 170774, questId = { 60915 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 28086058 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [175012] = { name = L["ikras_the_devourer"], npcid = 175012, questId = { 62788 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 30775000 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "Flies around Perdition Hold. This is a good place to pull him." },
            [158278] = { name = L["nascent_devourer"], npcid = 158278, questId = { 57573 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 45507376 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "In small cave" },
            [164064] = { name = L["obolos_prime_adjutant"], npcid = 164064, questId = { 60667 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 48801830 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [166398] = { name = L["soulforger_rhovus"], npcid = 166398, questId = { 60834 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 35974156 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [170731] = { name = L["thanassos_deaths_voice"], npcid = 170731, questId = { 60914 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 27397152 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [172862] = { name = L["yero_the_skittish"], npcid = 172862, questId = { 61568 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 37676591 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "Approach the Rare and then follow him down into a nearby cave where he becomes hostile." },
            [168693] = { name = L["cyrixia_the_willbreaker"], npcid = 168693, questId = { 61346 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 28712513 }, bothphases = true, loot = { { droptype = DROPTYPE.QUEST, itemID = 183070, checkId = 63164, isKnown = false } } },
            [162844] = { name = L["dath_rezara_lord_of_blades"], npcid = 162844, questId = { 61140 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 19205740 }, bothphases = true, loot = { { droptype = DROPTYPE.QUEST, itemID = 183066, checkId = 63160, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 183067, checkId = 63161, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 183068, checkId = 63162, isKnown = false } } },
            [169102] = { name = L["agonix"], npcid = 169102, questId = { 61136 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 28204450 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [170787] = { name = L["akros_deaths_hammer"], npcid = 170787, questId = { 60920 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 34087453 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [162452] = { name = L["dartanos_flayer_of_souls"], npcid = 162452, questId = { 59230 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 25831479 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "On the upper platforms of the Tremaculum. Use the teleport pad in the area to reach the event area." },
            [158314] = { name = L["drifting_sorrow"], npcid = 158314, questId = { 59183 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 31982122 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "Kill [Agonizing Shade] near the hovering orb to activate the boss." },
            [172523] = { name = L["houndmaster_vasanok"], npcid = 172523, questId = { 62209 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 60456478 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [162965] = { name = L["huwerath"], npcid = 162965, questId = { 58918 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 20782968 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [170692] = { name = L["krala_deaths_wings"], npcid = 170692, questId = { 60903 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 30846866 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [171316] = { name = L["malevolent_stygia"], npcid = 171316, questId = { 61125 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 27311754 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "In small cave" },
            [172207] = { name = L["odalrik"], npcid = 172207, questId = { 62618 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 38642880 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [162845] = { name = L["orrholyn_lord_of_bloodletting"], npcid = 162845, questId = { 60991 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 25364875 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [175821] = { name = L["ratgusher"], npcid = 175821, questId = { 63044 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 22674223 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, cave = { coord = { 20813927 } }, note = "In cave" },
            [162829] = { name = L["razkazzar_lord_of_axes"], npcid = 162829, questId = { 60992 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 26173744 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [172521] = { name = L["sanngror_the_torturer"], npcid = 172521, questId = { 62210 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 55626318 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, cave = { coord = { 55806753 } }, note = "If he is not attackable, wait until he is not experimenting on souls." },
            [172524] = { name = L["skittering_broodmother"], npcid = 172524, questId = { 62211 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 61737795 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, cave = { coord = { 59268001 } }, note = "In cave" },
            [165047] = { name = L["soulsmith_yol-mattar"], npcid = 165047, questId = { 59441 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 36253744 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [156203] = { name = L["stygian_incinerator"], npcid = 156203, questId = { 62539 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 36844480 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } } },
            [173086] = { name = L["valis_the_cruel"], npcid = 173086, questId = { 61728 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 40705959 }, bothphases = true, loot = { { droptype = DROPTYPE.ANIMA_ONLY, itemID = 0, isKnown = false } }, note = "Interact with the 3 [Rune of Cruelty] in the area to spawn the event. The runes inflict [Cruel Rebuke], so be careful to not die." },
            -- Added in Patch 9.1
            [179460] = { name = L["fallen_charger"], npcid = 179460, questId = { 64164 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 17714953 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 186659, mountID = 1502, isKnown = false } }, note = "Is located at the same location as the rare [Cyrixia] in the normal Maw phase." },
            [179779] = { name = L["deomen_the_vortex"], npcid = 179779, questId = { 64251 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 61334129 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 187385, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187367, isKnown = false } }, note = "Locked behind a cage. To unlock the rare, enter the building to the left of its cage and find the two levers." },
            [179805] = { name = L["traitor_balthier"], npcid = 179805, questId = { 64258 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 69044897 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 187364, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187374, isKnown = false } } },
            [177444] = { name = L["yiva"], npcid = 177444, questId = { 64152 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 66404400 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 186970, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187359, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 186217, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187393, isKnown = false } } },
            [179851] = { name = L["guard_orguluus"], npcid = 179851, questId = { 64272 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 49307274 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 187363, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187398, isKnown = false } }, note = "Initially not interactable, requires someone with [Repaired Riftkey] to go inside the Rift and pull the rare out of the rift." },
            [179853] = { name = L["blinding_shadow"], npcid = 179853, questId = { 64276 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 36034433 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 187406, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187361, isKnown = false } }, note = "Initially not interactable, requires someone with [Repaired Riftkey] to go inside the Rift and pull the rare out of the rift." },
            [179735] = { name = L["torglluun"], npcid = 179735, questId = { 64232 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 27672526 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 187139, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 186605, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187360, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187389, isKnown = false } }, note = "Initially not interactable, requires someone with [Repaired Riftkey] to go inside the Rift and pull the rare out of the rift." },
        },
    },
    [1961] = {
        zonename = "Korthia", -- 
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_UNTRACKED,
        currentAssault = 0,
        zonephaseID = 1276, -- ArtID
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!    
        hordeContributionMapID = 0, -- Change!       
        --homeCoord = { 39965257, 10205301 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 12,
        expansion = EXPANSION.SHADOWLANDS,
        --covenantID = COVENANTS.NONE,
        rares = {
            [180246] = { name = L["carriage_crusher"], npcid = 180246, questId = { 64258 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 58211773 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 187370, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187399, isKnown = false } }, note = "Spawns at the bridge between the Beastwarrens and the main Maw area once the announced The Assault Caravan event ends." },
            [179768] = { name = L["consumption"], npcid = 179768, questId = { 64243 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 51164167 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 187402, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187245, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187246, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187247, isKnown = false } }, note = "This rare absorbs critters around the area to increase its size. Only the Rare Elite version with 40+ stacks will count as a rare kill.", warning = "This rare is not available on some days." },
            [177903] = { name = L["dominated_protector"], npcid = 177903, questId = { 63830 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 51822081 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 187390, isKnown = false } } },
            [179684] = { name = L["malbog"], npcid = 179684, questId = { 64233 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 44222950 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 186645, mountID = 1506, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187377, isKnown = false } }, note = "Talk to [Caretaker Kah-Kay] to gain the Buff [Sharp-eyed] and follow the foot prints until you find the fleshy remains.", warning = "This rare is not available on some days." },
            [179108] = { name = L["kroke_the_tormented"], npcid = 179108, questId = { 64428 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 59203580 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 187394, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187248, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187250, isKnown = false } }, note = "Patrols around the Scholar's Den area.", warning = "This rare is not available on some days." },
            [179760] = { name = L["towering_exterminator"], npcid = 179760, questId = { 64245 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 16007500 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 187241, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187242, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187035, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187392, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187382, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187376, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187373, isKnown = false } }, note = "Spawns from a mawsworn portal event. The event can appear in many places throughout Korthia." },
            [179472] = { name = L["konthrogz_the_obliterator"], npcid = 179472, questId = { 64246 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 13007500 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 187183, mountID = 1514, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187397, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187384, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187378, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187375, isKnown = false } }, note = "Spawns from a devourer's portal event. The event can appear in many places throughout Korthia." },
            [180162] = { name = L["verayn"], npcid = 180162, questId = { 64457 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 14507900 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 187264, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 187404, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187369, isKnown = false } }, note = "Can be located inside several caves in Korthia. When spawned, the rare will give you a quiz. Any responses will eventually lead the rare to become hostile and attack you." },
            [180160] = { name = L["reliwik_the_defiant"], npcid = 180160, questId = { 64455 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 56276617 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 186652, mountID = 1509, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187388, isKnown = false } }, note = "Touch the Uncorrupted Razorwing Egg at the nest by the area to bring the rare down.", warning = "This rare is not available on some days." },
            [180032] = { name = L["wild_worldcracker"], npcid = 180032, questId = { 64338 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 56873237 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 186483, mountID = 1493, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 187423, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 187176, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187380, isKnown = false } }, note = "Talk to [PoPo] to trigger the escort event." },
            [179931] = { name = L["relic_breaker_krelva"], npcid = 179931, questId = { 64291 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 22604140 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 187403, isKnown = false } }, note = "Moves to another platform at 80%, then moves to the mainland at 60%. You must tag the rare after 60% to get kill credit!" },
            [177336] = { name = L["zelnithop"], npcid = 177336, questId = { 64442 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 27755885 }, bothphases = true, loot = { { droptype = DROPTYPE.PET, itemID = 186542, speciesID = 3136, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187371, isKnown = false } }, cave = { coord = { 30385480 } }, note = "At the back of a cave full of Shardhide mobs. The coordinates lead to the cave entrance.", warning = "This rare is not available on some days." },
            [180042] = { name = L["fleshwing_lord_of_the_heap"], npcid = 180042, questId = { 64349 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 59934371 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 186489, mountID = 1449, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 187424, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187372, isKnown = false } }, note = "Talk to [Cadaverous] to start the collection event." },
            [180014] = { name = L["escaped_wilderling"], npcid = 180014, questId = { 64320 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 33183938 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 186492, mountID = 1487, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 187423, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187395, isKnown = false } }, note = "Click on the [Escaped Wilderling] to start the taming event." },
            [179985] = { name = L["stygian_stonecrusher"], npcid = 179985, questId = { 64313 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 46507959 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 187428, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 186479, isKnown = false } }, note = "Talk to [Drippy] to start the event." },
            [179802] = { name = L["yarxhov_the_pillager"], npcid = 179802, questId = { 64257 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 39405240 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 187103, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187391, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187366, isKnown = false } }, note = "Requires someone at Rank 3 with the Archivist's Codex to use a [Teleporter Repair Kit] at the location to repair the teleporter." },
            [179859] = { name = L["xyraxz_the_unknowable"], npcid = 179859, questId = { 64278 }, type = RARETYPE.UNCOMMON, faction = FACTION.ALL, coord = { 44983552 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 187104, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187387, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187368, isKnown = false } }, note = "Requires someone at Rank 3 with the Archivist's Codex to use a [Teleporter Repair Kit] at the location to repair the teleporter." },
            [179914] = { name = L["observer_yorik"], npcid = 179914, questId = { 64369 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 50307590 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 187420, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 187405, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187365, isKnown = false } }, note = "Initially not interactable, requires someone with [Repaired Riftkey] to go inside the Rift and pull the rare out of the rift." },
            [179911] = { name = L["silent_soulstalker"], npcid = 179911, questId = { 64284 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 57607040 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 187381, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187383, isKnown = false } }, note = "Initially not interactable, requires someone with [Repaired Riftkey] to go inside the Rift and pull the rare out of the rift." },
            [179608] = { name = L["screaming_shade"], npcid = 179608, questId = { 64263 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 44604240 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 187400, isKnown = false } }, note = "Initially not interactable, requires someone with [Repaired Riftkey] to go inside the Rift and pull the rare out of the rift." },
            [179913] = { name = L["deadsoul_hatcher"], npcid = 179913, questId = { 64285 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 59335221 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 187174, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 187401, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 187396, isKnown = false } }, note = "Initially not interactable, requires someone with [Repaired Riftkey] to go inside the Rift and pull the rare out of the rift." },
        },
    },
    [1970] = { -- Parent mapID 1550 (Shadowlands main Map)
        zonename = "Zereth Mortis", -- 
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_UNTRACKED,
        currentAssault = 0,
        zonephaseID = 1650, -- ArtID
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!    
        hordeContributionMapID = 0, -- Change!       
        --homeCoord = { 39965257, 10205301 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 14,
        expansion = EXPANSION.SHADOWLANDS,
        --covenantID = COVENANTS.NONE,
        rares = {
            [179006] = { name = L["akkaris"], npcid = 179006, questId = { 65552 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 64743369 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189903, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189958, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190053, isKnown = false } } },
            [183596] = { name = L["chitali_the_eldest"], npcid = 183596, questId = { 65553 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 49566751 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189947, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189906, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189994, isKnown = false } } },
            [183953] = { name = L["corrupted_architect"], npcid = 183953, questId = { 65273 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 47486228 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189907, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189940, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190009, isKnown = false } }, note = L["corrupted_architect_note"] },
            [180917] = { name = L["destabilized_core"], npcid = 180917, questId = { 64716 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 53634435 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189910, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189930, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189985, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189999, isKnown = false } } },
            [184409] = { name = L["euvouk"], npcid = 184409, questId = { 65555 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 47474516 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189949, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189956, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190047, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189993, isKnown = false } } },
            [178229] = { name = L["feasting"], npcid = 178229, questId = { 65557 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 61826060 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189969, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189970, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189936, isKnown = false } }, note = L["feasting_note"] },
            [183646] = { name = L["furidian"], npcid = 183646, questId = { 65544 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 64585865 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189920, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189932, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189963, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190004, isKnown = false } }, note = L["furidian_note"] },
            [180924] = { name = L["garudeon"], npcid = 180924, questId = { 64719 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 69073662 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189951, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189937, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190057, isKnown = false } }, note = L["garudeon_note"] },
            [182318] = { name = L["general_zarathura"], npcid = 182318, questId = { 65583 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 59862111 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189968, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189948, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190125, isKnown = false } } },
            [178778] = { name = L["gluttonous_overgrowth"], npcid = 178778, questId = { 65579 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 53089305 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189929, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189953, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190008, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190049, isKnown = false } }, note = L["gluttonous_overgrowth_note"] },
            [178963] = { name = L["gorkek"], npcid = 178963, questId = { 63988 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 80384706 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189926, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189960, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190001, isKnown = false } } },
            [178563] = { name = L["hadeon_the_stonebreaker"], npcid = 178563, questId = { 65581 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 52612503 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189919, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189942, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190051, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190000, isKnown = false } } },
            [183748] = { name = L["helmix"], npcid = 183748, questId = { 65551 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 58186837 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189931, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189965, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190054, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190056, isKnown = false } }, note = L["helmix_note"] },
            [180978] = { name = L["hirukon"], npcid = 180978, questId = { 65548 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 52287541 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 187676, mountID = 1434, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189905, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189946, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190005, isKnown = false } } },
            [183814] = { name = L["otaris_the_provoked"], npcid = 183814, questId = { 65257 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 58654039 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189909, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189945, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189957, isKnown = false } }, cave = { coord = { 58723789 } }, note = L["in_small_cave"] },
            [178508] = { name = L["mother_phestis"], npcid = 178508, questId = { 65547 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 54083493 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189923, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189950, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189769, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190045, isKnown = false } }, cave = { coord = { 55963261 } }, note = L["in_cave"] },
            [179043] = { name = L["orixal"], npcid = 179043, questId = { 65582 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 55736915 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189912, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189934, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189952, isKnown = false } }, note = L["orixal_note"] },
            [183746] = { name = L["otiosen"], npcid = 183746, questId = { 65556 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 43308762 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189914, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189925, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190046, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189995, isKnown = false } } },
            [180746] = { name = L["protector_of_the_first_ones"], npcid = 180746, questId = { 64668 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 38872762 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189961, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189984, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190002, isKnown = false } }, note = L["protector_of_the_first_ones_note"] },
            [183927] = { name = L["sand_matriarch_ileus"], npcid = 183927, questId = { 65574 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 53384707 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189927, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189955, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189998, isKnown = false } } },
            [184413] = { name = L["shifting_stargorger"], npcid = 184413, questId = { 65549 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 42302099 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189908, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189916, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189941, isKnown = false }, { droptype = DROPTYPE.QUEST, itemID = 189972, checkId = 65505, covenantBound = COVENANTS.NIGHTFAE, isKnown = false } } },
            [183722] = { name = L["sorranos"], npcid = 183722, questId = { 65240 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 35877121 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189911, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189944, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189962, isKnown = false } } },
            [183925] = { name = L["tahkwitz"], npcid = 183925, questId = { 65272 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 49783914 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189915, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189933, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189954, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190003, isKnown = false } } },
            [181249] = { name = L["tethos"], npcid = 181249, questId = { 65550 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 54507344 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189967, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189928, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189966, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190055, isKnown = false } } },
            [183516] = { name = L["the_engulfer"], npcid = 183516, questId = { 65580 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 43947530 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189913, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189921, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190006, isKnown = false } }, note = L["the_engulfer_note"] },
            [181360] = { name = L["vexis"], npcid = 181360, questId = { 65239 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 39555737 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189900, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189959, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189997, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190048, isKnown = false } } },
            [183747] = { name = L["vitiane"], npcid = 183747, questId = { 65584 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 47044698 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189901, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189922, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189935, isKnown = false } } },
            [183737] = { name = L["xyrath_the_covetous"], npcid = 183737, questId = { 65241 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 64054975 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189918, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189964, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190052, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 190007, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 190238, isKnown = false } } },
            [183764] = { name = L["zatojin"], npcid = 183764, questId = { 65251 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 43513294 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189902, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189924, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 189939, isKnown = false } }, note = L["zatojin_note"] },
        },
    },
    --DragonFlight
    [2022] = { -- Parent mapID 1978 (Dragonflight Main Map)
        zonename = "The Waking Shores", -- 
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_UNTRACKED,
        currentAssault = 0,
        zonephaseID = 1706, -- ArtID
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!    
        hordeContributionMapID = 0, -- Change!       
        --homeCoord = { 39965257, 10205301 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 15,
        expansion = EXPANSION.DRAGONFLIGHT,
        rares = {
            [193118] = { name = L["onank_shorescour"], npcid = 193118, questId = { 74017 }, type = RARETYPE.WORLDBOSS, faction = FACTION.ALL, coord = { 81485082 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200684, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200203, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200151, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200435, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197022, checkId = 69222, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197608, checkId = 69812, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197589, checkId = 69793, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197149, checkId = 69350, isKnown = false } } },
            [187111] = { name = L["ancient_hornswog"], npcid = 187111, questId = { 72835 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 77302198 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200165, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200682, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197403, checkId = 69604, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196992, checkId = 69192, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } }, cave = { coord = { 77902281 } }, note = L["in_small_cave"] },
            [193198] = { name = L["captain_lancer"], npcid = 193198, questId = { 73075 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 26847642 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200169, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200286, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200757, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197019, checkId = 69219, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197005, checkId = 69205, isKnown = false } }, note = L["captain_lancer_note"] },
            [193708] = { name = L["skald_the_impaler"], npcid = 193708, questId = { 74078 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 33886446 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200133, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200247, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false } }, note = L["skald_the_impaler_note"] },
            [195915] = { name = L["firava_the_rekindler"], npcid = 195915, questId = { 70648 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 54582137 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200252, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200133, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200247, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197379, checkId = 69580, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197135, checkId = 69336, isKnown = false } } },
            [196056] = { name = L["gushgut_the_beaksinker"], npcid = 196056, questId = { 73879 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 52345829 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200245, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200187, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197098, checkId = 69299, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197001, checkId = 69201, isKnown = false } } },
            [187306] = { name = L["morchok"], npcid = 187306, questId = { 74067 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 32805248 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200244, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200246, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200683, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197624, checkId = 69828, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196991, checkId = 69191, isKnown = false } }, note = L["obsidian_citadel_rare_note"] },
            [190985] = { name = L["deaths_shadow"], npcid = 190985, questId = { 73074 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 31785474 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200133, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200247, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200252, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197379, checkId = 69580, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197135, checkId = 69336, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false } }, note = L["obsidian_citadel_rare_note"] },
            [193152] = { name = L["massive_magmashell"], npcid = 193152, questId = { 74012 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 22207649 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200192, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200133, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200247, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200252, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200151, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200435, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197022, checkId = 69222, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197589, checkId = 69793, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197379, checkId = 69580, isKnown = false } } },
            [186783] = { name = L["cauldronbearer_blakor"], npcid = 186783, questId = { 74042 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 30575625 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200169, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200757, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197019, checkId = 69219, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197005, checkId = 69205, isKnown = false } } },
            [193271] = { name = L["shadeslash_trakken"], npcid = 193271, questId = { 74076 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 46997332 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200152, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200297, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196999, checkId = 69199, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197116, checkId = 69317, isKnown = false } }, cave = { coord = { 47727466 } }, note = L["shadeslash_trakken_note"] },
            [193134] = { name = L["enkine_the_voracious"], npcid = 193134, questId = { 73072 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 21626478 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200167, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200247, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200252, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197379, checkId = 69580, isKnown = false } }, note = L["enkine_the_voracious_note"] },
            [189289] = { name = L["penumbrus"], npcid = 189289, questId = { 74019 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 24135392 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200244, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200246, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200683, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196991, checkId = 69191, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197624, checkId = 69828, isKnown = false } }, cave = { coord = { 27226096 } }, note = L["obsidian_throne_rare_note"] },
            [193217] = { name = L["drakewing"], npcid = 193217, questId = { 73874 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 60204535 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200219, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } } },
            [193181] = { name = L["skewersnout"], npcid = 193181, questId = { 73895 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 42892832 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200132, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200151, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197022, checkId = 69222, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197589, checkId = 69793, isKnown = false } } },
            [186200] = { name = L["harkyn_grymstone"], npcid = 186200, questId = { 74000 }, type = RARETYPE.WORLDBOSS, faction = FACTION.ALL, coord = { 42203960 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200171, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200175, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200243, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197131, checkId = 69332, isKnown = false } } },
            [191611] = { name = L["dragonhunter_igordan"], npcid = 191611, questId = { 72838 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 64173289 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200169, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200757, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197019, checkId = 69219, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197005, checkId = 69205, isKnown = false } } },
            [193171] = { name = L["terillod_the_devout"], npcid = 193171, questId = { 72850 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 60598285 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200208, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200292, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200306, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200313, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200314, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200198, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197606, checkId = 69810, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197372, checkId = 69573, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197383, checkId = 69584, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197602, checkId = 69806, isKnown = false } } },
            [184853] = { name = L["primal_scythid_queen"], npcid = 184853, questId = { 72843 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 81133794 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200244, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false } }, cave = { coord = { 81713719 } }, note = L["in_small_cave"] },
            [187209] = { name = L["klozicc_the_ascended"], npcid = 187209, questId = { 72841 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 54728225 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200199, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200244, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200246, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200253, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200254, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200292, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200293, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200294, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200313, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200439, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200683, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200198, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196991, checkId = 69191, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197023, checkId = 69223, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197624, checkId = 69828, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197383, checkId = 69584, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197602, checkId = 69806, isKnown = false } } },
            [186859] = { name = L["worldcarver_atir"], npcid = 186859, questId = { 74090 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 30025534 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200683, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200213, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200133, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200247, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200252, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197379, checkId = 69580, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197135, checkId = 69336, isKnown = false } }, note = L["worldcarver_atir_note"] },
            [187886] = { name = L["turboris"], npcid = 187886, questId = { 74054 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 33525576 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200246, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200683, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200244, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197624, checkId = 69828, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196991, checkId = 69191, isKnown = false } }, note = L["in_small_cave"] },
            [193148] = { name = L["thunderous_matriarch"], npcid = 193148, questId = { 73899 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 45453540 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false } } },
            [187945] = { name = L["anhydros_the_tidetaker"], npcid = 187945, questId = { 73865 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 58634021 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200245, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197098, checkId = 69299, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197001, checkId = 69201, isKnown = false } } },
            [187598] = { name = L["rohzor_forgesmash"], npcid = 187598, questId = { 74052 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 30736110 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200169, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200757, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197005, checkId = 69205, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197019, checkId = 69219, isKnown = false } } },
            [193256] = { name = L["nulltheria_the_void_gazer"], npcid = 193256, questId = { 73888 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 56004592 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200165, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200256, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200310, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197403, checkId = 69604, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197382, checkId = 69583, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196992, checkId = 69192, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196985, checkId = 69185, isKnown = false } } },
            [193228] = { name = L["snappy"], npcid = 193228, questId = { 73997 }, type = RARETYPE.WORLDBOSS, faction = FACTION.ALL, coord = { 78514999 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200281, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200151, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200435, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197589, checkId = 69793, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197022, checkId = 69222, isKnown = false } } },
            [190986] = { name = L["battlehorn_pyrhus"], npcid = 190986, questId = { 74040 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 28635882 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200247, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200252, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197135, checkId = 69336, isKnown = false } } },
            [193132] = { name = L["amethyzar_the_glittering"], npcid = 193132, questId = { 73981 }, type = RARETYPE.WORLDBOSS, faction = FACTION.ALL, coord = { 63695509 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200244, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200246, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200683, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196991, checkId = 69191, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197624, checkId = 69828, isKnown = false } } },
            [193120] = { name = L["smogswog_the_firebreather"], npcid = 193120, questId = { 74031 }, type = RARETYPE.WORLDBOSS, faction = FACTION.ALL, coord = { 69486653 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200209, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200133, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200247, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200252, isKnown = false } } },
            [193175] = { name = L["slurpo_the_incredible_snail"], npcid = 193175, questId = { 74079 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 34578950 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200189, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200245, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200187, isKnown = false } }, cave = { coord = { 36028984 } }, note = L["slurpo_the_incredible_snail_note"] },
            [193154] = { name = L["forgotten_gryphon"], npcid = 193154, questId = { 73073 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 33127632 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200256, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200310, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196985, checkId = 69185, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197382, checkId = 69583, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } }, note = L["forgotten_gryphon_note"] },
            [193232] = { name = L["rasnar_the_war_ender"], npcid = 193232, questId = { 74051 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 24005896 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200169, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200757, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197019, checkId = 69219, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197005, checkId = 69205, isKnown = false } }, cave = { coord = { 27226096 } }, note = L["obsidian_throne_rare_note"] },
            [192738] = { name = L["brundin_the_dragonbane"], npcid = 192738, questId = { 73890 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 52916529 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200133, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197379, checkId = 69580, isKnown = false } }, note = L["brundin_the_dragonbane_note"] },
            [186827] = { name = L["magmaton"], npcid = 186827, questId = { 74010 }, type = RARETYPE.WORLDBOSS, faction = FACTION.ALL, coord = { 39596353 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200133, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200203, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200247, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200252, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200684, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197149, checkId = 69350, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197608, checkId = 69812, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197379, checkId = 69580, isKnown = false } } },
            [193266] = { name = L["lepidoralia_the_resplendent"], npcid = 193266, questId = { 74065 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 34618275 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } }, note = L["lepidoralia_the_resplendent_note"] },
            [193263] = { name = L["helmet_missingway"], npcid = 193263, questId = { 73880 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 43007465 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [193135] = { name = L["azras_prized_peony"], npcid = 193135, questId = { 73984 }, type = RARETYPE.WORLDBOSS, faction = FACTION.ALL, coord = { 54517174 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200259, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200267, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200229, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197121, checkId = 69322, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197398, checkId = 69599, isKnown = false } } },
            [189822] = { name = L["shasith"], npcid = 189822, questId = { 74077 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 23755724 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false } }, note = L["obsidian_citadel_rare_note"] },
            [190991] = { name = L["char"], npcid = 190991, questId = { 74043 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 29935074 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200199, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200244, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200246, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200292, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200293, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200294, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200313, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200439, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200683, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200198, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197383, checkId = 69584, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197624, checkId = 69828, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197602, checkId = 69806, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196991, checkId = 69191, isKnown = false } }, cave = { coord = { 29335248 } }, note = L["in_cave"] },
        },
    },
    [2023] = { -- Parent mapID 1978
        zonename = "Ohn'ahran Plains", -- 
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_UNTRACKED,
        currentAssault = 0,
        zonephaseID = 1705, -- ArtID
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!    
        hordeContributionMapID = 0, -- Change!       
        --homeCoord = { 39965257, 10205301 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 16,
        expansion = EXPANSION.DRAGONFLIGHT,
        rares = {
            [193165] = { name = L["sparkspitter_vrak"], npcid = 193165, questId = { 73896 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 21603960 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200234, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200297, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200198, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197116, checkId = 69317, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197372, checkId = 69573, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196999, checkId = 69199, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197383, checkId = 69584, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197606, checkId = 69810, isKnown = false } } },
            [201537] = { name = L["groffnar"], npcid = 201537, questId = { 74463 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 35804040 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 203671, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197016, checkId = 69216, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197367, checkId = 69568, isKnown = false } } },
            [189652] = { name = L["deadwaker_ghendish"], npcid = 189652, questId = { 73872 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 30546628 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 189055, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200308, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200441, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197367, checkId = 69568, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197016, checkId = 69216, isKnown = false } } },
            [193235] = { name = L["oshigol"], npcid = 193235, questId = { 74018 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 61212950 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200203, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200684, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197149, checkId = 69350, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197608, checkId = 69812, isKnown = false } } },
            [187219] = { name = L["defend_clan_aylaag"], npcid = 187219, questId = { 0 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 58604940 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, note = L["defend_clan_aylaag_note"] },
            [193170] = { name = L["fulgurb"], npcid = 193170, questId = { 73994 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 75184651 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200433, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false } } },
            [197009] = { name = L["liskheszaera"], npcid = 197009, questId = { 73882 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 87556151 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200434, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197400, checkId = 69601, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197106, checkId = 69307, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } } },
            [193133] = { name = L["sunscale_behemoth"], npcid = 193133, questId = { 72849 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 63034854 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 198048, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 198409, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false } }, note = L["in_waterfall_cave"] },
            [193212] = { name = L["malsegan"], npcid = 193212, questId = { 74011 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 71694585 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200197, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 198409, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false } } },
            [201535] = { name = L["bloodbeak_the_ravenous"], npcid = 201535, questId = { 74552 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 36803800 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 203673, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false } } },
            [201538] = { name = L["huntmaster_yrgena"], npcid = 201538, questId = { 74548 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 33843872 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 203672, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200308, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197016, checkId = 69216, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197367, checkId = 69568, isKnown = false } } },
            [195223] = { name = L["rustlily"], npcid = 195223, questId = { 73973 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 42804428 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, note = L["rustlily_note"] },
            [193215] = { name = L["scaleseeker_mezeri"], npcid = 193215, questId = { 74073 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 20444344 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200292, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200293, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200294, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200313, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200439, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200198, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197383, checkId = 69584, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197602, checkId = 69806, isKnown = false } }, note = L["scaleseeker_mezeri_note"] },
            [193140] = { name = L["zarizz"], npcid = 193140, questId = { 74091 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 30206260 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200215, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false } }, note = L["zarizz_note"] },
            [201539] = { name = L["stormcaller_narkena"], npcid = 201539, questId = { 74547 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 32614184 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 203676, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200441, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197016, checkId = 69216, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197367, checkId = 69568, isKnown = false } } },
            [192020] = { name = L["eaglemaster_niraak"], npcid = 192020, questId = { 74063 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 49866673 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200308, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200441, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197367, checkId = 69568, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197016, checkId = 69216, isKnown = false } }, note = L["eaglemaster_niraak_note"] },
            [188451] = { name = L["zerimek"], npcid = 188451, questId = { 73980 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 72232306 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, note = L["aylaag_outpost_note"] },
            [191950] = { name = L["porta_the_overgrown"], npcid = 191950, questId = { 73971 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 59686802 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, cave = { coord = { 59696879 } }, note = L["river_camp_note"].."\n"..L["in_small_cave"].."\n"..L["porta_the_overgrown_note"] },
            [201540] = { name = L["lurgan"], npcid = 201540, questId = { 74546 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 35803600 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 203674, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197016, checkId = 69216, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197367, checkId = 69568, isKnown = false } } },
            [193163] = { name = L["territorial_coastling"], npcid = 193163, questId = { 72851 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 22956670 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 198048, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200212, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false } } },
            [192364] = { name = L["windscale_the_stormborn"], npcid = 192364, questId = { 73979 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 84214784 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, note = L["river_camp_note"].."\n"..L["windscale_the_stormborn_note"] },
            [192983] = { name = L["web-queen_ashkaz"], npcid = 192983, questId = { 74095 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 43105078 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false } }, cave = { coord = { 43724823 } }, note = L["in_cave"] },
            [191354] = { name = L["tyfoon_the_ascended"], npcid = 191354, questId = { 72852 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 26073412 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 198048, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 198429, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200306, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200314, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200439, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200198, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197606, checkId = 69810, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197372, checkId = 69573, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197383, checkId = 69584, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197602, checkId = 69806, isKnown = false } }, cave = { coord = { 23573442 } }, note = L["in_cave"] },
            [193173] = { name = L["mikrin_of_the_raging_winds"], npcid = 193173, questId = { 74015 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 63017996 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200306, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200198, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197606, checkId = 69810, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197602, checkId = 69806, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197372, checkId = 69573, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197383, checkId = 69584, isKnown = false } } },
            [192453] = { name = L["vaniik_the_stormtouched"], npcid = 192453, questId = { 73978 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 83786215 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, note = L["river_camp_note"] },
            [187559] = { name = L["shade_of_grief"], npcid = 187559, questId = { 74075 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 29964103 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200256, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200310, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200444, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200437, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196996, checkId = 69196, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197115, checkId = 69324, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196985, checkId = 69185, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197382, checkId = 69583, isKnown = false } }, note = L["shade_of_grief_note"] },
            [193153] = { name = L["ripsaw_the_stalker"], npcid = 193153, questId = { 72845 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 26366533 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 198048, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200137, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false } }, note = L["in_small_cave"] },
            [195186] = { name = L["cinta_the_forgotten"], npcid = 195186, questId = { 73950 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 31567644 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, note = L["cinta_the_forgotten_note"] },
            [193209] = { name = L["zenet_avis"], npcid = 193209, questId = { 73901 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 31456387 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 198825, mountID = 1672, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200314, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200306, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197372, checkId = 69573, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197606, checkId = 69810, isKnown = false } } },
            [193142] = { name = L["enraged_sapphire"], npcid = 193142, questId = { 73875 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 56718128 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200309, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200244, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200246, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200683, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197149, checkId = 69350, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196991, checkId = 69191, isKnown = false } }, note = L["in_small_cave"] },
            [193669] = { name = L["prozela_galeshot"], npcid = 193669, questId = { 72815 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 59926696 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 198048, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200199, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200292, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200293, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200294, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200306, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200313, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200314, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200439, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200198, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197372, checkId = 69573, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197606, checkId = 69810, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197383, checkId = 69584, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197602, checkId = 69806, isKnown = false } } },
            [191842] = { name = L["sulfurion"], npcid = 191842, questId = { 73974 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 78298276 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, note = L["river_camp_note"] },
            [197411] = { name = L["astray_splashe"], npcid = 197411, questId = { 74057 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 80817770 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200187, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200245, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197098, checkId = 69299, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197001, checkId = 69201, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 200086, isKnown = false } }, note = L["astray_splashe_note"] },
            [193128] = { name = L["blightpaw_the_depraved"], npcid = 193128, questId = { 74096 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 90434005 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200127, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200266, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200283, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200432, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200178, isKnown = false } }, note = L["blightpaw_the_depraved_note"] },
            [192045] = { name = L["windseeker_avash"], npcid = 192045, questId = { 74088 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 58596822 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200308, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200441, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197367, checkId = 69568, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197016, checkId = 69216, isKnown = false } }, note = L["windseeker_avash_note"] },
            [192949] = { name = L["skaara"], npcid = 192949, questId = { 72847 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 44894924 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 198048, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200137, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200212, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false } }, note = L["in_small_cave"] },
            [195204] = { name = L["the_jolly_giant"], npcid = 195204, questId = { 73976 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 27605560 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, note = L["the_jolly_giant_note"] },
            [193123] = { name = L["steamgill"], npcid = 193123, questId = { 74034 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 53627281 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200216, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } } },
            [193188] = { name = L["seeker_teryx"], npcid = 193188, questId = { 73894 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 61801283 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200875, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200138, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200758, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197105, checkId = 69306, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196970, checkId = 69170, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197586, checkId = 69790, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197138, checkId = 69339, isKnown = false } } },
            [193136] = { name = L["scav_notail"], npcid = 193136, questId = { 73893 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 50117517 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200168, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200266, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200283, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196982, checkId = 69182, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197150, checkId = 69351, isKnown = false } } },
            [187781] = { name = L["hamett"], npcid = 187781, questId = { 73951 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 85221544 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, note = L["aylaag_outpost_note"] },
            [193227] = { name = L["ronsak_the_decimator"], npcid = 193227, questId = { 74026 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 43405560 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200308, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200441, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197016, checkId = 69216, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197367, checkId = 69568, isKnown = false } } },
            [188124] = { name = L["irontree"], npcid = 188124, questId = { 73967 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 80513869 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, cave = { coord = { 79143656 } }, note = L["in_cave"].."\n"..L["aylaag_outpost_note"] },
            [195409] = { name = L["makhra_the_ashtouched"], npcid = 195409, questId = { 73968 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 32823817 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, note = L["makhra_the_ashtouched_note"] },
            [196010] = { name = L["researcher_sneakwing"], npcid = 196010, questId = { 74023 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 37005380 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200165, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200682, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200228, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200438, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196992, checkId = 69192, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197403, checkId = 69604, isKnown = false } } },
            [188095] = { name = L["hunter_of_the_deep"], npcid = 188095, questId = { 73966 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 80544222 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, note = L["aylaag_outpost_note"].."\n"..L["hunter_of_the_deep_note"] },
        },
    },
    [2024] = { -- Parent mapID 1978
        zonename = "The Azure Span", -- 
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_UNTRACKED,
        currentAssault = 0,
        zonephaseID = 1707, -- ArtID
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!    
        hordeContributionMapID = 0, -- Change!       
        --homeCoord = { 39965257, 10205301 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 17,
        expansion = EXPANSION.DRAGONFLIGHT,
        rares = {
            [198004] = { name = L["mange_the_outcast"], npcid = 198004, questId = { 73884 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 40514797 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200283, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200266, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196982, checkId = 69182, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197150, checkId = 69351, isKnown = false } } },
            [193157] = { name = L["dragonhunter_gorund"], npcid = 193157, questId = { 73873 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 27214490 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200302, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200169, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200757, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197019, checkId = 69219, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197005, checkId = 69205, isKnown = false } } },
            [201559] = { name = L["shiobhan_waterborn"], npcid = 201559, questId = { 74533 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 60196818 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 203661, isKnown = false } } },
            [197183] = { name = L["stranded_soul"], npcid = 197183, questId = { 71139 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 76602460 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 200528, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197137, checkId = 69338, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197141, checkId = 69342, isKnown = false } }, note = L["stranded_soul_note"] },
            [193238] = { name = L["spellwrought_snowman"], npcid = 193238, questId = { 74082 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 55033405 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200187, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200211, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200245, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197001, checkId = 69201, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197098, checkId = 69299, isKnown = false } }, note = L["spellwrought_snowman_note"] },
            [194270] = { name = L["arcane_devourer"], npcid = 194270, questId = { 73866 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 53013563 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [193288] = { name = L["summoned_destroyer"], npcid = 193288, questId = { 72848 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 70143327 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 198048, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200247, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200252, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200133, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197135, checkId = 69336, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197379, checkId = 69580, isKnown = false } } },
            [193214] = { name = L["forgotten_creation"], npcid = 193214, questId = { 72840 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 38155901 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200138, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200758, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197138, checkId = 69339, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197586, checkId = 69790, isKnown = false } }, cave = { coord = { 38625988 } }, note = L["in_cave"] },
            [193223] = { name = L["vakril"], npcid = 193223, questId = { 72853 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 17254144 }, bothphases = true, loot = { { droptype = DROPTYPE.ITEM, itemID = 201728, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200245, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200187, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197001, checkId = 69201, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197098, checkId = 69299, isKnown = false } } },
            [193269] = { name = L["grumbletrunk"], npcid = 193269, questId = { 74002 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 19234362 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200137, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200206, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false } } },
            [193691] = { name = L["fisherman_tinnak"], npcid = 193691, questId = { 72254 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 50043631 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200187, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200245, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200256, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200310, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197382, checkId = 69583, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196985, checkId = 69185, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197098, checkId = 69299, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197001, checkId = 69201, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 198070, isKnown = false } }, note = L["fisherman_tinnak_note"] },
            [193251] = { name = L["gruffy"], npcid = 193251, questId = { 74001 }, type = RARETYPE.WORLDBOSS, faction = FACTION.ALL, coord = { 32682911 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } } },
            [194210] = { name = L["azure_pathfinder"], npcid = 194210, questId = { 73867 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 55823132 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } } },
            [196165] = { name = L["gethdazr"], npcid = 196165, questId = { 74446 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 56407080 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200138, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200237, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200758, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197105, checkId = 69306, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196970, checkId = 69170, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197138, checkId = 69339, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197586, checkId = 69790, isKnown = false } }, note = L["gethdazr_note"] },
            [186962] = { name = L["cascade"], npcid = 186962, questId = { 72836 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 23503317 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200135, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200245, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200187, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197098, checkId = 69299, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197001, checkId = 69201, isKnown = false } } },
            [201561] = { name = L["movtivator_krathos"], npcid = 201561, questId = { 74544 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 43903096 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 203675, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200434, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197400, checkId = 69601, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197106, checkId = 69307, isKnown = false } } },
            [193149] = { name = L["skag_the_thrower"], npcid = 193149, questId = { 74030 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 26494939 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200203, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200244, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200246, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200279, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200683, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200684, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197149, checkId = 69350, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197608, checkId = 69812, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196991, checkId = 69191, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197624, checkId = 69828, isKnown = false } } },
            [191356] = { name = L["frostpaw"], npcid = 191356, questId = { 73877 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 58264391 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, note = L["frostpaw_note"] },
            [195353] = { name = L["breezebiter"], npcid = 195353, questId = { 0 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 28564743 }, bothphases = true, loot = { { droptype = DROPTYPE.MOUNT, itemID = 201440, mountID = 1553, isKnown = false } }, cave = { coord = { 29804622 } }, note = L["breezebiter_note"] },
            [193178] = { name = L["blightfur"], npcid = 193178, questId = { 74058 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 13432270 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200127, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200256, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200266, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200283, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200310, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200432, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197404, checkId = 69605, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196986, checkId = 69186, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196973, checkId = 69173, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196985, checkId = 69185, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197382, checkId = 69583, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196982, checkId = 69182, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197150, checkId = 69351, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200178, isKnown = false } }, note = L["blightfur_note"] },
            [192749] = { name = L["sharpfang"], npcid = 192749, questId = { 72846 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 36723247 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200283, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200266, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197150, checkId = 69351, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196982, checkId = 69182, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 198048, isKnown = false } }, note = L["sharpfang_note"] },
            [193632] = { name = L["wilrive"], npcid = 193632, questId = { 73900 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 59405520 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } } },
            [194392] = { name = L["brackle"], npcid = 194392, questId = { 73871 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 8944852 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200137, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200151, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200435, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false } }, cave = { coord = { 8584883 } }, note = L["in_small_cave"] },
            [190244] = { name = L["mahg_the_trampler"], npcid = 190244, questId = { 73883 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 36243573 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200157, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200684, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200203, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197149, checkId = 69350, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197608, checkId = 69812, isKnown = false } } },
            [201553] = { name = L["grand_artificer_zeerak"], npcid = 201553, questId = { 74545 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 47912378 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 203664, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200434, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197400, checkId = 69601, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197106, checkId = 69307, isKnown = false } } },
            [193698] = { name = L["frigidpelt_den_mother"], npcid = 193698, questId = { 73876 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 64992995 }, bothphases = true, loot = { { droptype = DROPTYPE.GEAR_ONLY, itemID = 0, isKnown = false } }, note = L["in_small_cave"] },
            [201554] = { name = L["unstable_arcanogolem"], npcid = 201554, questId = { 74536 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 47102582 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 203662, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200138, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200758, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197138, checkId = 69339, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197586, checkId = 69790, isKnown = false } } },
            [201556] = { name = L["waterpots"], npcid = 201556, questId = { 74535 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 57256464 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200135, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200187, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 203659, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197383, checkId = 69584, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197602, checkId = 69806, isKnown = false } } },
            [193116] = { name = L["beogoka"], npcid = 193116, questId = { 73868 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 73032680 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200253, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200254, isKnown = false } } },
            [193196] = { name = L["trilvarus_loreweaver"], npcid = 193196, questId = { 74087 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 70222532 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200434, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197106, checkId = 69307, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197400, checkId = 69601, isKnown = false } }, note = L["trilvarus_loreweaver_note"] },
            [201558] = { name = L["malgain_rockknell"], npcid = 201558, questId = { 74531 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 56016760 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200292, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 203660, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197624, checkId = 69828, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197602, checkId = 69806, isKnown = false } } },
            [193259] = { name = L["blue_terror"], npcid = 193259, questId = { 73870 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 16622798 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200137, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200212, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197595, checkId = 69799, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } } },
            [201557] = { name = L["graniteclaw"], npcid = 201557, questId = { 74532 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 57916842 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200246, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200254, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200313, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200683, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 203658, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197023, checkId = 69223, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197602, checkId = 69806, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197624, checkId = 69828, isKnown = false } } },
            [197371] = { name = L["lunker_rares"], npcid = 197371, questId = { 73891 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 58813260 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200187, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200245, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197001, checkId = 69201, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197098, checkId = 69299, isKnown = false } }, note = L["lunker_rares_note"] },
            [193225] = { name = L["notfar_the_unbearable"], npcid = 193225, questId = { 73887 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 20584943 }, bothphases = true, loot = { { droptype = DROPTYPE.TOY, itemID = 200160, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200253, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200254, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197023, checkId = 69223, isKnown = false } }, cave = { coord = { 34023076 } }, note = L["in_small_cave"] },
            [193201] = { name = L["mucka_the_raker"], npcid = 193201, questId = { 73885 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 58095471 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200137, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false } } },
        },
    },
    [2025] = { -- Parent mapID 1978
        zonename = "Thaldraszus", -- 
        scenarioname = "Unknown", -- Change!
        gatheringname = "Unknown", -- Change!
        hidden = false,
        zoneType = DB_ZONE_TYPE_UNTRACKED,
        currentAssault = 0,
        zonephaseID = 1708, -- ArtID
        zoneContributionMapID = 0, -- Change!
        allianceContributionMapID = 0, -- Change!    
        hordeContributionMapID = 0, -- Change!       
        --homeCoord = { 39965257, 10205301 }, -- Alliance is exactly on portal!
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        index = 18,
        expansion = EXPANSION.DRAGONFLIGHT,
        rares = {
            [193664] = { name = L["ancient_protector"], npcid = 193664, questId = { 74055 }, type = RARETYPE.WORLDBOSS, faction = FACTION.ALL, coord = { 59075874 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200138, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200299, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200303, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200758, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197586, checkId = 69790, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197138, checkId = 69339, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197100, checkId = 69301, isKnown = false } }, note = L["ancient_protector_note"] },
            [193128] = { name = L["blightpaw_the_depraved"], npcid = 193128, questId = { 74096 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 31097121 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200127, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200266, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200283, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200432, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200178, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196986, checkId = 69186, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196973, checkId = 69173, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196982, checkId = 69182, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197150, checkId = 69351, isKnown = false } }, note = L["blightpaw_the_depraved_note"] },
            [193220] = { name = L["broodweaver_araznae"], npcid = 193220, questId = { 73987 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 59847057 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200138, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200147, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200758, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197586, checkId = 69790, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197138, checkId = 69339, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false } } },
            [193658] = { name = L["corrupted_proto-dragon"], npcid = 193658, questId = { 74060 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 44886910 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200166, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200233, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200293, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200313, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200198, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196983, checkId = 69183, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197125, checkId = 69326, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197383, checkId = 69584, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197602, checkId = 69806, isKnown = false } }, cave = { coord = { 44616780 } }, note = L["corrupted_proto-dragon_note"] },
            [193663] = { name = L["craggravated_elemental"], npcid = 193663, questId = { 74061 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 45458518 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200298, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200244, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200246, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200683, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196991, checkId = 69191, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197624, checkId = 69828, isKnown = false } } },
            [193234] = { name = L["eldoren_the_reborn"], npcid = 193234, questId = { 73990 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 47675115 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200133, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200246, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200683, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197135, checkId = 69336, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false } } },
            [193125] = { name = L["goremaul_the_gluttonous"], npcid = 193125, questId = { 73878 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 53374092 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200436, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false } } },
            [193126] = { name = L["innumerable_ruination"], npcid = 193126, questId = { 73881 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 59128380 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200126, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200133, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200202, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200247, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200252, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200148, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197008, checkId = 69208, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197130, checkId = 69331, isKnown = false } } },
            [193241] = { name = L["lord_epochbrgl"], npcid = 193241, questId = { 74066 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 62298177 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200185, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200126, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200151, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200202, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200435, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200148, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197008, checkId = 69208, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197130, checkId = 69331, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197022, checkId = 69222, isKnown = false } }, cave = { coord = { 61708120 } }, note = L["lord_epochbrgl_note"] },
            [193246] = { name = L["matriarch_remalla"], npcid = 193246, questId = { 74013 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 52895903 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200257, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } } },
            [193688] = { name = L["phenran"], npcid = 193688, questId = { 74020 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 59806100 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200146, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200138, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200299, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200303, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200758, isKnown = false }, { droptype = DROPTYPE.PET, itemID = 200263, speciesID = 3310, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197100, checkId = 69301, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197138, checkId = 69339, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197586, checkId = 69790, isKnown = false } } },
            [193210] = { name = L["phleep"], npcid = 193210, questId = { 74021 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 57218420 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200202, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200126, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200148, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197130, checkId = 69331, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197008, checkId = 69208, isKnown = false } } },
            [193130] = { name = L["pleasant_alpha"], npcid = 193130, questId = { 73889 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 37967903 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } } },
            [193143] = { name = L["razkvex_the_untamed"], npcid = 193143, questId = { 73892 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 50404840 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200165, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200682, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196992, checkId = 69192, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197403, checkId = 69604, isKnown = false } } },
            [193240] = { name = L["riverwalker_tamopo"], npcid = 193240, questId = { 74024 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 40087014 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200137, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200212, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } } },
            [193666] = { name = L["rokmur"], npcid = 193666, questId = { 74025 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 50005180 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200137, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200212, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } } },
            [193176] = { name = L["sandana_the_tempest"], npcid = 193176, questId = { 74029 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 37607780 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200202, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200126, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200306, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200314, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200148, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197008, checkId = 69208, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197130, checkId = 69331, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197372, checkId = 69573, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197606, checkId = 69810, isKnown = false } }, cave = { coord = { 38507640 } } },
            [193258] = { name = L["tempestrian"], npcid = 193258, questId = { 74035 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 47207895 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200139, isKnown = false } } },
            [191305] = { name = L["the_great_shellkhan"], npcid = 191305, questId = { 74085 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 38466826 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200999, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } }, note = L["the_great_shellkhan_note"] },
            [183984] = { name = L["the_weeping_vilomah"], npcid = 183984, questId = { 74086 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 46267317 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200214, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } }, cave = { coord = { 47547180 } }, note = L["the_weeping_vilomah_note"] },
            [193146] = { name = L["treasure-mad_trambladd"], npcid = 193146, questId = { 74036 }, type = RARETYPE.ELITE, faction = FACTION.ALL, coord = { 35027001 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200291, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196994, checkId = 69194, isKnown = false } }, cave = { coord = { 34896938 } } },
            [193161] = { name = L["woolfang"], npcid = 193161, questId = { 74089 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 47884976 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197111, checkId = 69312, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } }, note = L["woolfang_note"] },
            [197411] = { name = L["astray_splasher"], npcid = 197411, questId = { 74057 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 57366540 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200187, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200245, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 200086, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197098, checkId = 69299, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197001, checkId = 69201, isKnown = false } }, note = L["astray_splasher_note"] },
            [193229] = { name = L["henlare"], npcid = 193229, questId = { 72814 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 55647727 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 198048, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 0, checkId = 0, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196976, checkId = 69176, isKnown = false } } },
            [193273] = { name = L["liskron_the_dazzling"], npcid = 193273, questId = { 72842 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 36757287 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200131, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200174, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200186, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200193, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200195, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200232, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200442, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200249, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 198048, isKnown = false } } },
            [193668] = { name = L["lookout_mordren"], npcid = 193668, questId = { 72813 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 36798556 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200182, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200133, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200247, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200252, isKnown = false }, { droptype = DROPTYPE.TOY, itemID = 200198, isKnown = false }, { droptype = DROPTYPE.ITEM, itemID = 198048, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197602, checkId = 69806, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197379, checkId = 69580, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197383, checkId = 69584, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197135, checkId = 69336, isKnown = false } } },
            [201562] = { name = L["shardwing"], npcid = 201562, questId = { 74556 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 48421722 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200182, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 203669, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200242, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200241, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197593, checkId = 69797, isKnown = false } } },
            [201542] = { name = L["tikarr_frostclaw"], npcid = 201542, questId = { 74558 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 61813142 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 203667, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196999, checkId = 69199, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197116, checkId = 69317, isKnown = false } } },
            [201543] = { name = L["avalantus"], npcid = 201543, questId = { 74554 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 53536521 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 200187, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200245, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200135, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 201447, isKnown = false } } },
            [201545] = { name = L["shapemaster_zalani"], npcid = 201545, questId = { 74553 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 46884248 }, bothphases = true, loot = { { droptype = DROPTYPE.TRANSMOG, itemID = 203668, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200199, isKnown = false }, { droptype = DROPTYPE.TRANSMOG, itemID = 200292, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197383, checkId = 69584, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197602, checkId = 69806, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 196991, checkId = 69191, isKnown = false }, { droptype = DROPTYPE.SCROLL, itemID = 197624, checkId = 69828, isKnown = false } } },

            [179608] = { name = "Test - Thaldraszus", npcid = 179608, questId = { 64263 }, type = RARETYPE.RARE, faction = FACTION.ALL, coord = { 50005000 }, bothphases = true, loot = { { droptype = DROPTYPE.SCROLL, itemID = 197139, checkId = 69340, isKnown = false } } },
        },
    },
}
WarfrontRareTracker.rareDB = rareDB

-- Colors
local colors = {
    white = { 1, 1, 1, 1 },
    red = { 1, 0.12, 0.12, 1 },
    green = { 0, 1, 0, 1 },
    purple = { 0.63, 0.20, 0.93, 1 },
    oldturqoise = { 0.40, 0.73, 1, 1 },
    turqoise = { 0.25, 0.78, 0.92, 1 },
    yellow = { 1, 0.82, 0, 1 },
    blue = { 0, 0.44, 0.87, 1 },
    grey = { 0.6, 0.6, 0.6, 1 },
    orange = { 1, 0.49, 0.04, 1 },
    lightcyan = { 0, 1 , 0.59, 1 },
}

-- Test new filter system
local HIDE_ALREADY_KNOWN = "AlreadyKnown"
local HIDE_UNKNOWN_LOOT = "UnknowLoot"
local HIDE_UNTRACKABLE = "Untrackable"
local HIDE_GOLIATHS = "Goliaths"
local HIDE_UNAVAILABLE = "Unavailable"
local HIDE_GEAR_ONLY = "GearOnly"
local HIDE_QUEST_ONLY = "QuestOnly"
local HIDE_ITEM_ONLY = "ItemOnly"


-- Default options
local dbDefaults = {
    profile = {
        profileversion = 3,
        minimap = {
            hide = false,
            minimapPos = 180,
        },
        broker = {
            showBrokerText = true,
            brokerText = "allstatus",
            updateInterval = 1,
            updateIntervalState1 = 10,
            updateIntervalState2 = 1,
        },
        menu = {
            showMenuOn = "mouse",
            hideOnCombat = true,
            clickToTomTom = true,
            useMasterfilter = true,
            hideAlreadyKnown = false,
            hideUnknowLoot = false,
            hideUntrackable = false,
            hideUnavailable = false,
            hideGoliaths = false,
            hideAncients = false,
            hideGearOnly = false,
            hideQuestOnly = false,
            hideBlueprintOnly = false,
            hideItemOnly = false,
            hideTransmogOnly = false,
            hideAnimaOnly = false,
            showAtMaxLevel = false,
            showCovenantBoundRares = false,
            showCovenantBoundLoot = false,
            showWarfrontOnZoneName = true,
            showWarfrontTitle = "all",
            showWarfrontInMenu = true,
            showWarfrontMenu = "current",
            autoChangeZone = true,
            autoSaveZone = false,
            whitelist = { [DROPTYPE.MOUNT] = false, [DROPTYPE.PET] = false, [DROPTYPE.TOY] = false, [DROPTYPE.BLUEPRINT] = false, [DROPTYPE.QUEST] = false, [DROPTYPE.TRANSMOG] = false, [DROPTYPE.SCROLL] = false },
            sortRaresOn = "drop",
            groupDropSortOn = "type",
            groupTypeSortOn = "drop",
            sortAscending = "true",
            worldbossOnTop = true,
            alwaysShowWorldboss = true,
            --lootTypeOrder = { [1] = "Mount", [2] = "Pet", [3] = "Toy", [4] = "Quest", [5] = "Blueprint", [6] = "Item", [7] = "Gear only", [8] = "Transmog", [9] = DROPTYPE.SCROLL, [10] = "Unknown" }
            lootTypeOrder = { [1] = DROPTYPE.MOUNT, [2] = DROPTYPE.PET, [3] = DROPTYPE.TOY, [4] = DROPTYPE.QUEST, [5] = DROPTYPE.BLUEPRINT, [6] = DROPTYPE.ITEM, [7] = DROPTYPE.GEAR_ONLY, [8] = DROPTYPE.TRANSMOG, [9] = DROPTYPE.SCROLL, [10] = DROPTYPE.UNKNOWN }
        },
        masterfilter = {
            hide = { [HIDE_ALREADY_KNOWN] = false, [HIDE_UNKNOWN_LOOT] = false, [HIDE_UNTRACKABLE] = false, [HIDE_GOLIATHS] = false, [HIDE_UNAVAILABLE] = false, [HIDE_GEAR_ONLY] = false, [HIDE_QUEST_ONLY] = false, [HIDE_ITEM_ONLY] = false },
            hideAlreadyKnown = false, -- Loot?
            hideUnknowLoot = false, -- Loot
            hideUntrackable = false, -- NPC/Rare Type
            hideGoliaths = false, -- NPC/Rare Type
            hideAncients = false, -- NPC/Rare Type
            hideUnavailable = false, -- NPC/Rare Type
            hideGearOnly = false, -- Loot
            hideQuestOnly = false, -- Loot
            hideBlueprintOnly = false, -- Loot
            hideItemOnly = false, -- Loot
            hideTransmogOnly = false, -- Loot
            hideAnimaOnly = false, -- Loot
            whitelist = { [DROPTYPE.MOUNT] = false, [DROPTYPE.PET] = false, [DROPTYPE.TOY] = false, [DROPTYPE.BLUEPRINT] = false, [DROPTYPE.QUEST] = false, [DROPTYPE.TRANSMOG] = false, [DROPTYPE.SCROLL] = false },
            worldmapShowOnlyAtPhase = true,
            worldmapShowOnlyAtMaxLevel = false,
            worldmapHandleDefeated = "change",
            alwaysShowWorldboss = true,
            ignoreAssault = false,
            showCovenantBoundRares = false,
            showCovenantBoundLoot = false,
        },
        lootwindow = {
            compactMode = "amount",
            alsohidenotes = false,
            compactModeAmount = 3,
            showCovenantBoundLoot = false,
        },
        colors = {
            colorizeDrops = true,
            knownColor = { 0, 1, 0, 1 },
            unknownColor = { 1, 1, 1, 1 },
            colorizeStatus = false,
            available = { 0, 1, 0, 1 },
            defeated = { 1, 0.12, 0.12, 1 },
            colorizeRares = true,
            worldboss = { 1, 0.5, 0, 1 },
            elite = { 0.63, 0.20, 0.93, 1 },
            rare = { 0, 0.44, 0.87, 1 },
            uncommon = { 0, 1, 0, 1 },
            goliath = { 1, 1, 1, 1 },
            menuAlpha = 0.7,
        },
        unitframe = {
            enableUnitframeIntegration = true,
            showStatus = true,
            showDrop = true,
            showAlreadyKnown = true,
            compactMode = true,
        },
        minimapIcons = {
            showMinimapIcons = true,
            showOnlyAtPhase = true,
            onMinimapHoover = true,
            minimapIconsCompactMode = true,
            minimapIconSize = 13,
            minimapIconAlpha = 1,
        },
        worldmapicons = {
            handleDefeated = "change",
            showWorldmapIcons = true,
            showOnlyAtPhase = true,
            showOnlyAtMaxLevel = false,
            showCovenantBoundRares = false,
            showCovenantBoundLoot = false,
            clickToTomTom = true,
            worldmapIconSize = 13,
            worldmapIconAlpha = 1,
            useMasterfilter = true,
            hideAlreadyKnown = false,
            hideUnknowLoot = false,
            hideUntrackable = false,
            hideUnavailable = false,
            hideGoliaths = false,
            hideAncients = false,
            hideGearOnly = false,
            hideQuestOnly = false,
            hideBlueprintOnly = false,
            hideItemOnly = false,
            hideTransmogOnly = false,
            hideAnimaOnly = false,
            whitelist = { [DROPTYPE.MOUNT] = false, [DROPTYPE.PET] = false, [DROPTYPE.TOY] = false, [DROPTYPE.BLUEPRINT] = false, [DROPTYPE.QUEST] = false, [DROPTYPE.TRANSMOG] = false, [DROPTYPE.SCROLL] = false },
            alwaysShowWorldboss = true,
        },
        tomtom = {
            enableIntegration = true,
            enableChatMessage = true,
            tomtomAnnounce = false,
            tomtomAnnounceLeader = true,
        },
        general = {
            enableZoneChangeSound = true,
            enableZoneChangeMessage = true,
            --enableLevelUpSound = true,
            --enableLevelUpChatMessage = true,
            disableBackground = false,
        },
        debug = {
            printDebug = false,
        },
    },
    char = {
        selectedZone = 14,
    },
    global = {
        printCompatibilityMessage1 = true,
        printCompatibilityMessage2 = true,
        debug = false,
    },
}

------------------
-- Local functions
------------------

---------------
-- Session lock
local sessionDB = {
    ["BUCKET_ON_LOOT_RECEIVED"] = { locked = false, delay = 4 },
    ["playSound"] = { locked = false, delay = 10 },
}
local function unlockSession(name)
    if sessionDB[name] then
        sessionDB[name].locked = false
    end
end

local function isSessionLocked(name)
    if not sessionDB[name] then
        return false
    else
        if sessionDB[name].locked == false then
            sessionDB[name].locked = true
            C_Timer.After(sessionDB[name].delay, function() unlockSession(name) end)
            return false
        else
            return true
        end
    end
end

--------------
-- Assault 8.3
--------------
local function getCurrentAssault(mapid)
    local textures = C_MapExplorationInfo.GetExploredMapTextures(mapid)
    if textures and textures[1].fileDataIDs[1] == 3165083 then -- Uldum Left assault: aqir
        return assaultType.aqir
    elseif textures and textures[1].fileDataIDs[1] == 3165092 then -- Uldum Middle assault: blackEmpire
        return assaultType.blackEmpire
    elseif textures and textures[1].fileDataIDs[1] == 3165098 then -- Uldum Right assault: amathet
        return assaultType.amathet
    elseif textures and textures[1].fileDataIDs[1] == 3155826 then -- Vale Left assault: mantid
        return assaultType.mantid
    elseif textures and textures[1].fileDataIDs[1] == 3155832 then -- Vale Middle assault: mogu
        return assaultType.mogu
    elseif textures and textures[1].fileDataIDs[1] == 3155841 then -- Vale Right assault: blackEmpire
        return assaultType.blackEmpire
    end
    return assaultType.unknown
end

local function checkAssaults()
    for mapid, contents in pairs(rareDB) do
        if contents.zoneType ~= nil and contents.zoneType == DB_ZONE_TYPE_ASSAULT then
            if contents.currentAssault then
                local assault = getCurrentAssault(mapid)
                contents.currentAssault = assault
            end
        end
    end
end

local function checkRareAssault(mapid, npcid)
    if rareDB[mapid] ~= nil and rareDB[mapid].rares[npcid] ~= nil and rareDB[mapid].rares[npcid].assault ~= nil then
        local assault = rareDB[mapid].rares[npcid].assault
        assault = type(assault) == 'number' and {assault} or assault
        for  i = 1, #assault, 1 do
            if i > #assault then
                return false
            end
            if assault[i] == rareDB[mapid].currentAssault or assault[i] == assaultType.unknown or assault[i] == assaultType.all then
                return true
            end
        end
        if WarfrontRareTracker.db.profile.masterfilter.ignoreAssault then
            return true
        else
            return false
        end
    end
    return false
end

----
-- Uldum:
-- Black Empire Assault*
-- Amathet Assault
-- Aqir Assault
-- Vale:
-- Black Empire Assault*
-- Mantid Assault
-- Mogu Assault
--local assault = nil

--------
-- Utils
local function getBDSize(inputDB)
    if inputDB == nil then
        return 0
    end
    local counter = 0
    for mapid, content in pairs(inputDB) do
        counter = counter + 1
    end
    return counter
end

local function clearTable(t)
    for k, v in pairs(t) do
        t[k] = nil
    end
end

local function getPlayerSelectedZone()
    local currentZone = WarfrontRareTracker.db.char.selectedZone
    if WarfrontRareTracker.db.profile.menu.autoChangeZone and autoChangeZone ~= nil then
        if autoChangeZoneTimestamp >= manualTimestamp then
            currentZone = autoChangeZone 
        end
    end
    return currentZone
end

local function isNPCPlayerFaction(mapid, npcid)
    return rareDB[mapid].rares[npcid].faction == currentPlayerFaction or rareDB[mapid].rares[npcid].faction == FACTION.ALL
end

local function IsPlayerWarfrontLevel()
    if currentPlayerLevel >= PLAYER_WARFRONT_LEVEL then
        return true
    else
        return false
    end
end

local function isPlayerInWarfront() -- Changed for ParentMapID
    if rareDB[currentPlayerMapid] ~= nil or rareDB[currentPlayerParentMapid] ~= nil then
        return true
    end
    return false
end

local function getNPCIDFromGUID(guid)
	local unitTypeName, _, _, _, _, unitID = ("-"):split(guid)
    return tonumber(unitID) or 0
end

local function isNPCUpForPlayerFaction(mapid, npcid)
    if rareDB[mapid].rares[npcid].bothphases then
        return true
    else
        return rareDB[mapid].rares[npcid].faction == rareDB[mapid].warfrontControlledByFaction or rareDB[mapid].rares[npcid].faction == FACTION.ALL
    end
end

local function isQuestCompleted(questid)
    return C_QuestLog.IsQuestFlaggedCompleted(questid)
end

local function areAllQuestsCompleted(mapid, npcid) -- Rename to isRareKilled(mapid, npcid) ?
    -- if rareDB[mapid].rares[npcid].questId == nil or rareDB[mapid].rares[npcid].questId[1] <= 0 then return false end
    -- if rareDB[mapid].expansion == EXPANSION.BFA then -- BfA has Alliance/Horde ID's.
    --     for k, v in pairs(rareDB[mapid].rares[npcid].questId) do
    --         if C_QuestLog.IsQuestFlaggedCompleted(rareDB[mapid].rares[npcid].questId[k]) then
    --             return true
    --         end
    --     end
    -- elseif rareDB[mapid].expansion == EXPANSION.SHADOWLANDS then -- Shadowlands has multiple questID's for a few Rare's so we need to iterate to see if all are completed.
    --     for k, v in pairs(rareDB[mapid].rares[npcid].questId) do
    --         if not C_QuestLog.IsQuestFlaggedCompleted(rareDB[mapid].rares[npcid].questId[k]) then
    --             return false
    --         end
    --     end
    --     return true
    -- end
    -- return false

    -- New
    if rareDB[mapid].rares[npcid].questId == nil or rareDB[mapid].rares[npcid].questId[1] <= 0 then return false end
    for k, v in pairs(rareDB[mapid].rares[npcid].questId) do
        if not isQuestCompleted(rareDB[mapid].rares[npcid].questId[k]) then
            return false
        end
    end
    return true
end

local function playSound(news)
    if news == nil or news == "" then
        return
    end
    if isSessionLocked("playSound") then
        return
    end
    news = news:lower()
    if news == "good" then
        PlaySoundFile(SOUND_GOODNEWS)
    elseif news == "bad" then
        PlaySoundFile(SOUND_BADNEWS)
    else
        return
    end
end

local function getWarfrontTimeLeft(changeTime)
    local daysLeft, hoursLeft, minutesLeft, secondsLeft = 0, 0, 0, 0
    local timeLeft = changeTime - GetServerTime()
    if timeLeft >= SECONDS_IN_DAY then -- If we have a full day left
        daysLeft = floor(timeLeft / SECONDS_IN_DAY)
        timeLeft = mod(timeLeft, SECONDS_IN_DAY)
    end
    if timeLeft >= SECONDS_IN_HOUR then -- If we have a full hour left
        hoursLeft = floor(timeLeft / SECONDS_IN_HOUR)
        timeLeft = mod(timeLeft, SECONDS_IN_HOUR)
    end
    if timeLeft >= SECONDS_IN_MIN then -- If we have a full minute left
        minutesLeft = floor(timeLeft / SECONDS_IN_MIN)
        timeLeft = mod(timeLeft, SECONDS_IN_MIN)
    end
    if timeLeft > 0 then -- If we have any seconss left
        secondsLeft = timeLeft
    end
    
    return daysLeft, hoursLeft, minutesLeft, secondsLeft
end

local function colorText(text, color, noreset)
    if noreset == nil then
        noreset = false
    end
    if text and color then
        if noreset then
            return format("|cff%02x%02x%02x%s", (color[1] or 1) * 255, (color[2] or 1) * 255, (color[3] or 1) * 255, text)
        else
            return format("|cff%02x%02x%02x%s|r", (color[1] or 1) * 255, (color[2] or 1) * 255, (color[3] or 1) * 255, text)
        end
    else
        return text
    end
end

local function DebugPrint(text, color)
    if WarfrontRareTracker.db.profile.debug.printDebug == false then return end
    if text == nil or text == "" then return end
    if color == nil then color = colors.lightcyan end
    print(colorText("[WRT] ", colors.orange)..colorText(text, color))
end

local function getColoredRareName(mapid, npcid)
    local rare = rareDB[mapid].rares[npcid]
    if WarfrontRareTracker.db.profile.colors.colorizeRares then
        if rare.type == RARETYPE.WORLDBOSS or rare.type == RARETYPE.ANCIENT then
            return colorText(rare.name, WarfrontRareTracker.db.profile.colors.worldboss)
        elseif rare.type == RARETYPE.ELITE then
            return colorText(rare.name, WarfrontRareTracker.db.profile.colors.elite)
        elseif rare.type == RARETYPE.RARE then
            return colorText(rare.name, WarfrontRareTracker.db.profile.colors.rare)
        elseif rare.type == RARETYPE.UNCOMMON then
            return colorText(rare.name, WarfrontRareTracker.db.profile.colors.uncommon)
        elseif rare.type == RARETYPE.GOLIATH then
            return colorText(rare.name, WarfrontRareTracker.db.profile.colors.goliath)
        else
            return colorText(rare.name, colors.white)
        end
    else
        return colorText(rare.name, colors.white)
    end
end

local function getColoredStatusText(mapid, npcid)
    if not IsPlayerWarfrontLevel() then
        return colorText("Level " .. PLAYER_WARFRONT_LEVEL, colors.orange)
    end
    local rare = rareDB[mapid].rares[npcid]
    if rare.questId[1] == -1 then
        return colorText("Untrackable", colors.yellow)
    elseif rare.questId[1] == 0 then
        return colorText("Missing Info", colors.orange)
    else
        if areAllQuestsCompleted(mapid, npcid) then
            return colorText("Defeated", WarfrontRareTracker.db.profile.colors.colorizeStatus and WarfrontRareTracker.db.profile.colors.defeated or colors.red)
        end
    end
    if isNPCPlayerFaction(mapid, npcid) and isNPCUpForPlayerFaction(mapid, npcid) then
        return colorText("Available", WarfrontRareTracker.db.profile.colors.colorizeStatus and WarfrontRareTracker.db.profile.colors.available or colors.green)
    else
        return colorText("Unavailable", colors.yellow)
    end
end

local function showDropTextCovenantCheck(mapid, npcid, index) -- for getColoredDropText(mapid, npcid) If needed make it universal! Looks like a smal portion of showRare but per loot for coloring. Might make a universal check aas I need one for lootToolTip too!
    if rareDB[mapid].expansion ~= EXPANSION.SHADOWLANDS then return true end
    if index == nil then index = 1 end
    if rareDB[mapid].rares[npcid].loot[index] == nil then return false end
    if rareDB[mapid].rares[npcid].loot[index].covenantBound then
        if not WarfrontRareTracker.db.profile.menu.useMasterfilter then
            --DebugPrint("displayCovenantLootWindow(): menu - name: " .. rareDB[mapid].rares[npcid].name)
            if WarfrontRareTracker.db.profile.menu.showCovenantBoundLoot == true and rareDB[mapid].rares[npcid].loot[index].covenantBound ~= currentPlayerCovenant then
                --DebugPrint("displayCovenantLootWindow(): showCovenantBoundLoot Returns FALSE")
                return false
            end
        else
            --DebugPrint("displayCovenantLootWindow(): Master filer name: " .. rareDB[mapid].rares[npcid].name .. ", loot="..tostring(rareDB[mapid].rares[npcid].loot[index].droptype))
            if WarfrontRareTracker.db.profile.masterfilter.showCovenantBoundLoot == true and rareDB[mapid].rares[npcid].loot[index].covenantBound ~= currentPlayerCovenant then
                --DebugPrint("displayCovenantLootWindow(): showCovenantBoundLoot Returns FALSE")
                return false
            end
        end
    end
    return true
end

local function getColoredDropText(mapid, npcid)
    local text = ""
    if rareDB[mapid].rares[npcid].loot == nil then
        text =  "nil"
    end
    
    if #rareDB[mapid].rares[npcid].loot == 0 then
        text =  DROPTYPE.UNKNOWN
    elseif #rareDB[mapid].rares[npcid].loot > 0 then
        local i
        if rareDB[mapid].expansion == EXPANSION.DRAGONFLIGHT then -- rares[npcid].loot < 4 then 
            -- Abbriviation
            local loot = {}
            local known = {}

            for _, drop in pairs(rareDB[mapid].rares[npcid].loot) do
                local index = drop.droptype
                -- Just for now TEMP
                if drop.droptype == DROPTYPE.SCROLL and not drop.isKnown then
                    drop.isKnown = isQuestCompleted(drop.checkId)
                end
                --
                loot[index] = (loot[index] or 0) + 1
                if drop.isKnown then
                    known[index] = (known[index] or 0) + 1
                end
            end
            for i = 1, #rareDB[mapid].rares[npcid].loot, 1 do

                -- Just for now TEMP
                -- if rareDB[mapid].expansion == EXPANSION.DRAGONFLIGHT and rareDB[mapid].rares[npcid].loot[i].droptype == DROPTYPE.SCROLL and not rareDB[mapid].rares[npcid].loot[i].isKnown then
                --     rareDB[mapid].rares[npcid].loot[i].isKnown = isQuestCompleted(rareDB[mapid].rares[npcid].loot[i].checkId)
                -- end
                --

                -- if rareDB[mapid].rares[npcid].loot[i].covenantBound and rareDB[mapid].rares[npcid].loot[i].covenantBound ~= currentPlayerCovenant then
                --     text = text .. colorText(rareDB[mapid].rares[npcid].loot[i].droptype, colors.red)
                -- elseif WarfrontRareTracker.db.profile.colors.colorizeDrops and rareDB[mapid].rares[npcid].loot[i].isKnown then
                --     table.insert(loot, {dr})
                --     text = text .. colorText(rareDB[mapid].rares[npcid].loot[i].droptype, WarfrontRareTracker.db.profile.colors.knownColor)
                -- elseif WarfrontRareTracker.db.profile.colors.colorizeDrops and not rareDB[mapid].rares[npcid].loot[i].isKnown then
                --     text = text .. colorText(rareDB[mapid].rares[npcid].loot[i].droptype, WarfrontRareTracker.db.profile.colors.unknownColor)
                -- else
                --     text = text .. rareDB[mapid].rares[npcid].loot[i].droptype
                -- end
            end
            for key, value in pairs(loot) do
                if string.len(text) > 1 then
                    text = text .. ", "
                end
                if known[key] then
                    if known[key] == value then -- All
                        text = text .. colorText(key .. " (" .. known[key] .. "/" .. value ..")", WarfrontRareTracker.db.profile.colors.knownColor)
                    else -- Partial
                        text = text .. colorText(key .. " (" .. known[key] .. "/" .. value ..")", WarfrontRareTracker.db.profile.colors.unknownColor)
                    end
                else
                    text = text .. colorText(key .. " (0/" .. value ..")", WarfrontRareTracker.db.profile.colors.unknownColor)
                end
            end
        else
            -- Normal
            for i = 1, #rareDB[mapid].rares[npcid].loot, 1 do
                if string.len(text) > 1 then
                    text = text .. colorText(", ", colors.yellow)
                end
            
                if rareDB[mapid].rares[npcid].loot[i].covenantBound and rareDB[mapid].rares[npcid].loot[i].covenantBound ~= currentPlayerCovenant then
                    text = text .. colorText(rareDB[mapid].rares[npcid].loot[i].droptype, colors.red)
                elseif WarfrontRareTracker.db.profile.colors.colorizeDrops and rareDB[mapid].rares[npcid].loot[i].isKnown then
                    text = text .. colorText(rareDB[mapid].rares[npcid].loot[i].droptype, WarfrontRareTracker.db.profile.colors.knownColor)
                elseif WarfrontRareTracker.db.profile.colors.colorizeDrops and not rareDB[mapid].rares[npcid].loot[i].isKnown then
                    text = text .. colorText(rareDB[mapid].rares[npcid].loot[i].droptype, WarfrontRareTracker.db.profile.colors.unknownColor)
                else
                    text = text .. rareDB[mapid].rares[npcid].loot[i].droptype
                end
            end
        end
    else
        text =  DROPTYPE.UNKNOWN
        DebugPrint(colorText(format("Function getColoredDropText(%d, %d): ", mapid, npcid), colors.yellow) .. "ELSE!!!!!!!!")
    end
    if string.len(text) == 0 then
        text = colorText("Covenant Bound", colors.red)
    end
    return text
end

local function getColoredPercentage(percentage)
    local progress = floor(percentage * 100 + 0.5)
    local color
    if progress < 25 then
        color = colors.red
    elseif progress < 50 then
        color = colors.orange
    elseif progress < 75 then
        color = colors.yellow
    else
        color = colors.green
    end
    return colorText(progress .. "%", color)
end

local function getColoredTimeLeft(timeNextChange, broker)
    local daysLeft, hoursLeft, minutesLeft, secondsLeft = getWarfrontTimeLeft(timeNextChange)
    if broker then
        if daysLeft > 0 then
            return colorText(format("%dD %dH %dM Left", daysLeft, hoursLeft, minutesLeft), colors.green)
        else
            if hoursLeft < 1 then
                return colorText(format("%sM Left", minutesLeft), colors.red)
            elseif hoursLeft < 12 then
                return colorText(format("%sH %sM Left", hoursLeft, minutesLeft), colors.orange)
            else
                return colorText(format("%sH %sM Left", hoursLeft, minutesLeft), colors.yellow)
            end
        end
    else
        if daysLeft > 0 then
            return colorText(format("%sDays %sHours %sMinutes", daysLeft, hoursLeft, minutesLeft), colors.green)
        else
            if hoursLeft < 1 then
                return colorText(format("%sMinutes", minutesLeft), colors.red)
            elseif hoursLeft < 12 then
                return colorText(format("%sHours %sMinutes", hoursLeft, minutesLeft), colors.orange)
            else
                return colorText(format("%sHours %sMinutes", hoursLeft, minutesLeft), colors.yellow)
            end
        end
    end
end

local function getDBZoneType(mapid)
    if mapid == nil then
        mapid = getPlayerSelectedZone()
    end
    if rareDB[mapid] == nil then
        return DB_ZONE_TYPE_UNKNOWN
    elseif rareDB[mapid].zoneType == nil then
        return DB_ZONE_TYPE_UNKNOWN
    else
        return rareDB[mapid].zoneType
    end
end

local function hasDBContributionInfo(mapid)
    if mapid == nil then
        mapid = getPlayerSelectedZone()
    end

    if rareDB[mapid].allianceContributionMapID == nil or rareDB[mapid].allianceContributionMapID <= 0 or rareDB[mapid].hordeContributionMapID == nil or rareDB[mapid].hordeContributionMapID <= 0 then
        return false
    end

    if rareDB[mapid].zoneContributionMapID ~= nil and rareDB[mapid].zoneContributionMapID > 0 then
        return true
    else
        return false
    end
end

local function getWarfrontZoneInfo(mapid)
    if mapid == nil then
        mapid = getPlayerSelectedZone()
    end
    local state
    local factionControlling
    if getDBZoneType(mapid) == DB_ZONE_TYPE_TRACKED then
        local contributionMapID = rareDB[mapid].zoneContributionMapID
        if contributionMapID == nil or contributionMapID <= 0 then
            return nil, nil
        end
        local zoneState, zonePercentage, zoneTimeNextChange, zoneTimeStarted = C_ContributionCollector.GetState(contributionMapID)
        state = zoneState
        if zoneState == 1 or zoneState == 2 then -- Arathi is under Alliance control
            factionControlling = FACTION.ALLIANCE
        end
        if zoneState == 3 or zoneState == 4 then -- Arathi is under Horde control
            factionControlling = FACTION.HORDE
        end
    else
        state = nil
        factionControlling = nil
    end
    return state, factionControlling
end

local function isWarfrontFactionChanged(mapid)
    if mapid == nil then
        mapid = getPlayerSelectedZone()
    end
    local state, factionControlling = getWarfrontZoneInfo(mapid)
    local dbFactionControlling = rareDB[mapid].warfrontControlledByFaction
    if factionControlling ~= nil and dbFactionControlling ~= nil then
        return dbFactionControlling ~= factionControlling
    else
        return false
    end
end

local function getWarfrontProgressInfo(mapid)
    if mapid == nil then
        mapid = getPlayerSelectedZone()
    end

    if getDBZoneType(mapid) == DB_ZONE_TYPE_TRACKED then
        local state, factionControlling = getWarfrontZoneInfo(mapid)
        local zoneId
        if state == 1 or state == 2 then -- Horde has control   
            zoneId = rareDB[mapid].hordeContributionMapID
        else
            zoneId = rareDB[mapid].allianceContributionMapID
        end
        local zoneState, zonePercentage, zoneTimeNextChange, zoneTimeStarted = C_ContributionCollector.GetState(zoneId)
        return zoneState, zonePercentage, zoneTimeNextChange
    else
        return 0, 0, 0
    end
end

local function checkFactionWarfrontControl(mapid)
    if mapid == nil then
        mapid = getPlayerSelectedZone()
    end

    if getDBZoneType(mapid) == DB_ZONE_TYPE_TRACKED then
        local state, factionControlling = getWarfrontZoneInfo(mapid)
        if rareDB[mapid].warfrontControlledByFaction == "" then
            if factionControlling == nil then
                return
            end
            rareDB[mapid].warfrontControlledByFaction = factionControlling
            return
        end

        if rareDB[mapid].warfrontControlledByFaction ~= "" and rareDB[mapid].warfrontControlledByFaction ~= factionControlling then
            rareDB[mapid].warfrontControlledByFaction = factionControlling
            WarfrontRareTracker:OnFactionChange(mapid)

            if WarfrontRareTracker.db.profile.general.enableZoneChangeMessage then
                local prefix = factionControlling == currentPlayerFaction and "Good" or "Bad"
                local faction = rareDB[mapid].warfrontControlledByFaction == FACTION.HORDE and colorText(FACTION.HORDE, colors.red) or colorText(FACTION.ALLIANCE, colors.blue)
                WarfrontRareTracker:Print(colorText(format("%s news everyone. The ", prefix), colors.turqoise) .. faction .. colorText(" has gained control over ", colors.turqoise) .. colorText(rareDB[mapid].zonename, colors.lightcyan) .. colorText("!", colors.turqoise))
                if WarfrontRareTracker.db.profile.general.enableZoneChangeSound then
                    playSound(prefix)
                end
            end
        end
        rareDB[mapid].warfrontControlledByFaction = factionControlling
    end
end

local checkWarfrontControlDone = false
local function checkWarfrontControl(mapid)
    local checkAll = false
    if mapid == nil then
        checkAll = true
    end

    if checkAll then
        for dbmapid, v in pairs(rareDB) do
            checkFactionWarfrontControl(dbmapid)
        end
    else
        checkFactionWarfrontControl(mapid)
    end
    if not checkWarfrontControlDone then
        checkWarfrontControlDone = true
        C_Timer.After(4, function() checkWarfrontControl() end)
    end
end

local function rareHasLoot(mapid, npcid)
    if rareDB[mapid].rares[npcid].loot == nil then
        return false
    end
    return #rareDB[mapid].rares[npcid].loot > 0
end

local function rareHasAllLoot(mapid, npcid)
    local i
    for i = 1, #rareDB[mapid].rares[npcid].loot do
        if not rareDB[mapid].rares[npcid].loot[i].isKnown then
            return false
        end
    end
    return true
end

local function checkWhitelist(mapid, npcid, whitelist)
    if type(whitelist) ~= "table" then
        return false
    end
    local i
    for i = 1, #rareDB[mapid].rares[npcid].loot do
        if whitelist[rareDB[mapid].rares[npcid].loot[i].droptype] == true then
            return true
        end
    end
    return false
end

local function rareIsPlayerCovenant(mapid, npcid)
    return rareDB[mapid].rares[npcid].covenantBound == currentPlayerCovenant
end

local function rareHasOnlyCovenantLoot(mapid, npcid)
    local i
    local count = 0
    for i = 1, #rareDB[mapid].rares[npcid].loot do
        if rareDB[mapid].rares[npcid].loot[i].covenantBound then
            count = count + 1
        end
    end
    --DebugPrint("rareHasOnlyCovenantLoot() END RESULT -> Name="..rareDB[mapid].rares[npcid].name..", Count="..count.."/"..tostring(#rareDB[mapid].rares[npcid].loot).."   RETURN (count == #rareDB[mapid].rares[npcid].loot)= " .. tostring(count == #rareDB[mapid].rares[npcid].loot), colors.turqoise)
    return count == #rareDB[mapid].rares[npcid].loot
end

local function rareHasLegitLoot(mapid, npcid)
    if rareDB[mapid].rares[npcid].type == RARETYPE.GOLIATH then
        return false
    end
    if rareDB[mapid].rares[npcid].loot == nil then
        return false
    end
    if #rareDB[mapid].rares[npcid].loot == 0 then
        return false
    elseif #rareDB[mapid].rares[npcid].loot == 1 then
        return rareDB[mapid].rares[npcid].loot[1].droptype ~= DROPTYPE.UNKNOWN
    else
        local i
        for i = 1, #rareDB[mapid].rares[npcid].loot do
            if rareDB[mapid].rares[npcid].loot[i].droptype == DROPTYPE.UNKNOWN then
                return false
            end
        end
    end
    return true
end

local function rareHasLegitQuests(mapid, npcid)
    if rareDB[mapid].rares[npcid].questId == nil then
        return false
    end
    if #rareDB[mapid].rares[npcid].questId > 0 then
        if #rareDB[mapid].rares[npcid].questId == 1 then
            return rareDB[mapid].rares[npcid].questId[1] > 0 or rareDB[mapid].rares[npcid].questId[1] == -1
        else
            local i
            local legit = true
            for i = 1, #rareDB[mapid].rares[npcid].questId do
                if rareDB[mapid].rares[npcid].questId[i] <= 0 then
                    return false
                end
            end
            return legit
        end
    else
        if rareDB[mapid].rares[npcid].type == RARETYPE.WORLDBOSS then
            return true
        else
            return false
        end
    end
end

local function showRare(mapid, npcid, mode)
    if isNPCPlayerFaction(mapid, npcid) then
        if rareDB[mapid].zoneType == DB_ZONE_TYPE_ASSAULT and WarfrontRareTracker.db.profile.masterfilter.ignoreAssault == false and rareDB[mapid].rares[npcid].assault ~= nil then
            if checkRareAssault(mapid, npcid) == false then
                return false
            end
        end
        
        if mode == "worldmap" and not WarfrontRareTracker.db.profile.worldmapicons.useMasterfilter then
            if WarfrontRareTracker.db.profile.worldmapicons.handleDefeated == "hide" and areAllQuestsCompleted(mapid, npcid) then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.alwaysShowWorldboss and rareDB[mapid].rares[npcid].type == RARETYPE.WORLDBOSS then
                return true
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideGoliaths and rareDB[mapid].rares[npcid].type == RARETYPE.GOLIATH then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideAncients and rareDB[mapid].rares[npcid].type == RARETYPE.ANCIENT then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideUnknowLoot and not rareHasLoot(mapid, npcid) then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideUnknowLoot and not rareHasLegitQuests(mapid, npcid) then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideUnavailable and rareDB[mapid].rares[npcid].bothphases == false and rareDB[mapid].warfrontControlledByFaction ~= currentPlayerFaction then
                return false 
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideUntrackable and rareHasLoot(mapid, npcid) and rareDB[mapid].rares[npcid].questId[1] == -1 then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideGearOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.GEAR_ONLY then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideAnimaOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.ANIMA_ONLY then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideQuestOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.QUEST then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideBlueprintOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.BLUEPRINT then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideItemOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.ITEM then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideTransmogOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.TRANSMOG then
                return false
            elseif rareDB[mapid].rares[npcid].covenantBound and not WarfrontRareTracker.db.profile.worldmapicons.showCovenantBoundRares and rareDB[mapid].rares[npcid].covenantBound ~= currentPlayerCovenant then
                --DebugPrint("ShowRare(MasterFiler): covenantBound hide: " .. tostring(rareDB[mapid].rares[npcid].name))
                return false
            elseif not WarfrontRareTracker.db.profile.worldmapicons.showCovenantBoundLoot and rareHasOnlyCovenantLoot(mapid, npcid) then
                --DebugPrint("ShowRare(MasterFiler): covenantBoundLoot hide: " .. tostring(rareDB[mapid].rares[npcid].name))
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideAlreadyKnown and rareHasLoot(mapid, npcid) and rareHasAllLoot(mapid, npcid) then
                return checkWhitelist(mapid, npcid, WarfrontRareTracker.db.profile.worldmapicons.whitelist)
            else
                return true
            end
        elseif mode == "menu" and not WarfrontRareTracker.db.profile.menu.useMasterfilter then
            if WarfrontRareTracker.db.profile.menu.alwaysShowWorldboss and rareDB[mapid].rares[npcid].type == RARETYPE.WORLDBOSS then
                return true
            elseif WarfrontRareTracker.db.profile.menu.hideGoliaths and rareDB[mapid].rares[npcid].type == RARETYPE.GOLIATH then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideAncients and rareDB[mapid].rares[npcid].type == RARETYPE.ANCIENT then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideUnknowLoot and not rareHasLoot(mapid, npcid) then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideUnknowLoot and not rareHasLegitQuests(mapid, npcid) then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideUnavailable and rareDB[mapid].rares[npcid].bothphases == false and rareDB[mapid].warfrontControlledByFaction ~= currentPlayerFaction then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideUntrackable and rareHasLoot(mapid, npcid) and rareDB[mapid].rares[npcid].questId[1] == -1 then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideGearOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.GEAR_ONLY then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideAnimaOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.ANIMA_ONLY then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideQuestOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.QUEST then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideBlueprintOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.BLUEPRINT then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideItemOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.ITEM then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideTransmogOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.TRANSMOG then
                return false
            elseif rareDB[mapid].rares[npcid].covenantBound and not WarfrontRareTracker.db.profile.menu.showCovenantBoundRares and rareDB[mapid].rares[npcid].covenantBound ~= currentPlayerCovenant then
                --DebugPrint("ShowRare(MasterFiler): covenantBound hide: " .. tostring(rareDB[mapid].rares[npcid].name))
                return false
            elseif not WarfrontRareTracker.db.profile.menu.showCovenantBoundLoot and rareHasOnlyCovenantLoot(mapid, npcid) then
                --DebugPrint("ShowRare(MasterFiler): covenantBoundLoot hide: " .. tostring(rareDB[mapid].rares[npcid].name))
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideAlreadyKnown and rareHasLoot(mapid, npcid) and rareHasAllLoot(mapid, npcid) then
                return checkWhitelist(mapid, npcid, WarfrontRareTracker.db.profile.menu.whitelist)
            else
                return true
            end
        else
            if mode == "worldmap" then
                if WarfrontRareTracker.db.profile.masterfilter.worldmapShowOnlyAtPhase == true and rareDB[mapid].zoneType == DB_ZONE_TYPE_TRACKED and rareDB[mapid].hidden == true then
                    return false
                elseif WarfrontRareTracker.db.profile.masterfilter.worldmapShowOnlyAtMaxLevel and not IsPlayerWarfrontLevel() then
                    return false
                elseif WarfrontRareTracker.db.profile.masterfilter.worldmapHandleDefeated == "hide" and areAllQuestsCompleted(mapid, npcid) then
                    return false
                end
            end
            if WarfrontRareTracker.db.profile.masterfilter.alwaysShowWorldboss and rareDB[mapid].rares[npcid].type == RARETYPE.WORLDBOSS then
                return true
            elseif WarfrontRareTracker.db.profile.masterfilter.hideGoliaths and rareDB[mapid].rares[npcid].type == RARETYPE.GOLIATH then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideAncients and rareDB[mapid].rares[npcid].type == RARETYPE.ANCIENT then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideUnknowLoot and not rareHasLoot(mapid, npcid) then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideUnknowLoot and not rareHasLegitQuests(mapid, npcid) then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideUnavailable and rareDB[mapid].rares[npcid].bothphases == false and rareDB[mapid].warfrontControlledByFaction ~= currentPlayerFaction then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideUntrackable and rareHasLoot(mapid, npcid) and rareDB[mapid].rares[npcid].questId[1] == -1 then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideGearOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.GEAR_ONLY then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideAnimaOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.ANIMA_ONLY then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideQuestOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.QUEST then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideBlueprintOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.BLUEPRINT then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideItemOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.ITEM then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideTransmogOnly and rareHasLoot(mapid, npcid) and #rareDB[mapid].rares[npcid].loot == 1 and rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.TRANSMOG then
                return false
            elseif rareDB[mapid].rares[npcid].covenantBound and not WarfrontRareTracker.db.profile.masterfilter.showCovenantBoundRares and rareDB[mapid].rares[npcid].covenantBound ~= currentPlayerCovenant then
                --DebugPrint("ShowRare(MasterFiler): covenantBound hide: " .. tostring(rareDB[mapid].rares[npcid].name))
                return false
            elseif not WarfrontRareTracker.db.profile.masterfilter.showCovenantBoundLoot and rareHasOnlyCovenantLoot(mapid, npcid) then
                --DebugPrint("ShowRare(MasterFiler): covenantBoundLoot hide: " .. tostring(rareDB[mapid].rares[npcid].name))
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideAlreadyKnown and rareHasLoot(mapid, npcid) and rareHasAllLoot(mapid, npcid) then
                return checkWhitelist(mapid, npcid, WarfrontRareTracker.db.profile.masterfilter.whitelist)
            else
                return true
            end
            return true
        end
    else
        return false
    end
end

local function playerHasMount(mountID)
    local name, spellId, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
    if isCollected then
        return true
    end
    return false
end

-- New but NYI: Check per LootType instead of fireing a Check ALL, This might reduce time as it skips everything non related. TODO: Rename scanForKnownItems(), <- this function is for the initial scan upon login to scan everything!
-- for mapid, content in pairs(rareDB) do
--     for k, rare in pairs(content.rares) do
--         if #rare.loot > 0 then
--             local i
--             for i = 1, #rare.loot do
--                 if rare.loot[i].droptype == DROPTYPE.MOUNT then
--                     -- Got the correct Loot, now check it
--                 end
--             end
--         end
--     end
-- end
local function checkAddedMount()
    for mapid, content in pairs(rareDB) do
        for k, rare in pairs(content.rares) do
            if #rare.loot > 0 then
                local i
                for i = 1, #rare.loot do
                    if rare.loot[i].droptype == DROPTYPE.MOUNT then
                        if playerHasMount(rare.loot[i].mountID) and rare.loot[i].isKnown == false then
                            rare.loot[i].isKnown = true
                        end
                    end
                end
            end
        end
    end
end
local function checkAddedPet() -- TODO: Add the count of the pets so it can show (1/1, 1/3, 2/3 or 3/3) Collected!
    for mapid, content in pairs(rareDB) do
        for k, rare in pairs(content.rares) do
            if #rare.loot > 0 then
                local i
                for i = 1, #rare.loot do
                    if rare.loot[i].droptype == DROPTYPE.PET then
                        local number, _ = C_PetJournal.GetNumCollectedInfo(rare.loot[i].speciesID);
                        if number >= 1  and rare.loot[i].isKnown == false then
                            rare.loot[i].isKnown = true
                        end
                    end
                end
            end
        end
    end
    
end
local function checkAddedToy()
    for mapid, content in pairs(rareDB) do
        for k, rare in pairs(content.rares) do
            if #rare.loot > 0 then
                local i
                for i = 1, #rare.loot do
                    if rare.loot[i].droptype == DROPTYPE.TOY then
                        if PlayerHasToy(rare.loot[i].itemID)  and rare.loot[i].isKnown == false then
                            rare.loot[i].isKnown = true
                        end
                    end
                end
            end
        end
    end
    
end
local function checkAddedTransmog()
    for mapid, content in pairs(rareDB) do
        for k, rare in pairs(content.rares) do
            if #rare.loot > 0 then
                local i
                for i = 1, #rare.loot do
                    if rare.loot[i].droptype == DROPTYPE.TRANSMOG then
                        if C_TransmogCollection.PlayerHasTransmog(rare.loot[i].itemID) and rare.loot[i].isKnown == false then
                            rare.loot[i].isKnown = true
                        end
                    end
                end
            end
        end
    end
end
-- checkItem need a different implementation as it's not learnable and only a few are flagged complete once you used it to activate a Rare or whatever.
  
local function scanForKnownItems()
    if newPetAdedTimer then
        WarfrontRareTracker:CancelTimer(newPetAdedTimer)
        newPetAdedTimer = nil
    end
    for mapid, content in pairs(rareDB) do
        for k, rare in pairs(content.rares) do -- checkMountID
            if #rare.loot > 0 then
                local i
                for i = 1, #rare.loot do
                    if rare.loot[i].droptype == DROPTYPE.MOUNT then
                        --local name, spellId, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(rare.loot[i].mountID)
                        if playerHasMount(rare.loot[i].mountID) then
                            rare.loot[i].isKnown = true
                        end
                    elseif rare.loot[i].droptype == DROPTYPE.ITEM and rare.loot[i].checkMountID ~= nil then -- TODO: Need to be able to check multiple types in the New Framework!!! Some items can be marked hidden after obtaining a 2nd item as the 1th item is a tool you use to activate a Rare. Once the 2nd Rare's loot is collected, the 1st Item isn't needed anymore!
                        --local name, spellId, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(rare.loot[i].checkMountID)
                        if playerHasMount(rare.loot[i].checkMountID) then
                            rare.loot[i].isKnown = true
                        end
                    elseif rare.loot[i].droptype == DROPTYPE.TOY then
                        if PlayerHasToy(rare.loot[i].itemID) then
                            rare.loot[i].isKnown = true
                        end
                    elseif rare.loot[i].droptype == DROPTYPE.PET then
                        local number, _ = C_PetJournal.GetNumCollectedInfo(rare.loot[i].speciesID);
                        if number >= 1 then
                            rare.loot[i].isKnown = true
                        end
                    elseif rare.loot[i].droptype == DROPTYPE.QUEST or rare.loot[i].droptype == DROPTYPE.BLUEPRINT or rare.loot[i].droptype == DROPTYPE.SCROLL then
                        if rare.loot[i].checkId ~= nil and rare.loot[i].checkId > 0 and C_QuestLog.IsQuestFlaggedCompleted(rare.loot[i].checkId) then
                            rare.loot[i].isKnown = true
                        end
                    elseif rare.loot[i].droptype == DROPTYPE.TRANSMOG then
                        if C_TransmogCollection.PlayerHasTransmog(rare.loot[i].itemID) then
                            rare.loot[i].isKnown = true
                        end
                    end
                end
            end
        end
    end
end

local function setBrokerIcon(mapid, faction)
    if mapid == nil then mapid = getPlayerSelectedZone() end
    if mapid and rareDB[mapid].expansion == EXPANSION.SHADOWLANDS then
        WarfrontRareTracker.broker.icon = BROKER_ICON_SHADOWLANDS
    elseif mapid and rareDB[mapid].expansion == EXPANSION.DRAGONFLIGHT then
        WarfrontRareTracker.broker.icon = BROKER_ICON_DRAGONFLIGHT
    elseif mapid and rareDB[mapid].expansion == EXPANSION.BFA then
        if faction == FACTION.ALLIANCE then
            WarfrontRareTracker.broker.icon = BROKER_ICON_ALLIANCE
        elseif faction == FACTION.HORDE then
            WarfrontRareTracker.broker.icon = BROKER_ICON_HORDE
        else
            WarfrontRareTracker.broker.icon = BROKER_ICON_UNKNOWN
        end
    else
        WarfrontRareTracker.broker.icon = BROKER_ICON_UNKNOWN
    end
end

local function updateBrokerText(mapid)
    if updateBrokerTimer then
        WarfrontRareTracker:CancelTimer(updateBrokerTimer)
        updateBrokerTimer = nil
    end
    if mapid then
        checkWarfrontControl(mapid)
    else
        checkWarfrontControl()
    end
    local canSchedule = false
    local scheduleState = 0
    local brokerText
    local factionControlling = rareDB[getPlayerSelectedZone()].warfrontControlledByFaction
    setBrokerIcon(mapid, factionControlling)
    if WarfrontRareTracker.db.profile.broker.showBrokerText then
        if WarfrontRareTracker.db.profile.broker.brokerText == "addonname" then
            brokerText = "Warfront Rare Tracker"
        elseif WarfrontRareTracker.db.profile.broker.brokerText == "factionstatus" then
            if getDBZoneType(mapid) == DB_ZONE_TYPE_TRACKED then
                canSchedule = true
                if factionControlling ~= currentPlayerFaction then
                    local state, percentage, timeNextChange = getWarfrontProgressInfo()
                    if state ~= nil and state == 1 then
                        if percentage ~= nil then
                            scheduleState = 1
                            brokerText = colorText("Contribution: ", colors.turqoise) .. getColoredPercentage(percentage)
                        else
                            scheduleState = 1
                            brokerText = colorText("Contributing", colors.turqoise)
                        end
                    elseif state ~= nil and state == 2 then
                        if timeNextChange ~= nil then
                            scheduleState = 2
                            brokerText = colorText("Scenario: ", colors.turqoise) .. getColoredTimeLeft(timeNextChange, true)
                        else
                            scheduleState = 2
                            brokerText = colorText("Scenario", colors.turqoise)
                        end
                    else 
                        scheduleState = 3
                        brokerText = colorText("Collecting Info...", colors.turqoise)
                    end
                else
                    factionControlling = rareDB[getPlayerSelectedZone()].warfrontControlledByFaction == FACTION.HORDE and colorText(FACTION.HORDE, colors.red) or colorText(FACTION.ALLIANCE, colors.blue)
                    brokerText = factionControlling .. colorText(" Has Control", colors.turqoise)
                    canSchedule = false
                end
            elseif getDBZoneType(mapid) == DB_ZONE_TYPE_UNTRACKED or getDBZoneType(mapid) == DB_ZONE_TYPE_UNKNOWN then
                brokerText = colorText(rareDB[getPlayerSelectedZone()].zonename, colors.lightcyan)
            elseif getDBZoneType(mapid) == DB_ZONE_TYPE_ASSAULT then
                brokerText = colorText(rareDB[getPlayerSelectedZone()].zonename, colors.orange)
            else
                brokerText = colorText("Unknown Zone", colors.orange)
            end
        elseif WarfrontRareTracker.db.profile.broker.brokerText == "allstatus" then
            canSchedule = true
            if getDBZoneType(mapid) == DB_ZONE_TYPE_TRACKED then
                local oppositeFaction = rareDB[getPlayerSelectedZone()].warfrontControlledByFaction == FACTION.HORDE and colorText("(A) ", colors.blue) or colorText("(H) ", colors.red)
                local state, percentage, timeNextChange = getWarfrontProgressInfo()
                if state ~= nil and state == 1 then
                    if percentage ~= nil then
                        scheduleState = 1
                        brokerText = oppositeFaction .. colorText("Contribution: ", colors.turqoise) .. getColoredPercentage(percentage)
                    else
                        scheduleState = 1
                        brokerText = oppositeFaction .. colorText("Contributing", colors.turqoise)
                    end
                elseif state ~= nil and state == 2 then
                    if timeNextChange ~= nil then
                        scheduleState = 2
                        brokerText = oppositeFaction .. colorText("Scenario: ", colors.turqoise) .. getColoredTimeLeft(timeNextChange, true)
                    else
                        scheduleState = 2
                        brokerText = oppositeFaction .. colorText("Scenario", colors.turqoise)
                    end
                else
                    scheduleState = 3
                    brokerText = colorText("Collecting Info...", colors.turqoise)
                end
            elseif getDBZoneType(mapid) == DB_ZONE_TYPE_UNTRACKED or getDBZoneType(mapid) == DB_ZONE_TYPE_UNKNOWN then
                brokerText = colorText(rareDB[getPlayerSelectedZone()].zonename, colors.lightcyan)
            elseif getDBZoneType(mapid) == DB_ZONE_TYPE_ASSAULT then
                brokerText = colorText(rareDB[getPlayerSelectedZone()].zonename, colors.orange)
            else
                brokerText = colorText("Unknown Zone", colors.orange)
            end
        elseif WarfrontRareTracker.db.profile.broker.brokerText == "zonename" then
            brokerText = rareDB[getPlayerSelectedZone()].zonename
        else
            brokerText = "Unkown Setting"
        end
    else
        brokerText = ""
    end
    if canSchedule and scheduleState > 0 then
        local scheduleTime
        if scheduleState == 1 then
            scheduleTime = tonumber(WarfrontRareTracker.db.profile.broker.updateIntervalState1) * SECONDS_IN_MIN
        elseif scheduleState == 2 then
            scheduleTime = tonumber(WarfrontRareTracker.db.profile.broker.updateIntervalState2) * SECONDS_IN_MIN
        else
            scheduleTime = SECONDS_IN_MIN
        end
        updateBrokerTimer = WarfrontRareTracker:ScheduleTimer(function() updateBrokerText() end, scheduleTime) -- update text at configured interval
    end
    WarfrontRareTracker.broker.text = brokerText
end

local function getCoordsForWarfrontPhase(mapid, npcid, cave)
    if rareDB[mapid].rares[npcid] == nil or type(rareDB[mapid].rares[npcid]) ~= "table" then
        return 0
    end
    if cave then
        if rareDB[mapid].rares[npcid].cave == nil then
            return 0
        end
        if #rareDB[mapid].rares[npcid].cave.coord == 1 then
            return rareDB[mapid].rares[npcid].cave.coord[1]
        else
            if rareDB[mapid].warfrontControlledByFaction == FACTION.ALLIANCE then
                return rareDB[mapid].rares[npcid].cave.coord[1]
            else
                return rareDB[mapid].rares[npcid].cave.coord[2]
            end
        end
    else
        if #rareDB[mapid].rares[npcid].coord == 1 then
            return rareDB[mapid].rares[npcid].coord[1]
        else
            if rareDB[mapid].warfrontControlledByFaction == FACTION.ALLIANCE then
                return rareDB[mapid].rares[npcid].coord[1]
            else
                return rareDB[mapid].rares[npcid].coord[2]
            end
        end
    end
end

local function hasValidCoord(mapid, npcid)
    if rareDB[mapid] ~= nil and rareDB[mapid].rares[npcid] ~= nil and rareDB[mapid].rares[npcid].coord ~= nil and #rareDB[mapid].rares[npcid].coord > 0 then
        for k, c in pairs(rareDB[mapid].rares[npcid].coord) do
            if string.len(tostring(c)) == 8 then
                return true
            end
        end
    end
    return false
end

local function getCoordsForPhase(mapid, npcid, tomtom)
    if not hasValidCoord(mapid, npcid) then
        return 0, 0
    end

    local coord = rareDB[mapid].rares[npcid].coord[1]
    if #rareDB[mapid].rares[npcid].coord > 1 and rareDB[mapid].warfrontControlledByFaction == FACTION.HORDE then
        coord = rareDB[mapid].rares[npcid].coord[2]
    end
    local x, y = 0, 0
    if tomtom ~= nil and tomtom == true then
        x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
    else
        x, y = floor(coord / 10000) / 100, (coord % 10000) / 100
    end
    return x, y
end

local function announceRare(mapid, npcid, mode)
    if mode == nil or mapid == nil and npcid == nil then return end
    if not hasValidCoord(mapid, npcid) then
        return 0, 0
    end
    
    local x, y = getCoordsForPhase(mapid, npcid)
    if x <= 0 or y <= 0 then return end
    if mode == "group" then
        if WarfrontRareTracker.db.profile.tomtom.tomtomAnnounceLeader == true and UnitIsGroupLeader("player") or WarfrontRareTracker.db.profile.tomtom.tomtomAnnounceLeader == false then
            if IsInRaid() then
                SendChatMessage(format("We're now heading to '%s'! Coords x = %.2f, y = %.2f", rareDB[mapid].rares[npcid].name, x, y), "RAID", nil, nil)
            elseif IsInGroup() then
                SendChatMessage(format("We're now heading to '%s'! Coords x = %.2f, y = %.2f", rareDB[mapid].rares[npcid].name, x, y), "PARTY", nil, nil)
            end
        end
    elseif mode == "local" then
        -- Local announce in /1
        if isPlayerInWarfront() and mapid == currentPlayerMapid then
            SendChatMessage(format("%s is up. /way %.0f, %.0f", rareDB[mapid].rares[npcid].name, x, y), "CHANNEL", nil, 1)
        else
            print(colorText("Warning: ", colors.orange) .. colorText("The rare you've selected is from a different zone. Message isn't send to prevent spam!", colors.yellow))
        end
    elseif mode == "tomtom" then
        -- Chat Message
        if WarfrontRareTracker.db.profile.tomtom.enableChatMessage then
            WarfrontRareTracker:Print(colorText("Added waypoint to: ", colors.turqoise) .. getColoredRareName(mapid, npcid))
        end
    end
end

local function addToTomTom(mapid, npcid)
    if type(rareDB[mapid]) ~= "table" then
        WarfrontRareTracker:Print(colorText("Error adding Waypoint: ", colors.red) .. colorText("Couldn't find zone ", colors.yellow) .. colorText(mapid, colors.orange) .. colorText(" in the Database.", colors.yellow))
        return
    elseif type(rareDB[mapid].rares[npcid]) ~= "table" then
        WarfrontRareTracker:Print(colorText("Error adding Waypoint: ", colors.red) .. colorText("Couldn't find Rare with npcid ", colors.yellow) .. colorText(npcid, colors.orange) .. colorText(" in the Database.", colors.yellow))
        return
    elseif not hasValidCoord(mapid, npcid) then
        WarfrontRareTracker:Print(colorText("Error adding Waypoint: ", colors.red) .. colorText("Rare with npcid ", colors.yellow) .. colorText(npcid, colors.orange) .. colorText(" is missing Coordinates in the Database.", colors.yellow))
        return
    end 

    if isTomTomloaded and WarfrontRareTracker.db.profile.tomtom.enableIntegration then
        local factionControlling = rareDB[mapid].warfrontControlledByFaction
        local rare = rareDB[mapid].rares[npcid]
        local coord = rare.coord[1]
        if #rare.coord > 1 and factionControlling == FACTION.HORDE then
            coord = rare.coord[2]
        end
        local name = rare.name

        local x, y = getCoordsForPhase(mapid, npcid, true)

        TomTom:AddWaypoint(mapid, x, y, {
            title = name,
            persistent = nil,
            minimap = true,
            world = true,
        })
        if rare.cave and type(rare.cave) == "table" then -- and rare.cave.infoOnly == nil then
            if rare.cave.infoOnly then
                return
            end
            coord = rare.cave.coord[1]
            if #rare.cave > 1 and factionControlling == FACTION.HORDE then
                coord = rare.cave.coord[2]
            end
            if rare.cave.caveNote and type(rare.cave.caveNote) == "string" then
                name = name .. rare.cave.caveNote
            else
                name = name .. " Cave Entrance"
            end
            x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
            TomTom:AddWaypoint(mapid, x, y, {
                title = name,
                persistent = nil,
                minimap = true,
                world = true,
            })
        end
        announceRare(mapid, npcid, "tomtom")
    end
end

-- REMOVED
-- local function playerLeveledUp(newLevel)
--     if newLevel == PLAYER_WARFRONT_LEVEL and WarfrontRareTracker.db.profile.general.enableLevelUpChatMessage then
--         if WarfrontRareTracker.db.profile.general.enableLevelUpSound then
--             C_Timer.After(5, function() WarfrontRareTracker:Print(colorText("Good news everyone. You are now egliable to fight enter Warfronts!", colors.turqoise)); playSound("good") end)
--         end
--     end  
-- end

local function sortLootTables()
    for mapid, contents in pairs(rareDB) do
        for npcid, rare in pairs(contents.rares) do
            if rare.loot ~= nil and #rare.loot > 1 then
                table.sort(rare.loot, function(a, b) return a.droptype < b.droptype end)
            end
        end
    end
end

local function checkWarfrontZonePhases()
    for mapid, contents in pairs(rareDB) do
        local artID = C_Map.GetMapArtID(mapid)
        if contents.zoneType == DB_ZONE_TYPE_TRACKED and contents.zonephaseID ~= artID then
            contents.hidden = true
        end
    end
end

local function setPlayersCovenant()
    currentPlayerCovenant = C_Covenants.GetActiveCovenantID() -- returns 0 if no Covenant chosen so is safe to use!
end

----------------------
-- Addon Compatibility
----------------------

-- MinimapButtonBag
-- Add Minimap Icons to the 'Ignore List' or else the addon thinks all Icons are an Addon Icon at the edge of the Minimap.
local function checkMBBPinExclusion()
    if IsAddOnLoaded("MBB") then
        if MBB_Ignore ~= nil then
            local pinAlreadyExcluded = false
            for k, v in pairs(MBB_Ignore) do
                if v == WARFRONT_PINNAME then
                    pinAlreadyExcluded = true
                end
            end
            if pinAlreadyExcluded == false then
                MBB_Ignore[#MBB_Ignore + 1] = WARFRONT_PINNAME
                if WarfrontRareTracker.db.global.printCompatibilityMessage1 then
                    C_Timer.After(15, function() WarfrontRareTracker:Print(colorText("Addon ", colors.turqoise) .. colorText("Minimap Button Bag", colors.yellow) .. colorText(" found, minimap icons are automatically blacklisted!", colors.turqoise)) end)
                    WarfrontRareTracker.db.global.printCompatibilityMessage1 = false
                end
            end
        end
    end
end

-- MinimapButtonFrame
-- Add Minimap Icons to the 'Ignore List' or else the addon thinks all Icons are an Addon Icon at the edge of the Minimap.
local function checkMBFPinExclusion()
    if IsAddOnLoaded("MinimapButtonFrame") then
        if bachMBF.db.profile.MinimapIcons ~= nil then
            local pinAlreadyExcluded = false
            for k, v in pairs(bachMBF.db.profile.MinimapIcons) do
                if v == WARFRONT_PINNAME then
                    pinAlreadyExcluded = true
                end
            end
            if pinAlreadyExcluded == false then
                bachMBF.db.profile.MinimapIcons[#bachMBF.db.profile.MinimapIcons + 1] = WARFRONT_PINNAME
                if WarfrontRareTracker.db.global.printCompatibilityMessage2 then
                    C_Timer.After(15, function() WarfrontRareTracker:Print(colorText("Addon ", colors.turqoise) .. colorText("Minimap Button Frame", colors.yellow) .. colorText(" found, minimap icons are automatically blacklisted!", colors.turqoise)) end)
                    WarfrontRareTracker.db.global.printCompatibilityMessage2 = false
                end
            end
        end
    end
end

local function checkAddonCompatibility()
    checkMBBPinExclusion()
    checkMBFPinExclusion()
end

------------
-- Ace3 Init
------------
function WarfrontRareTracker:OnInitialize()
    self.broker = LDB:NewDataObject("WarfrontRareTracker", {
        type = "data source",
        label = "WarfrontRareTracker",
        icon = BROKER_ICON_UNKNOWN,
        text = "Loading",
        OnEnter = function(self) WarfrontRareTracker:MenuOnEnter(self) end,
        OnLeave = function() WarfrontRareTracker:MenuOnLeave() end,
        OnClick = function(self, button) WarfrontRareTracker:MenuOnClick(self, button) end,
    })

    self.db = LibStub("AceDB-3.0"):New("WarfrontRareTrackerDB", dbDefaults, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    WarfrontRareTracker:RegisterOptions()
    MinimapIcon:Register("WarfrontRareTracker", self.broker, self.db.profile.minimap)
    WarfrontRareTracker:InitWarfrontSwitchTable()
    WarfrontRareTracker:populateSelectionMenu()
end

local delayedInitializeDone = false
function WarfrontRareTracker:DelayedInitialize(init)
    if init == false and delayedInitializeDone == false then
        return
    end
    WarfrontRareTracker:DelayedConfigInitialize()
    if IsAddOnLoaded("TomTom") then
        isTomTomloaded = true
    end
    if rareDB[WarfrontRareTracker.db.char.selectedZone] == nil then
        WarfrontRareTracker.db.char.selectedZone = 14
    end
    checkAssaults()
    scanForKnownItems()
    checkWarfrontZonePhases()
    self:UpdateAllWorldMapIcons()
    updateBrokerText()
    C_Timer.After(5, function() WarfrontRareTracker:RefreshAllData() end)
    delayedInitializeDone = true
    WarfrontRareTracker:InitWarfrontPhaseChange()
end

function WarfrontRareTracker:OnEnable()
    -- Normal Events
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("NEW_MOUNT_ADDED", "OnEvent")
    self:RegisterEvent("NEW_PET_ADDED", "OnEvent")
    -- self:RegisterEvent("PLAYER_LEVEL_UP")
    self:RegisterEvent("QUEST_WATCH_UPDATE")
    self:RegisterEvent("QUEST_ACCEPTED")
    self:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_ADDED", "TRANSMOG_EVENTS")
    self:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_REMOVED", "TRANSMOG_EVENTS")
    self:RegisterEvent("COVENANT_CHOSEN")
    -- Bucket Events
    self:RegisterBucketEvent("ZONE_CHANGED", 1, "ZONE_CHANGED")
    self:RegisterBucketEvent("ZONE_CHANGED_INDOORS", 1, "ZONE_CHANGED")
    self:RegisterBucketEvent("ZONE_CHANGED_NEW_AREA", 1,"ZONE_CHANGED")
    
    self:RegisterBucketEvent("LOOT_CLOSED", 1,"BUCKET_ON_LOOT_RECEIVED")
    self:RegisterBucketEvent("PLAYER_MONEY", 2, "BUCKET_ON_LOOT_RECEIVED") -- if worldboss only drops money
    self:RegisterBucketEvent("SHOW_LOOT_TOAST", 2, "BUCKET_ON_LOOT_RECEIVED")
    self:RegisterBucketEvent("SHOW_LOOT_TOAST_UPGRADE", 2,"BUCKET_ON_LOOT_RECEIVED")
    self:RegisterBucketEvent("ENCOUNTER_LOOT_RECEIVED", 2, "BUCKET_ON_LOOT_RECEIVED")
    self:RegisterBucketEvent("TOYS_UPDATED", 2,"TOYS_UPDATED") -- NEW_TOY_ADDED?
    -- Set variables and Worldmap Icons   
    self:DelayedInitialize(false)
end

function WarfrontRareTracker:OnDisable()
    -- Normal Events
    self:UnregisterEvent("NEW_MOUNT_ADDED")
    self:UnregisterEvent("NEW_PET_ADDED")
    -- self:UnregisterEvent("PLAYER_LEVEL_UP")
    self:UnregisterEvent("QUEST_WATCH_UPDATE")
    self:UnregisterEvent("QUEST_ACCEPTED")
    self:UnregisterEvent("TRANSMOG_COLLECTION_SOURCE_ADDED")
    self:UnregisterEvent("TRANSMOG_COLLECTION_SOURCE_REMOVED")
    self:UnregisterEvent("COVENANT_CHOSEN")
    -- Bucket Events
    self:UnregisterBucket("ZONE_CHANGED")
    self:UnregisterBucket("ZONE_CHANGED_INDOORS")
    self:UnregisterBucket("ZONE_CHANGED_NEW_AREA")
    self:UnregisterBucket("LOOT_CLOSED")
    self:UnregisterBucket("PLAYER_MONEY")
    self:UnregisterBucket("SHOW_LOOT_TOAST")
    self:UnregisterBucket("SHOW_LOOT_TOAST_UPGRADE")
    self:UnregisterBucket("ENCOUNTER_LOOT_RECEIVED")
    self:UnregisterBucket("TOYS_UPDATED")
    -- Delete Worldmap Icons
    self:DeleteAllWorldmapIcons()
    delayedInitializeDone = false
end

----------------
-- Events
----------------
-- Event Handler
-- local function checkAddedMount()
-- end
-- local function checkAddedPet()
-- end
-- local function checkAddedToy()
-- end
-- local function checkAddedTransmog()
-- end

function WarfrontRareTracker:OnEvent(event, ...)
    if event == "NEW_MOUNT_ADDED" and IsPlayerWarfrontLevel() then
        scanForKnownItems()
        --checkAddedMount()
    elseif event == "NEW_PET_ADDED" and IsPlayerWarfrontLevel() then
        if newPetAdedTimer == nil then
            newPetAdedTimer = self:ScheduleTimer(function() scanForKnownItems() end, 2)
            --newPetAdedTimer = self:ScheduleTimer(function() checkAddedPet() end, 2)
        end
    end
end

----------------
-- Normal Events
local function handleTransmog(itemID, add) -- On init Create Lookup Table with entry [itemID] = { mapid = mapid, npcid = npcid, lootIndex = index }. This might be a better idea.
    for mapid, contents in pairs(rareDB) do
        for npcid, rare in pairs(contents.rares) do
            if rare.loot and #rare.loot > 0 then
                local i
                for i = 1, #rare.loot do
                    if rare.loot[i].droptype == DROPTYPE.TRANSMOG then
                        if rare.loot[i].itemID == itemID then
                            --DebugPrint(format("Rare %s has loot with itemID: %d", rare.name, itemID))
                            if add then
                                rare.loot[i].isKnown = true
                            else
                                rare.loot[i].isKnown = false
                            end
                        end
                    end
                end
            end
        end
    end
end

function WarfrontRareTracker:TRANSMOG_EVENTS(event, appearanceID)
    if appearanceID == nil or appearanceID < 0 then return end
    local itemID = C_Transmog.GetItemIDForSource(appearanceID)
    if itemID and itemID > 0 then
        if event == "TRANSMOG_COLLECTION_SOURCE_ADDED" then -- TRANSMOG ADDED
            handleTransmog(itemID, true)
        elseif event == "TRANSMOG_COLLECTION_SOURCE_REMOVED" then -- TRANSMOG REMOVED
            handleTransmog(itemID, false)
        end
    end
end

function WarfrontRareTracker:PLAYER_ENTERING_WORLD()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    currentPlayerLevel = UnitLevel("player")
    currentPlayerName = UnitName("player")
    currentPlayerFaction = UnitFactionGroup("player")
    currentPlayerRealm = GetRealmName()
    setPlayersCovenant()
    WarfrontRareTracker:ZONE_CHANGED()
    checkAddonCompatibility()
    checkWarfrontControl()
    sortLootTables()
    WarfrontRareTracker:SortRares()
    C_Timer.After(5, function() WarfrontRareTracker:DelayedInitialize(true) end)
end

function WarfrontRareTracker:QUEST_WATCH_UPDATE(_, questID)
    if questID == 56376 then
        --print('Uldum assaults unlock detected')
        C_Timer.After(1, function()
            checkAssaults()
        end)
    end
end

function WarfrontRareTracker:QUEST_ACCEPTED(_, questID)
    if questID == 56540 then
        --print('Vale assaults unlock detected')
        C_Timer.After(1, function()
            checkAssaults()
        end)
    end
end

-- REMOVED
-- function WarfrontRareTracker:PLAYER_LEVEL_UP(event, newLevel, ...)
--     playerLeveledUp(newLevel)
--     --C_Timer.After(10, function(self, newLevel) playerLeveledUp(newLevel) end, newLevel)
-- end

function WarfrontRareTracker:COVENANT_CHOSEN(event, covenantID)
    DebugPrint(colorText("EVENT[COVENANT_CHOSEN] ", colors.yellow) .. colorText(format("Args: event=%s, xx=%s", colorText(tostring(event), colors.yellow), colorText(tostring(covenantID), colors.yellow)), colors.turqoise))
    if covenantID then
        if covenantID > 0 then
            currentPlayerCovenant = covenantID
            self:RefreshShadowlandsIcons()
        end
    else
        -- Safe way
        C_Timer.After(10, function() setPlayersCovenant() end)
    end
end

----------------
-- Bucket events
function WarfrontRareTracker:BUCKET_ON_LOOT_RECEIVED()
    if IsPlayerWarfrontLevel() and isPlayerInWarfront() and not playerIsInInstance then
        if isSessionLocked("BUCKET_ON_LOOT_RECEIVED") then
            return
        end
        C_Timer.After(3, function() WarfrontRareTracker:CheckAndUpdateZoneWorldMapIcons() end)
    end
end

local function isWarfrontInCorrectPhase(mapid)
    if rareDB[mapid] == nil then
        return false
    end
    return C_Map.GetMapArtID(currentPlayerMapid) == rareDB[mapid].zonephaseID
end

-- New
local function printMapChanges(currentParentMapid, currentMapName, previousMapid, text)
    if text == nil then text = "None" end
    if previousMapid > 0 then
        local parentMap = C_Map.GetMapInfo(currentParentMapid)
        local oldMap = C_Map.GetMapInfo(previousMapid)
        print(colorText("[WRT] ", colors.orange)..colorText("ZONE_CHANGED() ", colors.turqoise)..colorText(format("NEW: MapID=%d, Name=%s, ParentID=%d, ParentName=%s. | PREV: MapID=%d, INFO: %s", currentPlayerMapid, currentMapName, currentParentMapid, parentMap.name, previousMapid, text), colors.lightcyan))
    else
        print(colorText("[WRT] ", colors.orange)..colorText("ZONE_CHANGED() ", colors.turqoise)..colorText(format("NEW: MapID=%d, ParentID=%d, Name=%s. | PREV: MapID=%d (New Session?), INFO: %s", currentPlayerMapid, currentParentMapid, currentMapName, previousMapid, text), colors.lightcyan))
    end
end

function WarfrontRareTracker:ZONE_CHANGED()
    local currentMapid = C_Map.GetBestMapForUnit("player")
    if currentMapid == nil then
        currentMapid = 0
    elseif currentMapid ~= currentPlayerMapid then
        local previousMapid = currentPlayerMapid
        --DebugPrint("ZONE_CHANGED: currentPlayerMapid="..currentPlayerMapid..", previousMapid="..previousMapid)
        currentPlayerMapid = currentMapid
        playerIsInInstance, _ = IsInInstance()
        self:CheckMapChange(previousMapid)
    elseif currentMapid == currentPlayerMapid and rareDB[currentPlayerMapid] ~= nil then
        -- also Update??
        --DebugPrint("ZONE_CHANGED: WRT WarfrontRareTracker:ZONE_CHANGED(): also Update??")
    end
end

function WarfrontRareTracker:CheckMapChange(previousMapid)
    if currentPlayerMapid == nil or currentPlayerMapid <= 0 then return end
    if previousMapid == currentPlayerMapid then return end
    local mapInfo = C_Map.GetMapInfo(currentPlayerMapid)
    local currentParentMapid = mapInfo.parentMapID
    if currentParentMapid > 0 then -- TODO: check if exists after testing
        --printMapChanges(currentParentMapid, mapInfo.name, previousMapid)
        currentPlayerParentMapid = currentParentMapid
    end
    currentPlayerParentMapid = currentParentMapid

    local previousAutoChangeMapid = autoChangeZone
    if self.db.profile.menu.autoChangeZone then
        if rareDB[currentPlayerMapid] then
            printMapChanges(currentParentMapid, mapInfo.name, previousMapid, "NORMAL!")
            autoChangeZone = currentPlayerMapid
            if self.db.profile.menu.autoSaveZone then
                self.db.char.selectedZone = currentPlayerMapid
            end
            if rareDB[currentPlayerMapid].expansion and rareDB[currentPlayerMapid].expansion == EXPANSION.DRAGONFLIGHT then
                WarfrontRareTracker:RefreshDragonManuscritps(currentPlayerMapid)
            end
        elseif currentParentMapid > 0 and rareDB[currentParentMapid] then
            --printMapChanges(currentParentMapid, mapInfo.name, previousMapid, "PARENT!!!")
            autoChangeZone = currentParentMapid
            if self.db.profile.menu.autoSaveZone then
                self.db.char.selectedZone = currentParentMapid
            end
        else
            --reset auto
            if autoChangeZone ~= nil then
                autoChangeZone = nil
            end
        end
    else
        if autoChangeZone ~= nil then
            autoChangeZone = nil
        end
    end
    
    if self.db.profile.menu.autoChangeZone and autoChangeZone ~= previousAutoChangeMapid then
        -- Something has changed and all needs a refresh. Get the Timed Refresh code from the ON_ZONE_CHANGED Function here!!!
        --DebugPrint("CheckMapChange() has changed, executing CheckWarfrontPhaseChange("..tostring(autoChangeZone)..")", colors.green)
        WarfrontRareTracker:SetTimestamp(false)
        if autoChangeZone ~= nil then
            C_Timer.After(3, function() WarfrontRareTracker:CheckWarfrontPhaseChange(autoChangeZone) end)
        end
    end
end

function WarfrontRareTracker:TOYS_UPDATED()
    if IsPlayerWarfrontLevel() then
        scanForKnownItems()
        --checkAddedToy()
    end
end

----------
-- Refresh
----------
function WarfrontRareTracker:RefreshMinimap()
    LibStub("LibDBIcon-1.0"):Refresh("WarfrontRareTracker", self.db.profile.minimap)
end

function WarfrontRareTracker:RefreshConfig()
    self:OnRefreshConfig()
    self:RefreshMinimap()
    self:RefreshBrokerText()
    self:UpdateAllWorldMapIcons()
    self:SortRares()
end

function WarfrontRareTracker:RefreshAllData()
    checkWarfrontControl()
    self:RefreshBrokerText()
end

function WarfrontRareTracker:RefreshZoneData(mapid)
    updateBrokerText(mapid)
    self:UpdateZoneWorldMapIcons(mapid)
end

function WarfrontRareTracker:RefreshBrokerText()
    updateBrokerText()
end

function WarfrontRareTracker:SetTimestamp(manual)
    if manual and manual == true then
        manualTimestamp = GetServerTime()
    else
        autoChangeZoneTimestamp = GetServerTime()
    end
    self:RefreshBrokerText()
end

function WarfrontRareTracker:RefreshShadowlandsIcons()
    for mapid, content in pairs(rareDB) do
        if content.expansion == EXPANSION.SHADOWLANDS then
            self:UpdateZoneWorldMapIcons(mapid)
        end
    end
end

function WarfrontRareTracker:RefreshDragonManuscritps(mapid, npcid, index)
    if mapid and npcid and index and type(mapid) == "number" and type(npcid) == "number" and type(index) == "number" then
        rareDB[mapid].rares[npcid].loot[index].isKnown = isQuestCompleted(rareDB[mapid].rares[npcid].loot[index].checkId)
        --print("WRT - RefreshDragonManuscritps: " .. tostring(loot.isKnown) .. tostring(format("  - mapid: %d, npcid: %d, index: :d", mapid, npcid, index)))
    -- elseif mapid and type(mapid) == "number" and rareDB[mapid].expansion == EXPANSION.DRAGONFLIGHT then
    --     for mapid, npcid in pairs(rareDB) do
    --         for index, loot in pairs(rareDB[mapid].rares[npcid].loot) do
    --             if loot.droptype and loot.droptype == DROPTYPE.SCROLL then
    --                 loot.isKnown = isQuestCompleted(loot.checkId)
    --                 print("WRT - RefreshDragonManuscritps: " .. tostring(loot.isKnown))
    --             end
    --         end
    --     end
    end

    -- for drake, upgrade in pairs(DRAGONSCROLLS) do
    --     if drake == drakename then
    --         for upgradename, content in pairs(upgrade) do
    --             if upgradename == itemname then
    --                 itemid = content.item
    --                 questid = content.quest
    --                 if type(itemid) ~= "number" then
    --                     print ("DRAGONSCROLLS: ERROR itemid")
    --                 end
    --                 if type(questid) ~= "number" then
    --                     print("DRAGONSCROLLS: ERROR questid")
    --                 end
    --             end
    --         end
    --     end
    -- end

    -- if rareDB[mapid].expansion == EXPANSION.DRAGONFLIGHT and rareDB[mapid].rares[npcid].loot[i].droptype == DROPTYPE.SCROLL and not rareDB[mapid].rares[npcid].loot[i].isKnown then
    --     rareDB[mapid].rares[npcid].loot[i].isKnown = isQuestCompleted()
    -- end
end

-----------------
-- Main functions
-----------------
local currentPhaseID = 0
local previousPhaseID = 0
local function checkIconsForPhase(mapid)
    if rareDB[mapid].zoneType == DB_ZONE_TYPE_TRACKED then
        if currentPhaseID == rareDB[mapid].zonephaseID then
            if rareDB[mapid].hidden == true then
                rareDB[mapid].hidden = false
                WarfrontRareTracker:RefreshZoneData(mapid)
            end
        else
            if rareDB[mapid].hidden == false then
                rareDB[mapid].hidden = true
                WarfrontRareTracker:RefreshZoneData(mapid)
            end
        end
    end
end

function WarfrontRareTracker:CheckWarfrontPhaseChange(mapid)
    if delayedInitializeDone == false then
        return
    end

    if type(rareDB[mapid]) == "table" then -- If we are in a Warfont zone we need to keep track of it
        if currentPhaseID == 0 then
            currentPhaseID = C_Map.GetMapArtID(mapid)
        end
        previousPhaseID = currentPhaseID
        currentPhaseID = C_Map.GetMapArtID(mapid)

        if currentPhaseID > 0 and currentPhaseID ~= previousPhaseID then
            --checkIconsForPhase()
            C_Timer.After(1, function() checkIconsForPhase(mapid) end)
        end
    end
end

function WarfrontRareTracker:InitWarfrontPhaseChange()
    local phaseID = 0
    for mapid, content in pairs(rareDB) do
        phaseID = C_Map.GetMapArtID(mapid)
        if content.zoneType == DB_ZONE_TYPE_TRACKED and phaseID ~= content.zonephaseID then
            content.hidden = true
        end
    end
end

function WarfrontRareTracker:GetRareDBSize()
    return getBDSize(rareDB)
end

function WarfrontRareTracker:ColorizeText(text, color)
    return colorText(text, color)
end

function WarfrontRareTracker:OnFactionChange(mapid)
    self:RefreshZoneData(mapid)
end

-- function WarfrontRareTracker:CheckMapChange(oldMapid)
    -- This is where the function usually resides. I moved it up for debug reasons.
-- end

function WarfrontRareTracker:SetWorldmapIconSize(size, minimap)
    if minimap then
        self.db.profile.minimapIcons.minimapIconSize = size
        for mapid, content in pairs(rareDB) do
            for k, icon in pairs(content.minimapIcons) do
                if rareDB[mapid].rares[icon.npcid].type == RARETYPE.WORLDBOSS or rareDB[mapid].rares[icon.npcid].type == RARETYPE.ELITE or rareDB[mapid].rares[icon.npcid].type == RARETYPE.ANCIENT then
                    icon:SetHeight(size + 3)
                    icon:SetWidth(size + 3)
                else
                    icon:SetHeight(size)
                    icon:SetWidth(size)
                end
            end
        end
    else
        self.db.profile.worldmapicons.worldmapIconSize = size
        for mapid, content in pairs(rareDB) do
            for k, icon in pairs(content.worldmapIcons) do
                if rareDB[mapid].rares[icon.npcid].type == RARETYPE.WORLDBOSS or rareDB[mapid].rares[icon.npcid].type == RARETYPE.ELITE or rareDB[mapid].rares[icon.npcid].type == RARETYPE.ANCIENT then
                    icon:SetHeight(size + 3)
                    icon:SetWidth(size + 3)
                else
                    icon:SetHeight(size)
                    icon:SetWidth(size)
                end
            end
        end
    end
end

function WarfrontRareTracker:SetWorldmapIconAlpha(alpha, minimap)
    if minimap then
        self.db.profile.minimapIcons.minimapIconAlpha = alpha / 100
        for mapid, content in pairs(rareDB) do
            for k, icon in pairs(content.minimapIcons) do
                icon:SetAlpha(self.db.profile.minimapIcons.minimapIconAlpha)
            end
        end
    else
        self.db.profile.worldmapicons.worldmapIconAlpha = alpha / 100
        for mapid, content in pairs(rareDB) do
            for k, icon in pairs(content.worldmapIcons) do
                icon:SetAlpha(self.db.profile.worldmapicons.worldmapIconAlpha)
            end
        end
    end
    
end

function WarfrontRareTracker:GetWorldmapIconAlpha(minimap)
    if minimap then
        return self.db.profile.minimapIcons.minimapIconAlpha * 100
    else
        return self.db.profile.worldmapicons.worldmapIconAlpha * 100
    end
end

function WarfrontRareTracker:SetMenuAlpha(alpha)
    self.db.profile.colors.menuAlpha = alpha / 100
end

---------------
-- Tooltips
---------------
-- Menu Tooltip
local warfrontSwitchTable = {}
function WarfrontRareTracker:InitWarfrontSwitchTable()
    for mapid, contents in pairs(rareDB) do
        if contents.index then
            warfrontSwitchTable[contents.index] = mapid
        end
    end
end

local function switchToNextWarfront()
    local index = rareDB[WarfrontRareTracker.db.char.selectedZone].index + 1
    if index > getBDSize(rareDB) or warfrontSwitchTable[index] == nil then
        index = 1
    end
    WarfrontRareTracker.db.char.selectedZone = warfrontSwitchTable[index]
    if menuTooltip then
        WarfrontRareTracker:UpdateMenuToolTip(menuTooltip)
    end
end

function WarfrontRareTracker:MenuOnClick(self, button)
    if button == "RightButton" then
        LibStub("AceConfigDialog-3.0"):Open("WarfrontRareTracker")
    elseif button == "LeftButton" and IsShiftKeyDown() then
        switchToNextWarfront()
    elseif button == "LeftButton" and not IsShiftKeyDown() then
        if WarfrontRareTracker.db.profile.menu.showMenuOn ~= "click" then
            return
        end
        if WarfrontRareTracker.db.profile.menu.hideOnCombat and UnitAffectingCombat("player") then
            return
        end
        if WarfrontRareTracker.db.profile.menu.showAtMaxLevel and not IsPlayerWarfrontLevel() then
            return
        end
        if menuTooltip == nil then
            WarfrontRareTracker:ShowMenu(self)
        else
            WarfrontRareTracker:MenuOnLeave()
        end
    end
end

function WarfrontRareTracker:MenuOnEnter(self)
    if WarfrontRareTracker.db.profile.menu.showMenuOn ~= "mouse" then
        return
    end
    if WarfrontRareTracker.db.profile.menu.hideOnCombat and UnitAffectingCombat("player") then
        return
    end
    if WarfrontRareTracker.db.profile.menu.showAtMaxLevel and not IsPlayerWarfrontLevel() then
        return
    end
    WarfrontRareTracker:ShowMenu(self)
end

function WarfrontRareTracker:MenuOnLeave()
    if menuTooltip and MouseIsOver(menuTooltip) then
        return
    else
        if menuTooltip then
            LibQTip:Release(menuTooltip)
            menuTooltip = nil
            isWarfrontSelectionMenuCollapsed = true
            selectedWarfrontSelectionMenuExpansion = nil
        end
    end
end

function WarfrontRareTracker:ShowMenu(self)
    menuTooltip = LibQTip:Acquire("WarfrontRareTrackerMenuTip")
	menuTooltip:SmartAnchorTo(self)
    menuTooltip:SetAutoHideDelay(0.25, self, function() WarfrontRareTracker:MenuOnLeave() end)
    menuTooltip:EnableMouse(true)

    WarfrontRareTracker:UpdateMenuToolTip(menuTooltip)

	if menuTooltip:GetLineCount() >= 1 then
        menuTooltip:UpdateScrolling()
        -- if WarfrontRareTracker.db.profile.general.disableBackground == false then
        --     menuTooltip:SetBackdrop(tooltipBackDrop)
        --     menuTooltip:SetBackdropColor(0.2, 0.2, 0.2, WarfrontRareTracker.db.profile.colors.menuAlpha)
        -- end
        menuTooltip:Show()
    end
end

function WarfrontRareTracker:UpdateMenuToolTip(menuTooltip)
    local mapid = getPlayerSelectedZone()
    if getBDSize(sortedRareDB[mapid]) <= 0 then return end
    local line
    
    menuTooltip:Clear();
    menuTooltip:SetColumnLayout(3, "LEFT", "LEFT", "LEFT")

    line = menuTooltip:AddHeader()
    menuTooltip:SetCell(line, 1, colorText("Warfront Rare Tracker", colors.yellow), menuTooltip:GetHeaderFont(), "CENTER", 3)

    line = menuTooltip:AddLine()
    menuTooltip:SetCell(line, 1, " ", nil, "LEFT", 3)

    WarfrontRareTracker:ShowMenuWarfrontSelection(mapid, menuTooltip)

    line = menuTooltip:AddLine()
    menuTooltip:SetCell(line, 1, " ", nil, "LEFT", 3)


    if rareDB[mapid].zoneType ~= nil and rareDB[mapid].zoneType == DB_ZONE_TYPE_ASSAULT and rareDB[mapid].currentAssault ~= nil and rareDB[mapid].currentAssault == assaultType.unknown then
        line = menuTooltip:AddLine()
        menuTooltip:SetCell(line, 1, colorText("Area not unlocked yet!", colors.red), menuTooltip:GetHeaderFont(), "CENTER", 3)
        menuTooltip:AddSeparator()
    else
        menuTooltip:AddSeparator()
    end


    line = menuTooltip:AddHeader()
    menuRow1, menuCol1 = menuTooltip:SetCell(line, 1, "Rare")
    menuRow2, menuCol2 = menuTooltip:SetCell(line, 2, "Drops", nil, "LEFT", 1, LibQTip.LabelProvider, 10, nil, 150, 60)
    menuRow3, menuCol3 = menuTooltip:SetCell(line, 3, "Status")
    menuTooltip:AddSeparator()

    for k, npcid in pairs(sortedRareDB[mapid]) do
        if showRare(mapid, npcid, "menu") then
            local name = getColoredRareName(mapid, npcid)
            local drop = getColoredDropText(mapid, npcid)
            local status = getColoredStatusText(mapid, npcid)
            
            local info = mapid..":"..npcid

            line = menuTooltip:AddLine()
            menuTooltip:SetCell(line, 1, name)
            menuTooltip:SetCell(line, 2, drop, nil, "LEFT", 1, LibQTip.LabelProvider, 10, nil, 150, 60)
            menuTooltip:SetCell(line, 3, status)
            menuTooltip:SetLineScript(line, "OnEnter", function(self, info) WarfrontRareTracker:MenuTooltipOnLineEnter(self, info) end, info)
            menuTooltip:SetLineScript(line, "OnLeave", function() WarfrontRareTracker:MenuTooltipOnLineLeave() end)
            menuTooltip:SetLineScript(line, "OnMouseUp", function(self, info, button) WarfrontRareTracker:MenuTooltipOnLineClick(self, info, button) end, info)
        end
    end
    

    if WarfrontRareTracker.db.profile.menu.showWarfrontInMenu then
        --menuTooltip:AddSeparator()
        WarfrontRareTracker:WarfrontStatusInfoTooltip(true)
    end

    menuTooltip:AddSeparator()
    if isTomTomloaded and WarfrontRareTracker.db.profile.tomtom.enableIntegration then
        line = menuTooltip:AddLine()
        menuTooltip:SetCell(line, 1, colorText("Left-Click to add TomTom Waypoint.", colors.turqoise), "LEFT", 3)
    end
    
    line = menuTooltip:AddLine()
    menuTooltip:SetCell(line, 1, colorText("Right-Click the icon to open Options.", colors.turqoise), "LEFT", 3)
    if IsInRaid() then
        line = menuTooltip:AddLine()
        menuTooltip:SetCell(line, 1, colorText("Shift Left-Click to announce in Raid Chat.", colors.turqoise), "LEFT", 3)
    elseif IsInGroup() then
        line = menuTooltip:AddLine()
        menuTooltip:SetCell(line, 1, colorText("Shift Left-Click to announce in Party Chat.", colors.turqoise), "LEFT", 3)
    else
        line = menuTooltip:AddLine()
        menuTooltip:SetCell(line, 1, colorText("Shift Right-Click to announce in /1.", colors.turqoise), "LEFT", 3)
    end
    line = menuTooltip:AddLine()
    menuTooltip:SetCell(line, 1, colorText("Shift Left-Click the icon to cycle Warfront.", colors.turqoise), "LEFT", 3)
end

function WarfrontRareTracker:MenuTooltipOnLineClick(self, info, button)
    local mapid, npcid = strsplit(':', info)
    mapid = tonumber(mapid)
    npcid = tonumber(npcid)
    if mapid == nil or npcid == nil then return end
    if button == "LeftButton" then
       if isTomTomloaded and WarfrontRareTracker.db.profile.tomtom.enableIntegration then
            if IsShiftKeyDown() then
                announceRare(mapid, npcid, "group")
            else
                addToTomTom(mapid, npcid)
            end
        end
    elseif button == "RightButton" and IsShiftKeyDown() then
        announceRare(mapid, npcid, "local")
    end
end

----------------------------------
-- Menu Warfront Selection Tooltip
local oldSelectedZone
local SELECTION_MENU = {}
local MENU_EXPANSION_LIST = {}

function WarfrontRareTracker:populateSelectionMenu() -- Move up and make local (rename in INIT)
    SELECTION_MENU = {}
    for dbMapid, content in pairs(rareDB) do
        local entry = {}
        entry.mapid = dbMapid
        entry.zonename = content.zonename
        entry.expansion = content.expansion
        table.insert(SELECTION_MENU, entry)
    end
    for key , expansion in pairs(EXPANSION) do
        table.insert(MENU_EXPANSION_LIST, expansion)
    end
    --table.sort(MENU_EXPANSION_LIST)
    table.sort(SELECTION_MENU, function(a,b) return a.expansion < b.expansion or a.expansion == b.expansion and a.zonename < b.zonename end)
end

function WarfrontRareTracker:MenuWarfrontSelectionToolOnCick(self, mapid, button)
    if isWarfrontSelectionMenuCollapsed then
        oldSelectedZone = WarfrontRareTracker.db.char.selectedZone
        isWarfrontSelectionMenuCollapsed = false
    else
        WarfrontRareTracker.db.char.selectedZone = mapid
        if oldSelectedZone ~= nil or oldSelectedZone ~= mapid then
            WarfrontRareTracker:SetTimestamp(true)
        end
        isWarfrontSelectionMenuCollapsed = true
        selectedWarfrontSelectionMenuExpansion = nil
    end
    WarfrontRareTracker:UpdateMenuToolTip(menuTooltip)
end

function WarfrontRareTracker:ShowMenuWarfrontSelection(mapid, tooltip)
    local line
    if isWarfrontSelectionMenuCollapsed and getBDSize(rareDB) <= 1 then
        line = tooltip:AddHeader()
        tooltip:SetCell(line, 1, colorText(rareDB[mapid].zonename, colors.lightcyan), tooltip:GetHeaderFont(), "CENTER", 3)
    elseif isWarfrontSelectionMenuCollapsed and getBDSize(rareDB) > 1 then
        line = tooltip:AddHeader()
        tooltip:SetCell(line, 1, colorText(rareDB[mapid].zonename, colors.lightcyan), tooltip:GetHeaderFont(), "CENTER", 3)
        tooltip:SetLineScript(line, "OnEnter", function(self, mapid) WarfrontRareTracker:WarfrontStatusTooltipOnEnter(self, mapid) end, mapid)
        tooltip:SetLineScript(line, "OnLeave", function() WarfrontRareTracker:WarfrontStatusTooltipOnleave() end)
        tooltip:SetLineScript(line, "OnMouseUp", function(self, mapid, button) WarfrontRareTracker:MenuWarfrontSelectionToolOnCick(self, mapid, button) end, mapid)
    else
        line = tooltip:AddHeader()
        tooltip:SetCell(line, 1, colorText("Select Warfront", colors.yellow), tooltip:GetHeaderFont(), "CENTER", 3)
        tooltip:AddSeparator()
        local selectedColor = colors.green
        local activeColor = colors.orange

        if manualTimestamp > 0 and autoChangeZoneTimestamp > 0 and manualTimestamp >= autoChangeZoneTimestamp then
            selectedColor = colors.orange
            activeColor = colors.green
        end

        if selectedWarfrontSelectionMenuExpansion == nil then
            for _, expansion in pairs(MENU_EXPANSION_LIST) do
                line = tooltip:AddLine()
                tooltip:SetCell(line, 1, colorText(expansion, colors.lightcyan), nil, "CENTER", 3)
                tooltip:SetLineScript(line, "OnMouseUp", function(self, content, button) selectedWarfrontSelectionMenuExpansion = expansion; WarfrontRareTracker:UpdateMenuToolTip(menuTooltip) end, expansion, menuTooltip)
                
            end
        else
            for _, content in ipairs(SELECTION_MENU) do
                if content.expansion == selectedWarfrontSelectionMenuExpansion then
                    line = tooltip:AddLine()
                    if WarfrontRareTracker.db.profile.menu.autoChangeZone and autoChangeZone ~= nil and content.mapid == autoChangeZone or WarfrontRareTracker.db.profile.menu.autoChangeZone and autoChangeZone == nil and content.mapid == WarfrontRareTracker.db.char.selectedZone then
                        tooltip:SetCell(line, 1, colorText(content.zonename, selectedColor), nil, "CENTER", 3)
                    elseif WarfrontRareTracker.db.profile.menu.autoChangeZone and content.mapid == WarfrontRareTracker.db.char.selectedZone then
                        tooltip:SetCell(line, 1, colorText(content.zonename, activeColor), nil, "CENTER", 3)
                    elseif not WarfrontRareTracker.db.profile.menu.autoChangeZone and content.mapid == WarfrontRareTracker.db.char.selectedZone then
                        tooltip:SetCell(line, 1, colorText(content.zonename, selectedColor), nil, "CENTER", 3)
                    else
                        tooltip:SetCell(line, 1, colorText(content.zonename, colors.grey), nil, "CENTER", 3)
                    end
                    tooltip:SetLineScript(line, "OnMouseUp", function(self, mapid, button) WarfrontRareTracker:MenuWarfrontSelectionToolOnCick(self, mapid, button) end, content.mapid)
                end
            end
        end
        tooltip:AddSeparator()
    end
end

---------------
-- Loot Tooltip
function WarfrontRareTracker:MenuTooltipOnLineLeave()
    if lootTooltip then
        LibQTip:Release(lootTooltip)
        lootTooltip = nil
    end
end

local function getColoredCovenantText(covenantID)
    if covenantID > 0 and covenantID <= 4 then
        if covenantID == COVENANTS.KYRIAN then
            return colorText("Kyrian", colors.grey)
        elseif covenantID == COVENANTS.VENTHYR then
            return colorText("Venthyr", colors.red)
        elseif covenantID == COVENANTS.NIGHTFAE then
            return colorText("Night Fea", colors.blue)
        elseif covenantID == COVENANTS.NECROLORD then
            return colorText("Nercolord", colors.green)
        end
    else
        return colorText("Unknown", colors.orange)
    end
end

local function getRareInfoCovenantText(mapid, npcid)
    if index == nil then index = 1 end
    local rareCovenantID = rareDB[mapid].rares[npcid].covenantBound
    if rareCovenantID == currentPlayerCovenant then
        -- color right
        return colorText("Covenant Bound: ", colors.green) .. getColoredCovenantText(rareCovenantID)
    else
        --color wrong
        return colorText("Covenant Bound: ", colors.red) .. getColoredCovenantText(rareCovenantID)
    end
end

local function getLootInfoCovenantText(mapid, npcid, index)
    if index == nil then index = 1 end
    local lootCovenantID = rareDB[mapid].rares[npcid].loot[index].covenantBound
    if lootCovenantID == currentPlayerCovenant then
        -- color right
        return colorText("Covenant Availavle: ", colors.green) .. getColoredCovenantText(lootCovenantID)
    else
        --color wrong
        return colorText("Covenant Required: ", colors.red) .. getColoredCovenantText(lootCovenantID)
    end
end

local function isLootmenuCropped(mapid, npcid)
    return WarfrontRareTracker.db.profile.lootwindow.compactMode == "amount" and #rareDB[mapid].rares[npcid].loot >= WarfrontRareTracker.db.profile.lootwindow.compactModeAmount or WarfrontRareTracker.db.profile.lootwindow.compactMode == "all"
end

local function addLootInfoToTooltip(tooltip, mapid, npcid, lootindex, compactmode) -- Usable in multiple tooltips
    if rareDB[mapid].rares[npcid].loot[lootindex] == nil then
        return
    end
    if rareDB[mapid].rares[npcid].loot[lootindex].itemID > 0 then

        local itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(rareDB[mapid].rares[npcid].loot[lootindex].itemID)

        local line = tooltip:AddLine()
        tooltip:SetCell(line, 1, colorText("Drops: ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].loot[lootindex].droptype, colors.lightcyan), nil, nil, 2)

        if rareDB[mapid].rares[npcid].loot[lootindex].covenantBound then
            line = tooltip:AddLine()
            tooltip:SetCell(line, 1, getLootInfoCovenantText(mapid, npcid, lootindex), nil, nil, 2)
        end

        if itemTexture ~= nil then
            tooltip:AddHeader(itemLink or itemName, "|T" .. itemTexture .. ":22|t")
        else
            tooltip:AddHeader(itemLink or itemName)
        end
        
        npcToolTip:SetItemByID(rareDB[mapid].rares[npcid].loot[lootindex].itemID)
        if WarfrontRareTracker.db.profile.lootwindow.compactModeReguar or compactmode then
            local tooltipLine =  _G["__WarfrontRareTracker_ScanTipTextLeft" .. 2]
            local text = tooltipLine:GetText()
            if text == nil then return end
            local color = {}
            color[1], color[2], color[3], color[4] = tooltipLine:GetTextColor()

            if string.len(text) > 1 then
                line = tooltip:AddLine()
                tooltip:SetCell(line, 1, colorText(text, color), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 200)
            end
        else
            for i = 2, npcToolTip:NumLines() do
                local tooltipLine =  _G["__WarfrontRareTracker_ScanTipTextLeft" .. i]
                local text = tooltipLine:GetText()
                local color = {}
                color[1], color[2], color[3], color[4] = tooltipLine:GetTextColor()

                if string.len(text) > 1 then
                    line = tooltip:AddLine()
                    tooltip:SetCell(line, 1, colorText(text, color), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 200)
                end
            end
        end

        if rareDB[mapid].rares[npcid].loot[lootindex].isKnown then
            line = tooltip:AddLine()
            tooltip:SetCell(line, 1, colorText("Already Known", colors.red), nil, nil, 2)
        end
    elseif lootindex == 1 and rareDB[mapid].rares[npcid].loot[lootindex].itemID == 0 and rareDB[mapid].rares[npcid].loot[lootindex].droptype == DROPTYPE.GEAR_ONLY then
        line = tooltip:AddLine()
        tooltip:SetCell(line, 1, colorText("Drops: ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].loot[lootindex].droptype, colors.lightcyan), nil, nil, 2)
    end
    if rareDB[mapid].rares[npcid].loot[lootindex].note then
        tooltip:AddSeparator()
        line = tooltip:AddLine()
        tooltip:SetCell(line, 1, colorText(rareDB[mapid].rares[npcid].loot[lootindex].note, colors.orange), nil, "LEFT", 2, LibQTip.LabelProvider, nil, nil, 200)
    end
end

function WarfrontRareTracker:MenuTooltipOnLineEnter(self, info)
    local mapid, npcid = strsplit(':', info)
    mapid = tonumber(mapid)
    npcid = tonumber(npcid)
    if LibQTip:IsAcquired("WarfrontRareTrackerLootTip") and lootTooltip then
        LibQTip.Release(lootTooltip)
        lootTooltip = nil
    end
    lootTooltip = LibQTip:Acquire("WarfrontRareTrackerLootTip", 2, "LEFT", "RIGHT")
    lootTooltip:ClearAllPoints()
    lootTooltip:SetClampedToScreen(true)
    lootTooltip:SetPoint("RIGHT", self, "LEFT", -15, -18)

    lootTooltip:AddHeader(getColoredRareName(mapid, npcid))
    if rareDB[mapid].rares[npcid].covenantBound then
        line = lootTooltip:AddLine()
        lootTooltip:SetCell(line, 1, getRareInfoCovenantText(mapid, npcid), nil, nil, 2)
        --DebugPrint("MenuToolTip: Rare is Covenant bound to: " .. getColoredCovenantText(rareDB[mapid].rares[npcid].covenantBound))
    end
    line = lootTooltip:AddLine()
    lootTooltip:SetCell(line, 1, " ", nil, nil, 2)

    if rareHasLoot(mapid, npcid) then
        if isLootmenuCropped(mapid, npcid) then
            local i
            for i = 1, #rareDB[mapid].rares[npcid].loot do
                addLootInfoToTooltip(lootTooltip, mapid, npcid, i, true)
                if i < #rareDB[mapid].rares[npcid].loot then
                    lootTooltip:AddSeparator()
                end
            end
        else
            if #rareDB[mapid].rares[npcid].loot > 0 then
                local i
                for i = 1, #rareDB[mapid].rares[npcid].loot do
                    addLootInfoToTooltip(lootTooltip, mapid, npcid, i)
                    if i < #rareDB[mapid].rares[npcid].loot then
                        lootTooltip:AddSeparator()
                    end
                end
            end
        end
    else
        line = lootTooltip:AddLine()
        lootTooltip:SetCell(line, 1, colorText("No know drop", colors.lightcyan), nil, nil, 2)
    end

    if not isLootmenuCropped(mapid, npcid) and not WarfrontRareTracker.db.profile.lootwindow.alsohidenotes and rareDB[mapid].rares[npcid].note then
        line = lootTooltip:AddLine()
        lootTooltip:SetCell(line, 1, colorText("Note: ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].note, colors.orange), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 200)
    end

    if isTomTomloaded and WarfrontRareTracker.db.profile.tomtom.enableIntegration then
        lootTooltip:AddSeparator()
        line = lootTooltip:AddLine()
        lootTooltip:SetCell(line, 1, colorText("Left-Click to add TomTom Waypoint.", colors.turqoise), "LEFT", 2)
        
        if IsInRaid() then
            line = lootTooltip:AddLine()
            lootTooltip:SetCell(line, 1, colorText("Shift Left-Click to announce in Raid Chat.", colors.turqoise), "LEFT", 2)
        elseif IsInGroup() then
            line = lootTooltip:AddLine()
            lootTooltip:SetCell(line, 1, colorText("Shift Left-Click to announce in Party Chat.", colors.turqoise), "LEFT", 2)
        end
    end
    line = lootTooltip:AddLine()
    lootTooltip:SetCell(line, 1, colorText("Shift Right-Click to announce in /1.", colors.turqoise), "LEFT", 2)

    if lootTooltip:GetLineCount() > 1 then
        -- if WarfrontRareTracker.db.profile.general.disableBackground == false then
        --     lootTooltip:SetBackdrop(tooltipBackDrop)
        --     lootTooltip:SetBackdropColor(0, 0, 0, WarfrontRareTracker.db.profile.colors.menuAlpha)
        -- end
        lootTooltip:Show()
    end
end

--------------------------
-- Warfront Status Tooltip
local WarfrontStatusInfoTooltipCounter = 0

function WarfrontRareTracker:WarfrontStatusTooltipOnleave()
    if warfrontStatusTooltip then
        LibQTip:Release(warfrontStatusTooltip)
        warfrontStatusTooltip = nil
    end
end

function WarfrontRareTracker:WarfrontStatusTooltipOnEnter(self, mapid)
    if LibQTip:IsAcquired("WarfrontRareTrackerWarfrontStatusTip") and warfrontStatusTooltip then
        LibQTip.Release(warfrontStatusTooltip)
        warfrontStatusTooltip = nil
    end
    warfrontStatusTooltip = LibQTip:Acquire("WarfrontRareTrackerWarfrontStatusTip", 3, "LEFT", "LEFT", "LEFT")
    warfrontStatusTooltip:Clear()
    warfrontStatusTooltip:SetClampedToScreen(true)
    warfrontStatusTooltip:SetPoint("TOPRIGHT", self, "LEFT", -15, 17)

    if WarfrontRareTracker.db.profile.menu.showWarfrontOnZoneName and getDBZoneType(mapid) == DB_ZONE_TYPE_TRACKED and rareDB[mapid].warfrontControlledByFaction ~= "" then
        line = warfrontStatusTooltip:AddHeader()
        warfrontStatusTooltip:SetCell(line, 1, colorText("Click to select different Warfront ->", colors.yellow), warfrontStatusTooltip:GetHeaderFont(), "CENTER", 3)
        warfrontStatusTooltip:AddSeparator()

        line = warfrontStatusTooltip:AddLine()
        warfrontStatusTooltip:SetCell(line, 1, " ", nil, "LEFT", 3)

        line = warfrontStatusTooltip:AddHeader()
        warfrontStatusTooltip:SetCell(line, 1, colorText("Warfront Status", colors.yellow), warfrontStatusTooltip:GetHeaderFont(), "CENTER", 3)

        WarfrontRareTracker:WarfrontStatusInfoTooltip(false)

        if warfrontStatusTooltip:GetLineCount() > 3 then
            warfrontStatusTooltip:Show()
        end
    else
        local line = warfrontStatusTooltip:AddHeader()
        warfrontStatusTooltip:SetCell(line, 1, colorText("Click to select different Warfront", colors.yellow), warfrontStatusTooltip:GetHeaderFont())
        -- if WarfrontRareTracker.db.profile.general.disableBackground == false then
        --     warfrontStatusTooltip:SetBackdrop(tooltipBackDrop)
        --     warfrontStatusTooltip:SetBackdropColor(0, 0, 0, WarfrontRareTracker.db.profile.colors.menuAlpha)
        -- end
        warfrontStatusTooltip:Show()
    end
end

local function updateWarfrontStatusInfoTooltip(tooltip, mapid, inmenu)
    local line
    local controllingFaction = rareDB[mapid].warfrontControlledByFaction == FACTION.HORDE and colorText(FACTION.HORDE, colors.red) or colorText(FACTION.ALLIANCE, colors.blue)
    if getDBZoneType(mapid) == DB_ZONE_TYPE_TRACKED and rareDB[mapid].warfrontControlledByFaction ~= "" then
        -- print("WarfrontStatusInfoTooltipCounter: "..WarfrontStatusInfoTooltipCounter)
        -- print("update mapid: "..mapid..", type: "..rareDB[mapid].zoneType)
        if inmenu and WarfrontStatusInfoTooltipCounter == 0 or inmenu and WarfrontStatusInfoTooltipCounter == 3 then
            tooltip:AddSeparator()
            line = tooltip:AddHeader()
            tooltip:SetCell(line, 1, colorText("Warfront Status", colors.yellow), tooltip:GetHeaderFont(), "CENTER", 3)
        end

        local zoneState, zonePercentage, zoneTimeNextChange = getWarfrontProgressInfo(mapid)
        local oppositeFaction = rareDB[mapid].warfrontControlledByFaction == FACTION.HORDE and FACTION.ALLIANCE or FACTION.HORDE
        tooltip:AddSeparator()

        line = tooltip:AddHeader()
        tooltip:SetCell(line, 1, colorText(rareDB[mapid].zonename, colors.lightcyan), nil, "CENTER", 3)

        line = tooltip:AddHeader()
        if zoneState <= 2 then
            tooltip:SetCell(line, 1, colorText("Current control:", colors.yellow))
            tooltip:SetCell(line, 2, controllingFaction, nil, nil, 2)
        else
            tooltip:SetCell(line, 1, colorText("Current control:", colors.yellow))
            tooltip:SetCell(line, 2, colorText("Unknown", colors.turqoise), nil, nil, 2)
        end

        if oppositeFaction == FACTION.HORDE then
            oppositeFaction = colorText(FACTION.HORDE, colors.red)
        else
            oppositeFaction = colorText(FACTION.ALLIANCE, colors.blue)
        end
        tooltip:AddSeparator(1, colors.grey[1], colors.grey[2], colors.grey[3], 1)
        if zoneState == 1 then
            line = tooltip:AddLine()
            tooltip:SetCell(line, 1, oppositeFaction .. colorText(" Status:", colors.yellow))
            tooltip:SetCell(line, 2, colorText(rareDB[mapid].gatheringname, colors.turqoise), nil, nil, 2)

            if zonePercentage ~= nil then
                line = tooltip:AddLine()
                tooltip:SetCell(line, 1, colorText("Progress:", colors.yellow))
                tooltip:SetCell(line, 2, getColoredPercentage(zonePercentage), nil, nil, 2)
            end
        elseif zoneState == 2 then
            line = tooltip:AddLine()
            tooltip:SetCell(line, 1, oppositeFaction .. colorText(" Status:", colors.yellow))
            tooltip:SetCell(line, 2, colorText(rareDB[mapid].scenarioname, colors.turqoise), nil, nil, 2)

            if zoneTimeNextChange ~= nil then
                line = tooltip:AddLine()
                tooltip:SetCell(line, 1, colorText("Time Left:", colors.yellow))
                tooltip:SetCell(line, 2, getColoredTimeLeft(zoneTimeNextChange, false), nil, nil, 2)
            end
        else
            line = tooltip:AddLine()
            tooltip:SetCell(line, 1, colorText("Status:", colors.yellow))
            tooltip:SetCell(line, 2, colorText("Unknown", colors.turqoise), nil, nil, 2)
        end
    elseif getDBZoneType(mapid) == DB_ZONE_TYPE_UNTRACKED then
        return
    else
        -- tooltip:AddSeparator()
        -- line = tooltip:AddHeader()
        -- tooltip:SetCell(line, 1, colorText(rareDB[mapid].zonename, colors.lightcyan), nil, "CENTER", 3)
        -- tooltip:AddSeparator(1, colors.grey[1], colors.grey[2], colors.grey[3], 1)
        -- line = tooltip:AddLine()
        -- tooltip:SetCell(line, 1, colorText("No tracking info available.", colors.grey), nil, nil, 3)
    end
end

function WarfrontRareTracker:WarfrontStatusInfoTooltip(inmenu)
    WarfrontStatusInfoTooltipCounter = 0
    if warfrontStatusTooltip and WarfrontRareTracker.db.profile.menu.showWarfrontOnZoneName and WarfrontRareTracker.db.profile.menu.showWarfrontTitle == "current" then
        updateWarfrontStatusInfoTooltip(warfrontStatusTooltip, getPlayerSelectedZone(), inmenu)
    elseif warfrontStatusTooltip and WarfrontRareTracker.db.profile.menu.showWarfrontOnZoneName and WarfrontRareTracker.db.profile.menu.showWarfrontTitle == "all" then
        for mapid, v in pairs(rareDB) do
            updateWarfrontStatusInfoTooltip(warfrontStatusTooltip, mapid, inmenu)
            WarfrontStatusInfoTooltipCounter = WarfrontStatusInfoTooltipCounter + 1
        end
    elseif menuTooltip and WarfrontRareTracker.db.profile.menu.showWarfrontInMenu and WarfrontRareTracker.db.profile.menu.showWarfrontMenu == "current" and inmenu then
        updateWarfrontStatusInfoTooltip(menuTooltip, getPlayerSelectedZone(), inmenu)
        --menuTooltip:AddSeparator()
    elseif menuTooltip and WarfrontRareTracker.db.profile.menu.showWarfrontInMenu and WarfrontRareTracker.db.profile.menu.showWarfrontMenu == "all" and inmenu then
        for mapid, v in pairs(rareDB) do
            updateWarfrontStatusInfoTooltip(menuTooltip, mapid, inmenu)
            WarfrontStatusInfoTooltipCounter = WarfrontStatusInfoTooltipCounter + 1
        end
        --menuTooltip:AddSeparator()
    end
end

-------------------
-- Worldmap Tooltip
function WarfrontRareTracker:WorldmapTooltipOnClick(self, mapid, npcid, button)
    if mapid == nil or npcid == nil then return end
    if button == "LeftButton" then
       if isTomTomloaded and WarfrontRareTracker.db.profile.tomtom.enableIntegration then
            if IsShiftKeyDown() then
                announceRare(mapid, npcid, "group")
            else
                addToTomTom(mapid, npcid)
            end
        end
    elseif button == "RightButton" and IsShiftKeyDown() then
        announceRare(mapid, npcid, "local")
    end
end

function WarfrontRareTracker:WorldmapTooltipOnLeave()
    if worldmapTooltip then
        LibQTip:Release(worldmapTooltip)
        worldmapTooltip = nil
    end
end

local function checkItemNameIsValid(itemname, drop)
    if itemname == nil then
        if drop == nil then
            return colorText("Unknown", colors.orange)
        else
            return colorText(drop, colors.yellow)
        end
    else
        return itemname
    end
end

function WarfrontRareTracker:WorldmapTooltipOnEnter(self, mapid, npcid, cave, minimap)
    if LibQTip:IsAcquired("WarfrontRareTrackerWorldmapTip") and worldmapTooltip then
        LibQTip.Release(worldmapTooltip)
        worldmapTooltip = nil
    end
    worldmapTooltip = LibQTip:Acquire("WarfrontRareTrackerWorldmapTip", 2, "LEFT", "RIGHT")
    worldmapTooltip:ClearAllPoints()
    worldmapTooltip:SetClampedToScreen(true)
    worldmapTooltip:SetPoint("TOPRIGHT", self, "BOTTOM")

    local line
    if cave then
        if rareDB[mapid].rares[npcid].cave.caveNote and type(rareDB[mapid].rares[npcid].cave.caveNote) == "string" then
            worldmapTooltip:AddLine(colorText(rareDB[mapid].rares[npcid].cave.caveNote, colors.orange))
            --worldmapTooltip:Show()
        else
            worldmapTooltip:AddLine(colorText("Cave entrance for: " .. getColoredRareName(mapid, npcid), colors.yellow))
            --worldmapTooltip:Show()
        end
    else
        local itemName, itemLink, itemTexture
        if minimap and WarfrontRareTracker.db.profile.minimapIcons.onMinimapHoover then
            if WarfrontRareTracker.db.profile.minimapIcons.minimapIconsCompactMode then
                line = worldmapTooltip:AddHeader()
                worldmapTooltip:SetCell(line, 1, getColoredRareName(mapid, npcid) .. colorText(": ", colors.yellow) .. getColoredStatusText(mapid, npcid), nil, nil, 2)
                if rareDB[mapid].rares[npcid].covenantBound then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, getRareInfoCovenantText(mapid, npcid), nil, nil, 2)
                    --DebugPrint("WorldmapTooltip: Rare is Covenant bound to: " .. getColoredCovenantText(rareDB[mapid].rares[npcid].covenantBound))
                end

                if rareDB[mapid].rares[npcid].loot == nil then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText("No loot", colors.turqoise), nil, nil, 2)
                end
                if #rareDB[mapid].rares[npcid].loot == 0 then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText("No know drop", colors.lightcyan), nil, nil, 2)
                elseif #rareDB[mapid].rares[npcid].loot == 1 then
                    if rareHasLegitLoot(mapid, npcid) then
                        if rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.GEAR_ONLY then
                            line = worldmapTooltip:AddLine()
                            worldmapTooltip:SetCell(line, 1, colorText(DROPTYPE.GEAR_ONLY, colors.yellow), nil, nil, 2)
                        else
                            itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(rareDB[mapid].rares[npcid].loot[1].itemID)
                            itemName = checkItemNameIsValid(itemName, rareDB[mapid].rares[npcid].loot[1].droptype)
                            line = worldmapTooltip:AddLine()
                            if rareDB[mapid].rares[npcid].loot[1].isKnown then
                                worldmapTooltip:SetCell(line, 1, (itemLink or itemName) .. colorText(": ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].loot[1].droptype .. " already known", colors.red), nil, nil, 2)
                            else
                                worldmapTooltip:SetCell(line, 1, (itemLink or itemName) .. colorText(": ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].loot[1].droptype .. " still needed", colors.green), nil, nil, 2)
                            end
                        end
                    end
                elseif #rareDB[mapid].rares[npcid].loot > 1 then
                    if rareHasLegitLoot(mapid, npcid) then
                        local i
                        for i = 1, #rareDB[mapid].rares[npcid].loot do
                            itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(rareDB[mapid].rares[npcid].loot[i].itemID)
                            itemName = checkItemNameIsValid(itemName, rareDB[mapid].rares[npcid].loot[i].droptype)
                            line = worldmapTooltip:AddLine()
                            line = worldmapTooltip:AddLine()
                            if rareDB[mapid].rares[npcid].loot[i].isKnown then
                                worldmapTooltip:SetCell(line, 1, (itemLink or itemName) .. colorText(": ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].loot[i].droptype .. " already known", colors.red), nil, nil, 2)
                            else
                                worldmapTooltip:SetCell(line, 1, (itemLink or itemName) .. colorText(": ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].loot[i].droptype .. " still needed", colors.green), nil, nil, 2)
                            end
                        end
                    end
                end
            else
                line = worldmapTooltip:AddHeader()
                worldmapTooltip:SetCell(line, 1, getColoredRareName(mapid, npcid), nil, nil, 2)
                if rareDB[mapid].rares[npcid].covenantBound then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, getRareInfoCovenantText(mapid, npcid), nil, nil, 2)
                    --DebugPrint("WorldmapTooltip: Rare is Covenant bound to: " .. getColoredCovenantText(rareDB[mapid].rares[npcid].covenantBound))
                end
                line = worldmapTooltip:AddLine()
                worldmapTooltip:SetCell(line, 1, colorText("Status: ", colors.yellow) .. getColoredStatusText(mapid, npcid), nil, nil, 2)
                if rareDB[mapid].rares[npcid].loot == nil then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText("No loot", colors.turqoise), nil, nil, 2)
                end
                if #rareDB[mapid].rares[npcid].loot == 0 then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText("No know drop", colors.lightcyan), nil, nil, 2)
                elseif #rareDB[mapid].rares[npcid].loot == 1 then
                    if rareHasLegitLoot(mapid, npcid) then
                        if rareDB[mapid].rares[npcid].loot[1].droptype == DROPTYPE.GEAR_ONLY then
                            line = worldmapTooltip:AddLine()
                            worldmapTooltip:SetCell(line, 1, colorText("Drops " .. DROPTYPE.GEAR_ONLY, colors.yellow), nil, nil, 2)
                        else
                            itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(rareDB[mapid].rares[npcid].loot[1].itemID)
                            itemName = checkItemNameIsValid(itemName, rareDB[mapid].rares[npcid].loot[1].droptype)
                            line = worldmapTooltip:AddLine()
                            if rareDB[mapid].rares[npcid].loot[1].isKnown then
                                worldmapTooltip:SetCell(line, 1, colorText("Drops " .. rareDB[mapid].rares[npcid].loot[1].droptype .. ": ", colors.yellow) .. (itemLink or itemName) .. colorText(" already known", colors.red), nil, nil, 2)
                            else
                                worldmapTooltip:SetCell(line, 1, colorText("Drops " .. rareDB[mapid].rares[npcid].loot[1].droptype .. ": ", colors.yellow) .. (itemLink or itemName) .. colorText(" still needed", colors.green), nil, nil, 2)
                            end
                        end
                    end
                elseif #rareDB[mapid].rares[npcid].loot > 1 then
                    if rareHasLegitLoot(mapid, npcid) then
                        local i
                        for i = 1, #rareDB[mapid].rares[npcid].loot do
                            itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(rareDB[mapid].rares[npcid].loot[i].itemID)
                            itemName = checkItemNameIsValid(itemName, rareDB[mapid].rares[npcid].loot[i].droptype)
                            line = worldmapTooltip:AddLine()
                            if rareDB[mapid].rares[npcid].loot[i].isKnown then
                                worldmapTooltip:SetCell(line, 1, colorText("Drops " .. rareDB[mapid].rares[npcid].loot[i].droptype .. ": ", colors.yellow) .. (itemLink or itemName) .. colorText(" already known", colors.red), nil, nil, 2)
                            else
                                worldmapTooltip:SetCell(line, 1, colorText("Drops " .. rareDB[mapid].rares[npcid].loot[i].droptype .. ": ", colors.yellow) .. (itemLink or itemName) .. colorText(" still needed", colors.green), nil, nil, 2)
                            end
                        end
                    end
                end
            end
            
            if rareDB[mapid].rares[npcid].note and not WarfrontRareTracker.db.profile.minimapIcons.minimapIconsCompactMode then
                line = worldmapTooltip:AddLine()
                worldmapTooltip:SetCell(line, 1, colorText("Note: ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].note, colors.orange), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 280)
                if isTomTomloaded and WarfrontRareTracker.db.profile.tomtom.enableIntegration then
                    worldmapTooltip:AddSeparator()
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText("Left-Click to add TomTom Waypoint.", colors.turqoise), "LEFT", 2)
                    if IsInRaid() then
                        line = worldmapTooltip:AddLine()
                        worldmapTooltip:SetCell(line, 1, colorText("Shift Left-Click to announce in Raid Chat.", colors.turqoise), "LEFT", 2)
                    elseif IsInGroup() then
                        line = worldmapTooltip:AddLine()
                        worldmapTooltip:SetCell(line, 1, colorText("Shift Left-Click to announce in Party Chat.", colors.turqoise), "LEFT", 2)
                    end
                end
                line = worldmapTooltip:AddLine()
                worldmapTooltip:SetCell(line, 1, colorText("Shift Right-Click to announce in /1.", colors.turqoise), "LEFT", 2)
            end
        elseif not minimap then
            worldmapTooltip:AddHeader(getColoredRareName(mapid, npcid))
            if rareDB[mapid].rares[npcid].covenantBound then
                line = worldmapTooltip:AddLine()
                worldmapTooltip:SetCell(line, 1, getRareInfoCovenantText(mapid, npcid), nil, nil, 2)
                --DebugPrint("WorldmapTooltip: Rare is Covenant bound to: " .. getColoredCovenantText(rareDB[mapid].rares[npcid].covenantBound))
            end

            line = worldmapTooltip:AddLine()
            worldmapTooltip:SetCell(line, 1, colorText("Status: ", colors.yellow) .. getColoredStatusText(mapid, npcid), nil, nil, 2)
            line = worldmapTooltip:AddLine()
            worldmapTooltip:SetCell(line, 1, " ", nil, nil, 2)

            if rareHasLoot(mapid, npcid) then
                if isLootmenuCropped(mapid, npcid) then
                    local i
                    for i = 1, #rareDB[mapid].rares[npcid].loot do
                        addLootInfoToTooltip(worldmapTooltip, mapid, npcid, i, true)
                        if i < #rareDB[mapid].rares[npcid].loot then
                            worldmapTooltip:AddSeparator()
                        end
                    end
                else
                    if #rareDB[mapid].rares[npcid].loot > 0 then
                        local i
                        for i = 1, #rareDB[mapid].rares[npcid].loot do
                            addLootInfoToTooltip(worldmapTooltip, mapid, npcid, i)
                            if i < #rareDB[mapid].rares[npcid].loot then
                                worldmapTooltip:AddSeparator()
                            end
                        end
                    end
                end
            end

            if rareDB[mapid].rares[npcid].warning then
                if rareDB[mapid].rares[npcid].faction == currentPlayerFaction and rareDB[mapid].warfrontControlledByFaction ~= currentPlayerFaction then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, " ", nil, nil, 2)
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText(rareDB[mapid].rares[npcid].warning, colors.red), nil, nil, 2)
                end
            end
            if not isLootmenuCropped(mapid, npcid) and not WarfrontRareTracker.db.profile.lootwindow.alsohidenotes and rareDB[mapid].rares[npcid].note and WarfrontRareTracker.db.profile.lootwindow.alsohidenotes == false then
                if rareDB[mapid].rares[npcid].warning and rareDB[mapid].rares[npcid].faction == currentPlayerFaction and rareDB[mapid].warfrontControlledByFaction == currentPlayerFaction then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText("Note: ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].note, colors.orange), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 200)
                elseif not rareDB[mapid].rares[npcid].warning then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText("Note: ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].note, colors.orange), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 200)
                end
            end
            if isTomTomloaded and WarfrontRareTracker.db.profile.tomtom.enableIntegration then
                worldmapTooltip:AddSeparator()
                line = worldmapTooltip:AddLine()
                worldmapTooltip:SetCell(line, 1, colorText("Left-Click to add TomTom Waypoint.", colors.turqoise), "LEFT", 2)
                if IsInRaid() then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText("Shift Left-Click to announce in Raid Chat.", colors.turqoise), "LEFT", 2)
                elseif IsInGroup() then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText("Shift Left-Click to announce in Party Chat.", colors.turqoise), "LEFT", 2)
                end
            end
            line = worldmapTooltip:AddLine()
            worldmapTooltip:SetCell(line, 1, colorText("Shift Right-Click to announce in /1.", colors.turqoise), "LEFT", 2)
        else
            if rareDB[mapid].rares[npcid].warning then
                if worldmapTooltip:GetLineCount() > 1 then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, " ", nil, nil, 2)
                end
                line = worldmapTooltip:AddLine()
                worldmapTooltip:SetCell(line, 1, colorText(rareDB[mapid].rares[npcid].warning, colors.red), nil, nil, 2)
            else
                line = worldmapTooltip:AddLine()
                worldmapTooltip:SetCell(line, 1, colorText("No know drop", colors.lightcyan), nil, nil, 2)
            end
        end
    end

    -- check assault = assaultType.unknown
    if rareDB[mapid].zoneType == DB_ZONE_TYPE_ASSAULT and rareDB[mapid].rares[npcid].assault == assaultType.unknown then
        worldmapTooltip:AddSeparator()
        line = worldmapTooltip:AddLine()
        worldmapTooltip:SetCell(line, 1, colorText("Unknown Assaul, please report.", colors.orange), "LEFT", 2)
    end

    if worldmapTooltip:GetLineCount() >= 1 then
        -- if WarfrontRareTracker.db.profile.general.disableBackground == false then
        --     worldmapTooltip:SetBackdrop(tooltipBackDrop)
        --     worldmapTooltip:SetBackdropColor(0, 0, 0, WarfrontRareTracker.db.profile.colors.menuAlpha)
        -- end
        worldmapTooltip:Show()
    end
end

-----------------
-- Worldmap Icons
-----------------
local pinCache = {}
local pinCount = 0

local function getNewPin()
    local pin = next(pinCache)
    if pin then
		pinCache[pin] = nil
		return pin
    end
    pinCount = pinCount + 1
    pin = CreateFrame("Button", WARFRONT_PINNAME..pinCount, Minimap, _G.UIParent, BackdropTemplateMixin and "BackdropTemplate")
    pin:SetFrameLevel(5)
	pin:EnableMouse(true)
	pin:SetWidth(12)
	pin:SetHeight(12)
	pin:SetPoint("CENTER", Minimap, "CENTER")
	local texture = pin:CreateTexture(nil, "OVERLAY")
	pin.texture = texture
	texture:SetAllPoints(pin)
	pin:RegisterForClicks("AnyUp")
	pin:SetMovable(true)
    pin:Hide()
	return pin
end

local function recyclePin(icon)
    icon.npcid = nil
    icon.mapid = nil
	pinCache[icon] = true
end

local function deleteZonePins(mapid)
    for k, v in pairs(rareDB[mapid].worldmapIcons) do
        recyclePin(v)
        rareDB[mapid].worldmapIcons[k] = nil
    end
    HBDPins:RemoveAllWorldMapIcons("WarfrontRareTracker"..rareDB[mapid].zonename)
    for k, v in pairs(rareDB[mapid].minimapIcons) do
        recyclePin(v)
        rareDB[mapid].minimapIcons[k] = nil
    end
    HBDPins:RemoveAllMinimapIcons("WarfrontRareTracker"..rareDB[mapid].zonename)
end

local function deleteAllPins()
    for mapid, content in pairs(rareDB) do
        deleteZonePins(mapid)
    end
end

local function getWorldMapIconForRare(mapid, npcid, caveicon)
    if caveicon ~= nil and caveicon == true then
        if rareDB[mapid].rares[npcid].cave.caveNote and type(rareDB[mapid].rares[npcid].cave.caveNote) == "string" then
            return "Interface\\ICONS\\Ability_Hunter_MarkedForDeath"
        else
            return "Interface\\MINIMAP\\Suramar_Door_Icon"
        end
    end
    if not WarfrontRareTracker.db.profile.worldmapicons.useMasterfilter and WarfrontRareTracker.db.profile.worldmapicons.handleDefeated == "change" and areAllQuestsCompleted(mapid, npcid) then
        return "Interface\\Worldmap\\X_Mark_64Grey"
    elseif WarfrontRareTracker.db.profile.worldmapicons.useMasterfilter and WarfrontRareTracker.db.profile.masterfilter.worldmapHandleDefeated == "change" and areAllQuestsCompleted(mapid, npcid) then
        return "Interface\\Worldmap\\X_Mark_64Grey"
    end

    if rareDB[mapid].rares[npcid].faction == currentPlayerFaction and rareDB[mapid].warfrontControlledByFaction ~= currentPlayerFaction and not rareDB[mapid].rares[npcid].bothphases then
         return "Interface\\Worldmap\\GlowSkull_64Red"
    elseif rareDB[mapid].rares[npcid].type == RARETYPE.WORLDBOSS or rareDB[mapid].rares[npcid].type == RARETYPE.ELITE or rareDB[mapid].rares[npcid].type == RARETYPE.ANCIENT then
        return "Interface\\Worldmap\\GlowSkull_64Purple"
    elseif rareDB[mapid].rares[npcid].type == RARETYPE.GOLIATH then
        return "Interface\\Worldmap\\GlowSkull_64Grey"
    else
        return "Interface\\Worldmap\\GlowSkull_64Blue"
    end
end

local function getWorldMapIconSizeForRare(mapid, npcid, mode)
    if rareDB[mapid].rares[npcid].type == RARETYPE.WORLDBOSS or rareDB[mapid].rares[npcid].type == RARETYPE.ELITE or rareDB[mapid].rares[npcid].type == RARETYPE.ANCIENT then
        if mode == "minimap" then
            return WarfrontRareTracker.db.profile.minimapIcons.minimapIconSize + 3
        else
            return WarfrontRareTracker.db.profile.worldmapicons.worldmapIconSize + 3
        end    
    else
        if mode == "minimap" then
            return WarfrontRareTracker.db.profile.minimapIcons.minimapIconSize
        else
            return WarfrontRareTracker.db.profile.worldmapicons.worldmapIconSize
        end
    end
end

local function getWorldMapIconAlphaForRare(mapid, npcid, mode)
    if mode == "minimap" then
        return WarfrontRareTracker.db.profile.minimapIcons.minimapIconAlpha
    else
        return WarfrontRareTracker.db.profile.worldmapicons.worldmapIconAlpha
    end
end

function WarfrontRareTracker:DeleteAllWorldmapIcons()
    deleteAllPins()
end

function WarfrontRareTracker:CheckAndUpdateZoneWorldMapIcons()
    if not IsPlayerWarfrontLevel() then
        return
    end
    if self.db.profile.worldmapicons.useMasterfilter and self.db.profile.masterfilter.worldmapHandleDefeated == "hide" and rareDB[currentPlayerMapid] or not self.db.profile.worldmapicons.useMasterfilter and self.db.profile.worldmapicons.handleDefeated == "hide" and rareDB[currentPlayerMapid] then
        for k, icon in pairs(rareDB[currentPlayerMapid].worldmapIcons) do
            if areAllQuestsCompleted(currentPlayerMapid, icon.npcid) then
                HBDPins:RemoveWorldMapIcon("WarfrontRareTracker"..rareDB[currentPlayerMapid].zonename, icon)
                recyclePin(icon)
                rareDB[currentPlayerMapid].worldmapIcons[k] = nil
            end
        end
        if self.db.profile.minimapIcons.showMinimapIcons then
            for k, icon in pairs(rareDB[currentPlayerMapid].minimapIcons) do
                if areAllQuestsCompleted(currentPlayerMapid, icon.npcid) then
                    HBDPins:RemoveMinimapIcon("WarfrontRareTracker"..rareDB[currentPlayerMapid].zonename, icon)
                    recyclePin(icon)
                    rareDB[currentPlayerMapid].minimapIcons[k] = nil
                end
            end
        end
    elseif self.db.profile.worldmapicons.useMasterfilter and self.db.profile.masterfilter.worldmapHandleDefeated == "change" and rareDB[currentPlayerMapid] or not self.db.profile.worldmapicons.useMasterfilter and self.db.profile.worldmapicons.handleDefeated == "change" and rareDB[currentPlayerMapid] then
        for k, icon in pairs(rareDB[currentPlayerMapid].worldmapIcons) do
            if areAllQuestsCompleted(currentPlayerMapid, icon.npcid) then
                icon.texture:SetTexture(getWorldMapIconForRare(currentPlayerMapid, icon.npcid, icon.cave))
            end
        end
        if self.db.profile.minimapIcons.showMinimapIcons then
            for k, icon in pairs(rareDB[currentPlayerMapid].minimapIcons) do
                if areAllQuestsCompleted(currentPlayerMapid, icon.npcid) then
                    icon.texture:SetTexture(getWorldMapIconForRare(currentPlayerMapid, icon.npcid, icon.cave))
                end
            end
        end
    end
end

function WarfrontRareTracker:UpdateAllWorldMapIcons()
    deleteAllPins()
    for mapid, content in pairs(rareDB) do
        for k, rare in pairs(content.rares) do
            if showRare(mapid, rare.npcid, "worldmap") then
                WarfrontRareTracker:CreateNewMapIcon(mapid, rare.npcid, false)
                if rare.cave then
                    WarfrontRareTracker:CreateNewMapIcon(mapid, rare.npcid, true)
                end
            end
        end
    end
end

function WarfrontRareTracker:UpdateZoneWorldMapIcons(mapid)
    if mapid == nil then return end
    deleteZonePins(mapid)
    if rareDB[mapid] then
        for k, rare in pairs(rareDB[mapid].rares) do
            if showRare(mapid, rare.npcid, "worldmap") then
                WarfrontRareTracker:CreateNewMapIcon(mapid, rare.npcid, false)
                if rare.cave then
                    WarfrontRareTracker:CreateNewMapIcon(mapid, rare.npcid, true)
                end
            end
        end
    end
end

function WarfrontRareTracker:CreateNewMapIcon(mapid, npcid, caveicon)
    if not hasValidCoord(mapid, npcid) then
        return
    end
    local coord = getCoordsForWarfrontPhase(mapid, npcid, false)
    if caveicon then
        coord = getCoordsForWarfrontPhase(mapid, npcid, true)
    end
    local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000

    if self.db.profile.worldmapicons.showWorldmapIcons then
        local worldmapicon = getNewPin()
        worldmapicon:SetParent(WorldMapFrame)
        worldmapicon:SetHeight(getWorldMapIconSizeForRare(mapid, npcid, "worldmap"))
        worldmapicon:SetWidth(getWorldMapIconSizeForRare(mapid, npcid, "worldmap"))
        worldmapicon:SetAlpha(getWorldMapIconAlphaForRare(mapid, npcid, "worldmap"))
        worldmapicon.texture:SetTexCoord(0, 1, 0, 1)
        worldmapicon.texture:SetVertexColor(1, 1, 1, 1)
        worldmapicon.texture:SetTexture(getWorldMapIconForRare(mapid, npcid, caveicon))
        worldmapicon.npcid = npcid
        worldmapicon.mapid = mapid
        worldmapicon.cave = caveicon
        worldmapicon:SetScript("OnClick", function(self, button) WarfrontRareTracker:WorldmapTooltipOnClick(self, worldmapicon.mapid, worldmapicon.npcid, button) end)
        worldmapicon:SetScript("OnEnter", function(self) WarfrontRareTracker:WorldmapTooltipOnEnter(self, worldmapicon.mapid, worldmapicon.npcid, worldmapicon.cave, false) end)
        worldmapicon:SetScript("OnLeave", function() WarfrontRareTracker:WorldmapTooltipOnLeave() end)
        table.insert(rareDB[mapid].worldmapIcons, worldmapicon)
        HBDPins:AddWorldMapIconMap("WarfrontRareTracker"..rareDB[mapid].zonename, worldmapicon, mapid, x, y, 1)
    end
    if self.db.profile.minimapIcons.showMinimapIcons then
        local minimapIcon = getNewPin()
        minimapIcon:SetParent(Minimap)
        minimapIcon:SetHeight(getWorldMapIconSizeForRare(mapid, npcid, "minimap"))
        minimapIcon:SetWidth(getWorldMapIconSizeForRare(mapid, npcid, "minimap"))
        minimapIcon:SetAlpha(getWorldMapIconAlphaForRare(mapid, npcid, "minimap"))
        minimapIcon.texture:SetTexCoord(0, 1, 0, 1)
        minimapIcon.texture:SetVertexColor(1, 1, 1, 1)
        minimapIcon.texture:SetTexture(getWorldMapIconForRare(mapid, npcid, caveicon))
        minimapIcon.npcid = npcid
        minimapIcon.mapid = mapid
        minimapIcon.cave = caveicon
        if self.db.profile.minimapIcons.onMinimapHoover then
            minimapIcon:SetScript("OnEnter", function(self) WarfrontRareTracker:WorldmapTooltipOnEnter(self, minimapIcon.mapid, minimapIcon.npcid, minimapIcon.cave, true) end)
            minimapIcon:SetScript("OnLeave", function() WarfrontRareTracker:WorldmapTooltipOnLeave() end)
        end
        table.insert(rareDB[mapid].minimapIcons, minimapIcon)
        HBDPins:AddMinimapIconMap("WarfrontRareTracker"..rareDB[mapid].zonename, minimapIcon, mapid, x, y, false, false)
    end
end

----------
-- Sorting
----------
local function compareSortingString(a, b)
    --print("comp :: " .. tostring(a) .. "  " .. tostring(b))
    if WarfrontRareTracker.db.profile.menu.sortAscending == "true" then
        return a:upper() < b:upper()
    else
        return a:upper() > b:upper()
    end
end

local function getAllLootConcatinated(mapid, npcid)
    if rareDB[mapid].rares[npcid].loot == nil then
        return "znil"
    end
    if #rareDB[mapid].rares[npcid].loot == 0 then
        return "zNo loot"
    elseif #rareDB[mapid].rares[npcid].loot == 1 then
        return rareDB[mapid].rares[npcid].loot[1].droptype
    else
        local text = nil
        local i
        for i = 1, #rareDB[mapid].rares[npcid].loot do
            if text == nil then
                text = rareDB[mapid].rares[npcid].loot[i].droptype
            else
                text = text .. ", " .. rareDB[mapid].rares[npcid].loot[i].droptype
            end
        end
        return text
    end
end

local lootTypeIndex={}
local function getLootIndex(name)
    for k,v in pairs(WarfrontRareTracker.db.profile.menu.lootTypeOrder) do
        lootTypeIndex[v]=k
     end
     return lootTypeIndex[name] or 10
end

local function getHighestLootPriority(mapid, npcid)
    if rareDB[mapid].rares[npcid].loot == nil or #rareDB[mapid].rares[npcid].loot == 0 then
        return 100
    end
    if #rareDB[mapid].rares[npcid].loot == 1 then
        return getLootIndex(rareDB[mapid].rares[npcid].loot[1].droptype)
    else
        local prio = 10
        for index, loot in pairs(rareDB[mapid].rares[npcid].loot)do
            if getLootIndex(loot.droptype) < prio then
                prio = getLootIndex(loot.droptype)
            end
        end
        return prio
    end
end

function WarfrontRareTracker:SortRares()
    --print("SortRares() :: " .. tostring("a"))
    for mapid, contents in pairs(rareDB) do
        if sortedRareDB[mapid] == nil then
            sortedRareDB[mapid] = {}
        end

        clearTable(sortedRareDB[mapid])
        local tempTable = {}
        local normalTable = {}
        local worldbossTable = {}

        local i, j, n, w, min = 0, 0, 0, 0, 0
        if WarfrontRareTracker.db.profile.menu.sortRaresOn == "type" then
            if WarfrontRareTracker.db.profile.menu.worldbossOnTop then
                for k, v in pairs(contents.rares) do
                    if type(v) == "table" and v.type then
                        if v.type ~= RARETYPE.WORLDBOSS or v.type ~= RARETYPE.ANCIENT then
                            n = n + 1
                            normalTable[n] = v
                        else
                            w = w + 1
                            worldbossTable[w] = v
                        end
                    end
                end
                for i = 1, w, 1 do
                    min = i
                    for j = i + 1, w, 1 do
                        if compareSortingString(worldbossTable[j].name, worldbossTable[min].name) then min = j end
                    end
                    worldbossTable[i], worldbossTable[min] = worldbossTable[min], worldbossTable[i]
                end
                for i = 1, n, 1 do
                    min = i
                    for j = i + 1, n, 1 do
                        if WarfrontRareTracker.db.profile.menu.groupTypeSortOn == "drop" then
                            if (compareSortingString(normalTable[j].type, normalTable[min].type)) or (normalTable[j].type == normalTable[min].type and compareSortingString(getAllLootConcatinated(mapid, normalTable[j].npcid), getAllLootConcatinated(mapid, normalTable[min].npcid))) or (normalTable[j].type == normalTable[min].type and getAllLootConcatinated(mapid, normalTable[j].npcid) == getAllLootConcatinated(mapid, normalTable[min].npcid) and compareSortingString(normalTable[j].name, normalTable[min].name)) then min = j end
                        else
                            if (compareSortingString(normalTable[j].type, normalTable[min].type)) or (normalTable[j].type == normalTable[min].type and compareSortingString(normalTable[j].name, normalTable[min].name)) then min = j end
                        end
                    end
                    normalTable[i], normalTable[min] = normalTable[min], normalTable[i]
                end
            else
                for k, v in pairs(contents.rares) do
                    if type(v) == "table" and v.type then
                        n = n + 1
                        tempTable[n] = v
                    end
                end
                for i = 1, n, 1 do
                    min = i
                    for j = i + 1, n, 1 do
                        if WarfrontRareTracker.db.profile.menu.groupTypeSortOn == "drop" then
                            if (compareSortingString(tempTable[j].type, tempTable[min].type)) or (tempTable[j].type == tempTable[min].type and compareSortingString(getAllLootConcatinated(mapid, tempTable[j].npcid), getAllLootConcatinated(mapid, tempTable[min].npcid))) or (tempTable[j].type == tempTable[min].type and getAllLootConcatinated(mapid, tempTable[j].npcid) == getAllLootConcatinated(mapid, tempTable[min].npcid) and compareSortingString(tempTable[j].name, tempTable[min].name)) then min = j end
                        else
                            if (compareSortingString(tempTable[j].type, tempTable[min].type)) or (tempTable[j].type == tempTable[min].type and compareSortingString(tempTable[j].name, tempTable[min].name)) then min = j end
                        end
                    end
                    tempTable[i], tempTable[min] = tempTable[min], tempTable[i]
                end
            end
        elseif WarfrontRareTracker.db.profile.menu.sortRaresOn == "drop" then
            if WarfrontRareTracker.db.profile.menu.worldbossOnTop then
                for k, v in pairs(contents.rares) do
                    if type(v) == "table" then
                        if v.type ~= RARETYPE.WORLDBOSS or v.type ~= RARETYPE.ANCIENT then
                            n = n + 1
                            normalTable[n] = v
                        else
                            w = w + 1
                            worldbossTable[w] = v
                        end
                    end
                end
                for i = 1, w, 1 do
                    min = i
                    for j = i + 1, w, 1 do
                        if compareSortingString(worldbossTable[j].name, worldbossTable[min].name) then min = j end
                    end
                    worldbossTable[i], worldbossTable[min] = worldbossTable[min], worldbossTable[i]
                end
                for i = 1, n, 1 do
                    min = i
                    for j = i + 1, n, 1 do
                        if WarfrontRareTracker.db.profile.menu.groupDropSortOn == "type" then
                            if (getHighestLootPriority(mapid, normalTable[j].npcid) < getHighestLootPriority(mapid, normalTable[min].npcid)) or (getHighestLootPriority(mapid, normalTable[j].npcid) == getHighestLootPriority(mapid, normalTable[min].npcid)) and compareSortingString(normalTable[j].type, normalTable[min].type) or (getHighestLootPriority(mapid, normalTable[j].npcid) == getHighestLootPriority(mapid, normalTable[min].npcid)) and (normalTable[j].type == normalTable[min].type) and compareSortingString(normalTable[j].name, normalTable[min].name) then min = j end
                        else
                            if (compareSortingString(getAllLootConcatinated(mapid, normalTable[j].npcid), getAllLootConcatinated(mapid, normalTable[min].npcid))) or (getAllLootConcatinated(mapid, normalTable[j].npcid) == getAllLootConcatinated(mapid, normalTable[min].npcid) and compareSortingString(normalTable[j].name, normalTable[min].name)) then min = j end
                        end
                    end
                    normalTable[i], normalTable[min] = normalTable[min], normalTable[i]
                end
            else
                for k, v in pairs(contents.rares) do
                    if type(v) == "table" then
                        n = n + 1
                        tempTable[n] = v
                    end
                end
                for i = 1, n, 1 do
                    min = i
                    for j = i + 1, n, 1 do
                        if WarfrontRareTracker.db.profile.menu.groupDropSortOn == "type" then
                            if (getHighestLootPriority(mapid, tempTable[j].npcid) < getHighestLootPriority(mapid, tempTable[min].npcid)) or (getHighestLootPriority(mapid, tempTable[j].npcid) == getHighestLootPriority(mapid, tempTable[min].npcid)) and compareSortingString(tempTable[j].type, tempTable[min].type) or (getHighestLootPriority(mapid, tempTable[j].npcid) == getHighestLootPriority(mapid, tempTable[min].npcid)) and (tempTable[j].type == tempTable[min].type) and compareSortingString(tempTable[j].name, tempTable[min].name) then min = j end
                        else
                            if (compareSortingString(getAllLootConcatinated(mapid, tempTable[j].npcid), getAllLootConcatinated(mapid, tempTable[min].npcid))) or (getAllLootConcatinated(mapid, tempTable[j].npcid) == getAllLootConcatinated(mapid, tempTable[min].npcid) and compareSortingString(tempTable[j].name, tempTable[min].name)) then min = j end
                        end
                    end
                    tempTable[i], tempTable[min] = tempTable[min], tempTable[i]
                end
            end
        elseif WarfrontRareTracker.db.profile.menu.sortRaresOn == "name" then
            if WarfrontRareTracker.db.profile.menu.worldbossOnTop then
                for k, v in pairs(contents.rares) do
                    if type(v) == "table" then
                        if v.type ~= RARETYPE.WORLDBOSS or v.type ~= RARETYPE.ANCIENT then
                            n = n + 1
                            normalTable[n] = v
                        else
                            w = w + 1
                            worldbossTable[w] = v
                        end
                    end
                end
                for i = 1, w, 1 do
                    min = i
                    for j = i + 1, w, 1 do
                        if compareSortingString(worldbossTable[j].name, worldbossTable[min].name) then min = j end
                    end
                    worldbossTable[i], worldbossTable[min] = worldbossTable[min], worldbossTable[i]
                end
                for i = 1, n, 1 do
                    min = i
                    for j = i + 1, n, 1 do
                        if compareSortingString(normalTable[j].name, normalTable[min].name) then min = j end
                    end
                    normalTable[i], normalTable[min] = normalTable[min], normalTable[i]
                end
            else
                for k, v in pairs(contents.rares) do
                    if type(v) == "table" and v.name then
                        n = n + 1
                        tempTable[n] = v
                    end
                end
                for i = 1, n, 1 do
                    min = i
                    for j = i + 1, n, 1 do
                        if compareSortingString(tempTable[j].name, tempTable[min].name) then min = j end
                    end
                    tempTable[i], tempTable[min] = tempTable[min], tempTable[i]
                end
            end
        end

        local npcid
        if WarfrontRareTracker.db.profile.menu.worldbossOnTop then
            for i = 1, w, 1 do
                npcid = worldbossTable[i].npcid
                --print("Mapid:"..mapid.." worldbossTable:" .. npcid)
                sortedRareDB[mapid][i] = npcid
            end
            for i = 1 , n, 1 do
                npcid = normalTable[i].npcid
                --print("Mapid:"..mapid.." normalTable:" .. npcid)
                sortedRareDB[mapid][i+w] = npcid
            end
        else
            for i = 1, n do
                npcid = tempTable[i].npcid
                --print("Mapid: "..mapid.." tempTable: " .. npcid)
                sortedRareDB[mapid][i] = npcid
            end
        end
        tempTable = nil
        normalTable = nil
        worldbossTable = nil
    end
end

----------------
-- NPC UnitFrame
----------------
local function onTooltipSetUnit(tooltip, data)
    if tooltip ~= _G.GameTooltip then
		return -- Probably a tooltip created by another addon, that does use the new GameTooltipDataMixin (triggers post-hooks globally...)
	end

    -- Skip if the function is disabled
    if WarfrontRareTracker.db.profile.unitframe.enableUnitframeIntegration == false then
        return
    end

    local self = tooltip -- For backwards compatibility with the legacy code below (should be refactored eventually...)

    if not self.GetUnit then
		return -- Probably a tooltip created by another addon, that hasn't been updated to use GameTooltipDataMixin (risky assumption)
	end

    local name, unit = self:GetUnit()
    if not unit then 
        return
    end
    if UnitCreatureType(unit) == "Critter" or UnitCreatureType(unit) == "Non-combat Pet" or UnitCreatureType(unit) == "Wild Pet" then
        return
    end
    
    local guid = UnitGUID(unit)
    if not unit or not guid then return end
    if not UnitCanAttack("player", unit) then return end -- Something you can't attack
    if UnitIsPlayer(unit) then return end -- A player
    if UnitIsPVP(unit) then return end -- A PVP flagged unit
    if playerIsInInstance then return end
    -- Skip if the if Database doesn't contain current map
    if rareDB[currentPlayerMapid] == nil or playerIsInInstance then
        return
    end
    
    if WarfrontRareTracker.db.profile.worldmapicons.useMasterfilter == true and WarfrontRareTracker.db.profile.masterfilter.worldmapShowOnlyAtPhase == true and rareDB[currentPlayerMapid].hidden == true then
        return
    elseif WarfrontRareTracker.db.profile.worldmapicons.useMasterfilter == false and WarfrontRareTracker.db.profile.worldmapicons.showOnlyAtPhase == true and rareDB[currentPlayerMapid].hidden == true then
        return
    end

    local npcid = getNPCIDFromGUID(guid)
    if rareDB[currentPlayerMapid] and type(rareDB[currentPlayerMapid].rares[npcid]) == "table" then
        local rare = rareDB[currentPlayerMapid].rares[npcid]
        if isNPCPlayerFaction(currentPlayerMapid, npcid) then
            local itemName, itemLink, itemTexture
            if WarfrontRareTracker.db.profile.unitframe.compactMode then
                local text = ""
                if WarfrontRareTracker.db.profile.unitframe.showStatus then
                    text = text .. colorText("Warfront Rare Tracker: ", colors.yellow) .. getColoredStatusText(currentPlayerMapid, npcid) .. "\n"
                else
                    text = text .. colorText("Warfront Rare Tracker: ", colors.yellow) .. "\n"
                end

                if WarfrontRareTracker.db.profile.unitframe.showDrop then
                    if rareDB[currentPlayerMapid].rares[npcid].loot ~= nil then
                        if #rareDB[currentPlayerMapid].rares[npcid].loot == 0 then
                            text = text .. colorText("No know drop", colors.lightcyan)
                        elseif #rareDB[currentPlayerMapid].rares[npcid].loot == 1 then
                            itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(rareDB[currentPlayerMapid].rares[npcid].loot[1].itemID)
                            if itemLink or itemName then
                                if WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and rareDB[currentPlayerMapid].rares[npcid].loot[1].isKnown then
                                    text = text .. (itemLink or itemName) .. colorText(": ", colors.yellow) .. colorText(rareDB[currentPlayerMapid].rares[npcid].loot[1].droptype .. " already known", colors.red)
                                elseif WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and not rareDB[currentPlayerMapid].rares[npcid].loot[1].isKnown then
                                    text = text .. (itemLink or itemName) .. colorText(": ", colors.yellow) .. colorText(rareDB[currentPlayerMapid].rares[npcid].loot[1].droptype .. " still needed", colors.green)
                                else
                                    text = text .. (itemLink or itemName)
                                end
                            end
                        elseif #rareDB[currentPlayerMapid].rares[npcid].loot > 1 then
                            local i
                            for i = 1, #rareDB[currentPlayerMapid].rares[npcid].loot do
                                itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(rareDB[currentPlayerMapid].rares[npcid].loot[i].itemID)
                                if itemLink or itemName then
                                    if i > 1 then
                                        text = text .. "\n"
                                    end
                                    if WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and rareDB[currentPlayerMapid].rares[npcid].loot[i].isKnown then
                                        text = text .. (itemLink or itemName) .. colorText(": ", colors.yellow) .. colorText(rareDB[currentPlayerMapid].rares[npcid].loot[i].droptype .. " already known", colors.red)
                                    elseif WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and not rareDB[currentPlayerMapid].rares[npcid].loot[i].isKnown then
                                        text = text .. (itemLink or itemName) .. colorText(": ", colors.yellow) .. colorText(rareDB[currentPlayerMapid].rares[npcid].loot[i].droptype .. " still needed", colors.green)
                                    else
                                        text = text .. (itemLink or itemName)
                                    end
                                end
                            end
                        end
                    end
                end

                --GameTooltip:AddLine(" ")
                GameTooltip:AddLine(text)
            else
                --GameTooltip:AddLine(" ")
                GameTooltip:AddLine(colorText("Warfront Rare Tracker:", colors.yellow))

                if WarfrontRareTracker.db.profile.unitframe.showStatus then
                    GameTooltip:AddLine(colorText("Status: ", colors.yellow) .. getColoredStatusText(currentPlayerMapid, npcid))
                end

                if WarfrontRareTracker.db.profile.unitframe.showDrop then
                    if rareDB[currentPlayerMapid].rares[npcid].loot ~= nil then
                        if #rareDB[currentPlayerMapid].rares[npcid].loot == 0 then
                            GameTooltip:AddLine(colorText("No know drop", colors.lightcyan))
                        elseif #rareDB[currentPlayerMapid].rares[npcid].loot == 1 then
                            itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(rareDB[currentPlayerMapid].rares[npcid].loot[1].itemID)
                            if itemLink or itemName then
                                GameTooltip:AddLine(colorText("Drops " .. rareDB[currentPlayerMapid].rares[npcid].loot[1].droptype .. ": ", colors.yellow) .. (itemLink or itemName))
                                if WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and rareDB[currentPlayerMapid].rares[npcid].loot[1].isKnown then
                                    GameTooltip:AddLine(colorText(rareDB[currentPlayerMapid].rares[npcid].loot[1].droptype .. " already known", colors.red))
                                elseif WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and not rareDB[currentPlayerMapid].rares[npcid].loot[1].isKnown then
                                    GameTooltip:AddLine(colorText(rareDB[currentPlayerMapid].rares[npcid].loot[1].droptype .. " still needed", colors.green))
                                end
                            end
                        elseif #rareDB[currentPlayerMapid].rares[npcid].loot > 1 then
                            local i
                            for i = 1, #rareDB[currentPlayerMapid].rares[npcid].loot do
                                itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(rareDB[currentPlayerMapid].rares[npcid].loot[i].itemID)
                                if itemLink or itemName then
                                    GameTooltip:AddLine(colorText("Drops " .. rareDB[currentPlayerMapid].rares[npcid].loot[i].droptype .. ": ", colors.yellow) .. (itemLink or itemName))
                                    if WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and rareDB[currentPlayerMapid].rares[npcid].loot[i].isKnown then
                                        GameTooltip:AddLine(colorText(rareDB[currentPlayerMapid].rares[npcid].loot[i].droptype .. " already known", colors.red))
                                    elseif WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and not rareDB[currentPlayerMapid].rares[npcid].loot[i].isKnown then
                                        GameTooltip:AddLine(colorText(rareDB[currentPlayerMapid].rares[npcid].loot[i].droptype .. " still needed", colors.green))
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

end

_G.TooltipDataProcessor.AddTooltipPostCall(_G.Enum.TooltipDataType.Unit, onTooltipSetUnit)
