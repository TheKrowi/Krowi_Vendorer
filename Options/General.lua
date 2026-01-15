-- [[ Namespaces ]] --
local _, addon = ...;
local options = addon.Options;
options.General = {};
local general = options.General;
tinsert(options.OptionsTables, general);

local OrderPP = addon.InjectOptions.AutoOrderPlusPlus;
local AdjustedWidth = addon.InjectOptions.AdjustedWidth;

function general.RegisterOptionsTable()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.Metadata.Title, options.OptionsTable.args.General);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addon.Metadata.Title, addon.Metadata.Title, nil);
end

function general.PostLoad()

end

local function MinimapShowMinimapIconSet()
    addon.Options.db.profile.ShowMinimapIcon = not addon.Options.db.profile.ShowMinimapIcon;
    if addon.Options.db.profile.ShowMinimapIcon then
        addon.Icon:Show("Krowi_VendorerLDB");
    else
        addon.Icon:Hide("Krowi_VendorerLDB");
    end
end

options.OptionsTable.args["General"] = {
    type = "group", childGroups = "tab",
    name = addon.Util.L["General"],
    args = {
        Info = {
            order = OrderPP(), type = "group",
            name = addon.Util.L["Info"],
            args = {
                General = {
                    order = OrderPP(), type = "group", inline = true,
                    name = addon.Util.L["General"],
                    args = {
                        Version = {
                            order = OrderPP(), type = "description", width = AdjustedWidth(), fontSize = "medium",
                            name = (addon.Util.L["Version"] .. ": "):SetColorYellow() .. addon.Metadata.Version,
                        },
                        Build = {
                            order = OrderPP(), type = "description", width = AdjustedWidth(), fontSize = "medium",
                            name = (addon.Util.L["Build"] .. ": "):SetColorYellow() .. addon.Metadata.Build,
                        },
                        Blank1 = {order = OrderPP(), type = "description", width = AdjustedWidth(), name = ""},
                        Author = {
                            order = OrderPP(), type = "description", width = AdjustedWidth(2), fontSize = "medium",
                            name = (addon.Util.L["Author"] .. ": "):SetColorYellow() .. addon.Metadata.Author,
                        },
                        Discord = {
                            order = OrderPP(), type = "execute", width = AdjustedWidth(),
                            name = addon.Util.L["Discord"],
                            desc = addon.Util.L["Discord Desc"]:K_ReplaceVars(addon.Util.Constants.DiscordServerName),
                            func = function() LibStub("Krowi_PopupDialog_2").ShowExternalLink(addon.Util.Constants.DiscordInviteLink); end
                        }
                    }
                },
                Sources = {
                    order = OrderPP(), type = "group", inline = true,
                    name = addon.Util.L["Sources"],
                    args = {
                        CurseForge = {
                            order = OrderPP(), type = "execute", width = AdjustedWidth(),
                            name = addon.Util.L["CurseForge"],
                            desc = addon.Util.L["CurseForge Desc"]:KV_InjectAddonName():K_ReplaceVars(addon.Util.L["CurseForge"]),
                            func = function() LibStub("Krowi_PopupDialog_2").ShowExternalLink(addon.Metadata.CurseForge); end
                        },
                        Wago = {
                            order = OrderPP(), type = "execute", width = AdjustedWidth(),
                            name = addon.Util.L["Wago"],
                            desc = addon.Util.L["Wago Desc"]:KV_InjectAddonName():K_ReplaceVars(addon.Util.L["Wago"]),
                            func = function() LibStub("Krowi_PopupDialog_2").ShowExternalLink(addon.Metadata.Wago); end
                        }
                    }
                }
            }
        },
        Icon = {
            order = OrderPP(), type = "group",
            name = addon.Util.L['Icon'],
            args = {
                Minimap = {
                    order = OrderPP(), type = "group", inline = true,
                    name = addon.Util.L["Minimap"],
                    args = {
                        ShowMinimapIcon = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(),
                            name = addon.Util.L["Show minimap icon"],
                            desc = addon.Util.L["Show minimap icon Desc"]:KV_AddDefaultValueText("ShowMinimapIcon"),
                            get = function() return addon.Options.db.profile.ShowMinimapIcon; end,
                            set = MinimapShowMinimapIconSet
                        }
                    }
                }
            }
        },
        Debug = {
            order = OrderPP(), type = "group",
            name = addon.L["Debug"],
            args = {
                Debug = {
                    order = OrderPP(), type = "group", inline = true,
                    name = addon.L["Debug"],
                    args = {
                        Description = {
                            order = OrderPP(), type = "description", width = "full", fontSize = "medium",
                            name = addon.L["Debug Desc"],
                        },
                        TooltipShowAutoSellRules = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(),
                            name = addon.L["TooltipShowAutoSellRules"],
                            desc = addon.L["TooltipShowAutoSellRules Desc"]:KV_AddDefaultValueText("Debug.TooltipShowItemInfo"),
                            get = function() return addon.Options.db.profile.Debug.TooltipShowItemInfo; end,
                            set = function(_, value) addon.Options.db.profile.Debug.TooltipShowItemInfo = value; end
                        },
                        Blank1 = {order = OrderPP(), type = "description", width = AdjustedWidth(2), name = ""},
                        -- ScreenshotMode = {
                        --     order = OrderPP(), type = "execute",
                        --     name = addon.L["Screenshot Mode"],
                        --     desc = addon.L["Screenshot Mode Desc"],
                        --     func = HandleScreenshotMode
                        -- },
                        AutoSellPrintChatMessage = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(),
                            name = addon.L["AutoSellPrintChatMessage"],
                            desc = addon.L["AutoSellPrintChatMessage Desc"]:KV_AddDefaultValueText("AutoSell.PrintChatMessage"),
                            get = function() return addon.Options.db.profile.AutoSell.PrintChatMessage; end,
                            set = function(_, value) addon.Options.db.profile.AutoSell.PrintChatMessage = value; end
                        },
                        -- Blank2 = {order = OrderPP(), type = "description", width = AdjustedWidth(), name = ""},
                        -- ExportCriteria = {
                        --     order = OrderPP(), type = "execute",
                        --     name = addon.L["Export Criteria"],
                        --     desc = addon.L["Export Criteria Desc"],
                        --     func = ExportCriteria
                        -- },
                        -- ShowPlaceholdersFilter = {
                        --     order = OrderPP(), type = "toggle", width = AdjustedWidth(),
                        --     name = addon.L["Show placeholders filter"],
                        --     desc = addon.L["Show placeholders filter Desc"]:AddDefaultValueText_KAF("ShowPlaceholdersFilter"),
                        --     get = function() return addon.Options.db.profile.ShowPlaceholdersFilter; end,
                        --     set = function() addon.Options.db.profile.ShowPlaceholdersFilter = not addon.Options.db.profile.ShowPlaceholdersFilter; end
                        -- }
                    }
                }
            }
        }
    }
};