AutoDriveSetConnectionEvent = {}
AutoDriveSetConnectionEvent_mt = Class(AutoDriveSetConnectionEvent, Event)

InitEventClass(AutoDriveSetConnectionEvent, "AutoDriveSetConnectionEvent")

function AutoDriveSetConnectionEvent.emptyNew()
    local self = Event.new(AutoDriveSetConnectionEvent_mt)
    return self
end

function AutoDriveSetConnectionEvent.new(startNode, endNode, direction)
    local self = AutoDriveSetConnectionEvent.emptyNew()
    self.startNode = startNode
    self.endNode = endNode
    self.direction = direction
    return self
end

function AutoDriveSetConnectionEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.startNode.id, 20)
    streamWriteUIntN(streamId, self.endNode.id, 20)
    streamWriteUIntN(streamId, self.direction, 4)
end

function AutoDriveSetConnectionEvent:readStream(streamId, connection)
    self.startNode = ADGraphManager:getWayPointById(streamReadUIntN(streamId, 20))
    self.endNode = ADGraphManager:getWayPointById(streamReadUIntN(streamId, 20))
    self.direction = streamReadUIntN(streamId, 4)
    self:run(connection)
end

function AutoDriveSetConnectionEvent:run(connection)
    if g_server ~= nil and connection:getIsServer() == false then
        -- If the event is coming from a client, server have only to broadcast
        AutoDriveSetConnectionEvent.sendEvent(self.startNode, self.endNode, self.direction)
    else
        ADGraphManager:setConnectionBetween(self.startNode, self.endNode, self.direction, false)
    end
end

function AutoDriveSetConnectionEvent.sendEvent(startNode, endNode, direction)
    local event = AutoDriveSetConnectionEvent.new(startNode, endNode, direction)
    if g_server ~= nil then
        -- Server have to broadcast to all clients and himself
        g_server:broadcastEvent(event, true)
    else
        -- Client have to send to server
        g_client:getServerConnection():sendEvent(event)
    end
end
