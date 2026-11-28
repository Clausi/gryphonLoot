local _, ns = ...
local L = ns.L
local Options = ns:RegisterModule("Options")

-- Options page in Blizzard's settings (Esc > Options > AddOns > GryphonLoot) with one section per
-- feature, built with own controls (Core/OptionsPanel.lua explains why). The settings stay in
-- ns.db and ns.charDb; the controls read and write them through the getters and setters of the
-- modules, so a change takes effect right away.

local category, panel

local function AddNotifications()
    panel:AddCheckbox(L["OPTIONS_NOTIFICATIONS"], L["OPTIONS_NOTIFICATIONS_TOOLTIP"],
        function()
            return ns.charDb.notifications
        end,
        function(value)
            ns.charDb.notifications = value
        end)
end

-- Marks on the items and the bar below Blizzard's loot window (Modules/LootWindow.lua).
local function AddLootWindow()
    local LootWindow = ns.modules.LootWindow
    panel:AddHeader(L["OPTIONS_LOOT_WINDOW_HEADER"])
    local settings = {
        { key = "lootWindowItemLevel", label = "OPTIONS_LOOT_WINDOW_ITEM_LEVEL" },
        { key = "lootWindowUpgrades", label = "OPTIONS_LOOT_WINDOW_UPGRADES" },
        { key = "lootWindowUnusable", label = "OPTIONS_LOOT_WINDOW_UNUSABLE" },
        { key = "lootWindowValue", label = "OPTIONS_LOOT_WINDOW_VALUE" },
        { key = "lootWindowBagSpace", label = "OPTIONS_LOOT_WINDOW_BAG_SPACE" },
        { key = "lootWindowLootAll", label = "OPTIONS_LOOT_WINDOW_LOOT_ALL" },
    }
    for _, entry in ipairs(settings) do
        local key = entry.key
        panel:AddCheckbox(L[entry.label], L[entry.label .. "_TOOLTIP"],
            function()
                return LootWindow:IsEnabled(key)
            end,
            function(value)
                LootWindow:SetEnabled(key, value)
            end)
    end
end

local function FormatAutoClose(value)
    local seconds = floor(value + 0.5)
    if seconds == 0 then
        return L["OPTIONS_LOOT_AUTO_CLOSE_NEVER"]
    end
    return format(L["OPTIONS_LOOT_AUTO_CLOSE_SECONDS"], seconds)
end

-- Choices next to the roll frames and the results window (Modules/LootRolls.lua).
local function AddLootRolls()
    local LootRolls = ns.modules.LootRolls
    panel:AddHeader(L["OPTIONS_LOOT_ROLLS_HEADER"])
    panel:AddCheckbox(L["OPTIONS_LOOT_CHOICES"], L["OPTIONS_LOOT_CHOICES_TOOLTIP"],
        function()
            return LootRolls:AreChoicesEnabled()
        end,
        function(value)
            LootRolls:SetChoicesEnabled(value)
        end)
    panel:AddCheckbox(L["OPTIONS_LOOT_RESULTS"], L["OPTIONS_LOOT_RESULTS_TOOLTIP"],
        function()
            return LootRolls:AreResultsEnabled()
        end,
        function(value)
            LootRolls:SetResultsEnabled(value)
        end)
    panel:AddSlider(L["OPTIONS_LOOT_AUTO_CLOSE"], L["OPTIONS_LOOT_AUTO_CLOSE_TOOLTIP"],
        0, LootRolls.MAX_AUTO_CLOSE, LootRolls.AUTO_CLOSE_STEP, FormatAutoClose,
        function()
            return LootRolls:GetAutoClose()
        end,
        function(value)
            LootRolls:SetAutoClose(floor(value + 0.5))
        end)
end

-- Log of the looted items and money (Modules/LootLog.lua).
local function AddLootLog()
    local LootLog = ns.modules.LootLog
    panel:AddHeader(L["OPTIONS_LOOT_LOG_HEADER"])
    panel:AddCheckbox(L["OPTIONS_LOOT_LOG"], L["OPTIONS_LOOT_LOG_TOOLTIP"],
        function()
            return LootLog:IsEnabled()
        end,
        function(value)
            LootLog:SetEnabled(value)
        end)
    panel:AddCheckbox(L["OPTIONS_LOOT_LOG_RESET_ON_LOGIN"], L["OPTIONS_LOOT_LOG_RESET_ON_LOGIN_TOOLTIP"],
        function()
            return LootLog:IsResetOnLogin()
        end,
        function(value)
            LootLog:SetResetOnLogin(value)
        end)
    panel:AddCheckbox(L["OPTIONS_LOOT_LOG_SHOWN"], L["OPTIONS_LOOT_LOG_SHOWN_TOOLTIP"],
        function()
            return LootLog:IsShown()
        end,
        function(value)
            LootLog:SetShown(value)
        end)
    panel:AddButton(L["OPTIONS_LOOT_LOG_RESET"], L["OPTIONS_LOOT_LOG_RESET_BUTTON"],
        L["OPTIONS_LOOT_LOG_RESET_TOOLTIP"], function()
            LootLog:Reset()
        end)
end

function Options:OnInitialize()
    panel = ns.OptionsPanel.Create(ns.name)
    AddNotifications()
    AddLootWindow()
    AddLootRolls()
    AddLootLog()
    category = panel:Register()
end

-- "/gryphonloot options" opens the options page. Opening it from addon code is blocked in combat
-- (ADDON_ACTION_BLOCKED for OpenSettingsPanel); Esc > Options still works there.
ns:RegisterCommand("options", function()
    if InCombatLockdown() then
        ns:Print(L["OPTIONS_IN_COMBAT"])
        return
    end
    Settings.OpenToCategory(category:GetID())
end, { L["HELP_OPTIONS"] })
