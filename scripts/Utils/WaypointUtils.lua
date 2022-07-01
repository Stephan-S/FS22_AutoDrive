---@class AdWaypointUtils
AdWaypointUtils = {}

function AdWaypointUtils.getWayPointsInRange(position,  minDistance, maxDistance)
	local points = AdWaypointUtils.updateWayPointsDistance(position)
	local inRange = {}
	for _, elem in pairs(points) do
		if elem.distance >= minDistance and elem.distance <= maxDistance and elem.wayPoint.id > 0 then
			table.insert(inRange, elem.wayPoint)
		end
	end
	return inRange
end


function AdWaypointUtils.updateWayPointsDistance(position)
    local points = {}
    local x, _, z = unpack(position)

    --We should see some perfomance increase by localizing the sqrt/pow functions right here
    local sqrt = math.sqrt
    local distanceFunc = function(a, b)
        return sqrt(a * a + b * b)
    end
    for _, wp in pairs(ADGraphManager:getWayPoints()) do
        local distance = distanceFunc(wp.x - x, wp.z - z)
        if distance <= AutoDrive.drawDistance then
            table.insert(points, {distance = distance, wayPoint = wp})
        end
    end
    return points
end
