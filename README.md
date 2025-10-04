# disFlip

**disFlip** is a Lua library for interacting with the Discord API.  
It allows you to authenticate a bot, send messages, manage channels, and work with guild members.

---

## 📌 API Reference

* **`dsBot(token, guild)`** → returns a bot object
* **`dsBot:Auth()`** — checks token validity
* **`dsBot:SendMsg(channel, msg, embed)`** — sends a message
* **`dsBot:FormatEmbed(title, desc, color, footer)`** — creates a basic embed table
* **`dsBot:CreateChannel(name, category, access)`** — creates a new channel
* **`dsBot:DeleteChannel(channel)`** — deletes a channel
* **`dsBot:ReadMessages(channel, callback)`** — reads all messages and calls the callback with a table
* **`dsBot:AwaitMessage(channel, callback)`** — awaits a new message (work in progress)
* **`dsBot:GetGuildMembers(callback)`** — calls the callback with all guild members

---

## 📖 Usage

### Create and authenticate a bot
```lua
local bot = dsBot("TOKEN", "GUILD_ID")
bot:Auth() -- checks if the token is valid
````

### Send a message

```lua
bot:SendMsg("CHANNEL_ID", "Hello, Discord!")
```

### Send an embed message

```lua
local embed = bot:FormatEmbed(
    "Title",
    "Description",
    "0x00FF00", -- color in HEX
    "Footer text"
)

bot:SendMsg("CHANNEL_ID", "Message with embed", embed)
```

### Create a channel

```lua
bot:CreateChannel("new-channel", "category", 0) 
-- see Discord documentation for access/permissions details
```

### Delete a channel

```lua
bot:DeleteChannel("CHANNEL_ID")
```

### Read messages

```lua
bot:ReadMessages("CHANNEL_ID", function(messages)
    PrintTable(messages) -- prints all messages
end)
```

### Await a message (WIP)

```lua
bot:AwaitMessage("CHANNEL_ID", function(message)
    print("New message: ", message.content)
end)
```

### Get guild members

```lua
bot:GetGuildMembers(function(members)
    PrintTable(members)
end)
```

---

## ⚠️ Notes

* Check the [official Discord API documentation](https://discord.com/developers/docs/intro) for details about permissions and advanced usage.
* Some methods are still under development.
