ADFruitSensor = ADInheritsFrom(ADSensor)

function ADFruitSensor:new(vehicle, sensorParameters)
    local o = ADFruitSensor:create()
    o:init(vehicle, ADSensor.TYPE_FRUIT, sensorParameters)
    o.fruitType = 0
    o.foundFruitType = 0

    if sensorParameters.fruitType ~= nil then
        o.fruitType = sensorParameters.fruitType
    end

    return o
end

function ADFruitSensor:onUpdate(dt)
    local box = self:getBoxShape()
    local corners = self:getCorners(box)

    local foundFruit = false
    if self.fruitType == nil or self.fruitType == 0 then
        foundFruit, _ = self:checkForFruitInArea(corners)
    else
        foundFruit = self:checkForFruitTypeInArea(self.fruitType, corners)
    end

    self:setTriggered(foundFruit)

    self:onDrawDebug(box)
end

function ADFruitSensor:checkForFruitInArea(corners)
    for i = 1, #g_fruitTypeManager.fruitTypes do
        if i ~= g_fruitTypeManager.nameToIndex["GRASS"] and i ~= g_fruitTypeManager.nameToIndex["DRYGRASS"] then
            local fruitTypeToCheck = g_fruitTypeManager.fruitTypes[i].index
            if self:checkForFruitTypeInArea(fruitTypeToCheck, corners) then
                return true, fruitTypeToCheck
            end
        end
    end
    return false
end

function ADFruitSensor:checkForFruitTypeInArea(fruitType, corners)
    local fruitValue = 0
    fruitValue, _, _, _ = FSDensityMapUtil.getFruitArea(fruitType, corners[1].x, corners[1].z, corners[2].x, corners[2].z, corners[3].x, corners[3].z, true, true)

    return (fruitValue > 10)
end

function ADFruitSensor:setFruitType(newFruitType)
    self.fruitType = newFruitType
end
