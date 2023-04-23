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
        for _, _itemType in next, addon.Options.db.AutoSell.Rules[numRule].ItemTypes do
            if _itemType ~= removedFlag then
                isValid = isValid and _itemType.IsValid;
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

        addon.GUI.ItemListFrame.AutoSellList.Update();
    end
    autoSell.CheckIfRuleIsValid = CheckIfRuleIsValid;

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
                    desc = addon.L["Delete rule Desc"],
                    func = function()
                        options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule] = nil;
                        addon.Options.db.AutoSell.Rules[numRule] = removedFlag;
                        removedElementPending = true;
                    end
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
        -- autoSell.AddNewConditionFunc(numRules);
    end
    autoSell.AddNewRuleFunc = AddNewRuleFunc;
end

do -- [[ ItemType ]]
    local function CheckIfItemTypeIsValid(numRule, numItemType)
        local isValid = addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].Type ~= nil;
        if addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].CheckSubType then
            isValid = isValid and addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].NumSelectedSubTypes > 0;
        end
        addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].IsValid = isValid;
        autoSell.CheckIfRuleIsValid(numRule);
    end

    local function ResetItemTypeSubTypes(numRule, numItemType)
        addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].NumSelectedSubTypes = 0;
        for index, _ in next, addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].SubTypes do
            addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].SubTypes[index] = nil;
        end
    end

    local function ItemTypeTypeSet(numRule, numItemType, value, reset)
        addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].Type = value;
        if reset then
            ResetItemTypeSubTypes(numRule, numItemType);
        end
        CheckIfItemTypeIsValid(numRule, numItemType);
    end

    local function ItemTypeCheckSubTypeSet(numRule, numItemType, value)
        addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].CheckSubType = value;
        if not value then
            ResetItemTypeSubTypes(numRule, numItemType);
        end
        CheckIfItemTypeIsValid(numRule, numItemType);
    end

    local function DeleteItemType(numRule, numItemType)
        options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args.ItemTypes.args["ItemType" .. numItemType] = nil;
        addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType] = removedFlag;
        autoSell.CheckIfRuleIsValid(numRule);
        removedElementPending = true;
    end

    local function ItemTypeSubTypeSet(numRule, numItemType, index, value)
        if value then
            addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].NumSelectedSubTypes = addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].NumSelectedSubTypes + 1;
        else
            addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].NumSelectedSubTypes = addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].NumSelectedSubTypes - 1;
        end
        addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].SubTypes[index] = value;
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
                    get = function() return addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].Type; end,
                    set = function(_, value) ItemTypeTypeSet(numRule, numItemType, value, true); end
                },
                CheckSubType = {
                    order = OrderPP(), type = "toggle", width = AdjustedWidth(0.8),
                    name = addon.L["Select sub type"],
                    desc = addon.L["Select sub type Desc"],
                    get = function() return addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].CheckSubType; end,
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
                    hidden = function() return addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].Type ~= nil; end
                },
                SubTypes = {
                    order = OrderPP(), type = "multiselect", width = "full",
                    name = "",
                    values = function() return itemType.SubTypeList[addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].Type] end,
                    get = function(_, index) return addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].SubTypes[index]; end,
                    set = function(_, index, value) ItemTypeSubTypeSet(numRule, numItemType, index, value); end,
                    control = "Dropdown",
                    hidden = function() return not addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType].CheckSubType; end
                },
                AtLeastOneItemSubTypeMustBeSelected = {
                    order = OrderPP(), type = "description", width = "full",
                    name = addon.L["At least one item sub type must be selected"]:SetColorLightRed(),
                    fontSize = "medium",
                    hidden = function()
                        local thisItemType = addon.Options.db.AutoSell.Rules[numRule].ItemTypes[numItemType];
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
        tinsert(addon.Options.db.AutoSell.Rules[numRule].ItemTypes, {
            SubTypes = {},
            NumSelectedSubTypes = 0
        });
        local numItemType = #addon.Options.db.AutoSell.Rules[numRule].ItemTypes;
        AddItemTypeTable(numRule, numItemType);
    end
    autoSell.AddNewItemTypeFunc = AddNewItemTypeFunc;
end

do -- [[ Condition ]]
    local function CheckIfConditionIsValid(numRule, numCondition)
        local isValid, desc = criteriaType.CheckIfValid(addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition]);
        addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].IsValid = isValid;
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
            addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Value = 0;
        elseif tonumber(value) == nil then
            ShowAlert(addon.L["ItemLevel is not a valid item level."]:ReplaceVars(value));
        else
            addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Value = tonumber(value);
        end
        CheckIfConditionIsValid(numRule, numCondition);
    end

    local function ConditionCriteriaTypeSet_Reset(numRule, numCondition, value)
        if value == criteriaType.Enum.Soulbound or value == criteriaType.Enum.Quality then
            addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Operator = nil;
            addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Value = nil;
        end
        if value == criteriaType.Enum.ItemLevel or value == criteriaType.Enum.Soulbound then
            addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Qualities = nil;
            addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].NumSelectedQualities = nil;
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
    end

    local function ConditionCriteriaTypeSet_Soulbound(numRule, numCondition)
        KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.Condition" .. numCondition .. ".args", "Blank1", {
            order = OrderPP(), type = "description", width = AdjustedWidth(0.9), name = ""
        });
    end

    local function ConditionCriteriaTypeSet_Quality(numRule, numCondition)
        addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Qualities = addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Qualities or {};
        addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].NumSelectedQualities = addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].NumSelectedQualities or 0;
        KrowiV_InjectOptions:AddTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.Condition" .. numCondition .. ".args", "Value", {
            order = OrderPP(), type = "multiselect", width = AdjustedWidth(0.9),
            name = "",
            values = itemQuality.List,
            get = function(_, index) return addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Qualities[index]; end,
            set = function(_, index, value)
                if value then
                    addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].NumSelectedQualities = addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].NumSelectedQualities + 1;
                else
                    addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].NumSelectedQualities = addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].NumSelectedQualities - 1;
                end
                addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].Qualities[index] = value;
                CheckIfConditionIsValid(numRule, numCondition);
            end,
            control = "Dropdown"
        });
    end

    local function ConditionCriteriaTypeSet(numRule, numCondition, value)
        addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].CriteriaType = value;
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
                    get = function() return addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].CriteriaType; end,
                    set = function(_, value) ConditionCriteriaTypeSet(numRule, numCondition, value); end
                },
                DeleteCondition = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(0.4),
                    name = addon.L["Delete"],
                    desc = addon.L["Delete Condition Desc"],
                    func = function()
                        options.OptionsTable.args["AutoSell"].args.Rules.args["Rule" .. numRule].args.Conditions.args["Condition" .. numCondition] = nil;
                        addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition] = removedFlag;
                        autoSell.CheckIfRuleIsValid(numRule);
                        removedElementPending = true;
                    end
                },
                InvalidCondition = {
                    order = OrderPP(), type = "description", width = "full",
                    name = addon.L["Invalid condition"]:SetColorLightRed(),
                    fontSize = "medium",
                    hidden = function() return addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].IsValid; end
                }
            }
        });
        ConditionCriteriaTypeSet(numRule, numCondition, addon.Options.db.AutoSell.Rules[numRule].Conditions[numCondition].CriteriaType);
        local addNewConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args.Rules.args.Rule" .. numRule .. ".args.Conditions.args.AddNewCondition");
        addNewConditionTable.order = OrderPP();
    end
    autoSell.AddConditionTable = AddConditionTable;

    function AddNewConditionFunc(numRule)
        tinsert(addon.Options.db.AutoSell.Rules[numRule].Conditions, {});
        local numConditions = #addon.Options.db.AutoSell.Rules[numRule].Conditions;
        AddConditionTable(numRule, numConditions);
    end
    autoSell.AddNewConditionFunc = AddNewConditionFunc;
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
        autoSell.AddRuleTable(i);
        CleanUpRemovedItemTypes(i);
        for j, _ in next, addon.Options.db.AutoSell.Rules[i].ItemTypes do
            autoSell.AddItemTypeTable(i, j);
        end
        CleanUpRemovedConditions(i);
        for j, _ in next, addon.Options.db.AutoSell.Rules[i].Conditions do
            autoSell.AddConditionTable(i, j);
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
        -- General = {
        --     order = OrderPP(), type = "group",
        --     name = addon.L["General"],
        --     args = {
        --         Quality = {
        --             order = OrderPP(), type = "group", inline = true,
        --             name = addon.L["Quality"],
        --             args = {
        --                 Description = {
        --                     order = OrderPP(), type = "description", width = "full",
        --                     name = addon.L["Auto Sell Quality Desc"],
        --                     fontSize = "medium"
        --                 },
        --                 Poor = {
        --                     order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
        --                     name = addon.L["Poor"]:SetColorPoor(),
        --                     get = function() return addon.Options.db.AutoSell.Quality[1]; end,
        --                     set = function()
        --                         addon.Options.db.AutoSell.Quality[1] = not addon.Options.db.AutoSell.Quality[1];
        --                     end
        --                 },
        --                 Common = {
        --                     order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
        --                     name = addon.L["Common"]:SetColorCommon(),
        --                     get = function() return addon.Options.db.AutoSell.Quality[2]; end,
        --                     set = function()
        --                         addon.Options.db.AutoSell.Quality[2] = not addon.Options.db.AutoSell.Quality[2];
        --                     end
        --                 },
        --                 Uncommon = {
        --                     order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
        --                     name = addon.L["Uncommon"]:SetColorUncommon(),
        --                     get = function() return addon.Options.db.AutoSell.Quality[3]; end,
        --                     set = function()
        --                         addon.Options.db.AutoSell.Quality[3] = not addon.Options.db.AutoSell.Quality[3];
        --                     end
        --                 },
        --                 Rare = {
        --                     order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
        --                     name = addon.L["Rare"]:SetColorRare(),
        --                     get = function() return addon.Options.db.AutoSell.Quality[4]; end,
        --                     set = function()
        --                         addon.Options.db.AutoSell.Quality[4] = not addon.Options.db.AutoSell.Quality[4];
        --                     end
        --                 },
        --                 Epic = {
        --                     order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
        --                     name = addon.L["Epic"]:SetColorEpic(),
        --                     get = function() return addon.Options.db.AutoSell.Quality[5]; end,
        --                     set = function()
        --                         addon.Options.db.AutoSell.Quality[5] = not addon.Options.db.AutoSell.Quality[5];
        --                     end
        --                 }
        --             }
        --         },
        --         ItemLevel = {
        --             order = OrderPP(), type = "group", inline = true,
        --             name = addon.L["Quality"],
        --             args = {
        --                 Description = {
        --                     order = OrderPP(), type = "description", width = "full",
        --                     name = addon.L["Auto Sell Item Level Desc"],
        --                     fontSize = "medium"
        --                 },
        --                 ItemLevel = {
        --                     order = OrderPP(), type = "input", width = AdjustedWidth(),
        --                     name = addon.L["Item Level"],
        --                     get = function() return tostring(addon.Options.db.AutoSell.ItemLevel); end,
        --                     set = ItemLevelSet
        --                 }
        --             }
        --         },
        --         Artifactrelic = {
        --             order = OrderPP(), type = "group", inline = true,
        --             name = addon.L["Artifact relic"],
        --             args = {
        --                 Description = {
        --                     order = OrderPP(), type = "description", width = "full",
        --                     name = addon.L["Auto Sell Artifact Relic Desc"],
        --                     fontSize = "medium"
        --                 },
        --                 Epic = {
        --                     order = OrderPP(), type = "toggle", width = AdjustedWidth(0.5),
        --                     name = addon.L["Sell"],
        --                     get = function() return addon.Options.db.AutoSell.Artifactrelic; end,
        --                     set = function(_, value) addon.Options.db.AutoSell.Artifactrelic = value; end
        --                 }
        --             }
        --         }
        --     }
        -- },
        -- Tooltip = {
        --     order = OrderPP(), type = "group",
        --     name = addon.L["Tooltip"],
        --     args = {
        --         -- Operator = {
        --         --     order = OrderPP(), type = "select", width = AdjustedWidth(),
        --         --     name = addon.L["Operator"],
        --         --     desc = addon.L["Operator Desc"]:AddDefaultValueText_KV("AutoSell.Operator", addon.Operators),
        --         --     values = addon.Operators,
        --         --     get = function() return addon.Options.db.AutoSell.Operator; end,
        --         --     set = function(_, value) addon.Options.db.AutoSell.Operator = value; end
        --         -- },
        --     }
        -- },
        Rules = {
            order = OrderPP(), type = "group",
            name = addon.L["Rules"],
            args = {
                AddNewRule = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(),
                    name = addon.L["Add new rule"],
                    desc = addon.L["Add new rule Desc"],
                    func = autoSell.AddNewRuleFunc
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