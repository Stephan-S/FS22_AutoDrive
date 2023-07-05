ADDrivePathModule = {}

ADDrivePathModule.LOOKAHEADDISTANCE = 20
ADDrivePathModule.MAXLOOKAHEADPOINTS = 20
ADDrivePathModule.MAX_SPEED_DEVIATION = 6
ADDrivePathModule.MAX_STEERING_ANGLE = 30
ADDrivePathModule.PAUSE_TIMEOUT = 3000
ADDrivePathModule.BLINK_TIMEOUT = 1000

function ADDrivePathModule:new(vehicle)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.vehicle = vehicle
    o.min_distance = AutoDrive.defineMinDistanceByVehicleType(vehicle)
    o.minDistanceTimer = AutoDriveTON:new()
    o.waitTimer = AutoDriveTON:new()
    o.blinkTimer = AutoDriveTON:new()
    o.brakeHysteresisActive = false
    o.lastUsedWayPoint = nil
    ADDrivePathModule.reset(o)
    return o
end

function ADDrivePathModule:reset()
    if self.vehicle.spec_locomotive and self.vehicle.ad and self.vehicle.ad.trainModule then
        -- train
        self.vehicle.ad.trainModule:reset()
        return
    end
    self.turnAngle = 0
    self.isPaused = false
    self.atTarget = false
    self.wayPoints = nil
    self.currentWayPoint = 0
    self.onRoadNetwork = true
    self.minDistanceToNextWp = math.huge
    self.minDistanceTimer:timer(false, 5000, 0)
    self.waitTimer:timer(false, ADDrivePathModule.PAUSE_TIMEOUT, 0)
    self.blinkTimer:timer(false, ADDrivePathModule.BLINK_TIMEOUT, 0)
    self.vehicle.ad.stateModule:setCurrentWayPointId(-1)
    self.vehicle.ad.stateModule:setNextWayPointId(-1)
    self.isReversing = false
    self.vehicle:setTurnLightState(Lights.TURNLIGHT_OFF)
    self.distanceToTarget = math.huge
    self.speedLimit = 0
    self.lastUsedWayPoint = nil
end

function ADDrivePathModule:setPathTo(wayPointId)
    self.min_distance = 5 - self:getVehicleSteeringAxleOffset()
    self.wayPoints = ADGraphManager:getPathTo(self.vehicle, wayPointId, self.lastUsedWayPoint)
    local destination = ADGraphManager:getMapMarkerByWayPointId(self:getLastWayPointId())
    self.vehicle.ad.stateModule:setCurrentDestination(destination)
    self:setDirtyFlag()
    self.minDistanceToNextWp = math.huge

    if self.wayPoints == nil or (self.wayPoints[2] == nil and (self.wayPoints[1] == nil or (self.wayPoints[1] ~= nil and self.wayPoints[1].id ~= wayPointId))) then
        self.vehicle.ad.isStoppingWithError = true
        Logging.devError("[AutoDrive] Encountered a problem during initialization 'setPathTo'")

        local target = self.vehicle.ad.stateModule:getFirstMarker().name
        local mapMarker = ADGraphManager:getMapMarkerByWayPointId(wayPointId)
        if mapMarker ~= nil and mapMarker.name ~= nil then
            target = mapMarker.name
        end

        AutoDriveMessageEvent.sendMessageOrNotification(self.vehicle, ADMessagesManager.messageTypes.ERROR, "$l10n_AD_Driver_of; %s $l10n_AD_cannot_reach; %s", 5000, self.vehicle.ad.stateModule:getName(), target)
        self.vehicle.ad.taskModule:abortAllTasks()
        self.vehicle.ad.taskModule:addTask(StopAndDisableADTask:new(self.vehicle))
    else
        --skip first wp for a smoother start
        if self.wayPoints[2] ~= nil then
            self:setCurrentWayPointIndex(2)
        else
            self:setCurrentWayPointIndex(1)
        end

        if not self.vehicle.ad.trailerModule:isActiveAtTrigger() then
            self:setUnPaused()
        end

        self.atTarget = false
    end
    self:resetIsReversing()
end

