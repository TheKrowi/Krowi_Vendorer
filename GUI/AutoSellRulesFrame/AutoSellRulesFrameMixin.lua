-- [[ Namespaces ]] --
local _, addon = ...;
local rulesFrame, rulesList, ruleFrame;
local selectedRule;

KrowiV_AutoSellRulesElementMixin = CreateFromMixins(DefaultTooltipMixin);

function KrowiV_AutoSellRulesElementMixin:OnLoad()
    DefaultTooltipMixin.OnLoad(self);
	self.tooltipXOffset = 0;
end

function KrowiV_AutoSellRulesElementMixin:Init(element)
    self.Text:SetText(element.Text .. " - " .. element.Level);
    DefaultTooltipMixin.SetTooltipFunc(self.Tooltip, function()
        SettingsTooltip:AddLine(addon.L["Enabled"], 1, 1, 1);
        SettingsTooltip:AddLine(addon.L["Enabled Desc"], nil, nil, nil, true);
    end);
end

KrowiV_AutoSellRulesFrameMixin = {};

function KrowiV_AutoSellRulesFrameMixin:OnLoad()
    self:SetTitle(addon.L["Auto Sell Rules"]);
    self:SetIcon("Interface/Icons/Inv_Misc_Punchcards_Red");
    self:SetListInfo(addon.L["Auto Sell Rules Info"]);

    rulesFrame = self;
    rulesList = self.RulesList;
    ruleFrame = self.RuleFrame;
    self.SelectedTab = 1;

    -- addon.Util.DelayFunction("KrowiV_AutoSellRulesFrameMixin", 1, self.Show, self); -- For testing
end

function KrowiV_AutoSellRulesFrameMixin:OnShow()
    rulesList:Update();
end

function KrowiV_AutoSellRulesFrameMixin:SetIcon(icon)
    ButtonFrameTemplate_ShowPortrait(self);
    SetPortraitToTexture(self.PortraitContainer.portrait, icon);
end

function KrowiV_AutoSellRulesFrameMixin:SetListInfo(text)
    self.ItemListInfo:SetText(text);
end

local scope = addon.Objects.Scope;
function KrowiV_AutoSellRulesFrameMixin.GetScope(tabIndex)
    if tabIndex == 1 then
        return scope.Account;
    elseif tabIndex == 2 then
        return scope.Character;
    else
        return;
    end
end

function KrowiV_AutoSellRulesFrameMixin.GetRules(_scope)
    if _scope == scope.Character then
        local character = addon.GetCurrentCharacter();
        return character.Rules;
    end
    return KrowiV_SavedData.Rules;
end

KrowiV_AddNewRuleButtonMixin = {};

function KrowiV_AddNewRuleButtonMixin:OnLoad()
    self:SetText(addon.L["Add new rule"]);
    self.tooltipText = addon.L["Add new rule Desc"];
end

local autoSellRule = addon.Objects.AutoSellRule;
function KrowiV_AddNewRuleButtonMixin:OnClick()
    local _scope = rulesFrame.GetScope(rulesFrame.SelectedTab);
    local rules = rulesFrame.GetRules(_scope);
    local rule = autoSellRule.CreateNewRule(rules);
    rulesFrame:Update();
    rulesList.SelectionBehavior:ClearSelections();
    rulesList.SelectionBehavior:SelectElementData(rule);
    if KrowiV_AutoSellListFrame and KrowiV_AutoSellListFrame:IsShown() then
        KrowiV_AutoSellListFrame:Update();
    end
end

KrowiV_DeleteRuleButtonMixin = {};

function KrowiV_DeleteRuleButtonMixin:OnLoad()
    self:SetText(addon.L["Delete selected rule"]);
    self.tooltipText = addon.L["Delete selected rule Desc"];
end

function KrowiV_DeleteRuleButtonMixin:OnClick()
    local selectedIndex = rulesList.ScrollBox:FindIndex(selectedRule);
    local newSelectedRule = rulesList.ScrollBox:Find(selectedIndex + 1) or rulesList.ScrollBox:Find(selectedIndex - 1);
    local _scope = rulesFrame.GetScope(rulesFrame.SelectedTab);
    local rules = rulesFrame.GetRules(_scope);
    autoSellRule.DeleteRule(rules, selectedRule);
    rulesFrame:Update();
    rulesList.SelectionBehavior:ClearSelections();
    rulesList.SelectionBehavior:SelectElementData(newSelectedRule);
    if KrowiV_AutoSellListFrame and KrowiV_AutoSellListFrame:IsShown() then
        KrowiV_AutoSellListFrame:Update();
    end
end




















KrowiV_RulesFrameIsEnabledMixin = CreateFromMixins(CallbackRegistryMixin);
KrowiV_RulesFrameIsEnabledMixin:GenerateCallbackEvents(
    {
        "OnValueChanged",
    }
);

function KrowiV_RulesFrameIsEnabledMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self);
    self:GetParent().IsEnabledLabel:SetText(addon.L["Enabled"]);
end

function KrowiV_RulesFrameIsEnabledMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:AddLine(addon.L["Enabled"], 1, 1, 1);
    GameTooltip:AddLine(addon.L["Enabled Desc"], nil, nil, nil, true);
    GameTooltip:Show();
end

function KrowiV_RulesFrameIsEnabledMixin:OnLeave()
    GameTooltip:Hide();
end

function KrowiV_RulesFrameIsEnabledMixin:OnClick()
    selectedRule.IsDisabled = not self:GetChecked();
    self:TriggerEvent(self.Event.OnValueChanged, self:GetChecked());
end

KrowiV_AddMoreButton = {};

function KrowiV_AddMoreButton:OnClick()

end