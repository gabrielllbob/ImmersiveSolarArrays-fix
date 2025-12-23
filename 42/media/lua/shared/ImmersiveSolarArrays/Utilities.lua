---@class ImmersiveSolarArrays
---@field PBSystem_Server PowerbankSystem_Server
local ISA = {}

-- DEFINIÇÕES OBRIGATÓRIAS PARA O MOD FUNCIONAR
ISA.BatteryDefinitions = {
    ["ISA.DeepCycleBattery"] = { maxCapacity = 200, degrade = 0.033 },
    ["ISA.SuperBattery"]     = { maxCapacity = 400, degrade = 0.033 },
    ["ISA.DIYBattery"]       = { maxCapacity = 200, degrade = 0.125 },
    ["ISA.WiredCarBattery"]  = { maxCapacity = 50,  degrade = 8 },
    -- Compatibilidade com Vanilla (caso use baterias normais modificadas)
    ["Base.CarBattery1"]     = { maxCapacity = 50,  degrade = 8 },
    ["Base.CarBattery2"]     = { maxCapacity = 50,  degrade = 8 },
    ["Base.CarBattery3"]     = { maxCapacity = 50,  degrade = 8 }
}

function ISA.getBatteryDetails(item)
    if not item then return nil end
    return ISA.BatteryDefinitions[item:getFullType()]
end

-- Helpers
ISA.patchClassMetaMethod = function(class, methodName, createPatch)
    local metatable = __classmetatables[class]
    if not metatable then return end -- Falha silenciosa é melhor que crash
    local metatable__index = metatable.__index
    if not metatable__index then return end
    
    local originalMethod = metatable__index[methodName]
    metatable__index[methodName] = createPatch(originalMethod)
end

function ISA.queueFunction(eventName,fn)
    local event = Events[eventName]
    if not event then return end
    local function queueFn(...)
        event.Remove(queueFn)
        return fn(...)
    end
    event.Add(queueFn)
end

do
    local delayedProcess = ISBaseObject:derive("ISA delayedProcess")
    local meta = {__index=delayedProcess}

    function delayedProcess:new(obj)
        obj = obj or {}
        obj.event = obj.event or Events.OnTick
        setmetatable(obj,meta)
        return obj
    end

    function delayedProcess:start()
        self.event.Add(self.process)
    end

    function delayedProcess:stop()
        self.data = nil
        return self.event.Remove(self.process)
    end

    function delayedProcess.process() end

    ISA.delayedProcess = delayedProcess
end

function ISA.isDayTime()
    local time = getGameTime():getTimeOfDay()
    return time > 7 and time < 19 -- Simplificado para garantir funcionamento
end

return ISA