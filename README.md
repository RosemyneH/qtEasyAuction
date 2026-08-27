# qtEasyAuction

> **2.0.0 · Peloria · WoW 3.3.5**

A responsive replacement interface for Peloria's Auction House with weighted deal discovery, score-based posting, auction management, sales tracking, bulk buying, and configurable themes.

## What's new

### Deal filtering

- Deals below a configurable **Gold value** score are hidden by default.
- The default threshold is **30 score per gold**.
- The filter can be toggled or edited immediately from Settings.
- Duplicate item-level deals are collapsed to their best listing.

### Seller controls

- Alt-right-click a deal row or its Buy button to hide that seller.
- A confirmation appears above the custom Auction House frame.
- Hidden sellers can be restored individually or all at once.

### Typography

- The font picker is now a themed dropdown.
- Each option previews its own font face.
- Mouse-wheel and draggable scrollbar navigation are supported.
- Font size is adjustable from 80% to 130%.

### Scoring accuracy

- Random-affix bag items use their real item links when scored.
- Suffix stats now resolve reliably for items such as “of the Tiger.”
- Existing mythic scaling and Post weights remain intact.

### Bulk buying

- Listings are sent at a configurable interval, defaulting to 0.05 seconds.
- Server results continue arriving while the queue advances.
- Mass-buy confirmation can be enabled or disabled.
- Progress reports sent, bought, total, and available gold.

### Interface polish

- The custom window is movable, resizable, and resettable.
- Layouts adapt to the available window dimensions.
- The Easy UI / Default UI toggle aligns with the header controls.
- Typography applies consistently to dialogs and overlays.

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
