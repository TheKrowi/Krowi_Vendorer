-- [[ Namespaces ]] --
local _, addon = ...;
local options = addon.Options;
options.AutoSell = {};
local autoSell = options.AutoSell;
tinsert(options.OptionsTables, autoSell);

local criteriaType = addon.Objects.CriteriaType;

local OrderPP = KrowiV_InjectOptions.AutoOrderPlusPlus;
local AdjustedWidth = KrowiV_InjectOptions.AdjustedWidth;

function autoSell.RegisterOptionsTable()
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Auto Sell", options.OptionsTable.args.AutoSell);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Auto Sell", "Auto Sell", addon.MetaData.Title);
end

local removedFlag = "REMOVED";

local function ConditionCriteriaTypeSet_ItemLevel(numRule, numCondition)
    KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Condition" .. numCondition .. ".args", "Operator", {
        order = OrderPP(), type = "select", width = AdjustedWidth(0.5),
        name = "",
        values = addon.Operators,
        get = function() return addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Operator; end,
        set = function(_, _value) addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Operator = _value; end
    });
    KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Condition" .. numCondition .. ".args", "Value", {
        order = OrderPP(), type = "input", width = AdjustedWidth(0.4),
        name = "",
        get = function() return addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Value; end,
        set = function(_, _value) addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Value = _value; end
    });
    options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args["Condition" .. numCondition].args.Blank1 = nil;
end

local function ConditionCriteriaTypeSet_Soulbound(numRule, numCondition)
    KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Condition" .. numCondition .. ".args", "Blank1", {
        order = OrderPP(), type = "description", width = AdjustedWidth(0.9), name = ""
    });
    addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Operator = nil;
    addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Value = nil;
    options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args["Condition" .. numCondition].args.Operator = nil;
    options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args["Condition" .. numCondition].args.Value = nil;
end

local function ConditionCriteriaTypeSet_Other(numRule, numCondition)
    KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Condition" .. numCondition .. ".args", "Blank1", {
        order = OrderPP(), type = "description", width = AdjustedWidth(0.9), name = ""
    });
    addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Operator = nil;
    addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Value = nil;
    options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args["Condition" .. numCondition].args.Operator = nil;
    options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args["Condition" .. numCondition].args.Value = nil;
end

local function ConditionCriteriaTypeSet(numRule, numCondition, value)
    addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].CriteriaType = value;
    if value == criteriaType.Enum.ItemLevel then -- Item level
        ConditionCriteriaTypeSet_ItemLevel(numRule, numCondition);
    elseif value == criteriaType.Enum.Soulbound then -- Soulbound
        ConditionCriteriaTypeSet_Soulbound(numRule, numCondition);
    else
        ConditionCriteriaTypeSet_Other(numRule, numCondition);
    end
    local deleteConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Condition" .. numCondition .. ".args.DeleteCondition");
    deleteConditionTable.order = OrderPP();
end

local function AddConditionTable(numRule, numCondition)
    KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args", "Condition" .. tostring(numCondition), {
        order = OrderPP(), type = "group", inline = true,
        name = "",
        args = {
            If = {
                order = OrderPP(), type = "description", width = AdjustedWidth(0.1), fontSize = "medium",
                name = addon.L["If"],
            },
            CriteriaType = {
                order = OrderPP(), type = "select", width = AdjustedWidth(0.6),
                name = "",
                values = criteriaType.List,
                get = function() return addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].CriteriaType; end,
                set = function(_, value) ConditionCriteriaTypeSet(numRule, numCondition, value); end
            },
            DeleteCondition = {
                order = OrderPP(), type = "execute", width = AdjustedWidth(0.4),
                name = addon.L["Delete"],
                func = function()
                    options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args["Condition" .. numCondition] = nil;
                    addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition] = removedFlag;
                end
            }
        }
    });
    ConditionCriteriaTypeSet(numRule, numCondition, addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].CriteriaType);
    local addNewConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.AddNewCondition");
    addNewConditionTable.order = OrderPP();
end

function AddNewConditionFunc(numRule)
    tinsert(addon.Options.db.AutoSell.Rules[numRule].Conditions, {});
    local numConditions = #addon.Options.db.AutoSell.Rules[numRule].Conditions;
    AddConditionTable(numRule, numConditions);
end

