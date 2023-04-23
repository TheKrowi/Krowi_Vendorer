-- [[ Namespaces ]] --
local _, addon = ...;
local options = addon.Options;
options.AutoSell = {};
local autoSell = options.AutoSell;
tinsert(options.OptionsTables, autoSell);

local criteriaType = addon.Objects.CriteriaType;
local equalityOperator = addon.Objects.EqualityOperator;
local itemType = addon.Objects.ItemType;
local itemQuality = addon.Objects.ItemQuality;
local removedElementPending;

local OrderPP = KrowiV_InjectOptions.AutoOrderPlusPlus;
local AdjustedWidth = KrowiV_InjectOptions.AdjustedWidth;

function autoSell.RegisterOptionsTable()
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Auto Sell", options.OptionsTable.args.AutoSell);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Auto Sell", "Auto Sell", addon.MetaData.Title);
end

local removedFlag = "REMOVED";

do -- [[ Rule ]]
    local function CheckIfRuleIsValid(numRule)
        local isValid = true;
        for _, _itemType in next, KrowiV_SavedData.Rules[numRule].ItemTypes do
            if _itemType ~= removedFlag then
                isValid = isValid and _itemType.IsValid;
            end
        end
        for _, condition in next, KrowiV_SavedData.Rules[numRule].Conditions do
            if condition ~= removedFlag then
                isValid = isValid and (criteriaType.CheckIfValid(condition));
            end
        end
        KrowiV_SavedData.Rules[numRule].IsValid = isValid;

        local invalidRuleTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.InvalidRule");
        invalidRuleTable.hidden = isValid;

        addon.GUI.ItemListFrame.AutoSellList.Update();
    end
    autoSell.CheckIfRuleIsValid = CheckIfRuleIsValid;

    local function AddRuleTable(numRule)
        KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args", "Rule" .. tostring(numRule), {
            order = OrderPP(), type = "group",
            name = KrowiV_SavedData.Rules[numRule].Name,
            args = {
                Name = {
                    order = OrderPP(), type = "input", width = AdjustedWidth(1.5),
                    name = addon.L["Name"],
                    get = function() return KrowiV_SavedData.Rules[numRule].Name; end,
                    set = function(_, value)
                        KrowiV_SavedData.Rules[numRule].Name = value;
                        local ruleTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule);
                        ruleTable.name = value;
                    end
                },
                DeleteRule = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(0.5),
                    name = addon.L["Delete rule"],
                    desc = addon.L["Delete rule Desc"],
                    func = function()
                        options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule] = nil;
                        KrowiV_SavedData.Rules[numRule] = removedFlag;
                        removedElementPending = true;
                    end
                },
                Enabled = {
                    order = OrderPP(), type = "toggle", width = AdjustedWidth(0.8),
                    name = addon.L["Enabled"],
                    desc = addon.L["Enabled Desc"],
                    get = function() return KrowiV_SavedData.Rules[numRule].IsEnabled; end,
                    set = function(_, value) KrowiV_SavedData.Rules[numRule].IsEnabled = value; end
                },
                InvalidRule = {
                    order = OrderPP(), type = "description", width = "full",
                    name = addon.L["Invalid Rule"]:SetColorLightRed(),
                    fontSize = "medium"
                },
                ItemTypeHeader = {
                    order = OrderPP(), type = "header",
                    name = addon.L["Item types and sub types"]
                },
                ItemTypes = {
                    order = OrderPP(), type = "group", inline = true,
                    name = "",
                    args = {
                        AddNewItemType = {
                            order = OrderPP(), type = "execute",
                            name = addon.L["Add new item type"],
                            desc = addon.L["Add new item type Desc"],
                            func = function() autoSell.AddNewItemTypeFunc(numRule) end
                        }
                    }
                },
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
                            desc = addon.L["Add new condition Desc"],
                            func = function() autoSell.AddNewConditionFunc(numRule) end
                        }
                    }
                }
            }
        });
        autoSell.CheckIfRuleIsValid(numRule);
    end
    autoSell.AddRuleTable = AddRuleTable;

    local function AddNewRuleFunc(scope)
        local character = addon.GetCurrentCharacter();
        KrowiV_SavedData.RulesHistoryCounter = KrowiV_SavedData.RulesHistoryCounter + 1;
        tinsert(KrowiV_SavedData.Rules, {
            Name = "Rule " .. KrowiV_SavedData.RulesHistoryCounter,
            IsValid = false,
            IsEnabled = true,
            NumSelectedItemClasses = 0,
            ItemTypes = {},
            Conditions = {}
        });
        local numRules = #KrowiV_SavedData.Rules;
        AddRuleTable(numRules);
        -- autoSell.AddNewConditionFunc(numRules);
    end
    autoSell.AddNewRuleFunc = AddNewRuleFunc;
