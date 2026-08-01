local utils = {}
local clientUtils = require 'modules.utils.client'

local rotationToDirection = function(rotation)
	local adjustedRotation = { x = (math.pi / 180) * rotation.x, y = (math.pi / 180) * rotation.y, z = (math.pi / 180) * rotation.z }
	local direction = { x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), z = math.sin(adjustedRotation.x) }
	return direction
end

utils.rayCastGamePlayCamera = function(distance)
    local cameraRotation = GetGameplayCamRot(0)
	local cameraCoord = GetGameplayCamCoord()
	local direction = rotationToDirection(cameraRotation)
	local destination = { x = cameraCoord.x + direction.x * distance, y = cameraCoord.y + direction.y * distance, z = cameraCoord.z + direction.z * distance }
	local _, _, endCoords, surfaceNormal, _ = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
	return endCoords, surfaceNormal
end

utils.getTargetCoords = function()
    local coords = {}
    local radius = 0.3
    local lastCoords = {}

    while true do
        Wait(0)
        DisableAllControlActions(0)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        EnableControlAction(0, 30, true) -- Move LR
        EnableControlAction(0, 31, true) -- Move UD
        EnableControlAction(0, 21, true) -- Sprint
        EnableControlAction(0, 22, true) -- Jump
        EnableControlAction(0, 71, true) -- Enter Vehicle

        coords = utils.rayCastGamePlayCamera(10)
        local position = GetEntityCoords(cache.ped)
        if coords.x ~= 0.0 and coords.y ~= 0.0 and coords.z ~= 0.0 then
            DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, 255, 0, 0, 200)
            ---@diagnostic disable-next-line: param-type-mismatch
            DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, radius, radius, radius, 255, 0, 0, 200, false, true, 2, false, nil, nil, false)
            lastCoords = coords
        else
            DrawLine(position.x, position.y, position.z, lastCoords.x, lastCoords.y, lastCoords.z, 255, 0, 0, 200)
            ---@diagnostic disable-next-line: param-type-mismatch
            DrawMarker(28, lastCoords.x, lastCoords.y, lastCoords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, radius, radius, radius, 255, 0, 0, 200, false, true, 2, false, nil, nil, false)
        end

        if IsDisabledControlPressed(0, 241) then -- SCROLL UP - Increase radius
            radius = radius + 0.05
        elseif IsDisabledControlPressed(0, 242) then -- SCROLL DOWN - Decrease radius
            radius = radius - 0.05
        end

        if IsDisabledControlPressed(0, 201) or IsDisabledControlPressed(0, 24) then -- Enter or LMB - Finish
            break
        end

        if IsDisabledControlPressed(0, 194) or IsDisabledControlPressed(0, 202) then -- Backspace/ESC - Cancel
            return nil
        end
    end

    return {
        coords,
        radius
    }
end

utils.getPedCoords = function(model)
    local _, _, coords = lib.raycast.fromCamera(511, 4, 10)
    local heading = 0.0
    clientUtils.loadModel(model)
    local ped = CreatePed(1, GetHashKey(model), coords.x, coords.y, coords.z, 0, false, false)
    SetEntityCollision(ped, false, true)
    SetEntityAlpha(ped, 200, false)
    FreezeEntityPosition(ped, true)

    while true do
        Wait(0)
        DisableAllControlActions(0)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        EnableControlAction(0, 30, true) -- Move LR
        EnableControlAction(0, 31, true) -- Move UD
        EnableControlAction(0, 21, true) -- Sprint
        EnableControlAction(0, 22, true) -- Jump
        EnableControlAction(0, 71, true) -- Enter Vehicle

        _, _, coords = lib.raycast.fromCamera(511, 4, 10)
        local position = GetEntityCoords(cache.ped)
        DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, 255, 0, 0, 200)

        if coords.x ~= 0.0 and coords.y ~= 0.0 and coords.z ~= 0.0 then
            SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
            SetEntityHeading(ped, heading)
        end

        if IsDisabledControlPressed(0, 241) then -- SCROLL UP - Increase heading
            heading += 2.5
        elseif IsDisabledControlPressed(0, 242) then -- SCROLL DOWN - Decrease heading
            heading -= 2.5
        end

        if IsDisabledControlPressed(0, 201) or IsDisabledControlPressed(0, 24) then -- Enter or LMB - Finish
            coords = GetEntityCoords(ped)
            coords = vec4(coords.x, coords.y, coords.z, heading)
            DeleteEntity(ped)
            break
        end

        if IsDisabledControlPressed(0, 194) or IsDisabledControlPressed(0, 202) then -- Backspace/ESC - Cancel
            DeleteEntity(ped)
            return nil
        end
    end

    return coords
end

