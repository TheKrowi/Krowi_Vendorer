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
local autoSellRule = addon.Objects.AutoSellRule;

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
    local function CheckIfRuleIsValid(rule)
        autoSellRule.CheckIfRuleIsInvalid(rule);
        if KrowiV_AutoSellListFrame and KrowiV_AutoSellListFrame:IsShown() then
            KrowiV_AutoSellListFrame:Update();
        end
    end
    autoSell.CheckIfRuleIsValid = CheckIfRuleIsValid;

    local function DeleteRule(scopeName, rule)
        options.OptionsTable.args["AutoSell"].args[scopeName .. "Rules"].args[rule.Guid] = nil;
        local _scope = addon.Objects.Scope[scopeName];
        addon.Util.TableRemoveByValue(GetRules(_scope), rule);
        if KrowiV_AutoSellListFrame and KrowiV_AutoSellListFrame:IsShown() then
            KrowiV_AutoSellListFrame:Update();
        end
    end

    local function AddRuleTable(scopeName, rule)
        KrowiV_InjectOptions:AddTable("AutoSell.args." .. scopeName .. "Rules.args", rule.Guid, {
            order = OrderPP(), type = "group",
            name = function() return "|T13681" .. (not rule.IsDisabled and "4" or "3") .. ":0|t " .. rule.Name; end,
            args = {
                Name = {
                    order = OrderPP(), type = "input", width = AdjustedWidth(1.5),
                    name = addon.L["Name"],
                    get = function() return rule.Name; end,
                    set = function(_, value) rule.Name = value; end,
                    disabled = function() return rule.IsPreset; end
                },
                DeleteRule = {
                    order = OrderPP(), type = "execute", width = AdjustedWidth(0.5),
                    name = addon.L["Delete rule"],
                    desc = addon.L["Delete rule Desc"],
                    func = function() DeleteRule(scopeName, rule); end,
                    hidden = function() return rule.IsPreset; end
                },
                Enabled = {
                    order = OrderPP(), type = "toggle", width = AdjustedWidth(0.8),
                    name = addon.L["Enabled"],
                    desc = addon.L["Enabled Desc"],
                    get = function() return not rule.IsDisabled; end,
                    set = function(_, value)
                        rule.IsDisabled = not value and true or nil;
                        CheckIfRuleIsValid(rule);
                    end
                },
                InvalidRule = {
                    order = OrderPP(), type = "description", width = "full",
                    name = addon.L["Invalid Rule"]:SetColorLightRed(),
                    fontSize = "medium",
                    hidden = function() return not rule.IsInvalid; end
                },
                ItemTypeHeader = {
                    order = OrderPP(), type = "header",
                    name = addon.L["Item types and sub types"]
                },
                ItemTypes = {
                    order = OrderPP(), type = "group", inline = true,
                    name = "",
                    args = {
                        NoItemTypes = {
                            order = OrderPP(), type = "description", width = rule.IsPreset and "full" or AdjustedWidth(1.1),
                            name = addon.L["No item types"],
                            fontSize = "medium",
                            hidden = function() return rule.ItemTypes and #rule.ItemTypes > 0; end
                        },
                        ItemTypesAreReadOnly = {
                            order = OrderPP(), type = "description", width = rule.IsPreset and "full" or AdjustedWidth(1.1),
                            name = addon.L["Item Types are read only"],
                            fontSize = "medium",
                            hidden = function() return not(rule.ItemTypes and #rule.ItemTypes > 0) or not rule.IsPreset; end
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
                        NoConditions = {
                            order = OrderPP(), type = "description", width = rule.IsPreset and "full" or AdjustedWidth(1.1),
                            name = addon.L["No conditions"],
                            fontSize = "medium",
                            hidden = function() return rule.Conditions and #rule.Conditions > 0; end,
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
        autoSell.CheckIfRuleIsValid(rule);
    end
    autoSell.AddRuleTable = AddRuleTable;

    local function AddNewRuleFunc(_scope, guid, name)
        local rules = GetRules(_scope);
        local rule = autoSellRule.CreateNewRule(rules, guid, name);
        local scopeName = addon.Objects.ScopeList[_scope];
        AddRuleTable(scopeName, rule);
        return rule, true;
    end
    autoSell.AddNewRuleFunc = AddNewRuleFunc;
end

do -- [[ ItemType ]]
    local function CheckIfItemTypeIsValid(rule, _itemType)
        autoSellRule.CheckIfItemTypeIsInvalid(_itemType);
        autoSellRule.MakeQuickItemTypes(rule);
        autoSell.CheckIfRuleIsValid(rule);
    end

    local function ItemTypeTypeSet(rule, _itemType, value)
        autoSellRule.SetItemType(_itemType, value);
        _itemType.NumSelectedSubTypes = _itemType.SubTypes and 0 or nil;
        _itemType.SubTypes = _itemType.SubTypes and {} or nil;
        CheckIfItemTypeIsValid(rule, _itemType);
    end

    local function ItemTypeCheckSubTypeSet(rule, _itemType, value)
        _itemType.NumSelectedSubTypes = value and 0 or nil;
        _itemType.SubTypes = value and {} or nil;
        CheckIfItemTypeIsValid(rule, _itemType);
    end

    local function DeleteItemType(scopeName, rule, _itemType)
        options.OptionsTable.args["AutoSell"].args[scopeName .. "Rules"].args[rule.Guid].args.ItemTypes.args[_itemType.Guid] = nil;
        addon.Util.TableRemoveByValue(rule.ItemTypes, _itemType);
        autoSellRule.MakeQuickItemTypes(rule);
        autoSell.CheckIfRuleIsValid(rule);
    end

    local function AddItemTypeTable(scopeName, rule, _itemType)
        print(scopeName, rule, _itemType, "AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.ItemTypes.args")
        KrowiV_InjectOptions:AddTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.ItemTypes.args", _itemType.Guid, {
            order = OrderPP(), type = "group", inline = true,
            name = "",
            args = {
                Type = {
                    order = OrderPP(), type = "select", width = AdjustedWidth(0.8),
                    name = "",
                    values = itemType.List,
                    get = function() return _itemType.Type; end,
                    set = function(_, value)
                        if not rule.IsPreset then
                            ItemTypeTypeSet(rule, _itemType, value);
                        end
                    end,
                    -- disabled = function() return rule.IsPreset; end
                },
                CheckSubType = {
                    order = OrderPP(), type = "toggle", width = AdjustedWidth(0.8),
                    name = addon.L["Select sub type"],
                    desc = addon.L["Select sub type Desc"],
                    get = function() return _itemType.SubTypes; end,
                    set = function(_, value) ItemTypeCheckSubTypeSet(rule, _itemType, value); end,
                    hidden = function() return rule.IsPreset; end
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
                    set = function(_, index, value)
                        if not rule.IsPreset then
                            autoSellRule.SetSubItemType(_itemType, index, value);
                            CheckIfItemTypeIsValid(rule, _itemType);
                        end
                    end,
                    control = "Dropdown",
                    hidden = function() return not _itemType.SubTypes; end,
                    -- disabled = function() return rule.IsPreset; end
                },
                AtLeastOneItemSubTypeMustBeSelected = {
                    order = OrderPP(), type = "description", width = "full",
                    name = addon.L["At least one item sub type must be selected"]:SetColorLightRed(),
                    fontSize = "medium",
                    hidden = function() return not _itemType.SubTypes or (_itemType.NumSelectedSubTypes or 0) > 0; end
                },
            }
        });
        CheckIfItemTypeIsValid(rule, _itemType);
        local addNewItemClassTable = KrowiV_InjectOptions:GetTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.ItemTypes.args.AddNewItemType");
        addNewItemClassTable.order = OrderPP();
    end
    autoSell.AddItemTypeTable = AddItemTypeTable;

    local function AddNewItemTypeFunc(scopeName, rule)
        local _itemType = autoSellRule.AddNewItemType(rule);
        AddItemTypeTable(scopeName, rule, _itemType);
        return _itemType;
    end
    autoSell.AddNewItemTypeFunc = AddNewItemTypeFunc;
end

do -- [[ Condition ]]
    local function CheckIfConditionIsValid(scopeName, rule, condition)
        local description = autoSellRule.CheckIfConditionIsInalid(condition);
        local invalidConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args." .. condition.Guid .. ".args.InvalidCondition");
        invalidConditionTable.name = description:SetColorLightRed();
        autoSell.CheckIfRuleIsValid(rule);
    end

    local function ConditionCriteriaTypeSet_ItemLevel(scopeName, rule, condition)
        KrowiV_InjectOptions:AddTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args." .. condition.Guid .. ".args", "Operator", {
            order = OrderPP(), type = "select", width = AdjustedWidth(0.5),
            name = "",
            values = equalityOperator.List,
            get = function() return condition.Operator; end,
            set = function(_, value)
                condition.Operator = value;
                CheckIfConditionIsValid(scopeName, rule, condition);
            end,
            disabled = function() return rule.IsPreset; end
        });
        KrowiV_InjectOptions:AddTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args." .. condition.Guid .. ".args", "Value", {
            order = OrderPP(), type = "input", width = AdjustedWidth(0.4),
            name = "",
            get = function() return tostring(condition.Value or ""); end,
            set = function(_, value)
                autoSellRule.SetItemLevel(condition, value);
                CheckIfConditionIsValid(scopeName, rule, condition);
            end,
            disabled = function() return rule.IsPreset; end
        });
    end

    local function ConditionCriteriaTypeSet_Reset(scopeName, rule, condition)
        options.OptionsTable.args["AutoSell"].args[scopeName .. "Rules"].args[rule.Guid].args.Conditions.args[condition.Guid].args.Operator = nil;
        options.OptionsTable.args["AutoSell"].args[scopeName .. "Rules"].args[rule.Guid].args.Conditions.args[condition.Guid].args.Value = nil;
        options.OptionsTable.args["AutoSell"].args[scopeName .. "Rules"].args[rule.Guid].args.Conditions.args[condition.Guid].args.Blank1 = nil;
    end

    local function ConditionCriteriaTypeSet_Soulbound(scopeName, rule, condition)
        KrowiV_InjectOptions:AddTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args." .. condition.Guid .. ".args", "Blank1", {
            order = OrderPP(), type = "description", width = AdjustedWidth(0.9), name = ""
        });
    end

    local function ConditionCriteriaTypeSet_Quality(scopeName, rule, condition)
        condition.Qualities = condition.Qualities or {};
        condition.NumSelectedQualities = condition.NumSelectedQualities or 0;
        KrowiV_InjectOptions:AddTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args." .. condition.Guid .. ".args", "Value", {
            order = OrderPP(), type = "multiselect", width = AdjustedWidth(0.9),
            name = "",
            values = itemQuality.List,
            get = function(_, index) return condition.Qualities[index]; end,
            set = function(_, index, value)
                autoSellRule.SetQuality(condition, index, value)
                CheckIfConditionIsValid(scopeName, rule, condition);
            end,
            control = "Dropdown",
            disabled = function() return rule.IsPreset; end
        });
    end

    local function ConditionCriteriaTypeSet(scopeName, rule, condition, value)
        autoSellRule.SetCriteriaType(condition, value);
        ConditionCriteriaTypeSet_Reset(scopeName, rule, condition);

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
        autoSell.CheckIfRuleIsValid(rule);
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
                    hidden = function() return not condition.IsInvalid; end
                }
            }
        });
        ConditionCriteriaTypeSet(scopeName, rule, condition, condition.CriteriaType);
        local addNewConditionTable = KrowiV_InjectOptions:GetTable("AutoSell.args." .. scopeName .. "Rules.args." .. rule.Guid .. ".args.Conditions.args.AddNewCondition");
        addNewConditionTable.order = OrderPP();
    end
    autoSell.AddConditionTable = AddConditionTable;

    function AddNewConditionFunc(scopeName, rule)
        local condition = autoSellRule.AddNewCondition(rule);
        AddConditionTable(scopeName, rule, condition);
        return condition;
    end
    autoSell.AddNewConditionFunc = AddNewConditionFunc;