function ADDrivePathModule:appendPathTo(startWayPointId, wayPointId)
    local appendWayPoints = ADGraphManager:getPathTo(self.vehicle, wayPointId)

    if appendWayPoints == nil or (appendWayPoints[2] == nil and (appendWayPoints[1] == nil or (appendWayPoints[1] ~= nil and appendWayPoints[1].id ~= wayPointId))) then
        self.vehicle.ad.isStoppingWithError = true
        Logging.devError("[AutoDrive] Encountered a problem during initialization 'appendPathTo'")

        local target = self.vehicle.ad.stateModule:getFirstMarker().name
        local mapMarker = ADGraphManager:getMapMarkerByWayPointId(wayPointId)
        if mapMarker ~= nil and mapMarker.name ~= nil then
            target = mapMarker.name
        end

        AutoDriveMessageEvent.sendMessageOrNotification(self.vehicle, ADMessagesManager.messageTypes.ERROR, "$l10n_AD_Driver_of; %s $l10n_AD_cannot_reach; %s", 5000, self.vehicle.ad.stateModule:getName(), target)
        self.vehicle.ad.taskModule:abortAllTasks()
        self.vehicle.ad.taskModule:addTask(StopAndDisableADTask:new(self.vehicle))
    else
        --skip first wp for a smoother start
        for _, wp in ipairs(appendWayPoints) do
            table.insert(self.wayPoints, wp)
        end
    end
    self:resetIsReversing()
end

function ADDrivePathModule:setWayPoints(wayPoints)
    self.wayPoints = wayPoints
    local destination = ADGraphManager:getMapMarkerByWayPointId(self:getLastWayPointId())
    self.vehicle.ad.stateModule:setCurrentDestination(destination)
    self.minDistanceToNextWp = math.huge
    self.atTarget = false
    if self.wayPoints[2] ~= nil then
        self:setCurrentWayPointIndex(2)
    else
        self:setCurrentWayPointIndex(1)
    end
    self:resetIsReversing()
    if self.wayPoints == nil or #self.wayPoints < 0 then
        self.atTarget = true
    end
    self.speedLimit = self.vehicle.ad.stateModule:getSpeedLimit()
    self.distanceToTarget = self:getDistanceToLastWaypoint(40)
end

function ADDrivePathModule:setPaused()
    self.isPaused = true
    self.waitTimer:timer(false)
end

function ADDrivePathModule:setUnPaused()
    self.isPaused = false
end

function ADDrivePathModule:setDirtyFlag()
    self.wayPointsDirtyFlag = true
end

function ADDrivePathModule:resetDirtyFlag()
    self.wayPointsDirtyFlag = false
end

function ADDrivePathModule:update(dt)
    if self.vehicle.spec_locomotive and self.vehicle.ad and self.vehicle.ad.trainModule then
        -- train new
        self.vehicle.ad.trainModule:update(dt)
        return
    end
    if self.waitTimer:timer(self.isPaused, ADDrivePathModule.PAUSE_TIMEOUT, dt) then        -- used to wait for the CP silo compacter
        self:setUnPaused()
    end
    if self.isPaused then
        self.vehicle.ad.specialDrivingModule:stopVehicle()
        self.vehicle.ad.specialDrivingModule:update(dt)
        return
    end

    if self.wayPoints ~= nil and self:getCurrentWayPointIndex() <= #self.wayPoints then
        if self.isReversing then
            self.vehicle.ad.specialDrivingModule:handleReverseDriving(dt)
        else
            self:followWaypoints(dt)
            self:checkIfStuck(dt)

            if self:isCloseToWaypoint() then
                local reverseStart, _ = self:checkForReverseSection()
                if reverseStart then
                    self.isReversing = not self.isReversing
                    self.vehicle.ad.specialDrivingModule:reset()
                    self.vehicle.ad.specialDrivingModule.currentWayPointIndex = self:getCurrentWayPointIndex() + 1
                else
                    self:handleReachedWayPoint()
                end
            end
        end

        self:checkActiveAttributesSet(dt)
    else
        --keep calling the reverse function as it is also handling the bunkersilo unload, even after reaching the target
        if self.isReversing then
            self.vehicle.ad.specialDrivingModule:handleReverseDriving(dt)
        end
    end
end

function ADDrivePathModule:getIsReversing()
    return self.isReversing
end

function ADDrivePathModule:resetIsReversing()
    self.isReversing = false
    self.vehicle.ad.specialDrivingModule:reset()
end

function ADDrivePathModule:getVehicleSteeringAxleOffset()
    if self.steeringAxleOffset == nil then
        local spec = self.vehicle.spec_wheels
    
        local rotateableWheels = 0
        local diffXSum, diffZSum = 0, 0
    
        for _, wheel in pairs(spec.wheels) do
            if wheel.rotMax > 0.01 then
                rotateableWheels = rotateableWheels + 1
    
                local xs, ys, zs = getWorldTranslation(wheel.driveNode)
                local diffX, _, diffZ = worldToLocal(self.vehicle.components[1].node, xs, ys, zs)
                diffXSum = diffXSum + diffX
                diffZSum = diffZSum + diffZ
            end
        end
    
        if rotateableWheels > 0 then
            self.steeringAxleOffset = (diffZSum) / rotateableWheels
        else
            self.steeringAxleOffset = 2
        end
    end    

    return self.steeringAxleOffset --localToWorld(self.vehicle.components[1].node, steeringAxleX, steeringAxleY, steeringAxleZ)
