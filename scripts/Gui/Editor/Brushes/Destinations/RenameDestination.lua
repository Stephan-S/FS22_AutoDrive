
--- Creates a new waypoint at the mouse position.
---@class ADBrushRenameDestination : ADBrush
ADBrushRenameDestination = {
	imageFilename ="textures/input_editMapMarker_1.dds",
	name = "Rename destination",
	inputTitle = "Rename destination",
	primaryButtonText = "Delete destination",
}
local ADBrushRenameDestination_mt = Class(ADBrushRenameDestination,ADBrush)
function ADBrushRenameDestination.new(customMt,cursor)
	local self =  ADBrush.new(customMt or ADBrushRenameDestination_mt, cursor)
	self.supportsPrimaryButton = true
	--self.supportsPrimaryDragging = true

	return self
end

function ADBrushRenameDestination:onButtonPrimary()
	local nodeId = self:getHoveredNodeId()
	if nodeId ~= nil then
		local node = ADGraphManager:getMapMarkerByWayPointId(nodeId)
		if node ~= nil then
			self:openTextInput(self.renameDestination,self.inputTitle,node.markerIndex)
		end
	end
end

function ADBrushRenameDestination:renameDestination(text,clickOk,nodeId)
	if clickOk then 
		ADGraphManager:renameMapMarker(text, nodeId)
	end
end

function ADBrushRenameDestination:onButtonSecondary(isDown, isDrag, isUp)

end

function ADBrushRenameDestination:onButtonTertiary()
	
end

function ADBrushRenameDestination:activate()
	
end

function ADBrushRenameDestination:deactivate()
	
end


function ADBrushRenameDestination:getButtonPrimaryText()
	return self.primaryButtonText
end