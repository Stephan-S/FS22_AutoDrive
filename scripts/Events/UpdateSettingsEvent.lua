AutoDriveUpdateSettingsEvent = {}
AutoDriveUpdateSettingsEvent_mt = Class(AutoDriveUpdateSettingsEvent, Event)

InitEventClass(AutoDriveUpdateSettingsEvent, "AutoDriveUpdateSettingsEvent")

function AutoDriveUpdateSettingsEvent.emptyNew()
	print("AutoDriveUpdateSettingsEvent:emptyNew")
	local self = Event.new(AutoDriveUpdateSettingsEvent_mt)
	return self
end

function AutoDriveUpdateSettingsEvent.new(vehicle)
	local self = AutoDriveUpdateSettingsEvent.emptyNew()
	self.vehicle = vehicle
	return self
end

function AutoDriveUpdateSettingsEvent:writeStream(streamId, connection)
	-- Writing global confings
	for _, setting in pairs(AutoDrive.settings) do
		if setting ~= nil and not setting.isVehicleSpecific and not setting.isUserSpecific then
			streamWriteUInt16(streamId, setting.current)
		end
	end

	streamWriteBool(streamId, self.vehicle ~= nil)

	-- Writing vehicle confings
	if self.vehicle ~= nil then
		streamWriteInt32(streamId, NetworkUtil.getObjectId(self.vehicle))
		for settingName, setting in pairs(AutoDrive.settings) do
			if setting ~= nil and setting.isVehicleSpecific and not setting.isUserSpecific then
				streamWriteUInt16(streamId, AutoDrive.getSettingState(settingName, self.vehicle))
			end
		end
	end
end

function AutoDriveUpdateSettingsEvent:readStream(streamId, connection)
	-- Reading global confings
	for _, setting in pairs(AutoDrive.settings) do
		if setting ~= nil and not setting.isVehicleSpecific and not setting.isUserSpecific then
			setting.current = streamReadUInt16(streamId)
		end
	end

	local vehicle = nil

	if streamReadBool(streamId) then
		vehicle = NetworkUtil.getObject(streamReadInt32(streamId))
		if vehicle ~= nil then
			-- Reading vehicle confings
			for settingName, setting in pairs(AutoDrive.settings) do
				if setting ~= nil and setting.isVehicleSpecific and not setting.isUserSpecific then
					local newSettingsValue = streamReadUInt16(streamId)
					vehicle.ad.settings[settingName].current = newSettingsValue
					vehicle.ad.settings[settingName].new = newSettingsValue -- Also update 'new' field to prevent a following incoerence state of 'hasChanges()' function on settings pages
				end
			end
		end
	end

	AutoDrive.gui.ADSettings:forceLoadGUISettings()

	-- Server have to broadcast to all clients
	if g_server ~= nil then
		AutoDriveUpdateSettingsEvent.sendEvent(vehicle)
	end
end

function AutoDriveUpdateSettingsEvent.sendEvent(vehicle)
	local event = AutoDriveUpdateSettingsEvent.new(vehicle)
	if g_server ~= nil then
		-- Server have to broadcast to all clients
		g_server:broadcastEvent(event)
	else
		-- Client have to send to server
		g_client:getServerConnection():sendEvent(event)
	end
	AutoDrive.gui.ADSettings:forceLoadGUISettings()
end
