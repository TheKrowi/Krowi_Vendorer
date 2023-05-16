-- [[ Namespaces ]] --
local _, addon = ...;
addon.Data.AutoSell = {};
local autoSell = addon.Data.AutoSell;
local criteriaType = addon.Objects.CriteriaType;
local itemType = addon.Objects.ItemType;

function autoSell.CheckRule(rule, itemInfo)
    if rule.IsDisabled or rule.IsInvalid then
        return false;
    end

    -- If there are item types, either the type must match or when defined, also the sub type must match
    if rule.QuickItemTypes then
        local _itemType = rule.QuickItemTypes[itemInfo.ItemTypeId];
        if not _itemType then
            return false;
        end

        if type(_itemType) == "table" and not _itemType[itemInfo.ItemSubTypeId] then
            return false;
        end
    end

    -- If there are conditions, all conditions must match
    if rule.Conditions then
        for _, condition in next, rule.Conditions do
            local result = criteriaType.Func(condition, itemInfo);
            if not result then
                return false;
            end
        end
    end

    return true;
end

function autoSell.CheckRules(itemInfo)
    for _, rule in next, KrowiV_SavedData.Rules do
        if autoSell.CheckRule(rule, itemInfo) then
            return true;
        end
    end
    local character = addon.GetCurrentCharacter();
    for _, rule in next, character.Rules do
        if autoSell.CheckRule(rule, itemInfo) then
            return true;
        end
    end
end

function autoSell.CheckRuleWithFeedback(rule, itemInfo)
    if rule.IsDisabled or rule.IsInvalid then
        return nil; -- Do not add feedback about this
    end

    local doSell, feedback = true, {};

    -- If there are item types, either the type must match or when defined, also the sub type must match
    if rule.QuickItemTypes then
        local _itemType = rule.QuickItemTypes[itemInfo.ItemTypeId];
        if not _itemType then
            doSell = false;
            tinsert(feedback, {false, "Type is " .. (itemType.List[itemInfo.ItemTypeId] or itemInfo.ItemTypeId)});
        else
            tinsert(feedback, {true, "Type is " .. (itemType.List[itemInfo.ItemTypeId] or itemInfo.ItemTypeId)});

            if type(_itemType) == "table" and not _itemType[itemInfo.ItemSubTypeId] then
                doSell = false;
                tinsert(feedback, {false, "Sub-type is " .. itemType.SubTypeList[itemInfo.ItemTypeId][itemInfo.ItemSubTypeId]});
            else
                tinsert(feedback, {true, "Sub-type is " .. itemType.SubTypeList[itemInfo.ItemTypeId][itemInfo.ItemSubTypeId]});
            end
        end
    end

    -- If there are conditions, all conditions must match
    if rule.Conditions then
        for _, condition in next, rule.Conditions do
            local result, text = criteriaType.Func(condition, itemInfo);
            if not result then
                doSell = false;
                tinsert(feedback, {false, text});
            else
                tinsert(feedback, {true, text});
            end
        end
    end

    return doSell, feedback;
end

function autoSell.CheckRulesWithFeedback(itemInfo)
    local feedback, doSell = {}, false;
    for _, rule in next, KrowiV_SavedData.Rules do
        local d, f = autoSell.CheckRuleWithFeedback(rule, itemInfo);
        doSell = doSell or d;
        if f ~= nil then
            tinsert(feedback, {rule.Name, d, f});
        end
    end
    local character = addon.GetCurrentCharacter();
    for _, rule in next, character.Rules do
        local d, f = autoSell.CheckRuleWithFeedback(rule, itemInfo);
        doSell = doSell or d;
        if f ~= nil then
            tinsert(feedback, {rule.Name, d, f});
        end
    end
    return doSell, feedback;
end

