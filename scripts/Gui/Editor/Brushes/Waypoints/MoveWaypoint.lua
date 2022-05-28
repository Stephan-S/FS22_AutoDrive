
--- Moves a waypoint relative to the mouse position.
---@class ADBrushMove : ADBrush
ADBrushMove = {
	imageFilename ="textures/input_record_3.dds",
	name = "move",
}
local ADBrushMove_mt = Class(ADBrushMove,ADBrush)
function ADBrushMove.new(customMt,cursor)
	local self =  ADBrush.new(customMt or ADBrushMove_mt, cursor)
	self.supportsPrimaryButton = true
	self.supportsPrimaryDragging = true

	return self
end

function ADBrushMove:onButtonPrimary(isDown, isDrag, isUp)
	
	if isDown then
		self.selectedNodeId = self:getHoveredNodeId()
	end
	if isDrag then 
		if self.selectedNodeId then 
			local wayPoint = ADGraphManager:getWayPointById(self.selectedNodeId)
			local x, y, z = self.cursor:getPosition()
			ADGraphManager:moveWayPoint(self.selectedNodeId, x, y, z, wayPoint.flags,false)
		end
	end
	if isUp then
		if self.selectedNodeId then 
			local wayPoint = ADGraphManager:getWayPointById(self.selectedNodeId)
			local x, y, z = self.cursor:getPosition()
			ADGraphManager:moveWayPoint(self.selectedNodeId, x, y, z, wayPoint.flags)
		end
		self.selectedNodeId = nil
	end
end

function ADBrushMove:activate()
	self.selectedNodeId = nil
end

function ADBrushMove:deactivate()
	self.selectedNodeId = nil
end

function ADBrushMove:getButtonPrimaryText()
	return self:getTranslation(self.primaryButtonText)
end