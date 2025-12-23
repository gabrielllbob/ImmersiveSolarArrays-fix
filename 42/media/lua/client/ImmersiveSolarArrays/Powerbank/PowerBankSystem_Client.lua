require "Map/CGlobalObjectSystem"
---@class ImmersiveSolarArrays
local ISA = require "ImmersiveSolarArrays/Utilities"
local PowerBank = require "ImmersiveSolarArrays/Powerbank/PowerBankObject_Client"

---@class PowerbankSystem_Client : PowerbankSystem, CGlobalObjectSystem
local PBSystem = require("ImmersiveSolarArrays/PowerBankSystem_Shared"):new(CGlobalObjectSystem:derive("ISA_PowerBankSystem_Client"))

function PBSystem:new()
    return CGlobalObjectSystem.new(self, "isa_powerbank")
end

function PBSystem:initSystem()
    ISA.PBSystem_Client = self
    if isClient() then
        -- Atualiza visualmente as baterias e status a cada 10 minutos (jogo)
        Events.EveryTenMinutes.Add(PBSystem.updateBanksForClient)
    end
    
    -- FIX: Removido 'resetAcceptItemFunction' que não existe e causava crash.
    -- A lógica de aceitar itens já é tratada no MapObjects.lua.
end

function PBSystem:newLuaObject(globalObject)
    return PowerBank:new(self, globalObject)
end

-- Chamado pelo Java receiveNewLuaObjectAt
function PBSystem:newLuaObjectAt(x, y, z)
    -- self:noise("adding luaObject "..x..','..y..','..z)
    local globalObject = self.system:newGlobalObject(x, y, z)
    return self:newLuaObject(globalObject)
end

-- Lógica para contar geradores conectados (Backup)
function PBSystem:countGeneratorsInRange(luaPb)
    local generators = 0
    if not luaPb then return 0 end
    
    -- Definição da área de busca baseada em "Skill" ou padrão
    local level = 0 -- Cliente pode não saber o nível do dono, assume padrão ou busca local
    -- Simplificação: Usamos um raio fixo ou o do Shared se possível, aqui usaremos o padrão
    local area = { radius = 5, levels = 1, distance = 100 } -- Valores padrão seguros
    
    for ix = luaPb.x - area.radius, luaPb.x + area.radius do
        for iy = luaPb.y - area.radius, luaPb.y + area.radius do
            for iz = luaPb.z - area.levels, luaPb.z + area.levels do
                local isquare = getSquare(ix, iy, iz)
                local generator = isquare and luaPb.luaSystem:getValidBackupOnSquare(isquare)
                
                -- FIX: Uso correto de IsoUtils.DistanceToSquared
                if generator and IsoUtils.DistanceToSquared(luaPb.x, luaPb.y, luaPb.z, ix, iy, iz) <= area.distance then
                    generators = generators + 1
                end
            end
        end
    end
    return generators
end

function PBSystem.updateBanksForClient()
    local instance = PBSystem.instance
    if not instance then return end

    for i=1, instance:getLuaObjectCount() do
        local pb = instance:getLuaObjectByIndex(i-1) -- Java index começa em 0, Lua em 1. CGlobalObjectSystem usa 0-based no getByIndex? Geralmente sim.
        
        -- Segurança extra para B42
        if pb then 
            local isopb = pb:getIsoObject()
            if isopb then
                -- Atualiza dados do objeto Lua com o que veio do ModData do objeto Iso
                if isopb:getModData() then
                    pb:fromModData(isopb:getModData())
                end

                -- Atualiza visualmente o nível de carga das baterias dentro do banco
                if isopb:getContainer() then
                    local items = isopb:getContainer():getItems()
                    for v=0, items:size()-1 do
                        local item = items:get(v)
                        -- Verifica se é bateria do ISA antes de mexer
                        if item:getModData() and item:getModData().ISA_maxCapacity then
                            -- Na B42, setUsedDelta controla a barra de carga visual para itens Drainable
                            local currentCharge = pb.maxcapacity > 0 and (pb.charge / pb.maxcapacity) or 0
                            item:setUsedDelta(currentCharge)
                        end
                    end
                end
            end
        end
    end
end