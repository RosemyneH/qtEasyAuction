local S = {}
_G.qtEasyAuctionSkin = S

local TEX = "Interface\\AddOns\\qtEasyAuction\\Media\\"
local WHITE = "Interface\\Buttons\\WHITE8X8"

local C = {
    bg      = { 0.10, 0.09, 0.14, 1 },
    panel   = { 0.14, 0.12, 0.18, 1 },
    rowA    = { 0.16, 0.14, 0.20, 0.95 },
    rowB    = { 0.12, 0.11, 0.16, 0.95 },
    accent  = { 0.78, 0.55, 0.72, 1 },
    btn     = { 0.42, 0.28, 0.46, 1 },
    btnHi   = { 0.58, 0.40, 0.58, 1 },
    cream   = { 0.95, 0.90, 0.82, 1 },
    mute    = { 0.62, 0.56, 0.64, 1 },
    gold    = { 1.00, 0.84, 0.45, 1 },
    head    = { 0.22, 0.12, 0.28, 1 },
    headTxt = { 0.95, 0.78, 0.92, 1 },
}

S.THEMES = {
    { id = "lilac",     name = "Lilac Bunny",   mascot = "mascot-bunny",  fun = true },
    { id = "mint",      name = "Mint Frog",     mascot = "mascot-frog",   fun = true },
    { id = "honey",     name = "Honey Bear",    mascot = "mascot-bear",   fun = true },
    { id = "sky",       name = "Sky Owl",       mascot = "mascot-owl",    fun = true },
    { id = "peach",     name = "Peach Fox",     mascot = "mascot-fox",    fun = true },
    { id = "berry",     name = "Berry Cat",     mascot = "mascot-cat",    fun = true },
    { id = "forest",    name = "Forest Deer",   mascot = "mascot-deer",   fun = true },
    { id = "coral",     name = "Coral Fish",    mascot = "mascot-fish",   fun = true },
    { id = "slate",     name = "Slate",         mascot = "mascot-mark",   fun = false },
    { id = "parchment", name = "Parchment",     mascot = "mascot-coin",   fun = false },
    { id = "midnight",  name = "Midnight",      mascot = "mascot-moon",   fun = false },
    { id = "human",     name = "Human",         mascot = "mascot-human",     fun = true, sticker = true },
    { id = "gnome",     name = "Gnome",         mascot = "mascot-gnome",     fun = true, sticker = true },
    { id = "troll",     name = "Troll",         mascot = "mascot-troll",     fun = true, sticker = true },
    { id = "dwarf",     name = "Dwarf",         mascot = "mascot-dwarf",     fun = true, sticker = true },
    { id = "draenei",   name = "Draenei",       mascot = "mascot-draenei",   fun = true, sticker = true },
    { id = "tauren",    name = "Tauren",        mascot = "mascot-tauren",    fun = true, sticker = true },
    { id = "forsaken",  name = "Forsaken",      mascot = "mascot-forsaken",  fun = true, sticker = true },
    { id = "nightelf",  name = "Night Elf",     mascot = "mascot-nightelf",  fun = true, sticker = true },
    { id = "bloodelf",  name = "Blood Elf",     mascot = "mascot-bloodelf",  fun = true, sticker = true },
    { id = "orc",       name = "Orc",           mascot = "mascot-orc",       fun = true, sticker = true },
    { id = "eredar",    name = "Man'ari",       mascot = "mascot-eredar",    fun = true, sticker = true },
    { id = "crypt",     name = "Crypt Lord",    mascot = "mascot-crypt",     fun = true, sticker = true },
}

