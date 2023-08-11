-- [[ Namespaces ]] --
local addonName, addon = ...;

-- do --[[ KrowiV_InjectOptions ]]
-- 	KrowiV_InjectOptions = {};

--     function KrowiV_InjectOptions:SetOptionsTable(optionsTable)
--         self.OptionsTable = optionsTable;
--     end

-- 	function KrowiV_InjectOptions:AddTable(destTablePath, key, table)
-- 		local destTable;
-- 		if type(destTablePath) == "table" then
-- 			destTable = destTablePath;
-- 		elseif type(destTablePath) == "string" then
-- 			destTable = self.OptionsTable.args;
-- 			local pathParts = strsplittable(".", destTablePath);
-- 			for _, part in next, pathParts do
-- 				destTable = destTable[part];
-- 			end
-- 		end
-- 		destTable[key] = table;
-- 		return destTable[key];
-- 	end

-- 	function KrowiV_InjectOptions:GetTable(destTablePath)
-- 		local destTable = self.OptionsTable.args;
-- 		local pathParts = strsplittable(".", destTablePath);
-- 		for _, part in next, pathParts do
-- 			destTable = destTable[part];
-- 		end
-- 		return destTable;
-- 	end

-- 	function KrowiV_InjectOptions:TableExists(destTablePath)
-- 		local destTable = KrowiV_InjectOptions:GetTable(destTablePath)
-- 		return destTable and true or false;
-- 	end

-- 	-- function KrowiV_InjectOptions:DeleteTable(destTablePath)
-- 	-- 	local destTable = self.OptionsTable.args;
-- 	-- 	local pathParts = strsplittable(".", destTablePath);
-- 	-- 	for _, part in next, pathParts do
-- 	-- 		destTable = destTable[part];
-- 	-- 	end
-- 	-- 	destTable = nil;
-- 	-- end

--     function KrowiV_InjectOptions:SetOptions(options)
--         self.Options = options;
--     end

-- 	function KrowiV_InjectOptions:AddDefaults(destTablePath, key, table)
-- 		local destTable = self.Options;
-- 		local pathParts = strsplittable(".", destTablePath);
-- 		for _, part in next, pathParts do
-- 			destTable = destTable[part];
-- 		end
-- 		destTable[key] = table;
-- 	end

-- 	function KrowiV_InjectOptions:DefaultsExists(destTablePath)
-- 		local destTable = self.Options;
-- 		local pathParts = strsplittable(".", destTablePath);
-- 		for _, part in next, pathParts do
-- 			destTable = destTable[part];
-- 		end
-- 		return destTable and true or false;
-- 	end

-- 	local autoOrder = 1;
-- 	function KrowiV_InjectOptions.AutoOrderPlusPlus(amount)
-- 		local current = autoOrder;
-- 		autoOrder = autoOrder + (1 or amount);
-- 		return current;
-- 	end

-- 	function KrowiV_InjectOptions.PlusPlusAutoOrder(amount)
-- 		autoOrder = autoOrder + (1 or amount);
-- 		return autoOrder;
-- 	end

-- 	function KrowiV_InjectOptions.AdjustedWidth(number)
-- 		return (number or 1) * addon.Options.WidthMultiplier;
-- 	end

-- 	local OrderPP = KrowiV_InjectOptions.AutoOrderPlusPlus;
-- 	function KrowiV_InjectOptions.AddPluginTable(pluginName, pluginDisplayName, desc, loadedFunc)
-- 		return KrowiV_InjectOptions:AddTable("Plugins.args", pluginName, {
-- 			type = "group",
-- 			name = pluginDisplayName,
-- 			args = {
-- 				Loaded = {
-- 					order = OrderPP(), type = "toggle", width = "full",
-- 					name = addon.L["Loaded"],
-- 					desc = addon.L["Loaded Desc"],
-- 					descStyle = "inline",
-- 					get = loadedFunc,
-- 					disabled = true
-- 				},
-- 				Line = {
-- 					order = OrderPP(), type = "header", width = "full",
-- 					name = ""
-- 				},
-- 				Description = {
-- 					order = OrderPP(), type = "description", width = "full",
-- 					name = desc,
-- 					fontSize = "medium"
-- 				}
-- 			}
-- 		}).args;
-- 	end
-- end

