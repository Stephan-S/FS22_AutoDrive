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
    AutoDrive.devPrintDebugQueue(vehicle)
end

function AutoDrive.devAutoDriveInit()
    Logging.info("[AD] Info: g_server %s g_client %s g_dedicatedServer %s g_dedicatedServerInfo %s getUserProfileAppPath %s getIsClient %s getIsServer %s isMasterUser %s", tostring(g_server), tostring(g_client), tostring(g_dedicatedServer), tostring(g_dedicatedServerInfo), tostring(getUserProfileAppPath()), tostring(g_currentMission:getIsClient()), tostring(g_currentMission:getIsServer()), tostring(g_currentMission.isMasterUser))
end
