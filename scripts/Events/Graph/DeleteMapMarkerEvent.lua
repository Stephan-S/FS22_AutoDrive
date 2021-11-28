AutoDriveDeleteMapMarkerEvent = {}
AutoDriveDeleteMapMarkerEvent_mt = Class(AutoDriveDeleteMapMarkerEvent, Event)

InitEventClass(AutoDriveDeleteMapMarkerEvent, "AutoDriveDeleteMapMarkerEvent")

function AutoDriveDeleteMapMarkerEvent.emptyNew()
	local self = Event.new(AutoDriveDeleteMapMarkerEvent_mt)
	return self
end

function AutoDriveDeleteMapMarkerEvent.new(markerId)
	local self = AutoDriveDeleteMapMarkerEvent.emptyNew()
	self.markerId = markerId
	return self
end

function AutoDriveDeleteMapMarkerEvent:writeStream(streamId, connection)
	streamWriteUInt16(streamId, self.markerId)
end

function AutoDriveDeleteMapMarkerEvent:readStream(streamId, connection)
	self.markerId = streamReadUInt16(streamId)
	self:run(connection)
end

function AutoDriveDeleteMapMarkerEvent:run(connection)
	if g_server ~= nil and connection:getIsServer() == false then
		-- If the event is coming from a client, server have only to broadcast
		AutoDriveDeleteMapMarkerEvent.sendEvent(self.markerId)
	else
		-- If the event is coming from the server, both clients and server have to delete the map marker
		ADGraphManager:removeMapMarker(self.markerId, false)
	end
end

function AutoDriveDeleteMapMarkerEvent.sendEvent(markerId)
	local event = AutoDriveDeleteMapMarkerEvent.new(markerId)
	if g_server ~= nil then
		-- Server have to broadcast to all clients and himself
		g_server:broadcastEvent(event, true)
	else
		-- Client have to send to server
		g_client:getServerConnection():sendEvent(event)
	end
end
