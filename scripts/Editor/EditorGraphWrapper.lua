ADEditorGraphWrapper = {
	
}
local ADEditorGraphWrapper_mt = Class(ADEditorGraphWrapper)
function ADEditorGraphWrapper.new(graphManger, customMt)
	local self = setmetatable({}, customMt or ADEditorGraphWrapper_mt)
	self.graphManager = graphManger

	self.selectedNodeIds = {}
	self.hoveredNodeId = nil
	self.disabledBuffer = {}

	self.visiblePoints = {}
	self.lastPosition = {0, 0, 0}
	self.isDirty = false
	return self
end

function ADEditorGraphWrapper:setDirty()
	self.isDirty = true	
end

function ADEditorGraphWrapper:setSelected(ix)
	if ix ~=nil then
		self.selectedNodeIds[ix] = true
	end
end

function ADEditorGraphWrapper:isSelected(ix)
	return ix ~= nil and self.selectedNodeIds[ix]
end

function ADEditorGraphWrapper:resetSelected()
	self.selectedNodeIds = {}
end

function ADEditorGraphWrapper:setHovered(ix)
	self.hoveredNodeId = ix
end

function ADEditorGraphWrapper:isHovered(ix)
	return ix ~= nil and self.hoveredNodeId == ix
end

function ADEditorGraphWrapper:setDisabled(ix)
	if ix ~=nil then
		self.disabledBuffer[ix] = true
	end
end

function ADEditorGraphWrapper:popDisabled()
	local i = next(self.disabledBuffer)
	self.disabledBuffer[i] = nil
	return i
end

function ADEditorGraphWrapper:resetDisabled()
	self.disabledBuffer = {}
end

function ADEditorGraphWrapper:removeDisabled()
	local l = table.toList(self.disabledBuffer)
	table.sort(l)
	for i = #l, 1, -1 do 
		self:removePoint(l[i])
	end
	self:resetDisabled()
	self:setDirty()
end

function ADEditorGraphWrapper:isDisabled(ix)
	return self.disabledBuffer[ix]
end

function ADEditorGraphWrapper:hasDisabled()
	return next(self.disabledBuffer) ~= nil
end

function ADEditorGraphWrapper:draw(position)
	local x, _, z = unpack(position)
	local dx, _, dz = unpack(self.lastPosition)
	local distance = MathUtil.vector2Length(x - dx, z - dz)
	if self.isDirty or distance > AutoDrive.drawDistance/4 then
		self:updateVisiblePoints(position)
		self.lastPosition = position
		self.isDirty = false
	end
	-- Draw close destinations
	ADDrawUtils.drawCloseDestinations(position)	
	-- Draw waypoint network.
	ADDrawUtils.drawWaypoints(self.visiblePoints, self.hoveredNodeId, self.selectedNodeIds, self.disabledBuffer)
	ADDrawingManager:draw()
end

function ADEditorGraphWrapper:updateVisiblePoints(position)
	self.visiblePoints = AdWaypointUtils.getWayPointsInRange(position,  0, AutoDrive.drawDistance)
end

function ADEditorGraphWrapper:getVisiblePoints()
	return self.visiblePoints
end

function ADEditorGraphWrapper:getPoint(id)
	return self.graphManager:getWayPointById(id)	
end

function ADEditorGraphWrapper:getPosition(id)
	local point = self:getPoint(id)
	return point.x, point.y, point.z
end

function ADEditorGraphWrapper:addPoint(x, y, z)
	self:setDirty()
	return self.graphManager:createWayPoint(x, y, z).id
end

function ADEditorGraphWrapper:removePoint(id)
	self:setDirty()
	self.graphManager:removeWayPoint(id)
end

function ADEditorGraphWrapper:setPosition(id, x, y, z, sendEvent)
	self.graphManager:moveWayPoint(id, x, y, z, self:getPoint(id).flags, sendEvent)
end

function ADEditorGraphWrapper:setSubPriority(id, priority, sendEvent)
	self.graphManager:setSubPrio(id, priority, sendEvent)
end

function ADEditorGraphWrapper:clearConnection(startNodeId, endNodeId, sendEvent)
	local startNode, endNode = self:getPoint(startNodeId), self:getPoint(endNodeId)
	if table.contains(startNode.out, endNode.id) then
		table.removeValue(startNode.out, endNode.id)
	end
	if table.contains(startNode.incoming, endNode.id) then
		table.removeValue(startNode.incoming, endNode.id)
	end
	if table.contains(endNode.out, startNode.id) then
		table.removeValue(endNode.out, startNode.id)
	end
	if table.contains(endNode.incoming, startNode.id) then
		table.removeValue(endNode.incoming, startNode.id)
	end
end

function ADEditorGraphWrapper:clearAllConnection(nodeId, sendEvent)
	for i, id in pairs(self:getPoint(nodeId).incoming) do 
		self:clearConnection(nodeId, id, sendEvent)
	end

	for i, id in pairs(self:getPoint(nodeId).out) do 
		self:clearConnection(nodeId, id, sendEvent)
	end
end

function ADEditorGraphWrapper:setConnection(nodeId, targetNodeId, type, sendEvent)
	local startNode, targetNode = self:getPoint(nodeId), self:getPoint(targetNodeId)
	self.graphManager:setConnectionBetween(startNode, targetNode, type, sendEvent)
end

function ADEditorGraphWrapper:setConnectionAndSubPriority(nodeId, targetNodeId, type, priority, sendEvent)
	self:setConnection(nodeId, targetNodeId, type, sendEvent)
	self:setSubPriority(targetNodeId, priority, sendEvent)
end

function ADEditorGraphWrapper:synchronize(id)
	local x, y, z = self:getPosition(id)
	self:setPosition(id, x, y, z)
end