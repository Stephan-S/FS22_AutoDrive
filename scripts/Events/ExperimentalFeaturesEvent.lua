AutoDriveExperimentalFeaturesEvent = {}
AutoDriveExperimentalFeaturesEvent_mt = Class(AutoDriveExperimentalFeaturesEvent, Event)

InitEventClass(AutoDriveExperimentalFeaturesEvent, "AutoDriveExperimentalFeaturesEvent")

function AutoDriveExperimentalFeaturesEvent:emptyNew()
    local o = Event:new(AutoDriveExperimentalFeaturesEvent_mt)
    o.className = "AutoDriveExperimentalFeaturesEvent"
    return o
end

function AutoDriveExperimentalFeaturesEvent:new(featureName, state)
    local o = AutoDriveExperimentalFeaturesEvent:emptyNew()
    o.featureName = featureName
    o.state = state
    return o
end

function AutoDriveExperimentalFeaturesEvent:writeStream(streamId)
    AutoDrive.streamWriteStringOrEmpty(streamId, self.featureName)
    streamWriteBool(streamId, self.state)
end

function AutoDriveExperimentalFeaturesEvent:readStream(streamId, connection)
    self.featureName = AutoDrive.streamReadStringOrEmpty(streamId)
    self.state = streamReadBool(streamId)
    self:run(connection)
end

function AutoDriveExperimentalFeaturesEvent:run(connection)
    if g_server ~= nil and connection:getIsServer() == false then
        -- If the event is coming from a client, server have only to broadcast
        AutoDriveExperimentalFeaturesEvent.sendEvent(self.featureName, self.state)
    else
        -- If the event is coming from the server, both clients and server have to act
        if self.featureName ~= "" then
            AutoDrive.experimentalFeatures[self.featureName] = self.state
            print(string.format("AutoDrive.experimentalFeatures.%s = %s", self.featureName, AutoDrive.experimentalFeatures[self.featureName]))
        end
    end
end

function AutoDriveExperimentalFeaturesEvent.sendEvent(featureName, state)
    local event = AutoDriveExperimentalFeaturesEvent:new(featureName, state)
    if g_server ~= nil then
        -- Server have to broadcast to all clients and himself
        g_server:broadcastEvent(event, true)
    else
        -- Client have to send to server
        g_client:getServerConnection():sendEvent(event)
    end
end

function AutoDriveExperimentalFeaturesEvent.sendToClient(connection, featureName, state)
    if g_server ~= nil then
        connection:sendEvent(AutoDriveExperimentalFeaturesEvent:new(featureName, state))
    end
end
