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

    addon.Util.DelayFunction("KrowiV_AutoSellRulesFrameMixin", 1, self.Show, self); -- For testing
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

KrowiV_AddNewRuleButtonMixin = {};

function KrowiV_AddNewRuleButtonMixin:OnLoad()
    self:SetText(addon.L["Add new rule"]);
    self.tooltipText = addon.L["Add new rule Desc"];
end

local autoSellRule = addon.Objects.AutoSellRule;
function KrowiV_AddNewRuleButtonMixin:OnClick()
    local _scope = GetScope(selectedTab);
    local rules = GetRules(_scope);
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
    local _scope = GetScope(selectedTab);
    local rules = GetRules(_scope);
    autoSellRule.DeleteRule(rules, selectedRule);
    rulesFrame:Update();
    rulesList.SelectionBehavior:ClearSelections();
    rulesList.SelectionBehavior:SelectElementData(newSelectedRule);
    if KrowiV_AutoSellListFrame and KrowiV_AutoSellListFrame:IsShown() then
        KrowiV_AutoSellListFrame:Update();
    end
end

KrowiV_AddTestButtonMixin = {};

local items = {};

function KrowiV_AddTestButtonMixin:OnClick()
    -- tinsert(items, {
    --     Extend = random(10, 50),
    --     Text = "Text" .. tostring(random(10, 50)),
    --     Level = random(1, 3)
    -- });
    KrowiV_Test4 = KrowiV_Test4 or {};
    tinsert(items, CreateSettingsListSectionHeaderInitializer(addon.L["General"]))
    tinsert(items, Settings.CreateCheckBoxInitializer(CreateAndInitFromMixin(ProxySettingMixin, addon.L["Enabled"], "variable", KrowiV_Test4, Settings.VarType.Boolean, false, nil, nil, nil), function()
        local container = Settings.CreateControlTextContainer();
        container:Add(0, VIDEO_OPTIONS_DISABLED);
        container:Add(1, VIDEO_OPTIONS_ENABLED);
        return container:GetData();
    end, addon.L["Enabled Desc"]))
	local newDataProvider = CreateDataProvider();
    -- newDataProvider:SetSortComparator(SortRules, true);
    for _, rule in next, items do
        newDataProvider:Insert(rule);
    end
    -- newDataProvider:Sort();
	self:GetParent().RuleFrame.ScrollBox:SetDataProvider(newDataProvider, true);
end

KrowiV_RulesFrameNameMixin = CreateFromMixins(CallbackRegistryMixin);
KrowiV_RulesFrameNameMixin:GenerateCallbackEvents(
    {
        "OnValueChanged",
    }
);

function KrowiV_RulesFrameNameMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self);
    self:SetTextInsets(6, 0, 3, 3);
    self:GetParent().NameLabel:SetText(addon.L["Name"]);
end

function KrowiV_RulesFrameNameMixin:OnEscapePressed()
    self:SetTextInsets(6, 0, 3, 3);
    self:ClearFocus();
end

function KrowiV_RulesFrameNameMixin:OnEnterPressed()
    selectedRule.Name = self:GetText();
    self:TriggerEvent(self.Event.OnValueChanged, self:GetText());
    self:SetTextInsets(6, 0, 3, 3);
    self:ClearFocus();
    self.CommitChange:Hide();
end

function KrowiV_RulesFrameNameMixin:OnTextChanged()
    if not self:HasFocus() then
        return;
    end
    local value = self:GetText();
    if tostring(value) ~= tostring(self.PrevText) then
        self.PrevText = value;
        self:SetTextInsets(6, 40, 3, 3);
        self.CommitChange:Show();
    end
end

function KrowiV_RulesFrameNameMixin:OnEditFocusGained()
    self:HighlightText(0, 0);
end

KrowiV_RulesFrameNameCommitChangeMixin = {};

function KrowiV_RulesFrameNameCommitChangeMixin:OnClick()
    self:GetParent():OnEnterPressed();
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