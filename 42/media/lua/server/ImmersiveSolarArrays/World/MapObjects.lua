local ISA = require "ImmersiveSolarArrays/Utilities"
local RandomWorldSpawns = require "ImmersiveSolarArrays/World/RandomWorldSpawns"

if isClient() then

    ---update isoObjects when chunk loads
    local function LoadPowerbank(isoObject)
        -- Proteção B42: Verifica se o objeto e o contentor existem antes de mexer
        if isoObject and isoObject:getContainer() then
            isoObject:getCell():addToProcessIsoObjectRemove(isoObject)
            isoObject:getContainer():setAcceptItemFunction("AcceptItemFunction.ISA_Batteries")
        end
    end
    MapObjects.OnLoadWithSprite("solarmod_tileset_01_0", LoadPowerbank, 6)

else

    ---update isoObjects when chunk loads
    local function LoadPowerbank(isoObject)
        if ISA.PBSystem_Server then
            ISA.PBSystem_Server:loadIsoObject(isoObject)
        end
        
        -- Proteção B42
        if isoObject and isoObject:getContainer() then
            isoObject:getContainer():setAcceptItemFunction("AcceptItemFunction.ISA_Batteries")
        end
    end
    MapObjects.OnLoadWithSprite("solarmod_tileset_01_0", LoadPowerbank, 6)

    ---update isoObjects when chunk loads first time
    local function OnNewWithSprite(isoObject)
        local isaType = ISA.WorldUtil.getType(isoObject)
        local square = isoObject:getSquare()
        
        if not square then 
            print("ISA WARNING: OnNewWithSprite no square found") 
            return 
        end

        if isaType == "PowerBank" then
            local index = isoObject:getObjectIndex()
            local spriteName = isoObject:getTextureName()
            square:transmitRemoveItemFromSquare(isoObject)
            RandomWorldSpawns.addToWorld(square, spriteName, index)
        else
            -- Na B42, objetos especiais são geridos de forma diferente, mas isto deve manter-se funcional
            if square:getSpecialObjects() then
                square:getSpecialObjects():add(isoObject)
            end
        end
    end
    
    -- Ouve o evento de criação de objeto no mapa
    MapObjects.OnNewWithSprite("solarmod_tileset_01_0", OnNewWithSprite, 6)
end