end

function ADDrivePathModule:isCloseToWaypoint()
    local x, _, z = getWorldTranslation(self.vehicle.components[1].node)    

    local maxSkipWayPoints = 1
    for i = 0, maxSkipWayPoints do
        if self.wayPoints[self:getCurrentWayPointIndex() + i] ~= nil then
            local distanceToCurrentWp = MathUtil.vector2Length(x - self.wayPoints[self:getCurrentWayPointIndex() + i].x, z - self.wayPoints[self:getCurrentWayPointIndex() + i].z)
            if distanceToCurrentWp < self.min_distance  then --and i == 0
                return true
            end
            -- Check if the angle between vehicle and current wp and current wp to next wp is over 90° - then we should already make the switch
            if i == 1 then
                local wp_ahead = self:getNextWayPoint()
                local wp_current = self:getCurrentWayPoint()

                local angle = AutoDrive.angleBetween({x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z}, {x = wp_current.x - x, z = wp_current.z - z})
                angle = math.abs(angle)

                local isReverseStart = wp_ahead.incoming ~= nil and (not table.contains(wp_ahead.incoming, wp_current.id))
                if angle >= 90 and not isReverseStart then
                    return true
                end
            end
        end
    end
    return false
end

function ADDrivePathModule:followWaypoints(dt)
    local x, y, z = getWorldTranslation(self.vehicle.components[1].node)
    local maxSpeedDiff = ADDrivePathModule.MAX_SPEED_DEVIATION
    self.acceleration = 1
    self.distanceToLookAhead = 8

    if ((g_updateLoopIndex + self.vehicle.id) % AutoDrive.PERF_FRAMES_HIGH == 0) then
        self.speedLimit = self.vehicle.ad.stateModule:getSpeedLimit()
        if AutoDrive.checkIsOnField(x, y, z) then
            self.speedLimit = self.vehicle.ad.stateModule:getFieldSpeedLimit() --math.min(self.vehicle.ad.stateModule:getFieldSpeedLimit(), self.speedLimit)
        end
        if self.wayPoints[self:getCurrentWayPointIndex() - 1] ~= nil and self:getNextWayPoint() ~= nil then
            local highestAngle = self:getHighestApproachingAngle()

            if self:isOnRoadNetwork() then
                self.speedLimit = math.min(self.speedLimit, self:getMaxSpeedForAngle(highestAngle))
            else
                -- Let's increase the cornering speed for paths generated with the pathfinder module. There are many 45° angles in there that slow the process down otherwise.
                self.speedLimit = math.min(self.speedLimit, math.max(12, self:getMaxSpeedForAngle(highestAngle) * 2))
            end
        end

        self.distanceToTarget = self:getDistanceToLastWaypoint(40)
        if self.distanceToTarget < self.distanceToLookAhead then
            local currentTask = self.vehicle.ad.taskModule:getActiveTask()
            local isCatchingCombine = currentTask.taskType ~= nil and self.vehicle.ad.taskModule:getActiveTask().taskType == "CatchCombinePipeTask"
            if not isCatchingCombine then
                local min_speed = math.min(8, 2 + self.distanceToTarget)
                local max_speed = math.max(8, 2 + self.distanceToTarget)
                self.speedLimit = MathUtil.clamp(self.speedLimit, min_speed, max_speed)
            end
        end

        if self:isOnRoadNetwork() then
            self.speedLimit = math.min(self.speedLimit, self:getSpeedLimitBySteeringAngle())
        else
            -- Let's increase the cornering speed for paths generated with the pathfinder module. There are many 45° angles in there that slow the process down otherwise.
            self.speedLimit = math.min(self.speedLimit, self:getSpeedLimitBySteeringAngle() * 1.5)
        end

        if self.vehicle.ad.trailerModule:isUnloadingToBunkerSilo() then
            -- drive through bunker silo
            self.speedLimit = math.min(self.vehicle.ad.trailerModule:getBunkerSiloSpeed(), self.speedLimit)
            maxSpeedDiff = 1
        else
            if self.distanceToTarget < (AutoDrive.MAX_BUNKERSILO_LENGTH + AutoDrive.getSetting("maxTriggerDistance")) and AutoDrive.isVehicleInBunkerSiloArea(self.vehicle) then
                -- vehicle enters drive through bunker silo
                self.speedLimit = math.min(12, self.speedLimit)
                maxSpeedDiff = 3
            else
                local isInRangeToLoadUnloadTarget = AutoDrive.isInRangeToLoadUnloadTarget(self.vehicle) and self.distanceToTarget <= AutoDrive.getSetting("maxTriggerDistance")
                if isInRangeToLoadUnloadTarget == true then
                    self.speedLimit = math.min(5, self.speedLimit)
                end
            end
        end
    end

    local maxAngle = 60
    if self.vehicle.maxRotation then
        if self.vehicle.maxRotation > (2 * math.pi) then
            maxAngle = self.vehicle.maxRotation
        else
            maxAngle = math.deg(self.vehicle.maxRotation)
        end
    end

    self.targetX, self.targetZ = self:getLookAheadTarget()
    local lx, lz = AIVehicleUtil.getDriveDirection(self.vehicle.components[1].node, self.targetX, y, self.targetZ)

    if self.vehicle.ad.collisionDetectionModule:hasDetectedObstable(dt) then
        self.vehicle.ad.specialDrivingModule:stopVehicle((not self:isOnRoadNetwork()), lx, lz)
        self.vehicle.ad.specialDrivingModule:update(dt)
    else
        self.vehicle.ad.specialDrivingModule:releaseVehicle()
        local speedDiff = (self.vehicle.lastSpeedReal * 3600) - self.speedLimit
        -- Allow active braking if vehicle is not 'following' targetSpeed precise enough
        if speedDiff <= 0.25 then
            self.brakeHysteresisActive = false
        end
        if (speedDiff > maxSpeedDiff) or self.brakeHysteresisActive then
            self.brakeHysteresisActive = true
            
            self.acceleration = -math.min(0.6, speedDiff * 0.05)
        end
        
        ADDrawingManager:addLineTask(x, y, z, self.targetX, y, self.targetZ, 1, 0, 0)
        if self.vehicle.startMotor then
            if not self.vehicle:getIsMotorStarted() and self.vehicle:getCanMotorRun() and not self.vehicle.ad.specialDrivingModule:shouldStopMotor() then
                self.vehicle:startMotor()
            end
        end
        self.vehicle.ad.trailerModule:handleTrailerReversing(false)
        AutoDrive.driveInDirection(self.vehicle, dt, maxAngle, self.acceleration, 0.8, maxAngle, true, true, lx, lz, self.speedLimit, 1)
    end
