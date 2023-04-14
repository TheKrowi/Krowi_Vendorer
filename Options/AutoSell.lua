-- [[ Namespaces ]] --
local _, addon = ...;
local options = addon.Options;
options.AutoSell = {};
local autoSell = options.AutoSell;
tinsert(options.OptionsTables, autoSell);

local criteriaType = addon.Objects.CriteriaType;
local equalityOperator = addon.Objects.EqualityOperator;
local itemType = addon.Objects.ItemType;
local removedElementPending;

local OrderPP = KrowiV_InjectOptions.AutoOrderPlusPlus;
local AdjustedWidth = KrowiV_InjectOptions.AdjustedWidth;

function autoSell.RegisterOptionsTable()
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Auto Sell", options.OptionsTable.args.AutoSell);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Auto Sell", "Auto Sell", addon.MetaData.Title);
end

local removedFlag = "REMOVED";

local function CheckIfRuleIsValid(numRule)
    print(addon.Options.db.AutoSell.Rules[numRule].Name, addon.Options.db.AutoSell.Rules[numRule].NumSelectedItemClasses, #addon.Options.db.AutoSell.Rules[numRule].Conditions, addon.Options.db.AutoSell.Rules[numRule].IsValid)
    local isValid = true;
    for _, itemType in next, addon.Options.db.AutoSell.Rules[numRule].ItemTypes do
        if itemType ~= removedFlag then
            isValid = isValid and itemType.Type ~= nil;
        end
    end
    for _, condition in next, addon.Options.db.AutoSell.Rules[numRule].Conditions do
        if condition ~= removedFlag then
            isValid = isValid and (criteriaType.CheckIfValid(condition));
        end
    end
    addon.Options.db.AutoSell.Rules[numRule].IsValid = isValid;

    local invalidRuleTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.InvalidRule");
    invalidRuleTable.hidden = isValid;
end

local function CheckIfItemTypeIsValid(numRule, numItemType)
    local isValid = addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].Type ~= nil;
    local desc = addon.L["No item type selected"];
    addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].IsValid = isValid;

    local invalidItemTypeTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.ItemTypes.args.ItemType" .. numItemType .. ".args.InvalidItemType");
    invalidItemTypeTable.hidden = isValid;
    invalidItemTypeTable.name = desc:SetColorLightRed();

    CheckIfRuleIsValid(numRule);
end

local function ItemTypeTypeSet(numRule, numItemType, value)
    addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].Type = value;
    local subTypeTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.ItemTypes.args.ItemType" .. numItemType .. ".args.SubTypes");
    -- if value == Enum.ItemClass.Weapon then -- Weapon
        -- subTypeTable.hidden = false;
        subTypeTable.values = itemType.SubTypeList[value];
        -- ConditionCriteriaTypeSet_ItemLevel(numRule, numCondition);
    -- elseif value == criteriaType.Enum.Soulbound then -- Soulbound
    --     ConditionCriteriaTypeSet_Soulbound(numRule, numCondition);
    -- else
    --     ConditionCriteriaTypeSet_Other(numRule, numCondition);
        -- subTypeTable.hidden = true;
    -- end
    CheckIfItemTypeIsValid(numRule, numItemType);
    local invalidItemTypeTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.ItemTypes.args.ItemType" .. numItemType .. ".args.InvalidItemType");
    invalidItemTypeTable.order = OrderPP();
end

local function ItemTypeCheckSubTypeSet(numRule, numItemType, value)
    addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].CheckSubType = value;
    local subTypeTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.ItemTypes.args.ItemType" .. numItemType .. ".args.SubTypes");
    subTypeTable.hidden = not value;
end

