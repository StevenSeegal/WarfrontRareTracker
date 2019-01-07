WarfrontRareTracker = LibStub("AceAddon-3.0"):NewAddon("WarfrontRareTracker", "AceBucket-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local WarfrontRareTracker = WarfrontRareTracker

local L = LibStub("AceLocale-3.0"):GetLocale("WarfrontRareTracker")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1");
local MinimapIcon = LibStub("LibDBIcon-1.0")

local LibQTip = LibStub("LibQTip-1.0")
local HBD = LibStub("HereBeDragons-2.0")
local HBDPins = LibStub("HereBeDragons-Pins-2.0")


-----------------------------------------------
-- Local references to wow's provided functions
-----------------------------------------------
local floor, mod, format, strsplit, table, tonumber, type, pairs, next = floor, mod, format, strsplit, table, tonumber, type, pairs, next
local UnitName, GetRealmName, IsInInstance, GetItemInfo, GetServerTime, GetUnit, IsQuestFlaggedCompleted, PlayerHasToy, UnitAffectingCombat, UnitCanAttack, UnitCreatureType, UnitFactionGroup, UnitGUID, UnitIsPlayer, UnitIsPVP, UnitLevel = UnitName, GetRealmName, IsInInstance, GetItemInfo, GetServerTime, GetUnit, IsQuestFlaggedCompleted, PlayerHasToy, UnitAffectingCombat, UnitCanAttack, UnitCreatureType, UnitFactionGroup, UnitGUID, UnitIsPlayer, UnitIsPVP, UnitLevel
local C_ContributionCollector, C_Map, C_MountJournal, C_PetJournal, C_Timer, GameTooltip, MouseIsOver = C_ContributionCollector, C_Map, C_MountJournal, C_PetJournal, C_Timer, GameTooltip, MouseIsOver

------------
-- Constants
------------
local PLAYER_MAXLEVEL = 120
local SECONDS_IN_MIN = 60
local SECONDS_IN_HOUR = SECONDS_IN_MIN * 60
local SECONDS_IN_DAY = SECONDS_IN_HOUR * 24
local FACTION_ALLIANCE = "Alliance"
local FACTION_HORDE = "Horde"
local FACTION_ALL = "all"
local SOUND_GOODNEWS = "Interface\\AddOns\\WarfrontRareTracker\\Sounds\\goodnews.ogg"
local SOUND_BADNEWS = "Interface\\AddOns\\WarfrontRareTracker\\Sounds\\badnews.ogg"
local BROKER_ICON_ALLIANCE = "Interface\\Icons\\INV_AllianceWarEffort"
local BROKER_ICON_HORDE = "Interface\\Icons\\INV_HordeWarEffort"
local BROKER_ICON_UNKNOWN = "Interface\\Icons\\ability_ensnare"
local TYPE_GOLIATH = "Goliath"
local TYPE_WORLDBOSS = "WorldBoss"
local TYPE_ELITE = "Elite"
local TYPE_RARE = "Rare"
local DROP_ITEM = "Item"
local DROP_MOUNT = "Mount"
local DROP_PET = "Pet"
local DROP_TOY = "Toy"
local DROP_UNKNOWN = "Unknown"
local WARFRONT_PINNAME = "WarfrontRareTrackerPin"

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
-- Other vars
local isTomTomloaded = false
local autoChangeZone = nil
local autoChangeZoneTimestamp = 0
local manualTimestamp = 0
local playerIsInInstance = false
local currentPlayerMapid = 0
local currentPlayerLevel = 0
local currentPlayerName = ""
local currentPlayerFaction = ""
local currentPlayerRealm = ""

-- Rare Database
local sortedRareDB = {}
local rareDB = { -- New
    [14] = {
        zonename = "Arathi Highlands",
        scenarioname = "Battle for Stromgarde",
        gatheringname = "Contributing",
        zonelevel = 120,
        zoneContributionMapID = 11,
        allianceContributionMapID = 116,
        hordeContributionMapID = 11,
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        rares = {
            [138122] = { name = L["dooms_howl"], npcid = 138122, questId = { 53002 }, type = TYPE_WORLDBOSS, faction = FACTION_ALLIANCE, coord = { 38624096 }, bothphases = false, note = "Alliance only", warning = "Unavailable under Horde Control", loot = { { droptype = DROP_TOY, itemID = 163828, isKnown = false } } },
            [137374] = { name = L["the_lions_roar"], npcid = 137374, questId = { 53001 }, type = TYPE_WORLDBOSS, faction = FACTION_HORDE, coord = { 38624096 }, bothphases = false, note = "Horde only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROP_TOY, itemID = 163829, isKnown = false } } },
            [141618] = { name = L["cresting_goliath"], npcid = 141618, questId = { 53018, 53531 }, type = TYPE_GOLIATH, faction = FACTION_ALL, coord = { 62093158 }, bothphases = true, loot = { { droptype = DROP_ITEM, itemID = 163700, isKnown = false } } },
            [141615] = { name = L["burning_goliath"], npcid = 141615, questId = { 53017, 53506 }, type = TYPE_GOLIATH, faction = FACTION_ALL, coord = { 30664478 }, bothphases = true, loot = { { droptype = DROP_ITEM, itemID = 163691, isKnown = false } } },
            [141620] = { name = L["rumbling_goliath"], npcid = 141620, questId = { 53021, 53523 }, type = TYPE_GOLIATH, faction = FACTION_ALL, coord = { 29885974 }, bothphases = true, loot = { { droptype = DROP_ITEM, itemID = 163701, isKnown = false } } },
            [141616] = { name = L["thundering_goliath"], npcid = 141616, questId = { 53023, 53527 }, type = TYPE_GOLIATH, faction = FACTION_ALL, coord = { 46325212 }, bothphases = true, loot = { { droptype = DROP_ITEM, itemID = 163698, isKnown = false } } },
            [142709] = { name = L["beastrider_kama"], npcid = 142709, questId = { 53083, 53504 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 65347116 }, bothphases = true, loot = { { droptype = DROP_MOUNT, itemID = 163644, mountID = 1180, isKnown = false } } },
            [142692] = { name = L["nimar_the_slayer"], npcid = 142692, questId = { 53091, 53517 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 67616086 }, loot = { { droptype = DROP_MOUNT, itemID = 163706, mountID = 1185, isKnown = false } } },
            [142423] = { name = L["overseer_krix"], npcid = 142423, questId = { 53014, 53518 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 32923847, 27405722 }, cave = { 33693676, 27385601 }, bothphases = true, note = "Inside cave", loot = { { droptype = DROP_MOUNT, itemID = 163646, mountID = 1182, isKnown = false } } },
            [142437] = { name = L["skullripper"], npcid = 142437, questId = { 53022, 53526 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 57154575 }, bothphases = true, loot = { { droptype = DROP_MOUNT, itemID = 163645, mountID = 1183, isKnown = false } } },
            [142739] = { name = L["knight_captain_aldrin"], npcid = 142739, questId = { 53088 }, type = TYPE_RARE, faction = FACTION_HORDE, coord = { 48894001 }, bothphases = false, note = "Horde only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROP_MOUNT, itemID = 163578, mountID = 1173, isKnown = false } } },
            [142741] = { name = L["doomrider_helgrim"], npcid = 142741, questId = { 53085 }, type = TYPE_RARE, faction = FACTION_ALLIANCE, coord = { 53565764 }, bothphases = false, note = "Alliance only", warning = "Unavailable under Horde Control", loot = { { droptype = DROP_MOUNT, itemID = 163579, mountID = 1174, isKnown = false } } },
            [142508] = { name = L["branchlord_aldrus"], npcid = 142508, questId = { 53013, 53505 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 22602135 }, bothphases = true, loot = { { droptype = DROP_PET, itemID = 163650, petID = 143503, speciesID = 2433, isKnown = false } } },
            [142688] = { name = L["darbel_montrose"], npcid = 142688, questId = { 53084, 53507 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 50673675, 50756121 }, bothphases = true, loot = { { droptype = DROP_PET, itemID = 163652, petID = 143507, speciesID = 2434, isKnown = false } } },
            [141668] = { name = L["echo_of_myzrael"], npcid = 141668, questId = { 53059, 53508 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 57073506 }, note = "Spawns after defeating all 4 Goliaths.\nAfter defeating the Goliaths there will be\na broadcast when she spawns.", loot = { { droptype = DROP_PET, itemID = 163677, petID = 143515, speciesID = 2435, isKnown = false } } },
            [142433] = { name = L["fozruk"], npcid = 142433, questId = { 53019, 53510 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 59422773 }, bothphases = true, loot = { { droptype = DROP_PET, itemID = 163711, petID = 143627, speciesID = 2440, isKnown = false } } },
            [142716] = { name = L["man_hunter_rog"], npcid = 142716, questId = { 53090, 53515 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 52277674 }, bothphases = true, loot = { { droptype = DROP_PET, itemID = 163712, petID = 143628, speciesID = 2441, isKnown = false } } },
            [142435] = { name = L["plaguefeather"], npcid = 142435, questId = { 53020, 53519 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 35606435 }, bothphases = true, loot = { { droptype = DROP_PET, itemID = 163690, petID = 143564, speciesID = 2438, isKnown = false } } },
            [142436] = { name = L["ragebeak"], npcid = 142436, questId = { 53016, 53522 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 18412794, 11905220 }, bothphases = true, loot = { { droptype = DROP_PET, itemID = 163689, petID = 143563, speciesID = 2437, isKnown = false } } },
            [142438] = { name = L["venomarus"], npcid = 142438, questId = { 53024, 53528 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 56945330 }, bothphases = true, loot = { { droptype = DROP_PET, itemID = 163648, petID = 143499, speciesID = 2432, isKnown = false } } },
            [142440] = { name = L["yogursa"], npcid = 142440, questId = { 53015, 53529 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 13063622 }, bothphases = true, loot = { { droptype = DROP_PET, itemID = 163684, petID = 143533, speciesID = 2436, isKnown = false } } },
            [142686] = { name = L["foulbelly"], npcid = 142686, questId = { 53086, 53509 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 22305106 }, cave = { 28804557 }, bothphases = true, note = "Inside cave", loot = { { droptype = DROP_TOY, itemID = 163735, isKnown = false } } },
            [142662] = { name = L["geomancer_flintdagger"], npcid = 142662, questId = { 53060, 53511 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 79452939 }, cave = { 78143689 }, bothphases = true, note = "Inside cave", loot = { { droptype = DROP_TOY, itemID = 163713, isKnown = false } } },
            [142725] = { name = L["horrific_apparition"], npcid = 142725, questId = { 53087, 53512 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 26723278, 19446123 }, bothphases = true, loot = { { droptype = DROP_TOY, itemID = 163736, isKnown = false } } },
            [142112] = { name = L["korgresh_coldrage"], npcid = 142112, questId = { 53058, 53513 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 49178409 }, cave = { 48007941 }, bothphases = true, note = "Inside cave", loot = { { droptype = DROP_TOY, itemID = 163744, isKnown = false } } },
            [142684] = { name = L["kovork"], npcid = 142684, questId = { 53089, 53514 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 25404872 }, cave = { 28804557 }, bothphases = true, note = "Inside cave", loot = { { droptype = DROP_TOY, itemID = 163750, isKnown = false } } },
            [141942] = { name = L["molok_the_crusher"], npcid = 141942, questId = { 53057, 53516 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 47657800 }, bothphases = true, loot = { { droptype = DROP_TOY, itemID = 163775, isKnown = false } } },
            [142683] = { name = L["ruul_onestone"], npcid = 142683, questId = { 53092, 53524 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 42905660 }, bothphases = true, loot = { { droptype = DROP_TOY, itemID = 163741, isKnown = false } } },
            [142690] = { name = L["singer"], npcid = 142690, questId = { 53093, 53525 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 51213999, 50595746 }, bothphases = true, loot = { { droptype = DROP_TOY, itemID = 163738, isKnown = false } } },
            [142682] = { name = L["zalas_witherbark"], npcid = 142682, questId = { 53094, 53530 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 62868112 }, bothphases = true, cave = { 63277708 }, note = "Inside cave", loot = { { droptype = DROP_TOY, itemID = 163745, isKnown = false } } },
        },
    },
    [62] = {
        zonename = "Darkshore",
        scenarioname = "Battle for Darkshore",
        gatheringname = "Contributing", -- Change
        zonelevel = 120,
        zoneContributionMapID = 118,
        allianceContributionMapID = 117,
        hordeContributionMapID = 118,
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        minimapIcons = {},
        rares = {
            -- Worldbosses
            [148295] = { name = L["ivus_the_decayed"], npcid = 148295, questId = { 54895 }, type = TYPE_WORLDBOSS, faction = FACTION_ALLIANCE, coord = { 41253597 }, bothphases = false, note = "Alliance Only", warning = "Unavailable under Horde Control", loot = {  } },
            [144946] = { name = L["ivus_the_forest_lord"], npcid = 144946, questId = { 54896 }, type = TYPE_WORLDBOSS, faction = FACTION_HORDE, coord = { 41253597 }, bothphases = false, note = "Horde Only", warning = "Unavailable under Alliance Control", loot = {  } },
            -- Mounts
            [148787] = { name = L["alash_anir"], npcid = 148787, questId = { 54695, 54696 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 56473076 }, bothphases = true, loot = { { droptype = DROP_MOUNT, itemID = 166432, mountID = 1200, isKnown = false } } }, -- Mount: Ashenvale Chimaera
            [148790] = { name = L["frightened_kodo"], npcid = 148790, questId = { -1 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 41316547 }, bothphases = true, note = "Friendly Rare. Click it to receive the mount. Only 1 person can click him at a time.", loot = { { droptype = DROP_MOUNT, itemID = 166433, mountID = 1201, isKnown = false } } }, -- Mount: Frightened Kodo
            [149652] = { name = L["agathe_wyrmwood"], npcid = 149652, questId = { 54883 }, type = TYPE_RARE, faction = FACTION_ALLIANCE, coord = { 49522495 }, bothphases = false, note = "Alliance Only", warning = "Unavailable under Horde Control", loot = { { droptype = DROP_MOUNT, itemID = 166438, mountID = 1199, isKnown = false } } }, -- Mount: Blackpaw (Caged Bear)
            [149655] = { name = L["croz_bloodrage"], npcid = 149655, questId = { 54886 }, type = TYPE_RARE, faction = FACTION_ALLIANCE, coord = { 50633241 }, bothphases = false, note = "Alliance Only", warning = "Unavailable under Horde Control", loot = { { droptype = DROP_MOUNT, itemID = 166437, mountID = 1205, isKnown = false } } }, -- Mount: Kaldorei Nightsaber (Captured Kaldorei Nightsaber)
            [147701] = { name = L["moxo_the_beheader"], npcid = 147701, questId = { 54277 }, type = TYPE_RARE, faction = FACTION_ALLIANCE, coord = { 66981881 }, bothphases = true, note = "Alliance Only", loot = { { droptype = DROP_MOUNT, itemID = 166434, mountID = 1203, isKnown = false } } }, -- Mount: Umber Nightsaber (Captured Umber Nightsaber)
            [149660] = { name = L["blackpaw"], npcid = 149660, questId = { 54890 }, type = TYPE_RARE, faction = FACTION_HORDE, coord = { 49522495 }, bothphases = false, note = "Horde Only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROP_MOUNT, itemID = 166438, mountID = 1199, isKnown = false } } }, -- Mount: Blackpaw (Caged Bear)
            [149663] = { name = L["shadowclaw"], npcid = 149663, questId = { 54892 }, type = TYPE_RARE, faction = FACTION_HORDE, coord = { 39693341 }, bothphases = false, note = "Horde Only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROP_MOUNT, itemID = 166437, mountID = 1205, isKnown = false } } }, -- Mount: Kaldorei Nightsaber (Captured Kaldorei Nightsaber)
            [148037] = { name = L["athil_dewfire"], npcid = 148037, questId = { 54431 }, type = TYPE_RARE, faction = FACTION_HORDE, coord = { 41657594 }, bothphases = false, note = "Horde Only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROP_MOUNT, itemID = 166434, mountID = 1203, isKnown = false }, { droptype = DROP_PET, itemID = 166449, petID = 148781, speciesID = 2544, isKnown = false } } }, -- Mount: Umber Nightsaber, Pet: Darkshore Sentinel
            -- Pets
            [147260] = { name = L["conflagros"], npcid = 147260, questId = { 54232, 54233 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 39206200 }, bothphases = true, loot = { { droptype = DROP_PET, itemID = 166451, petID = 148825, speciesID = 2546, isKnown = false } } }, -- Detective Ray
            [147241] = { name = L["cyclarus"], npcid = 147241, questId = { 54229, 54230 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 43705350 }, bothphases = true, loot = { { droptype = DROP_PET, itemID = 166448, petID = 148784, speciesID = 2545, isKnown = false } } }, -- Gust of Cyclarus
            [147240] = { name = L["hydrath"], npcid = 147240, questId = { 54227, 54228 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 52403210 }, bothphases = true, loot = { { droptype = DROP_PET, itemID = 166452, petID = 148841, speciesID = 2547, isKnown = false } } }, -- Hydrath Droplet
            [147897] = { name = L["soggoth_the_slitherer"], npcid = 147897, questId = { 54320, 54321 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 40508510 }, bothphases = true, loot = { { droptype = DROP_PET, itemID = 166454, petID = 148844, speciesID = 2549, isKnown = false } } }, -- Void Jelly
            [147942] = { name = L["twilight_prophet_graeme"], npcid = 147942, questId = { 54397, 54398 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 40608260 }, bothphases = true, loot = { { droptype = DROP_PET, itemID = 166455, petID = 148846, speciesID = 2550, isKnown = false } } }, -- Zur'aj the Depleted
            [147664] = { name = L["zim_kaga"], npcid = 147664, questId = { 54274 }, type = TYPE_ELITE, faction = FACTION_ALLIANCE, coord = { 62300980 }, bothphases = true, note = "Alliance Only", loot = { { droptype = DROP_PET, itemID = 166453, petID = 148843, speciesID = 2548, isKnown = false } } }, -- Everburning Treant
            [149659] = { name = L["orwell_stevenson"], npcid = 149659, questId = { 54889 }, type = TYPE_RARE, faction = FACTION_ALLIANCE, coord = { 39673329 }, bothphases = false, note = "Alliance Only", warning = "Unavailable under Horde Control", loot = { { droptype = DROP_PET, itemID = 166528, petID = 149205, speciesID = 2563, isKnown = false } } }, -- Nightwreathed Watcher
            [147758] = { name = L["onu"], npcid = 147758, questId = { 54291 }, type = TYPE_ELITE, faction = FACTION_HORDE, coord = { 45207490 }, bothphases = true, note = "Horde Only", loot = { { droptype = DROP_PET, itemID = 166453, petID = 148843, speciesID = 2548, isKnown = false } } }, -- Everburning Treant
            [149662] = { name = L["grimhorn"], npcid = 149662, questId = { 54891 }, type = TYPE_RARE, faction = FACTION_HORDE, coord = { 50603240 }, bothphases = false, note = "Horde Only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROP_PET, itemID = 166528, petID = 149205, speciesID = 2563, isKnown = false } } },-- Nightwreathed Watcher
            -- Toys
            [148031] = { name = L["gren_tornfur"], npcid = 148031, questId = { 54428, 54429 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 40905640 }, bothphases = true, loot = { { droptype = DROP_TOY, itemID = 166785, isKnown = false } } },
            [147708] = { name = L["athrikus_narassin"], npcid = 147708, questId = { 54278, 54279 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 58402430 }, bothphases = true, loot = { { droptype = DROP_TOY, itemID = 166784, isKnown = false } } },
            [148025] = { name = L["commander_ral_esh"], npcid = 148025, questId = { 54426, 54427 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 37907620 }, bothphases = true, loot = { { droptype = DROP_TOY, itemID = 166787, isKnown = false } } },
            [147845] = { name = L["commander_drald"], npcid = 147845, questId = { 54309 }, type = TYPE_RARE, faction = FACTION_ALLIANCE, coord = { 46408590 }, bothphases = true, note = "Alliance Only", loot = { { droptype = DROP_TOY, itemID = 166790, isKnown = false } } }, -- Highborne Memento
            [149141] = { name = L["burninator_mark_v"], npcid = 149141, questId = { 54768 }, type = TYPE_RARE, faction = FACTION_ALLIANCE, coord = { 41507640 }, bothphases = false, note = "Alliance Only", warning = "Unavailable under Horde Control", loot = { { droptype = DROP_TOY, itemID = 166788, isKnown = false }, { droptype = DROP_PET, itemID = 166449, petID = 148781, speciesID = 2544, isKnown = false } } }, -- Toy: Widdle Twirler: Shredder Blade, Pet: Darkshore Sentinel
            [147435] = { name = L["thelar_moonstrike"], npcid = 147435, questId = { 54252 }, type = TYPE_RARE, faction = FACTION_HORDE, coord = { 62101650 }, bothphases = true, note = "Horde Only", loot = { { droptype = DROP_TOY, itemID = 166790, isKnown = false } } }, -- Highborne Memento
            [148103] = { name = L["sapper_odette"], npcid = 148103, questId = { 54452 }, type = TYPE_RARE, faction = FACTION_HORDE, coord = { 33008380 }, bothphases = false, note = "Horde Only", warning = "Unavailable under Alliance Control", loot = { { droptype = DROP_TOY, itemID = 166788, isKnown = false } } }, -- widdle Twirler: Shredder Blade
            -- Unknown
            [147966] = { name = L["aman"], npcid = 147966, questId = { 54405, 54406 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 37808470 }, bothphases = true, loot = {  } },
            [147970] = { name = L["mrggr_marr"], npcid = 147970, questId = { 54408, 54409 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 35808180 }, loot = {  } },
            [147332] = { name = L["stonebinder_ssra_vess"], npcid = 147332, questId = { 54247, 54248 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 45505900 }, bothphases = true, loot = {  } },
            [147261] = { name = L["granokk"], npcid = 147261, questId = { 54234, 54235 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 47995575 }, bothphases = true, cave = { 47125599 }, note = "Inside cave", loot = {  } },
            [149657] = { name = L["madfeather"], npcid = 149657, questId = { 54887, 54888 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 44004820 }, bothphases = true, loot = {  } },
            [149665] = { name = L["scalefiend"], npcid = 149665, questId = { 54893, 54894 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 47604450 }, bothphases = true, loot = {  } },
            [147751] = { name = L["shattershard"], npcid = 147751, questId = { 54289, 54290 }, type = TYPE_ELITE, faction = FACTION_ALL, coord = { 43402930 }, bothphases = true, loot = {  } },
            [149654] = { name = L["glimmerspine"], npcid = 149654, questId = { 54884, 54885 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 43401960 }, bothphases = true, loot = {  } },
            [147744] = { name = L["amberclaw"], npcid = 147744, questId = { 54285, 54286 }, type = TYPE_RARE, faction = FACTION_ALL, coord = { 57301560 }, bothphases = true, loot = {  } },
        },
    },
}

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
            showAtMaxLevel = false,
            showWarfrontOnZoneName = true,
            showWarfrontTitle = "all",
            showWarfrontInMenu = true,
            showWarfrontMenu = "current",
            autoChangeZone = true,
            autoSaveZone = false,
            whitelist = { [DROP_MOUNT] = false, [DROP_PET] = false, [DROP_TOY] = false},
            sortRaresOn = "drop",
            groupDropSortOn = "type",
            groupTypeSortOn = "drop",
            sortAscending = "true",
            worldbossOnTop = true,
        },
        masterfilter = {
            showOnlyAtMaxLevel = true,
            hideAlreadyKnown = false,
            hideUnknowLoot = false,
            hideUntrackable = false,
            hideGoliaths = false,
            hideUnavailable = false,
            whitelist = { [DROP_MOUNT] = false, [DROP_PET] = false, [DROP_TOY] = false },
            worldmapShowOnlyAtMaxLevel = false,
            worldmapHandleDefeated = "change",
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
            goliath = { 1, 1, 1, 1 },
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
            showOnlyAtMaxLevel = true,
            onMinimapHoover = true,
            minimapIconsCompactMode = true,
            minimapIconSize = 13,
            minimapIconAlpha = 1,
        },
        worldmapicons = {
            handleDefeated = "change",
            showWorldmapIcons = true,
            showOnlyAtMaxLevel = true,
            clickToTomTom = true,
            worldmapIconSize = 13,
            worldmapIconAlpha = 1,
            useMasterfilter = true,
            hideAlreadyKnown = false,
            hideUnknowLoot = false,
            hideUntrackable = false,
            hideUnavailable = false,
            hideGoliaths = false,
            whitelist = { [DROP_MOUNT] = false, [DROP_PET] = false, [DROP_TOY] = false },
        },
        tomtom = {
            enableIntegration = true,
            enableChatMessage = true,
        },
        general = {
            enableZoneChangeSound = true,
            enableLevelUpSound = true,
            enableLevelUpChatMessage = true,
        },
    },
    char = {
        selectedZone = 14,
        debug= 0,
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
    return rareDB[mapid].rares[npcid].faction == currentPlayerFaction or rareDB[mapid].rares[npcid].faction == FACTION_ALL
end

local function isPlayerMaxLevel()
    if currentPlayerLevel >= PLAYER_MAXLEVEL then
        return true
    else
        return false
    end
end

local function isPlayerInWarfront()
    if rareDB[currentPlayerMapid] ~= nil then
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
        return rareDB[mapid].rares[npcid].faction == rareDB[mapid].warfrontControlledByFaction or rareDB[mapid].rares[npcid].faction == FACTION_ALL
    end
end

local function isQuestCompleted(mapid, npcid)
    if rareDB[mapid].rares[npcid].questId[1] <= 0 then
        return false
    else
        for k, v in pairs(rareDB[mapid].rares[npcid].questId) do
            if IsQuestFlaggedCompleted(rareDB[mapid].rares[npcid].questId[k]) then
                return true
            end
        end
    end
    return false
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

local function colorText(text, color)
    if text and color then
        return format("|cff%02x%02x%02x%s|r", (color[1] or 1) * 255, (color[2] or 1) * 255, (color[3] or 1) * 255, text)
    else
        return text
    end
end

local function getColoredRareName(mapid, npcid)
    local rare = rareDB[mapid].rares[npcid]
    if WarfrontRareTracker.db.profile.colors.colorizeRares then
        if rare.type == TYPE_WORLDBOSS then
            return colorText(rare.name, WarfrontRareTracker.db.profile.colors.worldboss)
        elseif rare.type == TYPE_ELITE then
            return colorText(rare.name, WarfrontRareTracker.db.profile.colors.elite)
        elseif rare.type == TYPE_RARE then
            return colorText(rare.name, WarfrontRareTracker.db.profile.colors.rare)
        elseif rare.type == TYPE_GOLIATH then
            return colorText(rare.name, WarfrontRareTracker.db.profile.colors.goliath)
        else
            return colorText(rare.name, colors.white)
        end
    else
        return colorText(rare.name, colors.white)
    end
end

local function getColoredStatusText(mapid, npcid)
    if not isPlayerMaxLevel() then
        return colorText("Level "..rareDB[mapid].zonelevel, colors.orange)
    end
    local rare = rareDB[mapid].rares[npcid]
    if rare.questId[1] == -1 then
        return colorText("Untrackable", colors.yellow)
    elseif rare.questId[1] == 0 then
        return colorText("Unknown", colors.yellow)
    else
        if isQuestCompleted(mapid, npcid) then
            return colorText("Defeated", WarfrontRareTracker.db.profile.colors.colorizeStatus and WarfrontRareTracker.db.profile.colors.defeated or colors.red)
        end
    end
    if isNPCPlayerFaction(mapid, npcid) and isNPCUpForPlayerFaction(mapid, npcid) then
        return colorText("Available", WarfrontRareTracker.db.profile.colors.colorizeStatus and WarfrontRareTracker.db.profile.colors.available or colors.green)
    else
        return colorText("Unavailable", colors.yellow)
    end
end

local function getColoredDropText(mapid, npcid)
    if rareDB[mapid].rares[npcid].loot == nil then
        return "nil"
    end
    if #rareDB[mapid].rares[npcid].loot == 0 then
        return DROP_UNKNOWN
    elseif #rareDB[mapid].rares[npcid].loot == 1 then
        if WarfrontRareTracker.db.profile.colors.colorizeDrops and rareDB[mapid].rares[npcid].loot[1].isKnown then
            return colorText(rareDB[mapid].rares[npcid].loot[1].droptype, WarfrontRareTracker.db.profile.colors.knownColor)
        elseif WarfrontRareTracker.db.profile.colors.colorizeDrops and not rareDB[mapid].rares[npcid].loot[1].isKnown then
            return colorText(rareDB[mapid].rares[npcid].loot[1].droptype, WarfrontRareTracker.db.profile.colors.unknownColor)
        else
            return rareDB[mapid].rares[npcid].loot[1].droptype
        end
    else
        local text = ""
        local i
        for i = 1, #rareDB[mapid].rares[npcid].loot do
            if string.len(text) > 1 then
                text = text .. colorText(", ", colors.yellow)
            end
            if WarfrontRareTracker.db.profile.colors.colorizeDrops and rareDB[mapid].rares[npcid].loot[i].isKnown then
                text = text ..  colorText(rareDB[mapid].rares[npcid].loot[i].droptype, WarfrontRareTracker.db.profile.colors.knownColor)
            elseif WarfrontRareTracker.db.profile.colors.colorizeDrops and not rareDB[mapid].rares[npcid].loot[i].isKnown then
                text = text ..  colorText(rareDB[mapid].rares[npcid].loot[i].droptype, WarfrontRareTracker.db.profile.colors.unknownColor)
            else
                text = text ..  rareDB[mapid].rares[npcid].loot[i].droptype
            end
        end
        return text
    end
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

local function hasDBContributionInfo(mapid)
    if mapid == nil then
        mapid = getPlayerSelectedZone()
    end
    if rareDB[mapid].zoneContributionMapID ~= nil and rareDB[mapid].allianceContributionMapID ~= nil and rareDB[mapid].hordeContributionMapID ~= nil then
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
    if hasDBContributionInfo(mapid) then
        local contributionMapID = rareDB[mapid].zoneContributionMapID
        if contributionMapID == nil then
            return nil, nil
        end
        local zoneState, zonePercentage, zoneTimeNextChange, zoneTimeStarted = C_ContributionCollector.GetState(contributionMapID)
        state = zoneState
        if zoneState == 1 or zoneState == 2 then -- Arathi is under Alliance control
            factionControlling = FACTION_ALLIANCE
        end
        if zoneState == 3 or zoneState == 4 then -- Arathi is under Horde control
            factionControlling = FACTION_HORDE
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
    local state, factionControlling = getWarfrontZoneInfo(mapid)
    local zoneId
    if state == 1 or state == 2 then -- Horde has control   
        zoneId = rareDB[mapid].hordeContributionMapID
    else
        zoneId = rareDB[mapid].allianceContributionMapID
    end
    local zoneState, zonePercentage, zoneTimeNextChange, zoneTimeStarted = C_ContributionCollector.GetState(zoneId)
    return zoneState, zonePercentage, zoneTimeNextChange
end

local function checkFactionWarfrontControl(mapid)
    if mapid == nil then
        mapid = getPlayerSelectedZone()
    end

    if hasDBContributionInfo(mapid) then
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

            local prefix = factionControlling == currentPlayerFaction and "Good" or "Bad"
            local faction = rareDB[mapid].warfrontControlledByFaction == FACTION_HORDE and colorText(FACTION_HORDE, colors.red) or colorText(FACTION_ALLIANCE, colors.blue)
            WarfrontRareTracker:Print(colorText(format("%s news eveyone. The ", prefix), colors.turqoise) .. faction .. colorText(" has gained control over ", colors.turqoise) .. colorText(rareDB[mapid].zonename, colors.lightcyan) .. colorText("!", colors.turqoise))
            if WarfrontRareTracker.db.profile.general.enableZoneChangeSound then
                playSound(prefix)
            end
        end
        rareDB[mapid].warfrontControlledByFaction = factionControlling
    end
end

local checkWarfrontControlDone = fasle
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

local function rareHasLoot(mapid, npcid) -- New
    if rareDB[mapid].rares[npcid].loot == nil then
        return false
    end
    return #rareDB[mapid].rares[npcid].loot > 0
end

local function rareHasAllLoot(mapid, npcid) -- New
    local i
    for i = 1, #rareDB[mapid].rares[npcid].loot do
        if not rareDB[mapid].rares[npcid].loot[i].isKnown then
            return false
        end
    end
    return true
end

local function rareHasLootType(mapid, npcid, whitelist) -- New
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

local function rareHasLegitLoot(mapid, npcid)
    if rareDB[mapid].rares[npcid].type == TYPE_GOLIATH then
        return false
    end
    if rareDB[mapid].rares[npcid].loot == nil then
        return false
    end
    if #rareDB[mapid].rares[npcid].loot == 0 then
        return false
    elseif #rareDB[mapid].rares[npcid].loot == 1 then
        return rareDB[mapid].rares[npcid].loot[1].droptype ~= DROP_UNKNOWN
    else
        local i
        for i = 1, #rareDB[mapid].rares[npcid].loot do
            if rareDB[mapid].rares[npcid].loot[i].droptype == DROP_UNKNOWN then
                return false
            end
        end
    end
    return true
end

local function rareHasLegitQuests(mapid, npcid) -- New
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
        if rareDB[mapid].rares[npcid].type == TYPE_WORLDBOSS then
            return true
        else
            return false
        end
    end
end

local function showRare(mapid, npcid, mode) -- Rewritten
    if isNPCPlayerFaction(mapid, npcid) then
        if mode == "worldmap" and not WarfrontRareTracker.db.profile.worldmapicons.useMasterfilter then
            if WarfrontRareTracker.db.profile.worldmapicons.showOnlyAtMaxLevel and not isPlayerMaxLevel() then
                return false
            end
            if WarfrontRareTracker.db.profile.worldmapicons.hideGoliaths and rareDB[mapid].rares[npcid].type == TYPE_GOLIATH then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideUnknowLoot and not rareHasLoot(mapid, npcid) then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideUnknowLoot and not rareHasLegitQuests(mapid, npcid) then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.handleDefeated == "hide" and isQuestCompleted(mapid, npcid) then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideUnavailable and rareDB[mapid].rares[npcid].bothphases == false and rareDB[mapid].warfrontControlledByFaction ~= currentPlayerFaction then
                return false 
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideUntrackable and rareHasLoot(mapid, npcid) and rareDB[mapid].rares[npcid].questId[1] == -1 then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideAlreadyKnown and rareHasLoot(mapid, npcid) and rareHasAllLoot(mapid, npcid) then
                return rareHasLootType(mapid, npcid, WarfrontRareTracker.db.profile.worldmapicons.whitelist)
            else
                return true
            end
        elseif mode == "menu" and not WarfrontRareTracker.db.profile.menu.useMasterfilter then
            if WarfrontRareTracker.db.profile.menu.hideGoliaths and rareDB[mapid].rares[npcid].type == TYPE_GOLIATH then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideUnknowLoot and not rareHasLoot(mapid, npcid) then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideUnknowLoot and not rareHasLegitQuests(mapid, npcid) then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideUnavailable and rareDB[mapid].rares[npcid].bothphases == false and rareDB[mapid].warfrontControlledByFaction ~= currentPlayerFaction then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideUntrackable and rareHasLoot(mapid, npcid) and rareDB[mapid].rares[npcid].questId[1] == -1 then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideAlreadyKnown and rareHasLoot(mapid, npcid) and rareHasAllLoot(mapid, npcid) then
                return rareHasLootType(mapid, npcid, WarfrontRareTracker.db.profile.menu.whitelist)
            else
                return true
            end
        else
            if mode == "worldmap" then
                if WarfrontRareTracker.db.profile.masterfilter.worldmapShowOnlyAtMaxLevel and not isPlayerMaxLevel() then
                    return false
                elseif WarfrontRareTracker.db.profile.masterfilter.worldmapHandleDefeated == "hide" and isQuestCompleted(mapid, npcid) then
                    return false
                end
            end
            if WarfrontRareTracker.db.profile.masterfilter.hideGoliaths and rareDB[mapid].rares[npcid].type == TYPE_GOLIATH then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideUnknowLoot and not rareHasLoot(mapid, npcid) then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideUnknowLoot and not rareHasLegitQuests(mapid, npcid) then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideUnavailable and rareDB[mapid].rares[npcid].bothphases == false and rareDB[mapid].warfrontControlledByFaction ~= currentPlayerFaction then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideUntrackable and rareHasLoot(mapid, npcid) and rareDB[mapid].rares[npcid].questId[1] == -1 then
                return false
            elseif WarfrontRareTracker.db.profile.masterfilter.hideAlreadyKnown and rareHasLoot(mapid, npcid) and rareHasAllLoot(mapid, npcid) then
                return rareHasLootType(mapid, npcid, WarfrontRareTracker.db.profile.masterfilter.whitelist)
            else
                return true
            end
        end
    else
        return false
    end
end

local function scanForKnownItems() -- Rewritten
    if newPetAdedTimer then
        WarfrontRareTracker:CancelTimer(newPetAdedTimer)
        newPetAdedTimer = nil
    end
    for mapid, content in pairs(rareDB) do
        for k, rare in pairs(content.rares) do
            --isNPCPlayerFaction(mapid, npcid)?
            if #rare.loot > 0 then
                local i
                for i = 1, #rare.loot do
                    if rare.loot[i].droptype == DROP_MOUNT then
                        local name, spellId, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(rare.loot[i].mountID)
                        if isCollected then
                            rare.loot[i].isKnown = true
                        end
                    elseif rare.loot[i].droptype == DROP_TOY then
                        if PlayerHasToy(rare.loot[i].itemID) then
                            rare.loot[i].isKnown = true
                        end
                    elseif rare.loot[i].droptype == DROP_PET then
                        local number, _ = C_PetJournal.GetNumCollectedInfo(rare.loot[i].speciesID);
                        if number >= 1 then
                            rare.loot[i].isKnown = true
                        end
                    end
                end
            end
        end
    end
end

local function setBrokerIcon(faction)
    if faction == FACTION_ALLIANCE then
        WarfrontRareTracker.broker.icon = BROKER_ICON_ALLIANCE
    elseif faction == FACTION_HORDE then
        WarfrontRareTracker.broker.icon = BROKER_ICON_HORDE
    else
        WarfrontRareTracker.broker.icon = BROKER_ICON_UNKNOWN
    end
end

local function updateBrokerText()
    if updateBrokerTimer then
        WarfrontRareTracker:CancelTimer(updateBrokerTimer)
        updateBrokerTimer = nil
    end
    local canSchedule = false
    local scheduleState = 0
    local brokerText
    local factionControlling = rareDB[getPlayerSelectedZone()].warfrontControlledByFaction
    setBrokerIcon(factionControlling)
    if WarfrontRareTracker.db.profile.broker.showBrokerText then
        if WarfrontRareTracker.db.profile.broker.brokerText == "addonname" then
            brokerText = "Warfront Rare Tracker"
        elseif WarfrontRareTracker.db.profile.broker.brokerText == "factionstatus" then
            if hasDBContributionInfo() then
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
                    factionControlling = rareDB[getPlayerSelectedZone()].warfrontControlledByFaction == FACTION_HORDE and colorText(FACTION_HORDE, colors.red) or colorText(FACTION_ALLIANCE, colors.blue)
                    brokerText = factionControlling .. colorText(" Has Control", colors.turqoise)
                    canSchedule = false
                end
            else
                brokerText = "No Status Info"
            end
        elseif WarfrontRareTracker.db.profile.broker.brokerText == "allstatus" then
            if hasDBContributionInfo() then
                canSchedule = true
                local oppositeFaction = rareDB[getPlayerSelectedZone()].warfrontControlledByFaction == FACTION_HORDE and colorText("(A) ", colors.blue) or colorText("(H) ", colors.red)
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
                    canSchedule = false
                end
            else
                brokerText = "No Status Info"
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
        --print("error")
        return 0
    end
    if cave then
        if rareDB[mapid].rares[npcid].cave == nil then
            --print("no cave")
            return 0
        end
        if #rareDB[mapid].rares[npcid].cave == 1 then
            return rareDB[mapid].rares[npcid].cave[1]
        else
            if rareDB[mapid].warfrontControlledByFaction == FACTION_ALLIANCE then
                return rareDB[mapid].rares[npcid].cave[1]
            else
                return rareDB[mapid].rares[npcid].cave[2]
            end
        end
    else
        if #rareDB[mapid].rares[npcid].coord == 1 then
            return rareDB[mapid].rares[npcid].coord[1]
        else
            if rareDB[mapid].warfrontControlledByFaction == FACTION_ALLIANCE then
                return rareDB[mapid].rares[npcid].coord[1]
            else
                return rareDB[mapid].rares[npcid].coord[2]
            end
        end
    end
end

local function addToTomTom(mapid, npcid)
    if isTomTomloaded and WarfrontRareTracker.db.profile.tomtom.enableIntegration then
        local factionControlling = rareDB[mapid].warfrontControlledByFaction
        local rare = rareDB[mapid].rares[npcid]
        local coord = rare.coord[1]
        if #rare.coord > 1 and factionControlling == FACTION_HORDE then
            coord = rare.coord[2]
        end
        local name = rare.name
        local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000

        TomTom:AddWaypoint(mapid, x, y, {
            title = name,
            persistent = nil,
            minimap = true,
            world = true,
        })
        if rare.cave and type(rare.cave) == "table" then
            coord = rare.cave[1]
            if #rare.cave > 1 and factionControlling == FACTION_HORDE then
                coord = rare.cave[2]
            end
            name = name .. " Cave Entrance"
            x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
            TomTom:AddWaypoint(mapid, x, y, {
                title = name,
                persistent = nil,
                minimap = true,
                world = true,
            })
        end
        if WarfrontRareTracker.db.profile.tomtom.enableChatMessage then
            WarfrontRareTracker:Print("Added waypoint to: " .. rare.name)
        end
    end
end

local function currentPlayerLeveledUp(newLevel)
    if isPlayerMaxLevel() and WarfrontRareTracker.db.profile.general.enableLevelUpSound then
        playSound("good")
    end
    if isPlayerMaxLevel() and WarfrontRareTracker.db.profile.general.enableLevelUpChatMessage then
        local zones = ""
        for mapid, c in pairs(rareDB) do
            if string.len(zones) > 1 then
                zones = zones .. colorText(", ", colors.turqoise)
            end
            zones = zones .. colorText(rareDB[mapid].zonename, colors.lightcyan)
        end
        zones = zones .. colorText("!", colors.turqoise)
        WarfrontRareTracker:Print(colorText("Good news everyone. You are now egliable to fight the Rare's in: ", colors.turqoise) .. zones)
    end
end

local function sortLootTables()
    for mapid, contents in pairs(rareDB) do
        for npcid, rare in pairs(contents.rares) do
            if rare.loot ~= nil and #rare.loot > 1 then
                table.sort(rare.loot, function(a, b) return a.droptype < b.droptype end)
            end
        end
    end
end

----------------------
-- Addon Compatibility
----------------------

-- MinimapButtonBag
-- Add Minimap Icons to the 'Ignore List' or else the addon thinks all Icons are an Addon Icon at the edge of the Menimap.
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
            end
        end
    end
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
end

local delayedInitializeDone = false
function WarfrontRareTracker:DelayedInitialize(auto)
    if auto == true and delayedInitializeDone == false then
        return
    end
    WarfrontRareTracker:DelayedConfigInitialize()
    if IsAddOnLoaded("TomTom") then
        isTomTomloaded = true
    end
    scanForKnownItems()
    self:UpdateAllWorldMapIcons()
    updateBrokerText()
    C_Timer.After(5, function() WarfrontRareTracker:RefreshAllData() end)
    delayedInitializeDone = true
end

function WarfrontRareTracker:OnEnable()
    -- Normal Events
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("NEW_MOUNT_ADDED", "OnEvent")
    self:RegisterEvent("NEW_PET_ADDED", "OnEvent")
    self:RegisterEvent("PLAYER_LEVEL_UP", "OnEvent")
    -- Bucket Events
    self:RegisterBucketEvent("ZONE_CHANGED", 1, "ZONE_CHANGED")
    self:RegisterBucketEvent("ZONE_CHANGED_INDOORS", 1, "ZONE_CHANGED")
    self:RegisterBucketEvent("ZONE_CHANGED_NEW_AREA", 1,"ZONE_CHANGED")
    
    self:RegisterBucketEvent("LOOT_CLOSED", 1,"BUCKET_ON_LOOT_RECEIVED")
    self:RegisterBucketEvent("PLAYER_MONEY", 2, "BUCKET_ON_LOOT_RECEIVED") -- if worldboss only drops money
    self:RegisterBucketEvent("SHOW_LOOT_TOAST", 2, "BUCKET_ON_LOOT_RECEIVED")
    self:RegisterBucketEvent("SHOW_LOOT_TOAST_UPGRADE", 2,"BUCKET_ON_LOOT_RECEIVED")
    self:RegisterBucketEvent("ENCOUNTER_LOOT_RECEIVED", 2, "BUCKET_ON_LOOT_RECEIVED")
    self:RegisterBucketEvent("TOYS_UPDATED", 2,"TOYS_UPDATED")
    -- Set variables and Worldmap Icons
    self:DelayedInitialize(true)
end

function WarfrontRareTracker:OnDisable()
    -- Normal Events
    self:UnregisterEvent("NEW_MOUNT_ADDED")
    self:UnregisterEvent("NEW_PET_ADDED")
    self:UnregisterEvent("PLAYER_LEVEL_UP")
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
end

----------------
-- Events
----------------
-- Event Handler
function WarfrontRareTracker:OnEvent(event, ...)
    if event == "NEW_MOUNT_ADDED" and isPlayerMaxLevel() then
        scanForKnownItems()
    elseif event == "NEW_PET_ADDED" and isPlayerMaxLevel() then
        if newPetAdedTimer == nil then
            newPetAdedTimer = self:ScheduleTimer(function() scanForKnownItems() end, 2)
        end
    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        currentPlayerLevel = newLevel
        if isPlayerMaxLevel() then
            C_Timer.After(5, function() currentPlayerLeveledUp(newLevel) end)
        end
    end
end

----------------
-- Normal Events
function WarfrontRareTracker:PLAYER_ENTERING_WORLD()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    currentPlayerLevel = UnitLevel("player")
    currentPlayerName = UnitName("player")
    currentPlayerFaction = UnitFactionGroup("player")
    currentPlayerRealm = GetRealmName()
    WarfrontRareTracker:ZONE_CHANGED()
    checkMBBPinExclusion()
    checkWarfrontControl()
    sortLootTables()
    WarfrontRareTracker:SortRares()
    C_Timer.After(5, function() WarfrontRareTracker:DelayedInitialize(false) end)
end

----------------
-- Bucket events
function WarfrontRareTracker:BUCKET_ON_LOOT_RECEIVED()
    if isPlayerMaxLevel() and isPlayerInWarfront() and not playerIsInInstance then
        if isSessionLocked("BUCKET_ON_LOOT_RECEIVED") then
            return
        end
        C_Timer.After(3, function() WarfrontRareTracker:CheckAndUpdateZoneWorldMapIcons() end)
    end
end

function WarfrontRareTracker:ZONE_CHANGED()
    local oldMapid = currentPlayerMapid
    local currentMapID = C_Map.GetBestMapForUnit("player")
    if currentMapID ~= currentPlayerMapid then
        currentPlayerMapid = currentMapID
        playerIsInInstance, _ = IsInInstance()
        --print("ZONE_CHANGED - currentPlayerMapid: " .. currentPlayerMapid .. " playerIsInInstance: " .. tostring(playerIsInInstance))
        self:CheckMapChange(oldMapid)
    end
end

function WarfrontRareTracker:TOYS_UPDATED()
    if isPlayerMaxLevel() then
        scanForKnownItems()
    end
end

----------
-- Refresh
----------
function WarfrontRareTracker:RefreshMinimap()
    LibStub("LibDBIcon-1.0"):Refresh("WarfrontRareTracker", self.db.profile.minimap)
end

function WarfrontRareTracker:RefreshConfig()
    WarfrontRareTracker:OnRefreshConfig()
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
    self:RefreshBrokerText()
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

-----------------
-- Main functions
-----------------
function WarfrontRareTracker:GetRareDBSize()
    return getBDSize(rareDB)
end

function WarfrontRareTracker:ColorizeText(text, color)
    return colorText(text, color)
end

function WarfrontRareTracker:OnFactionChange(mapid)
    self:RefreshZoneData(mapid)
end

function WarfrontRareTracker:CheckMapChange(oldMapid)
    if oldMapid == currentPlayerMapid then return end
    local oldAutoChangeZone = autoChangeZone

    if self.db.profile.menu.autoChangeZone then
        if rareDB[currentPlayerMapid] then
            autoChangeZone = currentPlayerMapid
            if self.db.profile.menu.autoSaveZone then
                self.db.char.selectedZone = currentPlayerMapid
            end
        else
            autoChangeZone = nil
        end
    else
        if autoChangeZone ~= nil then
            autoChangeZone = nil
        end
    end
    if self.db.profile.menu.autoChangeZone and autoChangeZone ~= oldAutoChangeZone then
        WarfrontRareTracker:SetTimestamp(false)
    end
end

function WarfrontRareTracker:SetWorldmapIconSize(size, minimap)
    if minimap then
        self.db.profile.minimapIcons.minimapIconSize = size
        for mapid, content in pairs(rareDB) do
            for k, icon in pairs(content.minimapIcons) do
                if rareDB[mapid].rares[icon.npcid].type == TYPE_WORLDBOSS or rareDB[mapid].rares[icon.npcid].type == TYPE_ELITE then
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
                if rareDB[mapid].rares[icon.npcid].type == TYPE_WORLDBOSS or rareDB[mapid].rares[icon.npcid].type == TYPE_ELITE then
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

---------------
-- Tooltips
---------------
-- Menu Tooltip
function WarfrontRareTracker:MenuOnClick(self, button)
    if button == "RightButton" then
        LibStub("AceConfigDialog-3.0"):Open("WarfrontRareTracker")
    elseif button == "LeftButton" then
        if WarfrontRareTracker.db.profile.menu.showMenuOn ~= "click" then
            return
        end
        if WarfrontRareTracker.db.profile.menu.hideOnCombat and UnitAffectingCombat("player") then
            return
        end
        -- if WarfrontRareTracker.db.profile.menu.useMasterfilter then
        --     if WarfrontRareTracker.db.profile.masterfilter.worldmapShowOnlyAtMaxLevel and not isPlayerMaxLevel() then
        --         return
        --     end
        -- else
        --     if WarfrontRareTracker.db.profile.menu.showAtMaxLevel and not isPlayerMaxLevel() then
        --         return
        --     end
        -- end
        if WarfrontRareTracker.db.profile.menu.showAtMaxLevel and not isPlayerMaxLevel() then
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
    -- if WarfrontRareTracker.db.profile.menu.useMasterfilter then
    --     if WarfrontRareTracker.db.profile.masterfilter.worldmapShowOnlyAtMaxLevel and not isPlayerMaxLevel() then
    --         return
    --     end
    -- else
    --     if WarfrontRareTracker.db.profile.menu.showAtMaxLevel and not isPlayerMaxLevel() then
    --         return
    --     end
    -- end
    if WarfrontRareTracker.db.profile.menu.showAtMaxLevel and not isPlayerMaxLevel() then
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

    line = menuTooltip:AddHeader()
    menuTooltip:SetCell(line, 1, TYPE_RARE)
    menuTooltip:SetCell(line, 2, "Drops", nil, "LEFT", 1, LibQTip.LabelProvider, 20, nil, 100, 100)
    menuTooltip:SetCell(line, 3, "Status")
    menuTooltip:AddSeparator()

    for k, npcid in pairs(sortedRareDB[mapid]) do
        if showRare(mapid, npcid, "menu") then
            local name = getColoredRareName(mapid, npcid)
            local drop = getColoredDropText(mapid, npcid)
            local status = getColoredStatusText(mapid, npcid)
            
            local info = mapid..":"..npcid

            line = menuTooltip:AddLine()
            menuTooltip:SetCell(line, 1, name)
            menuTooltip:SetCell(line, 2, drop, nil, "LEFT", 1, LibQTip.LabelProvider, 20, nil, 100, 100)
            menuTooltip:SetCell(line, 3, status)
            menuTooltip:SetLineScript(line, "OnEnter", function(self, info) WarfrontRareTracker:MenuTooltipOnLineEnter(self, info) end, info)
            menuTooltip:SetLineScript(line, "OnLeave", function() WarfrontRareTracker:MenuTooltipOnLineLeave() end)
            menuTooltip:SetLineScript(line, "OnMouseUp", function(self, info, button) WarfrontRareTracker:MenuTooltipOnLineClick(self, info, button) end, info)
        end
    end
    menuTooltip:AddSeparator()

    if WarfrontRareTracker.db.profile.menu.showWarfrontInMenu then
        WarfrontRareTracker:WarfrontStatusInfoTooltip(true)
    end

    line = menuTooltip:AddLine()
    menuTooltip:SetCell(line, 1, colorText("Right-Click to open Options.", colors.turqoise), "LEFT", 3)
    if isTomTomloaded and WarfrontRareTracker.db.profile.tomtom.enableIntegration then
        line = menuTooltip:AddLine()
        menuTooltip:SetCell(line, 1, colorText("Left-Click to add TomTom Waypoint.", colors.turqoise), "LEFT", 3)
    end
end

function WarfrontRareTracker:MenuTooltipOnLineClick(self, info, button)
    if button == "LeftButton" then
        if isTomTomloaded and WarfrontRareTracker.db.profile.tomtom.enableIntegration and WarfrontRareTracker.db.profile.menu.clickToTomTom then
            local mapid, npcid = strsplit(':', info)
            mapid = tonumber(mapid)
            npcid = tonumber(npcid)
            addToTomTom(mapid, npcid)
        end
    end
end

----------------------------------
-- Menu Warfront Selection Tooltip
local oldSelectedZone
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
        tooltip:SetLineScript(line, "OnEnter", function(self) WarfrontRareTracker:WarfrontStatusTooltipOnEnter(self) end)
        tooltip:SetLineScript(line, "OnLeave", function() WarfrontRareTracker:WarfrontStatusTooltipOnleave() end)
        tooltip:SetLineScript(line, "OnMouseUp", function(self, mapid, button) WarfrontRareTracker:MenuWarfrontSelectionToolOnCick(self, mapid, button) end, mapid)
    else
        line = tooltip:AddHeader()
        tooltip:SetCell(line, 1, colorText("Select Warfront", colors.yellow), tooltip:GetHeaderFont(), "CENTER", 3)
        tooltip:AddSeparator()
        local selectedColor = colors.green
        local activeColor = colors.orange

        if manualTimestamp >= autoChangeZoneTimestamp then
            selectedColor = colors.orange
            activeColor = colors.green
        end
        
        for dbMapid, content in pairs(rareDB) do
            line = tooltip:AddLine()
            if WarfrontRareTracker.db.profile.menu.autoChangeZone and autoChangeZone ~= nil and dbMapid == autoChangeZone or WarfrontRareTracker.db.profile.menu.autoChangeZone and autoChangeZone == nil and dbMapid == WarfrontRareTracker.db.char.selectedZone then
                tooltip:SetCell(line, 1, colorText(content.zonename, selectedColor), nil, "CENTER", 3)
            elseif WarfrontRareTracker.db.profile.menu.autoChangeZone and dbMapid == WarfrontRareTracker.db.char.selectedZone then
                tooltip:SetCell(line, 1, colorText(content.zonename, activeColor), nil, "CENTER", 3)
            elseif not WarfrontRareTracker.db.profile.menu.autoChangeZone and dbMapid == WarfrontRareTracker.db.char.selectedZone then
                tooltip:SetCell(line, 1, colorText(content.zonename, selectedColor), nil, "CENTER", 3)
            else
                tooltip:SetCell(line, 1, colorText(content.zonename, colors.grey), nil, "CENTER", 3)
            end
            tooltip:SetLineScript(line, "OnMouseUp", function(self, mapid, button) WarfrontRareTracker:MenuWarfrontSelectionToolOnCick(self, mapid, button) end, dbMapid)
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

local function addLootInfoToTooltip(tooltip, mapid, npcid, lootindex) -- New, usable is more tooltips
    if rareDB[mapid].rares[npcid].loot[lootindex] == nil then
        return
    end
    if rareDB[mapid].rares[npcid].loot[lootindex].itemID > 0 then
        local itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(rareDB[mapid].rares[npcid].loot[lootindex].itemID)

        if lootindex > 1 then
            local line = tooltip:AddLine()
            tooltip:SetCell(line, 1, " ", nil, nil, 2)
        end
        local line = tooltip:AddLine()
        tooltip:SetCell(line, 1, colorText("Drops: ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].loot[lootindex].droptype, colors.lightcyan), nil, nil, 2)

        if itemTexture ~= nil then
            tooltip:AddHeader(itemLink or itemName, "|T" .. itemTexture .. ":22|t")
        else
            tooltip:AddHeader(itemLink or itemName)
        end
        
        npcToolTip:SetItemByID(rareDB[mapid].rares[npcid].loot[lootindex].itemID)
        for i = 2, npcToolTip:NumLines() do
            local tooltipLine =  _G["__WarfrontRareTracker_ScanTipTextLeft" .. i]
            local text = tooltipLine:GetText()
            local color = {}
            color[1], color[2], color[3], color[4] = tooltipLine:GetTextColor()

            if string.len(text) > 1 then
                local line = tooltip:AddLine()
                tooltip:SetCell(line, 1, colorText(text, color), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 200)
            end
        end
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

    if rareHasLoot(mapid, npcid) then
        if #rareDB[mapid].rares[npcid].loot > 0 then
            local i
            for i = 1, #rareDB[mapid].rares[npcid].loot do
                addLootInfoToTooltip(lootTooltip, mapid, npcid, i)
            end
        end
    else
        line = lootTooltip:AddLine()
        lootTooltip:SetCell(line, 1, colorText("No know drop", colors.lightcyan), nil, nil, 2)
    end

    if rareDB[mapid].rares[npcid].note then
        line = lootTooltip:AddLine()
        lootTooltip:SetCell(line, 1, " ", nil, nil, 2)
        line = lootTooltip:AddLine()
        lootTooltip:SetCell(line, 1, colorText("Note: ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].note, colors.grey), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 200)
    end

    if lootTooltip:GetLineCount() > 1 then
        lootTooltip:Show()
    end
end

--------------------------
-- Warfront Status Tooltip
local WarfrontStatusInfoTooltipCounter = 1

function WarfrontRareTracker:WarfrontStatusTooltipOnleave()
    if warfrontStatusTooltip then
        LibQTip:Release(warfrontStatusTooltip)
        warfrontStatusTooltip = nil
    end
end

function WarfrontRareTracker:WarfrontStatusTooltipOnEnter(self)
    if LibQTip:IsAcquired("WarfrontRareTrackerWarfrontStatusTip") and warfrontStatusTooltip then
        LibQTip.Release(warfrontStatusTooltip)
        warfrontStatusTooltip = nil
    end
    warfrontStatusTooltip = LibQTip:Acquire("WarfrontRareTrackerWarfrontStatusTip", 3, "LEFT", "LEFT", "LEFT")
    warfrontStatusTooltip:Clear()
    warfrontStatusTooltip:SetClampedToScreen(true)
    warfrontStatusTooltip:SetPoint("TOPRIGHT", self, "LEFT", -15, 17)

    if WarfrontRareTracker.db.profile.menu.showWarfrontOnZoneName then
        WarfrontRareTracker:WarfrontStatusInfoTooltip(false)

        if warfrontStatusTooltip:GetLineCount() > 3 then
            warfrontStatusTooltip:Show()
        end
    else
        local line = warfrontStatusTooltip:AddHeader()
        warfrontStatusTooltip:SetCell(line, 1, colorText("Click to select different Warfront", colors.yellow), warfrontStatusTooltip:GetHeaderFont())
        warfrontStatusTooltip:Show()
    end
end

local function addSeperator(tooltip, inmenu)
    if not inmenu and WarfrontStatusInfoTooltipCounter >= 1 then
        tooltip:AddSeparator()
        tooltip:AddLine(" ")
        tooltip:AddSeparator()
    elseif inmenu and WarfrontStatusInfoTooltipCounter >= 1 then
        tooltip:AddSeparator()
    end
end

local function updateWarfrontStatusInfoTooltip(tooltip, mapid, inmenu)
    local line
    local controllingFaction= rareDB[mapid].warfrontControlledByFaction == FACTION_HORDE and colorText(FACTION_HORDE, colors.red) or colorText(FACTION_ALLIANCE, colors.blue)
    if hasDBContributionInfo(mapid) and rareDB[mapid].warfrontControlledByFaction ~= "" then
        if inmenu and WarfrontStatusInfoTooltipCounter == 0 then
            line = tooltip:AddHeader()
            tooltip:SetCell(line, 1, colorText("Warfront Status", colors.yellow), tooltip:GetHeaderFont(), "CENTER", 3)
            tooltip:AddSeparator()
        elseif not inmenu and WarfrontStatusInfoTooltipCounter == 0 then
            line = tooltip:AddHeader()
            tooltip:SetCell(line, 1, colorText("Click to select different Warfront", colors.yellow), tooltip:GetHeaderFont(), "RIGHT", 3)
            line = tooltip:AddLine()
            tooltip:SetCell(line, 1, " ", nil, "LEFT", 3)

            line = tooltip:AddHeader()
            tooltip:SetCell(line, 1, colorText("Warfront Status", colors.yellow), tooltip:GetHeaderFont(), "CENTER", 3)

            line = tooltip:AddLine()
            tooltip:SetCell(line, 1, " ", nil, "LEFT", 3)

            tooltip:AddSeparator()
        end

        local zoneState, zonePercentage, zoneTimeNextChange = getWarfrontProgressInfo(mapid)
        local oppositeFaction = rareDB[mapid].warfrontControlledByFaction == FACTION_HORDE and FACTION_ALLIANCE or FACTION_HORDE
        addSeperator(tooltip, inmenu)

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

        if oppositeFaction == FACTION_HORDE then
            oppositeFaction = colorText(FACTION_HORDE, colors.red)
        else
            oppositeFaction = colorText(FACTION_ALLIANCE, colors.blue)
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
    else
        addSeperator(tooltip, inmenu)
        line = tooltip:AddHeader()
        tooltip:SetCell(line, 1, colorText(rareDB[mapid].zonename, colors.lightcyan), nil, "CENTER", 3)
        tooltip:AddSeparator(1, colors.grey[1], colors.grey[2], colors.grey[3], 1)
        line = tooltip:AddLine()
        tooltip:SetCell(line, 1, colorText("No info available.", colors.grey), nil, nil, 3)
    end
end

function WarfrontRareTracker:WarfrontStatusInfoTooltip(inmenu)
    WarfrontStatusInfoTooltipCounter = 0
    if warfrontStatusTooltip and WarfrontRareTracker.db.profile.menu.showWarfrontOnZoneName and WarfrontRareTracker.db.profile.menu.showWarfrontTitle == "current" then -- and hasDBContributionInfo() then
        updateWarfrontStatusInfoTooltip(warfrontStatusTooltip, getPlayerSelectedZone(), inmenu)
    elseif warfrontStatusTooltip and WarfrontRareTracker.db.profile.menu.showWarfrontOnZoneName and WarfrontRareTracker.db.profile.menu.showWarfrontTitle == "all" then
        for mapid, v in pairs(rareDB) do
            updateWarfrontStatusInfoTooltip(warfrontStatusTooltip, mapid, inmenu)
            WarfrontStatusInfoTooltipCounter = WarfrontStatusInfoTooltipCounter + 1
        end
    elseif menuTooltip and WarfrontRareTracker.db.profile.menu.showWarfrontInMenu and WarfrontRareTracker.db.profile.menu.showWarfrontMenu == "current" and inmenu then -- and hasDBContributionInfo() then
        updateWarfrontStatusInfoTooltip(menuTooltip, getPlayerSelectedZone(), inmenu)
        menuTooltip:AddSeparator()
    elseif menuTooltip and WarfrontRareTracker.db.profile.menu.showWarfrontInMenu and WarfrontRareTracker.db.profile.menu.showWarfrontMenu == "all" and inmenu then
        for mapid, v in pairs(rareDB) do
            updateWarfrontStatusInfoTooltip(menuTooltip, mapid, inmenu)
            WarfrontStatusInfoTooltipCounter = WarfrontStatusInfoTooltipCounter + 1
        end
        menuTooltip:AddSeparator()
    end
end

-------------------
-- Worldmap Tooltip
function WarfrontRareTracker:WorldmapTooltipOnClick(self, mapid, npcid)
    if isTomTomloaded and WarfrontRareTracker.db.profile.tomtom.enableIntegration and WarfrontRareTracker.db.profile.worldmapicons.clickToTomTom then
        addToTomTom(mapid, npcid)
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

function WarfrontRareTracker:WorldmapTooltipOnEnter(self, mapid, npcid, NPC, minimap) -- rewritten
    if LibQTip:IsAcquired("WarfrontRareTrackerWorldmapTip") and worldmapTooltip then
        LibQTip.Release(worldmapTooltip)
        worldmapTooltip = nil
    end
    worldmapTooltip = LibQTip:Acquire("WarfrontRareTrackerWorldmapTip", 2, "LEFT", "RIGHT")
    worldmapTooltip:ClearAllPoints()
    worldmapTooltip:SetClampedToScreen(true)
    worldmapTooltip:SetPoint("TOPRIGHT", self, "BOTTOM")

    local line
    if NPC then
        local itemName, itemLink, itemTexture
        if minimap and WarfrontRareTracker.db.profile.minimapIcons.onMinimapHoover then
            if WarfrontRareTracker.db.profile.minimapIcons.minimapIconsCompactMode then
                line = worldmapTooltip:AddHeader()
                worldmapTooltip:SetCell(line, 1, getColoredRareName(mapid, npcid) .. colorText(": ", colors.yellow) .. getColoredStatusText(mapid, npcid), nil, nil, 2)

                if rareDB[mapid].rares[npcid].loot == nil then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText("No loot", colors.turqoise), nil, nil, 2)
                end
                if #rareDB[mapid].rares[npcid].loot == 0 then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText("No know drop", colors.lightcyan), nil, nil, 2)
                elseif #rareDB[mapid].rares[npcid].loot == 1 then
                    if rareHasLegitLoot(mapid, npcid) then
                        itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(rareDB[mapid].rares[npcid].loot[1].itemID)
                        itemName = checkItemNameIsValid(itemName, rareDB[mapid].rares[npcid].loot[1].droptype)
                        line = worldmapTooltip:AddLine()
                        if rareDB[mapid].rares[npcid].loot[1].isKnown then
                            worldmapTooltip:SetCell(line, 1, (itemLink or itemName) .. colorText(": ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].loot[1].droptype .. " already known", colors.red), nil, nil, 2)
                        else
                            worldmapTooltip:SetCell(line, 1, (itemLink or itemName) .. colorText(": ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].loot[1].droptype .. " still needed", colors.green), nil, nil, 2)
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
                        itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(rareDB[mapid].rares[npcid].loot[1].itemID)
                        itemName = checkItemNameIsValid(itemName, rareDB[mapid].rares[npcid].loot[1].droptype)
                        line = worldmapTooltip:AddLine()
                        if rareDB[mapid].rares[npcid].loot[1].isKnown then
                            worldmapTooltip:SetCell(line, 1, colorText("Drops " .. rareDB[mapid].rares[npcid].loot[1].droptype .. ": ", colors.yellow) .. (itemLink or itemName) .. colorText(" already known", colors.red), nil, nil, 2)
                        else
                            worldmapTooltip:SetCell(line, 1, colorText("Drops " .. rareDB[mapid].rares[npcid].loot[1].droptype .. ": ", colors.yellow) .. (itemLink or itemName) .. colorText(" still needed", colors.green), nil, nil, 2)
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
                worldmapTooltip:SetCell(line, 1, colorText("Note: ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].note, colors.grey), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 280)
            end
        elseif not minimap then
            worldmapTooltip:AddHeader(getColoredRareName(mapid, npcid))

            line = worldmapTooltip:AddLine()
            worldmapTooltip:SetCell(line, 1, colorText("Status: ", colors.yellow) .. getColoredStatusText(mapid, npcid), nil, nil, 2)
            line = worldmapTooltip:AddLine()
            worldmapTooltip:SetCell(line, 1, " ", nil, nil, 2)

            if #rareDB[mapid].rares[npcid].loot > 0 then
                local i
                for i = 1, #rareDB[mapid].rares[npcid].loot do
                    addLootInfoToTooltip(worldmapTooltip, mapid, npcid, i)
                end
            else
                line = worldmapTooltip:AddLine()
                worldmapTooltip:SetCell(line, 1, colorText("No know drop", colors.lightcyan), nil, nil, 2)
            end

            if rareDB[mapid].rares[npcid].warning then
                if rareDB[mapid].rares[npcid].faction == currentPlayerFaction and rareDB[mapid].warfrontControlledByFaction ~= currentPlayerFaction then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, " ", nil, nil, 2)
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText(rareDB[mapid].rares[npcid].warning, colors.red), nil, nil, 2)
                end
            end
            if rareDB[mapid].rares[npcid].note then
                if rareDB[mapid].rares[npcid].warning and rareDB[mapid].rares[npcid].faction == currentPlayerFaction and rareDB[mapid].warfrontControlledByFaction == currentPlayerFaction then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, " ", nil, nil, 2)
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText("Note: ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].note, colors.grey), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 200)
                elseif not rareDB[mapid].rares[npcid].warning then
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, " ", nil, nil, 2)
                    line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText("Note: ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].note, colors.grey), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 200)
                    --lootTooltip:SetCell(line, 1, colorText("Note: ", colors.yellow) .. colorText(rareDB[mapid].rares[npcid].note, colors.grey), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 200)
                end
            end
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

        if worldmapTooltip:GetLineCount() >= 1 then
            worldmapTooltip:Show()
        end
    else
        worldmapTooltip:AddLine(colorText("Cave entrance for: " .. getColoredRareName(mapid, npcid), colors.yellow))
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
    pin = CreateFrame("Button", WARFRONT_PINNAME..pinCount, Minimap)
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
        return "Interface\\MINIMAP\\Suramar_Door_Icon"
    end
    if not WarfrontRareTracker.db.profile.worldmapicons.useMasterfilter and WarfrontRareTracker.db.profile.worldmapicons.handleDefeated == "change" and isQuestCompleted(mapid, npcid) then
        return "Interface\\Worldmap\\X_Mark_64Grey"
    elseif WarfrontRareTracker.db.profile.worldmapicons.useMasterfilter and WarfrontRareTracker.db.profile.masterfilter.worldmapHandleDefeated == "change" and isQuestCompleted(mapid, npcid) then
        return "Interface\\Worldmap\\X_Mark_64Grey"
    end

    if rareDB[mapid].rares[npcid].faction == currentPlayerFaction and rareDB[mapid].warfrontControlledByFaction ~= currentPlayerFaction and not rareDB[mapid].rares[npcid].bothphases then
         return "Interface\\Worldmap\\GlowSkull_64Red"
    elseif rareDB[mapid].rares[npcid].type == TYPE_WORLDBOSS or rareDB[mapid].rares[npcid].type == TYPE_ELITE then
        return "Interface\\Worldmap\\GlowSkull_64Purple"
    elseif rareDB[mapid].rares[npcid].type == TYPE_GOLIATH then
        return "Interface\\Worldmap\\GlowSkull_64Grey"
    else
        return "Interface\\Worldmap\\GlowSkull_64Blue"
    end
end

local function getWorldMapIconSizeForRare(mapid, npcid, mode)
    if rareDB[mapid].rares[npcid].type == TYPE_WORLDBOSS or rareDB[mapid].rares[npcid].type == TYPE_ELITE then
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
    if not isPlayerMaxLevel() then
        return
    end
    if self.db.profile.worldmapicons.useMasterfilter and self.db.profile.masterfilter.worldmapHandleDefeated == "hide" and rareDB[currentPlayerMapid] or not self.db.profile.worldmapicons.useMasterfilter and self.db.profile.worldmapicons.handleDefeated == "hide" and rareDB[currentPlayerMapid] then
        for k, icon in pairs(rareDB[currentPlayerMapid].worldmapIcons) do
            if isQuestCompleted(currentPlayerMapid, icon.npcid) then
                HBDPins:RemoveWorldMapIcon("WarfrontRareTracker"..rareDB[currentPlayerMapid].zonename, icon)
                recyclePin(icon)
                rareDB[currentPlayerMapid].worldmapIcons[k] = nil
            end
        end
        if self.db.profile.minimapIcons.showMinimapIcons then
            for k, icon in pairs(rareDB[currentPlayerMapid].minimapIcons) do
                if isQuestCompleted(currentPlayerMapid, icon.npcid) then
                    HBDPins:RemoveMinimapIcon("WarfrontRareTracker"..rareDB[currentPlayerMapid].zonename, icon)
                    recyclePin(icon)
                    rareDB[currentPlayerMapid].minimapIcons[k] = nil
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
    local coord = getCoordsForWarfrontPhase(mapid, npcid, false)
    if caveicon then
        coord = getCoordsForWarfrontPhase(mapid, npcid, true)
    end
    local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000

    if self.db.profile.worldmapicons.showWorldmapIcons then
        local worldmapicon = getNewPin()
        worldmapicon:SetParent(Worldmap)
        worldmapicon:SetHeight(getWorldMapIconSizeForRare(mapid, npcid, "worldmap")) -- ?
        worldmapicon:SetWidth(getWorldMapIconSizeForRare(mapid, npcid, "worldmap"))
        worldmapicon:SetAlpha(getWorldMapIconAlphaForRare(mapid, npcid, "worldmap"))
        worldmapicon.texture:SetTexCoord(0, 1, 0, 1)
        worldmapicon.texture:SetVertexColor(1, 1, 1, 1)
        worldmapicon.texture:SetTexture(getWorldMapIconForRare(mapid, npcid, caveicon))
        worldmapicon.npcid = npcid
        worldmapicon.mapid = mapid
        worldmapicon:SetScript("OnClick", function(self) WarfrontRareTracker:WorldmapTooltipOnClick(self, worldmapicon.mapid, worldmapicon.npcid, false) end)
        worldmapicon:SetScript("OnEnter", function(self) WarfrontRareTracker:WorldmapTooltipOnEnter(self, worldmapicon.mapid, worldmapicon.npcid, true, false) end)
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
        if self.db.profile.minimapIcons.onMinimapHoover then
            minimapIcon:SetScript("OnEnter", function(self) WarfrontRareTracker:WorldmapTooltipOnEnter(self, minimapIcon.mapid, minimapIcon.npcid, true, true) end)
            minimapIcon:SetScript("OnLeave", function() WarfrontRareTracker:WorldmapTooltipOnLeave() end)
        end
        table.insert(rareDB[mapid].minimapIcons, minimapIcon)
        HBDPins:AddMinimapIconMap("WarfrontRareTracker"..rareDB[mapid].zonename, minimapIcon, mapid, x, y, false, false)
    end
end

----------------
-- NPC UnitFrame
----------------
GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    if WarfrontRareTracker.db.profile.unitframe.enableUnitframeIntegration == false then
        return
    end
    if rareDB[currentPlayerMapid] == nil or playerIsInInstance then
        return
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

    --local mapid = currentPlayerMapid
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
                            --itemName = checkItemNameIsValid(itemName, rareDB[mapid].rares[npcid].loot[1].droptype)
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
                                --itemName = checkItemNameIsValid(itemName, rareDB[mapid].rares[npcid].loot[i].droptype)
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

                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(text)
            else
                GameTooltip:AddLine(" ")
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
                            --itemName = checkItemNameIsValid(itemName, rareDB[mapid].rares[npcid].loot[1].droptype)
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
                                --itemName = checkItemNameIsValid(itemName, rareDB[mapid].rares[npcid].loot[i].droptype)
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

                -- -- Ignore Goliaths
                -- if rare.type ~= TYPE_GOLIATH and WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and rare.isKnown and rare.itemID > 0 then
                --     GameTooltip:AddLine(colorText(rare.drop .. " already known", colors.red))
                -- elseif rare.type ~= TYPE_GOLIATH and WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and not rare.isKnown and rare.itemID > 0  then
                --     GameTooltip:AddLine(colorText(rare.drop .. " still needed", colors.green))
                -- end
                -- Ignore Drop: Item (if needed with a new Warfront)
                -- if rare.drop ~= DROP_ITEM and WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and rare.isKnown then
                --     GameTooltip:AddLine(colorText(rare.drop .. " already known", colors.red))
                -- elseif rare.drop ~= DROP_ITEM and WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and not rare.isKnown then
                --     GameTooltip:AddLine(colorText(rare.drop .. " still needed", colors.green))
                -- end
            end
        end
    end
end)

----------
-- Sorting
----------
local function compareString(a, b)
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

function WarfrontRareTracker:SortRares()
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
                        if v.type ~= TYPE_WORLDBOSS then
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
                        if compareString(worldbossTable[j].name, worldbossTable[min].name) then min = j end
                    end
                    worldbossTable[i], worldbossTable[min] = worldbossTable[min], worldbossTable[i]
                end
                for i = 1, n, 1 do
                    min = i
                    for j = i + 1, n, 1 do
                        if WarfrontRareTracker.db.profile.menu.groupTypeSortOn == "drop" then
                            if (compareString(normalTable[j].type, normalTable[min].type)) or (normalTable[j].type == normalTable[min].type and compareString(getAllLootConcatinated(mapid, normalTable[j].npcid), getAllLootConcatinated(mapid, normalTable[min].npcid))) or (normalTable[j].type == normalTable[min].type and getAllLootConcatinated(mapid, normalTable[j].npcid) == getAllLootConcatinated(mapid, normalTable[min].npcid) and compareString(normalTable[j].name, normalTable[min].name)) then min = j end
                        else
                            if (compareString(normalTable[j].type, normalTable[min].type)) or (normalTable[j].type == normalTable[min].type and compareString(normalTable[j].name, normalTable[min].name)) then min = j end
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
                            if (compareString(tempTable[j].type, tempTable[min].type)) or (tempTable[j].type == tempTable[min].type and compareString(getAllLootConcatinated(mapid, tempTable[j].npcid), getAllLootConcatinated(mapid, tempTable[min].npcid))) or (tempTable[j].type == tempTable[min].type and getAllLootConcatinated(mapid, tempTable[j].npcid) == getAllLootConcatinated(mapid, tempTable[min].npcid) and compareString(tempTable[j].name, tempTable[min].name)) then min = j end
                        else
                            if (compareString(tempTable[j].type, tempTable[min].type)) or (tempTable[j].type == tempTable[min].type and compareString(tempTable[j].name, tempTable[min].name)) then min = j end
                        end
                    end
                    tempTable[i], tempTable[min] = tempTable[min], tempTable[i]
                end
            end
        elseif WarfrontRareTracker.db.profile.menu.sortRaresOn == "drop" then
            if WarfrontRareTracker.db.profile.menu.worldbossOnTop then
                for k, v in pairs(contents.rares) do
                    if type(v) == "table" then
                        if v.type ~= TYPE_WORLDBOSS then
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
                        if compareString(worldbossTable[j].name, worldbossTable[min].name) then min = j end
                    end
                    worldbossTable[i], worldbossTable[min] = worldbossTable[min], worldbossTable[i]
                end
                for i = 1, n, 1 do
                    min = i
                    for j = i + 1, n, 1 do
                        if WarfrontRareTracker.db.profile.menu.groupDropSortOn == "type" then
                            --print("sort :: " .. normalTable[j].name .. ": " .. getAllLootConcatinated(mapid, normalTable[j].npcid) .. " - " .. normalTable[min].name .. ": " .. getAllLootConcatinated(mapid, normalTable[min].npcid))
                            if (compareString(getAllLootConcatinated(mapid, normalTable[j].npcid), getAllLootConcatinated(mapid, normalTable[min].npcid))) or (getAllLootConcatinated(mapid, normalTable[j].npcid) == getAllLootConcatinated(mapid, normalTable[min].npcid) and compareString(normalTable[j].type, normalTable[min].type)) or (getAllLootConcatinated(mapid, normalTable[j].npcid) == getAllLootConcatinated(mapid, normalTable[min].npcid) and normalTable[j].type == normalTable[min].type and compareString(normalTable[j].name, normalTable[min].name)) then min = j end
                        else
                            if (compareString(getAllLootConcatinated(mapid, normalTable[j].npcid), getAllLootConcatinated(mapid, normalTable[min].npcid))) or (getAllLootConcatinated(mapid, normalTable[j].npcid) == getAllLootConcatinated(mapid, normalTable[min].npcid) and compareString(normalTable[j].name, normalTable[min].name)) then min = j end
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
                            if (compareString(getAllLootConcatinated(mapid, tempTable[j].npcid), getAllLootConcatinated(mapid, tempTable[min].npcid))) or (getAllLootConcatinated(mapid, tempTable[j].npcid) == getAllLootConcatinated(mapid, tempTable[min].npcid) and compareString(tempTable[j].type, tempTable[min].type)) or (getAllLootConcatinated(mapid, tempTable[j].npcid) == getAllLootConcatinated(mapid, tempTable[min].npcid) and tempTable[j].type == tempTable[min].type and compareString(tempTable[j].name, tempTable[min].name)) then min = j end
                        else
                            if (compareString(getAllLootConcatinated(mapid, tempTable[j].npcid), getAllLootConcatinated(mapid, tempTable[min].npcid))) or (getAllLootConcatinated(mapid, tempTable[j].npcid) == getAllLootConcatinated(mapid, tempTable[min].npcid) and compareString(tempTable[j].name, tempTable[min].name)) then min = j end
                        end
                    end
                    tempTable[i], tempTable[min] = tempTable[min], tempTable[i]
                end
            end
        elseif WarfrontRareTracker.db.profile.menu.sortRaresOn == "name" then
            if WarfrontRareTracker.db.profile.menu.worldbossOnTop then
                for k, v in pairs(contents.rares) do
                    if type(v) == "table" then
                        if v.type ~= TYPE_WORLDBOSS then
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
                        if compareString(worldbossTable[j].name, worldbossTable[min].name) then min = j end
                    end
                    worldbossTable[i], worldbossTable[min] = worldbossTable[min], worldbossTable[i]
                end
                for i = 1, n, 1 do
                    min = i
                    for j = i + 1, n, 1 do
                        if compareString(normalTable[j].name, normalTable[min].name) then min = j end
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
                        if compareString(tempTable[j].name, tempTable[min].name) then min = j end
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
