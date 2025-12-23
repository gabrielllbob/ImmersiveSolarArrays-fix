---@class ImmersiveSolarArrays
local ISA = require "ImmersiveSolarArrays/Utilities"

local WorldUtil = {}

---@alias ISAType
---| `PowerBank`
---| `Panel`
---| `FailSafe`

WorldUtil.ISATypes = {
    solarmod_tileset_01_0 = "PowerBank",
    solarmod_tileset_01_6 = "Panel",
    solarmod_tileset_01_7 = "Panel",
    solarmod_tileset_01_8 = "Panel",
    solarmod_tileset_01_9 = "Panel",
    solarmod_tileset_01_10 = "Panel",
    solarmod_tileset_01_15 = "Failsafe",
}

---return type of solar object
---@param isoObject IsoObject
---@return ISAType
function WorldUtil.getType(isoObject)
    if not isoObject or not isoObject.getTextureName then return nil end
    return WorldUtil.ISATypes[isoObject:getTextureName()]
end

---@param isoObject IsoObject
---@param modType ISAType
---@return boolean
function WorldUtil.objectIsType(isoObject, modType)
    if not isoObject or not isoObject.getTextureName then return false end
    return WorldUtil.ISATypes[isoObject:getTextureName()] == modType
end

---@param level number Electical skill level
---@return table
function WorldUtil.getValidBackupArea(level)
    return { radius = level, levels = level > 5 and 1 or 0 }
end

---@param square IsoGridSquare
---@param spriteName string
---@return IsoObject
function WorldUtil.findOnSquare(square, spriteName)
    if not square then return nil end
    local objects = square:getObjects()
    for i=0, objects:size()-1 do
        local object = objects:get(i)
        if object:getTextureName() == spriteName then
            return object
        end
    end
end

---@param isoObject IsoObject
---@return IsoGenerator
function WorldUtil.replaceIsoObjectWithGenerator(isoObject)
    local square = isoObject:getSquare()
    local index = isoObject:getObjectIndex()
    
    if not square or index == -1 then return IsoGenerator.new(getCell()) end

    local fullType = isoObject:getSprite():getProperties():Is("CustomItem") and isoObject:getSprite():getProperties():Val("CustomItem") 
                     or ("Moveables." .. isoObject:getTextureName())
    
    square:transmitRemoveItemFromSquare(isoObject)
    
    -- Cria o gerador na célula correta
    local generator = IsoGenerator.new(square:getCell())
    generator:setSprite(isoObject:getSprite())
    generator:setSquare(square)
    
    -- Salva o tipo original
    if generator:getModData() then
        generator:getModData().generatorFullType = fullType
    end

    square:AddSpecialObject(generator, index)
    
    -- FIX B42: Container e Combustível Seguro
    if generator.createContainersFromSpriteProperties then
        generator:createContainersFromSpriteProperties()
    end
    
    if generator:getContainer() then
        generator:getContainer():setExplored(true)
    end
    
    generator:transmitCompleteItemToClients()
    
    -- FIX B42: Evitar crash se setFuel não existir ou se usar sistema de fluidos
    if generator.setCondition then generator:setCondition(100) end
    
    if generator.setFuel then 
        generator:setFuel(100) 
    elseif generator.getFluidContainer then
        -- Na B42, talvez não precisemos encher de fluido real, pois o mod controla a energia manualmente.
        -- Se necessário, injetaríamos fluido aqui, mas deixaremos vazio para evitar erros de tipo.
    end
    
    if generator.setConnected then generator:setConnected(true) end
    
    -- Importante: Remove da lista de objetos "normais" para não duplicar, pois agora é Especial
    if generator:getCell() then
        generator:getCell():addToProcessIsoObjectRemove(generator)
    end

    return generator
end

return WorldUtil