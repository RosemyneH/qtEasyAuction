local D = {}
_G.qtEasyAuctionDeals = D

local PREFIX = "PELAH"
local SORT_BUYOUT = 3
local GEN = 810000
local PAGE_CAP = 20
local BATCH = 16

local ROW_MAX = 32
local ROW_H = 34
local ICON_SZ = 26
local BUY_W = 50
local TRIM_A, TRIM_B = 0.03, 0.97
local COL = {}

local function TrimIcon(tex)
    if tex then tex:SetTexCoord(TRIM_A, TRIM_B, TRIM_A, TRIM_B) end
end

local function LayoutCols(width)
    width = tonumber(width) or 720
    if width < 400 then width = 400 end
    local inner = width - ICON_SZ - 12 - BUY_W - 6
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
    local x = ICON_SZ + 10
    COL.icon = 4
    for i = 1, #spec do
        local w = inner * spec[i][2] / sum
        COL[spec[i][1]] = x
        COL[spec[i][1] .. "W"] = w
        x = x + w
    end
end
LayoutCols(720)

local STAT_KEYS = { "str", "agi", "sta", "int", "spi", "ap", "sp", "arm" }
local STAT_LABEL = {
    str = "Str", agi = "Agi", sta = "Stam", int = "Int",
    spi = "Spi", ap = "AP", sp = "SP", arm = "Arm",
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
}

local CLASS_WEIGHTS = {
    WARRIOR     = { str = 1.00, sta = 0.50, ap = 0.45, agi = 0.25, int = 0, spi = 0, sp = 0, arm = 0 },
    PALADIN     = { str = 0.70, sta = 0.55, ap = 0.30, agi = 0.20, int = 0.55, spi = 0.25, sp = 0.55, arm = 0 },
    HUNTER      = { str = 0.20, sta = 0.35, ap = 0.70, agi = 1.00, int = 0.15, spi = 0, sp = 0, arm = 0 },
    ROGUE       = { str = 0.35, sta = 0.30, ap = 0.55, agi = 1.00, int = 0, spi = 0, sp = 0, arm = 0 },
    PRIEST      = { str = 0,    sta = 0.35, ap = 0,    agi = 0,    int = 1.00, spi = 0.75, sp = 1.00, arm = 0 },
    SHAMAN      = { str = 0.40, sta = 0.35, ap = 0.40, agi = 0.50, int = 0.70, spi = 0.25, sp = 0.70, arm = 0 },
    MAGE        = { str = 0,    sta = 0.30, ap = 0,    agi = 0,    int = 1.00, spi = 0.20, sp = 1.00, arm = 0 },
    WARLOCK     = { str = 0,    sta = 0.40, ap = 0,    agi = 0,    int = 1.00, spi = 0.20, sp = 1.00, arm = 0 },
    DRUID       = { str = 0.35, sta = 0.40, ap = 0.40, agi = 0.60, int = 0.70, spi = 0.45, sp = 0.60, arm = 0 },
    DEATHKNIGHT = { str = 1.00, sta = 0.55, ap = 0.40, agi = 0.15, int = 0, spi = 0, sp = 0, arm = 0 },
}

local BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local scanTip
local hookFn, attnFn
local state = "idle"
local gen, page, filterIdx
local summaries, deals, allDeals, offset
local primeIdx, readIdx, waitLeft, fetchLeft
local buyGen, buyEntry
local pendingBuys = {}
local sweep, sweepSet, sweepOrder, sweepAnchor, sweepHeld, sweepHover
local massList, massLeft, massTotal, massOk
local seenPages
local extraWait, resent
local sortKey, sortDesc = "perGold", true
local infoTip
local status = ""
local pendingSearch
local searchQuery, filterText = "", ""
local PREVIEW_MAX = 400
local previewCache, previewJobs, previewAsked = {}, {}, {}
local qIdx, inFlight = 1, 0
local flight = {}
local FLY_MAX = 3
local PumpPreview, ClearFlight, FinishPreviewPass, InstallHook, InstallPeekHook
local PumpDrill, BeginDrillPass, BeginTooltipPass, SetStatus
local Paint, ApplyFilter, ScanLabel
local drillJobs, drillIdx, drillInFlight = {}, 1, 0
local drillFlight, drillByGen = {}, {}
local DRILL_FLY = 6
local attnOrig
local peekWrapped = {}

local function NextGen()
    GEN = GEN + 1
    return GEN
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
    if not text then return 0 end
    text = string.lower(string.gsub(text, ",", ""))
    local n, suf = string.match(text, "^([%d%.]+)([km]?)$")
    n = tonumber(n)
    if not n then return 0 end
    if suf == "k" then n = n * 1000
    elseif suf == "m" then n = n * 1000000
    end
    return n
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
    if not scanTip then
        scanTip = CreateFrame("GameTooltip", "qtEasyAuctionScanTip", UIParent, "GameTooltipTemplate")
        scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    end
    if PeloriaRegisterItemTooltip and not scanTip.__PeloriaItemTooltipRegistered then
        PeloriaRegisterItemTooltip(scanTip)
    end
    return scanTip
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
    ["spell power"] = "sp", ["spell damage"] = "sp", sp = "sp", spellpower = "sp",
    armor = "arm", arm = "arm", armour = "arm",
}

local function ClassToken()
    local _, token = UnitClass("player")
    return token or "WARRIOR"
end

