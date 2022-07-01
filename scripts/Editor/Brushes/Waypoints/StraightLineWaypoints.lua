
--- Connects two waypoints.
---@class ADBrushStraightLine : ADBrushConnect
ADBrushStraightLine = {
	imageFilename ="textures/input_record_4.dds",
	name = "straight",
	DELAY = 100,
	MIN_DIST = 2,
	MAX_DIST = 20,
	START_DIST = 6,
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
			if not self.waypoints[nodeId] and #self.sortedWaypoints == 0 then
				if nodeId then 
					self.waypoints[nodeId] = true
					table.insert(self.sortedWaypoints,nodeId)
					return
				else 
					local x, y, z = self.cursor:getPosition()	
					local newNodeId = self:createWaypoint(1, x, y, z)
					self.graphWrapper:setSubPriority(newNodeId, self:getSubPriority(), false)
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
				self:removeWayPoint(self.sortedWaypoints[ix])
				self.sortedWaypoints[ix] = oldNodeId
			end
			self:sendEvent()
			self.waypoints = {}
			self.sortedWaypoints = {}
			self.graphWrapper:removeDisabled()
		end
	end

end

--- Synchronize the connections, flags and movement only once the creation is finished.
function ADBrushStraightLine:sendEvent()
	local nodeId, prevNodeId
	for i=1, #self.sortedWaypoints do 
		nodeId = self.sortedWaypoints[i]
		if nodeId ~=nil then
			self.graphWrapper:synchronize(nodeId)
			if i>1 then 
				self:connectWaypoints(prevNodeId,nodeId)
			end
			prevNodeId = nodeId
		end
	end
end

function ADBrushStraightLine:getOldHoveredNodeId()
	local function exclude(id)
		return self.waypoints[id]
	end

	return self:getHoveredNodeId(exclude)
end


function ADBrushStraightLine:moveWaypoints()
	local x, y, z = self.cursor:getPosition()
	if x == nil then 
		return
	end
	local tx, _, tz = self.graphWrapper:getPosition(self.sortedWaypoints[1])

	local dist = MathUtil.vector2Length(x-tx,z-tz)

	local spacing = self.spacing

	local nx, nz = MathUtil.vector2Normalize(x-tx, z-tz)
	
	if nx == nil or nz == nil then 
		nx = 0
		nz = 1
	end

	local n = math.max(math.ceil(dist/spacing), 2)

	spacing = dist/n

	for i=2, n do 
		self:moveSingleWaypoint(i, tx+nx*i*spacing, y, tz+nz*i*spacing)
	end
	self:deleteNotUsedWaypoints(n)
end

function ADBrushStraightLine:moveSingleWaypoint(i, x, y, z)
	local _,y1,_ = self.graphWrapper:getPosition(self.sortedWaypoints[1])
	local _,y2,_ = self.graphWrapper:getPosition(self.sortedWaypoints[#self.sortedWaypoints])
	local ny = math.abs(y1 - y2)
	local _, _, dy, _ = RaycastUtil.raycastClosest(x, y + ny + 4, z, 0, -1, 0, GuiTopDownCursor.RAYCAST_DISTANCE, self.cursor.rayCollisionMask) 
	local prevId = self.sortedWaypoints[i-1]
	if self.sortedWaypoints[i] == nil then 
		local nodeId = self:createWaypoint(i, x, y, z)
		self:connectWaypoints(prevId, nodeId, false)
	else 
		self:connectWaypoints(prevId, self.sortedWaypoints[i], false)
		self.graphWrapper:setPosition(self.sortedWaypoints[i], x, dy, z, false)
	end
end

function ADBrushStraightLine:createWaypoint(i, x, y, z)
	local nodeId
	if self.graphWrapper:hasDisabled() then 
		nodeId = self.graphWrapper:popDisabled()
		self.graphWrapper:setPosition(nodeId, x, y, z, false)
	else 
		nodeId = self.graphWrapper:addPoint(x, y, z)
	end
	self.waypoints[nodeId] = true
	table.insert(self.sortedWaypoints,nodeId)
	return nodeId
end

function ADBrushStraightLine:removeWayPoint(id)
	self.graphWrapper:setDisabled(id)
	self.waypoints[id] = false
	table.remove(self.sortedWaypoints)
end

function ADBrushStraightLine:deleteNotUsedWaypoints(n)
	for i = #self.sortedWaypoints, n+1, -1 do 
		self.graphWrapper:clearAllConnection(self.sortedWaypoints[i], false)
		self:removeWayPoint(self.sortedWaypoints[i])
	end
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
	self.buffer = {}
	self.graphWrapper:removeDisabled()
	ADBrushStraightLine:superClass().activate(self)
end

function ADBrushStraightLine:deactivate()
	self:sendEvent()
	self.waypoints = {}
	self.sortedWaypoints = {}
	self.graphWrapper:removeDisabled()
	ADBrushStraightLine:superClass().deactivate(self)
end

function ADBrushStraightLine:getButtonPrimaryText()
	return self:getTranslation(self.primaryButtonText)
end

function ADBrushStraightLine:getAxisPrimaryText()
	return self:getTranslation(self.primaryAxisText, self.spacing)
end

