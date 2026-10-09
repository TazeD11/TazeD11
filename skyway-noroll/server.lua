local players = {}
local total = 0

local function getLicense(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 8) == 'license:' then
            return id
        end
    end
    return 'neznámé'
end

local function log(...)
    if Config.Debug then
        print('[skyway-noroll]', ...)
    end
end

local function sendWebhook(src, count)
    local hook = Config.Webhook
    if not hook.enabled or hook.url == '' then return end
    if count % hook.everyNth ~= 0 then return end

    local payload = {
        username = hook.username,
        embeds = {
            {
                title = 'Pokus o kotoul',
                color = hook.color,
                fields = {
                    { name = 'Hráč', value = ('%s (ID %d)'):format(GetPlayerName(src) or '?', src), inline = true },
                    { name = 'Počet zmrazení', value = tostring(count), inline = true },
                    { name = 'Licence', value = getLicense(src), inline = false },
                },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
            },
        },
    }

    PerformHttpRequest(hook.url, function() end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json',
    })
end

RegisterNetEvent('skyway-noroll:attempt', function()
    local src = source
    local now = GetGameTimer()
    local data = players[src]

    if not data then
        data = { last = 0, count = 0, rejected = 0 }
        players[src] = data
    end

    local minGap = Config.FreezeTime + Config.Cooldown - Config.Server.tolerance

    if now - data.last < minGap then
        data.rejected = data.rejected + 1
        log('zamítnuto', src, data.rejected)
        return
    end

    data.last = now
    data.count = data.count + 1
    total = total + 1

    TriggerClientEvent('skyway-noroll:freeze', src, Config.FreezeTime, data.count)

    if Config.Server.consoleLog then
        print(('[skyway-noroll] %s (ID %d) zmrazen, celkem %dx'):format(GetPlayerName(src) or '?', src, data.count))
    end

    sendWebhook(src, data.count)
end)

AddEventHandler('playerDropped', function()
    players[source] = nil
end)

RegisterCommand('norollstats', function(src)
    local lines = { ('[skyway-noroll] celkem zmrazení: %d'):format(total) }

    for id, data in pairs(players) do
        lines[#lines + 1] = ('  ID %d (%s): %dx, zamítnuto %dx'):format(id, GetPlayerName(id) or '?', data.count, data.rejected)
    end

    local text = table.concat(lines, '\n')

    if src == 0 then
        print(text)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { 'NoRoll', text } })
    end
end, true)

exports('GetFreezeCount', function(src)
    local data = players[src]
    return data and data.count or 0
end)

exports('GetTotalFreezes', function()
    return total
end)
