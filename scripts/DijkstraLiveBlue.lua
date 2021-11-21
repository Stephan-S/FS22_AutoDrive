function AutoDrive:dijkstraLiveBlueLongLineBlue(current_in, linked_in, target_id, newdist_in)
	local current = current_in
	local linked = linked_in
	local newdist = newdist_in
	local distanceToAdd = 0
	local angle = 0
	local current_pre = 0
	local current_preBlue = 0
	local wayPoints = ADGraphManager:getWayPoints()
	local isLinewithReverse = false
	local count = 1
	local isDual = false
	
	if wayPoints[linked].out ~= nil and #wayPoints[linked].incoming == 2 and #wayPoints[linked].out == 2 then
		isDual = ADGraphManager:isDualRoad(wayPoints[current], wayPoints[linked]) and ADGraphManager:isDualRoad(wayPoints[linked], wayPoints[wayPoints[linked].out[1]]) and ADGraphManager:isDualRoad(wayPoints[linked], wayPoints[wayPoints[linked].out[2]])
	end

	if wayPoints[linked].incoming ~= nil and wayPoints[linked].out ~= nil and #wayPoints[linked].incoming == 2 and #wayPoints[linked].out == 2 and isDual then 
		if nil == AutoDrive.dijkstraCalc.distance[current] then
			AutoDrive.dijkstraCalc.distance[current] = 100000000
		end
		--newdist = AutoDrive.dijkstraCalc.distance[current]
		while #wayPoints[linked].incoming == 2 and #wayPoints[linked].out == 2 and not (linked == target_id) and isDual do
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
				if AutoDrive.dijkstraCalc.preBlue[current] ~= nil and AutoDrive.dijkstraCalc.preBlue[current] ~= -1 then	--we are on the second pass
					wp_ref = wayPoints[AutoDrive.dijkstraCalc.preBlue[current]%AutoDrive.dijkstraCalc.passfactor]
					isReverseStart = not table.contains(wp_ahead.incoming, wp_current.id)
					isReverseEnd = table.contains(wp_ahead.incoming, wp_current.id) and not table.contains(wp_current.incoming, wp_ref.id)
					isLinewithReverse = isLinewithReverse or (isReverseStart or isReverseEnd)
					
					angle = AutoDrive.angleBetween({x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z}, {x = wp_current.x - wp_ref.x, z = wp_current.z - wp_ref.z})
					angle = math.abs(angle)
				else																										--we are on the first pass
					wp_ref = wayPoints[AutoDrive.dijkstraCalc.pre[current]%AutoDrive.dijkstraCalc.passfactor]
					isReverseStart = not table.contains(wp_ahead.incoming, wp_current.id)
					isReverseEnd = table.contains(wp_ahead.incoming, wp_current.id) and not table.contains(wp_current.incoming, wp_ref.id)
					isLinewithReverse = isLinewithReverse or (isReverseStart or isReverseEnd)
					
					angle = AutoDrive.angleBetween({x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z}, {x = wp_current.x - wp_ref.x, z = wp_current.z - wp_ref.z})
					angle = math.abs(angle)
				end
			else
				angle = 0
			end

			distanceToAdd = ADGraphManager:getDistanceBetweenNodes(current, linked)

			newdist = newdist + distanceToAdd
			if math.abs(angle) > 90 and (not isReverseStart and not isReverseEnd) then
				newdist = 100000000
				return true, false
			else
				if AutoDrive.dijkstraCalc.pre[linked] ~= nil and AutoDrive.dijkstraCalc.pre[linked] ~= -1 then
				
					AutoDrive.dijkstraCalc.preBlue[linked] = current
					AutoDrive.dijkstraCalc.distanceBlue[linked] = newdist
				else
					AutoDrive.dijkstraCalc.pre[linked] = current
					AutoDrive.dijkstraCalc.distance[linked] = newdist
					AutoDrive.dijkstraCalc.preBlue[linked] = -1
				end
			end
			--if AutoDrive.dijkstraCalc.preBlue[linked] == nil then
				--AutoDrive.dijkstraCalc.preBlue[linked] = current
			--end
			for i,wp_out in pairs (wayPoints[linked].out) do
				if wp_out ~= current then	--we don't want to come back to the same waypoint
					current = linked
					linked = wp_out
					break
				end
			end
			if wayPoints[linked].out ~= nil and #wayPoints[linked].incoming == 2 and #wayPoints[linked].out == 2 then
				isDual = ADGraphManager:isDualRoad(wayPoints[current], wayPoints[linked]) and ADGraphManager:isDualRoad(wayPoints[linked], wayPoints[wayPoints[linked].out[1]]) and ADGraphManager:isDualRoad(wayPoints[linked], wayPoints[wayPoints[linked].out[2]])
			else
				isDual = false
			end

			if nil == AutoDrive.dijkstraCalc.pre[linked] then
				AutoDrive.dijkstraCalc.pre[linked] = -1
			end
			current_pre = AutoDrive.dijkstraCalc.pre[linked]
			
			if nil == AutoDrive.dijkstraCalc.preBlue[linked] then
				AutoDrive.dijkstraCalc.preBlue[linked] = -1
			end
			current_preBlue = AutoDrive.dijkstraCalc.preBlue[linked] % AutoDrive.dijkstraCalc.passfactor
		end -- while...

		distanceToAdd = 0
		angle = 0
		if nil == AutoDrive.dijkstraCalc.preBlue[current] then
			AutoDrive.dijkstraCalc.preBlue[current] = -1
		end
		local wp_current
		local wp_ahead
		local wp_ref
		local isReverseStart = false
		local isReverseEnd = false
		wp_current = wayPoints[current]
		wp_ahead = wayPoints[linked]
		if AutoDrive.dijkstraCalc.pre[current] ~= nil and AutoDrive.dijkstraCalc.pre[current] ~= -1 then
			if AutoDrive.dijkstraCalc.preBlue[current] ~= nil and AutoDrive.dijkstraCalc.preBlue[current] ~= -1 then	--we are on the second pass
				wp_ref = wayPoints[AutoDrive.dijkstraCalc.preBlue[current]%AutoDrive.dijkstraCalc.passfactor]
				isReverseStart = not table.contains(wp_ahead.incoming, wp_current.id)
				isReverseEnd = table.contains(wp_ahead.incoming, wp_current.id) and not table.contains(wp_current.incoming, wp_ref.id)
				isLinewithReverse = isLinewithReverse or (isReverseStart or isReverseEnd)
				
				angle = AutoDrive.angleBetween({x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z}, {x = wp_current.x - wp_ref.x, z = wp_current.z - wp_ref.z})
				angle = math.abs(angle)
			else																										--we are on the first pass
				wp_ref = wayPoints[AutoDrive.dijkstraCalc.pre[current]%AutoDrive.dijkstraCalc.passfactor]
				isReverseStart = not table.contains(wp_ahead.incoming, wp_current.id)
				isReverseEnd = table.contains(wp_ahead.incoming, wp_current.id) and not table.contains(wp_current.incoming, wp_ref.id)
				isLinewithReverse = isLinewithReverse or (isReverseStart or isReverseEnd)
				
				angle = AutoDrive.angleBetween({x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z}, {x = wp_current.x - wp_ref.x, z = wp_current.z - wp_ref.z})
				angle = math.abs(angle)
			end
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

		if nil == AutoDrive.dijkstraCalc.distanceBlue[linked] then
			AutoDrive.dijkstraCalc.distanceBlue[linked] = 100000000
		end
		if nil == AutoDrive.dijkstraCalc.preBlue[linked] then
			AutoDrive.dijkstraCalc.preBlue[linked] = -1
		end
		if newdist < AutoDrive.dijkstraCalc.distance[linked] then
			AutoDrive.dijkstraCalc.distance[linked] = newdist
			AutoDrive.dijkstraCalc.pre[linked] = current
			AutoDrive.dijkstraCalc.preBlue[linked] = -1
			if #wayPoints[linked].out > 0 then
				AutoDrive.dijkstraCalc.Q.dummy_id = AutoDrive.dijkstraCalc.Q.dummy_id + 1
				table.insert(AutoDrive.dijkstraCalc.Q, 1, AutoDrive.dijkstraCalc.Q.dummy_id)
				AutoDrive.dijkstraCalc.Q[1] = linked
			end
		elseif current_pre ~= 0 and newdist < AutoDrive.dijkstraCalc.distanceBlue[linked] and current_pre ~= current then
			if #wayPoints[linked].out >= 1 then
				for i,id_out in pairs (wayPoints[linked].out) do
					local wp_out = wayPoints[id_out]
					angle = AutoDrive.angleBetween({x = wp_out.x - wp_ahead.x, z = wp_out.z - wp_ahead.z}, {x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z})
					angle = math.abs(angle)
					if math.abs(angle) <= 90 then
						local dist = newdist + ADGraphManager:getDistanceBetweenNodes(linked, id_out)
						if nil == AutoDrive.dijkstraCalc.distance[id_out] then
							AutoDrive.dijkstraCalc.distance[id_out] = 100000000
						end
						if nil == AutoDrive.dijkstraCalc.distanceBlue[id_out] then
							AutoDrive.dijkstraCalc.distanceBlue[id_out] = 100000000
						end
						if dist < AutoDrive.dijkstraCalc.distance[id_out] then
							local new_pre = linked + current*AutoDrive.dijkstraCalc.passfactor
							AutoDrive.dijkstraCalc.pre[id_out] = new_pre
							AutoDrive.dijkstraCalc.distance[id_out] = dist
							AutoDrive.dijkstraCalc.preBlue[id_out] = -1
							if #wayPoints[id_out].out > 0 then
								AutoDrive.dijkstraCalc.Q.dummy_id = AutoDrive.dijkstraCalc.Q.dummy_id + 1
								table.insert(AutoDrive.dijkstraCalc.Q, 1, AutoDrive.dijkstraCalc.Q.dummy_id)
								AutoDrive.dijkstraCalc.Q[1] = id_out
							end
						elseif dist < AutoDrive.dijkstraCalc.distanceBlue[id_out] and true == ADGraphManager:isDualRoad(wayPoints[linked], wayPoints[id_out]) then
							local new_pre = linked + current*AutoDrive.dijkstraCalc.passfactor
							AutoDrive.dijkstraCalc.preBlue[id_out] = new_pre
							AutoDrive.dijkstraCalc.distanceBlue[id_out] = dist
							if #wayPoints[id_out].out > 0 then
								AutoDrive.dijkstraCalc.Q.dummy_id = AutoDrive.dijkstraCalc.Q.dummy_id + 1
								table.insert(AutoDrive.dijkstraCalc.Q, 1, AutoDrive.dijkstraCalc.Q.dummy_id)
								AutoDrive.dijkstraCalc.Q[1] = id_out
							end
						end
					end
				end

			end
		end

		if linked == target_id and newdist < 100000000 then
			-- if route to target is reverse or angle > 90, we have not to reach it here
			AutoDrive.dijkstraCalc.distance[linked] = newdist
			AutoDrive.dijkstraCalc.pre[linked] = current
			AutoDrive.dijkstraCalc.preBlue[linked] = -1

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