end

do -- [[ ItemType ]]
    local function CheckIfItemTypeIsValid(numRule, numItemType)
        local isValid = KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].Type ~= nil;
        if KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].CheckSubType then
            isValid = isValid and KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].NumSelectedSubTypes > 0;
        end
        KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].IsValid = isValid;
        autoSell.CheckIfRuleIsValid(numRule);
    end

    local function ResetItemTypeSubTypes(numRule, numItemType)
        KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].NumSelectedSubTypes = 0;
        for index, _ in next, KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].SubTypes do
            KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].SubTypes[index] = nil;
        end
    end

    local function ItemTypeTypeSet(numRule, numItemType, value, reset)
        KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].Type = value;
        if reset then
            ResetItemTypeSubTypes(numRule, numItemType);
        end
        CheckIfItemTypeIsValid(numRule, numItemType);
    end

    local function ItemTypeCheckSubTypeSet(numRule, numItemType, value)
        KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].CheckSubType = value;
        if not value then
            ResetItemTypeSubTypes(numRule, numItemType);
        end
        CheckIfItemTypeIsValid(numRule, numItemType);
    end

    local function DeleteItemType(numRule, numItemType)
        options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args.ItemTypes.args["ItemType" .. numItemType] = nil;
        KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType] = removedFlag;
        autoSell.CheckIfRuleIsValid(numRule);
        removedElementPending = true;
    end

    local function ItemTypeSubTypeSet(numRule, numItemType, index, value)
        if value then
            KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].NumSelectedSubTypes = KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].NumSelectedSubTypes + 1;
        else
            KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].NumSelectedSubTypes = KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].NumSelectedSubTypes - 1;
        end
        KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].SubTypes[index] = value;
        CheckIfItemTypeIsValid(numRule, numItemType);
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
                    get = function() return KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].Type; end,
                    set = function(_, value) ItemTypeTypeSet(numRule, numItemType, value, true); end
                },
                CheckSubType = {
                    order = OrderPP(), type = "toggle", width = AdjustedWidth(0.8),
                    name = addon.L["Select sub type"],
                    desc = addon.L["Select sub type Desc"],
                    get = function() return KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].CheckSubType; end,
                    set = function(_, value) ItemTypeCheckSubTypeSet(numRule, numItemType, value); end
                },
                DeleteItemType = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(0.4),
                    name = addon.L["Delete"],
                    desc = addon.L["Delete type Desc"],
                    func = function() DeleteItemType(numRule, numItemType); end
                },
                InvalidItemType = {
                    order = OrderPP(), type = "description", width = "full",
                    name = addon.L["No item type selected"]:SetColorLightRed(),
                    fontSize = "medium",
                    hidden = function() return KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].Type ~= nil; end
                },
                SubTypes = {
                    order = OrderPP(), type = "multiselect", width = "full",
                    name = "",
                    values = function() return itemType.SubTypeList[KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].Type] end,
                    get = function(_, index) return KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].SubTypes[index]; end,
                    set = function(_, index, value) ItemTypeSubTypeSet(numRule, numItemType, index, value); end,
                    control = "Dropdown",
                    hidden = function() return not KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType].CheckSubType; end
                },
                AtLeastOneItemSubTypeMustBeSelected = {
                    order = OrderPP(), type = "description", width = "full",
                    name = addon.L["At least one item sub type must be selected"]:SetColorLightRed(),
                    fontSize = "medium",
                    hidden = function()
                        local thisItemType = KrowiV_SavedData.Rules[numRule].ItemTypes[numItemType];
                        return not thisItemType.CheckSubType or thisItemType.NumSelectedSubTypes > 0;
                    end
                },
            }
        });
        CheckIfItemTypeIsValid(numRule, numItemType);
        local addNewItemClassTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.ItemTypes.args.AddNewItemType");
        addNewItemClassTable.order = OrderPP();
    end
    autoSell.AddItemTypeTable = AddItemTypeTable;

    local function AddNewItemTypeFunc(numRule)
        tinsert(KrowiV_SavedData.Rules[numRule].ItemTypes, {
            SubTypes = {},
            NumSelectedSubTypes = 0
        });
        local numItemType = #KrowiV_SavedData.Rules[numRule].ItemTypes;
        AddItemTypeTable(numRule, numItemType);
    end
    autoSell.AddNewItemTypeFunc = AddNewItemTypeFunc;
