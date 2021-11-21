AutoDriveDeleteWayPointEvent = {}
AutoDriveDeleteWayPointEvent_mt = Class(AutoDriveDeleteWayPointEvent, Event)

InitEventClass(AutoDriveDeleteWayPointEvent, "AutoDriveDeleteWayPointEvent")

function AutoDriveDeleteWayPointEvent:emptyNew()
	local o = Event:new(AutoDriveDeleteWayPointEvent_mt)
	o.className = "AutoDriveDeleteWayPointEvent"
	return o
end

function AutoDriveDeleteWayPointEvent:new(wayPointId)
	local o = AutoDriveDeleteWayPointEvent:emptyNew()
	o.wayPointId = wayPointId
	return o
end

function AutoDriveDeleteWayPointEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.wayPointId, 20)
end

function AutoDriveDeleteWayPointEvent:readStream(streamId, connection)
	self.wayPointId = streamReadUIntN(streamId, 20)
	self:run(connection)
end

function AutoDriveDeleteWayPointEvent:run(connection)
	if g_server ~= nil and connection:getIsServer() == false then
		-- If the event is coming from a client, server have only to broadcast
		AutoDriveDeleteWayPointEvent.sendEvent(self.wayPointId)
	else
		-- If the event is coming from the server, both clients and server have to delete the way point
		ADGraphManager:removeWayPoint(self.wayPointId, false)
	end
end

function AutoDriveDeleteWayPointEvent.sendEvent(wayPointId)
	local event = AutoDriveDeleteWayPointEvent:new(wayPointId)
	if g_server ~= nil then
		-- Server have to broadcast to all clients and himself
		g_server:broadcastEvent(event, true)
	else
		-- Client have to send to server
		g_client:getServerConnection():sendEvent(event)
	end
end
