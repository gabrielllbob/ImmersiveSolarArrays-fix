--[[
    "isa_powerbank" server luaObject
    FIX B42: Fluid Container support, safe fuel check, dynamic battery stats
--]]

if isClient() then return end

require "Map/SGlobalObject"
local ISA = require "ImmersiveSolarArrays/Utilities"
local solarscan = require "ImmersiveSolarArrays/Powerbank/SolarScan"
local sandbox = SandboxVars.ISA

---@class PowerBankObject_Server : SGlobalObject
---@field luaSystem PowerbankSystem_Server
local PowerBank = SGlobalObject:derive("ISA_PowerBank_Server")

function PowerBank:new(luaSystem, globalObject)
    return SGlobalObject.new(self, luaSystem, globalObject)
end

function PowerBank:initNew()
    self.on = false
    self.batteries = 0
    self.charge = 0
    self.maxcapacity = 0
    self.panels = {}
    self.npanels = 0
    self.drain = 0
    self.lastHour = 0
    self.conGenerator = false 
end

function PowerBank:stateFromIsoObject(isoObject)
    self:initNew()
    self:calculateBatteryStats(isoObject:getContainer())
    self:autoConnectBackup()
    self:checkPanels()
    self:updateDrain()
    self:updateSprite()
    self:saveData(true)
end

function PowerBank:stateToIsoObject(isoObject)
    self:updateBatteries(isoObject:getContainer())
    self:updateSprite()
    isoObject:getModData().isa_pb_id = self.system:getObjectIndex(self)
    isoObject:transmitModData()
end

-- =============================================================================
-- FIX B42: HELPER DE COMBUSTÍVEL SEGURO
-- =============================================================================
local function getGeneratorFuelSafe(generator)
    if not generator then return 0 end
    
    -- Tenta o método antigo (Legacy B41)
    if generator.getFuel and generator:getFuel() then
        return generator:getFuel()
    end
    
    -- Tenta o novo sistema de fluidos (Build 42+)
    if generator.getFluidContainer and generator:getFluidContainer() then
        return generator:getFluidContainer():getAmount()
    end
    
    -- Se falhar ambos (ex: generator desconectado ou classe mudada), retorna 0 para não crashar
    return 0 
end
-- =============================================================================

function PowerBank:updateConGenerator()
    local currentHour = math.floor(getGameTime():getWorldAgeHours())
    if self.lastHour == currentHour then return end
    
    local conGenerator, square = self:getConGenerator()
    
    if conGenerator then
        -- Na B42, update() manual pode não ser estritamente necessário, mas mantemos por segurança
        if conGenerator.update then conGenerator:update() end

        -- Verifica se o Failsafe (interruptor automático) está instalado no chão
        if self.on and ISA.WorldUtil.findOnSquare(square, "solarmod_tileset_01_15") then
            local minfailsafe = self.drain
            
            -- Leitura segura do combustível
            local fuelAmount = getGeneratorFuelSafe(conGenerator)

            if conGenerator:isActivated() then
                -- Se a bateria já carregou o suficiente, desliga o gerador
                if self.charge > minfailsafe then 
                    conGenerator:setActivated(false)
                end
            else
                -- Se a bateria está crítica E tem gasolina E o gerador não está quebrado -> Liga
                if self.charge < minfailsafe and fuelAmount > 0 and conGenerator:getCondition() > 20 then 
                    conGenerator:setActivated(true) 
                end
            end
        end
        self.lastHour = currentHour
        self.conGenerator.ison = conGenerator:isActivated()
    end
end

function PowerBank:getConGenerator()
    if self.conGenerator then
        local square = getSquare(self.conGenerator.x, self.conGenerator.y, self.conGenerator.z)
        if square then
            local generator = square:getGenerator()
            -- Se não achou gerador, limpa a referência
            if not generator then 
                self.conGenerator = false 
                return nil, nil
            end
            return generator, square
        end
    end
    return nil, nil
end

function PowerBank:autoConnectBackup()
    local isoObject = self:getIsoObject()
    if not isoObject then return end
    
    local square = isoObject:getSquare()
    if square then
        -- Procura no próprio quadrado
        local generator = square:getGenerator()
        if generator then self:connectBackupGenerator(generator) return end
        
        -- Procura num raio de 1 tile (3x3)
        for x = -1, 1 do
            for y = -1, 1 do
                local sq = getSquare(square:getX() + x, square:getY() + y, square:getZ())
                if sq then
                    generator = sq:getGenerator()
                    if generator then self:connectBackupGenerator(generator) return end
                end
            end
        end
    end
end

function PowerBank:connectBackupGenerator(generator)
    if generator then
        local square = generator:getSquare()
        self.conGenerator = { x = square:getX(), y = square:getY(), z = square:getZ(), ison = generator:isActivated() }
    end
end

-- =============================================================================
-- FIX: CÁLCULO DE BATERIAS DINÂMICO (Lê Utilities.lua)
-- =============================================================================
function PowerBank:calculateBatteryStats(inventory)
    if not inventory then return end
    
    local currentCapacity = 0
    local maxCapacity = 0
    local batteries = 0
    local drain = 0

    local items = inventory:getItems()
    for i=0, items:size()-1 do
        local item = items:get(i)
        -- Busca os detalhes na tabela global que definimos no Utilities.lua
        local details = ISA.BatteryDefinitions[item:getFullType()]
        
        if details then
            batteries = batteries + 1
            
            -- Capacidade real baseada na condição do item (Bateria velha armazena menos)
            local conditionPct = item:getCondition() / 100.0
            local thisMaxCap = details.maxCapacity * conditionPct
            
            maxCapacity = maxCapacity + thisMaxCap
            
            -- Carga atual = Capacidade Máxima * O quanto está cheia (UsedDelta)
            currentCapacity = currentCapacity + (thisMaxCap * item:getUsedDelta())
            
            -- Degradação natural da bateria
            drain = drain + (details.degrade or 0)
        end
    end

    self.batteries = batteries
    self.maxcapacity = maxCapacity
    self.charge = currentCapacity
    self.drain = drain 