local function AddItemTypeTable(numRule, numItemType)
    KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.ItemTypes.args", "ItemType" .. tostring(numItemType), {
        order = OrderPP(), type = "group", inline = true,
        name = "",
        args = {
            Type = {
                order = OrderPP(), type = "select", width = AdjustedWidth(0.8),
                name = "",
                values = itemType.List,
                get = function() return addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].Type; end,
                set = function(_, value) ItemTypeTypeSet(numRule, numItemType, value); end
            },
            CheckSubType = {
                order = OrderPP(), type = "toggle", width = AdjustedWidth(0.8),
                name = addon.L["Select sub type"],
                get = function() return addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].CheckSubType; end,
                set = function(_, value) ItemTypeCheckSubTypeSet(numRule, numItemType, value); end
            },
            DeleteItemType = {
                order = OrderPP(), type = "execute", width = AdjustedWidth(0.4),
                name = addon.L["Delete"],
                func = function()
                    options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args.ItemTypes.args["ItemType" .. numItemType] = nil;
                    addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType] = removedFlag;
                    CheckIfRuleIsValid(numRule);
                    removedElementPending = true;
                end
            },
            SubTypes = {
                order = OrderPP(), type = "multiselect", width = "full",
                name = "",
                values = itemType.List,
                get = function(_, index)
                    return addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].SubTypes[index];
                end,
                set = function(_, index, value)
                    addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].SubTypes[index] = value;
                end,
                control = "Dropdown",
                hidden = true
            },
            -- If = {
            --     order = OrderPP(), type = "description", width = AdjustedWidth(0.1), fontSize = "medium",
            --     name = addon.L["If"],
            -- },
            -- CriteriaType = {
            --     order = OrderPP(), type = "select", width = AdjustedWidth(0.6),
            --     name = "",
            --     values = criteriaType.List,
            --     get = function() return addon.Options.db.AutoSell.Rules[numRule].Conditions[numItemClass].CriteriaType; end,
            --     set = function(_, value) ConditionCriteriaTypeSet(numRule, numItemClass, value); end
            -- },
            InvalidItemType = {
                order = OrderPP(), type = "description", width = "full",
                name = addon.L["InvalidItemType"]:SetColorLightRed(),
                fontSize = "medium"
            }
        }
    });
    ItemTypeTypeSet(numRule, numItemType, addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].Type);
    local addNewItemClassTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.ItemTypes.args.AddNewItemType");
    addNewItemClassTable.order = OrderPP();
end

local function AddNewItemTypeFunc(numRule)
    tinsert(addon.Options.db.AutoSell.Rules[numRule].ItemTypes, {
        SubTypes = {}
    });
    local numItemType = #addon.Options.db.AutoSell.Rules[numRule].ItemTypes;
    AddItemTypeTable(numRule, numItemType);
end

local function CheckIfConditionIsValid(numRule, numCondition)
    local isValid, desc = criteriaType.CheckIfValid(addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition]);
    addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].IsValid = isValid;

    local invalidConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.Condition" .. numCondition .. ".args.InvalidCondition");
    invalidConditionTable.hidden = isValid;
    invalidConditionTable.name = desc:SetColorLightRed();

    CheckIfRuleIsValid(numRule);
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

local function ConditionItemLevelValueSet(numRule, numCondition, value)
    if strtrim(value) == "" then
        addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Value = 0;
    elseif tonumber(value) == nil then
        ShowAlert(addon.L["ItemLevel is not a valid item level."]:ReplaceVars(value));
    else
        addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Value = tonumber(value);
    end
    CheckIfConditionIsValid(numRule, numCondition);
end

local function ConditionCriteriaTypeSet_ItemLevel(numRule, numCondition)
    KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.Condition" .. numCondition .. ".args", "Operator", {
        order = OrderPP(), type = "select", width = AdjustedWidth(0.5),
        name = "",
        values = equalityOperator.List,
        get = function() return addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Operator; end,
        set = function(_, _value)
            addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Operator = _value;
            CheckIfConditionIsValid(numRule, numCondition);
        end
    });
    KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.Condition" .. numCondition .. ".args", "Value", {
        order = OrderPP(), type = "input", width = AdjustedWidth(0.4),
        name = "",
        get = function() return tostring(addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Value or ""); end,
        set = function(_, _value) ConditionItemLevelValueSet(numRule, numCondition, _value); end
    });
    options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args.Conditions.args["Condition" .. numCondition].args.Blank1 = nil;
end

local function ConditionCriteriaTypeSet_Soulbound(numRule, numCondition)
    KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.Condition" .. numCondition .. ".args", "Blank1", {
        order = OrderPP(), type = "description", width = AdjustedWidth(0.9), name = ""
    });
    addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Operator = nil;
    addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Value = nil;
    options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args.Conditions.args["Condition" .. numCondition].args.Operator = nil;
    options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args.Conditions.args["Condition" .. numCondition].args.Value = nil;
end

local function ConditionCriteriaTypeSet_Other(numRule, numCondition)
    KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.Condition" .. numCondition .. ".args", "Blank1", {
        order = OrderPP(), type = "description", width = AdjustedWidth(0.9), name = ""
    });
    addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Operator = nil;
    addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Value = nil;
    options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args.Conditions.args["Condition" .. numCondition].args.Operator = nil;
    options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args.Conditions.args["Condition" .. numCondition].args.Value = nil;
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
    local deleteConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.Condition" .. numCondition .. ".args.DeleteCondition");
    deleteConditionTable.order = OrderPP();
    CheckIfConditionIsValid(numRule, numCondition);
    local invalidConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.Condition" .. numCondition .. ".args.InvalidCondition");
    invalidConditionTable.order = OrderPP();
end