end

function ADDrivePathModule:handleReachedWayPoint()    
    self.lastUsedWayPoint = self:getCurrentWayPoint()
    if self:getNextWayPoint() ~= nil then
        self:switchToNextWayPoint()
    else
        self:reachedTarget()
    end
end

function ADDrivePathModule:reachedTarget()
    self.atTarget = true
    self.wayPoints = nil
    self.currentWayPoint = 0
end

function ADDrivePathModule:isTargetReached()
    if self.vehicle.spec_locomotive and self.vehicle.ad and self.vehicle.ad.trainModule then
        -- train
        return self.vehicle.ad.trainModule:isTargetReached()
    end
    return self.atTarget
end

-- To differentiate between waypoints on the road and ones created from pathfinder
function ADDrivePathModule:isOnRoadNetwork()
    return (self.wayPoints ~= nil and self:getCurrentWayPoint() ~= nil and not self:getCurrentWayPoint().isPathFinderPoint)
end

function ADDrivePathModule:getWayPoints()
    return self.wayPoints, self:getCurrentWayPointIndex()
end

function ADDrivePathModule:getLastWayPoint()
    if self.wayPoints ~= nil then
        return self.wayPoints[#self.wayPoints]
    end
    return nil
end

function ADDrivePathModule:getLastWayPointId()
    local lastWp = self:getLastWayPoint()
    if lastWp ~= nil then
        return lastWp.id
    end
    return -1
end

function ADDrivePathModule:getCurrentLookAheadDistance()
    local totalMass = self.vehicle:getTotalMass(false)
    local massFactor = math.max(1, math.min(3, (totalMass + 20) / 30))
    local speedFactor = math.max(0.25, math.min(4, (((self.vehicle.lastSpeedReal * 3600) + 10) / 20.0)))
    if speedFactor <= 1 then
        massFactor = math.min(speedFactor, massFactor)
    end
    return math.min(ADDrivePathModule.LOOKAHEADDISTANCE * massFactor * speedFactor, 150)
end

function ADDrivePathModule:getHighestApproachingAngle()
    self.turnAngle = 0
    self.distanceToLookAhead = self:getCurrentLookAheadDistance()
    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_DEVINFO, "ADDrivePathModule:getHighestApproachingAngle -> Lookahead distance: " .. self.distanceToLookAhead)
    local pointsToLookAhead = ADDrivePathModule.MAXLOOKAHEADPOINTS
    local x, y, z = getWorldTranslation(self.vehicle.components[1].node)

    if self:getCurrentWayPointIndex() + 2 >= #self.wayPoints then
        return 0
    end

    local baseDistance = MathUtil.vector2Length(self:getCurrentWayPoint().x - x, self:getCurrentWayPoint().z - z)

    local highestAngle = 0
    local doneCheckingRoute = false
    local currentLookAheadPoint = 1
    while not doneCheckingRoute and currentLookAheadPoint <= pointsToLookAhead do
        if self.wayPoints[self:getCurrentWayPointIndex() + currentLookAheadPoint] ~= nil then
            local wp_ahead = self.wayPoints[self:getCurrentWayPointIndex() + currentLookAheadPoint]
            local wp_current = self.wayPoints[self:getCurrentWayPointIndex() + currentLookAheadPoint - 1]
            local wp_ref = self.wayPoints[self:getCurrentWayPointIndex() + currentLookAheadPoint - 2]
            
            AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_DEVINFO, "ADDrivePathModule:getHighestApproachingAngle -> wp_ahead: " .. wp_ahead.x .. " / " .. wp_ahead.z)
            AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_DEVINFO, "ADDrivePathModule:getHighestApproachingAngle -> wp_current: " .. wp_current.x .. " / " .. wp_current.z)
            AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_DEVINFO, "ADDrivePathModule:getHighestApproachingAngle -> wp_ref: " .. wp_ref.x .. " / " .. wp_ref.z)

            local angle = AutoDrive.angleBetween({x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z}, {x = wp_current.x - wp_ref.x, z = wp_current.z - wp_ref.z})
            
            AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_DEVINFO, "ADDrivePathModule:getHighestApproachingAngle -> angle: " .. angle)

            self.turnAngle = self.turnAngle + MathUtil.clamp(angle, -90, 90)

            angle = math.abs(angle)

            if MathUtil.vector2Length(self:getCurrentWayPoint().x - wp_ahead.x, self:getCurrentWayPoint().z - wp_ahead.z) <= (self.distanceToLookAhead - baseDistance) then
                if angle < 180 then
                    highestAngle = math.max(highestAngle, angle)
                end
            else
                doneCheckingRoute = true
            end
        else
            doneCheckingRoute = true
        end
        currentLookAheadPoint = currentLookAheadPoint + 1
    end

    return highestAngle

    --new function. Take the angle of the current ref node and then go through x-points until the distance (not geometric but pathwise) is bigger than y-
    -- 1.) Take the angle of the current ref node and then go through x-points until the distance (not geometric but pathwise) is bigger than y
    -- 2.) Increase ref node index
    -- 3.) Repeat until either index > ADDrivePathModule.MAXLOOKAHEADPOINTS or ref node distance (geometric) > distanceToLookAhead
    --[[
    local refNodeIndex = self:getCurrentWayPointIndex()
    local lookAheadIndex = 1
    local wp_ref = self.wayPoints[refNodeIndex]
    local refNodeDistance = MathUtil.vector2Length(wp_ref.x - x, wp_ref.z - z)
    local wp_current = self.wayPoints[refNodeIndex + lookAheadIndex]
    local wp_ahead = self.wayPoints[refNodeIndex + lookAheadIndex + 1]
    local refVector = {x = wp_current.x - wp_ref.x, z = wp_current.z - wp_ref.z}
    local nextVector = {x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z}
    local maxAngle = math.abs(AutoDrive.angleBetween(nextVector, refVector))

    while refNodeIndex < (self:getCurrentWayPointIndex() + self.MAXLOOKAHEADPOINTS) and refNodeDistance < self.distanceToLookAhead and (refNodeIndex + 1) < #self.wayPoints do
        lookAheadIndex = 1
        while self:getDistanceBetweenWayPoints(refNodeIndex, refNodeIndex + lookAheadIndex) < 15 and (refNodeIndex + lookAheadIndex + 1) < #self.wayPoints do
            wp_current = self.wayPoints[refNodeIndex + lookAheadIndex]
            wp_ahead = self.wayPoints[refNodeIndex + lookAheadIndex + 1]
            nextVector = {x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z}
            maxAngle = math.max(maxAngle, math.abs(AutoDrive.angleBetween(nextVector, refVector)))
            
            lookAheadIndex = lookAheadIndex + 1
        end
        refNodeIndex = refNodeIndex + 1
        wp_ref = self.wayPoints[refNodeIndex]
        refNodeDistance = self:getDistanceBetweenWayPoints(self:getCurrentWayPointIndex(), refNodeIndex)
        wp_current = self.wayPoints[refNodeIndex + 1]
        refVector = {x = wp_current.x - wp_ref.x, z = wp_current.z - wp_ref.z}
    end
    --print("MaxAngle: " .. maxAngle)
    return maxAngle
    --]]
