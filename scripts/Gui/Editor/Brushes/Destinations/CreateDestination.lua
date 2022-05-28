
--- Creates a new waypoint at the mouse position.
---@class ADBrushCreateDestination : ADBrush
ADBrushCreateDestination = {
	imageFilename ="textures/input_createMapMarker_1.dds",
	name = "createDestination",

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
			self:openTextInput(self.createDestination,self:getTranslation(self.inputTitle),nodeId)
		end
	end
end

function ADBrushCreateDestination:createDestination(text,clickOk,nodeId)
	if clickOk then 
		ADGraphManager:createMapMarker(nodeId, text)
	end
end

function ADBrushCreateDestination:getButtonPrimaryText()
	return self:getTranslation(self.primaryButtonText)
end
