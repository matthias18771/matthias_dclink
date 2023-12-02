
# matthias_dclink
This resource synchronizes discord permissions to a FiveM server running es_extended or qb-core




## FAQ

#### How do I enable qb-core support?
Set framework to "qbcore" in config.lua - this is the only step needed!

#### How do I set this up?

Here's a video showing exactly how to do that: [Tutorial](https://www.youtube.com/watch?v=ucB-yLmhwN0&ab_channel=RIVAL)

#### Need more help?
Join our discord: [Discord](https://discord.gg/Wt9RRxszJv)


# Exports

## Integrate this into your resources

#### local inGuild, userData = getUserData(discordId)
### Example
```
local donatorRole = "1080602993478615061"

RegisterCommand("hello123", function()
  local src = source
  local discordId = GetPlayerIdentifierByType(src, "discord")
  if discordId ~= nil then
    discordId = discordId:sub(9)
    local inGuild, userData = exports["matthias_dclink"]:getUserData(discordId)
    if inGuild then
      for k,v in pairs(userData.roles) do
        if v == donatorRole then
          print("You are a donator!")
          return
        end
      end
      print("You are not a donator!")
    else
      print("You are not in the guild!")
    end
  else
    print("You don't have a discord account linked!")
  end
end)
```



## Authors

- [@matthias-codes](https://www.github.com/matthias-codes)




## License

[MIT](https://choosealicense.com/licenses/mit/)
