
--- Creates a new waypoint at the mouse position.
---@class ADBrushCreate : ADBrush
ADBrushCreate = {
	imageFilename ="textures/plusSign.dds",
	name = "Create",
	primaryButtonText = "Create",
}
local ADBrushCreate_mt = Class(ADBrushCreate,ADBrush)
function ADBrushCreate.new(customMt,cursor)
	local self =  ADBrush.new(customMt or ADBrushCreate_mt, cursor)
	self.supportsPrimaryButton = true
	--self.supportsPrimaryDragging = true

	return self
end

function ADBrushCreate:onButtonPrimary()
	if not self:getHoveredNodeId() then 
		local x, y, z = self.cursor:getPosition()
		ADGraphManager:createWayPoint(x, y, z)
	end
end

function ADBrushCreate:onButtonSecondary(isDown, isDrag, isUp)

end

function ADBrushCreate:onButtonTertiary()
	
end

function ADBrushCreate:activate()
	
end

function ADBrushCreate:deactivate()
	
end


function ADBrushCreate:getButtonPrimaryText()
	return self.primaryButtonText
end