function AutoDrive:dijkstraLiveBlueLongLine(current_in, linked_in, target_id)
	local current = current_in
	local linked = linked_in
	local newdist = 0
	local distanceToAdd = 0
	local angle = 0
	local current_pre = 0
	local wayPoints = ADGraphManager:getWayPoints()
	local isLinewithReverse = false
	local count = 1
	local target_found = false

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
				wp_ref = wayPoints[AutoDrive.dijkstraCalc.pre[current]%AutoDrive.dijkstraCalc.passfactor]
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

			--if isLinewithReverse then 
				-- distanceToAdd = 1000000		-- do not add this here with multiple iterations !
			--end

			newdist = newdist + distanceToAdd
			if math.abs(angle) > 90 and (not isReverseStart and not isReverseEnd) then
				newdist = 100000000
			else
				AutoDrive.dijkstraCalc.pre[linked] = current
				AutoDrive.dijkstraCalc.distance[linked] = newdist
				AutoDrive.dijkstraCalc.preBlue[linked] = -1
			end
			if AutoDrive.dijkstraCalc.pre[linked] == nil or AutoDrive.dijkstraCalc.pre[linked] <= 0 then
				return true, false --AutoDrive.dijkstraCalc.pre[linked] = current
			end
			current = linked
			linked = wayPoints[current].out[1]

			if nil == AutoDrive.dijkstraCalc.pre[linked] then
				AutoDrive.dijkstraCalc.pre[linked] = -1
			end
			current_pre = AutoDrive.dijkstraCalc.pre[linked] % AutoDrive.dijkstraCalc.passfactor
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
			wp_ref = wayPoints[AutoDrive.dijkstraCalc.pre[current]%AutoDrive.dijkstraCalc.passfactor]
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
			AutoDrive.dijkstraCalc.preBlue[linked] = -1
			if #wayPoints[linked].out > 0 then
				AutoDrive.dijkstraCalc.Q.dummy_id = AutoDrive.dijkstraCalc.Q.dummy_id + 1
				table.insert(AutoDrive.dijkstraCalc.Q, 1, AutoDrive.dijkstraCalc.Q.dummy_id)
				AutoDrive.dijkstraCalc.Q[1] = linked
			end
		elseif current_pre ~= 0 and newdist < 100000000 and current_pre ~= current then	--Bad angle. Can we reach the following wp from another angle?
			
			if #wayPoints[linked].out >= 1 then
				for i,id_out in pairs (wayPoints[linked].out) do
					local wp_out = wayPoints[id_out]
					angle = AutoDrive.angleBetween({x = wp_out.x - wp_ahead.x, z = wp_out.z - wp_ahead.z}, {x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z})
					angle = math.abs(angle)
					if math.abs(angle) <= 90 then
						local dist = newdist + ADGraphManager:getDistanceBetweenNodes(linked, id_out)
						if nil == AutoDrive.dijkstraCalc.distance[id_out] then
							AutoDrive.dijkstraCalc.distance[id_out] = 100000000
						end
						if nil == AutoDrive.dijkstraCalc.distanceBlue[id_out] then
							AutoDrive.dijkstraCalc.distanceBlue[id_out] = 100000000
						end
						if dist < AutoDrive.dijkstraCalc.distance[id_out] then
							local new_pre = linked + current*AutoDrive.dijkstraCalc.passfactor
							AutoDrive.dijkstraCalc.pre[id_out] = new_pre
							AutoDrive.dijkstraCalc.distance[id_out] = dist
							AutoDrive.dijkstraCalc.preBlue[id_out] = -1
							if #wayPoints[id_out].out > 0 then
								AutoDrive.dijkstraCalc.Q.dummy_id = AutoDrive.dijkstraCalc.Q.dummy_id + 1
								table.insert(AutoDrive.dijkstraCalc.Q, 1, AutoDrive.dijkstraCalc.Q.dummy_id)
								AutoDrive.dijkstraCalc.Q[1] = id_out
							end
						elseif dist < AutoDrive.dijkstraCalc.distanceBlue[id_out] and true == ADGraphManager:isDualRoad(wayPoints[linked], wayPoints[id_out]) then
							local new_pre = linked + current*AutoDrive.dijkstraCalc.passfactor
							AutoDrive.dijkstraCalc.preBlue[id_out] = new_pre
							AutoDrive.dijkstraCalc.distanceBlue[id_out] = dist
							if #wayPoints[id_out].out > 0 then
								AutoDrive.dijkstraCalc.Q.dummy_id = AutoDrive.dijkstraCalc.Q.dummy_id + 1
								table.insert(AutoDrive.dijkstraCalc.Q, 1, AutoDrive.dijkstraCalc.Q.dummy_id)
								AutoDrive.dijkstraCalc.Q[1] = id_out
							end
						end
					end
				end
				_, target_found = AutoDrive:dijkstraLiveBlueLongLineBlue(current, linked, target_id, newdist)
			end
		end

		if target_found == true then
			return true, true
		end

		if linked == target_id and newdist < 100000000 then
			-- if route to target is reverse or angle > 90, we have not to reach it here
			AutoDrive.dijkstraCalc.distance[linked] = newdist
			AutoDrive.dijkstraCalc.pre[linked] = current
			AutoDrive.dijkstraCalc.preBlue[linked] = -1

			AutoDrive.dijkstraCalc.Q.dummy_id = AutoDrive.dijkstraCalc.Q.dummy_id + 1
			table.insert(AutoDrive.dijkstraCalc.Q, 1, AutoDrive.dijkstraCalc.Q.dummy_id)
			AutoDrive.dijkstraCalc.Q[1] = linked

			return true, true
		end

		return true, false
	else
		if AutoDrive.dijkstraCalc.distanceBlue[current] ~= nil and AutoDrive.dijkstraCalc.distanceBlue[current] < 100000000 then
			newdist = AutoDrive.dijkstraCalc.distanceBlue[current]
		else
			if nil == AutoDrive.dijkstraCalc.distance[current] then
				AutoDrive.dijkstraCalc.distance[current] = 100000000
			end
			newdist = AutoDrive.dijkstraCalc.distance[current]
		end
		return AutoDrive:dijkstraLiveBlueLongLineBlue(current, linked, target_id, newdist)
	end -- if...
