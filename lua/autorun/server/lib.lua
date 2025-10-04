require("reqwest")
--require("gwsockets")

local userAgent = "DisFlip (By Zynarix, 1.0)"
local api = "https://discord.com/api/v10"

if not reqwest then
    return print("reqwest.dll not found")
end

local disFlip = {}

-- Helper
local function request(token, opts)
    opts.headers = opts.headers or {}
    opts.headers["Authorization"] = token
    opts.headers["User-Agent"] = userAgent

    if opts.body and type(opts.body) == "table" then
        opts.body = util.TableToJSON(opts.body)
        opts.type = "application/json"
    end

    reqwest(opts)
end

-- @ param callback function(success: bool, data: table)
function disFlip.auth(token, callback)
    request(token, {
        blocking = true,
        method = "GET",
        url = api .. "/users/@me",
        success = function(status, body)
            local data = util.JSONToTable(body)
            if callback then callback(true, data) end
        end,
        failed = function(err, errExt)
            print("Auth error: " .. err .. " (" .. errExt .. ")")
            if callback then callback(false, { error = errExt }) end
        end
    })
end

-- @ param channel id MUST be a STRING
-- @ param msg string
-- @ param embed table
function disFlip.sendMessage(token, channel, msg, embed)
    local payload = {}
    if msg then payload.content = tostring(msg) end
    if embed then payload.embeds = { embed } end

    request(token, {
        method = "POST",
        url = api .. "/channels/" .. tostring(channel) .. "/messages",
        body = payload,
        success = function(status, body)
            print("Message sent! HTTP " .. status)
            print(body)
        end,
        failed = function(err, errExt)
            print("Send error: " .. err .. " (" .. errExt .. ")")
        end
    })
end

-- @ param title string
-- @ param desc string
-- @ param color int
-- @ param footer string
function disFlip.formatEmbed(title, desc, color, footer)
    local embed = {}
    if title then embed.title = tostring(title) end
    if desc then embed.description = tostring(desc) end
    if color then embed.color = tonumber(color) end
    if footer then embed.footer = { text = tostring(footer) } end
    embed.timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    return embed
end

-- Create channel
function disFlip.CreateChannel(token, guild, name, category, access)
    request(token, {
        method = "POST",
        url = api .. "/guilds/" .. guild .. "/channels",
        body = {
            name = tostring(name),
            type = 0,
            parent_id = tostring(category),
            permission_overwrites = access or {}
        },
        success = function(status, body)
            print("Channel created! HTTP " .. status)
            print(body)
        end,
        failed = function(err, errExt)
            print("Create channel error: " .. err .. " (" .. errExt .. ")")
        end
    })
end

-- Delete channel
function disFlip.deleteChannel(token, channel)
    request(token, {
        method = "DELETE",
        url = api .. "/channels/" .. tostring(channel),
        success = function(status, body)
            print("Channel deleted! HTTP " .. status)
            print(body)
        end,
        failed = function(err, errExt)
            print("Delete channel error: " .. err .. " (" .. errExt .. ")")
        end
    })
end

-- Read messages
function disFlip.msgRead(token, channel, callback)
    local ret = {}
    request(token, {
        blocking = true,
        method = "GET",
        url = api .. "/channels/" .. tostring(channel) .. "/messages?limit=50",
        success = function(status, body)
            local messages = util.JSONToTable(body) or {}
            ret = messages
            if callback then callback(messages) end
        end,
        failed = function(err, errExt)
            print("Read messages error: " .. err .. " (" .. errExt .. ")")
        end
    })
    return ret or {}
end

-- Await new message
function disFlip.awaitMsg(token, chan, callback)
    local msgs = disFlip.msgRead(token, chan)
    local co = coroutine.create(function()
        while true do
            local t = disFlip.msgRead(token, chan)
            if #t > #msgs then
                for i = 1, #msgs do
                    table.remove(t, 1)
                end
                callback(t)
                return true -- завершить
            end
            coroutine.yield()
        end
    end)

    local ct = tostring(math.Round(CurTime(), 0))
    timer.Create("disFlipMsgAwait" .. chan .. ct, 1, 0, function()
        if coroutine.resume(co) then
            timer.Remove("disFlipMsgAwait" .. chan .. ct)
        end
    end)
end

-- Get guild members
function disFlip.getGuildMembers(token, guild, callback)
    request(token, {
        blocking = true,
        method = "GET",
        url = api .. "/guilds/" .. guild .. "/members?limit=1000",
        success = function(status, body)
            local members = util.JSONToTable(body) or {}

            request(token, {
                blocking = true,
                method = "GET",
                url = api .. "/guilds/" .. guild .. "/roles",
                success = function(status2, body2)
                    local roles = util.JSONToTable(body2) or {}
                    local roleMap = {}

                    for _, role in ipairs(roles) do
                        roleMap[role.id] = role.name
                    end

                    local result = {}
                    for _, member in ipairs(members) do
                        local user = member.user
                        local userRoles = {}
                        for _, rid in ipairs(member.roles) do
                            table.insert(userRoles, roleMap[rid] or rid)
                        end
                        result[user.id] = {
                            username = user.username .. "#" .. user.discriminator,
                            roles = userRoles
                        }
                    end

                    if callback then callback(result) end
                end,
                failed = function(err, errExt)
                    print("Roles error: " .. err .. " (" .. errExt .. ")")
                end
            })
        end,
        failed = function(err, errExt)
            print("Members error: " .. err .. " (" .. errExt .. ")")
        end
    })
end

_G.disFlip = disFlip