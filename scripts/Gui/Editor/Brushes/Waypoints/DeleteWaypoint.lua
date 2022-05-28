
--- Creates a new waypoint at the mouse position.
---@class ADBrushDelete : ADBrush
ADBrushDelete = {
	imageFilename ="textures/input_removeWaypoint.dds",
	name = "delete",
}
local ADBrushDelete_mt = Class(ADBrushDelete,ADBrush)
function ADBrushDelete.new(customMt,cursor)
	local self =  ADBrush.new(customMt or ADBrushDelete_mt, cursor)
	self.supportsPrimaryButton = true
	self.supportsPrimaryDragging = true

	return self
end

function ADBrushDelete:onButtonPrimary(isDown, isDrag, isUp)
	local nodeId = self:getHoveredNodeId()	
	if nodeId ~= nil then 
		if isDown or isDrag then
			ADGraphManager:removeWayPoint(nodeId)
		end
	end
end

function ADBrushDelete:getButtonPrimaryText()
	return self:getTranslation(self.primaryButtonText)
end
