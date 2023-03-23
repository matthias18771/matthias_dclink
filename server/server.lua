local requestHeaders = {
    ["Authorization"] = "Bot " .. RIVAL.botToken,
    ["Content-Type"] = "application/json",
    ["User-Agent"] = "rival_dclink v1.0"
}

local adaptiveCardTemplate = {
    type = "AdaptiveCard",
    body = {
        {
            type = "TextBlock",
            size = "Medium",
            weight = "Bolder",
            text = ""
        },
        {
            type = "TextBlock",
            text = "",
            wrap = true
        }
    },
    ["$schema"] = "http://adaptivecards.io/schemas/adaptive-card.json",
    ["version"] =  "1.0"
}

function copyTable(table)
    local newTable = {}
    for k,v in pairs(table) do
        if type(v) == "table" then
            newTable[k] = copyTable(v)
        else
            newTable[k] = v
        end
    end
    return newTable
end

RegisterNetEvent("playerConnecting", function(playerName, setKickReason, deferrals)
    deferrals.defer()

    local discordId = GetPlayerIdentifierByType(source, "discord")
    local licenseId = GetPlayerIdentifierByType(source, "license")
    if discordId ~= nil then
        discordId = discordId:sub(9)
        licenseId = licenseId:sub(9)
        PerformHttpRequest(("https://discord.com/api/v10/guilds/%s/members/%s"):format(RIVAL.guildId, discordId), function(status, body, headers)
            if body ~= nil then
                local userData = json.decode(body)
                local card = copyTable(adaptiveCardTemplate)
                card.body[1].text = RIVAL.locales.welcomeBack:format(userData.user.username, userData.user.discriminator)
                card.body[2].text = RIVAL.locales.deferMessage
                deferrals.presentCard(card)
                for k,v in pairs(RIVAL.roles) do
                    for i=1, #userData.roles do
                        if userData.roles[i] == v.roleId then
                            MySQL.Async.execute("UPDATE users SET `group` = @group WHERE `identifier` = @identifier", {
                                group = v.groupName,
                                identifier = licenseId
                            }, function()
                                card.body[2].text = (RIVAL.locales.authenticatedAsGroup):format(v.label)
                                deferrals.presentCard(card)
                                Wait(2000)
                                deferrals.done()
                            end)
                            return
                        end
                    end
                end
                if RIVAL.enforceDiscordPermissions then
                    MySQL.Async.execute("UPDATE users SET `group` = @group WHERE `identifier` = @identifier", {
                        group = "user",
                        identifier = licenseId
                    }, function()
                        deferrals.done()
                    end)
                else
                    deferrals.done()
                end
            else
                local card = copyTable(adaptiveCardTemplate)
                table.remove(card.body, 1)
                card.body[1].text = RIVAL.locales.notInGuild
                deferrals.presentCard(card)
                Wait(2000)
                deferrals.done()
            end
        end, "GET", "", requestHeaders)
    else
        local card = copyTable(adaptiveCardTemplate)
        table.remove(card.body, 1)
        card.body[1].text = RIVAL.locales.discordNotFound
        deferrals.presentCard(card)
        Wait(2000)
        deferrals.done()
    end
end)

CreateThread(function()
    -- Config check on startup (this validated that the guildId, botToken and roles have been configurated properly)
    log("Requesting roles from guild...")
    PerformHttpRequest(("https://discord.com/api/v10/guilds/%s/roles"):format(RIVAL.guildId), function(status, body, headers)
        if status == 200 then
            local error = false
            log("Successfully requested roles from guild! Checking configurated roles...")
            local roles = json.decode(body)
            for k,v in pairs(RIVAL.roles) do
                for i=1, #roles do
                    if roles[i].id == v.roleId then
                        goto continue
                    end
                end
                error = true
                log("Invalid role: " .. v.roleId)
                ::continue::
            end

            if error then
                log("It seems like there is a misconfiguration regarding roles - please review it.")
            else
                log("Configuration valid. Have fun!")
            end
        else
            log("Failed to request roles from guild! Check your config (guildId & botToken) and make sure the bot is on the specified guild.")
            log("Script exiting. Configure the script and start again.")
            os.exit()
        end
    end, "GET", "", requestHeaders)
end)

function log(msg)
    print(("^9[^5rival_dclink^9] ^0%s"):format(msg))
end