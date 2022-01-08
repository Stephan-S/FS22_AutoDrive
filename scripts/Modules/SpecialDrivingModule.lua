ADSpecialDrivingModule = {}

ADSpecialDrivingModule.MAX_SPEED_DEVIATION = 6

function ADSpecialDrivingModule:new(vehicle)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.vehicle = vehicle
    ADSpecialDrivingModule.reset(o)
    return o
end

function ADSpecialDrivingModule:reset()
    self.shouldStopOrHoldVehicle = false
    self.motorShouldNotBeStopped = false
    self.motorShouldBeStopped = false
    self.unloadingIntoBunkerSilo = false
    self.stoppedTimer = AutoDriveTON:new()
    self.vehicle.trailer = {}
    self.isReversing = false
end

function ADSpecialDrivingModule:stopVehicle(isBlocked, lx, lz)
    self.shouldStopOrHoldVehicle = true
    self.isBlocked = isBlocked
    self.targetLX = lx
    self.targetLZ = lz
    self.vehicle.trailer = {}
end

function ADSpecialDrivingModule:releaseVehicle()
    self.shouldStopOrHoldVehicle = false
    self.motorShouldBeStopped = false
    self.isBlocked = false
    self.stoppedTimer:timer(false)
end

function ADSpecialDrivingModule:update(dt)
    if self.shouldStopOrHoldVehicle then
        self:stopAndHoldVehicle(dt)
    end
    if AutoDrive.getDebugChannelIsSet(AutoDrive.DC_VEHICLEINFO) and self.vehicle.getIsEntered ~= nil and self.vehicle:getIsEntered() then
        local dbg = {}
        dbg.isStoppingVehicle = self:isStoppingVehicle()
        dbg.unloadingIntoBunkerSilo = self.unloadingIntoBunkerSilo
        dbg.shouldStopMotor = self:shouldStopMotor()
        dbg.shouldNotStopMotor = self:shouldNotStopMotor()
        dbg.stoppedTimer = self.stoppedTimer.elapsedTime
        AutoDrive.renderTable(0.6, 0.7, 0.009, dbg)
    end

    if not self.isReversing then
        self.reverseTarget = nil
    end
    self.isReversing = false
end

function ADSpecialDrivingModule:isStoppingVehicle()
    return self.shouldStopOrHoldVehicle
end

function ADSpecialDrivingModule:stopAndHoldVehicle(dt)
    local finalSpeed = 0
    local acc = -0.6
    local allowedToDrive = false

    if math.abs(self.vehicle.lastSpeedReal) > 0.002 then
        finalSpeed = 0.01
        allowedToDrive = true
    end

    local x, y, z = getWorldTranslation(self.vehicle.components[1].node)

    local lx, lz = self.targetLX, self.targetLZ

    if lx == nil or lz == nil then
        --If no target was provided, aim in front of te vehicle to prevent steering maneuvers
        local rx, _, rz = localDirectionToWorld(self.vehicle.components[1].node, 0, 0, 1)
        x = x + rx
        z = z + rz

        lx, lz = AIVehicleUtil.getDriveDirection(self.vehicle.components[1].node, x, y, z)
    end

    self.stoppedTimer:timer(self.vehicle.lastSpeedReal < 0.00028 and (self.vehicle.ad.trailerModule:getCanStopMotor()), 10000, dt)

    if self.stoppedTimer:done() then
        self.motorShouldBeStopped = true
        if self:shouldStopMotor() and self.vehicle:getIsMotorStarted() and (not g_currentMission.missionInfo.automaticMotorStartEnabled) then
            self.vehicle:stopMotor()
        end
    end

    AutoDrive.driveInDirection(self.vehicle, dt, 30, acc, 0.2, 20, allowedToDrive, true, lx, lz, finalSpeed, 1)
end

function ADSpecialDrivingModule:shouldStopMotor()
    return self.motorShouldBeStopped and (not self:shouldNotStopMotor())
end

function ADSpecialDrivingModule:shouldNotStopMotor()
    return self.motorShouldNotBeStopped
end

