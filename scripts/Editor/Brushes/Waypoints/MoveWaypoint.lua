
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
		self.graphWrapper:setSelected(self.selectedNodeId)
	end
	if isDrag then 
		if self.selectedNodeId then 
			local x, y, z = self.cursor:getPosition()
			self.graphWrapper:setPosition(self.selectedNodeId, x, y, z, false)
		end
	end
	if isUp then
		if self.selectedNodeId then 
			local x, y, z = self.cursor:getPosition()
			self.graphWrapper:setPosition(self.selectedNodeId, x, y, z, true)
		end
		self.selectedNodeId = nil
		self.graphWrapper:resetSelected()
	end
end

function ADBrushMove:activate()
	self.selectedNodeId = nil
	self.graphWrapper:resetSelected()
end

function ADBrushMove:deactivate()
	self.selectedNodeId = nil
	self.graphWrapper:resetSelected()
end

function ADBrushMove:getButtonPrimaryText()
	return self:getTranslation(self.primaryButtonText)
end