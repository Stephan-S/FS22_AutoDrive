AutoDriveCreateWayPointEvent = {}
AutoDriveCreateWayPointEvent_mt = Class(AutoDriveCreateWayPointEvent, Event)

InitEventClass(AutoDriveCreateWayPointEvent, "AutoDriveCreateWayPointEvent")

function AutoDriveCreateWayPointEvent.emptyNew()
	local self = Event.new(AutoDriveCreateWayPointEvent_mt)
	return self
end

function AutoDriveCreateWayPointEvent.new(x, y, z)
	local self = AutoDriveCreateWayPointEvent.emptyNew()
	self.x = x
	self.y = y
	self.z = z
	return self
end

function AutoDriveCreateWayPointEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.x)
	streamWriteFloat32(streamId, self.y)
	streamWriteFloat32(streamId, self.z)
end

function AutoDriveCreateWayPointEvent:readStream(streamId, connection)
	self.x = streamReadFloat32(streamId)
	self.y = streamReadFloat32(streamId)
	self.z = streamReadFloat32(streamId)
	self:run(connection)
end

function AutoDriveCreateWayPointEvent:run(connection)
	--- Create waypoint on server and receiving clients.
	ADGraphManager:createWayPoint(self.x, self.y, self.z, false)

	if not connection:getIsServer() then
		-- If the event is coming from a client, server has to broadcast it.
		local event = AutoDriveCreateWayPointEvent.new(self.x, self.y, self.z)
		g_server:broadcastEvent(event, nil, connection, nil)
	end
end

function AutoDriveCreateWayPointEvent.sendEvent(x, y, z)
	local event = AutoDriveCreateWayPointEvent.new(x, y, z)
	if g_server ~= nil then
		-- Server have to broadcast to all clients
		g_server:broadcastEvent(event, nil, nil, nil)
	else
		-- Client have to send to server
		g_client:getServerConnection():sendEvent(event)
	end
end
