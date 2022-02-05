
--- Creates a new waypoint at the mouse position.
---@class ADBrushDelete : ADBrush
ADBrushDelete = {
	imageFilename ="textures/input_removeWaypoint.dds",
	name = "Delete waypoints",
	primaryButtonText = "Delete",
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

function ADBrushDelete:onButtonSecondary()
	
end

function ADBrushDelete:onButtonTertiary()
	
end

function ADBrushDelete:activate()
	
end

function ADBrushDelete:deactivate()
	
end


function ADBrushDelete:getButtonPrimaryText()
	return self.primaryButtonText
end
