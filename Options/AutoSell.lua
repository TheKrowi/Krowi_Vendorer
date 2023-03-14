-- [[ Namespaces ]] --
local _, addon = ...;
local options = addon.Options;
options.AutoSell = {};
local autoSell = options.AutoSell;
tinsert(options.OptionsTables, autoSell);

local OrderPP = KrowiV_InjectOptions.AutoOrderPlusPlus;
local AdjustedWidth = KrowiV_InjectOptions.AdjustedWidth;

function autoSell.RegisterOptionsTable()
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Auto Sell", options.OptionsTable.args.AutoSell);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Auto Sell", "Auto Sell", addon.MetaData.Title);
end

function autoSell.PostLoad()

end

local function ShowAlert(message)
	StaticPopupDialogs["KROWIV_ALERT"] = {
		text = message,
		button1 = OKAY,
		hideOnEscape = true,
		timeout = 0,
		exclusive = true,
		whileDead = true,
	}
	StaticPopup_Show("KROWIV_ALERT")
end

local function ItemLevelSet(_, value)
    if strtrim(value) == "" then
        addon.Options.db.AutoSell.ItemLevel = 0;
    elseif tonumber(value) == nil then
        ShowAlert(addon.L["ItemLevel is not a valid item level."]:ReplaceVars(value));
    else
        addon.Options.db.AutoSell.ItemLevel = tonumber(value);
    end
end

options.OptionsTable.args["AutoSell"] = {
    type = "group", childGroups = "tab",
    name = addon.L["Auto Sell"],
    args = {
        General = {
            order = OrderPP(), type = "group",
            name = addon.L["General"],
            args = {
                Quality = {
                    order = OrderPP(), type = "group", inline = true,
                    name = addon.L["Quality"],
                    args = {
                        Description = {
                            order = OrderPP(), type = "description", width = "full",
                            name = addon.L["Auto Sell Quality Desc"],
                            fontSize = "medium"
                        },
                        Poor = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
                            name = addon.L["Poor"]:SetColorPoor(),
                            get = function() return addon.Options.db.AutoSell.Quality[1]; end,
                            set = function()
                                addon.Options.db.AutoSell.Quality[1] = not addon.Options.db.AutoSell.Quality[1];
                            end
                        },
                        Common = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
                            name = addon.L["Common"]:SetColorCommon(),
                            get = function() return addon.Options.db.AutoSell.Quality[2]; end,
                            set = function()
                                addon.Options.db.AutoSell.Quality[2] = not addon.Options.db.AutoSell.Quality[2];
                            end
                        },
                        Uncommon = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
                            name = addon.L["Uncommon"]:SetColorUncommon(),
                            get = function() return addon.Options.db.AutoSell.Quality[3]; end,
                            set = function()
                                addon.Options.db.AutoSell.Quality[3] = not addon.Options.db.AutoSell.Quality[3];
                            end
                        },
                        Rare = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
                            name = addon.L["Rare"]:SetColorRare(),
                            get = function() return addon.Options.db.AutoSell.Quality[4]; end,
                            set = function()
                                addon.Options.db.AutoSell.Quality[4] = not addon.Options.db.AutoSell.Quality[4];
                            end
                        },
                        Epic = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
                            name = addon.L["Epic"]:SetColorEpic(),
                            get = function() return addon.Options.db.AutoSell.Quality[5]; end,
                            set = function()
                                addon.Options.db.AutoSell.Quality[5] = not addon.Options.db.AutoSell.Quality[5];
                            end
                        }
                    }
                },
                ItemLevel = {
                    order = OrderPP(), type = "group", inline = true,
                    name = addon.L["Quality"],
                    args = {
                        Description = {
                            order = OrderPP(), type = "description", width = "full",
                            name = addon.L["Auto Sell Item Level Desc"],
                            fontSize = "medium"
                        },
                        ItemLevel = {
                            order = OrderPP(), type = "input", width = AdjustedWidth(),
                            name = addon.L["Item Level"],
                            get = function() return tostring(addon.Options.db.AutoSell.ItemLevel); end,
                            set = ItemLevelSet
                        }
                    }
                }
            }
        },
        Tooltip = {
            order = OrderPP(), type = "group",
            name = addon.L["Tooltip"],
            args = {
                Operator = {
                    order = OrderPP(), type = "select", width = AdjustedWidth(),
                    name = addon.L["Operator"],
                    desc = addon.L["Operator Desc"]:AddDefaultValueText_KV("AutoSell.Operator", addon.Operators),
                    values = addon.Operators,
                    get = function() return addon.Options.db.AutoSell.Operator; end,
                    set = function(_, value) addon.Options.db.AutoSell.Operator = value; end
                },
            }
        }
    }
};