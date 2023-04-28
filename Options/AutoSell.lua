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
local scope = addon.Objects.Scope;

local OrderPP = KrowiV_InjectOptions.AutoOrderPlusPlus;
local AdjustedWidth = KrowiV_InjectOptions.AdjustedWidth;

function autoSell.RegisterOptionsTable()
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Auto Sell", options.OptionsTable.args.AutoSell);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Auto Sell", "Auto Sell", addon.MetaData.Title);
end

local function GetRules(_scope)
    if _scope == scope.Character then
        local character = addon.GetCurrentCharacter();
        return character.Rules;
    end
    return KrowiV_SavedData.Rules;
end

do -- [[ Rule ]]
    local function CheckIfRuleIsValid(scopeName, rule)
        local isValid = true;
        for _, _itemType in next, rule.ItemTypes do
            if not _itemType.Remove then
                isValid = isValid and _itemType.IsValid;
            end
        end
        for _, condition in next, rule.Conditions do
            if not condition.Remove then
                isValid = isValid and (criteriaType.CheckIfValid(condition));
            end
        end
        rule.IsValid = isValid;

        local invalidRuleTable = KrowiV_InjectOptions:GetTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.InvalidRule");
        invalidRuleTable.hidden = isValid;

        addon.GUI.ItemListFrame.AutoSellList.Update();
    end
    autoSell.CheckIfRuleIsValid = CheckIfRuleIsValid;

    local function DeleteRule(scopeName, rule)
        options.OptionsTable.args["AutoSell"].args[scopeName .. "Rules"].args[rule.Guid] = nil;
        local _scope = addon.Objects.Scope[scopeName];
        addon.Util.TableRemoveByValue(GetRules(_scope), rule);
        addon.GUI.ItemListFrame.AutoSellList.Update();
    end

    local function AddRuleTable(scopeName, rule)
        KrowiV_InjectOptions:AddTable("AutoSell.args." .. scopeName .. "Rules.args", rule.Guid, {
            order = OrderPP(), type = "group",
            name = rule.Name,
            args = {
                Name = {
                    order = OrderPP(), type = "input", width = AdjustedWidth(1.5),
                    name = addon.L["Name"],
                    get = function() return rule.Name; end,
                    set = function(_, value)
                        rule.Name = value;
                        local ruleTable = KrowiV_InjectOptions:GetTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid);
                        ruleTable.name = value;
                    end,
                    disabled = function() return rule.IsPreset; end
                },
                DeleteRule = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(0.5),
                    name = addon.L["Delete rule"],
                    desc = addon.L["Delete rule Desc"],
                    func = function() DeleteRule(scopeName, rule); end
                },
                Enabled = {
                    order = OrderPP(), type = "toggle", width = AdjustedWidth(0.8),
                    name = addon.L["Enabled"],
                    desc = addon.L["Enabled Desc"],
                    get = function() return rule.IsEnabled; end,
                    set = function(_, value) rule.IsEnabled = value; end,
                    hidden = function() return rule.IsPreset; end
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
                        NoItemType = {
                            order = OrderPP(), type = "description", width = rule.IsPreset and "full" or AdjustedWidth(1.1),
                            name = addon.L["No item type"],
                            fontSize = "medium",
                            hidden = function()
                                local numItemTypes = 0;
                                for _, _itemType in next, rule.ItemTypes do
                                    numItemTypes = numItemTypes + (_itemType.Remove and 0 or 1);
                                end
                                return numItemTypes > 0;
                            end,
                            disabled = function() return rule.IsPreset; end
                        },
                        AddNewItemType = {
                            order = OrderPP(), type = "execute",
                            name = addon.L["Add new item type"],
                            desc = addon.L["Add new item type Desc"],
                            func = function() autoSell.AddNewItemTypeFunc(scopeName, rule); end,
                            hidden = function() return rule.IsPreset; end
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
                        NoCondition = {
                            order = OrderPP(), type = "description", width = rule.IsPreset and "full" or AdjustedWidth(1.1),
                            name = addon.L["No condition"],
                            fontSize = "medium",
                            hidden = function()
                                local numConditions = 0;
                                for _, condition in next, rule.Conditions do
                                    numConditions = numConditions + (condition.Remove and 0 or 1);
                                end
                                return numConditions > 0;
                            end,
                            disabled = function() return rule.IsPreset; end
                        },
                        AddNewCondition = {
                            order = OrderPP(), type = "execute",
                            name = addon.L["Add new condition"],
                            desc = addon.L["Add new condition Desc"],
                            func = function() autoSell.AddNewConditionFunc(scopeName, rule); end,
                            hidden = function() return rule.IsPreset; end
                        }
                    }
                }
            }
        });
        autoSell.CheckIfRuleIsValid(scopeName, rule);
    end
    autoSell.AddRuleTable = AddRuleTable;

    local function AddNewRuleFunc(_scope, guid, name)
        local unique = time() + random(time());
        local rule = {
            Guid = guid or ("Rule-" .. unique),
            Name = name or ("Rule " .. unique),
            IsValid = false,
            IsEnabled = true,
            NumSelectedItemClasses = 0,
            ItemTypes = {},
            Conditions = {}
        };
        tinsert(GetRules(_scope), rule);
        local scopeName = addon.Objects.ScopeList[_scope];
        AddRuleTable(scopeName, rule);
        return rule;
    end
    autoSell.AddNewRuleFunc = AddNewRuleFunc;