end
-- =============================================================================

function PowerBank:updateDrain()
    if self.on then
        local isopb = self:getIsoObject()
        if isopb then
            -- Chama o scanner de consumo
            local drain, npanels = solarscan(isopb:getSquare(), false, false)
            self.drain = drain
            self.npanels = npanels
        end
    else
        self.drain = 0
    end
end

function PowerBank:shouldDrain(isoObject)
    -- Se estiver desligado, não drena
    if not self.on then return false end
    
    -- Se o gerador de backup estiver ligado, usa o gerador, não a bateria
    if self.conGenerator and self.conGenerator.ison then return false end
    
    -- Compatibilidade: Se a energia "Hydro" (Vanilla/Modded) estiver ativa, não usa bateria
    if getWorld():isHydroPowerOn() then
        if isoObject then
            local square = isoObject:getSquare()
            if square and not square:isOutside() then return false end
        end
    end
    
    return true
end

function PowerBank:updateBatteries(container, ratio)
    if not container then return end
    
    -- Se não passou ratio, calcula
    if not ratio then 
        ratio = (self.maxcapacity > 0) and (self.charge / self.maxcapacity) or 0
    end

    local items = container:getItems()
    for i=0, items:size()-1 do
        local item = items:get(i)
        if ISA.BatteryDefinitions[item:getFullType()] then
            -- Atualiza visualmente a barra de carga da bateria
            item:setUsedDelta(ratio)
        end
    end
end

function PowerBank:checkPanels()
    if self.panels then
        for i=#self.panels, 1, -1 do
            local panelLoc = self.panels[i]
            local square = getSquare(panelLoc.x, panelLoc.y, panelLoc.z)
            if square then
                -- Verifica se o painel ainda existe
                if not ISA.WorldUtil.findOnSquare(square, "solarmod_tileset_01_6") and 
                   not ISA.WorldUtil.findOnSquare(square, "solarmod_tileset_01_7") and
                   not ISA.WorldUtil.findOnSquare(square, "solarmod_tileset_01_8") and
                   not ISA.WorldUtil.findOnSquare(square, "solarmod_tileset_01_9") and
                   not ISA.WorldUtil.findOnSquare(square, "solarmod_tileset_01_10") then
                   
                    table.remove(self.panels, i)
                    self.npanels = self.npanels - 1
                end
            end
        end
    end
end

function PowerBank:updateSprite(modCharge)
    local isoObject = self:getIsoObject()
    if not isoObject then return end

    if not modCharge then
        modCharge = (self.maxcapacity > 0) and (self.charge / self.maxcapacity) or 0
    end

    -- Altera o sprite baseado na quantidade de baterias e carga (visual feedback)
    if self.batteries == 0 then
        isoObject:setSprite("solarmod_tileset_01_0")
    elseif self.batteries <= 4 then
        if modCharge > 0.5 then isoObject:setSprite("solarmod_tileset_01_1")
        elseif modCharge > 0 then isoObject:setSprite("solarmod_tileset_01_16")
        else isoObject:setSprite("solarmod_tileset_01_32") end
    elseif self.batteries <= 8 then
        if modCharge > 0.5 then isoObject:setSprite("solarmod_tileset_01_2")
        elseif modCharge > 0 then isoObject:setSprite("solarmod_tileset_01_17")
        else isoObject:setSprite("solarmod_tileset_01_33") end
    elseif self.batteries <= 12 then
        if modCharge > 0.5 then isoObject:setSprite("solarmod_tileset_01_3")
        elseif modCharge > 0 then isoObject:setSprite("solarmod_tileset_01_18")
        else isoObject:setSprite("solarmod_tileset_01_34") end
    elseif self.batteries <= 16 then
        if modCharge > 0.5 then isoObject:setSprite("solarmod_tileset_01_4")
        elseif modCharge > 0 then isoObject:setSprite("solarmod_tileset_01_19")
        else isoObject:setSprite("solarmod_tileset_01_35") end
    else
        if modCharge > 0.5 then isoObject:setSprite("solarmod_tileset_01_5")
        elseif modCharge > 0 then isoObject:setSprite("solarmod_tileset_01_20")
        else isoObject:setSprite("solarmod_tileset_01_40") end
    end
end

-- Função placeholder para compatibilidade com o loop do sistema principal
function PowerBank:updateGenerator(charge)
    -- Na B42, não precisamos atualizar um gerador "falso" constantemente se gerenciarmos a eletricidade via IsoGenerator real.
    -- Se o mod original usava um gerador oculto para prover energia à casa, a lógica ficaria aqui.
    -- Como corrigimos o updateConGenerator, isso foca no Backup.
end

function PowerBank:saveData(transmit)
    local modData = self:getIsoObject() and self:getIsoObject():getModData()
    if modData then
        modData.on = self.on
        modData.batteries = self.batteries
        modData.charge = self.charge
        modData.maxcapacity = self.maxcapacity
        modData.drain = self.drain
        modData.npanels = self.npanels
        modData.panels = self.panels
        modData.lastHour = self.lastHour
        modData.conGenerator = self.conGenerator
        
        if transmit then
            self:getIsoObject():transmitModData()
        end
    end
end

return PowerBank