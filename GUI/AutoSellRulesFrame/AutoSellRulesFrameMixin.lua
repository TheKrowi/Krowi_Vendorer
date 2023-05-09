-- [[ Namespaces ]] --
local _, addon = ...;

KrowiV_AutoSellRulesFrameMixin = {};

local function CreateScrollView(self)
    self.ScrollView = CreateScrollBoxListLinearView();
    self.ScrollView:SetElementInitializer("KrowiV_AutoSellRulesButton_Template", function(frame, elementData)
        frame:Init(elementData);
    end);
    local elementExtent = 30; -- Better performance if hardcoded, must be same height as template
    self.ScrollView:SetElementExtent(elementExtent);
    self.ScrollView:SetPadding(0, 0, 0, 0, 1);
    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, self.ScrollView);
end

local function AddManagedScrollBarVisibilityBehavior(self)
	local anchorsWithBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self.ScrollBar, "BOTTOMLEFT", 0, 4),
    };

    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4),
    };

    ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.ScrollBox, self.ScrollBar, anchorsWithBar, anchorsWithoutBar);
end

local selectedRule;
local function ScrollBoxSelectionChanged(self, rule, selected)
    -- print(selected, rule.Name, selectedRule and selectedRule.Name)
    selectedRule = selected and rule or nil;

    local button = self.ScrollBox:FindFrame(rule);
	if not button then
		return;
	end

    if rule == selectedRule then
        button:LockHighlight();
	end

    if not selectedRule then
        button:UnlockHighlight();
        return;
    end

    self:GetParent():SetSelectedRule(rule);
end

local function AddSelectionBehavior(self)
	self.SelectionBehavior = ScrollUtil.AddSelectionBehavior(self.ScrollBox, SelectionBehaviorFlags.Intrusive);
	self.SelectionBehavior:RegisterCallback(SelectionBehaviorMixin.Event.OnSelectionChanged, ScrollBoxSelectionChanged, self);
end

function KrowiV_AutoSellRulesFrameMixin:OnLoad()
    self:SetTitle(addon.L["Auto Sell Rules"]);
    self:SetIcon("Interface/Icons/Inv_Misc_Punchcards_Red");
    self:SetListInfo(addon.L["Auto Sell Rules Info"]);

    CreateScrollView(self.RulesList);
    AddManagedScrollBarVisibilityBehavior(self.RulesList);
    AddSelectionBehavior(self.RulesList);

    addon.Util.DelayFunction("KrowiV_AutoSellRulesFrameMixin", 1, self.Show, self); -- For testing
end

function KrowiV_AutoSellRulesFrameMixin:OnShow()
    self:Update();
end

function KrowiV_AutoSellRulesFrameMixin:SetIcon(icon)
    ButtonFrameTemplate_ShowPortrait(self);
    SetPortraitToTexture(self.PortraitContainer.portrait, icon);
end

function KrowiV_AutoSellRulesFrameMixin:SetListInfo(text)
    self.ItemListInfo:SetText(text);
end

local scope = addon.Objects.Scope;
local function GetScope(tabIndex)
    if tabIndex == 1 then
        return scope.Account;
    elseif tabIndex == 2 then
        return scope.Character;
    else
        return;
    end
end

local function GetRules(_scope)
    if _scope == scope.Character then
        local character = addon.GetCurrentCharacter();
        return character.Rules;
    end
    return KrowiV_SavedData.Rules;
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

local selectedTab = 1;
local function UpdateDataProvider(self, retainScrollPosition)
    local _scope = GetScope(selectedTab);
    local rules = GetRules(_scope);
    table.sort(rules, SortRules);
    -- local scopeName = addon.Objects.ScopeList[_scope];

	local newDataProvider = CreateDataProvider();
    newDataProvider:SetSortComparator(SortRules, true);
    for _, rule in next, rules do
        newDataProvider:Insert(rule);
    end
    newDataProvider:Sort();
	self.ScrollBox:SetDataProvider(newDataProvider, retainScrollPosition);
