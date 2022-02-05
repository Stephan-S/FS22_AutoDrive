---@class AdWaypointUtils
AdWaypointUtils = {}

function AdWaypointUtils.getWayPointsInRange(ad,minDistance, maxDistance)
	if ad.distances.wayPoints == nil then
		AdWaypointUtils.updateWayPointsDistance(ad)
	end
	local inRange = {}
	for _, elem in pairs(ad.distances.wayPoints) do
		if elem.distance >= minDistance and elem.distance <= maxDistance and elem.wayPoint.id > 0 then
			table.insert(inRange, elem.wayPoint)
		end
	end
	return inRange

end


function AdWaypointUtils.updateWayPointsDistance(ad)
    ad.distances.wayPoints = {}
    ad.distances.closest.wayPoint = nil
    ad.distances.closest.distance = math.huge
    ad.distances.closestNotReverse.wayPoint = nil
    ad.distances.closestNotReverse.distance = math.huge

    local x, _, z = unpack(ad.position)

    --We should see some perfomance increase by localizing the sqrt/pow functions right here
    local sqrt = math.sqrt
    local distanceFunc = function(a, b)
        return sqrt(a * a + b * b)
    end
    for _, wp in pairs(ADGraphManager:getWayPoints()) do
        local distance = distanceFunc(wp.x - x, wp.z - z)
        if distance < ad.distances.closest.distance then
            ad.distances.closest.distance = distance
            ad.distances.closest.wayPoint = wp
        end
        if distance <= AutoDrive.drawDistance then
            table.insert(ad.distances.wayPoints, {distance = distance, wayPoint = wp})
        end
        if distance < ad.distances.closestNotReverse.distance and (wp.incoming == nil or #wp.incoming > 0) then
            ad.distances.closestNotReverse.distance = distance
            ad.distances.closestNotReverse.wayPoint = wp
        end
    end
end

function AdWaypointUtils.resetClosestWayPoint(ad)
    ad.distances.closest.wayPoint = -1
end

function AdWaypointUtils.resetWayPointsDistance(ad)
    ad.distances.wayPoints = nil
end

function AdWaypointUtils.getWayPointsDistance(ad)
    return ad.distances.wayPoints
end

function AdWaypointUtils.updateClosestWayPoint(ad)
    if ad.distances.wayPoints == nil then
        AdWaypointUtils.updateWayPointsDistance()
    end
    ad.distances.closest.wayPoint = nil
    ad.distances.closest.distance = math.huge
    ad.distances.closestNotReverse.wayPoint = nil
    ad.distances.closestNotReverse.distance = math.huge

    if ad.distances.wayPoints == nil then
        -- something went wrong, so exit
        return
    end
    local x, _, z = unpack(ad.position)

    --We should see some perfomance increase by localizing the sqrt/pow functions right here
    local sqrt = math.sqrt
    local distanceFunc = function(a, b)
        return sqrt(a * a + b * b)
    end
    for _, elem in pairs(ad.distances.wayPoints) do
        local wp = elem.wayPoint
        local distance = distanceFunc(wp.x - x, wp.z - z)
        if distance < ad.distances.closest.distance then
            ad.distances.closest.distance = distance
            ad.distances.closest.wayPoint = wp
        end
        if distance < ad.distances.closestNotReverse.distance and (wp.incoming == nil or #wp.incoming > 0) then
            ad.distances.closestNotReverse.distance = distance
            ad.distances.closestNotReverse.wayPoint = wp
        end
    end
end

-- update distances only if not called in (frame) update functions
function AdWaypointUtils.getClosestWayPoint(ad, noUpdate)
    if noUpdate == nil or noUpdate == false then
        -- update on request function calls - force all update
        AdWaypointUtils.updateWayPointsDistance(ad)
    end
    if ad.distances.closest.wayPoint == nil or noUpdate == true then
        -- get closest wayPoint in view distance -> perfomance improvement
        AdWaypointUtils.updateClosestWayPoint(ad)
    end
    if ad.distances.closest.wayPoint ~= nil then
        return ad.distances.closest.wayPoint.id, ad.distances.closest.distance
    end
    return -1, math.huge
end

function AdWaypointUtils.getClosestNotReversedWayPoint(ad)
    if ad.distances.closestNotReverse.wayPoint == -1 then
        AdWaypointUtils.updateWayPointsDistance(ad)
    end
    if ad.distances.closestNotReverse.wayPoint ~= nil then
        return ad.distances.closestNotReverse.wayPoint.id, ad.distances.closestNotReverse.distance
    end
    return -1, math.huge
end

function AdWaypointUtils.getWayPointsInRange(ad, minDistance, maxDistance)
    if ad.distances.wayPoints == nil then
        AdWaypointUtils.updateWayPointsDistance(ad)
    end
    local inRange = {}
    for _, elem in pairs(ad.distances.wayPoints) do
        if elem.distance >= minDistance and elem.distance <= maxDistance and elem.wayPoint.id > 0 then
            table.insert(inRange, elem.wayPoint)
        end
    end
    return inRange
end

function AdWaypointUtils.getWayPointIdsInRange(ad, minDistance, maxDistance)
    if ad.distances.wayPoints == nil then
        AdWaypointUtils.updateWayPointsDistance(ad)
    end
    local inRange = {}
    for _, elem in pairs(ad.distances.wayPoints) do
        if elem.distance >= minDistance and elem.distance <= maxDistance and elem.wayPoint.id > 0 then
            table.insert(inRange, elem.wayPoint.id)
        end
    end
    return inRange
end