
--- Creates a new waypoint at the mouse position.
---@class ADBrushCreateDestination : ADBrush
ADBrushCreateDestination = {
	imageFilename ="textures/input_createMapMarker_1.dds",
	name = "Create destination",
	inputTitle = "New destination",
	primaryButtonText = "Create destination",

}
local ADBrushCreateDestination_mt = Class(ADBrushCreateDestination,ADBrush)
function ADBrushCreateDestination.new(customMt,cursor)
	local self =  ADBrush.new(customMt or ADBrushCreateDestination_mt, cursor)
	self.supportsPrimaryButton = true
	--self.supportsPrimaryDragging = true

	return self
end

function ADBrushCreateDestination:onButtonPrimary()
	local nodeId = self:getHoveredNodeId()
	if nodeId ~= nil then
		local node = ADGraphManager:getMapMarkerByWayPointId(nodeId)
		if node == nil then
			self:openTextInput(self.createDestination,self.inputTitle,nodeId)
		end
	end
end

function ADBrushCreateDestination:createDestination(text,clickOk,nodeId)
	if clickOk then 
		ADGraphManager:createMapMarker(nodeId, text)
	end
end

function ADBrushCreateDestination:onButtonSecondary(isDown, isDrag, isUp)

end

function ADBrushCreateDestination:onButtonTertiary()
	
end

function ADBrushCreateDestination:activate()
	
end

function ADBrushCreateDestination:deactivate()
	
end


function ADBrushCreateDestination:getButtonPrimaryText()
	return self.primaryButtonText
end
