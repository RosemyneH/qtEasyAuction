local PAA = CreateFrame("Frame")
local PREFIX = "PELAH"

local COL_SIZE = 28
local hidePreviewAt = 0

local DB

local scanner
local function Scanner()
    if not scanner then
        scanner = CreateFrame("GameTooltip", "PeloriaAutoAuctionScanner", nil, "GameTooltipTemplate")
        scanner:SetOwner(UIParent, "ANCHOR_NONE")
    end
    if _G.PeloriaRegisterItemTooltip and not scanner.__PeloriaItemTooltipRegistered then
        _G.PeloriaRegisterItemTooltip(scanner)
    end
    return scanner
end

local function AccountDB()
    qtEasyAuctionDB = qtEasyAuctionDB or {}
    qtEasyAuctionDB.ignore = qtEasyAuctionDB.ignore or {}
    return qtEasyAuctionDB
end

local function LoadDB()
    AccountDB()
    local Skin = _G.qtEasyAuctionSkin
    if Skin and Skin.Char then
        DB = Skin.Char()
    else
        qtEasyAuctionCharDB = qtEasyAuctionCharDB or {}
        DB = qtEasyAuctionCharDB
    end
    if DB.priceGold == 50 or DB.priceGold == 150000 then
        DB.priceGold = 25000
    end
    if not DB.priceGold then DB.priceGold = 25000 end
    if DB.returnUnsold == nil then DB.returnUnsold = true end
    DB.itemPrices = DB.itemPrices or {}
    DB.weights = DB.weights or {}
    if DB.scorePrice == nil then DB.scorePrice = false end
    if DB.ratioPrice == nil then DB.ratioPrice = true end
    if DB.goldValue == nil then DB.goldValue = 40 end
    if DB.goldValue == 55 then DB.goldValue = 40 end
    if DB.ratioPrice then DB.scorePrice = false end
    if DB.postBindable == nil then DB.postBindable = false end
    if not DB.priceMax then DB.priceMax = 3000000 end
    if not DB.scoreCap then DB.scoreCap = 1000000 end
    if not DB.theme then DB.theme = "crypt" end
end

local function ParseGold(text)
    if not text then return nil end
    text = string.lower(string.gsub(text, "[,%s]", ""))
    local n, suf = string.match(text, "^([%d%.]+)([km]?)$")
    n = tonumber(n)
    if not n or n <= 0 then return nil end
    if suf == "k" then n = n * 1000
    elseif suf == "m" then n = n * 1000000
    end
    return math.floor(n + 0.5)
end

local function FormatGold(n)
    n = tonumber(n) or 0
    if n >= 1000000 then
        local m = n / 1000000
        if m == math.floor(m) then return tostring(m) .. "m" end
        return string.format("%.1fm", m)
    end
    if n >= 1000 then
        local k = n / 1000
        if k == math.floor(k) then return tostring(k) .. "k" end
        return string.format("%.1fk", k)
    end
    return tostring(n)
end

local function Clean(s)
    if not s then return "" end
    s = string.gsub(s, "|c%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|C%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|r", "")
    s = string.gsub(s, "|T.-|t", "")
    s = string.gsub(s, "|H.-|h(.-)|h", "%1")
    s = string.gsub(s, "|n", " ")
    return s
end

