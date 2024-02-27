function AutoDrive:checkDestinations(showAll)
    local vehicle = g_currentMission.controlledVehicle
    if vehicle == nil or vehicle.ad == nil or vehicle.ad.stateModule == nil then
        Logging.error("ADCheckDestinations needs to be called only while entered an AD vehicle")
        return
    end
    local mapMarkers = ADGraphManager:getMapMarkers()
    if mapMarkers and table.count(mapMarkers) > 0 then

        for index, mapMarker in pairs(mapMarkers) do
            local wayPoints = ADGraphManager:getPathTo(vehicle, mapMarker.id)

            if wayPoints == nil or (wayPoints[2] == nil and (wayPoints[1] == nil or (wayPoints[1] ~= nil and wayPoints[1].id ~= mapMarker.id))) then
                Logging.error("[AD] Could not find a path to ->%s<- !", tostring(mapMarker.name))
            else
                if showAll then
                    Logging.info("[AD] Path found to ->%s<- ", tostring(mapMarker.name))
                end
            end
        end
    end
end
function AutoDrive.debugVehicleMsg(vehicle, msg)
    if vehicle ~= nil and vehicle.ad ~= nil and vehicle.ad.debug ~= nil then
        vehicle.ad.debug:Enqueue(msg)
    end
end

function AutoDrive.devPrintDebugQueue(vehicle)
    if vehicle == nil or vehicle.ad == nil or vehicle.ad.debug == nil then return end
    Logging.info("[AD] %s: debugPrintQueue start... count %s", tostring(vehicle:getName()), tostring(vehicle.ad.debug:Count()))

    local item = vehicle.ad.debug:Dequeue()
    local count = 0
    while item ~= nil and count < 20000 do
        Logging.info(item)
        count = count + 1
        item = vehicle.ad.debug:Dequeue()
    end
    Logging.info("[AD] %s: debugPrintQueue end...", tostring(vehicle:getName()))
end


function AutoDrive.devAction(vehicle)
    if vehicle ~= nil and vehicle.getName ~= nil then
        Logging.info("[AD] AutoDrive.devAction vehicle %s", tostring(vehicle:getName()))
    else
        Logging.info("[AD] AutoDrive.devAction vehicle %s", tostring(vehicle))
    end

    if vehicle ~= nil and g_currentMission.mapWidth and AutoDrive.getDebugChannelIsSet(AutoDrive.DC_ROADNETWORKINFO) and AutoDrive.isInExtendedEditorMode() then
        local x, y, z = getWorldTranslation(vehicle.rootNode)

        for _, wp in pairs(ADGraphManager:getWayPoints()) do
            if math.abs(wp.x) >= g_currentMission.mapWidth/2 or math.abs(wp.z) >= g_currentMission.mapHeight/2 then
                ADGraphManager:moveWayPoint(wp.id, x, y, z, wp.flags)
            end
        end
    end
    AutoDrive.devPrintDebugQueue(vehicle)
end

function AutoDrive.devAutoDriveInit()
    Logging.info("[AD] Info: g_server %s g_client %s g_dedicatedServer %s g_dedicatedServerInfo %s getUserProfileAppPath %s getIsClient %s getIsServer %s isMasterUser %s", tostring(g_server), tostring(g_client), tostring(g_dedicatedServer), tostring(g_dedicatedServerInfo), tostring(getUserProfileAppPath()), tostring(g_currentMission:getIsClient()), tostring(g_currentMission:getIsServer()), tostring(g_currentMission.isMasterUser))
	addConsoleCommand( 'ADCheckDestinations', 'Find path to all destinations', 'checkDestinations', AutoDrive )
end