autoSell.ItemClassMatrix = {
    ["DEATHKNIGHT"] = {
        [Enum.ItemClass.Armor] = {
            [Enum.ItemArmorSubclass.Plate] = true
        },
        [Enum.ItemClass.Weapon] = {
            [Enum.ItemWeaponSubclass.Axe1H] = true,
            [Enum.ItemWeaponSubclass.Axe2H] = true,
            [Enum.ItemWeaponSubclass.Mace1H] = true,
            [Enum.ItemWeaponSubclass.Mace2H] = true,
            [Enum.ItemWeaponSubclass.Polearm] = true,
            [Enum.ItemWeaponSubclass.Sword1H] = true,
            [Enum.ItemWeaponSubclass.Sword2H] = true
        }
    },
    ["DEMONHUNTER"] = {
        [Enum.ItemClass.Armor] = {
            [Enum.ItemArmorSubclass.Leather] = true
        },
        [Enum.ItemClass.Weapon] = {
            [Enum.ItemWeaponSubclass.Axe1H] = true,
            [Enum.ItemWeaponSubclass.Sword1H] = true,
            [Enum.ItemWeaponSubclass.Warglaive] = true,
            [Enum.ItemWeaponSubclass.Unarmed] = true
        }
    },
    ["DRUID"] = {
        [Enum.ItemClass.Armor] = {
            [Enum.ItemArmorSubclass.Leather] = true
        },
        [Enum.ItemClass.Weapon] = {
            [Enum.ItemWeaponSubclass.Mace1H] = true,
            [Enum.ItemWeaponSubclass.Mace2H] = true,
            [Enum.ItemWeaponSubclass.Polearm] = true,
            [Enum.ItemWeaponSubclass.Staff] = true,
            [Enum.ItemWeaponSubclass.Bearclaw] = true,
            [Enum.ItemWeaponSubclass.Catclaw] = true,
            [Enum.ItemWeaponSubclass.Unarmed] = true,
            [Enum.ItemWeaponSubclass.Dagger] = true
        }
    },
    ["EVOKER"] = {
        [Enum.ItemClass.Armor] = {
            [Enum.ItemArmorSubclass.Mail] = true
        },
        [Enum.ItemClass.Weapon] = {
            [Enum.ItemWeaponSubclass.Axe1H] = true,
            [Enum.ItemWeaponSubclass.Axe2H] = true,
            [Enum.ItemWeaponSubclass.Mace1H] = true,
            [Enum.ItemWeaponSubclass.Mace2H] = true,
            [Enum.ItemWeaponSubclass.Sword1H] = true,
            [Enum.ItemWeaponSubclass.Sword2H] = true,
            [Enum.ItemWeaponSubclass.Staff] = true,
            [Enum.ItemWeaponSubclass.Unarmed] = true,
            [Enum.ItemWeaponSubclass.Dagger] = true
        }
    },
    ["HUNTER"] = {
        [Enum.ItemClass.Armor] = {
            [Enum.ItemArmorSubclass.Mail] = true
        },
        [Enum.ItemClass.Weapon] = {
            [Enum.ItemWeaponSubclass.Axe1H] = true,
            [Enum.ItemWeaponSubclass.Axe2H] = true,
            [Enum.ItemWeaponSubclass.Bows] = true,
            [Enum.ItemWeaponSubclass.Guns] = true,
            [Enum.ItemWeaponSubclass.Polearm] = true,
            [Enum.ItemWeaponSubclass.Sword1H] = true,
            [Enum.ItemWeaponSubclass.Sword2H] = true,
            [Enum.ItemWeaponSubclass.Staff] = true,
            [Enum.ItemWeaponSubclass.Unarmed] = true,
            [Enum.ItemWeaponSubclass.Dagger] = true,
            [Enum.ItemWeaponSubclass.Crossbow] = true
        }
    },
    ["MAGE"] = {
        [Enum.ItemClass.Armor] = {
            [Enum.ItemArmorSubclass.Cloth] = true
        },
        [Enum.ItemClass.Weapon] = {
            [Enum.ItemWeaponSubclass.Sword1H] = true,
            [Enum.ItemWeaponSubclass.Staff] = true,
            [Enum.ItemWeaponSubclass.Dagger] = true,
            [Enum.ItemWeaponSubclass.Wand] = true
        }
    },
    ["MONK"] = {
        [Enum.ItemClass.Armor] = {
            [Enum.ItemArmorSubclass.Leather] = true
        },
        [Enum.ItemClass.Weapon] = {
            [Enum.ItemWeaponSubclass.Axe1H] = true,
            [Enum.ItemWeaponSubclass.Mace1H] = true,
            [Enum.ItemWeaponSubclass.Polearm] = true,
            [Enum.ItemWeaponSubclass.Sword1H] = true,
            [Enum.ItemWeaponSubclass.Staff] = true,
            [Enum.ItemWeaponSubclass.Unarmed] = true
        }
    },
    ["PALADIN"] = {
        [Enum.ItemClass.Armor] = {
            [Enum.ItemArmorSubclass.Plate] = true,
            [Enum.ItemArmorSubclass.Shield] = true
        },
        [Enum.ItemClass.Weapon] = {
            [Enum.ItemWeaponSubclass.Axe1H] = true,
            [Enum.ItemWeaponSubclass.Axe2H] = true,
            [Enum.ItemWeaponSubclass.Mace1H] = true,
            [Enum.ItemWeaponSubclass.Mace2H] = true,
            [Enum.ItemWeaponSubclass.Polearm] = true,
            [Enum.ItemWeaponSubclass.Sword1H] = true,
            [Enum.ItemWeaponSubclass.Sword2H] = true
        }
    },
    ["PRIEST"] = {
        [Enum.ItemClass.Armor] = {
            [Enum.ItemArmorSubclass.Cloth] = true
        },
        [Enum.ItemClass.Weapon] = {
            [Enum.ItemWeaponSubclass.Mace1H] = true,
            [Enum.ItemWeaponSubclass.Staff] = true,
            [Enum.ItemWeaponSubclass.Dagger] = true,
            [Enum.ItemWeaponSubclass.Wand] = true
        }
    },
    ["ROGUE"] = {
        [Enum.ItemClass.Armor] = {
            [Enum.ItemArmorSubclass.Leather] = true
        },
        [Enum.ItemClass.Weapon] = {
            [Enum.ItemWeaponSubclass.Axe1H] = true,
            [Enum.ItemWeaponSubclass.Mace1H] = true,
            [Enum.ItemWeaponSubclass.Sword1H] = true,
            [Enum.ItemWeaponSubclass.Unarmed] = true,
            [Enum.ItemWeaponSubclass.Dagger] = true
        }
    },
    ["SHAMAN"] = {
        [Enum.ItemClass.Armor] = {
            [Enum.ItemArmorSubclass.Mail] = true,
            [Enum.ItemArmorSubclass.Shield] = true
        },
        [Enum.ItemClass.Weapon] = {
            [Enum.ItemWeaponSubclass.Axe1H] = true,
            [Enum.ItemWeaponSubclass.Axe2H] = true,
            [Enum.ItemWeaponSubclass.Mace1H] = true,
            [Enum.ItemWeaponSubclass.Mace2H] = true,
            [Enum.ItemWeaponSubclass.Staff] = true,
            [Enum.ItemWeaponSubclass.Unarmed] = true,
            [Enum.ItemWeaponSubclass.Dagger] = true
        }
    },
    ["WARLOCK"] = {
        [Enum.ItemClass.Armor] = {
            [Enum.ItemArmorSubclass.Cloth] = true
        },
        [Enum.ItemClass.Weapon] = {
            [Enum.ItemWeaponSubclass.Sword1H] = true,
            [Enum.ItemWeaponSubclass.Staff] = true,
            [Enum.ItemWeaponSubclass.Dagger] = true,
            [Enum.ItemWeaponSubclass.Wand] = true
        }
    },
    ["WARRIOR"] = {
        [Enum.ItemClass.Armor] = {
            [Enum.ItemArmorSubclass.Plate] = true,
            [Enum.ItemArmorSubclass.Shield] = true
        },
        [Enum.ItemClass.Weapon] = {
            [Enum.ItemWeaponSubclass.Axe1H] = true,
            [Enum.ItemWeaponSubclass.Axe2H] = true,
            [Enum.ItemWeaponSubclass.Mace1H] = true,
            [Enum.ItemWeaponSubclass.Mace2H] = true,
            [Enum.ItemWeaponSubclass.Polearm] = true,
            [Enum.ItemWeaponSubclass.Sword1H] = true,
            [Enum.ItemWeaponSubclass.Sword2H] = true,
            [Enum.ItemWeaponSubclass.Staff] = true,
            [Enum.ItemWeaponSubclass.Unarmed] = true,
            [Enum.ItemWeaponSubclass.Dagger] = true
        }
    }
};