function ADSpecialDrivingModule:driveForward(dt)
    local speed = 8
    local acc = 0.6

    local targetX, targetY, targetZ = localToWorld(self.vehicle.components[1].node, 0, 0, 20)
    local lx, lz = AIVehicleUtil.getDriveDirection(self.vehicle.components[1].node, targetX, targetY, targetZ)

    self:releaseVehicle()
    if self.vehicle.startMotor then
        if not self.vehicle:getIsMotorStarted() and self.vehicle:getCanMotorRun() and not self.vehicle.ad.specialDrivingModule:shouldStopMotor() then
            self.vehicle:startMotor()
        end
    end
    AutoDrive.driveInDirection(self.vehicle, dt, 30, acc, 0.2, 20, true, true, lx, lz, speed, 1)
end

function ADSpecialDrivingModule:driveReverse(dt, maxSpeed, maxAcceleration, guided)
    self.isReversing = true
    local speed = maxSpeed
    local acc = maxAcceleration


    if self.vehicle.ad.collisionDetectionModule:checkReverseCollision() then
        self:stopAndHoldVehicle(dt)
    else
        if guided ~= true then
            local targetX, targetY, targetZ = localToWorld(self.vehicle.components[1].node, 0, 0, -20)
            local lx, lz = AIVehicleUtil.getDriveDirection(self.vehicle.components[1].node, targetX, targetY, targetZ)

            self:releaseVehicle()
            if self.vehicle.startMotor then
                if not self.vehicle:getIsMotorStarted() and self.vehicle:getCanMotorRun() and not self.vehicle.ad.specialDrivingModule:shouldStopMotor() then
                    self.vehicle:startMotor()
                end
            end
            local storedSmootherDriving = AutoDrive.smootherDriving
            AutoDrive.smootherDriving = false
            AutoDrive.driveInDirection(self.vehicle, dt, 30, acc, 0.2, 20, true, false, -lx, -lz, speed, 1)
            AutoDrive.smootherDriving = storedSmootherDriving
        else
            if self.reverseTarget == nil then
                local x, y, z = localToWorld(self.vehicle.components[1].node, 0, 0 , -100)
                self.reverseTarget = {x=x, y=y, z=z}
            end
            self.vehicle.ad.specialDrivingModule:reverseToTargetLocation(dt, self.reverseTarget, maxSpeed)
        end
    end
    
    -- Update trailers in case we need to lock the front axle
    self.vehicle.ad.trailerModule:handleTrailerReversing(true)
end

function ADSpecialDrivingModule:driveToPoint(dt, point, maxFollowSpeed, checkDynamicCollision, maxAcc, maxSpeed)
    local speed = math.min(self.vehicle.ad.stateModule:getFieldSpeedLimit(), maxSpeed)
    local acc = math.min(0.75, maxAcc)

    local x, y, z = getWorldTranslation(self.vehicle.components[1].node)
    self.distanceToChasePos = MathUtil.vector2Length(x - point.x, z - point.z)

    if self.distanceToChasePos < 0.5 then
        speed = maxFollowSpeed * 1
    elseif self.distanceToChasePos < 7 then
        speed = maxFollowSpeed + self.distanceToChasePos * 1.4
    elseif self.distanceToChasePos < 20 then
        speed = maxFollowSpeed + self.distanceToChasePos * 2
    end

    --print("Targetspeed: " .. speed .. " distance: " .. self.distanceToChasePos .. " maxFollowSpeed: " .. maxFollowSpeed)

    local lx, lz = AIVehicleUtil.getDriveDirection(self.vehicle.components[1].node, point.x, point.y, point.z)

    if checkDynamicCollision and (self.vehicle.ad.collisionDetectionModule:hasDetectedObstable(dt) or self.vehicle.ad.sensors.frontSensor:pollInfo()) then
        self:stopVehicle(true, lx, lz)
        self:update(dt)
    else
        self:releaseVehicle()

        self.isBlocked = self.stoppedTimer:timer(self.vehicle.lastSpeedReal < 0.00028, 15000, dt)
        -- Allow active braking if vehicle is not 'following' targetSpeed precise enough
        if (self.vehicle.lastSpeedReal * 3600) > (speed + ADSpecialDrivingModule.MAX_SPEED_DEVIATION) then
            self.acceleration = -0.6
        end
        --ADDrawingManager:addLineTask(x, y, z, point.x, point.y, point.z, 1, 0, 0)

        if self.vehicle.startMotor then
            if not self.vehicle:getIsMotorStarted() and self.vehicle:getCanMotorRun() and not self.vehicle.ad.specialDrivingModule:shouldStopMotor() then
                self.vehicle:startMotor()
            end
        end

        local storedSmootherDriving = AutoDrive.smootherDriving
        AutoDrive.smootherDriving = false
        AutoDrive.driveInDirection(self.vehicle, dt, 30, acc, 0.2, 20, true, true, lx, lz, speed, 0.3)
        AutoDrive.smootherDriving = storedSmootherDriving
    end
