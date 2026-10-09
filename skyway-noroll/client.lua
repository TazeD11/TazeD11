local state = {
    frozen = false,
    pending = false,
    pendingUntil = 0,
    frozenAt = 0,
    frozenUntil = 0,
    duration = Config.FreezeTime,
    cooldownUntil = 0,
}

local MELEE_GROUP = 2685387236

local function log(...)
    if Config.Debug then
        print('[skyway-noroll]', ...)
    end
end

local function notify(count, duration)
    local cfg = Config.Notify
    if not cfg.enabled then return end

    local message = Config.Locale.frozen
    local shown = cfg.syncWithFreeze and (duration + cfg.extraTime) or cfg.duration

    if cfg.mode == 'nui' then
        SendNUIMessage({
            action = 'notify',
            title = Config.Locale.title,
            message = message,
            counter = cfg.showCounter and Config.Locale.counter:format(count) or '',
            duration = shown,
            freeze = duration,
            position = cfg.position,
            accent = cfg.accent,
            seconds = Config.Locale.seconds,
        })
    elseif cfg.mode == 'ox_lib' then
        exports.ox_lib:notify({ description = message, type = 'error', duration = shown })
    elseif cfg.mode == 'qb' then
        TriggerEvent('QBCore:Notify', message, 'error', shown)
    elseif cfg.mode == 'esx' then
        TriggerEvent('esx:showNotification', message)
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, false)
    end
end

local function hideNotify()
    if Config.Notify.mode == 'nui' then
        SendNUIMessage({ action = 'hide' })
    end
end

local function isAiming()
    return IsPlayerFreeAiming(PlayerId()) or IsControlPressed(0, 25)
end

local function canBeFrozen(ped)
    if IsEntityDead(ped) then return false end
    if IsPedRagdoll(ped) or IsPedFalling(ped) or IsPedSwimming(ped) then return false end
    if IsPedClimbing(ped) or IsPedInParachuteFreeFall(ped) or IsPedGettingUp(ped) then return false end
    if Config.DisableInVehicle and IsPedInAnyVehicle(ped, false) then return false end
    return true
end

local function hasValidWeapon(ped)
    if not Config.RequireWeapon then return true end

    local _, weapon = GetCurrentPedWeapon(ped, true)

    if Config.IgnoredWeapons[weapon] then return false end
    if Config.OnlyFirearms and GetWeapontypeGroup(weapon) == MELEE_GROUP then return false end

    return IsPedArmed(ped, 4)
end

local function isActive(ped)
    if IsEntityDead(ped) then return false end
    if Config.DisableInVehicle and IsPedInAnyVehicle(ped, false) then return false end
    if state.frozen then return true end
    if Config.RequireAiming and not isAiming() then return false end
    return hasValidWeapon(ped)
end

local function startFreeze(duration, count)
    local ped = PlayerPedId()

    state.pending = false

    if state.frozen or not canBeFrozen(ped) then return end

    local now = GetGameTimer()

    state.frozen = true
    state.duration = duration
    state.frozenAt = now
    state.frozenUntil = now + duration

    FreezeEntityPosition(ped, true)

    if Config.ScreenEffect.enabled then
        AnimpostfxPlay(Config.ScreenEffect.name, 0, false)
    end

    if Config.CameraShake.enabled then
        ShakeGameplayCam(Config.CameraShake.name, Config.CameraShake.amplitude)
    end

    if Config.Sound.enabled then
        PlaySoundFrontend(-1, Config.Sound.name, Config.Sound.set, true)
    end

    notify(count, duration)
    log('freeze start', duration, count)
end

local function stopFreeze()
    if not state.frozen then return end

    state.frozen = false
    state.cooldownUntil = GetGameTimer() + Config.Cooldown

    FreezeEntityPosition(PlayerPedId(), false)

    if Config.ScreenEffect.enabled then
        AnimpostfxStop(Config.ScreenEffect.name)
    end

    if Config.CameraShake.enabled then
        StopGameplayCamShaking(true)
    end

    log('freeze stop')
end

local function drawBar(now)
    local bar = Config.Bar
    local progress = 1.0 - ((now - state.frozenAt) / state.duration)

    if progress < 0.0 then progress = 0.0 end
    if progress > 1.0 then progress = 1.0 end

    local bg = bar.background
    local fg = bar.fill

    DrawRect(bar.x, bar.y, bar.width, bar.height, bg.r, bg.g, bg.b, bg.a)

    local fillWidth = bar.width * progress
    DrawRect(bar.x - (bar.width - fillWidth) / 2.0, bar.y, fillWidth, bar.height, fg.r, fg.g, fg.b, fg.a)
end

local function blockMovement()
    DisableControlAction(0, 30, true)
    DisableControlAction(0, 31, true)
    DisableControlAction(0, 21, true)
    DisableControlAction(0, 36, true)
    DisableControlAction(0, 44, true)
end

local function tryRoll(ped, now)
    if state.pending and now < state.pendingUntil then return end
    if now < state.cooldownUntil then return end
    if not canBeFrozen(ped) then return end

    state.pending = true
    state.pendingUntil = now + 1500

    TriggerServerEvent('skyway-noroll:attempt')
end

CreateThread(function()
    while true do
        local sleep = 250
        local ped = PlayerPedId()
        local now = GetGameTimer()

        if state.frozen and (IsEntityDead(ped) or now >= state.frozenUntil) then
            stopFreeze()
        end

        if isActive(ped) then
            sleep = 0

            DisableControlAction(0, Config.RollControl, true)

            if state.frozen then
                if Config.BlockMovementWhileFrozen then
                    blockMovement()
                end

                if Config.Bar.enabled then
                    drawBar(now)
                end
            elseif IsDisabledControlJustPressed(0, Config.RollControl) then
                tryRoll(ped, now)
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('skyway-noroll:freeze', function(duration, count)
    startFreeze(duration, count)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if state.frozen then
        FreezeEntityPosition(PlayerPedId(), false)
        AnimpostfxStop(Config.ScreenEffect.name)
        StopGameplayCamShaking(true)
    end

    hideNotify()
end)

exports('IsFrozen', function()
    return state.frozen
end)

exports('GetFreezeRemaining', function()
    if not state.frozen then return 0 end
    return math.max(0, state.frozenUntil - GetGameTimer())
end)
