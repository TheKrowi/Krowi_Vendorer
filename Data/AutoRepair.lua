-- [[ Namespaces ]] --
local addonName, addon = ...;
addon.Data.AutoRepair = {};
local autoRepair = addon.Data.AutoRepair;

local co, fail;

local function GetGuildBankRepairMoney()
    -- If player doesn't enable KV Guild Auto Repair
    if not addon.Options.db.AutoRepair.IsGuildEnabled then
        return 0;
    end

    -- If player can't repair, or is not in a guild
    if (not CanGuildBankRepair() or not GetGuildInfo("player")) then
        return 0;
    end

    -- Blizzard odd API behavior: If Guild Bank wasn't opened after login, it returns 0.
    -- But if it was opened on any character logged in before, it returns that char's bank value
    -- So we can only trust it and test fail when we try to repair, if it's enough
    local guildBankMoney = GetGuildBankMoney();
    local guildBankWithdrawMoney = GetGuildBankWithdrawMoney();
    -- If Guild Master, just return all the bank money
    if guildBankWithdrawMoney == 2 ^ 64 then
        return guildBankMoney;
    end

    -- Return the lowest of the two, in case you can repair more than the bank can have
    return math.min(guildBankMoney, guildBankWithdrawMoney);
end

local function TryPersonalRepairs(playerMoney, repairAllCost)
    -- If there's nothing to repair
    if repairAllCost == 0 then return; end

    local gold = math.floor(repairAllCost / 10000);
    local silver = math.floor((repairAllCost / 100) % 100);
    local copper = repairAllCost % 100;

    if playerMoney >= repairAllCost then
        RepairAllItems(false);
        PlaySound(SOUNDKIT.ITEM_REPAIR);
        if addon.Options.db.AutoRepair.PrintChatMessage then
            print(addon.L["Auto Repair Repaired Personal"]:ReplaceVars { g = gold, s = silver, c = copper });
        end
        return;
    end

    -- If I don't have any funds to repair
    if playerMoney < repairAllCost then
        if addon.Options.db.AutoRepair.PrintChatMessage then
            print(addon.L["Auto Repair No Personal"]);
        end
        return;
    end
end

local function DoAutoRepair()
    -- If merchant can't repair
    if not CanMerchantRepair() then return; end

    local repairAllCost = GetRepairAllCost();
    -- If there's nothing to repair
    if repairAllCost == 0 then return; end

    local gold = math.floor(repairAllCost / 10000);
    local silver = math.floor((repairAllCost / 100) % 100);
    local copper = repairAllCost % 100;

    local playerMoney = GetMoney();
    local guildBankMoney = GetGuildBankRepairMoney();

    -- If guild funds are available and I can repair
    if (guildBankMoney > 0 and repairAllCost <= guildBankMoney) then
        RepairAllItems(true);
        coroutine.yield();

        if not fail then
            PlaySound(SOUNDKIT.ITEM_REPAIR);

            if addon.Options.db.AutoRepair.PrintChatMessage then
                print(addon.L["Auto Repair Repaired Guild"]:ReplaceVars { g = gold, s = silver, c = copper });
            end
            return;
        end
    end

    -- If guild funds are available, but my repair cost is too much, try to repair from personal funds
    if (guildBankMoney > 0 and repairAllCost > guildBankMoney) then
        if addon.Options.db.AutoRepair.PrintChatMessage then
            print(addon.L["Auto Repair No Guild Funds Use Personal"]);
        end
        TryPersonalRepairs(playerMoney, repairAllCost)
    -- If no guild funds are available, just try repairing from personal funds
    else
        TryPersonalRepairs(playerMoney, repairAllCost);
    end
end

local function TryAutoRepairAsync()
    -- If player doesn't enable KV Auto Repair
    if not addon.Options.db.AutoRepair.IsEnabled then return; end

    local _, canRepair = GetRepairAllCost();
    -- If repairs aren't needed
    if not canRepair then
        return;
    end

    co = coroutine.create(DoAutoRepair);
    coroutine.resume(co);
end

local loadHelper = CreateFrame("Frame");
loadHelper:RegisterEvent("MERCHANT_SHOW");
-- loadHelper:RegisterEvent("UI_ERROR_MESSAGE");

function loadHelper:OnEvent(event, arg1, arg2)
    if event == "MERCHANT_SHOW" then
        TryAutoRepairAsync();
    end

    -- 154 The guild bank does not have enough money
    if event == "UI_ERROR_MESSAGE" and arg1 == 154 then
        fail = true;
        if co ~= nil then
            coroutine.resume(co);
        end
    end

    if event == "UPDATE_INVENTORY_DURABILITY" then
        fail = nil;
        if co ~= nil then
            coroutine.resume(co);
        end
    end
end
loadHelper:SetScript("OnEvent", loadHelper.OnEvent);


