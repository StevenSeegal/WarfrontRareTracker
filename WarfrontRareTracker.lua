WarfrontRareTracker = LibStub("AceAddon-3.0"):NewAddon("WarfrontRareTracker", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("WarfrontRareTracker")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1");
local MinimapIcon = LibStub("LibDBIcon-1.0")

local LibQTip = LibStub("LibQTip-1.0")
local HBDPins = LibStub("HereBeDragons-Pins-2.0")

local npcToolTip = CreateFrame("GameTooltip", "__WarfrontRareTracker_ScanTip", nil, "GameTooltipTemplate")
npcToolTip:SetOwner(WorldFrame, "ANCHOR_NONE")

local worldmapIcons = {}
local worldmapIconsCount = 0

WarfrontRareTracker.WR = {}
local WR = WarfrontRareTracker.WR

WR.rares = {
    [138122] = { name = L["dooms_howl"], id = 138122, questId = { 53002 }, type = "WorldBoss", drop = "Toy", itemID = 163828, faction = "Alliance", coord = { 38624096 }, note = "Alliance only", sort = 1, isKnown = false },
    [137374] = { name = L["the_lions_roar"], id = 137374, questId = { 53001 }, type = "WorldBoss", drop = "Toy", itemID = 163829, faction = "Horde", coord = { 38624096 }, note = "Horde only", sort = 2, isKnown = false },
    [141618] = { name = L["cresting_goliath"], id = 141618, questId = { 53018, 53531 }, type = "Goliath", drop = "Item", itemID = 163700, faction = "all", coord = { 62093158 }, sort = 3, isKnown = false },
    [141615] = { name = L["burning_goliath"], id = 141615, questId = { 53017, 53506 }, type = "Goliath", drop = "Item", itemID = 163691, faction = "all", coord = { 30664478 }, sort = 4, isKnown = false },
    [141620] = { name = L["rumbling_goliath"], id = 141620, questId = { 53021, 53523 }, type = "Goliath", drop = "Item", itemID = 163701, faction = "all", coord = { 29885974 }, sort = 5, isKnown = false },
    [141616] = { name = L["thundering_goliath"], id = 141616, questId = { 53023, 53527 }, type = "Goliath", drop = "Item", itemID = 163698, faction = "all", coord = { 46325212 }, sort = 6, isKnown = false },
    [142709] = { name = L["beastrider_kama"], id = 142709, questId = { 53083, 53504 }, type = "Rare", drop = "Mount", itemID = 163644, mountID = 1180, faction = "all", coord = { 65347116 }, sort = 7, isKnown = false },
    [142692] = { name = L["nimar_the_slayer"], id = 142692, questId = { 53091, 53517 }, type = "Rare", drop = "Mount", itemID = 163706, mountID = 1185, faction = "all", coord = { 67616086 }, sort = 8, isKnown = false },
    [142423] = { name = L["overseer_krix"], id = 142423, questId = { 53014, 53518 }, type = "Elite", drop = "Mount", itemID = 163646, mountID = 1182, faction = "all", coord = { 32923847, 27405722 }, cave = { 33693676, 27385601 }, note = "Inside cave", sort = 9, isKnown = false },
    [142437] = { name = L["skullripper"], id = 142437, questId = { 53022, 53526 }, type = "Elite", drop = "Mount", itemID = 163645, mountID = 1183, faction = "all", coord = { 57154575 }, sort = 10, isKnown = false },
    [142739] = { name = L["knight_captain_aldrin"], id = 142739, questId = { 53088 }, type = "Rare", drop = "Mount", itemID = 163578, mountID = 1173, faction = "Horde", coord = { 48894001 }, note = "Horde only", sort = 11, isKnown = false },
    [142741] = { name = L["doomrider_helgrim"], id = 142741, questId = { 53085 }, type = "Rare", drop = "Mount", itemID = 163579, mountID = 1174, faction = "Alliance", coord = { 53565764 }, note = "Alliance only", sort = 12, isKnown = false },
    [142508] = { name = L["branchlord_aldrus"], id = 142508, questId = { 53013, 53505 }, type = "Elite", drop = "Pet", itemID = 163650, petID = 143503, speciesID = 2433, faction = "all", coord = { 22602135 }, sort = 13, isKnown = false },
    [142688] = { name = L["darbel_montrose"], id = 142688, questId = { 53084, 53507 }, type = "Rare", drop = "Pet", itemID = 163652, petID = 143507, speciesID = 2434, faction = "all", coord = { 50673675, 50756121 }, sort = 14, isKnown = false },
    [141668] = { name = L["echo_of_myzrael"], id = 141668, questId = { 53059, 53508 }, type = "Elite", drop = "Pet", itemID = 163677, petID = 143515, speciesID = 2435, faction = "all", coord = { 57073506 }, sort = 15, isKnown = false },
    [142433] = { name = L["fozruk"], id = 142433, questId = { 53019, 53510 }, type = "Elite", drop = "Pet", itemID = 163711, petID = 143627, speciesID = 2440, faction = "all", coord = { 59422773 }, sort = 16, isKnown = false },
    [142716] = { name = L["man_hunter_rog"], id = 142716, questId = { 53090, 53515 }, type = "Rare", drop = "Pet", itemID = 163712 , petID = 143628, speciesID = 2441, faction = "all", coord = { 52277674 }, sort = 17, isKnown = false },
    [142435] = { name = L["plaguefeather"], id = 142435, questId = { 53020, 53519 }, type = "Elite", drop = "Pet", itemID = 163690, petID = 143564, speciesID = 2438, faction = "all", coord = { 35606435 }, sort = 18, isKnown = false },
    [142436] = { name = L["ragebeak"], id = 142436, questId = { 53016, 53522 }, type = "Elite", drop = "Pet", itemID = 163689, petID = 143563, speciesID = 2437, faction = "all", coord = { 18412794, 11905220 }, sort = 19, isKnown = false },
    [142438] = { name = L["venomarus"], id = 142438, questId = { 53024, 53528 }, type = "Elite", drop = "Pet", itemID = 163648, petID = 143499, speciesID = 2432, faction = "all", coord = { 56945330 }, sort = 20, isKnown = false },
    [142440] = { name = L["yogursa"], id = 142440, questId = { 53015, 53529 }, type = "Elite", drop = "Pet", itemID = 163684, petID = 143533, speciesID = 2436, faction = "all", coord = { 13063622 }, sort = 21, isKnown = false },
    [142686] = { name = L["foulbelly"], id = 142686, questId = { 53086, 53509 }, type = "Rare", drop = "Toy", itemID = 163735, faction = "all", coord = { 22305106 }, cave = { 28804557 }, note = "Inside cave", sort = 22, isKnown = false },
    [142662] = { name = L["geomancer_flintdagger"], id = 142662, questId = { 53060, 53511 }, type = "Rare", drop = "Toy", itemID = 163713, faction = "all", coord = { 79452939 }, cave = { 78143689 }, note = "Inside cave", sort = 23, isKnown = false },
    [142725] = { name = L["horrific_apparition"], id = 142725, questId = { 53087, 53512 }, type = "Rare", drop = "Toy", itemID = 163736, faction = "all", coord = { 26723278, 19446123 }, sort = 24, isKnown = false },
    [142112] = { name = L["korgresh_coldrage"], id = 142112, questId = { 53058, 53513 }, type = "Rare", drop = "Toy", itemID = 163744, faction = "all", coord = { 49178409 }, cave = { 48007941 }, note = "Inside cave", sort = 25, isKnown = false },
    [142684] = { name = L["kovork"], id = 142684, questId = { 53089, 53514 }, type = "Rare", drop = "Toy", itemID = 163750, faction = "all", coord = { 25404872 }, cave = { 28804557 }, note = "Inside cave", sort = 26, isKnown = false },
    [141942] = { name = L["molok_the_crusher"], id = 141942, questId = { 53057, 53516 }, type = "Rare", drop = "Toy", itemID = 163775, faction = "all", coord = { 47657800 }, sort = 27, isKnown = false },
    [142683] = { name = L["ruul_onestone"], id = 142683, questId = { 53092, 53524 }, type = "Rare", drop = "Toy", itemID = 163741, faction = "all", coord = { 42905660 }, sort = 28, isKnown = false },
    [142690] = { name = L["singer"], id = 142690, questId = { 53093, 53525 }, type = "Rare", drop = "Toy", itemID = 163738, faction = "all", coord = { 51213999, 50595746 }, sort = 29, isKnown = false },
    [142682] = { name = L["zalas_witherbark"], id = 142682, questId = { 53094, 53530 }, type = "Rare", drop = "Toy", itemID = 163745, faction = "all", coord = { 62868112 }, cave = { 63277708 }, note = "Inside cave", sort = 30, isKnown = false },
}

WR.isTomTomloaded = false
WR.warning = false
WR.warfrontControlledByFaction = ""

WR.colors = {
    white = { 1, 1, 1, 1 },
    red = { 1, 0.12, 0.12, 1 },
    green = { 0, 1, 0, 1 },
    purple = { 0.63, 0.20, 0.93, 1 },
    turqoise = { 0.40, 0.73, 1, 1 },
    yellow = { 1, 0.82, 0, 1 },
    blue = { 0, 0.44, 0.87, 1 },
    grey = { 0.6, 0.6, 0.6, 1 },
}

local defaults = {
    profile = {
        minimap = {
            hide = false,
            minimapPos = 180,
        },
        broker = {
            showBrokerText = true,
            brokerText = "name",
            updateInterval = 1,
        },
        menu = {
            showMenuOn = "mouse",
            hideAlreadyKnown = false,
            hideGoliaths = false,
            showAtMaxLevel = false,
            showWarfrontOnTitle = true,
            showWarfrontInMenu = false,
        },
        colors = {
            colorizeDrops = true,
            knownColor = { 0, 1, 0, 1 },
            unknownColor = { 1, 1, 1, 1 },
            colorizeStatus = false,
            available = { 0, 1, 0, 1 },
            defeated = { 1, 0.12, 0.12, 1 },
        },
        unitframe = {
            showStaus = true,
            showDrop = true,
            showAlreadyKnown = true,
        },
        worldmapicons = {
            showWorldmapIcons = true,
            clickToTomTom = true,
            hideIconWhenDefeated = false,
            hideAlreadyKnown = false,
            hideGoliaths = false,
        },
        tomtom = {
            enableIntegration = true,
            enableChatMessage = true,
        },
    },
}


function WarfrontRareTracker:OnInitialize()
    WR.broker = LDB:NewDataObject("WarfrontRareTracker", {
        type = "data source",
        label = "WarfrontRareTracker",
        icon = "Interface\\Icons\\ability_ensnare",
        text = "Loading",
        OnEnter = function(self) WarfrontRareTracker:MenuOnEnter(self) end,
        OnLeave = function() WarfrontRareTracker:MenuOnLeave() end,
        OnClick = function(self, button) WarfrontRareTracker:MenuOnClick(self, button) end,
    })

    WR.db = LibStub("AceDB-3.0"):New("WarfrontRareTrackerDB", defaults, true)
    WR.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	WR.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    WR.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    WarfrontRareTracker:RegisterOptions()
    MinimapIcon:Register("WarfrontRareTracker", WR.broker, WR.db.profile.minimap)

    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WarfrontRareTracker", "WarfrontRareTracker")
    self:RegisterChatCommand("warfront", function() LibStub("AceConfigDialog-3.0"):Open("WarfrontRareTracker") end)
end

function WarfrontRareTracker:DelayedInitialize()
    if IsAddOnLoaded("TomTom") then
        WR.isTomTomloaded = true
    end
    WarfrontRareTracker:ScanForKnownItems()
    WarfrontRareTracker:UpdateWorldMapIcons()
    WarfrontRareTracker:UpdateBrokerText()
end

function WarfrontRareTracker:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("NEW_MOUNT_ADDED", "OnEvent")
    self:RegisterEvent("TOYS_UPDATED", "OnEvent")
    self:RegisterEvent("NEW_PET_ADDED", "OnEvent")
    self:RegisterEvent("CONTRIBUTION_CHANGED", "OnEvent")

    self:RegisterEvent("LOOT_CLOSED", "OnEvent")
    self:RegisterEvent("PLAYER_MONEY", "OnEvent")
    self:RegisterEvent("SHOW_LOOT_TOAST", "OnEvent")
    self:RegisterEvent("SHOW_LOOT_TOAST_UPGRADE", "OnEvent")
end

function WarfrontRareTracker:OnDisable()
    self:UnregisterEvent("NEW_MOUNT_ADDED")
    self:UnregisterEvent("TOYS_UPDATED")
    self:UnregisterEvent("NEW_PET_ADDED")
    self:UnregisterEvent("CONTRIBUTION_CHANGED")

    self:UnregisterEvent("LOOT_CLOSED")
    self:UnregisterEvent("PLAYER_MONEY")
    self:UnregisterEvent("SHOW_LOOT_TOAST")
    self:UnregisterEvent("SHOW_LOOT_TOAST_UPGRADE")
    WarfrontRareTracker:WipeWorldmapIcons()
end

function WarfrontRareTracker:RefreshConfig()
    LibStub("LibDBIcon-1.0"):Refresh("WarfrontRareTracker", WR.db.profile.minimap)
    WarfrontRareTracker:UpdateBrokerText()
    WarfrontRareTracker:UpdateWorldMapIcons()
end

function WarfrontRareTracker:PLAYER_ENTERING_WORLD()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    WarfrontRareTracker:CheckFactionWarfrontControl()
    self:ScheduleTimer("DelayedInitialize", 5)
end

function WarfrontRareTracker:OnEvent(event, ...)
    if event == "NEW_MOUNT_ADDED" then
        WarfrontRareTracker:ScanForKnownItems()
    elseif event == "TOYS_UPDATED" then
        WarfrontRareTracker:ScanForKnownItems()
    elseif event == "NEW_PET_ADDED" then
        self:ScheduleTimer("ScanForKnownItems", 5)
    elseif event == "CONTRIBUTION_CHANGED" then
        WarfrontRareTracker:UpdateWorldMapIcons()
        self:ScheduleTimer("UpdateWorldMapIcons", 10)
    elseif event == "LOOT_CLOSED" or event == "PLAYER_MONEY" or event == "SHOW_LOOT_TOAST" or event == "SHOW_LOOT_TOAST_UPGRADE" then
        WarfrontRareTracker:UpdateWorldMapIcons()
    end
end

function WarfrontRareTracker:ScanForKnownItems()
    for k, rare in pairs(WR.rares) do
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

function WarfrontRareTracker:UpdateBrokerText()
    local brokerText
    if WR.db.profile.broker.showBrokerText  then
        if WR.db.profile.broker.brokerText == "name" then
            brokerText = "Warfront Rare Tracker"
        else
            local factionControlling = WR.warfrontControlledByFaction == "Horde" and WarfrontRareTracker:ColorText("(H)", WR.colors.red) or WarfrontRareTracker:ColorText("(A)", WR.colors.blue)
            brokerText = factionControlling
            local percentage, timeNextChange = WarfrontRareTracker:GetWarfrontInfo()
            if timeNextChange ~= nil then
                local daysLeft, hoursLeft, minutesLeft, secondsLeft = WarfrontRareTracker:GetWarfrontTimeLeft(timeNextChange)
                if daysLeft > 0 then
                    brokerText = brokerText .. WarfrontRareTracker:ColorText(" Scenario: ", WR.colors.turqoise) .. WarfrontRareTracker:ColorText(string.format("%sD %sH %sM Left", daysLeft, hoursLeft, minutesLeft), WR.colors.green)
                else
                    brokerText = brokerText .. WarfrontRareTracker:ColorText(" Scenario: ", WR.colors.turqoise) .. WarfrontRareTracker:ColorText(string.format("%sH %sM Left", hoursLeft, minutesLeft), WR.colors.red)
                end
            elseif percentage ~= nil then
                local progress = math.floor(percentage * 100 + 0.5)
                local color
                if progress < 30 then
                    color = WR.colors.red
                elseif progress < 70 then
                    color = WR.colors.yellow
                else
                    color = WR.colors.green
                end
                brokerText = brokerText .. WarfrontRareTracker:ColorText(" Gathering: ", WR.colors.turqoise) .. WarfrontRareTracker:ColorText(progress .. " %", color)
            else -- opposite side cannot readout percentage
                brokerText = WarfrontRareTracker:ColorText(WR.warfrontControlledByFaction .. " Has Control", WR.colors.turqoise)
            end
            self:ScheduleTimer("UpdateBrokerText", WR.db.profile.broker.updateInterval * 60) -- update text at configured interval
        end
    else
        brokerText = ""
    end
    WR.broker.text = brokerText
end

function WarfrontRareTracker:ColorText(text, color)
    if text and color then
        return format("|cff%02x%02x%02x%s|r", (color[1] or 1) * 255, (color[2] or 1) * 255, (color[3] or 1) * 255, text)
    else
        return text
    end
end

function WarfrontRareTracker:GetNPCIDFromGUID(guid)
	if guid then
		local unit_type, _, _, _, _, mob_id = strsplit('-', guid)
		if unit_type == "Pet" or unit_type == "Player" then return 0 end
		return (guid and mob_id and tonumber(mob_id)) or 0
	end
	return 0
end

function WarfrontRareTracker:GetStatusText(npcid)
    local rare = WR.rares[npcid]
    if rare.questId[1] == 0 then
        return WarfrontRareTracker:ColorText("Unknown", WR.colors.yellow)
    else
        for k, v in pairs(rare.questId) do
            if IsQuestFlaggedCompleted(rare.questId[k]) then
                return WarfrontRareTracker:ColorText("Defeated", WR.db.profile.colors.colorizeStatus and WR.db.profile.colors.defeated or WR.colors.red)
            end
        end
    end
    if rare.faction == "all" or rare.faction == WR.warfrontControlledByFaction then
        return WarfrontRareTracker:ColorText("Available", WR.db.profile.colors.colorizeStatus and WR.db.profile.colors.available or WR.colors.green)
    else
        return WarfrontRareTracker:ColorText("Unavailable", WR.colors.yellow)
    end
end

function WarfrontRareTracker:IsQuestCompleted(npcid)
    local rare = WR.rares[npcid]
    if rare.questId[1] == 0 then
        return false
    else
        for k, v in pairs(rare.questId) do
            if IsQuestFlaggedCompleted(rare.questId[k]) then
                return true
            end
        end
    end
    -- if rare.faction == "all" or rare.faction == WR.warfrontControlledByFaction then
    --     return false
    -- else
    --     return -- Unavailable, true or false?
    -- end
    return false
end

function WarfrontRareTracker:GetDropText(npcid)
    local rare = WR.rares[npcid]
    if WR.db.profile.colors.colorizeDrops and rare.isKnown then
        return WarfrontRareTracker:ColorText(rare.drop, WR.db.profile.colors.knownColor)
    elseif WR.db.profile.colors.colorizeDrops and not rare.isKnown then
        return WarfrontRareTracker:ColorText(rare.drop, WR.db.profile.colors.unknownColor)
    else
        return rare.drop
    end
end

function WarfrontRareTracker:CheckFactionWarfrontControl()
    local state, percentage, nextChange, _ = C_ContributionCollector.GetState(11); -- Battle for Stromgarde
    local factionControlling
    if state == 1 or state == 2 then
        -- zone is currently active == faction is not controlling arathi
        factionControlling = "Alliance"
    end
    if state == 3 or state == 4 then
        -- zone is currently destroyed == faction is controlling arathi
        factionControlling = "Horde"
    end
    if WR.warfrontControlledByFaction == "" then
        WR.warfrontControlledByFaction = factionControlling
        self:ScheduleTimer("CheckFactionWarfrontControl", 2)
        return
    end

    if factionControlling == WR.warfrontControlledByFaction and nextChange ~= nill then
        local daysLeft, hoursLeft, minutesLeft, secondsLeft = WarfrontRareTracker:GetWarfrontTimeLeft(nextChange)
        if daysLeft >= 1 then
        elseif hoursLeft >= 1 then
            if hoursLeft > 1 then
                local scheduleTime = (hoursLeft - 1) * 3600
                self:ScheduleTimer("CheckFactionWarfrontControl", scheduleTime)
            else
                local scheduleTime = (minutesLeft + 2) * 60
                self:ScheduleTimer("CheckFactionWarfrontControl", scheduleTime)
            end
        elseif minutesLeft >= 1 then
            if minutesLeft > 1 then
                local scheduleTime = (minutesLeft - 1) * 60
                self:ScheduleTimer("CheckFactionWarfrontControl", scheduleTime)
            else
                local scheduleTime = secondsLeft + 2
                self:ScheduleTimer("CheckFactionWarfrontControl", scheduleTime)
            end
        elseif secondsLeft > 1 then
            local scheduleTime = secondsLeft + 10
            self:ScheduleTimer("CheckFactionWarfrontControl", scheduleTime)
        end
    elseif factionControlling == WR.warfrontControlledByFaction then
        self:ScheduleTimer("CheckFactionWarfrontControl", 3600)
    end
    WR.warfrontControlledByFaction = factionControlling
end

function WarfrontRareTracker:GetWarfrontTimeLeft(changeTime)
    local timeLeft = date("*t", changeTime - GetServerTime())
    local daysLeft = timeLeft.day - 1
    local hoursLeft = timeLeft.hour - 1
    return daysLeft, hoursLeft, timeLeft.min, timeLeft.sec
end

function WarfrontRareTracker:IsNPCPlayerFaction(npcid)
    local playerFaction, _ = UnitFactionGroup("player")
    local rareFaction = WR.rares[npcid].faction
    return rareFaction == playerFaction or rareFaction == "all"
end

function WarfrontRareTracker:AddToTomTom(npcid)
    if WR.isTomTomloaded and WR.db.profile.tomtom.enableIntegration then
        local rare = WR.rares[npcid]
        local coord = rare.coord[1]
        if #rare.coord > 1 and WR.warfrontControlledByFaction == "Horde" then
            coord = rare.coord[2]
        end
        local name = rare.name
        local mapID = 14
        local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000

        TomTom:AddWaypoint(mapID, x, y, {
            title = name,
            persistent = nil,
            minimap = true,
            world = true,
        })
        if rare.cave and type(rare.cave) == "table" then
            coord = rare.cave[1]
            if #rare.cave > 1 and WR.warfrontControlledByFaction == "Horde" then
                coord = rare.cave[2]
            end
            name = name .. " Cave Entrance"
            x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
            TomTom:AddWaypoint(mapID, x, y, {
                title = name,
                persistent = nil,
                minimap = true,
                world = true,
            })
        end
        if WR.db.profile.tomtom.enableChatMessage then
            WarfrontRareTracker:Print("Added waypoint to: " .. rare.name)
        end
    end
end

---------------
-- Menu Tooltip
function WarfrontRareTracker:MenuOnClick(self, button)
    if button == "RightButton" then
        LibStub("AceConfigDialog-3.0"):Open("WarfrontRareTracker")
    elseif button == "LeftButton" and WR.db.profile.menu.showMenuOn == "click" then
        if not WR.db.profile.menu.showAtMaxLevel then
            WarfrontRareTracker:ShowMenu(self, button)
        elseif WR.db.profile.menu.showAtMaxLevel and UnitLevel("player") == 120 then
            WarfrontRareTracker:ShowMenu(self, button)
        end
    end
end

function WarfrontRareTracker:MenuOnEnter(self, button)
    if WR.db.profile.menu.showMenuOn == "mouse" then
        if not WR.db.profile.menu.showAtMaxLevel then
            WarfrontRareTracker:ShowMenu(self, button)
        elseif WR.db.profile.menu.showAtMaxLevel and UnitLevel("player") == 120 then
            WarfrontRareTracker:ShowMenu(self, button)
        end
    end
end

function WarfrontRareTracker:MenuOnLeave(self, button)
end

function WarfrontRareTracker:ShowMenu(self, button)
    menuTooltip = LibQTip:Acquire("WarfrontRareTrackerMenuTip")
	menuTooltip:SmartAnchorTo(self)
    menuTooltip:SetAutoHideDelay(0.25, self)
    menuTooltip:EnableMouse(true)
    WarfrontRareTracker:UpdateMenuToolTip(menuTooltip)

    if WarfrontRareTracker.WR.db.profile.menu.showWarfrontInMenu then
        WarfrontRareTracker:WarfrontStatusInfoTooltip(menuTooltip)
        menuTooltip:AddSeparator()
    end

    line = menuTooltip:AddLine()
    line = menuTooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Right-Click to open Options.", WR.colors.turqoise), "LEFT", 3)
    if WR.isTomTomloaded and WR.db.profile.tomtom.enableIntegration then
        line = menuTooltip:AddLine()
        line = menuTooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Left-Click to add TomTom Waypoint.", WR.colors.turqoise), "LEFT", 3)
    end
	menuTooltip:Show()
end

function WarfrontRareTracker:UpdateMenuToolTip(menuTooltip)
    local line

    menuTooltip:Clear();
    menuTooltip:SetColumnLayout(3, "LEFT", "LEFT", "LEFT")

    line = menuTooltip:AddHeader()
    menuTooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Warfront Rare Tracker", WR.colors.yellow), menuTooltip:GetHeaderFont(), "CENTER", 3)

    if WarfrontRareTracker.WR.db.profile.menu.showWarfrontOnTitle then
        menuTooltip:SetLineScript(line, "OnEnter", function(self) WarfrontRareTracker:WarfrontStatusTooltipOnEnter(self) end)
        menuTooltip:SetLineScript(line, "OnLeave", function() WarfrontRareTracker:WarfrontStatusTooltipOnleave() end)
        menuTooltip:SetLineScript(line, "OnMouseUp", function(self, button) WarfrontRareTracker:WarfrontStatusTooltipOnClick(self, button) end)
    end

    line = menuTooltip:AddLine()
    menuTooltip:SetCell(line, 1, " ", nil, "LEFT", 3)

    line = menuTooltip:AddHeader()
    menuTooltip:SetCell(line, 1, "Rare")
    menuTooltip:SetCell(line, 2, "Drops", nil, "LEFT", 1, LibQTip.LabelProvider, 20, nil, 100, 100)
    menuTooltip:SetCell(line, 3, "Status")
    menuTooltip:AddSeparator()

    for k, rare in pairs(sortRares(WR.rares)) do
        local npcid = rare.id
        if WarfrontRareTracker:IsNPCPlayerFaction(npcid) then
            if WR.db.profile.menu.hideAlreadyKnown and rare.isKnown then
            elseif WR.db.profile.menu.hideGoliaths and rare.type == "Goliath" then
            else
                local rare = WR.rares[npcid]
                local name = rare.name
                if rare.type == "WorldBoss" then
                    name = WarfrontRareTracker:ColorText(name, WR.colors.purple)
                end
                local drop = WarfrontRareTracker:GetDropText(npcid)
                local status = WarfrontRareTracker:GetStatusText(npcid)

                line = menuTooltip:AddLine()
                menuTooltip:SetCell(line, 1, name)
                menuTooltip:SetCell(line, 2, drop, nil, "LEFT", 1, LibQTip.LabelProvider, 20, nil, 100, 100)
                menuTooltip:SetCell(line, 3, status)
                menuTooltip:SetLineScript(line, "OnEnter", function(self, npcid) WarfrontRareTracker:MenuTooltipOnLineEnter(self, npcid) end, npcid)
                menuTooltip:SetLineScript(line, "OnLeave", function() WarfrontRareTracker:MenuTooltipOnLineLeave() end)
                menuTooltip:SetLineScript(line, "OnMouseUp", function(self, npcid, button) WarfrontRareTracker:MenuTooltipOnLineClick(self, npcid, button) end, npcid)
            end
        end
    end
    menuTooltip:AddSeparator()
end

---------------
-- Loot Tooltip
function WarfrontRareTracker:MenuTooltipOnLineClick(self, npcid, button)
    if button == "LeftButton" then
        if WR.isTomTomloaded and WR.db.profile.tomtom.enableIntegration then
            WarfrontRareTracker:AddToTomTom(npcid)
        end
    end
end

function WarfrontRareTracker:MenuTooltipOnLineLeave()
    if lootTooltip then
        LibQTip:Release(lootTooltip)
        lootTooltip = nil
    end
end

function WarfrontRareTracker:MenuTooltipOnLineEnter(self, npcid)
    if LibQTip:IsAcquired("WarfrontRareTrackerLootTip") and lootTooltip then
        LibQTip.Release(lootTooltip)
        lootTooltip = nil
    end
    lootTooltip = LibQTip:Acquire("WarfrontRareTrackerLootTip", 2, "LEFT", "RIGHT")
    lootTooltip:ClearAllPoints()
    lootTooltip:SetClampedToScreen(true)
    lootTooltip:SetPoint("RIGHT", self, "LEFT", -15, -18)
        
    local rare = WR.rares[npcid]
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
                lootTooltip:SetCell(line, 1, WarfrontRareTracker:ColorText(text, color), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 200)
            end
        end
        if lootTooltip:GetLineCount() > 1 then
            lootTooltip:Show()
        end
    end
end

--------------------------
-- Warfront Status Tooltip
function WarfrontRareTracker:WarfrontStatusTooltipOnClick(self, button)
    --print("WarfrontStatusTooltipOnClick")
end

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
    warfrontStatusTooltip:ClearAllPoints()
    warfrontStatusTooltip:SetClampedToScreen(true)
    warfrontStatusTooltip:SetPoint("TOPRIGHT", self, "LEFT", -15, 17)

    
    line = warfrontStatusTooltip:AddHeader()
    warfrontStatusTooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Warfront Status", WR.colors.yellow), warfrontStatusTooltip:GetHeaderFont(), "CENTER", 3)

    line = warfrontStatusTooltip:AddLine()
    warfrontStatusTooltip:SetCell(line, 1, " ", nil, "LEFT", 3)

    WarfrontRareTracker:WarfrontStatusInfoTooltip(warfrontStatusTooltip)
    warfrontStatusTooltip:Show()
end

function WarfrontRareTracker:WarfrontStatusInfoTooltip(tooltip)
    local factionControlling = WR.warfrontControlledByFaction == "Horde" and WarfrontRareTracker:ColorText("Horde", WR.colors.red) or WarfrontRareTracker:ColorText("Alliance", WR.colors.blue)
    local line = tooltip:AddHeader()
    tooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Current control:", WR.colors.yellow))
    tooltip:SetCell(line, 2, factionControlling, nil, nil, 2)
    --tooltip:AddSeparator()

    local stromgardeState, stromgardePercentage, stromgardeNextChange, timeStarted = C_ContributionCollector.GetState(11)
    if stromgardeState == 1 or ststromgardeStateate == 2 then -- Alliance control
        local percentage, timeNextChange = WarfrontRareTracker:GetWarfrontInfo()
        if timeNextChange ~= nil then
            tooltip:AddSeparator()
            local line = tooltip:AddLine()
            tooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Horde Status:", WR.colors.yellow))
            tooltip:SetCell(line, 2, WarfrontRareTracker:ColorText("Attacking", WR.colors.red), nil, nil, 2)

            local daysLeft, hoursLeft, minutesLeft, secondsLeft = WarfrontRareTracker:GetWarfrontTimeLeft(timeNextChange)
            local timeLeft = string.format("%s Days %s Hours %s Minutes", daysLeft, hoursLeft, minutesLeft)
            local line = tooltip:AddLine()
            tooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Time Left:", WR.colors.yellow))
            tooltip:SetCell(line, 2, WarfrontRareTracker:ColorText(timeLeft, WR.colors.turqoise), nil, nil, 2)
        elseif percentage ~= nil then
            tooltip:AddSeparator()
            local line = tooltip:AddLine()
            tooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Horde Status:", WR.colors.yellow))
            tooltip:SetCell(line, 2, WarfrontRareTracker:ColorText("Gathering Resources", WR.colors.turqoise), nil, nil, 2)

            local progress = math.floor(percentage * 100 + 0.5)
            local line = tooltip:AddLine()
            tooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Progress:", WR.colors.yellow))
            tooltip:SetCell(line, 2, WarfrontRareTracker:ColorText(progress .. " %", WR.colors.turqoise), nil, nil, 2)
        end
    elseif stromgardeState == 3 or stromgardeState == 4 then -- Horde control
        local percentage, timeNextChange = WarfrontRareTracker:GetWarfrontInfo()
        if timeNextChange ~= nil then
            tooltip:AddSeparator()
            local line = tooltip:AddLine()
            tooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Alliance Status:", WR.colors.yellow))
            tooltip:SetCell(line, 2, WarfrontRareTracker:ColorText("Attacking", WR.colors.red), nil, nil, 2)

            local daysLeft, hoursLeft, minutesLeft, secondsLeft = WarfrontRareTracker:GetWarfrontTimeLeft(timeNextChange)
            local timeLeft = string.format("%s Days %s Hours %s Minutes", daysLeft, hoursLeft, minutesLeft)
            local line = tooltip:AddLine()
            tooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Time Left:", WR.colors.yellow))
            tooltip:SetCell(line, 2, WarfrontRareTracker:ColorText(timeLeft, WR.colors.turqoise), nil, nil, 2)
        elseif percentage ~= nil then
            tooltip:AddSeparator()
            local line = tooltip:AddLine()
            tooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Alliance Status:", WR.colors.yellow))
            tooltip:SetCell(line, 2, WarfrontRareTracker:ColorText("Gathering Resources", WR.colors.turqoise), nil, nil, 2)

            local progress = math.floor(percentage * 100 + 0.5)
            local line = tooltip:AddLine()
            tooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Progress:", WR.colors.yellow))
            tooltip:SetCell(line, 2, WarfrontRareTracker:ColorText(progress .. " %", WR.colors.turqoise), nil, nil, 2)
        end
    end
end

function WarfrontRareTracker:GetWarfrontInfo()
    local percentage
    local time
    local contributionMapID
    if WR.warfrontControlledByFaction == "Horde" then
        contributionMapID = 876 -- Alliance
    else
        contributionMapID = 875 -- Horde
    end
    local contribution = C_ContributionCollector.GetContributionCollectorsForMap(contributionMapID)
    if #contribution > 0 then
        local collectorCreatureID = C_ContributionCollector.GetManagedContributionsForCreatureID(contribution[1].collectorCreatureID)
        local contributionState, contributionPercentage, contributionTimeNextChange, contributionTimeStarted = C_ContributionCollector.GetState(collectorCreatureID)
        percentage = contributionPercentage
        time = contributionTimeNextChange
    else
        percentage = nil
        time = nil
    end
    local warfrontState, warfrontPercentage, warfrontTimeNextChange, warfrontTimeStarted = C_ContributionCollector.GetState(11)
    return percentage, time
end

-------------------
-- Worldmap Tooltip
function WarfrontRareTracker:WorldmapTooltipOnClick(self, npcid)
    local rare = WR.rares[npcid]
    if WR.isTomTomloaded and WR.db.profile.tomtom.enableIntegration and WR.db.profile.worldmapicons.clickToTomTom then
        WarfrontRareTracker:AddToTomTom(npcid)
    end
end

function WarfrontRareTracker:WorldmapTooltipOnLeave()
    if worldmapTooltip then
        LibQTip:Release(worldmapTooltip)
        worldmapTooltip = nil
    end
end

function WarfrontRareTracker:WorldmapTooltipOnEnter(self, npcid, NPC)
    if LibQTip:IsAcquired("WarfrontRareTrackerWorldmapTip") and worldmapTooltip then
        LibQTip.Release(worldmapTooltip)
        worldmapTooltip = nil
    end
    worldmapTooltip = LibQTip:Acquire("WarfrontRareTrackerWorldmapTip", 2, "LEFT", "RIGHT")
    worldmapTooltip:ClearAllPoints()
    worldmapTooltip:SetClampedToScreen(true)
    worldmapTooltip:SetPoint("TOPRIGHT", self, "BOTTOM")

    local rare = WR.rares[npcid]
    if NPC then
        if rare.itemID ~= 0 then
            local name = rare.name
            if rare.type == "WorldBoss" or rare.type == "Elite" or rare.type == "Goliath" then
                name = WarfrontRareTracker:ColorText(name, WR.colors.purple)
            else
                name = WarfrontRareTracker:ColorText(name, WR.colors.blue)
            end
            worldmapTooltip:AddHeader(name)

            local line = worldmapTooltip:AddLine()
            worldmapTooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Drop: ", WR.colors.yellow), nil, nil, 2)

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

                if string.len(text) > 1 then
                    local line = worldmapTooltip:AddLine()
                    worldmapTooltip:SetCell(line, 1, WarfrontRareTracker:ColorText(text, color), nil, nil, 2, LibQTip.LabelProvider, nil, nil, 200)
                end
            end
            if rare.note then
                local line = worldmapTooltip:AddLine()
                worldmapTooltip:SetCell(line, 1, " ", nil, nil, 2)
                local line = worldmapTooltip:AddLine()
                worldmapTooltip:SetCell(line, 1, WarfrontRareTracker:ColorText("Note: ", WR.colors.yellow) .. WarfrontRareTracker:ColorText(rare.note, WR.colors.grey), nil, nil, 2)
            end
            if worldmapTooltip:GetLineCount() > 1 then
                worldmapTooltip:Show()
            end
        end
    else
        local name = rare.name
        worldmapTooltip:AddLine(WarfrontRareTracker:ColorText("Cave entrance for: "..name, WR.colors.yellow))
        worldmapTooltip:Show()
    end
end

-----------------
-- Worldmap Icons
local function getNewWorldmapPin()
    local worldmapIcon = next(worldmapIcons)
    if worldmapIcon then
		worldmapIcons[worldmapIcon] = nil
		return worldmapIcon
    end
    worldmapIconsCount = worldmapIconsCount + 1
    worldmapIcon = CreateFrame("Button", "WarfrontPin"..worldmapIconsCount, WorldMap)
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

function WarfrontRareTracker:UpdateWorldMapIcons()
    self:WipeWorldmapIcons()
    if WR.db.profile.worldmapicons.showWorldmapIcons then
        for k, rare in pairs(WR.rares) do
            local npcid = rare.id
            if WarfrontRareTracker:IsNPCPlayerFaction(npcid) then
                if WR.db.profile.worldmapicons.hideIconWhenDefeated and WarfrontRareTracker:IsQuestCompleted(npcid) then
                    -- do nothing
                elseif WR.db.profile.worldmapicons.hideAlreadyKnown and rare.isKnown then
                elseif WR.db.profile.worldmapicons.hideGoliaths and rare.type == "Goliath" then
                else
                    WarfrontRareTracker:PlaceWorldmapNPCIcon(npcid)
                    if rare.cave then
                        WarfrontRareTracker:PlaceWorldmapCaveIcon(npcid, rare.cave)
                    end
                end
            end
        end
    end
end

function WarfrontRareTracker:PlaceWorldmapNPCIcon(npcid)
    local rare = WR.rares[npcid]
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
    icon:SetScript("OnClick", function(self) WarfrontRareTracker:WorldmapTooltipOnClick(self, icon.npcid) end)
    icon:SetScript("OnEnter", function(self) WarfrontRareTracker:WorldmapTooltipOnEnter(self, icon.npcid, true) end)
    icon:SetScript("OnLeave", function() WarfrontRareTracker:WorldmapTooltipOnLeave() end)
    local coord = rare.coord[1]
    if #rare.coord > 1 and WR.warfrontControlledByFaction == "Horde" then
        coord = rare.coord[2]
    end
    local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
    HBDPins:AddWorldMapIconMap("WarfrontRareTracker", icon, 14, x, y, 1)
end

function WarfrontRareTracker:PlaceWorldmapCaveIcon(npcid, caveCoord)
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
    icon:SetScript("OnEnter", function(self) WarfrontRareTracker:WorldmapTooltipOnEnter(self, icon.npcid, false) end)
    icon:SetScript("OnLeave", function() WarfrontRareTracker:WorldmapTooltipOnLeave() end)
    local coord = caveCoord[1]
    if #caveCoord > 1 and WR.warfrontControlledByFaction == "Horde" then
        coord = caveCoord[2]
    end
    local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
    HBDPins:AddWorldMapIconMap("WarfrontRareTracker", icon, 14, x, y, 1)
end

function WarfrontRareTracker:WipeWorldmapIcons()
    HBDPins:RemoveAllWorldMapIcons("WarfrontRareTracker")
    wipe(worldmapIcons)
end

----------------
-- NPC UnitFrame
GameTooltip:HookScript("OnTooltipSetUnit", function(self)
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

    local npcid = WarfrontRareTracker:GetNPCIDFromGUID(guid)
    local rare = WR.rares[npcid]
    if rare and type(rare) == "table" and WarfrontRareTracker:IsNPCPlayerFaction(npcid) then
        if WR.db.profile.unitframe.showStaus then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(WarfrontRareTracker:ColorText("Warfront Rare Tracker: ", WR.colors.yellow) .. WarfrontRareTracker:GetStatusText(npcid))
        end
        if WR.db.profile.unitframe.showDrop and rare.itemID ~= 0 then
            local itemName, itemLink, itemRarity, _, _, itemType, _, _, _, _, _ = GetItemInfo(rare.itemID)
            if itemLink or itemName then
                GameTooltip:AddLine(WarfrontRareTracker:ColorText("Drops " .. rare.drop .. ": ", WR.colors.yellow) .. (itemLink or itemName))
            end
        end
        if WR.db.profile.unitframe.showAlreadyKnown and rare.isKnown then
            GameTooltip:AddLine(WarfrontRareTracker:ColorText("Already known", WR.colors.red))
        end
    end
end)

local function compareNum(a, b)
    if not a or not b then return 0 end
    if type(a) ~= "table" or type(b) ~= "table" then return 0 end
    return (a.sort or 0) < (b.sort or 0)
end

function sortRares(t)
    local newTable = {}
    local i, j, n, min = 0, 0, 0, 0
    local k, v
    for k, v in pairs(t) do
        if type(v) == "table" and v.sort then
            n = n + 1
            newTable[n]  = v
        end
    end
    for i = 1, n, 1 do
        min = i
        for j = i + 1, n, 1 do
            if compareNum(newTable[j], newTable[min]) then min = j end
        end
        newTable[i], newTable[min] = newTable[min], newTable[i]
    end
    return newTable
end