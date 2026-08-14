# qtEasyAuction

Auto-post items to Peloria Auction House with intelligent soulbind filtering.

## Features

- **Soulbind Filtering**: Only posts items you would normally sell
  - Skips items already soulbound
  - Skips items your class cannot soulbind
  - Skips legendary items (quality 5+)
  
- **Auto-Post Button**: Convenient button in top-right of Peloria AH frame
- **One-Click Operation**: Click "Auto Post" to start, click again to stop
- **Safe & Controlled**: 1-second delay between posts

## Installation

1. Copy the `qtEasyAuction` folder to `Interface\AddOns\`
2. Restart WoW or reload UI (`/reload`)
3. Enable the addon in character select

## Usage

1. Open the Peloria Auction House
2. Click the "Auto Post" button in the top-right corner
3. The addon will automatically post sellable items from your bags
4. Click "STOP" to halt posting at any time

## How It Works

The addon scans your bags and checks each item's tooltip for:
- "Already Soulbound" - skips these
- "Class Cannot Soulbind" - skips these  
- "Soulbind Available" - posts these
- Legendary quality - skips these

Only items that would normally be sold are posted to the auction house.

## Version

1.0.0 - Initial release
