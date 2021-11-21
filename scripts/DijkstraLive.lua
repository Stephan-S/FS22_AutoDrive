function AutoDrive:dijkstraLiveLongLine(current_in, linked_in, target_id)
	local current = current_in
	local linked = linked_in
	local newdist = 0
	local distanceToAdd = 0
	local angle = 0
	local current_pre = 0
	local wayPoints = ADGraphManager:getWayPoints()
	local isLinewithReverse = false
	local count = 1

	if wayPoints[linked].incoming ~= nil and wayPoints[linked].out ~= nil and #wayPoints[linked].incoming == 1 and #wayPoints[linked].out == 1 then
		if nil == AutoDrive.dijkstraCalc.distance[current] then
			AutoDrive.dijkstraCalc.distance[current] = 100000000
		end
		newdist = AutoDrive.dijkstraCalc.distance[current]
		while #wayPoints[linked].incoming <= 1 and #wayPoints[linked].out == 1 and not (linked == target_id) do
			count = count + 1
			if count > 5000 then
				return false, false --something went wrong. prevent overflow here
			end
			distanceToAdd = 0
			angle = 0
			if nil == AutoDrive.dijkstraCalc.pre[current] then
				AutoDrive.dijkstraCalc.pre[current] = -1
			end
			local wp_current
			local wp_ahead
			local wp_ref
			local isReverseStart = false
			local isReverseEnd = false
			wp_current = wayPoints[current]
			wp_ahead = wayPoints[linked]
			if AutoDrive.dijkstraCalc.pre[current] ~= nil and AutoDrive.dijkstraCalc.pre[current] ~= -1 then
				wp_ref = wayPoints[AutoDrive.dijkstraCalc.pre[current]]
				isReverseStart = not table.contains(wp_ahead.incoming, wp_current.id)
				isReverseEnd = table.contains(wp_ahead.incoming, wp_current.id) and not table.contains(wp_current.incoming, wp_ref.id)
				isLinewithReverse = isLinewithReverse or (isReverseStart or isReverseEnd)
			end

			distanceToAdd = ADGraphManager:getDistanceBetweenNodes(current, linked)
			if AutoDrive.dijkstraCalc.pre[current] ~= nil and AutoDrive.dijkstraCalc.pre[current] ~= -1 then
				angle = AutoDrive.angleBetween({x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z}, {x = wp_current.x - wp_ref.x, z = wp_current.z - wp_ref.z})
				angle = math.abs(angle)
			else
				angle = 0
			end

			if isLinewithReverse then 
				-- distanceToAdd = 1000000		-- do not add this here with multiple iterations !
			end

			newdist = newdist + distanceToAdd
			if math.abs(angle) > 90 and (not isReverseStart and not isReverseEnd) then
				newdist = 100000000
			end

			AutoDrive.dijkstraCalc.pre[linked] = current

			current = linked
			linked = wayPoints[current].out[1]

			if nil == AutoDrive.dijkstraCalc.pre[linked] then
				AutoDrive.dijkstraCalc.pre[linked] = -1
			end
			current_pre = AutoDrive.dijkstraCalc.pre[linked]
		end -- while...

		distanceToAdd = 0
		angle = 0
		if nil == AutoDrive.dijkstraCalc.pre[current] then
			AutoDrive.dijkstraCalc.pre[current] = -1
		end
		local wp_current
		local wp_ahead
		local wp_ref
		local isReverseStart = false
		local isReverseEnd = false
		wp_current = wayPoints[current]
		wp_ahead = wayPoints[linked]
		if AutoDrive.dijkstraCalc.pre[current] ~= nil and AutoDrive.dijkstraCalc.pre[current] ~= -1 then
			wp_ref = wayPoints[AutoDrive.dijkstraCalc.pre[current]]
			isReverseStart = not table.contains(wp_ahead.incoming, wp_current.id)
			isReverseEnd = table.contains(wp_ahead.incoming, wp_current.id) and not table.contains(wp_current.incoming, wp_ref.id)
			isLinewithReverse = isLinewithReverse or (isReverseStart or isReverseEnd)
		end

		distanceToAdd = ADGraphManager:getDistanceBetweenNodes(current, linked)
		if AutoDrive.dijkstraCalc.pre[current] ~= nil and AutoDrive.dijkstraCalc.pre[current] ~= -1 then
			angle = AutoDrive.angleBetween({x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z}, {x = wp_current.x - wp_ref.x, z = wp_current.z - wp_ref.z})
			angle = math.abs(angle)
		else
			angle = 0
		end

		if isLinewithReverse then 
			distanceToAdd = 1000000
		end

		newdist = newdist + distanceToAdd

		if math.abs(angle) > 90 and (not isReverseStart and not isReverseEnd) then
			newdist = 100000000
		end

		if nil == AutoDrive.dijkstraCalc.distance[linked] then
			AutoDrive.dijkstraCalc.distance[linked] = 100000000
		end
		if nil == AutoDrive.dijkstraCalc.pre[linked] then
			AutoDrive.dijkstraCalc.pre[linked] = -1
		end
		if newdist < AutoDrive.dijkstraCalc.distance[linked] then
			AutoDrive.dijkstraCalc.distance[linked] = newdist
			AutoDrive.dijkstraCalc.pre[linked] = current

			if #wayPoints[linked].out > 0 then
				AutoDrive.dijkstraCalc.Q.dummy_id = AutoDrive.dijkstraCalc.Q.dummy_id + 1
				table.insert(AutoDrive.dijkstraCalc.Q, 1, AutoDrive.dijkstraCalc.Q.dummy_id)
				AutoDrive.dijkstraCalc.Q[1] = linked
			end
		else
			if current_pre ~= 0 then
