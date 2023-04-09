-- [[ Namespaces ]] --
local addonName, addon = ...;
addon.Data.AutoRepair = {};
local autoRepair = addon.Data.AutoRepair;

local function GetGuildBankRepairMoney()
    -- If player doesn't enable KV Guild Auto Repair
    if (not addon.Options.db.AutoRepair.IsGuildEnabled) then
        return 0;
    end

    -- If player can't repair, or is not in a guild
    if (not CanGuildBankRepair() or not GetGuildInfo("player")) then
        return 0;
    end

    local guildBankMoney = GetGuildBankMoney();
    local guildBankWithdrawMoney = GetGuildBankWithdrawMoney();
    -- If Guild Master, just return all the bank money
    if (guildBankWithdrawMoney == 2 ^ 64) then
        return guildBankMoney;
    end
    -- Return the lowest of the two, in case you can repair more than the bank can have
    return math.min(guildBankMoney, guildBankWithdrawMoney);
end

local function DoAutoRepair()
    -- If merchant can't repair
    if (not CanMerchantRepair()) then return end

    local repairAllCost = GetRepairAllCost();
    -- If there's nothing to repair
    if (repairAllCost == 0) then return end

    local playerMoney = GetMoney();
    local guildBankMoney = GetGuildBankRepairMoney();

    -- If guild funds are available, but my repair cost is too much, try to repair from personal funds
    if (guildBankMoney > 0 and repairAllCost > guildBankMoney) then
        if (addon.Options.db.AutoRepair.PrintChatMessage) then
            if (addon.Options.db.AutoRepair.PrintChatMessage) then
                print("[KV] Not enough guild funds to repair, using personal!");
            end
            RepairAllItems(false);
            if (addon.Options.db.AutoRepair.PrintChatMessage) then
                print("[KV] Repaired with personal funds " ..
                    math.floor(repairAllCost / 10000) .. "g " ..
                    math.floor((repairAllCost / 100) % 100) .. "s " ..
                    repairAllCost % 100 .. "c ");
            end
        end
        return
        -- If guild funds are available and I can repair
    elseif (guildBankMoney > 0 and repairAllCost <= guildBankMoney) then
        RepairAllItems(true);
        if (addon.Options.db.AutoRepair.PrintChatMessage) then
            print("[KV] Repaired with guild funds " ..
                math.floor(repairAllCost / 10000) .. "g " ..
                math.floor((repairAllCost / 100) % 100) .. "s " ..
                repairAllCost % 100 .. "c ");
            repairAllCost = 0;
        end
    end

    -- If I haven't repaired from guild, there is still a cost and I have money
    if (repairAllCost > 0 and playerMoney >= GetRepairAllCost()) then
        RepairAllItems(false);
        if (addon.Options.db.AutoRepair.PrintChatMessage) then
            print("[KV] Repaired with personal funds " ..
                math.floor(repairAllCost / 10000) .. "g " ..
                math.floor((repairAllCost / 100) % 100) .. "s " ..
                repairAllCost % 100 .. "c ");
        end
    end

    -- If I don't have any funds to repair
    if (playerMoney < repairAllCost) then
        if (addon.Options.db.AutoRepair.PrintChatMessage) then
            print("[KV] Not enough personal funds to repair!");
        end
        return
    end
    -- Doesn't play?
    --PlaySound(SOUNDKIT.ITEM_REPAIR);
end

local function TryAutoRepair()
    -- If player doesn't enable KV Auto Repair
    if (not addon.Options.db.AutoRepair.IsEnabled) then
        return;
    end

    local repairAllCost, canRepair = GetRepairAllCost();
    -- If repairs aren't needed
    if (not canRepair) then
        return
    else
        DoAutoRepair();
    end
end


local loadHelper = CreateFrame("Frame");
loadHelper:RegisterEvent("MERCHANT_SHOW");

function loadHelper:OnEvent(event, arg1, arg2)
    if event == "MERCHANT_SHOW" then
        TryAutoRepair();
    end
end

loadHelper:SetScript("OnEvent", loadHelper.OnEvent);
