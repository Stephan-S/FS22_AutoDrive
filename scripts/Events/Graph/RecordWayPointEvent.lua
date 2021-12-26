AutoDriveRecordWayPointEvent = {}
AutoDriveRecordWayPointEvent_mt = Class(AutoDriveRecordWayPointEvent, Event)

InitEventClass(AutoDriveRecordWayPointEvent, "AutoDriveRecordWayPointEvent")

function AutoDriveRecordWayPointEvent.emptyNew()
	local self = Event.new(AutoDriveRecordWayPointEvent_mt)
	return self
end

function AutoDriveRecordWayPointEvent.new(x, y, z, connectPrevious, dual, isReverse, previousId, flags)
	local self = AutoDriveRecordWayPointEvent.emptyNew()
	self.x = x
	self.y = y
	self.z = z
	self.connectPrevious = connectPrevious or false
	self.dual = dual or false
	self.isReverse = isReverse
	self.previousId = previousId
	self.flags = flags
	return self
end

function AutoDriveRecordWayPointEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.x)
	streamWriteFloat32(streamId, self.y)
	streamWriteFloat32(streamId, self.z)
	streamWriteBool(streamId, self.connectPrevious)
	streamWriteBool(streamId, self.dual)
	streamWriteBool(streamId, self.isReverse)
	streamWriteInt32(streamId, self.previousId)
	streamWriteInt32(streamId, self.flags)
end

function AutoDriveRecordWayPointEvent:readStream(streamId, connection)
	self.x = streamReadFloat32(streamId)
	self.y = streamReadFloat32(streamId)
	self.z = streamReadFloat32(streamId)
	self.connectPrevious = streamReadBool(streamId)
	self.dual = streamReadBool(streamId)
	self.isReverse = streamReadBool(streamId)
	self.previousId = streamReadInt32(streamId)
	self.flags = streamReadInt32(streamId)
	self:run(connection)
end

function AutoDriveRecordWayPointEvent:run(connection)
	if connection:getIsServer() then
		-- If the event is coming from the server, clients have to record the way point
		ADGraphManager:recordWayPoint(self.x, self.y, self.z, self.connectPrevious, self.dual, self.isReverse, self.previousId, self.flags, false)
	end
end

function AutoDriveRecordWayPointEvent.sendEvent(x, y, z, connectPrevious, dual, isReverse, previousId, flags)
	local event = AutoDriveRecordWayPointEvent.new(x, y, z, connectPrevious, dual, isReverse, previousId, flags)
	if g_server ~= nil then
		-- Server have to broadcast to all clients
		g_server:broadcastEvent(event)
	else
		-- Client have to send to server
		g_client:getServerConnection():sendEvent(event)
	end
end
