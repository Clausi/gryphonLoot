-- luacheck configuration for GryphonLoot (WoW Forever, Lua 5.1)
std = "lua51"
max_line_length = 120
exclude_files = { ".tools/", "Libs/" }

-- Methods defined with ":" do not have to use the implicit self.
self = false

-- Globals the addon defines.
globals = {
    "GryphonLootDB",
    "GryphonLootCharDB",
    "SLASH_GRYPHONLOOT1",
    "SlashCmdList",
}

-- WoW API and Blizzard UI globals the addon reads. Add new ones here when used.
read_globals = {
    -- WoW Lua extensions
    "format",
    "floor",
    "strtrim",
    "hooksecurefunc",
    "wipe",
    "CopyTable",

    -- Libraries
    "LibStub",

    -- API
    "C_AddOns",
    "C_LootHistory",
    "C_Timer",
    "CreateFrame",
    "Enum",
    "GetAddOnMemoryUsage",
    "GetLocale",
    "GetLootRollItemLink",
    "HandleModifiedItemClick",
    "InCombatLockdown",
    "IsModifiedClick",
    "Item",
    "UnitClass",
    "UnitName",
    "UpdateAddOnMemoryUsage",

    -- Global strings and colors
    "LOOT_HISTORY_ALL_PASSED",
    "LOOT_HISTORY_PLAYER_DELIMITER",
    "LOOT_HISTORY_WAITING_ON",
    "RAID_CLASS_COLORS",
    "UNKNOWN",

    -- UI helpers
    "CreateAtlasMarkup",
    "MinimalSliderWithSteppersMixin",
    "Settings",

    -- Frames
    "DEFAULT_CHAT_FRAME",
    "GameTooltip",
    "UIParent",
}