local function CopyWeights(src)
    local w = {}
    for i = 1, #STAT_KEYS do
        local k = STAT_KEYS[i]
        w[k] = tonumber(src and src[k]) or 0
    end
    return w
end

local function DefaultWeights()
    return CopyWeights(CLASS_WEIGHTS[ClassToken()] or CLASS_WEIGHTS.WARRIOR)
end

local function CharDB()
    local Skin = _G.qtEasyAuctionSkin
    if Skin and Skin.Char then return Skin.Char() end
    qtEasyAuctionCharDB = qtEasyAuctionCharDB or {}
    qtEasyAuctionCharDB.weights = qtEasyAuctionCharDB.weights or {}
    qtEasyAuctionCharDB.itemPrices = qtEasyAuctionCharDB.itemPrices or {}
    return qtEasyAuctionCharDB
end

local function GetWeights()
    local C = CharDB()
    C.weights = C.weights or {}
    local token = ClassToken()
    if not C.weights[token] then
        C.weights[token] = DefaultWeights()
    end
    local w = C.weights[token]
    local d = DefaultWeights()
    for i = 1, #STAT_KEYS do
        local k = STAT_KEYS[i]
        if w[k] == nil then w[k] = d[k] or 0 end
    end
    return w
end

local function CanonicalStat(stat)
    if not stat then return nil end
    local low = string.lower(stat)
    low = string.gsub(low, "%s+$", "")
    low = string.gsub(low, "^%s+", "")
    low = string.gsub(low, " rating$", "")
    if string.find(low, "mythic", 1, true) then return nil end
    if string.find(low, "armor penetration", 1, true) or string.find(low, "armour penetration", 1, true) then
        return nil
    end
    if ALIAS[low] then return ALIAS[low] end
    for key, canon in pairs(ALIAS) do
        if string.find(low, key, 1, true) then return canon end
    end
    return nil
end

local function PreviewKey(entry, level, affix)
    return tostring(entry) .. ":" .. tostring(level or 0) .. ":" .. tostring(affix or 0)
end

local function StatsFromPreview(preview)
    local stats = {}
    if type(preview) ~= "table" then return stats end
    for i = 1, #preview do
        local row = preview[i]
        local key = CanonicalStat(row.name)
        local v = tonumber(row.value)
        if key and v and v > 0 then
            stats[key] = (stats[key] or 0) + v
        end
    end
    return stats
end