local function ReadTooltipLines(tip)
    local name = tip:GetName()
    local lines = {}
    for i = 1, tip:NumLines() do
        local fs = _G[name .. "TextLeft" .. i]
        local t = fs and fs:GetText()
        if t then lines[#lines + 1] = t end
    end
    return lines
end

local function LineIsTag(line)
    local low = string.lower(Clean(line))
    if string.find(low, "if soulbound", 1, true) then return true end
    if string.find(low, "soulbound stats", 1, true) then return true end
    return false
end

local function StateFromLines(lines)
    local s = {}
    if not lines then return s end
    for _, text in ipairs(lines) do
        local low = string.lower(Clean(text))
        if string.find(low, "already soulbound", 1, true) then
            s.bound, s.known = true, true
        end
        if string.find(low, "soulbind available", 1, true) then
            s.available, s.known = true, true
        end
        if string.find(low, "class cannot soulbind", 1, true) then
            s.classBlocked, s.known = true, true
        end
        if LineIsTag(text) then s.known = true end
    end
    return s
end

local function Coherent(s)
    if s.classBlocked and (s.available or s.bound) then return false end
    return true
end

local function MythicFromLines(lines)
    if not lines then return nil end
    for _, text in ipairs(lines) do
        local low = string.lower(Clean(text))
        if string.find(low, "mythic", 1, true) then
            local raw = string.match(low, "mythic%s*%+%s*([%d%.,]+%s*[km]?)")
            local n = ParseGold(raw)
            if n and n > 0 then return n end
            if raw then
                raw = string.gsub(raw, "[,%s]", "")
                n = tonumber(raw)
                if n and n > 0 then return math.floor(n + 0.5) end
            end
        end
    end
    return nil
end

local TRADESMAN_TOOL_IDS = {
    [5956] = true, [2901] = true, [7005] = true, [6219] = true,
    [9149] = true, [10498] = true, [40772] = true, [20815] = true,
    [39505] = true, [40892] = true, [40893] = true, [6218] = true,
    [6339] = true, [11130] = true, [11145] = true, [16207] = true,
    [22461] = true, [22462] = true, [22463] = true, [44452] = true,
}

local function ItemIDFromLink(link)
    if not link then return nil end
    return tonumber(string.match(link, "item:(%d+)"))
end

local function IsTradesmanTool(link, itemName)
    local itemID = ItemIDFromLink(link)
    if itemID and TRADESMAN_TOOL_IDS[itemID] then return true end
    if not itemName then return false end
    local lower = string.lower(itemName)
    if string.find(lower, "runed", 1, true) and string.find(lower, " rod", 1, true) then
        return true
    end
    return false
end

local function IsIgnored(link)
    local id = ItemIDFromLink(link)
    local ignore = AccountDB().ignore
    return id and ignore and ignore[id]
end

local stateCache = {}
local SCAN_PER, SCORE_PER = 8, 4
local EMPTY = {}

local function BagItemState(b, s, link)
    local key = b * 100 + s
    local hit = stateCache[key]
    if hit and hit.link == link then return hit.state end
    local tip = Scanner()
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearLines()
    if not pcall(tip.SetBagItem, tip, b, s) then return {} end
    if tip:NumLines() == 0 then return {} end
    local lines = ReadTooltipLines(tip)
    local state = StateFromLines(lines)
    state.mythic = MythicFromLines(lines)
    if not Coherent(state) then
        return { mythic = state.mythic, classBlocked = state.classBlocked, known = true }
    end
    stateCache[key] = { link = link, state = state }
    return state
end

local function ShouldPost(link, bag, slot)
    if not link then return false end
    if IsIgnored(link) then return false end

    local itemName, _, quality, _, _, itemType, itemSubType = GetItemInfo(link)
    if not itemName then return false end
    if quality and quality >= 6 then return false end
    if itemType == "Quest" then return false end

    local lowerName = string.lower(itemName)
    if string.find(lowerName, "hearthstone", 1, true) then return false end
    if IsTradesmanTool(link, itemName) then return false end
    if itemSubType == "Junk" then return true end

    local state = BagItemState(bag, slot, link)
    if state.bound then return true end
    if state.classBlocked and not state.available then return true end
    if state.available then
        LoadDB()
        return DB.postBindable and true or false
    end
    if not state.known and (itemType == "Armor" or itemType == "Weapon") then
        return true
    end
    return false
end

local FillItemScore
local EnsureTick
local RefreshPostList
local RefreshPreview
local RequestPaint
local QueueBagRefresh
local WaitingScores

local sortKey, sortDesc = "score", true

local function MakeItem(b, s, link)
    local texture, count = GetContainerItemInfo(b, s)
    local name, _, quality = GetItemInfo(link)
    return {
        bag = b,
        slot = s,
        link = link,
        itemID = ItemIDFromLink(link),
        texture = texture,
        count = count or 1,
        name = name or "",
        quality = quality or 0,
        score = 0,
        scoreReady = false,
    }
end

local bagItems
local bagSoon = 0
local listBusy, listDirty = false, false
local paintSoon = 0
local scan = { on = false, bag = 0, slot = 1, items = nil }
local POST_BATCH, POST_TICK = 80, 0.1
local postJobs, postIdx, postWait, postSent, postRet, postHow, postBagDirty
local postPump = CreateFrame("Frame", nil, UIParent)
postPump:Hide()

local function InvalidateBags()
    bagItems = nil
    stateCache = {}
    scan.on = false
end

local function FinishScan(items)
    scan.on = false
    bagItems = items or {}
    paintSoon = 0
    if RefreshPostList then RefreshPostList() end
    if PAA.preview and PAA.preview:IsShown() and RefreshPreview then RefreshPreview() end
    EnsureTick()
end

local function PumpBagScan()
    if not scan.on then return false end
    local n = 0
    while n < SCAN_PER do
        if scan.bag > 4 then
            FinishScan(scan.items)
            return false
        end
        local slots = GetContainerNumSlots(scan.bag) or 0
        if scan.slot > slots then
            scan.bag = scan.bag + 1
            scan.slot = 1
        else
            local link = GetContainerItemLink(scan.bag, scan.slot)
            if link and ShouldPost(link, scan.bag, scan.slot) then
                scan.items[#scan.items + 1] = MakeItem(scan.bag, scan.slot, link)
            end
            scan.slot = scan.slot + 1
            n = n + 1
        end
    end
    return true
end

local function StartBagScan()
    scan.on = true
    scan.bag, scan.slot = 0, 1
    scan.items = {}
    EnsureTick()
end

-- ʕ •ᴥ•ʔ✿ sync path for Post All only — UI uses StartBagScan ✿ ʕ •ᴥ•ʔ
local function CollectItems()
    local items = {}
    for b = 0, 4 do
        local slots = GetContainerNumSlots(b) or 0
        for s = 1, slots do
            local link = GetContainerItemLink(b, s)
            if link and ShouldPost(link, b, s) then
                items[#items + 1] = MakeItem(b, s, link)
            end
        end
    end
    return items
end

local function Items()
    if bagItems then return bagItems end
    if scan.on then return scan.items or EMPTY end
    if bagSoon > 0 then return EMPTY end
    StartBagScan()
    return EMPTY
end

local SENTINEL_BASE, SENTINEL_MAX = 20000, 60020000
local PriceGold

local function AffixFromLink(link)
    if not link then return 0 end
    local _, _, _, _, _, _, suffix =
        string.match(link, "item:(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+)")
    suffix = tonumber(suffix)
    if not suffix then return 0 end
    if suffix <= -(SENTINEL_BASE + 1) and suffix >= -SENTINEL_MAX then return 0 end
    return suffix
end

local function MythicFromLink(link)
    if not link then return nil end
    local _, _, _, _, _, prism, suffix, _, renderLevel =
        string.match(link, "item:(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+)")
    prism = tonumber(prism)
    if prism and prism > SENTINEL_BASE and prism <= SENTINEL_MAX then
        return prism - SENTINEL_BASE
    end
    renderLevel = tonumber(renderLevel)
    if renderLevel and renderLevel > SENTINEL_BASE and renderLevel <= SENTINEL_MAX then
        return renderLevel - SENTINEL_BASE
    end
    suffix = tonumber(suffix)
    if suffix and suffix <= -(SENTINEL_BASE + 1) and suffix >= -SENTINEL_MAX then
        return -suffix - SENTINEL_BASE
    end
end

local function MythicFor(bag, slot, link)
    local D = _G.qtEasyAuctionDeals
    local v = D and D.BagMythic and D.BagMythic(bag, slot)
    if v and v > 0 then return v end
    v = MythicFromLink(link)
    if v and v > 0 then return v end
    local state = BagItemState(bag, slot, link)
    if state and state.mythic and state.mythic > 0 then return state.mythic end
    return 0
end

local scoreWarned

function FillItemScore(item)
    local D = _G.qtEasyAuctionDeals
    if not D or not D.PrimeAndScore then
        item.score, item.scoreReady = 0, false
        if not scoreWarned then
            scoreWarned = true
            print("|cffff5555qtEasyAuction:|r Post score unavailable — /reload if Deals failed to load.")
        end
        return
    end
    local level = MythicFor(item.bag, item.slot, item.link)
    if (not level or level <= 0) and D.MythicReady and not D.MythicReady() then
        item.score, item.scoreReady = 0, false
        return
    end
    local affix = AffixFromLink(item.link)
    local ok, score, ready = pcall(D.PrimeAndScore, item.itemID, level or 0, affix)
    if not ok then
        if not scoreWarned then
            scoreWarned = true
            print("|cffff5555qtEasyAuction:|r post score: " .. tostring(score))
        end
        item.score, item.scoreReady = 0, true
        return
    end
    item.score, item.scoreReady = score or 0, ready and true or false
end

local function RescoreItem(item)
    if not item or not item.itemID then return end
    local D = _G.qtEasyAuctionDeals
    local level = MythicFor(item.bag, item.slot, item.link)
    if D and D.ClearAsk then
        D.ClearAsk(item.itemID, level, AffixFromLink(item.link))
    end
    item.score, item.scoreReady = 0, false
    FillItemScore(item)
    if RefreshPostList then RefreshPostList() end
    EnsureTick()
end

RescoreMissing = function()
    stateCache = {}
    local items = bagItems or (scan.on and scan.items) or EMPTY
    local D = _G.qtEasyAuctionDeals
    for i = 1, #items do
        local it = items[i]
        if not it.scoreReady or (it.score or 0) <= 0 then
            if D and D.ClearAsk then
                D.ClearAsk(it.itemID, MythicFor(it.bag, it.slot, it.link), AffixFromLink(it.link))
            end
            it.score, it.scoreReady = 0, false
        end
    end
    RequestPaint()
    EnsureTick()
end

local function ShowItemTip(owner, bag, slot, itemID, link, anchor)
    if not bag then return end
    local level = MythicFor(bag, slot, link)
    PeloriaSoulbindHoverLevel = (level > 0) and level or nil
    GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
    GameTooltip:SetBagItem(bag, slot)
    local D = _G.qtEasyAuctionDeals
    if D and D.AddPreviewToTip then
        D.AddPreviewToTip(GameTooltip, itemID, level, AffixFromLink(link))
    end
    GameTooltip:Show()
    owner.tipAnchor = anchor or "ANCHOR_RIGHT"
    PAA.hover = owner
end

local function HideItemTip()
    PAA.hover = nil
    PeloriaSoulbindHoverLevel = nil
    GameTooltip:Hide()
end

local function ParseRatio(text)
    if not text then return nil end
    text = string.lower(string.gsub(text, "[,%s]", ""))
    local n = tonumber(text)
    if not n or n <= 0 then return nil end
    return n
end

local function FormatRatio(n)
    n = tonumber(n) or 40
    if n == math.floor(n) then return tostring(n) end
    return string.format("%.1f", n)
end

local function GoldValue()
    if PAA.ratioBox then
        local n = ParseRatio(PAA.ratioBox:GetText())
        if n then
            DB.goldValue = n
            return n
        end
    end
    return (DB and DB.goldValue) or 40
end

-- ʕ •ᴥ•ʔ✿ buyout = weighted score / gold-value ✿ ʕ •ᴥ•ʔ
local function GoldValuePrice(item)
    LoadDB()
    local score = tonumber(item and item.score) or 0
    if score <= 0 then return nil end
    local ratio = GoldValue()
    if ratio < 0.01 then ratio = 0.01 end
    local gold = math.floor(score / ratio + 0.5)
    if gold < 1 then gold = 1 end
    return gold
end

function PriceGold()
    if PAA.priceBox then
        local n = ParseGold(PAA.priceBox:GetText())
        if n then
            DB.priceGold = n
            return n
        end
    end
    return DB and DB.priceGold or 25000
end

local function PinnedPrice(id)
    if not id or not DB or not DB.itemPrices then return nil end
    return DB.itemPrices[id] or DB.itemPrices[tostring(id)]
end

local function ItemPrice(item)
    LoadDB()
    local id = item
    if type(item) == "table" then id = item.itemID end
    local pinned = PinnedPrice(id)
    if pinned then return pinned end
    if DB.ratioPrice then
        return GoldValuePrice(type(item) == "table" and item or nil)
    end
    return PriceGold()
end

-- ʕ •ᴥ•ʔ✿ bag buyout if every listing sells ✿ ʕ •ᴥ•ʔ
local function BagBuyout(items)
    items = items or Items()
    local gold, n, pending = 0, 0, 0
    for i = 1, #items do
        local it = items[i]
        local p = ItemPrice(it)
        if p and p >= 1 then
            gold = gold + p
            n = n + 1
        elseif not it.scoreReady then
            pending = pending + 1
        end
    end
    return gold, n, pending
end

local function PaintBagSum(items)
    if not PAA.sum then return end
    local gold, n, pending = BagBuyout(items)
    if n <= 0 and pending <= 0 then
        PAA.sum:SetText("—")
    elseif n <= 0 then
        PAA.sum:SetText("...")
    else
        local t = n .. " · " .. FormatGold(gold) .. "g"
        if pending > 0 then t = t .. "..." end
        PAA.sum:SetText(t)
    end
    PAA.sumGold, PAA.sumN, PAA.sumPending = gold, n, pending
end

local function SortName(item)
    local n = item and item.name
    if n and n ~= "" then return string.lower(n) end
    return string.lower(Clean(item and item.link or ""))
end

local function SortItems(items)
    if not items then return end
    local key, desc = sortKey or "score", sortDesc ~= false
    table.sort(items, function(a, b)
        if key == "name" then
            local va, vb = SortName(a), SortName(b)
            if va ~= vb then
                if desc then return va < vb end
                return va > vb
            end
            return (a.score or 0) > (b.score or 0)
        end
        local va, vb
        if key == "price" then
            va, vb = ItemPrice(a) or 0, ItemPrice(b) or 0
        else
            va, vb = a.score or 0, b.score or 0
        end
        if va == vb then
            local na, nb = SortName(a), SortName(b)
            if na ~= nb then return na < nb end
        end
        if desc then return va > vb end
        return va < vb
    end)
end

local function ComputedPrice(item)
    LoadDB()
    if DB.ratioPrice then return GoldValuePrice(item) end
    return PriceGold()
end

local function SaveItemPrice(itemID, gold)
    LoadDB()
    if not itemID then return end
    DB.itemPrices = DB.itemPrices or {}
    if gold and gold > 0 then
        DB.itemPrices[itemID] = gold
    else
        DB.itemPrices[itemID] = nil
    end
end

local function ReturnFlag()
    if PAA.returnCheck then
        DB.returnUnsold = PAA.returnCheck:GetChecked() and true or false
    end
    return (DB and DB.returnUnsold) and 1 or 0
end

local RefreshPostHeads
local RescoreMissing

local function AskMythicBags()
    local D = _G.qtEasyAuctionDeals
    if D and D.AskMythicBags then
        D.AskMythicBags(function()
            QueueBagRefresh()
        end)
    end
end

local function SetPostLabel(text)
    if not PAA.button then return end
    if PAA.button.label then
        PAA.button.label:SetText(text)
    else
        PAA.button:SetText(text)
    end
end

-- ʕ ● ᴥ ●ʔ✿ 80 SELL packets per 0.1s — server packet cap ✿ ʕ ● ᴥ ●ʔ
local function SendSell(b, s, stack, stacks, copper, ret)
    if type(PeloriaSend) ~= "function" then return false end
    return pcall(PeloriaSend, string.format(
        "%s^SELL^%d^%d^%d^%d^%.0f^%d",
        PREFIX, b, s, stack, stacks, copper, ret))
end

local function FinishPost()
    local sent = postSent or 0
    postJobs, postIdx, postWait = nil, 1, 0
    postPump:Hide()
    SetPostLabel("Post All")
    if sent == 0 then
        print("|cffff0000PeloriaAuto:|r PeloriaSend failed — stand near an auctioneer.")
        return
    end
    print("|cff00ff00PeloriaAuto:|r Sent " .. sent .. " listing(s). " .. (postHow or "") .. ".")
end

local function PumpPost()
    local jobs = postJobs
    if not jobs then return false end
    local n = 0
    while n < POST_BATCH and postIdx <= #jobs do
        local job = jobs[postIdx]
        postIdx = postIdx + 1
        n = n + 1
        if job and SendSell(job.bag, job.slot, job.stack, 1, job.copper, postRet) then
            postSent = postSent + 1
            if _G.qtEasyAuctionSales and _G.qtEasyAuctionSales.NotePost then
                _G.qtEasyAuctionSales.NotePost(job.name, job.copper)
            end
            -- ʕ ● ᴥ ●ʔ✿ pin last buyout on legendaries ✿ ʕ ● ᴥ ●ʔ
            if (job.quality or 0) >= 5 then
                SaveItemPrice(job.itemID, job.gold)
            end
        end
    end
    if postIdx > #jobs then
        FinishPost()
        return false
    end
    SetPostLabel(postIdx .. "/" .. #jobs)
    return true
end

postPump:SetScript("OnUpdate", function(self, delta)
    if not postJobs then
        self:Hide()
        return
    end
    postWait = (postWait or 0) + (delta or 0)
    if postWait < POST_TICK then return end
    postWait = 0
    local ok, more = pcall(PumpPost)
    if not ok then
        print("|cffff0000PeloriaAuto:|r Post failed — " .. tostring(more))
        FinishPost()
    end
end)

local function Start()
    if postJobs then
        print("|cffffff00PeloriaAuto:|r Already posting " .. (postIdx - 1) .. "/" .. #postJobs .. ".")
        return
    end
    if type(PeloriaSend) ~= "function" then
        print("|cffff0000PeloriaAuto:|r PeloriaSend not found. Open the Peloria AH first.")
        return
    end

    LoadDB()
    if not DB.ratioPrice then
        local gold = PriceGold()
        if not gold or gold <= 0 then
            print("|cffff0000PeloriaAuto:|r Set a buyout price first.")
            return
        end
    end

    local items = bagItems
    if scan.on then
        print("|cffffff00PeloriaAuto:|r Still scanning bags — wait a moment, then Post All.")
        return
    end
    if not items then
        items = CollectItems()
        bagItems = items
        EnsureTick()
    end
    if #items == 0 then
        print("|cffffff00PeloriaAuto:|r Nothing to post.")
        return
    end

    local jobs = {}
    for i = 1, #items do
        local item = items[i]
        local gold = ItemPrice(item)
        if gold and gold >= 1 then
            local maxStack = select(8, GetItemInfo(item.link)) or 1
            jobs[#jobs + 1] = {
                bag = item.bag,
                slot = item.slot,
                stack = math.min(item.count or 1, maxStack),
                copper = gold * 10000,
                gold = gold,
                itemID = item.itemID,
                name = item.name,
                quality = item.quality,
            }
        end
    end
    if #jobs == 0 then
        if WaitingScores() then
            print("|cffffff00PeloriaAuto:|r Prices still loading — try again in a moment.")
            EnsureTick()
        else
            print("|cffffff00PeloriaAuto:|r No scored items to post.")
        end
        return
    end
    if WaitingScores() and #jobs < #items then
        print("|cffffff00PeloriaAuto:|r Posting " .. #jobs .. " ready listing(s); " .. (#items - #jobs) .. " still pricing.")
    end

    local bagGold = 0
    for i = 1, #jobs do
        bagGold = bagGold + (jobs[i].gold or 0)
    end
    if DB.ratioPrice then
        postHow = "gold value " .. FormatRatio(GoldValue()) .. "/g"
    else
        postHow = "simple " .. FormatGold(PriceGold()) .. "g"
    end
    -- ʕノ•ᴥ•ʔノ first 80 leave on the next tick, not inside the click ✿ ʕノ•ᴥ•ʔノ
    postJobs, postIdx, postSent, postWait, postRet = jobs, 1, 0, POST_TICK, ReturnFlag()
    postBagDirty = false
    SetPostLabel("1/" .. #jobs)
    print("|cff00ff00PeloriaAuto:|r Posting " .. #jobs .. " listing(s)  ·  " .. FormatGold(bagGold) .. "g. " .. postHow .. ".")
    postPump:Show()
end

local BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local function EnsurePreview()
    if PAA.preview then return PAA.preview end
    local root = CreateFrame("Frame", "PeloriaAutoAuctionPreview", UIParent)
    root:SetFrameStrata("TOOLTIP")
    root:Hide()
    PAA.preview = root
    PAA.columns = {}
    return root
end

local function HidePreview()
    if PAA.preview then PAA.preview:Hide() end
    HideItemTip()
end

local function MouseOverPreview()
    if PAA.button and MouseIsOver(PAA.button) then return true end
    if PAA.dock and MouseIsOver(PAA.dock) then return true end
    if not PAA.columns then return false end
    for _, col in ipairs(PAA.columns) do
        if col:IsShown() and MouseIsOver(col) then return true end
    end
    return false
end

local function IgnoreItem(itemID, link)
    if not itemID then return end
    LoadDB()
    AccountDB().ignore[itemID] = true
    print("|cffffff00PeloriaAuto:|r Ignored", link or itemID)
    QueueBagRefresh()
end

local function AcquireColumn(i)
    local col = PAA.columns[i]
    if col then return col end
    col = CreateFrame("Frame", "PeloriaAutoAuctionCol" .. i, PAA.preview)
    col:SetBackdrop(BACKDROP)
    col:SetBackdropColor(0.09, 0.09, 0.09, 0.94)
    col:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    col:EnableMouse(true)
    col:SetWidth(240)
    col.header = col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    col.header:SetPoint("TOPLEFT", 12, -10)
    col.header:SetJustifyH("LEFT")
    col.foot = col:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    col.foot:SetPoint("BOTTOMLEFT", 12, 10)
    col.foot:SetJustifyH("LEFT")
    col.rows = {}
    PAA.columns[i] = col
    return col
end

local function AcquireRow(col, i)
    local row = col.rows[i]
    if row then return row end
    row = CreateFrame("Button", nil, col)
    row:SetHeight(18)
    row:RegisterForClicks("RightButtonUp")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(16)
    row.icon:SetHeight(16)
    row.icon:SetPoint("LEFT", 0, 0)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.text:SetPoint("RIGHT", 0, 0)
    row.text:SetJustifyH("LEFT")
    row:SetScript("OnEnter", function(self)
        if self.bag then
            ShowItemTip(self, self.bag, self.slot, self.itemID, self.link, "ANCHOR_LEFT")
        end
    end)
    row:SetScript("OnLeave", HideItemTip)
    row:SetScript("OnClick", function(self, btn)
        if btn == "RightButton" then IgnoreItem(self.itemID, self.link) end
    end)
    col.rows[i] = row
    return row
end

RefreshPreview = function()
    if not PAA.button or not PAA.preview or not PAA.preview.wantShow then return end
    local items = Items()
    local n = #items
    local cols = math.max(1, math.ceil(n / COL_SIZE))

    for i, col in ipairs(PAA.columns) do
        if i > cols then col:Hide() end
    end

    local anchor = PAA.button
    for c = 1, cols do
        local col = AcquireColumn(c)
        local startIdx = (c - 1) * COL_SIZE + 1
        local stopIdx = math.min(n, c * COL_SIZE)
        local rows = stopIdx >= startIdx and (stopIdx - startIdx + 1) or 0
        local extra = (c == 1) and 36 or 28
        col:ClearAllPoints()
        if c == 1 then
            col:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -6, 4)
        else
            col:SetPoint("TOPRIGHT", PAA.columns[c - 1], "TOPLEFT", -4, 0)
        end
        col:SetHeight(extra + 18 + rows * 18 + 22)
        if c == 1 then
            local gold, listings, pending = BagBuyout(items)
            local head = listings .. " listing" .. (listings == 1 and "" or "s")
            if listings > 0 then
                head = head .. "  ·  " .. FormatGold(gold) .. "g"
            end
            if pending > 0 then head = head .. "..." end
            col.header:SetText("|cffffd100" .. head .. "|r")
            col.foot:SetText("|cff888888Right-click an item to ignore it.|r")
        else
            col.header:SetText(string.format("|cffffd100Additional items (%d-%d of %d)|r", startIdx, stopIdx, n))
            col.foot:SetText("")
        end
        if n == 0 and c == 1 then
            col.header:SetText("|cffffd100Nothing to post.|r")
            col.foot:SetText("|cff888888Right-click ignored items via /qta clearignore|r")
            col:SetHeight(54)
        end
        local y0 = (c == 1) and -30 or -28
        for r = 1, COL_SIZE do
            local row = AcquireRow(col, r)
            local item = items[startIdx + r - 1]
            if item then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", 10, y0 - (r - 1) * 18)
                row:SetPoint("TOPRIGHT", -10, y0 - (r - 1) * 18)
                row.bag, row.slot = item.bag, item.slot
                row.itemID, row.link = item.itemID, item.link
                row.icon:SetTexture(item.texture)
                local label = item.link
                if item.count and item.count > 1 then
                    label = label .. " |cffaaaaaax" .. item.count .. "|r"
                end
                row.text:SetText(label)
                row:Show()
            else
                row:Hide()
            end
        end
        col:Show()
    end
    PAA.preview:Show()
end

local function ShowPreview()
    EnsurePreview()
    PAA.preview.wantShow = true
    hidePreviewAt = 0
    RefreshPreview()
    EnsureTick()
end

local ticking

local function FlushBags()
    bagSoon = 0
    StartBagScan()
end

WaitingScores = function()
    local items = bagItems
    if not items then return false end
    for i = 1, #items do
        if not items[i].scoreReady then return true end
    end
    return false
end

local function PumpScores()
    local items = bagItems
    if not items then return false end
    local n = 0
    for i = 1, #items do
        local it = items[i]
        if not it.scoreReady then
            FillItemScore(it)
            n = n + 1
            if n >= SCORE_PER then break end
        end
    end
    return n > 0
end

RequestPaint = function()
    listDirty = true
    EnsureTick()
end

local function OnTick(self, delta)
    local busy = false
    if bagSoon > 0 then
        busy = true
        bagSoon = bagSoon - delta
        if bagSoon <= 0 then FlushBags() end
    end
    if scan.on then
        busy = true
        PumpBagScan()
        listDirty = true
    end
    if WaitingScores() then
        busy = true
        if PumpScores() then listDirty = true end
    end
    if listDirty then
        busy = true
        paintSoon = (paintSoon or 0) + (delta or 0)
        if paintSoon >= 0.12 then
            paintSoon = 0
            listDirty = false
            if RefreshPostList then RefreshPostList() end
            if PAA.preview and PAA.preview:IsShown() and RefreshPreview then
                RefreshPreview()
            end
        end
    end
    if PAA.preview and PAA.preview:IsShown() then
        busy = true
        if MouseOverPreview() then
            hidePreviewAt = 0
        else
            hidePreviewAt = hidePreviewAt + delta
            if hidePreviewAt > 0.15 then
                PAA.preview.wantShow = false
                HidePreview()
            end
        end
    end
    if not busy then
        ticking = false
        self:SetScript("OnUpdate", nil)
    end
end

EnsureTick = function()
    if ticking then return end
    ticking = true
    PAA:SetScript("OnUpdate", OnTick)
end

QueueBagRefresh = function()
    bagItems = nil
    stateCache = {}
    scan.on = false
    bagSoon = 0.15
    EnsureTick()
end

local function ApplyPostSkin()
    local Skin = _G.qtEasyAuctionSkin
    local pal = Skin and Skin.C and Skin.C()
    if not pal then return end
    if PAA.blurb then PAA.blurb:SetTextColor(pal.mute[1], pal.mute[2], pal.mute[3]) end
    if PAA.unit then PAA.unit:SetTextColor(pal.gold[1], pal.gold[2], pal.gold[3]) end
    if PAA.sum then PAA.sum:SetTextColor(pal.gold[1], pal.gold[2], pal.gold[3]) end
    if PAA.ratioU then PAA.ratioU:SetTextColor(pal.mute[1], pal.mute[2], pal.mute[3]) end
    if PAA.headBg then PAA.headBg:SetVertexColor(pal.head[1], pal.head[2], pal.head[3], pal.head[4] or 1) end
    if PAA.headLine then PAA.headLine:SetVertexColor(pal.accent[1], pal.accent[2], pal.accent[3], 0.9) end
    if PAA.SyncMode then PAA.SyncMode() end
    if RefreshPostHeads then RefreshPostHeads() end
    if RefreshPostList then RefreshPostList() end
end

local function CreateButton()
    PAA.dock = PAA.dock or _G.PeloriaAutoAuctionDock
    if PAA.dock then return end
    if not PeloriaAuctionHouseFrame then return end
    LoadDB()
    if _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.Create then
        _G.qtEasyAuctionSkin.Create()
    end
    local page = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.pages and _G.qtEasyAuctionSkin.pages.post
    local parent = page or PeloriaAuctionHouseFrame
    local Skin = _G.qtEasyAuctionSkin

    AskMythicBags()
    local dock = CreateFrame("Frame", "PeloriaAutoAuctionDock", parent)
    if page then
        dock:SetAllPoints(page)
    else
        dock:SetWidth(340)
        dock:SetHeight(28)
        dock:SetPoint("TOPRIGHT", PeloriaAuctionHouseFrame, "TOPRIGHT", -36, -8)
    end
    PAA.dock = dock
    local top = (dock:GetFrameLevel() or 1) + 8

    local function BindGoldBox(box, get, set, fallback)
        box:SetMaxLetters(12)
        box:SetText(FormatGold(get() or fallback))
        local function save(self)
            local n = ParseGold(self:GetText())
            if n then set(n); self:SetText(FormatGold(n))
            else self:SetText(FormatGold(get() or fallback)) end
            if RefreshPostList then RefreshPostList() end
        end
        box:SetScript("OnEnterPressed", function(self) save(self); self:ClearFocus() end)
        box:SetScript("OnEditFocusLost", save)
        box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        return box
    end

    local button
    if Skin and Skin.CuteButton then
        button = Skin.CuteButton(dock, 124, 32, "Post All", "post")
    else
        button = CreateFrame("Button", "PeloriaAutoPostButton", dock, "UIPanelButtonTemplate")
        button:SetWidth(110)
        button:SetHeight(28)
        button:SetText("Post All")
    end
    button:SetPoint("TOPRIGHT", -8, -6)
    button:SetFrameLevel(top)
    button:SetScript("OnClick", Start)
    button:SetScript("OnEnter", ShowPreview)
    PAA.button = button

    local sumHit = CreateFrame("Button", nil, dock)
    sumHit:SetHeight(32)
    sumHit:SetWidth(120)
    sumHit:SetPoint("RIGHT", button, "LEFT", -8, 0)
    sumHit:SetFrameLevel(top)
    local sum = sumHit:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sum:SetPoint("RIGHT", 0, 0)
    sum:SetJustifyH("RIGHT")
    sum:SetText("—")
    sumHit:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Bag buyout")
        local gold, n, pending = PAA.sumGold or 0, PAA.sumN or 0, PAA.sumPending or 0
        GameTooltip:AddLine("Total gold if every listing in your bags sells.", 0.8, 0.8, 0.8, true)
        GameTooltip:AddDoubleLine("Listings", tostring(n), 1, 1, 1, 1, 0.84, 0.45)
        GameTooltip:AddDoubleLine("Buyout", FormatGold(gold) .. "g", 1, 1, 1, 1, 0.84, 0.45)
        if pending > 0 then
            GameTooltip:AddLine(pending .. " still scoring", 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)
    sumHit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    PAA.sum = sum
    PAA.sumHit = sumHit

    local ratioChip = Skin and Skin.Chip and Skin.Chip(dock, 108, 32, "Gold value")
    if ratioChip then
        ratioChip:SetPoint("TOPLEFT", 8, -6)
        ratioChip:SetFrameLevel(top)
        ratioChip.OnToggle = function()
            DB.ratioPrice = true
            if PAA.SyncMode then PAA.SyncMode() end
            if RefreshPostList then RefreshPostList() end
        end
    end
    PAA.ratioChip = ratioChip

    local ratioField = Skin and Skin.Field and Skin.Field(dock, 48, 32, "PeloriaAutoAuctionGoldValue")
    local ratioBox
    if ratioField then
        ratioField:SetPoint("LEFT", ratioChip, "RIGHT", 6, 0)
        ratioField:SetFrameLevel(top)
        ratioBox = ratioField.box
    else
        ratioBox = CreateFrame("EditBox", "PeloriaAutoAuctionGoldValue", dock, "InputBoxTemplate")
        ratioBox:SetWidth(40)
        ratioBox:SetHeight(20)
        ratioBox:SetPoint("TOPLEFT", 122, -12)
        ratioBox:SetAutoFocus(false)
    end
    ratioBox:SetMaxLetters(8)
    ratioBox:SetText(FormatRatio(DB.goldValue or 40))
    local function SaveRatio(self)
        local n = ParseRatio(self:GetText())
        if n then DB.goldValue = n; self:SetText(FormatRatio(n))
        else self:SetText(FormatRatio(DB.goldValue or 40)) end
        if RefreshPostList then RefreshPostList() end
    end
    ratioBox:SetScript("OnEnterPressed", function(self) SaveRatio(self); self:ClearFocus() end)
    ratioBox:SetScript("OnEditFocusLost", SaveRatio)
    ratioBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    PAA.ratioBox = ratioBox
    PAA.ratioField = ratioField

    local ratioU = dock:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ratioU:SetPoint("LEFT", ratioField or ratioBox, "RIGHT", 6, 0)
    ratioU:SetText("/g")
    PAA.ratioU = ratioU

    local simpleChip = Skin and Skin.Chip and Skin.Chip(dock, 72, 32, "Simple")
    if simpleChip then
        simpleChip:SetPoint("LEFT", ratioU, "RIGHT", 14, 0)
        simpleChip:SetFrameLevel(top)
        simpleChip.OnToggle = function()
            DB.ratioPrice = false
            if PAA.SyncMode then PAA.SyncMode() end
            if RefreshPostList then RefreshPostList() end
        end
    end
    PAA.simpleChip = simpleChip

    local priceField = Skin and Skin.Field and Skin.Field(dock, 72, 32, "PeloriaAutoAuctionPrice")
    local box
    if priceField then
        priceField:SetPoint("LEFT", simpleChip or ratioU, "RIGHT", 6, 0)
        priceField:SetFrameLevel(top)
        box = priceField.box
    else
        box = CreateFrame("EditBox", "PeloriaAutoAuctionPrice", dock, "InputBoxTemplate")
        box:SetWidth(80)
        box:SetHeight(22)
        box:SetPoint("LEFT", simpleChip or ratioU, "RIGHT", 6, 0)
        box:SetAutoFocus(false)
    end
    BindGoldBox(box, function() return DB.priceGold end, function(n) DB.priceGold = n end, 25000)
    PAA.priceBox = box
    PAA.priceField = priceField

    local unit = dock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    unit:SetPoint("LEFT", priceField or box, "RIGHT", 4, 0)
    unit:SetText("g")
    PAA.unit = unit

    local mailChip = Skin and Skin.Chip and Skin.Chip(dock, 132, 28, "Mail unsold", true)
    if mailChip then
        mailChip:SetPoint("TOPLEFT", 8, -44)
        mailChip.OnToggle = function(self, on)
            DB.returnUnsold = on and true or false
            self:SetOn(DB.returnUnsold)
        end
    end
    PAA.mailChip = mailChip
    PAA.returnCheck = mailChip

    local bindChip = Skin and Skin.Chip and Skin.Chip(dock, 140, 28, "Post bindable", true)
    if bindChip then
        bindChip:SetPoint("LEFT", mailChip, "RIGHT", 6, 0)
        bindChip.OnToggle = function(self, on)
            DB.postBindable = on and true or false
            self:SetOn(DB.postBindable)
            QueueBagRefresh()
        end
    end
    PAA.bindChip = bindChip
    PAA.bindCheck = bindChip

    local weights
    if Skin and Skin.CuteButton then
        weights = Skin.CuteButton(dock, 108, 28, "Weights")
    else
        weights = CreateFrame("Button", nil, dock, "UIPanelButtonTemplate")
        weights:SetWidth(90)
        weights:SetHeight(28)
        weights:SetText("Weights")
    end
    weights:SetPoint("TOPRIGHT", -8, -44)
    weights:SetFrameLevel(top)
    weights:EnableMouse(true)
    weights:RegisterForClicks("LeftButtonUp")
    weights:SetScript("OnClick", function()
        local Deals = _G.qtEasyAuctionDeals
        if not Deals or not Deals.ShowWeights then return end
        local ok, err = pcall(Deals.ShowWeights, "post")
        if not ok then
            print("|cffff5555qtEasyAuction:|r weights: " .. tostring(err))
        end
    end)
    PAA.weightBtn = weights

    local blurb = dock:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    blurb:SetPoint("LEFT", bindChip or mailChip, "RIGHT", 12, 0)
    blurb:SetPoint("RIGHT", weights, "LEFT", -8, 0)
    blurb:SetJustifyH("LEFT")
    blurb:SetText("pin a row to override  ·  right-click ignores")
    PAA.blurb = blurb

    PAA.SyncMode = function()
        LoadDB()
        if PAA.ratioChip and PAA.ratioChip.SetOn then PAA.ratioChip:SetOn(DB.ratioPrice) end
        if PAA.simpleChip and PAA.simpleChip.SetOn then PAA.simpleChip:SetOn(not DB.ratioPrice) end
        if PAA.mailChip and PAA.mailChip.SetOn then PAA.mailChip:SetOn(DB.returnUnsold) end
        if PAA.bindChip and PAA.bindChip.SetOn then PAA.bindChip:SetOn(DB.postBindable) end
    end
    PAA.SyncMode()

    local head = CreateFrame("Frame", nil, dock)
    head:SetPoint("TOPLEFT", 8, -78)
    head:SetPoint("TOPRIGHT", -24, -78)
    head:SetHeight(22)
    local ht = head:CreateTexture(nil, "BACKGROUND")
    ht:SetAllPoints()
    ht:SetTexture("Interface\\Buttons\\WHITE8X8")
    local line = head:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", 0, 0)
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    PAA.head = head
    PAA.headBg = ht
    PAA.headLine = line
    local function HeadBtn(label, key, justify)
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
            if RefreshPostHeads then RefreshPostHeads() end
            if RefreshPostList then RefreshPostList() end
        end)
        return b
    end
    PAA.headBtns = {
        HeadBtn("Item", "name", "LEFT"),
        HeadBtn("Score", "score", "RIGHT"),
        HeadBtn("Buyout", "price", "RIGHT"),
    }
    do
        local scoreHead = PAA.headBtns[2]
        scoreHead:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local sortClick = scoreHead:GetScript("OnClick")
        scoreHead:SetScript("OnClick", function(self, btn)
            if btn == "RightButton" then
                RescoreMissing()
                return
            end
            if sortClick then sortClick(self, btn) end
        end)
        scoreHead:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText("Score")
            GameTooltip:AddLine("Left-click sorts. Right-click rescores missing.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        scoreHead:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    RefreshPostHeads = function()
        local item, score, buy = PAA.headBtns[1], PAA.headBtns[2], PAA.headBtns[3]
        buy:ClearAllPoints()
        buy:SetPoint("RIGHT", -6, 0)
        buy:SetWidth(72)
        score:ClearAllPoints()
        score:SetPoint("RIGHT", buy, "LEFT", -10, 0)
        score:SetWidth(56)
        item:ClearAllPoints()
        item:SetPoint("LEFT", 32, 0)
        item:SetPoint("RIGHT", score, "LEFT", -8, 0)
        for i = 1, #PAA.headBtns do
            local b = PAA.headBtns[i]
            local mark = ""
            if sortKey == b.key then mark = sortDesc and " ▼" or " ▲" end
            b.fs:SetText(b.sortName .. mark)
            local pal = Skin and Skin.C and Skin.C()
            if sortKey == b.key then
                if pal then b.fs:SetTextColor(pal.gold[1], pal.gold[2], pal.gold[3])
                else b.fs:SetTextColor(1, 0.92, 0.55) end
            else
                if pal then b.fs:SetTextColor(pal.headTxt[1], pal.headTxt[2], pal.headTxt[3])
                else b.fs:SetTextColor(0.95, 0.78, 0.92) end
            end
        end
    end

    local list = CreateFrame("Frame", nil, dock)
    list:SetPoint("TOPLEFT", 8, -102)
    list:SetPoint("BOTTOMRIGHT", -24, 8)
    PAA.list = list
    local bar = CreateFrame("Slider", "qtEasyAuctionPostBar", dock, "UIPanelScrollBarTemplate")
    bar:SetPoint("TOPRIGHT", -4, -102)
    bar:SetPoint("BOTTOMRIGHT", -4, 8)
    bar:SetValueStep(1)
    bar:SetScript("OnValueChanged", function(self, value)
        local off = math.floor((value or 0) + 0.5)
        if off == (PAA.offset or 0) then return end
        PAA.offset = off
        if not listBusy and RefreshPostList then RefreshPostList() end
    end)
    PAA.bar = bar
    PAA.offset = 0
    PAA.rows = {}
    local ROW_H, ROW_MAX = 28, 18
    for i = 1, ROW_MAX do
        local r = CreateFrame("Button", nil, list)
        r:SetHeight(ROW_H)
        r:EnableMouse(true)
        r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        r.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetWidth(22)
        r.icon:SetHeight(22)
        r.icon:SetPoint("LEFT", 6, 0)
        r.icon:SetTexCoord(0.03, 0.97, 0.03, 0.97)
        r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.name:SetPoint("LEFT", 32, 0)
        r.scoreFs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.scoreFs:SetPoint("RIGHT", -88, 0)
        r.scoreFs:SetWidth(56)
        r.scoreFs:SetJustifyH("RIGHT")
        r.name:SetPoint("RIGHT", r.scoreFs, "LEFT", -8, 0)
        r.name:SetJustifyH("LEFT")
        local pb
        if Skin and Skin.Field then
            local wrap = Skin.Field(r, 72, 22, "qtEasyAuctionPostP" .. i)
            wrap:ClearAllPoints()
            wrap:SetPoint("RIGHT", -6, 0)
            pb = wrap.box
            r.priceWrap = wrap
        else
            pb = CreateFrame("EditBox", "qtEasyAuctionPostP" .. i, r, "InputBoxTemplate")
            pb:SetWidth(72)
            pb:SetHeight(20)
            pb:SetPoint("RIGHT", -6, 0)
            pb:SetAutoFocus(false)
        end
        pb:SetMaxLetters(12)
        local function CommitPrice(self)
            local n = ParseGold(self:GetText())
            local item = { itemID = r.itemID, score = r.score, quality = r.quality, scoreReady = r.scoreReady }
            local computed = ComputedPrice(item)
            if (r.quality or 0) >= 5 then
                if n and n > 0 then SaveItemPrice(r.itemID, n) end
            elseif n and computed and n == computed then
                SaveItemPrice(r.itemID, nil)
            else
                SaveItemPrice(r.itemID, n)
            end
            local p = ItemPrice(item)
            self:SetText(p and FormatGold(p) or "—")
            PaintBagSum()
        end
        pb:SetScript("OnEnterPressed", function(self)
            CommitPrice(self)
            self:ClearFocus()
        end)
        pb:SetScript("OnEditFocusLost", CommitPrice)
        pb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        r.price = pb
        r:SetScript("OnEnter", function(self)
            if self.bag then
                ShowItemTip(self, self.bag, self.slot, self.itemID, self.link, "ANCHOR_RIGHT")
            end
        end)
        r:SetScript("OnLeave", HideItemTip)
        r:SetScript("OnClick", function(self, btn)
            if btn == "RightButton" then
                IgnoreItem(self.itemID, self.link)
                return
            end
            if (self.score or 0) > 0 and self.scoreReady then return end
            local items = Items()
            for i = 1, #items do
                if items[i].bag == self.bag and items[i].slot == self.slot then
                    RescoreItem(items[i])
                    return
                end
            end
        end)
        PAA.rows[i] = r
    end

    RefreshPostList = function()
        if not PAA.rows then return end
        if listBusy then
            listDirty = true
            return
        end
        listBusy = true
        local ok, err = pcall(function()
            LoadDB()
            local pal = Skin and Skin.C and Skin.C()
            local items = Items()
            SortItems(items)
            local vis = 12
            if PAA.list and PAA.list:GetHeight() and PAA.list:GetHeight() > 0 then
                vis = math.max(6, math.min(18, math.floor(PAA.list:GetHeight() / ROW_H)))
            end
            PAA.offset = math.max(0, math.min(PAA.offset or 0, math.max(0, #items - vis)))
            if PAA.bar then
                local maxOff = math.max(0, #items - vis)
                PAA.bar:SetMinMaxValues(0, maxOff)
                PAA.bar:SetValue(PAA.offset)
                if maxOff > 0 then PAA.bar:Show() else PAA.bar:Hide() end
            end
            for i = 1, 18 do
                local r = PAA.rows[i]
                if i > vis then
                    r:Hide()
                else
                    local e = items[PAA.offset + i]
                    if not e then
                        r:Hide()
                    else
                        r:ClearAllPoints()
                        r:SetPoint("TOPLEFT", PAA.list, "TOPLEFT", 0, -((i - 1) * ROW_H))
                        r:SetPoint("TOPRIGHT", PAA.list, "TOPRIGHT", 0, -((i - 1) * ROW_H))
                        r.bag, r.slot, r.itemID, r.link = e.bag, e.slot, e.itemID, e.link
                        r.score, r.quality, r.scoreReady = e.score or 0, e.quality or 0, e.scoreReady
                        r.icon:SetTexture(e.texture)
                        r.icon:SetTexCoord(0.03, 0.97, 0.03, 0.97)
                        local label = e.link
                        if e.count and e.count > 1 then
                            label = label .. " |cffaaaaaax" .. e.count .. "|r"
                        end
                        r.name:SetText(label)
                        if r.scoreFs then
                            if e.scoreReady then
                                r.scoreFs:SetText(FormatGold(e.score or 0))
                                if pal then r.scoreFs:SetTextColor(pal.gold[1], pal.gold[2], pal.gold[3])
                                else r.scoreFs:SetTextColor(1, 0.84, 0.45) end
                            else
                                r.scoreFs:SetText(scan.on and ".." or "...")
                                if pal then r.scoreFs:SetTextColor(pal.mute[1], pal.mute[2], pal.mute[3])
                                else r.scoreFs:SetTextColor(0.6, 0.56, 0.64) end
                            end
                        end
                        if not r.price:HasFocus() then
                            local p = ItemPrice(e)
                            if p then
                                r.price:SetText(FormatGold(p))
                            elseif not e.scoreReady then
                                r.price:SetText("...")
                            else
                                r.price:SetText("-")
                            end
                        end
                        local tint = pal and ((i % 2 == 0) and pal.rowA or pal.rowB)
                        if tint then
                            r.bg:SetVertexColor(tint[1], tint[2], tint[3], tint[4] or 0.9)
                        elseif i % 2 == 0 then
                            r.bg:SetVertexColor(0.16, 0.14, 0.20, 0.9)
                        else
                            r.bg:SetVertexColor(0.12, 0.11, 0.16, 0.9)
                        end
                        r:Show()
                    end
                end
            end
            PaintBagSum(items)
            if scan.on or WaitingScores() then EnsureTick() end
        end)
        listBusy = false
        if not ok then
            print("|cffff5555qtEasyAuction:|r post list: " .. tostring(err))
        elseif listDirty then
            listDirty = false
            RefreshPostList()
        end
    end
    dock:EnableMouseWheel(true)
    dock:SetScript("OnMouseWheel", function(_, delta)
        PAA.offset = (PAA.offset or 0) - delta * 3
        RefreshPostList()
    end)
    RefreshPostHeads()
    RefreshPostList()
    ApplyPostSkin()

    if PeloriaAuctionHouseFrame and not PeloriaAuctionHouseFrame._qtEasyAuctionHooked then
        PeloriaAuctionHouseFrame._qtEasyAuctionHooked = true
        PeloriaAuctionHouseFrame:HookScript("OnHide", function()
            HidePreview()
        end)
    end
end

PAA:RegisterEvent("AUCTION_HOUSE_SHOW")
PAA:RegisterEvent("AUCTION_HOUSE_CLOSED")

PAA:SetScript("OnEvent", function(self, event)
    if event == "AUCTION_HOUSE_SHOW" then
        self:RegisterEvent("BAG_UPDATE")
        CreateButton()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        self:UnregisterEvent("BAG_UPDATE")
    elseif event == "BAG_UPDATE" then
        -- ʕ •ᴥ•ʔ✿ coalesce per-bag floods; tooltip scan is the hitch ✿ ʕ •ᴥ•ʔ
        local live = (PAA.preview and PAA.preview:IsShown())
            or (PAA.dock and PAA.dock:IsVisible())
        if not live then return end
        QueueBagRefresh()
    end
end)

LoadDB()

_G.qtEasyAuctionSlash = function(msg)
    msg = string.lower(msg or "")
    if msg == "test" then
        print("|cff00ff00qtEasyAuction:|r Addon is loaded and working!")
        print("|cff00ff00qtEasyAuction:|r PeloriaSend", type(PeloriaSend) == "function" and "OK" or "MISSING")
        print("|cff00ff00qtEasyAuction:|r PeloriaAuctionHouseFrame", PeloriaAuctionHouseFrame and "found" or "NOT found")
        if PeloriaAuctionHouseFrame then
            local ah = PeloriaAuctionHouseFrame
            print("|cff00ff00qtEasyAuction:|r AH shown", ah:IsShown() and "yes" or "no",
                "visible", ah:IsVisible() and "yes" or "no",
                "strata", ah:GetFrameStrata() or "?",
                "level", ah:GetFrameLevel() or "?")
        end
        local host = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.host
        print("|cff00ff00qtEasyAuction:|r Skin host", host and "yes" or "no")
        if host then
            print("|cff00ff00qtEasyAuction:|r host shown", host:IsShown() and "yes" or "no",
                "visible", host:IsVisible() and "yes" or "no",
                "strata", host:GetFrameStrata() or "?",
                "level", host:GetFrameLevel() or "?")
        end
        print("|cff00ff00qtEasyAuction:|r Button", PAA.button and "created" or "not yet created")
    elseif msg == "skin" then
        local Skin = _G.qtEasyAuctionSkin
        if not Skin then
            print("|cffff0000qtEasyAuction:|r skin module missing")
            return
        end
        Skin.Attach()
        local ok, err = pcall(Skin.Create)
        if not ok then
            print("|cffff0000qtEasyAuction:|r skin error:", tostring(err))
        else
            print("|cff00ff00qtEasyAuction:|r Forced skin. host=", Skin.host and "yes" or "no")
        end
    elseif msg == "create" then
        CreateButton()
        print("|cff00ff00qtEasyAuction:|r Attempted to create button")
    elseif msg == "clearignore" then
        LoadDB()
        AccountDB().ignore = {}
        print("|cff00ff00qtEasyAuction:|r Ignore list cleared.")
        QueueBagRefresh()
    else
        print("|cff00ff00qtEasyAuction:|r Commands: /qta test, /qta skin, /qta create, /qta clearignore, /qta gold")
    end
end

_G.qtEasyAuctionPost = {
    OnShown = function()
        CreateButton()
        PAA:RegisterEvent("BAG_UPDATE")
        AskMythicBags()
        QueueBagRefresh()
        ApplyPostSkin()
        EnsureTick()
    end,
    Rescore = function()
        if bagItems then
            for i = 1, #bagItems do
                bagItems[i].score, bagItems[i].scoreReady = 0, false
            end
        else
            QueueBagRefresh()
        end
        RequestPaint()
        EnsureTick()
    end,
    OnPreview = function()
        RequestPaint()
        local h = PAA.hover
        if h and h:IsShown() and MouseIsOver(h) and h.bag then
            ShowItemTip(h, h.bag, h.slot, h.itemID, h.link, h.tipAnchor)
        end
    end,
    OnMythic = function()
        if PAA.dock and PAA.dock:IsVisible() then
            QueueBagRefresh()
        end
    end,
    ApplySkin = function()
        ApplyPostSkin()
    end,
}
