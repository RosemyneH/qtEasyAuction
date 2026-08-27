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
local FONT_BASE = setmetatable({}, { __mode = "k" })
local FONT_PREVIEW = setmetatable({}, { __mode = "k" })
local FONT_ROOTS = setmetatable({}, { __mode = "k" })
local FONT_PATHS = {}
local DEFAULT_FONT = "Default"
local MIN_W, MIN_H = 760, 520
local defaultWindow

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
    if C.useCustomUI == nil then C.useCustomUI = true end
    if type(C.fontScale) ~= "number" then C.fontScale = 1 end
    C.fontScale = math.max(0.8, math.min(1.3, C.fontScale))
    if type(C.window) ~= "table" then C.window = {} end
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

local function SharedMedia()
    if type(LibStub) == "table" and LibStub.GetLibrary then
        return LibStub:GetLibrary("LibSharedMedia-3.0", true)
    end
    if type(LibStub) == "function" then return LibStub("LibSharedMedia-3.0", true) end
    return nil
end

function S.FontNames()
    local out = { DEFAULT_FONT }
    local seen = { [DEFAULT_FONT] = true }
    local media = SharedMedia()
    local names = media and media.List and media:List("font")
    for i = 1, #(names or {}) do
        if not seen[names[i]] then
            seen[names[i]] = true
            out[#out + 1] = names[i]
        end
    end
    table.sort(out, function(a, b)
        if a == DEFAULT_FONT then return true end
        if b == DEFAULT_FONT then return false end
        return string.lower(a) < string.lower(b)
    end)
    return out
end

function S.FontName()
    return S.Char().fontName or DEFAULT_FONT
end

function S.FontScale()
    return S.Char().fontScale or 1
end

local function FontPath(name)
    if not name or name == DEFAULT_FONT then return nil end
    if FONT_PATHS[name] ~= nil then return FONT_PATHS[name] or nil end
    local media = SharedMedia()
    local path = media and media.Fetch and media:Fetch("font", name, true) or nil
    FONT_PATHS[name] = path or false
    return path
end

local function ApplyFontObject(obj, path, scale)
    if not obj or type(obj.GetFont) ~= "function" or type(obj.SetFont) ~= "function" then return end
    local base = FONT_BASE[obj]
    if not base then
        local font, size, flags = obj:GetFont()
        if not font or not size then return end
        base = { font = font, size = size, flags = flags }
        FONT_BASE[obj] = base
    end
    local preview = FONT_PREVIEW[obj]
    local font = preview ~= nil and (preview or base.font) or (path or base.font)
    pcall(obj.SetFont, obj, font, math.max(6, base.size * scale), base.flags)
end

function S.SetFontPreview(obj, name)
    local path = FontPath(name) or false
    if FONT_PREVIEW[obj] == path then return end
    FONT_PREVIEW[obj] = path
    ApplyFontObject(obj, nil, S.FontScale())
end

local function ApplyFontTree(frame, path, scale, seen)
    if not frame or seen[frame] then return end
    seen[frame] = true
    if frame.GetObjectType and frame:GetObjectType() == "GameTooltip" then return end
    if frame.GetObjectType then
        local kind = frame:GetObjectType()
        if kind == "EditBox" or kind == "FontString" then ApplyFontObject(frame, path, scale) end
    end
    if frame.GetFontString then ApplyFontObject(frame:GetFontString(), path, scale) end
    if frame.GetRegions then
        local regions = { frame:GetRegions() }
        for i = 1, #regions do
            local region = regions[i]
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                ApplyFontObject(region, path, scale)
            end
        end
    end
    if frame.GetChildren then
        local children = { frame:GetChildren() }
        for i = 1, #children do ApplyFontTree(children[i], path, scale, seen) end
    end
end

function S.ApplyTypography(root)
    local path = FontPath(S.FontName())
    local scale = S.FontScale()
    if root then
        ApplyFontTree(root, path, scale, {})
        return
    end
    for frame in pairs(FONT_ROOTS) do ApplyFontTree(frame, path, scale, {}) end
end

function S.RegisterFontRoot(frame)
    if not frame then return end
    FONT_ROOTS[frame] = true
    S.ApplyTypography(frame)
end

function S.SetFont(name)
    if name ~= DEFAULT_FONT and not FontPath(name) then name = DEFAULT_FONT end
    S.Char().fontName = name
    S.ApplyTypography()
end

function S.SetFontScale(scale)
    S.Char().fontScale = math.max(0.8, math.min(1.3, tonumber(scale) or 1))
    S.ApplyTypography()
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
    "tuning your auction house",
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

function S.Dropdown(parent, w, h, value, options, onSelect)
    local b = S.CuteButton(parent, w, h, value)
    b.label:ClearAllPoints()
    b.label:SetPoint("LEFT", 10, 0)
    b.label:SetPoint("RIGHT", -28, 0)
    b.label:SetJustifyH("LEFT")

    local arrow = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    arrow:SetPoint("RIGHT", -10, 1)
    arrow:SetText("v")
    b.arrow = arrow

    local menu = CreateFrame("Frame", nil, UIParent)
    menu:SetWidth(w)
    menu.bg = Fill(menu, "BACKGROUND", C.panel)
    Stroke(menu)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(220)
    menu:SetToplevel(true)
    menu:EnableMouse(true)
    menu:EnableMouseWheel(true)
    menu:Hide()
    S.RegisterFontRoot(menu)
    b.menu = menu

    local rowHeight, rowMax, menuOffset, maxOffset = h, 10, 0, 0
    local visibleRows = {}
    menu.rows = {}

    local bar = CreateFrame("Slider", nil, menu)
    bar:SetPoint("TOPRIGHT", -3, -3)
    bar:SetPoint("BOTTOMRIGHT", -3, 3)
    bar:SetWidth(14)
    bar:SetFrameLevel(menu:GetFrameLevel() + 3)
    bar:SetOrientation("VERTICAL")
    bar:SetValueStep(1)
    bar.track = Fill(bar, "BACKGROUND", C.rowB)
    bar.thumb = bar:CreateTexture(nil, "ARTWORK")
    bar.thumb:SetTexture(WHITE)
    Size(bar.thumb, 10, 28)
    bar:SetThumbTexture(bar.thumb)
    bar:Hide()
    menu.bar = bar

    local function OptionRow(index, option)
        local row = menu.rows[index]
        if row then
            if row.value ~= option then
                row.value = option
                row.label:SetText(option)
                S.SetFontPreview(row.label, option)
            end
            return row
        end
        row = S.CuteButton(menu, w - 20, rowHeight - 2, option)
        row:SetFrameLevel(menu:GetFrameLevel() + 2)
        row.label:ClearAllPoints()
        row.label:SetJustifyH("LEFT")
        row.label:SetPoint("LEFT", 8, 0)
        row.label:SetPoint("RIGHT", -8, 0)
        row.value = option
        S.SetFontPreview(row.label, option)
        row:SetScript("OnClick", function(self)
            b:SetValue(self.value)
            menu:Hide()
            if onSelect then onSelect(self.value) end
        end)
        menu.rows[index] = row
        return row
    end

    function b:SetValue(nextValue)
        self.value = nextValue
        self.label:SetText(nextValue or "")
    end

    function b:Refresh()
        local values = type(options) == "function" and options() or options or {}
        local visible = math.min(rowMax, #values)
        maxOffset = math.max(0, #values - visible)
        menuOffset = math.max(0, math.min(menuOffset, maxOffset))
        menu:SetHeight(math.max(4, visible * rowHeight + 4))
        for i = 1, #visibleRows do visibleRows[i]:Hide() end
        visibleRows = {}
        for i = 1, visible do
            local index = menuOffset + i
            local row = OptionRow(index, values[index])
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 2, -2 - (i - 1) * rowHeight)
            row:SetLocked(row.value == self.value)
            row:Show()
            visibleRows[i] = row
        end
        menu.syncingBar = true
        bar:SetMinMaxValues(0, maxOffset)
        bar:SetValue(maxOffset - menuOffset)
        menu.syncingBar = nil
        if maxOffset > 0 then bar:Show() else bar:Hide() end
    end

    menu:SetScript("OnMouseWheel", function(_, delta)
        local nextOffset = math.max(0, math.min(menuOffset - delta, maxOffset))
        if nextOffset == menuOffset then return end
        menuOffset = nextOffset
        b:Refresh()
    end)
    bar:SetScript("OnValueChanged", function(_, nextValue)
        if menu.syncingBar then return end
        local nextOffset = math.floor(maxOffset - (nextValue or 0) + 0.5)
        if nextOffset == menuOffset then return end
        menuOffset = nextOffset
        b:Refresh()
    end)
    b:SetScript("OnClick", function()
        if menu:IsShown() then
            menu:Hide()
            return
        end
        local values = type(options) == "function" and options() or options or {}
        menuOffset = 0
        for i = 1, #values do
            if values[i] == b.value then
                menuOffset = math.max(0, math.min(i - 1, #values - rowMax))
                break
            end
        end
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -2)
        b:Refresh()
        menu:Show()
        menu:Raise()
    end)
    parent:HookScript("OnHide", function() menu:Hide() end)

    local PaintButton = b.PaintTheme
    function b:PaintTheme()
        PaintButton(self)
        Ink(self.arrow, C.cream)
        Tint(menu.bg, C.panel)
        PaintStroke(menu, C.accent)
        Tint(bar.track, C.rowB)
        Tint(bar.thumb, C.accent)
    end
    b:SetValue(value)
    b:PaintTheme()
    return b
end

local function ShowTab(i, quiet)
    S.tab = i
    if S.pages then
        S.pages.deals:Hide()
        S.pages.post:Hide()
        S.pages.mine:Hide()
        if S.pages.stats then S.pages.stats:Hide() end
        if S.pages.settings then S.pages.settings:Hide() end
        if i == 1 then S.pages.deals:Show()
        elseif i == 2 then S.pages.post:Show()
        elseif i == 3 then S.pages.mine:Show()
        elseif i == 4 and S.pages.stats then S.pages.stats:Show()
        elseif S.pages.settings then S.pages.settings:Show() end
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
    if i == 5 and _G.qtEasyAuctionSettings and _G.qtEasyAuctionSettings.OnShown then
        _G.qtEasyAuctionSettings.OnShown()
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
    if _G.qtEasyAuctionSettings and _G.qtEasyAuctionSettings.ApplySkin then
        _G.qtEasyAuctionSettings.ApplySkin()
    end
    S.ApplyTypography()
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

local function SaveWindow(parent)
    if not parent then return end
    local cx, cy = parent:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not cx or not cy or not ux or not uy then return end
    local window = S.Char().window
    window.width = parent:GetWidth()
    window.height = parent:GetHeight()
    window.x = cx - ux
    window.y = cy - uy
end

local function ConfigureWindow(parent)
    if not defaultWindow then
        local cx, cy = parent:GetCenter()
        local ux, uy = UIParent:GetCenter()
        defaultWindow = {
            width = parent:GetWidth(),
            height = parent:GetHeight(),
            x = cx and ux and (cx - ux) or 0,
            y = cy and uy and (cy - uy) or 0,
            movable = parent.IsMovable and parent:IsMovable() or false,
            resizable = parent.IsResizable and parent:IsResizable() or false,
            clamped = parent.IsClampedToScreen and parent:IsClampedToScreen() or false,
        }
    end
    if S.customMode then
        parent:SetMovable(true)
        parent:SetResizable(true)
        parent:SetClampedToScreen(true)
        if parent.SetMinResize then parent:SetMinResize(MIN_W, MIN_H) end
        if parent.SetMaxResize then
            parent:SetMaxResize(math.max(MIN_W, UIParent:GetWidth()), math.max(MIN_H, UIParent:GetHeight()))
        end
    else
        if parent.SetMinResize then parent:SetMinResize(1, 1) end
        if parent.SetMaxResize then parent:SetMaxResize(UIParent:GetWidth(), UIParent:GetHeight()) end
        parent:SetMovable(defaultWindow.movable)
        parent:SetResizable(defaultWindow.resizable)
        parent:SetClampedToScreen(defaultWindow.clamped)
    end
    if S.geometryApplied and S.geometryParent == parent then return end
    local window = S.customMode and S.Char().window or defaultWindow
    if window.width and window.height then
        local minW, minH = S.customMode and MIN_W or 1, S.customMode and MIN_H or 1
        parent:SetWidth(math.max(minW, math.min(window.width, UIParent:GetWidth())))
        parent:SetHeight(math.max(minH, math.min(window.height, UIParent:GetHeight())))
    end
    if window.x and window.y then
        parent:ClearAllPoints()
        parent:SetPoint("CENTER", UIParent, "CENTER", window.x, window.y)
    end
    S.geometryApplied = true
    S.geometryParent = parent
end

function S.ResetWindow()
    local parent = PeloriaAuctionHouseFrame
    if not parent then return end
    S.Char().window = {}
    parent:ClearAllPoints()
    parent:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    parent:SetWidth(math.max(MIN_W, math.min(defaultWindow and defaultWindow.width or 900, UIParent:GetWidth())))
    parent:SetHeight(math.max(MIN_H, math.min(defaultWindow and defaultWindow.height or 650, UIParent:GetHeight())))
    SaveWindow(parent)
    S.geometryApplied = true
    S.geometryParent = parent
    if S.RefreshLayout then S.RefreshLayout() end
end

local function RefreshLayout()
    if S.tabBar and S.tabs then
        local width = S.tabBar:GetWidth() or 0
        if width > 0 then
            local gap, edge = 6, 6
            local tabW = (width - edge * 2 - gap * (#S.tabs - 1)) / #S.tabs
            for i = 1, #S.tabs do
                local tab = S.tabs[i]
                tab:ClearAllPoints()
                tab:SetWidth(tabW)
                tab:SetPoint("LEFT", edge + (i - 1) * (tabW + gap), 0)
            end
        end
    end
    local modules = {
        _G.qtEasyAuctionDeals,
        _G.qtEasyAuctionPost,
        _G.qtEasyAuctionMine,
        _G.qtEasyAuctionSales,
        _G.qtEasyAuctionSettings,
    }
    for i = 1, #modules do
        local module = modules[i]
        if module and module.RefreshLayout then module.RefreshLayout() end
    end
end

S.RefreshLayout = RefreshLayout

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
    if S.customMode then host:Show() else host:Hide() end
    host:Raise()
end

local function ApplyDisplayMode(parent)
    if not parent then return end
    local custom = S.Char().useCustomUI ~= false
    S.customMode = custom
    if custom then
        local alpha = parent:GetAlpha()
        if alpha and alpha > 0 then S.nativeAlpha = alpha end
        parent:SetAlpha(0)
        if S.host then S.host:Show() end
    else
        parent:SetAlpha(S.nativeAlpha or 1)
        if S.host then S.host:Hide() end
        if S.tray then S.tray:Hide() end
        local deals = _G.qtEasyAuctionDeals
        if deals and deals.weightFrame then deals.weightFrame:Hide() end
    end
    if S.uiToggle then
        S.uiToggle.label:SetText(custom and "Default UI" or "Easy UI")
        S.uiToggle:Show()
        S.uiToggle:Raise()
    end
end

function S.SetCustomUI(on)
    local parent = PeloriaAuctionHouseFrame
    if S.customMode and parent then SaveWindow(parent) end
    S.Char().useCustomUI = on and true or false
    S.customMode = S.Char().useCustomUI
    S.geometryApplied = nil
    ConfigureWindow(parent)
    ApplyDisplayMode(parent)
end

function S.Create()
    local parent = PeloriaAuctionHouseFrame
    if not parent then return end
    parent:SetScale(1)
    S.customMode = S.Char().useCustomUI ~= false
    ConfigureWindow(parent)
    if S.host then
        Cover(S.host, parent)
        ApplyDisplayMode(parent)
        RefreshLayout()
        return S.host
    end
    S.themeId = S.Char().theme or "crypt"
    CopyInto(C, PALETTE[S.themeId] or PALETTE.crypt)

    local host = CreateFrame("Frame", "qtEasyAuctionSkinHost", UIParent)
    S.host = host
    Cover(host, parent)
    host:EnableMouse(true)
    S.hostBg = Fill(host, "BACKGROUND", C.bg)
    S.RegisterFontRoot(host)

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

    local moveGrip = CreateFrame("Frame", nil, host)
    moveGrip:SetPoint("TOPLEFT", 8, -8)
    moveGrip:SetPoint("TOPRIGHT", -8, -8)
    moveGrip:SetHeight(76)
    moveGrip:SetFrameLevel((host:GetFrameLevel() or 1) + 2)
    moveGrip:EnableMouse(true)
    moveGrip:RegisterForDrag("LeftButton")
    moveGrip:SetScript("OnDragStart", function()
        S.movingWindow = true
        parent:StartMoving()
    end)
    moveGrip:SetScript("OnDragStop", function()
        parent:StopMovingOrSizing()
        S.movingWindow = nil
        SaveWindow(parent)
    end)
    S.moveGrip = moveGrip

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
    S.RegisterFontRoot(tray)

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

    local uiToggle = S.CuteButton(UIParent, 88, 28, "Default UI")
    uiToggle:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -176, -16)
    uiToggle:SetFrameStrata(host:GetFrameStrata())
    uiToggle:SetFrameLevel((host:GetFrameLevel() or 1) + 40)
    uiToggle:SetScript("OnClick", function()
        S.SetCustomUI(not S.customMode)
    end)
    uiToggle:SetScript("OnEnter", function(self)
        Tint(self.bg, C.btnHi)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(S.customMode and "Show Peloria auction house" or "Show qtEasyAuction")
        GameTooltip:Show()
    end)
    uiToggle:SetScript("OnLeave", function(self)
        if not self.locked then Tint(self.bg, C.btn) end
        GameTooltip:Hide()
    end)
    S.uiToggle = uiToggle
    S.RegisterFontRoot(uiToggle)

    local tabBar = CreateFrame("Frame", nil, host)
    tabBar:SetPoint("TOPLEFT", 12, -92)
    tabBar:SetPoint("TOPRIGHT", -12, -92)
    tabBar:SetHeight(36)
    S.tabBg = Fill(tabBar, "BACKGROUND", C.panel)
    S.tabBar = tabBar

    S.tabs = {}
    local specs = {
        { "Deals", "deals" },
        { "Post", "post" },
        { "Auctions", "auctions" },
        { "Stats", "deals" },
        { "Settings" },
    }
    for i, spec in ipairs(specs) do
        local t = S.CuteButton(tabBar, 128, 32, spec[1], spec[2])
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
    S.pages = { deals = Page(), post = Page(), mine = Page(), stats = Page(), settings = Page() }

    local resize = CreateFrame("Button", nil, host)
    Size(resize, 20, 20)
    resize:SetPoint("BOTTOMLEFT", 2, 2)
    resize:SetFrameLevel((host:GetFrameLevel() or 1) + 30)
    resize:RegisterForDrag("LeftButton")
    resize:EnableMouse(true)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    local states = { resize:GetNormalTexture(), resize:GetHighlightTexture(), resize:GetPushedTexture() }
    for i = 1, #states do states[i]:SetTexCoord(1, 0, 0, 1) end
    resize:SetScript("OnDragStart", function()
        S.sizingWindow = true
        parent:StartSizing("BOTTOMLEFT")
    end)
    resize:SetScript("OnDragStop", function()
        parent:StopMovingOrSizing()
        S.sizingWindow = nil
        SaveWindow(parent)
        RefreshLayout()
    end)
    S.resizeGrip = resize

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
    host:SetScript("OnSizeChanged", function()
        if S.sizingWindow then SaveWindow(parent) end
        RefreshLayout()
    end)
    RefreshLayout()
    S.host = host
    S.Apply(S.themeId)
    ApplyDisplayMode(parent)
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
            S.geometryApplied = nil
            local ok, err = pcall(S.Create)
            if not ok then
                print("|cffff5555qtEasyAuction:|r skin error: " .. tostring(err))
            end
        end)
        pcall(parent.HookScript, parent, "OnHide", function()
            if S.customMode then SaveWindow(parent) end
            S.geometryApplied = nil
            parent:SetAlpha(S.nativeAlpha or 1)
            if S.tray then S.tray:Hide() end
            if S.host then S.host:Hide() end
            if S.uiToggle then S.uiToggle:Hide() end
        end)
    end
    if parent:IsShown() then
        local ok, err = pcall(S.Create)
        if not ok then
            print("|cffff5555qtEasyAuction:|r skin error: " .. tostring(err))
        end
    end
end

