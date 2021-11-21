AutoDriveCreateMapMarkerEvent = {}
AutoDriveCreateMapMarkerEvent_mt = Class(AutoDriveCreateMapMarkerEvent, Event)

InitEventClass(AutoDriveCreateMapMarkerEvent, "AutoDriveCreateMapMarkerEvent")

function AutoDriveCreateMapMarkerEvent:emptyNew()
	local o = Event:new(AutoDriveCreateMapMarkerEvent_mt)
	o.className = "AutoDriveCreateMapMarkerEvent"
	return o
end

function AutoDriveCreateMapMarkerEvent:new(wayPointId, markerName)
	local o = AutoDriveCreateMapMarkerEvent:emptyNew()
	o.wayPointId = wayPointId
	o.markerName = markerName
	return o
end

function AutoDriveCreateMapMarkerEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.wayPointId, 17)
	AutoDrive.streamWriteStringOrEmpty(streamId, self.markerName)
end

function AutoDriveCreateMapMarkerEvent:readStream(streamId, connection)
	self.wayPointId = streamReadUIntN(streamId, 17)
	self.markerName = streamReadString(streamId)
	self:run(connection)
end

function AutoDriveCreateMapMarkerEvent:run(connection)
	if g_server ~= nil and connection:getIsServer() == false then
		-- If the event is coming from a client, server have only to broadcast
		AutoDriveCreateMapMarkerEvent.sendEvent(self.wayPointId, self.markerName)
	else
		ADGraphManager:createMapMarker(self.wayPointId, self.markerName, false)
	end
end

function AutoDriveCreateMapMarkerEvent.sendEvent(wayPointId, markerName)
	local event = AutoDriveCreateMapMarkerEvent:new(wayPointId, markerName)
	if g_server ~= nil then
		-- Server have to broadcast to all clients and himself
		g_server:broadcastEvent(event, true)
	else
		-- Client have to send to server
		g_client:getServerConnection():sendEvent(event)
	end
end
