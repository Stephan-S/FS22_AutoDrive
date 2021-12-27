ADInputManager = {}

-- same order as in modDesc.xml
ADInputManager.actionsToInputs = {
    {"ADSilomode", "input_silomode", true},
    {"ADPreviousMode", "input_previousMode", true},
    {"ADRecord", "input_record", false},
    {"ADRecord_Dual", "input_record_dual", false},
    {"ADRecord_SubPrio", "input_record_subPrio", false},
    {"ADRecord_SubPrioDual", "input_record_subPrioDual", false},
    {"ADEnDisable", "input_start_stop", true},
    {"ADSelectTarget", "input_nextTarget", true},
    {"ADSelectPreviousTarget", "input_previousTarget", true},
    {"ADSelectTargetUnload", "input_nextTarget_Unload", true},
    {"ADSelectPreviousTargetUnload", "input_previousTarget_Unload", true},
    {"ADActivateDebug", "input_debug", false},
    {"ADDisplayMapPoints", "input_displayMapPoints", false},
    {"ADDebugSelectNeighbor", "input_showNeighbor", false},
    {"ADDebugCreateConnection", "input_toggleConnection", false},
    {"ADDebugToggleConnectionInverted", "input_toggleConnectionInverted", false},
    {"ADDebugChangeNeighbor", "input_nextNeighbor", false},
    {"ADDebugPreviousNeighbor", "input_previousNeighbor", false},
    {"ADDebugCreateMapMarker", "input_createMapMarker", false},
    {"ADRenameMapMarker", "input_editMapMarker", false},
    {"ADDebugDeleteDestination", "input_removeMapMarker", false},
    {"ADNameDriver", "input_nameDriver", true},
    {"ADSetDestinationFilter", "input_setDestinationFilter", true},
    {"AD_Speed_up", "input_increaseSpeed", true},
    {"AD_Speed_down", "input_decreaseSpeed", true},
    {"AD_FieldSpeed_up", "input_increaseFieldSpeed", true},
    {"AD_FieldSpeed_down", "input_decreaseFieldSpeed", true},
    {"ADToggleHud", "input_toggleHud", false},
    {"ADToggleMouse", "input_toggleMouse", true},
    {"COURSEPLAY_MOUSEACTION_SECONDARY", "input_toggleMouse", false},
    {"ADDebugDeleteWayPoint", "input_removeWaypoint", false},
    {"AD_routes_manager", "input_routesManager", false},
    {"ADSelectNextFillType", "input_nextFillType", true},
    {"ADSelectPreviousFillType", "input_previousFillType", true},
    {"ADOpenGUI", "input_openGUI", true},
    {"ADCallDriver", "input_callDriver", false},
    {"ADGoToVehicle", "input_goToVehicle", false},
    {"ADIncLoopCounter", "input_incLoopCounter", true},
    {"ADDecLoopCounter", "input_decLoopCounter", true},
    {"ADSwapTargets", "input_swapTargets", true},
    {"ADStartCP", "input_startCp", true},
    {"ADToggleCP_AIVE", "input_toggleCP_AIVE", true},
    {"AD_open_notification_history", "input_openNotificationHistory", false},
    -- {"AD_open_colorSettings", "input_openColorSettings", false},
    {"AD_continue", "input_continue", true},
    {"ADParkVehicle", "input_parkVehicle", true},
    {"ADSetParkDestination", "input_setParkDestination", false},
    {"AD_devAction", "input_devAction", false},
    {"ADRefuelVehicle", "input_refuelVehicle", false},
    {"ADToggleHudExtension", "input_toggleHudExtension", true},
    {"ADToggleAutomaticUnloadTarget", "input_toggleAutomaticUnloadTarget", true},
    {"ADToggleAutomaticPickupTarget", "input_toggleAutomaticPickupTarget", true},
    {"ADRepairVehicle", "input_repairVehicle", false}
}

