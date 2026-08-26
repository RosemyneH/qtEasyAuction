local D = {}
_G.qtEasyAuctionDeals = D

local C = {
    PREFIX = "PELAH",
    SORT_BUYOUT = 3,
    GEN = 810000,
    PAGE_CAP = 20,
    ROW_MAX = 32,
    ROW_H = 34,
    ICON_SZ = 26,
    BUY_W = 50,
    TRIM_A = 0.03,
    TRIM_B = 0.97,
    FLY_MAX = 20,
    FLY_WAIT = 2.4,
    PREVIEW_TRIES = 6,
    WORK_SKIP = 100,
    DRILL_ASK = 8,
    PREVIEW_ASK = 10,
    FILL_FRAME = 48,
    FRAME_MS = 10,
    DRILL_FLY = 14,
    LIVE_DT = 0.28,
    SENTINEL_BASE = 20000,
    SENTINEL_MAX = 60020000,
    WEIGHT_LAYOUT = 7,
}

local COL = {}

local function TrimIcon(tex)
    if tex then tex:SetTexCoord(C.TRIM_A, C.TRIM_B, C.TRIM_A, C.TRIM_B) end
end

local function LayoutCols(width)
    width = tonumber(width) or 720
    if width < 400 then width = 400 end
    local inner = width - C.ICON_SZ - 12 - C.BUY_W - 6
    local spec = {
        { "name", 2.15 },
        { "mythic", 0.78 },
        { "score", 0.78 },
        { "ratio", 0.92 },
        { "stats", 1.65 },
        { "price", 0.82 },
        { "seller", 1.12 },
    }
    local sum = 0
    for i = 1, #spec do sum = sum + spec[i][2] end
    local x = C.ICON_SZ + 10
    COL.icon = 4
    for i = 1, #spec do
        local w = inner * spec[i][2] / sum
        COL[spec[i][1]] = x
        COL[spec[i][1] .. "W"] = w
        x = x + w
    end
end
LayoutCols(720)

local STAT_KEYS = { "str", "agi", "sta", "int", "spi", "ap", "sp", "arm", "crit", "hit", "haste", "exp", "mp5", "raw" }
local STAT_LABEL = {
    str = "Str", agi = "Agi", sta = "Stam", int = "Int",
    spi = "Spi", ap = "AP", sp = "SP", arm = "Arm",
    crit = "Crit", hit = "Hit", haste = "Haste", exp = "Exp",
    mp5 = "MP5", raw = "Other",
}
local STAT_COLOR = {
    str = { 0.95, 0.35, 0.30 },
    agi = { 0.95, 0.88, 0.28 },
    sta = { 0.35, 0.90, 0.45 },
    int = { 0.40, 0.65, 1.00 },
    spi = { 0.85, 0.85, 0.95 },
    ap  = { 1.00, 0.55, 0.20 },
    sp  = { 0.75, 0.45, 0.95 },
    arm = { 0.72, 0.72, 0.76 },
    crit = { 1.00, 0.82, 0.35 },
    hit = { 0.85, 0.75, 0.40 },
    haste = { 0.55, 0.85, 0.95 },
    exp = { 0.80, 0.55, 0.35 },
    mp5 = { 0.45, 0.70, 1.00 },
    raw = { 0.80, 0.80, 0.84 },
}

-- ʕ •ᴥ•ʔ✿ sell = shop listings, post = bag buyouts ✿ ʕ •ᴥ•ʔ
local SHOP_WEIGHTS = {
    str = 1.01, agi = 1.00, sta = 0.26, int = 0.49, spi = 0.55,
    ap  = 1.00, sp  = 1.00,
    arm = 0.01, crit = 0.01, hit = 0.01, haste = 0.01,
    exp = 0.00, mp5 = 0.00, raw = 0.01,
}
local POST_WEIGHTS = {
    str = 1.00, agi = 1.00, int = 1.00,
    ap  = 1.00, sp  = 1.00,
    spi = 0.50, sta = 0.40, arm = 0.05,
    crit = 1.00, hit = 1.00, haste = 1.00, exp = 1.00, mp5 = 1.00, raw = 1.00,
}

local BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

-- ʕ •ᴥ•ʔ✿ mutable scan state (Lua 5.1 caps a function at 200 locals) ✿ ʕ •ᴥ•ʔ
local S = {
    state = "idle",
    pendingBuys = {},
    sortKey = "perGold",
    sortDesc = true,
    status = "",
    searchQuery = "",
    filterText = "",
    searchAllScan = false,
    previewJobs = {},
    qIdx = 1,
    inFlight = 0,
    flight = {},
    previewRound = 0,
    previewPumping = false,
    previewStatusAt = 0,
    previewTries = {},
    previewByEntry = {},
    itemStats = {},
    localPreviews = {},
    askTries = {},
    liveDirty = false,
    liveAt = 0,
    pubIdx = 1,
    pubOut = {},
    drillSeen = {},
    previewSeen = {},
    goldVault = 0,
    drillJobs = {},
    drillIdx = 1,
    drillInFlight = 0,
    drillFlight = {},
    drillByGen = {},
    peekWrapped = {},
    mythicBags = {},
    mythicPending = {},
    mythicSynced = false,
    mythicSyncing = false,
    mythicCbs = {},
    mythicAskedAt = 0,
    frameStamp = 0,
    frameAsks = 0,
    frameSkips = 0,
    frameDrillAsks = 0,
    framePreviewAsks = 0,
    weightKind = "sell",
}
local page

local PumpPreview, ClearFlight, FinishPreviewPass, PumpScore, InstallHook, InstallPeekHook
local PumpDrill, BeginDrillPass, BeginTooltipPass, SetStatus
local EnqueueNewWork, PumpPublish, MaybeFinishScan, MakeDeal, FillInfoFromPackets
local Paint, ApplyFilter, ScanLabel, FinishRead, PaintMassGoldWarn, PaintPreviewProgress, PaintSweepGold
local FinishMassBuy

local function AccountDB()
    qtEasyAuctionDB = qtEasyAuctionDB or {}
    qtEasyAuctionDB.hiddenSellers = qtEasyAuctionDB.hiddenSellers or {}
    qtEasyAuctionDB.bulkBuyDelay = tonumber(qtEasyAuctionDB.bulkBuyDelay) or 0.10
    if qtEasyAuctionDB.confirmMassBuy == nil then qtEasyAuctionDB.confirmMassBuy = true end
    if qtEasyAuctionDB.hideDuplicateDeals == nil then qtEasyAuctionDB.hideDuplicateDeals = true end
    return qtEasyAuctionDB
end

local function SellerKey(name)
    name = string.lower(tostring(name or ""))
    name = string.gsub(name, "^%s+", "")
    name = string.gsub(name, "%s+$", "")
    return name
end

local function IsSellerHidden(name)
    local key = SellerKey(name)
    return key ~= "" and AccountDB().hiddenSellers[key] ~= nil
end

