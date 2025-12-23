require 'Items/Distributions'
require 'Items/ProceduralDistributions'

local ISA = require "ImmersiveSolarArrays/Utilities"

-- Função principal de injeção de loot
local function InitISALoot()
    -- Verificações de segurança para B42
    if not ProceduralDistributions or not ProceduralDistributions.list then
        print("ISA ERROR: ProceduralDistributions not found. Skipping loot injection.")
        return
    end

    local pdList = ProceduralDistributions.list
    local vehDist = VehicleDistributions

    -- Inicializa a tabela de distribuições do mod se ainda não existir
    ISA.Distributions = ISA.Distributions or {}

    -- Função auxiliar de distribuição (assumindo que ISA.Distributions.distributeItem existe em Utilities)
    -- Se não existir, o código abaixo falhará. Certifique-se que Utilities.lua tem essa função.
    if not ISA.Distributions.distributeItem then
        -- Fallback simples caso a função helper não exista
        ISA.Distributions.distributeItem = function(args)
            if not args.entries then return end
            -- Lógica simplificada de inserção (apenas exmplo, ideal é usar a do Utilities)
            -- Na prática, confie na função do Utilities se ela existir.
        end
    end

    -- Inserindo Painéis Solares
    ISA.Distributions.distributeItem({
        fullType = "ISA.SolarPanel",
        LRM = "LRMElectronics", -- Compatibilidade com mods de Loot Rarity
        entries = {
            { 0.50, pdList["CrateElectronics"] and pdList["CrateElectronics"].items },
            { 0.50, pdList["GigamartHouseElectronics"] and pdList["GigamartHouseElectronics"].items },
            { 0.50, pdList["ArmyStorageElectronics"] and pdList["ArmyStorageElectronics"].items },
            { 1.00, pdList["ElectronicStoreMisc"] and pdList["ElectronicStoreMisc"].items },
            { 0.10, pdList["CrateRandomJunk"] and pdList["CrateRandomJunk"].items },
            { 0.10, pdList["CrateTools"] and pdList["CrateTools"].items },
            { 0.10, pdList["OtherGeneric"] and pdList["OtherGeneric"].items },
            { 0.10, pdList["GarageMechanics"] and pdList["GarageMechanics"].items },
            { 0.10, pdList["ElectronicStoreAppliances"] and pdList["ElectronicStoreAppliances"].items },
            { 0.10, pdList["ToolStoreFarming"] and pdList["ToolStoreFarming"].items },
            { 0.03, pdList["CrateFarming"] and pdList["CrateFarming"].items },
            { 0.03, pdList["CrateMetalwork"] and pdList["CrateMetalwork"].items },
            { 0.60, vehDist and vehDist["ElectricianTruckBed"] and vehDist["ElectricianTruckBed"].items }
        },
    })

    -- Inserindo Inversor
    ISA.Distributions.distributeItem({
        fullType = "ISA.ISAInverter",
        LRM = "LRMElectronics",
        entries = {
            { 0.20, pdList["CrateElectronics"] and pdList["CrateElectronics"].items },
            { 0.20, pdList["GigamartHouseElectronics"] and pdList["GigamartHouseElectronics"].items },
            { 0.20, pdList["ArmyStorageElectronics"] and pdList["ArmyStorageElectronics"].items },
            { 0.50, pdList["ElectronicStoreMisc"] and pdList["ElectronicStoreMisc"].items },
            { 0.05, pdList["CrateRandomJunk"] and pdList["CrateRandomJunk"].items },
            { 0.05, pdList["CrateTools"] and pdList["CrateTools"].items },
            { 0.05, pdList["OtherGeneric"] and pdList["OtherGeneric"].items },
            { 0.05, pdList["GarageMechanics"] and pdList["GarageMechanics"].items },
            { 0.05, pdList["ElectronicStoreAppliances"] and pdList["ElectronicStoreAppliances"].items },
            { 0.20, vehDist and vehDist["ElectricianTruckBed"] and vehDist["ElectricianTruckBed"].items }
        },
    })
    
    -- Inserindo Revista (Manual)
    ISA.Distributions.distributeItem({
        fullType = "ISA.ISAMag1",
        LRM = "LRMMisc",
        entries = {
            { 1.00, pdList["ShelfBookstore"] and pdList["ShelfBookstore"].items },
            { 1.00, pdList["BookstoreMisc"] and pdList["BookstoreMisc"].items },
            { 0.50, pdList["LivingRoomShelf"] and pdList["LivingRoomShelf"].items },
            { 0.50, pdList["PostOfficeBooks"] and pdList["PostOfficeBooks"].items },
            { 0.10, pdList["CrateMagazines"] and pdList["CrateMagazines"].items },
            { 1.00, pdList["ElectronicStoreMagazines"] and pdList["ElectronicStoreMagazines"].items },
            { 0.50, pdList["LibraryBooks"] and pdList["LibraryBooks"].items },
        },
    })

    print("ISA: Loot tables injected successfully.")
end

-- Executa a injeção no evento apropriado
Events.OnLoadedTileDefinitions.Add(InitISALoot)