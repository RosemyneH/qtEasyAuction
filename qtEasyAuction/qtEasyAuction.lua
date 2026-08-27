local UI = "qtEasyAuctionUI"

local watch = CreateFrame("Frame")
local pump = CreateFrame("Frame")
local elapsed, tries, warned = 0, 0, nil
local wrappedPelah, watchElapsed = nil, 0
local WATCH_GAP = 0.25
local origClose

local function StopPump()
    pump:SetScript("OnUpdate", nil)
    elapsed, tries = 0, 0
end

local function Sleep()
    StopPump()
    local Skin = _G.qtEasyAuctionSkin
    if Skin and Skin.tray then Skin.tray:Hide() end
    if Skin and Skin.host then Skin.host:Hide() end
end

local function LoadUI()
    if IsAddOnLoaded(UI) then return true end
    EnableAddOn(UI)
    local _, reason = LoadAddOn(UI)
    if IsAddOnLoaded(UI) then return true end
    if not warned then
        warned = true
        print("|cffff5555qtEasyAuction:|r UI failed to load (" .. tostring(reason or "MISSING") .. ")")
    end
    return false
end

local function Pump(_, delta)
    elapsed = elapsed + (delta or 1)
    if elapsed < 0.1 then return end
    elapsed = 0
    tries = tries + 1
    if not LoadUI() or tries > 200 then
        StopPump()
        return
    end
    local Skin = _G.qtEasyAuctionSkin
    if Skin and Skin.Attach then Skin.Attach() end
    if Skin and Skin.host then StopPump() end
end

local function Wake()
    elapsed, tries = 0.1, 0
    pump:SetScript("OnUpdate", Pump)
    Pump(pump, 0)
end

local function ArmFrame()
    local ah = _G.PeloriaAuctionHouseFrame
    if not ah then return false end
    if not ah._qtEasyAuction then
        ah._qtEasyAuction = true
        pcall(ah.HookScript, ah, "OnShow", Wake)
        pcall(ah.HookScript, ah, "OnHide", Sleep)
    end
    if ah:IsShown() then Wake() end
    return true
end

local function ArmClose()
    local close = _G.PeloriaAuctionHouseClose
    if type(close) ~= "function" then return false end
    if origClose then return true end
    origClose = close
    _G.PeloriaAuctionHouseClose = function(...)
        origClose(...)
        Sleep()
    end
    return true
end

local function PacketArmed()
    local handlers = _G.PeloriaPacketHandlers
    return wrappedPelah
        and type(handlers) == "table"
        and handlers.PELAH == wrappedPelah
end

-- ʕ •ᴥ•ʔ✿ Peloria AH opens on PELAH OPEN, not AUCTION_HOUSE_SHOW ✿ ʕ •ᴥ•ʔ
local function ArmPackets()
    local handlers = _G.PeloriaPacketHandlers
    if type(handlers) ~= "table" then return false end
    local fn = handlers.PELAH
    if type(fn) ~= "function" then return false end
    if fn == wrappedPelah then return true end
    local orig = fn
    wrappedPelah = function(body)
        orig(body)
        if type(body) ~= "string" then return end
        if string.find(body, "OPEN^", 1, true) == 1 then
            Wake()
        elseif body == "CLOSE" then
            Sleep()
        end
    end
    handlers.PELAH = wrappedPelah
    return true
end

local function Arm()
    ArmPackets()
    ArmClose()
    ArmFrame()
    if PacketArmed() then
        watch:SetScript("OnUpdate", nil)
    end
end

local function Watch(_, delta)
    watchElapsed = watchElapsed + (delta or 1)
    if watchElapsed < WATCH_GAP then return end
    watchElapsed = 0
    Arm()
end

local function StartWatch()
    if PacketArmed() then
        ArmFrame()
        return
    end
    watchElapsed = WATCH_GAP
    watch:SetScript("OnUpdate", Watch)
    Watch(watch, 0)
end

watch:RegisterEvent("PLAYER_LOGIN")
watch:RegisterEvent("PLAYER_ENTERING_WORLD")
watch:RegisterEvent("AUCTION_HOUSE_SHOW")
watch:RegisterEvent("AUCTION_HOUSE_CLOSED")
watch:SetScript("OnEvent", function(_, event)
    if event == "AUCTION_HOUSE_CLOSED" then
        Sleep()
        return
    end
    if event == "AUCTION_HOUSE_SHOW" then
        Arm()
        Wake()
        return
    end
    StartWatch()
end)
StartWatch()

SlashCmdList["QTEASYAUCTION"] = function(msg)
    if _G.qtEasyAuctionSales and _G.qtEasyAuctionSales.Slash and _G.qtEasyAuctionSales.Slash(msg) then
        return
    end
    LoadUI()
    if _G.qtEasyAuctionSlash then
        _G.qtEasyAuctionSlash(msg)
        return
    end
    print("|cff00ff00qtEasyAuction:|r silent until the auction house opens")
end
SLASH_QTEASYAUCTION1 = "/qta"
SLASH_QTEASYAUCTION2 = "/qtauction"
