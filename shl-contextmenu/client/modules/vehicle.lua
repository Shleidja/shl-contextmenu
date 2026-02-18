--[[
    Module: Vehicle
    Menu contextuel pour les véhicules.
    Inclut : suppression, portes, outils de dev.
]]

local ECM = ContextMenu

-- ============================================================================
-- Helpers
-- ============================================================================

local function ShowNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
    DrawNotification(false, true)
end

-- ============================================================================
-- Context Menu Registration
-- ============================================================================

ECM.Register(function(screenPosition, hitSomething, worldPosition, hitEntity, normalDirection)
    if not DoesEntityExist(hitEntity) or not IsEntityAVehicle(hitEntity) then
        return
    end

    local vehicle = hitEntity

    -- Suppression
    local itemDelete = ECM.AddItem(0, "Delete vehicle")
    ECM.OnActivate(itemDelete, function()
        if DoesEntityExist(vehicle) then
            SetEntityAsMissionEntity(vehicle)
            DeleteEntity(vehicle)
        end
    end)

    -- Réparation
    local itemRepair = ECM.AddItem(0, "Repair vehicle")
    ECM.OnActivate(itemRepair, function()
        if DoesEntityExist(vehicle) then
            SetVehicleFixed(vehicle)
        end
    end)

    -- Portes
    if GetNumberOfVehicleDoors(vehicle) > 0 then
        local submenuDoor, _ = ECM.AddSubmenu(0, "Open door")
        for i = 1, GetNumberOfVehicleDoors(vehicle), 1 do
            local itemDoor = ECM.AddItem(submenuDoor, "Door " .. i)
            ECM.OnActivate(itemDoor, function()
                local door = i - 1
                if GetVehicleDoorAngleRatio(vehicle, door) < 0.1 then
                    SetVehicleDoorOpen(vehicle, door, false, false)
                else
                    SetVehicleDoorShut(vehicle, door, false)
                end
            end)
        end
    end

    -- Outils de dev
    local submenuDev, _ = ECM.AddSubmenu(0, "~y~Outils de dev")

    local vehCoords = GetEntityCoords(vehicle)
    local vehHeading = GetEntityHeading(vehicle)
    local modelHash = GetEntityModel(vehicle)
    local netId = VehToNet(vehicle)
    local hasNetId = NetworkDoesNetworkIdExist(netId)

    local posString = string.format("%.2f, %.2f, %.2f", vehCoords.x, vehCoords.y, vehCoords.z)
    local headingString = string.format("%.2f", vehHeading)
    local hashString = tostring(modelHash)
    local archetypeString = GetEntityArchetypeName(vehicle)
    local netIdString = hasNetId and tostring(netId) or "N/A (Local)"

    local function AddCopyableItem(label, value, successMsg)
        local item = ECM.AddItem(submenuDev, label .. ": " .. value)
        ECM.OnActivate(item, function()
            SendNUIMessage({ action = "copyToClipboard", text = value })
            ShowNotification("~g~" .. successMsg .. " copié !")
        end)
    end

    AddCopyableItem("Pos", posString, "Position")
    AddCopyableItem("Heading", headingString, "Heading")
    AddCopyableItem("Hash", hashString, "Hash du modèle")
    AddCopyableItem("Archetype", archetypeString, "Archetype")

    if hasNetId then
        AddCopyableItem("NetID", netIdString, "NetID")

        local ownerId = NetworkGetEntityOwner(vehicle)
        local ownerName = GetPlayerName(ownerId) or "Inconnu"
        local ownerInfo = string.format("%d (%s)", ownerId, ownerName)

        local itemOwner = ECM.AddItem(submenuDev, "Network Owner: " .. ownerInfo)
        ECM.OnActivate(itemOwner, function()
            local serverId = GetPlayerServerId(ownerId)
            SendNUIMessage({ action = "copyToClipboard", text = tostring(serverId) })
            ShowNotification("~g~Network ID copié !")
        end)
    else
        ECM.AddItem(submenuDev, "NetID: ~c~" .. netIdString)
    end
end)