do --[[ KrowiV_RegisterAutoJunkOptions ]]
    local function InjectOptionsDefaults(expansion, instanceId, junkByDefault)
		if junkByDefault == nil then
			junkByDefault = false;
		end
		if not addon.InjectOptions:DefaultsExists("AutoJunk.Instances") then
			addon.InjectOptions:AddDefaults("AutoJunk", "Instances", { });
		end
		addon.InjectOptions:AddDefaults("AutoJunk.Instances", instanceId, junkByDefault);
	end

    local OrderPP = addon.InjectOptions.AutoOrderPlusPlus;
	local AdjustedWidth = addon.InjectOptions.AdjustedWidth;
	local function InjectOptionsTable(expansion, expansionDisplayName, instanceType, instanceTypeDisplayName, instanceId, instanceDisplayName)
        if not addon.InjectOptions:TableExists("AutoJunk.args." .. expansion) then
			addon.InjectOptions:AddTable("AutoJunk.args", expansion, {
				order = OrderPP(), type = "group",
				name = expansionDisplayName,
				args = {}
			});
		end
		if not addon.InjectOptions:TableExists("AutoJunk.args." .. expansion .. ".args." .. instanceType) then
			addon.InjectOptions:AddTable("AutoJunk.args." .. expansion .. ".args", instanceType, {
				order = OrderPP(), type = "group", inline = true,
				name = instanceTypeDisplayName,
				args = {}
			});
		end
		addon.InjectOptions:AddTable("AutoJunk.args." .. expansion .. ".args." .. instanceType .. ".args", tostring(instanceId), {
			order = OrderPP(), type = "toggle", width = AdjustedWidth(0.95),
			name = instanceDisplayName,
			get = function() return addon.Options.db.profile.AutoJunk.Instances[instanceId]; end,
			set = function()
				addon.Options.db.profile.AutoJunk.Instances[instanceId] = not addon.Options.db.profile.AutoJunk.Instances[instanceId];
                addon.Data.AutoJunk.EnableForInstanceId();
            end
		});
	end

    function KrowiV_RegisterAutoJunkOptions(expansion, expansionDisplayName, instanceType, instanceTypeDisplayName, instanceId, instanceDisplayName, junkByDefault)
        InjectOptionsDefaults(expansion, instanceId, junkByDefault);
        InjectOptionsTable(expansion, expansionDisplayName, instanceType, instanceTypeDisplayName, instanceId, instanceDisplayName);
    end

    function KrowiAF_RegisterDeSelectAllEventOptions(expansion, instanceType, instanceIds)
		if addon.InjectOptions:TableExists("AutoJunk.args." .. expansion .. ".args." .. instanceType .. ".args.SelectAll") then
			return;
		end

		addon.InjectOptions:AddTable("AutoJunk.args." .. expansion .. ".args." .. instanceType .. ".args", "Blank1", {
			order = OrderPP(), type = "description", width = "full", name = ""
		});
		addon.InjectOptions:AddTable("AutoJunk.args." .. expansion .. ".args." .. instanceType .. ".args", "Blank2", {
			order = OrderPP(), type = "description", width = AdjustedWidth(0.95), name = ""
		});
		addon.InjectOptions:AddTable("AutoJunk.args." .. expansion .. ".args." .. instanceType .. ".args", "SelectAll", {
			order = OrderPP(), type = "execute", width = AdjustedWidth(0.95),
			name = addon.L["Select All"],
			func = function()
				for _, instanceId in next, instanceIds do
					addon.Options.db.profile.AutoJunk.Instances[instanceId] = true;
				end
                addon.Data.AutoJunk.EnableForInstanceId();
			end
		});
		addon.InjectOptions:AddTable("AutoJunk.args." .. expansion .. ".args." .. instanceType .. ".args", "DeselectAll", {
			order = OrderPP(), type = "execute", width = AdjustedWidth(0.95),
			name = addon.L["Deselect All"],
			func = function()
				for _, instanceId in next, instanceIds do
					addon.Options.db.profile.AutoJunk.Instances[instanceId] = nil;
				end
                addon.Data.AutoJunk.EnableForInstanceId();
			end
		});
	end
end