CreateSplineConnectionEvent = {}
CreateSplineConnectionEvent_mt = Class(CreateSplineConnectionEvent, Event)

InitEventClass(CreateSplineConnectionEvent, "CreateSplineConnectionEvent")

function CreateSplineConnectionEvent.emptyNew()
	local self = Event.new(CreateSplineConnectionEvent_mt)
	return self
end

function CreateSplineConnectionEvent.new(start, waypoints, target)
	local self = CreateSplineConnectionEvent.emptyNew()
	self.start = start
	self.waypoints = waypoints
	self.target = target
	return self
end

function CreateSplineConnectionEvent:writeStream(streamId, connection)	
    local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
    local paramsY = g_currentMission.vehicleYPosCompressionParams

	streamWriteInt32(streamId, self.start)

	streamWriteInt32(streamId, #self.waypoints)
	for _, wp in pairs(self.waypoints) do
        NetworkUtil.writeCompressedWorldPosition(streamId, wp.x, paramsXZ)
        NetworkUtil.writeCompressedWorldPosition(streamId, wp.y, paramsY)
        NetworkUtil.writeCompressedWorldPosition(streamId, wp.z, paramsXZ)
	end

	streamWriteInt32(streamId, self.target)
end

function CreateSplineConnectionEvent:readStream(streamId, connection)
    local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
    local paramsY = g_currentMission.vehicleYPosCompressionParams
	self.start = streamReadInt32(streamId)

	self.waypoints = {}
	local wpCount = streamReadInt32(streamId)
	for i=1, wpCount do
		local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
		local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		table.insert(self.waypoints, {x=x, y=y,z=z})
	end	

	self.target = streamReadInt32(streamId)
	self:run(connection)
end

function CreateSplineConnectionEvent:run(connection)
	if g_server ~= nil and connection:getIsServer() == false then
		-- If the event is coming from a client, server have only to broadcast
		CreateSplineConnectionEvent.sendEvent(self.start, self.waypoints, self.target)
	else
		-- If the event is coming from the server, both clients and server have to create the way point
		ADGraphManager:createSplineConnection(self.start, self.waypoints, self.target, false)
	end
end

function CreateSplineConnectionEvent.sendEvent(start, waypoints, target)
	local event = CreateSplineConnectionEvent.new(start, waypoints, target)
	if g_server ~= nil then
		-- Server have to broadcast to all clients and himself
		g_server:broadcastEvent(event, true)
	else
		-- Client have to send to server
		g_client:getServerConnection():sendEvent(event)
	end
end
