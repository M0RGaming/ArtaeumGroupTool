-- Discord Invite Module
local AD = ArtaeumGroupTool
AD.Discord = {}
local discord = AD.Discord
local vars = {}

function discord.setDiscord(link)
	vars.discordLink = link
	d("Discord link set: "..vars.discordLink)
end

function discord.setDiscordInv(invite)
	vars.discordInvite = invite
	d("Discord Invite Message set: "..vars.discordInvite)
end

function discord.sendDiscord()
	local channel = CHAT_CHANNEL_PARTY
	local target = nil
	local message = vars.discordInvite.." "..vars.discordLink
	CHAT_SYSTEM:StartTextEntry(message, channel, target)
end


function discord.init()
	vars = ArtaeumGroupTool.vars.Discord
end


-- Register slash commands and keybinds
ZO_CreateStringId("SI_BINDING_NAME_ARTAEUMGROUPTOOL_SEND_DISCORD", "Send Discord Message")
SLASH_COMMANDS["/addiscord"] = discord.sendDiscord