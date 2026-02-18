--[[
    Module: Object
    Menu contextuel pour les objets (props).
    Inclut : suppression, outils de dev (position, hash, archetype, network).
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
    if not DoesEntityExist(hitEntity) or not IsEntityAnObject(hitEntity) then
        return
    end

    local object = hitEntity

    -- Suppression
    local itemDelete = ECM.AddItem(0, "Delete object")
    ECM.OnActivate(itemDelete, function()
        if DoesEntityExist(object) then
            SetEntityAsMissionEntity(object)
            DeleteEntity(object)
        end
    end)

    -- Outils de dev
    local submenuDev, _ = ECM.AddSubmenu(0, "~y~Outils de dev")

    local objCoords = GetEntityCoords(object)
    local objHeading = GetEntityHeading(object)
    local modelHash = GetEntityModel(object)
    local netId = ObjToNet(object)
    local hasNetId = NetworkDoesNetworkIdExist(netId)

    local posString = string.format("%.2f, %.2f, %.2f", objCoords.x, objCoords.y, objCoords.z)
    local headingString = string.format("%.2f", objHeading)
    local hashString = tostring(modelHash)
    local archetypeString = GetEntityArchetypeName(object)
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

        local ownerId = NetworkGetEntityOwner(object)
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
