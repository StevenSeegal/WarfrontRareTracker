local WarfrontRareTracker = LibStub("AceAddon-3.0"):GetAddon("WarfrontRareTracker")

local isTomTomlocked = true
local hasMultipleRareDB = false
local whitelist = { ["Mount"] = "Mounts", ["Pet"] = "Pets", ["Toy"] = "Toys" }
local intervalTimes = { [1]="1 minute", [2] = "2 minutes", [3] = "3 minutes", [4] = "4 minutes", [5]="5 minutes", [10]="10 minutes", [15]="15 minutes", [30]="30 minutes", [60]="1 hour" }

local colors = {
    red = { 1, 0.12, 0.12, 1 },
    green = { 0, 1, 0, 1 },
    turqoise = { 0.25, 0.78, 0.92, 1 },
    yellow = { 1, 0.82, 0, 1 },
    blue = { 0, 0.44, 0.87, 1 },
    lightcyan = { 0, 1 , 0.59, 1 },
}

local function isBrokerIntervalDisabled()
    if WarfrontRareTracker.db.profile.broker.showBrokerText then
        if WarfrontRareTracker.db.profile.broker.brokerText == "factionstatus" then
            return false
        elseif WarfrontRareTracker.db.profile.broker.brokerText == "allstatus" then
            return false
        else
            return true
        end
    else
        return true
    end
end

local function refreshWorldmapIcons()
    if WarfrontRareTracker.db.profile.worldmapicons.showWorldmapIcons then
        WarfrontRareTracker:UpdateAllWorldMapIcons()
    end
end