local function AddRuleTable(numRule)
    KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args", "Rule" .. tostring(numRule), {
        order = OrderPP(), type = "group",
        name = addon.Options.db.AutoSell.Rules[numRule].Name,
        args = {
            Name = {
                order = OrderPP(), type = "input", width = AdjustedWidth(1.5),
                name = addon.L["Name"],
                get = function() return addon.Options.db.AutoSell.Rules[numRule].Name; end,
                set = function(_, value)
                    addon.Options.db.AutoSell.Rules[numRule].Name = value;
                    local ruleTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule);
                    ruleTable.name = value;
                end
            },
            DeleteRule = {
                order = OrderPP(), type = "execute", width = AdjustedWidth(0.5),
                name = addon.L["Delete rule"],
                func = function()
                    options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule] = nil;
                    addon.Options.db.AutoSell.Rules[numRule] = removedFlag;
                end
            },
            ItemClassesHeader = {
                order = OrderPP(), type = "header",
                name = addon.L["Sell selected item types"]
            },
            ItemClasses = {
                order = OrderPP(), type = "multiselect", width = "full",
                name = "",
                values = addon.ItemClass,
                get = function(_, index) return addon.Options.db.AutoSell.Rules[numRule].ItemClasses[index]; end,
                set = function(_, index, value) addon.Options.db.AutoSell.Rules[numRule].ItemClasses[index] = value; end,
                control = "Dropdown"
            },
            ConditionsHeader = {
                order = OrderPP(), type = "header",
                name = addon.L["Conditions"]
            },
            AddNewCondition = {
                order = OrderPP(), type = "execute",
                name = addon.L["Add new condition"],
                func = function() AddNewConditionFunc(numRule) end
            }
        }
    });
end

local function AddNewRuleFunc()
    addon.Options.db.AutoSell.RulesHistoryCounter = addon.Options.db.AutoSell.RulesHistoryCounter + 1;
    tinsert(addon.Options.db.AutoSell.Rules, {
        Name = "Rule " .. addon.Options.db.AutoSell.RulesHistoryCounter,
        ItemClasses = {},
        Conditions = {}
    });
    local numRules = #addon.Options.db.AutoSell.Rules;
    AddRuleTable(numRules);
    AddNewConditionFunc(numRules);
end

function autoSell.PostLoad()
    -- Clean up deleted rules during previous session
    for i = #addon.Options.db.AutoSell.Rules, 1, -1 do
        if addon.Options.db.AutoSell.Rules[i] == removedFlag then
            tremove(addon.Options.db.AutoSell.Rules, i);
        end
    end

    for i, _ in next, addon.Options.db.AutoSell.Rules do
        AddRuleTable(i);
        -- Clean up deleted conditions during previous session
        for j = #addon.Options.db.AutoSell.Rules[i].Conditions, 1, -1 do
            if addon.Options.db.AutoSell.Rules[i].Conditions[j] == removedFlag then
                tremove(addon.Options.db.AutoSell.Rules[i].Conditions, j);
            end
        end
        for j, _ in next, addon.Options.db.AutoSell.Rules[i].Conditions do
            AddConditionTable(i, j);
        end
    end
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
                },
                Artifactrelic = {
                    order = OrderPP(), type = "group", inline = true,
                    name = addon.L["Artifact relic"],
                    args = {
                        Description = {
                            order = OrderPP(), type = "description", width = "full",
                            name = addon.L["Auto Sell Artifact Relic Desc"],
                            fontSize = "medium"
                        },
                        Epic = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
                            name = addon.L["Sell"],
                            get = function() return addon.Options.db.AutoSell.Artifactrelic; end,
                            set = function(_, value) addon.Options.db.AutoSell.Artifactrelic = value; end
                        }
                    }
                }
            }
        },
        Tooltip = {
            order = OrderPP(), type = "group",
            name = addon.L["Tooltip"],
            args = {
                -- Operator = {
                --     order = OrderPP(), type = "select", width = AdjustedWidth(),
                --     name = addon.L["Operator"],
                --     desc = addon.L["Operator Desc"]:AddDefaultValueText_KV("AutoSell.Operator", addon.Operators),
                --     values = addon.Operators,
                --     get = function() return addon.Options.db.AutoSell.Operator; end,
                --     set = function(_, value) addon.Options.db.AutoSell.Operator = value; end
                -- },
            }
        },
        Rules = {
            order = OrderPP(), type = "group",
            name = addon.L["Rules"],
            args = {
                AddNewRule = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(),
                    name = addon.L["Add new rule"],
                    desc = addon.L["Add new rule Desc"],
                    func = AddNewRuleFunc
                }
            }
        }
    }
};