local PALETTE = {
    lilac = {
        bg = { 0.10, 0.09, 0.14, 1 }, panel = { 0.14, 0.12, 0.18, 1 },
        rowA = { 0.16, 0.14, 0.20, 0.95 }, rowB = { 0.12, 0.11, 0.16, 0.95 },
        accent = { 0.78, 0.55, 0.72, 1 }, btn = { 0.42, 0.28, 0.46, 1 }, btnHi = { 0.58, 0.40, 0.58, 1 },
        cream = { 0.95, 0.90, 0.82, 1 }, mute = { 0.62, 0.56, 0.64, 1 }, gold = { 1.00, 0.84, 0.45, 1 },
        head = { 0.22, 0.12, 0.28, 1 }, headTxt = { 0.95, 0.78, 0.92, 1 },
    },
    mint = {
        bg = { 0.07, 0.12, 0.10, 1 }, panel = { 0.10, 0.18, 0.15, 1 },
        rowA = { 0.12, 0.22, 0.18, 0.95 }, rowB = { 0.09, 0.16, 0.13, 0.95 },
        accent = { 0.43, 0.73, 0.55, 1 }, btn = { 0.18, 0.42, 0.32, 1 }, btnHi = { 0.28, 0.58, 0.44, 1 },
        cream = { 0.90, 0.96, 0.90, 1 }, mute = { 0.52, 0.64, 0.56, 1 }, gold = { 0.95, 0.88, 0.45, 1 },
        head = { 0.10, 0.24, 0.18, 1 }, headTxt = { 0.70, 0.90, 0.78, 1 },
    },
    honey = {
        bg = { 0.14, 0.10, 0.05, 1 }, panel = { 0.20, 0.15, 0.08, 1 },
        rowA = { 0.24, 0.18, 0.10, 0.95 }, rowB = { 0.16, 0.12, 0.07, 0.95 },
        accent = { 0.91, 0.69, 0.28, 1 }, btn = { 0.48, 0.32, 0.12, 1 }, btnHi = { 0.66, 0.46, 0.18, 1 },
        cream = { 0.98, 0.93, 0.78, 1 }, mute = { 0.70, 0.58, 0.38, 1 }, gold = { 1.00, 0.84, 0.40, 1 },
        head = { 0.28, 0.18, 0.08, 1 }, headTxt = { 0.98, 0.86, 0.50, 1 },
    },
    sky = {
        bg = { 0.06, 0.10, 0.17, 1 }, panel = { 0.10, 0.16, 0.26, 1 },
        rowA = { 0.12, 0.20, 0.32, 0.95 }, rowB = { 0.08, 0.14, 0.22, 0.95 },
        accent = { 0.47, 0.69, 0.86, 1 }, btn = { 0.18, 0.32, 0.50, 1 }, btnHi = { 0.28, 0.48, 0.70, 1 },
        cream = { 0.90, 0.94, 0.98, 1 }, mute = { 0.52, 0.62, 0.74, 1 }, gold = { 0.95, 0.86, 0.50, 1 },
        head = { 0.10, 0.18, 0.32, 1 }, headTxt = { 0.72, 0.86, 0.98, 1 },
    },
    peach = {
        bg = { 0.16, 0.08, 0.07, 1 }, panel = { 0.24, 0.12, 0.10, 1 },
        rowA = { 0.28, 0.16, 0.12, 0.95 }, rowB = { 0.20, 0.10, 0.08, 0.95 },
        accent = { 0.94, 0.59, 0.43, 1 }, btn = { 0.56, 0.28, 0.20, 1 }, btnHi = { 0.74, 0.40, 0.28, 1 },
        cream = { 0.98, 0.92, 0.86, 1 }, mute = { 0.74, 0.54, 0.46, 1 }, gold = { 1.00, 0.84, 0.45, 1 },
        head = { 0.30, 0.14, 0.10, 1 }, headTxt = { 1.00, 0.78, 0.62, 1 },
    },
    berry = {
        bg = { 0.14, 0.05, 0.08, 1 }, panel = { 0.22, 0.08, 0.12, 1 },
        rowA = { 0.28, 0.10, 0.16, 0.95 }, rowB = { 0.18, 0.06, 0.10, 0.95 },
        accent = { 0.82, 0.27, 0.39, 1 }, btn = { 0.50, 0.14, 0.22, 1 }, btnHi = { 0.70, 0.24, 0.34, 1 },
        cream = { 0.98, 0.90, 0.92, 1 }, mute = { 0.72, 0.48, 0.54, 1 }, gold = { 1.00, 0.84, 0.45, 1 },
        head = { 0.28, 0.08, 0.14, 1 }, headTxt = { 1.00, 0.72, 0.78, 1 },
    },
    forest = {
        bg = { 0.05, 0.11, 0.07, 1 }, panel = { 0.08, 0.16, 0.10, 1 },
        rowA = { 0.12, 0.20, 0.12, 0.95 }, rowB = { 0.07, 0.14, 0.08, 0.95 },
        accent = { 0.35, 0.59, 0.31, 1 }, btn = { 0.18, 0.34, 0.18, 1 }, btnHi = { 0.28, 0.50, 0.28, 1 },
        cream = { 0.90, 0.94, 0.84, 1 }, mute = { 0.50, 0.62, 0.48, 1 }, gold = { 0.95, 0.86, 0.45, 1 },
        head = { 0.10, 0.22, 0.12, 1 }, headTxt = { 0.72, 0.88, 0.58, 1 },
    },
    coral = {
        bg = { 0.07, 0.12, 0.13, 1 }, panel = { 0.09, 0.18, 0.20, 1 },
        rowA = { 0.12, 0.24, 0.24, 0.95 }, rowB = { 0.08, 0.16, 0.17, 0.95 },
        accent = { 0.31, 0.75, 0.71, 1 }, btn = { 0.14, 0.40, 0.40, 1 }, btnHi = { 0.22, 0.56, 0.54, 1 },
        cream = { 0.88, 0.96, 0.94, 1 }, mute = { 0.48, 0.66, 0.64, 1 }, gold = { 1.00, 0.84, 0.45, 1 },
        head = { 0.08, 0.22, 0.24, 1 }, headTxt = { 0.62, 0.92, 0.88, 1 },
    },
    slate = {
        bg = { 0.09, 0.10, 0.11, 1 }, panel = { 0.13, 0.14, 0.16, 1 },
        rowA = { 0.16, 0.17, 0.19, 0.95 }, rowB = { 0.11, 0.12, 0.14, 0.95 },
        accent = { 0.55, 0.58, 0.63, 1 }, btn = { 0.28, 0.30, 0.34, 1 }, btnHi = { 0.40, 0.43, 0.48, 1 },
        cream = { 0.90, 0.91, 0.92, 1 }, mute = { 0.58, 0.60, 0.64, 1 }, gold = { 0.92, 0.82, 0.50, 1 },
        head = { 0.16, 0.17, 0.20, 1 }, headTxt = { 0.78, 0.80, 0.84, 1 },
    },
    parchment = {
        bg = { 0.16, 0.13, 0.08, 1 }, panel = { 0.22, 0.18, 0.11, 1 },
        rowA = { 0.26, 0.21, 0.13, 0.95 }, rowB = { 0.18, 0.15, 0.09, 0.95 },
        accent = { 0.77, 0.61, 0.28, 1 }, btn = { 0.42, 0.32, 0.16, 1 }, btnHi = { 0.58, 0.44, 0.22, 1 },
        cream = { 0.96, 0.90, 0.74, 1 }, mute = { 0.66, 0.56, 0.36, 1 }, gold = { 1.00, 0.84, 0.40, 1 },
        head = { 0.28, 0.22, 0.12, 1 }, headTxt = { 0.90, 0.76, 0.42, 1 },
    },
    midnight = {
        bg = { 0.03, 0.04, 0.06, 1 }, panel = { 0.06, 0.08, 0.12, 1 },
        rowA = { 0.09, 0.11, 0.16, 0.95 }, rowB = { 0.05, 0.06, 0.10, 0.95 },
        accent = { 0.27, 0.35, 0.55, 1 }, btn = { 0.14, 0.18, 0.28, 1 }, btnHi = { 0.22, 0.28, 0.42, 1 },
        cream = { 0.82, 0.86, 0.92, 1 }, mute = { 0.48, 0.52, 0.62, 1 }, gold = { 0.90, 0.80, 0.48, 1 },
        head = { 0.08, 0.10, 0.16, 1 }, headTxt = { 0.62, 0.70, 0.86, 1 },
    },
    crypt = {
        bg = { 0.10, 0.06, 0.08, 1 }, panel = { 0.16, 0.10, 0.12, 1 },
        rowA = { 0.20, 0.12, 0.14, 0.95 }, rowB = { 0.13, 0.08, 0.10, 0.95 },
        accent = { 0.82, 0.66, 0.38, 1 }, btn = { 0.42, 0.16, 0.18, 1 }, btnHi = { 0.58, 0.24, 0.24, 1 },
        cream = { 0.94, 0.88, 0.78, 1 }, mute = { 0.52, 0.56, 0.62, 1 }, gold = { 1.00, 0.84, 0.45, 1 },
        head = { 0.28, 0.10, 0.12, 1 }, headTxt = { 0.95, 0.80, 0.50, 1 },
    },
    eredar = {
        bg = { 0.12, 0.04, 0.04, 1 }, panel = { 0.20, 0.08, 0.07, 1 },
        rowA = { 0.26, 0.10, 0.08, 0.95 }, rowB = { 0.16, 0.06, 0.05, 0.95 },
        accent = { 0.98, 0.88, 0.28, 1 }, btn = { 0.38, 0.22, 0.16, 1 }, btnHi = { 0.52, 0.30, 0.18, 1 },
        cream = { 0.98, 0.94, 0.82, 1 }, mute = { 0.70, 0.48, 0.42, 1 }, gold = { 1.00, 0.84, 0.40, 1 },
        head = { 0.32, 0.10, 0.08, 1 }, headTxt = { 1.00, 0.78, 0.42, 1 },
    },
    orc = {
        bg = { 0.10, 0.12, 0.07, 1 }, panel = { 0.16, 0.18, 0.10, 1 },
        rowA = { 0.20, 0.22, 0.12, 0.95 }, rowB = { 0.13, 0.15, 0.08, 0.95 },
        accent = { 0.46, 0.62, 0.28, 1 }, btn = { 0.32, 0.24, 0.14, 1 }, btnHi = { 0.46, 0.36, 0.18, 1 },
        cream = { 0.92, 0.94, 0.82, 1 }, mute = { 0.58, 0.60, 0.42, 1 }, gold = { 1.00, 0.84, 0.40, 1 },
        head = { 0.22, 0.26, 0.12, 1 }, headTxt = { 0.78, 0.90, 0.48, 1 },
    },
    bloodelf = {
        bg = { 0.16, 0.08, 0.06, 1 }, panel = { 0.24, 0.12, 0.08, 1 },
        rowA = { 0.28, 0.16, 0.10, 0.95 }, rowB = { 0.20, 0.10, 0.07, 0.95 },
        accent = { 0.90, 0.72, 0.28, 1 }, btn = { 0.52, 0.18, 0.16, 1 }, btnHi = { 0.70, 0.28, 0.22, 1 },
        cream = { 0.98, 0.94, 0.86, 1 }, mute = { 0.74, 0.56, 0.42, 1 }, gold = { 1.00, 0.84, 0.40, 1 },
        head = { 0.32, 0.14, 0.10, 1 }, headTxt = { 1.00, 0.82, 0.48, 1 },
    },
    nightelf = {
        bg = { 0.08, 0.06, 0.14, 1 }, panel = { 0.14, 0.10, 0.22, 1 },
        rowA = { 0.18, 0.12, 0.28, 0.95 }, rowB = { 0.10, 0.08, 0.18, 0.95 },
        accent = { 0.55, 0.82, 0.90, 1 }, btn = { 0.28, 0.18, 0.42, 1 }, btnHi = { 0.40, 0.28, 0.58, 1 },
        cream = { 0.90, 0.92, 0.98, 1 }, mute = { 0.58, 0.54, 0.70, 1 }, gold = { 0.90, 0.82, 0.48, 1 },
        head = { 0.18, 0.12, 0.30, 1 }, headTxt = { 0.72, 0.90, 0.96, 1 },
    },
    forsaken = {
        bg = { 0.08, 0.10, 0.08, 1 }, panel = { 0.12, 0.16, 0.12, 1 },
        rowA = { 0.16, 0.20, 0.14, 0.95 }, rowB = { 0.10, 0.13, 0.10, 0.95 },
        accent = { 0.55, 0.78, 0.32, 1 }, btn = { 0.28, 0.32, 0.22, 1 }, btnHi = { 0.40, 0.46, 0.28, 1 },
        cream = { 0.86, 0.92, 0.78, 1 }, mute = { 0.54, 0.62, 0.50, 1 }, gold = { 0.90, 0.82, 0.42, 1 },
        head = { 0.16, 0.22, 0.14, 1 }, headTxt = { 0.78, 0.92, 0.50, 1 },
    },
    tauren = {
        bg = { 0.12, 0.08, 0.05, 1 }, panel = { 0.20, 0.14, 0.08, 1 },
        rowA = { 0.24, 0.18, 0.10, 0.95 }, rowB = { 0.16, 0.11, 0.06, 0.95 },
        accent = { 0.78, 0.58, 0.32, 1 }, btn = { 0.42, 0.28, 0.14, 1 }, btnHi = { 0.58, 0.40, 0.20, 1 },
        cream = { 0.96, 0.90, 0.78, 1 }, mute = { 0.66, 0.54, 0.38, 1 }, gold = { 1.00, 0.84, 0.40, 1 },
        head = { 0.26, 0.16, 0.08, 1 }, headTxt = { 0.94, 0.80, 0.52, 1 },
    },
    draenei = {
        bg = { 0.06, 0.10, 0.18, 1 }, panel = { 0.10, 0.16, 0.28, 1 },
        rowA = { 0.14, 0.20, 0.34, 0.95 }, rowB = { 0.08, 0.12, 0.22, 0.95 },
        accent = { 0.62, 0.78, 0.98, 1 }, btn = { 0.22, 0.32, 0.52, 1 }, btnHi = { 0.34, 0.46, 0.70, 1 },
        cream = { 0.90, 0.94, 0.98, 1 }, mute = { 0.52, 0.62, 0.76, 1 }, gold = { 1.00, 0.84, 0.45, 1 },
        head = { 0.12, 0.20, 0.36, 1 }, headTxt = { 0.78, 0.88, 1.00, 1 },
    },
    dwarf = {
        bg = { 0.12, 0.10, 0.08, 1 }, panel = { 0.18, 0.16, 0.12, 1 },
        rowA = { 0.24, 0.20, 0.14, 0.95 }, rowB = { 0.16, 0.13, 0.10, 0.95 },
        accent = { 0.78, 0.52, 0.28, 1 }, btn = { 0.42, 0.32, 0.22, 1 }, btnHi = { 0.58, 0.44, 0.28, 1 },
        cream = { 0.96, 0.90, 0.80, 1 }, mute = { 0.66, 0.58, 0.46, 1 }, gold = { 1.00, 0.84, 0.40, 1 },
        head = { 0.26, 0.18, 0.12, 1 }, headTxt = { 0.96, 0.76, 0.48, 1 },
    },
    troll = {
        bg = { 0.06, 0.12, 0.12, 1 }, panel = { 0.10, 0.18, 0.18, 1 },
        rowA = { 0.14, 0.24, 0.22, 0.95 }, rowB = { 0.08, 0.16, 0.15, 0.95 },
        accent = { 0.42, 0.78, 0.62, 1 }, btn = { 0.22, 0.40, 0.36, 1 }, btnHi = { 0.32, 0.56, 0.48, 1 },
        cream = { 0.88, 0.96, 0.90, 1 }, mute = { 0.48, 0.64, 0.58, 1 }, gold = { 0.95, 0.82, 0.40, 1 },
        head = { 0.10, 0.24, 0.22, 1 }, headTxt = { 0.62, 0.92, 0.78, 1 },
    },
    gnome = {
        bg = { 0.12, 0.08, 0.14, 1 }, panel = { 0.18, 0.12, 0.20, 1 },
        rowA = { 0.24, 0.16, 0.26, 0.95 }, rowB = { 0.16, 0.10, 0.18, 0.95 },
        accent = { 0.86, 0.58, 0.82, 1 }, btn = { 0.42, 0.24, 0.46, 1 }, btnHi = { 0.58, 0.36, 0.62, 1 },
        cream = { 0.96, 0.90, 0.94, 1 }, mute = { 0.70, 0.56, 0.70, 1 }, gold = { 1.00, 0.84, 0.45, 1 },
        head = { 0.26, 0.14, 0.28, 1 }, headTxt = { 0.96, 0.78, 0.92, 1 },
    },
    human = {
        bg = { 0.08, 0.10, 0.16, 1 }, panel = { 0.12, 0.16, 0.24, 1 },
        rowA = { 0.16, 0.20, 0.30, 0.95 }, rowB = { 0.10, 0.13, 0.20, 0.95 },
        accent = { 0.42, 0.58, 0.86, 1 }, btn = { 0.22, 0.30, 0.50, 1 }, btnHi = { 0.34, 0.44, 0.68, 1 },
        cream = { 0.92, 0.94, 0.98, 1 }, mute = { 0.54, 0.60, 0.72, 1 }, gold = { 1.00, 0.84, 0.45, 1 },
        head = { 0.14, 0.18, 0.32, 1 }, headTxt = { 0.72, 0.82, 0.98, 1 },
    },
}

