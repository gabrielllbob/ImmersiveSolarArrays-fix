require "TimedActions/ISBaseTimedAction"
local ISA = require "ImmersiveSolarArrays/Utilities"

local ConnectPanel = ISBaseTimedAction:derive("ISA_ConnectPanel")

function ConnectPanel:new(character, panel, luaPb)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.panel = panel
    o.powerbank = luaPb -- Coordenadas do Powerbank
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = false
    o.maxTime = o:getDuration()
    return o
end

function ConnectPanel:isValid()
    -- Verifica se o painel ainda existe no mundo
    return self.panel and self.panel:getObjectIndex() ~= -1
end

function ConnectPanel:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    -- Tempo base baseado em skill
    local electrical = self.character:getPerkLevel(Perks.Electricity)
    local minutes = SandboxVars.ISA and SandboxVars.ISA.ConnectPanelMin or 10
    return minutes * (1 - 0.095 * (electrical - 3)) * 60 -- Convertido para ticks (aprox)
end

function ConnectPanel:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self.character:reportEvent("EventLootItem")
    self.sound = self.character:getEmitter():playSound("GeneratorRepair")
end

function ConnectPanel:update()
    self.character:faceThisObject(self.panel)
end

function ConnectPanel:stop()
    if self.sound then
        self.character:getEmitter():stopSound(self.sound)
    end
    ISBaseTimedAction.stop(self)
end

function ConnectPanel:perform()
    if self.sound then
        self.character:getEmitter():stopSound(self.sound)
    end

    -- COMANDO PARA O SERVIDOR
    local args = { 
        panel = { x = self.panel:getX(), y = self.panel:getY(), z = self.panel:getZ() },
        pb = self.powerbank 
    }
    sendClientCommand(self.character, 'isa', 'connectPanel', args)

    -- Atualiza UI se necessário (opcional, mas bom pra feedback)
    HaloTextHelper.addText(self.character, "Painel Conectado", HaloTextHelper.getColorGreen())

    ISBaseTimedAction.perform(self)
end

return ConnectPanel