configOptions = {
    type = "group",
    args = {
        minimapBroker = {
            name = "Minimap & Broker",
            type = "group",
            order = 2,
            args = {
                minimap = {
                    name = "Minimap Options",
                    order = 1,
                    type = "group",
                    inline = true,
                    args = {
                        minimapButton = {
                            name = "Show Minimap Icon",
                            desc = "Shows Minimap Icon",
                            type = "toggle",
                            order = 1,
                            get = function(info)
                                    return not WarfrontRareTracker.db.profile.minimap.hide
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.minimap.hide = not value
                                    WarfrontRareTracker:RefreshMinimap()
                                end,
                        },
                        showMenu = {
                            name = "Show Menu",
                            desc = "Select how you want to show the menu.",
                            type = "select",
                            style = "dropdown",
                            order = 2,
                            values = { ["mouse"]="On Mouse-Over", ["click"]="On Left-Click" },
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.showMenuOn
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.showMenuOn = value
                                end,
                        },
                    },
                },
                broker = {
                    name = "Broker Options",
                    order = 2,
                    type = "group",
                    inline = true,
                    args = {
                        showBrokerText = {
                            name = "Show Broker Text",
                            desc = "Shows Broker Text. (You only see the Icon when Disabled)",
                            type = "toggle",
                            --width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.broker.showBrokerText
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.broker.showBrokerText = value
                                    WarfrontRareTracker:RefreshBrokerText()
                                end,
                        },
                        brokerText = {
                            name = "Broker Text",
                            desc = "Select which text the broker shows.",
                            type = "select",
                            style = "dropdown",
                            order = 2,
                            values = { ["addonname"]="Addon Name", ["factionstatus"]="Faction Warfront Status", ["allstatus"]="All Warfront Status", ["zonename"]="Selected Zone Name" },
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.broker.brokerText
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.broker.brokerText = value
                                    WarfrontRareTracker:RefreshBrokerText()
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.broker.showBrokerText end,
                        },
                        seperator = {
                            name = WarfrontRareTracker:ColorizeText("Update Interval:", colors.yellow),
                            type = "description",
                            order = 3,
                        },
                        updateIntervalState1 = {
                            name = "'Percentage' Stage",
                            desc = "Select the interval on which the text updates.",
                            type = "select",
                            style = "dropdown",
                            order = 4,
                            values = intervalTimes,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.broker.updateIntervalState1
                            end,
                            set = function(info, value)
                                        WarfrontRareTracker.db.profile.broker.updateIntervalState1 = value
                                        WarfrontRareTracker:RefreshBrokerText()
                                end,
                            hidden = function(info) return isBrokerIntervalDisabled() end,
                        },
                        updateIntervalState2 = {
                            name = "'Time Left' Stage",
                            desc = "Select the interval on which the text updates.",
                            type = "select",
                            style = "dropdown",
                            order = 5,
                            values = intervalTimes,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.broker.updateIntervalState2
                            end,
                            set = function(info, value)
                                        WarfrontRareTracker.db.profile.broker.updateIntervalState2 = value
                                        WarfrontRareTracker:RefreshBrokerText()
                                end,
                            hidden = function(info) return isBrokerIntervalDisabled() end,
                        },
                        brokerTextDescription = {
                            name = WarfrontRareTracker:ColorizeText("\nNote:",colors.yellow)..WarfrontRareTracker:ColorizeText(" The Broker/Minimap icon shows which faction is currently in control of the Warfront!\n",colors.turqoise)..
                                    WarfrontRareTracker:ColorizeText("If the Controlling Faction is unknown it will display the good old Net Icon.",colors.turqoise)..
                                    WarfrontRareTracker:ColorizeText("\n\nMore info about the Broker Text options:\n\n",colors.yellow)..
                                    WarfrontRareTracker:ColorizeText("Addon Name", colors.lightcyan).." and "..WarfrontRareTracker:ColorizeText("Selected Zone Name", colors.lightcyan).." speaks for themself.\n\n"..
                                    WarfrontRareTracker:ColorizeText("Faction Warfront Status", colors.lightcyan).." only shows info about your faction:\n"..
                                    "When your faction is currently in the 'Gathering stage' it will show:\n"..
                                    WarfrontRareTracker:ColorizeText("Gathering: ", colors.turqoise)..WarfrontRareTracker:ColorizeText("50%",colors.yellow).."\n"..
                                    "Once the 'Gathering stage' is completed it will display the time left for the Scenario:\n"..
                                    WarfrontRareTracker:ColorizeText("Scenario: ", colors.turqoise)..WarfrontRareTracker:ColorizeText("5D 7H 35M Left",colors.green).."\n"..
                                    "When the opposite faction is in control of the Warfront it will show:\n"..
                                    WarfrontRareTracker:ColorizeText("Horde", colors.red)..WarfrontRareTracker:ColorizeText(" Has Control", colors.turqoise).."\n\n"..
                                    WarfrontRareTracker:ColorizeText("All Warfront Status", colors.lightcyan).." shows information about both Factions and can be seen on both factions, here are 2 examples:\n"..
                                    WarfrontRareTracker:ColorizeText("(A) ", colors.blue)..WarfrontRareTracker:ColorizeText("Gathering: ", colors.turqoise)..WarfrontRareTracker:ColorizeText("50%",colors.yellow).." or "..
                                    WarfrontRareTracker:ColorizeText("(H) ", colors.red)..WarfrontRareTracker:ColorizeText("Scenario: ", colors.turqoise)..WarfrontRareTracker:ColorizeText("5D 7H 35M Left",colors.green).."\n"..
                                    "The letter between the braces indicates which Faction is the NON controlling faction, including it's progress: "..WarfrontRareTracker:ColorizeText("Gathering:", colors.turqoise).." or "..WarfrontRareTracker:ColorizeText("Scenario:", colors.turqoise),
                            type = "description",
                            order = 10,
                        },
                    },
                },
            },
        },
        menuGeneral = {
            name = "Menu Options", -- showOnCombat
            type = "group",
            order = 3,
            args = {
                general = {
                    name = "General Options",
                    order = 1,
                    type = "group",
                    inline = true,
                    args = {
                        showAtMaxLevel = {
                            name = "Only Show At Level 120",
                            desc = "Only show the menu when your Character is level 120.",
                            type = "toggle",
                            width = 1.3,
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.showAtMaxLevel
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.showAtMaxLevel = value
                                end,
                        },
                        hideOnCombat = {
                            name = "Hide On Combat",
                            desc = "Don't show the menu while you're in combat.",
                            type = "toggle",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.hideOnCombat
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.hideOnCombat = value
                                end,
                        },
                        clickToTomTom = {
                            name = "Click To Add TomTom Waypoint",
                            desc = "Click on the Rare in the menu to add a TomTom Waypoint.",
                            type = "toggle",
                            width = "full",
                            order = 3,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.clickToTomTom
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.clickToTomTom = value
                                end,
                            disabled = function() return isTomTomlocked or not WarfrontRareTracker.db.profile.tomtom.enableIntegration end,
                        },
                    },
                },
                hide = {
                    name = "Hide Options",
                    order = 2,
                    type = "group",
                    inline = true,
                    args = {
                        hideAlreadyKnown = {
                            name = "Hide Known Items",
                            desc = "Hides Rare's of which drop you already know.",
                            type = "toggle",
                            width = 1,
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.hideAlreadyKnown
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.hideAlreadyKnown = value
                                end,
                        },
                        hideGoliaths = {
                            name = "Hide Goliaths",
                            desc = "Hides the Goliaths as they don't drop a learnable item.",
                            type = "toggle",
                            width = 1,
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.hideGoliaths
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.hideGoliaths = value
                                end,
                        },
                        whitelist = {
                            name = "Whitelist:",
                            desc = "Select which 'Already Know' drop you still want to show.",
                            type = "multiselect",
                            width = "half",
                            order = 3,
                            values = whitelist,
                            get = function(info, key)
                                    return WarfrontRareTracker.db.profile.menu.whitelist[key]
                                end,
                            set = function(info, key, value)
                                    WarfrontRareTracker.db.profile.menu.whitelist[key] = value
                                end,
                            hidden = function() return not WarfrontRareTracker.db.profile.menu.hideAlreadyKnown end,
                        },
                    },
                },
                warfront = {
                    name = "Warfront Status",
                    order = 3,
                    type = "group",
                    inline = true,
                    args = {
                        showWarfrontOnTitle = {
                            name = "Warfront Status In Title",
                            desc = "Shows Warfront Status when mouse over the title of the menu.",
                            type = "toggle",
                            width = 1.3,
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.showWarfrontOnTitle
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.showWarfrontOnTitle = value
                                end,
                        },
                        showWarfrontTitle = {
                            name = "Show Warfront:",
                            desc = "Select which warfront you want to show.",
                            type = "select",
                            style = "dropdown",
                            order = 2,
                            values = { ["current"]="Current Selected", ["all"]="All Warfronts" },
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.showWarfrontTitle
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.showWarfrontTitle = value
                                end,
                            hidden = function() return not WarfrontRareTracker.db.profile.menu.showWarfrontOnTitle end,
                        },
                        seperator = {
                            name = "",
                            type = "description",
                            order = 3,
                        },
                        showWarfrontInMenu = {
                            name = "Warfront Status In Menu",
                            desc = "Shows Warfront Status in the menu.",
                            type = "toggle",
                            width = 1.3,
                            order = 4,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.showWarfrontInMenu
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.showWarfrontInMenu = value
                                end,
                        },
                        showWarfrontMenu = {
                            name = "Show Warfront:",
                            desc = "Select which warfront you want to show.",
                            type = "select",
                            style = "dropdown",
                            order = 5,
                            values = { ["current"]="Current Selected", ["all"]="All Warfronts" },
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.showWarfrontMenu
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.showWarfrontMenu = value
                                end,
                            hidden = function() return not WarfrontRareTracker.db.profile.menu.showWarfrontInMenu end,
                        },
                    },
                },
                zonechange = {
                    name = "Auto Change Warfront Options",
                    order = 4,
                    type = "group",
                    inline = true,
                    args = {
                        autoChangeZone = {
                            name = "Auto Change Warfront On Zone-in",
                            desc = "Automatically change the menu to the Warfront you just 'zoned' in.\nWhen you leave the Warfront zone it changes back to your saved one, unless you've selected the 'Save' option below.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.autoChangeZone
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.autoChangeZone = value
                                    WarfrontRareTracker:CheckMapChange()
                                end,
                            disabled = function() return not hasMultipleRareDB end,
                        },
                        autoSaveZone = {
                            name = "Auto Save 'Zoned-in' Warfront",
                            desc = "Automatically saves the Warfront you just 'zoned' in as being tracked.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.autoSaveZone
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.autoSaveZone = value
                                end,
                            disabled = function() return not hasMultipleRareDB or not WarfrontRareTracker.db.profile.menu.autoChangeZone end,
                        },
                    },
                },
            },
        },
        menusorting = {
            name = "Menu Sorting",
            type = "group",
            order = 4,
            args = {
                sort = {
                    name = "Sorting Options",
                    order = 5,
                    type = "group",
                    inline = true,
                    args = {
                        worldbossOnTop = {
                            name = "World Boss Always On Top",
                            desc = "Shows the World Boss always on the top of the menu.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.worldbossOnTop
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.worldbossOnTop = value
                                    WarfrontRareTracker:SortRares()
                                end,
                        },
                        sortRaresOn = {
                            name = "Sort Rare's On",
                            desc = "Select how the Rare's are sorted in the menu.",
                            type = "select",
                            style = "dropdown",
                            order = 2,
                            values = { ["type"]="Rare Type", ["drop"]="Rare Drop", ["name"]="Rare Name" },
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.sortRaresOn
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.sortRaresOn = value
                                    WarfrontRareTracker:SortRares()
                                end,
                        },
                        groupTypeSortOn = {
                            name = "Group Sorted Rare's On",
                            desc = "Select how the Rare's are grouped in the menu.",
                            type = "select",
                            style = "dropdown",
                            order = 3,
                            values = { ["drop"]="Drop", ["name"]="Name" },
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.groupTypeSortOn
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.groupTypeSortOn = value
                                    WarfrontRareTracker:SortRares()
                                end,
                            hidden = function(info)
                                    return WarfrontRareTracker.db.profile.menu.sortRaresOn ~= "type"
                                end,
                        },
                        groupDropSortOn = {
                            name = "Group Sorted Rare's On",
                            desc = "Select how the Rare's are grouped in the menu.",
                            type = "select",
                            style = "dropdown",
                            order = 4,
                            values = { ["type"]="Type (Elite, Rare, etc.)", ["name"]="Name" },
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.groupDropSortOn
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.groupDropSortOn = value
                                    WarfrontRareTracker:SortRares()
                                end,
                            hidden = function(info)
                                    return WarfrontRareTracker.db.profile.menu.sortRaresOn ~= "drop"
                                end,
                        },
                        seperator = {
                            name = "",
                            type = "description",
                            order = 5,
                        },
                        sortAscending = {
                            name = "Sort Order",
                            desc = "Select the order how the Rare's are sorted in the menu.",
                            type = "select",
                            style = "dropdown",
                            order = 6,
                            values = { ["true"]="Ascending", ["false"]="Descending" },
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.sortAscending
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.sortAscending = value
                                    WarfrontRareTracker:SortRares()
                                end,
                        },
                    },
                },
            },
        },
        colors = {
            name = "Color Options",
            type = "group",
            order = 5,
            args = {
                drops = {
                    name = "Color Known Items",
                    order = 1,
                    type = "group",
                    inline = true,
                    args = {
                        colorizeDrops = {
                            name = "Colorize Known Items",
                            desc = "Gives the item in the 'Drops' Collum a color if known and unknown.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.colors.colorizeDrops
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.colors.colorizeDrops = value
                                end,
                        },
                        knownColor = {
                            name = "Color Of Known Items",
                            desc = "Set the color of Known Items.",
                            type = "color",
                            order = 2,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.db.profile.colors.knownColor
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.db.profile.colors.knownColor
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.colors.colorizeDrops end,
                        },
                        unknownColor = {
                            name = "Color Of Unknown Items",
                            desc = "Set the color of Unknown Items.",
                            type = "color",
                            order = 3,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.db.profile.colors.unknownColor
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.db.profile.colors.unknownColor
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.colors.colorizeDrops end,
                        },
                    },
                },
                status = {
                    name = "Color Status Text",
                    order = 2,
                    type = "group",
                    inline = true,
                    args = {
                        colorizeStatus = {
                            name = "Custom Status text",
                            desc = "Use custom colors for the status text. When disabled it uses the default colors.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.colors.colorizeStatus
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.colors.colorizeStatus = value
                                end,
                        },
                        available = {
                            name = "Color Of 'Available'",
                            desc = "Set the color of the 'Available' status.",
                            type = "color",
                            order = 2,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.db.profile.colors.available
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.db.profile.colors.available
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.colors.colorizeStatus end,
                        },
                        defeated = {
                            name = "Color Of 'Defeated'",
                            desc = "Set the color of the 'Defeated' status.",
                            type = "color",
                            order = 3,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.db.profile.colors.defeated
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.db.profile.colors.defeated
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.colors.colorizeStatus end,
                        },
                    },
                },
                rares = {
                    name = "Color Rare Names",
                    order = 3,
                    type = "group",
                    inline = true,
                    args = {
                        colorizeRares = {
                            name = "Color Rare Names",
                            desc = "Use colors for the Rare names based on their type. When disabled all names are white.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.colors.colorizeRares
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.colors.colorizeRares = value
                                end,
                        },
                        worldboss = {
                            name = "Color Of 'World Boss'",
                            desc = "Set the color of the 'World Boss' Rare's.",
                            type = "color",
                            order = 2,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.db.profile.colors.worldboss
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.db.profile.colors.worldboss
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.colors.colorizeRares end,
                        },
                        elite = {
                            name = "Color Of 'Elite'",
                            desc = "Set the color of the 'Elite' Rares.",
                            type = "color",
                            order = 3,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.db.profile.colors.elite
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.db.profile.colors.elite
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.colors.colorizeRares end,
                        },
                        seperator = {
                            name = "",
                            type = "description",
                            order = 4,
                        },
                        rare = {
                            name = "Color Of 'Rare'",
                            desc = "Set the color of the 'Rare' Rare's.",
                            type = "color",
                            order = 5,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.db.profile.colors.rare
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.db.profile.colors.rare
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.colors.colorizeRares end,
                        },
                        goliath = {
                            name = "Color Of 'Goliath'",
                            desc = "Set the color of the 'Goliath' Rares.",
                            type = "color",
                            order = 6,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.db.profile.colors.goliath
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.db.profile.colors.goliath
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.colors.colorizeRares end,
                        },
                    },
                },
            },
        },
        unitframes = {
            name = "Unit Frames",
            type = "group",
            order = 6,
            args = {
                unitframes = {
                    name = "NPC Unit Frame Options",
                    order = 1,
                    type = "group",
                    inline = true,
                    args = {
                        enableUnitframeIntegration = {
                            name = "Enable UnitFrame Integration",
                            desc = "Adds Status information to the Unit Frame Box.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.unitframe.enableUnitframeIntegration
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.unitframe.enableUnitframeIntegration = value
                                end,
                        },
                        compactMode = {
                            name = "Compact Mode",
                            desc = "Shows the Status information in a compact way.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.unitframe.compactMode
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.unitframe.compactMode = value
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.unitframe.enableUnitframeIntegration end,
                        },
                    },
                },
                hideoptions = {
                    name = "Show Info",
                    order = 4,
                    type = "group",
                    inline = true,
                    args = {
                        showStatus = {
                            name = "Show Status Text",
                            desc = "Adds Status information to the Unit Frame Box.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.unitframe.showStatus
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.unitframe.showStatus = value
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.unitframe.enableUnitframeIntegration end,
                        },
                        showDrop = {
                            name = "Show Loot",
                            desc = "Adds Loot information to the Unit Frame Box.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.unitframe.showDrop
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.unitframe.showDrop = value
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.unitframe.enableUnitframeIntegration end,
                        },
                        showAlreadyKnown = {
                            name = "Show Already Known Info",
                            desc = "Adds 'Already Known' to the Unit Frame Box when you already know the item.",
                            type = "toggle",
                            width = "full",
                            order = 3,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.unitframe.showAlreadyKnown = value
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.unitframe.enableUnitframeIntegration end,
                        },
                        description = {
                            name = WarfrontRareTracker:ColorizeText("\nNote:\n", colors.yellow)..
                            "A 'Unit Frame' is the popup box you'll see in the bottom right corner of your screen when you mouse-over a NPC, showing it's name and level by default.\n"..
                            "These options add's relevant information to the Unit Frame.",
                            type = "description",
                            order = 4,
                        },
                    },
                },
            },
        },
        worldmap = {
            name = "Worldmap",
            type = "group",
            order = 7,
            args = {
                worldmap = {
                    name = "Worldmap Icons",
                    order = 1,
                    type = "group",
                    inline = true,
                    args = {
                        showWorldmapIcons = {
                            name = "Show Worldmap Icons",
                            desc = "Adds Icons to the Worldmap showing you where a Rare can be found.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.worldmapicons.showWorldmapIcons
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.worldmapicons.showWorldmapIcons = value
                                    WarfrontRareTracker:UpdateAllWorldMapIcons()
                                end,
                        },
                        showOnlyAtMaxLevel = {
                            name = "Show Only At Level 120",
                            desc = "Show Worldmap Icons only at level 120. When lower then level 120 no Woldmap Icons will be shown, unless disabled.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.worldmapicons.showOnlyAtMaxLevel
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.worldmapicons.showOnlyAtMaxLevel = value
                                    refreshWorldmapIcons()
                                end,
                        },
                        clickToTomTom = {
                            name = "Click To Add TomTom Waypoint",
                            desc = "Click on the Rare's Icon to add a TomTom Waypoint.",
                            type = "toggle",
                            width = "full",
                            order = 3,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.worldmapicons.clickToTomTom
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.worldmapicons.clickToTomTom = value
                                end,
                            disabled = function() return isTomTomlocked or not WarfrontRareTracker.db.profile.tomtom.enableIntegration end,
                        },
                    },
                },
                hide = {
                    name = "Hide Icons",
                    order = 2,
                    type = "group",
                    inline = true,
                    args = {
                        hideIconWhenDefeated = {
                            name = "Hide When Defeated",
                            desc = "Hides the Icon when the Rare is Defeated.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.worldmapicons.hideIconWhenDefeated
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.worldmapicons.hideIconWhenDefeated = value
                                    refreshWorldmapIcons()
                                end,
                        },
                        hideGoliaths = {
                            name = "Hide Goliaths",
                            desc = "Hides the Icon of the Goliaths.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.worldmapicons.hideGoliaths
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.worldmapicons.hideGoliaths = value
                                    refreshWorldmapIcons()
                                end,
                        },
                        hideAlreadyKnown = {
                            name = "Hide Known Items",
                            desc = "Hides the Icon of the Rare's which drop you already know.",
                            type = "toggle",
                            width = "full",
                            order = 3,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.worldmapicons.hideAlreadyKnown
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.worldmapicons.hideAlreadyKnown = value
                                    refreshWorldmapIcons()
                                end,
                        },
                        whitelist = {
                            name = "Whitelist:",
                            desc = "Select which 'Already Know' drop you still want to show.",
                            type = "multiselect",
                            width = "half",
                            order = 4,
                            values = whitelist,
                            get = function(info, key)
                                    return WarfrontRareTracker.db.profile.worldmapicons.whitelist[key]
                                end,
                            set = function(info, key, value)
                                    WarfrontRareTracker.db.profile.worldmapicons.whitelist[key] = value
                                    refreshWorldmapIcons()
                                end,
                            hidden = function() return not WarfrontRareTracker.db.profile.worldmapicons.hideAlreadyKnown end,
                        },
                    },
                },
            },
        },
        tomtom = {
            name = "TomTom",
            type = "group",
            order = 8,
            args = {
                tomtom = {
                    name = "TomTom Integration (Requires TomTom)",
                    order = 1,
                    type = "group",
                    inline = true,
                    args = {
                        tomtomIntegration = {
                            name = "TomTom Integration",
                            desc = "Create a TomTom Waypoint when Clicked on a Rare in the menu.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.tomtom.enableIntegration
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.tomtom.enableIntegration = value
                                end,
                            disabled = function() return isTomTomlocked end,
                        },
                        tomtomChatMessage = {
                            name = "Output To Chat",
                            desc = "Prints a message in your Chat window when a waypoint is created.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                return WarfrontRareTracker.db.profile.tomtom.enableChatMessage
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.tomtom.enableChatMessage = value
                                end,
                            disabled = function() return isTomTomlocked or not WarfrontRareTracker.db.profile.tomtom.enableIntegration end,
                        }
                    },
                },
            },
        },
        soundMessage = {
            name = "Sounds & Messages",
            type = "group",
            order = 9,
            args = {
                zone = {
                    name = "Warfront Change Options",
                    type = "group",
                    order = 1,
                    inline = true,
                    args = {
                        enableZoneChangeSound = {
                            name = "Play Sound On Warfront Change",
                            desc = "Plays a sound when the controlling faction changes in a Warfront.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.general.enableZoneChangeSound
                                end,
                            set = function(info, value)
                                WarfrontRareTracker.db.profile.general.enableZoneChangeSound = value
                                end,
                        },
                    },
                },
                levelUp = {
                    name = "Level-Up Options",
                    type = "group",
                    order = 2,
                    inline = true,
                    args = {
                        enableLevelUpSound = {
                            name = "Play Sound On Max Level",
                            desc = "Plays a sound when the player reaches Max Level controlling faction changes in a Warfront, letting them know they now egliable to enter the Warfront.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.general.enableLevelUpSound
                                end,
                            set = function(info, value)
                                WarfrontRareTracker.db.profile.general.enableLevelUpSound = value
                                end,
                        },
                        enableLevelUpChatMessage = {
                            name = "Get Chat Message on Max Level",
                            desc = "Prints a message in your Chat window when the player reaches Max Level, letting them know they now egliable to enter the Warfront.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.general.enableLevelUpChatMessage
                                end,
                            set = function(info, value)
                                WarfrontRareTracker.db.profile.general.enableLevelUpChatMessage = value
                                end,
                        },
                    },
                },
            },
        },
    },
}

