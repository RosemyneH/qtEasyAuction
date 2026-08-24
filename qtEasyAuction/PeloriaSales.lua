local T = {}
_G.qtEasyAuctionSales = T

local peekWrapped = {}
local lastGold, watch, watchLeft
local wrappedRaw
local ev
local InstallHook

local function Now()
    return (type(time) == "function" and time()) or 0
end

local function DayKey(ts)
    ts = ts or Now()
    if type(date) == "function" then
        local ok, d = pcall(date, "*t", ts)
        if ok and type(d) == "table" and d.year then
            return string.format("%04d%02d%02d", d.year, d.month, d.day)
        end
    end
    return tostring(math.floor((ts or 0) / 86400))
end

local function ShiftDay(key, delta)
    if type(date) ~= "function" or type(time) ~= "function" then return key end
    local y = tonumber(string.sub(key, 1, 4))
    local m = tonumber(string.sub(key, 5, 6))
    local d = tonumber(string.sub(key, 7, 8))
    if not (y and m and d) then return key end
    local ok, ts = pcall(time, { year = y, month = m, day = d, hour = 12 })
    if not ok or not ts then return key end
    return DayKey(ts + delta * 86400)
end

local function StripLink(s)
    s = tostring(s or "")
    s = string.gsub(s, "|c%x+|H.-|h%[(.-)%]|h|r", "%1")
    s = string.gsub(s, "%[(.-)%]", "%1")
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

local function Lower(s)
    return string.lower(StripLink(s))
end

