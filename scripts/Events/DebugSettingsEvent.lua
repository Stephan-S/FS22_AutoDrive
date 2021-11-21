AutoDriveDebugSettingsEvent = {}
AutoDriveDebugSettingsEvent_mt = Class(AutoDriveDebugSettingsEvent, Event)

InitEventClass(AutoDriveDebugSettingsEvent, "AutoDriveDebugSettingsEvent")

function AutoDriveDebugSettingsEvent:emptyNew()
    local o = Event:new(AutoDriveDebugSettingsEvent_mt)
    o.className = "AutoDriveDebugSettingsEvent"
    return o
end

function AutoDriveDebugSettingsEvent:new(currentDebugChannelMask)
    local o = AutoDriveDebugSettingsEvent:emptyNew()
    o.currentDebugChannelMask = currentDebugChannelMask
    return o
end

function AutoDriveDebugSettingsEvent:writeStream(streamId)
    -- Logging.info("[AD] AutoDriveDebugSettingsEvent.writeStream currentDebugChannelMask %s", tostring(self.currentDebugChannelMask))
    streamWriteUInt16(streamId, self.currentDebugChannelMask)
end

function AutoDriveDebugSettingsEvent:readStream(streamId, connection)
    self.currentDebugChannelMask = streamReadUInt16(streamId)
    -- Logging.info("[AD] AutoDriveDebugSettingsEvent.readStream currentDebugChannelMask %s", tostring(self.currentDebugChannelMask))
    self:run(connection)
end

function AutoDriveDebugSettingsEvent:run(connection)
    if g_server ~= nil and connection:getIsServer() == false then
        -- If the event is coming from a client, server have only to broadcast
        -- Logging.info("[AD] AutoDriveDebugSettingsEvent.run If the event is coming from a client... currentDebugChannelMask %s", tostring(self.currentDebugChannelMask))
        AutoDriveDebugSettingsEvent.sendEvent(self.currentDebugChannelMask)

        local user = g_currentMission.userManager:getUserByConnection(connection)
        if user ~= nil and user.nickname ~= nil  then
            Logging.info("[AD] DebugChannel changed by user: %s", tostring(user.nickname))
        end

    else
        -- If the event is coming from the server, both clients and server have to act
        -- Logging.info("[AD] AutoDriveDebugSettingsEvent.run If the event is coming from the server... currentDebugChannelMask %s", tostring(self.currentDebugChannelMask))
        AutoDrive.currentDebugChannelMask = self.currentDebugChannelMask
        ADGraphManager:createDebugMarkers()
    end
end

function AutoDriveDebugSettingsEvent.sendEvent(currentDebugChannelMask)
    local event = AutoDriveDebugSettingsEvent:new(currentDebugChannelMask)
    if g_server ~= nil then
        -- Server have to broadcast to all clients and himself
        -- Logging.info("[AD] AutoDriveDebugSettingsEvent.sendEvent Server have to broadcast to all clients and himself currentDebugChannelMask %s", tostring(currentDebugChannelMask))
        g_server:broadcastEvent(event, true)
    else
        -- Client have to send to server
        -- Logging.info("[AD] AutoDriveDebugSettingsEvent.sendEvent Client have to send to server currentDebugChannelMask %s", tostring(currentDebugChannelMask))
        g_client:getServerConnection():sendEvent(event)
    end
end

function AutoDriveDebugSettingsEvent.sendToClient(connection, currentDebugChannelMask)
    if g_server ~= nil then
        -- Logging.info("[AD] AutoDriveDebugSettingsEvent.sendToClient g_server ~= nil currentDebugChannelMask %s", tostring(currentDebugChannelMask))
        connection:sendEvent(AutoDriveDebugSettingsEvent:new(currentDebugChannelMask))
    end
end
