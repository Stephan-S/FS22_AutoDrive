
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
	self.supportsPrimaryAxis = true
	return self
end

function ADBrushDelete:onButtonPrimary(isDown, isDrag, isUp)
	local nodeId = self:getHoveredNodeId()	
	if nodeId ~= nil then 
		if isDown or isDrag then
			self.graphWrapper:removePoint(nodeId)
		end
	end
end

function ADBrushDelete:onAxisPrimary(delta)
	local d = self.sizeModifier + delta
	if d > self.sizeModifierMax then 
		self:changeSizeModifier(1)
	elseif d <= 0 then 
		self:changeSizeModifier(self.sizeModifierMax)
	else
		self:changeSizeModifier(d)
	end
	self:setInputTextDirty()
end

function ADBrushDelete:getButtonPrimaryText()
	return self:getTranslation(self.primaryButtonText)
end

function ADBrushDelete:getAxisPrimaryText()
	return self:getTranslation(self.primaryAxisText, self.sizeModifier)
end