end

function ADDrivePathModule:getDistanceBetweenWayPoints(indexStart, indexTarget)
    local distance = 0
    while indexStart < indexTarget do
        local wpStart = self.wayPoints[indexStart]
        local wpNext = self.wayPoints[indexStart + 1]
        distance = distance + MathUtil.vector2Length(wpStart.x - wpNext.x, wpStart.z - wpNext.z)
        indexStart = indexStart + 1
    end

    return distance
end

function ADDrivePathModule:getApproachingHeightDiff()
    local heightDiff = 0
    local maxLookAhead = 10
    local maxLookAheadDistance = 20
    local lookAhead = 1
    for i = 1, maxLookAhead do
        if self.wayPoints ~= nil and self:getCurrentWayPointIndex() ~= nil and self:getCurrentWayPoint() ~= nil and (self:getCurrentWayPointIndex() + lookAhead) <= #self.wayPoints then
            local p1 = self.wayPoints[self:getCurrentWayPointIndex()]
            local p2 = self.wayPoints[self:getCurrentWayPointIndex() + lookAhead]
            local refNodeDistance = self:getDistanceBetweenWayPoints(self:getCurrentWayPointIndex(), self:getCurrentWayPointIndex() + lookAhead)
            if refNodeDistance <= maxLookAheadDistance then
                heightDiff = heightDiff + (p2.y - p1.y)
            end
            lookAhead = lookAhead + 1
        end
    end
    return heightDiff
