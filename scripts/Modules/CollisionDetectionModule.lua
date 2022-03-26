ADCollisionDetectionModule = {}

function ADCollisionDetectionModule:new(vehicle)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.vehicle = vehicle
	o.detectedObstable = false
	o.reverseSectionClear = AutoDriveTON:new()
	o.reverseSectionClear.elapsedTime = 20000
	o.detectedCollision = false
	o.lastReverseCheck = false
	return o
end

function ADCollisionDetectionModule:hasDetectedObstable(dt)
	local reverseSectionBlocked = self:detectTrafficOnUpcomingReverseSection()
	self.reverseSectionClear:timer(not reverseSectionBlocked, 10000, dt)
	self.detectedObstable = self:detectObstacle() or self:detectAdTrafficOnRoute() or not self.reverseSectionClear:done()
	return self.detectedObstable
end

function ADCollisionDetectionModule:update(dt)
end

function ADCollisionDetectionModule:detectObstacle()
	local box = self.vehicle.ad.sensors.frontSensorDynamic:getBoxShape()

	if AutoDrive.getSetting("enableTrafficDetection") == true then
		if self.vehicle.ad.sensors.frontSensorDynamic:pollInfo() then
			return true
		end
	end

	if ((g_updateLoopIndex + self.vehicle.id) % AutoDrive.PERF_FRAMES == 0) then
		local excludedList = self.vehicle.ad.taskModule:getActiveTask():getExcludedVehiclesForCollisionCheck()

		local boundingBox = {}
	    boundingBox[1] = box.topLeft
	    boundingBox[2] = box.topRight
	    boundingBox[3] = box.downRight
		boundingBox[4] = box.downLeft

		self.detectedCollision = AutoDrive:checkForVehicleCollision(self.vehicle, boundingBox, excludedList)
	end
	return self.detectedCollision
end

function ADCollisionDetectionModule:detectAdTrafficOnRoute()
	local wayPoints, currentWayPoint = self.vehicle.ad.drivePathModule:getWayPoints()
	if self.vehicle.ad.stateModule:isActive() and wayPoints ~= nil and self.vehicle.ad.drivePathModule:isOnRoadNetwork() then
		if ((g_updateLoopIndex + self.vehicle.id) % AutoDrive.PERF_FRAMES == 0) then			
			self.trafficVehicle = nil
			local idToCheck = 3
			local alreadyOnDualRoute = false
			if wayPoints[currentWayPoint - 1] ~= nil and wayPoints[currentWayPoint] ~= nil then
				alreadyOnDualRoute = ADGraphManager:isDualRoad(wayPoints[currentWayPoint - 1], wayPoints[currentWayPoint])
			end
			
			if wayPoints[currentWayPoint + idToCheck] ~= nil and wayPoints[currentWayPoint + idToCheck + 1] ~= nil and not alreadyOnDualRoute then
				local dualRoute = ADGraphManager:isDualRoad(wayPoints[currentWayPoint + idToCheck], wayPoints[currentWayPoint + idToCheck + 1])

				local dualRoutePoints = {}
				idToCheck = 0
				while (dualRoute == true) or (idToCheck < 8) do
					local startNode = wayPoints[currentWayPoint + idToCheck]
					local targetNode = wayPoints[currentWayPoint + idToCheck + 1]
					if (startNode ~= nil) and (targetNode ~= nil) then
						local testDual = ADGraphManager:isDualRoad(startNode, targetNode)
						if testDual == true then
							table.insert(dualRoutePoints, startNode.id)
							dualRoute = true
						else
							dualRoute = false
						end
					else
						dualRoute = false
					end
					idToCheck = idToCheck + 1
				end

				if #dualRoutePoints > 0 then
					for _, other in pairs(g_currentMission.vehicles) do
						if other ~= self.vehicle and other.ad ~= nil and other.ad.stateModule ~= nil and other.ad.stateModule:isActive() and other.ad.drivePathModule:isOnRoadNetwork() then					
							local onSameRoute = false
							local sameDirection = false
							local window = 4
							local i = -window
							local otherWayPoints, otherCurrentWayPoint = other.ad.drivePathModule:getWayPoints()
							while i <= window do
								if otherWayPoints ~= nil and otherWayPoints[otherCurrentWayPoint + i] ~= nil then
									for _, point in pairs(dualRoutePoints) do
										if point == otherWayPoints[otherCurrentWayPoint + i].id then
											onSameRoute = true
											--check if going in same direction
											if dualRoutePoints[_ + 1] ~= nil and otherWayPoints[otherCurrentWayPoint + i + 1] ~= nil then
												if dualRoutePoints[_ + 1] == otherWayPoints[otherCurrentWayPoint + i + 1].id then
													sameDirection = true
												end
											end
											--check if going in same direction
											if dualRoutePoints[_ - 1] ~= nil and otherWayPoints[otherCurrentWayPoint + i - 1] ~= nil then
												if dualRoutePoints[_ - 1] == otherWayPoints[otherCurrentWayPoint + i - 1].id then
													sameDirection = true
												end
											end
										end
									end
								end
								i = i + 1
							end
							
							if onSameRoute == true and other.ad.collisionDetectionModule:getDetectedVehicle() == nil and (sameDirection == false) then
								self.trafficVehicle = other
								return true
							end
						end
					end
				end
			end
		else
			return self.trafficVehicle ~= nil
		end
	end
	return false