--[[
tool selection not proper on dedi servers as known!
That's why the following event is only taken on clients and send as event in the network
input_setParkDestination
]]
-- inputs to send to server
ADInputManager.inputsToIds = {}
ADInputManager.idsToInputs = {}

function ADInputManager:load()
    for k, v in pairs(self.actionsToInputs) do
        self.inputsToIds[self.actionsToInputs[k][2]] = k
    end
    for k, v in pairs(self.inputsToIds) do
        self.idsToInputs[v] = k
    end
end

function ADInputManager.onActionCall(vehicle, actionName)
    local controlledVehicle = g_currentMission.controlledVehicle

    for k, v in pairs(ADInputManager.actionsToInputs) do
        local action = ADInputManager.actionsToInputs[k][1]
        local allowed = ADInputManager.actionsToInputs[k][3] or (controlledVehicle ~= nil and controlledVehicle == vehicle)

        if action == actionName and allowed then
            local input = ADInputManager.actionsToInputs[k][2]
            if type(input) ~= "string" or input == "" then
                Logging.devError("[AutoDrive] Action '%s' = '%s'", actionName, input)
                return
            end
            ADInputManager:onInputCall(vehicle, input)
            break
        end
    end
end

function ADInputManager:onInputCall(vehicle, input, sendEvent)
    local controlledVehicle = g_currentMission.controlledVehicle
    for k, v in pairs(ADInputManager.actionsToInputs) do
        local allowed = ADInputManager.actionsToInputs[k][3] or (controlledVehicle ~= nil and controlledVehicle == vehicle)
        if input == ADInputManager.actionsToInputs[k][2] and allowed then
            local func = self[input]
            if type(func) ~= "function" then
                Logging.devError("[AutoDrive] Input '%s' = '%s'", input, type(func))
                return
            end

            if sendEvent == nil or sendEvent == true then
                local inputId = self.inputsToIds[input]
                if inputId ~= nil then
                    AutoDriveInputEventEvent.sendEvent(vehicle, inputId)
                    return
                end
            end

            func(ADInputManager, vehicle)
            break
        end
    end


end

-- Sender only events

function ADInputManager:input_openNotificationHistory(vehicle)
    AutoDrive.onOpenNotificationsHistory()
end

function ADInputManager:input_openColorSettings()
    AutoDrive.onOpenColorSettings()
end

function ADInputManager:input_editMapMarker(vehicle)
    if AutoDrive.isEditorModeEnabled() then
        -- This can be triggered both from 'Edit Target' keyboard shortcut and right click on 'Create Target' hud button
        if ADGraphManager:getWayPointById(1) == nil or vehicle.ad.stateModule:getFirstMarker() == nil then
            return
        end
        AutoDrive.editSelectedMapMarker = true
        AutoDrive.onOpenEnterTargetName()
    end
end

function ADInputManager:input_removeWaypoint(vehicle)
    if AutoDrive.isEditorModeEnabled() then
        local closestWayPoint, _ = vehicle:getClosestWayPoint()
        if ADGraphManager:getWayPointById(closestWayPoint) ~= nil then
            -- This can be triggered both from 'Remove Waypoint' keyboard shortcut and left click on 'Remove Waypoint' hud button
            ADGraphManager:removeWayPoint(closestWayPoint)
        end
    end
end

function ADInputManager:input_removeMapMarker(vehicle)
    if AutoDrive.isEditorModeEnabled() then
        local closestWayPoint, _ = vehicle:getClosestWayPoint()
        if ADGraphManager:getWayPointById(closestWayPoint) ~= nil then
            -- This can be triggered both from 'Remove Target' keyboard shortcut and right click on 'Remove Waypoint' hud button
            ADGraphManager:removeMapMarkerByWayPoint(closestWayPoint)
        end
    end
end

