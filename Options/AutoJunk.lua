-- [[ Namespaces ]] --
local _, addon = ...;
local options = addon.Options;
options.AutoJunk = {};
local autoJunk = options.AutoJunk;
tinsert(options.OptionsTables, autoJunk);

local OrderPP = KrowiV_InjectOptions.AutoOrderPlusPlus;
local AdjustedWidth = KrowiV_InjectOptions.AdjustedWidth;

function autoJunk.RegisterOptionsTable()
    -- LibStub("AceConfig-3.0"):RegisterOptionsTable("Auto Junk", options.OptionsTable.args.AutoJunk);
    -- LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Auto Junk", "Auto Junk", addon.MetaData.Title);
end

function autoJunk.PostLoad()

end

options.OptionsTable.args["AutoJunk"] = {
    type = "group", childGroups = "tab",
    name = addon.L["Auto Junk"],
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
                            name = addon.L["AutoJunkQualityDesc"],
                            fontSize = "medium"
                        },
                        Poor = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
                            name = addon.L["Poor"]:SetColorPoor(),
                            get = function() return addon.Options.db.AutoJunk.Quality[1]; end,
                            set = function()
                                addon.Options.db.AutoJunk.Quality[1] = not addon.Options.db.AutoJunk.Quality[1];
                            end
                        },
                        Common = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
                            name = addon.L["Common"]:SetColorCommon(),
                            get = function() return addon.Options.db.AutoJunk.Quality[2]; end,
                            set = function()
                                addon.Options.db.AutoJunk.Quality[2] = not addon.Options.db.AutoJunk.Quality[2];
                            end
                        },
                        Uncommon = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
                            name = addon.L["Uncommon"]:SetColorUncommon(),
                            get = function() return addon.Options.db.AutoJunk.Quality[3]; end,
                            set = function()
                                addon.Options.db.AutoJunk.Quality[3] = not addon.Options.db.AutoJunk.Quality[3];
                            end
                        },
                        Rare = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
                            name = addon.L["Rare"]:SetColorRare(),
                            get = function() return addon.Options.db.AutoJunk.Quality[4]; end,
                            set = function()
                                addon.Options.db.AutoJunk.Quality[4] = not addon.Options.db.AutoJunk.Quality[4];
                            end
                        },
                        Epic = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
                            name = addon.L["Epic"]:SetColorEpic(),
                            get = function() return addon.Options.db.AutoJunk.Quality[5]; end,
                            set = function()
                                addon.Options.db.AutoJunk.Quality[5] = not addon.Options.db.AutoJunk.Quality[5];
                            end
                        }
                    }
                }
            }
        }
    }
};