end

do -- [[ Condition ]]
    local function CheckIfConditionIsValid(numRule, numCondition)
        local isValid, desc = criteriaType.CheckIfValid(KrowiV_SavedData.Rules[numRule].Conditions[numCondition]);
        KrowiV_SavedData.Rules[numRule].Conditions[numCondition].IsValid = isValid;
        local invalidConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.Condition" .. numCondition .. ".args.InvalidCondition");
        invalidConditionTable.name = desc:SetColorLightRed();
        autoSell.CheckIfRuleIsValid(numRule);
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
            KrowiV_SavedData.Rules[numRule].Conditions[numCondition].Value = 0;
        elseif tonumber(value) == nil then
            ShowAlert(addon.L["ItemLevel is not a valid item level."]:ReplaceVars(value));
        else
            KrowiV_SavedData.Rules[numRule].Conditions[numCondition].Value = tonumber(value);
        end
        CheckIfConditionIsValid(numRule, numCondition);
    end

    local function ConditionCriteriaTypeSet_Reset(numRule, numCondition, value)
        if value == criteriaType.Enum.Soulbound or value == criteriaType.Enum.Quality then
            KrowiV_SavedData.Rules[numRule].Conditions[numCondition].Operator = nil;
            KrowiV_SavedData.Rules[numRule].Conditions[numCondition].Value = nil;
        end
        if value == criteriaType.Enum.ItemLevel or value == criteriaType.Enum.Soulbound then
            KrowiV_SavedData.Rules[numRule].Conditions[numCondition].Qualities = nil;
            KrowiV_SavedData.Rules[numRule].Conditions[numCondition].NumSelectedQualities = nil;
        end
        options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args.Conditions.args["Condition" .. numCondition].args.Operator = nil;
        options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args.Conditions.args["Condition" .. numCondition].args.Value = nil;
        options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args.Conditions.args["Condition" .. numCondition].args.Blank1 = nil;
    end

    local function ConditionCriteriaTypeSet_ItemLevel(numRule, numCondition)
        KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.Condition" .. numCondition .. ".args", "Operator", {
            order = OrderPP(), type = "select", width = AdjustedWidth(0.5),
            name = "",
            values = equalityOperator.List,
            get = function() return KrowiV_SavedData.Rules[numRule].Conditions[numCondition].Operator; end,
            set = function(_, _value)
                KrowiV_SavedData.Rules[numRule].Conditions[numCondition].Operator = _value;
                CheckIfConditionIsValid(numRule, numCondition);
            end
        });
        KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.Condition" .. numCondition .. ".args", "Value", {
            order = OrderPP(), type = "input", width = AdjustedWidth(0.4),
            name = "",
            get = function() return tostring(KrowiV_SavedData.Rules[numRule].Conditions[numCondition].Value or ""); end,
            set = function(_, _value) ConditionItemLevelValueSet(numRule, numCondition, _value); end
        });
    end

    local function ConditionCriteriaTypeSet_Soulbound(numRule, numCondition)
        KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.Condition" .. numCondition .. ".args", "Blank1", {
            order = OrderPP(), type = "description", width = AdjustedWidth(0.9), name = ""
        });
    end

    local function ConditionCriteriaTypeSet_Quality(numRule, numCondition)
        KrowiV_SavedData.Rules[numRule].Conditions[numCondition].Qualities = KrowiV_SavedData.Rules[numRule].Conditions[numCondition].Qualities or {};
        KrowiV_SavedData.Rules[numRule].Conditions[numCondition].NumSelectedQualities = KrowiV_SavedData.Rules[numRule].Conditions[numCondition].NumSelectedQualities or 0;
        KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.Condition" .. numCondition .. ".args", "Value", {
            order = OrderPP(), type = "multiselect", width = AdjustedWidth(0.9),
            name = "",
            values = itemQuality.List,
            get = function(_, index) return KrowiV_SavedData.Rules[numRule].Conditions[numCondition].Qualities[index]; end,
            set = function(_, index, value)
                if value then
                    KrowiV_SavedData.Rules[numRule].Conditions[numCondition].NumSelectedQualities = KrowiV_SavedData.Rules[numRule].Conditions[numCondition].NumSelectedQualities + 1;
                else
                    KrowiV_SavedData.Rules[numRule].Conditions[numCondition].NumSelectedQualities = KrowiV_SavedData.Rules[numRule].Conditions[numCondition].NumSelectedQualities - 1;
                end
                KrowiV_SavedData.Rules[numRule].Conditions[numCondition].Qualities[index] = value;
                CheckIfConditionIsValid(numRule, numCondition);
            end,
            control = "Dropdown"
        });
    end

    local function ConditionCriteriaTypeSet(numRule, numCondition, value)
        KrowiV_SavedData.Rules[numRule].Conditions[numCondition].CriteriaType = value;
        ConditionCriteriaTypeSet_Reset(numRule, numCondition, value);

        if value == criteriaType.Enum.ItemLevel then
            ConditionCriteriaTypeSet_ItemLevel(numRule, numCondition);
        elseif value == criteriaType.Enum.Soulbound then
            ConditionCriteriaTypeSet_Soulbound(numRule, numCondition);
        elseif value == criteriaType.Enum.Quality then
            ConditionCriteriaTypeSet_Quality(numRule, numCondition);
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
                    get = function() return KrowiV_SavedData.Rules[numRule].Conditions[numCondition].CriteriaType; end,
                    set = function(_, value) ConditionCriteriaTypeSet(numRule, numCondition, value); end
                },
                DeleteCondition = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(0.4),
                    name = addon.L["Delete"],
                    desc = addon.L["Delete Condition Desc"],
                    func = function()
                        options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args.Conditions.args["Condition" .. numCondition] = nil;
                        KrowiV_SavedData.Rules[numRule].Conditions[numCondition] = removedFlag;
                        autoSell.CheckIfRuleIsValid(numRule);
                        removedElementPending = true;
                    end
                },
                InvalidCondition = {
                    order = OrderPP(), type = "description", width = "full",
                    name = addon.L["Invalid condition"]:SetColorLightRed(),
                    fontSize = "medium",
                    hidden = function() return KrowiV_SavedData.Rules[numRule].Conditions[numCondition].IsValid; end
                }
            }
        });
        ConditionCriteriaTypeSet(numRule, numCondition, KrowiV_SavedData.Rules[numRule].Conditions[numCondition].CriteriaType);
        local addNewConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.AddNewCondition");
        addNewConditionTable.order = OrderPP();
    end
    autoSell.AddConditionTable = AddConditionTable;

    function AddNewConditionFunc(numRule)
        tinsert(KrowiV_SavedData.Rules[numRule].Conditions, {});
        local numConditions = #KrowiV_SavedData.Rules[numRule].Conditions;
        AddConditionTable(numRule, numConditions);
    end
    autoSell.AddNewConditionFunc = AddNewConditionFunc;
