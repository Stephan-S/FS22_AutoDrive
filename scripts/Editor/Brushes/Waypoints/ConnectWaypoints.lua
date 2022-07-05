
--- Connects two waypoints.
---@class ADBrushConnect : ADBrush
ADBrushConnect = {
	imageFilename ="textures/input_record_2.dds",
	name = "connect",
	TYPE_NORMAL = 1,
	TYPE_LOW_PRIO = 2,
	TYPE_CROSSING = 3,
	TYPE_CROSSING_LOW_PRIO = 4,
	TYPE_REVERSE_NORMAL = 5,
	TYPE_REVERSE_LOW_PRIO = 6,
	TYPE_MIN = 1,
	TYPE_MAX = 6,
}
ADBrushConnect.typeTexts = {
	[ADBrushConnect.TYPE_NORMAL] = "type_normal",
	[ADBrushConnect.TYPE_LOW_PRIO] = "type_sub_route",
	[ADBrushConnect.TYPE_REVERSE_NORMAL] = "type_reverse_route",
	[ADBrushConnect.TYPE_REVERSE_LOW_PRIO] = "type_reverse_sub_route",
	[ADBrushConnect.TYPE_CROSSING] = "type_crossing_route",
	[ADBrushConnect.TYPE_CROSSING_LOW_PRIO] = "type_sub_crossing_route",
}

local ADBrushConnect_mt = Class(ADBrushConnect,ADBrush)
function ADBrushConnect.new(customMt,cursor)
	local self =  ADBrush.new(customMt or ADBrushConnect_mt, cursor)
	self.supportsPrimaryButton = true
	self.supportsPrimaryDragging = true
	self.supportsSecondaryButton = true
	self.supportsTertiaryButton = true

	self.changedWaypoints = {}

	self.mode = self.TYPE_NORMAL
	return self
end

function ADBrushConnect:onButtonPrimary(isDown, isDrag, isUp)
	if self.selectedNodeId == nil and isDown then 
		self.selectedNodeId = self:getHoveredNodeId()
		self.graphWrapper:setSelected(self.selectedNodeId)
		return
	end
	local nodeId = self:getHoveredNodeId()
	if nodeId ~= nil then 
		if isDrag then 
			if nodeId ~= self.selectedNodeId and not self.changedWaypoints[nodeId] then 
				self:connectWaypoints(self.selectedNodeId, nodeId)
				self.selectedNodeId = nodeId
				self.changedWaypoints[nodeId] = true
			end
		end
	end
	if isUp then 
		self.selectedNodeId = nil
		self.graphWrapper:resetSelected()
		self.changedWaypoints = {}
	end
end

function ADBrushConnect:onButtonSecondary()
	local d = self.sizeModifier + 1
	if d > self.sizeModifierMax then 
		self:changeSizeModifier(1)
	elseif d <= 0 then 
		self:changeSizeModifier(self.sizeModifierMax)
	else
		self:changeSizeModifier(d)
	end
	self:setInputTextDirty()
end

function ADBrushConnect:connectWaypoints(nodeId, targetNodeId, sendEvent)
	self.graphWrapper:setConnectionAndSubPriority(nodeId, targetNodeId, self:getCurrentConnectionType(), self:getSubPriority(), sendEvent)
end

function ADBrushConnect:getCurrentConnectionType()
	local dir = 1
	if self.mode == self.TYPE_CROSSING or self.mode == self.TYPE_CROSSING_LOW_PRIO then 
		dir = 3
	elseif self.mode == self.TYPE_REVERSE_NORMAL or self.mode == self.TYPE_REVERSE_LOW_PRIO then 
		dir = 4
	end
	return dir
end

function ADBrushConnect:getSubPriority()
	return self.mode == self.TYPE_LOW_PRIO or self.mode == self.TYPE_REVERSE_LOW_PRIO or self.mode == self.TYPE_CROSSING_LOW_PRIO
end

function ADBrushConnect:onButtonTertiary()
	self.mode = self.mode + 1
	if self.mode > self.TYPE_MAX then 
		self.mode = self.TYPE_MIN
	end
	self:setInputTextDirty()
end

--- Not working, as the brush classes need to be the same.
function ADBrushConnect:copyState(from)
	if from.mode ~= nil then 
		self.mode = from.mode
		self.sizeModifier = from.sizeModifier or 1
		self:setInputTextDirty()
	end
end

function ADBrushConnect:activate()
	self.selectedNodeId = nil
	self.changedWaypoints = {}
	self.graphWrapper:resetSelected()
end

function ADBrushConnect:deactivate()
	self.selectedNodeId = nil
	self.changedWaypoints = {}
	self.graphWrapper:resetSelected()
end

function ADBrushConnect:getButtonPrimaryText()
	return self:getTranslation(self.primaryButtonText)
end

function ADBrushConnect:getButtonSecondaryText()
	return self:getTranslation(self.secondaryButtonText, self.sizeModifier)
end

function ADBrushConnect:getButtonTertiaryText()
	return self:getTranslation(self.tertiaryButtonText, self:getTranslation(self.typeTexts[self.mode]))
end