function ADInputManager:input_createMapMarker(vehicle)
    if AutoDrive.isEditorModeEnabled() then
        local closestWayPoint, _ = vehicle:getClosestWayPoint()
        if ADGraphManager:getWayPointById(closestWayPoint) ~= nil then
            -- This can be triggered both from 'Create Target' keyboard shortcut and left click on 'Create Target' hud button
            AutoDrive.editSelectedMapMarker = false
            AutoDrive.onOpenEnterTargetName()
        end
    end
end

function ADInputManager:input_toggleConnection(vehicle)
    if AutoDrive.isEditorModeEnabled() then
        local closestWayPoint, _ = vehicle:getClosestWayPoint()
        if ADGraphManager:getWayPointById(closestWayPoint) ~= nil then
            if vehicle.ad.stateModule:getSelectedNeighbourPoint() ~= nil then
                ADGraphManager:toggleConnectionBetween(ADGraphManager:getWayPointById(closestWayPoint), vehicle.ad.stateModule:getSelectedNeighbourPoint(), false)
            end
        end
    end
end

function ADInputManager:input_toggleConnectionInverted(vehicle)
    if AutoDrive.isEditorModeEnabled() then
        local closestWayPoint, _ = vehicle:getClosestWayPoint()
        if ADGraphManager:getWayPointById(closestWayPoint) ~= nil then
            if vehicle.ad.stateModule:getSelectedNeighbourPoint() ~= nil then
                ADGraphManager:toggleConnectionBetween(vehicle.ad.stateModule:getSelectedNeighbourPoint(), ADGraphManager:getWayPointById(closestWayPoint), false)
            end
        end
    end
end

function ADInputManager:input_nameDriver()
    AutoDrive.onOpenEnterDriverName()
end

function ADInputManager:input_setDestinationFilter()
    AutoDrive.onOpenEnterDestinationFilter()
end

function ADInputManager:input_openGUI()
    AutoDrive.onOpenSettings()
end

function ADInputManager:input_toggleHud(vehicle)
    AutoDrive.Hud:toggleHud(vehicle)
end

function ADInputManager:input_toggleHudExtension(vehicle)
    AutoDrive.Hud:toggleHudExtension(vehicle)
end

function ADInputManager:input_toggleMouse()
    g_inputBinding:setShowMouseCursor(not g_inputBinding:getShowMouseCursor())
end

function ADInputManager:input_routesManager()
    if (AutoDrive.experimentalFeatures.enableRoutesManagerOnDediServer == true and g_dedicatedServer ~= nil) or g_dedicatedServer == nil then
        AutoDrive.onOpenRoutesManager()
    end
end

function ADInputManager:input_goToVehicle()
    ADMessagesManager:goToVehicle()
end

function ADInputManager:input_showNeighbor(vehicle)
    vehicle.ad.stateModule:togglePointToNeighbor()
end

function ADInputManager:input_nextNeighbor(vehicle)
    vehicle.ad.stateModule:changeNeighborPoint(1)
end

function ADInputManager:input_previousNeighbor(vehicle)
    vehicle.ad.stateModule:changeNeighborPoint(-1)
end

-- Sender and server events

function ADInputManager:input_start_stop(vehicle)
    if ADGraphManager:getWayPointById(1) == nil or vehicle.ad.stateModule:getFirstMarker() == nil then
        return
    end
    if vehicle.ad.stateModule:isActive() then
        vehicle.ad.isStoppingWithError = true
        vehicle:stopAutoDrive()
    else
        vehicle.ad.stateModule:getCurrentMode():start()

        if AutoDrive.rightSHIFTmodifierKeyPressed then
            for _, otherVehicle in pairs(g_currentMission.vehicles) do
                if otherVehicle ~= nil and otherVehicle ~= vehicle and otherVehicle.ad ~= nil and otherVehicle.ad.stateModule ~= nil then
                    --Doesn't work yet, if vehicle hasn't been entered before apparently. So we need to check what to call before, to setup all required variables.
                    
                    if otherVehicle.ad.stateModule.activeBeforeSave then
                        -- g_currentMission:requestToEnterVehicle(otherVehicle)
                        otherVehicle.ad.stateModule:getCurrentMode():start()
                    end
                    if otherVehicle.ad.stateModule.AIVEActiveBeforeSave and otherVehicle.acParameters ~= nil then
                        -- g_currentMission:requestToEnterVehicle(otherVehicle)
                        otherVehicle.acParameters.enabled = true
                        otherVehicle:toggleAIVehicle()
                    end                    
				end
			end
            -- g_currentMission:requestToEnterVehicle(vehicle)
        end
    end

    --AutoDrive.dumpTable(ADTriggerManager.tipTriggers, "ADTriggerManager.tipTriggers", 4)
