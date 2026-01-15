-- [[ Namespaces ]] --
local _, addon = ...;
local options = addon.Options;
options.AutoRepair = {};
local autoRepair = options.AutoRepair;
tinsert(options.OptionsTables, autoRepair);

local OrderPP = addon.InjectOptions.AutoOrderPlusPlus;

function autoRepair.RegisterOptionsTable()
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Auto Repair", options.OptionsTable.args.AutoRepair);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Auto Repair", "Auto Repair", addon.Metadata.Title);
end

function autoRepair.PostLoad()

end

options.OptionsTable.args["AutoRepair"] = {
    type = "group",
    childGroups = "tab",
    name = addon.L["Auto Repair"],
    args = {
        General = {
            order = OrderPP(), type = "group",
            name = addon.Util.L["General"],
            args = {
                IsEnabled = {
                    order = OrderPP(), type = "toggle", width = "full",
                    name = addon.L["Auto Repair Is Enabled"],
                    get = function() return addon.Options.db.profile.AutoRepair.IsEnabled; end,
                    set = function()
                        addon.Options.db.profile.AutoRepair.IsEnabled = not addon.Options.db.profile.AutoRepair.IsEnabled;
                    end
                },
                IsGuildEnabled = {
                    order = OrderPP(), type = "toggle", width = "full",
                    name = addon.L["Auto Repair Is Guild Enabled"],
                    get = function() return addon.Options.db.profile.AutoRepair.IsGuildEnabled; end,
                    set = function()
                        addon.Options.db.profile.AutoRepair.IsGuildEnabled = not addon.Options.db.profile.AutoRepair.IsGuildEnabled;
                    end
                },
                PrintChatMessage = {
                    order = OrderPP(), type = "toggle", width = "full",
                    name = addon.L["Auto Repair Print Chat Message"],
                    get = function() return addon.Options.db.profile.AutoRepair.PrintChatMessage; end,
                    set = function()
                        addon.Options.db.profile.AutoRepair.PrintChatMessage = not addon.Options.db.profile.AutoRepair.PrintChatMessage;
                    end
                }
            }
        }
    }
};