end

function ADSpecialDrivingModule:handleReverseDriving(dt)
    self.wayPoints = self.vehicle.ad.drivePathModule:getWayPoints()
    self.currentWayPointIndex = self.vehicle.ad.drivePathModule:getCurrentWayPointIndex()
    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "ADSpecialDrivingModule:handleReverseDriving start self.currentWayPointIndex %s ", tostring(self.currentWayPointIndex))
    
    -- Update trailers in case we need to lock the front axle
    self.vehicle.ad.trailerModule:handleTrailerReversing(true)

    if self.vehicle.ad.trailerModule:isUnloadingToBunkerSilo() then
        AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "ADSpecialDrivingModule:handleReverseDriving isUnloadingToBunkerSilo self.currentWayPointIndex %s ", tostring(self.currentWayPointIndex))
        if self.vehicle.ad.trailerModule:getIsBlocked(dt) then
            AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "ADSpecialDrivingModule:handleReverseDriving isUnloadingToBunkerSilo driveForward self.currentWayPointIndex %s ", tostring(self.currentWayPointIndex))
            self:driveForward(dt)
        else
            AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "ADSpecialDrivingModule:handleReverseDriving isUnloadingToBunkerSilo stopAndHoldVehicle self.currentWayPointIndex %s ", tostring(self.currentWayPointIndex))
            self:stopAndHoldVehicle(dt)
        end
        self.unloadingIntoBunkerSilo = true
    else
        if self.unloadingIntoBunkerSilo then
            AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "ADSpecialDrivingModule:handleReverseDriving unloadingIntoBunkerSilo self.currentWayPointIndex %s ", tostring(self.currentWayPointIndex))
            self.vehicle.ad.drivePathModule:reachedTarget()
        else
            if self.wayPoints == nil or self.wayPoints[self.currentWayPointIndex] == nil then
                return
            end

            self.reverseNode = self:getReverseNode()
            if self.reverseNode == nil then
                AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "ADSpecialDrivingModule:handleReverseDriving self.reverseNode == nil -> return self.currentWayPointIndex %s ", tostring(self.currentWayPointIndex))
                return
            end

            self.reverseTarget = self.wayPoints[self.currentWayPointIndex]

            self:getBasicStates()

            if self:checkWayPointReached() then
                AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "ADSpecialDrivingModule:handleReverseDriving self:checkWayPointReached -> handleReachedWayPoint / return self.currentWayPointIndex %s ", tostring(self.currentWayPointIndex))
                self.vehicle.ad.drivePathModule:handleReachedWayPoint()
                return
            end

            local inBunkerSilo = AutoDrive.isVehicleInBunkerSiloArea(self.vehicle)

            if not inBunkerSilo and (AutoDrive.getSetting("enableTrafficDetection") == true) and self.vehicle.ad.collisionDetectionModule:checkReverseCollision() then
                AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "ADSpecialDrivingModule:handleReverseDriving self:stopAndHoldVehicle inBunkerSilo %s self.vehicle.ad.collisionDetectionModule:checkReverseCollision() %s self.currentWayPointIndex %s ", tostring(inBunkerSilo), tostring(self.vehicle.ad.collisionDetectionModule:checkReverseCollision()), tostring(self.currentWayPointIndex))
                self:stopAndHoldVehicle(dt)
            else
                AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "ADSpecialDrivingModule:handleReverseDriving reverseToPoint self.currentWayPointIndex %s ", tostring(self.currentWayPointIndex))
                -- open trailer cover if trigger is reachable
                local trailers, _ = AutoDrive.getAllUnits(self.vehicle)
                local isInRangeToLoadUnloadTarget = AutoDrive.isInRangeToLoadUnloadTarget(self.vehicle)
                AutoDrive.setTrailerCoverOpen(self.vehicle, trailers, isInRangeToLoadUnloadTarget)

                self:reverseToPoint(dt)
            end
        end
        self.unloadingIntoBunkerSilo = false
    end
