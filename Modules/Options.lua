local _, ns = ...
local L = ns.L
local Options = ns:RegisterModule("Options")

-- Options page in Blizzard's settings (Esc > Options > AddOns > GryphonLoot) as a vertical list
-- with one section per feature. The settings stay in ns.db and ns.charDb; proxy settings read and
-- write them there through the getters and setters of the modules, so a change takes effect right
-- away.

local category, layout

-- Proxy setting variables must be unique among all settings of the game and addons.
local function RegisterProxySetting(variable, varType, name, defaultValue, getValue, setValue)
    return Settings.RegisterProxySetting(category, "GRYPHONLOOT_" .. variable, varType, name,
        defaultValue, getValue, setValue)
end

local function AddHeader(text)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
end

local function AddCheckbox(variable, name, tooltip, defaultValue, getValue, setValue)
    local setting = RegisterProxySetting(variable, Settings.VarType.Boolean, name, defaultValue, getValue, setValue)
    Settings.CreateCheckbox(category, setting, tooltip)
end

local function RegisterNotifications()
    AddCheckbox("NOTIFICATIONS", L["OPTIONS_NOTIFICATIONS"], L["OPTIONS_NOTIFICATIONS_TOOLTIP"],
        ns.charDefaults.notifications,
        function()
            return ns.charDb.notifications
        end,
        function(value)
            ns.charDb.notifications = value
        end)
end

-- Marks on the items and the bar below Blizzard's loot window (Modules/LootWindow.lua).
local function RegisterLootWindow()
    local LootWindow = ns.modules.LootWindow
    AddHeader(L["OPTIONS_LOOT_WINDOW_HEADER"])
    local settings = {
        { key = "lootWindowItemLevel", variable = "LOOT_WINDOW_ITEM_LEVEL", label = "OPTIONS_LOOT_WINDOW_ITEM_LEVEL" },
        { key = "lootWindowUpgrades", variable = "LOOT_WINDOW_UPGRADES", label = "OPTIONS_LOOT_WINDOW_UPGRADES" },
        { key = "lootWindowUnusable", variable = "LOOT_WINDOW_UNUSABLE", label = "OPTIONS_LOOT_WINDOW_UNUSABLE" },
        { key = "lootWindowValue", variable = "LOOT_WINDOW_VALUE", label = "OPTIONS_LOOT_WINDOW_VALUE" },
        { key = "lootWindowBagSpace", variable = "LOOT_WINDOW_BAG_SPACE", label = "OPTIONS_LOOT_WINDOW_BAG_SPACE" },
        { key = "lootWindowLootAll", variable = "LOOT_WINDOW_LOOT_ALL", label = "OPTIONS_LOOT_WINDOW_LOOT_ALL" },
    }
    for _, entry in ipairs(settings) do
        local key = entry.key
        AddCheckbox(entry.variable, L[entry.label], L[entry.label .. "_TOOLTIP"], ns.charDefaults[key],
            function()
                return LootWindow:IsEnabled(key)
            end,
            function(value)
                LootWindow:SetEnabled(key, value)
            end)
    end
end

-- Choices next to the roll frames and the results window (Modules/LootRolls.lua).
local function RegisterLootRolls()
    local LootRolls = ns.modules.LootRolls
    AddHeader(L["OPTIONS_LOOT_ROLLS_HEADER"])
    AddCheckbox("LOOT_ROLL_CHOICES", L["OPTIONS_LOOT_CHOICES"], L["OPTIONS_LOOT_CHOICES_TOOLTIP"],
        ns.charDefaults.lootRollChoices,
        function()
            return LootRolls:AreChoicesEnabled()
        end,
        function(value)
            LootRolls:SetChoicesEnabled(value)
        end)

    AddCheckbox("LOOT_ROLL_RESULTS", L["OPTIONS_LOOT_RESULTS"], L["OPTIONS_LOOT_RESULTS_TOOLTIP"],
        ns.charDefaults.lootRollResults,
        function()
            return LootRolls:AreResultsEnabled()
        end,
        function(value)
            LootRolls:SetResultsEnabled(value)
        end)

    local autoClose = RegisterProxySetting("LOOT_ROLL_AUTO_CLOSE", Settings.VarType.Number,
        L["OPTIONS_LOOT_AUTO_CLOSE"], ns.charDefaults.lootRollResultsAutoClose,
        function()
            return LootRolls:GetAutoClose()
        end,
        function(value)
            LootRolls:SetAutoClose(floor(value + 0.5))
        end)
    local autoCloseOptions = Settings.CreateSliderOptions(0, LootRolls.MAX_AUTO_CLOSE, LootRolls.AUTO_CLOSE_STEP)
    autoCloseOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        local seconds = floor(value + 0.5)
        if seconds == 0 then
            return L["OPTIONS_LOOT_AUTO_CLOSE_NEVER"]
        end
        return format(L["OPTIONS_LOOT_AUTO_CLOSE_SECONDS"], seconds)
    end)
    Settings.CreateSlider(category, autoClose, autoCloseOptions, L["OPTIONS_LOOT_AUTO_CLOSE_TOOLTIP"])
end

-- Log of the looted items and money (Modules/LootLog.lua).
local function RegisterLootLog()
    local LootLog = ns.modules.LootLog
    AddHeader(L["OPTIONS_LOOT_LOG_HEADER"])
    AddCheckbox("LOOT_LOG", L["OPTIONS_LOOT_LOG"], L["OPTIONS_LOOT_LOG_TOOLTIP"], ns.charDefaults.lootLog,
        function()
            return LootLog:IsEnabled()
        end,
        function(value)
            LootLog:SetEnabled(value)
        end)
    AddCheckbox("LOOT_LOG_RESET_ON_LOGIN", L["OPTIONS_LOOT_LOG_RESET_ON_LOGIN"],
        L["OPTIONS_LOOT_LOG_RESET_ON_LOGIN_TOOLTIP"], ns.charDefaults.lootLogResetOnLogin,
        function()
            return LootLog:IsResetOnLogin()
        end,
        function(value)
            LootLog:SetResetOnLogin(value)
        end)
    AddCheckbox("LOOT_LOG_SHOWN", L["OPTIONS_LOOT_LOG_SHOWN"], L["OPTIONS_LOOT_LOG_SHOWN_TOOLTIP"],
        ns.charDefaults.lootLogShown,
        function()
            return LootLog:IsShown()
        end,
        function(value)
            LootLog:SetShown(value)
        end)
    layout:AddInitializer(CreateSettingsButtonInitializer(L["OPTIONS_LOOT_LOG_RESET"],
        L["OPTIONS_LOOT_LOG_RESET_BUTTON"], function()
            LootLog:Reset()
        end, L["OPTIONS_LOOT_LOG_RESET_TOOLTIP"], true))
end

function Options:OnInitialize()
    category = Settings.RegisterVerticalLayoutCategory(ns.name)
    layout = SettingsPanel:GetLayout(category)
    RegisterNotifications()
    RegisterLootWindow()
    RegisterLootRolls()
    RegisterLootLog()
    Settings.RegisterAddOnCategory(category)
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