end

function ADInputManager:input_incLoopCounter(vehicle)
    vehicle.ad.stateModule:increaseLoopCounter()
end

function ADInputManager:input_decLoopCounter(vehicle)
    vehicle.ad.stateModule:decreaseLoopCounter()
end

function ADInputManager:input_setParkDestination(vehicle)
    AutoDrive.setActualParkDestination(vehicle)
end

function ADInputManager:input_silomode(vehicle)
    vehicle.ad.stateModule:nextMode()
end

function ADInputManager:input_previousMode(vehicle)
    vehicle.ad.stateModule:previousMode()
end

function ADInputManager:input_record(vehicle)
    if not vehicle.ad.stateModule:isInCreationMode() and not vehicle.ad.stateModule:isInDualCreationMode() and not vehicle.ad.stateModule:isInSubPrioCreationMode() and not vehicle.ad.stateModule:isInSubPrioDualCreationMode() then
        vehicle.ad.stateModule:startNormalCreationMode()
    else
        vehicle.ad.stateModule:disableCreationMode()
    end
end

function ADInputManager:input_record_dual(vehicle)
    if not vehicle.ad.stateModule:isInCreationMode() and not vehicle.ad.stateModule:isInDualCreationMode() and not vehicle.ad.stateModule:isInSubPrioCreationMode() and not vehicle.ad.stateModule:isInSubPrioDualCreationMode() then
        vehicle.ad.stateModule:startDualCreationMode()
    else
        vehicle.ad.stateModule:disableCreationMode()
    end
end

function ADInputManager:input_record_subPrio(vehicle)
    if not vehicle.ad.stateModule:isInCreationMode() and not vehicle.ad.stateModule:isInDualCreationMode() and not vehicle.ad.stateModule:isInSubPrioCreationMode() and not vehicle.ad.stateModule:isInSubPrioDualCreationMode() then
        vehicle.ad.stateModule:startSubPrioCreationMode()
    else
        vehicle.ad.stateModule:disableCreationMode()
    end
end

function ADInputManager:input_record_subPrioDual(vehicle)
    if not vehicle.ad.stateModule:isInCreationMode() and not vehicle.ad.stateModule:isInDualCreationMode() and not vehicle.ad.stateModule:isInSubPrioCreationMode() and not vehicle.ad.stateModule:isInSubPrioDualCreationMode() then
        vehicle.ad.stateModule:startSubPrioDualCreationMode()
    else
        vehicle.ad.stateModule:disableCreationMode()
    end
end

function ADInputManager:input_debug(vehicle)
    AutoDrive.cycleEditMode()
end

function ADInputManager:input_displayMapPoints(vehicle)
    AutoDrive.cycleEditorShowMode()
end

function ADInputManager:input_increaseSpeed(vehicle)
    vehicle.ad.stateModule:increaseSpeedLimit()
end

function ADInputManager:input_decreaseSpeed(vehicle)
    vehicle.ad.stateModule:decreaseSpeedLimit()
end

function ADInputManager:input_increaseFieldSpeed(vehicle)
    vehicle.ad.stateModule:increaseFieldSpeedLimit()
end

function ADInputManager:input_decreaseFieldSpeed(vehicle)
    vehicle.ad.stateModule:decreaseFieldSpeedLimit()
