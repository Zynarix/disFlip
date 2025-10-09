require("reqwest")
require("gwsockets")

local userAgent = "DisFlip (https://github.com/Zynarix/disFlip/, 1.0)"
local api = "https://discord.com/api/v10"
local wss = "wss://gateway.discord.gg/?v=10&encoding=json"

if not reqwest then
    return print("reqwest.dll not found")
end

if not GWSockets then
    return print("gwsockets.dll not found")
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
function disFlip.createChannel(token, guild, name, category, access)
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

-- Gateways and etc.

local op = {
    dispatch = 0,
    heartbeat = 1,
    identify = 2,
    presenceUpdate = 3,
    voiceUpdate = 4,
    resume = 6,
    reconnect = 7,
    requestGuildMembers = 8,
    invalidSession = 9,
    hello = 10,
    heartbeatAck = 11,
    unkerr = 4000,
    unknownOp = 4001,
    decodeErr = 4002,
    notAuthenticated = 4003,
    authFailed = 4004,
    alreadyAuthenticated = 4005,
    invalidSeq = 4007,
    rateLimited = 4008,
    sessionTimedOut = 4009,
    invalidShard = 4010,
    shardingRequired = 4011,
    invalidAPIVersion = 4012,
    invalidIntents = 4013,
    disallowedIntents = 4014
}

local intents = {
    GUILDS = 2^0,
    GUILD_MEMBERS = 2^1,
    GUILD_MODERATION = 2^2,
    GUILD_EXPRESSIONS = 2^3,
    GUILD_INTEGRATIONS = 2^4,
    GUILD_WEBHOOKS = 2^5,
    GUILD_INVITES = 2^6,
    GUILD_VOICE_STATES = 2^7,
    GUILD_PRESENCES = 2^8,
    GUILD_MESSAGES = 2^9,
    GUILD_MESSAGE_REACTIONS = 2^10,
    GUILD_MESSAGE_TYPING = 2^11,
    DIRECT_MESSAGES = 2^12,
    DIRECT_MESSAGE_REACTIONS = 2^13,
    DIRECT_MESSAGE_TYPING = 2^14,
    MESSAGE_CONTENT = 2^15,
    GUILD_SCHEDULED_EVENTS = 2^16,
    AUTO_MODERATION_CONFIGURATION = 2^20,
    AUTO_MODERATION_EXECUTION = 2^21,
    GUILD_MESSAGE_POLLS = 2^24,
    DIRECT_MESSAGE_POLLS = 2^25,
    ALL = 56052435
}

function disFlip.formGatewayMsg(op, data)
    if not data then
        return util.TableToJSON({ op = op })
    end
    return util.TableToJSON({ op = op, d = data })
end

function disFlip.startGateway(token, ints)
    local con = GWSockets.createWebSocket(wss)
    con.hbint = 0
    con.sid = nil
    con.resu = ""
    con.seq = 0
    con.callback = {}

    con:setHeader("User-Agent", userAgent)

    function con:onConnected()
        print("[DisFlip] Connected to Discord Gateway")
    end

    function con:onDisconnected(errCode, errStr)
        print("[DisFlip] Disconnected: " .. tostring(errCode) .. " (" .. tostring(errStr) .. ")")
        timer.Remove("DisFlipHB_" .. (self.sid or "nil"))
    end

    function con:onMessage(msg)
        local data = util.JSONToTable(msg)
        if not data or not data.op then return end

        local opc = tonumber(data.op)
        local t = data.d

        if opc == op.hello then
            if not t or not t.heartbeat_interval then return end
            self.hbint = t.heartbeat_interval / 1000

            timer.Simple(self.hbint * math.Rand(0.1, 0.8), function()
                if not self:IsValid() then return end

                self:write(disFlip.formGatewayMsg(op.heartbeat, { s = nil }))
                timer.Simple(0.05, function()
                    if not self:IsValid() then return end

                    self:write(disFlip.formGatewayMsg(op.identify, {
                        token = token,
                        properties = {
                            os = system.IsWindows() and "windows" or "linux",
                            browser = "DisFlip",
                            device = "DisFlip",
                        },
                        large_threshold = 250,
                        intents = ints or intents.ALL
                    }))
                end)

                local tid = "DisFlipHB_" .. string.sub(token, 1, 8)
                timer.Create(tid, self.hbint, 0, function()
                    if not self:IsValid() then timer.Remove(tid) return end
                    self:write(disFlip.formGatewayMsg(op.heartbeat, { s = self.seq }))
                end)
            end)

        elseif opc == op.heartbeat then
            self:write(disFlip.formGatewayMsg(op.heartbeat, { s = self.seq }))

        elseif opc == op.dispatch then
            self.seq = data.s
            self.sid = (t and t.session_id) or self.sid
            self.resu = (t and t.resume_gateway_url) or self.resu

            if data.t and self.callback[data.t] then
                self.callback[data.t](t)
            end

        elseif opc == op.invalidSession then
            self:close()
            error("[DisFlip] Invalid session")

        elseif opc == op.invalidIntents then
            self:close()
            error("[DisFlip] Invalid intents. Check https://discord.com/developers/docs/topics/gateway#gateway-intents")

        elseif opc == op.sessionTimedOut then
            print("[DisFlip] Session timed out. Reconnecting...")
            self:close()
            disFlip.startGateway(token, ints)
        end
    end

    con:connect()
    return con
end


_G.disFlip = disFlip