end

function KrowiV_AutoSellRulesFrameMixin:Update(retainScrollPosition)
	if selectedTab == nil then
		return;
	end

	UpdateDataProvider(self.RulesList, retainScrollPosition);

    if selectedRule == nil then
        self.RulesList.SelectionBehavior:ClearSelections();
        self.RulesList.SelectionBehavior:SelectFirstElementData();
    end
end

function KrowiV_AutoSellRulesFrameMixin:SetSelectedRule(rule)
    self.RuleFrame.Name:SetText(rule.Name);
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
    self:GetParent():Update();
    self:GetParent().RulesList.SelectionBehavior:ClearSelections();
    self:GetParent().RulesList.SelectionBehavior:SelectElementData(rule);
    if KrowiV_AutoSellListFrame and KrowiV_AutoSellListFrame:IsShown() then
        KrowiV_AutoSellListFrame:Update();
    end
end

KrowiV_DeleteRuleButtonMixin = {};

function KrowiV_DeleteRuleButtonMixin:OnLoad()
    self:SetText(addon.L["Delete rule"]);
    self.tooltipText = addon.L["Delete rule Desc"];
end

function KrowiV_DeleteRuleButtonMixin:OnClick()
    local selectedIndex = self:GetParent().RulesList.ScrollBox:FindIndex(selectedRule);
    local newSelectedRule = self:GetParent().RulesList.ScrollBox:Find(selectedIndex + 1) or self:GetParent().RulesList.ScrollBox:Find(selectedIndex - 1);
    local _scope = GetScope(selectedTab);
    local rules = GetRules(_scope);
    autoSellRule.DeleteRule(rules, selectedRule);
    self:GetParent():Update();
    self:GetParent().RulesList.SelectionBehavior:ClearSelections();
    self:GetParent().RulesList.SelectionBehavior:SelectElementData(newSelectedRule);
    if KrowiV_AutoSellListFrame and KrowiV_AutoSellListFrame:IsShown() then
        KrowiV_AutoSellListFrame:Update();
    end
end

KrowiV_AutoSellRulesButtonMixin = {};

function KrowiV_AutoSellRulesButtonMixin:Init(rule)
    self.Rule = rule;
    self.Name:SetText("|T13681" .. (rule.IsDisabled and "3" or "4") .. ":0|t " .. rule.Name);

     -- We need this here to properly select new rules
    if rule == selectedRule then
		self:LockHighlight();
        return;
	end
	self:UnlockHighlight();
end

function KrowiV_AutoSellRulesButtonMixin:OnEnter()
    -- print("enter")
end

function KrowiV_AutoSellRulesButtonMixin:OnLeave()
    -- print("leave")
end

function KrowiV_AutoSellRulesButtonMixin:OnClick()
    self:GetParent():GetParent():GetParent().SelectionBehavior:ToggleSelect(self);
end

KrowiV_RulesFrameNameMixin = {};

function KrowiV_RulesFrameNameMixin:OnLoad()
	self:SetTextInsets(0, 0, 3, 3);
end

function KrowiV_RulesFrameNameMixin:OnEscapePressed()
    self:ClearFocus();
end

function KrowiV_RulesFrameNameMixin:OnEnterPressed()
    self:ClearFocus();
end

function KrowiV_RulesFrameNameMixin:OnTextChanged()
    if not self:HasFocus() then
        return;
    end
    local value = self:GetText();
    if tostring(value) ~= tostring(self.PrevText) then
		self.PrevText = value;
        self:SetTextInsets(0, 40, 3, 3);
		self.CommitChange:Show();
	end
end

function KrowiV_RulesFrameNameMixin:OnEditFocusGained()
    self:HighlightText(0, 0);
end

KrowiV_RulesFrameNameCommitChangeMixin = {};

function KrowiV_RulesFrameNameCommitChangeMixin:OnClick()
    self:GetParent():OnEnterPressed();
    self:GetParent():SetTextInsets(0, 0, 3, 3);
    self:Hide();
end