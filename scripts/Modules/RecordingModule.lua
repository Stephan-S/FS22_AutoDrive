ADRecordingModule = {}

function ADRecordingModule:new(vehicle)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.vehicle = vehicle
    o.isRecording = false
    o.isDual = false
    o.lastWp = nil
    o.secondLastWp = nil
    o.isRecordingReverse = false
    o.isSubPrio = false
    o.trailerCount = 0
    return o
end

function ADRecordingModule:start(dual, subPrio)
    self.isDual = dual
    self.isSubPrio = subPrio
    self.vehicle:stopAutoDrive()
    self.flags = 0
    
    local startNodeId, _ = self.vehicle:getClosestWayPoint()
    local startNode = ADGraphManager:getWayPointById(startNodeId)

    if self.isSubPrio then
        self.flags = self.flags + AutoDrive.FLAG_SUBPRIO
    end

    local rearOffset = 0
    local _, trailerCount = AutoDrive.getTrailersOf(self.vehicle, false)
    self.trailerCount = trailerCount
    if self.trailerCount > 0 then
        rearOffset = -6
    end

    self.drivingReverse = (self.vehicle.lastSpeedReal * self.vehicle.movingDirection) < 0
    local x1, y1, z1 = getWorldTranslation(self:getRecordingPoint())
    if self.drivingReverse then
        x1, y1, z1 = localToWorld(self.vehicle.ad.specialDrivingModule:getReverseNode(), 0, 0, rearOffset)
    end
    self.lastWp = ADGraphManager:recordWayPoint(x1, y1, z1, false, false, self.drivingReverse, 0, self.flags)
    self.lastWpPosition = {}
    self.lastWpPosition.x, self.lastWpPosition.y, self.lastWpPosition.z = getWorldTranslation(self.vehicle.components[1].node)

    if AutoDrive.getSetting("autoConnectStart") then
        if startNode ~= nil then
            if ADGraphManager:getDistanceBetweenNodes(startNodeId, self.lastWp.id) < 12 then
                ADGraphManager:toggleConnectionBetween(startNode, self.lastWp, self.drivingReverse)
                if self.isDual then
                    ADGraphManager:toggleConnectionBetween(self.lastWp, startNode, self.drivingReverse)
                end
            end
        end
    end
    self.isRecording = true
    self.isRecordingReverse = self.drivingReverse
end

function ADRecordingModule:stop()
    if AutoDrive.getSetting("autoConnectEnd") then
        if self.lastWp ~= nil then
            local targetId = ADGraphManager:findMatchingWayPointForVehicle(self.vehicle)
            local targetNode = ADGraphManager:getWayPointById(targetId)
            if targetNode ~= nil then
                ADGraphManager:toggleConnectionBetween(self.lastWp, targetNode, false)
                if self.isDual then
                    ADGraphManager:toggleConnectionBetween(targetNode, self.lastWp, false)
                end
            end
        end
    end

    self.isRecording = false
    self.isRecordingReverse = false
    self.isDual = false
    self.lastWp = nil
    self.secondLastWp = nil
end