S.buttons = {}
S.themeId = "crypt"

local charRef

-- ʕ •ᴥ•ʔ✿ per-character prefs; copy from account DB once ✿ ʕ •ᴥ•ʔ
function S.Char()
    if charRef and charRef == qtEasyAuctionCharDB then return charRef end
    qtEasyAuctionCharDB = qtEasyAuctionCharDB or {}
    qtEasyAuctionDB = qtEasyAuctionDB or {}
    local C, A = qtEasyAuctionCharDB, qtEasyAuctionDB
    if C.theme == nil then C.theme = A.theme or "crypt" end
    if C.priceGold == nil then C.priceGold = A.priceGold or 25000 end
    if C.returnUnsold == nil then
        C.returnUnsold = (A.returnUnsold == nil) and true or A.returnUnsold
    end
    if C.scorePrice == nil then C.scorePrice = A.scorePrice and true or false end
    if C.ratioPrice == nil then
        C.ratioPrice = (A.ratioPrice == nil) and true or (A.ratioPrice and true or false)
    end
    if C.goldValue == nil then C.goldValue = A.goldValue or 40 end
    if C.goldValue == 55 then C.goldValue = 40 end
    if C.ratioPrice then C.scorePrice = false end
    if C.postBindable == nil then C.postBindable = false end
    if C.searchAll == nil then C.searchAll = false end
    if C.priceMax == nil then C.priceMax = A.priceMax or 3000000 end
    if C.scoreCap == nil then C.scoreCap = A.scoreCap or 1000000 end
    if not C.weights then
        C.weights = {}
        if type(A.weights) == "table" then
            for token, w in pairs(A.weights) do
                if type(w) == "table" then
                    local copy = {}
                    for k, v in pairs(w) do copy[k] = v end
                    C.weights[token] = copy
                end
            end
        end
    end
    local function CopyMap(src)
        if type(src) ~= "table" then return nil end
        local t = {}
        for k, v in pairs(src) do t[k] = v end
        return t
    end
    local function LegacyWeights(bag)
        if type(bag) ~= "table" then return nil end
        if type(bag.GENERAL) == "table" then return bag.GENERAL end
        for _, w in pairs(bag) do
            if type(w) == "table" then return w end
        end
    end
    local inherited = LegacyWeights(C.weights) or LegacyWeights(A.weights)
    if type(C.sellWeights) ~= "table" then
        C.sellWeights = CopyMap(inherited) or {}
    end
    -- ʕ •ᴥ•ʔ✿ post used to clone shop weights; reseed once ✿ ʕ •ᴥ•ʔ
    if C.postWeightSeed ~= 1 then
        C.postWeights = nil
        C.postWeightSeed = 1
    end
    if not C.itemPrices then
        C.itemPrices = {}
        if type(A.itemPrices) == "table" then
            for id, gold in pairs(A.itemPrices) do
                C.itemPrices[id] = gold
            end
        end
    end
    charRef = C
    return C
