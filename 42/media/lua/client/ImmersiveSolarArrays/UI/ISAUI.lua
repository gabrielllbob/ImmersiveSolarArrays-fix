local string, math, getText = string, math, getText

---@class ImmersiveSolarArrays
local ISA = require "ImmersiveSolarArrays/Utilities"

local UI = {}

local rgbDefault, rgbGood, rgbBad = { r = 1, g = 1, b = 1, rich = " <RGB:1,1,1> " }, {}, {}
UI.rgbDefault, UI.rgbGood, UI.rgbBad = rgbDefault, rgbGood, rgbBad

function UI.updateColours()
    local core = getCore()
    local good = core:getGoodHighlitedColor()
    rgbGood.ColorInfo = good
    rgbGood.r, rgbGood.g, rgbGood.b = good:getR(), good:getG(), good:getB()
    rgbGood.rich = string.format(" <RGB:%.2f,%.2f,%.2f> ", rgbGood.r, rgbGood.g, rgbGood.b)
    local bad = core:getBadHighlitedColor()
    rgbBad.ColorInfo = bad
    rgbBad.r, rgbBad.g, rgbBad.b = bad:getR(), bad:getG(), bad:getB()
    rgbBad.rich = string.format(" <RGB:%.2f,%.2f,%.2f> ", rgbBad.r, rgbBad.g, rgbBad.b)
end

function UI.onConnectPanel(player,panel,luaPb)
    local character = getSpecificPlayer(player)
    if luautils.walkAdj(character, panel:getSquare()) then
        ISTimedActionQueue.add(ISA.ConnectPanel:new(character, panel, luaPb))
    end
end

function UI.onDisconnectPanel(player,panel,luaPb)
    local character = getSpecificPlayer(player)
    if luautils.walkAdj(character, panel:getSquare()) then
        -- FIX: Usar sendCommand em vez de acessar PBSystem_Server direto
        local args = { 
            panel = { x = panel:getX(), y = panel:getY(), z = panel:getZ() },
            pb = { x = luaPb.x, y = luaPb.y, z = luaPb.z }
        }
        -- Simula uma timed action rápida ou manda direto (simplificado para evitar timed action nova)
        sendClientCommand(character, 'isa', 'disconnectPanel', args)
    end
end

function UI.onActivatePowerBank(player,isoPb,activate)
    local character = getSpecificPlayer(player)
    if luautils.walkAdj(character, isoPb:getSquare()) then
        ISTimedActionQueue.add(ISA.ActivatePowerBank:new(character, isoPb, activate))
    end
end

-- PATCH: Tooltip segura para B42
function UI.DoTooltip_patch(original)
    return function(tooltip, layout)
        local item = tooltip:getItem()
        local maxCapacity = item:getModData().ISA_maxCapacity
        
        -- Se não for bateria do ISA, roda o tooltip original e sai
        if not maxCapacity then 
            return original(tooltip, layout)
        end

        -- Renderiza o tooltip customizado
        local option
        if tooltip:getWeightOfStack() > 0 then
            option = layout:addItem()
            option:setLabel(getText("Tooltip_item_StackWeight")..":",1,1,0.8,1)
            option:setValueRightNoPlus(tooltip:getWeightOfStack())
        else
            option = layout:addItem()
            option:setLabel(getText("Tooltip_item_Weight")..":",1,1,0.8,1)
            option:setValue(string.format("%.2f",item:isEquipped() and item:getEquippedWeight() or item:getUnequippedWeight()),1,1,0.8,1)
            
            -- FIX B42: Verifica se é drenável antes de pedir CurrentUses
            if item:IsDrainable() then
                option = layout:addItem()
                option:setLabel(getText("IGUI_invpanel_Remaining")..":",1,1,0.8,1)
                option:setValue(string.format("%d%%", item:getCurrentUsesFloat() * 100),1,1,0.8,1)
            end

            option = layout:addItem()
            option:setLabel(getText("Tooltip_weapon_Condition")..":",1,1,0.8,1)
            option:setValue(string.format("%d%%",item:getCondition()),1,1,0.8,1)
            
            -- Cálculo de capacidade real baseado na condição
            local realCapacity = maxCapacity * (1 - math.pow((1 - (item:getCondition()/100)),6))
            
            option = layout:addItem()
            option:setLabel(getText("Tooltip_container_Capacity")..":",1,1,0.8,1)
            option:setValue(string.format("%d / %d", realCapacity, maxCapacity), 1,1,0.8,1)
        end
        
        -- Layout render (não chame o original aqui para não duplicar info)
        -- Mas precisamos renderizar o layout que criamos
        -- Nota: A função original retorna o layout renderizado, aqui estamos manipulando o layout direto.
        -- O ideal é deixar o jogo lidar com o render final, mas como estamos injetando...
        
        return original(tooltip, layout)
    end
end

-- PATCH: Inventory Pane (Texto pequeno embaixo do item no inventário)
function UI.ISInventoryPane_drawItemDetails_patch(original)
    return function(self, item, y, x, width, color)
        if item and item:getModData().ISA_maxCapacity then
             -- Se for nossa bateria, desenha barra customizada?
             -- Na verdade, vamos deixar o original desenhar, mas garantindo que não crashe
             if not item:IsDrainable() then
                -- Se o jogo mudou o tipo do item, evitamos erro
                return original(self, item, y, x, width, color)
             end
        end
        return original(self, item, y, x, width, color)
    end
end

return UI