end

function ADCollisionDetectionModule:detectTrafficOnUpcomingReverseSection()
	local wayPoints, currentWayPoint = self.vehicle.ad.drivePathModule:getWayPoints()
	if self.vehicle.ad.stateModule:isActive() and wayPoints ~= nil and self.vehicle.ad.drivePathModule:isOnRoadNetwork() then
		if ((g_updateLoopIndex + self.vehicle.id) % AutoDrive.PERF_FRAMES == 0) then
			self.lastReverseCheck = false
			local idToCheck = 1

			if wayPoints[currentWayPoint + idToCheck] ~= nil and wayPoints[currentWayPoint + idToCheck + 1] ~= nil then
				local reverseSection = ADGraphManager:isReverseRoad(wayPoints[currentWayPoint + idToCheck], wayPoints[currentWayPoint + idToCheck + 1])

				local reverseSectionPoints = {}
				idToCheck = 0
				while (reverseSection == true) or (idToCheck < 20) do
					local startNode = wayPoints[currentWayPoint + idToCheck]
					local targetNode = wayPoints[currentWayPoint + idToCheck + 1]
					if (startNode ~= nil) and (targetNode ~= nil) then
						if ADGraphManager:isReverseRoad(startNode, targetNode) == true then
							table.insert(reverseSectionPoints, startNode.id)
							reverseSection = true
						else
							reverseSection = false
						end
					else
						reverseSection = false
					end
					idToCheck = idToCheck + 1
				end

				if #reverseSectionPoints > 0 then
					--print(self.vehicle.ad.stateModule:getName() .. " - detected reverse section ahead")
					for _, other in pairs(g_currentMission.vehicles) do
						if other ~= self.vehicle and other.ad ~= nil and other.ad.stateModule ~= nil and other.ad.stateModule:isActive() and other.ad.drivePathModule:isOnRoadNetwork() and
				not (other.ad ~= nil and other.ad == self.vehicle.ad)       -- some trailed harvester get assigned AD from the trailing vehicle, see "attachable.ad = self.ad" in Specialisation
			    then
							local onSameRoute = false
							local i = -10
							local otherWayPoints, otherCurrentWayPoint = other.ad.drivePathModule:getWayPoints()
							while i <= 10 do
								if otherWayPoints ~= nil and otherWayPoints[otherCurrentWayPoint + i] ~= nil then
									for _, point in pairs(reverseSectionPoints) do
										if point == otherWayPoints[otherCurrentWayPoint + i].id then
											onSameRoute = true
											break
										end
									end
								end
								i = i + 1
							end

							if onSameRoute == true then							
								--print(self.vehicle.ad.stateModule:getName() .. " - detected reverse section ahead - another vehicle on it")
								self.trafficVehicle = other
								self.lastReverseCheck = true
							end
						end
					end
				end
			end
		else
			return self.lastReverseCheck
		end
	end
	
	--print(self.vehicle.ad.stateModule:getName() .. " - all clear")
	return false
end

function ADCollisionDetectionModule:getDetectedVehicle()
	return self.trafficVehicle
end

function ADCollisionDetectionModule:checkReverseCollision()
    local trailers, trailerCount = AutoDrive.getAllUnits(self.vehicle)
    local mostBackImplement = AutoDrive.getMostBackImplementOf(self.vehicle)
    
    local trailer = nil
    if trailerCount > 1 and self.vehicle.trailer ~= nil and self.vehicle.trailer ~= self.vehicle then
        -- vehicle.trailer is the controlable reverse attachable
        trailer = trailers[trailerCount]
    elseif mostBackImplement ~= nil then
        trailer = mostBackImplement
    else
        return self.vehicle.ad.sensors.rearSensor:pollInfo()
	end
    if trailer ~= nil then
        if trailer.ad == nil then
            trailer.ad = {}
        end
        ADSensor:handleSensors(trailer, 0)
        --trailer.ad.sensors.rearSensor.drawDebug = true
        trailer.ad.sensors.rearSensor.enabled = true
        return trailer.ad.sensors.rearSensor:pollInfo()
    end
end
