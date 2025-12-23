--[[
	global and recipe functions
--]]

require "Items/AcceptItemFunction"

local ISA = require("ImmersiveSolarArrays/Utilities")
local Sandbox = SandboxVars.ISA
local RecipeDef = {}

function returnFalse() return false end

local function roundToNumber(x, n)
	return math.ceil(x / n - 0.5) * n
end

--- 衰减函数，仅适用于计算电池容量及耐久，a(factor)越小值越大，b(qualityMod)越大值越大
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

RecipeDef.carBatteries = { ["Base.CarBattery1"] = { ah = 50, degrade = 10 }, ["Base.CarBattery2"] = { ah = 100, degrade = 6 }, ["Base.CarBattery3"] = { ah = 75, degrade = 8 } }

if not Recipe.GetItemTypes then Recipe.GetItemTypes = {} end
function Recipe.GetItemTypes.wireCarBattery(scriptItems)
    local manager = getScriptManager()
    for fullType,_ in pairs(RecipeDef.carBatteries) do
        scriptItems:add(manager:getItem(fullType))
    end
end

if not Recipe.OnCreate then Recipe.OnCreate = {} end
function Recipe.OnCreate.ISA_wireCarBattery(craftRecipeData, player)
	local items = craftRecipeData:getAllConsumedItems()
	local result = craftRecipeData:getAllCreatedItems():get(0)
	for i = items:size() - 1, 0, -1 do
		local carBattery = items:get(i)
		local fullType = carBattery:getFullType()
		local batteryInfo = RecipeDef.carBatteries[fullType]
		if batteryInfo then
			local resultData = result:getModData()
			resultData.unwiredType = fullType
			if carBattery:hasModData() then
				resultData.unwiredData = carBattery:getModData()
			end
			local skillLevel = player:getPerkLevel(Perks.Electricity)
			local maxSM = math.min(10, skillLevel)
			local minSM = math.floor(math.min(maxSM, skillLevel * 0.8))
			local skillMod = ZombRand(minSM, maxSM + 1)
			local qualityMod = 0.8 + (skillMod / 10) * 0.4 + (ZombRand(0, 101) / 100 * 0.1)
			resultData.ISA_maxCapacity = roundToNumber(batteryInfo.ah * qualityMod, 5)
			resultData.ISA_BatteryDegrade = batteryInfo.degrade / qualityMod 
			result:setCurrentUsesFloat(carBattery:getCurrentUsesFloat() * factor(0.3,qualityMod))
			result:setCondition(carBattery:getCondition() * factor(0.1,qualityMod))
			break
		end
	end
end

function Recipe.OnCreate.ISA_unwireCarBattery(craftRecipeData, player)
	local items = craftRecipeData:getAllConsumedItems()
	local requiredType = "ISA.WiredCarBattery"
	local inventory = player:getInventory()
	for i=items:size()-1,0,-1 do
		local wiredBattery = items:get(i)
		local fullType = wiredBattery:getFullType()
		if fullType == requiredType then
			local oldData = wiredBattery:getModData()
			local fullType1 = oldData.unwiredType or "Base.CarBattery1"
			local item = instanceItem(fullType1)
			if oldData.unwiredData then
				local newData = item:getModData()
				for k,v in pairs(oldData.unwiredData) do
					newData[k] = v
				end
			end
			local skillLevel = player:getPerkLevel(Perks.Electricity)
			local maxSM = math.min(10, skillLevel)
			local minSM = math.floor(math.min(maxSM, skillLevel * 0.8))
			local skillMod = ZombRand(minSM, maxSM + 1)
			local qualityMod = 0.8 + (skillMod / 10) * 0.4 + (ZombRand(0, 101) / 100 * 0.1)
			item:setCurrentUsesFloat(wiredBattery:getCurrentUsesFloat() * factor(0.15,qualityMod))
			item:setCondition(wiredBattery:getCondition() * factor(0.05,qualityMod))
			addOrDrop(player,item)
			inventory:AddItems("Base.ElectricWire",1)
			break
		end
	end
end

