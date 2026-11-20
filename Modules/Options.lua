local _, ns = ...
local L = ns.L
local Options = ns:RegisterModule("Options")

-- Options page in Blizzard's settings (Esc > Options > AddOns > GryphonLoot) as a vertical list.
-- The settings stay in ns.db and ns.charDb; proxy settings read and write them there through the
-- getters and setters of the modules, so a change takes effect right away.

local category

-- Proxy setting variables must be unique among all settings of the game and addons.
local function RegisterProxySetting(variable, varType, name, defaultValue, getValue, setValue)
    return Settings.RegisterProxySetting(category, "GRYPHONLOOT_" .. variable, varType, name,
        defaultValue, getValue, setValue)
end

local function RegisterChatMessages()
    local chatMessages = RegisterProxySetting("CHAT_MESSAGES", Settings.VarType.Boolean,
        L["OPTIONS_CHAT_MESSAGES"], ns.charDefaults.chatMessages,
        function()
            return ns.charDb.chatMessages
        end,
        function(value)
            ns.charDb.chatMessages = value
        end)
    Settings.CreateCheckbox(category, chatMessages, L["OPTIONS_CHAT_MESSAGES_TOOLTIP"])
end

-- Choices next to the roll frames and the results window (Modules/LootRolls.lua).
local function RegisterLootRolls()
    local LootRolls = ns.modules.LootRolls
    local choices = RegisterProxySetting("LOOT_ROLL_CHOICES", Settings.VarType.Boolean,
        L["OPTIONS_LOOT_CHOICES"], ns.charDefaults.lootRollChoices,
        function()
            return LootRolls:AreChoicesEnabled()
        end,
        function(value)
            LootRolls:SetChoicesEnabled(value)
        end)
    Settings.CreateCheckbox(category, choices, L["OPTIONS_LOOT_CHOICES_TOOLTIP"])

    local results = RegisterProxySetting("LOOT_ROLL_RESULTS", Settings.VarType.Boolean,
        L["OPTIONS_LOOT_RESULTS"], ns.charDefaults.lootRollResults,
        function()
            return LootRolls:AreResultsEnabled()
        end,
        function(value)
            LootRolls:SetResultsEnabled(value)
        end)
    Settings.CreateCheckbox(category, results, L["OPTIONS_LOOT_RESULTS_TOOLTIP"])

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

function Options:OnInitialize()
    category = Settings.RegisterVerticalLayoutCategory(ns.name)
    RegisterChatMessages()
    RegisterLootRolls()
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