end

local function Tint(tex, color)
    if tex and color then
        tex:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    end
end

local function Fill(frame, layer, color)
    local t = frame:CreateTexture(nil, layer or "BACKGROUND")
    t:SetAllPoints()
    t:SetTexture(WHITE)
    Tint(t, color)
    return t
end

local function Ink(fs, color)
    if fs and color then fs:SetTextColor(color[1], color[2], color[3]) end
end

local function Size(obj, w, h)
    obj:SetWidth(w)
    obj:SetHeight(h)
end

local function Stroke(frame)
    local edges = {}
    local function edge(p1, p2, w, h)
        local t = frame:CreateTexture(nil, "BORDER")
        t:SetTexture(WHITE)
        t:SetPoint(p1)
        t:SetPoint(p2)
        if w then t:SetWidth(w) else t:SetHeight(h) end
        edges[#edges + 1] = t
    end
    edge("TOPLEFT", "TOPRIGHT", nil, 2)
    edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 2)
    edge("TOPLEFT", "BOTTOMLEFT", 2, nil)
    edge("TOPRIGHT", "BOTTOMRIGHT", 2, nil)
    frame.stroke = edges
    return edges
end

local function PaintStroke(frame, color)
    local edges = frame.stroke
    if not edges then return end
    for i = 1, #edges do
        Tint(edges[i], color)
    end
