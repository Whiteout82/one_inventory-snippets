RegisterNetEvent('mt_restaurants:client:addArmour', function(amount)
    local ped = PlayerPedId()
    local currentArmour = GetPedArmour(ped)
    local newArmour = currentArmour + math.floor(amount)
    if newArmour > 100 then newArmour = 100 end
    SetPedArmour(ped, newArmour)
end)

local hasAlcoholEffect = false

AddStateBagChangeHandler('restaurant_buff_alcohol', nil, function(bagName, key, value, _reserved, replicated)
    local player = GetPlayerFromStateBagName(bagName)
    if player == 0 or player ~= PlayerId() then return end

    if value and value > 0 then
        if not hasAlcoholEffect then
            hasAlcoholEffect = true
            CreateThread(function()
                local ped = PlayerPedId()
                
                while hasAlcoholEffect do
                    Wait(1000)
                    local currentAlcohol = LocalPlayer.state.restaurant_buff_alcohol or 0
                    
                    if currentAlcohol > 0 then
                        if currentAlcohol >= 75 then
                            SetTimecycleModifier("spectator5")
                            SetTimecycleModifierStrength(1.0)
                            SetPedIsDrunk(ped, true)
                            SetPedMotionBlur(ped, true)
                            
                            if GetPedMovementClipset(ped) ~= joaat("move_m@drunk@verydrunk") then
                                RequestAnimSet("move_m@drunk@verydrunk")
                                while not HasAnimSetLoaded("move_m@drunk@verydrunk") do
                                    Wait(0)
                                end
                                SetPedMovementClipset(ped, "move_m@drunk@verydrunk", 1.0)
                            end
                        elseif currentAlcohol >= 40 then
                            SetTimecycleModifier("spectator5")
                            SetTimecycleModifierStrength(0.5)
                            SetPedIsDrunk(ped, true)
                            SetPedMotionBlur(ped, true)
                            
                            if GetPedMovementClipset(ped) ~= joaat("move_m@drunk@slightlydrunk") then
                                RequestAnimSet("move_m@drunk@slightlydrunk")
                                while not HasAnimSetLoaded("move_m@drunk@slightlydrunk") do
                                    Wait(0)
                                end
                                SetPedMovementClipset(ped, "move_m@drunk@slightlydrunk", 1.0)
                            end
                        else
                            SetTimecycleModifier("spectator5")
                            SetTimecycleModifierStrength(0.2)
                            SetPedIsDrunk(ped, false)
                            SetPedMotionBlur(ped, false)
                            ResetPedMovementClipset(ped, 0.0)
                        end
                    else
                        hasAlcoholEffect = false
                    end
                end
                
                local currentPed = PlayerPedId()
                ClearTimecycleModifier()
                ResetPedMovementClipset(currentPed, 0.0)
                SetPedIsDrunk(currentPed, false)
                SetPedMotionBlur(currentPed, false)
            end)
        end
    else
        hasAlcoholEffect = false
    end
end)