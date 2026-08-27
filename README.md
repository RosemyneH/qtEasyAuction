# qtEasyAuction

> **2.0.0 · Peloria · WoW 3.3.5**

A responsive replacement interface for Peloria's Auction House with weighted deal discovery, score-based posting, auction management, sales tracking, bulk buying, and configurable themes.

## 2.0.0 highlights

### Configurable deal discovery

- Filter deals by a configurable minimum **Gold value**, defaulting to 30 score per gold.
- Collapse duplicate item-level deals to the best available listing.
- Hide individual sellers with Alt-right-click and restore them from Settings.
- Search, re-scan, sort, inspect, and bulk-select current listings.

### Score-based posting

- Score eligible bag items with configurable stat weights.
- Calculate buyouts from a target Gold value or fixed price.
- Pin manual price overrides, ignore unwanted items, and post all ready listings.

### Managed bulk buying

- Queue selected listings at a configurable request interval.
- Review total cost and score gain before confirming a mass purchase.
- Follow sent, purchased, total, and available-gold progress.

### Custom interface

- Choose from multiple themes and switch between Easy UI and Peloria's default UI.
- Move, resize, and reset the Auction House window.
- Select a shared-media font from a themed preview dropdown.
- Adjust interface text from 80% to 130%.
- Use responsive Deals, Post, Auctions, Stats, and Settings layouts.

## Fixes included in 2.0.0

These correct behavior found during the Beta 2 and Beta 3 cycle; they are not separate addon features.

- Random-affix bag items are scored from their real item links so suffix stats resolve correctly.
- Mythic stat scaling uses bounded, coherent item data.
- Seller-hide confirmation responds across the deal row and Buy cell and appears above the custom frame.
- The font dropdown displays its options above the menu background.
- Font preview paths and rows are cached to prevent lag while scrolling.
- The font list includes a draggable scrollbar and follows the expected wheel direction.
- Bulk buying advances independently of delayed server results while retaining accurate progress.
- Dialogs and overlays consistently inherit the selected typography.
- Responsive row counts prevent hidden-seller lists from overflowing smaller windows.

## Main features

### Deals

Search and re-scan current listings, compare weighted soulbind scores, inspect score-per-gold value, sort columns, buy individual listings, or select a range for bulk purchase.

### Post

Score eligible bag items, calculate buyouts from either a target Gold value or fixed price, pin manual overrides, ignore items, and post all ready listings.

### Auctions

Search active auctions, view time remaining and buyout values, unlist one auction, or confirm removal of matching or all auctions.

### Stats

Track confirmed Auction House gold in and out, recent activity, daily totals, lifetime totals, sold counts, and purchase counts.

## Settings

| Setting | Default | Purpose |
| --- | --- | --- |
| Buy interval | 0.05 seconds | Delay between queued bulk-buy requests. |
| Confirm mass buys | Enabled | Shows cost and score gain before buying a selection. |
| Hide duplicate item levels | Enabled | Keeps the best score-per-gold listing for each item and mythic level. |
| Hide Gold value under | Enabled at 30 | Removes deals whose weighted score per gold is below the threshold. |
| Font | Default | Selects a font supplied by LibSharedMedia when available. |
| Font size | 100% | Scales text throughout the custom interface. |

## Controls

- **Alt + right-click:** Confirm hiding every deal from a seller.
- **Shift + right-drag:** Select a deal range for bulk buying.
- **Right-click a Post item:** Add that item to the posting ignore list.
- **Right-click the Score heading:** Retry items with missing scores.
- **Drag the header:** Move the custom Auction House window.
- **Drag the lower-left grip:** Resize the window.

## Installation

1. Place both `qtEasyAuction` and `qtEasyAuctionUI` in `Interface/AddOns`.
2. Optionally install `LibSharedMedia-3.0` for additional font choices.
3. Enable qtEasyAuction and open Peloria's Auction House.

The UI module is load-on-demand and activates when the Peloria Auction House opens. Account-wide filters and per-character appearance and pricing preferences are saved automatically.

## Commands

| Command | Action |
| --- | --- |
| `/qta` or `/qtauction` | Shows available commands. |
| `/qta gold` | Prints today's and lifetime Auction House totals. |
| `/qta goldreset` | Clears the character's Auction House gold history. |
| `/qta clearignore` | Clears the posting ignore list. |
| `/qta test` | Prints addon and Peloria integration diagnostics. |
| `/qta skin` | Attempts to attach and recreate the custom skin. |

## Compatibility

- World of Warcraft client interface: `30300`.
- Designed specifically for Peloria's custom Auction House APIs and packets.
- Current addon version: `2.0.0`.
