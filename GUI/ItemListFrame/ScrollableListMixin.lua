-- [[ Namespaces ]] --
local _, addon = ...;

KrowiV_ScrollableListMixin = {};

function KrowiV_ScrollableListMixin:OnLoad()
    self.DataProvider = CreateDataProvider();

    local elementExtent = 38; -- Better performance if hardcoded, must be same as ScrollableListItemTemplate

    self.ScrollView = CreateScrollBoxListLinearView();
    self.ScrollView:SetDataProvider(self.DataProvider);
    self.ScrollView:SetElementExtent(elementExtent);
    self.ScrollView:SetElementInitializer("ScrollableListItemTemplate", function(frame, elementData)
        frame:Init(elementData);
    end);

    local paddingT = 0;
    local paddingB = 0;
    local paddingL = 0;
    local paddingR = 0;
    local spacing = 5;

    self.ScrollView:SetPadding(paddingT, paddingB, paddingL, paddingR, spacing);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, self.ScrollView);

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

function KrowiV_ScrollableListMixin:AppendListItem(id, icon, color, name)
    local elementData =
    {
        Id = id,
        Icon = icon,
        Color = color,
        Name = name,
    };

    self.DataProvider:Insert(elementData);
    self.ScrollBox:ScrollToEnd(ScrollBoxConstants.NoScrollInterpolation);
end

function KrowiV_ScrollableListMixin:RemoveListItem(elementData)
    local index = self.DataProvider:FindIndex(elementData);
    self.DataProvider:RemoveIndex(index);
end