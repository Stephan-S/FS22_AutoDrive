AutoDriveInputEventEvent = {}
AutoDriveInputEventEvent_mt = Class(AutoDriveInputEventEvent, Event)

InitEventClass(AutoDriveInputEventEvent, "AutoDriveInputEventEvent")

function AutoDriveInputEventEvent.emptyNew()
    local self = Event.new(AutoDriveInputEventEvent_mt)
    return self
end

function AutoDriveInputEventEvent.new(vehicle, inputId)
    local self = AutoDriveInputEventEvent.emptyNew()
    self.vehicle = vehicle
    self.inputId = inputId
    return self
end

function AutoDriveInputEventEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.vehicle))
    streamWriteUInt8(streamId, self.inputId)
end

function AutoDriveInputEventEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.getObject(NetworkUtil.readNodeObjectId(streamId))
    self.inputId = streamReadUInt8(streamId)
    self:run(connection)
end

function AutoDriveInputEventEvent:run(connection)
    if g_server ~= nil then
        local input = ADInputManager.idsToInputs[self.inputId]
        --print(string.format("onInputCall [%s] %s", self.inputId, input))
        ADInputManager:onInputCall(self.vehicle, input, false)
    end
end

function AutoDriveInputEventEvent.sendEvent(vehicle, inputId)
    if g_client ~= nil then
        -- Client have to send to server
        g_client:getServerConnection():sendEvent(AutoDriveInputEventEvent.new(vehicle, inputId))
    end
end
