AutoDriveRoutesUploadEvent = {}
AutoDriveRoutesUploadEvent_mt = Class(AutoDriveRoutesUploadEvent, Event)

InitEventClass(AutoDriveRoutesUploadEvent, "AutoDriveRoutesUploadEvent")

function AutoDriveRoutesUploadEvent.emptyNew()
	print("AutoDriveRoutesUploadEvent:emptyNew")
	local self = Event.new(AutoDriveRoutesUploadEvent_mt)
	return self
end

function AutoDriveRoutesUploadEvent.new(wayPoints, mapMarkers, groups)
	local self = AutoDriveRoutesUploadEvent.emptyNew()
	self.wayPoints = wayPoints
	self.mapMarkers = mapMarkers
	self.groups = groups
	return self
end

function AutoDriveRoutesUploadEvent:writeStream(streamId, connection)
	AutoDriveSync.streamWriteGraph(streamId, self.wayPoints, self.mapMarkers, self.groups)
end

function AutoDriveRoutesUploadEvent:readStream(streamId, connection)
	self.wayPoints, self.mapMarkers, self.groups = AutoDriveSync.streamReadGraph(streamId)
	self:run(connection)
end

function AutoDriveRoutesUploadEvent:run(connection)
	if g_server ~= nil and connection:getIsServer() == false then
		-- If the event is coming from a client, server have only to broadcast
		AutoDriveRoutesUploadEvent.sendEvent(self.wayPoints, self.mapMarkers, self.groups)
	else
		-- If the event is coming from the server, both clients and server have to delete the way point
		ADGraphManager:setWayPoints(self.wayPoints)
		ADGraphManager:setMapMarkers(self.mapMarkers)
		AutoDrive:notifyDestinationListeners()
		ADGraphManager:setGroups(self.groups, true)

		if g_server ~= nil then
			for _, vehicle in pairs(g_currentMission.vehicles) do
				if vehicle ~= nil and vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil then
					vehicle.ad.stateModule:resetMarkersOnReload()
				end
			end
		end

		AutoDrive.Hud.lastUIScale = 0
	end
end

function AutoDriveRoutesUploadEvent.sendEvent(wayPoints, mapMarkers, groups)
	local event = AutoDriveRoutesUploadEvent.new(wayPoints, mapMarkers, groups)
	if g_server ~= nil then
		-- Server have to broadcast to all clients and himself
		g_server:broadcastEvent(event, true)
	else
		-- Client have to send to server
		g_client:getServerConnection():sendEvent(event)
	end
end
