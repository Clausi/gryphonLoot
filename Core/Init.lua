local addonName, ns = ...

-- Shared addon namespace. All files receive the same `ns` table via `...`.
ns.name = addonName
ns.version = C_AddOns.GetAddOnMetadata(addonName, "Version")
ns.modules = {}

-- Default values for the saved variables. Missing keys are filled in on load.
-- Account-wide (GryphonLootDB, ns.db): settings and data shared by all characters.
ns.defaults = {
    debug = false,
    -- Position, size and look of the loot roll results per Edit Mode layout. Filled by Modules/LootRolls.lua.
    lootRolls = {
        layouts = {},
    },
    -- Position and size of the loot log window per Edit Mode layout. Filled by Modules/LootLog.lua.
    lootLog = {
        layouts = {},
    },
}

-- Per character (GryphonLootCharDB, ns.charDb): data and settings only the logged-in character needs.
ns.charDefaults = {
    -- Automatic messages (login, automatic reset of the loot log, hints). Change with
    -- "/gryphonloot notify on|off".
    notifications = true,
    -- Who chose need, greed or pass, next to the roll frames (Modules/LootRolls.lua). Change with
    -- "/gryphonloot rolls on|off".
    lootRollChoices = true,
    -- Window with the results of finished rolls. Change with "/gryphonloot results on|off".
    lootRollResults = true,
    -- Seconds until the window closes by itself, 0 = stays open.
    lootRollResultsAutoClose = 0,
    -- Marks on the items of the loot window (Modules/LootWindow.lua): item level, upgrade arrow and
    -- red tint for items the character cannot use.
    lootWindowItemLevel = true,
    lootWindowUpgrades = true,
    lootWindowUnusable = true,
    -- Bar below the loot window: vendor value, free bag space and a "Loot All" button.
    lootWindowValue = true,
    lootWindowBagSpace = true,
    lootWindowLootAll = true,
    -- Records the looted items and money (Modules/LootLog.lua). Change with "/gryphonloot log on|off".
    lootLog = true,
    -- Empties the loot log on each login (not on /reload).
    lootLogResetOnLogin = false,
    -- The loot log window is open. Toggle with "/gryphonloot log".
    lootLogShown = false,
    -- The recorded loot until "/gryphonloot log reset": items oldest first as { link, count }, money in copper.
    lootLogData = {
        money = 0,
        items = {},
    },
}

-- Registers a module. A module may implement:
--   module:OnInitialize()  -- called once after saved variables are loaded
--   module:OnEnable()      -- called on PLAYER_LOGIN
function ns:RegisterModule(name)
    local module = { name = name }
    self.modules[#self.modules + 1] = module
    self.modules[name] = module
    return module
end

-- Registers a "/gryphonloot <name> ..." subcommand.
--   handler(args)  -- args: the rest of the input after the command name, trimmed
--   helpLines      -- user-facing help lines (already localized), shown by "/gryphonloot"
ns.commands = {}

function ns:RegisterCommand(name, handler, helpLines)
    local command = { name = name, handler = handler, helpLines = helpLines or {} }
    self.commands[#self.commands + 1] = command
    self.commands[name] = command
end

-- Simple event dispatcher: ns:RegisterEvent("EVENT", function(event, ...) end)
local eventFrame = CreateFrame("Frame")
local eventHandlers = {}

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local handlers = eventHandlers[event]
    if not handlers then
        return
    end
    for i = 1, #handlers do
        handlers[i](event, ...)
    end
end)

function ns:RegisterEvent(event, handler)
    if not eventHandlers[event] then
        eventHandlers[event] = {}
        eventFrame:RegisterEvent(event)
    end
    table.insert(eventHandlers[event], handler)
end
