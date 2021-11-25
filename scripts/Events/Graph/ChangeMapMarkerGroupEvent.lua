AutoDriveChangeMapMarkerGroupEvent = {}
AutoDriveChangeMapMarkerGroupEvent_mt = Class(AutoDriveChangeMapMarkerGroupEvent, Event)

InitEventClass(AutoDriveChangeMapMarkerGroupEvent, "AutoDriveChangeMapMarkerGroupEvent")

function AutoDriveChangeMapMarkerGroupEvent.emptyNew()
	print("AutoDriveChangeMapMarkerGroupEvent:emptyNew")
	local self = Event.new(AutoDriveChangeMapMarkerGroupEvent_mt)
	return self
end

function AutoDriveChangeMapMarkerGroupEvent.new(groupName, markerId)
	local self = AutoDriveChangeMapMarkerGroupEvent.emptyNew()
	self.groupName = groupName
	self.markerId = markerId
	return self
end

function AutoDriveChangeMapMarkerGroupEvent:writeStream(streamId, connection)
	AutoDrive.streamWriteStringOrEmpty(streamId, self.groupName)
	streamWriteUInt16(streamId, self.markerId)
end

function AutoDriveChangeMapMarkerGroupEvent:readStream(streamId, connection)
	self.groupName = AutoDrive.streamReadStringOrEmpty(streamId)
	self.markerId = streamReadUInt16(streamId)
	self:run(connection)
end

function AutoDriveChangeMapMarkerGroupEvent:run(connection)
	if g_server ~= nil and connection:getIsServer() == false then
		-- If the event is coming from a client, server have only to broadcast
		AutoDriveChangeMapMarkerGroupEvent.sendEvent(self.groupName, self.markerId)
	else
		-- If the event is coming from the server, both clients and server have to change the marker group
		ADGraphManager:changeMapMarkerGroup(self.groupName, self.markerId, false)
	end
end

function AutoDriveChangeMapMarkerGroupEvent.sendEvent(groupName, markerId)
	local event = AutoDriveChangeMapMarkerGroupEvent.new(groupName, markerId)
	if g_server ~= nil then
		-- Server have to broadcast to all clients and himself
		g_server:broadcastEvent(event, true)
	else
		-- Client have to send to server
		g_client:getServerConnection():sendEvent(event)
	end
end
