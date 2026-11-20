local _, ns = ...
local L = ns.L

-- Improves Blizzard's loot window (LootFrame, Blizzard_UIPanels_Game/Mainline/LootFrame.lua), each
-- part set per character in the options:
-- - On the icon of each item: its item level (equipment only), a green arrow if it has a higher
--   item level than the equipped item of its slot, and a red tint if the character cannot use it.
-- - A bar below the window with the vendor value of the items still in it, the free bag space and a
--   "Loot All" button.
--
-- Blizzard's window and its elements are not changed: the marks are own frames on the icons, the
-- bar is an own child of LootFrame, so it hides with it. The ScrollBox calls the callback for each
-- element it initializes through securecallfunction, so the callback does not taint Blizzard's
-- code. Blizzard re-initializes an element itself on LOOT_SLOT_CHANGED (frame:Init(), without the
-- callback), so the module listens to that event as well. The marks of an element are kept in a
-- weak table instead of a field on Blizzard's frame.
local LootWindow = ns:RegisterModule("LootWindow")

local BAR_HEIGHT, BAR_PADDING, BAR_GAP = 40, 8, 2
local BUTTON_WIDTH, BUTTON_HEIGHT = 80, 22
local BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
-- Bags 0 (backpack) to NUM_BAG_SLOTS; the reagent bag only takes reagents and is left out.
local FIRST_BAG = 0
-- RED_FONT_COLOR of the tooltip lines that say an item cannot be used (1, 0.125, 0.125).
local function IsRed(color)
    return color and color.r > 0.99 and color.g < 0.2 and color.b < 0.2
end

-- Equipment slots by inventory type, as names for GetInventorySlotInfo. Types not listed (bags,
-- tabards, shirts, ammo, ...) get no item level or arrow.
local SLOT_NAMES = {
    INVTYPE_HEAD = { "HeadSlot" },
    INVTYPE_NECK = { "NeckSlot" },
    INVTYPE_SHOULDER = { "ShoulderSlot" },
    INVTYPE_CHEST = { "ChestSlot" },
    INVTYPE_ROBE = { "ChestSlot" },
    INVTYPE_WAIST = { "WaistSlot" },
    INVTYPE_LEGS = { "LegsSlot" },
    INVTYPE_FEET = { "FeetSlot" },
    INVTYPE_WRIST = { "WristSlot" },
    INVTYPE_HAND = { "HandsSlot" },
    INVTYPE_FINGER = { "Finger0Slot", "Finger1Slot" },
    INVTYPE_TRINKET = { "Trinket0Slot", "Trinket1Slot" },
    INVTYPE_CLOAK = { "BackSlot" },
    INVTYPE_WEAPON = { "MainHandSlot", "SecondaryHandSlot" },
    INVTYPE_2HWEAPON = { "MainHandSlot" },
    INVTYPE_WEAPONMAINHAND = { "MainHandSlot" },
    INVTYPE_WEAPONOFFHAND = { "SecondaryHandSlot" },
    INVTYPE_SHIELD = { "SecondaryHandSlot" },
    INVTYPE_HOLDABLE = { "SecondaryHandSlot" },
    -- The ranged slot only exists on some clients, otherwise the main hand.
    INVTYPE_RANGED = { "RangedSlot", "MainHandSlot" },
    INVTYPE_RANGEDRIGHT = { "RangedSlot", "MainHandSlot" },
    INVTYPE_THROWN = { "RangedSlot", "MainHandSlot" },
    INVTYPE_RELIC = { "RangedSlot" },
}
-- Slot IDs by inventory type, filled on first use. Unknown slot names are left out.
local slotIdCache = {}

local decorations = setmetatable({}, { __mode = "k" })
local bar
local isLooting = false
-- Slots looted since the window opened.
local clearedSlots = {}

