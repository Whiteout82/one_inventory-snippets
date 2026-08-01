local utils = {}
local bridge = require 'modules.bridge.server'

if not _G.ActiveRestaurantBuffs then
    _G.ActiveRestaurantBuffs = {}

    exports('getBuff', function(src, buff)
        if _G.ActiveRestaurantBuffs[src] and _G.ActiveRestaurantBuffs[src][buff] then
            return _G.ActiveRestaurantBuffs[src][buff]
        end
        return 0
    end)

    CreateThread(function()
        while true do
            Wait(10000) -- Update buffs every 10 seconds
            for src, b in pairs(_G.ActiveRestaurantBuffs) do
                if not GetPlayerEndpoint(src) then
                    _G.ActiveRestaurantBuffs[src] = nil
                else
                    if b.alcohol and b.alcohol > 0 then
                        b.alcohol = b.alcohol - 1
                        if b.alcohol <= 0 then
                            b.alcohol = nil
                            Player(src).state.restaurant_buff_alcohol = 0
                            if GetResourceState('mt_hud') == 'started' then
                                exports.mt_hud:updateBuff(src, 'alcohol', 'fas fa-beer', 0, '#E67E22')
                            end
                        else
                            Player(src).state.restaurant_buff_alcohol = b.alcohol
                            if GetResourceState('mt_hud') == 'started' then
                                exports.mt_hud:updateBuff(src, 'alcohol', 'fas fa-beer', b.alcohol, '#E67E22')
                            end
                        end
                    end

                    if b.fortune and b.fortune > 0 then
                        b.fortune = b.fortune - 1
                        if b.fortune <= 0 then
                            b.fortune = nil
                            Player(src).state.restaurant_buff_fortune = 0
                            if GetResourceState('mt_hud') == 'started' then
                                exports.mt_hud:updateBuff(src, 'fortune', 'fas fa-clover', 0, '#2ECC71')
                            end
                        else
                            Player(src).state.restaurant_buff_fortune = b.fortune
                            if GetResourceState('mt_hud') == 'started' then
                                exports.mt_hud:updateBuff(src, 'fortune', 'fas fa-clover', b.fortune, '#2ECC71')
                            end
                        end
                    end

                    if not b.alcohol and not b.fortune then
                        _G.ActiveRestaurantBuffs[src] = nil
                    end
                end
            end
        end
    end)
end

utils.addCustomBuffs = function(src, buffs)
    if not _G.ActiveRestaurantBuffs[src] then _G.ActiveRestaurantBuffs[src] = {} end
    
    for buff, amount in pairs(buffs) do
        if buff == 'stress' then
            bridge.relieveStress(src, amount)
        elseif buff == 'alcohol' then
            _G.ActiveRestaurantBuffs[src].alcohol = math.min(100, (_G.ActiveRestaurantBuffs[src].alcohol or 0) + amount)
            Player(src).state.restaurant_buff_alcohol = _G.ActiveRestaurantBuffs[src].alcohol
            if GetResourceState('mt_hud') == 'started' then
                exports.mt_hud:updateBuff(src, 'alcohol', 'fas fa-beer', _G.ActiveRestaurantBuffs[src].alcohol, '#E67E22')
            end
        elseif buff == 'armour' then
            TriggerClientEvent('mt_restaurants:client:addArmour', src, amount)
        elseif buff == 'fortune' then
            _G.ActiveRestaurantBuffs[src].fortune = math.min(100, (_G.ActiveRestaurantBuffs[src].fortune or 0) + amount)
            Player(src).state.restaurant_buff_fortune = _G.ActiveRestaurantBuffs[src].fortune
            if GetResourceState('mt_hud') == 'started' then
                exports.mt_hud:updateBuff(src, 'fortune', 'fas fa-clover', _G.ActiveRestaurantBuffs[src].fortune, '#2ECC71')
            end
        end
    end
end

return utils
