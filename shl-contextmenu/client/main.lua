-- ContextMenu — Core Engine
-- Gère l'API de construction de menus, la boucle d'input, et les callbacks NUI.

ContextMenu = {}
local OPENING_COOLDOWN = 250

-- ============================================================================
-- State
-- ============================================================================

local funcTable = {}
local activeMenus = {}
local itemList = {}
local itemCounter = 0
local menuCounter = 0

local onCooldown = false
local altState = false
local focusLock = false
local isMenuOpen = false

-- ============================================================================
-- Internal State Management
-- ============================================================================

local function Reset()
    activeMenus = {}
    activeMenus[0] = { id = 0, items = {} }
    itemList = {}
    itemCounter = 0
    menuCounter = 1
end

local function GetMenu(menuId)
    menuId = menuId or 0
    if not activeMenus[menuId] then
        activeMenus[menuId] = { id = menuId, items = {} }
    end
    return activeMenus[menuId]
end

-- ============================================================================
-- Menu Builder API — Items
-- ============================================================================

--- Ajoute un item cliquable à un menu.
function ContextMenu.AddItem(menuId, title, func)
    local menu = GetMenu(menuId)
    itemCounter = itemCounter + 1

    local item = {
        id = itemCounter,
        label = title,
        type = "item",
        OnActivate = func
    }

    table.insert(menu.items, item)
    itemList[itemCounter] = item

    return itemCounter
end

--- Ajoute un séparateur visuel.
function ContextMenu.AddSeparator(menuId)
    local menu = GetMenu(menuId)
    table.insert(menu.items, { type = "separator" })
    return -1
end

--- Ajoute un item texte non-interactif.
function ContextMenu.AddTextItem(menuId, title)
    return ContextMenu.AddItem(menuId, title, nil)
end

--- Ajoute un item checkbox avec état on/off.
function ContextMenu.AddCheckboxItem(menuId, title, checked)
    local id = ContextMenu.AddItem(menuId, title, nil)
    itemList[id].type = "checkbox"
    itemList[id].checked = checked
    return id
end

-- ============================================================================
-- Menu Builder API — Submenus
-- ============================================================================

--- Crée un sous-menu imbriqué.
function ContextMenu.AddSubmenu(parentMenuId, title)
    local parentMenu = GetMenu(parentMenuId)

    local newMenuId = menuCounter
    menuCounter = menuCounter + 1
    activeMenus[newMenuId] = { id = newMenuId, items = {} }

    itemCounter = itemCounter + 1
    local item = {
        id = itemCounter,
        label = title,
        type = "submenu",
        submenuId = newMenuId
    }

    table.insert(parentMenu.items, item)
    itemList[itemCounter] = item

    return newMenuId, itemCounter
end

--- Crée un sous-menu scrollable avec hauteur max.
function ContextMenu.AddScrollSubmenu(parentMenuId, title, maxItems)
    local newMenuId, itemId = ContextMenu.AddSubmenu(parentMenuId, title)
    activeMenus[newMenuId].subtype = "scroll"
    activeMenus[newMenuId].maxItems = maxItems or 10
    return newMenuId, itemId
end

--- Crée un sous-menu paginé.
function ContextMenu.AddPageSubmenu(parentMenuId, title, maxItems)
    local newMenuId, itemId = ContextMenu.AddSubmenu(parentMenuId, title)
    activeMenus[newMenuId].subtype = "page"
    activeMenus[newMenuId].maxItems = maxItems or 10
    return newMenuId, itemId
end

-- ============================================================================
-- Item Modifiers
-- ============================================================================

function ContextMenu.OnActivate(itemId, func)
    if itemList[itemId] then itemList[itemId].OnActivate = func end
end

function ContextMenu.OnRelease(itemId, func)
    if itemList[itemId] then itemList[itemId].OnRelease = func end
end

function ContextMenu.OnValueChanged(itemId, func)
    if itemList[itemId] then itemList[itemId].OnValueChanged = func end
end

