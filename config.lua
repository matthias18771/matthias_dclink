RIVAL = {
    framework = "esx", -- can be "qbcore" or "esx"
    botToken = "",
    guildId = "",
    enforceDiscordPermissions = true, -- This will enforce discord permission (player joins on the server, has superadmin in database, but no roles in guild, means he gets set to "user")
    roles = { -- this needs to be in the right order (higher ranks -> higher priority)
        -- {
        --     roleId = "1088140932332925053",
        --     groupName = "projektleitung",
        --     label = "Projektleitung"
        -- },
    },
    locales = {
        notInGuild = "You haven't joined our guild - permission roles won't be synchronized!\nJoin our discord at https://discord.gg/rivalstudios",
        discordNotFound = "We couldn't find a discord identifier on your account. Permissions roles won't be synchronized until you fix this",
        authenticatedAsGroup = "Authenticated as %s",
        deferMessage = "Looking up your roles. This won't take long...",
        welcomeBack = "Welcome back, %s#%s",
    }
}