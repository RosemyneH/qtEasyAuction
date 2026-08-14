local PAA = CreateFrame("Frame")
local running = false
local bag, slot = 0, 0
local elapsed = 0
local DELAY = 0.3

print("|cff00ff00qtEasyAuction loaded!|r")

local scanner = CreateFrame("GameTooltip", "PeloriaAutoAuctionScanner", nil, "GameTooltipTemplate")

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

local function BagItemState(b, s)
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner:ClearLines()
    if not pcall(scanner.SetBagItem, scanner, b, s) then return {} end
    if scanner:NumLines() == 0 then return {} end
    local state = StateFromLines(ReadTooltipLines(scanner))
    if not Coherent(state) then return {} end
    return state
end

local function ShouldPost(link, bag, slot)
    if not link then return false end

    local itemName, _, quality, _, _, itemType, itemSubType = GetItemInfo(link)
    if not itemName then return false end

    if quality and quality >= 5 then return false end

    if itemType == "Quest" then return false end

    local lowerName = string.lower(itemName)
    if string.find(lowerName, "hearthstone", 1, true) then return false end

    if itemSubType == "Junk" then return true end

    local state = BagItemState(bag, slot)

    if state.bound then return true end

    if state.classBlocked and not state.available then return true end

    if state.available then return false end

    if not state.known and (itemType == "Armor" or itemType == "Weapon") then
        return true
    end

    return false
end

local function GetFrames()
    if not PeloriaAuctionHouseFrame then return end

    local root = select(22, PeloriaAuctionHouseFrame:GetChildren())
    if not root then return end

    local a = select(1, root:GetChildren())
    if not a then return end

    local b = select(1, a:GetChildren())
    if not b then return end

    local drop = select(1, b:GetChildren())

    local cp = select(2, root:GetChildren())
    if not cp then return end

    local create = select(3, cp:GetChildren())

    return drop, create
end

local function FindNextItem()
    while bag <= 4 do
        slot = slot + 1

        if slot > GetContainerNumSlots(bag) then
            bag = bag + 1
            slot = 0
        else
            local link = GetContainerItemLink(bag, slot)
            if link and ShouldPost(link, bag, slot) then
                return bag, slot
            end
        end
    end
end

local function SetButtonState()
    if not PAA.button then return end

    if running then
        PAA.button:SetText("STOP")
    else
        PAA.button:SetText("Auto Post")
    end
end

local function Stop()
    running = false
    ClearCursor()
    SetButtonState()
    print("|cffffff00PeloriaAuto:|r Stopped.")
end

local function PostNext()
    local drop, create = GetFrames()

    if not drop or not create then
        print("|cffff0000PeloriaAuto:|r Auction controls not found.")
        Stop()
        return
    end

    local b, s = FindNextItem()

    if not b then
        running = false
        SetButtonState()
        print("|cff00ff00PeloriaAuto:|r Finished.")
        return
    end

    local link = GetContainerItemLink(b, s)

    print("|cff00ccffPeloriaAuto:|r Posting", link)

    PickupContainerItem(b, s)

    local drag = drop:GetScript("OnReceiveDrag")

    if not drag then
        print("|cffff0000PeloriaAuto:|r OnReceiveDrag not found.")
        Stop()
        return
    end

    drag(drop)

    create:Click("LeftButton")
end

local function Start()
    if running then
        Stop()
        return
    end

    bag = 0
    slot = 0
    elapsed = DELAY
    running = true

    SetButtonState()

    print("|cff00ff00PeloriaAuto:|r Started.")
end

PAA:SetScript("OnUpdate", function(self, delta)
    if not running then return end

    elapsed = elapsed + delta

    if elapsed >= DELAY then
        elapsed = 0
        PostNext()
    end
end)

local function CreateButton()
    print("|cff00ffffCreateButton called|r")
    
    if PAA.button then 
        print("|cffff8800Button already exists|r")
        return 
    end
    
    if not PeloriaAuctionHouseFrame then 
        print("|cffff0000PeloriaAuctionHouseFrame not found in CreateButton|r")
        return 
    end
    
    print("|cff00ff00Creating button...|r")

    local button = CreateFrame(
        "Button",
        "PeloriaAutoPostButton",
        PeloriaAuctionHouseFrame,
        "UIPanelButtonTemplate"
    )

    button:SetWidth(90)
    button:SetHeight(22)

    button:SetPoint(
        "TOPRIGHT",
        PeloriaAuctionHouseFrame,
        "TOPRIGHT",
        -35,
        -8
    )

    button:SetText("Auto Post")

    button:SetScript("OnClick", function()
        Start()
    end)

    PAA.button = button
    print("|cff00ff00Button created successfully!|r")
end

PAA:RegisterEvent("AUCTION_HOUSE_SHOW")

PAA:SetScript("OnEvent", function(self, event)
    if event == "AUCTION_HOUSE_SHOW" then
        print("|cffff8800qtEasyAuction:|r Auction House opened")
        CreateButton()
    end
end)

local buttonCheckFrame = CreateFrame("Frame")
local buttonCheckElapsed = 0
buttonCheckFrame:SetScript("OnUpdate", function(self, delta)
    buttonCheckElapsed = buttonCheckElapsed + delta
    if buttonCheckElapsed >= 0.5 then
        buttonCheckElapsed = 0
        if PeloriaAuctionHouseFrame and PeloriaAuctionHouseFrame:IsShown() and not PAA.button then
            CreateButton()
        end
    end
end)

SlashCmdList["QTEASYAUCTION"] = function(msg)
    if msg == "test" then
        print("|cff00ff00qtEasyAuction:|r Addon is loaded and working!")
        if PeloriaAuctionHouseFrame then
            print("|cff00ff00qtEasyAuction:|r PeloriaAuctionHouseFrame found")
        else
            print("|cffff0000qtEasyAuction:|r PeloriaAuctionHouseFrame NOT found")
        end
        if PAA.button then
            print("|cff00ff00qtEasyAuction:|r Button created")
        else
            print("|cffff8800qtEasyAuction:|r Button not yet created")
        end
    elseif msg == "create" then
        CreateButton()
        print("|cff00ff00qtEasyAuction:|r Attempted to create button")
    else
        print("|cff00ff00qtEasyAuction:|r Commands: /qta test, /qta create")
    end
end
SLASH_QTEASYAUCTION1 = "/qta"
SLASH_QTEASYAUCTION2 = "/qtauction"
