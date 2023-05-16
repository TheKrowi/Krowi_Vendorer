-- [[ Namespaces ]] --
local _, addon = ...;
local rulesFrame, ruleFrame;

KrowiV_AutoSellRuleFrameMixin = {};

local function CreateScrollView(self)
    self.ScrollView = CreateScrollBoxListLinearView();
    self.ScrollView:SetElementFactory(function(factory, elementData)
        elementData:Factory(factory, function(frame, elementData)
            elementData:InitFrame(frame);
        end);
    end);
    self.ScrollView:SetElementResetter(function(frame, elementData)
		elementData:Resetter(frame);
	end);
    self.ScrollView:SetElementExtentCalculator(function(dataIndex, elementData)
        local extent = elementData:GetExtent();
		return extent or self.ScrollView:CreateTemplateExtent(elementData:GetTemplate());
    end);
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

function KrowiV_AutoSellRuleFrameMixin:OnLoad()
    print("KrowiV_AutoSellRuleFrameMixin:OnLoad")
    CreateScrollView(self);
    AddManagedScrollBarVisibilityBehavior(self);
    ruleFrame = self;
    rulesFrame = ruleFrame:GetParent();
end

local function CreateCheckBoxInitializer(rule)
    local data = Settings.CreateSettingInitializerData(
        CreateAndInitFromMixin(
            ProxySettingMixin,
            addon.L["Enabled"],
            "IsEnabled",
            rule,
            Settings.VarType.Boolean,
            true
        ),
        nil,
        addon.L["Enabled Desc"]
    );
    return Settings.CreateElementInitializer("SettingsCheckBoxControlTemplate", data);
end

function KrowiV_AutoSellRuleFrameMixin:SetSelectedRule(rule)
    local newDataProvider = CreateDataProvider();
    newDataProvider:Insert(CreateSettingsListSectionHeaderInitializer(addon.L["General"]));
    -- Insert name
    newDataProvider:Insert(CreateCheckBoxInitializer(rule));
	self.ScrollBox:SetDataProvider(newDataProvider, false);
end