-- TODO ???
				-- AutoDrive.dijkstraCalc.pre[linked] = current_pre
			end
		end

		if linked == target_id and newdist < 100000000 then
			-- if route to target is reverse or angle > 90, we have not to reach it here
			AutoDrive.dijkstraCalc.distance[linked] = newdist
			AutoDrive.dijkstraCalc.pre[linked] = current

			AutoDrive.dijkstraCalc.Q.dummy_id = AutoDrive.dijkstraCalc.Q.dummy_id + 1
			table.insert(AutoDrive.dijkstraCalc.Q, 1, AutoDrive.dijkstraCalc.Q.dummy_id)
			AutoDrive.dijkstraCalc.Q[1] = linked

			return true, true
		end

		return true, false
	else
		return false, false
	end -- if...
end

function AutoDrive:dijkstraLive(start, target)
	local distanceToAdd = 0
	local angle = 0
	local result = false
	local target_found = false
	local wayPoints = ADGraphManager:getWayPoints()

	if start == nil or start == 0 or start == -1 or target == nil or target == 0 or target == -1 then
		return false
	end

	AutoDrive:dijkstraLiveInit(start)

	while next(AutoDrive.dijkstraCalc.Q, nil) ~= nil do
		local shortest = 100000000
		local shortest_id = -1
		local shortest_index = nil
		for i, element_wp in ipairs(AutoDrive.dijkstraCalc.Q) do
			if nil == AutoDrive.dijkstraCalc.distance[element_wp] then
				AutoDrive.dijkstraCalc.distance[element_wp] = 100000000
			end
			if AutoDrive.dijkstraCalc.distance[element_wp] < shortest then
				shortest = AutoDrive.dijkstraCalc.distance[element_wp]
				shortest_id = element_wp
				shortest_index = i
			end
			if AutoDrive.dijkstraCalc.distance[element_wp] >= 100000000 then
				break
			end
		end

		if shortest_id == target then
			return true
		end

		table.remove(AutoDrive.dijkstraCalc.Q, shortest_index)

		if shortest_id == -1 then
			AutoDrive.dijkstraCalc.Q = {}
		else
			if AutoDrive.dijkstraCalc.Q[shortest_index] ~= nil then
				if #wayPoints[shortest_id].out > 0 then
					for i, linkedNodeId in pairs(wayPoints[shortest_id].out) do
						local wp = wayPoints[linkedNodeId]

						if wp ~= nil then
							result = false
							target_found = false
							result, target_found = AutoDrive:dijkstraLiveLongLine(shortest_id, linkedNodeId, target)

							if target_found == true then
								return true
							end

							if result ~= true then
								distanceToAdd = 0
								angle = 0
								if nil == AutoDrive.dijkstraCalc.pre[shortest_id] then
									AutoDrive.dijkstraCalc.pre[shortest_id] = -1
								end
								local wp_current
								local wp_ahead
								local wp_ref
								local isReverseStart = false
								local isReverseEnd = false
								local isLinewithReverse = false
								wp_current = wayPoints[shortest_id]
								wp_ahead = wayPoints[linkedNodeId]
								if AutoDrive.dijkstraCalc.pre[shortest_id] ~= nil and AutoDrive.dijkstraCalc.pre[shortest_id] ~= -1 then
									wp_ref = wayPoints[AutoDrive.dijkstraCalc.pre[shortest_id]]
									isReverseStart = not table.contains(wp_ahead.incoming, wp_current.id)
									isReverseEnd = table.contains(wp_ahead.incoming, wp_current.id) and not table.contains(wp_current.incoming, wp_ref.id)
									isLinewithReverse = isLinewithReverse or (isReverseStart or isReverseEnd)
								end

								distanceToAdd = ADGraphManager:getDistanceBetweenNodes(shortest_id, linkedNodeId)
								if AutoDrive.dijkstraCalc.pre[shortest_id] ~= nil and AutoDrive.dijkstraCalc.pre[shortest_id] ~= -1 then
									angle = AutoDrive.angleBetween({x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z}, {x = wp_current.x - wp_ref.x, z = wp_current.z - wp_ref.z})
									angle = math.abs(angle)
								else
									angle = 0
								end

								if isLinewithReverse then 
									distanceToAdd = 1000000
								end

								local alternative = shortest + distanceToAdd
								if math.abs(angle) > 90 and (not isReverseStart and not isReverseEnd) then
									alternative = 100000000
								end

								if nil == AutoDrive.dijkstraCalc.distance[linkedNodeId] then
									AutoDrive.dijkstraCalc.distance[linkedNodeId] = 100000000
								end
								if nil == AutoDrive.dijkstraCalc.pre[linkedNodeId] then
									AutoDrive.dijkstraCalc.pre[linkedNodeId] = -1
								end

								if alternative < AutoDrive.dijkstraCalc.distance[linkedNodeId] and alternative < 100000000 then
									-- if route to target is reverse or angle > 90, we have not to reach it here
									AutoDrive.dijkstraCalc.distance[linkedNodeId] = alternative
									AutoDrive.dijkstraCalc.pre[linkedNodeId] = shortest_id

									AutoDrive.dijkstraCalc.Q.dummy_id = AutoDrive.dijkstraCalc.Q.dummy_id + 1

									table.insert(AutoDrive.dijkstraCalc.Q, 1, AutoDrive.dijkstraCalc.Q.dummy_id)

									AutoDrive.dijkstraCalc.Q[1] = linkedNodeId
								end
							end
						end -- if wp ~= nil then
						if linkedNodeId == target then
							return true
						end
					end -- for i, linkedNodeId in pairs...
				end -- if
			end -- if AutoDrive.dijkstraCalc.Q[shortest_id] ~= nil then
		end
	end

	if next(AutoDrive.dijkstraCalc.Q, nil) == nil then
		return true
	end

	return false
