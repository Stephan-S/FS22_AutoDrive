
--- Connects two waypoints.
---@class ADBrushStraightLine : ADBrushConnect
ADBrushStraightLine = {
	imageFilename ="textures/input_record_4.dds",
	name = "Straight line",
	DELAY = 100,
	MIN_DIST = 2,
	MAX_DIST = 20,
	START_DIST = 6,
	primaryButtonText = "Create straight line",
	primaryAxisText = "Change spacing (%d)",

}
local ADBrushStraightLine_mt = Class(ADBrushStraightLine,ADBrushConnect)
function ADBrushStraightLine.new(customMt,cursor)
	local self =  ADBrushConnect.new(customMt or ADBrushStraightLine_mt, cursor)
	self.supportsPrimaryAxis = true

	self.spacing = self.START_DIST
	self.waypoints = {}
	self.sortedWaypoints = {}
	self.delay = g_time
	return self
end

function ADBrushStraightLine:onButtonPrimary(isDown, isDrag, isUp)
	
	
	if isDown and not isDrag then
		if self.delay <= g_time then 
			local nodeId = self:getHoveredNodeId()
			if not self.waypoints[nodeId] then
				if nodeId then 
					self.waypoints[nodeId] = true
					table.insert(self.sortedWaypoints,nodeId)
					return
				else 
					local x, y, z = self.cursor:getPosition()	
					local newNodeId = self:createWaypoint(1, x, y, z)
					self:setPrio(newNodeId, false)
				end
			end
		end
		self.delay = g_time + self.DELAY
	end

	if isDrag and #self.sortedWaypoints>0 then 
		self:moveWaypoints()
	end

	if isUp then 
		if self.delay <= g_time then 
			local oldNodeId = self:getOldHoveredNodeId()
			if oldNodeId and #self.sortedWaypoints>0 then 
				local ix = #self.sortedWaypoints
				self:removeWayPoint(ix, self.sortedWaypoints[ix])
				self.sortedWaypoints[ix] = oldNodeId
			end
			self:sendEvent()
			self.waypoints = {}
			self.sortedWaypoints = {}
		end
	end

end

--- Synchronize the connections, flags and movement only once the creation is finished.
function ADBrushStraightLine:sendEvent()
	local node, nodeId, prevNodeId
	local x, y, z, flags
	for i=1,#self.sortedWaypoints do 
		nodeId = self.sortedWaypoints[i]
		node = ADGraphManager:getWayPointById(nodeId)
		x, y, z, flags = node.x, node.y, node.z, node.flags
		ADGraphManager:moveWayPoint(nodeId, x, y, z, flags)

		if i>1 then 
			self:connectWaypoints(prevNodeId,nodeId)
		end
		prevNodeId = nodeId
	end
end

function ADBrushStraightLine:getOldHoveredNodeId()
	local x, y, z = self.cursor:getPosition()
	-- try to get a waypoint in mouse range
	for _, point in pairs(AdWaypointUtils.getWayPointsInRange(self.ad,0, math.huge)) do
		if self:isAtPos(point, x, y, z) and not self.waypoints[point.id] then
			return point.id
		end
	end
end


function ADBrushStraightLine:moveWaypoints()
	local x, y, z = self.cursor:getPosition()
	if x == nil then 
		return
	end
	local firstWayPoint = ADGraphManager:getWayPointById(self.sortedWaypoints[1])
	local tx, tz = firstWayPoint.x, firstWayPoint.z

	local dist = MathUtil.vector2Length(x-tx,z-tz)

	local spacing = self.spacing

	local nx, nz = MathUtil.vector2Normalize(x-tx, z-tz)
	
	if nx == nil or nz == nil then 
		nx = 0
		nz = 1
	end

	local n = math.ceil(dist/spacing)

	spacing = dist/n

	for i=1, n do 
		self:moveSingleWaypoint(i, tx+nx*i*spacing, y, tz+nz*i*spacing)
	end
	self:deleteNotUsedWaypoints(n)
end

function ADBrushStraightLine:moveSingleWaypoint(i, x, y, z)
	local ny = math.abs(ADGraphManager:getWayPointById(self.sortedWaypoints[1]).y - ADGraphManager:getWayPointById(self.sortedWaypoints[#self.sortedWaypoints]).y)
	local _, _, dy, _ = RaycastUtil.raycastClosest(x, y + ny + 4, z, 0, -1, 0, GuiTopDownCursor.RAYCAST_DISTANCE, self.cursor.rayCollisionMask) 
	local nodeId = self.sortedWaypoints[i+1]
	if nodeId == nil then 
		nodeId = self:createWaypoint(i, x, y, z)
		self:connectWaypoints(self.sortedWaypoints[i], nodeId, false)
	else 
		self:connectWaypoints(self.sortedWaypoints[i], nodeId, false)
		local node = ADGraphManager:getWayPointById(nodeId)
		if node then
			ADGraphManager:moveWayPoint(nodeId, x, dy, z, node.flags, false)
		else 
			self.sortedWaypoints[i+1] = nil
		end
	end
end

function ADBrushStraightLine:createWaypoint(i, x, y, z)
	local nodeId = ADGraphManager:createWayPoint(x, y, z).id
	self.waypoints[nodeId] = true
	table.insert(self.sortedWaypoints,nodeId)
	return nodeId
end

function ADBrushStraightLine:removeWayPoint(i, id)
	ADGraphManager:removeWayPoint(id)
	self.waypoints[id] = false
	self.sortedWaypoints[i] = nil
end

function ADBrushStraightLine:deleteNotUsedWaypoints(n)
	for i = #self.sortedWaypoints, n+2, -1 do 
		if i>1 and self.sortedWaypoints[i] then
			self:removeWayPoint(i, self.sortedWaypoints[i])
		end
	end
end

function ADBrushStraightLine:onButtonSecondary()
	
end

function ADBrushStraightLine:onAxisPrimary(inputValue)
	self:setSpacing(inputValue)
	self:setInputTextDirty()
end

function ADBrushStraightLine:setSpacing(inputValue)
	self.spacing = MathUtil.clamp(self.spacing + inputValue, self.MIN_DIST, self.MAX_DIST)
end

function ADBrushStraightLine:activate()
	self.waypoints = {}
	self.sortedWaypoints = {}
	ADBrushStraightLine:superClass().activate(self)
end

function ADBrushStraightLine:deactivate()
	self:sendEvent()
	self.waypoints = {}
	self.sortedWaypoints = {}
	ADBrushStraightLine:superClass().deactivate(self)
end

function ADBrushStraightLine:getButtonPrimaryText()
	return self.primaryButtonText
end

function ADBrushStraightLine:getAxisPrimaryText()
	return string.format(self.primaryAxisText, self.spacing)
end

