AutoDriveUserConnectedEvent = {}
AutoDriveUserConnectedEvent_mt = Class(AutoDriveUserConnectedEvent, Event)

InitEventClass(AutoDriveUserConnectedEvent, "AutoDriveUserConnectedEvent")

function AutoDriveUserConnectedEvent:emptyNew()
	local o = Event:new(AutoDriveUserConnectedEvent_mt)
	o.className = "AutoDriveUserConnectedEvent"
	return o
end

function AutoDriveUserConnectedEvent:new()
	return AutoDriveUserConnectedEvent:emptyNew()
end

function AutoDriveUserConnectedEvent:writeStream(streamId, connection)
end

function AutoDriveUserConnectedEvent:readStream(streamId, connection)
	self:run(connection)
end

function AutoDriveUserConnectedEvent:run(connection)
	if g_server ~= nil then
		ADUserDataManager:userConnected(connection)
		connection:sendEvent(AutoDriveUpdateSettingsEvent:new())
		-- Here we can add other sync for newly connected players
		ADUserDataManager:sendToClient(connection)
		for feature, state in pairs(AutoDrive.experimentalFeatures) do
			AutoDriveExperimentalFeaturesEvent.sendToClient(connection, feature, state)
		end
        AutoDriveDebugSettingsEvent.sendToClient(connection, AutoDrive.currentDebugChannelMask)
	end
end

function AutoDriveUserConnectedEvent.sendEvent()
	if g_server == nil then
		g_client:getServerConnection():sendEvent(AutoDriveUserConnectedEvent:new())
	end
end