end

function AutoDrive:dijkstraLiveInit(start)
	if AutoDrive.dijkstraCalc == nil then
		AutoDrive.dijkstraCalc = {}
	end

	AutoDrive.dijkstraCalc.distance = {}
	AutoDrive.dijkstraCalc.pre = {}

	AutoDrive.dijkstraCalc.Q = {}
	AutoDrive.dijkstraCalc.Q.dummy_id = 1000000

	AutoDrive.dijkstraCalc.Q.dummy_id = AutoDrive.dijkstraCalc.Q.dummy_id + 1
	table.insert(AutoDrive.dijkstraCalc.Q, 1, AutoDrive.dijkstraCalc.Q.dummy_id)

	AutoDrive.dijkstraCalc.distance[start] = 0
	if nil == AutoDrive.dijkstraCalc.pre[start] then
		AutoDrive.dijkstraCalc.pre[start] = -1
	end

	table.insert(AutoDrive.dijkstraCalc.Q, 1, start)
end

--[[
Graph - ADGraphManager:getWayPoints()
start_id - Waypoint ID of start point of the route
target_id_id - Waypoint ID of target point of the route

return values:
1.	empty table {}, if 
    - start_id and / or target_id out of valid range (1..n), i.e. nil, 0, -1
	- something with route calculation is not working
	- route calculation from start_id not possible to target_id, i.e. track(s) is/are not connected inbetween start_id and target_id
	- more than 50000 waypoints for a route, this is assumed as no practical use case
2.	table with only 1 waypoint if start_id == target_id, same as in ADGraphManager:FastShortestPath
3.	table with waypoints from start_id to target_id including start_id and target_id
]]
function AutoDrive:dijkstraLiveShortestPath(start_id, target_id)
    if ADGraphManager:hasChanges() then
        AutoDrive.checkWaypointsLinkedtothemselve(true)		-- find WP linked to themselve, with parameter true issues will be fixed
        AutoDrive.checkWaypointsMultipleSameOut(true)		-- find WP with multiple same out ID, with parameter true issues will be fixed
        ADGraphManager:resetChanges()
    end

	local wayPoints = ADGraphManager:getWayPoints()
	local ret = false
	ret = AutoDrive:dijkstraLive(start_id, target_id)
	if false == ret then
		return {} --something went wrong
	end
	local wp = {}
	local count = 1
	local id = target_id

	while (AutoDrive.dijkstraCalc.pre[id] ~= -1 and id ~= nil) or id == start_id do
		table.insert(wp, 1, wayPoints[id])
		count = count + 1
		if id == start_id then
			id = nil
		else
			if AutoDrive.dijkstraCalc.pre[id] ~= nil and AutoDrive.dijkstraCalc.pre[id] ~= -1 then
				id = AutoDrive.dijkstraCalc.pre[id]
			else -- invalid Route -> keep Vehicle at start point
				--				print(string.format("Axel: AutoDrive:dijkstraLiveShortestPath ERROR invalid Route count = %d -> keep Vehicle at start point",count))
				-- TODO: message to user route not calculateable
				return {}
			end
		end
		if count > 50000 then
			print(string.format("Axel: AutoDrive:dijkstraLiveShortestPath ERROR count > 50000"))
			return {} --something went wrong. prevent overflow here
		end
	end

	return wp
end
