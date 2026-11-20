local _, ns = ...
local L = ns.L

-- Keeps what the character looted, per character and until it is reset ("/gryphonloot log reset",
-- the options, or on each login if ns.charDb.lootLogResetOnLogin is set):
-- the items with their count, newest first, the money and the vendor value of the items. A small
-- window shows it ("/gryphonloot log"); recording can be turned off ("/gryphonloot log off").
--
-- Items come from the own loot messages in chat (LOOT_ITEM_SELF, LOOT_ITEM_SELF_MULTIPLE), so won
-- rolls count as well. Chat messages may be secret values during encounters; those are skipped.
-- Money is the gain of GetMoney() while the loot window is open, which includes the share of the
-- group.
--
-- Position and size of the window are saved per Edit Mode layout in ns.db.lootLog.layouts. In Edit
-- Mode the window is shown while recording is on, so it can be placed.
local LootLog = ns:RegisterModule("LootLog")

local LibEditMode = LibStub("LibEditMode")

local DEFAULT_POSITION = { point = "CENTER", x = 300, y = 0 }
local LAYOUT_DEFAULTS = { width = 260, height = 240 }
local MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT = 180, 120, 600, 800
local WINDOW_PADDING, WINDOW_HEADER = 8, 44
local SCROLL_BAR_SPACE = 24
local ROW_HEIGHT, ICON_SIZE = 18, 16
local RESIZE_HANDLE_SIZE = 32
-- The oldest item goes when a new one does not fit.
local MAX_ITEMS = 200
local BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local window, scrollFrame, content
local rows = {}
local isEditing = false
local isLooting = false
local lastMoney
local lootPatterns

-- A Lua pattern for a global format string: %s becomes the link, %d the count.
local function ToPattern(formatString)
    local pattern = formatString:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
    pattern = pattern:gsub("%%%%s", "(.+)"):gsub("%%%%d", "(%%d+)")
    return "^" .. pattern .. "$"
end

