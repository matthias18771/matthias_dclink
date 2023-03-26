local assignedGroup = {}

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
    local card = copyTable(adaptiveCardTemplate)
    if discordId ~= nil then
        discordId = discordId:sub(9)
        licenseId = licenseId:sub(9)
        local inGuild, userData = getUserData(discordId)
        if inGuild then
            card.body[1].text = RIVAL.locales.welcomeBack:format(userData.user.username, userData.user.discriminator)
            card.body[2].text = RIVAL.locales.deferMessage
            deferrals.presentCard(card)
            for k,v in pairs(RIVAL.roles) do
                for i=1, #userData.roles do
                    if userData.roles[i] == v.roleId then
                        if RIVAL.framework == "esx" then
                            MySQL.Async.execute("UPDATE users SET `group` = @group WHERE `identifier` = @identifier", {
                                group = v.groupName,
                                identifier = licenseId
                            }, function()
                                card.body[2].text = (RIVAL.locales.authenticatedAsGroup):format(v.label)
                                deferrals.presentCard(card)
                                Wait(2000)
                                deferrals.done()
                            end)
                        elseif RIVAL.framework == "qbcore" then
                            if assignedGroup[licenseId] then
                                ExecuteCommand(("remove_principal identifier.license:%s qbcore.%s"):format(licenseId, assignedGroup[licenseId]))
                            end
                            assignedGroup[licenseId] = v.groupName
                            ExecuteCommand(("add_principal identifier.license:%s qbcore.%s"):format(licenseId, assignedGroup[licenseId]))
                            card.body[2].text = (RIVAL.locales.authenticatedAsGroup):format(v.label)
                            deferrals.presentCard(card)
                            Wait(2000)
                            deferrals.done()
                        end
                        return
                    end
                end
            end
            if RIVAL.enforceDiscordPermissions and RIVAL.framework == "esx" then
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
            table.remove(card.body, 1)
            card.body[1].text = RIVAL.locales.notInGuild
            deferrals.presentCard(card)
            Wait(2000)
            deferrals.done()
        end
    else
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
        elseif status == 429 then
            log("Failed to request roles from guild! This error occurs because discord rate-limited you - this happens when you have lots of applications that send too much requests to the api.")
        else
            log("Failed to request roles from guild! Check your config (guildId & botToken) and make sure the bot is on the specified guild.")
        end
    end, "GET", "", requestHeaders)
end)

function log(msg)
    print(("^9[^5rival_dclink^9] ^0%s"):format(msg))
end

function getUserData(discordId)
    local isInGuild = false
    local userData
    PerformHttpRequest(("https://discord.com/api/v10/guilds/%s/members/%s"):format(RIVAL.guildId, discordId), function(status, body, headers)
        if body ~= nil then
            isInGuild = true
            userData = json.decode(body)
        else
            userData = {}
        end
    end, "GET", "", requestHeaders)

    while userData == nil do
        Wait(0)
    end
    return isInGuild, userData
end

exports("getUserData", getUserData)