end

function AutoDrive:dijkstraLiveBlue(start, target)
	local distanceToAdd = 0
	local angle = 0
	local result = false
	local target_found = false
	local wayPoints = ADGraphManager:getWayPoints()

	if start == nil or start == 0 or start == -1 or target == nil or target == 0 or target == -1 then
		return false
	end

	AutoDrive:dijkstraLiveBlueInit(start)

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
							result, target_found = AutoDrive:dijkstraLiveBlueLongLine(shortest_id, linkedNodeId, target)

							if target_found == true then
								return true
							end

							if result ~= true then
								distanceToAdd = 0
								angle = 0
								if nil == AutoDrive.dijkstraCalc.pre[shortest_id] then
									AutoDrive.dijkstraCalc.pre[shortest_id] = -1
								end
								if nil == AutoDrive.dijkstraCalc.preBlue[shortest_id] then
									AutoDrive.dijkstraCalc.preBlue[shortest_id] = -1
								end
								local wp_current
								local wp_ahead
								local wp_ref
								local isReverseStart = false
								local isReverseEnd = false
								local isLinewithReverse = false
								wp_current = wayPoints[shortest_id]
								wp_ahead = wayPoints[linkedNodeId]

								distanceToAdd = ADGraphManager:getDistanceBetweenNodes(shortest_id, linkedNodeId)
								if AutoDrive.dijkstraCalc.pre[shortest_id] ~= nil and AutoDrive.dijkstraCalc.pre[shortest_id] ~= -1 then
									if AutoDrive.dijkstraCalc.preBlue[shortest_id] ~= nil and AutoDrive.dijkstraCalc.preBlue[shortest_id] ~= -1 then	--we are on the second pass
										wp_ref = wayPoints[AutoDrive.dijkstraCalc.preBlue[shortest_id]%AutoDrive.dijkstraCalc.passfactor]
										isReverseStart = not table.contains(wp_ahead.incoming, wp_current.id)
										isReverseEnd = table.contains(wp_ahead.incoming, wp_current.id) and not table.contains(wp_current.incoming, wp_ref.id)
										isLinewithReverse = isLinewithReverse or (isReverseStart or isReverseEnd)
										
										angle = AutoDrive.angleBetween({x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z}, {x = wp_current.x - wp_ref.x, z = wp_current.z - wp_ref.z})
										angle = math.abs(angle)
									else																										--we are on the first pass
										wp_ref = wayPoints[AutoDrive.dijkstraCalc.pre[shortest_id]%AutoDrive.dijkstraCalc.passfactor]
										isReverseStart = not table.contains(wp_ahead.incoming, wp_current.id)
										isReverseEnd = table.contains(wp_ahead.incoming, wp_current.id) and not table.contains(wp_current.incoming, wp_ref.id)
										isLinewithReverse = isLinewithReverse or (isReverseStart or isReverseEnd)
										
										angle = AutoDrive.angleBetween({x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z}, {x = wp_current.x - wp_ref.x, z = wp_current.z - wp_ref.z})
										angle = math.abs(angle)
									end
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

								if nil == AutoDrive.dijkstraCalc.distanceBlue[linkedNodeId] then
									AutoDrive.dijkstraCalc.distanceBlue[linkedNodeId] = 100000000
								end
								if nil == AutoDrive.dijkstraCalc.preBlue[linkedNodeId] then
									AutoDrive.dijkstraCalc.preBlue[linkedNodeId] = -1
								end
								local current_pre = AutoDrive.dijkstraCalc.pre[linkedNodeId]

								if alternative < AutoDrive.dijkstraCalc.distance[linkedNodeId] and alternative < 100000000 then
									-- if route to target is reverse or angle > 90, we have not to reach it here
									AutoDrive.dijkstraCalc.distance[linkedNodeId] = alternative
									AutoDrive.dijkstraCalc.pre[linkedNodeId] = shortest_id

									AutoDrive.dijkstraCalc.Q.dummy_id = AutoDrive.dijkstraCalc.Q.dummy_id + 1

									table.insert(AutoDrive.dijkstraCalc.Q, 1, AutoDrive.dijkstraCalc.Q.dummy_id)

									AutoDrive.dijkstraCalc.Q[1] = linkedNodeId
								elseif current_pre ~= 0 and alternative < 100000000 and current_pre ~= shortest_id then	--Bad angle. Can we reach the following wp from another angle?

									if #wayPoints[linkedNodeId].out >= 1 then
										for i,id_out in pairs (wayPoints[linkedNodeId].out) do
											local wp_out = wayPoints[id_out]
											angle = AutoDrive.angleBetween({x = wp_out.x - wp_ahead.x, z = wp_out.z - wp_ahead.z}, {x = wp_ahead.x - wp_current.x, z = wp_ahead.z - wp_current.z})
											angle = math.abs(angle)
											if math.abs(angle) <= 90 then
												local dist = alternative + ADGraphManager:getDistanceBetweenNodes(linkedNodeId, id_out)
												if nil == AutoDrive.dijkstraCalc.distance[id_out] then
													AutoDrive.dijkstraCalc.distance[id_out] = 100000000
												end
												if nil == AutoDrive.dijkstraCalc.distanceBlue[id_out] then
													AutoDrive.dijkstraCalc.distanceBlue[id_out] = 100000000
												end
												if dist < AutoDrive.dijkstraCalc.distance[id_out] then
													local new_pre = linkedNodeId + shortest_id*AutoDrive.dijkstraCalc.passfactor
													AutoDrive.dijkstraCalc.pre[id_out] = new_pre
													AutoDrive.dijkstraCalc.distance[id_out] = dist
													AutoDrive.dijkstraCalc.preBlue[id_out] = -1
													if #wayPoints[id_out].out > 0 then
														AutoDrive.dijkstraCalc.Q.dummy_id = AutoDrive.dijkstraCalc.Q.dummy_id + 1
														table.insert(AutoDrive.dijkstraCalc.Q, 1, AutoDrive.dijkstraCalc.Q.dummy_id)
														AutoDrive.dijkstraCalc.Q[1] = id_out
													end
												else
													if AutoDrive.dijkstraCalc.distanceBlue[shortest_id] ~= nil and AutoDrive.dijkstraCalc.distanceBlue[shortest_id] < 100000000 and AutoDrive.dijkstraCalc.distance[shortest_id] ~= nil and AutoDrive.dijkstraCalc.distance[shortest_id] < AutoDrive.dijkstraCalc.distanceBlue[shortest_id] then
														dist = dist + AutoDrive.dijkstraCalc.distanceBlue[shortest_id] - AutoDrive.dijkstraCalc.distance[shortest_id]
													end
													if dist < AutoDrive.dijkstraCalc.distanceBlue[id_out] and true == ADGraphManager:isDualRoad(wayPoints[linkedNodeId], wayPoints[id_out]) then
														local new_pre = linkedNodeId + shortest_id*AutoDrive.dijkstraCalc.passfactor
														AutoDrive.dijkstraCalc.preBlue[id_out] = new_pre
														AutoDrive.dijkstraCalc.distanceBlue[id_out] = dist
														if #wayPoints[id_out].out > 0 then
															AutoDrive.dijkstraCalc.Q.dummy_id = AutoDrive.dijkstraCalc.Q.dummy_id + 1
															table.insert(AutoDrive.dijkstraCalc.Q, 1, AutoDrive.dijkstraCalc.Q.dummy_id)
															AutoDrive.dijkstraCalc.Q[1] = id_out
														end
													end
												end
											end -- if math.abs(angle) <= 90 then
										end
									end
								end	-- if alternative < AutoDrive.dijkstraCalc.distance[linkedNodeId] and alternative < 100000000 then
							end
						end -- if wp ~= nil then
						if linkedNodeId == target and AutoDrive.dijkstraCalc.distance[linkedNodeId] ~= nil and AutoDrive.dijkstraCalc.distance[linkedNodeId] < 100000000 then
							return true
						end
					end -- for i, linkedNodeId in pairs...
				end -- if
			end -- if AutoDrive.dijkstraCalc.Q[shortest_id] ~= nil then
		end
	end	-- while next(AutoDrive.dijkstraCalc.Q, nil) ~= nil do

	if next(AutoDrive.dijkstraCalc.Q, nil) == nil then
		return true
	end

	return false