end

function ADInputManager:input_nextTarget(vehicle)
    if ADGraphManager:getMapMarkerById(1) ~= nil and ADGraphManager:getWayPointById(1) ~= nil then
        local currentTarget = vehicle.ad.stateModule:getFirstMarkerId()
        if currentTarget < #ADGraphManager:getMapMarkers() then
            currentTarget = currentTarget + 1
        else
            currentTarget = 1
        end
        vehicle.ad.stateModule:setFirstMarker(currentTarget)
        vehicle.ad.stateModule:removeCPCallback()
    end
end

function ADInputManager:input_previousTarget(vehicle)
    if ADGraphManager:getMapMarkerById(1) ~= nil and ADGraphManager:getWayPointById(1) ~= nil then
        local currentTarget = vehicle.ad.stateModule:getFirstMarkerId()
        if currentTarget > 1 then
            currentTarget = currentTarget - 1
        else
            currentTarget = #ADGraphManager:getMapMarkers()
        end
        vehicle.ad.stateModule:setFirstMarker(currentTarget)
        vehicle.ad.stateModule:removeCPCallback()
    end
end

function ADInputManager:input_nextTarget_Unload(vehicle)
    if ADGraphManager:getMapMarkerById(1) ~= nil and ADGraphManager:getWayPointById(1) ~= nil then
        local currentTarget = vehicle.ad.stateModule:getSecondMarkerId()
        if currentTarget < #ADGraphManager:getMapMarkers() then
            currentTarget = currentTarget + 1
        else
            currentTarget = 1
        end
        vehicle.ad.stateModule:setSecondMarker(currentTarget)
    end
end

function ADInputManager:input_previousTarget_Unload(vehicle)
    if ADGraphManager:getMapMarkerById(1) ~= nil and ADGraphManager:getWayPointById(1) ~= nil then
        local currentTarget = vehicle.ad.stateModule:getSecondMarkerId()
        if currentTarget > 1 then
            currentTarget = currentTarget - 1
        else
            currentTarget = #ADGraphManager:getMapMarkers()
        end
        vehicle.ad.stateModule:setSecondMarker(currentTarget)
    end
end

function ADInputManager:input_nextFillType(vehicle)
    vehicle.ad.stateModule:nextFillType()
end

function ADInputManager:input_previousFillType(vehicle)
    vehicle.ad.stateModule:previousFillType()
end

function ADInputManager:input_continue(vehicle)
    vehicle.ad.stateModule:getCurrentMode():continue()
end

function ADInputManager:input_callDriver(vehicle)
    if vehicle.spec_pipe ~= nil and vehicle.spec_enterable ~= nil then
        ADHarvestManager:assignUnloaderToHarvester(vehicle)
    elseif vehicle.ad.isCombine and vehicle.ad.attachableCombine ~= nil then
        ADHarvestManager:assignUnloaderToHarvester(vehicle.ad.attachableCombine)
    end
end

function ADInputManager:input_parkVehicle(vehicle)
    local actualParkDestination = vehicle.ad.stateModule:getParkDestinationAtJobFinished()
    if actualParkDestination >= 1 then
        vehicle.ad.stateModule:setFirstMarker(actualParkDestination)
        vehicle.ad.stateModule:removeCPCallback()
        if vehicle.ad.stateModule:isActive() then
            self:input_start_stop(vehicle) --disable if already active
        end
        vehicle.ad.stateModule:setMode(AutoDrive.MODE_DRIVETO)
        self:input_start_stop(vehicle)
        vehicle.ad.onRouteToPark = true
    else
        vehicle.ad.onRouteToPark = false
        AutoDriveMessageEvent.sendMessage(vehicle, ADMessagesManager.messageTypes.ERROR, "$l10n_AD_parkVehicle_noPosSet;", 5000)
    end
end

