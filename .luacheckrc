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
    "C_Container",
    "C_Item",
    "C_LootFrame",
    "C_LootHistory",
    "C_Timer",
    "C_TooltipInfo",
    "CreateFrame",
    "Enum",
    "GetAddOnMemoryUsage",
    "GetInventoryItemLink",
    "GetInventorySlotInfo",
    "GetLocale",
    "GetLootRollItemLink",
    "GetLootSlotInfo",
    "GetLootSlotLink",
    "GetLootSlotType",
    "GetMoney",
    "GetMoneyString",
    "GetNumLootItems",
    "issecretvalue",
    "LootSlot",
    "NUM_BAG_SLOTS",
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
    "LOOT_ITEM_SELF",
    "LOOT_ITEM_SELF_MULTIPLE",
    "HIGHLIGHT_FONT_COLOR",
    "RED_FONT_COLOR",
    "RAID_CLASS_COLORS",
    "UNKNOWN",

    -- UI helpers
    "CreateAtlasMarkup",
    "CreateSettingsButtonInitializer",
    "CreateSettingsListSectionHeaderInitializer",
    "MinimalSliderWithSteppersMixin",
    "ScrollUtil",
    "Settings",
    "SettingsPanel",

    -- Frames
    "DEFAULT_CHAT_FRAME",
    "GameTooltip",
    -- Blizzard's loot window: only read, the module adds own frames to it (see LootWindow.lua).
    "LootFrame",
    "UIParent",
}
