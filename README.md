# 📚 Documentation - **disFlip Library & Bot Wrapper**

## Overview

`disFlip` is a Lua library for interacting with the Discord API and Gateway via REST and WebSocket connections.
It supports sending messages, managing channels, reading messages, awaiting new messages, and retrieving guild members.
The `dsBot` wrapper makes bot creation and event handling simpler.

---

## 📦 Library: `lib.lua`

### Constants

* **`userAgent`** - Custom User-Agent for requests.
* **`api`** - Discord REST API base URL.
* **`wss`** - Discord Gateway URL.

---

### Main Table

```lua
_G.disFlip = {}
```

### Functions

#### `disFlip.auth(token, callback)`

Authenticate a bot/user token.

```lua
disFlip.auth(token, function(success, data) end)
```

* **token** - Discord bot/user token.
* **callback** - `(success: boolean, data: table)`
* Fetches the `/users/@me` endpoint.

---

#### `disFlip.sendMessage(token, channel, msg, embed)`

Send a message to a channel.

```lua
disFlip.sendMessage(token, channelId, "Hello", embedTable)
```

* **channel** - Channel ID (string).
* **msg** - Text content (string).
* **embed** - Optional embed table.

---

#### `disFlip.formatEmbed(title, desc, color, footer)`

Create a Discord embed object.

```lua
local embed = disFlip.formatEmbed("Title", "Description", 0xFF0000, "Footer")
```

* Returns a table with `title`, `description`, `color`, `footer`, and `timestamp`.

---

#### `disFlip.createChannel(token, guild, name, category, access)`

Create a text channel.

```lua
disFlip.createChannel(token, guildId, "channel-name", categoryId, accessTable)
```

* **category** - Optional parent category ID.
* **access** - Optional permission overwrites.

---

#### `disFlip.deleteChannel(token, channel)`

Delete a channel.

```lua
disFlip.deleteChannel(token, channelId)
```

---

#### `disFlip.msgRead(token, channel, callback)`

Read messages from a channel.

```lua
local messages = disFlip.msgRead(token, channelId, function(msgs) end)
```

* Returns up to 50 messages.
* **callback** - `(messages: table)`.

---

#### `disFlip.awaitMsg(token, channel, callback)`

Wait for a new message in a channel.

##### ⚠ Warning! It's a legacy function, you shouldn't use it
```lua
disFlip.awaitMsg(token, channelId, function(newMessages) end)
```

* Uses a coroutine and timer to detect new messages.

---

#### `disFlip.getGuildMembers(token, guild, callback)`

Get members and roles from a guild.

```lua
disFlip.getGuildMembers(token, guildId, function(members) end)
```

* Returns a table:

```lua
members[userId] = {
    username = "User#1234",
    roles = {"Admin", "Member"}
}
```

---

### Gateway Helpers

#### `disFlip.startGateway(token, intents)`

Start a WebSocket connection to Discord Gateway.

```lua
local con = disFlip.startGateway(token, intents)
```

* **intents** - bitwise intents mask (see below).
* Returns a WebSocket connection object.

---

#### Intents

Discord Gateway intents control which events your bot receives.
They can be combined using the bitwise OR operator (`+` in Lua):

```lua
local intents = disFlip.intents.GUILD_MESSAGES + disFlip.intents.GUILD_MEMBERS
```

| Intent             | Value      |
| ------------------ | ---------- |
| `GUILDS`           | `2^0`      |
| `GUILD_MEMBERS`    | `2^1`      |
| `GUILD_MODERATION` | `2^2`      |
| `GUILD_MESSAGES`   | `2^9`      |
| `MESSAGE_CONTENT`  | `2^15`     |
| `ALL`              | `56052435` |

Example:

```lua
local intents = disFlip.intents.GUILD_MESSAGES + disFlip.intents.GUILD_MEMBERS
bot:initWss(intents)
```

---

### Gateway Events

When connected via `startGateway`, you can assign hooks to event names:

```lua
con["MESSAGE_CREATE"] = function(data) print(data.content) end
```

Reference for event types: [Discord Gateway Events](https://discord.com/developers/docs/topics/gateway#events)

---

---

## 🤖 Bot Wrapper: `bot.lua`

### Creating a Bot

```lua
local bot = dsBot(token, guildId)
```

* **token** - bot token.
* **guildId** - target guild ID.

---

### Methods

#### `bot:Auth()`

Authenticate the bot.

#### `bot:SendMsg(channel, msg, embed)`

Send a message.

#### `bot:FormatEmbed(title, desc, color, footer)`

Create an embed.

#### `bot:createChannel(name, category, access)`

Create a channel in the guild.

#### `bot:deleteChannel(channel)`

Delete a channel.

#### `bot:ReadMessages(channel, callback)`

Read channel messages.

#### `bot:AwaitMessage(channel, callback)`

Wait for a new message in a channel.

#### `bot:GetGuildMembers(callback)`

Get guild members and roles.

#### `bot:initWss(intents)`

Start gateway connection with intents.

#### `bot:AddHook(eventName, callback)`

Register an event hook.

```lua
bot:AddHook("MESSAGE_CREATE", function(data)
    print(data.content)
end)
```

---

### Example Bot

```lua
local myBot = dsBot("TOKEN_HERE", "GUILD_ID")

myBot:initWss(disFlip.intents.GUILD_MESSAGES + disFlip.intents.GUILD_MEMBERS)

myBot:AddHook("MESSAGE_CREATE", function(data)
    print("New message: " .. data.content)
end)

myBot:SendMsg("CHANNEL_ID", "Hello world!")
```

---

## 📑 References

* [Discord API Docs](https://discord.com/developers/docs/intro)
* [Gateway Intents](https://discord.com/developers/docs/topics/gateway#gateway-intents)
* [Gateway Events](https://discord.com/developers/docs/topics/gateway#events)
* [REST API Reference](https://discord.com/developers/docs/resources/channel)

---

✅ **Tip:**
To combine intents, just sum them:

```lua
local intents = disFlip.intents.GUILD_MESSAGES + disFlip.intents.MESSAGE_CONTENT
```

This way, you don’t need to manually calculate masks.
