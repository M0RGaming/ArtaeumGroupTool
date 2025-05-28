# `Artaeum Group Tool 2.0`

This is an addon which provides utility to players both in Cyrodiil and PvE content where ultimate share addons are used. All features except for the Front Door markers are disabled by default, and more details about each feature can be found below.

## Features

### `Custom Group Frames: Group Data Share`
- This feature is a custom Group Frame UI with support for showing all player's ultimates as well as providing clear visual feedback as to when people can cast ultimates.
- The Group Frames will also show if a player has a shield, trauma, or is running a no healing item/skill similar to base game.
- If a player is camp locked in Cyrodiil, their group frame outline will turn red until they are no longer camp locked.
- If a player in the gorup is holding Volendrung, its current value will be shared with everyone in the group. In addition, players' Stamina and Magicka bars will be shared and have a visual effect on the group frames if enabled.
- On the press of a keybind an 'Assist Ping' is sent, allowing everyone running the addon to get a beam of light where you are. This will also tell you which direction you are respective to the group leader in chat.

### `Crown Arrow`
- A beam of light, crown icon, or downwards arrow will be placed above the group leader, with a blue arrow pointing towards them.

### `Front Doors`
- Places little gate markers at the front door of each keep in Cyrodiil in your map.
- If you right click these markers, a rally point will be set there.

### `Group Location Sharing`
- Uses guild notes to transfer the position of group A's leader to members of other groups.
- The location that is transferred shows up as a beam of light with a 3d arrow pointing towards it (Made using Lib3dArrow)
- Still in beta, and time is set to 10 seconds between transmissions (otherwise you will get kicked for spam)

### `Stay on Crown`
- Will kick pugs if they are not within a forward camp radius of crown for more than 10 (adjustable) minutes
- To toggle, type in /stayoncrown, use the keybind, or use the button in the addon settings page.
- Timeout duration can be set in the addon settings page.
- If a person about to be kicked is part of a specified guild, crown will be notified instead of them being kicked.

### `Discord Invite`
- Will send a message in group chat with a prefilled discord invite
- Both the message and the link itself, can be configured in the addon settings page.
- To activate, type in /addiscord, use the keybind, or use the button in the addon settings page

### Planned:
- Visual notification if in healing range of crown

### Requirements:
- LibAddonMenu2, LibMapPins, LibMapPing, Lib3D, LibGPS, Lib3DArrow, LibGroupCombatStats, LibGroupBroadcast