--[[
    Screen Utilities
    Raycast depuis la position écran vers le monde 3D.
    Basé sur le travail de Kiminaze (Discord: Kiminaze#9097).
]]

-- ============================================================================
-- Cursor Position
-- ============================================================================

--- Retourne la position normalisée du curseur (0.0 - 1.0).
function GetCursorScreenPosition()
    if not IsControlEnabled(0, 239) then
        EnableControlAction(0, 239, true)
    end
    if not IsControlEnabled(0, 240) then
        EnableControlAction(0, 240, true)
    end

    return vector2(GetControlNormal(0, 239), GetControlNormal(0, 240))
end

-- ============================================================================
-- Screen-to-World Raycast
-- ============================================================================

local cachedCam

--- Lance un raycast depuis une position écran vers le monde.
--- @param screenPosition vector2 Position normalisée (0,0 = top-left, 1,1 = bottom-right)
--- @param maxDistance number Distance max du raycast en mètres
--- @return boolean hit, vector3 worldPosition, vector3 normalDirection, entity|nil entity
function ScreenToWorld(screenPosition, maxDistance)
    local pos = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(0)
    local fov = GetGameplayCamFov()

    -- Réutilise la caméra scriptée pour éviter les créations/destructions répétées
    if not DoesCamExist(cachedCam) then
        cachedCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", false)
    end

    SetCamCoord(cachedCam, pos.x, pos.y, pos.z)
    SetCamRot(cachedCam, rot.x, rot.y, rot.z, 2)
    SetCamFov(cachedCam, fov)

    local camRight, camForward, camUp, camPos = GetCamMatrix(cachedCam)

    -- Convertir les coordonnées écran normalisées en espace caméra
    screenPosition = vector2(screenPosition.x - 0.5, screenPosition.y - 0.5) * 2.0

    local fovRadians = DegreesToRadians(fov)
    local to = camPos + camForward + (camRight * screenPosition.x * fovRadians * GetAspectRatio(false) * 0.534375) - (camUp * screenPosition.y * fovRadians * 0.534375)

    local direction = (to - camPos) * maxDistance
    local endPoint = camPos + direction

    local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, endPoint.x, endPoint.y, endPoint.z, -1, 0, 0)
    local _, hit, worldPosition, normalDirection, entity = GetShapeTestResult(rayHandle)

    if hit == 1 then
        return true, worldPosition, normalDirection, entity
    else
        return false, vector3(0, 0, 0), vector3(0, 0, 0), nil
    end
end

-- ============================================================================
-- Math Utilities
-- ============================================================================

function DegreesToRadians(degrees)
    return (degrees * 3.14) / 180.0
end