end

local function AddJunkRule(_scope)
    local rules = GetRules(_scope);
    local rule, isNew = autoSellRule.CreateNewRule(rules, "Rule-PresetJunk", addon.L["Junk"] .. " (Preset)");
    if not isNew then
        return;
    end
    rule.IsPreset = true;
    rule.IsDisabled = true;
    local condition = autoSellRule.AddNewCondition(rule, criteriaType.Enum.Quality);
    autoSellRule.SetQuality(condition, Enum.ItemQuality.Poor, true);
end

local function AddArtifactRelicRule(_scope)
    local rules = GetRules(_scope);
    local rule, isNew = autoSellRule.CreateNewRule(rules, "Rule-PresetArtifactRelic", addon.L["Artifact Relic"] .. " (Preset)");
    if not isNew then
        return;
    end
    rule.IsPreset = true;
    rule.IsDisabled = true;
    local _itemType = autoSellRule.AddNewItemType(rule, Enum.ItemClass.Gem);
    autoSellRule.SetSubItemType(_itemType, Enum.ItemGemSubclass.Artifactrelic, true);
end

local function AddUnusableEquipmentRule(_scope)
    -- Data taken from https://wowpedia.fandom.com/wiki/Proficiency
    local rules = GetRules(_scope);
    local rule, isNew = autoSellRule.CreateNewRule(rules, "Rule-UnusableEquipment", addon.L["Unusable Equipment"] .. " (Preset)");
    if isNew then
        rule.IsDisabled = true;
    end
    rule.IsPreset = true;
    rule.ItemTypes = nil;
    local itemClassMatrix = addon.Data.AutoSell.ItemClassMatrix[select(2, UnitClass("player"))];
    local _itemType = autoSellRule.AddNewItemType(rule, Enum.ItemClass.Armor);
    local armorMatrix = itemClassMatrix[Enum.ItemClass.Armor];
    for _, value in pairs(Enum.ItemArmorSubclass) do
        if not armorMatrix[value] then
            autoSellRule.SetSubItemType(_itemType, value, true);
        end
    end
    _itemType = autoSellRule.AddNewItemType(rule, Enum.ItemClass.Weapon);
    local weaponMatrix = itemClassMatrix[Enum.ItemClass.Weapon];
    for _, value in pairs(Enum.ItemWeaponSubclass) do
        if not weaponMatrix[value] and value ~= Enum.ItemWeaponSubclass.Fishingpole then
            autoSellRule.SetSubItemType(_itemType, value, true);
        end
    end