function Recipe.OnCreate.ISA_createDiyBattery(craftRecipeData, player)
    local items = craftRecipeData:getAllConsumedItems()
    local result = craftRecipeData:getAllCreatedItems():get(0)
	local requiredType = "ISA.WiredCarBattery"
    local sumCurrentUses = 0
    local sumCount = 0
    local sumCondition = 0
    local sumCapacity = 0
	local sumDegrade = 0
    for i = items:size() - 1, 0, -1 do
        local wiredBattery = items:get(i)
		local fullType = wiredBattery:getFullType()
		if fullType == requiredType then
			local batteryModData = wiredBattery:getModData()
			sumCurrentUses = sumCurrentUses + wiredBattery:getCurrentUsesFloat()
			sumCount = sumCount + 1
			sumCapacity = sumCapacity + batteryModData.ISA_maxCapacity
			sumCondition = sumCondition + wiredBattery:getCondition()
			sumDegrade = sumDegrade + batteryModData.ISA_BatteryDegrade
		end
    end
	local multiplier = Sandbox.DIYBatteryMultiplier or 1
    local resultData = result:getModData()
	local skillLevel = player:getPerkLevel(Perks.Electricity)
	local maxSM = math.min(10, skillLevel)
	local minSM = math.floor(math.min(maxSM, skillLevel * 0.8))
	local skillMod = ZombRand(minSM, maxSM + 1)
	local qualityMod = 0.8 + (skillMod / 10) * 0.4 + (ZombRand(0, 101)/100 * 0.1)
    resultData.ISA_maxCapacity = roundToNumber(sumCapacity * math.min(qualityMod, 1) * multiplier, 5)
    resultData.ISA_BatteryDegrade = (sumDegrade / sumCount) / 64 / qualityMod
	result:setCurrentUsesFloat((sumCurrentUses / sumCount) * factor(0.15,qualityMod))
    result:setCondition(sumCondition / sumCount * factor(0.05,qualityMod))
end

function Recipe.OnCreate.ISA_ReverseSolarPanel(craftRecipeData, player)
	local inventory = player:getInventory()
    local Items = craftRecipeData:getAllConsumedItems()
    local flatType = "ISA.solarmod_tileset_01_8"
    local wallType = "ISA.solarmod_tileset_01_6"
    local mountedType = "ISA.solarmod_tileset_01_9"
	local flatType1 = "ISA.SolarPanelFlat"
    local wallType1 = "ISA.SolarPanelWall"
    local mountedType1 = "ISA.SolarPanelMounted"
    for i = Items:size() - 1, 0, -1 do
        local solarPanel = Items:get(i)
        if solarPanel then
            local panelType = solarPanel:getFullType()
            if panelType == flatType or panelType == flatType1 then
                inventory:AddItems("Base.ElectricWire",3)
				inventory:AddItems("ISA.SolarPanel",1)
            elseif panelType == wallType or panelType == wallType1 then
				inventory:AddItems("Base.ElectricWire",3)
				inventory:AddItems("Base.MetalBar",4)
				inventory:AddItems("Base.Screws",4)
				inventory:AddItems("ISA.SolarPanel",1)
            elseif panelType == mountedType or panelType == mountedType1 then
				inventory:AddItems("Base.ElectricWire",3)
				inventory:AddItems("Base.MetalBar",4)
				inventory:AddItems("Base.Screws",4)
				inventory:AddItems("ISA.SolarPanel",1)
            end
            break
        end
    end
end

RecipeDef.hiddenExpandedRecipes = {"ISA.Make Solar Panel","ISA.Make Inverter"}
function RecipeDef.OnInitGlobalModData()
	if Sandbox.enableExpandedRecipes then
		local manager = getScriptManager()
		for _,recipeName in ipairs(RecipeDef.hiddenExpandedRecipes) do
			local recipe = manager:getRecipe(recipeName)
			if recipe then
				recipe:setIsHidden(false)
				recipe:setCanPerform(nil)
			end
		end
	end
end
Events.OnInitGlobalModData.Add(RecipeDef.OnInitGlobalModData)

return RecipeDef
