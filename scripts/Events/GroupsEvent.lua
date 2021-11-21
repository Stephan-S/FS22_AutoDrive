AutoDriveGroupsEvent = {}
AutoDriveGroupsEvent.TYPE_ADD = 0
AutoDriveGroupsEvent.TYPE_REMOVE = 1
AutoDriveGroupsEvent_mt = Class(AutoDriveGroupsEvent, Event)

InitEventClass(AutoDriveGroupsEvent, "AutoDriveGroupsEvent")

function AutoDriveGroupsEvent:emptyNew()
	local o = Event:new(AutoDriveGroupsEvent_mt)
	o.className = "AutoDriveGroupsEvent"
	return o
end

function AutoDriveGroupsEvent:new(groupName, eventType)
	local o = AutoDriveGroupsEvent:emptyNew()
	o.groupName = groupName
	o.eventType = eventType
	return o
end

function AutoDriveGroupsEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.eventType)
	AutoDrive.streamWriteStringOrEmpty(streamId, self.groupName)
end

function AutoDriveGroupsEvent:readStream(streamId, connection)
	self.eventType = streamReadUInt8(streamId)
	self.groupName = streamReadString(streamId)
	self:run(connection)
end

function AutoDriveGroupsEvent:run(connection)
	if g_server ~= nil and connection:getIsServer() == false then
		-- If the event is coming from a client, server have only to broadcast
		AutoDriveGroupsEvent.sendEvent(self.groupName, self.eventType)
	else
		-- If the event is coming from the server, both clients and server have to do the job
		if self.eventType == AutoDriveGroupsEvent.TYPE_ADD then
			ADGraphManager:addGroup(self.groupName, false)
		elseif self.eventType == AutoDriveGroupsEvent.TYPE_REMOVE then
			ADGraphManager:removeGroup(self.groupName, false)
		end
	end
end

function AutoDriveGroupsEvent.sendEvent(groupName, eventType)
	local event = AutoDriveGroupsEvent:new(groupName, eventType)
	if g_server ~= nil then
		-- Server have to broadcast to all clients and himself
		g_server:broadcastEvent(event, true)
	else
		-- Client have to send to server
		g_client:getServerConnection():sendEvent(event)
	end
end