local function GetSlotIds(equipLoc)
    local ids = slotIdCache[equipLoc]
    if ids then
        return ids
    end
    ids = {}
    local seen = {}
    for _, name in ipairs(SLOT_NAMES[equipLoc] or {}) do
        -- GetInventorySlotInfo raises an error for a slot name the client does not know.
        local ok, slotId = pcall(GetInventorySlotInfo, name)
        if ok and slotId and not seen[slotId] then
            seen[slotId] = true
            ids[#ids + 1] = slotId
            -- RangedSlot or the main hand, not both.
            if equipLoc ~= "INVTYPE_WEAPON" and equipLoc ~= "INVTYPE_FINGER" and equipLoc ~= "INVTYPE_TRINKET" then
                break
            end
        end
    end
    slotIdCache[equipLoc] = ids
    return ids
end

local function GetItemLevel(link)
    return link and C_Item.GetDetailedItemLevelInfo(link)
end

-- True if the tooltip of the slot has a red line, e.g. an armor type, weapon skill, class or level
-- the character does not have.
local function IsUnusable(slotIndex)
    local data = C_TooltipInfo.GetLootItem(slotIndex)
    for _, line in ipairs(data and data.lines or {}) do
        if IsRed(line.leftColor) or IsRed(line.rightColor) then
            return true
        end
    end
    return false
end

-- True if the item level is higher than that of the equipped item of one of its slots, or one of
-- its slots is empty.
local function IsUpgrade(equipLoc, itemLevel)
    local ids = GetSlotIds(equipLoc)
    if #ids == 0 or not itemLevel then
        return false
    end
    for _, slotId in ipairs(ids) do
        local equipped = GetItemLevel(GetInventoryItemLink("player", slotId))
        if not equipped or itemLevel > equipped then
            return true
        end
    end
    return false
end

local function GetDecoration(frame)
    local decoration = decorations[frame]
    if decoration then
        return decoration
    end
    -- An own frame above the item button, so the marks are drawn over its icon and border.
    decoration = CreateFrame("Frame", nil, frame.Item)
    decoration:SetAllPoints(frame.Item)
    decoration:SetFrameLevel(frame.Item:GetFrameLevel() + 2)

    decoration.Unusable = decoration:CreateTexture(nil, "ARTWORK")
    decoration.Unusable:SetAllPoints()
    decoration.Unusable:SetColorTexture(1, 0, 0, 0.35)

    decoration.Upgrade = decoration:CreateTexture(nil, "OVERLAY")
    decoration.Upgrade:SetAtlas("bags-greenarrow", true)
    decoration.Upgrade:SetPoint("TOPLEFT", -2, 2)

    decoration.Level = decoration:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    decoration.Level:SetPoint("BOTTOMLEFT", 2, 2)

    decorations[frame] = decoration
    return decoration
end

local function HideDecoration(frame)
    local decoration = decorations[frame]
    if decoration then
        decoration:Hide()
    end
end

local function UpdateElement(frame)
    local settings = ns.charDb
    if not (frame.Item and frame.GetSlotIndex and frame:GetElementData()) then
        return
    end
    local slotIndex = frame:GetSlotIndex()
    local link = GetLootSlotType(slotIndex) == Enum.LootSlotType.Item and GetLootSlotLink(slotIndex)
    if not (link and (settings.lootWindowItemLevel or settings.lootWindowUpgrades or settings.lootWindowUnusable)) then
        HideDecoration(frame)
        return
    end

    local item = Item:CreateFromItemLink(link)
    if not item:IsItemDataCached() then
        HideDecoration(frame)
        -- The element may show another slot by then.
        item:ContinueOnItemLoad(function()
            if frame:IsShown() and frame:GetElementData() and frame:GetSlotIndex() == slotIndex then
                UpdateElement(frame)
            end
        end)
        return
    end

    local _, _, _, equipLoc = C_Item.GetItemInfoInstant(link)
    local isEquipment = SLOT_NAMES[equipLoc] ~= nil
    local itemLevel = isEquipment and GetItemLevel(link)
    local unusable = (settings.lootWindowUnusable or settings.lootWindowUpgrades) and IsUnusable(slotIndex)

    local decoration = GetDecoration(frame)
    decoration.Unusable:SetShown(settings.lootWindowUnusable and unusable or false)
    decoration.Upgrade:SetShown(settings.lootWindowUpgrades and isEquipment and not unusable
        and IsUpgrade(equipLoc, itemLevel) or false)
    decoration.Level:SetText(settings.lootWindowItemLevel and itemLevel or "")
    decoration:Show()
end

local function UpdateElements()
    if LootFrame and LootFrame.ScrollBox:HasDataProvider() then
        LootFrame.ScrollBox:ForEachFrame(UpdateElement)
    end
end

local function IsBarEnabled()
    local settings = ns.charDb
    return settings.lootWindowValue or settings.lootWindowBagSpace or settings.lootWindowLootAll
end

-- Free slots in the bags that take any item.
local function GetFreeBagSlots()
    local free = 0
    for bag = FIRST_BAG, NUM_BAG_SLOTS do
        local numFree, bagFamily = C_Container.GetContainerNumFreeSlots(bag)
        if bagFamily == 0 then
            free = free + numFree
        end
    end
    return free
end

-- Vendor value and number of the items still in the window, and whether anything (also money or a
-- currency) is left. Money and currencies do not need bag space.
local function GetRemainingItems()
    local value, count, anyLeft = 0, 0, false
    for slotIndex = 1, GetNumLootItems() do
        local slotType = GetLootSlotType(slotIndex)
        if not clearedSlots[slotIndex] and slotType ~= Enum.LootSlotType.None then
            anyLeft = true
        end
        if not clearedSlots[slotIndex] and slotType == Enum.LootSlotType.Item then
            local link = GetLootSlotLink(slotIndex)
            local _, _, quantity = GetLootSlotInfo(slotIndex)
            if link then
                count = count + 1
                local sellPrice = select(11, C_Item.GetItemInfo(link))
                value = value + (sellPrice or 0) * (quantity or 1)
            end
        end
    end
    return value, count, anyLeft
end

local function UpdateBar()
    if not bar then
        return
    end
    if not (isLooting and IsBarEnabled() and LootFrame:IsShown()) then
        bar:Hide()
        return
    end
    local settings = ns.charDb
    local value, count, anyLeft = GetRemainingItems()

    bar.Value:SetShown(settings.lootWindowValue)
    bar.Value:SetText(format(L["LOOT_WINDOW_VALUE"], GetMoneyString(value, true)))

    local free = GetFreeBagSlots()
    bar.Bags:SetShown(settings.lootWindowBagSpace)
    bar.Bags:SetText(format(L["LOOT_WINDOW_BAG_SPACE"], free))
    if free < count then
        bar.Bags:SetTextColor(RED_FONT_COLOR:GetRGB())
    else
        bar.Bags:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    end

    bar.LootAll:SetShown(settings.lootWindowLootAll)
    bar.LootAll:SetEnabled(anyLeft)

    -- Without the value, the bag space moves up.
    bar.Bags:ClearAllPoints()
    if settings.lootWindowValue then
        bar.Bags:SetPoint("TOPLEFT", bar.Value, "BOTTOMLEFT", 0, -4)
    else
        bar.Bags:SetPoint("LEFT", BAR_PADDING, 0)
    end
    bar:Show()
end

local function LootAll()
    if C_LootFrame and C_LootFrame.TryAutoLoot then
        C_LootFrame.TryAutoLoot()
        return
    end
    for slotIndex = GetNumLootItems(), 1, -1 do
        LootSlot(slotIndex)
    end
end

-- A child of LootFrame below it, so it moves and hides with the window.
local function CreateBar()
    bar = CreateFrame("Frame", nil, LootFrame, "BackdropTemplate")
    bar:SetHeight(BAR_HEIGHT)
    bar:SetPoint("TOPLEFT", LootFrame, "BOTTOMLEFT", 0, -BAR_GAP)
    bar:SetPoint("TOPRIGHT", LootFrame, "BOTTOMRIGHT", 0, -BAR_GAP)
    bar:SetBackdrop(BACKDROP)
    bar:SetBackdropColor(0, 0, 0, 0.85)
    bar:SetBackdropBorderColor(0.4, 0.4, 0.4)
    bar:Hide()

    bar.LootAll = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    bar.LootAll:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    bar.LootAll:SetPoint("RIGHT", -BAR_PADDING, 0)
    bar.LootAll:SetText(L["LOOT_WINDOW_LOOT_ALL"])
    bar.LootAll:SetScript("OnClick", LootAll)

    bar.Value = bar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    bar.Value:SetPoint("TOPLEFT", BAR_PADDING, -BAR_PADDING)
    bar.Value:SetPoint("RIGHT", bar.LootAll, "LEFT", -4, 0)
    bar.Value:SetJustifyH("LEFT")
    bar.Value:SetWordWrap(false)

    bar.Bags = bar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    bar.Bags:SetJustifyH("LEFT")
end

-- Called by the options after a change.
function LootWindow:Refresh()
    UpdateElements()
    UpdateBar()
end

function LootWindow:IsEnabled(key)
    return ns.charDb[key]
end

function LootWindow:SetEnabled(key, enabled)
    ns.charDb[key] = enabled
    self:Refresh()
end

function LootWindow:OnEnable()
    if not (LootFrame and LootFrame.ScrollBox) then
        ns:Debug("LootFrame not found, the loot window is not improved.")
        return
    end
    CreateBar()
    ScrollUtil.AddInitializedFrameCallback(LootFrame.ScrollBox, function(_, frame)
        UpdateElement(frame)
    end, LootWindow, false)

    ns:RegisterEvent("LOOT_OPENED", function()
        isLooting = true
        wipe(clearedSlots)
        UpdateBar()
    end)
    ns:RegisterEvent("LOOT_CLOSED", function()
        isLooting = false
        UpdateBar()
    end)
    ns:RegisterEvent("LOOT_SLOT_CLEARED", function(_, slotIndex)
        clearedSlots[slotIndex] = true
        UpdateBar()
    end)
    ns:RegisterEvent("LOOT_SLOT_CHANGED", function()
        if isLooting then
            UpdateElements()
            UpdateBar()
        end
    end)
    ns:RegisterEvent("BAG_UPDATE_DELAYED", function()
        if isLooting then
            UpdateBar()
        end
    end)
    ns:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function()
        if isLooting then
            UpdateElements()
        end
    end)
end