-- The message with a count first, it would also match the other one.
local function GetLootPatterns()
    if not lootPatterns then
        lootPatterns = {}
        if LOOT_ITEM_SELF_MULTIPLE then
            lootPatterns[#lootPatterns + 1] = ToPattern(LOOT_ITEM_SELF_MULTIPLE)
        end
        if LOOT_ITEM_SELF then
            lootPatterns[#lootPatterns + 1] = ToPattern(LOOT_ITEM_SELF)
        end
    end
    return lootPatterns
end

local function GetData()
    return ns.charDb.lootLogData
end

local function GetLayouts()
    return ns.db.lootLog.layouts
end

local function GetLayout(layoutName)
    layoutName = layoutName or LibEditMode:GetActiveLayoutName()
    if not layoutName then
        return LAYOUT_DEFAULTS
    end
    local layout = ns.ApplyDefaults(GetLayouts()[layoutName] or {}, LAYOUT_DEFAULTS)
    GetLayouts()[layoutName] = layout
    return layout
end

local function GetItemValue(entry)
    local sellPrice = select(11, C_Item.GetItemInfo(entry.link))
    return (sellPrice or 0) * entry.count
end

local function HideTooltip()
    GameTooltip:Hide()
end

local function GetRow(index)
    local row = rows[index]
    if row then
        return row
    end
    row = CreateFrame("Button", nil, content)
    row:SetHeight(ROW_HEIGHT)
    row.Icon = row:CreateTexture(nil, "ARTWORK")
    row.Icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.Icon:SetPoint("LEFT")
    row.Value = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.Value:SetPoint("RIGHT")
    row.Name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.Name:SetPoint("LEFT", row.Icon, "RIGHT", 4, 0)
    row.Name:SetPoint("RIGHT", row.Value, "LEFT", -6, 0)
    row.Name:SetJustifyH("LEFT")
    row.Name:SetWordWrap(false)
    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", HideTooltip)
    -- Shift-click links the item in chat.
    row:SetScript("OnClick", function(self)
        if IsModifiedClick() then
            HandleModifiedItemClick(self.link)
        end
    end)
    rows[index] = row
    return row
end

local function RefreshWindow()
    if not window then
        return
    end
    local settings = ns.charDb
    local shown = settings.lootLogShown or (isEditing and settings.lootLog)
    if not shown then
        window:Hide()
        return
    end
    local data = GetData()
    local value = 0
    local index = 0
    for i = #data.items, 1, -1 do
        local entry = data.items[i]
        index = index + 1
        local row = GetRow(index)
        local itemValue = GetItemValue(entry)
        value = value + itemValue
        row.link = entry.link
        row.Icon:SetTexture(C_Item.GetItemIconByID(entry.link))
        row.Name:SetText(entry.count > 1 and format("%s x%d", entry.link, entry.count) or entry.link)
        row.Value:SetText(itemValue > 0 and GetMoneyString(itemValue, true) or "")
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", 0, -(index - 1) * ROW_HEIGHT)
        row:Show()
    end
    for i = index + 1, #rows do
        rows[i]:Hide()
    end
    content:SetHeight(math.max(index * ROW_HEIGHT, 1))
    window.Empty:SetShown(index == 0)
    window.Totals:SetText(format(L["LOOT_LOG_TOTALS"], GetMoneyString(data.money, true), GetMoneyString(value, true)))
    window:Show()
end

local function AddItem(link, count)
    local items = GetData().items
    -- The same item moves to the top with the new count.
    for i, entry in ipairs(items) do
        if entry.link == link then
            table.remove(items, i)
            entry.count = entry.count + count
            items[#items + 1] = entry
            RefreshWindow()
            return
        end
    end
    items[#items + 1] = { link = link, count = count }
    if #items > MAX_ITEMS then
        table.remove(items, 1)
    end
    RefreshWindow()
end

local function OnLootMessage(_, message)
    if not ns.charDb.lootLog or issecretvalue(message) then
        return
    end
    for _, pattern in ipairs(GetLootPatterns()) do
        local link, count = message:match(pattern)
        if link then
            AddItem(link, tonumber(count) or 1)
            return
        end
    end
end

local function OnMoneyChanged()
    local money = GetMoney()
    if isLooting and ns.charDb.lootLog and lastMoney and money > lastMoney then
        GetData().money = GetData().money + money - lastMoney
        RefreshWindow()
    end
    lastMoney = money
end

local function OnDragStart()
    if not LibEditMode:IsInEditMode() then
        -- LibEditMode turns movable off again when it leaves Edit Mode with the window selected.
        window:SetMovable(true)
        window:StartMoving()
        window.isMoving = true
    end
end

-- The position of the top left corner: changing the size then keeps the window in place.
local function SavePosition()
    local layout = GetLayout()
    if layout ~= LAYOUT_DEFAULTS then
        layout.point, layout.x, layout.y = "TOPLEFT", window:GetLeft(), window:GetTop() - UIParent:GetHeight()
    end
end

local function OnDragStop()
    if window.isMoving then
        window.isMoving = false
        window:StopMovingOrSizing()
        SavePosition()
    end
end

local function ApplyLayout()
    local layout = GetLayout()
    local position = layout.point and layout or DEFAULT_POSITION
    window:ClearAllPoints()
    window:SetPoint(position.point, UIParent, position.point, position.x, position.y)
    window:SetSize(layout.width, layout.height)
    RefreshWindow()
end

local function OnResizeStart(button, mouseButton)
    if mouseButton == "LeftButton" then
        -- StartSizing("BOTTOMRIGHT") only keeps the top left corner in place if the window is
        -- anchored there.
        local left, top = window:GetLeft(), window:GetTop()
        window:ClearAllPoints()
        window:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        button:SetButtonState("PUSHED", true)
        window:StartSizing("BOTTOMRIGHT")
        window.isResizing = true
    end
end

local function OnResizeStop(button, mouseButton)
    if mouseButton ~= "LeftButton" or not window.isResizing then
        return
    end
    window.isResizing = false
    button:SetButtonState("NORMAL", false)
    window:StopMovingOrSizing()
    local layout = GetLayout()
    if layout ~= LAYOUT_DEFAULTS then
        layout.width, layout.height = floor(window:GetWidth() + 0.5), floor(window:GetHeight() + 0.5)
    end
    SavePosition()
    ApplyLayout()
end

local function CreateWindow()
    -- Stays in the MEDIUM strata, so the selection of Edit Mode can be clicked.
    window = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    window:SetClampedToScreen(true)
    window:SetResizable(true)
    window:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", OnDragStart)
    window:SetScript("OnDragStop", OnDragStop)
    window:SetBackdrop(BACKDROP)
    window:SetBackdropColor(0, 0, 0, 0.85)
    window:SetBackdropBorderColor(0.4, 0.4, 0.4)
    window:Hide()

    window.Title = window:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    window.Title:SetPoint("TOPLEFT", WINDOW_PADDING, -WINDOW_PADDING)
    window.Title:SetText(L["LOOT_LOG_TITLE"])

    window.Totals = window:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    window.Totals:SetPoint("TOPLEFT", window.Title, "BOTTOMLEFT", 0, -6)
    window.Totals:SetPoint("RIGHT", -WINDOW_PADDING, 0)
    window.Totals:SetJustifyH("LEFT")
    window.Totals:SetWordWrap(false)

    -- Not UIPanelCloseButton: its script goes through the panel manager, blocked in combat.
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButtonNoScripts")
    close:SetSize(22, 22)
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function()
        LootLog:SetShown(false)
    end)

    scrollFrame = CreateFrame("ScrollFrame", nil, window, "ScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", WINDOW_PADDING, -WINDOW_HEADER)
    scrollFrame:SetPoint("BOTTOMRIGHT", -SCROLL_BAR_SPACE, WINDOW_PADDING)
    scrollFrame.ScrollBar:SetHideIfUnscrollable(true)
    content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)
    window:SetScript("OnSizeChanged", function(_, width)
        content:SetWidth(width - WINDOW_PADDING - SCROLL_BAR_SPACE)
    end)

    window.Empty = window:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    window.Empty:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT")
    window.Empty:SetText(L["LOOT_LOG_EMPTY"])

    local resize = CreateFrame("Button", nil, window)
    resize:SetFrameStrata("DIALOG")
    resize:SetSize(RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE)
    resize:SetPoint("BOTTOMRIGHT", 4, -4)
    resize:SetNormalAtlas("damagemeters-scalehandle")
    resize:SetHighlightAtlas("damagemeters-scalehandle-hover")
    resize:SetPushedAtlas("damagemeters-scalehandle-pressed")
    resize:SetScript("OnMouseDown", OnResizeStart)
    resize:SetScript("OnMouseUp", OnResizeStop)
end

-- LibEditMode callback after the window was dragged, moved with the arrow keys or reset.
local function OnPositionChanged(_, layoutName, point, x, y)
    if layoutName then
        local layout = GetLayout(layoutName)
        layout.point, layout.x, layout.y = point, x, y
        ApplyLayout()
    end
end

local function RegisterEditMode()
    window.editModeName = L["LOOT_LOG_TITLE"]
    LibEditMode:AddFrame(window, OnPositionChanged, DEFAULT_POSITION, L["LOOT_LOG_TITLE"])
    LibEditMode:RegisterCallback("layout", ApplyLayout)
    LibEditMode:RegisterCallback("enter", function()
        isEditing = true
        RefreshWindow()
    end)
    LibEditMode:RegisterCallback("exit", function()
        isEditing = false
        RefreshWindow()
    end)
    LibEditMode:RegisterCallback("create", function(layoutName, _, sourceLayoutName)
        local source = sourceLayoutName and GetLayouts()[sourceLayoutName]
        if source then
            GetLayouts()[layoutName] = CopyTable(source)
        end
    end)
    LibEditMode:RegisterCallback("rename", function(oldLayoutName, newLayoutName)
        GetLayouts()[newLayoutName] = GetLayouts()[oldLayoutName]
        GetLayouts()[oldLayoutName] = nil
    end)
    LibEditMode:RegisterCallback("delete", function(layoutName)
        GetLayouts()[layoutName] = nil
    end)
end

function LootLog:IsEnabled()
    return ns.charDb.lootLog
end

function LootLog:SetEnabled(enabled)
    ns.charDb.lootLog = enabled
    RefreshWindow()
end

function LootLog:IsShown()
    return ns.charDb.lootLogShown
end

function LootLog:SetShown(shown)
    ns.charDb.lootLogShown = shown
    RefreshWindow()
end

-- silent: no chat message (the automatic reset at login uses ns:Notify instead).
function LootLog:Reset(silent)
    local data = GetData()
    wipe(data.items)
    data.money = 0
    RefreshWindow()
    if not silent then
        ns:Print(L["LOOT_LOG_RESET_DONE"])
    end
end

function LootLog:IsResetOnLogin()
    return ns.charDb.lootLogResetOnLogin
end

function LootLog:SetResetOnLogin(enabled)
    ns.charDb.lootLogResetOnLogin = enabled
end

ns:RegisterCommand("log", function(args)
    local value = args:lower()
    if value == "" then
        LootLog:SetShown(not LootLog:IsShown())
        return
    elseif value == "reset" then
        LootLog:Reset()
        return
    elseif value == "on" then
        LootLog:SetEnabled(true)
    elseif value == "off" then
        LootLog:SetEnabled(false)
    else
        ns:Print(L["HELP_LOOT_LOG"])
        return
    end
    ns:Print(LootLog:IsEnabled() and L["LOOT_LOG_ON"] or L["LOOT_LOG_OFF"])
end, { L["HELP_LOOT_LOG"] })

function LootLog:OnEnable()
    CreateWindow()
    RegisterEditMode()
    ApplyLayout()

    lastMoney = GetMoney()
    -- PLAYER_LOGIN also comes after /reload, PLAYER_ENTERING_WORLD tells them apart.
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin)
        local data = GetData()
        if isInitialLogin and ns.charDb.lootLogResetOnLogin and (#data.items > 0 or data.money > 0) then
            LootLog:Reset(true)
            ns:Notify(L["LOOT_LOG_RESET_AT_LOGIN"])
        end
    end)
    ns:RegisterEvent("CHAT_MSG_LOOT", OnLootMessage)
    ns:RegisterEvent("PLAYER_MONEY", OnMoneyChanged)
    ns:RegisterEvent("LOOT_OPENED", function()
        isLooting = true
        lastMoney = GetMoney()
    end)
    ns:RegisterEvent("LOOT_CLOSED", function()
        isLooting = false
    end)
    -- Item names and sell prices of the saved items may arrive later.
    ns:RegisterEvent("GET_ITEM_INFO_RECEIVED", function()
        if window:IsShown() then
            RefreshWindow()
        end
    end)
end
