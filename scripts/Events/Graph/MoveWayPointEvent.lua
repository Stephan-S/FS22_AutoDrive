AutoDriveMoveWayPointEvent = {}
AutoDriveMoveWayPointEvent_mt = Class(AutoDriveMoveWayPointEvent, Event)

InitEventClass(AutoDriveMoveWayPointEvent, "AutoDriveMoveWayPointEvent")

function AutoDriveMoveWayPointEvent.emptyNew()
	print("AutoDriveMoveWayPointEvent.emptyNew")
    local self = Event.new(AutoDriveMoveWayPointEvent_mt)
    return self
end

function AutoDriveMoveWayPointEvent.new(wayPointId, x, y, z, flags)
    local self = AutoDriveMoveWayPointEvent.emptyNew()
    self.wayPointId = wayPointId
    self.x = x
    self.y = y
    self.z = z
    self.flags = flags
    return self
end

function AutoDriveMoveWayPointEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.wayPointId, 20)
    streamWriteFloat32(streamId, self.x)
    streamWriteFloat32(streamId, self.y)
    streamWriteFloat32(streamId, self.z)
    streamWriteInt32(streamId, self.flags)
end

function AutoDriveMoveWayPointEvent:readStream(streamId, connection)
    self.wayPointId = streamReadUIntN(streamId, 20)
    self.x = streamReadFloat32(streamId)
    self.y = streamReadFloat32(streamId)
    self.z = streamReadFloat32(streamId)
    self.flags = streamReadInt32(streamId)
    self:run(connection)
end

function AutoDriveMoveWayPointEvent:run(connection)
    if g_server ~= nil and connection:getIsServer() == false then
        -- If the event is coming from a client, server have only to broadcast
        AutoDriveMoveWayPointEvent.sendEvent(self.wayPointId, self.x, self.y, self.z, self.flags)
    else
        -- If the event is coming from the server, both clients and server have to move the way point
        ADGraphManager:moveWayPoint(self.wayPointId, self.x, self.y, self.z, self.flags, false)
    end
end

function AutoDriveMoveWayPointEvent.sendEvent(wayPointId, x, y, z, flags)
    local event = AutoDriveMoveWayPointEvent.new(wayPointId, x, y, z, flags)
    if g_server ~= nil then
        -- Server have to broadcast to all clients and himself
        g_server:broadcastEvent(event, true)
    else
        -- Client have to send to server
        g_client:getServerConnection():sendEvent(event)
    end
end
