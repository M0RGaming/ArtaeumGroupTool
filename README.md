# `Artaeum Group Tool 2.0`

This is an addon meant to provide Cyrodiil based PvP groups with tools to help them out. All features except for the Front Door markers are disabled by default.

## Features

### `Group Data Share`
- This module shares data between members in a party, such as what ult they have slotted, what percent their ult is at, and more, such as if they are camp locked.
- In addition, Volendrung's bar is also sent and so is the user's Stamina and Magicka bars.
- Finally, an 'Assist Ping' is also sent, which allows everyone running the addon to get a beam of light where you are at the press of a keybind. This will also tell you which direction you are to the crown.

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

### Coming Soon:
- Visual notification if in healing range of crown

### Requirements:
- LibAddonMenu2, LibMapPins, LibMapPing, Lib3D, LibGPS, Lib3DArrow