function ADRecordingModule:updateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if self.lastWp == nil or not self.isRecording or not self.vehicle.ad.stateModule:isInCreationMode() then
        return
    end

    local rearOffset = 0
    if self.trailerCount > 0 then
        rearOffset = -6
    end

    local vehicleX, _, vehicleZ = getWorldTranslation(self.vehicle.components[1].node)
    local reverseX, _, reverseZ = localToWorld(self.vehicle.ad.specialDrivingModule:getReverseNode(), 0, 0, rearOffset)
    local _, _, diffZ = worldToLocal(self.vehicle.components[1].node, self.lastWpPosition.x, self.lastWpPosition.y, self.lastWpPosition.z)

    self.drivingReverse = self.isRecordingReverse
    if self.isRecordingReverse and (diffZ < -1) then
        self.drivingReverse = false
    elseif not self.isRecordingReverse and (diffZ > 1) then
        self.drivingReverse = true
    end
    local x, y, z = getWorldTranslation(self:getRecordingPoint())

    if self.drivingReverse then
        x, y, z = localToWorld(self.vehicle.ad.specialDrivingModule:getReverseNode(), 0, 0, rearOffset)
    end

    local minDistanceToLastWayPoint = true
    if self.isRecordingReverse ~= self.drivingReverse then
        --now we want a minimum distance from the last recording position to the last recorded point
        if self.isRecordingReverse then
            minDistanceToLastWayPoint = (MathUtil.vector2Length(reverseX - self.lastWp.x, reverseZ - self.lastWp.z) > 1)
        else
            if not self.isDual and not self.isSubPrio then
                minDistanceToLastWayPoint = (MathUtil.vector2Length(vehicleX - self.lastWp.x, vehicleZ - self.lastWp.z) > 1)
            else
                minDistanceToLastWayPoint = false
            end
        end
    end

    local speedMatchesRecording = (self.vehicle.lastSpeedReal * self.vehicle.movingDirection) > 0
    if self.drivingReverse then
        speedMatchesRecording = (self.vehicle.lastSpeedReal * self.vehicle.movingDirection) < 0
    end

    if self.secondLastWp == nil then
        if MathUtil.vector2Length(x - self.lastWp.x, z - self.lastWp.z) > 3 and MathUtil.vector2Length(vehicleX - self.lastWp.x, vehicleZ - self.lastWp.z) > 3 then
            self.secondLastWp = self.lastWp
            self.lastWp = ADGraphManager:recordWayPoint(x, y, z, true, self.isDual, self.drivingReverse, self.secondLastWp.id, self.flags)
            self.lastWpPosition.x, self.lastWpPosition.y, self.lastWpPosition.z = getWorldTranslation(self.vehicle.components[1].node)
            self.isRecordingReverse = self.drivingReverse
        end
    else
        local angle = math.abs(AutoDrive.angleBetween({x = x - self.secondLastWp.x, z = z - self.secondLastWp.z}, {x = self.lastWp.x - self.secondLastWp.x, z = self.lastWp.z - self.secondLastWp.z}))
        local max_distance = 6
        if angle < 0.5 then
            max_distance = 12
        elseif angle < 1 then
            max_distance = 6
        elseif angle < 2 then
            max_distance = 4
        elseif angle < 4 then
            max_distance = 3
        elseif angle < 7 then
            max_distance = 2
        elseif angle < 14 then
            max_distance = 1
        elseif angle < 27 then
            max_distance = 0.5
        else
            max_distance = 0.25
        end

        if self.drivingReverse then
            max_distance = math.min(max_distance, 2)
        end

        if MathUtil.vector2Length(x - self.lastWp.x, z - self.lastWp.z) > max_distance and minDistanceToLastWayPoint and speedMatchesRecording then
            self.secondLastWp = self.lastWp
            self.lastWp = ADGraphManager:recordWayPoint(x, y, z, true, self.isDual, self.drivingReverse, self.secondLastWp.id, self.flags)
            self.lastWpPosition.x, self.lastWpPosition.y, self.lastWpPosition.z = getWorldTranslation(self.vehicle.components[1].node)
            self.isRecordingReverse = self.drivingReverse
        end
    end
end

function ADRecordingModule:update(dt)
end

function ADRecordingModule:getRecordingPoint()
    local reverseNode = self.vehicle.components[1].node

    if self.drivingReverse then
        reverseNode = self.vehicle.ad.specialDrivingModule:getReverseNode()
    end

    return reverseNode
end

--function ADRecordingModule:getLastRecordingPoint()
--    local reverseNode = self.vehicle.components[1].node
--    if self.isRecordingReverse then
--        reverseNode = self.vehicle.ad.specialDrivingModule:getReverseNode()
--    end
--
--    return reverseNode
--end