end

function ADDrivePathModule:getMaxSpeedForAngle(angle)
    local maxSpeed = math.huge

    if angle < 5 then
        maxSpeed = math.huge
    elseif angle < 50 then
        maxSpeed = 12 + 48 * (1 - MathUtil.clamp((angle - 5), 0, 25) / (30 - 5))
    elseif angle >= 50 then
        maxSpeed = 3
    end

    self.maxAngle = angle
    self.maxAngleSpeed = maxSpeed * 1.0 * AutoDrive.getSetting("cornerSpeed", self.vehicle)

    return self.maxAngleSpeed
end

function ADDrivePathModule:getSpeedLimitBySteeringAngle()
    local steeringAngle = math.deg(math.abs(self.vehicle.rotatedTime))

    local maxSpeed = math.huge

    local maxAngle = 60
    if self.vehicle.maxRotation then
        if self.vehicle.maxRotation > (2 * math.pi) then
            maxAngle = self.vehicle.maxRotation
        else
            maxAngle = math.deg(self.vehicle.maxRotation)
        end
    end

    if steeringAngle > maxAngle * 0.95 then
        maxSpeed = 10
    end
    return maxSpeed
end

function ADDrivePathModule:getDistanceToLastWaypoint(maxLookAheadPar)
    local distance = math.huge
    local maxLookAhead = maxLookAheadPar
    if maxLookAhead == nil then
        maxLookAhead = 10
    end

    if self.wayPoints ~= nil and self:getCurrentWayPointIndex() ~= nil and self:getCurrentWayPoint() ~= nil and (self:getCurrentWayPointIndex() + maxLookAheadPar) >= #self.wayPoints then
        distance = 0
        local lookAhead = 1
        while self.wayPoints[self:getCurrentWayPointIndex() + lookAhead] ~= nil and lookAhead < maxLookAhead do
            local p1 = self.wayPoints[self:getCurrentWayPointIndex() + lookAhead]
            local p2 = self.wayPoints[self:getCurrentWayPointIndex() + lookAhead - 1]
            local pointDistance = MathUtil.vector2Length(p2.x - p1.x, p2.z - p1.z)
            if pointDistance ~= nil then
                distance = distance + pointDistance
            end
            lookAhead = lookAhead + 1
        end
    end

    return distance