end

function ADSpecialDrivingModule:getBasicStates()
    self.x, self.y, self.z = getWorldTranslation(self.vehicle:getAIDirectionNode())
    self.vehicleVecX, _, self.vehicleVecZ = localDirectionToWorld(self.vehicle:getAIDirectionNode(), 0, 0, 1)
    self.rNx, self.rNy, self.rNz = getWorldTranslation(self.reverseNode)
    self.targetX, self.targetY, self.targetZ = localToWorld(self.vehicle:getAIDirectionNode(), 0, 0, 5)
    self.trailerVecX, _, self.trailerVecZ = localDirectionToWorld(self.reverseNode, 0, 0, 1)
    self.trailerRearVecX, _, self.trailerRearVecZ = localDirectionToWorld(self.reverseNode, 0, 0, -1)
    self.vecToPoint = {x = self.reverseTarget.x - self.rNx, z = self.reverseTarget.z - self.rNz}
    self.angleToTrailer = AutoDrive.angleBetween({x = self.vehicleVecX, z = self.vehicleVecZ}, {x = self.trailerVecX, z = self.trailerVecZ})
    self.angleToPoint = AutoDrive.angleBetween({x = self.trailerRearVecX, z = self.trailerRearVecZ}, {x = self.vecToPoint.x, z = self.vecToPoint.z})
    self.steeringAngle = math.deg(math.abs(self.vehicle.rotatedTime))

    if self.reverseSolo then
        self.angleToTrailer = -math.deg(self.vehicle.rotatedTime)
    end

    self.trailerX, self.trailerY, self.trailerZ = localToWorld(self.reverseNode, 0, 0, 5)
    --ADDrawingManager:addLineTask(self.x, self.y+3, self.z, self.targetX, self.targetY+3, self.targetZ, 1, 1, 1)
    --ADDrawingManager:addLineTask(self.rNx, self.rNy + 3, self.rNz, self.trailerX, self.trailerY + 3, self.trailerZ, 1, 1, 1)
    --ADDrawingManager:addLineTask(self.reverseTarget.x, self.reverseTarget.y + 1, self.reverseTarget.z, self.trailerX, self.trailerY + 3, self.trailerZ, 1, 1, 1)
    --ADDrawingManager:addLineTask(self.rNx, self.rNy + 3, self.rNz, self.rNx, self.rNy + 5, self.rNz, 1, 1, 1)

    --print("AngleToTrailer: " .. self.angleToTrailer .. " angleToPoint: " .. self.angleToPoint)
end

function ADSpecialDrivingModule:getAngleToTrailer()
    self:getBasicStates()
    return self.angleToTrailer
end

function ADSpecialDrivingModule:checkWayPointReached()
    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "ADSpecialDrivingModule:checkWayPointReached start self.currentWayPointIndex %s ", tostring(self.currentWayPointIndex))
    local distanceToTarget = MathUtil.vector2Length(self.reverseTarget.x - self.rNx, self.reverseTarget.z - self.rNz)
    local minDistance = 9
    local storedIndex = self.vehicle.ad.drivePathModule.currentWayPoint
    self.vehicle.ad.drivePathModule.currentWayPoint = self.vehicle.ad.drivePathModule.currentWayPoint + 1
    local reverseStart, reverseEnd = self.vehicle.ad.drivePathModule:checkForReverseSection()
    self.vehicle.ad.drivePathModule.currentWayPoint = storedIndex
    if self.reverseSolo then
        minDistance = AutoDrive.defineMinDistanceByVehicleType(self.vehicle)
    elseif self.currentWayPointIndex == #self.wayPoints then
        minDistance = 4.5
    elseif reverseEnd then
        minDistance = 3
    end
    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "ADSpecialDrivingModule:checkWayPointReached distanceToTarget %s minDistance %s angleToPoint %s self.currentWayPointIndex %s ", tostring(distanceToTarget), tostring(minDistance), tostring(math.abs(self.angleToPoint)), tostring(self.currentWayPointIndex))
    if distanceToTarget < minDistance or math.abs(self.angleToPoint) > 80 then
        AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "ADSpecialDrivingModule:checkWayPointReached return true self.currentWayPointIndex %s ", tostring(self.currentWayPointIndex))
        return true
    end

    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "ADSpecialDrivingModule:checkWayPointReached end self.currentWayPointIndex %s ", tostring(self.currentWayPointIndex))
    return false
