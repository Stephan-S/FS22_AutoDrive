AutoDriveToggleConnectionEvent = {}
AutoDriveToggleConnectionEvent_mt = Class(AutoDriveToggleConnectionEvent, Event)

InitEventClass(AutoDriveToggleConnectionEvent, "AutoDriveToggleConnectionEvent")

function AutoDriveToggleConnectionEvent:emptyNew()
    local o = Event:new(AutoDriveToggleConnectionEvent_mt)
    o.className = "AutoDriveToggleConnectionEvent"
    return o
end

function AutoDriveToggleConnectionEvent:new(startNode, endNode, reverseDirection)
    local o = AutoDriveToggleConnectionEvent:emptyNew()
    o.startNode = startNode
    o.endNode = endNode
    o.reverseDirection = reverseDirection
    return o
end

function AutoDriveToggleConnectionEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.startNode.id, 20)
    streamWriteUIntN(streamId, self.endNode.id, 20)
    streamWriteBool(streamId, self.reverseDirection)
end

function AutoDriveToggleConnectionEvent:readStream(streamId, connection)
    self.startNode = ADGraphManager:getWayPointById(streamReadUIntN(streamId, 20))
    self.endNode = ADGraphManager:getWayPointById(streamReadUIntN(streamId, 20))
    self.reverseDirection = streamReadBool(streamId)
    self:run(connection)
end

function AutoDriveToggleConnectionEvent:run(connection)
    if g_server ~= nil and connection:getIsServer() == false then
        -- If the event is coming from a client, server have only to broadcast
        AutoDriveToggleConnectionEvent.sendEvent(self.startNode, self.endNode, self.reverseDirection)
    else
        ADGraphManager:toggleConnectionBetween(self.startNode, self.endNode, self.reverseDirection, false)
    end
end

function AutoDriveToggleConnectionEvent.sendEvent(startNode, endNode, reverseDirection)
    local event = AutoDriveToggleConnectionEvent:new(startNode, endNode, reverseDirection)
    if g_server ~= nil then
        -- Server have to broadcast to all clients and himself
        g_server:broadcastEvent(event, true)
    else
        -- Client have to send to server
        g_client:getServerConnection():sendEvent(event)
    end
end