end

function ADDrivePathModule:getNextWayPoint()
    return self.wayPoints[self:getNextWayPointIndex()]
end

function ADDrivePathModule:getNextWayPointId()
    local nWp = self:getNextWayPoint()
    if nWp ~= nil and nWp.id ~= nil then
        return nWp.id
    end
    return -1
end

function ADDrivePathModule:getNextWayPoints()
    local cId = self:getCurrentWayPointIndex()
    return self.wayPoints[cId + 1], self.wayPoints[cId + 2], self.wayPoints[cId + 3], self.wayPoints[cId + 4], self.wayPoints[cId + 5]
end

function ADDrivePathModule:setCurrentWayPointIndex(waypointId)
    self.currentWayPoint = waypointId
    self.vehicle.ad.stateModule:setCurrentWayPointId(self:getCurrentWayPointId())
    self.vehicle.ad.stateModule:setNextWayPointId(self:getNextWayPointId())
end

function ADDrivePathModule:getCurrentWayPointIndex()
    return self.currentWayPoint
end

function ADDrivePathModule:getCurrentWayPoint()
    if self.wayPoints ~= nil then
        return self.wayPoints[self:getCurrentWayPointIndex()]
    end

    return nil
end

function ADDrivePathModule:getCurrentWayPointId()
    local nWp = self:getCurrentWayPoint()
    if nWp ~= nil and nWp.id ~= nil then
        return nWp.id
    end
    return -1
end

function ADDrivePathModule:getNextWayPointIndex()
    return self:getCurrentWayPointIndex() + 1
end

function ADDrivePathModule:switchToNextWayPoint()
    self:setCurrentWayPointIndex(self:getNextWayPointIndex())
    self.minDistanceToNextWp = math.huge

    local _, reverseEnd = self:checkForReverseSection()
    if reverseEnd and self.isReversing then
        self.isReversing = false --not self.isReversing
        self.vehicle.ad.specialDrivingModule:reset()
        self.vehicle.ad.specialDrivingModule.currentWayPointIndex = self:getCurrentWayPointIndex()
    end
end