end

local function CleanUpRemovedRules()
    -- Clean up deleted rules during previous session
    for i = #KrowiV_SavedData.Rules, 1, -1 do
        if KrowiV_SavedData.Rules[i] == removedFlag then
            tremove(KrowiV_SavedData.Rules, i);
        end
    end
end

local function CleanUpRemovedItemTypes(numRule)
    -- Clean up deleted conditions during previous session
    for i = #KrowiV_SavedData.Rules[numRule].ItemTypes, 1, -1 do
        if KrowiV_SavedData.Rules[numRule].ItemTypes[i] == removedFlag then
            tremove(KrowiV_SavedData.Rules[numRule].ItemTypes, i);
        end
    end
end

local function CleanUpRemovedConditions(numRule)
    -- Clean up deleted conditions during previous session
    for i = #KrowiV_SavedData.Rules[numRule].Conditions, 1, -1 do
        if KrowiV_SavedData.Rules[numRule].Conditions[i] == removedFlag then
            tremove(KrowiV_SavedData.Rules[numRule].Conditions, i);
        end
    end
end

function autoSell.PostLoad()
    KrowiV_SavedData.Rules = KrowiV_SavedData.Rules or {};
    KrowiV_SavedData.RulesHistoryCounter = KrowiV_SavedData.RulesHistoryCounter or 0;
    CleanUpRemovedRules();
    for i, _ in next, KrowiV_SavedData.Rules do
        autoSell.AddRuleTable(i);
        CleanUpRemovedItemTypes(i);
        for j, _ in next, KrowiV_SavedData.Rules[i].ItemTypes do
            autoSell.AddItemTypeTable(i, j);
        end
        CleanUpRemovedConditions(i);
        for j, _ in next, KrowiV_SavedData.Rules[i].Conditions do
            autoSell.AddConditionTable(i, j);
        end
    end