end

function ADSpecialDrivingModule:getReverseNode()
    local reverseNode
    local count = 1
    if self.vehicle.trailer == nil then
        self.vehicle.trailer = {}
    end
    self.vehicle.trailer = nil

    for _, implement in pairs(AutoDrive.getAllImplements(self.vehicle, true)) do
        -- Logging.info("[AD] ADSpecialDrivingModule:getReverseNode count %s ", tostring(count))
        
        if (implement ~= self.vehicle or reverseNode == nil) and 
            implement.spec_wheels ~= nil and
            AutoDrive.isImplementAllowedForReverseDriving(self.vehicle, implement)                    -- whitelist of implements allowed as reverse node
        then
            local implementX, implementY, implementZ = getWorldTranslation(implement.components[1].node)
            local _, _, diffZ = worldToLocal(self.vehicle.components[1].node, implementX, implementY, implementZ)
            -- Logging.info("[AD] ADSpecialDrivingModule:getReverseNode diffZ %s ", tostring(diffZ))
            if diffZ < 0 then
            -- if diffZ < 0 and math.abs(diffZ) >= (self.vehicle.size.length / 2) then
            
                local hasSynchronizedWheels = false
                local centerX, centerZ = 0,0
                local wheelCount = 0
                for _, wheel in pairs(implement.spec_wheels.wheels) do
                    hasSynchronizedWheels = hasSynchronizedWheels or wheel.isSynchronized
                    if wheel.isSynchronized then
                        wheelCount = wheelCount + 1
                        local posX, _, posZ = localToLocal(wheel.node, implement.components[1].node, wheel.positionX, wheel.positionY, wheel.positionZ)
                        centerX = centerX + posX
                        centerZ = centerZ + posZ
                    end
                end
                -- Logging.info("[AD] ADSpecialDrivingModule:getReverseNode hasSynchronizedWheels %s ", tostring(hasSynchronizedWheels))
                if hasSynchronizedWheels then
                    if implement.spec_wheels.steeringCenterNode == nil then
                        centerX = centerX / wheelCount
                        centerZ = centerZ / wheelCount

                        implement.spec_wheels.steeringCenterNode = createTransformGroup("steeringCenterNode")

                        link(implement.components[1].node, implement.spec_wheels.steeringCenterNode)

                        if centerX ~= nil and centerZ ~= nil then
                            setTranslation(implement.spec_wheels.steeringCenterNode, centerX, 0, centerZ)
                        end
                    end  
                    reverseNode = implement.spec_wheels.steeringCenterNode
                            
                    self.reverseSolo = false
                    self.vehicle.trailer = implement                 
                end
                break
            end
        end
        count = count + 1
    end
    if reverseNode == nil then
        -- no implement with steeringCenterNode found
        local steeringCenterX, steeringCenterY, steeringCenterZ = getWorldTranslation(self.vehicle.spec_wheels.steeringCenterNode)
        local _, _, diffZ = worldToLocal(self.vehicle.components[1].node, steeringCenterX, steeringCenterY, steeringCenterZ)
        -- use the more back node
        if diffZ < 0 then
            reverseNode = self.vehicle.spec_wheels.steeringCenterNode
        else
            reverseNode = self.vehicle.components[1].node
        end
        self.reverseSolo = true
    end
    return reverseNode
end