local HIDE_SELLER_POPUP = "QTEASYAUCTION_HIDE_SELLER"
StaticPopupDialogs[HIDE_SELLER_POPUP] = {
    text = "Hide every listing from %s?",
    button1 = "Hide seller",
    button2 = CANCEL,
    OnAccept = function(_, data)
        AccountDB().hiddenSellers[data.key] = data.owner
        SetStatus("Hidden listings from " .. data.owner .. ".")
        ApplyFilter()
        local settings = _G.qtEasyAuctionSettings
        if settings and settings.Refresh then settings.Refresh() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function ConfirmHideSeller(owner)
    local key = SellerKey(owner)
    if key == "" then return end
    StaticPopup_Show(HIDE_SELLER_POPUP, owner, nil, { key = key, owner = owner })
end

local function NextGen()
    C.GEN = C.GEN + 1
    return C.GEN
end

local function Strip(s)
    if not s then return "" end
    s = string.gsub(s, "|c%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|C%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|r", "")
    s = string.gsub(s, "|T.-|t", "")
    return s
end

local function ParseStatAmount(text)
    if text == nil then return 0 end
    if type(text) == "number" then
        if text > 0 then return text end
        return 0
    end
    text = string.lower(tostring(text))
    text = string.gsub(text, ",", "")
    text = string.gsub(text, "%s+", "")
    text = string.gsub(text, "^%+", "")
    local n, suf = string.match(text, "^([%d%.]+)([km])$")
    if n then
        n = tonumber(n) or 0
        if suf == "k" then return n * 1000 end
        return n * 1000000
    end
    return tonumber(text) or 0
end

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

local function GoldRaw(copper)
    return (tonumber(copper) or 0) / 10000
end

local function GoldText(copper)
    return Compact(GoldRaw(copper)) .. "g"
end

-- ʕ •ᴥ•ʔ✿ bag gold plus GOLD-packet vault ✿ ʕ •ᴥ•ʔ
local function GoldTotal()
    local fn = _G.PeloriaGoldTotal
    if type(fn) == "function" then
        local ok, v = pcall(fn)
        if ok and type(v) == "number" then return v end
    end
    return (GetMoney() or 0) + S.goldVault
end

local function OnGoldRest(rest)
    local n = tonumber(rest)
    if n then S.goldVault = n end
    if PaintMassGoldWarn then PaintMassGoldWarn() end
end

local function MythicTag(minL, maxL)
    minL, maxL = tonumber(minL) or 0, tonumber(maxL) or 0
    if minL <= 0 and maxL <= 0 then return "|cff555555—|r" end
    local n = math.max(minL, maxL)
    if minL > 0 and maxL > minL then
        return "|cff66ff33+" .. Compact(minL) .. "–" .. Compact(maxL) .. "|r"
    end
    return "|cff66ff33+" .. Compact(n) .. "|r"
end

local function RatioText(per)
    per = tonumber(per) or 0
    if per <= 0 then return "|cff666666—|r" end
    if per >= 10000 then return Compact(per) end
    if per >= 100 then return string.format("%.0f", per) end
    if per >= 10 then return string.format("%.1f", per) end
    if per >= 1 then return string.format("%.2f", per) end
    return string.format("%.3f", per)
end

local function SellerText(name)
    if not name or name == "" then return "|cff666666—|r" end
    local h = 0
    for i = 1, string.len(name) do h = h + string.byte(name, i) end
    local tokens = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "DEATHKNIGHT" }
    local token = tokens[(h % #tokens) + 1]
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if c then
        return string.format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, name)
    end
    return "|cffffd100" .. name .. "|r"
end

local function TooltipHasText(tt, needle)
    local name = tt and tt:GetName()
    if not name then return false end
    for i = 1, tt:NumLines() do
        local fs = _G[name .. "TextLeft" .. i]
        local text = fs and fs:GetText()
        if text and string.find(text, needle, 1, true) then return true end
    end
    return false
end

local function EnsureTip()
    if not S.scanTip then
        S.scanTip = CreateFrame("GameTooltip", "qtEasyAuctionScanTip", UIParent, "GameTooltipTemplate")
        S.scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    end
    if PeloriaRegisterItemTooltip and not S.scanTip.__PeloriaItemTooltipRegistered then
        PeloriaRegisterItemTooltip(S.scanTip)
    end
    return S.scanTip
end

local function ItemLink(entry, randProp)
    return string.format("item:%d:0:0:0:0:0:%d:0:80", entry or 0, randProp or 0)
end

-- ʕ •ᴥ•ʔ✿ same hover path as Peloria AH browse rows ✿ ʕ •ᴥ•ʔ
local function PulseTooltip(entry, mythic, randProp)
    local tip = EnsureTip()
    local level = tonumber(mythic) or 0
    PeloriaSoulbindHoverLevel = (level > 0) and level or nil
    tip:Hide()
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearLines()
    if PrimeItemCache then PrimeItemCache(entry) end
    tip:SetHyperlink(ItemLink(entry, randProp))
end

local ALIAS = {
    strength = "str", str = "str",
    agility = "agi", agi = "agi",
    stamina = "sta", stam = "sta",
    intellect = "int", int = "int",
    spirit = "spi", spi = "spi",
    ["attack power"] = "ap", ap = "ap", attackpower = "ap",
    ["feral attack power"] = "ap",
    ["spell power"] = "sp", ["spell damage"] = "sp", sp = "sp", spellpower = "sp",
    healing = "sp", ["spell healing"] = "sp",
    armor = "arm", arm = "arm", armour = "arm",
    ["critical strike"] = "crit", crit = "crit",
    ["hit rating"] = "hit", hit = "hit",
    ["haste rating"] = "haste", haste = "haste",
    ["expertise rating"] = "exp", expertise = "exp",
    ["mana per 5"] = "mp5", ["mana every 5"] = "mp5", mp5 = "mp5",
}

local function CopyWeights(src)
    local w = {}
    for i = 1, #STAT_KEYS do
        local k = STAT_KEYS[i]
        w[k] = tonumber(src and src[k]) or 0
    end
    return w
end

local function DefaultWeights(kind)
    if kind == "post" then return CopyWeights(POST_WEIGHTS) end
    return CopyWeights(SHOP_WEIGHTS)
end

local function CharDB()
    local Skin = _G.qtEasyAuctionSkin
    if Skin and Skin.Char then return Skin.Char() end
    qtEasyAuctionCharDB = qtEasyAuctionCharDB or {}
    qtEasyAuctionCharDB.itemPrices = qtEasyAuctionCharDB.itemPrices or {}
    if qtEasyAuctionCharDB.searchAll == nil then qtEasyAuctionCharDB.searchAll = false end
    return qtEasyAuctionCharDB
end

local function SearchAll()
    return CharDB().searchAll and true or false
end

local function EmptyStatus()
    if S.searchAllScan then return "No listings." end
    return "No soulbindable listings."
end

local function WeightStore(kind)
    if kind == "post" then return "postWeights" end
    return "sellWeights"
end

local function GetWeights(kind)
    if kind ~= "post" then kind = "sell" end
    local db = CharDB()
    local key = WeightStore(kind)
    if type(db[key]) ~= "table" then
        local src
        if kind == "sell" then
            local legacy = db.weights and (db.weights.GENERAL or db.weights[1])
            if type(legacy) ~= "table" and type(db.weights) == "table" then
                for _, w in pairs(db.weights) do
                    if type(w) == "table" then
                        legacy = w
                        break
                    end
                end
            end
            src = legacy
        end
        db[key] = CopyWeights(src or DefaultWeights(kind))
    end
    local w = db[key]
    local d = DefaultWeights(kind)
    for i = 1, #STAT_KEYS do
        local k = STAT_KEYS[i]
        if w[k] == nil then w[k] = d[k] or 0 end
    end
    return w
end

local function RescoreKind(kind)
    if kind == "post" then
        local post = _G.qtEasyAuctionPost
        if post and post.Rescore then
            post.Rescore()
        elseif post and post.OnPreview then
            post.OnPreview()
        end
        return
    end
    if S.state ~= "idle" then
        S.liveDirty = true
        return
    end
    if S.summaries and #S.summaries > 0 then FinishRead(true) end
end

local function CanonicalStat(stat)
    if not stat then return nil end
    local low = string.lower(stat)
    low = string.gsub(low, "%s+$", "")
    low = string.gsub(low, "^%s+", "")
    low = string.gsub(low, " rating$", "")
    if string.find(low, "mythic", 1, true) then return nil end
    if string.find(low, "armor penetration", 1, true) or string.find(low, "armour penetration", 1, true) then
        return "raw"
    end
    if ALIAS[low] then return ALIAS[low] end
    local best, bestLen
    for key, canon in pairs(ALIAS) do
        if string.len(key) >= 3 and string.find(low, key, 1, true) then
            if not bestLen or string.len(key) > bestLen then
                best, bestLen = canon, string.len(key)
            end
        end
    end
    return best
end

local function PreviewKey(entry, level, affix)
    return tostring(entry) .. ":" .. tostring(level or 0) .. ":" .. tostring(affix or 0)
end

local function AffixForSoulbind(raw)
    raw = tonumber(raw) or 0
    if raw <= -(C.SENTINEL_BASE + 1) and raw >= -C.SENTINEL_MAX then return 0 end
    return raw
end

local function PreviewRows(preview)
    return type(preview) == "table" and #preview > 0 and preview or nil
end

local function PeekNative(entry, level, affix)
    local t = PeloriaSoulbindPreviews
    if type(t) ~= "table" then return nil, false end
    local p = t[PreviewKey(entry, level or 0, affix or 0)]
    if p ~= nil then return p, true end
    return nil, false
end

local function RowFields(row)
    if type(row) ~= "table" then return nil, row end
    local name = row.name or row.label or row.stat or row.Name or row.Label or row[1]
    local value = row.value or row.amount or row.amt or row.val or row.Value or row.n or row[2]
    return name, value
end

local function StatsFromPreview(preview)
    local stats = {}
    if type(preview) ~= "table" then return stats end
    local function add(name, value)
        local key = CanonicalStat(name)
        local v = ParseStatAmount(value)
        if (not v or v == 0) then v = tonumber(value) end
        if v and v > 0 then
            if not key then key = "raw" end
            stats[key] = (stats[key] or 0) + v
        end
    end
    if preview[1] then
        for i = 1, #preview do
            local name, value = RowFields(preview[i])
            add(name, value)
        end
    else
        for name, value in pairs(preview) do
            if type(value) == "table" then
                local n, v = RowFields(value)
                add(n or name, v)
            else
                add(name, value)
            end
        end
    end
    if not next(stats) then
        for i = 1, #preview do
            local _, value = RowFields(preview[i])
            local v = ParseStatAmount(value)
            if v and v > 0 then stats.raw = (stats.raw or 0) + v end
        end
    end
    return stats
end

local ITEM_STAT_KEYS = {
    ITEM_MOD_STRENGTH_SHORT = "str",
    ITEM_MOD_AGILITY_SHORT = "agi",
    ITEM_MOD_STAMINA_SHORT = "sta",
    ITEM_MOD_INTELLECT_SHORT = "int",
    ITEM_MOD_SPIRIT_SHORT = "spi",
    ITEM_MOD_ATTACK_POWER_SHORT = "ap",
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "ap",
    ITEM_MOD_FERAL_ATTACK_POWER_SHORT = "ap",
    ITEM_MOD_SPELL_POWER_SHORT = "sp",
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "sp",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = "sp",
    RESISTANCE0_NAME = "arm",
    ITEM_MOD_CRIT_RATING_SHORT = "crit",
    ITEM_MOD_CRIT_MELEE_RATING_SHORT = "crit",
    ITEM_MOD_CRIT_RANGED_RATING_SHORT = "crit",
    ITEM_MOD_CRIT_SPELL_RATING_SHORT = "crit",
    ITEM_MOD_HIT_RATING_SHORT = "hit",
    ITEM_MOD_HIT_MELEE_RATING_SHORT = "hit",
    ITEM_MOD_HIT_RANGED_RATING_SHORT = "hit",
    ITEM_MOD_HIT_SPELL_RATING_SHORT = "hit",
    ITEM_MOD_HASTE_RATING_SHORT = "haste",
    ITEM_MOD_HASTE_MELEE_RATING_SHORT = "haste",
    ITEM_MOD_HASTE_RANGED_RATING_SHORT = "haste",
    ITEM_MOD_HASTE_SPELL_RATING_SHORT = "haste",
    ITEM_MOD_EXPERTISE_RATING_SHORT = "exp",
    ITEM_MOD_MANA_REGENERATION_SHORT = "mp5",
    ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = "raw",
}

local function MythicMultiplier(level)
    return 1 + math.max(0, tonumber(level) or 0) / 200
end

local function LocalPreview(entry, level, affix)
    if type(GetItemStats) ~= "function" then return nil end
    local key = PreviewKey(entry, level, affix)
    if S.localPreviews[key] then return S.localPreviews[key] end
    local link = ItemLink(entry, affix)
    if not GetItemInfo(link) then
        if PrimeItemCache then PrimeItemCache(entry) end
        return nil
    end
    local base = S.itemStats[link]
    if not base then
        base = GetItemStats(link)
        if type(base) ~= "table" then return nil end
        S.itemStats[link] = base
    end
    local totals = {}
    for stat, value in pairs(base) do
        local canon = ITEM_STAT_KEYS[stat]
        value = tonumber(value)
        if canon and value and value > 0 then
            totals[canon] = (totals[canon] or 0) + value
        end
    end
    local rows = {}
    local scale = MythicMultiplier(level)
    for i = 1, #STAT_KEYS do
        local stat = STAT_KEYS[i]
        local value = totals[stat]
        if value and value > 0 then
            if stat == "sta" then value = value * 2 end
            rows[#rows + 1] = {
                name = STAT_LABEL[stat],
                value = math.floor(value * scale),
            }
        end
    end
    if #rows == 0 then
        S.peekWrapped.empty = S.peekWrapped.empty or {}
        S.peekWrapped.empty[key] = true
        return nil
    end
    S.localPreviews[key] = rows
    return rows
end

local function PreviewHasStats(preview)
    local stats = StatsFromPreview(preview)
    for i = 1, #STAT_KEYS do
        if (stats[STAT_KEYS[i]] or 0) > 0 then return true end
    end
    return false
end

local function AsPreviewRows(p)
    if type(p) ~= "table" then return nil end
    local rows = PreviewRows(p)
    if rows and PreviewHasStats(rows) then return rows end
    if rows then return rows end
    rows = {}
    for name, value in pairs(p) do
        if type(name) ~= "number" then
            if type(value) == "table" then
                local n, v = RowFields(value)
                v = ParseStatAmount(v) or tonumber(v)
                if v and v > 0 then
                    rows[#rows + 1] = { name = n or tostring(name), value = v }
                end
            else
                local v = ParseStatAmount(value) or tonumber(value)
                if v and v > 0 then
                    rows[#rows + 1] = { name = tostring(name), value = v }
                end
            end
        end
    end
    if #rows > 0 then return rows end
end

local function CachedPreview(entry, level, affix)
    affix = AffixForSoulbind(affix)
    local hit = LocalPreview(entry, level, affix)
    if hit then return hit end
    hit = AsPreviewRows((PeekNative(entry, level, affix)))
    if hit then return hit end
    if affix ~= 0 then
        hit = AsPreviewRows((PeekNative(entry, level, 0)))
        if hit then return hit end
    end
    if S.previewByEntry then
        return AsPreviewRows(S.previewByEntry[entry])
    end
end

function ClearFlight(entry, key)
    local drop = {}
    for k in pairs(S.flight) do
        if k == key or (entry and string.sub(k, 1, string.len(tostring(entry)) + 1) == tostring(entry) .. ":") then
            drop[#drop + 1] = k
        end
    end
    for i = 1, #drop do
        if S.flight[drop[i]] then
            S.flight[drop[i]] = nil
            S.inFlight = math.max(0, S.inFlight - 1)
        end
    end
end

local function GiveUpPreview(entry, level, affix)
    local key = PreviewKey(entry, level, AffixForSoulbind(affix))
    return S.peekWrapped.empty and S.peekWrapped.empty[key] and true or false
end

local function LiveFlights()
    local n, now = 0, GetTime()
    for _, t in pairs(S.flight) do
        if type(t) == "number" and t > now then n = n + 1 end
    end
    return n
end

local function AskPreview(entry, level, affix)
    if CachedPreview(entry, level, affix) then return true end
    local key = PreviewKey(entry, level, affix)
    if S.peekWrapped.empty and S.peekWrapped.empty[key] then return false end
    local now = GetTime()
    if S.flight[key] and now < S.flight[key] then return false end
    S.flight[key] = now + C.FLY_WAIT
    if CachedPreview(entry, level, affix) then
        S.flight[key] = nil
        return true
    end
    return false
end

local function SendPreview(entry, level, affix)
    entry = tonumber(entry)
    level = tonumber(level) or 0
    affix = AffixForSoulbind(affix)
    if not entry then return false end
    if type(PeloriaRequestSoulbindEligibility) == "function" then
        PeloriaRequestSoulbindEligibility(entry)
    end
    return AskPreview(entry, level, affix) and true or false
end

local function OnSoulbindReady(itemEntry)
    ClearFlight(itemEntry)
    if PumpPreview then PumpPreview() end
    S.liveDirty = true
    if S.state == "idle" then S.rescoreAt = GetTime() + 0.15 end
    local post = _G.qtEasyAuctionPost
    if post and post.OnPreview then post.OnPreview() end
end

local function OverflowValue(plain, mant, exp)
    local m, e = tonumber(mant), tonumber(exp)
    if m and m > 0 and e and e >= 0 and e <= 300 then
        return m * (10 ^ e)
    end
    local v = ParseStatAmount(plain)
    if v and v > 0 then return v end
    return tonumber(plain) or 0
end

local function SplitCaret(s)
    local t, i = {}, 1
    s = s or ""
    while true do
        local a, b = string.find(s, "^", i, true)
        if not a then
            t[#t + 1] = string.sub(s, i)
            return t
        end
        t[#t + 1] = string.sub(s, i, a - 1)
        i = b + 1
    end
end

local function IsExp(s)
    local e = tonumber(s)
    return e and e >= 0 and e <= 300 and e == math.floor(e)
end

local function PushStat(dst, label, value)
    if type(label) ~= "string" then return end
    label = string.gsub(label, "^%s+", "")
    label = string.gsub(label, "%s+$", "")
    if label == "" or label == "S" or label == "P" then return end
    if string.find(string.lower(label), "mythic", 1, true) then return end
    value = OverflowValue(value)
    if value and value > 0 then
        dst[#dst + 1] = { name = label, value = value }
    end
end

local function ConsumeFields(fields, dst)
    local i, n = 1, #fields
    while i <= n do
        local label = fields[i]
        if label == "S" and i < n then
            i = i + 1
            label = fields[i]
        end
        if i + 3 <= n and tonumber(fields[i + 2]) and IsExp(fields[i + 3]) then
            PushStat(dst, label, OverflowValue(fields[i + 1], fields[i + 2], fields[i + 3]))
            i = i + 4
        elseif i + 2 <= n and tonumber(fields[i + 1]) and IsExp(fields[i + 2]) then
            PushStat(dst, label, OverflowValue(fields[i + 1], fields[i + 1], fields[i + 2]))
            i = i + 3
        elseif i + 1 <= n then
            PushStat(dst, label, fields[i + 1])
            i = i + 2
        else
            i = i + 1
        end
    end
end

local function ParseRecords(records)
    local preview = {}
    if type(records) ~= "string" or records == "" then return preview end
    if string.find(records, "~", 1, true) then
        for record in string.gmatch(records, "([^~]+)") do
            ConsumeFields(SplitCaret(record), preview)
        end
    else
        ConsumeFields(SplitCaret(records), preview)
    end
    return preview
end

local function ParsePreviewBody(message)
    if type(message) ~= "string" then return end
    message = string.gsub(message, "^PELATTN%^", "")
    if string.sub(message, 1, 2) ~= "P^" then return end
    local itemEntryText, levelText, affixText, records =
        string.match(message, "^P%^([^%^]+)%^([^%^]+)%^([^%^]+)%^(.*)$")
    local itemEntry, level, affix = tonumber(itemEntryText), tonumber(levelText), tonumber(affixText)
    if not itemEntry or itemEntry <= 0 or level == nil or level < 0 or affix == nil then return end
    local preview = ParseRecords(records)
    local key = PreviewKey(itemEntry, level, affix)
    S.peekWrapped.empty = S.peekWrapped.empty or {}
    if #preview == 0 then
        if not records or records == "" then
            S.peekWrapped.empty[key] = true
        end
        OnSoulbindReady(itemEntry)
        return
    end
    S.peekWrapped.empty[key] = nil
    PeloriaSoulbindPreviews = PeloriaSoulbindPreviews or {}
    PeloriaSoulbindPreviews[key] = preview
    S.previewByEntry = S.previewByEntry or {}
    S.previewByEntry[itemEntry] = preview
    OnSoulbindReady(itemEntry)
end

local function ReadTipStats()
    local tip = EnsureTip()
    local name = tip:GetName()
    local blocked, available, bound = false, false, false
    local inSoul, stats = false, {}

    for i = 1, tip:NumLines() do
        local fs = _G[name .. "TextLeft" .. i]
        local raw = fs and fs:GetText()
        if raw then
            local text = Strip(raw)
            local low = string.lower(text)
            if string.find(low, "mythic", 1, true) then
                -- ʕ •ᴥ•ʔ✿ never treat Mythic +N as a stat ✿ ʕ •ᴥ•ʔ
            elseif string.find(low, "class cannot soulbind", 1, true) then
                blocked = true
            elseif string.find(low, "already soulbound", 1, true) then
                bound = true
            elseif string.find(low, "soulbind available", 1, true) then
                available = true
            end
            if string.find(low, "if soulbound", 1, true) or string.find(low, "soulbound stats", 1, true) then
                inSoul = true
            end
            if inSoul and not blocked then
                local n, stat = string.match(text, "%+%s*([%d%.,]+%s*[kKmM]?)%s+(.+)")
                if not n then
                    n, stat = string.match(text, "([%d%.,]+%s*[kKmM]?)%s+(.+)")
                end
                if not n then
                    stat, n = string.match(text, "increases.-(attack power).-%s(%d+)")
                    if not n then stat, n = string.match(text, "increases.-(spell power).-%s(%d+)") end
                end
                local right = _G[name .. "TextRight" .. i]
                local rt = right and Strip(right:GetText() or "")
                if (not n) and rt and rt ~= "" then
                    n = string.match(rt, "%+?([%d%.,]+%s*[kKmM]?)")
                    stat = stat or text
                end
                if n and stat then
                    local key = CanonicalStat(stat)
                    local v = ParseStatAmount(string.gsub(n, "%s+", ""))
                    if key and v > 0 then
                        stats[key] = (stats[key] or 0) + v
                    end
                end
            end
        end
    end

    local score = 0
    for i = 1, #STAT_KEYS do
        local k = STAT_KEYS[i]
        score = score + (stats[k] or 0)
    end
    PeloriaSoulbindHoverLevel = nil
    return {
        blocked = blocked,
        bound = bound,
        available = available,
        waiting = available and score == 0,
        stats = stats,
        total = score,
    }
end

local function ParseSummaryRows(tail)
    local out = {}
    for rec in string.gmatch(tail or "", "[^~]+") do
        local entry, count, minPrice, minMythic, maxMythic, quality, ilvl, name =
            string.match(rec, "^(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(.*)$")
        if entry then
            out[#out + 1] = {
                entry = tonumber(entry),
                count = tonumber(count),
                minPriceRaw = minPrice,
                minPrice = tonumber(minPrice),
                minMythic = tonumber(minMythic),
                maxMythic = tonumber(maxMythic),
                quality = tonumber(quality),
                ilvl = tonumber(ilvl),
                name = name,
                affix = 0,
            }
        end
    end
    return out
end

local function ParseListings(tail)
    local out = {}
    for rec in string.gmatch(tail or "", "[^~]+") do
        local id, entry, cnt, mythic, buyout, randProp, timeLeft, quality, owner, name =
            string.match(rec, "^(%d+):(%d+):(%d+):(%d+):(%d+):(%-?%d+):(%d+):(%d+):([^:]*):(.*)$")
        if id then
            out[#out + 1] = {
                idRaw = id,
                buyoutRaw = buyout,
                entry = tonumber(entry),
                mythic = tonumber(mythic),
                buyout = tonumber(buyout),
                randProp = tonumber(randProp),
                owner = owner,
                name = name,
                quality = tonumber(quality),
            }
        end
    end
    return out
end

local function CleanQuery(s)
    s = tostring(s or "")
    s = string.gsub(s, "[%^~]", "")
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

local function Search(g, pg, drill)
    if type(PeloriaSend) ~= "function" then return end
    local q = ""
    if not drill or drill == 0 then
        q = CleanQuery(S.searchQuery)
    end
    -- ʕ •ᴥ•ʔ✿ soulbind=1 default, 0 when All items is checked ✿ ʕ •ᴥ•ʔ
    local soulbind = 1
    if S.searchAllScan then soulbind = 0 end
    PeloriaSend(string.format("%s^SEARCH^%d^%d^%d^%d^%d^%d^%d^%d^%d^%d^%d^%d^%d^%s",
        C.PREFIX, g, pg, -1, -1, 0, 0, 0, 0, -1, C.SORT_BUYOUT, 0, soulbind, drill or 0, q))
end

-- ʕ •ᴥ•ʔ✿ one AH listing per row — never collapse by item id ✿ ʕ •ᴥ•ʔ
local function SummaryFromListing(e, base)
    base = base or {}
    local mythic = tonumber(e.mythic) or 0
    local name = e.name
    if not name or name == "" then name = base.name end
    local quality = tonumber(e.quality) or 0
    if quality <= 0 then quality = base.quality end
    return {
        entry = e.entry or base.entry,
        count = 1,
        minPrice = e.buyout or base.minPrice,
        minPriceRaw = e.buyoutRaw or base.minPriceRaw,
        minMythic = mythic,
        maxMythic = mythic,
        quality = quality,
        ilvl = base.ilvl or 0,
        name = name,
        idRaw = e.idRaw,
        buyoutRaw = e.buyoutRaw,
        affix = AffixForSoulbind(e.randProp or base.affix),
        owner = e.owner,
    }
end

local function ExpandListings(entry, rows)
    if not S.summaries or not entry then return end
    local me = UnitName("player")
    local base
    local byId = {}
    for i = 1, #S.summaries do
        local s = S.summaries[i]
        if s.entry == entry then
            if not base then base = s end
            if s.idRaw then byId[s.idRaw] = s end
        end
    end
    local function take(allowOwn)
        for i = 1, #(rows or {}) do
            local e = rows[i]
            if e.entry == entry and e.idRaw then
                if allowOwn or e.owner ~= me then
                    byId[e.idRaw] = SummaryFromListing(e, base)
                end
            end
        end
    end
    take(false)
    if not next(byId) then take(true) end
    if not next(byId) then return end
    local out, placed = {}, false
    for i = 1, #S.summaries do
        local s = S.summaries[i]
        if s.entry == entry then
            if not placed then
                for _, row in pairs(byId) do
                    out[#out + 1] = row
                end
                placed = true
            end
        else
            out[#out + 1] = s
        end
    end
    S.summaries = out
end

-- ʕ •ᴥ•ʔ✿ cap preview / score work so 2k listings don't hitch ✿ ʕ •ᴥ•ʔ

local function BeginFrameWork()
    local t = GetTime()
    if t ~= S.frameStamp then
        S.frameStamp, S.frameAsks, S.frameSkips, S.frameDrillAsks, S.framePreviewAsks = t, 0, 0, 0, 0
        if type(debugprofilestart) == "function" then debugprofilestart() end
    end
end

local function FrameOver(ms)
    return type(debugprofilestop) == "function" and debugprofilestop() >= (ms or C.FRAME_MS)
end

function PumpDrill()
    if S.state ~= "fetch" and S.state ~= "fill" then return end
    if not S.drillJobs or (#S.drillJobs == 0 and S.drillInFlight == 0) then return end
    BeginFrameWork()
    local now = GetTime()
    local expired = {}
    for g, t in pairs(S.drillFlight) do
        if now > t then expired[#expired + 1] = g end
    end
    for i = 1, #expired do
        local g = expired[i]
        if S.drillFlight[g] then
            local job = S.drillByGen[g]
            S.drillFlight[g] = nil
            S.drillByGen[g] = nil
            S.drillInFlight = math.max(0, S.drillInFlight - 1)
            if type(job) == "table" then
                ExpandListings(job.entry, job.rows)
                if EnqueueNewWork then EnqueueNewWork() end
                S.liveDirty = true
            end
        end
    end
    while S.drillInFlight < C.DRILL_FLY and S.drillIdx <= #(S.drillJobs or {}) and S.frameDrillAsks < C.DRILL_ASK do
        local j = S.drillJobs[S.drillIdx]
        S.drillIdx = S.drillIdx + 1
        local g = NextGen()
        S.drillByGen[g] = { entry = j.entry, rows = {} }
        S.drillFlight[g] = now + 2.5
        S.drillInFlight = S.drillInFlight + 1
        S.frameDrillAsks = S.frameDrillAsks + 1
        Search(g, 0, j.entry)
        if FrameOver(C.FRAME_MS) then break end
    end
end

function BeginDrillPass()
    if not S.summaries or #S.summaries == 0 then
        S.state = "idle"
        SetStatus(EmptyStatus())
        return
    end
    if S.state == "fetch" then S.state = "fill" end
    if EnqueueNewWork then EnqueueNewWork() end
    S.liveDirty = true
    PumpDrill()
    if PumpPreview then PumpPreview() end
end

local function WeightedScore(stats, kind)
    local w = GetWeights(kind)
    local score, bestKey, bestPart = 0, nil, 0
    stats = stats or {}
    for i = 1, #STAT_KEYS do
        local k = STAT_KEYS[i]
        local part = (stats[k] or 0) * (w[k] or 0)
        score = score + part
        if part > bestPart then bestPart, bestKey = part, k end
    end
    return score, bestKey
end

function D.PrimeAndScore(entry, level, affix)
    entry = tonumber(entry)
    level, affix = tonumber(level) or 0, AffixForSoulbind(affix)
    if not entry then return 0, true end
    if InstallHook then InstallHook() end
    local preview = CachedPreview(entry, level, affix)
    if preview then
        return WeightedScore(StatsFromPreview(preview), "post"), true
    end
    SendPreview(entry, level, affix)
    preview = CachedPreview(entry, level, affix)
    if preview then
        return WeightedScore(StatsFromPreview(preview), "post"), true
    end
    if GiveUpPreview(entry, level, affix) then
        return 0, true
    end
    return 0, false
end

function D.ClearAsk(entry, level, affix)
    entry = tonumber(entry)
    level, affix = tonumber(level) or 0, AffixForSoulbind(affix)
    if not entry then return end
    local key = PreviewKey(entry, level, affix)
    if S.peekWrapped.empty then S.peekWrapped.empty[key] = nil end
    if S.peekWrapped.sent then S.peekWrapped.sent[key] = nil end
    if S.flight[key] then
        S.flight[key] = nil
        S.inFlight = math.max(0, S.inFlight - 1)
    end
    if affix ~= 0 then
        local z = PreviewKey(entry, level, 0)
        if S.peekWrapped.empty then S.peekWrapped.empty[z] = nil end
        if S.peekWrapped.sent then S.peekWrapped.sent[z] = nil end
        S.flight[z] = nil
    end
end

-- ʕ •ᴥ•ʔ✿ Peloria skips If Soulbound when class-blocked or affix is a mythic sentinel ✿ ʕ •ᴥ•ʔ
function D.AddPreviewToTip(tip, entry, level, affix)
    if not tip then return end
    entry = tonumber(entry)
    level, affix = tonumber(level) or 0, AffixForSoulbind(affix)
    PeloriaSoulbindHoverLevel = (level > 0) and level or nil
    if not entry then return end
    if InstallHook then InstallHook() end
    local preview = CachedPreview(entry, level, affix)
    if not preview then
        SendPreview(entry, level, affix)
        preview = CachedPreview(entry, level, affix)
    end
    if not preview or #preview == 0 then return end
    if TooltipHasText(tip, "If Soulbound") then return end
    local rows = {}
    for i = 1, #preview do rows[i] = preview[i] end
    table.sort(rows, function(a, b)
        local _, va = RowFields(a)
        local _, vb = RowFields(b)
        return (tonumber(va) or 0) > (tonumber(vb) or 0)
    end)
    tip:AddLine(" ")
    tip:AddLine("|cff7CFC00If Soulbound:|r")
    for i = 1, #rows do
        local name, value = RowFields(rows[i])
        tip:AddLine("|cff66ff33  +" .. Compact(value or 0) .. "  " .. (name or "?") .. "|r")
    end
end

local function TopStats(stats)
    local w = GetWeights("sell")
    local bits = {}
    stats = stats or {}
    for i = 1, #STAT_KEYS do
        local k = STAT_KEYS[i]
        local v = stats[k]
        if v and v > 0 then
            bits[#bits + 1] = { k = k, v = v, part = v * (w[k] or 0) }
        end
    end
    table.sort(bits, function(a, b)
        if a.part ~= b.part then return a.part > b.part end
        return a.v > b.v
    end)
    return bits
end

local function ApplySort()
    if not S.deals then return end
    local key, desc = S.sortKey or "perGold", S.sortDesc ~= false
    table.sort(S.deals, function(a, b)
        local va, vb
        if key == "price" then
            va, vb = a.minPrice or 0, b.minPrice or 0
        elseif key == "score" then
            va, vb = a.total or 0, b.total or 0
        elseif key == "mythic" then
            va = math.max(a.mythic or 0, a.mythicMax or 0)
            vb = math.max(b.mythic or 0, b.mythicMax or 0)
        elseif key == "perGold" then
            va, vb = a.perGold or 0, b.perGold or 0
        elseif key == "seller" then
            va, vb = string.lower(a.owner or ""), string.lower(b.owner or "")
            if va ~= vb then
                if desc then return va < vb end
                return va > vb
            end
            return (a.perGold or 0) > (b.perGold or 0)
        elseif key == "name" then
            va, vb = string.lower(a.name or ""), string.lower(b.name or "")
            if va ~= vb then
                if desc then return va < vb end
                return va > vb
            end
            return (a.perGold or 0) > (b.perGold or 0)
        else
            va, vb = a.perGold or 0, b.perGold or 0
        end
        if va == vb then
            va, vb = a.total or 0, b.total or 0
        end
        if desc then return va > vb end
        return va < vb
    end)
end

local function DealMatches(deal, q)
    if IsSellerHidden(deal.owner) then return false end
    if not q or q == "" then return true end
    local name = string.lower(deal.name or "")
    local seller = string.lower(deal.owner or "")
    return string.find(name, q, 1, true) or string.find(seller, q, 1, true)
end

local function DuplicateKey(deal)
    return tostring(deal.entry or 0) .. ":" .. tostring(tonumber(deal.mythic) or 0)
end

local function IsBetterDeal(deal, current)
    local ratio, currentRatio = tonumber(deal.perGold) or 0, tonumber(current.perGold) or 0
    if ratio ~= currentRatio then return ratio > currentRatio end
    local price, currentPrice = tonumber(deal.minPrice) or math.huge, tonumber(current.minPrice) or math.huge
    if price ~= currentPrice then return price < currentPrice end
    return (tonumber(deal.total) or 0) > (tonumber(current.total) or 0)
end

function ApplyFilter(keepOffset)
    local q = string.lower(CleanQuery(S.filterText))
    S.deals = {}
    local unique = AccountDB().hideDuplicateDeals and {} or nil
    for i = 1, #(S.allDeals or {}) do
        local deal = S.allDeals[i]
        if DealMatches(deal, q) then
            if unique then
                local key = DuplicateKey(deal)
                local index = unique[key]
                if not index then
                    S.deals[#S.deals + 1] = deal
                    unique[key] = #S.deals
                elseif IsBetterDeal(deal, S.deals[index]) then
                    S.deals[index] = deal
                end
            else
                S.deals[#S.deals + 1] = deal
            end
        end
    end
    ApplySort()
    if not keepOffset then S.offset = 0 end
    Paint()
end

local function FormatStatLine(stats, score, bestKey)
    local bits = TopStats(stats)
    if not score or score <= 0 then return "|cff666666—|r" end
    return "|cffe8d5a3" .. Compact(score) .. "|r"
end

function SetStatus(text)
    S.status = text or ""
    if D.status then D.status:SetText(S.status) end
end

local function DealKey(deal)
    if not deal then return "" end
    if deal.idRaw then return "id:" .. tostring(deal.idRaw) end
    return "e:" .. tostring(deal.entry or 0)
end

local function PlaceRow(r)
    r.icon:ClearAllPoints()
    r.icon:SetWidth(C.ICON_SZ)
    r.icon:SetHeight(C.ICON_SZ)
    r.icon:SetPoint("LEFT", COL.icon, 0)
    TrimIcon(r.icon)
    local function put(fs, key)
        fs:ClearAllPoints()
        fs:SetPoint("LEFT", COL[key], 0)
        fs:SetWidth(COL[key .. "W"])
        fs:SetJustifyH("CENTER")
    end
    put(r.name, "name")
    put(r.mythic, "mythic")
    put(r.score, "score")
    put(r.ratio, "ratio")
    put(r.price, "price")
    put(r.seller, "seller")
    local cellW = COL.statsW / 3
    for s = 1, 3 do
        local cell = r.statCells[s]
        cell.lab:ClearAllPoints()
        cell.lab:SetPoint("TOPLEFT", COL.stats + (s - 1) * cellW, -2)
        cell.lab:SetWidth(cellW)
        cell.lab:SetJustifyH("CENTER")
        cell.val:ClearAllPoints()
        cell.val:SetPoint("TOPLEFT", COL.stats + (s - 1) * cellW, -16)
        cell.val:SetWidth(cellW)
        cell.val:SetJustifyH("CENTER")
    end
end

local function VisCount()
    if D.list and D.list:GetHeight() and D.list:GetHeight() > 0 then
        return math.max(8, math.min(C.ROW_MAX, math.floor(D.list:GetHeight() / C.ROW_H)))
    end
    return 18
end

function Paint()
    if not D.rows then return end
    local n = S.deals and #S.deals or 0
    local vis = VisCount()
    D.vis = vis
    S.offset = math.max(0, math.min(S.offset or 0, math.max(0, n - vis)))
    if D.painting then return end
    D.painting = true
    if D.list and D.list:GetWidth() and D.list:GetWidth() > 50 then
        LayoutCols(D.list:GetWidth())
    end
    if D.PlaceHeads then D.PlaceHeads() end
    if D.bar then
        local maxOff = math.max(0, n - vis)
        D.bar:SetMinMaxValues(0, maxOff)
        D.bar:SetValue(S.offset)
        if maxOff > 0 then D.bar:Show() else D.bar:Hide() end
    end
    for i = 1, C.ROW_MAX do
        local r = D.rows[i]
        if i > vis then
            r:Hide()
        else
            local e = S.deals and S.deals[S.offset + i]
            if not e then
                r:Hide()
            else
                r.deal = e
                r:SetHeight(C.ROW_H)
                r:ClearAllPoints()
                r:SetPoint("TOPLEFT", D.list, "TOPLEFT", 0, -((i - 1) * C.ROW_H))
                r:SetPoint("TOPRIGHT", D.list, "TOPRIGHT", 0, -((i - 1) * C.ROW_H))
                PlaceRow(r)
                local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(e.entry)
                r.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
                TrimIcon(r.icon)
                local q = ITEM_QUALITY_COLORS[e.quality or 1]
                local name = e.name ~= "" and e.name or ("Item " .. e.entry)
                if q then
                    name = string.format("|cff%02x%02x%02x%s|r", q.r * 255, q.g * 255, q.b * 255, name)
                end
                r.name:SetText(name)
                if r.mythic then r.mythic:SetText(MythicTag(e.mythic, e.mythicMax)) end
                r.score:SetText((e.total or 0) > 0 and ("|cffe8d5a3" .. Compact(e.total) .. "|r") or "|cff666666—|r")
                local bits = TopStats(e.stats)
                for s = 1, 3 do
                    local cell = r.statCells[s]
                    local bit = bits[s]
                    if bit then
                        local c = STAT_COLOR[bit.k] or { 0.8, 0.8, 0.8 }
                        cell.lab:SetText(STAT_LABEL[bit.k])
                        cell.lab:SetTextColor(c[1], c[2], c[3])
                        cell.val:SetText(Compact(bit.v))
                        cell.val:SetTextColor(1, 1, 1)
                        cell.lab:Show()
                        cell.val:Show()
                    else
                        cell.lab:SetText(s == 1 and "—" or "")
                        cell.lab:SetTextColor(0.4, 0.4, 0.45)
                        cell.val:SetText("")
                    end
                end
                r.price:SetText("|cffffd700" .. GoldText(e.minPrice) .. "|r")
                r.ratio:SetText((e.perGold or 0) > 0 and ("|cff9ee0b0" .. RatioText(e.perGold) .. "|r") or "|cff666666—|r")
                r.seller:SetText(SellerText(e.owner))
                local pal = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.C and _G.qtEasyAuctionSkin.C()
                if r.bg then
                    local tint = (i % 2 == 0) and (pal and pal.rowA) or (pal and pal.rowB)
                    if tint then
                        r.bg:SetVertexColor(tint[1], tint[2], tint[3], tint[4] or 0.95)
                    else
                        r.bg:SetVertexColor(0.12, 0.11, 0.16, 0.95)
                    end
                end
                if r.sel then
                    if S.sweepSet and S.sweepSet[DealKey(e)] then
                        local g = pal and pal.gold or { 1, 0.84, 0.45 }
                        r.sel:SetVertexColor(g[1], g[2], g[3], 0.32)
                        r.sel:Show()
                    else
                        r.sel:Hide()
                    end
                end
                r:Show()
            end
        end
    end
    if D.count then
        local n = S.deals and #S.deals or 0
        local total = S.allDeals and #S.allDeals or n
        if n > 0 and total > n then
            D.count:SetText(n .. " of " .. total)
        else
            D.count:SetText(n > 0 and (n .. " deals") or "")
        end
    end
    if _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.SetEmpty then
        local hideEmpty = n == 0
        if D.weightFrame and D.weightFrame:IsShown() then hideEmpty = false end
        _G.qtEasyAuctionSkin.SetEmpty(hideEmpty)
    end
    D.painting = nil
end

local function HideBought(idRaw, entry)
    local function drop(list)
        if not list then return end
        for i = #list, 1, -1 do
            local e = list[i]
            if (idRaw and e.idRaw == idRaw) or (not idRaw and entry and e.entry == entry) then
                table.remove(list, i)
            end
        end
    end
    drop(S.deals)
    drop(S.allDeals)
    drop(S.summaries)
    Paint()
end

-- ʕ •ᴥ•ʔ✿ same BOUGHT codes the AH prints to chat ✿ ʕ •ᴥ•ʔ
local function OnBought(code, detail)
    local pending = table.remove(S.pendingBuys, 1)
    code = tostring(code or "")
    detail = detail or ""
    if code == "OK" or code == "NOSUCH" then
        if pending then HideBought(pending.idRaw, pending.entry) end
    end
    if code == "OK" then
        local copper = tonumber(string.match(detail, "^(%d+)")) or 0
        if pending and copper <= 0 then copper = tonumber(pending.copper) or 0 end
        local Sales = _G.qtEasyAuctionSales
        if Sales and Sales.NoteBuy then
            Sales.NoteBuy(pending and pending.name, copper, pending and pending.idRaw)
        end
    end
    if S.massLeft and S.massLeft > 0 then
        S.massLeft = S.massLeft - 1
        if code == "OK" then S.massOk = (S.massOk or 0) + 1 end
        S.massWaiting = nil
        if S.massLeft <= 0 then
            FinishMassBuy()
        else
            S.massNextAt = GetTime() + math.max(0, tonumber(AccountDB().bulkBuyDelay) or 0.10)
            SetStatus(string.format("Buying… %d of %d bought.", S.massOk or 0, S.massTotal or 0))
        end
        return
    end
    if code == "OK" then
        local copper = tonumber(string.match(detail, "^(%d+)"))
        SetStatus(copper
            and ("Bought for " .. GoldText(copper) .. ". On the way to your mailbox.")
            or "Bought. It's on the way to your mailbox.")
    elseif code == "NOSUCH" then
        SetStatus("That one's gone. Someone got there first.")
    elseif code == "NOMONEY" then
        SetStatus("You can't afford that one.")
    elseif code == "OWNAUCTION" then
        SetStatus("That's your own listing.")
    elseif code == "PRICECHANGED" then
        local copper = tonumber(string.match(detail, "^(%d+)"))
        SetStatus(copper
            and ("The price is now " .. GoldText(copper) .. ". Nothing was charged.")
            or "The price changed. Nothing was charged.")
    end
end

local function QueueBuy(row)
    if not row then return end
    S.pendingBuys[#S.pendingBuys + 1] = {
        idRaw = row.idRaw,
        entry = row.entry,
        name = row.name,
        copper = tonumber(row.buyoutRaw or row.buyout or row.minPriceRaw or row.minPrice) or 0,
    }
end

FinishMassBuy = function()
    local bought, total = S.massOk or 0, S.massTotal or 0
    S.massQueue, S.massWaiting, S.massNextAt = nil, nil, nil
    S.massLeft, S.massTotal, S.massOk = nil, nil, nil
    if S.massPump then S.massPump:Hide() end
    SetStatus(string.format("Mass buy done — %d of %d bought. Mail is on the way.", bought, total))
end

local function PumpMassBuy()
    if not S.massQueue or S.massWaiting then return end
    if S.massNextAt and GetTime() < S.massNextAt then return end
    local deal = table.remove(S.massQueue, 1)
    if not deal then
        FinishMassBuy()
        return
    end
    QueueBuy(deal)
    S.massWaiting = true
    SetStatus(string.format("Buying… %d of %d bought.", S.massOk or 0, S.massTotal or 0))
    local ok = pcall(PeloriaSend, string.format("%s^BUY^%s^%s", C.PREFIX, deal.idRaw, deal.buyoutRaw))
    if not ok then
        table.remove(S.pendingBuys, #S.pendingBuys)
        S.massQueue, S.massWaiting, S.massNextAt = nil, nil, nil
        S.massLeft, S.massTotal, S.massOk = nil, nil, nil
        SetStatus("Bulk buying stopped — PeloriaSend failed.")
        return
    end
end

local function StartMassPump()
    if not S.massPump then
        S.massPump = CreateFrame("Frame", nil, UIParent)
        S.massPump:SetScript("OnUpdate", function()
            if S.massQueue and not S.massWaiting then
                PumpMassBuy()
            elseif not S.massQueue then
                S.massPump:Hide()
            end
        end)
    end
    S.massPump:Show()
    PumpMassBuy()
end

local function HideSweepGold()
    if D.sweepGold then D.sweepGold:Hide() end
end

local function ClearSweep()
    S.sweep, S.sweepHeld, S.sweepHover, S.sweepSet, S.sweepOrder, S.sweepAnchor = false, false, nil, nil, nil, nil
    S.massList = nil
    HideSweepGold()
    if D.rows then Paint() end
end

local function IndexOfDeal(deal)
    if not deal or not S.deals then return end
    for i = 1, #S.deals do
        if S.deals[i] == deal then return i end
    end
    if deal.idRaw then
        for i = 1, #S.deals do
            if S.deals[i].idRaw == deal.idRaw then return i end
        end
    elseif deal.entry then
        for i = 1, #S.deals do
            if S.deals[i].entry == deal.entry then return i end
        end
    end
end

local function SweepAdd(deal)
    if not deal then return end
    local key = DealKey(deal)
    if S.sweepSet[key] then return end
    S.sweepSet[key] = deal
    S.sweepOrder[#S.sweepOrder + 1] = deal
end

-- ʕ ● ᴥ ●ʔ✿ shift-right drag paints a contiguous buy range ✿ ʕ ● ᴥ ●ʔ
local function SweepTo(deal)
    if not deal then return end
    if not S.sweepAnchor then S.sweepAnchor = deal end
    local a, b = IndexOfDeal(S.sweepAnchor), IndexOfDeal(deal)
    if not a or not b then
        SweepAdd(deal)
        return
    end
    if a > b then a, b = b, a end
    S.sweepSet, S.sweepOrder = {}, {}
    for i = a, b do SweepAdd(S.deals[i]) end
end

local function MassStats(list)
    local stats, copper, score = {}, 0, 0
    for i = 1, #(list or {}) do
        local d = list[i]
        copper = copper + (tonumber(d.buyoutRaw or d.minPriceRaw or d.minPrice) or 0)
        score = score + (tonumber(d.total) or 0)
        local s = d.stats or {}
        for k = 1, #STAT_KEYS do
            local key = STAT_KEYS[k]
            local v = tonumber(s[key]) or 0
            if v > 0 then stats[key] = (stats[key] or 0) + v end
        end
    end
    return stats, copper, score
end

function PaintSweepGold()
    if not S.sweep then
        HideSweepGold()
        return
    end
    if not D.sweepGold then
        local f = CreateFrame("Frame", nil, UIParent)
        f:SetFrameStrata("TOOLTIP")
        f:SetFrameLevel(128)
        f:SetWidth(180)
        f:SetHeight(18)
        f:EnableMouse(false)
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("LEFT", 0, 0)
        fs:SetJustifyH("LEFT")
        local font, size = fs:GetFont()
        if font then fs:SetFont(font, size or 12, "OUTLINE") end
        D.sweepGoldFs = fs
        D.sweepGold = f
    end
    local _, copper = MassStats(S.sweepOrder)
    local have = GoldTotal()
    local left = have - copper
    local pal = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.C and _G.qtEasyAuctionSkin.C()
    local fs = D.sweepGoldFs
    if left >= 0 then
        fs:SetText("after  " .. GoldText(left))
        local g = pal and pal.gold or { 1, 0.84, 0.45 }
        fs:SetTextColor(g[1], g[2], g[3])
    else
        fs:SetText("short  " .. GoldText(copper - have))
        fs:SetTextColor(1, 0.45, 0.4)
    end
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale() or 1
    D.sweepGold:ClearAllPoints()
    D.sweepGold:SetPoint("LEFT", UIParent, "BOTTOMLEFT", (x / scale) + 18, y / scale)
    D.sweepGold:Show()
end

function PaintMassGoldWarn()
    if not S.massList then return end
    local _, copper = MassStats(S.massList)
    local have = GoldTotal()
    local left = have - copper
    local pal = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.C and _G.qtEasyAuctionSkin.C()
    if D.massHave then
        if left >= 0 then
            D.massHave:SetText("You have  " .. GoldText(have) .. "   ·   after buying  " .. GoldText(left))
            if pal and pal.cream then
                D.massHave:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3])
            else
                D.massHave:SetTextColor(0.95, 0.90, 0.82)
            end
        else
            D.massHave:SetText("You have  " .. GoldText(have) .. "   ·   after buying  0g")
            D.massHave:SetTextColor(1, 0.45, 0.4)
        end
        D.massHave:Show()
    end
    if not D.massWarn then return end
    if have < copper then
        D.massWarn:SetText("Short  " .. GoldText(copper - have))
        D.massWarn:Show()
    else
        D.massWarn:SetText("")
        D.massWarn:Hide()
    end
end

local function MassStatText(stats)
    local bits = {}
    for i = 1, #STAT_KEYS do
        local k = STAT_KEYS[i]
        local v = stats[k]
        if v and v > 0 then
            local c = STAT_COLOR[k] or { 1, 1, 1 }
            bits[#bits + 1] = string.format("|cff%02x%02x%02x+%s %s|r",
                c[1] * 255, c[2] * 255, c[3] * 255, Compact(v), STAT_LABEL[k])
        end
    end
    if #bits == 0 then return "|cff888888No soulbind stats on these.|r" end
    local lines, row = {}, {}
    for i = 1, #bits do
        row[#row + 1] = bits[i]
        if #row == 3 or i == #bits then
            lines[#lines + 1] = table.concat(row, "    ")
            row = {}
        end
    end
    return table.concat(lines, "\n")
end

local function CanMassBuy(deal)
    if not deal or not deal.idRaw or not deal.buyoutRaw then return false end
    local me = UnitName("player")
    if deal.owner and me and deal.owner == me then return false end
    if IsSellerHidden(deal.owner) then return false end
    return true
end

local function BuyPicked(list)
    if type(PeloriaSend) ~= "function" then
        SetStatus("PeloriaSend missing — stand at an auctioneer.")
        return
    end
    InstallHook()
    local queue = {}
    for i = 1, #(list or {}) do
        local deal = list[i]
        if CanMassBuy(deal) then
            queue[#queue + 1] = deal
        end
    end
    if #queue == 0 then
        SetStatus("Nothing in that sweep can be bought yet.")
        return
    end
    if S.massQueue or S.massWaiting or #S.pendingBuys > 0 then
        SetStatus("A bulk purchase is already running.")
        return
    end
    S.massQueue = queue
    S.massTotal, S.massOk, S.massLeft = #queue, 0, #queue
    S.massNextAt = 0
    StartMassPump()
end

local function PaintMassConfirm()
    local pal = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.C and _G.qtEasyAuctionSkin.C()
    local f = D.massFrame
    if not f or not pal then return end
    f:SetBackdropColor(pal.bg[1], pal.bg[2], pal.bg[3], 0.98)
    f:SetBackdropBorderColor(pal.accent[1], pal.accent[2], pal.accent[3], 1)
    if D.massTitle then D.massTitle:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3]) end
    if D.massCost then D.massCost:SetTextColor(pal.gold[1], pal.gold[2], pal.gold[3]) end
    if D.massScore then D.massScore:SetTextColor(pal.accent[1], pal.accent[2], pal.accent[3]) end
    local function paintBtn(b)
        if not b then return end
        if b.bg then
            b.bg:SetVertexColor(pal.btn[1], pal.btn[2], pal.btn[3], 1)
        end
        if b.label then
            b.label:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3], 1)
        end
        b:Enable()
        b:EnableMouse(true)
    end
    paintBtn(D.massBuyBtn)
    paintBtn(D.massCancelBtn)
end

local function MassBtn(parent, w, h, label)
    local pal = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.C and _G.qtEasyAuctionSkin.C()
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(w)
    b:SetHeight(h)
    b:EnableMouse(true)
    b:Enable()
    b:RegisterForClicks("LeftButtonUp")
    b:SetFrameLevel((parent:GetFrameLevel() or 1) + 8)
    b.bg = b:CreateTexture(nil, "ARTWORK")
    b.bg:SetAllPoints()
    b.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    local br, bg, bb = 0.42, 0.28, 0.46
    if pal and pal.btn then br, bg, bb = pal.btn[1], pal.btn[2], pal.btn[3] end
    b.bg:SetVertexColor(br, bg, bb, 1)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetAllPoints()
    fs:SetJustifyH("CENTER")
    local cr, cg, cb = 0.95, 0.90, 0.82
    if pal and pal.cream then cr, cg, cb = pal.cream[1], pal.cream[2], pal.cream[3] end
    fs:SetTextColor(cr, cg, cb, 1)
    fs:SetText(label)
    b.label = fs
    b:SetScript("OnEnter", function(self)
        local p = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.C and _G.qtEasyAuctionSkin.C()
        local c = p and p.btnHi or { 0.58, 0.40, 0.58 }
        self.bg:SetVertexColor(c[1], c[2], c[3], 1)
    end)
    b:SetScript("OnLeave", function(self)
        local p = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.C and _G.qtEasyAuctionSkin.C()
        local c = p and p.btn or { 0.42, 0.28, 0.46 }
        self.bg:SetVertexColor(c[1], c[2], c[3], 1)
    end)
    return b
end

local function EnsureMassConfirm()
    if D.massFrame then return D.massFrame end
    local host = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.host
    local parent = host or UIParent
    local f = CreateFrame("Frame", "qtEasyAuctionMassBuy", parent)
    f:SetWidth(360)
    f:SetHeight(236)
    f:SetPoint("CENTER", 0, 40)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel((parent:GetFrameLevel() or 1) + 80)
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    local grip = CreateFrame("Frame", nil, f)
    grip:SetPoint("TOPLEFT", 4, -4)
    grip:SetPoint("TOPRIGHT", -4, -4)
    grip:SetHeight(36)
    grip:EnableMouse(true)
    grip:RegisterForDrag("LeftButton")
    grip:SetScript("OnDragStart", function() f:StartMoving() end)
    grip:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -16)
    D.massTitle = title
    local cost = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cost:SetPoint("TOP", title, "BOTTOM", 0, -10)
    D.massCost = cost
    local have = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    have:SetPoint("TOP", cost, "BOTTOM", 0, -6)
    D.massHave = have
    local score = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    score:SetPoint("TOP", have, "BOTTOM", 0, -6)
    D.massScore = score
    local stats = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    stats:SetPoint("TOP", score, "BOTTOM", 0, -12)
    stats:SetWidth(320)
    stats:SetJustifyH("CENTER")
    D.massStats = stats
    local warn = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    warn:SetPoint("BOTTOM", 0, 52)
    warn:SetWidth(320)
    warn:SetJustifyH("CENTER")
    warn:SetTextColor(1, 0.45, 0.4)
    D.massWarn = warn
    local buy = MassBtn(f, 120, 32, "Buy all")
    local cancel = MassBtn(f, 100, 32, "Cancel")
    buy:SetPoint("BOTTOMRIGHT", -20, 14)
    cancel:SetPoint("BOTTOMLEFT", 20, 14)
    buy:SetScript("OnClick", function()
        local list = S.massList
        f:Hide()
        ClearSweep()
        BuyPicked(list)
    end)
    cancel:SetScript("OnClick", function()
        f:Hide()
        ClearSweep()
    end)
    f:SetScript("OnHide", function()
        if S.massList then ClearSweep() end
    end)
    D.massBuyBtn = buy
    D.massCancelBtn = cancel
    D.massFrame = f
    tinsert(UISpecialFrames, "qtEasyAuctionMassBuy")
    return f
end

local function ShowMassConfirm(list)
    local buyable = {}
    for i = 1, #(list or {}) do
        if CanMassBuy(list[i]) then buyable[#buyable + 1] = list[i] end
    end
    if #buyable == 0 then
        SetStatus("Nothing buyable in that sweep.")
        ClearSweep()
        return
    end
    S.massList = buyable
    local stats, copper, score = MassStats(buyable)
    local f = EnsureMassConfirm()
    local n = #buyable
    D.massTitle:SetText(n == 1 and "Buy this listing?" or ("Buy " .. n .. " listings?"))
    D.massCost:SetText("Cost  " .. Commas(GoldRaw(copper)) .. "g   ·   " .. GoldText(copper))
    D.massScore:SetText("Score gain  +" .. Compact(score))
    D.massStats:SetText(MassStatText(stats))
    PaintMassConfirm()
    PaintMassGoldWarn()
    f:SetFrameStrata("TOOLTIP")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:Show()
    f:Raise()
    if D.massBuyBtn then
        D.massBuyBtn:Enable()
        D.massBuyBtn:Raise()
    end
    if D.massCancelBtn then
        D.massCancelBtn:Enable()
        D.massCancelBtn:Raise()
    end
end

local function FinishSweep()
    if not S.sweep then return end
    S.sweep, S.sweepHeld = false, false
    HideSweepGold()
    local list = S.sweepOrder
    if list and #list > 0 then
        if AccountDB().confirmMassBuy then
            ShowMassConfirm(list)
        else
            ClearSweep()
            BuyPicked(list)
        end
    else
        ClearSweep()
    end
end

function MakeDeal(s)
    local info = s.info or {}
    local score, bestKey = WeightedScore(info.stats, "sell")
    local gold = GoldRaw(s.minPrice)
    if gold < 1 then gold = 1 end
    local per = (score > 0) and (score / gold) or 0
    return {
        entry = s.entry,
        name = s.name,
        quality = s.quality,
        minPrice = s.minPrice,
        minPriceRaw = s.minPriceRaw or s.buyoutRaw,
        mythic = s.minMythic or 0,
        mythicMax = s.maxMythic or s.minMythic or 0,
        affix = s.affix or 0,
        owner = s.owner,
        perGold = per,
        perK = (score > 0) and (score * 1000 / gold) or 0,
        gold = gold,
        statText = FormatStatLine(info.stats, score, bestKey),
        stats = info.stats,
        preview = info.preview,
        total = score,
        waiting = info.waiting,
        idRaw = s.idRaw,
        buyoutRaw = s.buyoutRaw,
    }
end

function FinishRead(keepOffset)
    local out = {}
    for i = 1, #(S.summaries or {}) do
        local s = S.summaries[i]
        FillInfoFromPackets(s)
        if S.searchAllScan or not (s.info and s.info.blocked) then
            out[#out + 1] = MakeDeal(s)
        end
    end
    S.allDeals = out
    S.filterText = CleanQuery(D.searchBox and D.searchBox:GetText() or S.filterText or "")
    if not keepOffset then S.offset = 0 end
    ApplyFilter(true)
    S.state = "idle"
    PaintPreviewProgress()
    local got = 0
    for i = 1, #out do
        if PreviewRows(out[i].preview) then got = got + 1 end
    end
    if #out == 0 then
        SetStatus(EmptyStatus())
    else
        local q = CleanQuery(S.searchQuery)
        if q ~= "" then
            SetStatus(string.format("Search '%s' — %d items, %d with preview. Type to filter.", q, #out, got))
        else
            SetStatus(string.format("Weighted score / gold — %d items, %d with preview. Type to filter.", #out, got))
        end
    end
    ScanLabel()
end

local function StripPrefix(body)
    body = body or ""
    body = string.gsub(body, "^PELAH%^", "")
    return body
end

local function UsePreviewPackets()
    return type(PeloriaSend) == "function"
end

function FillInfoFromPackets(s)
    local level = s.minMythic or 0
    if level == 0 then level = s.maxMythic or 0 end
    local affix = AffixForSoulbind(s.affix)
    local elig = PeloriaSoulbindEligibility and PeloriaSoulbindEligibility[s.entry]
    local skipPreview = S.searchAllScan and (elig == 0 or elig == 1)
    local preview = CachedPreview(s.entry, level, affix)
    s.info = {
        blocked = elig == 1,
        preview = preview,
        stats = StatsFromPreview(preview),
        waiting = (not skipPreview) and preview == nil,
    }
end

local function JobPreviewDone(j)
    return CachedPreview(j.entry, j.level, j.affix) or GiveUpPreview(j.entry, j.level, j.affix)
end

local function PreviewCounts()
    local jobs, seen = S.previewJobs or {}, {}
    local need, got, pending = 0, 0, 0
    for i = 1, #jobs do
        local j = jobs[i]
        if j and j.key and not seen[j.key] then
            seen[j.key] = true
            need = need + 1
            if CachedPreview(j.entry, j.level, j.affix) then
                got = got + 1
            elseif not GiveUpPreview(j.entry, j.level, j.affix)
                and (S.previewTries[j.key] or 0) < C.PREVIEW_TRIES then
                pending = pending + 1
            end
        end
    end
    return got, need, pending
end

function PaintPreviewProgress()
    local got, need, pending = PreviewCounts()
    local resolved = need - pending
    local active = (S.state == "fetch" or S.state == "fill" or S.state == "preview") and need > 0 and pending > 0
    if D.prog then
        if active then
            D.prog:Show()
            local w = D.prog:GetWidth() or 0
            if w < 8 then w = 200 end
            local frac = need > 0 and (resolved / need) or 0
            if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
            D.progFill:SetWidth(math.max(1, w * frac))
        else
            D.prog:Hide()
        end
    end
    return got, need, pending, active, resolved
end

local function MarkPreviewGiveUp(key)
    if not key then return end
    S.flight[key] = nil
end

local function QueueRetry(job)
    if not job or not job.key or JobPreviewDone(job) then return false end
    if (S.previewTries[job.key] or 0) >= C.PREVIEW_TRIES then
        MarkPreviewGiveUp(job.key)
        return false
    end
    local jobs = S.previewJobs
    if not jobs then return false end
    if S.flight[job.key] and S.flight[job.key] > GetTime() then return false end
    for i = S.qIdx, #jobs do
        if jobs[i] and jobs[i].key == job.key then return false end
    end
    if S.peekWrapped.sent then S.peekWrapped.sent[job.key] = nil end
    jobs[#jobs + 1] = { entry = job.entry, level = job.level, affix = job.affix, key = job.key }
    return true
end

local function RequeueUnresolved()
    local jobs, best = S.previewJobs or {}, {}
    for i = 1, #jobs do
        local j = jobs[i]
        if j and j.key then best[j.key] = j end
    end
    local n = 0
    for _, j in pairs(best) do
        if QueueRetry(j) then n = n + 1 end
    end
    return n
end

local function JobByKey(key)
    local jobs = S.previewJobs or {}
    for i = #jobs, 1, -1 do
        if jobs[i] and jobs[i].key == key then return jobs[i] end
    end
end

-- ʕ •ᴥ•ʔ✿ queue drill + preview as pages land so the list is buyable live ✿ ʕ •ᴥ•ʔ
function EnqueueNewWork()
    S.drillJobs = S.drillJobs or {}
    S.previewJobs = S.previewJobs or {}
    for i = 1, #(S.summaries or {}) do
        local s = S.summaries[i]
        local e = s.entry
        if e and not S.drillSeen[e] then
            S.drillSeen[e] = true
            if not s.idRaw then
                S.drillJobs[#S.drillJobs + 1] = { entry = e }
            end
        end
        local level = s.minMythic or 0
        if level == 0 then level = s.maxMythic or 0 end
        local affix = AffixForSoulbind(s.affix)
        local key = PreviewKey(e, level, affix)
        if e and not S.previewSeen[key] then
            S.previewSeen[key] = true
            local elig = PeloriaSoulbindEligibility and PeloriaSoulbindEligibility[e]
            if not (S.searchAllScan and (elig == 0 or elig == 1)) then
                S.previewJobs[#S.previewJobs + 1] = { entry = e, level = level, affix = affix, key = key }
            end
        end
    end
end

local function DrillBusy()
    return S.drillInFlight > 0 or (S.drillJobs and S.drillIdx <= #S.drillJobs)
end

local function PreviewBusy()
    S.inFlight = LiveFlights()
    if S.inFlight > 0 then return true end
    if S.previewJobs and S.qIdx <= #S.previewJobs then return true end
    return false
end

function PumpPublish()
    if S.state ~= "fetch" and S.state ~= "fill" then return end
    if not S.summaries or #S.summaries == 0 then return end
    local now = GetTime()
    local mid = S.pubIdx > 1
    local draining = S.state == "fill" and not DrillBusy() and not PreviewBusy()
    if not mid and not S.liveDirty and not draining then return end
    if not mid and not draining and #S.allDeals > 0 and now - S.liveAt < C.LIVE_DT then return end
    if type(debugprofilestart) == "function" then debugprofilestart() end
    local n = #S.summaries
    if not mid then
        S.pubOut, S.pubIdx = {}, 1
    end
    local cap = S.pubIdx + C.FILL_FRAME - 1
    if cap > n then cap = n end
    while S.pubIdx <= cap do
        local s = S.summaries[S.pubIdx]
        FillInfoFromPackets(s)
        if S.searchAllScan or not (s.info and s.info.blocked) then
            S.pubOut[#S.pubOut + 1] = MakeDeal(s)
        end
        S.pubIdx = S.pubIdx + 1
        if FrameOver(C.FRAME_MS) then break end
    end
    if S.pubIdx <= n then
        S.liveDirty = true
        return
    end
    S.pubIdx = 1
    S.liveAt = now
    S.liveDirty = S.state == "fetch" or DrillBusy() or PreviewBusy()
    S.allDeals = S.pubOut
    ApplyFilter(true)
    local sellers, got = 0, 0
    for i = 1, #S.allDeals do
        local d = S.allDeals[i]
        if d.owner and d.owner ~= "" then sellers = sellers + 1 end
        if PreviewRows(d.preview) then got = got + 1 end
    end
    local _, need, pending, active, resolved = PaintPreviewProgress()
    if active then
        local pct = math.floor(resolved / need * 100 + 0.5)
        SetStatus(string.format("Fetching previews  %d / %d  —  %d%%", resolved, need, pct))
    else
        SetStatus(string.format("Live · %d listed · %d scored · %d sellers · work %d",
            #S.allDeals, got, sellers, S.drillInFlight + S.inFlight))
    end
end

function MaybeFinishScan()
    if S.state ~= "fill" then return end
    if DrillBusy() or PreviewBusy() then return end
    FinishRead(true)
end

function PumpScore()
    if S.state ~= "score" then return end
    BeginFrameWork()
    local n = #(S.summaries or {})
    local i, cap = S.scoreIdx or 1, (S.scoreIdx or 1) + C.FILL_FRAME - 1
    if cap > n then cap = n end
    while i <= cap do
        FillInfoFromPackets(S.summaries[i])
        i = i + 1
        if FrameOver(C.FRAME_MS) then break end
    end
    S.scoreIdx = i
    if n > 0 then
        SetStatus(string.format("Scoring %d/%d", math.min(i - 1, n), n))
    end
    if S.scoreIdx <= n then return end
    local keep = S.scoreKeep
    S.scoreKeep = nil
    FinishRead(keep)
end

function FinishPreviewPass()
    if S.state == "preview" then S.state = "fill" end
    S.liveDirty = true
end

function PumpPreview()
    if (S.state ~= "fetch" and S.state ~= "fill" and S.state ~= "preview") or S.previewPumping then return end
    S.previewPumping = true
    local function work()
        if type(debugprofilestart) == "function" then debugprofilestart() end
        local now = GetTime()
        if now ~= S.frameStamp then
            S.frameStamp, S.frameAsks, S.frameSkips, S.frameDrillAsks, S.framePreviewAsks = now, 0, 0, 0, 0
        end
        local expired = {}
        for k, t in pairs(S.flight) do
            if now > t then expired[#expired + 1] = k end
        end
        for i = 1, #expired do
            local key = expired[i]
            S.flight[key] = nil
            QueueRetry(JobByKey(key))
        end
        local jobs = S.previewJobs or {}
        local nJobs = #jobs
        while S.qIdx <= nJobs do
            local j = jobs[S.qIdx]
            if not j or not j.key then
                S.qIdx = S.qIdx + 1
            elseif JobPreviewDone(j) then
                S.qIdx = S.qIdx + 1
            elseif (S.previewTries[j.key] or 0) >= C.PREVIEW_TRIES then
                MarkPreviewGiveUp(j.key)
                S.qIdx = S.qIdx + 1
            elseif S.flight[j.key] and now < S.flight[j.key] then
                S.qIdx = S.qIdx + 1
            elseif LiveFlights() >= C.FLY_MAX or S.framePreviewAsks >= C.PREVIEW_ASK then
                break
            else
                S.qIdx = S.qIdx + 1
                S.framePreviewAsks = S.framePreviewAsks + 1
                S.previewTries[j.key] = (S.previewTries[j.key] or 0) + 1
                if SendPreview(j.entry, j.level, j.affix) then
                    S.flight[j.key] = nil
                    S.liveDirty = true
                elseif not S.flight[j.key] then
                    S.flight[j.key] = now + C.FLY_WAIT
                end
                if FrameOver(C.FRAME_MS) then break end
            end
        end
        nJobs = #(S.previewJobs or {})
        if S.qIdx > nJobs and LiveFlights() == 0 and nJobs > 0 then
            RequeueUnresolved()
        end
        S.inFlight = LiveFlights()
        if now - (S.previewStatusAt or 0) > 0.15 then
            S.previewStatusAt = now
            local _, need, _, active, resolved = PaintPreviewProgress()
            if active then
                local pct = math.floor(resolved / need * 100 + 0.5)
                SetStatus(string.format("Fetching previews  %d / %d  —  %d%%", resolved, need, pct))
            end
        end
    end
    pcall(work)
    S.previewPumping = false
    S.inFlight = LiveFlights()
end

function BeginTooltipPass()
    S.extraWait = false
    S.resent = false
    S.askTries = {}
    S.peekWrapped.empty = S.peekWrapped.empty or {}
    S.peekWrapped.sent = S.peekWrapped.sent or {}
    if S.previewRound < 1 then S.previewRound = 1 end
    S.previewPumping = false
    EnqueueNewWork()
    S.liveDirty = true
    PumpPreview()
end

local function OnPacket(body)
    body = StripPrefix(body)
    if body == "NOFILTER" then
        if S.state == "fetch" then SetStatus("Soulbind filter still loading — try Scan again.") end
        return
    end

    local boughtCode, boughtDetail = string.match(body, "^BOUGHT%^([^%^]*)%^(.*)$")
    if not boughtCode then
        boughtCode = string.match(body, "^BOUGHT%^([^%^]+)")
    end
    if boughtCode then
        OnBought(boughtCode, boughtDetail)
        return
    end

    local isSummary = string.find(body, "^SUMMARY%^") == 1
    local isPage = string.find(body, "^PAGE%^") == 1
    if not isSummary and not isPage then return end

    local kind, g, pg, pages = string.match(body, "^(%u+)%^(%d+)%^(%d+)%^(%d+)%^")
    g, pg, pages = tonumber(g), tonumber(pg), tonumber(pages)

    if S.buyGen and isPage and g == S.buyGen then
        local first = string.find(body, "~", 1, true)
        local rows = ParseListings(first and string.sub(body, first + 1) or "")
        local me = UnitName("player")
        local best
        for i = 1, #rows do
            local e = rows[i]
            if e.entry == S.buyEntry and e.owner ~= me then
                if not best or e.buyout < best.buyout then best = e end
            end
        end
        S.buyGen, S.buyEntry = nil, nil
        if not best then
            SetStatus("No listing left to buy.")
            return
        end
        if GoldTotal() < best.buyout then
            SetStatus("Not enough gold.")
            return
        end
        QueueBuy(best)
        PeloriaSend(string.format("%s^BUY^%s^%s", C.PREFIX, best.idRaw, best.buyoutRaw))
        SetStatus("Buying " .. (best.name or "") .. " for " .. GoldText(best.buyout) .. ".")
        return
    end

    if isPage and S.drillByGen and S.drillByGen[g] then
        local job = S.drillByGen[g]
        local entry = type(job) == "table" and job.entry or job
        local first = string.find(body, "~", 1, true)
        local rows = ParseListings(first and string.sub(body, first + 1) or "")
        if type(job) == "table" then
            for i = 1, #rows do job.rows[#job.rows + 1] = rows[i] end
            if pg + 1 < (pages or 1) and pg + 1 < C.PAGE_CAP then
                S.drillFlight[g] = GetTime() + 2.5
                Search(g, pg + 1, entry)
                return
            end
        end
        S.drillByGen[g] = nil
        if S.drillFlight[g] then
            S.drillFlight[g] = nil
            S.drillInFlight = math.max(0, S.drillInFlight - 1)
        end
        ExpandListings(entry, type(job) == "table" and job.rows or rows)
        EnqueueNewWork()
        S.liveDirty = true
        PumpDrill()
        PumpPreview()
        return
    end

    if g ~= S.gen or (S.state ~= "fetch" and S.state ~= "fill") then return end
    S.seenPages = S.seenPages or {}
    local key = kind .. ":" .. pg
    if S.seenPages[key] then return end
    S.seenPages[key] = true
    S.fetchLeft = 20

    local first = string.find(body, "~", 1, true)
    local tail = first and string.sub(body, first + 1) or ""
    if isSummary then
        local rows = ParseSummaryRows(tail)
        for i = 1, #rows do S.summaries[#S.summaries + 1] = rows[i] end
    else
        local rows = ParseListings(tail)
        for i = 1, #rows do
            local e = rows[i]
            S.summaries[#S.summaries + 1] = {
                entry = e.entry,
                count = 1,
                minPrice = e.buyout,
                minPriceRaw = e.buyoutRaw,
                minMythic = e.mythic,
                maxMythic = e.mythic,
                quality = e.quality,
                ilvl = 0,
                name = e.name,
                idRaw = e.idRaw,
                buyoutRaw = e.buyoutRaw,
                affix = e.randProp or 0,
                owner = e.owner,
            }
        end
    end

    if pg + 1 < (pages or 1) and pg + 1 < C.PAGE_CAP then
        page = pg + 1
        local label = S.searchAllScan and "Scanning all items…" or "Scanning soulbindable items…"
        SetStatus(string.format("%s page %d/%d · %d live", label, page + 1, math.min(pages, C.PAGE_CAP), #S.summaries))
        EnqueueNewWork()
        S.liveDirty = true
        Search(S.gen, page, 0)
        PumpDrill()
        PumpPreview()
        PumpPublish()
    else
        S.state = "fill"
        EnqueueNewWork()
        S.liveDirty = true
        PumpDrill()
        PumpPreview()
        PumpPublish()
    end
end

local function HandlersFromUpvalue()
    local dbg = _G.debug
    if type(dbg) ~= "table" or type(dbg.getupvalue) ~= "function" then return nil end
    local function isHandlers(val)
        return type(val) == "table" and (
            type(val.PELAH) == "function"
            or type(val.PELMYTH) == "function"
            or type(val.PELATTN) == "function"
        )
    end
    local function walk(fn, depth)
        if depth > 5 or type(fn) ~= "function" then return nil end
        for i = 1, 32 do
            local ok, name, val = pcall(dbg.getupvalue, fn, i)
            if not ok or name == nil then break end
            if isHandlers(val) then return val end
            if type(val) == "function" then
                local found = walk(val, depth + 1)
                if found then return found end
            end
        end
    end
    return walk(_G.PeloriaOnRawPacket, 0) or walk(_G.PeloriaOnPacket, 0)
end


local function GetHandlers()
    if type(S.packetHandlers) == "table" then return S.packetHandlers end
    local u = HandlersFromUpvalue()
    if type(u) == "table" then
        S.packetHandlers = u
        return u
    end
    local g = rawget(_G, "PeloriaPacketHandlers")
    if type(g) == "table" then
        S.packetHandlers = g
        return g
    end
end

local function FireMythicCbs()
    local cbs = S.mythicCbs
    S.mythicCbs = {}
    for i = 1, #cbs do pcall(cbs[i]) end
end

local function NotifyPostMythic()
    local post = _G.qtEasyAuctionPost
    if post and post.OnMythic then post.OnMythic() end
end

function D.ProcessPelMyth(body)
    if type(body) ~= "string" then return end
    body = string.gsub(body, "^PELMYTH%^", "")
    if body == "BAGBEGIN" then
        S.mythicSyncing, S.mythicSynced = true, false
        S.mythicPending = {}
        return
    end
    if body == "BAGEND" then
        S.mythicBags = S.mythicPending
        S.mythicPending = {}
        S.mythicSyncing, S.mythicSynced = false, true
        FireMythicCbs()
        NotifyPostMythic()
        return
    end
    for rec in string.gmatch(body, "[^~]+") do
        local b, s, l = string.match(rec, "B%^(%d+)%^(%d+)%^(%d+)")
        if b then
            local key = tonumber(b) * 100 + tonumber(s)
            local lvl = tonumber(l)
            if S.mythicSyncing then
                S.mythicPending[key] = lvl
            else
                S.mythicBags[key] = lvl
                NotifyPostMythic()
            end
        end
    end
end

function D.BagMythic(bag, slot)
    return S.mythicBags[(tonumber(bag) or 0) * 100 + (tonumber(slot) or 0)]
end

function D.MythicReady()
    return S.mythicSynced and true or false
end

function D.AskMythicBags(onDone)
    if InstallHook then InstallHook() end
    if type(onDone) == "function" then
        S.mythicCbs[#S.mythicCbs + 1] = onDone
    end
    if S.mythicSynced and not S.mythicSyncing then
        FireMythicCbs()
        return true
    end
    if type(PeloriaSend) == "function" and not S.mythicSyncing then
        local now = GetTime()
        if now - S.mythicAskedAt > 2 then
            S.mythicAskedAt = now
            pcall(PeloriaSend, "MYTHIC^BAGS")
        end
    end
    return S.mythicSynced
end

function InstallHook()
    InstallPeekHook()
    if type(PeloriaRefreshSoulbindTooltips) == "function" and PeloriaRefreshSoulbindTooltips ~= S.peekWrapped.refreshFn then
        local orig = PeloriaRefreshSoulbindTooltips
        S.peekWrapped.refreshFn = function(itemEntry)
            orig(itemEntry)
            OnSoulbindReady(itemEntry)
        end
        PeloriaRefreshSoulbindTooltips = S.peekWrapped.refreshFn
    end
    local handlers = GetHandlers()
    if type(handlers) == "table" and type(handlers.GOLD) == "function" and handlers.GOLD ~= S.goldFn then
        local orig = handlers.GOLD
        S.goldFn = function(rest, ...)
            local r1, r2, r3, r4, r5 = orig(rest, ...)
            OnGoldRest(rest)
            return r1, r2, r3, r4, r5
        end
        handlers.GOLD = S.goldFn
    end
    if type(handlers) == "table" and type(handlers.PELATTN) == "function" and handlers.PELATTN ~= S.attnFn then
        local orig = handlers.PELATTN
        S.attnFn = function(body, full, ...)
            local r1, r2, r3, r4, r5 = orig(body, full, ...)
            if type(full) == "string" then pcall(ParsePreviewBody, full) end
            pcall(ParsePreviewBody, body)
            return r1, r2, r3, r4, r5
        end
        handlers.PELATTN = S.attnFn
    end
    if type(handlers) == "table" and type(handlers.PELMYTH) == "function" and handlers.PELMYTH ~= S.mythFn then
        local orig = handlers.PELMYTH
        S.mythFn = function(body, full, ...)
            local r1, r2, r3, r4, r5 = orig(body, full, ...)
            pcall(D.ProcessPelMyth, body)
            if type(full) == "string" then pcall(D.ProcessPelMyth, full) end
            return r1, r2, r3, r4, r5
        end
        handlers.PELMYTH = S.mythFn
    end
    if S.peekWrapped.attnDone then return true end
    local peek = S.peekWrapped.ok
    local handlers = GetHandlers()
    if type(handlers) ~= "table" then return peek or false end
    if not peek and type(handlers[C.PREFIX]) == "function" then
        if handlers[C.PREFIX] ~= S.hookFn then
            local orig = handlers[C.PREFIX]
            S.hookFn = function(body, ...)
                pcall(OnPacket, body)
                if orig then return orig(body, ...) end
            end
            handlers[C.PREFIX] = S.hookFn
        end
    end
    S.peekWrapped.attnDone = true
    return true
end

local function RouteIncoming(a, b)
    if type(a) == "string" and a == "GOLD" then
        OnGoldRest(b)
        return
    end
    local payload = a
    if type(a) == "string" and type(b) == "string" and a == "PELATTN" then
        pcall(ParsePreviewBody, b)
        return
    end
    if type(a) == "string" and type(b) == "string" and a == "PELMYTH" then
        pcall(D.ProcessPelMyth, b)
        return
    end
    if type(a) == "string" and type(b) == "string" and a == "PELAH" then
        pcall(OnPacket, b)
        return
    end
    if type(payload) ~= "string" then payload = b end
    if type(payload) ~= "string" then return end
    if string.find(payload, "^PELATTN") or string.sub(payload, 1, 2) == "P^" then
        pcall(ParsePreviewBody, payload)
        return
    end
    local goldRest = string.match(payload, "^GOLD%^(.+)$")
    if goldRest then
        OnGoldRest(goldRest)
        return
    end
    if string.find(payload, "^PELMYTH") then
        pcall(D.ProcessPelMyth, payload)
        return
    end
    if string.find(payload, "^PELAH") or string.find(payload, "^SUMMARY") or string.find(payload, "^PAGE") or string.find(payload, "^BOUGHT") then
        pcall(OnPacket, payload)
    end
end

function InstallPeekHook()
    if S.peekWrapped.ok then return true end
    local names = { "PeloriaOnRawPacket", "PeloriaOnPacket" }
    for i = 1, #names do
        local name = names[i]
        if type(_G[name]) == "function" then
            local orig = _G[name]
            _G[name] = function(a, b, ...)
                local r1, r2, r3, r4, r5 = orig(a, b, ...)
                RouteIncoming(a, b)
                return r1, r2, r3, r4, r5
            end
            S.peekWrapped.ok = true
            return true
        end
    end
    return false
end

function ScanLabel()
    if not D.scanBtn then return end
    local text = "Scan"
    if S.state == "fetch" or S.state == "fill" or S.state == "drill" or S.state == "preview" or S.state == "score" then
        text = "Scanning"
    elseif S.allDeals and #S.allDeals > 0 then
        text = "Re-scan"
    end
    if D.scanBtn.label then
        D.scanBtn.label:SetText(text)
    else
        D.scanBtn:SetText(text)
    end
end

local function StartScan(query)
    if type(PeloriaSend) ~= "function" then
        SetStatus("PeloriaSend missing — open the AH at an auctioneer.")
        return
    end
    EnsureTip()
    S.searchQuery = CleanQuery(query)
    S.filterText = S.searchQuery
    S.searchAllScan = SearchAll()
    S.summaries, S.deals, S.allDeals, S.seenPages = {}, {}, {}, {}
    S.pendingBuys = {}
    if D.massFrame then D.massFrame:Hide() end
    ClearSweep()
    S.drillJobs, S.drillIdx, S.drillInFlight = {}, 1, 0
    S.drillFlight, S.drillByGen = {}, {}
    S.offset, S.primeIdx, S.readIdx = 0, 1, 1
    S.extraWait = false
    S.fetchLeft = 20
    S.previewPumping = false
    S.previewStatusAt = 0
    S.previewRound = 1
    S.previewTries = {}
    S.previewByEntry = {}
    S.previewJobs, S.qIdx, S.inFlight = {}, 1, 0
    S.flight = {}
    if D.prog then D.prog:Hide() end
    S.drillSeen, S.previewSeen = {}, {}
    S.liveDirty, S.liveAt, S.pubIdx, S.pubOut = false, 0, 1, {}
    S.peekWrapped.empty, S.peekWrapped.sent = {}, {}
    S.scoreIdx, S.scoreKeep = nil, nil
    S.gen = NextGen()
    page = 0
    S.state = "fetch"
    S.pendingSearch = false
    ScanLabel()
    Paint()
    InstallHook()
    if S.searchQuery ~= "" then
        SetStatus("Searching '" .. S.searchQuery .. "'...")
    else
        SetStatus(S.searchAllScan and "Scanning all items…" or "Scanning soulbindable items…")
    end
    Search(S.gen, 0, 0)
end
D.StartScan = StartScan


local function KindTitle(kind)
    if kind == "post" then return "Weights  ·  Post" end
    return "Weights  ·  Shop"
end

local function KindHint(kind)
    if kind == "post" then
        return "prices items you post  ·  1.00 = full  ·  0 = ignore"
    end
    return "scores AH listings  ·  1.00 = full  ·  0 = ignore"
end

local function ClampWeight(n)
    n = tonumber(n) or 0
    if n < 0 then n = 0 elseif n > 2 then n = 2 end
    return math.floor(n * 100 + 0.5) / 100
end

local function PaintWeightFrame()
    local pal = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.C and _G.qtEasyAuctionSkin.C()
    if not pal or not D.weightFrame then return end
    D.weightFrame:SetBackdropColor(pal.bg[1], pal.bg[2], pal.bg[3], 0.98)
    D.weightFrame:SetBackdropBorderColor(pal.accent[1], pal.accent[2], pal.accent[3], 1)
    if D.weightTitle then D.weightTitle:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3]) end
    if D.weightHint then D.weightHint:SetTextColor(pal.mute[1], pal.mute[2], pal.mute[3]) end
    if D.weightSellChip and D.weightSellChip.PaintTheme then D.weightSellChip:PaintTheme() end
    if D.weightPostChip and D.weightPostChip.PaintTheme then D.weightPostChip:PaintTheme() end
    if D.weightRows then
        for i = 1, #D.weightRows do
            local row = D.weightRows[i]
            local c = STAT_COLOR[row.key] or pal.cream
            if row.lab then row.lab:SetTextColor(c[1], c[2], c[3]) end
            if row.track then row.track:SetVertexColor(pal.rowB[1], pal.rowB[2], pal.rowB[3], 1) end
            if row.fill then row.fill:SetVertexColor(c[1], c[2], c[3], 1) end
            if row.thumb then row.thumb:SetVertexColor(pal.cream[1], pal.cream[2], pal.cream[3], 1) end
            if row.boxBg then row.boxBg:SetVertexColor(pal.rowA[1], pal.rowA[2], pal.rowA[3], 1) end
            if row.box then row.box:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3]) end
        end
    end
end

local function RaiseWeights(f)
    f = f or D.weightFrame
    if not f then return end
    f:SetParent(UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetFrameLevel(400)
    f:Raise()
    if f.resetBtn then f.resetBtn:SetFrameLevel(f:GetFrameLevel() + 8) end
    if f.closeBtn then f.closeBtn:SetFrameLevel(f:GetFrameLevel() + 8) end
    if D.weightSellChip then D.weightSellChip:SetFrameLevel(f:GetFrameLevel() + 8) end
    if D.weightPostChip then D.weightPostChip:SetFrameLevel(f:GetFrameLevel() + 8) end
    if D.weightRows then
        for i = 1, #D.weightRows do
            local row = D.weightRows[i]
            row:EnableMouse(true)
            row:SetFrameLevel(f:GetFrameLevel() + 2)
            if row.sl then
                row.sl:EnableMouse(true)
                row.sl:SetFrameLevel(row:GetFrameLevel() + 1)
            end
            if row.box then
                row.box:EnableMouse(true)
                row.box:SetFrameLevel(row:GetFrameLevel() + 2)
            end
        end
    end
end

local function ShowWeights(kind)
    kind = (kind == "post") and "post" or "sell"
    S.weightKind = kind
    D.weightKind = kind
    if D.weightFrame and D.weightLayout == C.WEIGHT_LAYOUT then
        if D.weightFrame:IsShown() and D.weightFrame.kind == kind then
            D.weightFrame:Hide()
        else
            D.weightFrame.kind = kind
            if D.RefreshWeights then D.RefreshWeights() end
            PaintWeightFrame()
            RaiseWeights(D.weightFrame)
            D.weightFrame:Show()
        end
        return
    end
    if D.weightFrame then
        D.weightFrame:Hide()
        D.weightFrame = nil
        D.weightSliders, D.weightBoxes, D.weightRows = nil, nil, nil
        D.weightSellChip, D.weightPostChip = nil, nil
    end

    local Skin = _G.qtEasyAuctionSkin
    local f = CreateFrame("Frame", "qtEasyAuctionWeights", UIParent)
    f:SetWidth(328)
    f:SetHeight(88 + #STAT_KEYS * 34 + 44)
    f:SetPoint("CENTER", 0, 24)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f.kind = S.weightKind
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -12)
    title:SetText(KindTitle(S.weightKind))
    D.weightTitle = title

    local function PickKind(nextKind)
        S.weightKind = nextKind
        D.weightKind = nextKind
        f.kind = nextKind
        if D.RefreshWeights then D.RefreshWeights() end
        PaintWeightFrame()
    end
    local sellChip, postChip
    if Skin and Skin.Chip then
        sellChip = Skin.Chip(f, 100, 24, "Shop")
        postChip = Skin.Chip(f, 100, 24, "Post")
        sellChip:SetPoint("TOP", -54, -32)
        postChip:SetPoint("TOP", 54, -32)
        sellChip.OnToggle = function() PickKind("sell") end
        postChip.OnToggle = function() PickKind("post") end
    else
        sellChip = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        sellChip:SetWidth(90)
        sellChip:SetHeight(22)
        sellChip:SetText("Shop")
        sellChip:SetPoint("TOP", -54, -32)
        sellChip:SetScript("OnClick", function() PickKind("sell") end)
        postChip = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        postChip:SetWidth(90)
        postChip:SetHeight(22)
        postChip:SetText("Post")
        postChip:SetPoint("TOP", 54, -32)
        postChip:SetScript("OnClick", function() PickKind("post") end)
        function sellChip:SetOn() end
        function postChip:SetOn() end
    end
    D.weightSellChip, D.weightPostChip = sellChip, postChip

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOP", 0, -58)
    hint:SetText(KindHint(S.weightKind))
    D.weightHint = hint

    D.weightSliders, D.weightBoxes, D.weightRows = {}, {}, {}
    local busy = false
    local function FillBar(row, value)
        local w = row.sl:GetWidth() or 180
        local t = value / 2
        if t < 0 then t = 0 elseif t > 1 then t = 1 end
        row.fill:ClearAllPoints()
        row.fill:SetPoint("LEFT", row.track, "LEFT", 0, 0)
        row.fill:SetWidth(math.max(1, w * t))
        row.fill:SetHeight(4)
    end
    local function Commit(k, value, fromBox)
        value = ClampWeight(value)
        GetWeights(S.weightKind)[k] = value
        local row = D.weightRows[k]
        if not row then return value end
        busy = true
        if not fromBox then
            row.sl:SetValue(value)
        end
        if row.box and not row.box:HasFocus() then
            row.box:SetText(string.format("%.2f", value))
        elseif fromBox and row.box then
            row.box:SetText(string.format("%.2f", value))
        end
        FillBar(row, value)
        busy = false
        return value
    end

    local w = GetWeights(S.weightKind)
    for i = 1, #STAT_KEYS do
        local k = STAT_KEYS[i]
        local y = -48 - i * 34
        local row = CreateFrame("Frame", nil, f)
        row:SetPoint("TOPLEFT", 16, y)
        row:SetPoint("TOPRIGHT", -16, y)
        row:SetHeight(28)
        row.key = k
        local lab = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lab:SetPoint("LEFT", 0, 0)
        lab:SetWidth(36)
        lab:SetJustifyH("LEFT")
        lab:SetText(STAT_LABEL[k])
        row.lab = lab

        local sl = CreateFrame("Slider", nil, row)
        sl:SetPoint("LEFT", 42, 0)
        sl:SetPoint("RIGHT", -52, 0)
        sl:SetHeight(20)
        sl:SetOrientation("HORIZONTAL")
        sl:SetMinMaxValues(0, 2)
        sl:SetValueStep(0.01)
        sl:EnableMouse(true)
        sl:SetHitRectInsets(0, 0, -4, -4)
        local track = sl:CreateTexture(nil, "BACKGROUND")
        track:SetHeight(4)
        track:SetPoint("LEFT", 0, 0)
        track:SetPoint("RIGHT", 0, 0)
        track:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.track = track
        local fill = sl:CreateTexture(nil, "BORDER")
        fill:SetHeight(4)
        fill:SetPoint("LEFT", track, "LEFT", 0, 0)
        fill:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.fill = fill
        local thumb = sl:CreateTexture(nil, "OVERLAY")
        thumb:SetWidth(8)
        thumb:SetHeight(16)
        thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
        sl:SetThumbTexture(thumb)
        row.thumb = thumb
        sl:SetValue(w[k] or 0)
        sl:SetScript("OnValueChanged", function(self)
            if busy then
                FillBar(row, self:GetValue() or 0)
                return
            end
            local value = Commit(k, self:GetValue(), false)
            if row.box then row.box:SetText(string.format("%.2f", value)) end
        end)
        sl:SetScript("OnMouseUp", function()
            RescoreKind(S.weightKind)
        end)
        row.sl = sl

        local box = CreateFrame("EditBox", "qtEasyAuctionWBox" .. k, row)
        box:SetWidth(44)
        box:SetHeight(20)
        box:SetPoint("RIGHT", 0, 0)
        box:SetAutoFocus(false)
        box:SetMaxLetters(5)
        box:SetFontObject(GameFontHighlightSmall)
        box:SetJustifyH("CENTER")
        box:EnableMouse(true)
        box:EnableKeyboard(true)
        box:SetAltArrowKeyMode(false)
        box:SetText(string.format("%.2f", w[k] or 0))
        local boxBg = box:CreateTexture(nil, "BACKGROUND")
        boxBg:SetAllPoints()
        boxBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.boxBg = boxBg
        local function SaveBox(self)
            local value = Commit(k, self:GetText(), true)
            self:SetText(string.format("%.2f", value))
            self:ClearFocus()
            RescoreKind(S.weightKind)
        end
        box:SetScript("OnEnterPressed", SaveBox)
        box:SetScript("OnEditFocusLost", function(self)
            local value = Commit(k, self:GetText(), true)
            self:SetText(string.format("%.2f", value))
            RescoreKind(S.weightKind)
        end)
        box:SetScript("OnEscapePressed", function(self)
            self:SetText(string.format("%.2f", GetWeights(S.weightKind)[k] or 0))
            self:ClearFocus()
        end)
        row.box = box
        D.weightSliders[k] = sl
        D.weightBoxes[k] = box
        D.weightRows[i] = row
        D.weightRows[k] = row
        FillBar(row, w[k] or 0)
    end

    function D.RefreshWeights()
        local nw = GetWeights(S.weightKind)
        busy = true
        for i = 1, #STAT_KEYS do
            local k = STAT_KEYS[i]
            local row = D.weightRows[k]
            if row then
                row.sl:SetValue(nw[k] or 0)
                if not row.box:HasFocus() then
                    row.box:SetText(string.format("%.2f", nw[k] or 0))
                end
                FillBar(row, nw[k] or 0)
            end
        end
        busy = false
        if D.weightTitle then
            D.weightTitle:SetText(KindTitle(S.weightKind))
        end
        if D.weightHint then
            D.weightHint:SetText(KindHint(S.weightKind))
        end
        if D.weightSellChip and D.weightSellChip.SetOn then
            D.weightSellChip:SetOn(S.weightKind == "sell")
        end
        if D.weightPostChip and D.weightPostChip.SetOn then
            D.weightPostChip:SetOn(S.weightKind == "post")
        end
    end

    local reset
    if Skin and Skin.CuteButton then
        reset = Skin.CuteButton(f, 90, 22, "Reset")
    else
        reset = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        reset:SetWidth(90)
        reset:SetHeight(22)
        reset:SetText("Reset")
    end
    reset:SetPoint("BOTTOMLEFT", 16, 12)
    f.resetBtn = reset
    reset:SetScript("OnClick", function()
        CharDB()[WeightStore(S.weightKind)] = DefaultWeights(S.weightKind)
        D.RefreshWeights()
        RescoreKind(S.weightKind)
    end)
    local close
    if Skin and Skin.CuteButton then
        close = Skin.CuteButton(f, 90, 22, "Close")
    else
        close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        close:SetWidth(90)
        close:SetHeight(22)
        close:SetText("Close")
    end
    close:SetPoint("BOTTOMRIGHT", -16, 12)
    f.closeBtn = close
    close:SetScript("OnClick", function()
        RescoreKind(S.weightKind)
        f:Hide()
    end)
    D.weightFrame = f
    D.weightLayout = C.WEIGHT_LAYOUT
    f:SetScript("OnShow", function(self)
        RaiseWeights(self)
        if D.RefreshWeights then D.RefreshWeights() end
        PaintWeightFrame()
        if _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.SetEmpty then
            _G.qtEasyAuctionSkin.SetEmpty(false)
        end
    end)
    f:SetScript("OnHide", function()
        if Paint then Paint() end
    end)
    tinsert(UISpecialFrames, "qtEasyAuctionWeights")
    PaintWeightFrame()
    RaiseWeights(f)
    f:Show()
end
D.ShowWeights = ShowWeights

local function BuyDeal(deal)
    if not deal then return end
    if type(PeloriaSend) ~= "function" then return end
    if S.massQueue or S.massWaiting then
        SetStatus("Wait for the bulk purchase to finish.")
        return
    end
    InstallHook()
    if deal.idRaw and deal.buyoutRaw then
        QueueBuy(deal)
        PeloriaSend(string.format("%s^BUY^%s^%s", C.PREFIX, deal.idRaw, deal.buyoutRaw))
        SetStatus("Buying " .. (deal.name or "") .. " for " .. GoldText(deal.minPrice) .. ".")
        return
    end
    S.buyGen = NextGen()
    S.buyEntry = deal.entry
    SetStatus("Finding cheapest listing…")
    Search(S.buyGen, 0, deal.entry)
end

local function EnsureInfoTip()
    if not S.infoTip then
        S.infoTip = CreateFrame("GameTooltip", "qtEasyAuctionInfoTip", UIParent, "GameTooltipTemplate")
        S.infoTip:SetFrameStrata("TOOLTIP")
    end
    return S.infoTip
end

local function PlaceInfoTip(tip)
    local uiLeft = UIParent:GetLeft() or 0
    local uiRight = UIParent:GetRight() or (uiLeft + (UIParent:GetWidth() or 0))
    local itemLeft, itemRight = GameTooltip:GetLeft() or 0, GameTooltip:GetRight() or 0
    local width = tip:GetWidth() or 0
    tip:ClearAllPoints()
    if itemRight + width + 6 <= uiRight then
        tip:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 6, 0)
    elseif itemLeft - width - 6 >= uiLeft then
        tip:SetPoint("TOPRIGHT", GameTooltip, "TOPLEFT", -6, 0)
    else
        tip:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 0, -6)
    end
end

local function HideTips()
    PeloriaSoulbindHoverLevel = nil
    GameTooltip:Hide()
    if S.infoTip then S.infoTip:Hide() end
end

local function ShowDealTips(row)
    local deal = row.deal
    if not deal then return end
    local level = tonumber(deal.mythic) or 0
    PeloriaSoulbindHoverLevel = (level > 0) and level or nil
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    if PrimeItemCache then PrimeItemCache(deal.entry) end
    GameTooltip:SetHyperlink(ItemLink(deal.entry, deal.affix or 0))
    GameTooltip:Show()
    local tip = EnsureInfoTip()
    tip:ClearLines()
    tip:SetOwner(GameTooltip, "ANCHOR_NONE")
    tip:ClearAllPoints()
    tip:SetPoint("TOPRIGHT", GameTooltip, "TOPLEFT", -6, 0)
    tip:AddLine("Deal math", 0.95, 0.82, 0.55)
    tip:AddDoubleLine("Mythic", MythicTag(deal.mythic, deal.mythicMax), 0.75, 0.75, 0.8, 0.4, 1, 0.4)
    local gold = deal.gold or GoldRaw(deal.minPrice)
    tip:AddDoubleLine("Buyout", Commas(gold) .. "g", 0.75, 0.75, 0.8, 1, 0.85, 0.3)
    local preview = CachedPreview(deal.entry, deal.mythic, deal.affix) or deal.preview
    if preview and #preview > 0 then
        tip:AddLine("Soulbind preview", 0.55, 0.72, 0.95)
        for i = 1, #preview do
            local p = preview[i]
            tip:AddDoubleLine(p.name or "?", "+" .. Compact(p.value or 0), 0.8, 0.8, 0.85, 0.7, 0.9, 0.7)
        end
    end
    local wt = GetWeights("sell")
    local stats = (preview and StatsFromPreview(preview)) or deal.stats or {}
    local score = WeightedScore(stats, "sell")
    local any
    for i = 1, #STAT_KEYS do
        local k = STAT_KEYS[i]
        local v = stats[k]
        if v and v > 0 then
            any = true
            local part = v * (wt[k] or 0)
            tip:AddDoubleLine(
                STAT_LABEL[k],
                Compact(v) .. " × " .. string.format("%.2f", wt[k] or 0) .. " = " .. Compact(part),
                0.8, 0.8, 0.85, 0.7, 0.9, 0.7)
        end
    end
    if any then
        local per = (score > 0 and gold > 0) and (score / gold) or (deal.perGold or 0)
        local perK = (score > 0 and gold > 0) and (score * 1000 / gold) or (deal.perK or 0)
        tip:AddLine("Score " .. Compact(score) .. "  ·  " .. RatioText(per) .. "/g  ·  " .. RatioText(perK) .. "/1kg", 0.95, 0.85, 0.55, true)
    end
    if deal.owner then
        tip:AddDoubleLine("Seller", deal.owner, 0.7, 0.7, 0.75, 1, 0.82, 0.4)
    end
    tip:Show()
    PlaceInfoTip(tip)
end

local function CreateRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r:SetHeight(C.ROW_H)
    r:EnableMouse(true)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    r.sel = r:CreateTexture(nil, "BORDER")
    r.sel:SetAllPoints()
    r.sel:SetTexture("Interface\\Buttons\\WHITE8X8")
    r.sel:Hide()
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetWidth(C.ICON_SZ)
    r.icon:SetHeight(C.ICON_SZ)
    r.icon:SetPoint("LEFT", COL.icon, 0)
    TrimIcon(r.icon)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.name:SetJustifyH("CENTER")
    r.mythic = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.mythic:SetJustifyH("CENTER")
    r.score = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.score:SetJustifyH("CENTER")
    r.statCells = {}
    for s = 1, 3 do
        local lab = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        lab:SetJustifyH("CENTER")
        local val = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        val:SetJustifyH("CENTER")
        r.statCells[s] = { lab = lab, val = val }
    end
    r.price = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.price:SetJustifyH("CENTER")
    r.ratio = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.ratio:SetJustifyH("CENTER")
    r.seller = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.seller:SetJustifyH("CENTER")
    PlaceRow(r)
    local Skin = _G.qtEasyAuctionSkin
    local buy
    if Skin and Skin.CuteButton then
        buy = Skin.CuteButton(r, 44, 18, "Buy")
    else
        buy = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
        buy:SetWidth(44)
        buy:SetHeight(18)
        buy:SetText("Buy")
    end
    buy:SetPoint("RIGHT", -2, 0)
    buy:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    buy:SetScript("OnClick", function(_, btn)
        if btn == "LeftButton" then BuyDeal(r.deal) end
    end)
    local function BeginSweep(deal)
        if not deal then return end
        S.sweep, S.sweepHeld = true, false
        S.sweepSet, S.sweepOrder = {}, {}
        S.sweepAnchor, S.sweepHover = deal, deal
        SweepTo(deal)
        HideTips()
        Paint()
    end
    buy:SetScript("OnEnter", function()
        if S.sweep and r.deal then
            SweepTo(r.deal)
            Paint()
        end
    end)
    buy:SetScript("OnMouseDown", function(_, btn)
        if btn == "RightButton" and IsShiftKeyDown() and not IsAltKeyDown() then BeginSweep(r.deal) end
    end)
    buy:SetScript("OnMouseUp", function(_, btn)
        if btn == "RightButton" then
            if S.sweep then FinishSweep() end
        end
    end)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r:SetScript("OnMouseDown", function(self, btn)
        if btn == "RightButton" and IsShiftKeyDown() and not IsAltKeyDown() then BeginSweep(self.deal) end
    end)
    r:SetScript("OnMouseUp", function(self, btn)
        if btn ~= "RightButton" then return end
        if S.sweep then
            FinishSweep()
            return
        end
        if IsAltKeyDown() then ConfirmHideSeller(self.deal and self.deal.owner) end
    end)
    r:SetScript("OnEnter", function(self)
        if S.sweep then
            if self.deal then
                SweepTo(self.deal)
                Paint()
            end
            return
        end
        ShowDealTips(self)
    end)
    r:SetScript("OnLeave", function()
        if not S.sweep then HideTips() end
    end)
    return r
end

local function CreatePanel()
    local Skin = _G.qtEasyAuctionSkin
    if Skin and Skin.Create then Skin.Create() end
    local page = Skin and Skin.pages and Skin.pages.deals
    if not page then return end
    D.panel = D.panel or _G.qtEasyAuctionDealsPanel
    if D.panel then
        if D.panel:GetParent() ~= page then
            D.panel:SetParent(page)
            D.panel:SetAllPoints(page)
        end
        if D.allChip and D.allChip.SetOn then D.allChip:SetOn(SearchAll()) end
        D.panel:Show()
        return
    end
    local panel = CreateFrame("Frame", "qtEasyAuctionDealsPanel", page)
    panel:SetAllPoints(page)
    panel:EnableMouse(true)
    D.panel = panel
    local top = (panel:GetFrameLevel() or 1) + 24

    local scan
    if Skin and Skin.CuteButton then
        scan = Skin.CuteButton(panel, 118, 32, "Re-scan", "scan")
    else
        scan = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        scan:SetWidth(96)
        scan:SetHeight(32)
        scan:SetText("Re-scan")
    end
    scan:SetPoint("TOPRIGHT", -8, -6)
    scan:SetFrameLevel(top)
    scan:RegisterForClicks("LeftButtonUp")
    scan:SetScript("OnClick", function()
        if D.searchBox then D.searchBox:SetText("") end
        if D.searchHint then D.searchHint:Show() end
        StartScan("")
    end)
    D.scanBtn = scan

    local weights
    if Skin and Skin.CuteButton then
        weights = Skin.CuteButton(panel, 108, 32, "Weights")
    else
        weights = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        weights:SetWidth(90)
        weights:SetHeight(32)
        weights:SetText("Weights")
    end
    weights:SetPoint("RIGHT", scan, "LEFT", -6, 0)
    weights:SetFrameLevel(top)
    weights:EnableMouse(true)
    weights:RegisterForClicks("LeftButtonUp")
    weights:SetScript("OnClick", function()
        local ok, err = pcall(ShowWeights, "sell")
        if not ok then
            print("|cffff5555qtEasyAuction:|r weights: " .. tostring(err))
        end
    end)
    D.filterBtn = weights

    local allChip
    if Skin and Skin.Chip then
        allChip = Skin.Chip(panel, 118, 32, "All items", true)
    else
        allChip = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        allChip:SetWidth(24)
        allChip:SetHeight(24)
        local lab = allChip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lab:SetPoint("LEFT", allChip, "RIGHT", 2, 0)
        lab:SetText("All items")
        function allChip:SetOn(on)
            self:SetChecked(on and true or false)
        end
    end
    allChip:SetPoint("RIGHT", weights, "LEFT", -6, 0)
    allChip:SetFrameLevel(top)
    allChip:SetOn(SearchAll())
    allChip.OnToggle = function(self, on)
        CharDB().searchAll = on and true or false
        self:SetOn(CharDB().searchAll)
        if S.state == "idle" then
            StartScan(CleanQuery(D.searchBox and D.searchBox:GetText() or S.searchQuery or ""))
        end
    end
    if not (Skin and Skin.Chip) then
        allChip:SetScript("OnClick", function(self)
            if self.OnToggle then self:OnToggle(self:GetChecked() and true or false) end
        end)
    end
    D.allChip = allChip

    -- ʕ •ᴥ•ʔ✿ search field is chrome, not a floating blizzard box ✿ ʕ •ᴥ•ʔ
    local search = CreateFrame("Frame", nil, panel)
    search:SetPoint("TOPLEFT", 8, -6)
    search:SetPoint("RIGHT", allChip, "LEFT", -8, 0)
    search:SetHeight(32)
    search:SetFrameLevel(top)
    search:EnableMouse(true)
    local searchBg = search:CreateTexture(nil, "BACKGROUND")
    searchBg:SetAllPoints()
    searchBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    D.searchBg = searchBg
    local searchLine = search:CreateTexture(nil, "ARTWORK")
    searchLine:SetHeight(1)
    searchLine:SetPoint("BOTTOMLEFT", 0, 0)
    searchLine:SetPoint("BOTTOMRIGHT", 0, 0)
    searchLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    D.searchLine = searchLine
    local hint = search:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    hint:SetPoint("LEFT", 10, 0)
    hint:SetJustifyH("LEFT")
    hint:SetText("Search deals")
    D.searchHint = hint
    local box = CreateFrame("EditBox", "qtEasyAuctionDealSearch", search)
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
    D.searchBox = box
    local function BoxQuery()
        return CleanQuery(box:GetText())
    end
    local function PaintHint()
        local empty = BoxQuery() == ""
        if empty and not box:HasFocus() then hint:Show() else hint:Hide() end
    end
    local function RunSearch()
        local q = BoxQuery()
        box:ClearFocus()
        PaintHint()
        if q == "" then
            StartScan("")
            return
        end
        StartScan(q)
    end
    box:SetScript("OnEnterPressed", RunSearch)
    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        PaintHint()
    end)
    box:SetScript("OnEditFocusGained", function() hint:Hide() end)
    box:SetScript("OnEditFocusLost", PaintHint)
    box:SetScript("OnTextChanged", function()
        PaintHint()
        if not S.allDeals or #S.allDeals == 0 then return end
        S.filterText = BoxQuery()
        ApplyFilter()
    end)
    search:SetScript("OnMouseDown", function() box:SetFocus() end)
    D.searchBar = search

    D.count = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    D.count:SetPoint("TOPRIGHT", -28, -44)
    D.status = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    D.status:SetPoint("TOPLEFT", 12, -44)
    D.status:SetPoint("RIGHT", D.count, "LEFT", -12, 0)
    D.status:SetJustifyH("LEFT")
    D.status:SetText("Type to filter, Enter to search the AH. Re-scan refreshes listings.")
    -- ʕ •ᴥ•ʔ✿ preview fetch bar sits in the status gap so the list doesn't jump ✿ ʕ •ᴥ•ʔ
    local prog = CreateFrame("Frame", nil, panel)
    prog:SetPoint("TOPLEFT", 8, -55)
    prog:SetPoint("TOPRIGHT", -24, -55)
    prog:SetHeight(5)
    prog:SetFrameLevel(top)
    prog:Hide()
    local progTrack = prog:CreateTexture(nil, "BACKGROUND")
    progTrack:SetAllPoints()
    progTrack:SetTexture("Interface\\Buttons\\WHITE8X8")
    progTrack:SetVertexColor(0.18, 0.14, 0.20, 0.95)
    local progFill = prog:CreateTexture(nil, "ARTWORK")
    progFill:SetPoint("TOPLEFT", 0, 0)
    progFill:SetPoint("BOTTOMLEFT", 0, 0)
    progFill:SetWidth(1)
    progFill:SetTexture("Interface\\Buttons\\WHITE8X8")
    progFill:SetVertexColor(1.00, 0.84, 0.45, 1)
    D.prog, D.progTrack, D.progFill = prog, progTrack, progFill
    ScanLabel()
    local head = CreateFrame("Frame", nil, panel)
    head:SetPoint("TOPLEFT", 8, -62)
    head:SetPoint("TOPRIGHT", -24, -62)
    head:SetHeight(22)
    local ht = head:CreateTexture(nil, "BACKGROUND")
    ht:SetAllPoints()
    ht:SetTexture("Interface\\Buttons\\WHITE8X8")
    ht:SetVertexColor(0.22, 0.12, 0.28, 1)
    local line = head:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", 0, 0)
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    D.headBg = ht
    D.headLine = line
    D.head = head
    local function HeadBtn(label, key, colKey)
        local b = CreateFrame("Button", nil, head)
        b:SetHeight(22)
        b:RegisterForClicks("LeftButtonUp")
        b:EnableMouse(true)
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetAllPoints()
        fs:SetJustifyH("CENTER")
        fs:SetText(label)
        fs:SetTextColor(0.95, 0.78, 0.92)
        b.fs = fs
        b.sortName = label
        b.key = key
        b.colKey = colKey
        b:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight")
        local hl = b:GetHighlightTexture()
        if hl then hl:SetAlpha(0.25) end
        if key then
            b:SetScript("OnClick", function()
                if S.sortKey == key then
                    S.sortDesc = not S.sortDesc
                else
                    S.sortKey = key
                    S.sortDesc = true
                end
                ApplySort()
                D.RefreshHeads()
                Paint()
            end)
        end
        return b
    end
    D.headBtns = {
        HeadBtn("Item", "name", "name"),
        HeadBtn("M+", "mythic", "mythic"),
        HeadBtn("Score", "score", "score"),
        HeadBtn("Gold value", "perGold", "ratio"),
        HeadBtn("Stats", nil, "stats"),
        HeadBtn("Buyout", "price", "price"),
        HeadBtn("Seller", "seller", "seller"),
    }
    function D.PlaceHeads()
        for i = 1, #(D.headBtns or {}) do
            local b = D.headBtns[i]
            local k = b.colKey
            b:ClearAllPoints()
            b:SetPoint("LEFT", COL[k] or 0, 0)
            b:SetWidth(COL[k .. "W"] or 60)
        end
    end
    function D.RefreshHeads()
        for i = 1, #(D.headBtns or {}) do
            local b = D.headBtns[i]
            local mark = ""
            if b.key and S.sortKey == b.key then mark = S.sortDesc and " ▼" or " ▲" end
            b.fs:SetText(b.sortName .. mark)
            local pal = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.C and _G.qtEasyAuctionSkin.C()
            if b.key and S.sortKey == b.key then
                if pal then b.fs:SetTextColor(pal.gold[1], pal.gold[2], pal.gold[3])
                else b.fs:SetTextColor(1, 0.92, 0.55) end
            else
                if pal then b.fs:SetTextColor(pal.headTxt[1], pal.headTxt[2], pal.headTxt[3])
                else b.fs:SetTextColor(0.95, 0.78, 0.92) end
            end
        end
        D.PlaceHeads()
    end
    D.RefreshHeads()
    local list = CreateFrame("Frame", nil, panel)
    list:SetPoint("TOPLEFT", 8, -86)
    list:SetPoint("BOTTOMRIGHT", -24, 8)
    D.list = list
    local bar = CreateFrame("Slider", "qtEasyAuctionDealsBar", panel, "UIPanelScrollBarTemplate")
    bar:SetPoint("TOPRIGHT", -4, -86)
    bar:SetPoint("BOTTOMRIGHT", -4, 8)
    bar:SetValueStep(1)
    bar:SetScript("OnValueChanged", function(self, value)
        if D.painting then return end
        S.offset = math.floor((value or 0) + 0.5)
        Paint()
    end)
    D.bar = bar
    D.rows = {}
    for i = 1, C.ROW_MAX do
        D.rows[i] = CreateRow(list)
    end
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta)
        S.offset = (S.offset or 0) - delta * 3
        Paint()
    end)
    panel:SetScript("OnShow", function() Paint() end)
    panel:SetScript("OnHide", function()
        if D.massFrame then D.massFrame:Hide() end
        ClearSweep()
    end)
    panel:SetScript("OnUpdate", function(_, delta)
        if S.massQueue and not S.massWaiting then PumpMassBuy() end
        if S.state == "idle" and S.rescoreAt and GetTime() >= S.rescoreAt then
            S.rescoreAt = nil
            if S.summaries and #S.summaries > 0 then
                S.state = "score"
                S.scoreIdx, S.scoreKeep = 1, true
            end
        end
        if S.state == "idle" and not S.sweep and not S.massQueue then return end
        if S.sweep then
            if IsMouseButtonDown("RightButton") then
                S.sweepHeld = true
                for i = 1, #(D.rows or {}) do
                    local row = D.rows[i]
                    if row:IsShown() and MouseIsOver(row) and row.deal then
                        if row.deal ~= S.sweepHover then
                            S.sweepHover = row.deal
                            SweepTo(row.deal)
                            Paint()
                        end
                        break
                    end
                end
            elseif S.sweepHeld then
                FinishSweep()
            end
            if S.sweep then PaintSweepGold() end
        end
        if S.state == "fetch" then
            InstallHook()
            S.fetchLeft = (S.fetchLeft or 0) - delta
            if S.fetchLeft <= 0 then
                if S.summaries and #S.summaries > 0 then
                    S.state = "fill"
                    EnqueueNewWork()
                    S.liveDirty = true
                else
                    S.state = "idle"
                    ScanLabel()
                    SetStatus("No AH reply. Open the house, then Re-scan.")
                end
            end
        end
        if S.state == "fetch" or S.state == "fill" then
            PumpDrill()
            PumpPreview()
            PumpPublish()
            MaybeFinishScan()
        elseif S.state == "score" then
            PumpScore()
        end
    end)
    panel:Show()
end

function D.ApplySkin()
    local pal = _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.C and _G.qtEasyAuctionSkin.C()
    if not pal then return end
    if D.headBg then D.headBg:SetVertexColor(pal.head[1], pal.head[2], pal.head[3], pal.head[4] or 1) end
    if D.headLine then D.headLine:SetVertexColor(pal.accent[1], pal.accent[2], pal.accent[3], 0.9) end
    if D.status then D.status:SetTextColor(pal.mute[1], pal.mute[2], pal.mute[3]) end
    if D.count then D.count:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3]) end
    if D.progTrack then D.progTrack:SetVertexColor(pal.rowB[1], pal.rowB[2], pal.rowB[3], 1) end
    if D.progFill then D.progFill:SetVertexColor(pal.gold[1], pal.gold[2], pal.gold[3], 1) end
    if D.searchBg then D.searchBg:SetVertexColor(pal.rowB[1], pal.rowB[2], pal.rowB[3], 1) end
    if D.searchLine then D.searchLine:SetVertexColor(pal.accent[1], pal.accent[2], pal.accent[3], 0.85) end
    if D.searchHint then D.searchHint:SetTextColor(pal.mute[1], pal.mute[2], pal.mute[3]) end
    if D.searchBox then D.searchBox:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3]) end
    if D.RefreshHeads then D.RefreshHeads() end
    PaintWeightFrame()
    PaintMassConfirm()
    Paint()
end

function D.RefreshSellerFilter()
    ApplyFilter()
end

function D.OnShown()
    local ok, err = pcall(CreatePanel)
    if not ok then
        print("|cffff5555qtEasyAuction:|r deals ui: " .. tostring(err))
        D.panel = nil
    end
    if D.panel then D.panel:Show() end
    D.ApplySkin()
    InstallHook()
    if type(PeloriaSend) == "function" then pcall(PeloriaSend, "GOLDC^SYNC") end
    if type(rawget(_G, "PeloriaRegisterGoldCallback")) == "function" and not S.peekWrapped.goldCb then
        S.peekWrapped.goldCb = true
        pcall(_G.PeloriaRegisterGoldCallback, PaintMassGoldWarn)
    end
    if S.state == "idle" and (not S.deals or #S.deals == 0) then StartScan() end
end

function D.Toggle()
    if _G.qtEasyAuctionSkin and _G.qtEasyAuctionSkin.host then
        _G.qtEasyAuctionSkin.host:Show()
    end
    D.OnShown()
end

function D.Show()
    D.OnShown()
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("AUCTION_HOUSE_SHOW")
boot:SetScript("OnEvent", function()
    if _G.qtEasyAuctionSkin then _G.qtEasyAuctionSkin.Create() end
    CreatePanel()
    InstallHook()
end)