utils.getObjectCoords = function(model)
    local _, _, coords = lib.raycast.fromCamera(511, 4, 10)
    local heading = 0.0
    clientUtils.loadModel(model)
    local object = CreateObject(GetHashKey(model), coords.x, coords.y, coords.z, false, false, false)
    SetEntityCollision(object, false, true)
    SetEntityAlpha(object, 200, false)
    FreezeEntityPosition(object, true)

    local zOffset = 0.0

    while true do
        Wait(0)
        DisableAllControlActions(0)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        EnableControlAction(0, 30, true) -- Move LR
        EnableControlAction(0, 31, true) -- Move UD
        EnableControlAction(0, 21, true) -- Sprint
        EnableControlAction(0, 22, true) -- Jump
        EnableControlAction(0, 71, true) -- Enter Vehicle

        _, _, coords = lib.raycast.fromCamera(511, 4, 10)
        local position = GetEntityCoords(cache.ped)
        DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, 255, 0, 0, 200)

        if coords.x ~= 0.0 and coords.y ~= 0.0 and coords.z ~= 0.0 then
            SetEntityCoords(object, coords.x, coords.y, coords.z + zOffset, false, false, false, false)
            SetEntityHeading(object, heading)
        end

        if IsDisabledControlPressed(0, 254) then -- Hold LEFT SHIFT - Change Z offset
            if IsDisabledControlPressed(0, 241) then -- SCROLL UP - Increase Z offset
                zOffset += 0.05
            elseif IsDisabledControlPressed(0, 242) then -- SCROLL DOWN - Decrease Z offset
                zOffset -= 0.05
            end
        elseif IsDisabledControlPressed(0, 241) then -- SCROLL UP - Increase heading
            heading += 2.5
        elseif IsDisabledControlPressed(0, 242) then -- SCROLL DOWN - Decrease heading
            heading -= 2.5
        end

        if IsDisabledControlPressed(0, 201) or IsDisabledControlPressed(0, 24) then -- Enter or LMB - Finish
            coords = GetEntityCoords(object)
            coords = vec4(coords.x, coords.y, coords.z, heading)
            DeleteEntity(object)
            break
        end

        if IsDisabledControlPressed(0, 194) or IsDisabledControlPressed(0, 202) then -- Backspace/ESC - Cancel
            DeleteEntity(object)
            return nil
        end
    end

    return coords
end

utils.getVehicleCoords = function(model)
    local _, _, coords = lib.raycast.fromCamera(511, 4, 10)
    local heading = 0.0
    local hash = type(model) == 'number' and model or joaat(model)
    
    if not IsModelValid(hash) then
        clientUtils.notify('Invalid model name!', 'error')
        return nil
    end

    clientUtils.loadModel(hash)
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, false, false)
    
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        clientUtils.notify('Failed to spawn vehicle model!', 'error')
        return nil
    end

    SetEntityCollision(vehicle, false, true)
    SetEntityAlpha(vehicle, 255, false)
    FreezeEntityPosition(vehicle, true)

    local zOffset = 0.0
    local liveryIndex = -1
    local liveryType = nil
    local liveryCount = 0

    local standardLiveryCount = GetVehicleLiveryCount(vehicle)
    local modLiveryCount = GetNumVehicleMods(vehicle, 48)

    if standardLiveryCount > 0 then
        liveryType = 'standard'
        liveryCount = standardLiveryCount
    elseif modLiveryCount > 0 then
        liveryType = 'mod'
        liveryCount = modLiveryCount
    end

    local function applyLivery(index)
        if not liveryType then return end
        if liveryType == 'standard' then
            SetVehicleLivery(vehicle, index)
        elseif liveryType == 'mod' then
            SetVehicleMod(vehicle, 48, index, false)
        end
    end

    while true do
        Wait(0)
        DisableAllControlActions(0)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        EnableControlAction(0, 30, true) -- Move LR
        EnableControlAction(0, 31, true) -- Move UD
        EnableControlAction(0, 21, true) -- Sprint
        EnableControlAction(0, 22, true) -- Jump
        EnableControlAction(0, 71, true) -- Enter Vehicle

        _, _, coords = lib.raycast.fromCamera(511, 4, 10)
        local position = GetEntityCoords(cache.ped)
        DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, 255, 0, 0, 200)

        if coords.x ~= 0.0 and coords.y ~= 0.0 and coords.z ~= 0.0 then
            SetEntityCoords(vehicle, coords.x, coords.y, coords.z + zOffset, false, false, false, false)
            SetEntityHeading(vehicle, heading)
            if zOffset == 0.0 then
                SetVehicleOnGroundProperly(vehicle)
            end
        end

        if IsDisabledControlPressed(0, 254) then -- Hold LEFT SHIFT - Change Z offset
            if IsDisabledControlPressed(0, 241) then -- SCROLL UP - Increase Z offset
                zOffset += 0.05
            elseif IsDisabledControlPressed(0, 242) then -- SCROLL DOWN - Decrease Z offset
                zOffset -= 0.05
            end
        elseif IsDisabledControlPressed(0, 241) then -- SCROLL UP - Increase heading
            heading += 2.5
        elseif IsDisabledControlPressed(0, 242) then -- SCROLL DOWN - Decrease heading
            heading -= 2.5
        end

        if liveryCount > 0 then
            if IsDisabledControlJustPressed(0, 175) then -- Right Arrow
                liveryIndex = liveryIndex + 1
                if liveryIndex >= liveryCount then
                    liveryIndex = -1
                end
                applyLivery(liveryIndex)
            elseif IsDisabledControlJustPressed(0, 174) then -- Left Arrow
                liveryIndex = liveryIndex - 1
                if liveryIndex < -1 then
                    liveryIndex = liveryCount - 1
                end
                applyLivery(liveryIndex)
            end
        end

        if IsDisabledControlPressed(0, 201) or IsDisabledControlPressed(0, 24) then -- Enter or LMB - Finish
            coords = GetEntityCoords(vehicle)
            coords = vec4(coords.x, coords.y, coords.z, heading)
            DeleteEntity(vehicle)
            break
        end

        if IsDisabledControlPressed(0, 194) or IsDisabledControlPressed(0, 202) then -- Backspace/ESC - Cancel
            DeleteEntity(vehicle)
            return nil
        end
    end

    return {
        coords = coords,
        livery = liveryIndex
    }
end

return utils