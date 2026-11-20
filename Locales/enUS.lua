local _, ns = ...

-- Base locale. Every key used in the addon must be defined here.
-- Other locales only override the keys they translate; missing keys fall back to enUS.
local L = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})
ns.L = L

L["ADDON_LOADED"] = "Version %s loaded. Type /gryphonloot for help."
L["DEBUG_ON"] = "Debug output enabled."
L["DEBUG_OFF"] = "Debug output disabled."
L["HELP_HEADER"] = "Commands:"
L["HELP_VERSION"] = "/gryphonloot version - show the addon version"
L["HELP_DEBUG"] = "/gryphonloot debug - toggle debug output"
L["HELP_CHAT"] = "/gryphonloot chat on||off - automatic chat messages (login, hints)"
L["CHAT_ON"] = "Automatic chat messages are on for this character."
L["CHAT_OFF"] = "Automatic chat messages are off for this character. Answers to commands are still shown."
L["HELP_OPTIONS"] = "/gryphonloot options - open the options"
L["OPTIONS_IN_COMBAT"] = "The options cannot be opened by command in combat. Use "
    .. "Esc > Options > AddOns or try again after the fight."
L["OPTIONS_CHAT_MESSAGES"] = "Chat Messages"
L["OPTIONS_CHAT_MESSAGES_TOOLTIP"] = "Shows automatic chat messages (login, hints). Answers to commands are "
    .. "always shown. Saved for this character."
L["HELP_LOOT_ROLLS"] = "/gryphonloot rolls on||off - show who chose need, greed or pass next to the roll frames"
L["LOOT_ROLLS_ON"] = "Choices next to the roll frames are on for this character."
L["LOOT_ROLLS_OFF"] = "Choices next to the roll frames are off for this character."
L["HELP_LOOT_RESULTS"] = "/gryphonloot results on||off||test - keep the results of loot rolls in a window"
L["LOOT_RESULTS_ON"] = "The loot roll results window is on for this character."
L["LOOT_RESULTS_OFF"] = "The loot roll results window is off for this character."
L["LOOT_RESULTS_TITLE"] = "Roll Results"
L["LOOT_SETTING_WIDTH"] = "Frame Width"
L["LOOT_SETTING_HEIGHT"] = "Frame Height"
L["LOOT_SETTING_PADDING"] = "Padding"
L["LOOT_SETTING_OPACITY"] = "Opacity"
L["LOOT_SETTING_BACKGROUND"] = "Background"
L["LOOT_SETTING_TEXT_SIZE"] = "Text Size"
L["LOOT_SETTING_ITEM_ICONS"] = "Show Item Icon"
L["LOOT_SETTING_CLASS_COLORS"] = "Show Class Color"
L["OPTIONS_LOOT_CHOICES"] = "Show Choices of the Group"
L["OPTIONS_LOOT_CHOICES_TOOLTIP"] = "Shows next to each roll frame who chose need, greed or pass. The tooltip "
    .. "lists all names. Blizzard closes a roll frame after your own choice. Saved for this character."
L["OPTIONS_LOOT_RESULTS"] = "Results Window"
L["OPTIONS_LOOT_RESULTS_TOOLTIP"] = "Keeps finished rolls in a small scrolling window, grouped by item, newest "
    .. "first. A roll already shows there after your own choice, with the players still to choose. Drag it to "
    .. "move it, and use the corner to change its size, also in combat. Size and look are in Edit Mode. Saved for "
    .. "this character."
L["OPTIONS_LOOT_AUTO_CLOSE"] = "Close Results Automatically"
L["OPTIONS_LOOT_AUTO_CLOSE_TOOLTIP"] = "Closes the results window this long after the last result, once no roll "
    .. "runs anymore. Saved for this character."
L["OPTIONS_LOOT_AUTO_CLOSE_NEVER"] = "Never"
L["OPTIONS_LOOT_AUTO_CLOSE_SECONDS"] = "%d Seconds"
