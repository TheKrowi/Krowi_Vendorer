-- [[ Namespaces ]] --
local _, addon = ...;
addon.GlobalStrings = {};
local globalStrings = addon.GlobalStrings;

function globalStrings.Load(L)
    L["Options"] = GAMEOPTIONS_MENU;
end