Config = {}

Config.Debug = false

Config.FreezeTime = 1000

Config.Cooldown = 500

Config.RollControl = 22

Config.RequireWeapon = true

Config.RequireAiming = true

Config.OnlyFirearms = true

Config.DisableInVehicle = true

Config.BlockMovementWhileFrozen = true

Config.IgnoredWeapons = {
    [`WEAPON_UNARMED`] = true,
    [`WEAPON_FLASHLIGHT`] = true,
    [`WEAPON_NIGHTSTICK`] = true,
}

Config.Notify = {
    enabled = true,
    mode = 'nui',
    position = 'top-right',
    accent = '#ff4655',
    syncWithFreeze = true,
    extraTime = 350,
    duration = 2500,
    showCounter = true,
}

Config.ScreenEffect = {
    enabled = true,
    name = 'FocusOut',
}

Config.Sound = {
    enabled = true,
    name = 'ERROR',
    set = 'HUD_FRONTEND_DEFAULT_SOUNDSET',
}

Config.CameraShake = {
    enabled = true,
    name = 'SMALL_EXPLOSION_SHAKE',
    amplitude = 0.08,
}

Config.Bar = {
    enabled = true,
    x = 0.5,
    y = 0.88,
    width = 0.12,
    height = 0.008,
    background = { r = 0, g = 0, b = 0, a = 140 },
    fill = { r = 255, g = 70, b = 70, a = 220 },
}

Config.Server = {
    tolerance = 250,
    consoleLog = true,
}

Config.Webhook = {
    enabled = false,
    url = '',
    username = 'Skyway NoRoll',
    color = 16729677,
    everyNth = 1,
}

Config.Locale = {
    title = 'SKYWAY  NO-ROLL',
    frozen = 'Kotoul neni povolen. Byl jsi zmrazen.',
    counter = 'Zmrazen',
    seconds = 's',
}
