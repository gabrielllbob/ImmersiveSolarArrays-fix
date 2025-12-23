local ISA = require "ImmersiveSolarArrays/Utilities"
require "Map/CGlobalObject"

---@class PowerBankObject_Client : CGlobalObject
---@field luaSystem PowerbankSystem_Client
local PowerBank = CGlobalObject:derive("ISA_PowerBank_Client")

function PowerBank:new(luaSystem, globalObject)
    return CGlobalObject.new(self, luaSystem, globalObject)
end

function PowerBank:fromModData(modData)
    if not modData then return end
    self.on = modData["on"]
    self.batteries = modData["batteries"] or 0
    self.charge = modData["charge"] or 0
    self.maxcapacity = modData["maxcapacity"] or 0
    self.drain = modData["drain"] or 0
    self.npanels = modData["npanels"] or 0
    self.panels = modData["panels"] or {}
    self.lastHour = modData["lastHour"]
    self.conGenerator = modData["conGenerator"] -- Pode ser nil ou tabela
end

function PowerBank:shouldDrain()
    local square = self:getSquare()
    if not self.on then return false end
    
    -- Se o gerador de backup estiver ligado, o banco não drena
    if self.conGenerator and self.conGenerator.ison then return false end
    
    -- Compatibilidade com Hydrocraft ou Vanilla Hydro Power
    if getWorld():isHydroPowerOn() then
        if square and not square:isOutside() then return false end
    end
    return true
end

function PowerBank:getPanelStatus(panel)
    if not panel then return "not connected" end
    local x,y,z = panel:getX(), panel:getY(), panel:getZ()
    
    -- FIX: IsoUtils para garantir funcionamento
    if IsoUtils.DistanceToSquared(x, y, self.x, self.y) <= 400.0 and math.abs(z - self.z) <= 3 then
        if self.panels then
            for _, panelXYZ in ipairs(self.panels) do
                if x == panelXYZ.x and y == panelXYZ.y and z == panelXYZ.z then 
                    return "connected" 
                end
            end
        end
        return "not connected"
    else
        return "far"
    end
end

return PowerBank