function ContextMenu.Enabled(itemId, enabled)
    if itemList[itemId] then itemList[itemId].enabled = enabled end
end

function ContextMenu.CloseOnActivate(itemId, close)
    if itemList[itemId] then itemList[itemId].closeOnActivate = close end
end

function ContextMenu.RightText(itemId, text)
    if itemList[itemId] then
        if text then itemList[itemId].rightText = text
        else return itemList[itemId].rightText end
    end
end

-- ============================================================================
-- Module Registration
-- ============================================================================

--- Enregistre une fonction de construction de menu contextuel.
function ContextMenu.Register(func)
    table.insert(funcTable, func)
    return #funcTable
end

-- ============================================================================
-- Focus Lock
-- ============================================================================

--- Verrouille/déverrouille le focus NUI (pour les dialogs).
function ContextMenu.SetFocusLock(locked)
    focusLock = locked
    if locked then
        altState = false
        isMenuOpen = false
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    else
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
end

-- ============================================================================
-- JSON Serialization (Lua → NUI)
-- ============================================================================

--- Construit récursivement l'arbre JSON des menus pour le NUI.
local function BuildJsonTree(menuId)
    local menu = GetMenu(menuId)
    local result = {}

    for _, item in ipairs(menu.items) do
        if item.type == "separator" then
            table.insert(result, { type = "separator" })
        elseif item.type == "submenu" then
            local subItems = BuildJsonTree(item.submenuId)
            if #subItems > 0 then
                local subMenuDef = GetMenu(item.submenuId)
                table.insert(result, {
                    id = item.id,
                    label = item.label,
                    type = "submenu",
                    items = subItems,
                    rightText = item.rightText,
                    menuType = subMenuDef.subtype,
                    maxItems = subMenuDef.maxItems
                })
            end
        else
            table.insert(result, {
                id = item.id,
                label = item.label,
                type = item.type or "item",
                rightText = item.rightText,
                checked = item.checked,
                keepOpen = (item.closeOnActivate == false)
            })
        end
    end
    return result
end

-- ============================================================================
-- Menu Opening
-- ============================================================================

local function OpenMenu(screenPosition)
    Reset()

    local hit, worldPos, normal, entity = ScreenToWorld(screenPosition, 1000.0)

    for _, func in ipairs(funcTable) do
        local status, err = pcall(func, screenPosition, hit, worldPos, entity, normal)
        if not status then
            print("[ContextMenu] Error: " .. tostring(err))
        end
    end

    local rootItems = BuildJsonTree(0)

    if #rootItems > 0 then
        isMenuOpen = true
        SendNUIMessage({
            action = 'openMenu',
            items = rootItems,
            x = screenPosition.x,
            y = screenPosition.y
        })
    end
end

-- ============================================================================
-- Input — Event-Based Key Detection (zero cost quand inactif)
-- ============================================================================

RegisterCommand('+ctx_interact', function()
    if focusLock then return end
    altState = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
end, false)

RegisterCommand('-ctx_interact', function()
    if focusLock then return end
    altState = false

    if isMenuOpen then
        SendNUIMessage({ action = "closeMenu" })
        isMenuOpen = false
    end

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end, false)

RegisterKeyMapping('+ctx_interact', 'ContextMenu - Mode Interaction', 'keyboard', 'LMENU')

-- ============================================================================
-- Input — Disable Controls Loop (ne tourne que quand actif)
-- ============================================================================

