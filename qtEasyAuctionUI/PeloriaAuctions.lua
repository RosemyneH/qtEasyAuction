local A = {}
_G.qtEasyAuctionMine = A

local PREFIX = "PELAH"
local PAGE_CAP = 80
local ROW_MAX = 40
local ROW_H = 32
local ICON_SZ = 22
local UNLIST_W = 56
local TRIM_A, TRIM_B = 0.03, 0.97
local COL = {}

local listings, shown, offset, page, fetching
local fetchLeft, refreshAt
local cancelQ, cancelBusy, cancelAt, cancelTotal, cancelDoneAt
local pendingCancel, cancelledIds = {}, {}
local peekWrapped = {}
local status = ""
local sortKey, sortDesc = "name", true
local filterText = ""

local function TrimIcon(tex)
    if tex then tex:SetTexCoord(TRIM_A, TRIM_B, TRIM_A, TRIM_B) end
end

local function LayoutCols(width)
    width = tonumber(width) or 720
    if width < 400 then width = 400 end
    local inner = width - ICON_SZ - 10 - UNLIST_W - 10
    local spec = {
        { "name", 3.6 },
        { "mythic", 0.55 },
        { "price", 0.95 },
        { "time", 0.7 },
    }
    local sum = 0
    for i = 1, #spec do sum = sum + spec[i][2] end
    local x = ICON_SZ + 10
    COL.icon = 6
    for i = 1, #spec do
        local w = inner * spec[i][2] / sum
        COL[spec[i][1]] = x
        COL[spec[i][1] .. "W"] = w
        x = x + w
    end
end
LayoutCols(720)

local function Commas(n)
    local text = string.format("%.0f", n or 0)
    while true do
        local replaced
        text, replaced = string.gsub(text, "^(%-?%d+)(%d%d%d)", "%1,%2")
        if replaced == 0 then break end
    end
    return text
end

local function Compact(n)
    n = tonumber(n) or 0
    local a = math.abs(n)
    if a >= 1000000 then
        local x = n / 1000000
        if x == math.floor(x) then return tostring(x) .. "m" end
        return string.format("%.1fm", x)
    end
    if a >= 10000 then
        return string.format("%.0fk", n / 1000)
    end
    return Commas(n)
end

local function GoldText(copper)
    return Compact((tonumber(copper) or 0) / 10000) .. "g"
end

local function MythicTag(level)
    level = tonumber(level) or 0
    if level <= 0 then return "|cff555555—|r" end
    return "|cff66ff33+" .. Compact(level) .. "|r"
end

local function CleanQuery(s)
    s = tostring(s or "")
    s = string.gsub(s, "[%^~]", "")
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

local function Matches(e, q)
    if not q or q == "" then return true end
    local name = string.lower(e.name or "")
    if string.find(name, q, 1, true) then return true end
    local m = tonumber(e.mythic) or 0
    if m > 0 then
        local tag = "+" .. tostring(m)
        if q == tostring(m) or q == tag or string.find(tag, q, 1, true) then
            return true
        end
    end
    return false
end