end

function AutoDrive:dijkstraLiveBlueInit(start)
	if AutoDrive.dijkstraCalc == nil then
		AutoDrive.dijkstraCalc = {}
	end

	AutoDrive.dijkstraCalc.distance = {}
	AutoDrive.dijkstraCalc.pre = {}
	AutoDrive.dijkstraCalc.distanceBlue = {}
	AutoDrive.dijkstraCalc.preBlue = {}

	AutoDrive.dijkstraCalc.passfactor = ADGraphManager:getWayPointsCount() + 1		--factor to multiply by N passes through the same waypoint. Cheat to store 2 wp in 1 variable. Used for the second pass through a same wp when the first pass we can´t turn to desired waypoint because of angle >90 (blue lanes and loops to a same point)

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
function AutoDrive:dijkstraLiveBlueShortestPath(start_id, target_id)
    if ADGraphManager:hasChanges() then
		AutoDrive.checkWaypointsLinkedtothemselve(true)		-- find WP linked to themselve, with parameter true issues will be fixed
		AutoDrive.checkWaypointsMultipleSameOut(true)		-- find WP with multiple same out ID, with parameter true issues will be fixed
        ADGraphManager:resetChanges()
    end

	local dist = 100000000
	local wayPoints = ADGraphManager:getWayPoints()
	local ret = false
	ret = AutoDrive:dijkstraLiveBlue(start_id, target_id)
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
				if AutoDrive.dijkstraCalc.preBlue[id] ~= nil and AutoDrive.dijkstraCalc.preBlue[id] ~= -1 and AutoDrive.dijkstraCalc.distanceBlue[id] ~= nil and AutoDrive.dijkstraCalc.distanceBlue[id] < 100000000 and AutoDrive.dijkstraCalc.distanceBlue[id] < dist then
					dist = AutoDrive.dijkstraCalc.distanceBlue[id]
					if AutoDrive.dijkstraCalc.passfactor ~= 0 and AutoDrive.dijkstraCalc.preBlue[id] >= AutoDrive.dijkstraCalc.passfactor then
						local new_pre = AutoDrive.dijkstraCalc.preBlue[id] % AutoDrive.dijkstraCalc.passfactor
						table.insert(wp, 1, wayPoints[new_pre])
						local id_copy = id
						id = math.floor((AutoDrive.dijkstraCalc.preBlue[id] - new_pre) / AutoDrive.dijkstraCalc.passfactor)
						AutoDrive.dijkstraCalc.preBlue[id_copy] = -1
					else
						local new_pre = AutoDrive.dijkstraCalc.preBlue[id]
						AutoDrive.dijkstraCalc.preBlue[id] = -1
						id = new_pre
					end
				elseif AutoDrive.dijkstraCalc.passfactor ~= 0 and AutoDrive.dijkstraCalc.pre[id] >= AutoDrive.dijkstraCalc.passfactor then
					if AutoDrive.dijkstraCalc.distance[id] ~= nil then
						dist = AutoDrive.dijkstraCalc.distance[id]
					end
					local new_pre = AutoDrive.dijkstraCalc.pre[id] % AutoDrive.dijkstraCalc.passfactor
					table.insert(wp, 1, wayPoints[new_pre])
					id = math.floor((AutoDrive.dijkstraCalc.pre[id] - new_pre) / AutoDrive.dijkstraCalc.passfactor)
				else
					if AutoDrive.dijkstraCalc.distance[id] ~= nil then
						dist = AutoDrive.dijkstraCalc.distance[id]
					end
					id = AutoDrive.dijkstraCalc.pre[id]
				end
			else -- invalid Route -> keep Vehicle at start point
				--				print(string.format("jala15: AutoDrive:dijkstraLiveBlueShortestPath ERROR invalid Route count = %d -> keep Vehicle at start point",count))
				-- TODO: message to user route not calculateable
				return {}
			end
		end
		if count > 50000 then
			print(string.format("jala15: AutoDrive:dijkstraLiveBlueShortestPath ERROR count > 50000"))
			return {} --something went wrong. prevent overflow here
		end
	end

	return wp
end