end

do -- [[ ItemType ]]
    local function CheckIfItemTypeIsValid(scopeName, rule, _itemType)
        local isValid = _itemType.Type ~= nil;
        if _itemType.CheckSubType then
            isValid = isValid and _itemType.NumSelectedSubTypes > 0;
        end
        _itemType.IsValid = isValid;
        autoSell.CheckIfRuleIsValid(scopeName, rule);
    end

    local function ResetItemTypeSubTypes(_itemType)
        _itemType.NumSelectedSubTypes = 0;
        for index, _ in next, _itemType.SubTypes do
            _itemType.SubTypes[index] = nil;
        end
    end

    local function ItemTypeTypeSet(scopeName, rule, _itemType, value, reset)
        _itemType.Type = value;
        if reset then
            ResetItemTypeSubTypes(_itemType);
        end
        CheckIfItemTypeIsValid(scopeName, rule, _itemType);
    end

    local function ItemTypeCheckSubTypeSet(scopeName, rule, _itemType, value)
        _itemType.CheckSubType = value;
        if not value then
            ResetItemTypeSubTypes(_itemType);
        end
        CheckIfItemTypeIsValid(scopeName, rule, _itemType);
    end

    local function DeleteItemType(scopeName, rule, _itemType)
        options.OptionsTable.args["AutoSell"].args[scopeName .. "Rules"].args[rule.Guid].args.ItemTypes.args[_itemType.Guid] = nil;
        addon.Util.TableRemoveByValue(rule.ItemTypes, _itemType);
        autoSell.CheckIfRuleIsValid(scopeName, rule);
    end

    local function ItemTypeSubTypeSet(scopeName, rule, _itemType, index, value)
        if value then
            _itemType.NumSelectedSubTypes = _itemType.NumSelectedSubTypes + 1;
        else
            _itemType.NumSelectedSubTypes = _itemType.NumSelectedSubTypes - 1;
        end
        _itemType.SubTypes[index] = value;
        CheckIfItemTypeIsValid(scopeName, rule, _itemType);
    end

    local function AddItemTypeTable(scopeName, rule, _itemType)
        KrowiV_InjectOptions:AddTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.ItemTypes.args", _itemType.Guid, {
            order = OrderPP(), type = "group", inline = true,
            name = "",
            args = {
                Type = {
                    order = OrderPP(), type = "select", width = AdjustedWidth(0.8),
                    name = "",
                    values = itemType.List,
                    get = function() return _itemType.Type; end,
                    set = function(_, value) ItemTypeTypeSet(scopeName, rule, _itemType, value, true); end,
                    disabled = function() return rule.IsPreset; end
                },
                CheckSubType = {
                    order = OrderPP(), type = "toggle", width = AdjustedWidth(0.8),
                    name = addon.L["Select sub type"],
                    desc = addon.L["Select sub type Desc"],
                    get = function() return _itemType.CheckSubType; end,
                    set = function(_, value) ItemTypeCheckSubTypeSet(scopeName, rule, _itemType, value); end,
                    disabled = function() return rule.IsPreset; end
                },
                DeleteItemType = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(0.4),
                    name = addon.L["Delete"],
                    desc = addon.L["Delete type Desc"],
                    func = function() DeleteItemType(scopeName, rule, _itemType); end,
                    hidden = function() return rule.IsPreset; end
                },
                InvalidItemType = {
                    order = OrderPP(), type = "description", width = "full",
                    name = addon.L["No item type selected"]:SetColorLightRed(),
                    fontSize = "medium",
                    hidden = function() return _itemType.Type ~= nil; end
                },
                SubTypes = {
                    order = OrderPP(), type = "multiselect", width = "full",
                    name = "",
                    values = function() return itemType.SubTypeList[_itemType.Type] end,
                    get = function(_, index) return _itemType.SubTypes[index]; end,
                    set = function(_, index, value) ItemTypeSubTypeSet(scopeName, rule, _itemType, index, value); end,
                    control = "Dropdown",
                    hidden = function() return not _itemType.CheckSubType; end,
                    disabled = function() return rule.IsPreset; end
                },
                AtLeastOneItemSubTypeMustBeSelected = {
                    order = OrderPP(), type = "description", width = "full",
                    name = addon.L["At least one item sub type must be selected"]:SetColorLightRed(),
                    fontSize = "medium",
                    hidden = function() return not _itemType.CheckSubType or _itemType.NumSelectedSubTypes > 0; end
                },
            }
        });
        CheckIfItemTypeIsValid(scopeName, rule, _itemType);
        local addNewItemClassTable = KrowiV_InjectOptions:GetTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.ItemTypes.args.AddNewItemType");
        addNewItemClassTable.order = OrderPP();
    end
    autoSell.AddItemTypeTable = AddItemTypeTable;

    local function AddNewItemTypeFunc(scopeName, rule)
        local unique = time() + random(time());
        local _itemType = {
            Guid = "ItemType-" .. unique,
            SubTypes = {},
            NumSelectedSubTypes = 0
        };
        tinsert(rule.ItemTypes, _itemType);
        AddItemTypeTable(scopeName, rule, _itemType);
        return _itemType;
    end
    autoSell.AddNewItemTypeFunc = AddNewItemTypeFunc;
