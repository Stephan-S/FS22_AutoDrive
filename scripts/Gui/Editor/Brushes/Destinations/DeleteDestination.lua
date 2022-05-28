

--- Creates a new waypoint at the mouse position.
---@class ADBrushDeleteDestination : ADBrush
ADBrushDeleteDestination = {
	imageFilename ="textures/input_removeMapMarker_1.dds",
	name = "deleteDestination",
}
local ADBrushDeleteDestination_mt = Class(ADBrushDeleteDestination,ADBrush)
function ADBrushDeleteDestination.new(customMt,cursor)
	local self =  ADBrush.new(customMt or ADBrushDeleteDestination_mt, cursor)
	self.supportsPrimaryButton = true
	--self.supportsPrimaryDragging = true

	return self
end

function ADBrushDeleteDestination:onButtonPrimary()
	local nodeId = self:getHoveredNodeId()
	if nodeId ~= nil then
		local node = ADGraphManager:getMapMarkerByWayPointId(nodeId)
		if node then
			self:showYesNoDialog(self.deleteDestination, self:getTranslation(self.yesNoTitle, node.name), node.markerIndex)
		end
	end
end

function ADBrushDeleteDestination:deleteDestination(clickOk, markerIndex)
	if clickOk then
		ADGraphManager:removeMapMarker(markerIndex)
	end
end

function ADBrushDeleteDestination:getButtonPrimaryText()
	return self:getTranslation(self.primaryButtonText)
end