Citizen.CreateThread(function()
    while true do
        if altState or focusLock then
            Citizen.Wait(0)

            -- Camera & Combat
            DisableControlAction(0, 1, true)   -- Look L/R
            DisableControlAction(0, 2, true)   -- Look U/D
            DisableControlAction(0, 106, true) -- Vehicle Mouse Control
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 25, true)  -- Global Aim
            DisableControlAction(0, 68, true)  -- Vehicle Aiming
            DisableControlAction(0, 140, true) -- Melee Light
            DisableControlAction(0, 141, true) -- Melee Heavy
            DisableControlAction(0, 142, true) -- Melee Alternate

            -- Weapon Wheel & Scroll
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 16, true)
            DisableControlAction(0, 17, true)
            DisableControlAction(0, 99, true)
            DisableControlAction(0, 115, true)
            DisableControlAction(0, 261, true)
            DisableControlAction(0, 262, true)
            DisableControlAction(0, 334, true)
            DisableControlAction(0, 335, true)
            DisableControlAction(0, 336, true)

            if focusLock then
                -- Movement (bloqué uniquement si un dialog est actif)
                DisableControlAction(0, 30, true) -- Move L/R
                DisableControlAction(0, 31, true) -- Move F/B
                DisableControlAction(0, 32, true) -- Move W
                DisableControlAction(0, 33, true) -- Move S
                DisableControlAction(0, 34, true) -- Move A
                DisableControlAction(0, 35, true) -- Move D
            end
        else
            -- Inactif : le thread dort, coût ~0.00ms
            Citizen.Wait(10)
        end
    end
end)

-- ============================================================================
-- NUI Callbacks
-- ============================================================================

RegisterNUICallback('requestOpenCoordinates', function(data, cb)
    if altState and not onCooldown then
        OpenMenu(vector2(data.x, data.y))
        onCooldown = true
        Citizen.SetTimeout(OPENING_COOLDOWN, function() onCooldown = false end)
    end
    cb('ok')
end)

RegisterNUICallback('triggerAction', function(data, cb)
    local item = itemList[data.id]
    if item then
        if item.type == "checkbox" then
            item.checked = not item.checked
            if item.OnValueChanged then
                item.OnValueChanged(item.checked)
            end
        elseif item.OnActivate then
            item.OnActivate()
        end
    end
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(data, cb)
    isMenuOpen = false
    if not altState and not focusLock then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
    cb('ok')
end)

RegisterNUICallback('submitVehicleNameToSpawn', function(data, cb)
    ContextMenu.SetFocusLock(false)
    local modelName = data.vehicleName
    local modelHash = GetHashKey(modelName)

    if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
        SetNotificationTextEntry("STRING")
        AddTextComponentSubstringPlayerName("~r~Véhicule invalide: " .. modelName)
        DrawNotification(false, true)
        cb('error')
        return
    end

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(0)
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)
    SetPedIntoVehicle(ped, vehicle, -1)
    SetModelAsNoLongerNeeded(modelHash)

    SetNotificationTextEntry("STRING")
    AddTextComponentSubstringPlayerName("~g~Véhicule spawn: " .. modelName)
    DrawNotification(false, true)

    cb('ok')
end)

RegisterNUICallback('cancelSpawnVehicleDialog', function(data, cb)
    ContextMenu.SetFocusLock(false)
    cb('ok')
end)

-- ============================================================================
-- Exports
-- ============================================================================

exports("Register", ContextMenu.Register)
exports("AddSeparator", ContextMenu.AddSeparator)
exports("AddTextItem", ContextMenu.AddTextItem)
exports("AddItem", ContextMenu.AddItem)
exports("AddItems", function(items)
    local ids = {}
    for _, def in ipairs(items) do
        table.insert(ids, ContextMenu.AddItem(def[1], def[2], def[3]))
    end
    return ids
end)

exports("AddCheckboxItem", ContextMenu.AddCheckboxItem)
exports("AddSubmenu", ContextMenu.AddSubmenu)
exports("AddScrollSubmenu", ContextMenu.AddScrollSubmenu)
exports("AddPageSubmenu", ContextMenu.AddPageSubmenu)

exports("OnActivate", ContextMenu.OnActivate)
exports("OnRelease", ContextMenu.OnRelease)
exports("OnValueChanged", ContextMenu.OnValueChanged)
exports("Enabled", ContextMenu.Enabled)
exports("CloseOnActivate", ContextMenu.CloseOnActivate)
exports("RightText", ContextMenu.RightText)
exports("SetFocusLock", ContextMenu.SetFocusLock)
