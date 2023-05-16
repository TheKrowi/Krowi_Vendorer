-- [[ Namespaces ]] --
local _, addon = ...;
addon.GUI.AutoSellRulesFrame = {};
local rulesFrame, rulesList;

KrowiV_AutoSellRulesListMixin = {};

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

local function ScrollBoxSelectionChanged(self, rule, selected)
    -- print(selected, rule.Name, selectedRule and selectedRule.Name)
    rulesFrame.SelectedRule = selected and rule or nil;

    local button = self.ScrollBox:FindFrame(rule);
	if not button then
		return;
	end

    if rule == rulesFrame.SelectedRule then
        button:LockHighlight();
	end

    if not rulesFrame.SelectedRule then
        button:UnlockHighlight();
        return;
    end

    rulesFrame.RuleFrame:SetSelectedRule(rule);
end

local function AddSelectionBehavior(self)
	self.SelectionBehavior = ScrollUtil.AddSelectionBehavior(self.ScrollBox, SelectionBehaviorFlags.Intrusive);
	self.SelectionBehavior:RegisterCallback(SelectionBehaviorMixin.Event.OnSelectionChanged, ScrollBoxSelectionChanged, self);
end

function KrowiV_AutoSellRulesListMixin:OnLoad()
    CreateScrollView(self);
    AddManagedScrollBarVisibilityBehavior(self);
    AddSelectionBehavior(self);
    rulesList = self;
    rulesFrame = rulesList:GetParent();
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

local function UpdateDataProvider(self, retainScrollPosition)
    local _scope = rulesFrame.GetScope(rulesFrame.SelectedTab);
    local rules = rulesFrame.GetRules(_scope);
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

function KrowiV_AutoSellRulesListMixin:Update(retainScrollPosition)
	if rulesFrame.SelectedTab == nil then
		return;
	end

	UpdateDataProvider(self, retainScrollPosition);

    if rulesFrame.SelectedRule == nil then
        self.SelectionBehavior:ClearSelections();
        self.SelectionBehavior:SelectFirstElementData();
    end
end

KrowiV_AutoSellRulesButtonMixin = CreateFromMixins(CallbackRegistryMixin);
KrowiV_AutoSellRulesButtonMixin:GenerateCallbackEvents(
    {
        "OnValueChanged",
        "OnSizeChanged", -- Unused
        "OnEnter", -- Unused
        "OnLeave", -- Unused
        "OnMouseDown", -- Unused
        "OnMouseUp", -- Unused
        "OnClick" -- Unused
    }
);

function KrowiV_AutoSellRulesButtonMixin:SetName(rule)
    self.Name:SetText("|T13681" .. (rule.IsDisabled and "3" or "4") .. ":0|t " .. rule.Name);
end

function KrowiV_AutoSellRulesButtonMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self);
    -- ruleFrame.Name:RegisterCallback(self.Event.OnValueChanged, function(_, value)
    --     if self.Rule == selectedRule then
    --         self:SetName(selectedRule);
    --     end
    -- end, self);
    -- ruleFrame.IsEnabled:RegisterCallback(self.Event.OnValueChanged, function(_, value)
    --     if self.Rule == selectedRule then
    --         self:SetName(selectedRule);
    --     end
    -- end, self);
end

function KrowiV_AutoSellRulesButtonMixin:Init(rule)
    self.Rule = rule;
    self:SetName(rule);

    -- We need this here to properly select new rules
    if rule == rulesFrame.SelectedRule then
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
    rulesList.SelectionBehavior:ToggleSelect(self);
end