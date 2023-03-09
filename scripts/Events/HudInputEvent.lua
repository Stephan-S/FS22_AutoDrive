AutoDriveHudInputEventEvent = {}
AutoDriveHudInputEventEvent.TYPE_FIRST_MARKER = 1
AutoDriveHudInputEventEvent.TYPE_SECOND_MARKER = 2
AutoDriveHudInputEventEvent.TYPE_FILLTYPE = 3
AutoDriveHudInputEventEvent.TYPE_TOGGLE_FILLTYPE_SELECTION = 4
AutoDriveHudInputEventEvent.TYPE_TOGGLE_ALL_FILLTYPE_SELECTIONS = 5

AutoDriveHudInputEventEvent_mt = Class(AutoDriveHudInputEventEvent, Event)

InitEventClass(AutoDriveHudInputEventEvent, "AutoDriveHudInputEventEvent")

function AutoDriveHudInputEventEvent.emptyNew()
    local self = Event.new(AutoDriveHudInputEventEvent_mt)
    return self
end

function AutoDriveHudInputEventEvent.new(vehicle, eventType, value)
    local self = AutoDriveHudInputEventEvent.emptyNew()
    self.vehicle = vehicle
    self.eventType = eventType
    self.value = value
    return self
end

function AutoDriveHudInputEventEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.vehicle))
    streamWriteUInt8(streamId, self.eventType)
    streamWriteUIntN(streamId, self.value, 16)
end

function AutoDriveHudInputEventEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.getObject(NetworkUtil.readNodeObjectId(streamId))
    self.eventType = streamReadUInt8(streamId)
    self.value = streamReadUIntN(streamId, 16)
    self:run(connection)
end

function AutoDriveHudInputEventEvent:run(connection)
    if g_server ~= nil then
        if self.eventType == self.TYPE_FIRST_MARKER then
			local currentFirstMarker = self.vehicle.ad.stateModule:getFirstMarkerId()
			if currentFirstMarker > 0 and currentFirstMarker ~= self.value then
                if not (self.vehicle.spec_combine or AutoDrive.getIsBufferCombine(self.vehicle) or self.vehicle.ad.isCombine ~= nil) then
                    -- not stop / change CP for harvesters
                    AutoDrive:StopCP(self.vehicle)
                end
			end
            self.vehicle.ad.stateModule:setFirstMarker(self.value)
        end

        if self.eventType == self.TYPE_SECOND_MARKER then
            self.vehicle.ad.stateModule:setSecondMarker(self.value)
        end

        if self.eventType == self.TYPE_FILLTYPE then
            self.vehicle.ad.stateModule:setFillType(self.value)
        end

        if self.eventType == self.TYPE_TOGGLE_FILLTYPE_SELECTION then
            self.vehicle.ad.stateModule:toggleFillTypeSelection(self.value)
        end

        if self.eventType == self.TYPE_TOGGLE_ALL_FILLTYPE_SELECTIONS then
            self.vehicle.ad.stateModule:toggleAllFillTypeSelections(self.value)
        end
    end
end

function AutoDriveHudInputEventEvent:sendFirstMarkerEvent(vehicle, markerId)
    if g_client ~= nil then
        -- Client have to send to server
        g_client:getServerConnection():sendEvent(AutoDriveHudInputEventEvent.new(vehicle, self.TYPE_FIRST_MARKER, markerId))
    end
end

function AutoDriveHudInputEventEvent:sendSecondMarkerEvent(vehicle, markerId)
    if g_client ~= nil then
        -- Client have to send to server
        g_client:getServerConnection():sendEvent(AutoDriveHudInputEventEvent.new(vehicle, self.TYPE_SECOND_MARKER, markerId))
    end
end

function AutoDriveHudInputEventEvent:sendFillTypeEvent(vehicle, fillTypeId)
    if g_client ~= nil then
        -- Client have to send to server
        g_client:getServerConnection():sendEvent(AutoDriveHudInputEventEvent.new(vehicle, self.TYPE_FILLTYPE, fillTypeId))
    end
end

function AutoDriveHudInputEventEvent:sendToggleFillTypeSelectionEvent(vehicle, fillTypeId)
    if g_client ~= nil then
        -- Client have to send to server
        g_client:getServerConnection():sendEvent(AutoDriveHudInputEventEvent.new(vehicle, self.TYPE_TOGGLE_FILLTYPE_SELECTION, fillTypeId))
    end
end

function AutoDriveHudInputEventEvent:sendToggleAllFillTypeSelectionsEvent(vehicle, fillTypeId)
    if g_client ~= nil then
        -- Client have to send to server
        g_client:getServerConnection():sendEvent(AutoDriveHudInputEventEvent.new(vehicle, self.TYPE_TOGGLE_ALL_FILLTYPE_SELECTIONS, fillTypeId))
    end
end