end

do -- [[ Condition ]]
    local function CheckIfConditionIsValid(scopeName, rule, condition)
        local isValid, desc = criteriaType.CheckIfValid(condition);
        condition.IsValid = isValid;
        local invalidConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args." .. condition.Guid .. ".args.InvalidCondition");
        invalidConditionTable.name = desc:SetColorLightRed();
        autoSell.CheckIfRuleIsValid(scopeName, rule);
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

    local function ConditionItemLevelValueSet(scopeName, rule, condition, value)
        if strtrim(value) == "" then
            condition.Value = 0;
        elseif tonumber(value) == nil then
            ShowAlert(addon.L["ItemLevel is not a valid item level."]:ReplaceVars(value));
        else
            condition.Value = tonumber(value);
        end
        CheckIfConditionIsValid(scopeName, rule, condition);
    end

    local function ConditionCriteriaTypeSet_ItemLevel(scopeName, rule, condition)
        KrowiV_InjectOptions:AddTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args." .. condition.Guid .. ".args", "Operator", {
            order = OrderPP(), type = "select", width = AdjustedWidth(0.5),
            name = "",
            values = equalityOperator.List,
            get = function() return condition.Operator; end,
            set = function(_, _value)
                condition.Operator = _value;
                CheckIfConditionIsValid(scopeName, rule, condition);
            end,
            disabled = function() return rule.IsPreset; end
        });
        KrowiV_InjectOptions:AddTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args." .. condition.Guid .. ".args", "Value", {
            order = OrderPP(), type = "input", width = AdjustedWidth(0.4),
            name = "",
            get = function() return tostring(condition.Value or ""); end,
            set = function(_, _value) ConditionItemLevelValueSet(scopeName, rule, condition, _value); end,
            disabled = function() return rule.IsPreset; end
        });
    end

    local function ConditionCriteriaTypeSet_Reset(scopeName, rule, condition, value)
        if value == criteriaType.Enum.Soulbound or value == criteriaType.Enum.Quality then
            condition.Operator = nil;
            condition.Value = nil;
        end
        if value == criteriaType.Enum.ItemLevel or value == criteriaType.Enum.Soulbound then
            condition.Qualities = nil;
            condition.NumSelectedQualities = nil;
        end
        options.OptionsTable.args["AutoSell"].args[scopeName .. "Rules"].args[rule.Guid].args.Conditions.args[condition.Guid].args.Operator = nil;
        options.OptionsTable.args["AutoSell"].args[scopeName .. "Rules"].args[rule.Guid].args.Conditions.args[condition.Guid].args.Value = nil;
        options.OptionsTable.args["AutoSell"].args[scopeName .. "Rules"].args[rule.Guid].args.Conditions.args[condition.Guid].args.Blank1 = nil;
    end

    local function ConditionCriteriaTypeSet_Soulbound(scopeName, rule, condition)
        KrowiV_InjectOptions:AddTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args." .. condition.Guid .. ".args", "Blank1", {
            order = OrderPP(), type = "description", width = AdjustedWidth(0.9), name = ""
        });
    end

    local function ConditionQualityValueSet(scopeName, rule, condition, index, value)
        if value then
            condition.NumSelectedQualities = condition.NumSelectedQualities + 1;
        else
            condition.NumSelectedQualities = condition.NumSelectedQualities - 1;
        end
        condition.Qualities[index] = value;
        CheckIfConditionIsValid(scopeName, rule, condition);
    end
    autoSell.ConditionQualityValueSet = ConditionQualityValueSet;

    local function ConditionCriteriaTypeSet_Quality(scopeName, rule, condition)
        condition.Qualities = condition.Qualities or {};
        condition.NumSelectedQualities = condition.NumSelectedQualities or 0;
        KrowiV_InjectOptions:AddTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args." .. condition.Guid .. ".args", "Value", {
            order = OrderPP(), type = "multiselect", width = AdjustedWidth(0.9),
            name = "",
            values = itemQuality.List,
            get = function(_, index) return condition.Qualities[index]; end,
            set = function(_, index, value) ConditionQualityValueSet(scopeName, rule, condition, index, value); end,
            control = "Dropdown",
            disabled = function() return rule.IsPreset; end
        });
    end

    local function ConditionCriteriaTypeSet(scopeName, rule, condition, value)
        condition.CriteriaType = value;
        ConditionCriteriaTypeSet_Reset(scopeName, rule, condition, value);

        if value == criteriaType.Enum.ItemLevel then
            ConditionCriteriaTypeSet_ItemLevel(scopeName, rule, condition);
        elseif value == criteriaType.Enum.Soulbound then
            ConditionCriteriaTypeSet_Soulbound(scopeName, rule, condition);
        elseif value == criteriaType.Enum.Quality then
            ConditionCriteriaTypeSet_Quality(scopeName, rule, condition);
        end
        local deleteConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args." .. condition.Guid .. ".args.DeleteCondition");
        deleteConditionTable.order = OrderPP();
        CheckIfConditionIsValid(scopeName, rule, condition);
        local invalidConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args." .. condition.Guid .. ".args.InvalidCondition");
        invalidConditionTable.order = OrderPP();
    end
    autoSell.ConditionCriteriaTypeSet = ConditionCriteriaTypeSet;

    local function DeleteCondition(scopeName, rule, condition)
        options.OptionsTable.args["AutoSell"].args[scopeName .. "Rules"].args[rule.Guid].args.Conditions.args[condition.Guid] = nil;
        addon.Util.TableRemoveByValue(rule.Conditions, condition);
        autoSell.CheckIfRuleIsValid(scopeName, rule);
    end

    local function AddConditionTable(scopeName, rule, condition)
        KrowiV_InjectOptions:AddTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args", condition.Guid, {
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
                    get = function() return condition.CriteriaType; end,
                    set = function(_, value) ConditionCriteriaTypeSet(scopeName, rule, condition, value); end,
                    disabled = function() return rule.IsPreset; end
                },
                DeleteCondition = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(0.4),
                    name = addon.L["Delete"],
                    desc = addon.L["Delete Condition Desc"],
                    func = function() DeleteCondition(scopeName, rule, condition); end,
                    hidden = function() return rule.IsPreset; end
                },
                InvalidCondition = {
                    order = OrderPP(), type = "description", width = "full",
                    name = addon.L["Invalid condition"]:SetColorLightRed(),
                    fontSize = "medium",
                    hidden = function() return condition.IsValid; end
                }
            }
        });
        ConditionCriteriaTypeSet(scopeName, rule, condition, condition.CriteriaType);
        local addNewConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args.AddNewCondition");
        addNewConditionTable.order = OrderPP();
    end
    autoSell.AddConditionTable = AddConditionTable;

    function AddNewConditionFunc(scopeName, rule)
        local unique = time() + random(time());
        local condition = {
            Guid = "Condition-" .. unique,
        };
        tinsert(rule.Conditions, condition);
        AddConditionTable(scopeName, rule, condition);
        return condition;
    end
    autoSell.AddNewConditionFunc = AddNewConditionFunc;
