--[[
    Module: Misc
    Menu contextuel pour les interactions générales (sol, ciel).
    Inclut : téléportation, spawn véhicule, météo, heure, outils dev, démo.
]]

local ECM = ContextMenu

-- ============================================================================
-- Data
-- ============================================================================

local weathers = {
    "Clear", "Extrasunny", "Clouds", "Overcast",
    "Rain", "Clearing", "Thunder", "Smog",
    "Foggy", "Xmas", "Snowlight", "Blizzard"
}

local times = {
    { "Morning",   8  },
    { "Afternoon", 12 },
    { "Evening",   18 },
    { "Night",     22 },
}

-- ============================================================================
-- State
-- ============================================================================

local isSnowEnabled = false
local isBlackoutEnabled = false
local isTimeFrozen = false

-- ============================================================================
-- Time Freeze Loop
-- ============================================================================

Citizen.CreateThread(function()
    while true do
        if isTimeFrozen then
            NetworkOverrideClockTime(GetClockHours(), GetClockMinutes(), GetClockSeconds())
            Citizen.Wait(0)
        else
            Citizen.Wait(1000)
        end
    end
end)

-- ============================================================================
-- Context Menu Registration
-- ============================================================================

ECM.Register(function(screenPosition, hitSomething, worldPosition, hitEntity, normalDirection)
    -- Clic sur le sol ou un mur (entité qui n'est ni véhicule, ni ped, ni objet)
    if (DoesEntityExist(hitEntity) and not IsEntityAVehicle(hitEntity) and not IsEntityAPed(hitEntity) and not IsEntityAnObject(hitEntity)) then
        local itemTeleport = ECM.AddItem(0, "Teleport to point")
        ECM.OnActivate(itemTeleport, function()
            SetEntityCoords(PlayerPedId(), worldPosition)
        end)

        if not IsPedInAnyVehicle(PlayerPedId(), false) then
            local itemSpawn = ECM.AddItem(0, "Spawn un véhicule")
            ECM.OnActivate(itemSpawn, function()
                SendNUIMessage({ action = "showSpawnVehicleDialog" })
                ContextMenu.SetFocusLock(true)
            end)
        end

        -- Outils de dev
        local submenuDev, _ = ECM.AddSubmenu(0, "~y~Outils de dev")

        local posString = string.format("%.2f, %.2f, %.2f", worldPosition.x, worldPosition.y, worldPosition.z)
        local itemPos = ECM.AddItem(submenuDev, "Pos: " .. posString)
        ECM.OnActivate(itemPos, function()
            SendNUIMessage({ action = "copyToClipboard", text = posString })
            SetNotificationTextEntry("STRING")
            AddTextComponentSubstringPlayerName("~g~Position copiée !")
            DrawNotification(false, true)
        end)
    end

    -- Clic dans le vide (ciel)
    if (not hitSomething) then
        -- Météo
        local submenuWeather, _ = ECM.AddSubmenu(0, "Change weather")
        for i = 1, #weathers, 1 do
            local itemWeather = ECM.AddItem(submenuWeather, weathers[i])
            ECM.OnActivate(itemWeather, function()
                SetWeatherTypeOvertimePersist(weathers[i], 1.0)
            end)
        end

        ECM.AddSeparator(submenuWeather)

        local itemSnow = ECM.AddCheckboxItem(submenuWeather, "Neige au sol", isSnowEnabled)
        ECM.OnValueChanged(itemSnow, function(checked)
            isSnowEnabled = checked
            ForceSnowPass(checked)
        end)

        local itemBlackout = ECM.AddCheckboxItem(submenuWeather, "Blackout", isBlackoutEnabled)
        ECM.OnValueChanged(itemBlackout, function(checked)
            isBlackoutEnabled = checked
            SetBlackout(checked)
        end)

        -- Heure
        local submenuTime = ECM.AddSubmenu(0, "Changer heure")

        local itemFreeze = ECM.AddCheckboxItem(submenuTime, "Figer le temps", isTimeFrozen)
        ECM.RightText(itemFreeze, GetClockHours() .. ":" .. GetClockMinutes())
        ECM.OnValueChanged(itemFreeze, function(checked)
            isTimeFrozen = checked
        end)

        ECM.AddSeparator(submenuTime)

        for _, timeData in ipairs(times) do
            local itemTime = ECM.AddItem(submenuTime, timeData[1])
            ECM.OnActivate(itemTime, function()
                NetworkOverrideClockTime(timeData[2], 0, 0)
            end)
        end

        -- Outils de dev
        local submenuDev, _ = ECM.AddSubmenu(0, "~y~Outils de dev")

        local posString = string.format("%.2f, %.2f, %.2f", worldPosition.x, worldPosition.y, worldPosition.z)
        local itemPos = ECM.AddItem(submenuDev, "Pos: " .. posString)
        ECM.OnActivate(itemPos, function()
            SendNUIMessage({ action = "copyToClipboard", text = posString })
            SetNotificationTextEntry("STRING")
            AddTextComponentSubstringPlayerName("~g~Position copiée !")
            DrawNotification(false, true)
        end)

        ECM.AddSeparator(0)

        -- Démo Features & Couleurs
        local submenuDemo, _ = ECM.AddSubmenu(0, "Démo Features & Couleurs")

        ECM.AddItem(submenuDemo, "Standard Item")
        ECM.AddCheckboxItem(submenuDemo, "Checkbox Item (On)", true)
        ECM.AddCheckboxItem(submenuDemo, "Checkbox Item (Off)", false)
        ECM.AddSeparator(submenuDemo)

        local itemRight = ECM.AddItem(submenuDemo, "Item with Right Text")
        ECM.RightText(itemRight, "R-Text")

        local submenuColors, _ = ECM.AddSubmenu(submenuDemo, "Couleurs (GTA Style)")
        ECM.AddItem(submenuColors, "~r~Rouge (r)")
        ECM.AddItem(submenuColors, "~b~Bleu (b)")
        ECM.AddItem(submenuColors, "~g~Vert (g)")
        ECM.AddItem(submenuColors, "~y~Jaune (y)")
        ECM.AddItem(submenuColors, "~o~Orange (o)")
        ECM.AddItem(submenuColors, "~c~Gris (c)")
        ECM.AddItem(submenuColors, "~m~Gris Foncé (m)")
        ECM.AddItem(submenuColors, "~p~Violet (p)")
        ECM.AddItem(submenuColors, "~v~Magenta (v)")
        ECM.AddItem(submenuColors, "~l~Noir (l)")
        ECM.AddItem(submenuColors, "~w~Blanc (w)")
        ECM.AddItem(submenuColors, "~h~Gras (h)")
        ECM.AddItem(submenuColors, "~h~~r~Gras Rouge (h r)")

        local submenuTypes, _ = ECM.AddSubmenu(submenuDemo, "Types de Menus")
        ECM.AddItem(submenuTypes, "Ce menu est 'default'")

        local scrollMenu, _ = ECM.AddScrollSubmenu(submenuTypes, "Menu Scrollable (Max 5)", 5)
        for i = 1, 20 do ECM.AddItem(scrollMenu, "Item " .. i) end

        local pageMenu, _ = ECM.AddPageSubmenu(submenuTypes, "Menu Paginé (Max 5)", 5)
        for i = 1, 20 do ECM.AddItem(pageMenu, "Page Item " .. i) end
    end
end)
