require "Moveables/ISMoveableDefinitions"

Events.OnGameBoot.Add(function()
    local defs = ISMoveableDefinitions:getInstance()
    
    -- CORREÇÃO: Uso de ':' em vez de '.' para chamar os métodos
    defs:addScrapDefinition( "BatteryBank",  {"Base.Screwdriver"}, {}, Perks.Electricity,  2000, "Dismantle", true, 10)
    
    defs:addScrapItem( "BatteryBank", "ISA.ISAInverter", 1, 60, true )
    -- CORREÇÃO: Mudado de Radio.ElectricWire para Base.ElectricWire (padrão B41/B42)
    defs:addScrapItem( "BatteryBank", "Base.ElectricWire", 3, 80, true )
    defs:addScrapItem( "BatteryBank", "Base.ElectronicsScrap", 6, 80, true )
    defs:addScrapItem( "BatteryBank", "Base.MetalBar", 4, 70, true )
    defs:addScrapItem( "BatteryBank", "Base.SmallSheetMetal", 5, 70, true )
end)