function ADDrivePathModule:getLookAheadTarget()
    --start driving to the nextWayPoint when closing in on current waypoint in order to avoid harsh steering angles and oversteering

    local x, _, z = getWorldTranslation(self.vehicle.components[1].node)
    local targetX = x
    local targetZ = z

    local wp_current = self:getCurrentWayPoint()

    if wp_current ~= nil then
        targetX = wp_current.x
        targetZ = wp_current.z
    end

    if self:getNextWayPoint() ~= nil and (self:getNextWayPoint().incoming == nil or #self:getNextWayPoint().incoming > 0) then
        local lookAheadID = 1
        local lookAheadDistance = AutoDrive.getSetting("lookAheadTurning") + self.min_distance
        local distanceToCurrentTarget = MathUtil.vector2Length(x - wp_current.x, z - wp_current.z)

        local wp_ahead = self.wayPoints[self:getCurrentWayPointIndex() + lookAheadID]
        local distanceToNextTarget = MathUtil.vector2Length(wp_current.x - wp_ahead.x, wp_current.z - wp_ahead.z)

        lookAheadDistance = lookAheadDistance - distanceToCurrentTarget

        while lookAheadDistance > distanceToNextTarget do
            lookAheadDistance = lookAheadDistance - distanceToNextTarget
            lookAheadID = lookAheadID + 1
            if self.wayPoints[self:getCurrentWayPointIndex() + lookAheadID] == nil then
                break
            end
            wp_current = wp_ahead
            wp_ahead = self.wayPoints[self:getCurrentWayPointIndex() + lookAheadID]
            distanceToNextTarget = MathUtil.vector2Length(wp_current.x - wp_ahead.x, wp_current.z - wp_ahead.z)
        end

        local distX = wp_ahead.x - wp_current.x
        local distZ = wp_ahead.z - wp_current.z
        if lookAheadDistance > 0 then
            local addX = lookAheadDistance * (math.abs(distX) / (math.abs(distX) + math.abs(distZ)))
            local addZ = lookAheadDistance * (math.abs(distZ) / (math.abs(distX) + math.abs(distZ)))
            if distX < 0 then
                addX = -addX
            end

            if distZ < 0 then
                addZ = -addZ
            end

            if (math.abs(distX) + math.abs(distZ)) > 0 then
                targetX = wp_current.x + addX
                targetZ = wp_current.z + addZ
            end
        end
    end

    return targetX, targetZ
end

function ADDrivePathModule:checkActiveAttributesSet(dt)
    if self.vehicle.isServer then
        self.vehicle.forceIsActive = true
        self.vehicle.spec_motorized.stopMotorOnLeave = false
        self.vehicle.spec_enterable.disableCharacterOnLeave = false

        if self.vehicle.spec_aiVehicle ~= nil and self.vehicle.spec_aiVehicle.aiTrafficCollisionTranslation ~= nil then
            self.vehicle.spec_aiVehicle.aiTrafficCollisionTranslation[2] = -1000
        end

        if ((g_updateLoopIndex + self.vehicle.id) % AutoDrive.PERF_FRAMES == 0) then
            if self.vehicle.setBeaconLightsVisibility ~= nil and AutoDrive.getSetting("useBeaconLights", self.vehicle) then
                local x, y, z = getWorldTranslation(self.vehicle.components[1].node)
                if not AutoDrive.checkIsOnField(x, y, z) and self.vehicle.spec_motorized.isMotorStarted then
                    self.vehicle:setBeaconLightsVisibility(true)
                else
                    self.vehicle:setBeaconLightsVisibility(false)
                end
            end
            local blinkangle = AutoDrive.getSetting("blinkValue") or 0

            if blinkangle > 0 then
                if self.blinkTimer:timer(math.abs(self.turnAngle) < blinkangle, ADDrivePathModule.BLINK_TIMEOUT, dt * AutoDrive.PERF_FRAMES) then -- Rough estimate for the dt time. But should be fine
                    self.vehicle:setTurnLightState(Lights.TURNLIGHT_OFF)
                else
                    if self.turnAngle > blinkangle and self:isOnRoadNetwork() then
                        self.vehicle:setTurnLightState(Lights.TURNLIGHT_LEFT)
                    elseif self.turnAngle < - blinkangle and self:isOnRoadNetwork() then
                        self.vehicle:setTurnLightState(Lights.TURNLIGHT_RIGHT)
                    end
                end
            end
        end

    end
end

function ADDrivePathModule:checkIfStuck(dt)
    if self.vehicle.isServer then
        local wp = self:getCurrentWayPoint()
        if not self.vehicle.ad.specialDrivingModule:isStoppingVehicle() and wp ~= nil then
            local x, _, z = getWorldTranslation(self.vehicle.components[1].node)
            local distanceToNextWayPoint = MathUtil.vector2Length(x - wp.x, z - wp.z)
            self.minDistanceTimer:timer(distanceToNextWayPoint >= self.minDistanceToNextWp, 8000, dt)
            self.minDistanceToNextWp = math.min(self.minDistanceToNextWp, distanceToNextWayPoint)
            if self.minDistanceTimer:done() then
                self:handleBeingStuck()
            end
        else
            self.minDistanceTimer:timer(false)
        end
    end
end

function ADDrivePathModule:handleBeingStuck()
    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "handleBeingStuck")
    if self.vehicle.isServer then
        self.vehicle.ad.taskModule:stopAndRestartAD()
    end
end

function ADDrivePathModule:checkForReverseSection()
    local reverseStart = false
    local reverseEnd = false
    if self.wayPoints ~= nil and #self.wayPoints > self:getCurrentWayPointIndex() + 1 and self:getCurrentWayPointIndex() > 1 then
        local wp_ahead = self.wayPoints[self:getCurrentWayPointIndex() + 1]
        local wp_current = self.wayPoints[self:getCurrentWayPointIndex() - 0]
        local wp_ref = self.wayPoints[self:getCurrentWayPointIndex() - 1]
        local isReverseStart = (wp_ahead.incoming ~= nil and (not table.contains(wp_ahead.incoming, wp_current.id))) or (wp_ahead.isReverse ~= nil and wp_ahead.isReverse == true)
        local isReverseEnd = wp_ahead.incoming ~= nil and wp_current.incoming ~= nil and table.contains(wp_ahead.incoming, wp_current.id) and not table.contains(wp_current.incoming, wp_ref.id)

        local angle = AutoDrive.angleBetween({x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z}, {x = wp_current.x - wp_ref.x, z = wp_current.z - wp_ref.z})

        angle = math.abs(angle)
        if (angle > 100 and isReverseStart) or (wp_ahead.isReverse ~= nil and wp_ahead.isReverse == true) then
            reverseStart = true
        end
        if (angle > 100 and isReverseEnd) or (wp_ahead.isForward ~= nil and wp_ahead.isForward == true) then
            reverseEnd = true
        end
    end

    return reverseStart, reverseEnd
end
