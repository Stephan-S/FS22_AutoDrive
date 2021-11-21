AutoDriveInputEventEvent = {}
AutoDriveInputEventEvent_mt = Class(AutoDriveInputEventEvent, Event)

InitEventClass(AutoDriveInputEventEvent, "AutoDriveInputEventEvent")

function AutoDriveInputEventEvent:emptyNew()
    local o = Event:new(AutoDriveInputEventEvent_mt)
    o.className = "AutoDriveInputEventEvent"
    return o
end

function AutoDriveInputEventEvent:new(vehicle, inputId)
    local o = AutoDriveInputEventEvent:emptyNew()
    o.vehicle = vehicle
    o.inputId = inputId
    return o
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
        g_client:getServerConnection():sendEvent(AutoDriveInputEventEvent:new(vehicle, inputId))
    end
end
