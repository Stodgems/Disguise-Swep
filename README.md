# Disguiser - Garry's Mod Addon

## Features

- **Complete Identity Masking**: Copy another player's model, name, and player color
- **Toggle System**: Set a disguise target and toggle it on/off at will
- **Custom Name Handler**: Built-in name overlay system that changes your displayed name everywhere in the game
- **Configurable Settings**: Extensive configuration options for customization
- **Team Blacklist**: Prevent players from disguising as certain teams (e.g., Police, Admins)
- **Range Limitation**: Configurable distance requirement for targeting players
- **Smart Cleanup**: Automatic disguise removal on death, disconnect, or weapon removal
- **Custom Chat Messages**: Color-coded chat notifications with configurable prefix
- **Clean UI**: Minimalist HUD showing disguise status and target

## Installation

1. Download or clone this repository
2. Place the `disguiser` folder in your `garrysmod/addons/` directory
3. Restart your server or type `lua_refresh` in console
4. The weapon will be available in the Roleplay category

## How to Use

### Basic Controls

- **Left Click**: Select a player to disguise as (must be within range and aiming at them)
- **Right Click**: Toggle your disguise on/off

### Workflow

1. Equip the Disguiser weapon
2. Aim at a player and left-click to set them as your disguise target
3. Right-click to activate the disguise (you'll transform into them)
4. Right-click again to deactivate and return to your original appearance
5. Left-click on a different player to change your disguise target (works even while disguised)

### UI Display

When holding the disguiser, a panel appears on the right side showing:
- **Status**: ACTIVE (green) or INACTIVE (red)
- **Target**: The player you've selected to disguise as
- **Instructions**: Helpful hints when no target is set

## Configuration

Edit the configuration file at: `disguiser/lua/autorun/disguiser_config.lua`

### Available Settings

#### Chat Prefix
Customize the prefix shown in chat messages:
```lua
Disguiser.Config.ChatPrefix = "Disguiser"
```

#### Target Range
Maximum distance (in units) to target a player:
```lua
Disguiser.Config.TargetRange = 1000  -- Default: 150
```

#### Blacklisted Teams
Prevent disguising as specific teams:
```lua
Disguiser.Config.BlacklistedTeams = {
    TEAM_POLICE,
    TEAM_MAYOR,
    TEAM_CHIEF,
}
```

**Finding Team IDs:**
- Use console command: `lua_run PrintTable(RPExtraTeams)`
- Check your DarkRP `jobs.lua` file for team definitions