function WarfrontRareTracker:DelayedConfigInitialize()
    if IsAddOnLoaded("TomTom") then
        isTomTomlocked = false
    end
    local dbsize = WarfrontRareTracker:GetRareDBSize()
    if dbsize > 1 then
        hasMultipleRareDB = true
    end
end

local function checkConfigChanges()
    if WarfrontRareTracker.db.profile.profileversion == nil then
        WarfrontRareTracker.db.profile["profileversion"] = 1
    end
    if WarfrontRareTracker.db.profile.profileversion == 1 then
        WarfrontRareTracker.db.profile.profileversion = 2 -- Set the version one higher
        -- changes
        WarfrontRareTracker.db.profile.broker.brokerText = "addonname"
    end
end

function WarfrontRareTracker:RegisterOptions()
    configOptions.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(WarfrontRareTracker.db)
    configOptions.args.profiles.order = 10
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("WarfrontRareTracker", configOptions)
    checkConfigChanges()

    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WarfrontRareTracker", "WarfrontRareTracker")
    LibStub("AceConfigDialog-3.0"):SetDefaultSize("WarfrontRareTracker", 700, 575)
    WarfrontRareTracker:RegisterChatCommand("warfront", function() LibStub("AceConfigDialog-3.0"):Open("WarfrontRareTracker") end)
end