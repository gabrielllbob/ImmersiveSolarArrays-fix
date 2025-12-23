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

-- [[ FIX B42: Lógica de Aceitação de Bateria ]]
function AcceptItemFunction.ISA_Batteries(container, item)
    -- 1. O item existe na nossa lista permitida?
    if not ISA.BatteryDefinitions[item:getFullType()] then
        return false
    end
    -- 2. É um item drenável? (Evita bugs com items convertidos em fluido)
    if not item:IsDrainable() then
        return false
    end
    return true
end

RecipeDef.hiddenExpandedRecipes = {"ISA.Make Solar Panel","ISA.Make Inverter"}

function RecipeDef.OnInitGlobalModData()
    -- [[ FIX: Leitura segura do Sandbox ]]
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

Events.OnInitGlobalModData.Add(RecipeDef.OnInitGlobalModData)

return RecipeDef