end

local function SortRules(a, b)
    if a.IsPreset == b.IsPreset then
        return a.Name < b.Name;
    elseif a.IsPreset then
        return true;
    else
        return false;
    end
end

function autoSell.PostLoad()
    KrowiV_SavedData = KrowiV_SavedData or {};
    KrowiV_SavedData.Rules = KrowiV_SavedData.Rules or {};
    for _, _scope in next, scope do
        AddJunkRule(_scope);
        AddArtifactRelicRule(_scope);
        AddUnusableEquipmentRule(_scope);
        local rules = GetRules(_scope);
        table.sort(rules, SortRules);
        local scopeName = addon.Objects.ScopeList[_scope];
        for _, rule in next, rules do
            autoSell.AddRuleTable(scopeName, rule);
            if rule.ItemTypes then
                for _, _itemType in next, rule.ItemTypes do
                    autoSell.AddItemTypeTable(scopeName, rule, _itemType);
                end
            end
            if rule.Conditions then
                for _, condition in next, rule.Conditions do
                    autoSell.AddConditionTable(scopeName, rule, condition);
                end
            end
        end

    end
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
                        KrowiV_AutoSellListFrame:ShowWithSettingsPanel();
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
                        KrowiV_AutoSellListFrame:ShowWithSettingsPanel();
                    end
                }
            }
        },
        -- PresetRules = {
        --     order = OrderPP(), type = "group",
        --     name = addon.L["Preset Rules"],
        --     args = {
        --         Description = {
        --             order = OrderPP(), type = "description", width = "full",
        --             name = addon.L["Preset Rules Desc"],
        --             fontSize = "medium"
        --         },
        --         JunkRuleName = {
        --             order = OrderPP(), type = "description", width = AdjustedWidth(1),
        --             name = addon.L["Junk"],
        --             fontSize = "medium"
        --         },
        --         JunkRuleAccount = {
        --             order = OrderPP(), type = "execute", width = AdjustedWidth(1),
        --             name = "Add to Account", desc = "",
        --             func = function(_, value) AddJunkRule(scope.Account); end
        --         },
        --         JunkRuleCharacter = {
        --             order = OrderPP(), type = "execute", width = AdjustedWidth(1),
        --             name = "Add to Character", desc = "",
        --             func = function(_, value) AddJunkRule(scope.Character); end
        --         },
        --         ArtifactRelicRuleName = {
        --             order = OrderPP(), type = "description", width = AdjustedWidth(1),
        --             name = addon.L["Artifact Relic"],
        --             fontSize = "medium"
        --         },
        --         ArtifactRelicRuleAccount = {
        --             order = OrderPP(), type = "execute", width = AdjustedWidth(1),
        --             name = "Add to Account", desc = "",
        --             func = function(_, value) AddArtifactRelicRule(scope.Account); end
        --         },
        --         ArtifactRelicRuleCharacter = {
        --             order = OrderPP(), type = "execute", width = AdjustedWidth(1),
        --             name = "Add to Character", desc = "",
        --             func = function(_, value) AddArtifactRelicRule(scope.Character); end
        --         }
        --     }
        -- }
    }
};