end

local function CopyInto(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = dst[k] or {}
            dst[k][1], dst[k][2], dst[k][3], dst[k][4] = v[1], v[2], v[3], v[4] or 1
        end
    end
end

function S.Path(name)
    return TEX .. name
end

function S.Icon(kind)
    kind = string.gsub(kind or "", "^icon%-", "")
    kind = string.gsub(kind, "^mascot%-", "")
    return TEX .. "icon-" .. kind .. "-" .. (S.themeId or "crypt")
end

function S.C()
    return C
end

function S.ThemeById(id)
    local fallback = S.THEMES[1]
    for i = 1, #S.THEMES do
        local t = S.THEMES[i]
        if t.id == id then return t end
        if t.id == "crypt" then fallback = t end
    end
    return fallback
end

local TAB_LINE = {
    "hoppin into some good deals",
    "lining up some listings",
    "watching your auctions",
    "counting sold and spent",
}

local function PaintSub()
    if not S.sub then return end
    Ink(S.sub, C.mute)
    S.sub:SetText(TAB_LINE[S.tab or 1] or TAB_LINE[1])
end

function S.CuteButton(parent, w, h, label, iconName)
    local b = CreateFrame("Button", nil, parent)
    Size(b, w, h)
    b.bg = Fill(b, "BACKGROUND", C.btn)
    local icSz = 0
    if iconName then
        icSz = math.max(22, h - 6)
        local ic = b:CreateTexture(nil, "ARTWORK")
        Size(ic, icSz, icSz)
        ic:SetPoint("LEFT", 4, 0)
        b.iconKind = string.gsub(string.gsub(iconName, "^icon%-", ""), "^mascot%-", "")
        ic:SetTexture(S.Icon(b.iconKind))
        b.icon = ic
    end
    local fs = b:CreateFontString(nil, "OVERLAY", h >= 30 and "GameFontNormal" or "GameFontNormalSmall")
    if iconName then
        fs:SetPoint("LEFT", icSz + 8, 0)
        fs:SetPoint("RIGHT", -8, 0)
    else
        fs:SetAllPoints()
    end
    fs:SetJustifyH("CENTER")
    Ink(fs, C.cream)
    fs:SetText(label or "")
    b.label = fs
    b:EnableMouse(true)
    b:RegisterForClicks("LeftButtonUp")
    b:SetScript("OnEnter", function(self)
        Tint(self.bg, C.btnHi)
    end)
    b:SetScript("OnLeave", function(self)
        if not self.locked then Tint(self.bg, C.btn) end
    end)
    function b:SetLocked(on)
        self.locked = on and true or false
        if on then Tint(self.bg, C.accent) else Tint(self.bg, C.btn) end
    end
    function b:PaintTheme()
        Ink(self.label, C.cream)
        if self.locked then Tint(self.bg, C.accent) else Tint(self.bg, C.btn) end
        if self.icon and self.iconKind then
            self.icon:SetTexture(S.Icon(self.iconKind))
        end
    end
    S.buttons[#S.buttons + 1] = b
    return b
end

function S.Field(parent, w, h, name)
    local wrap = CreateFrame("Frame", nil, parent)
    Size(wrap, w, h)
    wrap.bg = Fill(wrap, "BACKGROUND", C.rowB)
    local line = wrap:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", 0, 0)
    line:SetTexture(WHITE)
    wrap.line = line
    local box = CreateFrame("EditBox", name, wrap)
    box:SetPoint("TOPLEFT", 6, -2)
    box:SetPoint("BOTTOMRIGHT", -6, 2)
    box:SetAutoFocus(false)
    box:SetFontObject(GameFontHighlight)
    box:SetTextInsets(0, 0, 0, 0)
    box:SetJustifyH("CENTER")
    box:EnableMouse(true)
    box:EnableKeyboard(true)
    box:SetAltArrowKeyMode(false)
    wrap.box = box
    function wrap:PaintTheme()
        local pal = C
        Tint(self.bg, pal.rowB)
        Tint(self.line, pal.accent)
        self.box:SetTextColor(pal.gold[1], pal.gold[2], pal.gold[3])
    end
    wrap:PaintTheme()
    S.buttons[#S.buttons + 1] = wrap
    return wrap
end

function S.Chip(parent, w, h, label, tick)
    local b = CreateFrame("Button", nil, parent)
    Size(b, w, h or 32)
    b.bg = Fill(b, "BACKGROUND", C.btn)
    if tick then
        local ic = b:CreateTexture(nil, "ARTWORK")
        Size(ic, 16, 16)
        ic:SetPoint("LEFT", 8, 0)
        b.tick = ic
    end
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    if tick then
        fs:SetPoint("LEFT", 28, 0)
        fs:SetPoint("RIGHT", -8, 0)
        fs:SetJustifyH("LEFT")
    else
        fs:SetPoint("LEFT", 10, 0)
        fs:SetPoint("RIGHT", -10, 0)
        fs:SetJustifyH("CENTER")
    end
    fs:SetText(label or "")
    b.label = fs
    b.on = false
    b:EnableMouse(true)
    b:RegisterForClicks("LeftButtonUp")
    function b:SetOn(on)
        self.on = on and true or false
        self:PaintTheme()
    end
    function b:PaintTheme()
        if self.tick then
            if self.on then
                self.tick:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
            else
                self.tick:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
            end
        end
        if self.on then
            Tint(self.bg, C.accent)
            Ink(self.label, C.cream)
        else
            Tint(self.bg, C.btn)
            Ink(self.label, C.mute)
        end
    end
    b:SetScript("OnEnter", function(self)
        if not self.on then Tint(self.bg, C.btnHi) end
    end)
    b:SetScript("OnLeave", function(self)
        self:PaintTheme()
    end)
    b:SetScript("OnClick", function(self)
        if self.OnToggle then self:OnToggle(not self.on) end
    end)
    b:PaintTheme()
    function b:GetChecked()
        return self.on and true or false
    end
    function b:SetChecked(on)
        self:SetOn(on)
    end
    S.buttons[#S.buttons + 1] = b
    return b
end

local function ShowTab(i, quiet)
    S.tab = i
    if S.pages then
        S.pages.deals:Hide()
        S.pages.post:Hide()
        S.pages.mine:Hide()
        if S.pages.stats then S.pages.stats:Hide() end
        if i == 1 then S.pages.deals:Show()
        elseif i == 2 then S.pages.post:Show()
        elseif i == 3 then S.pages.mine:Show()
        elseif S.pages.stats then S.pages.stats:Show() end
    end
    if S.tabs then
        for n = 1, #S.tabs do
            S.tabs[n]:SetLocked(n == i)
        end
    end
    PaintSub()
    if quiet then return end
    if i == 1 and _G.qtEasyAuctionDeals and _G.qtEasyAuctionDeals.OnShown then
        _G.qtEasyAuctionDeals.OnShown()
    end
    if i == 2 and _G.qtEasyAuctionPost and _G.qtEasyAuctionPost.OnShown then
        _G.qtEasyAuctionPost.OnShown()
    end
    if i == 3 and _G.qtEasyAuctionMine and _G.qtEasyAuctionMine.OnShown then
        _G.qtEasyAuctionMine.OnShown()
    end
    if i == 4 and _G.qtEasyAuctionSales and _G.qtEasyAuctionSales.OnShown then
        _G.qtEasyAuctionSales.OnShown()
    end
end

local function PaintButtons()
    for i = 1, #S.buttons do
        local b = S.buttons[i]
        if b.PaintTheme then b:PaintTheme() end
    end
end

local function PaintSwatches()
    if not S.swatches then return end
    for i = 1, #S.swatches do
        local b = S.swatches[i]
        local on = b.themeId == S.themeId
        if b.ring then
            if on then Tint(b.ring, C.cream) else b.ring:SetVertexColor(0, 0, 0, 0.45) end
        end
    end
    if S.themeBtn then
        if S.tray and S.tray:IsShown() then
            PaintStroke(S.themeBtn, C.accent)
        else
            PaintStroke(S.themeBtn, { 0, 0, 0, 0 })
        end
    end
end

function S.Apply(id)
    local theme = S.ThemeById(id or S.themeId)
    S.themeId = theme.id
    CopyInto(C, PALETTE[theme.id] or PALETTE.crypt)
    S.Char().theme = theme.id
    if S.hostBg then Tint(S.hostBg, C.bg) end
    if S.tabBg then Tint(S.tabBg, C.panel) end
    if S.bodyBg then Tint(S.bodyBg, C.panel) end
    if S.tray and S.tray.bg then Tint(S.tray.bg, C.panel) end
    if S.tray then PaintStroke(S.tray, C.accent) end
    if S.banner then S.banner:SetTexture(TEX .. "banner-" .. theme.id) end
    if S.mascot then S.mascot:SetTexture(TEX .. theme.mascot) end
    if S.themeBtn and S.themeBtn.pic then S.themeBtn.pic:SetTexture(TEX .. theme.mascot) end
    if S.emptyIcon then S.emptyIcon:SetTexture(TEX .. theme.mascot) end
    if S.title then Ink(S.title, C.cream) end
    PaintSub(theme)
    if S.emptyText then Ink(S.emptyText, C.mute) end
    PaintButtons()
    PaintSwatches()
    if S.tray then S.tray:Hide() end
    if _G.qtEasyAuctionDeals and _G.qtEasyAuctionDeals.ApplySkin then
        _G.qtEasyAuctionDeals.ApplySkin()
    end
    if _G.qtEasyAuctionMine and _G.qtEasyAuctionMine.ApplySkin then
        _G.qtEasyAuctionMine.ApplySkin()
    end
    if _G.qtEasyAuctionPost and _G.qtEasyAuctionPost.ApplySkin then
        _G.qtEasyAuctionPost.ApplySkin()
    end
    if _G.qtEasyAuctionSales and _G.qtEasyAuctionSales.ApplySkin then
        _G.qtEasyAuctionSales.ApplySkin()
    end
end

local function MakeThemeChip(parent, theme, index)
    local pal = PALETTE[theme.id]
    local b = CreateFrame("Button", nil, parent)
    Size(b, 44, 44)
    local col = (index - 1) % 7
    local row = math.floor((index - 1) / 7)
    b:SetPoint("TOPLEFT", 8 + col * 48, -8 - row * 48)
    b.themeId = theme.id
    b.ring = b:CreateTexture(nil, "BACKGROUND")
    b.ring:SetAllPoints()
    b.ring:SetTexture(WHITE)
    local pic = b:CreateTexture(nil, "ARTWORK")
    pic:SetPoint("TOPLEFT", 3, -3)
    pic:SetPoint("BOTTOMRIGHT", -3, 3)
    pic:SetTexture(TEX .. theme.mascot)
    b.pic = pic
    b:EnableMouse(true)
    b:RegisterForClicks("LeftButtonUp")
    b:SetScript("OnClick", function() S.Apply(theme.id) end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(theme.name)
        GameTooltip:AddLine(theme.sticker and "sticker skin" or (theme.fun and "cute skin" or "simple skin"), pal.mute[1], pal.mute[2], pal.mute[3])
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

local STRATA_RANK = {
    BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4,
    DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8,
}
local STRATA_NAME = {
    "BACKGROUND", "LOW", "MEDIUM", "HIGH",
    "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP",
}

-- ʕ •ᴥ•ʔ✿ sibling overlay; HIGH-child sits under DIALOG AH chrome ✿ ʕ •ᴥ•ʔ
local function Cover(host, parent)
    local anchor = parent:GetParent() or UIParent
    if anchor == host then anchor = UIParent end
    host:SetParent(anchor)
    host:ClearAllPoints()
    host:SetAllPoints(parent)
    local rank = STRATA_RANK[parent:GetFrameStrata() or "MEDIUM"] or 4
    if rank < 8 then rank = rank + 1 end
    host:SetFrameStrata(STRATA_NAME[rank])
    host:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
    host:Show()
    host:Raise()
end

function S.Create()
    local parent = PeloriaAuctionHouseFrame
    if not parent then return end
    parent:SetScale(1)
    if S.host then
        Cover(S.host, parent)
        return S.host
    end
    S.themeId = S.Char().theme or "crypt"
    CopyInto(C, PALETTE[S.themeId] or PALETTE.crypt)

    local host = CreateFrame("Frame", "qtEasyAuctionSkinHost", UIParent)
    S.host = host
    Cover(host, parent)
    host:EnableMouse(true)
    S.hostBg = Fill(host, "BACKGROUND", C.bg)

    local banner = host:CreateTexture(nil, "ARTWORK")
    banner:SetPoint("TOPLEFT", 8, -8)
    banner:SetPoint("TOPRIGHT", -8, -8)
    banner:SetHeight(76)
    banner:SetTexture(TEX .. "banner-" .. S.themeId)
    S.banner = banner

    local logo = host:CreateTexture(nil, "OVERLAY")
    Size(logo, 64, 64)
    logo:SetPoint("TOPLEFT", 14, -14)
    logo:SetTexture(TEX .. S.ThemeById(S.themeId).mascot)
    S.mascot = logo

    local title = host:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", logo, "RIGHT", 10, 8)
    Ink(title, C.cream)
    title:SetText("qtEasyAuction")
    S.title = title

    local sub = host:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    Ink(sub, C.mute)
    S.sub = sub
    PaintSub()

    local close = S.CuteButton(host, 32, 32, "X")
    close:SetPoint("TOPRIGHT", -12, -14)
    close:SetFrameLevel((host:GetFrameLevel() or 1) + 12)
    close:SetScript("OnClick", function()
        if S.tray then S.tray:Hide() end
        parent:Hide()
    end)
    close:SetScript("OnEnter", function(self)
        Tint(self.bg, C.btnHi)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Close")
        GameTooltip:Show()
    end)
    close:SetScript("OnLeave", function(self)
        if not self.locked then Tint(self.bg, C.btn) end
        GameTooltip:Hide()
    end)
    S.closeBtn = close

    local themeBtn = CreateFrame("Button", nil, host)
    Size(themeBtn, 56, 56)
    themeBtn:SetPoint("TOPRIGHT", close, "TOPLEFT", -8, 0)
    themeBtn.pic = themeBtn:CreateTexture(nil, "ARTWORK")
    themeBtn.pic:SetAllPoints()
    themeBtn.pic:SetTexture(TEX .. S.ThemeById(S.themeId).mascot)
    Stroke(themeBtn)
    PaintStroke(themeBtn, { 0, 0, 0, 0 })
    themeBtn:EnableMouse(true)
    themeBtn:RegisterForClicks("LeftButtonUp")
    themeBtn:SetFrameLevel((host:GetFrameLevel() or 1) + 10)
    S.themeBtn = themeBtn

    local tray = CreateFrame("Frame", "qtEasyAuctionThemeTray", UIParent)
    tray:SetPoint("TOPRIGHT", themeBtn, "BOTTOMRIGHT", 0, -6)
    Size(tray, 8 + 7 * 48, 8 + 4 * 48)
    tray.bg = Fill(tray, "BACKGROUND", C.panel)
    Stroke(tray)
    PaintStroke(tray, C.accent)
    tray:SetFrameStrata("TOOLTIP")
    tray:SetFrameLevel(200)
    tray:EnableMouse(true)
    tray:Hide()
    S.tray = tray

    S.swatches = {}
    for i = 1, #S.THEMES do
        local sw = MakeThemeChip(tray, S.THEMES[i], i)
        sw:SetFrameLevel((tray:GetFrameLevel() or 1) + 2)
        S.swatches[#S.swatches + 1] = sw
    end

    themeBtn:SetScript("OnClick", function()
        GameTooltip:Hide()
        if tray:IsShown() then
            tray:Hide()
        else
            tray:SetFrameStrata("TOOLTIP")
            tray:SetFrameLevel(200)
            tray:Show()
            tray:Raise()
        end
        PaintSwatches()
    end)
    themeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Themes")
        GameTooltip:AddLine("click for sticker skins", C.mute[1], C.mute[2], C.mute[3])
        GameTooltip:Show()
    end)
    themeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local tabBar = CreateFrame("Frame", nil, host)
    tabBar:SetPoint("TOPLEFT", 12, -92)
    tabBar:SetPoint("TOPRIGHT", -12, -92)
    tabBar:SetHeight(36)
    S.tabBg = Fill(tabBar, "BACKGROUND", C.panel)

    S.tabs = {}
    local specs = {
        { "Deals", "deals" },
        { "Post", "post" },
        { "Auctions", "auctions" },
        { "Stats", "deals" },
    }
    local tabW, tabGap = 128, 136
    for i, spec in ipairs(specs) do
        local t = S.CuteButton(tabBar, tabW, 32, spec[1], spec[2])
        t:SetPoint("LEFT", 6 + (i - 1) * tabGap, 0)
        t:SetScript("OnClick", function() ShowTab(i) end)
        S.tabs[i] = t
    end

    local body = CreateFrame("Frame", nil, host)
    body:SetPoint("TOPLEFT", 12, -134)
    body:SetPoint("BOTTOMRIGHT", -12, 12)
    S.bodyBg = Fill(body, "BACKGROUND", C.panel)
    S.body = body

    local function Page()
        local p = CreateFrame("Frame", nil, body)
        p:SetAllPoints()
        p:Hide()
        return p
    end
    S.pages = { deals = Page(), post = Page(), mine = Page(), stats = Page() }

    local empty = S.pages.deals:CreateTexture(nil, "BACKGROUND")
    Size(empty, 128, 128)
    empty:SetPoint("CENTER", 0, 24)
    empty:SetTexture(TEX .. S.ThemeById(S.themeId).mascot)
    S.emptyIcon = empty
    local emptyFs = S.pages.deals:CreateFontString(nil, "BACKGROUND", "GameFontDisable")
    emptyFs:SetPoint("TOP", empty, "BOTTOM", 0, -10)
    Ink(emptyFs, C.mute)
    emptyFs:SetText("no deals yet — Re-scan or search")
    S.emptyText = emptyFs

    ShowTab(1, true)
    host:Show()
    S.host = host
    S.Apply(S.themeId)
    if _G.qtEasyAuctionDeals and _G.qtEasyAuctionDeals.OnShown then
        _G.qtEasyAuctionDeals.OnShown()
    end
    return host
end

function S.SetEmpty(show)
    if S.emptyIcon then
        if show then S.emptyIcon:Show() else S.emptyIcon:Hide() end
    end
    if S.emptyText then
        if show then S.emptyText:Show() else S.emptyText:Hide() end
    end
end

function S.Attach()
    local parent = PeloriaAuctionHouseFrame
    if not parent then return end
    if not parent._qtEasySkinHooked then
        parent._qtEasySkinHooked = true
        pcall(parent.HookScript, parent, "OnShow", function()
            local ok, err = pcall(S.Create)
            if not ok then
                print("|cffff5555qtEasyAuction:|r skin error: " .. tostring(err))
            elseif S.host then
                S.host:Show()
            end
        end)
        pcall(parent.HookScript, parent, "OnHide", function()
            if S.tray then S.tray:Hide() end
            if S.host then S.host:Hide() end
        end)
    end
    if parent:IsShown() then
        local ok, err = pcall(S.Create)
        if not ok then
            print("|cffff5555qtEasyAuction:|r skin error: " .. tostring(err))
        elseif S.host then
            S.host:Show()
        end
    end
end

