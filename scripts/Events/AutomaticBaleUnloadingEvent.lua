AutoDriveAutomaticBaleUnloadingEvent = {}
AutoDriveAutomaticBaleUnloadingEvent_mt = Class(AutoDriveAutomaticBaleUnloadingEvent, Event)

InitEventClass(AutoDriveAutomaticBaleUnloadingEvent, "AutoDriveAutomaticBaleUnloadingEvent")

function AutoDriveAutomaticBaleUnloadingEvent.emptyNew()
    local self = Event.new(AutoDriveAutomaticBaleUnloadingEvent_mt)
    return self
end

function AutoDriveAutomaticBaleUnloadingEvent.new(baleLoader)
    local self = AutoDriveAutomaticBaleUnloadingEvent.emptyNew()
	self.baleLoader = baleLoader
    return self
end

function AutoDriveAutomaticBaleUnloadingEvent:writeStream(streamId)
    NetworkUtil.writeNodeObject(streamId, self.baleLoader)
end

function AutoDriveAutomaticBaleUnloadingEvent:readStream(streamId, connection)
	self.baleLoader = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end

function AutoDriveAutomaticBaleUnloadingEvent:run(connection)
	self.baleLoader:startAutomaticBaleUnloading()
	if not connection:getIsServer() then 
		local event = AutoDriveAutomaticBaleUnloadingEvent.new(self.baleLoader)
		g_server:broadcastEvent(event, nil, connection, self.baleLoader)
	end
end

function AutoDriveAutomaticBaleUnloadingEvent.sendEvent(baleLoader)
    local event = AutoDriveAutomaticBaleUnloadingEvent.new(baleLoader)
    if g_server ~= nil then
        g_server:broadcastEvent(event, nil, nil, baleLoader)
    else
        g_client:getServerConnection():sendEvent(event)
    end
	baleLoader:startAutomaticBaleUnloading()
end
