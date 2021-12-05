addConsoleCommand("adParseSplines", "Parse traffic splines into waypoints", "adParseSplines", AutoDrive)
addConsoleCommand("adRemoveSplines", "Remove parsed traffic spline nodes", "removeTrafficSplineNodes", AutoDrive)
addConsoleCommand("adCreateJunctions", "Create junctions", "createJunctionCommand", AutoDrive)
addConsoleCommand("adRemoveJunctions", "Remove junctions", "removeJunctionCommand", AutoDrive)

function AutoDrive:removeTrafficSplineNodes()
	ADGraphManager:removeNodesWithFlag(AutoDrive.FLAG_TRAFFIC_SYSTEM)
end

function AutoDrive:adParseSplines()
	local startNodes = {}
	local endNodes = {}

	local aiSplineNode = self:getAiSplinesParentNode()
	local hasSplines = true
	local splineIndex = 0
	while hasSplines do
		hasSplines = false

		local spline = g_currentMission.trafficSystem:getSplineByIndex(splineIndex)		
		if spline ~= nil then
			hasSplines = true
			splineIndex = splineIndex + 1
			self:createWaypointsForSpline(startNodes, endNodes, spline)
		end
	end

	if aiSplineNode ~= nil then
		for i=0, getNumOfChildren(aiSplineNode)-1, 1 do
			local spline = getChildAt(aiSplineNode, i)
			if spline ~= nil then
				self:createWaypointsForSpline(startNodes, endNodes, spline)
			end
		end
	end

	AutoDrive.startNodes = startNodes
	AutoDrive.endNodes = endNodes

	--self:createJunctions(startNodes, endNodes, 100, 60)
end

function AutoDrive:getAiSplinesParentNode()
	local aiSplineNode = nil
	local hasSplines = true
	local splineIndex = 1
	while hasSplines and aiSplineNode == nil do
		local spline = g_currentMission.trafficSystem:getSplineByIndex(splineIndex)
		
		hasSplines = spline ~= nil
		
		if aiSplineNode == nil and spline ~= nil then
			local parent = getParent(spline) --now we are at trafficSystem
			if parent ~= nil then
				print("Parent name: " .. getName(parent))
				parent = getParent(parent) -- now we are at "Splines"
				if parent ~= nil then
					print("Parent parent name: " .. getName(parent))
					for i=0, getNumOfChildren(parent)-1, 1 do
						if string.find(getName(getChildAt(parent, i)), "ai") then
							aiSplineNode = getChildAt(parent, i)
							print("aiSplineNode name: " .. getName(aiSplineNode))
						end
					end
				end				
			end
		end

		splineIndex = splineIndex + 1
	end

	return aiSplineNode
end

function AutoDrive:createWaypointsForSpline(startNodes, endNodes, spline)
	local lastX, lastY, lastZ = 0,0,0
	local length = getSplineLength(spline)
	local secondLastX, secondLastY, secondLastZ = 0,0,0
	if length > 0 then
		for i=0, 1, 1.0/length do
			local posX, posY, posZ = getSplinePosition(spline, i)
			if posX ~= nil then
				local maxDistance = 3
				if lastX ~= 0 and secondLastX ~= 0 then
					local angle = math.abs(AutoDrive.angleBetween({x = posX - lastX, z = posZ - lastZ}, {x = lastX - secondLastX, z = lastZ - secondLastZ}))
					maxDistance = 6
					if angle < 0.5 then
						maxDistance = 12
					elseif angle < 1 then
						maxDistance = 6
					elseif angle < 2 then
						maxDistance = 4
					elseif angle < 4 then
						maxDistance = 3
					elseif angle < 7 then
						maxDistance = 2
					elseif angle < 14 then
						maxDistance = 1
					elseif angle < 27 then
						maxDistance = 0.5
					else
						maxDistance = 0.25
					end
				end

				if MathUtil.vector3Length(lastX - posX, lastY - posY, lastZ - posZ) > maxDistance then
					local connectLast = false
					if lastX ~= 0 then
						connectLast = true
					end
					--if lastY - posY > 2 and lastY ~= 0 then -- prevent point dropping into the ground in case of bridges etc
						--posY = lastY
					--end
					ADGraphManager:recordWayPoint(posX, posY, posZ, connectLast, false, false, 0, AutoDrive.FLAG_TRAFFIC_SYSTEM)

					if lastX == 0 then
						local wpId = ADGraphManager:getWayPointsCount()
						local wp = ADGraphManager:getWayPointById(wpId)
						table.insert(startNodes, wp)
					end

					secondLastX, secondLastY, secondLastZ = lastX, lastY, lastZ
					lastX, lastY, lastZ = posX, posY, posZ
				end
			end
		end

		local wpId = ADGraphManager:getWayPointsCount()
		local wp = ADGraphManager:getWayPointById(wpId)
		table.insert(endNodes, wp)
	end	