function ADInputManager:input_swapTargets(vehicle)
    local currentFirstMarker = vehicle.ad.stateModule:getFirstMarkerId()
    vehicle.ad.stateModule:setFirstMarker(vehicle.ad.stateModule:getSecondMarkerId())
    vehicle.ad.stateModule:setSecondMarker(currentFirstMarker)
    vehicle.ad.stateModule:removeCPCallback()
end

function ADInputManager:input_startCp(vehicle) -- enable / disable CP or AIVE
    if g_courseplay ~= nil or vehicle.acParameters ~= nil then
        vehicle.ad.stateModule:toggleStartCP_AIVE()
    end
end

function ADInputManager:input_toggleCP_AIVE(vehicle) -- select CP or AIVE
    if g_courseplay ~= nil and vehicle.acParameters ~= nil then
        vehicle.ad.stateModule:toggleUseCP_AIVE()
        vehicle.ad.stateModule:setStartCP_AIVE(false) -- disable if changed between CP and AIVE
    end
end

function ADInputManager:input_toggleAutomaticUnloadTarget(vehicle)
    vehicle.ad.stateModule:toggleAutomaticUnloadTarget()
end

function ADInputManager:input_toggleAutomaticPickupTarget(vehicle)
    vehicle.ad.stateModule:toggleAutomaticPickupTarget()
end

function ADInputManager:input_devAction(vehicle)
    if AutoDrive.devAction ~= nil then
        AutoDrive.devAction(vehicle)
    end
end

function ADInputManager:input_bunkerUnloadType(vehicle)    
    vehicle.ad.stateModule:nextBunkerUnloadType()
end

function ADInputManager:input_refuelVehicle(vehicle)
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_VEHICLEINFO, "ADInputManager:input_refuelVehicle ")
    local refuelDestination = ADTriggerManager.getClosestRefuelDestination(vehicle, true)
    if refuelDestination ~= nil and refuelDestination >= 1 then
        -- vehicle.ad.stateModule:setFirstMarker(refuelDestination)
        vehicle.ad.stateModule:removeCPCallback()
        if vehicle.ad.stateModule:isActive() then
            self:input_start_stop(vehicle) --disable if already active
        end
        vehicle.ad.stateModule:setMode(AutoDrive.MODE_DRIVETO)
        vehicle.ad.onRouteToRefuel = true
        self:input_start_stop(vehicle)
    else
        local refuelFillTypes = AutoDrive.getRequiredRefuels(vehicle, true)
        local refuelFillTypeTitle = ""
        if #refuelFillTypes > 0 then
            refuelFillTypeTitle = g_fillTypeManager:getFillTypeByIndex(refuelFillTypes[1]).title
        end
        AutoDriveMessageEvent.sendMessageOrNotification(vehicle, ADMessagesManager.messageTypes.ERROR, "$l10n_AD_Driver_of; %s $l10n_AD_No_Refuel_Station; %s", 5000, vehicle.ad.stateModule:getName(), refuelFillTypeTitle)
    end
end

function ADInputManager:input_repairVehicle(vehicle)
    AutoDrive.debugPrint(vehicle, AutoDrive.DC_VEHICLEINFO, "ADInputManager:input_repairVehicle ")
    local repairDestinationMarkerNodeID = AutoDrive:getClosestRepairTrigger(vehicle)
    if repairDestinationMarkerNodeID ~= nil then
        if vehicle.ad.stateModule:isActive() then
            self:input_start_stop(vehicle) --disable if already active
        end
        vehicle.ad.onRouteToRepair = true
        vehicle.ad.stateModule:setMode(AutoDrive.MODE_DRIVETO)
        self:input_start_stop(vehicle)
    else
        AutoDriveMessageEvent.sendMessageOrNotification(vehicle, ADMessagesManager.messageTypes.ERROR, "$l10n_AD_Driver_of; %s $l10n_AD_No_Repair_Station;", 5000, vehicle.ad.stateModule:getName())
    end
end
