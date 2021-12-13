AutoDriveUpdateSettingsEvent = {}
AutoDriveUpdateSettingsEvent_mt = Class(AutoDriveUpdateSettingsEvent, Event)

InitEventClass(AutoDriveUpdateSettingsEvent, "AutoDriveUpdateSettingsEvent")

function AutoDriveUpdateSettingsEvent.emptyNew()
	local self = Event.new(AutoDriveUpdateSettingsEvent_mt)
	return self
end

function AutoDriveUpdateSettingsEvent.new(vehicle)
	local self = AutoDriveUpdateSettingsEvent.emptyNew()
	self.vehicle = vehicle
	return self
end

function AutoDriveUpdateSettingsEvent:writeStream(streamId, connection)
	-- Writing global configs
	local count = 0
	for _, setting in pairs(AutoDrive.settings) do
		if setting ~= nil and not setting.isVehicleSpecific and not setting.isUserSpecific then
			count = count + 1
		end
	end

	streamWriteUInt16(streamId, count)

	for settingName, setting in pairs(AutoDrive.settings) do
		if setting ~= nil and not setting.isVehicleSpecific and not setting.isUserSpecific then
			streamWriteString(streamId, settingName)
			streamWriteUInt16(streamId, setting.current)
		end
	end

	streamWriteBool(streamId, self.vehicle ~= nil)	

	-- Writing vehicle configs
	if self.vehicle ~= nil then		
		count = 0
		for _, setting in pairs(AutoDrive.settings) do
			if setting ~= nil and setting.isVehicleSpecific and not setting.isUserSpecific then
				count = count + 1
			end
		end

		streamWriteInt32(streamId, NetworkUtil.getObjectId(self.vehicle))
		
		streamWriteUInt16(streamId, count)

		for settingName, setting in pairs(AutoDrive.settings) do
			if setting ~= nil and setting.isVehicleSpecific and not setting.isUserSpecific then
				streamWriteString(streamId, settingName)
				streamWriteUInt16(streamId, AutoDrive.getSettingState(settingName, self.vehicle))
			end
		end
	end

	-- Writing global userDefault values
	count = 0
	for _, setting in pairs(AutoDrive.settings) do
		if setting ~= nil and not setting.isUserSpecific and setting.isVehicleSpecific and setting.userDefault ~= nil then
			count = count + 1
		end
	end

	streamWriteUInt16(streamId, count)

	for settingName, setting in pairs(AutoDrive.settings) do
		if setting ~= nil and not setting.isUserSpecific and setting.isVehicleSpecific and setting.userDefault ~= nil then
			streamWriteString(streamId, settingName)
			streamWriteUInt16(streamId, setting.userDefault)
		end
	end
end

function AutoDriveUpdateSettingsEvent:readStream(streamId, connection)
	-- Reading global confings
	local count = streamReadUInt16(streamId)
	for i = 1, count do
		local settingName = streamReadString(streamId)
		local value = streamReadUInt16(streamId)
		AutoDrive.settings[settingName].current = value
		AutoDrive.settings[settingName].new = value
	end

	local vehicle = nil

	if streamReadBool(streamId) then
		vehicle = NetworkUtil.getObject(streamReadInt32(streamId))
		if vehicle ~= nil then
			count = streamReadUInt16(streamId)
			for i = 1, count do
				local settingName = streamReadString(streamId)
				local value = streamReadUInt16(streamId)
				vehicle.ad.settings[settingName].current = value
				vehicle.ad.settings[settingName].new = value
			end
		end
	end

	-- Reading global confings
	count = streamReadUInt16(streamId)
	for i = 1, count do
		local settingName = streamReadString(streamId)
		local value = streamReadUInt16(streamId)
		AutoDrive.settings[settingName].userDefault = value
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
