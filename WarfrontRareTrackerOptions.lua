local WarfrontRareTracker = LibStub("AceAddon-3.0"):GetAddon("WarfrontRareTracker")

local isTomTomlocked = true
local hasMultipleRareDB = false
local whitelist = { ["Mount"] = "Mounts", ["Pet"] = "Pets", ["Toy"] = "Toys", ["Quest"] = "Quests", ["Blueprint"] = "Blueprints", ["Transmog"] = "Transmog", ["Scroll"] = "Scroll", }
local defeatModes = { ["hide"] = "Hide Icon", ["change"] = "Change Icon", ["none"] = "Nothing" }
local brokerTexts = { ["addonname"] = "Addon Name", ["factionstatus"] = "Faction Warfront Status", ["allstatus"] = "All Warfront Status", ["zonename"] = "Selected Zone Name" }
local intervalTimes = { [1]="1 minute", [2] = "2 minutes", [3] = "3 minutes", [4] = "4 minutes", [5]="5 minutes", [10]="10 minutes", [15]="15 minutes", [30]="30 minutes", [60]="1 hour" }

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

local function refreshWorldmapIcons(masterfiltermode)
    if masterfiltermode then
        if WarfrontRareTracker.db.profile.worldmapicons.useMasterfilter and WarfrontRareTracker.db.profile.worldmapicons.showWorldmapIcons then
            WarfrontRareTracker:UpdateAllWorldMapIcons()
        end
    else
        if WarfrontRareTracker.db.profile.worldmapicons.showWorldmapIcons then
            WarfrontRareTracker:UpdateAllWorldMapIcons()
        end
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
                            values = brokerTexts,
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
            name = "Menu Options",
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
                            name = "Only Show At Level 50",
                            desc = "Only show the menu when your Character is level 50 or higher.",
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
                    order = 3,
                    type = "group",
                    inline = true,
                    args = {
                        useMasterfilter = {
                            name = "Use Master Filter",
                            desc = "Use Master Filter.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.useMasterfilter
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.useMasterfilter = value
                                end,
                        },
                        hideoptions = {
                            name = "Hide Options",
                            order = 10,
                            type = "group",
                            inline = true,
                            hidden = function() return WarfrontRareTracker.db.profile.menu.useMasterfilter end,
                            args = {
                                alwaysShowWorldboss = {
                                    name = "Always Show Worldboss",
                                    desc = "Don't hide the Icon for the Worldbosses if it contains no loot on already known loot. Unless it's killed and you have a \"Hide When Defeated\" option selected somewhere.",
                                    type = "toggle",
                                    width = 1.2,
                                    order = 1,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.alwaysShowWorldboss
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.alwaysShowWorldboss = value
                                        end,
                                },
                                hideGoliaths = {
                                    name = "Hide Goliaths",
                                    desc = "Hides the Goliaths as they don't drop a learnable item.",
                                    type = "toggle",
                                    width = 1.2,
                                    order = 2,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.hideGoliaths
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.hideGoliaths = value
                                        end,
                                },
                                hideAncients = {
                                    name = "Hide Ancients",
                                    desc = "Hides the Icons of the Ancients in Nazjatar.",
                                    type = "toggle",
                                    width = 1.2,
                                    order = 3,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.hideAncients
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.hideAncients = value
                                        end,
                                },
                                hideUnavailable = {
                                    name = "Hide Unavailable Rares",
                                    desc = "An Unavailable Rare is a Rare who is only up when your faction has control over the Warfront Zone, but the opposite side has currently control. This indicates you cannot pay him a visit at this moment. It can in some cases be a rare with missing information.",
                                    type = "toggle",
                                    width = 1.2,
                                    order = 4,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.hideUnavailable
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.hideUnavailable = value
                                        end,
                                },
                                hideUntrackable = {
                                    name = "Hide Untrackable Rares",
                                    desc = "An Untrackable Rare is a Rare without a QuestID attached to test if you have killed him or not. Currently only the 'Frightened Kodo' in Darkshore is one of them",
                                    type = "toggle",
                                    width = 1.2,
                                    order = 5,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.hideUntrackable
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.hideUntrackable = value
                                        end,
                                },
                                hideUnknowLoot = {
                                    name = "Hide Unknown Loot",
                                    desc = "Hides the Rare's that don't drop a learnable item.",
                                    type = "toggle",
                                    width = 1.2,
                                    order = 6,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.hideUnknowLoot
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.hideUnknowLoot = value
                                        end,
                                },
                                hideGearOnly = {
                                    name = "Hide Gear Only",
                                    desc = "Hides the Rare's that only drops Gear.",
                                    type = "toggle",
                                    width = 1.2,
                                    order = 7,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.hideGearOnly
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.hideGearOnly = value
                                        end,
                                },
                                hideQuestOnly = {
                                    name = "Hide Quest Only",
                                    desc = "Hides the Rare's that only drops Quest items.",
                                    type = "toggle",
                                    width = 1.2,
                                    order = 8,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.hideQuestOnly
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.hideQuestOnly = value
                                        end,
                                },
                                description = {
                                    name = "I personally think you will have to do the quest but you can use this option for the menu only so the icons stay. I'm working on an implementation on checking wheter the quest has been completed and markt it as \"Complete\", but before that you can manually disable the big quest list in the Menu Options",
                                    type = "description",
                                    width = "full",
                                    order = 9,
                                },
                                hideItemOnly = {
                                    name = "Hide Item Only",
                                    desc = "Hides the Rare's that only drop Items.",
                                    type = "toggle",
                                    width = 1.2,
                                    order = 10,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.hideItemOnly
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.hideItemOnly = value
                                        end,
                                },
                                hideBlueprintOnly = {
                                    name = "Hide Blueprint Only",
                                    desc = "Hides the Rare's that only drop Blueprints.",
                                    type = "toggle",
                                    width = 1.2,
                                    order = 11,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.hideBlueprintOnly
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.hideBlueprintOnly = value
                                        end,
                                },
                                hideTransmogOnly = {
                                    name = "Hide Transmog Only",
                                    desc = "Hides the Rare's that only drop Transmog.",
                                    type = "toggle",
                                    width = 1.2,
                                    order = 12,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.hideTransmogOnly
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.hideTransmogOnly = value
                                        end,
                                },
                                hideAnimaOnly = {
                                    name = "Hide Anima Only",
                                    desc = "Hides the Rare's that only drop Anima.",
                                    type = "toggle",
                                    width = 1.2,
                                    order = 13,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.hideAnimaOnly
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.hideAnimaOnly = value
                                        end,
                                },
                                showCovenantBoundRares = {
                                    name = "Show All Covenant Bound Rare's",
                                    desc = "Some Rare's or are bound to the Covenant you sign up for. By default these are hidded. If you Enable this option you are able to see all Rare's from all Covenants." .. WarfrontRareTracker:ColorizeText("\nWarning: ",colors.red) .. WarfrontRareTracker:ColorizeText("You're most likely not able to interact with and/or loot these Rare's!",colors.orange),
                                    type = "toggle",
                                    width = 1.2,
                                    order = 15,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.showCovenantBoundRares
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.showCovenantBoundRares = value
                                        end,
                                },
                                showCovenantBoundLoot = {
                                    name = "Show Rare's With Loot From All Covenants",
                                    desc = "Some Rare's Loot is bound to the Covenant you sign up for. By default these are hidded. If you Enable this option you are able to see the Loot from all Covenants." .. WarfrontRareTracker:ColorizeText("\nWarning: ",colors.red) .. WarfrontRareTracker:ColorizeText("You're most likely not able to interact with and/or loot these Rare's!",colors.orange),
                                    type = "toggle",
                                    width = 1.2,
                                    order = 16,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.showCovenantBoundLoot
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.showCovenantBoundLoot = value
                                        end,
                                },
                                hideAlreadyKnown = {
                                    name = "Hide Known Items",
                                    desc = "Hides Rare's of which drop you already know.",
                                    type = "toggle",
                                    width = 1.2,
                                    order = 19,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.menu.hideAlreadyKnown
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.menu.hideAlreadyKnown = value
                                        end,
                                },
                                whitelist = {
                                    name = "Whitelist:",
                                    desc = "Select which 'Already Know' drop you still want to show.",
                                    type = "multiselect",
                                    width = "half",
                                    order = 20,
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
                    },
                },
                warfront = {
                    name = "Warfront Status",
                    order = 4,
                    type = "group",
                    inline = true,
                    args = {
                        showWarfrontOnZoneName = {
                            name = "Warfront Status On Zone Name",
                            desc = "Shows Warfront Status when mouse over the title of the zone.",
                            type = "toggle",
                            width = 1.3,
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.menu.showWarfrontOnZoneName
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.menu.showWarfrontOnZoneName = value
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
                            disabled = function() return not WarfrontRareTracker.db.profile.menu.showWarfrontOnZoneName end,
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
                            disabled = function() return not WarfrontRareTracker.db.profile.menu.showWarfrontInMenu end,
                        },
                    },
                },
                zonechange = {
                    name = "Auto Change Warfront Options",
                    order = 5,
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
                    order = 1,
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
                        seperator = {
                            name = "",
                            type = "description",
                            order = 10,
                        },
                        
                    },
                },
                lootTypeOrder = {
                    name = "Loot Type Order",
                    order = 11,
                    type = "group",
                    inline = true,
                    hidden = function(info)
                        return WarfrontRareTracker.db.profile.menu.sortRaresOn ~= "drop"
                    end,
                    args = { -- Script generates this
                        seperator = {
                            name = "Test",
                            type = "description",
                            order = 1,
                        },
                    },
                },
            },
        },
        masterfilter = {
            name = "Master Filter",
            type = "group",
            order = 5,
            args = {
                hideOptions = {
                    name = "Shared Filter Options",
                    order = 1,
                    type = "group",
                    inline = true,
                    args = {
                        alwaysShowWorldboss = {
                            name = "Always Show Worldboss",
                            desc = "Don't hide the Icon for the Worldbosses if it contains no loot on already known loot. Unless it's killed and you have a \"Hide When Defeated\" option selected somewhere.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.alwaysShowWorldboss
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.alwaysShowWorldboss = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        hideGoliaths = {
                            name = "Hide Goliaths",
                            desc = "Hides the Icons of the Goliaths.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.hideGoliaths
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.hideGoliaths = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        hideAncients = {
                            name = "Hide Ancients",
                            desc = "Hides the Icons of the Ancients in Nazjatar.",
                            type = "toggle",
                            width = "full",
                            order = 3,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.hideAncients
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.hideAncients = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        hideUnavailable = {
                            name = "Hide Unavailable Rares",
                            desc = "An Unavailable Rare is a Rare who is only up when your faction has control over the Warfront Zone, but the opposite side has currently control. This indicates you cannot pay him a visit at this moment. It can in some cases be a rare with missing information.",
                            type = "toggle",
                            width = "full",
                            order = 4,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.hideUnavailable
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.hideUnavailable = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        hideUntrackable = {
                            name = "Hide Untrackable Rares",
                            desc = "An Untrackable Rare is a Rare without a QuestID attached to test if you have killed him or not. Currently only the 'Frightened Kodo' in Darkshore is one of them",
                            type = "toggle",
                            width = "full",
                            order = 5,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.hideUntrackable
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.hideUntrackable = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        hideUnknowLoot = {
                            name = "Hide Unknown Loot",
                            desc = "Hides the Rare's that don't drop a learnable item.",
                            type = "toggle",
                            width = "full",
                            order = 6,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.hideUnknowLoot
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.hideUnknowLoot = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        hideGearOnly = {
                            name = "Hide Gear Only",
                            desc = "Hides the Rare's that only drops Gear.",
                            type = "toggle",
                            width = "full",
                            order = 7,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.hideGearOnly
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.hideGearOnly = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        hideQuestOnly = {
                            name = "Hide Quest Only",
                            desc = "Hides the Rare's that only drops Quest items.",
                            type = "toggle",
                            width = "full",
                            order = 8,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.hideQuestOnly
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.hideQuestOnly = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        description = {
                            name = "I personally think you will have to do the quest but you can use this option for the menu only so the icons stay. I'm working on an implementation on checking wheter the quest has been completed and markt it as \"Complete\", but before that you can manually disable the big quest list in the Menu Options",
                            type = "description",
                            width = "full",
                            order = 9,
                        },
                        hideItemOnly = {
                            name = "Hide Item Only",
                            desc = "Hides the Rare's that only drop Items.",
                            type = "toggle",
                            width = "full",
                            order = 10,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.hideItemOnly
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.hideItemOnly = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        hideBlueprintOnly = {
                            name = "Hide Blueprint Only",
                            desc = "Hides the Rare's that only drop Blueprints.",
                            type = "toggle",
                            width = "full",
                            order = 11,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.hideBlueprintOnly
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.hideBlueprintOnly = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        ignoreAssault = {
                            name = "Ignore Assaults",
                            desc = "Shows all Rare's in Uldum and Vale of Eternal Blossoms.",
                            type = "toggle",
                            width = "full",
                            order = 12,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.ignoreAssault
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.ignoreAssault = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        hideTransmogOnly = {
                            name = "Hide Transmog Only",
                            desc = "Hides the Rare's that only drop Transmog.",
                            type = "toggle",
                            width = "full",
                            order = 13,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.hideTransmogOnly
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.hideTransmogOnly = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        hideAnimaOnly = {
                            name = "Hide Anima Only",
                            desc = "Hides the Rare's that only drop Anima.",
                            type = "toggle",
                            width = "full",
                            order = 14,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.hideAnimaOnly
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.hideAnimaOnly = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        showCovenantBoundRares = {
                            name = "Show All Covenant Bound Rare's",
                            desc = "Some Rare's or are bound to the Covenant you sign up for. By default these are hidded. If you Enable this option you are able to see all Rare's from all Covenants." .. WarfrontRareTracker:ColorizeText("\nWarning: ",colors.red) .. WarfrontRareTracker:ColorizeText("You're most likely not able to interact with and/or loot these Rare's!",colors.orange),
                            type = "toggle",
                            width = "full",
                            order = 15,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.showCovenantBoundRares
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.showCovenantBoundRares = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        showCovenantBoundLoot = {
                            name = "Show Rare's With Loot From All Covenants",
                            desc = "Some Rare's Loot is bound to the Covenant you sign up for. By default these are hidded. If you Enable this option you are able to see the Loot from all Covenants." .. WarfrontRareTracker:ColorizeText("\nWarning: ",colors.red) .. WarfrontRareTracker:ColorizeText("You're most likely not able to interact with and/or loot these Rare's!",colors.orange),
                            type = "toggle",
                            width = "full",
                            order = 16,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.showCovenantBoundLoot
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.showCovenantBoundLoot = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        hideAlreadyKnown = {
                            name = "Hide Known Items",
                            desc = "Hides the Icon of the Rare's which drop you already know.",
                            type = "toggle",
                            width = "full",
                            order = 19,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.hideAlreadyKnown
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.hideAlreadyKnown = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        whitelist = {
                            name = "Whitelist:",
                            desc = "Select which 'Already Know' drop you still want to show.",
                            type = "multiselect",
                            width = "half",
                            order = 20,
                            values = whitelist,
                            get = function(info, key)
                                    return WarfrontRareTracker.db.profile.masterfilter.whitelist[key]
                                end,
                            set = function(info, key, value)
                                    WarfrontRareTracker.db.profile.masterfilter.whitelist[key] = value
                                    refreshWorldmapIcons(true)
                                end,
                            hidden = function() return not WarfrontRareTracker.db.profile.masterfilter.hideAlreadyKnown end,
                        },
                    },
                },
                worldmap = {
                    name = "Worldmap Options",
                    order = 3,
                    type = "group",
                    inline = true,
                    args = {
                        worldmapHandleDefeated = {
                            name = "What to do with Defeated Rare's",
                            desc = "What to do with Defeated Rare's.",
                            type = "select",
                            order = 1,
                            values = defeatModes,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.worldmapHandleDefeated
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.worldmapHandleDefeated = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        worldmapShowOnlyAtPhase = {
                            name = "Show Only In Warfront Phase",
                            desc = "Only Show Worldmap Icons while the zone is in the Warfron Phase.\nWhen you talk to a \"Time Traveler NPC\" in the area to return to the past the Icons will disappear.\nTalk again to go to the present time enables the Icons again.\n\nThis feature overrules \"Show Only at Level 50 or higher\" as low level characters always are in the 'past' phase of the zone, so no Icons will be shown.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.worldmapShowOnlyAtPhase
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.worldmapShowOnlyAtPhase = value
                                    refreshWorldmapIcons(true)
                                end,
                        },
                        worldmapShowOnlyAtMaxLevel = {
                            name = "Show Only At Level 50",
                            desc = "Show Worldmap Icons only at level 50 or higher. When lower then level 50 no Woldmap Icons will be shown, unless disabled.",
                            type = "toggle",
                            width = "full",
                            order = 3,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.masterfilter.worldmapShowOnlyAtMaxLevel
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.masterfilter.worldmapShowOnlyAtMaxLevel = value
                                    refreshWorldmapIcons(true)
                                end,
                            disabled = function() return WarfrontRareTracker.db.profile.masterfilter.worldmapShowOnlyAtPhase end,
                        },
                    },
                },
            },
        },
        lootwindow = {
            name = "Loot Window",
            type = "group",
            order = 6,
            args = {
                compactmode = {
                    name = "Loot Window Options",
                    order = 1,
                    type = "group",
                    inline = true,
                    args = {
                        compactMode = {
                            name = "Compact Mode",
                            desc = "Enable/Disable Compact Loot Window.\n[Compact on Amount] lets you choose how many enties a Rare hs to be to get a Copacted list.\n[Compact All] always gives you a compacted list but in inadviced as it doesn't diaplay all information about the Loot",
                            type = "select",
                            style = "dropdown",
                            order = 2,
                            values = { ["amount"] = "Compact on Amount", ["all"] = "Compact All", ["disabled"] = "Disabled" },
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.lootwindow.compactMode
                            end,
                            set = function(info, value)
                                        WarfrontRareTracker.db.profile.lootwindow.compactMode = value
                                end,
                        },
                        compactModeAmount = {
                            name = "Compact if more than: ",
                            desc = "Select the amount of drops before Compacting the information in the Loot Window",
                            type = "select",
                            style = "dropdown",
                            order = 3,
                            values = {[1] = 1,[2] = 2,[3] = 3,[4] = 4,[5] = 5, [6] = 6, [7] = 7, [8] = 8, [9] = 9},
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.lootwindow.compactModeAmount
                            end,
                            set = function(info, value)
                                        WarfrontRareTracker.db.profile.lootwindow.compactModeAmount = value
                                end,
                            hidden = function(info)
                                return WarfrontRareTracker.db.profile.lootwindow.compactMode ~= "amount"
                            end,
                        },
                        alsohidenotes = {
                            name = "Also Hide Notes",
                            desc = "Also hide Notes in the Loot Window while mousing over a Rare in the Menu or Worldmap.",
                            type = "toggle",
                            width = "full",
                            order = 4,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.lootwindow.alsohidenotes
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.lootwindow.alsohidenotes = value
                                end,
                        },
                        description = {
                            name = WarfrontRareTracker:ColorizeText("\nNote:\n", colors.yellow)..
                            "As a lot of Rares drops multiple items the Loot Window you see while mousing over a Rare in the Menu or Worldmap get big and can even slide under your UI.\n"..
                            "These options allow you to make the Loot window show less information for all with the first option, or the default option, when a Rare had more than 3 drops.",
                            type = "description",
                            order = 5,
                        },
                    },
                },
                -- showCovenantBoundLoot = { -- NYI
                --     name = "Show other Covenant's Loot [NYI]",
                --     order = 2,
                --     type = "group",
                --     inline = true,
                --     args = {
                --         showCovenantBoundLoot = {
                --             name = "Show Covenant Bound Rare's and Loot [NYI]",
                --             desc = "Some Rare's Loot is bound to the Covenant you sign up for. By default these left out of the list. If you Enable this option you are able to see the hidden Loot from all Covenants." .. WarfrontRareTracker:ColorizeText("\nWarning: ",colors.red) .. WarfrontRareTracker:ColorizeText("Covenant Bound Loot for other Covenant's doesn't drop!",colors.orange),
                --             type = "toggle",
                --             width = "full",
                --             order = 1,
                --             get = function(info)
                --                     return WarfrontRareTracker.db.profile.lootwindow.showCovenantBoundLoot
                --                 end,
                --             set = function(info, value)
                --                     WarfrontRareTracker.db.profile.lootwindow.showCovenantBoundLoot = value
                --                 end,
                --         },
                --     },
                -- },
            },
        },
        colors = {
            name = "Color Options",
            type = "group",
            order = 7,
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
                        seperator2 = {
                            name = "",
                            type = "description",
                            order = 7,
                        },
                        rare = {
                            name = "Color Of 'Uncommon'",
                            desc = "Set the color of the 'Uncommon' Rare's. This is the old Warfront's 'Rare' color as the new ones have quite some more HP.",
                            type = "color",
                            order = 8,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.db.profile.colors.uncommon
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.db.profile.colors.uncommon
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.colors.colorizeRares end,
                        },
                    },
                },
                menu = {
                    name = "Menu's",
                    order = 4,
                    type = "group",
                    inline = true,
                    args = {
                        menuAlpha = {
                            name = "Menu Alpha",
                            desc = "Set the Menu Alpha.",
                            type = "range",
                            order = 1,
                            min = 1,
                            max = 100,
                            step = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.colors.menuAlpha * 100
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker:SetMenuAlpha(value)
                                end,
                        },
                    },
                },
            },
        },
        unitframes = {
            name = "Unit Frames",
            type = "group",
            order = 8,
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
            name = "Worldmap & Minimap",
            type = "group",
            order = 9,
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
                        showOnlyAtPhase = {
                            name = "Show Only In Warfront Phase",
                            desc = "Only Show Worldmap Icons while the zone is in the Warfron Phase.\nWhen you talk to a \"Time Traveler NPC\" in the area to return to the past the Icons will disappear.\nTalk again to go to the present time enables the Icons again.\n\nThis feature overrules \"Show Only at Level 50 or higher\" as low level characters always are in the 'past' phase of the zone, so no Icons will be shown.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.worldmapicons.showOnlyAtPhase
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.worldmapicons.showOnlyAtPhase = value
                                    refreshWorldmapIcons(false)
                                end,
                        },
                        showOnlyAtMaxLevel = {
                            name = "Show Only At Level 50",
                            desc = "Show Worldmap Icons only at level 50 or higher. When lower then level 50 no Woldmap Icons will be shown, unless disabled.",
                            type = "toggle",
                            width = "full",
                            order = 6,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.worldmapicons.showOnlyAtMaxLevel
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.worldmapicons.showOnlyAtMaxLevel = value
                                    refreshWorldmapIcons(false)
                                end,
                            disabled = function() return WarfrontRareTracker.db.profile.worldmapicons.showOnlyAtPhase end,
                        },
                        clickToTomTom = {
                            name = "Click Worldmap To Add TomTom Waypoint",
                            desc = "Click on the Rare's Icon to add a TomTom Waypoint.",
                            type = "toggle",
                            width = "full",
                            order = 7,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.worldmapicons.clickToTomTom
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.worldmapicons.clickToTomTom = value
                                end,
                            disabled = function() return isTomTomlocked or not WarfrontRareTracker.db.profile.tomtom.enableIntegration end,
                        },
                        description = {
                            name = WarfrontRareTracker:ColorizeText("\nIcon Settings:\n", colors.yellow),
                            type = "description",
                            order = 8,
                        },
                        iconSize = {
                            name = "Worldmap Icon Size",
                            desc = "Set the Worldmap Icon Size.",
                            type = "range",
                            order = 9,
                            min = 8,
                            max = 42,
                            step = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.worldmapicons.worldmapIconSize
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker:SetWorldmapIconSize(value, false)
                                end,
                        },
                        iconAlpha = {
                            name = "Worldmap Icon Alpha",
                            desc = "Set the Worldmap Icon Alpha.",
                            type = "range",
                            order = 10,
                            min = 1,
                            max = 100,
                            step = 1,
                            get = function(info)
                                    return WarfrontRareTracker:GetWorldmapIconAlpha(false)
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker:SetWorldmapIconAlpha(value, false)
                                end,
                        },
                        seperator = {
                            name = "",
                            type = "description",
                            order = 11,
                        },
                    },
                },
                minimap = {
                    name = "Minimap Icons",
                    order = 2,
                    type = "group",
                    inline = true,
                    args = {
                        showMinimapIcons = {
                            name = "Show Minimap Icons",
                            desc = "Adds Icons to the Minimap showing you where a Rare can be found.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.minimapIcons.showMinimapIcons
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.minimapIcons.showMinimapIcons = value
                                    WarfrontRareTracker:UpdateAllWorldMapIcons()
                                end,
                        },
                        onMinimapHoover = {
                            name = "Show Loot Info In Minimap",
                            desc = "Shows a Loot Info window while mousing over an icon on the Minimap.",
                            type = "toggle",
                            width = 1.3,
                            order = 4,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.minimapIcons.onMinimapHoover
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.minimapIcons.onMinimapHoover = value
                                    WarfrontRareTracker:UpdateAllWorldMapIcons()
                                end,
                        },
                        minimapIconsCompactMode = {
                            name = "Compact mode",
                            desc = "Minimalize the info showing while hoovering over an Icon in the Minimap.",
                            type = "toggle",
                            width = 1,
                            order = 5,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.minimapIcons.minimapIconsCompactMode
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.minimapIcons.minimapIconsCompactMode = value
                                    WarfrontRareTracker:UpdateAllWorldMapIcons()
                                end,
                            disabled = function() return not WarfrontRareTracker.db.profile.minimapIcons.onMinimapHoover end,
                        },
                        description = {
                            name = WarfrontRareTracker:ColorizeText("\nIcon Settings:\n", colors.yellow),
                            type = "description",
                            order = 8,
                        },
                        minimapIconSize = {
                            name = "Minimap Icon Size",
                            desc = "Set the Worldmap Icon Size.",
                            type = "range",
                            order = 12,
                            min = 8,
                            max = 42,
                            step = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.minimapIcons.minimapIconSize
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker:SetWorldmapIconSize(value, true)
                                end,
                        },
                        minimapIconAlpha = {
                            name = "Minimap Icon Alpha",
                            desc = "Set the Worldmap Icon Alpha.",
                            type = "range",
                            order = 13,
                            min = 1,
                            max = 100,
                            step = 1,
                            get = function(info)
                                    return WarfrontRareTracker:GetWorldmapIconAlpha(true)
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker:SetWorldmapIconAlpha(value, true)
                                end,
                        },
                    },
                },
                hide = {
                    name = "Hide Icons",
                    order = 3,
                    type = "group",
                    inline = true,
                    args = {
                        description = {
                            name = WarfrontRareTracker:ColorizeText("Note: ", colors.yellow) .. WarfrontRareTracker:ColorizeText("Both Worldmap Icons and Minimap Icons uses the same filter options!\n", colors.lightcyan),
                            type = "description",
                            order = 1,
                        },
                        useMasterfilter = {
                            name = "Use Master Filter",
                            desc = "Use Master Filter.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.worldmapicons.useMasterfilter
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.worldmapicons.useMasterfilter = value
                                    refreshWorldmapIcons(false)
                                end,
                        },
                        hideoptions = {
                            name = "Hide Options",
                            order = 10,
                            type = "group",
                            inline = true,
                            hidden = function() return WarfrontRareTracker.db.profile.worldmapicons.useMasterfilter end,
                            args = {
                                handleDefeated = {
                                    name = "What to do with Defeated Rare's",
                                    desc = "What to do with Defeated Rare's.",
                                    type = "select",
                                    style = "dropdown",
                                    --width = "half",
                                    order = 1,
                                    values = defeatModes,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.handleDefeated
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.handleDefeated = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                alwaysShowWorldboss = {
                                    name = "Always Show Worldboss",
                                    desc = "Don't hide the Icon for the Worldbosses if it contains no loot on already known loot. Unless it's killed and you have a \"Hide When Defeated\" option selected somewhere.",
                                    type = "toggle",
                                    width = "full",
                                    order = 2,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.alwaysShowWorldboss
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.alwaysShowWorldboss = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                hideGoliaths = {
                                    name = "Hide Goliaths",
                                    desc = "Hides the Icons of the Goliaths.",
                                    type = "toggle",
                                    width = "full",
                                    order = 3,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.hideGoliaths
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.hideGoliaths = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                hideAncients = {
                                    name = "Hide Ancients",
                                    desc = "Hides the Icons of the Ancients in Nazjatar.",
                                    type = "toggle",
                                    width = "full",
                                    order = 4,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.hideAncients
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.hideAncients = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                hideUnavailable = {
                                    name = "Hide Unavailable Rares",
                                    desc = "An Unavailable Rare is a Rare who is only up when your faction has control over the Warfront Zone, but the opposite side has currently control. This indicates you cannot pay him a visit at this moment. It can in some cases be a rare with missing information.",
                                    type = "toggle",
                                    width = "full",
                                    order = 5,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.hideUnavailable
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.hideUnavailable = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                hideUntrackable = {
                                    name = "Hide Untrackable Rares",
                                    desc = "An Untrackable Rare is a Rare without a QuestID attached to test if you have killed him or not. Currently only the 'Frightened Kodo' in Darkshore is one of them",
                                    type = "toggle",
                                    width = "full",
                                    order = 6,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.hideUntrackable
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.hideUntrackable = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                hideUnknowLoot = {
                                    name = "Hide Unknown Loot",
                                    desc = "Hides the Rare's that don't drop a learnable item.",
                                    type = "toggle",
                                    width = "full",
                                    order = 7,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.hideUnknowLoot
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.hideUnknowLoot = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                hideGearOnly = {
                                    name = "Hide Gear Only",
                                    desc = "Hides the Rare's that only drops Gear.",
                                    type = "toggle",
                                    width = "full",
                                    order = 8,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.hideGearOnly
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.hideGearOnly = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                hideQuestOnly = {
                                    name = "Hide Quest Only",
                                    desc = "Hides the Rare's that only drops Quest items.",
                                    type = "toggle",
                                    width = "full",
                                    order = 9,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.hideQuestOnly
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.hideQuestOnly = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                description = {
                                    name = "I personally think you will have to do the quest but you can use this option for the menu only so the icons stay. I'm working on an implementation on checking wheter the quest has been completed and markt it as \"Complete\", but before that you can manually disable the big quest list in the Menu Options",
                                    type = "description",
                                    width = "full",
                                    order = 10,
                                },
                                hideItemOnly = {
                                    name = "Hide Item Only",
                                    desc = "Hides the Rare's that only drop Items.",
                                    type = "toggle",
                                    width = "full",
                                    order = 11,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.hideItemOnly
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.hideItemOnly = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                hideBlueprintOnly = {
                                    name = "Hide Blueprint Only",
                                    desc = "Hides the Rare's that only drop Blueprints.",
                                    type = "toggle",
                                    width = "full",
                                    order = 12,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.hideBlueprintOnly
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.hideBlueprintOnly = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                hideTransmogOnly = {
                                    name = "Hide Transmog Only",
                                    desc = "Hides the Rare's that only drop Transmog.",
                                    type = "toggle",
                                    width = "full",
                                    order = 13,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.hideTransmogOnly
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.hideTransmogOnly = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                hideAnimaOnly = {
                                    name = "Hide Anima Only",
                                    desc = "Hides the Rare's that only drop Anima.",
                                    type = "toggle",
                                    width = "full",
                                    order = 14,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.hideAnimaOnly
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.hideAnimaOnly = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                showCovenantBoundRares = {
                                    name = "Show All Covenant Bound Rare's",
                                    desc = "Some Rare's or are bound to the Covenant you sign up for. By default these are hidded. If you Enable this option you are able to see all Rare's from all Covenants." .. WarfrontRareTracker:ColorizeText("\nWarning: ",colors.red) .. WarfrontRareTracker:ColorizeText("You're most likely not able to interact with and/or loot these Rare's!",colors.orange),
                                    type = "toggle",
                                    width = "full",
                                    order = 15,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.showCovenantBoundRares
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.showCovenantBoundRares = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                showCovenantBoundLoot = {
                                    name = "Show Rare's With Loot From All Covenants",
                                    desc = "Some Rare's Loot is bound to the Covenant you sign up for. By default these are hidded. If you Enable this option you are able to see the Loot from all Covenants." .. WarfrontRareTracker:ColorizeText("\nWarning: ",colors.red) .. WarfrontRareTracker:ColorizeText("You're most likely not able to interact with and/or loot these Rare's!",colors.orange),
                                    type = "toggle",
                                    width = "full",
                                    order = 16,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.showCovenantBoundLoot
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.showCovenantBoundLoot = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                hideAlreadyKnown = {
                                    name = "Hide Known Items",
                                    desc = "Hides the Icon of the Rare's which drop you already know.",
                                    type = "toggle",
                                    width = "full",
                                    order = 19,
                                    get = function(info)
                                            return WarfrontRareTracker.db.profile.worldmapicons.hideAlreadyKnown
                                        end,
                                    set = function(info, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.hideAlreadyKnown = value
                                            refreshWorldmapIcons(false)
                                        end,
                                },
                                whitelist = {
                                    name = "Whitelist:",
                                    desc = "Select which 'Already Know' drop you still want to show.",
                                    type = "multiselect",
                                    width = "half",
                                    order = 20,
                                    values = whitelist,
                                    get = function(info, key)
                                            return WarfrontRareTracker.db.profile.worldmapicons.whitelist[key]
                                        end,
                                    set = function(info, key, value)
                                            WarfrontRareTracker.db.profile.worldmapicons.whitelist[key] = value
                                            refreshWorldmapIcons(false)
                                        end,
                                    hidden = function() return not WarfrontRareTracker.db.profile.worldmapicons.hideAlreadyKnown end,
                                },
                            },
                        },
                        
                    },
                },
            },
        },
        tomtom = {
            name = "TomTom",
            type = "group",
            order = 10,
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
                        },
                        tomtomAnnounce = {
                            name = "Announce In Party Chat",
                            desc = "Prints a message in Party Chat, telling your Party members to which Rare you're heading to.",
                            type = "toggle",
                            width = "full",
                            order = 4,
                            get = function(info)
                                return WarfrontRareTracker.db.profile.tomtom.tomtomAnnounce
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.tomtom.tomtomAnnounce = value
                                end,
                            disabled = function() return isTomTomlocked or not WarfrontRareTracker.db.profile.tomtom.enableIntegration end,
                        },
                        tomtomAnnounceLeader = {
                            name = "Only When Group Leader",
                            desc = "Print the Party Announce only when you're the Group Leader.",
                            type = "toggle",
                            width = "full",
                            order = 6,
                            get = function(info)
                                return WarfrontRareTracker.db.profile.tomtom.tomtomAnnounceLeader
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.tomtom.tomtomAnnounceLeader = value
                                end,
                            disabled = function() return isTomTomlocked or not WarfrontRareTracker.db.profile.tomtom.enableIntegration or not WarfrontRareTracker.db.profile.tomtom.tomtomAnnounce end,
                        },
                    },
                },
            },
        },
        soundMessage = {
            name = "Sounds & Messages",
            type = "group",
            order = 11,
            args = {
                zone = {
                    name = "Warfront Change Options",
                    type = "group",
                    order = 1,
                    inline = true,
                    args = {
                        enableZoneChangeMessage = {
                            name = "Enable Notifications on Warfront Change",
                            desc = "Prints a message in your chat window when the controlling faction changes in a Warfront.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.general.enableZoneChangeMessage
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.general.enableZoneChangeMessage = value
                                end,
                        },
                        enableZoneChangeSound = {
                            name = "Play Sound On Warfront Change",
                            desc = "Plays a sound when the controlling faction changes in a Warfront.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.db.profile.general.enableZoneChangeSound
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.db.profile.general.enableZoneChangeSound = value
                                end,
                            disabled = function(info)
                                    return not WarfrontRareTracker.db.profile.general.enableZoneChangeMessage
                                end,
                        },
                    },
                },
                -- levelUp = { -- REMOVED
                --     name = "Level-Up Options",
                --     type = "group",
                --     order = 2,
                --     inline = true,
                --     args = {
                --         enableLevelUpChatMessage = {
                --             name = "Enable Notification on Max Level",
                --             desc = "Prints a message in your chat window when the player reaches Max Level, letting them know they now egliable to enter the Warfront.",
                --             type = "toggle",
                --             width = "full",
                --             order = 1,
                --             get = function(info)
                --                     return WarfrontRareTracker.db.profile.general.enableLevelUpChatMessage
                --                 end,
                --             set = function(info, value)
                --                     WarfrontRareTracker.db.profile.general.enableLevelUpChatMessage = value
                --                 end,
                --         },
                --         enableLevelUpSound = {
                --             name = "Play Sound On Max Level",
                --             desc = "Plays a sound when the player reaches Max Level controlling faction changes in a Warfront, letting them know they now egliable to enter the Warfront.",
                --             type = "toggle",
                --             width = "full",
                --             order = 2,
                --             get = function(info)
                --                     return WarfrontRareTracker.db.profile.general.enableLevelUpSound
                --                 end,
                --             set = function(info, value)
                --                     WarfrontRareTracker.db.profile.general.enableLevelUpSound = value
                --                 end,
                --             disabled = function(info)
                --                     return not WarfrontRareTracker.db.profile.general.enableLevelUpChatMessage
                --                 end,
                --         },
                --     },
                -- },
            },
        },
        -- compat = {
        --     name = "Compatibility",
        --     type = "group",
        --     order = 12,
        --     args = {
        --         disableBackground = {
        --             name = "Disable tooltip backgroud",
        --             desc = "Disables the background texture so it can be override by another addon if any errors occure.",
        --             type = "toggle",
        --             width = "full",
        --             order = 1,
        --             get = function(info)
        --                     return WarfrontRareTracker.db.profile.general.disableBackground
        --                 end,
        --             set = function(info, value)
        --                     WarfrontRareTracker.db.profile.general.disableBackground = value
        --                 end,
        --         },
        --     },
        -- },

        -- debug = {
        --     name = "Debug",
        --     type = "group",
        --     order = 13,
        --     args = {
        --         printDebug = {
        --             name = "Enable Debug Messages.",
        --             desc = "Enable Debug Messages.",
        --             type = "toggle",
        --             width = "full",
        --             order = 1,
        --             get = function(info)
        --                     return WarfrontRareTracker.db.profile.debug.printDebug
        --                 end,
        --             set = function(info, value)
        --                     WarfrontRareTracker.db.profile.debug.printDebug = value
        --                 end,
        --         },
        --     },
        -- },
    },
}

local refreshMenuLootTypeOrder
local function lootTypeOrderButtonPress(a, b)
    if a.option and a.option.type and a.option.type == "execute" and a.option.name and a.option.desc then
        local action = string.lower(a.option.name)
        local name = a.option.desc
        if action == "up" or action == "down" then
            for order, lootType in pairs(WarfrontRareTracker.db.profile.menu.lootTypeOrder) do
                if lootType == name then
                    if action == "up" then
                        WarfrontRareTracker.db.profile.menu.lootTypeOrder[order], WarfrontRareTracker.db.profile.menu.lootTypeOrder[order-1] = WarfrontRareTracker.db.profile.menu.lootTypeOrder[order-1], WarfrontRareTracker.db.profile.menu.lootTypeOrder[order]
                        refreshMenuLootTypeOrder()
                        WarfrontRareTracker:SortRares()
                        break
                    elseif action == "down" then
                        WarfrontRareTracker.db.profile.menu.lootTypeOrder[order], WarfrontRareTracker.db.profile.menu.lootTypeOrder[order+1] = WarfrontRareTracker.db.profile.menu.lootTypeOrder[order+1], WarfrontRareTracker.db.profile.menu.lootTypeOrder[order]
                        refreshMenuLootTypeOrder()
                        WarfrontRareTracker:SortRares()
                        break
                    end
                end
            end 
        end
    end
end

function refreshMenuLootTypeOrder()
    wipe(configOptions.args.menusorting.args.lootTypeOrder.args)
    local lst = configOptions.args.menusorting.args.lootTypeOrder.args

    for order, lootType in pairs(WarfrontRareTracker.db.profile.menu.lootTypeOrder) do
        lst[lootType] = {
            type = "group", name = "", order = order, inline = true,
            args = {
                label = {
                    type = "description", name = WarfrontRareTracker:ColorizeText(lootType, colors.yellow), width = "normal", order = 1, fontSize = "medium"
                },
                up = { type = "execute", order = 2, width = "half", name = "Up", desc = lootType, func = function(info, value) lootTypeOrderButtonPress(info, value) end, disabled = (order == 1) },
                down = { type = "execute", order = 3, width = "half", name = "Down", desc = lootType, func = function(info, value) lootTypeOrderButtonPress(info, value) end, disabled = (order == #WarfrontRareTracker.db.profile.menu.lootTypeOrder) },
            },
        }
    end
end

-- Config Migration
local currentConfigVersion = 3
local function checkConfigChanges()

    if brokerTexts[WarfrontRareTracker.db.profile.broker.brokerText] == nil then
        WarfrontRareTracker.db.profile.broker.brokerText = "allstatus"
    end

    -- Changes once as it check by 'Config Version'
    -- This is meant to automatically migrate your old config for mostly renames variables.
    if WarfrontRareTracker.db.profile.profileversion == nil then
        WarfrontRareTracker.db.profile["profileversion"] = 1
    end
    if WarfrontRareTracker.db.profile.profileversion < currentConfigVersion then
        WarfrontRareTracker.db.profile.profileversion = currentConfigVersion
        -- Copy current 'Hide' settings to the new 'Master Filter'  showWarfrontOnTitle showWarfrontOnZoneName
        WarfrontRareTracker.db.profile.menu.showWarfrontOnZoneName = WarfrontRareTracker.db.profile.menu.showWarfrontOnTitle
        --WarfrontRareTracker.db.profile.masterfilter.showOnlyAtMaxLevel = WarfrontRareTracker.db.profile.worldmapicons.showOnlyAtMaxLevel
        WarfrontRareTracker.db.profile.masterfilter.hideAlreadyKnown = WarfrontRareTracker.db.profile.worldmapicons.hideAlreadyKnown
        WarfrontRareTracker.db.profile.masterfilter.hideGoliaths = WarfrontRareTracker.db.profile.worldmapicons.hideGoliaths
        WarfrontRareTracker.db.profile.masterfilter.whitelist["Mount"] = WarfrontRareTracker.db.profile.worldmapicons.whitelist["Mount"]
        WarfrontRareTracker.db.profile.masterfilter.whitelist["Pet"] = WarfrontRareTracker.db.profile.worldmapicons.whitelist["Pet"]
        WarfrontRareTracker.db.profile.masterfilter.whitelist["Toy"] = WarfrontRareTracker.db.profile.worldmapicons.whitelist["Toy"]
        WarfrontRareTracker.db.profile.masterfilter.worldmapShowOnlyAtMaxLevel = WarfrontRareTracker.db.profile.worldmapicons.showOnlyAtMaxLevel
        WarfrontRareTracker.db.profile.masterfilter.worldmapHideIconWhenDefeated = WarfrontRareTracker.db.profile.worldmapicons.hideIconWhenDefeated
    end
end

function WarfrontRareTracker:OnRefreshConfig()
    checkConfigChanges()
end

function WarfrontRareTracker:DelayedConfigInitialize()
    if IsAddOnLoaded("TomTom") then
        isTomTomlocked = false
    end
    local dbsize = WarfrontRareTracker:GetRareDBSize()
    if dbsize > 1 then
        hasMultipleRareDB = true
    end
end

function WarfrontRareTracker:RegisterOptions()
    configOptions.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(WarfrontRareTracker.db)
    configOptions.args.profiles.order = -1
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("WarfrontRareTracker", configOptions)
    checkConfigChanges()
    refreshMenuLootTypeOrder()
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WarfrontRareTracker", "WarfrontRareTracker")
    LibStub("AceConfigDialog-3.0"):SetDefaultSize("WarfrontRareTracker", 700, 575)
    WarfrontRareTracker:RegisterChatCommand("warfront", function() LibStub("AceConfigDialog-3.0"):Open("WarfrontRareTracker") end)
end