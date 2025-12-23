--[[
	global and recipe functions
--]]

require "Items/AcceptItemFunction"

local ISA = require("ImmersiveSolarArrays/Utilities")
local RecipeDef = {}

function returnFalse() return false end

local function roundToNumber(x, n)
	return math.ceil(x / n - 0.5) * n
end

--- Função de decaimento para baterias
local function factor(a, b)
    return 1 - a * math.max(0, (1.3 - b) / 0.5)
end

--- ISCraftAction:addOrDropItem
local function addOrDrop(character, item)
	local inv = character:getInventory()
	if inv:getCapacityWeight() + item:getWeight() < inv:getEffectiveCapacity(character) then
		inv:AddItem(item)
	else
		character:getCurrentSquare():AddWorldInventoryItem(item,
			character:getX() %1,
			character:getY() %1,
			character:getZ() %1)
	end
end

function AcceptItemFunction.ISA_Batteries(container, item)
    -- Verifica se o tipo do item existe na nossa tabela de definições
    return ISA.BatteryDefinitions[item:getFullType()] ~= nil
end

-- Definição de baterias compatíveis (Exemplo)
RecipeDef.carBatteries = { ["Base.CarBattery1"] = true, ["Base.CarBattery2"] = true, ["Base.CarBattery3"] = true }

-- ... (Mantenha as funções de criação de bateria WireCarBattery/Unwire aqui, se houver) ...

RecipeDef.hiddenExpandedRecipes = {"ISA.Make Solar Panel","ISA.Make Inverter"}

function RecipeDef.OnInitGlobalModData()
    -- FIX: Ler SandboxVars aqui dentro, quando já é seguro
    local Sandbox = SandboxVars.ISA
    if Sandbox and Sandbox.enableExpandedRecipes then
		local manager = getScriptManager()
		for _,recipeName in ipairs(RecipeDef.hiddenExpandedRecipes) do
			local recipe = manager:getRecipe(recipeName)
			if recipe then
				recipe:setNeedToBeLearn(false)
			end
		end
	end
end

-- Registra o evento para rodar a função acima
Events.OnInitGlobalModData.Add(RecipeDef.OnInitGlobalModData)

return RecipeDef