end

function autoSell.PostLoad()
    KrowiV_SavedData = KrowiV_SavedData or {};
    KrowiV_SavedData.Rules = KrowiV_SavedData.Rules or {};
    for _, _scope in next, scope do
        local rules = GetRules(_scope);
        local scopeName = addon.Objects.ScopeList[_scope];
        for _, rule in next, rules do
            autoSell.AddRuleTable(scopeName, rule);
            for _, _itemType in next, rule.ItemTypes do
                autoSell.AddItemTypeTable(scopeName, rule, _itemType);
            end
            for _, condition in next, rule.Conditions do
                autoSell.AddConditionTable(scopeName, rule, condition);
            end
        end
    end
end

local function AddJunkRule(_scope)
    local rule = autoSell.AddNewRuleFunc(_scope, "Rule-Preset" .. addon.L["Junk"], addon.L["Junk"] .. " (Preset)");
    rule.IsPreset = true;
    local scopeName = addon.Objects.ScopeList[_scope];
    local condition = autoSell.AddNewConditionFunc(scopeName, rule);
    autoSell.ConditionCriteriaTypeSet(scopeName, rule, condition, criteriaType.Enum.Quality);
    autoSell.ConditionQualityValueSet(scopeName, rule, condition, 0, true);
end

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
        PresetRules = {
            order = OrderPP(), type = "group",
            name = addon.L["Preset Rules"],
            args = {
                Description = {
                    order = OrderPP(), type = "description", width = "full",
                    name = addon.L["Preset Rules Desc"]
                },
                JunkRuleName = {
                    order = OrderPP(), type = "description", width = AdjustedWidth(1),
                    name = addon.L["Junk"]
                },
                JunkRuleAccount = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(1),
                    name = "Add to Account", desc = "",
                    func = function(_, value) AddJunkRule(scope.Account); end
                },
                JunkRuleCharacter = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(1),
                    name = "Add to Character", desc = "",
                    func = function(_, value) AddJunkRule(scope.Character); end
                }
            }
        },
        AccountRules = {
            order = OrderPP(), type = "group",
            name = addon.L["Account Rules"],
            args = {
                AddNewRule = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(),
                    name = addon.L["Add new rule"],
                    desc = addon.L["Add new rule Desc"],
                    func = function() autoSell.AddNewRuleFunc(scope.Account); end
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
                    name = addon.L["Open auto sell list"],
                    desc = addon.L["Open auto sell list Desc"],
                    func = function()
                        addon.GUI.ItemListFrame.AutoSellList:ShowStandalone();
                    end
                }
            }
        },
        CharacterRules = {
            order = OrderPP(), type = "group",
            name = addon.L["Character Rules"],
            args = {
                AddNewRule = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(),
                    name = addon.L["Add new rule"],
                    desc = addon.L["Add new rule Desc"],
                    func = function() autoSell.AddNewRuleFunc(scope.Character); end
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
                    name = addon.L["Open auto sell list"],
                    desc = addon.L["Open auto sell list Desc"],
                    func = function()
                        addon.GUI.ItemListFrame.AutoSellList:ShowStandalone();
                    end
                }
            }
        }
    }
};