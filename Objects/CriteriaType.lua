-- [[ Namespaces ]] --
local _, addon = ...;
local objects = addon.Objects;
objects.CriteriaType = {};
local criteriaType = objects.CriteriaType;
local equalityOperator = addon.Objects.EqualityOperator;

criteriaType.List = {
    addon.L["Item level"],
    addon.L["Soulbound"]
};

criteriaType.Enum = addon.Util.Enum2{
    "ItemLevel",
    "Soulbound"
};

do --[[ Rule evaluation functions ]]
    local function ItemLevel_Func(itemLevel, operator, value)
        local result = equalityOperator.Func[operator](itemLevel, value);
        return result, "Item is " .. equalityOperator.List[operator] .. " " .. value;
    end

    local function Soulbound_Func(bindType)
        local result = bindType == LE_ITEM_BIND_ON_ACQUIRE;
        return result, "Item is soulbound";
    end

    function criteriaType.Func(condition, itemInfo)
        if condition.CriteriaType == criteriaType.Enum.ItemLevel then -- Item level
            return ItemLevel_Func(itemInfo.ItemLevel, condition.Operator, condition.Value);
        elseif condition.CriteriaType == criteriaType.Enum.Soulbound then -- Soulbound
            return Soulbound_Func(itemInfo.BindType);
        end
    end
end

do --[[ Rule validity checking ]]
    local function ItemLevel_IsValid(condition)
        if not condition.Operator then
            return false, addon.L["No equality operator selected"];
        end
        if not equalityOperator.List[condition.Operator] then
            return false, addon.L["No valid equality operator selected"];
        end
        if not condition.Value then
            return false, addon.L["No item level value entered"];
        end
        return true, "";
    end

    function criteriaType.CheckIfValid(condition)
        local desc = addon.L["Invalid condition"] .. " - ";
        if not condition.CriteriaType then
            return false, desc .. addon.L["No criteria type selected"];
        end
        if not criteriaType.List[condition.CriteriaType] then
            return false, desc .. addon.L["No valid criteria type selected"];
        end
        if condition.CriteriaType == criteriaType.Enum.ItemLevel then -- Item level
            local isValid, text = ItemLevel_IsValid(condition)
            return isValid, desc .. text;
        elseif condition.CriteriaType == criteriaType.Enum.Soulbound then -- Soulbound
            return true, "";
        end
        return true, "";
    end
end