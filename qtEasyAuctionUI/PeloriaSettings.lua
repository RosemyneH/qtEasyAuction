local T = {}
_G.qtEasyAuctionSettings = T

local ROW_MAX = 14
local ROW_H = 28
local offset = 0

local function DB()
    qtEasyAuctionDB = qtEasyAuctionDB or {}
    qtEasyAuctionDB.hiddenSellers = qtEasyAuctionDB.hiddenSellers or {}
    qtEasyAuctionDB.bulkBuyDelay = tonumber(qtEasyAuctionDB.bulkBuyDelay) or 0.10
    if qtEasyAuctionDB.confirmMassBuy == nil then qtEasyAuctionDB.confirmMassBuy = true end
    if qtEasyAuctionDB.hideDuplicateDeals == nil then qtEasyAuctionDB.hideDuplicateDeals = true end
    return qtEasyAuctionDB
end

local function Hidden()
    local out = {}
    for key, name in pairs(DB().hiddenSellers) do
        out[#out + 1] = { key = key, name = tostring(name or key) }
    end
    table.sort(out, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
    return out
end

local function RefreshDeals()
    local deals = _G.qtEasyAuctionDeals
    if deals and deals.RefreshSellerFilter then deals.RefreshSellerFilter() end
end

local function Paint()
    if not T.rows then return end
    local hidden = Hidden()
    local maxOffset = math.max(0, #hidden - ROW_MAX)
    offset = math.max(0, math.min(offset, maxOffset))
    if T.bar then
        T.bar:SetMinMaxValues(0, maxOffset)
        T.bar:SetValue(offset)
        if maxOffset > 0 then T.bar:Show() else T.bar:Hide() end
    end
    if T.hiddenCount then
        T.hiddenCount:SetText(#hidden == 1 and "1 hidden seller" or (#hidden .. " hidden sellers"))
    end
    if T.confirm then
        if T.confirm.SetOn then T.confirm:SetOn(DB().confirmMassBuy)
        else T.confirm:SetChecked(DB().confirmMassBuy) end
    end
    if T.duplicates then
        if T.duplicates.SetOn then T.duplicates:SetOn(DB().hideDuplicateDeals)
        else T.duplicates:SetChecked(DB().hideDuplicateDeals) end
    end
    for i = 1, ROW_MAX do
        local row = T.rows[i]
        local seller = hidden[offset + i]
        if seller then
            row.key = seller.key
            row.name:SetText(seller.name)
            row:Show()
        else
            row:Hide()
        end
    end
end

function T.Refresh()
    Paint()
end

local function Cute(parent, w, h, text)
    local Skin = _G.qtEasyAuctionSkin
    if Skin and Skin.CuteButton then return Skin.CuteButton(parent, w, h, text) end
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(w)
    button:SetHeight(h)
    button:SetText(text)
    return button
end

local function CreatePanel()
    local Skin = _G.qtEasyAuctionSkin
    if Skin and Skin.Create then Skin.Create() end
    local page = Skin and Skin.pages and Skin.pages.settings
    if not page then return end
    if T.panel then
        T.panel:Show()
        Paint()
        return
    end

    local panel = CreateFrame("Frame", "qtEasyAuctionSettingsPanel", page)
    panel:SetAllPoints(page)
    panel:EnableMouse(true)
    T.panel = panel

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -18)
    title:SetText("Bulk buying")
    T.title = title

    local detail = panel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    detail:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    detail:SetWidth(520)
    detail:SetJustifyH("LEFT")
    detail:SetText("Purchases wait for the server to confirm each listing before sending the next.")
    T.detail = detail

    local delayLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    delayLabel:SetPoint("TOPLEFT", detail, "BOTTOMLEFT", 0, -18)
    delayLabel:SetText("Delay after confirmation")
    T.delayLabel = delayLabel

    local delayWrap
    local delay
    if Skin and Skin.Field then
        delayWrap = Skin.Field(panel, 72, 28, "qtEasyAuctionBulkDelay")
        delayWrap:SetPoint("LEFT", delayLabel, "RIGHT", 12, 0)
        delay = delayWrap.box
    else
        delay = CreateFrame("EditBox", "qtEasyAuctionBulkDelay", panel, "InputBoxTemplate")
        delay:SetWidth(64)
        delay:SetHeight(24)
        delay:SetPoint("LEFT", delayLabel, "RIGHT", 12, 0)
        delay:SetAutoFocus(false)
    end
    delay:SetMaxLetters(5)
    delay:SetText(string.format("%.2f", DB().bulkBuyDelay))
    local function SaveDelay(self)
        local value = tonumber(self:GetText())
        if value then DB().bulkBuyDelay = math.max(0, math.min(2, value)) end
        self:SetText(string.format("%.2f", DB().bulkBuyDelay))
    end
    delay:SetScript("OnEnterPressed", function(self) SaveDelay(self); self:ClearFocus() end)
    delay:SetScript("OnEditFocusLost", SaveDelay)
    delay:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    T.delay = delay
    T.delayWrap = delayWrap

    local seconds = panel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    seconds:SetPoint("LEFT", delayWrap or delay, "RIGHT", 8, 0)
    seconds:SetText("seconds")
    T.seconds = seconds

    local confirm
    if Skin and Skin.Chip then
        confirm = Skin.Chip(panel, 164, 28, "Confirm mass buys", true)
        confirm:SetPoint("LEFT", seconds, "RIGHT", 20, 0)
        confirm.OnToggle = function(self, on)
            DB().confirmMassBuy = on and true or false
            self:SetOn(DB().confirmMassBuy)
        end
        confirm:SetOn(DB().confirmMassBuy)
    else
        confirm = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        confirm:SetPoint("LEFT", seconds, "RIGHT", 20, 0)
        local label = confirm:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", confirm, "RIGHT", 2, 0)
        label:SetText("Confirm mass buys")
        confirm:SetChecked(DB().confirmMassBuy)
        confirm:SetScript("OnClick", function(self)
            DB().confirmMassBuy = self:GetChecked() and true or false
        end)
        confirm.label = label
    end
    T.confirm = confirm

    local duplicates
    if Skin and Skin.Chip then
        duplicates = Skin.Chip(panel, 190, 28, "Hide duplicate item levels", true)
        duplicates:SetPoint("LEFT", confirm, "RIGHT", 8, 0)
        duplicates.OnToggle = function(self, on)
            DB().hideDuplicateDeals = on and true or false
            self:SetOn(DB().hideDuplicateDeals)
            RefreshDeals()
        end
        duplicates:SetOn(DB().hideDuplicateDeals)
    else
        duplicates = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        duplicates:SetPoint("LEFT", confirm, "RIGHT", 8, 0)
        local label = duplicates:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", duplicates, "RIGHT", 2, 0)
        label:SetText("Hide duplicate item levels")
        duplicates:SetChecked(DB().hideDuplicateDeals)
        duplicates:SetScript("OnClick", function(self)
            DB().hideDuplicateDeals = self:GetChecked() and true or false
            RefreshDeals()
        end)
        duplicates.label = label
    end
    T.duplicates = duplicates

    local hiddenTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    hiddenTitle:SetPoint("TOPLEFT", 18, -126)
    hiddenTitle:SetText("Hidden sellers")
    T.hiddenTitle = hiddenTitle

    local hiddenCount = panel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    hiddenCount:SetPoint("LEFT", hiddenTitle, "RIGHT", 12, 0)
    T.hiddenCount = hiddenCount

    local clear = Cute(panel, 100, 28, "Show all")
    clear:SetPoint("TOPRIGHT", -18, -118)
    clear:SetScript("OnClick", function()
        DB().hiddenSellers = {}
        offset = 0
        RefreshDeals()
        Paint()
    end)
    T.clear = clear

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", hiddenTitle, "BOTTOMLEFT", 0, -6)
    hint:SetText("Right-click a deal to hide every listing from that seller.")
    T.hint = hint

    local list = CreateFrame("Frame", nil, panel)
    list:SetPoint("TOPLEFT", 18, -176)
    list:SetPoint("BOTTOMRIGHT", -38, 12)
    T.list = list
    T.rows = {}
    for i = 1, ROW_MAX do
        local row = CreateFrame("Frame", nil, list)
        row:SetHeight(ROW_H)
        row:SetPoint("TOPLEFT", 0, -((i - 1) * ROW_H))
        row:SetPoint("TOPRIGHT", 0, -((i - 1) * ROW_H))
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.name:SetPoint("LEFT", 10, 0)
        row.name:SetPoint("RIGHT", -88, 0)
        row.name:SetJustifyH("LEFT")
        local show = Cute(row, 72, 22, "Show")
        show:SetPoint("RIGHT", -4, 0)
        show:SetScript("OnClick", function()
            if row.key then DB().hiddenSellers[row.key] = nil end
            RefreshDeals()
            Paint()
        end)
        row.show = show
        T.rows[i] = row
    end

    local bar = CreateFrame("Slider", "qtEasyAuctionSettingsBar", panel, "UIPanelScrollBarTemplate")
    bar:SetPoint("TOPRIGHT", -12, -176)
    bar:SetPoint("BOTTOMRIGHT", -12, 12)
    bar:SetValueStep(1)
    bar:SetScript("OnValueChanged", function(_, value)
        local nextOffset = math.floor((value or 0) + 0.5)
        if nextOffset == offset then return end
        offset = nextOffset
        Paint()
    end)
    T.bar = bar
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta)
        offset = offset - delta * 3
        Paint()
    end)
    panel:SetScript("OnShow", Paint)
    Paint()
end

function T.ApplySkin()
    local Skin = _G.qtEasyAuctionSkin
    local pal = Skin and Skin.C and Skin.C()
    if not pal then return end
    local labels = { T.title, T.hiddenTitle }
    for i = 1, #labels do
        if labels[i] then labels[i]:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3]) end
    end
    local muted = { T.detail, T.seconds, T.hiddenCount, T.hint }
    for i = 1, #muted do
        if muted[i] then muted[i]:SetTextColor(pal.mute[1], pal.mute[2], pal.mute[3]) end
    end
    if T.delayLabel then T.delayLabel:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3]) end
    if T.confirm and T.confirm.PaintTheme then T.confirm:PaintTheme() end
    if T.duplicates and T.duplicates.PaintTheme then T.duplicates:PaintTheme() end
    for i = 1, #(T.rows or {}) do
        local tint = (i % 2 == 0) and pal.rowA or pal.rowB
        T.rows[i].bg:SetVertexColor(tint[1], tint[2], tint[3], tint[4] or 1)
    end
end

function T.OnShown()
    CreatePanel()
    if T.panel then T.panel:Show() end
    T.ApplySkin()
    Paint()
end
