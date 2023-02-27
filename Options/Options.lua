-- [[ Namespaces ]] --
local _, addon = ...;
addon.Options = {}; -- Will be overwritten in Load (intended)
local options = addon.Options;

function options.Load()
    addon.Options = LibStub("AceDB-3.0"):New("Options", options.Defaults, true);
    addon.Options.db = addon.Options.profile;
end