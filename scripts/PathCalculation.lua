ADPathCalculator = {}

function ADPathCalculator:GetPath(startID, targetID, preferredStartIds)
	local count = 0

    if not ADGraphManager:areWayPointsPrepared() then
		AutoDrive.checkWaypointsLinkedtothemselve(true)		-- find WP linked to themselve, with parameter true issues will be fixed
		AutoDrive.checkWaypointsMultipleSameOut(true)		-- find WP with multiple same out ID, with parameter true issues will be fixed
        ADGraphManager:prepareWayPoints()
    end

    local network = ADGraphManager:getWayPoints()
    local addedWeights = self:getDetourWeights()
    
    if startID == nil or targetID == nil or network[startID] == nil or network[targetID] == nil then
        return {}
    end

    if startID == targetID then
        return {network[startID]}
    end

    local candidates = SortedQueue:new("distance")
    candidates:enqueue({p=network[startID], distance=0, pre=-1})

    local results = {}

    local foundTarget = false
    local sqrt = math.sqrt
    local distanceFunc = function(a, b)
        return sqrt(a * a + b * b)
    end

    local isSubPrio = function(pointToTest) 
        return bitAND(pointToTest.flags, AutoDrive.FLAG_SUBPRIO) > 0
    end

    local lastPredecessor = nil
    while not candidates:empty() and not foundTarget do
        local next = candidates:dequeue()
        local point, distance, previousPoint = next.p, next.distance, next.pre
        while point ~= nil do
            if results[point.id] == nil then
                results[point.id] = {}
            end
            if point.id == targetID then
                foundTarget = true
                lastPredecessor = previousPoint
                point = nil
                break
            else
                -- Check all out points if
                -- a) is startpoint
                -- b) has multiple incoming routes? (Because we could have followed the wrong path to that intersection after all, I guess)
                -- c) we have multiple outgoing routes (coming from previousPoint)
                if previousPoint == -1 or #point.incoming > 1 or (point.transitMapping[previousPoint] == nil or #point.transitMapping[previousPoint] > 1) then
                    
                    -- use either the default .out variable of each point or preferably, use the transitMapping 
                    local outMap = point.out
                    if previousPoint ~= -1 and point.transitMapping[previousPoint] ~= nil then
                        outMap = point.transitMapping[previousPoint]
                    end

                    for _, outId in pairs(outMap) do
                        local outPoint = network[outId]
                        
                        -- Add this out point into our results table with the current distance
                        if results[point.id][outId] == nil then
                            results[point.id][outId] = {distance=distance, pre=previousPoint}
                        else
                            if results[point.id][outId].distance > distance then
                                results[point.id][outId] = {distance=distance, pre=previousPoint}
                            end
                        end

                        -- First check if this outgoing point has already been completely analyzed before
                        local toBeAdded = true
                        if results[outId] ~= nil then
                            local allOutsTested = true
                            if outPoint.transitMapping[point.id] ~= nil then
                                for _, nextOutId in pairs(outPoint.transitMapping[point.id]) do
                                    -- Check for shortcut here as well!
                                    allOutsTested = allOutsTested and results[outId][nextOutId] ~= nil and not (results[outId][nextOutId].distance > distance)
                                end
                            end
                            if allOutsTested then
                                toBeAdded = false
                            end
                        end

                        -- Add this point then
                        if toBeAdded then --or (#point.incoming > 1)
                            local factor = 1
                            if isSubPrio(outPoint) then
                                factor = 20
                            end
                            local preventTurnaroundWeight = 0
                            if point.id == startID then
                                if not table.contains(preferredStartIds, outPoint.id) then
                                    preventTurnaroundWeight = 5000000
                                end
                            end
                            candidates:enqueue({p=outPoint, distance=(distance + (distanceFunc(outPoint.x - point.x, outPoint.z - point.z) + (addedWeights[outPoint.id] or 0)) * factor + preventTurnaroundWeight), pre=point.id})
                        end
                    end
                    point = nil
                else
                    -- We can continue analyzing if this is a segment with only one possible direction
                    if #point.transitMapping[previousPoint] == 1 then
                        local outPoint = network[point.transitMapping[previousPoint][1]]
                        if results[point.id][outPoint.id] == nil then
                            results[point.id][outPoint.id] = {distance=distance, pre=previousPoint}
                        else
                            if results[point.id][outPoint.id].distance > distance then
                                results[point.id][outPoint.id] = {distance=distance, pre=previousPoint}
                            end
                        end
                        previousPoint = point.id

                        local factor = 1
                        if isSubPrio(outPoint) then
                            factor = 20
                        end

                        distance = distance + (distanceFunc(outPoint.x - point.x, outPoint.z - point.z) + (addedWeights[outPoint.id] or 0)) * factor
                        point = outPoint
                    else
                        point = nil
                    end
                end
            end
        end
    end
    
    if not foundTarget then
        return {}
    end

    --Now we just have to reverse engineer the path
    local inversePath = {}
    local point = network[targetID]
    local counter = 0
    while point ~= nil do
        counter = counter + 1
        local previousPoint = network[lastPredecessor]
        lastPredecessor = results[lastPredecessor][point.id].pre

        table.insert(inversePath, point)
        point = previousPoint

        if lastPredecessor == -1 then
            point = nil
        end
        --emergency stop - we have some loop in the graph that went through till here
        if counter >= 500000 then
            return {}
        end
    end

    local path  = {}
    local count = #inversePath
    for i=0, count-1 do
        path[count-i] = inversePath[i+1]
    end

    return path
end

function ADPathCalculator:getDetourWeights()
    local addedWeights = {}
    local maxDetour = AutoDrive.getSetting("mapMarkerDetour")
    if maxDetour > 0 then
        for _, marker in pairs(ADGraphManager:getMapMarkers()) do
            addedWeights[marker.id] = maxDetour
        end
    end
    return addedWeights
end
