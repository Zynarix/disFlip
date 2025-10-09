dsBot = {}
dsBot.__index = dsBot

local dsBot_mt = {}

function dsBot_mt.__index(_, key)
    if string.find(key, "^p__") then
        return nil
    end
    return dsBot[key]
end

function dsBot_mt.__newindex(_, key, value)
    if string.find(key, "^p__") then
        error("You cannot overwrite bot protected key: " .. key, 2)
    end
    rawset(_, key, value)
end

function dsBot_mt.__call(_, token, guild)
    local self = setmetatable({}, dsBot_mt)
    rawset(self, "p__token", token)
    rawset(self, "guild", guild)
    if self:Auth() then
        print("Bot authorized for guild " .. tostring(guild))
        return self
    else
        error("disFlip bot can't auth()!", 2)
    end
end

function dsBot:Auth()
    local ok = false
    disFlip.auth(self.p__token, function(success, res)
        if success and res then
            ok = true
        else
            print("Auth failed: " .. util.TableToJSON(res))
        end
    end)
    return ok
end

function dsBot:SendMsg(channel, msg, embed)
    disFlip.sendMessage(self.p__token, channel, msg, embed)
end

function dsBot:FormatEmbed(title, desc, color, footer)
    return disFlip.formatEmbed(title, desc, color, footer)
end

function dsBot:createChannel(name, category, access)
    disFlip.createChannel(self.p__token, self.guild, name, category, access)
end

function dsBot:deleteChannel(channel)
    disFlip.deleteChannel(self.p__token, channel)
end

function dsBot:ReadMessages(channel, callback)
    return disFlip.msgRead(self.p__token, channel, callback)
end

function dsBot:AwaitMessage(channel, callback)
    disFlip.awaitMsg(self.p__token, channel, callback)
end

function dsBot:GetGuildMembers(callback)
    disFlip.getGuildMembers(self.p__token, self.guild, callback)
end

function dsBot:initWss(intents)
    self.con = disFlip.startGateway(self.p__token,intents)
end

function dsBot:AddHook(name,callback)
    self.con[name] = callback
end

setmetatable(dsBot, dsBot_mt)