function ClearFlight(entry, key)
    local drop = {}
    for k in pairs(flight) do
        if k == key or (entry and string.sub(k, 1, string.len(tostring(entry)) + 1) == tostring(entry) .. ":") then
            drop[#drop + 1] = k
        end
    end
    for i = 1, #drop do
        if flight[drop[i]] then
            flight[drop[i]] = nil
            inFlight = math.max(0, inFlight - 1)
        end
    end
end

local function ParsePreviewBody(message)
    if type(message) ~= "string" then return end
    message = string.gsub(message, "^PELATTN%^", "")
    if string.sub(message, 1, 2) ~= "P^" then return end
    local itemEntryText, levelText, affixText, records =
        string.match(message, "^P%^([^%^]+)%^([^%^]+)%^([^%^]+)%^(.*)$")
    local itemEntry, level, affix = tonumber(itemEntryText), tonumber(levelText), tonumber(affixText)
    if not itemEntry or itemEntry <= 0 or level == nil or level < 0 or affix == nil then return end
    local key = PreviewKey(itemEntry, level, affix)
    local preview = {}
    for record in string.gmatch(records or "", "([^~]+)") do
        local label, valueText = string.match(record, "^([^%^]+)%^([^%^]+)$")
        local value = ParseStatAmount(valueText)
        if (not value or value == 0) then value = tonumber(valueText) end
        if label and label ~= "" and value and value > 0 then
            preview[#preview + 1] = { name = label, value = value }
        end
    end
    previewCache[key] = preview
    ClearFlight(itemEntry, key)
    if PumpPreview then PumpPreview() end
    local post = _G.qtEasyAuctionPost
    if post and post.OnPreview then post.OnPreview() end
end

local function SendPreview(entry, level, affix)
    entry = tonumber(entry)
    level = tonumber(level) or 0
    affix = tonumber(affix) or 0
    if not entry or type(PeloriaSend) ~= "function" then return end
    PeloriaSend("ATTN^PREVIEW^" .. entry .. "^" .. level .. "^" .. affix)
end

local function CachedPreview(entry, level, affix)
    local key = PreviewKey(entry, level or 0, affix or 0)
    if previewCache[key] then return previewCache[key] end
    if PeloriaSoulbindPreviews and PeloriaSoulbindPreviews[key] then
        previewCache[key] = PeloriaSoulbindPreviews[key]
        return previewCache[key]
    end
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
            elseif string.find(low, "if soulbound", 1, true) or string.find(low, "soulbound stats", 1, true) then
                inSoul = true
            else
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
                    if key and v > 0 and v < 500000 then
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
        q = CleanQuery(searchQuery)
    end
    PeloriaSend(string.format("%s^SEARCH^%d^%d^%d^%d^%d^%d^%d^%d^%d^%d^%d^%d^%d^%s",
        PREFIX, g, pg, -1, -1, 0, 0, 0, 0, -1, SORT_BUYOUT, 0, 1, drill or 0, q))
end

local function ApplyListing(entry, row)
    if not entry or not row then return end
    for i = 1, #(summaries or {}) do
        local s = summaries[i]
        if s.entry == entry then
            s.owner = row.owner
            if row.mythic and row.mythic > 0 then
                s.minMythic = row.mythic
                s.maxMythic = row.mythic
            end
            s.affix = row.randProp or s.affix or 0
            s.idRaw = row.idRaw
            s.buyoutRaw = row.buyoutRaw
            if row.buyout and row.buyout > 0 then s.minPrice = row.buyout end
        end
    end
end

local function PickListing(rows, entry)
    local me = UnitName("player")
    local best
    for i = 1, #(rows or {}) do
        local e = rows[i]
        if e.entry == entry then
            if e.owner ~= me then
                if not best or (e.buyout or 0) < (best.buyout or 0) then best = e end
            elseif not best then
                best = e
            end
        end
    end
    return best or (rows and rows[1])
end

function PumpDrill()
    if state ~= "drill" then return end
    local now = GetTime()
    local expired = {}
    for g, t in pairs(drillFlight) do
        if now > t then expired[#expired + 1] = g end
    end
    for i = 1, #expired do
        local g = expired[i]
        if drillFlight[g] then
            drillFlight[g] = nil
            drillByGen[g] = nil
            drillInFlight = math.max(0, drillInFlight - 1)
        end
    end
    while drillInFlight < DRILL_FLY and drillIdx <= #(drillJobs or {}) do
        local j = drillJobs[drillIdx]
        drillIdx = drillIdx + 1
        local g = NextGen()
        drillByGen[g] = j.entry
        drillFlight[g] = now + 2.5
        drillInFlight = drillInFlight + 1
        Search(g, 0, j.entry)
    end
    local have = 0
    for i = 1, #(summaries or {}) do
        if summaries[i].owner and summaries[i].owner ~= "" then have = have + 1 end
    end
    SetStatus(string.format("Fetching sellers & mythic… %d/%d", have, summaries and #summaries or 0))
    if drillJobs and drillIdx > #drillJobs and drillInFlight == 0 then
        BeginTooltipPass()
    end
end

function BeginDrillPass()
    if not summaries or #summaries == 0 then
        state = "idle"
        SetStatus("No soulbindable listings.")
        return
    end
    local jobs, seen = {}, {}
    for i = 1, #summaries do
        local e = summaries[i].entry
        if e and not seen[e] then
            seen[e] = true
            jobs[#jobs + 1] = { entry = e }
        end
    end
    drillJobs, drillIdx, drillInFlight = jobs, 1, 0
    drillFlight, drillByGen = {}, {}
    state = "drill"
    PumpDrill()
end

local function WeightedScore(stats)
    local w = GetWeights()
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
    level, affix = tonumber(level) or 0, tonumber(affix) or 0
    if not entry then return 0, false end
    if InstallHook then InstallHook() end
    local key = PreviewKey(entry, level, affix)
    local preview = previewCache[key]
    if not preview and PeloriaSoulbindPreviews and PeloriaSoulbindPreviews[key] then
        preview = PeloriaSoulbindPreviews[key]
        previewCache[key] = preview
    end
    if not preview then
        if not previewAsked[key] then
            previewAsked[key] = true
            SendPreview(entry, level, affix)
        end
        return 0, false
    end
    return WeightedScore(StatsFromPreview(preview)), true
end

local function TopStats(stats)
    local w = GetWeights()
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
    if not deals then return end
    local key, desc = sortKey or "perGold", sortDesc ~= false
    table.sort(deals, function(a, b)
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
    if not q or q == "" then return true end
    local name = string.lower(deal.name or "")
    local seller = string.lower(deal.owner or "")
    return string.find(name, q, 1, true) or string.find(seller, q, 1, true)
end

function ApplyFilter()
    local q = string.lower(CleanQuery(filterText))
    deals = {}
    for i = 1, #(allDeals or {}) do
        if DealMatches(allDeals[i], q) then
            deals[#deals + 1] = allDeals[i]
        end
    end
    ApplySort()
    offset = 0
    Paint()
end

local function FormatStatLine(stats, score, bestKey)
    local bits = TopStats(stats)
    if not score or score <= 0 then return "|cff666666—|r" end
    return "|cffe8d5a3" .. Compact(score) .. "|r"
end

function SetStatus(text)
    status = text or ""
    if D.status then D.status:SetText(status) end
end

local function DealKey(deal)
    if not deal then return "" end
    if deal.idRaw then return "id:" .. tostring(deal.idRaw) end
    return "e:" .. tostring(deal.entry or 0)
end

local function PlaceRow(r)
    r.icon:ClearAllPoints()
    r.icon:SetWidth(ICON_SZ)
    r.icon:SetHeight(ICON_SZ)
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
        return math.max(8, math.min(ROW_MAX, math.floor(D.list:GetHeight() / ROW_H)))
    end
    return 18
end

function Paint()
    if not D.rows then return end
    local n = deals and #deals or 0
    local vis = VisCount()
    D.vis = vis
    offset = math.max(0, math.min(offset or 0, math.max(0, n - vis)))
    if D.painting then return end
    D.painting = true
    if D.list and D.list:GetWidth() and D.list:GetWidth() > 50 then
        LayoutCols(D.list:GetWidth())
    end
    if D.PlaceHeads then D.PlaceHeads() end
    if D.bar then
        local maxOff = math.max(0, n - vis)
        D.bar:SetMinMaxValues(0, maxOff)
        D.bar:SetValue(offset)
        if maxOff > 0 then D.bar:Show() else D.bar:Hide() end
    end
    for i = 1, ROW_MAX do
        local r = D.rows[i]
        if i > vis then
            r:Hide()
        else
            local e = deals and deals[offset + i]
            if not e then
                r:Hide()
            else
                r.deal = e
                r:SetHeight(ROW_H)
                r:ClearAllPoints()
                r:SetPoint("TOPLEFT", D.list, "TOPLEFT", 0, -((i - 1) * ROW_H))
                r:SetPoint("TOPRIGHT", D.list, "TOPRIGHT", 0, -((i - 1) * ROW_H))
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
                    if sweepSet and sweepSet[DealKey(e)] then
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
        local n = deals and #deals or 0
        local total = allDeals and #allDeals or n
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
    drop(deals)
    drop(allDeals)
    drop(summaries)
    Paint()
end

-- ʕ •ᴥ•ʔ✿ same BOUGHT codes the AH prints to chat ✿ ʕ •ᴥ•ʔ
local function OnBought(code, detail)
    local pending = table.remove(pendingBuys, 1)
    code = tostring(code or "")
    detail = detail or ""
    if code == "OK" or code == "NOSUCH" then
        if pending then HideBought(pending.idRaw, pending.entry) end
    end
    if massLeft and massLeft > 0 then
        massLeft = massLeft - 1
        if code == "OK" then massOk = (massOk or 0) + 1 end
        if massLeft <= 0 then
            local bought, total = massOk or 0, massTotal or 0
            massLeft, massTotal, massOk = nil, nil, nil
            SetStatus(string.format("Mass buy done — %d of %d bought. Mail is on the way.", bought, total))
        else
            SetStatus(string.format("Buying… %d of %d in.", massOk or 0, massTotal or 0))
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
    pendingBuys[#pendingBuys + 1] = {
        idRaw = row.idRaw,
        entry = row.entry,
        name = row.name,
    }
end

local function ClearSweep()
    sweep, sweepHeld, sweepHover, sweepSet, sweepOrder, sweepAnchor = false, false, nil, nil, nil, nil
    massList = nil
    if D.rows then Paint() end
end

local function IndexOfDeal(deal)
    if not deal or not deals then return end
    for i = 1, #deals do
        if deals[i] == deal then return i end
    end
    if deal.idRaw then
        for i = 1, #deals do
            if deals[i].idRaw == deal.idRaw then return i end
        end
    elseif deal.entry then
        for i = 1, #deals do
            if deals[i].entry == deal.entry then return i end
        end
    end
end

local function SweepAdd(deal)
    if not deal then return end
    local key = DealKey(deal)
    if sweepSet[key] then return end
    sweepSet[key] = deal
    sweepOrder[#sweepOrder + 1] = deal
end

-- ʕ ● ᴥ ●ʔ✿ shift-right drag paints a contiguous buy range ✿ ʕ ● ᴥ ●ʔ
local function SweepTo(deal)
    if not deal then return end
    if not sweepAnchor then sweepAnchor = deal end
    local a, b = IndexOfDeal(sweepAnchor), IndexOfDeal(deal)
    if not a or not b then
        SweepAdd(deal)
        return
    end
    if a > b then a, b = b, a end
    sweepSet, sweepOrder = {}, {}
    for i = a, b do SweepAdd(deals[i]) end
end

local function MassStats(list)
    local stats, copper, score = {}, 0, 0
    for i = 1, #(list or {}) do
        local d = list[i]
        copper = copper + (tonumber(d.minPrice) or 0)
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
    return true
end

local function BuyPicked(list)
    if type(PeloriaSend) ~= "function" then
        SetStatus("PeloriaSend missing — stand at an auctioneer.")
        return
    end
    InstallHook()
    local sent = 0
    for i = 1, #(list or {}) do
        local deal = list[i]
        if CanMassBuy(deal) then
            QueueBuy(deal)
            PeloriaSend(string.format("%s^BUY^%s^%s", PREFIX, deal.idRaw, deal.buyoutRaw))
            sent = sent + 1
        end
    end
    if sent == 0 then
        SetStatus("Nothing in that sweep can be bought yet.")
        return
    end
    massTotal, massOk, massLeft = sent, 0, sent
    SetStatus(string.format("Buying %d listing%s…", sent, sent == 1 and "" or "s"))
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
    f:SetHeight(220)
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
    local score = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    score:SetPoint("TOP", cost, "BOTTOM", 0, -6)
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
        local list = massList
        f:Hide()
        ClearSweep()
        BuyPicked(list)
    end)
    cancel:SetScript("OnClick", function()
        f:Hide()
        ClearSweep()
    end)
    f:SetScript("OnHide", function()
        if massList then ClearSweep() end
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
    massList = buyable
    local stats, copper, score = MassStats(buyable)
    local f = EnsureMassConfirm()
    local n = #buyable
    D.massTitle:SetText(n == 1 and "Buy this listing?" or ("Buy " .. n .. " listings?"))
    D.massCost:SetText("Cost  " .. Commas(GoldRaw(copper)) .. "g   ·   " .. GoldText(copper))
    D.massScore:SetText("Score gain  +" .. Compact(score))
    D.massStats:SetText(MassStatText(stats))
    local have = GetMoney() or 0
    if have < copper then
        D.massWarn:SetText("You have " .. GoldText(have) .. "  ·  short " .. GoldText(copper - have))
        D.massWarn:Show()
    else
        D.massWarn:SetText("")
        D.massWarn:Hide()
    end
    PaintMassConfirm()
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
    if not sweep then return end
    sweep, sweepHeld = false, false
    local list = sweepOrder
    if list and #list > 0 then
        ShowMassConfirm(list)
    else
        ClearSweep()
    end
end

local function FinishRead()
    local out = {}
    for i = 1, #(summaries or {}) do
        local s = summaries[i]
        local info = s.info or {}
        if not info.blocked then
            local score, bestKey = WeightedScore(info.stats)
            local gold = GoldRaw(s.minPrice)
            if gold < 1 then gold = 1 end
            local per = (score > 0) and (score / gold) or 0
            local perK = (score > 0) and (score * 1000 / gold) or 0
            out[#out + 1] = {
                entry = s.entry,
                name = s.name,
                quality = s.quality,
                minPrice = s.minPrice,
                mythic = s.minMythic or 0,
                mythicMax = s.maxMythic or s.minMythic or 0,
                affix = s.affix or 0,
                owner = s.owner,
                perGold = per,
                perK = perK,
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
    end
    allDeals, deals = out, out
    ApplySort()
    local got = 0
    for i = 1, #out do
        if out[i].preview then got = got + 1 end
    end
    offset = 0
    state = "idle"
    if #out == 0 then
        SetStatus("No soulbindable listings.")
    else
        local q = CleanQuery(searchQuery)
        if q ~= "" then
            SetStatus(string.format("Search '%s' — %d items, %d with preview.", q, #out, got))
        else
            SetStatus(string.format("Weighted score / gold — %d items, %d with preview. Click Weights to tune.", #out, got))
        end
    end
    filterText = CleanQuery(D.searchBox and D.searchBox:GetText() or "")
    ScanLabel()
    if filterText ~= "" and filterText ~= CleanQuery(searchQuery) then
        ApplyFilter()
    else
        Paint()
    end
end

local function StripPrefix(body)
    body = body or ""
    body = string.gsub(body, "^PELAH%^", "")
    return body
end

local function UsePreviewPackets()
    return type(PeloriaSend) == "function"
end

local function FillInfoFromPackets(s)
    local level = s.minMythic or 0
    if level == 0 then level = s.maxMythic or 0 end
    local affix = s.affix or 0
    local elig = PeloriaSoulbindEligibility and PeloriaSoulbindEligibility[s.entry]
    local preview = CachedPreview(s.entry, level, affix)
    s.info = {
        blocked = elig == 1,
        preview = preview,
        stats = StatsFromPreview(preview),
        waiting = preview == nil,
    }
end

local function BuildPreviewJobs()
    local jobs, seen = {}, {}
    for i = 1, #(summaries or {}) do
        local s = summaries[i]
        local level = s.minMythic or 0
        if level == 0 then level = s.maxMythic or 0 end
        local affix = s.affix or 0
        local key = PreviewKey(s.entry, level, affix)
        if not seen[key] then
            seen[key] = true
            jobs[#jobs + 1] = { entry = s.entry, level = level, affix = affix, key = key }
        end
    end
    return jobs
end

local function PendingPreviews()
    local n = 0
    for i = 1, #(previewJobs or {}) do
        local j = previewJobs[i]
        if not previewCache[j.key] then n = n + 1 end
    end
    return n
end

function FinishPreviewPass()
    if state ~= "preview" then return end
    for i = 1, #(summaries or {}) do
        FillInfoFromPackets(summaries[i])
    end
    FinishRead()
end

function PumpPreview()
    if state ~= "preview" then return end
    local now = GetTime()
    local expired = {}
    for k, t in pairs(flight) do
        if now > t then expired[#expired + 1] = k end
    end
    for i = 1, #expired do
        if flight[expired[i]] then
            flight[expired[i]] = nil
            inFlight = math.max(0, inFlight - 1)
        end
    end
    while inFlight < FLY_MAX and qIdx <= #(previewJobs or {}) do
        local j = previewJobs[qIdx]
        qIdx = qIdx + 1
        if previewCache[j.key] then
        else
            inFlight = inFlight + 1
            flight[j.key] = now + 1.75
            SendPreview(j.entry, j.level, j.affix)
        end
    end
    local done = #(previewJobs or {}) - PendingPreviews()
    SetStatus(string.format("Soulbind previews %d/%d  in-flight %d", done, previewJobs and #previewJobs or 0, inFlight))
    if previewJobs and qIdx > #previewJobs and inFlight == 0 then
        FinishPreviewPass()
    end
end

function BeginTooltipPass()
    if #summaries == 0 then
        state = "idle"
        SetStatus("No soulbindable listings.")
        return
    end
    extraWait = false
    resent = false
    previewJobs = BuildPreviewJobs()
    qIdx, inFlight = 1, 0
    flight = {}
    state = "preview"
    SetStatus("Soulbind previews 0/" .. #previewJobs)
    PumpPreview()
end

local function OnPacket(body)
    body = StripPrefix(body)
    if body == "NOFILTER" then
        if state == "fetch" then SetStatus("Soulbind filter still loading — try Scan again.") end
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

    if buyGen and isPage and g == buyGen then
        local first = string.find(body, "~", 1, true)
        local rows = ParseListings(first and string.sub(body, first + 1) or "")
        local me = UnitName("player")
        local best
        for i = 1, #rows do
            local e = rows[i]
            if e.entry == buyEntry and e.owner ~= me then
                if not best or e.buyout < best.buyout then best = e end
            end
        end
        buyGen, buyEntry = nil, nil
        if not best then
            SetStatus("No listing left to buy.")
            return
        end
        if GetMoney() < best.buyout then
            SetStatus("Not enough gold.")
            return
        end
        QueueBuy(best)
        PeloriaSend(string.format("%s^BUY^%s^%s", PREFIX, best.idRaw, best.buyoutRaw))
        SetStatus("Buying " .. (best.name or "") .. " for " .. GoldText(best.buyout) .. ".")
        return
    end

    if isPage and drillByGen and drillByGen[g] then
        local entry = drillByGen[g]
        drillByGen[g] = nil
        if drillFlight[g] then
            drillFlight[g] = nil
            drillInFlight = math.max(0, drillInFlight - 1)
        end
        local first = string.find(body, "~", 1, true)
        local rows = ParseListings(first and string.sub(body, first + 1) or "")
        ApplyListing(entry, PickListing(rows, entry))
        PumpDrill()
        return
    end

    if state ~= "fetch" or g ~= gen then return end
    seenPages = seenPages or {}
    local key = kind .. ":" .. pg
    if seenPages[key] then return end
    seenPages[key] = true

    local first = string.find(body, "~", 1, true)
    local tail = first and string.sub(body, first + 1) or ""
    if isSummary then
        local rows = ParseSummaryRows(tail)
        for i = 1, #rows do summaries[#summaries + 1] = rows[i] end
    else
        local rows = ParseListings(tail)
        for i = 1, #rows do
            local e = rows[i]
            summaries[#summaries + 1] = {
                entry = e.entry,
                count = 1,
                minPrice = e.buyout,
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

    if pg + 1 < (pages or 1) and pg + 1 < PAGE_CAP then
        page = pg + 1
        SetStatus(string.format("Scanning soulbindable items… page %d/%d", page + 1, math.min(pages, PAGE_CAP)))
        Search(gen, page, 0)
    else
        BeginDrillPass()
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
    local u = HandlersFromUpvalue()
    if type(u) == "table" then return u end
    if PeloriaItemHelper and PeloriaItemHelper.GetPacketHandlers then
        local h = PeloriaItemHelper.GetPacketHandlers()
        if type(h) == "table" then return h end
    end
    local g = rawget(_G, "PeloriaPacketHandlers")
    if type(g) == "table" then return g end
end

function InstallHook()
    local peek = InstallPeekHook()
    if peekWrapped.attnDone then return peek or true end
    local handlers = GetHandlers()
    if type(handlers) ~= "table" then return peek end
    -- ʕ •ᴥ•ʔ✿ skip PELAH if peek already sees it; ATTN may be a separate path ✿ ʕ •ᴥ•ʔ
    if not peek and type(handlers[PREFIX]) == "function" then
        if handlers[PREFIX] ~= hookFn then
            local orig = handlers[PREFIX]
            hookFn = function(body, ...)
                pcall(OnPacket, body)
                if orig then return orig(body, ...) end
            end
            handlers[PREFIX] = hookFn
        end
    end
    if type(handlers.PELATTN) == "function" and handlers.PELATTN ~= attnFn then
        local orig = handlers.PELATTN
        attnOrig = orig
        attnFn = function(body, full, ...)
            pcall(ParsePreviewBody, body)
            if type(full) == "string" then pcall(ParsePreviewBody, full) end
            return orig(body, full, ...)
        end
        handlers.PELATTN = attnFn
    end
    peekWrapped.attnDone = true
    return true
end

local function RouteIncoming(a, b)
    local payload = a
    if type(a) == "string" and type(b) == "string" and (a == "PELAH" or a == "PELATTN") then
        if a == "PELATTN" then pcall(ParsePreviewBody, b) else pcall(OnPacket, b) end
        return
    end
    if type(payload) ~= "string" then payload = b end
    if type(payload) ~= "string" then return end
    if string.find(payload, "^PELATTN") or string.sub(payload, 1, 2) == "P^" then
        pcall(ParsePreviewBody, payload)
    elseif string.find(payload, "^PELAH") or string.find(payload, "^SUMMARY") or string.find(payload, "^PAGE") or string.find(payload, "^BOUGHT") then
        pcall(OnPacket, payload)
    end
end

function InstallPeekHook()
    if peekWrapped.ok then return true end
    local names = { "PeloriaOnRawPacket", "PeloriaOnPacket" }
    for i = 1, #names do
        local name = names[i]
        if type(_G[name]) == "function" then
            local orig = _G[name]
            _G[name] = function(a, b, ...)
                RouteIncoming(a, b)
                return orig(a, b, ...)
            end
            peekWrapped.ok = true
            return true
        end
    end
    return false
end

function ScanLabel()
    if not D.scanBtn then return end
    local text = "Scan"
    if state == "fetch" or state == "drill" or state == "preview" then
        text = "Scanning"
    elseif allDeals and #allDeals > 0 then
        text = "Re-scan"
    end
    if D.scanBtn.label then
        D.scanBtn.label:SetText(text)
    else
        D.scanBtn:SetText(text)
    end
end

local function TrimPreviewCache()
    local n = 0
    for _ in pairs(previewCache) do
        n = n + 1
        if n > PREVIEW_MAX then
            previewCache, previewAsked = {}, {}
            return
        end
    end
end

local function StartScan(query)
    if type(PeloriaSend) ~= "function" then
        SetStatus("PeloriaSend missing — open the AH at an auctioneer.")
        return
    end
    TrimPreviewCache()
    EnsureTip()
    searchQuery = CleanQuery(query)
    filterText = searchQuery
    summaries, deals, allDeals, seenPages = {}, {}, {}, {}
    pendingBuys = {}
    if D.massFrame then D.massFrame:Hide() end
    ClearSweep()
    drillJobs, drillIdx, drillInFlight = {}, 1, 0
    drillFlight, drillByGen = {}, {}
    offset, primeIdx, readIdx = 0, 1, 1
    extraWait = false
    fetchLeft = 20
    gen = NextGen()
    page = 0
    state = "fetch"
    pendingSearch = false
    ScanLabel()
    Paint()
    InstallHook()
    if searchQuery ~= "" then
        SetStatus("Searching '" .. searchQuery .. "'...")
    else
        SetStatus("Scanning soulbindable items…")
    end
    Search(gen, 0, 0)
end
D.StartScan = StartScan

local WEIGHT_LAYOUT = 4

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

local function ShowWeights()
    if D.weightFrame and D.weightLayout == WEIGHT_LAYOUT then
        if D.weightFrame:IsShown() then
            D.weightFrame:Hide()
        else
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
    end

    local Skin = _G.qtEasyAuctionSkin
    local f = CreateFrame("Frame", "qtEasyAuctionWeights", UIParent)
    f:SetWidth(328)
    f:SetHeight(58 + #STAT_KEYS * 34 + 44)
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
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Weights  ·  " .. (UnitClass("player") or "class"))
    D.weightTitle = title
    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOP", 0, -28)
    hint:SetText("drag or type   ·   1.00 = full   ·   0 = ignore")
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
        GetWeights()[k] = value
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

    local w = GetWeights()
    for i = 1, #STAT_KEYS do
        local k = STAT_KEYS[i]
        local y = -18 - i * 34
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
            if summaries and #summaries > 0 then FinishRead() end
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
            if summaries and #summaries > 0 then FinishRead() end
        end
        box:SetScript("OnEnterPressed", SaveBox)
        box:SetScript("OnEditFocusLost", function(self)
            local value = Commit(k, self:GetText(), true)
            self:SetText(string.format("%.2f", value))
        end)
        box:SetScript("OnEscapePressed", function(self)
            self:SetText(string.format("%.2f", GetWeights()[k] or 0))
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
        local nw = GetWeights()
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
            D.weightTitle:SetText("Weights  ·  " .. (UnitClass("player") or "class"))
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
        CharDB().weights[ClassToken()] = DefaultWeights()
        D.RefreshWeights()
        if summaries and #summaries > 0 then FinishRead() end
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
        if summaries and #summaries > 0 then FinishRead() end
        f:Hide()
    end)
    D.weightFrame = f
    D.weightLayout = WEIGHT_LAYOUT
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
    InstallHook()
    if deal.idRaw and deal.buyoutRaw then
        QueueBuy(deal)
        PeloriaSend(string.format("%s^BUY^%s^%s", PREFIX, deal.idRaw, deal.buyoutRaw))
        SetStatus("Buying " .. (deal.name or "") .. " for " .. GoldText(deal.minPrice) .. ".")
        return
    end
    buyGen = NextGen()
    buyEntry = deal.entry
    SetStatus("Finding cheapest listing…")
    Search(buyGen, 0, deal.entry)
end

local function EnsureInfoTip()
    if not infoTip then
        infoTip = CreateFrame("GameTooltip", "qtEasyAuctionInfoTip", UIParent, "GameTooltipTemplate")
        infoTip:SetFrameStrata("TOOLTIP")
        infoTip:SetScript("OnShow", function(self)
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 6, 0)
        end)
    end
    return infoTip
end

local function HideTips()
    PeloriaSoulbindHoverLevel = nil
    GameTooltip:Hide()
    if infoTip then infoTip:Hide() end
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
    tip:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 6, 0)
    tip:AddLine("Deal math", 0.95, 0.82, 0.55)
    tip:AddDoubleLine("Mythic", MythicTag(deal.mythic, deal.mythicMax), 0.75, 0.75, 0.8, 0.4, 1, 0.4)
    local gold = deal.gold or GoldRaw(deal.minPrice)
    tip:AddDoubleLine("Buyout", Commas(gold) .. "g", 0.75, 0.75, 0.8, 1, 0.85, 0.3)
    local preview = deal.preview
    if preview and #preview > 0 then
        tip:AddLine("Soulbind preview", 0.55, 0.72, 0.95)
        for i = 1, #preview do
            local p = preview[i]
            tip:AddDoubleLine(p.name or "?", "+" .. Compact(p.value or 0), 0.8, 0.8, 0.85, 0.7, 0.9, 0.7)
        end
    end
    local wt = GetWeights()
    local stats = deal.stats or {}
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
        tip:AddLine("Score " .. Compact(deal.total or 0) .. "  ·  " .. RatioText(deal.perGold) .. "/g  ·  " .. RatioText(deal.perK) .. "/1kg", 0.95, 0.85, 0.55, true)
    end
    if deal.owner then
        tip:AddDoubleLine("Seller", deal.owner, 0.7, 0.7, 0.75, 1, 0.82, 0.4)
    end
    tip:Show()
end

local function CreateRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r:SetHeight(ROW_H)
    r:EnableMouse(true)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    r.sel = r:CreateTexture(nil, "BORDER")
    r.sel:SetAllPoints()
    r.sel:SetTexture("Interface\\Buttons\\WHITE8X8")
    r.sel:Hide()
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetWidth(ICON_SZ)
    r.icon:SetHeight(ICON_SZ)
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
    buy:SetScript("OnClick", function() BuyDeal(r.deal) end)
    local function BeginSweep(deal)
        if not deal then return end
        sweep, sweepHeld = true, false
        sweepSet, sweepOrder = {}, {}
        sweepAnchor, sweepHover = deal, deal
        SweepTo(deal)
        HideTips()
        Paint()
    end
    buy:SetScript("OnEnter", function()
        if sweep and r.deal then
            SweepTo(r.deal)
            Paint()
        end
    end)
    buy:SetScript("OnMouseDown", function(_, btn)
        if btn == "RightButton" and IsShiftKeyDown() then BeginSweep(r.deal) end
    end)
    buy:SetScript("OnMouseUp", function(_, btn)
        if btn == "RightButton" then FinishSweep() end
    end)
    r:SetScript("OnMouseDown", function(self, btn)
        if btn == "RightButton" and IsShiftKeyDown() then BeginSweep(self.deal) end
    end)
    r:SetScript("OnMouseUp", function(_, btn)
        if btn == "RightButton" then FinishSweep() end
    end)
    r:SetScript("OnEnter", function(self)
        if sweep then
            if self.deal then
                SweepTo(self.deal)
                Paint()
            end
            return
        end
        ShowDealTips(self)
    end)
    r:SetScript("OnLeave", function()
        if not sweep then HideTips() end
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
        local ok, err = pcall(ShowWeights)
        if not ok then
            print("|cffff5555qtEasyAuction:|r weights: " .. tostring(err))
        end
    end)
    D.filterBtn = weights

    -- ʕ •ᴥ•ʔ✿ search field is chrome, not a floating blizzard box ✿ ʕ •ᴥ•ʔ
    local search = CreateFrame("Frame", nil, panel)
    search:SetPoint("TOPLEFT", 8, -6)
    search:SetPoint("RIGHT", weights, "LEFT", -8, 0)
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
        if state ~= "idle" then return end
        if not allDeals or #allDeals == 0 then return end
        filterText = BoxQuery()
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
                if sortKey == key then
                    sortDesc = not sortDesc
                else
                    sortKey = key
                    sortDesc = true
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
        offset = math.floor((value or 0) + 0.5)
        Paint()
    end)
    D.bar = bar
    D.rows = {}
    for i = 1, ROW_MAX do
        D.rows[i] = CreateRow(list)
    end
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta)
        offset = (offset or 0) - delta * 3
        Paint()
    end)
    panel:SetScript("OnShow", function() Paint() end)
    panel:SetScript("OnHide", function()
        if D.massFrame then D.massFrame:Hide() end
        ClearSweep()
    end)
    panel:SetScript("OnUpdate", function(_, delta)
        if state == "idle" and not sweep then return end
        if sweep then
            if IsMouseButtonDown("RightButton") then
                sweepHeld = true
                for i = 1, #(D.rows or {}) do
                    local row = D.rows[i]
                    if row:IsShown() and MouseIsOver(row) and row.deal then
                        if row.deal ~= sweepHover then
                            sweepHover = row.deal
                            SweepTo(row.deal)
                            Paint()
                        end
                        break
                    end
                end
            elseif sweepHeld then
                FinishSweep()
            end
        end
        if state == "fetch" then
            InstallHook()
            fetchLeft = (fetchLeft or 0) - delta
            if fetchLeft <= 0 then
                if summaries and #summaries > 0 then
                    BeginDrillPass()
                else
                    state = "idle"
                    ScanLabel()
                    SetStatus("No AH reply. Open the house, then Re-scan.")
                end
            end
        elseif state == "drill" then
            PumpDrill()
        elseif state == "preview" then
            PumpPreview()
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
    if D.searchBg then D.searchBg:SetVertexColor(pal.rowB[1], pal.rowB[2], pal.rowB[3], 1) end
    if D.searchLine then D.searchLine:SetVertexColor(pal.accent[1], pal.accent[2], pal.accent[3], 0.85) end
    if D.searchHint then D.searchHint:SetTextColor(pal.mute[1], pal.mute[2], pal.mute[3]) end
    if D.searchBox then D.searchBox:SetTextColor(pal.cream[1], pal.cream[2], pal.cream[3]) end
    if D.RefreshHeads then D.RefreshHeads() end
    PaintWeightFrame()
    PaintMassConfirm()
    Paint()
end

function D.OnShown()
    local ok, err = pcall(CreatePanel)
    if not ok then
        print("|cffff5555qtEasyAuction:|r deals ui: " .. tostring(err))
        D.panel = nil
    end
    if D.panel then D.panel:Show() end
    D.ApplySkin()
    if state == "idle" and (not deals or #deals == 0) then StartScan() end
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
