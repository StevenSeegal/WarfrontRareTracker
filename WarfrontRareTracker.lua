WarfrontRareTracker = LibStub("AceAddon-3.0"):NewAddon("WarfrontRareTracker", "AceBucket-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local WarfrontRareTracker = WarfrontRareTracker

local L = LibStub("AceLocale-3.0"):GetLocale("WarfrontRareTracker")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1");
local MinimapIcon = LibStub("LibDBIcon-1.0")

local LibQTip = LibStub("LibQTip-1.0")
local HBDPins = LibStub("HereBeDragons-Pins-2.0")


-----------------------------------------------
-- Local references to wow's provided functions
-----------------------------------------------
local floor, mod, format, strsplit, table, tonumber, type, pairs, next = floor, mod, format, strsplit, table, tonumber, type, pairs, next
local IsInInstance, GetItemInfo, GetServerTime, GetUnit, IsQuestFlaggedCompleted, PlayerHasToy, UnitAffectingCombat, UnitCanAttack, UnitCreatureType, UnitFactionGroup, UnitGUID, UnitIsPlayer, UnitIsPVP, UnitLevel = IsInInstance, GetItemInfo, GetServerTime, GetUnit, IsQuestFlaggedCompleted, PlayerHasToy, UnitAffectingCombat, UnitCanAttack, UnitCreatureType, UnitFactionGroup, UnitGUID, UnitIsPlayer, UnitIsPVP, UnitLevel
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
local SOUND_GOODNEWS = "Interface\\AddOns\\WarfrontRareTracker\\Sounds\\goodnews.ogg"
local SOUND_BADNEWS = "Interface\\AddOns\\WarfrontRareTracker\\Sounds\\badnews.ogg"
local BROKER_ICON_ALLIANCE = "Interface\\Icons\\INV_AllianceWarEffort"
local BROKER_ICON_HORDE = "Interface\\Icons\\INV_HordeWarEffort"
local BROKER_ICON_UNKNOWN = "Interface\\Icons\\ability_ensnare"

---------
-- Locals
---------
-- GameToolTip
local npcToolTip = CreateFrame("GameTooltip", "__WarfrontRareTracker_ScanTip", nil, "GameTooltipTemplate")
npcToolTip:SetOwner(WorldFrame, "ANCHOR_NONE")
-- Timers
local updateBrokerTimer, newPetAdedTimer
-- Tooltips
local lootTooltip, menuSelectTooltip, menuTooltip, warfrontStatusTooltip, worldmapTooltip
local isWarfrontSelectionMenuCollapsed = true
-- Other vars
local isTomTomloaded = false
local autoChangeZone = nil
local autoChangeZoneTimestamp = 0
local manualTimestamp = 0
local currentPlayerMapid = 0
local playerLevel = 0

-- Rare Database
local sortedRareDB = {}
local rareDB = {
    [14] = {
        zonename = "Arathi Highlands",
        scenarioname = "Battle for Stromgarde",
        gatheringname = "Gathering Resources",
        zonelevel = 120,
        zoneContributionMapID = 11,
        allianceContributionMapID = 116,
        hordeContributionMapID = 11,
        warfrontControlledByFaction = "",
        worldmapIcons = {},
        rares = {
            [138122] = { name = L["dooms_howl"], npcid = 138122, questId = { 53002 }, type = "WorldBoss", drop = "Toy", itemID = 163828, faction = "Alliance", coord = { 38624096 }, note = "Alliance only", isKnown = false },
            [137374] = { name = L["the_lions_roar"], npcid = 137374, questId = { 53001 }, type = "WorldBoss", drop = "Toy", itemID = 163829, faction = "Horde", coord = { 38624096 }, note = "Horde only", isKnown = false },
            [141618] = { name = L["cresting_goliath"], npcid = 141618, questId = { 53018, 53531 }, type = "Goliath", drop = "Item", itemID = 163700, faction = "all", coord = { 62093158 }, isKnown = false },
            [141615] = { name = L["burning_goliath"], npcid = 141615, questId = { 53017, 53506 }, type = "Goliath", drop = "Item", itemID = 163691, faction = "all", coord = { 30664478 }, isKnown = false },
            [141620] = { name = L["rumbling_goliath"], npcid = 141620, questId = { 53021, 53523 }, type = "Goliath", drop = "Item", itemID = 163701, faction = "all", coord = { 29885974 }, isKnown = false },
            [141616] = { name = L["thundering_goliath"], npcid = 141616, questId = { 53023, 53527 }, type = "Goliath", drop = "Item", itemID = 163698, faction = "all", coord = { 46325212 }, isKnown = false },
            [142709] = { name = L["beastrider_kama"], npcid = 142709, questId = { 53083, 53504 }, type = "Rare", drop = "Mount", itemID = 163644, mountID = 1180, faction = "all", coord = { 65347116 }, isKnown = false },
            [142692] = { name = L["nimar_the_slayer"], npcid = 142692, questId = { 53091, 53517 }, type = "Rare", drop = "Mount", itemID = 163706, mountID = 1185, faction = "all", coord = { 67616086 }, isKnown = false },
            [142423] = { name = L["overseer_krix"], npcid = 142423, questId = { 53014, 53518 }, type = "Elite", drop = "Mount", itemID = 163646, mountID = 1182, faction = "all", coord = { 32923847, 27405722 }, cave = { 33693676, 27385601 }, note = "Inside cave", isKnown = false },
            [142437] = { name = L["skullripper"], npcid = 142437, questId = { 53022, 53526 }, type = "Elite", drop = "Mount", itemID = 163645, mountID = 1183, faction = "all", coord = { 57154575 }, isKnown = false },
            [142739] = { name = L["knight_captain_aldrin"], npcid = 142739, questId = { 53088 }, type = "Rare", drop = "Mount", itemID = 163578, mountID = 1173, faction = "Horde", coord = { 48894001 }, note = "Horde only", isKnown = false },
            [142741] = { name = L["doomrider_helgrim"], npcid = 142741, questId = { 53085 }, type = "Rare", drop = "Mount", itemID = 163579, mountID = 1174, faction = "Alliance", coord = { 53565764 }, note = "Alliance only", isKnown = false },
            [142508] = { name = L["branchlord_aldrus"], npcid = 142508, questId = { 53013, 53505 }, type = "Elite", drop = "Pet", itemID = 163650, petID = 143503, speciesID = 2433, faction = "all", coord = { 22602135 }, isKnown = false },
            [142688] = { name = L["darbel_montrose"], npcid = 142688, questId = { 53084, 53507 }, type = "Rare", drop = "Pet", itemID = 163652, petID = 143507, speciesID = 2434, faction = "all", coord = { 50673675, 50756121 }, isKnown = false },
            [141668] = { name = L["echo_of_myzrael"], npcid = 141668, questId = { 53059, 53508 }, type = "Elite", drop = "Pet", itemID = 163677, petID = 143515, speciesID = 2435, faction = "all", coord = { 57073506 }, note = "Spawns after defeating all 4 Goliaths.\nAfter defeating the Goliaths there will be\na broadcast when she spawns.", isKnown = false },
            [142433] = { name = L["fozruk"], npcid = 142433, questId = { 53019, 53510 }, type = "Elite", drop = "Pet", itemID = 163711, petID = 143627, speciesID = 2440, faction = "all", coord = { 59422773 }, isKnown = false },
            [142716] = { name = L["man_hunter_rog"], npcid = 142716, questId = { 53090, 53515 }, type = "Rare", drop = "Pet", itemID = 163712 , petID = 143628, speciesID = 2441, faction = "all", coord = { 52277674 }, isKnown = false },
            [142435] = { name = L["plaguefeather"], npcid = 142435, questId = { 53020, 53519 }, type = "Elite", drop = "Pet", itemID = 163690, petID = 143564, speciesID = 2438, faction = "all", coord = { 35606435 }, isKnown = false },
            [142436] = { name = L["ragebeak"], npcid = 142436, questId = { 53016, 53522 }, type = "Elite", drop = "Pet", itemID = 163689, petID = 143563, speciesID = 2437, faction = "all", coord = { 18412794, 11905220 }, isKnown = false },
            [142438] = { name = L["venomarus"], npcid = 142438, questId = { 53024, 53528 }, type = "Elite", drop = "Pet", itemID = 163648, petID = 143499, speciesID = 2432, faction = "all", coord = { 56945330 }, isKnown = false },
            [142440] = { name = L["yogursa"], npcid = 142440, questId = { 53015, 53529 }, type = "Elite", drop = "Pet", itemID = 163684, petID = 143533, speciesID = 2436, faction = "all", coord = { 13063622 }, isKnown = false },
            [142686] = { name = L["foulbelly"], npcid = 142686, questId = { 53086, 53509 }, type = "Rare", drop = "Toy", itemID = 163735, faction = "all", coord = { 22305106 }, cave = { 28804557 }, note = "Inside cave", isKnown = false },
            [142662] = { name = L["geomancer_flintdagger"], npcid = 142662, questId = { 53060, 53511 }, type = "Rare", drop = "Toy", itemID = 163713, faction = "all", coord = { 79452939 }, cave = { 78143689 }, note = "Inside cave", isKnown = false },
            [142725] = { name = L["horrific_apparition"], npcid = 142725, questId = { 53087, 53512 }, type = "Rare", drop = "Toy", itemID = 163736, faction = "all", coord = { 26723278, 19446123 }, isKnown = false },
            [142112] = { name = L["korgresh_coldrage"], npcid = 142112, questId = { 53058, 53513 }, type = "Rare", drop = "Toy", itemID = 163744, faction = "all", coord = { 49178409 }, cave = { 48007941 }, note = "Inside cave", isKnown = false },
            [142684] = { name = L["kovork"], npcid = 142684, questId = { 53089, 53514 }, type = "Rare", drop = "Toy", itemID = 163750, faction = "all", coord = { 25404872 }, cave = { 28804557 }, note = "Inside cave", isKnown = false },
            [141942] = { name = L["molok_the_crusher"], npcid = 141942, questId = { 53057, 53516 }, type = "Rare", drop = "Toy", itemID = 163775, faction = "all", coord = { 47657800 }, isKnown = false },
            [142683] = { name = L["ruul_onestone"], npcid = 142683, questId = { 53092, 53524 }, type = "Rare", drop = "Toy", itemID = 163741, faction = "all", coord = { 42905660 }, isKnown = false },
            [142690] = { name = L["singer"], npcid = 142690, questId = { 53093, 53525 }, type = "Rare", drop = "Toy", itemID = 163738, faction = "all", coord = { 51213999, 50595746 }, isKnown = false },
            [142682] = { name = L["zalas_witherbark"], npcid = 142682, questId = { 53094, 53530 }, type = "Rare", drop = "Toy", itemID = 163745, faction = "all", coord = { 62868112 }, cave = { 63277708 }, note = "Inside cave", isKnown = false },
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
        profileversion = 1,
        minimap = {
            hide = false,
            minimapPos = 180,
        },
        broker = {
            showBrokerText = true,
            brokerText = "addonname",
            updateInterval = 1,
            updateIntervalState1 = 10,
            updateIntervalState2 = 1,
        },
        menu = {
            showMenuOn = "mouse",
            hideOnCombat = true,
            clickToTomTom = true,
            hideAlreadyKnown = false,
            hideGoliaths = false,
            showAtMaxLevel = false,
            showWarfrontOnTitle = true,
            showWarfrontTitle = "current",
            showWarfrontInMenu = false,
            showWarfrontMenu = "current",
            autoChangeZone = true,
            autoSaveZone = false,
            whitelist = { ["Mount"] = false, ["Pet"] = false, ["Toy"] = false},
            sortRaresOn = "drop",
            groupDropSortOn = "type",
            groupTypeSortOn = "drop",
            sortAscending = "true",
            worldbossOnTop = true,
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
        worldmapicons = {
            showWorldmapIcons = true,
            showOnlyAtMaxLevel = true,
            clickToTomTom = true,
            hideIconWhenDefeated = false,
            hideAlreadyKnown = false,
            hideGoliaths = false,
            whitelist = { ["Mount"] = false, ["Pet"] = false, ["Toy"] = false },
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
local function getBDSize(db)
    local counter = 0
    for mapid, content in pairs(db) do
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

local function getPlayerFaction()
    local playerFaction, _ = UnitFactionGroup("player")
    return playerFaction
end

local function isNPCPlayerFaction(mapid, npcid)
    local playerFaction = getPlayerFaction()
    local rareFaction = rareDB[mapid].rares[npcid].faction
    return rareFaction == playerFaction or rareFaction == "all"
end

local function isPlayerMaxZoneLevel(mapid)
    if mapid == nil then
        mapid = getPlayerSelectedZone()
    end
    return playerLevel >= rareDB[mapid].zonelevel 
end

local function getNPCIDFromGUID(guid)
	if guid then
		local unit_type, _, _, _, _, mob_id = strsplit('-', guid)
		if unit_type == "Pet" or unit_type == "Player" then return 0 end
		return (guid and mob_id and tonumber(mob_id)) or 0
	end
	return 0
end

local function isNPCUpForPlayerFaction(mapid, npcid)
    return rareDB[mapid].rares[npcid].faction == rareDB[mapid].warfrontControlledByFaction or rareDB[mapid].rares[npcid].faction == "all"
end

local function isQuestCompleted(mapid, npcid)
    local rare = rareDB[mapid].rares[npcid]
    if rare.questId[1] == 0 then
        return false
    else
        for k, v in pairs(rare.questId) do
            if IsQuestFlaggedCompleted(rare.questId[k]) then
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
        if rare.type == "WorldBoss" then
            return colorText(rare.name, WarfrontRareTracker.db.profile.colors.worldboss)
        elseif rare.type == "Elite" then
            return colorText(rare.name, WarfrontRareTracker.db.profile.colors.elite)
        elseif rare.type == "Rare" then
            return colorText(rare.name, WarfrontRareTracker.db.profile.colors.rare)
        elseif rare.type == "Goliath" then
            return colorText(rare.name, WarfrontRareTracker.db.profile.colors.goliath)
        else
            return colorText(rare.name, colors.white)
        end
    else
        return colorText(rare.name, colors.white)
    end
end

local function getColoredStatusText(mapid, npcid)
    if not isPlayerMaxZoneLevel(mapid) then
        return colorText("Level "..rareDB[mapid].zonelevel, colors.orange)
    end
    local rare = rareDB[mapid].rares[npcid]
    if rare.questId[1] == 0 then
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
    local rare = rareDB[mapid].rares[npcid]
    if WarfrontRareTracker.db.profile.colors.colorizeDrops and rare.isKnown then
        return colorText(rare.drop, WarfrontRareTracker.db.profile.colors.knownColor)
    elseif WarfrontRareTracker.db.profile.colors.colorizeDrops and not rare.isKnown then
        return colorText(rare.drop, WarfrontRareTracker.db.profile.colors.unknownColor)
    else
        return rare.drop
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

            local prefix = factionControlling == getPlayerFaction() and "Good" or "Bad"
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
        C_Timer.After(5, function() checkWarfrontControl() end)
    end
end

local function showRare(mapid, npcid, worldmap)
    if isNPCPlayerFaction(mapid, npcid) then
        if worldmap ~= nil and worldmap == true then
            if WarfrontRareTracker.db.profile.worldmapicons.showOnlyAtMaxLevel and playerLevel ~= PLAYER_MAXLEVEL then
                return false
            end
            if WarfrontRareTracker.db.profile.worldmapicons.hideIconWhenDefeated and isQuestCompleted(mapid, npcid) or WarfrontRareTracker.db.profile.worldmapicons.hideGoliaths and rareDB[mapid].rares[npcid].type == "Goliath" then
                return false
            elseif WarfrontRareTracker.db.profile.worldmapicons.hideAlreadyKnown and rareDB[mapid].rares[npcid].isKnown then
                if WarfrontRareTracker.db.profile.worldmapicons.whitelist[rareDB[mapid].rares[npcid].drop] == true then
                    return true
                else
                    return false
                end
            else
                return true
            end
        else
            if WarfrontRareTracker.db.profile.menu.hideGoliaths and rareDB[mapid].rares[npcid].type == "Goliath" then
                return false
            elseif WarfrontRareTracker.db.profile.menu.hideAlreadyKnown and rareDB[mapid].rares[npcid].isKnown then
                if WarfrontRareTracker.db.profile.menu.whitelist[rareDB[mapid].rares[npcid].drop] == true then
                    return true
                else
                    return false
                end
            else
                return true
            end
        end
    else
        return false
    end
end

local function scanForKnownItems()
    if newPetAdedTimer then
        WarfrontRareTracker:CancelTimer(newPetAdedTimer)
        newPetAdedTimer = nil
    end
    for mapid, content in pairs(rareDB) do
        for k, rare in pairs(content.rares) do
            if rare.drop == "Mount" and rare.mountID and rare.mountID ~= 0 then
                local name, spellId, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(rare.mountID)
                if isCollected then
                    rare.isKnown = true
                end
            elseif rare.drop == "Toy" and rare.itemID ~= 0 then
                if PlayerHasToy(rare.itemID) then
                    rare.isKnown = true
                end
            elseif rare.drop == "Pet" then
                local number, _ = C_PetJournal.GetNumCollectedInfo(rare.speciesID);
                if number >= 1 then
                    rare.isKnown = true
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
                if isPlayerMaxZoneLevel(mapid) then
                    canSchedule = true
                    if factionControlling ~= getPlayerFaction() then
                        local state, percentage, timeNextChange = getWarfrontProgressInfo()
                        if state ~= nil and state == 1 and percentage ~= nil then
                            scheduleState = 1
                            brokerText = colorText("Gathering: ", colors.turqoise) .. getColoredPercentage(percentage)
                        elseif state ~= nil and state == 2 and timeNextChange ~= nil then
                            scheduleState = 2
                            brokerText = colorText("Scenario: ", colors.turqoise) .. getColoredTimeLeft(timeNextChange, true)
                        else 
                            scheduleState = 3
                            brokerText = colorText("Waiting", colors.turqoise)
                        end
                    else
                        factionControlling = rareDB[getPlayerSelectedZone()].warfrontControlledByFaction == FACTION_HORDE and colorText(FACTION_HORDE, colors.red) or colorText(FACTION_ALLIANCE, colors.blue)
                        brokerText = factionControlling .. colorText(" Has Control", colors.turqoise)
                        canSchedule = false
                    end
                else
                    brokerText = "Level too low"
                end
            else
                brokerText = "No Status Info"
            end
        elseif WarfrontRareTracker.db.profile.broker.brokerText == "allstatus" then
            if hasDBContributionInfo() then
                canSchedule = true
                local oppositeFaction = rareDB[getPlayerSelectedZone()].warfrontControlledByFaction == FACTION_HORDE and colorText("(A) ", colors.blue) or colorText("(H) ", colors.red)
                local state, percentage, timeNextChange = getWarfrontProgressInfo()
                if state ~= nil and state == 1 and percentage ~= nil then
                    scheduleState = 1
                    brokerText = oppositeFaction .. colorText("Gathering: ", colors.turqoise) .. getColoredPercentage(percentage)
                elseif state ~= nil and state == 2 and timeNextChange ~= nil then
                    scheduleState = 2
                    brokerText = oppositeFaction .. colorText("Scenario: ", colors.turqoise) .. getColoredTimeLeft(timeNextChange, true)
                else
                    scheduleState = 3
                    factionControlling = factionControlling == FACTION_HORDE and colorText(FACTION_HORDE, colors.red) or colorText(FACTION_ALLIANCE, colors.blue)
                    brokerText = factionControlling .. colorText(" Has Control!!", colors.turqoise)
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

local function playerLeveledUp(newLevel)
    playerLevel = newLevel

    if newLevel == PLAYER_MAXLEVEL and WarfrontRareTracker.db.profile.general.enableLevelUpSound then
        playSound("good")
    end
    if newLevel == PLAYER_MAXLEVEL and WarfrontRareTracker.db.profile.general.enableLevelUpChatMessage then
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
    WarfrontRareTracker:ZONE_CHANGED()
    scanForKnownItems()
    self:UpdateAllWorldMapIcons()
    updateBrokerText()
    WarfrontRareTracker:SortRares()
    C_Timer.After(10, function() WarfrontRareTracker:RefreshAllData() end)
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
    self:RegisterBucketEvent("SHOW_LOOT_TOAST", 2, "BUCKET_ON_LOOT_RECEIVED")
    self:RegisterBucketEvent("SHOW_LOOT_TOAST_UPGRADE", 2,"BUCKET_ON_LOOT_RECEIVED")
    self:RegisterBucketEvent("TOYS_UPDATED", 2,"TOYS_UPDATED")
    self:RegisterBucketEvent("CONTRIBUTION_COLLECTOR_UPDATE_SINGLE", 30, "CONTRIBUTION_COLLECTOR_UPDATE_SINGLE") -- maybe 1 min.
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
    self:UnregisterBucket("SHOW_LOOT_TOAST")
    self:UnregisterBucket("SHOW_LOOT_TOAST_UPGRADE")
    self:UnregisterBucket("TOYS_UPDATED")
    self:UnregisterBucket("CONTRIBUTION_COLLECTOR_UPDATE_SINGLE")
    -- Delete Worldmap Icons
    self:DeleteAllWorldmapIcons()
end

----------------
-- Events
----------------
-- Event Handler
function WarfrontRareTracker:OnEvent(event, ...)
    if event == "NEW_MOUNT_ADDED" then
        scanForKnownItems()
    elseif event == "NEW_PET_ADDED" then
        if newPetAdedTimer == nil then
            newPetAdedTimer = self:ScheduleTimer(function() scanForKnownItems() end, 5)
        end
    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        if newLevel == PLAYER_MAXLEVEL then
            C_Timer.After(5, function() playerLeveledUp(newLevel) end)
        end
    end
end

----------------
-- Normal Events
function WarfrontRareTracker:PLAYER_ENTERING_WORLD()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    playerLevel = UnitLevel("player")
    checkWarfrontControl()
    C_Timer.After(5, function() WarfrontRareTracker:DelayedInitialize(false) end)
end

----------------
-- Bucket events
function WarfrontRareTracker:BUCKET_ON_LOOT_RECEIVED()
    if isSessionLocked("BUCKET_ON_LOOT_RECEIVED") then
        return
    end
    C_Timer.After(4, function() WarfrontRareTracker:CheckAndUpdateZoneWorldMapIcons("LootTimer") end)
end

function WarfrontRareTracker:ZONE_CHANGED()
    local oldMapid = currentPlayerMapid
    local currentMapID = C_Map.GetBestMapForUnit("player")
    if currentMapID ~= currentPlayerMapid then
        currentPlayerMapid = currentMapID
        local mapFileName = C_Map.GetMapInfo(currentMapID)
        for k, v in pairs(mapFileName) do
        end
        self:CheckMapChange(oldMapid)
    end
end

function WarfrontRareTracker:TOYS_UPDATED()
    scanForKnownItems()
end

function WarfrontRareTracker:CONTRIBUTION_COLLECTOR_UPDATE_SINGLE() -- This got fired on faction change and percentage. NOTE this got spammed on percentage, so it's a Bucket event with a delay of 30 seconds.
    for mapid, v in pairs(rareDB) do
        if isWarfrontFactionChanged(mapid) then
            checkWarfrontControl(mapid)
        end
    end
end

----------
-- Refresh
----------
function WarfrontRareTracker:RefreshMinimap()
    LibStub("LibDBIcon-1.0"):Refresh("WarfrontRareTracker", self.db.profile.minimap)
end

function WarfrontRareTracker:RefreshConfig()
    self:ConfigChangeCheck()
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

---------------
-- Tooltips
---------------
-- Menu Tooltip
function WarfrontRareTracker:MenuOnClick(self, button)
    if button == "RightButton" then
        LibStub("AceConfigDialog-3.0"):Open("WarfrontRareTracker")
    elseif button == "LeftButton" then
        if not WarfrontRareTracker.db.profile.menu.hideOnCombat or WarfrontRareTracker.db.profile.menu.hideOnCombat and not UnitAffectingCombat("player") then
            if WarfrontRareTracker.db.profile.menu.showMenuOn == "click" and not WarfrontRareTracker.db.profile.menu.showAtMaxLevel or WarfrontRareTracker.db.profile.menu.showAtMaxLevel and playerLevel == PLAYER_MAXLEVEL then
                if menuTooltip == nil then
                    WarfrontRareTracker:ShowMenu(self)
                else
                    WarfrontRareTracker:MenuOnLeave()
                end
            end
        end
    end
end

function WarfrontRareTracker:MenuOnEnter(self)
    if not WarfrontRareTracker.db.profile.menu.hideOnCombat or WarfrontRareTracker.db.profile.menu.hideOnCombat and not UnitAffectingCombat("player") then
        if WarfrontRareTracker.db.profile.menu.showMenuOn == "mouse" and not WarfrontRareTracker.db.profile.menu.showAtMaxLevel or WarfrontRareTracker.db.profile.menu.showAtMaxLevel and playerLevel == PLAYER_MAXLEVEL then
            WarfrontRareTracker:ShowMenu(self)
        end
    end
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

    if WarfrontRareTracker.db.profile.menu.showWarfrontOnTitle then
        menuTooltip:SetLineScript(line, "OnEnter", function(self) WarfrontRareTracker:WarfrontStatusTooltipOnEnter(self) end)
        menuTooltip:SetLineScript(line, "OnLeave", function() WarfrontRareTracker:WarfrontStatusTooltipOnleave() end)
    end

    line = menuTooltip:AddLine()
    menuTooltip:SetCell(line, 1, " ", nil, "LEFT", 3)

    WarfrontRareTracker:ShowMenuWarfrontSelection(mapid, menuTooltip)

    line = menuTooltip:AddLine()
    menuTooltip:SetCell(line, 1, " ", nil, "LEFT", 3)

    line = menuTooltip:AddHeader()
    menuTooltip:SetCell(line, 1, "Rare")
    menuTooltip:SetCell(line, 2, "Drops", nil, "LEFT", 1, LibQTip.LabelProvider, 20, nil, 100, 100)
    menuTooltip:SetCell(line, 3, "Status")
    menuTooltip:AddSeparator()

    for k, npcid in pairs(sortedRareDB[mapid]) do
        if showRare(mapid, npcid, false) then
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
        print("isWarfrontSelectionMenuCollapsed = true")
        oldSelectedZone = WarfrontRareTracker.db.char.selectedZone
        isWarfrontSelectionMenuCollapsed = false
    else
        print("isWarfrontSelectionMenuCollapsed = false")
        WarfrontRareTracker.db.char.selectedZone = mapid
        if oldSelectedZone ~= nil or oldSelectedZone ~= mapid then
            print("Zone Changed")
            WarfrontRareTracker:SetTimestamp(true)
            oldSelectedZone = nil
        else
            print("Something went wrong!")
        end
        isWarfrontSelectionMenuCollapsed = true
    end
    WarfrontRareTracker:UpdateMenuToolTip(menuTooltip)
end

function WarfrontRareTracker:MenuWarfrontSelectionTooltipOnLeave()
    if menuSelectTooltip then
        LibQTip:Release(menuSelectTooltip)
        menuSelectTooltip = nil
    end
end

function WarfrontRareTracker:MenuWarfrontSelectionTooltipOnEnter(self)
    if LibQTip:IsAcquired("WarfrontRareTrackerMenuSelectTip") and menuSelectTooltip then
        LibQTip.Release(menuSelectTooltip)
        menuSelectTooltip = nil
    end
    menuSelectTooltip = LibQTip:Acquire("WarfrontRareTrackerMenuSelectTip", 1, "LEFT")
    menuSelectTooltip:ClearAllPoints()
    menuSelectTooltip:SetClampedToScreen(true)
    menuSelectTooltip:SetPoint("TOPRIGHT", self, "LEFT", -15, 17)

    local line = menuSelectTooltip:AddHeader()
    menuSelectTooltip:SetCell(line, 1, colorText("Click to select different Warfront", colors.yellow), menuSelectTooltip:GetHeaderFont())

    menuSelectTooltip:Show()
end

function WarfrontRareTracker:ShowMenuWarfrontSelection(mapid, tooltip)
    local line
    if isWarfrontSelectionMenuCollapsed and getBDSize(rareDB) <= 1 then
        line = tooltip:AddHeader()
        tooltip:SetCell(line, 1, colorText(rareDB[mapid].zonename, colors.lightcyan), tooltip:GetHeaderFont(), "CENTER", 3)
    elseif isWarfrontSelectionMenuCollapsed and getBDSize(rareDB) > 1 then
        line = tooltip:AddHeader()
        tooltip:SetCell(line, 1, colorText(rareDB[mapid].zonename, colors.lightcyan), tooltip:GetHeaderFont(), "CENTER", 3)
        tooltip:SetLineScript(line, "OnEnter", function(self) WarfrontRareTracker:MenuWarfrontSelectionTooltipOnEnter(self) end)
        tooltip:SetLineScript(line, "OnLeave", function() WarfrontRareTracker:MenuWarfrontSelectionTooltipOnLeave() end)
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
        
    local rare = rareDB[mapid].rares[npcid]
    if rare.itemID ~= 0 then
        local itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(rare.itemID)

        if itemTexture ~= nil then
            lootTooltip:AddHeader(itemLink or itemName, "|T" .. itemTexture .. ":22|t")
        else
            lootTooltip:AddHeader(itemLink or itemName)
        end
        
        npcToolTip:SetItemByID(rare.itemID)
        for i = 2, npcToolTip:NumLines() do
            local tooltipLine =  _G["__WarfrontRareTracker_ScanTipTextLeft" .. i]
            local text = tooltipLine:GetText()
            local color = {}
            color[1], color[2], color[3], color[4] = tooltipLine:GetTextColor()

            if string.len(text) > 1 then
                local line = lootTooltip:AddLine()
                lootTooltip:SetCell(line, 1, colorText(text, color), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 200)
            end
        end

        if rare.note then
            line = lootTooltip:AddLine()
            lootTooltip:SetCell(line, 1, " ", nil, nil, 2)
            line = lootTooltip:AddLine()
            lootTooltip:SetCell(line, 1, colorText("Note: ", colors.yellow) .. colorText(rare.note, colors.grey), nil, nil, 2)
        end

        if lootTooltip:GetLineCount() > 1 then
            lootTooltip:Show()
        end
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
    local line
    warfrontStatusTooltip = LibQTip:Acquire("WarfrontRareTrackerWarfrontStatusTip", 3, "LEFT", "LEFT", "LEFT")
    warfrontStatusTooltip:ClearAllPoints()
    warfrontStatusTooltip:SetClampedToScreen(true)
    warfrontStatusTooltip:SetPoint("TOPRIGHT", self, "LEFT", -15, 17)

    WarfrontRareTracker:WarfrontStatusInfoTooltip(false)

    if warfrontStatusTooltip:GetLineCount() > 3 then
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
        if zoneState == 1 and zonePercentage ~= nil then
            line = tooltip:AddLine()
            tooltip:SetCell(line, 1, oppositeFaction .. colorText(" Status:", colors.yellow))
            tooltip:SetCell(line, 2, colorText(rareDB[mapid].gatheringname, colors.turqoise), nil, nil, 2)

            line = tooltip:AddLine()
            tooltip:SetCell(line, 1, colorText("Progress:", colors.yellow))
            tooltip:SetCell(line, 2, getColoredPercentage(zonePercentage), nil, nil, 2)
        elseif zoneState == 2 and zoneTimeNextChange ~= nil then
            line = tooltip:AddLine()
            tooltip:SetCell(line, 1, oppositeFaction .. colorText(" Status:", colors.yellow))
            tooltip:SetCell(line, 2, colorText(rareDB[mapid].scenarioname, colors.turqoise), nil, nil, 2)

            line = tooltip:AddLine()
            tooltip:SetCell(line, 1, colorText("Time Left:", colors.yellow))
            tooltip:SetCell(line, 2, getColoredTimeLeft(zoneTimeNextChange, false), nil, nil, 2)
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
    if warfrontStatusTooltip and WarfrontRareTracker.db.profile.menu.showWarfrontOnTitle and WarfrontRareTracker.db.profile.menu.showWarfrontTitle == "current" then -- and hasDBContributionInfo() then
        updateWarfrontStatusInfoTooltip(warfrontStatusTooltip, getPlayerSelectedZone(), inmenu)
    elseif warfrontStatusTooltip and WarfrontRareTracker.db.profile.menu.showWarfrontOnTitle and WarfrontRareTracker.db.profile.menu.showWarfrontTitle == "all" then
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
    local rare = rareDB[mapid].rares[npcid]
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

function WarfrontRareTracker:WorldmapTooltipOnEnter(self, mapid, npcid, NPC)
    if LibQTip:IsAcquired("WarfrontRareTrackerWorldmapTip") and worldmapTooltip then
        LibQTip.Release(worldmapTooltip)
        worldmapTooltip = nil
    end
    worldmapTooltip = LibQTip:Acquire("WarfrontRareTrackerWorldmapTip", 2, "LEFT", "RIGHT")
    worldmapTooltip:ClearAllPoints()
    worldmapTooltip:SetClampedToScreen(true)
    worldmapTooltip:SetPoint("TOPRIGHT", self, "BOTTOM")

    local line
    local name
    local rare = rareDB[mapid].rares[npcid]
    if NPC then
        name = rare.name
        if rare.type == "WorldBoss" or rare.type == "Elite" or rare.type == "Goliath" then
            name = colorText(name, colors.purple)
        else
            name = colorText(name, colors.blue)
        end
        worldmapTooltip:AddHeader(name)

        line = worldmapTooltip:AddLine()
        worldmapTooltip:SetCell(line, 1, colorText("Drop: ", colors.yellow), nil, nil, 2)
        if rare.itemID ~= 0 then
            local itemName, itemLink, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(rare.itemID)

            if itemTexture ~= nil then
                worldmapTooltip:AddHeader(itemLink or itemName, "|T" .. itemTexture .. ":22|t")
            else
                worldmapTooltip:AddHeader(itemLink or itemName)
            end
            
            npcToolTip:SetItemByID(rare.itemID)
            for i = 2, npcToolTip:NumLines() do
                local tooltipLine =  _G["__WarfrontRareTracker_ScanTipTextLeft" .. i]
                local text = tooltipLine:GetText()
                local color = {}
                color[1], color[2], color[3], color[4] = tooltipLine:GetTextColor()
                --print("text: "..text.."  R: "..color[1].."  G: "..color[2].."  B: "..color[3])

                if string.len(text) > 1 then
                    local line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, colorText(text, color), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 200)
                end
            end
            if rare.note then
                line = worldmapTooltip:AddLine()
                worldmapTooltip:SetCell(line, 1, " ", nil, nil, 2)
                line = worldmapTooltip:AddLine()
                worldmapTooltip:SetCell(line, 1, colorText("Note: ", colors.yellow) .. colorText(rare.note, colors.grey), nil, nil, 2)
            end
        else
            worldmapTooltip:AddHeader("No know drop")
        end
        if worldmapTooltip:GetLineCount() > 1 then
            worldmapTooltip:Show()
        end
    else
        name = rare.name
        worldmapTooltip:AddLine(colorText("Cave entrance for: "..name, colors.yellow))
        worldmapTooltip:Show()
    end
end

-----------------
-- Worldmap Icons
-----------------
local pinCache = {}
local PinCount = 0
local function getNewWorldmapPin()
    local worldmapIcon = next(pinCache)
    if worldmapIcon then
		pinCache[worldmapIcon] = nil
		return worldmapIcon
    end
    PinCount = PinCount + 1
    worldmapIcon = CreateFrame("Button", "WarfrontPin"..PinCount, WorldMap)
    worldmapIcon:SetFrameLevel(5)
	worldmapIcon:EnableMouse(true)
	worldmapIcon:SetWidth(12)
	worldmapIcon:SetHeight(12)
	worldmapIcon:SetPoint("CENTER", Worldmap, "CENTER")
	local texture = worldmapIcon:CreateTexture(nil, "OVERLAY")
	worldmapIcon.texture = texture
	texture:SetAllPoints(worldmapIcon)
	worldmapIcon:RegisterForClicks("AnyUp")
	worldmapIcon:SetMovable(true)
    worldmapIcon:Hide()
	return worldmapIcon
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
end

local function deleteAllPins()
    for mapid, content in pairs(rareDB) do
        deleteZonePins(mapid)
    end
end

function WarfrontRareTracker:DeleteAllWorldmapIcons()
    deleteAllPins()
end

function WarfrontRareTracker:CheckAndUpdateZoneWorldMapIcons(event)
    if not isPlayerMaxZoneLevel() then
        return
    end
    if event == nil then event = "Unknown" end
    local inInstance, _ = IsInInstance()
    if inInstance == false then
        local mapid = currentPlayerMapid
        if self.db.profile.worldmapicons.hideIconWhenDefeated and rareDB[mapid] then
            for k, icon in pairs(rareDB[mapid].worldmapIcons) do
                local npcid = icon.npcid
                local mapid = icon.mapid
                if isQuestCompleted(mapid, npcid) then
                    HBDPins:RemoveWorldMapIcon("WarfrontRareTracker"..rareDB[mapid].zonename, icon)
                    recyclePin(icon)
                    rareDB[mapid].worldmapIcons[k] = nil
                end
            end
        end
    end
end

function WarfrontRareTracker:UpdateAllWorldMapIcons()
    deleteAllPins()
    if self.db.profile.worldmapicons.showWorldmapIcons then
        for mapid, content in pairs(rareDB) do
            for k, rare in pairs(content.rares) do
                local npcid = rare.npcid
                if showRare(mapid, npcid, true) then
                    WarfrontRareTracker:PlaceWorldmapNPCIcon(mapid, npcid)
                        if rare.cave then
                            WarfrontRareTracker:PlaceWorldmapCaveIcon(mapid, npcid, rare.cave)
                        end
                end
            end
        end
    end
end

function WarfrontRareTracker:UpdateZoneWorldMapIcons(mapid)
    if mapid == nil then return end
    deleteZonePins(mapid)
    if self.db.profile.worldmapicons.showWorldmapIcons then
        if rareDB[mapid] then
            for k, rare in pairs(rareDB[mapid].rares) do
                local npcid = rare.npcid
                if showRare(mapid, npcid, true) then
                    WarfrontRareTracker:PlaceWorldmapNPCIcon(mapid, npcid)
                    if rare.cave then
                        WarfrontRareTracker:PlaceWorldmapCaveIcon(mapid, npcid, rare.cave)
                    end
                end
            end
        end
    end
end

function WarfrontRareTracker:PlaceWorldmapNPCIcon(mapid, npcid)
    local rare = rareDB[mapid].rares[npcid]
    local icon = getNewWorldmapPin()
    icon:SetParent(WorldMap)
    icon:SetHeight(13)
    icon:SetWidth(13)
    icon:SetAlpha(1)
    local t = icon.texture
    t:SetTexCoord(0, 1, 0, 1)
    t:SetVertexColor(1, 1, 1, 1)
    if rare.type == "WorldBoss" or rare.type == "Elite" then
        icon:SetHeight(15)
        icon:SetWidth(15)
        t:SetTexture("Interface\\Worldmap\\GlowSkull_64Purple")
    elseif rare.type == "Goliath" then
        t:SetTexture("Interface\\Worldmap\\Skull_64Grey")
    else
        t:SetTexture("Interface\\Worldmap\\GlowSkull_64Blue")
    end
    icon.npcid = npcid
    icon.mapid = mapid
    icon:SetScript("OnClick", function(self) WarfrontRareTracker:WorldmapTooltipOnClick(self, icon.mapid, icon.npcid) end)
    icon:SetScript("OnEnter", function(self) WarfrontRareTracker:WorldmapTooltipOnEnter(self, icon.mapid, icon.npcid, true) end)
    icon:SetScript("OnLeave", function() WarfrontRareTracker:WorldmapTooltipOnLeave() end)
    local coord = rare.coord[1]
    if #rare.coord > 1 and rareDB[mapid].warfrontControlledByFaction == FACTION_HORDE then
        coord = rare.coord[2]
    end
    local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
    table.insert(rareDB[mapid].worldmapIcons, icon)
    HBDPins:AddWorldMapIconMap("WarfrontRareTracker"..rareDB[mapid].zonename, icon, mapid, x, y, 1)
end

function WarfrontRareTracker:PlaceWorldmapCaveIcon(mapid, npcid, caveCoord)
    local icon = getNewWorldmapPin()
    icon:SetParent(WorldMap)
    icon:SetHeight(13)
    icon:SetWidth(13)
    icon:SetAlpha(1)
    local t = icon.texture
    t:SetTexCoord(0, 1, 0, 1)
    t:SetVertexColor(1, 1, 1, 1)
    t:SetTexture("Interface\\MINIMAP\\Suramar_Door_Icon")
    icon.npcid = npcid
    icon.mapid = mapid
    icon:SetScript("OnEnter", function(self) WarfrontRareTracker:WorldmapTooltipOnEnter(self, icon.mapid, icon.npcid, false) end)
    icon:SetScript("OnLeave", function() WarfrontRareTracker:WorldmapTooltipOnLeave() end)
    local coord = caveCoord[1]
    if #caveCoord > 1 and rareDB[mapid].warfrontControlledByFaction == FACTION_HORDE then
        coord = caveCoord[2]
    end
    local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
    table.insert(rareDB[mapid].worldmapIcons, icon)
    HBDPins:AddWorldMapIconMap("WarfrontRareTracker"..rareDB[mapid].zonename, icon, mapid, x, y, 1)
end

----------------
-- NPC UnitFrame
----------------
GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    if WarfrontRareTracker.db.profile.unitframe.enableUnitframeIntegration == false then
        return
    end

    local name, unit = self:GetUnit()
    if not unit then 
        return
    end
    local creatureType = UnitCreatureType(unit)
    if creatureType == "Critter" or creatureType == "Non-combat Pet" or creatureType == "Wild Pet" then
        return
    end
    local guid = UnitGUID(unit)
    if not unit or not guid then return end
    if not UnitCanAttack("player", unit) then return end -- Something you can't attack
    if UnitIsPlayer(unit) then return end -- A player
    if UnitIsPVP(unit) then return end -- A PVP flagged unit

    local mapid = currentPlayerMapid
        local npcid = getNPCIDFromGUID(guid)
        if rareDB[mapid] then
        local rare = rareDB[mapid].rares[npcid]
        if rare and type(rare) == "table" and isNPCPlayerFaction(mapid, npcid) then
            if WarfrontRareTracker.db.profile.unitframe.compactMode then
                local text = ""
                if WarfrontRareTracker.db.profile.unitframe.showStatus then
                    text = text .. colorText("Warfront Rare Tracker: ", colors.yellow) .. getColoredStatusText(mapid, npcid) .. "\n"
                else
                    text = text .. colorText("Warfront Rare Tracker: ", colors.yellow) .. "\n"
                end
                if WarfrontRareTracker.db.profile.unitframe.showDrop and rare.itemID == 0 then
                    text = text .. "Nothing"
                elseif WarfrontRareTracker.db.profile.unitframe.showDrop and rare.itemID ~= 0 then
                    local itemName, itemLink, itemRarity, _, _, itemType, _, _, _, _, _ = GetItemInfo(rare.itemID)
                    if itemLink or itemName then
                        text = text .. (itemLink or itemName) .. " "
                    end
                end
                -- Ignore Goliaths
                if rare.type ~= "Goliath" and WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and rare.isKnown then
                    text = text .. colorText(rare.drop .. " already known", colors.red)
                elseif rare.type ~= "Goliath" and WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and not rare.isKnown then
                    text = text .. colorText(rare.drop .. " still needed", colors.green)
                end
                -- Ignore Drop: Item (if needed with a new Warfront)
                -- if rare.drop ~= "Item" and WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and rare.isKnown then
                --     text = text .. colorText(rare.drop .. " already known", colors.red)
                -- elseif rare.drop ~= "Item" and WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and not rare.isKnown then
                --     text = text .. colorText(rare.drop .. " still needed", colors.green)
                -- end

                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(text)
            else
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(colorText("Warfront Rare Tracker:", colors.yellow))
                if WarfrontRareTracker.db.profile.unitframe.showStatus then
                    GameTooltip:AddLine(colorText("Status: ", colors.yellow) .. getColoredStatusText(mapid, npcid))
                end
                if WarfrontRareTracker.db.profile.unitframe.showDrop and rare.itemID ~= 0 then
                    local itemName, itemLink, itemRarity, _, _, itemType, _, _, _, _, _ = GetItemInfo(rare.itemID)
                    if itemLink or itemName then
                        GameTooltip:AddLine(colorText("Drops " .. rare.drop .. ": ", colors.yellow) .. (itemLink or itemName))
                    end
                elseif WarfrontRareTracker.db.profile.unitframe.showDrop and rare.itemID == 0 then
                    GameTooltip:AddLine(colorText("Drops: ", colors.yellow) .. colorText("Nothing", colors.white))
                end
                -- Ignore Goliaths
                if rare.type ~= "Goliath" and WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and rare.isKnown then
                    GameTooltip:AddLine(colorText(rare.drop .. " already known", colors.red))
                elseif rare.type ~= "Goliath" and WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and not rare.isKnown then
                    GameTooltip:AddLine(colorText(rare.drop .. " still needed", colors.green))
                end
                -- Ignore Drop: Item (if needed with a new Warfront)
                -- if rare.drop ~= "Item" and WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and rare.isKnown then
                --     GameTooltip:AddLine(colorText(rare.drop .. " already known", colors.red))
                -- elseif rare.drop ~= "Item" and WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown and not rare.isKnown then
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
    if WarfrontRareTracker.db.profile.menu.sortAscending == "true" then
        return a:upper() < b:upper()
    else
        return a:upper() > b:upper()
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
                        if v.type ~= "WorldBoss" then
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
                            if (compareString(normalTable[j].type, normalTable[min].type)) or (normalTable[j].type == normalTable[min].type and compareString(normalTable[j].drop, normalTable[min].drop)) or (normalTable[j].type == normalTable[min].type and normalTable[j].drop == normalTable[min].drop and compareString(normalTable[j].name, normalTable[min].name)) then min = j end
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
                            if (compareString(tempTable[j].type, tempTable[min].type)) or (tempTable[j].type == tempTable[min].type and compareString(tempTable[j].drop, tempTable[min].drop)) or (tempTable[j].type == tempTable[min].type and tempTable[j].drop == tempTable[min].drop and compareString(tempTable[j].name, tempTable[min].name)) then min = j end
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
                    if type(v) == "table" and v.drop and v.type then
                        if v.type ~= "WorldBoss" then
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
                            if (compareString(normalTable[j].drop, normalTable[min].drop)) or (normalTable[j].drop == normalTable[min].drop and compareString(normalTable[j].type, normalTable[min].type)) or (normalTable[j].drop == normalTable[min].drop and normalTable[j].type == normalTable[min].type and compareString(normalTable[j].name, normalTable[min].name)) then min = j end
                        else
                            if (compareString(normalTable[j].drop, normalTable[min].drop)) or (normalTable[j].drop == normalTable[min].drop and compareString(normalTable[j].name, normalTable[min].name)) then min = j end
                        end
                    end
                    normalTable[i], normalTable[min] = normalTable[min], normalTable[i]
                end
            else
                for k, v in pairs(contents.rares) do
                    if type(v) == "table" and v.drop then
                        n = n + 1
                        tempTable[n] = v
                    end
                end
                for i = 1, n, 1 do
                    min = i
                    for j = i + 1, n, 1 do
                        if WarfrontRareTracker.db.profile.menu.groupDropSortOn == "type" then
                            if (compareString(tempTable[j].drop, tempTable[min].drop)) or (tempTable[j].drop == tempTable[min].drop and compareString(tempTable[j].type, tempTable[min].type)) or (tempTable[j].drop == tempTable[min].drop and tempTable[j].type == tempTable[min].type and compareString(tempTable[j].name, tempTable[min].name)) then min = j end
                        else
                            if (compareString(tempTable[j].drop, tempTable[min].drop)) or (tempTable[j].drop == tempTable[min].drop and compareString(tempTable[j].name, tempTable[min].name)) then min = j end
                        end
                    end
                    tempTable[i], tempTable[min] = tempTable[min], tempTable[i]
                end
            end
        elseif WarfrontRareTracker.db.profile.menu.sortRaresOn == "name" then
            if WarfrontRareTracker.db.profile.menu.worldbossOnTop then
                for k, v in pairs(contents.rares) do
                    if type(v) == "table" and v.name and v.type then
                        if v.type ~= "WorldBoss" then
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
