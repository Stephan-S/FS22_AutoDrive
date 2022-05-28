

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
			-- TODO: Add yes or no dialog 
			--self:openTextInput(self.deleteDestination,self:getTranslation(self.inputTitle), node)

			ADGraphManager:removeMapMarker(node.markerIndex)
		end
	end
end

function ADBrushDeleteDestination:deleteDestination()
	
end

function ADBrushDeleteDestination:onButtonSecondary(isDown, isDrag, isUp)

end

function ADBrushDeleteDestination:onButtonTertiary()
	
end

function ADBrushDeleteDestination:activate()
	
end

function ADBrushDeleteDestination:deactivate()
	
end


function ADBrushDeleteDestination:getButtonPrimaryText()
	return self:getTranslation(self.primaryButtonText)
end