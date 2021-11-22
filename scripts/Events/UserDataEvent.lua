AutoDriveUserDataEvent = {}
AutoDriveUserDataEvent_mt = Class(AutoDriveUserDataEvent, Event)

InitEventClass(AutoDriveUserDataEvent, "AutoDriveUserDataEvent")

function AutoDriveUserDataEvent.emptyNew()
	print("AutoDriveUserDataEvent:emptyNew")
    local self = Event.new(AutoDriveUserDataEvent_mt)
    return self
end

function AutoDriveUserDataEvent.new(hudX, hudY, settings)
    local self = AutoDriveUserDataEvent.emptyNew()
    self.hudX = hudX
    self.hudY = hudY
    self.settings = settings
    return self
end

function AutoDriveUserDataEvent:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.hudX)
    streamWriteFloat32(streamId, self.hudY)
    streamWriteUInt16(streamId, table.count(self.settings))
    for sn, sv in pairs(self.settings) do
        streamWriteString(streamId, sn)
        streamWriteUInt16(streamId, sv)
    end
end

function AutoDriveUserDataEvent:readStream(streamId, connection)
    self.hudX = streamReadFloat32(streamId)
    self.hudY = streamReadFloat32(streamId)
    local settingsCount = streamReadUInt16(streamId)
    self.settings = {}
    for _ = 1, settingsCount do
        local sn = streamReadString(streamId)
        local sv = streamReadUInt16(streamId)
        self.settings[sn] = sv
    end
    self:run(connection)
end

function AutoDriveUserDataEvent:run(connection)
    if g_server ~= nil then
        -- Saving data if we are on the server
        ADUserDataManager:updateUserSettings(connection, self.hudX, self.hudY, self.settings)
    else
        -- Applying data if we are on the client
        ADUserDataManager:applyUserSettings(self.hudX, self.hudY, self.settings)
    end
end

function AutoDriveUserDataEvent.sendToClient(connection, hudX, hudY, settings)
    connection:sendEvent(AutoDriveUserDataEvent.new(hudX, hudY, settings))
end

function AutoDriveUserDataEvent.sendToServer(hudX, hudY, settings)
    if g_server == nil then
        g_client:getServerConnection():sendEvent(AutoDriveUserDataEvent.new(hudX, hudY, settings))
    end
end
