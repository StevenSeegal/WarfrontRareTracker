local WarfrontRareTracker = LibStub("AceAddon-3.0"):GetAddon("WarfrontRareTracker")

configOptions = {
    type = "group",
    args = {
        minimapBroker = {
            name = "Minimap & Broker",
            type = "group",
            order = 1,
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
                                    return not WarfrontRareTracker.WR.db.profile.minimap.hide
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.minimap.hide = not value
                                    WarfrontRareTracker:RefreshConfig()
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
                                    return WarfrontRareTracker.WR.db.profile.menu.showMenuOn
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.menu.showMenuOn = value
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
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.broker.showBrokerText
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.broker.showBrokerText = value
                                    WarfrontRareTracker:UpdateBrokerText()
                                end,
                        },
                        brokerText = {
                            name = "Broker Text",
                            desc = "Select which text the broker shows.",
                            type = "select",
                            style = "dropdown",
                            order = 2,
                            values = { ["name"]="Addon Name", ["status"]="Warfront Status" },
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.broker.brokerText
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.broker.brokerText = value
                                    WarfrontRareTracker:UpdateBrokerText()
                                end,
                            disabled = function() return not WarfrontRareTracker.WR.db.profile.broker.showBrokerText end,
                        },
                        updateInterval = {
                            name = "Update Interval",
                            desc = "Select the interval on which the text updates.",
                            type = "select",
                            style = "dropdown",
                            order = 3,
                            values = { [1]="1 minute", [5]="5 minutes", [10]="10 minutes", [15]="15 minutes", [30]="30 minutes", [60]="1 hour" },
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.broker.updateInterval
                            end,
                        set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.broker.updateInterval = value
                                    WarfrontRareTracker:UpdateBrokerText()
                            end,
                            disabled = function(info) return not WarfrontRareTracker.WR.db.profile.broker.showBrokerText or WarfrontRareTracker.WR.db.profile.broker.brokerText == "name" end,
                        },
                        brokerTextDescription = {
                            name = "\nInfo about the option 'Warfront Status' in Broker Text\n\nExample 1:\n"..
                                    WarfrontRareTracker:ColorText("(H)", WarfrontRareTracker.WR.colors.red)..WarfrontRareTracker:ColorText(" Gathering: ", WarfrontRareTracker.WR.colors.turqoise)..WarfrontRareTracker:ColorText("80%", WarfrontRareTracker.WR.colors.green).."\n\n"..
                                    "(H) = Faction currently in control of the zone (Shows 'H' for Horde or 'A' for Alliance)\n"..
                                    "'Scenario' states you're currently in the 'Quest Phase' and it show the percentage completed.\n"..
                                    "Note: Opposite Faction cannot readout the percentage completed!\n\nExample 2:\n"..
                                    WarfrontRareTracker:ColorText("(H)", WarfrontRareTracker.WR.colors.red)..WarfrontRareTracker:ColorText(" Scenario: ", WarfrontRareTracker.WR.colors.turqoise)..WarfrontRareTracker:ColorText("5D 7H 35M Left", WarfrontRareTracker.WR.colors.green).."\n\n"..
                                    "(H) = Faction currently in control of the zone (Shows 'H' for Horde or 'A' for Alliance)\n"..
                                    "'Gathering' states you're currently in the 'Warfront Scenario' and it show the time left.\n",
                            type = "description",
                        },
                    },
                },
            },
        },
        menu = {
            name = "Menu",
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
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.menu.showAtMaxLevel
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.menu.showAtMaxLevel = value
                                end,
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
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.menu.hideAlreadyKnown
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.menu.hideAlreadyKnown = value
                                end,
                        },
                        hideGoliaths = {
                            name = "Hide Goliaths",
                            desc = "Hides the 4 Goliaths as they don't drop a learnable item.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.menu.hideGoliaths
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.menu.hideGoliaths = value
                                end,
                        },
                    },
                },
                warfront = {
                    name = "Warfront Status",
                    order = 2,
                    type = "group",
                    inline = true,
                    args = {
                        showWarfrontOnTitle = {
                            name = "Warfront Status In Title",
                            desc = "Shows Warfront Status when mouse over the title of the menu.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.menu.showWarfrontOnTitle
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.menu.showWarfrontOnTitle = value
                                end,
                        },
                        showWarfrontInMenu = {
                            name = "Warfront Status In Menu",
                            desc = "Shows Warfront Status in the menu.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.menu.showWarfrontInMenu
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.menu.showWarfrontInMenu = value
                                end,
                        },
                    },
                },
            },
        },
        colors = {
            name = "Colors",
            type = "group",
            order = 4,
            args = {
                drops = {
                    name = "Color Known Items",
                    order = 1,
                    type = "group",
                    inline = true,
                    args = {
                        colorizeDrops = {
                            name = "Colorize Known Items",
                            desc = "Gives the item in the 'Drops' Collum a color if known and unknown",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.colors.colorizeDrops
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.colors.colorizeDrops = value
                                end,
                        },
                        knownColor = {
                            name = "Color Of Known Items",
                            desc = "Set the color of Known Items",
                            type = "color",
                            order = 2,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.knownColor
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.knownColor
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.WR.db.profile.colors.colorizeDrops end,
                        },
                        unknownColor = {
                            name = "Color Of Unknown Items",
                            desc = "Set the color of Unknown Items",
                            type = "color",
                            order = 3,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.unknownColor
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.unknownColor
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.WR.db.profile.colors.colorizeDrops end,
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
                            desc = "Use custom colors for the status text. When disabled it uses the default colors",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.colors.colorizeStatus
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.colors.colorizeStatus = value
                                end,
                        },
                        available = {
                            name = "Color Of 'Available'",
                            desc = "Set the color of the 'Available' status",
                            type = "color",
                            order = 2,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.available
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.available
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.WR.db.profile.colors.colorizeStatus end,
                        },
                        defeated = {
                            name = "Color Of 'Defeated'",
                            desc = "Set the color of the 'Defeated' status",
                            type = "color",
                            order = 3,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.defeated
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.defeated
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.WR.db.profile.colors.colorizeStatus end,
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
                                    return WarfrontRareTracker.WR.db.profile.colors.colorizeRares
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.colors.colorizeRares = value
                                end,
                        },
                        worldboss = {
                            name = "Color Of 'World Boss'",
                            desc = "Set the color of the 'World Boss' Rare's.",
                            type = "color",
                            order = 2,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.worldboss
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.worldboss
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.WR.db.profile.colors.colorizeRares end,
                        },
                        elite = {
                            name = "Color Of 'Elite'",
                            desc = "Set the color of the 'Elite' Rares.",
                            type = "color",
                            order = 3,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.elite
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.elite
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.WR.db.profile.colors.colorizeRares end,
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
                                    local color = WarfrontRareTracker.WR.db.profile.colors.rare
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.rare
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.WR.db.profile.colors.colorizeRares end,
                        },
                        goliath = {
                            name = "Color Of 'Goliath'",
                            desc = "Set the color of the 'Goliath' Rares.",
                            type = "color",
                            order = 6,
                            hasAlpha = false,
                            get = function(info)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.goliath
                                    return color[1], color[2], color[3], color[4]
                                end,
                            set = function(info, r, g, b, a)
                                    local color = WarfrontRareTracker.WR.db.profile.colors.goliath
                                    color[1], color[2], color[3], color[4] = r, g, b, a
                                end,
                            disabled = function() return not WarfrontRareTracker.WR.db.profile.colors.colorizeRares end,
                        },
                    },
                },
            },
        },
        unitframes = {
            name = "Unit Frames",
            type = "group",
            order = 5,
            args = {
                unitframes = {
                    name = "NPC Unit Frame Options",
                    order = 4,
                    type = "group",
                    inline = true,
                    args = {
                        showStaus = {
                            name = "Show Status Text",
                            desc = "Adds Status information to the Unit Frame Box.",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.unitframe.showStaus
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.unitframe.showStaus = value
                                end,
                        },
                        showDrop = {
                            name = "Show Loot",
                            desc = "Adds Loot information to the Unit Frame Box.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.unitframe.showDrop
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.unitframe.showDrop = value
                                end,
                        },
                        showAlreadyKnown = {
                            name = "Show Already Known Info",
                            desc = "Adds 'Already Known' to the Unit Frame Box when you already know the item.",
                            type = "toggle",
                            width = "full",
                            order = 3,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.unitframe.showAlreadyKnown
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.unitframe.showAlreadyKnown = value
                                end,
                        },
                    },
                },
            },
        },
        worldmap = {
            name = "Worldmap",
            type = "group",
            order = 6,
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
                                    return WarfrontRareTracker.WR.db.profile.worldmapicons.showWorldmapIcons
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.worldmapicons.showWorldmapIcons = value
                                    WarfrontRareTracker:UpdateWorldMapIcons(true)
                                end,
                        },
                        showOnlyAtMaxLevel = {
                            name = "Show Only At Level 120",
                            desc = "Show Worldmap Icons only at level 120. When lower then level 120 no Woldmap Icons will be shown, unless disabled.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.worldmapicons.showOnlyAtMaxLevel
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.worldmapicons.showOnlyAtMaxLevel = value
                                    WarfrontRareTracker:UpdateWorldMapIcons(true)
                                end,
                        },
                        clickToTomTom = {
                            name = "Click To Add TomTom Waypoint",
                            desc = "Click on the Rare's Icon to add a TomTom Waypoint.",
                            type = "toggle",
                            width = "full",
                            order = 3,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.worldmapicons.clickToTomTom
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.worldmapicons.clickToTomTom = value
                                end,
                            disabled = function() return not WarfrontRareTracker.WR.isTomTomloaded or not WarfrontRareTracker.WR.db.profile.tomtom.enableIntegration end,
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
                                    return WarfrontRareTracker.WR.db.profile.worldmapicons.hideIconWhenDefeated
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.worldmapicons.hideIconWhenDefeated = value
                                    WarfrontRareTracker:UpdateWorldMapIcons(true)
                                end,
                        },
                        hideAlreadyKnown = {
                            name = "Hide Known Items",
                            desc = "Hides the Icon of the Rare's which drop you already know.",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.worldmapicons.hideAlreadyKnown
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.worldmapicons.hideAlreadyKnown = value
                                    WarfrontRareTracker:UpdateWorldMapIcons(true)
                                end,
                        },
                        hideGoliaths = {
                            name = "Hide Goliaths",
                            desc = "Hides the Icon of the 4 Goliaths.",
                            type = "toggle",
                            width = "full",
                            order = 3,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.worldmapicons.hideGoliaths
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.worldmapicons.hideGoliaths = value
                                    WarfrontRareTracker:UpdateWorldMapIcons(true)
                                end,
                        },
                    },
                },
            },
        },
        tomtom = {
            name = "TomTom",
            type = "group",
            order = 7,
            args = {
                tomtom = {
                    name = "TomTom Integration (Requires TomTom)",
                    order = 1,
                    type = "group",
                    inline = true,
                    args = {
                        tomtomIntegration = {
                            name = "TomTom Integration",
                            desc = "Create a TomTom Waypoint when Clicked on a Rare in the menu",
                            type = "toggle",
                            width = "full",
                            order = 1,
                            get = function(info)
                                    return WarfrontRareTracker.WR.db.profile.tomtom.enableIntegration
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.tomtom.enableIntegration = value
                                end,
                            disabled = function() return not WarfrontRareTracker.WR.isTomTomloaded end,
                        },
                        tomtomChatMessage = {
                            name = "Output To Chat",
                            desc = "Prints a message in your Chat window when a waypoint is created",
                            type = "toggle",
                            width = "full",
                            order = 2,
                            get = function(info)
                                return WarfrontRareTracker.WR.db.profile.tomtom.enableChatMessage
                                end,
                            set = function(info, value)
                                    WarfrontRareTracker.WR.db.profile.tomtom.enableChatMessage = value
                                end,
                            disabled = function() return not WarfrontRareTracker.WR.isTomTomloaded or not WarfrontRareTracker.WR.db.profile.tomtom.enableIntegration end,
                        }
                    },
                },
            },
        },
    },
}

function WarfrontRareTracker:RegisterOptions()
    configOptions.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(WarfrontRareTracker.WR.db)
    configOptions.args.profiles.order = 10
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("WarfrontRareTracker", configOptions)
end