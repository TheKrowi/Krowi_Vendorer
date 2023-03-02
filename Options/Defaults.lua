-- [[ Namespaces ]] --
local _, addon = ...;
local options = addon.Options;

options.Defaults = {
    profile = {
        NumRows = 5,
        NumColumns = 2,
        Direction = addon.L["Rows first"]
    }
};