local function FmtPat(fmt)
    fmt = tostring(fmt or "")
    fmt = string.gsub(fmt, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    fmt = string.gsub(fmt, "%%%%s", "(.+)")
    fmt = string.gsub(fmt, "%%%%d", "(%%d+)")
    return "^" .. fmt .. "$"
end

local soldChatPat = FmtPat(_G.ERR_AUCTION_SOLD_S or "A buyer has been found for your auction of %s.")

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
    if a >= 1000 then
        local k = n / 1000
        if k == math.floor(k) then return tostring(k) .. "k" end
        return string.format("%.1fk", k)
    end
    local text = string.format("%.0f", n)
    while true do
        local replaced
        text, replaced = string.gsub(text, "^(%-?%d+)(%d%d%d)", "%1,%2")
        if replaced == 0 then break end
    end
    return text
end

local MONTH = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

local function DayLabel(key)
    if key == DayKey() then return "Today" end
    if key == ShiftDay(DayKey(), -1) then return "Yesterday" end
    local m = tonumber(string.sub(key, 5, 6))
    local d = tonumber(string.sub(key, 7, 8))
    if m and d and MONTH[m] then return d .. " " .. MONTH[m] end
    return key
end

local function Ago(ts)
    local d = Now() - (tonumber(ts) or 0)
    if d < 90 then return "just now" end
    if d < 3600 then return math.floor(d / 60) .. "m ago" end
    if d < 86400 then return math.floor(d / 3600) .. "h ago" end
    local days = math.floor(d / 86400)
    if days == 1 then return "yesterday" end
    return days .. "d ago"
end

local function ListedSum(s)
    local n, copper = 0, 0
    for i = 1, #(s.onAH or {}) do
        n = n + 1
        copper = copper + (s.onAH[i].buyout or 0)
    end
    return n, copper
end

local function GoldText(copper)
    return Compact((tonumber(copper) or 0) / 10000) .. "g"
end

local function DB()
    qtEasyAuctionCharDB = qtEasyAuctionCharDB or {}
    local s = qtEasyAuctionCharDB.sales
    if type(s) ~= "table" then
        s = {}
        qtEasyAuctionCharDB.sales = s
    end
    s.days = s.days or {}
    s.onAH = s.onAH or {}
    s.recent = s.recent or {}
    s.seenSold = s.seenSold or {}
    s.seenBought = s.seenBought or {}
    s.totalCopper = s.totalCopper or 0
    s.totalCount = s.totalCount or 0
    s.totalBuyCopper = s.totalBuyCopper or 0
    s.totalBuyCount = s.totalBuyCount or 0
    s.pending = s.pending or 0
    return s
end

local function EnsureDay(key)
    local s = DB()
    local b = s.days[key]
    if not b then
        b = { copper = 0, count = 0, buyCopper = 0, buyCount = 0 }
        s.days[key] = b
    end
    b.buyCopper = b.buyCopper or 0
    b.buyCount = b.buyCount or 0
    return b
end

local function PruneDays()
    local s = DB()
    local keys = {}
    for k in pairs(s.days) do keys[#keys + 1] = k end
    table.sort(keys)
    while #keys > 90 do
        s.days[keys[1]] = nil
        table.remove(keys, 1)
    end
    while #(s.recent) > 50 do table.remove(s.recent, 1) end
    local function pruneSeen(bag, cap)
        local n = 0
        for _ in pairs(bag) do n = n + 1 end
        if n > cap then
            return {}
        end
        return bag
    end
    s.seenSold = pruneSeen(s.seenSold, 400)
    s.seenBought = pruneSeen(s.seenBought, 400)
end

local function Paint()
    if T.Refresh then T.Refresh() end
end

local function RememberSold(idRaw)
    if not idRaw or idRaw == "" then return end
    DB().seenSold[tostring(idRaw)] = Now()
end

local function AlreadySold(idRaw)
    if not idRaw or idRaw == "" then return false end
    return DB().seenSold[tostring(idRaw)] and true or false
end

local function RememberBought(idRaw)
    if not idRaw or idRaw == "" then return end
    DB().seenBought[tostring(idRaw)] = Now()
end

local function AlreadyBought(idRaw)
    if not idRaw or idRaw == "" then return false end
    return DB().seenBought[tostring(idRaw)] and true or false
end

local function AddSale(name, copper, src, idRaw)
    copper = math.floor(tonumber(copper) or 0)
    if copper <= 0 then return false end
    if AlreadySold(idRaw) then return false end
    local s = DB()
    local t = Now()
    s.startedAt = s.startedAt or t
    local day = DayKey(t)
    s.totalCopper = s.totalCopper + copper
    s.totalCount = s.totalCount + 1
    local b = EnsureDay(day)
    b.copper = b.copper + copper
    b.count = b.count + 1
    s.recent[#s.recent + 1] = { t = t, name = name, copper = copper, src = src, kind = "sale" }
    RememberSold(idRaw)
    if (s.pending or 0) > 0 then s.pending = s.pending - 1 end
    PruneDays()
    Paint()
    return true
end

local function AddBuy(name, copper, idRaw)
    copper = math.floor(tonumber(copper) or 0)
    if copper <= 0 then return false end
    if AlreadyBought(idRaw) then return false end
    name = StripLink(name)
    if name == "" then name = "Purchase" end
    local s = DB()
    local t = Now()
    s.startedAt = s.startedAt or t
    local day = DayKey(t)
    s.totalBuyCopper = s.totalBuyCopper + copper
    s.totalBuyCount = s.totalBuyCount + 1
    local b = EnsureDay(day)
    b.buyCopper = (b.buyCopper or 0) + copper
    b.buyCount = (b.buyCount or 0) + 1
    s.recent[#s.recent + 1] = { t = t, name = name, copper = copper, src = "buy", kind = "buy" }
    RememberBought(idRaw)
    PruneDays()
    Paint()
    return true
end

function T.NoteBuy(name, copper, idRaw)
    return AddBuy(name, copper, idRaw)
end

local function TakeListing(name)
    local s = DB()
    local want = Lower(name)
    if want == "" then return nil end
    local best, idx
    for i = 1, #(s.onAH) do
        local e = s.onAH[i]
        if Lower(e.name) == want then
            if not best or (e.buyout or 0) > (best.buyout or 0) then
                best, idx = e, i
            end
        end
    end
    if not idx then return nil end
    table.remove(s.onAH, idx)
    return best
end

-- ʕ •ᴥ•ʔ✿ bag money only — sales land here, not account totals ✿ ʕ •ᴥ•ʔ
local function BagGold()
    return GetMoney() or 0
end

local Pulse
local hookWait, hookTries = 0, 0
local HOOK_GAP, HOOK_CAP = 0.5, 80

local function ArmPulse()
    if watch or (not peekWrapped.ok and hookTries < HOOK_CAP) then
        ev:SetScript("OnUpdate", Pulse)
    else
        ev:SetScript("OnUpdate", nil)
    end
end

local function SampleGold()
    lastGold = BagGold()
end

local function FinishWatch(copper)
    local job = watch
    watch, watchLeft = nil, nil
    if not job then
        ArmPulse()
        return
    end
    copper = math.floor(tonumber(copper) or 0)
    if copper > 0 then
        if AddSale(job.name, copper, "gold", job.idRaw) then
            print("|cff00ff00qtEasyAuction:|r Sold " .. (job.name or "") .. "  ·  " .. GoldText(copper))
        end
        ArmPulse()
        return
    end
    DB().pending = (DB().pending or 0) + 1
    Paint()
    ArmPulse()
end

local function OnGoldBump()
    local now = BagGold()
    local prev = lastGold or now
    lastGold = now
    if not watch then return end
    local d = now - prev
    if d > 0 then FinishWatch(d) end
end

Pulse = function(_, delta)
    if not peekWrapped.ok and hookTries < HOOK_CAP then
        hookWait = hookWait + (delta or 0)
        if hookWait >= HOOK_GAP then
            hookWait = 0
            hookTries = hookTries + 1
            InstallHook()
        end
    end
    if watch then
        watchLeft = (watchLeft or 0) - (delta or 0)
        if watchLeft <= 0 then FinishWatch(0) end
    end
    if not watch and (peekWrapped.ok or hookTries >= HOOK_CAP) then
        ev:SetScript("OnUpdate", nil)
    end
end

local function StartWatch(name, idRaw)
    watch = { name = name, idRaw = idRaw, gold = BagGold() }
    watchLeft = 2.5
    lastGold = watch.gold
    ArmPulse()
end

local function DayBits(b)
    b = b or {}
    return {
        copper = b.copper or 0,
        count = b.count or 0,
        buyCopper = b.buyCopper or 0,
        buyCount = b.buyCount or 0,
    }
end

function T.Summary()
    local s = DB()
    local todayKey = DayKey()
    local today = DayBits(s.days[todayKey])
    local yest = DayBits(s.days[ShiftDay(todayKey, -1)])
    local weekCopper, weekBuy = 0, 0
    for i = 0, 6 do
        local b = s.days[i == 0 and todayKey or ShiftDay(todayKey, -i)]
        if b then
            weekCopper = weekCopper + (b.copper or 0)
            weekBuy = weekBuy + (b.buyCopper or 0)
        end
    end
    local elapsed = math.max(0, Now() - (s.startedAt or Now()))
    local days = elapsed / 86400
    local perDay = today.copper or 0
    local buyPerDay = today.buyCopper or 0
    if days >= 1 then
        perDay = s.totalCopper / math.max(1, days)
        buyPerDay = (s.totalBuyCopper or 0) / math.max(1, days)
    end
    local listedN, listedCopper = ListedSum(s)
    local daysRows = {}
    for i = 0, 13 do
        local k = i == 0 and todayKey or ShiftDay(todayKey, -i)
        local b = DayBits(s.days[k])
        daysRows[#daysRows + 1] = {
            key = k,
            label = DayLabel(k),
            copper = b.copper,
            count = b.count,
            buyCopper = b.buyCopper,
            buyCount = b.buyCount,
        }
    end
    return {
        today = today.copper,
        todayCount = today.count,
        todayBuy = today.buyCopper,
        todayBuyCount = today.buyCount,
        yesterday = yest.copper,
        yesterdayCount = yest.count,
        yesterdayBuy = yest.buyCopper,
        yesterdayBuyCount = yest.buyCount,
        week = weekCopper,
        weekBuy = weekBuy,
        perDay = perDay,
        buyPerDay = buyPerDay,
        total = s.totalCopper or 0,
        count = s.totalCount or 0,
        totalBuy = s.totalBuyCopper or 0,
        buyCount = s.totalBuyCount or 0,
        pending = s.pending or 0,
        listed = listedN,
        listedCopper = listedCopper,
        days = days,
        startedAt = s.startedAt,
        recent = s.recent,
        dayRows = daysRows,
    }
end

function T.GoldText(copper)
    return GoldText(copper)
end

function T.Line()
    local u = T.Summary()
    return GoldText(u.today) .. " sold  ·  " .. GoldText(u.todayBuy or 0) .. " spent"
end

function T.Tip(tip)
    local u = T.Summary()
    local pal = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.C and _G.qtEasyAuctionSkin.C()
    local mr, mg, mb = 0.62, 0.56, 0.64
    if pal and pal.mute then mr, mg, mb = pal.mute[1], pal.mute[2], pal.mute[3] end
    tip:AddLine("Auction gold", 1, 0.84, 0.45)
    tip:AddLine("Sales credit your bags. Buys go to the mailbox.", mr, mg, mb)
    tip:AddLine(" ")
    tip:AddDoubleLine("Today sold", GoldText(u.today) .. "  ·  " .. (u.todayCount or 0), 1, 1, 1, 1, 0.84, 0.45)
    tip:AddDoubleLine("Today spent", GoldText(u.todayBuy or 0) .. "  ·  " .. (u.todayBuyCount or 0), 1, 1, 1, 0.95, 0.62, 0.58)
    tip:AddDoubleLine("Sold / day", GoldText(u.perDay), 1, 1, 1, 1, 0.84, 0.45)
    tip:AddDoubleLine("Spent / day", GoldText(u.buyPerDay or 0), 1, 1, 1, 0.95, 0.62, 0.58)
    tip:AddDoubleLine("Lifetime sold", GoldText(u.total) .. "  ·  " .. (u.count or 0), 1, 1, 1, 1, 0.84, 0.45)
    tip:AddDoubleLine("Lifetime spent", GoldText(u.totalBuy or 0) .. "  ·  " .. (u.buyCount or 0), 1, 1, 1, 0.95, 0.62, 0.58)
    if (u.pending or 0) > 0 then
        tip:AddLine(" ")
        tip:AddLine(u.pending .. " sold — open Auctions to price them", 1, 0.75, 0.45)
    end
    if u.recent and #u.recent > 0 then
        tip:AddLine(" ")
        tip:AddLine("Recent", mr, mg, mb)
        local n = #u.recent
        local from = n - 7
        if from < 1 then from = 1 end
        for i = n, from, -1 do
            local e = u.recent[i]
            local buy = e.kind == "buy"
            tip:AddDoubleLine(
                (buy and "Buy  " or "Sold  ") .. (e.name or ""),
                GoldText(e.copper),
                0.9, 0.88, 0.82,
                buy and 0.95 or 1, buy and 0.62 or 0.84, buy and 0.58 or 0.45)
        end
    end
    tip:AddLine(" ")
    tip:AddLine("/qta gold   ·   /qta goldreset", mr, mg, mb)
end

function T.NoteListings(rows)
    local s = DB()
    local old = s.onAH or {}
    local bag, newIds = {}, {}
    local t = Now()
    for i = 1, #(rows or {}) do
        local e = rows[i]
        local id = e.idRaw and tostring(e.idRaw) or nil
        bag[#bag + 1] = {
            idRaw = e.idRaw,
            name = e.name or "",
            buyout = e.buyout or 0,
            timeLeft = e.timeLeft or 0,
            seenAt = t,
        }
        if id then newIds[id] = true end
    end
    for i = 1, #old do
        local e = old[i]
        local id = e.idRaw and tostring(e.idRaw) or nil
        if id and not newIds[id] then
            local expireAt = (e.seenAt or t) + (e.timeLeft or 0)
            if t + 30 < expireAt and (e.buyout or 0) > 0 then
                if AddSale(e.name, e.buyout, "gone", e.idRaw) then
                    print("|cff00ff00qtEasyAuction:|r Sold " .. (e.name or "") .. "  ·  " .. GoldText(e.buyout))
                end
            end
        end
    end
    s.onAH = bag
    Paint()
end

function T.NotePost(name, copper)
    if not name or name == "" then return end
    local bag = DB().onAH
    bag[#bag + 1] = {
        name = name,
        buyout = tonumber(copper) or 0,
        timeLeft = 2 * 86400,
        seenAt = Now(),
    }
end

function T.DropId(idRaw)
    if not idRaw then return end
    local bag = DB().onAH
    for i = #bag, 1, -1 do
        if bag[i].idRaw == idRaw then table.remove(bag, i) end
    end
    DB().seenSold[tostring(idRaw)] = Now()
end

local function SoldName(msg)
    if type(msg) ~= "string" then return end
    local name = string.match(msg, soldChatPat)
    if name then return StripLink(name) end
    name = string.match(msg, "[Bb]uyer has been found for your auction of (.+)%.?$")
    if name then return StripLink(name) end
    name = string.match(msg, "[Yy]our auction of (.+) [Ss]old")
    if name then return StripLink(name) end
end

local function OnSoldName(name)
    name = StripLink(name)
    if name == "" then return end
    local listing = TakeListing(name)
    local buyout = listing and listing.buyout or 0
    if buyout > 0 then
        if AddSale(name, buyout, "sold", listing.idRaw) then
            print("|cff00ff00qtEasyAuction:|r Sold " .. name .. "  ·  " .. GoldText(buyout))
        end
        return
    end
    StartWatch(name, listing and listing.idRaw)
end

local function RouteIncoming(a, b)
    local prefix, body = a, b
    if type(a) == "string" and type(b) ~= "string" then
        prefix, body = string.match(a, "^([^%^]+)%^(.*)$")
        if not prefix then body = a end
    end
    if prefix == "GOLD" then
        pcall(OnGoldBump)
    end
end

local function WrapHandler(key, fnField, after)
    local handlers = rawget(_G, "PeloriaPacketHandlers")
    if type(handlers) ~= "table" then return false end
    local cur = handlers[key]
    if type(cur) ~= "function" or cur == T[fnField] then
        return cur == T[fnField]
    end
    local orig = cur
    T[fnField] = function(rest, ...)
        local r1, r2, r3 = orig(rest, ...)
        if after then pcall(after, rest) end
        return r1, r2, r3
    end
    handlers[key] = T[fnField]
    return true
end

function InstallHook()
    WrapHandler("GOLD", "goldFn", function()
        OnGoldBump()
    end)
    if wrappedRaw then return true end
    local names = { "PeloriaOnRawPacket", "PeloriaOnPacket" }
    for i = 1, #names do
        local name = names[i]
        if type(_G[name]) == "function" then
            local orig = _G[name]
            wrappedRaw = function(x, y, ...)
                RouteIncoming(x, y)
                return orig(x, y, ...)
            end
            _G[name] = wrappedRaw
            peekWrapped.ok = true
            return true
        end
    end
    return false
end

local WHITE = "Interface\\Buttons\\WHITE8X8"
local CARD_H, LIST_ROW = 70, 24
local resetArm

local function Pal()
    local Skin = _G.qtEasyAuctionSkin
    return Skin and Skin.C and Skin.C()
end

local function Tint(tex, color)
    if tex and color then tex:SetVertexColor(color[1], color[2], color[3], color[4] or 1) end
end

local function Ink(fs, color)
    if fs and color then fs:SetTextColor(color[1], color[2], color[3]) end
end

local function Fill(frame, color)
    local t = frame:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints()
    t:SetTexture(WHITE)
    Tint(t, color)
    return t
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

local function Card(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.bg = Fill(f, { 0.12, 0.11, 0.16, 0.95 })
    f.k = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.k:SetPoint("TOPLEFT", 10, -10)
    f.k:SetPoint("TOPRIGHT", -10, -10)
    f.k:SetJustifyH("LEFT")
    f.v = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.v:SetPoint("TOPLEFT", 10, -28)
    f.v:SetPoint("TOPRIGHT", -10, -28)
    f.v:SetJustifyH("LEFT")
    f.s = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.s:SetPoint("BOTTOMLEFT", 10, 10)
    f.s:SetPoint("BOTTOMRIGHT", -10, 10)
    f.s:SetJustifyH("LEFT")
    return f
end

local SPEND = { 0.95, 0.62, 0.58 }

local function ListRow(parent)
    local r = CreateFrame("Frame", nil, parent)
    r:SetHeight(LIST_ROW)
    r.bg = Fill(r, { 0.12, 0.11, 0.16, 0.9 })
    r.right = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.right:SetPoint("RIGHT", -8, 0)
    r.right:SetJustifyH("RIGHT")
    r.mid = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.mid:SetPoint("RIGHT", r.right, "LEFT", -10, 0)
    r.mid:SetWidth(118)
    r.mid:SetJustifyH("LEFT")
    r.left = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.left:SetPoint("LEFT", 8, 0)
    r.left:SetPoint("RIGHT", r.mid, "LEFT", -6, 0)
    r.left:SetJustifyH("LEFT")
    return r
end

local function MixSub(soldN, buyN, buyCopper)
    local t = (soldN or 0) .. " sold"
    if (buyN or 0) > 0 or (buyCopper or 0) > 0 then
        t = t .. "  ·  " .. (buyN or 0) .. " bought"
    end
    return t
end

local function DayMid(e)
    local sold, buy = e.count or 0, e.buyCount or 0
    if buy > 0 and sold > 0 then return sold .. " sold · " .. buy .. " bought" end
    if buy > 0 then return buy .. " bought" end
    return sold .. " sold"
end

local function DayRight(e)
    local sold, buy = e.copper or 0, e.buyCopper or 0
    if buy > 0 and sold > 0 then return GoldText(sold) .. " / −" .. GoldText(buy) end
    if buy > 0 then return "−" .. GoldText(buy) end
    if sold > 0 then return GoldText(sold) end
    return "—"
end

local function PaintPanel()
    local P = T.ui
    if not P or not P.panel then return end
    local pal = Pal()
    local u = T.Summary()
    if P.hero then
        P.hero:SetText(GoldText(u.perDay) .. " in  ·  " .. GoldText(u.buyPerDay or 0) .. " out")
        if pal then Ink(P.hero, pal.gold) end
    end
    if resetArm and GetTime() >= resetArm then
        resetArm = nil
        if P.reset and P.reset.label then P.reset.label:SetText("Reset")
        elseif P.reset then P.reset:SetText("Reset") end
    end
    if P.blurb then
        local extra = ""
        if (u.pending or 0) > 0 then
            extra = "  ·  " .. u.pending .. " sold waiting on a price"
        end
        P.blurb:SetText("Sales hit your bags. Buys land in the mailbox." .. extra)
        if pal then Ink(P.blurb, pal.mute) end
    end
    local cards = {
        { "Today", GoldText(u.today), MixSub(u.todayCount, u.todayBuyCount, u.todayBuy) },
        { "Yesterday", GoldText(u.yesterday), MixSub(u.yesterdayCount, u.yesterdayBuyCount, u.yesterdayBuy) },
        { "Last 7 days", GoldText((u.week or 0) / 7) .. "/day",
            ((u.weekBuy or 0) > 0) and (GoldText(u.weekBuy) .. " spent") or (GoldText(u.week or 0) .. " total") },
        { "Lifetime", GoldText(u.total), MixSub(u.count, u.buyCount, u.totalBuy) },
    }
    for i = 1, 4 do
        local c = P.cards and P.cards[i]
        local row = cards[i]
        if c and row then
            c.k:SetText(row[1])
            c.v:SetText(row[2])
            c.s:SetText(row[3])
            if pal then
                Ink(c.k, pal.mute)
                Ink(c.v, pal.gold)
                Ink(c.s, pal.cream)
                Tint(c.bg, pal.rowB)
            end
        end
    end
    if P.listed then
        P.listed:SetText((u.listed or 0) .. " still listed  ·  " .. GoldText(u.listedCopper or 0) .. " posted")
        if pal then Ink(P.listed, pal.cream) end
    end
    local recent = u.recent or {}
    local n = #recent
    for i = 1, #(P.sales or {}) do
        local r = P.sales[i]
        local e = recent[n - i + 1]
        if not e then
            r:Hide()
        else
            local buy = e.kind == "buy"
            r.left:SetText(e.name or (buy and "Purchase" or "Sale"))
            r.mid:SetText((buy and "bought  " or "sold  ") .. Ago(e.t))
            r.right:SetText((buy and "−" or "") .. GoldText(e.copper))
            if pal then
                Ink(r.left, pal.cream)
                Ink(r.mid, pal.mute)
                Ink(r.right, buy and SPEND or pal.gold)
                Tint(r.bg, (i % 2 == 0) and pal.rowA or pal.rowB)
            end
            r:Show()
        end
    end
    for i = 1, #(P.days or {}) do
        local r = P.days[i]
        local e = u.dayRows and u.dayRows[i]
        if not e then
            r:Hide()
        else
            r.left:SetText(e.label)
            r.mid:SetText(DayMid(e))
            r.right:SetText(DayRight(e))
            if pal then
                local spendOnly = (e.buyCopper or 0) > 0 and (e.copper or 0) <= 0
                local any = (e.copper or 0) > 0 or (e.buyCopper or 0) > 0
                Ink(r.left, pal.cream)
                Ink(r.mid, pal.mute)
                Ink(r.right, spendOnly and SPEND or (any and pal.gold or pal.mute))
                Tint(r.bg, (i % 2 == 0) and pal.rowA or pal.rowB)
            end
            r:Show()
        end
    end
    if pal then
        if P.head then Ink(P.head, pal.cream) end
        if P.salesHead then Ink(P.salesHead, pal.mute) end
        if P.daysHead then Ink(P.daysHead, pal.mute) end
        if P.note then Ink(P.note, pal.mute) end
    end
end

local function LayoutPanel()
    local P = T.ui
    if not P or not P.panel then return end
    local w = P.panel:GetWidth() or 720
    if w < 400 then w = 400 end
    local gap = 8
    local cw = (w - 16 - 3 * gap) / 4
    for i = 1, 4 do
        local c = P.cards[i]
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", 8 + (i - 1) * (cw + gap), -92)
        c:SetWidth(cw)
        c:SetHeight(CARD_H)
    end
    local colW = (w - 24) / 2
    P.salesHead:ClearAllPoints()
    P.salesHead:SetPoint("TOPLEFT", 12, -92 - CARD_H - 16)
    P.daysHead:ClearAllPoints()
    P.daysHead:SetPoint("TOPLEFT", 16 + colW, -92 - CARD_H - 16)
    for i = 1, #P.sales do
        local r = P.sales[i]
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 8, -92 - CARD_H - 36 - (i - 1) * LIST_ROW)
        r:SetWidth(colW)
    end
    for i = 1, #P.days do
        local r = P.days[i]
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 16 + colW, -92 - CARD_H - 36 - (i - 1) * LIST_ROW)
        r:SetWidth(colW)
    end
end

local function AskReset()
    if resetArm and GetTime() < resetArm then
        resetArm = nil
        qtEasyAuctionCharDB = qtEasyAuctionCharDB or {}
        qtEasyAuctionCharDB.sales = nil
        if T.ui and T.ui.reset and T.ui.reset.label then
            T.ui.reset.label:SetText("Reset")
        elseif T.ui and T.ui.reset then
            T.ui.reset:SetText("Reset")
        end
        PaintPanel()
        print("|cff00ff00qtEasyAuction:|r Auction gold history cleared.")
        return
    end
    resetArm = GetTime() + 4
    if T.ui and T.ui.reset and T.ui.reset.label then
        T.ui.reset.label:SetText("Confirm")
    elseif T.ui and T.ui.reset then
        T.ui.reset:SetText("Confirm")
    end
end

local function CreatePanel()
    T.panel = T.panel or _G.qtEasyAuctionStatsPanel
    if T.panel then
        local page = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.pages and _G.qtEasyAuctionSkin.pages.stats
        if page and T.panel:GetParent() ~= page then
            T.panel:SetParent(page)
            T.panel:SetAllPoints(page)
        end
        T.panel:Show()
        LayoutPanel()
        PaintPanel()
        return
    end
    local Skin = _G.qtEasyAuctionSkin
    if Skin and Skin.Create then Skin.Create() end
    local page = Skin and Skin.pages and Skin.pages.stats
    local parent = page or PeloriaAuctionHouseFrame
    if not parent then return end
    local panel = CreateFrame("Frame", "qtEasyAuctionStatsPanel", parent)
    panel:SetAllPoints(parent)
    panel:EnableMouse(true)
    T.panel = panel
    T.ui = { panel = panel, cards = {}, sales = {}, days = {} }
    local P = T.ui

    local reset = Cute(panel, 90, 32, "Reset")
    reset:SetPoint("TOPRIGHT", -8, -8)
    reset:SetFrameLevel((panel:GetFrameLevel() or 1) + 8)
    reset:SetScript("OnClick", AskReset)
    P.reset = reset

    P.head = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    P.head:SetPoint("TOPLEFT", 12, -10)
    P.head:SetText("Auction gold")

    P.hero = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    P.hero:SetPoint("TOPLEFT", 12, -36)
    P.hero:SetText("0g in  ·  0g out")

    P.blurb = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    P.blurb:SetPoint("TOPLEFT", P.hero, "BOTTOMLEFT", 0, -4)
    P.blurb:SetPoint("RIGHT", reset, "LEFT", -12, 0)
    P.blurb:SetJustifyH("LEFT")
        P.blurb:SetText("Sales hit your bags. Buys land in the mailbox.")

    for i = 1, 4 do
        P.cards[i] = Card(panel)
    end

    P.listed = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    P.listed:SetPoint("TOPRIGHT", reset, "BOTTOMRIGHT", 0, -8)
    P.listed:SetJustifyH("RIGHT")
    P.listed:SetText("")

    P.salesHead = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    P.salesHead:SetText("Recent")
    P.daysHead = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    P.daysHead:SetText("By day")

    for i = 1, 12 do
        P.sales[i] = ListRow(panel)
        P.days[i] = ListRow(panel)
    end

    P.note = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    P.note:SetPoint("BOTTOMLEFT", 12, 8)
    P.note:SetPoint("BOTTOMRIGHT", -12, 8)
    P.note:SetJustifyH("LEFT")
    P.note:SetText("Loot, vendors, and trades are ignored. Unlisting is not a sale. Buys count when the AH confirms them.")

    panel:SetScript("OnSizeChanged", function()
        LayoutPanel()
        PaintPanel()
    end)
    panel:SetScript("OnShow", function()
        LayoutPanel()
        PaintPanel()
    end)
    LayoutPanel()
    PaintPanel()
    panel:Show()
end

function T.Refresh()
    if T.panel and T.panel:IsVisible() then
        PaintPanel()
    end
end

function T.ApplySkin()
    PaintPanel()
end

function T.OnShown()
    CreatePanel()
    if T.panel then T.panel:Show() end
    LayoutPanel()
    PaintPanel()
end

function T.Slash(msg)
    msg = string.lower(string.gsub(msg or "", "^%s+", ""))
    if msg == "goldreset" then
        qtEasyAuctionCharDB = qtEasyAuctionCharDB or {}
        qtEasyAuctionCharDB.sales = nil
        watch, watchLeft = nil, nil
        Paint()
        print("|cff00ff00qtEasyAuction:|r Auction gold history cleared.")
        return true
    end
    if msg ~= "gold" then return false end
    local u = T.Summary()
    print("|cff00ff00qtEasyAuction:|r Auction gold  " .. GoldText(u.today) .. " sold  ·  "
        .. GoldText(u.todayBuy or 0) .. " spent today")
    print("  " .. (u.todayCount or 0) .. " sold  ·  " .. (u.todayBuyCount or 0) .. " bought  ·  "
        .. GoldText(u.total) .. " lifetime in  ·  " .. GoldText(u.totalBuy or 0) .. " out")
    if (u.pending or 0) > 0 then
        print("  " .. u.pending .. " sold — open the Auctions tab to price them")
    end
    return true
end

ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("CHAT_MSG_SYSTEM")
ev:RegisterEvent("PLAYER_MONEY")
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "CHAT_MSG_SYSTEM" then
        local name = SoldName(arg1)
        if name then OnSoldName(name) end
        return
    end
    if event == "PLAYER_MONEY" then
        OnGoldBump()
        return
    end
    SampleGold()
    InstallHook()
    if not peekWrapped.ok then
        hookTries, hookWait = 0, 0
    end
    ArmPulse()
    if type(_G.PeloriaRegisterGoldCallback) == "function" and not T._goldCb then
        T._goldCb = true
        pcall(_G.PeloriaRegisterGoldCallback, OnGoldBump)
    end
end)

ArmPulse()
