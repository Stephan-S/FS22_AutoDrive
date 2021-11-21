ADFieldSensor = ADInheritsFrom(ADSensor)

function ADFieldSensor:new(vehicle, sensorParameters)
    local sensor = ADFieldSensor:create()
    sensor:init(vehicle, ADSensor.TYPE_FIELDBORDER, sensorParameters)

    return sensor
end

function ADFieldSensor:onUpdate(dt)
    local box = self:getBoxShape()
    local corners = self:getCorners(box)

    local onField = true
    for _, corner in pairs(corners) do
        local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, corner.x, 1, corner.z)
        local densityBits = getDensityAtWorldPos(g_currentMission.terrainDetailId, corner.x, y, corner.z)
        local densityType = bitAND(bitShiftRight(densityBits, g_currentMission.terrainDetailTypeFirstChannel), 2 ^ g_currentMission.terrainDetailTypeNumChannels - 1)

        if AutoDrive.experimentalFeatures.detectGrasField == true then
            onField = onField and (densityType ~= 0)
        else
            onField = onField and (densityType ~= g_currentMission.grassValue and densityType ~= 0)
        end
    end

    self:setTriggered(onField)

    self:onDrawDebug(box)
end
