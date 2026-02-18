--[[
    Module: Ped
    Menu contextuel pour les peds (NPC, joueurs, soi-même).
    Inclut : suppression NPC, identification, outils de dev.
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
    if not DoesEntityExist(hitEntity) or not IsEntityAPed(hitEntity) then
        return
    end

    local ped = hitEntity

    local isPlayer = IsPedAPlayer(ped)
    local isSelf = (ped == PlayerPedId())
    local isOtherPlayer = (isPlayer and not isSelf)

    -- Suppression (NPC uniquement)
    if not isPlayer then
        local itemDelete = ECM.AddItem(0, "Delete ped")
        ECM.OnActivate(itemDelete, function()
            if DoesEntityExist(ped) then
                SetEntityAsMissionEntity(ped)
                DeleteEntity(ped)
            end
        end)
    end

    -- Outils de dev
    local submenuDev, _ = ECM.AddSubmenu(0, "~y~Outils de dev")

    local pedCoords = GetEntityCoords(ped)
    local pedHeading = GetEntityHeading(ped)
    local modelHash = GetEntityModel(ped)
    local netId = PedToNet(ped)
    local hasNetId = NetworkDoesNetworkIdExist(netId)

    local posString = string.format("%.2f, %.2f, %.2f", pedCoords.x, pedCoords.y, pedCoords.z)
    local headingString = string.format("%.2f", pedHeading)
    local hashString = tostring(modelHash)
    local archetypeString = GetEntityArchetypeName(ped)
    local netIdString = hasNetId and tostring(netId) or "N/A (Local)"

    local function AddCopyableItem(label, value, successMsg)
        local item = ECM.AddItem(submenuDev, label .. ": " .. value)
        ECM.OnActivate(item, function()
            SendNUIMessage({ action = "copyToClipboard", text = value })
            ShowNotification("~g~" .. successMsg .. " copié !")
        end)
    end

    -- Tag d'identification
    if isSelf then
        ECM.AddItem(submenuDev, "~g~[SELF]")
    elseif isOtherPlayer then
        ECM.AddItem(submenuDev, "~b~[PLAYER]")
    else
        ECM.AddItem(submenuDev, "~c~[NPC]")
    end

    -- Infos serveur (joueurs uniquement)
    if isPlayer then
        local playerIdx = NetworkGetPlayerIndexFromPed(ped)
        if isSelf then playerIdx = PlayerId() end

        local serverId = GetPlayerServerId(playerIdx)
        local name = GetPlayerName(playerIdx)

        AddCopyableItem("Pseudo", name, "Pseudo")
        AddCopyableItem("Server ID", tostring(serverId), "ID Serveur")
        ECM.AddSeparator(submenuDev)
    end

    -- Entity data
    AddCopyableItem("Pos", posString, "Position")
    AddCopyableItem("Heading", headingString, "Heading")
    AddCopyableItem("Hash", hashString, "Hash du modèle")
    AddCopyableItem("Archetype", archetypeString, "Archetype")

    if hasNetId then
        AddCopyableItem("NetID", netIdString, "NetID")

        -- Network Owner (NPC uniquement, les joueurs ont déjà le Server ID)
        if not isPlayer then
            local ownerId = NetworkGetEntityOwner(ped)
            local ownerName = GetPlayerName(ownerId) or "Inconnu"
            local ownerInfo = string.format("%d (%s)", ownerId, ownerName)

            local itemOwner = ECM.AddItem(submenuDev, "Owner: " .. ownerInfo)
            ECM.OnActivate(itemOwner, function()
                local serverId = GetPlayerServerId(ownerId)
                SendNUIMessage({ action = "copyToClipboard", text = tostring(serverId) })
                ShowNotification("~g~ID Serveur du propriétaire copié !")
            end)
        end
    else
        ECM.AddItem(submenuDev, "NetID: ~c~" .. netIdString)
    end
end)
