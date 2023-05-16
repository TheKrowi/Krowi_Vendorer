-- [[ Namespaces ]] --
local _, addon = ...;

KrowiV_AutoSellEditBoxMixin = CreateFromMixins(CallbackRegistryMixin, DefaultTooltipMixin);
KrowiV_AutoSellEditBoxMixin:GenerateCallbackEvents(
    {
        "OnValueChanged",
    }
);

function KrowiV_AutoSellEditBoxMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self);
	DefaultTooltipMixin.OnLoad(self);
	self.tooltipXOffset = 0;
    self:SetTextInsets(6, 0, 3, 3);
    -- self:GetParent().NameLabel:SetText(addon.L["Name"]);
end

function KrowiV_AutoSellEditBoxMixin:Init(rulesFrame, value, initTooltip)
	self:SetText(value);
	self:SetTooltipFunc(initTooltip);
    self.RulesFrame = rulesFrame;
	-- self:SetScript("OnClick", function(button, buttonName, down)
	-- 	self:TriggerEvent("OnValueChanged", button:GetChecked());
	-- end);
end

function KrowiV_AutoSellEditBoxMixin:OnEscapePressed()
    self:SetTextInsets(6, 0, 3, 3);
    self:ClearFocus();
end

function KrowiV_AutoSellEditBoxMixin:OnEnterPressed()
    self.RulesFrame.SelectedRule.Name = self:GetText();
    self:TriggerEvent(self.Event.OnValueChanged, self:GetText());
    self:SetTextInsets(6, 0, 3, 3);
    self:ClearFocus();
    self.CommitChange:Hide();
end

function KrowiV_AutoSellEditBoxMixin:OnTextChanged()
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

function KrowiV_AutoSellEditBoxMixin:OnEditFocusGained()
    self:HighlightText(0, 0);
end

function KrowiV_AutoSellEditBoxMixin:Release()
	-- self:SetScript("OnClick", nil);
end

KrowiV_AutoSellEditBoxCommitChangeMixin = {};

function KrowiV_AutoSellEditBoxCommitChangeMixin:OnClick()
    self:GetParent():OnEnterPressed();
end

KrowiV_AutoSellEditBoxControlMixin = CreateFromMixins(SettingsControlMixin);

function KrowiV_AutoSellEditBoxControlMixin:OnLoad()
	SettingsControlMixin.OnLoad(self);
	self.EditBox = CreateFrame("EditBox", nil, self, "KrowiV_AutoSellEditBox_Template");
	self.EditBox:SetPoint("LEFT", self, "CENTER", -80, 0);
	-- self.Tooltip:SetScript("OnMouseUp", function()
	-- 	if self.EditBox:IsEnabled() then
	-- 		self.EditBox:Click();
	-- 	end
	-- end);
end

function KrowiV_AutoSellEditBoxControlMixin:Init(initializer)
	SettingsControlMixin.Init(self, initializer);
	local setting = self:GetSetting();
	local options = initializer:GetOptions();
	local initTooltip = Settings.CreateOptionsInitTooltip(setting, initializer:GetName(), initializer:GetTooltip(), options);
	self.EditBox:Init(initializer.data.RulesFrame, setting:GetValue(), initTooltip);

	self.cbrHandles:RegisterCallback(self.EditBox, "OnValueChanged", self.OnEditBoxValueChanged, self);
	self:EvaluateState();
end

function KrowiV_AutoSellEditBoxControlMixin:OnSettingValueChanged(setting, value)
	SettingsControlMixin.OnSettingValueChanged(self, setting, value);
	self.EditBox:SetText(value);
end

function KrowiV_AutoSellEditBoxControlMixin:OnEditBoxValueChanged(value)
	-- if self:ShouldInterceptSetting(value) then
	-- 	self.EditBox:SetChecked(not value);
	-- else
	-- 	self:GetSetting():SetValue(value);
	-- end
end

function KrowiV_AutoSellEditBoxControlMixin:SetValue(value)
	self.EditBox:SetText(value);
	-- if value then
	-- 	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	-- else 
	-- 	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
	-- end
end

function KrowiV_AutoSellEditBoxControlMixin:EvaluateState()
	SettingsListElementMixin.EvaluateState(self);
	local enabled = SettingsControlMixin.IsEnabled(self);
	-- local initializer = self:GetElementData();
	-- local options = initializer:GetOptions();
	-- if options then
	-- 	local optionData = type(options) == 'function' and options() or options;
	-- 	local value = self:GetSetting():GetValue();
	-- 	for index, option in ipairs(optionData) do
	-- 		if option.disabled and option.value ~= value then
	-- 			enabled = false;
	-- 		end
	-- 	end
	-- end
	self.EditBox:SetEnabled(enabled);
	self:DisplayEnabled(enabled);
end

function KrowiV_AutoSellEditBoxControlMixin:Release()
	self.EditBox:Release();
	SettingsControlMixin.Release(self);
end