end

hooksecurefunc(SettingsPanel, "Hide", function()
    if not removedElementPending then
        return;
    end

    CleanUpRemovedRules();
    for i, _ in next, KrowiV_SavedData.Rules do
        CleanUpRemovedItemTypes(i);
        CleanUpRemovedConditions(i);
    end
    removedElementPending = nil;
end);

options.OptionsTable.args["AutoSell"] = {
    type = "group", childGroups = "tab",
    name = addon.L["Auto Sell"],
    args = {
        -- Tooltip = {
        --     order = OrderPP(), type = "group",
        --     name = addon.L["Tooltip"],
        --     args = {
        --         -- Operator = {
        --         --     order = OrderPP(), type = "select", width = AdjustedWidth(),
        --         --     name = addon.L["Operator"],
        --         --     desc = addon.L["Operator Desc"]:AddDefaultValueText_KV("AutoSell.Operator", addon.Operators),
        --         --     values = addon.Operators,
        --         --     get = function() return KrowiV_SavedData.Operator; end,
        --         --     set = function(_, value) KrowiV_SavedData.Operator = value; end
        --         -- },
        --     }
        -- },
        Rules = {
            order = OrderPP(), type = "group",
            name = addon.L["Account Rules"],
            args = {
                AddNewRule = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(),
                    name = addon.L["Add new rule"],
                    desc = addon.L["Add new rule Desc"],
                    func = function() autoSell.AddNewRuleFunc("Account"); end
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
                },
                OpenAutoSellListFrame = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(),
                    name = addon.L["Open Auto Sell List"],
                    desc = addon.L["Open Auto Sell List Desc"],
                    func = function()
                        addon.GUI.ItemListFrame.AutoSellList:ShowStandalone();
                    end
                }
            }
        },
        CharactertRules = {
            order = OrderPP(), type = "group",
            name = addon.L["Character Rules"],
            args = {
                AddNewRule = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(),
                    name = addon.L["Add new rule"],
                    desc = addon.L["Add new rule Desc"],
                    func = function() autoSell.AddNewRuleFunc("Character"); end
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
                },
                OpenAutoSellListFrame = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(),
                    name = addon.L["Open Auto Sell List"],
                    desc = addon.L["Open Auto Sell List Desc"],
                    func = function()
                        addon.GUI.ItemListFrame.AutoSellList:ShowStandalone();
                    end
                }
            }
        }
    }
};