local function RebuildShown()
    local q = string.lower(CleanQuery(filterText))
    shown = {}
    for i = 1, #(listings or {}) do
        if Matches(listings[i], q) then
            shown[#shown + 1] = listings[i]
        end
    end
end

local function TimeText(sec)
    sec = tonumber(sec) or 0
    if sec <= 0 then return "—" end
    if sec >= 86400 then return string.format("%dd", math.floor(sec / 86400 + 0.5)) end
    if sec >= 3600 then return string.format("%dh", math.floor(sec / 3600 + 0.5)) end
    if sec >= 60 then return string.format("%dm", math.floor(sec / 60 + 0.5)) end
    return string.format("%ds", sec)
end

local function ItemLink(entry, randProp)
    return string.format("item:%d:0:0:0:0:0:%d:0:80", entry or 0, randProp or 0)
end

local function SetStatus(text)
    status = text or ""
    if A.status then A.status:SetText(status) end
end

local function TotalCopper()
    local sum = 0
    for i = 1, #(listings or {}) do
        sum = sum + (listings[i].buyout or 0)
    end
    return sum
end

local function ApplySort()
    if not listings then return end
    local key, desc = sortKey or "name", sortDesc ~= false
    table.sort(listings, function(a, b)
        if key == "name" then
            local va = string.lower(a.name or "")
            local vb = string.lower(b.name or "")
            if va ~= vb then
                if desc then return va < vb end
                return va > vb
            end
            return (a.buyout or 0) > (b.buyout or 0)
        end
        local va, vb
        if key == "mythic" then
            va, vb = a.mythic or 0, b.mythic or 0
        elseif key == "time" then
            va, vb = a.timeLeft or 0, b.timeLeft or 0
        else
            va, vb = a.buyout or 0, b.buyout or 0
        end
        if va == vb then
            local na, nb = string.lower(a.name or ""), string.lower(b.name or "")
            if na ~= nb then return na < nb end
        end
        if desc then return va > vb end
        return va < vb
    end)
end

local function VisCount()
    if A.list and A.list:GetHeight() and A.list:GetHeight() > 0 then
        return math.max(8, math.min(ROW_MAX, math.floor(A.list:GetHeight() / ROW_H)))
    end
    return 18
end

local function PlaceRow(r)
    r.icon:ClearAllPoints()
    r.icon:SetWidth(ICON_SZ)
    r.icon:SetHeight(ICON_SZ)
    r.icon:SetPoint("LEFT", COL.icon, 0)
    TrimIcon(r.icon)
    local function put(fs, key, justify)
        fs:ClearAllPoints()
        fs:SetPoint("LEFT", COL[key], 0)
        fs:SetWidth(COL[key .. "W"])
        fs:SetJustifyH(justify or "LEFT")
    end
    put(r.name, "name", "LEFT")
    put(r.mythic, "mythic", "CENTER")
    put(r.price, "price", "RIGHT")
    put(r.time, "time", "CENTER")
end

local function Paint()
    if not A.rows then return end
    if not shown then RebuildShown() end
    local n = shown and #shown or 0
    local vis = VisCount()
    offset = math.max(0, math.min(offset or 0, math.max(0, n - vis)))
    if A.painting then return end
    A.painting = true
    if A.list and A.list:GetWidth() and A.list:GetWidth() > 50 then
        LayoutCols(A.list:GetWidth())
    end
    if A.PlaceHeads then A.PlaceHeads() end
    if A.bar then
        local maxOff = math.max(0, n - vis)
        A.bar:SetMinMaxValues(0, maxOff)
        A.bar:SetValue(offset)
        if maxOff > 0 then A.bar:Show() else A.bar:Hide() end
    end
    for i = 1, ROW_MAX do
        local r = A.rows[i]
        if i > vis then
            r:Hide()
        else
            local e = shown and shown[offset + i]
            if not e then
                r:Hide()
            else
                r.row = e
                r:SetHeight(ROW_H)
                r:ClearAllPoints()
                r:SetPoint("TOPLEFT", A.list, "TOPLEFT", 0, -((i - 1) * ROW_H))
                r:SetPoint("TOPRIGHT", A.list, "TOPRIGHT", 0, -((i - 1) * ROW_H))
                PlaceRow(r)
                if r.unlist then
                    r.unlist:SetFrameLevel((r:GetFrameLevel() or 1) + 6)
                end
                local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(e.entry)
                r.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
                TrimIcon(r.icon)
                local q = ITEM_QUALITY_COLORS[e.quality or 1]
                local name = e.name ~= "" and e.name or ("Item " .. e.entry)
                if q then
                    name = string.format("|cff%02x%02x%02x%s|r", q.r * 255, q.g * 255, q.b * 255, name)
                end
                r.name:SetText(name)
                r.mythic:SetText(MythicTag(e.mythic))
                r.price:SetText("|cffffd700" .. GoldText(e.buyout) .. "|r")
                r.time:SetText("|cffc8b8c4" .. TimeText(e.timeLeft) .. "|r")
                if r.bg then
                    local c = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.C and _G.qtEasyAuctionSkin.C()
                    local tint = (i % 2 == 0) and (c and c.rowA) or (c and c.rowB)
                    if tint then
                        r.bg:SetVertexColor(tint[1], tint[2], tint[3], tint[4] or 0.95)
                    else
                        r.bg:SetVertexColor(0.12, 0.11, 0.16, 0.95)
                    end
                end
                r:Show()
            end
        end
    end
    if A.sum then
        local nAll = listings and #listings or 0
        if nAll > 0 then
            if n < nAll then
                A.sum:SetText(n .. " of " .. nAll .. "  ·  " .. GoldText(TotalCopper()) .. " posted")
            else
                A.sum:SetText(nAll .. " auctions  ·  " .. GoldText(TotalCopper()) .. " posted")
            end
        else
            A.sum:SetText("")
        end
    end
    A.painting = nil
end

local function ApplyFilter()
    RebuildShown()
    offset = 0
    Paint()
end

local function ParseListings(tail)
    local out = {}
    for rec in string.gmatch(tail or "", "[^~]+") do
        local id, entry, cnt, mythic, buyout, randProp, timeLeft, quality, owner, name =
            string.match(rec, "^(%d+):(%d+):(%d+):(%d+):(%d+):(%-?%d+):(%d+):(%d+):([^:]*):(.*)$")
        if id then
            out[#out + 1] = {
                idRaw = id,
                entry = tonumber(entry),
                count = tonumber(cnt) or 1,
                mythic = tonumber(mythic) or 0,
                buyout = tonumber(buyout) or 0,
                randProp = tonumber(randProp) or 0,
                timeLeft = tonumber(timeLeft) or 0,
                quality = tonumber(quality) or 1,
                owner = owner,
                name = name,
            }
        end
    end
    return out
end

local function Request(pg)
    if type(PeloriaSend) ~= "function" then return end
    PeloriaSend(PREFIX .. "^MINE^" .. tostring(pg or 0))
end

local function Cancelling()
    return cancelBusy and true or false
end

local function StartFetch()
    if Cancelling() then return end
    if type(PeloriaSend) ~= "function" then
        SetStatus("PeloriaSend missing — stand at an auctioneer.")
        return
    end
    if A.confirm then A.confirm:Hide() end
    if A.searchBox then filterText = CleanQuery(A.searchBox:GetText()) end
    listings, shown, offset, page = {}, {}, 0, 0
    fetching = true
    fetchLeft = 12
    refreshAt = 0
    Paint()
    SetStatus("Loading your auctions…")
    Request(0)
end

local function DropCancelled(rows)
    if not rows then return rows end
    local now = GetTime()
    for id, t in pairs(cancelledIds) do
        if now - t > 20 then cancelledIds[id] = nil end
    end
    for i = #rows, 1, -1 do
        local id = rows[i].idRaw
        if id and (pendingCancel[id] or cancelledIds[id]) then
            table.remove(rows, i)
        end
    end
    return rows
end

local function DropId(idRaw)
    if not listings then return end
    for i = #listings, 1, -1 do
        if listings[i].idRaw == idRaw then
            table.remove(listings, i)
        end
    end
end

local function FinishCancel()
    cancelQ, cancelBusy, cancelAt, cancelTotal = nil, nil, nil, nil
    pendingCancel = {}
    cancelDoneAt = GetTime() + 0.45
    SetStatus("Refreshing auctions…")
end

local function SendCancel(idRaw)
    if type(PeloriaSend) ~= "function" or not idRaw then return false end
    return pcall(PeloriaSend, string.format("%s^CANCEL^%s", PREFIX, tostring(idRaw)))
end

local function QueueRows(rows)
    if type(PeloriaSend) ~= "function" then
        SetStatus("PeloriaSend missing — stand at an auctioneer.")
        return
    end
    cancelQ = cancelQ or {}
    local added = 0
    for i = 1, #(rows or {}) do
        local id = rows[i] and rows[i].idRaw
        if id and not pendingCancel[id] then
            pendingCancel[id] = true
            cancelledIds[id] = GetTime()
            cancelQ[#cancelQ + 1] = { idRaw = id, name = rows[i].name }
            if _G.qtEasyAuctionSales and _G.qtEasyAuctionSales.DropId then
                _G.qtEasyAuctionSales.DropId(id)
            end
            added = added + 1
        end
    end
    if added == 0 then
        SetStatus("Nothing to unlist.")
        return
    end
    cancelBusy = true
    cancelTotal = (cancelTotal or 0) + added
    cancelAt = 0
    refreshAt = 0
    fetching = false
end

local function PumpCancel()
    if not cancelBusy then return end
    if cancelQ and #cancelQ > 0 then
        if cancelAt and GetTime() < cancelAt then return end
        local job = table.remove(cancelQ, 1)
        if SendCancel(job.idRaw) then
            DropId(job.idRaw)
            RebuildShown()
            Paint()
            cancelAt = GetTime() + 0.08
            local left = #cancelQ
            local n = cancelTotal or 1
            if left > 0 then
                SetStatus("Unlisting… " .. (n - left) .. "/" .. n)
            else
                SetStatus("Unlisting " .. (job.name or "auction") .. ".")
            end
        else
            pendingCancel[job.idRaw] = nil
            FinishCancel()
            SetStatus("PeloriaSend failed — stand at an auctioneer.")
        end
        return
    end
    if cancelAt and GetTime() < cancelAt + 0.5 then return end
    FinishCancel()
end

local function CancelOne(row)
    if Cancelling() and cancelQ and #cancelQ > 40 then return end
    QueueRows({ row })
end

local function CancelAll()
    if A.confirm then A.confirm:Hide() end
    local rows = A.confirmRows
    if not rows or #rows == 0 then rows = shown end
    if not rows or #rows == 0 then rows = listings end
    A.confirmRows = nil
    QueueRows(rows)
end

local function OnPacket(body)
    body = body or ""
    body = string.gsub(body, "^PELAH%^", "")
    if string.find(body, "^CANCELLED%^") == 1 then
        local code = string.match(body, "^CANCELLED%^(%w+)")
        if Cancelling() then
            if code == "NOAUCTIONEER" or code == "NOHOUSE" then
                cancelQ = {}
                FinishCancel()
                SetStatus("Step back to the auctioneer.")
                return
            end
            cancelAt = GetTime()
            return
        end
        if not fetching then refreshAt = GetTime() + 0.35 end
        return
    end
    if string.find(body, "^MINE%^") ~= 1 then return end
    if Cancelling() then return end
    local pg, hasMore = string.match(body, "^MINE%^(%d+)%^(%d+)")
    pg, hasMore = tonumber(pg), tonumber(hasMore)
    if pg == nil then return end
    if pg == 0 then listings = {} end
    local first = string.find(body, "~", 1, true)
    local rows = ParseListings(first and string.sub(body, first + 1) or "")
    rows = DropCancelled(rows)
    for i = 1, #rows do listings[#listings + 1] = rows[i] end
    fetchLeft = 12
    if hasMore == 1 and (pg + 1) < PAGE_CAP then
        page = pg + 1
        SetStatus(string.format("Loading your auctions… page %d", page + 1))
        Request(page)
    else
        fetching = false
        ApplySort()
        RebuildShown()
        if #listings == 0 then
            SetStatus("No auctions posted.")
        elseif shown and #shown == 0 then
            SetStatus("No auctions match that search.")
        else
            SetStatus("")
        end
        Paint()
        if _G.qtEasyAuctionSales and _G.qtEasyAuctionSales.NoteListings then
            _G.qtEasyAuctionSales.NoteListings(listings)
        end
    end
end

local function RouteIncoming(a, b)
    local payload = a
    if type(a) == "string" and type(b) == "string" and a == "PELAH" then
        pcall(OnPacket, b)
        return
    end
    if type(payload) ~= "string" then payload = b end
    if type(payload) ~= "string" then return end
    if string.find(payload, "^PELAH") or string.find(payload, "^MINE") or string.find(payload, "^CANCELLED") then
        pcall(OnPacket, payload)
    end
end

local function InstallHook()
    if peekWrapped.ok then return end
    -- ʕ •ᴥ•ʔ✿ wrap one outer entry only — RawPacket calls OnPacket ✿ ʕ •ᴥ•ʔ
    local names = { "PeloriaOnRawPacket", "PeloriaOnPacket" }
    for i = 1, #names do
        local name = names[i]
        if type(_G[name]) == "function" then
            local orig = _G[name]
            _G[name] = function(x, y, ...)
                RouteIncoming(x, y)
                return orig(x, y, ...)
            end
            peekWrapped.ok = true
            return
        end
    end
    local handlers = rawget(_G, "PeloriaPacketHandlers")
    if type(handlers) == "table" and type(handlers[PREFIX]) == "function" and handlers[PREFIX] ~= A.hookFn then
        local orig = handlers[PREFIX]
        A.hookFn = function(body, ...)
            pcall(OnPacket, body)
            if orig then return orig(body, ...) end
        end
        handlers[PREFIX] = A.hookFn
        peekWrapped.ok = true
    end
end

local function AskUnlistAll()
    if Cancelling() then
        SetStatus("Already unlisting.")
        return
    end
    local rows = shown
    if not rows or #rows == 0 then rows = listings end
    local n = rows and #rows or 0
    if n == 0 then
        SetStatus("Nothing to unlist.")
        return
    end
    A.confirmRows = rows
    if A.confirmText then
        if listings and #rows < #listings then
            A.confirmText:SetText("Unlist " .. n .. " matching auctions?")
        else
            A.confirmText:SetText("Unlist all " .. n .. " auctions?")
        end
    end
    if A.confirm then
        A.confirm:Show()
        A.confirm:Raise()
        return
    end
    CancelAll()
end

local function CreateRow(parent)
    local r = CreateFrame("Frame", nil, parent)
    r:SetHeight(ROW_H)
    r:EnableMouse(true)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetWidth(ICON_SZ)
    r.icon:SetHeight(ICON_SZ)
    r.icon:SetPoint("LEFT", COL.icon, 0)
    TrimIcon(r.icon)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.name:SetJustifyH("LEFT")
    r.mythic = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.mythic:SetJustifyH("CENTER")
    r.price = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.price:SetJustifyH("RIGHT")
    r.time = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.time:SetJustifyH("CENTER")
    PlaceRow(r)
    local Skin = _G.qtEasyAuctionSkin
    local unlist
    if Skin and Skin.CuteButton then
        unlist = Skin.CuteButton(r, UNLIST_W, 22, "Unlist")
    else
        unlist = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
        unlist:SetWidth(UNLIST_W)
        unlist:SetHeight(22)
        unlist:SetText("Unlist")
    end
    unlist:SetPoint("RIGHT", -4, 0)
    unlist:SetFrameLevel((r:GetFrameLevel() or 1) + 6)
    unlist:EnableMouse(true)
    unlist:RegisterForClicks("LeftButtonUp")
    unlist:SetScript("OnClick", function() CancelOne(r.row) end)
    r.unlist = unlist
    r:SetScript("OnEnter", function(self)
        if not self.row then return end
        local level = tonumber(self.row.mythic) or 0
        PeloriaSoulbindHoverLevel = (level > 0) and level or nil
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        if PrimeItemCache then PrimeItemCache(self.row.entry) end
        GameTooltip:SetHyperlink(ItemLink(self.row.entry, self.row.randProp))
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function()
        PeloriaSoulbindHoverLevel = nil
        GameTooltip:Hide()
    end)
    return r
end

local function Cute(parent, w, h, label)
    local Skin = _G.qtEasyAuctionSkin
    if Skin and Skin.CuteButton then
        return Skin.CuteButton(parent, w, h, label)
    end
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(w)
    b:SetHeight(h)
    b:SetText(label)
    return b
end

local function CreatePanel()
    A.panel = A.panel or _G.qtEasyAuctionMinePanel
    if A.panel then
        local page = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.pages and _G.qtEasyAuctionSkin.pages.mine
        if page and A.panel:GetParent() ~= page then
            A.panel:SetParent(page)
            A.panel:SetAllPoints(page)
        end
        A.panel:Show()
        return
    end
    if _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.Create then
        _G.qtEasyAuctionSkin.Create()
    end
    local page = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.pages and _G.qtEasyAuctionSkin.pages.mine
    local parent = page or PeloriaAuctionHouseFrame
    if not parent then return end
    local panel = CreateFrame("Frame", "qtEasyAuctionMinePanel", parent)
    panel:SetAllPoints(parent)
    panel:EnableMouse(true)
    A.panel = panel

    local top = (panel:GetFrameLevel() or 1) + 8
    local unlistAll = Cute(panel, 110, 32, "Unlist All")
    unlistAll:SetPoint("TOPRIGHT", -8, -6)
    unlistAll:SetFrameLevel(top)
    unlistAll:EnableMouse(true)
    unlistAll:RegisterForClicks("LeftButtonUp")
    unlistAll:SetScript("OnClick", AskUnlistAll)
    A.unlistAll = unlistAll

    local confirm = CreateFrame("Frame", "qtEasyAuctionUnlistConfirm", panel)
    confirm:SetWidth(280)
    confirm:SetHeight(110)
    confirm:SetPoint("CENTER", 0, 20)
    confirm:SetFrameStrata("TOOLTIP")
    confirm:SetFrameLevel((panel:GetFrameLevel() or 1) + 80)
    confirm:SetToplevel(true)
    confirm:EnableMouse(true)
    confirm:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    confirm:SetBackdropColor(0.08, 0.07, 0.12, 0.98)
    confirm:SetBackdropBorderColor(0.78, 0.55, 0.72, 1)
    local confirmText = confirm:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    confirmText:SetPoint("TOP", 0, -22)
    confirmText:SetWidth(240)
    confirmText:SetJustifyH("CENTER")
    A.confirmText = confirmText
    local yes = Cute(confirm, 90, 28, "Unlist")
    yes:SetPoint("BOTTOMLEFT", 24, 16)
    yes:SetScript("OnClick", CancelAll)
    local no = Cute(confirm, 90, 28, "Cancel")
    no:SetPoint("BOTTOMRIGHT", -24, 16)
    no:SetScript("OnClick", function()
        A.confirmRows = nil
        confirm:Hide()
    end)
    confirm:Hide()
    A.confirm = confirm
    tinsert(UISpecialFrames, "qtEasyAuctionUnlistConfirm")

    local refresh = Cute(panel, 96, 32, "Refresh")
    refresh:SetPoint("RIGHT", unlistAll, "LEFT", -8, 0)
    refresh:SetFrameLevel(top)
    refresh:SetScript("OnClick", StartFetch)

    -- ʕ •ᴥ•ʔ✿ search chrome matches deals, filters your listings live ✿ ʕ •ᴥ•ʔ
    local search = CreateFrame("Frame", nil, panel)
    search:SetPoint("TOPLEFT", 8, -6)
    search:SetPoint("RIGHT", refresh, "LEFT", -8, 0)
    search:SetHeight(32)
    search:SetFrameLevel(top)
    search:EnableMouse(true)
    local searchBg = search:CreateTexture(nil, "BACKGROUND")
    searchBg:SetAllPoints()
    searchBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    A.searchBg = searchBg
    local searchLine = search:CreateTexture(nil, "ARTWORK")
    searchLine:SetHeight(1)
    searchLine:SetPoint("BOTTOMLEFT", 0, 0)
    searchLine:SetPoint("BOTTOMRIGHT", 0, 0)
    searchLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    A.searchLine = searchLine
    local hint = search:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    hint:SetPoint("LEFT", 10, 0)
    hint:SetJustifyH("LEFT")
    hint:SetText("Search auctions")
    A.searchHint = hint
    local box = CreateFrame("EditBox", "qtEasyAuctionMineSearch", search)
    box:SetPoint("TOPLEFT", 8, -4)
    box:SetPoint("BOTTOMRIGHT", -8, 4)
    box:SetAutoFocus(false)
    box:SetMaxLetters(40)
    box:SetFontObject(GameFontHighlight)
    box:SetTextInsets(2, 2, 0, 0)
    box:EnableMouse(true)
    box:EnableKeyboard(true)
    box:SetAltArrowKeyMode(false)
    box:SetFrameLevel(top + 1)
    A.searchBox = box
    local function BoxQuery()
        return CleanQuery(box:GetText())
    end
    local function PaintHint()
        local empty = BoxQuery() == ""
        if empty and not box:HasFocus() then hint:Show() else hint:Hide() end
    end
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        PaintHint()
        filterText = BoxQuery()
        ApplyFilter()
    end)
    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        PaintHint()
    end)
    box:SetScript("OnEditFocusGained", function() hint:Hide() end)
    box:SetScript("OnEditFocusLost", PaintHint)
    box:SetScript("OnTextChanged", function()
        PaintHint()
        filterText = BoxQuery()
        ApplyFilter()
    end)
    search:SetScript("OnMouseDown", function() box:SetFocus() end)
    A.searchBar = search

    A.sum = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    A.sum:SetPoint("TOPRIGHT", -28, -44)
    A.sum:SetTextColor(1, 0.84, 0.45)

    A.status = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    A.status:SetPoint("TOPLEFT", 12, -44)
    A.status:SetPoint("RIGHT", A.sum, "LEFT", -12, 0)
    A.status:SetJustifyH("LEFT")
    A.status:SetText("Your posted auctions.")

    local head = CreateFrame("Frame", nil, panel)
    head:SetPoint("TOPLEFT", 8, -62)
    head:SetPoint("TOPRIGHT", -24, -62)
    head:SetHeight(22)
    local ht = head:CreateTexture(nil, "BACKGROUND")
    ht:SetAllPoints()
    ht:SetTexture("Interface\\Buttons\\WHITE8X8")
    A.headBg = ht
    local line = head:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", 0, 0)
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    A.headLine = line
    A.headLabs = {}
    local function HeadBtn(label, key, colKey, justify)
        local b = CreateFrame("Button", nil, head)
        b:SetHeight(22)
        b:RegisterForClicks("LeftButtonUp")
        b:EnableMouse(true)
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetAllPoints()
        fs:SetJustifyH(justify or "CENTER")
        fs:SetText(label)
        b.fs = fs
        b.sortName = label
        b.key = key
        b.colKey = colKey
        b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight")
        local hl = b:GetHighlightTexture()
        if hl then hl:SetAlpha(0.25) end
        b:SetScript("OnClick", function()
            if sortKey == key then
                sortDesc = not sortDesc
            else
                sortKey = key
                sortDesc = true
            end
            ApplySort()
            RebuildShown()
            A.RefreshHeads()
            Paint()
        end)
        A.headLabs[#A.headLabs + 1] = b
        return b
    end
    HeadBtn("Item", "name", "name", "LEFT")
    HeadBtn("M+", "mythic", "mythic", "CENTER")
    HeadBtn("Buyout", "price", "price", "RIGHT")
    HeadBtn("Time", "time", "time", "CENTER")
    function A.PlaceHeads()
        for i = 1, #(A.headLabs or {}) do
            local b = A.headLabs[i]
            local k = b.colKey
            b:ClearAllPoints()
            b:SetPoint("LEFT", COL[k] or 0, 0)
            b:SetWidth(COL[k .. "W"] or 60)
        end
    end
    function A.RefreshHeads()
        for i = 1, #(A.headLabs or {}) do
            local b = A.headLabs[i]
            local mark = ""
            if b.key and sortKey == b.key then mark = sortDesc and " ▼" or " ▲" end
            b.fs:SetText(b.sortName .. mark)
            local pal = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.C and _G.qtEasyAuctionSkin.C()
            if b.key and sortKey == b.key then
                if pal then b.fs:SetTextColor(pal.gold[1], pal.gold[2], pal.gold[3])
                else b.fs:SetTextColor(1, 0.92, 0.55) end
            else
                if pal then b.fs:SetTextColor(pal.headTxt[1], pal.headTxt[2], pal.headTxt[3])
                else b.fs:SetTextColor(0.95, 0.78, 0.92) end
            end
        end
        if A.PlaceHeads then A.PlaceHeads() end
    end
    A.RefreshHeads()

    local list = CreateFrame("Frame", nil, panel)
    list:SetPoint("TOPLEFT", 8, -86)
    list:SetPoint("BOTTOMRIGHT", -24, 8)
    A.list = list
    local bar = CreateFrame("Slider", "qtEasyAuctionMineBar", panel, "UIPanelScrollBarTemplate")
    bar:SetPoint("TOPRIGHT", -4, -86)
    bar:SetPoint("BOTTOMRIGHT", -4, 8)
    bar:SetValueStep(1)
    bar:SetScript("OnValueChanged", function(self, value)
        if A.painting then return end
        offset = math.floor((value or 0) + 0.5)
        Paint()
    end)
    A.bar = bar
    A.rows = {}
    for i = 1, ROW_MAX do
        A.rows[i] = CreateRow(list)
    end
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta)
        offset = (offset or 0) - delta * 3
        Paint()
    end)
    panel:SetScript("OnShow", function()
        Paint()
        if not fetching and not Cancelling() and (not listings or #listings == 0) then
            StartFetch()
        end
    end)
    panel:SetScript("OnUpdate", function(_, delta)
        if cancelBusy then PumpCancel() end
        if cancelDoneAt and GetTime() >= cancelDoneAt then
            cancelDoneAt = nil
            StartFetch()
        end
        if not fetching and not (refreshAt and refreshAt > 0) then return end
        if fetching then
            InstallHook()
            fetchLeft = (fetchLeft or 0) - delta
            if fetchLeft <= 0 then
                fetching = false
                if listings and #listings > 0 then
                    ApplySort()
                    RebuildShown()
                    SetStatus("")
                    Paint()
                else
                    SetStatus("No AH reply. Open the house, then Refresh.")
                end
            end
        elseif refreshAt and refreshAt > 0 and GetTime() >= refreshAt then
            refreshAt = 0
            StartFetch()
        end
    end)
    panel:Show()
end

function A.ApplySkin()
    local pal = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.C and _G.qtEasyAuctionSkin.C()
    if not pal then return end
    if A.headBg then A.headBg:SetVertexColor(pal.head[1], pal.head[2], pal.head[3], pal.head[4] or 1) end
    if A.headLine then A.headLine:SetVertexColor(pal.accent[1], pal.accent[2], pal.accent[3], 0.9) end
    if A.status then A.status:SetTextColor(pal.mute[1], pal.mute[2], pal.mute[3]) end
    if A.sum then A.sum:SetTextColor(pal.gold[1], pal.gold[2], pal.gold[3]) end
    if A.searchBg then A.searchBg:SetVertexColor(pal.rowB[1], pal.rowB[2], pal.rowB[3], 1) end
    if A.searchLine then A.searchLine:SetVertexColor(pal.accent[1], pal.accent[2], pal.accent[3], 0.85) end
    if A.searchHint then A.searchHint:SetTextColor(pal.mute[1], pal.mute[2], pal.mute[3]) end
    if A.searchBox then A.searchBox:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3]) end
    if A.confirm then
        A.confirm:SetBackdropColor(pal.bg[1], pal.bg[2], pal.bg[3], 0.98)
        A.confirm:SetBackdropBorderColor(pal.accent[1], pal.accent[2], pal.accent[3], 1)
    end
    if A.confirmText then A.confirmText:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3]) end
    if A.RefreshHeads then A.RefreshHeads() end
    Paint()
end

function A.OnShown()
    CreatePanel()
    if A.panel then A.panel:Show() end
    A.ApplySkin()
    InstallHook()
    if not Cancelling() then StartFetch() end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("AUCTION_HOUSE_SHOW")
boot:SetScript("OnEvent", function()
    if _G.qtEasyAuctionSkin then _G.qtEasyAuctionSkin.Create() end
    CreatePanel()
    InstallHook()
end)