function ADSpecialDrivingModule:reverseToPoint(dt, maxSpeed)
    if maxSpeed == nil then
        maxSpeed = math.huge
    end
	local vehicleIsTruck = self:isTruck(self.vehicle)

    if self.lastAngleToPoint == nil then
        self.lastAngleToPoint = self.angleToPoint
    end
    if self.i == nil then
        self.i = 0
    end

    local delta = self.angleToPoint -- - angleToTrailer
    local p = delta
    self.i = self.i + (delta) * 0.05
    local d = delta - self.lastAngleToPoint

    self.pFactor = 6 --self.vehicle.ad.stateModule:getSpeedLimit()
    self.iFactor = 0.01
    self.dFactor = 1400 --self.vehicle.ad.stateModule:getFieldSpeedLimit() * 100

    if vehicleIsTruck then
        self.pFactor = 1 --self.vehicle.ad.stateModule:getSpeedLimit() * 0.05 --0.1 -- --0.1
        self.iFactor = 0.00001
        self.dFactor = 6.7 --self.vehicle.ad.stateModule:getFieldSpeedLimit() * 0.1 --10
    end

    local targetAngleToTrailer = math.clamp(-40, (p * self.pFactor) + (self.i * self.iFactor) + (d * self.dFactor), 40)
    local targetDiff = self.angleToTrailer - targetAngleToTrailer
    local offsetX = -targetDiff * 5
    local offsetZ = -20

    if vehicleIsTruck then
        offsetX = -targetDiff * 0.1
        offsetZ = -100
    end

    --print("p: " .. p .. " i: " .. self.i .. " d: " .. d)
    --print("p: " .. p * self.pFactor .. " i: " .. (self.i * self.iFactor) .. " d: " .. (d * self.dFactor))
    --print("targetAngleToTrailer: " .. targetAngleToTrailer .. " targetDiff: " .. targetDiff .. "  offsetX" .. offsetX)

    local speed = 5 + (6 * math.clamp(0, (5 / math.max(self.steeringAngle, math.abs(self.angleToTrailer))), 1))
    local acc = 0.4

    if vehicleIsTruck then
        speed = 3
    end

    local node = self.vehicle:getAIDirectionNode()

    local rx, _, rz = localDirectionToWorld(node, offsetX, 0, offsetZ)
    local targetX = self.x + rx
    local targetZ = self.z + rz

    if self.reverseSolo then
        targetX = self.reverseTarget.x
        targetZ = self.reverseTarget.z
    end
    local lx, lz = AIVehicleUtil.getDriveDirection(node, targetX, self.y, targetZ)
    if self.reverseSolo then
        lx = -lx
        lz = -lz
    end

    local maxAngle = 60
    if self.vehicle.maxRotation then
        if self.vehicle.maxRotation > (2 * math.pi) then
            maxAngle = self.vehicle.maxRotation
        else
            maxAngle = math.deg(self.vehicle.maxRotation)
        end
    end

    self:releaseVehicle()
    if self.vehicle.startMotor then
        if not self.vehicle:getIsMotorStarted() and self.vehicle:getCanMotorRun() and not self.vehicle.ad.specialDrivingModule:shouldStopMotor() then
            self.vehicle:startMotor()
        end
    end

    local storedSmootherDriving = AutoDrive.smootherDriving
    AutoDrive.smootherDriving = false
    speed = math.min(maxSpeed, speed)
    AutoDrive.driveInDirection(self.vehicle, dt, maxAngle, acc, 0.2, 20, true, false, lx, lz, speed, 1)
    AutoDrive.smootherDriving = storedSmootherDriving

    self.lastAngleToPoint = self.angleToPoint
end

function ADSpecialDrivingModule:reverseToTargetLocation(dt, location, maxSpeed)
    self.reverseNode = self:getReverseNode()
    if self.reverseNode == nil then
        return true
    end

    self.reverseTarget = location
    self.currentWayPointIndex = 0
    self.wayPoints = {}

    self:getBasicStates()

    if self:checkWayPointReached() then
        return true
    end

    if self.vehicle.ad.collisionDetectionModule:checkReverseCollision() then
        self:stopAndHoldVehicle(dt)
    else
        self:reverseToPoint(dt, maxSpeed)
    end

    return false
end

function ADSpecialDrivingModule:isTruck(vehicle)
	local ret = false

	if vehicle == nil then
		return false
	end
	
	for _,joint in pairs(vehicle.spec_attacherJoints.attacherJoints) do
		if AttacherJoints.jointTypeNameToInt["semitrailer"] and joint.jointType == AttacherJoints.jointTypeNameToInt["semitrailer"] then
			ret = true
			break
		elseif AttacherJoints.jointTypeNameToInt["hookLift"] and joint.jointType == AttacherJoints.jointTypeNameToInt["hookLift"] then
			ret = true
			break
		elseif AttacherJoints.jointTypeNameToInt["terraVariant"] and joint.jointType == AttacherJoints.jointTypeNameToInt["terraVariant"] then
			ret = true
			break
		end
	end
	return ret
end