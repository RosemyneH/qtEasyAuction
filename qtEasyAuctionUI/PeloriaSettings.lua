local T = {}
_G.qtEasyAuctionSettings = T

local ROW_MAX = 14
local ROW_H = 28
local offset = 0

local function DB()
    qtEasyAuctionDB = qtEasyAuctionDB or {}
    qtEasyAuctionDB.hiddenSellers = qtEasyAuctionDB.hiddenSellers or {}
    if qtEasyAuctionDB.bulkBuyVersion ~= 1 then
        if qtEasyAuctionDB.bulkBuyDelay == nil or qtEasyAuctionDB.bulkBuyDelay == 0.10 then
            qtEasyAuctionDB.bulkBuyDelay = 0.05
        end
        qtEasyAuctionDB.bulkBuyStep = nil
        qtEasyAuctionDB.bulkBuyVersion = 1
    end
    qtEasyAuctionDB.bulkBuyDelay = tonumber(qtEasyAuctionDB.bulkBuyDelay) or 0.05
    if qtEasyAuctionDB.confirmMassBuy == nil then qtEasyAuctionDB.confirmMassBuy = true end
    if qtEasyAuctionDB.hideDuplicateDeals == nil then qtEasyAuctionDB.hideDuplicateDeals = true end
    if qtEasyAuctionDB.hideLowGoldValueDeals == nil then
        qtEasyAuctionDB.hideLowGoldValueDeals = qtEasyAuctionDB.hideLowValueDeals
        if qtEasyAuctionDB.hideLowGoldValueDeals == nil then qtEasyAuctionDB.hideLowGoldValueDeals = true end
    end
    qtEasyAuctionDB.minimumGoldValue = math.max(
        0, tonumber(qtEasyAuctionDB.minimumGoldValue or qtEasyAuctionDB.minimumDealGold) or 30)
    qtEasyAuctionDB.hideLowValueDeals = nil
    qtEasyAuctionDB.minimumDealGold = nil
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
    local visible = ROW_MAX
    if T.list and T.list:GetHeight() and T.list:GetHeight() > 0 then
        visible = math.max(1, math.min(ROW_MAX, math.floor(T.list:GetHeight() / ROW_H)))
    end
    local maxOffset = math.max(0, #hidden - visible)
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
    if T.lowValue then
        if T.lowValue.SetOn then T.lowValue:SetOn(DB().hideLowGoldValueDeals)
        else T.lowValue:SetChecked(DB().hideLowGoldValueDeals) end
    end
    if T.minimumGoldValue and not T.minimumGoldValue:HasFocus() then
        T.minimumGoldValue:SetText(tostring(DB().minimumGoldValue))
    end
    if T.font then
        local Skin = _G.qtEasyAuctionSkin
        local fontName = Skin and Skin.FontName and Skin.FontName() or "Default"
        if T.font.SetValue then T.font:SetValue(fontName)
        else UIDropDownMenu_SetText(T.font, fontName) end
    end
    if T.fontSize then
        local Skin = _G.qtEasyAuctionSkin
        local scale = Skin and Skin.FontScale and Skin.FontScale() or 1
        T.fontSize:SetText(string.format("%d%%", math.floor(scale * 100 + 0.5)))
    end
    for i = 1, ROW_MAX do
        local row = T.rows[i]
        local seller = hidden[offset + i]
        if seller and i <= visible then
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
    detail:SetText("Send one listing each interval; results continue arriving in the background.")
    T.detail = detail

    local delayLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    delayLabel:SetPoint("TOPLEFT", detail, "BOTTOMLEFT", 0, -18)
    delayLabel:SetText("Buy interval")
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

    local dealsTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dealsTitle:SetPoint("TOPLEFT", 18, -108)
    dealsTitle:SetText("Deals filtering")
    T.dealsTitle = dealsTitle

    local lowValue
    if Skin and Skin.Chip then
        lowValue = Skin.Chip(panel, 164, 28, "Hide Gold value under", true)
        lowValue:SetPoint("LEFT", dealsTitle, "RIGHT", 18, 0)
        lowValue.OnToggle = function(self, on)
            DB().hideLowGoldValueDeals = on and true or false
            self:SetOn(DB().hideLowGoldValueDeals)
            RefreshDeals()
        end
        lowValue:SetOn(DB().hideLowGoldValueDeals)
    else
        lowValue = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        lowValue:SetPoint("LEFT", dealsTitle, "RIGHT", 18, 0)
        local label = lowValue:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", lowValue, "RIGHT", 2, 0)
        label:SetText("Hide Gold value under")
        lowValue:SetChecked(DB().hideLowGoldValueDeals)
        lowValue:SetScript("OnClick", function(self)
            DB().hideLowGoldValueDeals = self:GetChecked() and true or false
            RefreshDeals()
        end)
        lowValue.label = label
    end
    T.lowValue = lowValue

    local minimumWrap
    local minimumGoldValue
    if Skin and Skin.Field then
        minimumWrap = Skin.Field(panel, 72, 28, "qtEasyAuctionMinimumGoldValue")
        minimumWrap:SetPoint("LEFT", lowValue, "RIGHT", 8, 0)
        minimumGoldValue = minimumWrap.box
    else
        minimumGoldValue = CreateFrame("EditBox", "qtEasyAuctionMinimumGoldValue", panel, "InputBoxTemplate")
        minimumGoldValue:SetWidth(64)
        minimumGoldValue:SetHeight(24)
        minimumGoldValue:SetPoint("LEFT", lowValue, "RIGHT", 8, 0)
        minimumGoldValue:SetAutoFocus(false)
    end
    minimumGoldValue:SetMaxLetters(9)
    minimumGoldValue:SetText(tostring(DB().minimumGoldValue))
    local function SaveMinimumGoldValue(self)
        local value = tonumber(self:GetText())
        if value then DB().minimumGoldValue = math.max(0, math.min(100000000, value)) end
        self:SetText(tostring(DB().minimumGoldValue))
        RefreshDeals()
    end
    minimumGoldValue:SetScript("OnEnterPressed", function(self) SaveMinimumGoldValue(self); self:ClearFocus() end)
    minimumGoldValue:SetScript("OnEditFocusLost", SaveMinimumGoldValue)
    minimumGoldValue:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    T.minimumGoldValue = minimumGoldValue
    T.minimumWrap = minimumWrap

    local minimumValueLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    minimumValueLabel:SetPoint("LEFT", minimumWrap or minimumGoldValue, "RIGHT", 8, 0)
    minimumValueLabel:SetText("score / gold")
    T.minimumValueLabel = minimumValueLabel

    local appearanceTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    appearanceTitle:SetPoint("TOPLEFT", 18, -154)
    appearanceTitle:SetText("Appearance")
    T.appearanceTitle = appearanceTitle

    local fontLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fontLabel:SetPoint("TOPLEFT", 18, -192)
    fontLabel:SetText("Font")
    T.fontLabel = fontLabel

    local font
    if Skin and Skin.Dropdown then
        font = Skin.Dropdown(
            panel,
            210,
            28,
            Skin.FontName(),
            function() return Skin.FontNames() end,
            function(fontName)
                Skin.SetFont(fontName)
                Paint()
            end)
        font:SetPoint("LEFT", fontLabel, "RIGHT", 12, 0)
    else
        font = CreateFrame("Frame", "qtEasyAuctionFontDropdown", panel, "UIDropDownMenuTemplate")
        font:SetPoint("LEFT", fontLabel, "RIGHT", 0, -2)
        UIDropDownMenu_SetWidth(font, 180)
        UIDropDownMenu_JustifyText(font, "LEFT")
        UIDropDownMenu_Initialize(font, function(_, level)
            if level ~= 1 or not Skin or not Skin.FontNames or not Skin.SetFont then return end
            local names = Skin.FontNames()
            local current = Skin.FontName()
            for i = 1, #names do
                local fontName = names[i]
                local info = UIDropDownMenu_CreateInfo()
                info.text = fontName
                info.checked = fontName == current
                info.func = function()
                    Skin.SetFont(fontName)
                    UIDropDownMenu_SetText(font, fontName)
                    CloseDropDownMenus()
                    Paint()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        UIDropDownMenu_SetText(font, Skin and Skin.FontName and Skin.FontName() or "Default")
    end
    T.font = font

    local sizeLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sizeLabel:SetPoint("LEFT", font, "RIGHT", 2, 2)
    sizeLabel:SetText("Size")
    T.sizeLabel = sizeLabel

    local smaller = Cute(panel, 28, 28, "−")
    smaller:SetPoint("LEFT", sizeLabel, "RIGHT", 8, 0)
    local fontSize = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fontSize:SetPoint("LEFT", smaller, "RIGHT", 8, 0)
    fontSize:SetWidth(44)
    fontSize:SetJustifyH("CENTER")
    local larger = Cute(panel, 28, 28, "+")
    larger:SetPoint("LEFT", fontSize, "RIGHT", 8, 0)
    smaller:SetScript("OnClick", function()
        if Skin and Skin.SetFontScale then Skin.SetFontScale((Skin.FontScale and Skin.FontScale() or 1) - 0.05) end
        Paint()
    end)
    larger:SetScript("OnClick", function()
        if Skin and Skin.SetFontScale then Skin.SetFontScale((Skin.FontScale and Skin.FontScale() or 1) + 0.05) end
        Paint()
    end)
    T.smaller, T.fontSize, T.larger = smaller, fontSize, larger

    local resetWindow = Cute(panel, 112, 28, "Reset window")
    resetWindow:SetPoint("TOPRIGHT", -18, -178)
    resetWindow:SetScript("OnClick", function()
        if Skin and Skin.ResetWindow then Skin.ResetWindow() end
    end)
    T.resetWindow = resetWindow

    local hiddenTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    hiddenTitle:SetPoint("TOPLEFT", 18, -240)
    hiddenTitle:SetText("Hidden sellers")
    T.hiddenTitle = hiddenTitle

    local hiddenCount = panel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    hiddenCount:SetPoint("LEFT", hiddenTitle, "RIGHT", 12, 0)
    T.hiddenCount = hiddenCount

    local clear = Cute(panel, 100, 28, "Show all")
    clear:SetPoint("TOPRIGHT", -18, -232)
    clear:SetScript("OnClick", function()
        DB().hiddenSellers = {}
        offset = 0
        RefreshDeals()
        Paint()
    end)
    T.clear = clear

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", hiddenTitle, "BOTTOMLEFT", 0, -6)
    hint:SetText("Alt-right-click a deal to confirm hiding every listing from that seller.")
    T.hint = hint

    local list = CreateFrame("Frame", nil, panel)
    list:SetPoint("TOPLEFT", 18, -290)
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
    bar:SetPoint("TOPRIGHT", -12, -290)
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
    local labels = { T.title, T.dealsTitle, T.appearanceTitle, T.hiddenTitle }
    for i = 1, #labels do
        if labels[i] then labels[i]:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3]) end
    end
    local muted = { T.detail, T.seconds, T.minimumValueLabel, T.hiddenCount, T.hint }
    for i = 1, #muted do
        if muted[i] then muted[i]:SetTextColor(pal.mute[1], pal.mute[2], pal.mute[3]) end
    end
    if T.delayLabel then T.delayLabel:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3]) end
    if T.fontLabel then T.fontLabel:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3]) end
    if T.sizeLabel then T.sizeLabel:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3]) end
    if T.fontSize then T.fontSize:SetTextColor(pal.gold[1], pal.gold[2], pal.gold[3]) end
    if T.confirm and T.confirm.PaintTheme then T.confirm:PaintTheme() end
    if T.duplicates and T.duplicates.PaintTheme then T.duplicates:PaintTheme() end
    if T.lowValue and T.lowValue.PaintTheme then T.lowValue:PaintTheme() end
    for i = 1, #(T.rows or {}) do
        local tint = (i % 2 == 0) and pal.rowA or pal.rowB
        T.rows[i].bg:SetVertexColor(tint[1], tint[2], tint[3], tint[4] or 1)
    end
    if Skin and Skin.ApplyTypography then Skin.ApplyTypography(T.panel) end
end

function T.OnShown()
    CreatePanel()
    if T.panel then T.panel:Show() end
    T.ApplySkin()
    Paint()
end

function T.RefreshLayout()
    Paint()
end
