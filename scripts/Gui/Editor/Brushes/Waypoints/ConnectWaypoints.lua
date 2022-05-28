
--- Connects two waypoints.
---@class ADBrushConnect : ADBrush
ADBrushConnect = {
	imageFilename ="textures/input_record_2.dds",
	name = "connect",
	TYPE_NORMAL = 1,
	TYPE_LOW_PRIO = 2,
	TYPE_REVERSE_NORMAL = 3,
	TYPE_REVERSE_LOW_PRIO = 4,
	TYPE_CROSSING = 5,
	TYPE_CROSSING_LOW_PRIO = 6,
	TYPE_MIN = 1,
	TYPE_MAX = 6,
	typeTexts = {
		"type_normal",
		"type_sub_route",
		"type_reverse_route",
		"type_reverse_sub_route",
		"type_crossing_route",
		"type_sub_crossing_route"
	},
}
local ADBrushConnect_mt = Class(ADBrushConnect,ADBrush)
function ADBrushConnect.new(customMt,cursor)
	local self =  ADBrush.new(customMt or ADBrushConnect_mt, cursor)
	self.supportsPrimaryButton = true
	self.supportsPrimaryDragging = true
	self.supportsTertiaryButton = true

	self.changedWaypoints = {}

	self.mode = self.TYPE_NORMAL
	return self
end

function ADBrushConnect:onButtonPrimary(isDown, isDrag, isUp)
	if self.ad.selectedNodeId == nil and isDown then 
		self.ad.selectedNodeId = self:getHoveredNodeId()
		return
	end
	local nodeId = self:getHoveredNodeId()
	if nodeId ~= nil then 
		if isDrag then 
			if nodeId ~= self.ad.selectedNodeId and not self.changedWaypoints[nodeId] then 
				self:connectWaypoints(self.ad.selectedNodeId, nodeId)
				self.ad.selectedNodeId = nodeId
				self.changedWaypoints[nodeId] = true
			end
		end
	end
	if isUp then 
		self.ad.selectedNodeId = nil
		self.changedWaypoints = {}
	end
end

function ADBrushConnect:connectWaypoints(nodeId, targetNodeId, sendEvent)
	local startNode, targetNode = ADGraphManager:getWayPointById(nodeId), ADGraphManager:getWayPointById(targetNodeId)
	ADGraphManager:setConnectionBetween(startNode, targetNode, self:getCurrentConnectionType(), sendEvent)
	self:setPrio(targetNodeId, sendEvent)
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

function ADBrushConnect:setPrio(nodeId, sendEvent)
	ADGraphManager:setSubPrio(nodeId, self.mode == self.TYPE_LOW_PRIO or self.mode == self.TYPE_REVERSE_LOW_PRIO 
												or self.mode == self.TYPE_CROSSING_LOW_PRIO, sendEvent)
end

function ADBrushConnect:clearConnection(startNode, endNode, sendEvent)
	ADGraphManager:setConnectionBetween(startNode, endNode, 0, sendEvent)
end

function ADBrushConnect:onButtonSecondary()
	
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
		self:setInputTextDirty()
	end
end

function ADBrushConnect:activate()
	self.ad.selectedNodeId = nil
	self.changedWaypoints = {}
end

function ADBrushConnect:deactivate()
	self.ad.selectedNodeId = nil
	self.changedWaypoints = {}
end

function ADBrushConnect:getButtonPrimaryText()
	return self:getTranslation(self.primaryButtonText)
end

function ADBrushConnect:getButtonTertiaryText()
	return self:getTranslation(self.tertiaryButtonText, ADBrushConnect.getTranslation(ADBrushConnect, self.typeTexts[self.mode]))
end