end

function AutoDrive:createJunctionCommand()
	self:createJunctions(AutoDrive.startNodes, AutoDrive.endNodes, 150, 60)
end

function AutoDrive:removeJunctionCommand()
	ADGraphManager:removeNodesWithFlag(AutoDrive.FLAG_TRAFFIC_SYSTEM_CONNECTION)
end

function AutoDrive:createJunctions(startNodes, endNodes, maxAngle, maxDist)
	--print("AutoDrive:createJunctions")
	for _, endNode in pairs(endNodes) do
		if endNode.incoming ~= nil and #endNode.incoming > 0 then
			local incomingNode = ADGraphManager:getWayPointById(endNode.incoming[1])

			for __, startNode in pairs(startNodes) do
				if startNode.out ~= nil and #startNode.out > 0 then
					local outNode = ADGraphManager:getWayPointById(startNode.out[1])
					
					local angle = math.abs(AutoDrive.angleBetween({x = outNode.x - startNode.x, z = outNode.z - startNode.z}, {x = endNode.x - incomingNode.x, z = endNode.z - incomingNode.z}))
					local angle2 = math.abs(AutoDrive.angleBetween({x = startNode.x - endNode.x, z = startNode.z - endNode.z}, {x = endNode.x - incomingNode.x, z = endNode.z - incomingNode.z}))
					local angle3 = math.abs(AutoDrive.angleBetween({x = startNode.x - endNode.x, z = startNode.z - endNode.z}, {x = outNode.x - startNode.x, z = outNode.z - startNode.z}))
					local dist = ADGraphManager:getDistanceBetweenNodes(startNode.id, endNode.id)

					if angle < maxAngle and angle2 < 85 and angle3 < 85 and dist < maxDist then
						self.splineInterpolation = nil
						AutoDrive:createSplineInterpolationBetween(endNode, startNode)
						-- Todo: check validity of path by checking for collision along created path
						if self.splineInterpolation ~= nil and self.splineInterpolation.waypoints ~= nil and #self.splineInterpolation.waypoints > 2 then
							if AutoDrive:checkForCollisionOnSpline() then
								local lastId = endNode.id
								local lastHeight = endNode.y
								for wpId, wp in pairs(self.splineInterpolation.waypoints) do
									if wpId ~= 1 and wpId < (#self.splineInterpolation.waypoints - 1) then
										if math.abs(wp.y - lastHeight) > 1 then -- prevent point dropping into the ground in case of bridges etc
											wp.y = lastHeight
										end			
										ADGraphManager:recordWayPoint(wp.x, wp.y, wp.z, true, false, false, lastId, AutoDrive.FLAG_TRAFFIC_SYSTEM_CONNECTION)
										lastId = ADGraphManager:getWayPointsCount()
									end
								end

								local wp = ADGraphManager:getWayPointById(lastId)
								ADGraphManager:toggleConnectionBetween(wp, startNode, false)
							end
						else
							--print("AutoDrive:createJunctions - Fallback to toggle connections")
							ADGraphManager:toggleConnectionBetween(endNode, startNode, false)
						end
						--ADGraphManager:toggleConnectionBetween(endNode, startNode, false)
					end
				end				
			end
		end
	end
	
end

function AutoDrive:checkForCollisionOnSpline()
	local widthX = 5
	local height = 2.65
	for wpId, wp in pairs(self.splineInterpolation.waypoints) do
		if wpId > 1 and wpId < (#self.splineInterpolation.waypoints - 1) then
			local wpLast = self.splineInterpolation.waypoints[wpId - 1]
			local deltaX, deltaY, deltaZ = wp.x - wpLast.x, wp.y - wpLast.y, wp.z - wpLast.z
			local centerX, centerY, centerZ = wpLast.x + deltaX/2,  wpLast.y + deltaY/2,  wpLast.z + deltaZ/2
			local angleRad = math.atan2(-deltaZ, deltaX)
    		angleRad = AutoDrive.normalizeAngle(angleRad)
			local shapes = overlapBox(centerX, centerY+3, centerZ, 0, angleRad, 0, widthX, height, deltaZ, "collisionTestCallbackIgnore", nil, 12, true, true, true)
			if shapes > 0 then
				return false
			end
		end
	end
	return true
end
