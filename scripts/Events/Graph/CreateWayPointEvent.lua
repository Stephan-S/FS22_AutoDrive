AutoDriveCreateWayPointEvent = {}
AutoDriveCreateWayPointEvent_mt = Class(AutoDriveCreateWayPointEvent, Event)

InitEventClass(AutoDriveCreateWayPointEvent, "AutoDriveCreateWayPointEvent")

function AutoDriveCreateWayPointEvent.emptyNew()
	print("AutoDriveCreateWayPointEvent.emptyNew")
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
	if g_server ~= nil and connection:getIsServer() == false then
		-- If the event is coming from a client, server have only to broadcast
		AutoDriveCreateWayPointEvent.sendEvent(self.x, self.y, self.z)
	else
		-- If the event is coming from the server, both clients and server have to create the way point
		ADGraphManager:createWayPoint(self.x, self.y, self.z, false)
	end
end

function AutoDriveCreateWayPointEvent.sendEvent(x, y, z)
	local event = AutoDriveCreateWayPointEvent.new(x, y, z)
	if g_server ~= nil then
		-- Server have to broadcast to all clients and himself
		g_server:broadcastEvent(event, true)
	else
		-- Client have to send to server
		g_client:getServerConnection():sendEvent(event)
	end
end