local function AddConditionTable(numRule, numCondition)
    KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args", "Condition" .. tostring(numCondition), {
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
                    options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args.Conditions.args["Condition" .. numCondition] = nil;
                    addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition] = removedFlag;
                    CheckIfRuleIsValid(numRule);
                    removedElementPending = true;
                end
            },
            InvalidCondition = {
                order = OrderPP(), type = "description", width = "full",
                name = addon.L["InvalidCondition"]:SetColorLightRed(),
                fontSize = "medium"
            }
        }
    });
    ConditionCriteriaTypeSet(numRule, numCondition, addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].CriteriaType);
    local addNewConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.AddNewCondition");
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
                    removedElementPending = true;
                end
            },
            InvalidRule = {
                order = OrderPP(), type = "description", width = "full",
                name = addon.L["InvalidRule"]:SetColorLightRed(),
                fontSize = "medium"
            },
            ItemClassesHeader = {
                order = OrderPP(), type = "header",
                name = addon.L["Sell selected item types"]
            },
            ItemTypes = {
                order = OrderPP(), type = "group", inline = true,
                name = "",
                args = {
                    AddNewItemType = {
                        order = OrderPP(), type = "execute",
                        name = addon.L["Add new item type"],
                        func = function() AddNewItemTypeFunc(numRule) end
                    }
                }
            },
            -- AtLeastOneItemClass = {
            --     order = OrderPP(), type = "description", width = "full",
            --     name = addon.L["AtLeastOneItemClass"]:SetColorLightRed(),
            --     fontSize = "medium"
            -- },
            ConditionsHeader = {
                order = OrderPP(), type = "header",
                name = addon.L["Conditions"]
            },
            Conditions = {
                order = OrderPP(), type = "group", inline = true,
                name = "",
                args = {
                    AddNewCondition = {
                        order = OrderPP(), type = "execute",
                        name = addon.L["Add new condition"],
                        func = function() AddNewConditionFunc(numRule) end
                    }
                }
            }
        }
    });
    CheckIfRuleIsValid(numRule);
end

local function AddNewRuleFunc()
    addon.Options.db.AutoSell.RulesHistoryCounter = addon.Options.db.AutoSell.RulesHistoryCounter + 1;
    tinsert(addon.Options.db.AutoSell.Rules, {
        Name = "Rule " .. addon.Options.db.AutoSell.RulesHistoryCounter,
        IsValid = false,
        NumSelectedItemClasses = 0,
        ItemTypes = {},
        Conditions = {}
    });
    local numRules = #addon.Options.db.AutoSell.Rules;
    AddRuleTable(numRules);
    AddNewConditionFunc(numRules);
end

local function CleanUpRemovedRules()
    -- Clean up deleted rules during previous session
    for i = #addon.Options.db.AutoSell.Rules, 1, -1 do
        if addon.Options.db.AutoSell.Rules[i] == removedFlag then
            tremove(addon.Options.db.AutoSell.Rules, i);
        end
    end
end

local function CleanUpRemovedItemTypes(numRule)
    -- Clean up deleted conditions during previous session
    for i = #addon.Options.db.AutoSell.Rules[numRule].ItemTypes, 1, -1 do
        if addon.Options.db.AutoSell.Rules[numRule].ItemTypes[i] == removedFlag then
            tremove(addon.Options.db.AutoSell.Rules[numRule].ItemTypes, i);
        end
    end
end

local function CleanUpRemovedConditions(numRule)
    -- Clean up deleted conditions during previous session
    for i = #addon.Options.db.AutoSell.Rules[numRule].Conditions, 1, -1 do
        if addon.Options.db.AutoSell.Rules[numRule].Conditions[i] == removedFlag then
            tremove(addon.Options.db.AutoSell.Rules[numRule].Conditions, i);
        end
    end
end

function autoSell.PostLoad()
    CleanUpRemovedRules();
    for i, _ in next, addon.Options.db.AutoSell.Rules do
        AddRuleTable(i);
        CleanUpRemovedItemTypes(i);
        for j, _ in next, addon.Options.db.AutoSell.Rules[i].ItemTypes do
            AddItemTypeTable(i, j);
        end
        CleanUpRemovedConditions(i);
        for j, _ in next, addon.Options.db.AutoSell.Rules[i].Conditions do
            AddConditionTable(i, j);
        end
    end
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

hooksecurefunc(SettingsPanel, "Hide", function()
    if not removedElementPending then
        return;
    end

    CleanUpRemovedRules();
    for i, _ in next, addon.Options.db.AutoSell.Rules do
        CleanUpRemovedItemTypes(i);
        CleanUpRemovedConditions(i);
    end
    removedElementPending = nil;
end);

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
                },
                OpenInventory = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(),
                    name = addon.L["Open inventory"],
                    desc = addon.L["Open inventory Desc"],
                    func = function()
                        SettingsPanel:SetAttribute("UIPanelLayout-allowOtherPanels", 1);
                        OpenAllBags(SettingsPanel);
                        SettingsPanel:SetAttribute("UIPanelLayout-allowOtherPanels", nil);
                    end
                }
            }
        }
    }
};