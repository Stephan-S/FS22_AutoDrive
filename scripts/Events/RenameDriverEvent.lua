AutoDriveRenameDriverEvent = {}
AutoDriveRenameDriverEvent_mt = Class(AutoDriveRenameDriverEvent, Event)

InitEventClass(AutoDriveRenameDriverEvent, "AutoDriveRenameDriverEvent")

function AutoDriveRenameDriverEvent:emptyNew()
	local o = Event:new(AutoDriveRenameDriverEvent_mt)
	o.className = "AutoDriveRenameDriverEvent"
	return o
end

function AutoDriveRenameDriverEvent:new(vehicle, name)
	local o = AutoDriveRenameDriverEvent:emptyNew()
	o.vehicle = vehicle
	o.name = name
	return o
end

function AutoDriveRenameDriverEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, NetworkUtil.getObjectId(self.vehicle))
	AutoDrive.streamWriteStringOrEmpty(streamId, self.name)
end

function AutoDriveRenameDriverEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.getObject(streamReadInt32(streamId))
	self.name = AutoDrive.streamReadStringOrEmpty(streamId)
	self:run(connection)
end

function AutoDriveRenameDriverEvent:run(connection)
	if g_server ~= nil and connection:getIsServer() == false then
		-- If the event is coming from a client, server have only to broadcast
		AutoDriveRenameDriverEvent.sendEvent(self.vehicle, self.name)
	else
		-- If the event is coming from the server, both clients and server have to rename the driver
		AutoDrive.renameDriver(self.vehicle, self.name, false)
	end
end

function AutoDriveRenameDriverEvent.sendEvent(vehicle, name)
	local event = AutoDriveRenameDriverEvent:new(vehicle, name)
	if g_server ~= nil then
		-- Server have to broadcast to all clients and himself
		g_server:broadcastEvent(event, true)
	else
		-- Client have to send to server
		g_client:getServerConnection():sendEvent(event)
	end
end
