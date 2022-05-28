
--- Creates a new waypoint at the mouse position.
---@class ADBrushCreate : ADBrush
ADBrushCreate = {
	imageFilename ="textures/plusSign.dds",
	name = "create",
}
local ADBrushCreate_mt = Class(ADBrushCreate,ADBrush)
function ADBrushCreate.new(customMt,cursor)
	local self =  ADBrush.new(customMt or ADBrushCreate_mt, cursor)
	self.supportsPrimaryButton = true

	return self
end

function ADBrushCreate:onButtonPrimary()
	if not self:getHoveredNodeId() then 
		local x, y, z = self.cursor:getPosition()
		ADGraphManager:createWayPoint(x, y, z)
	end
end

function ADBrushCreate:getButtonPrimaryText()
	return self:getTranslation(self.primaryButtonText)
end
