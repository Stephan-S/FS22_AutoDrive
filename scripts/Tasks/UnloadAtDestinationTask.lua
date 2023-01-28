UnloadAtDestinationTask = ADInheritsFrom(AbstractTask)

UnloadAtDestinationTask.STATE_PATHPLANNING = 1
UnloadAtDestinationTask.STATE_DRIVING = 2
UnloadAtDestinationTask.STATE_WAIT_FOR_AL_UNLOAD = 3

function UnloadAtDestinationTask:new(vehicle, destinationID)
    local o = UnloadAtDestinationTask:create()
    o.vehicle = vehicle
    o.destinationID = destinationID
    o.isContinued = false
    o.waitForALUnloadTimer = AutoDriveTON:new()
    o.waitForALUnload = false
    o.isReverseTriggerReached = false
    o.trailers = nil
    return o
end

function UnloadAtDestinationTask:setUp()
    if self.vehicle.spec_locomotive and self.vehicle.ad and self.vehicle.ad.trainModule then
        self.state = UnloadAtDestinationTask.STATE_DRIVING
        self.vehicle.ad.trainModule:setPathTo(self.destinationID)
    elseif ADGraphManager:getDistanceFromNetwork(self.vehicle) > 30 then
        self.state = UnloadAtDestinationTask.STATE_PATHPLANNING
        if self.vehicle.ad.restartCP == true then
            if self.vehicle.ad.stateModule:getMode() == AutoDrive.MODE_PICKUPANDDELIVER then
                self.vehicle.ad.pathFinderModule:startPathPlanningToWayPoint(self.vehicle.ad.stateModule:getFirstWayPoint(), self.destinationID)
            else
                self.vehicle.ad.pathFinderModule:startPathPlanningToWayPoint(self.vehicle.ad.stateModule:getSecondWayPoint(), self.destinationID)
            end
        else
            self.vehicle.ad.pathFinderModule:startPathPlanningToNetwork(self.destinationID)
        end
    else
        self.state = UnloadAtDestinationTask.STATE_DRIVING
        self.vehicle.ad.drivePathModule:setPathTo(self.destinationID)
    end
    self.trailers, _ = AutoDrive.getAllUnits(self.vehicle)
    self.vehicle.ad.trailerModule:reset()
    self.waitForALUnload = false
    self.isReverseTriggerReached = false
end

function UnloadAtDestinationTask:update(dt)
    self.vehicle.ad.specialDrivingModule.motorShouldNotBeStopped = false
    if self.state == UnloadAtDestinationTask.STATE_PATHPLANNING then
        if self.vehicle.ad.pathFinderModule:hasFinished() then
            self.wayPoints = self.vehicle.ad.pathFinderModule:getPath()
            if self.wayPoints == nil or #self.wayPoints == 0 then
                if self.vehicle.ad.pathFinderModule:isTargetBlocked() then
                    -- If the selected field exit isn't reachable, try the closest one                    
                    self.vehicle.ad.pathFinderModule:startPathPlanningToNetwork(self.vehicle.ad.stateModule:getSecondWayPoint())
                elseif self.vehicle.ad.pathFinderModule:timedOut() or self.vehicle.ad.pathFinderModule:isBlocked() then
                    -- Add some delay to give the situation some room to clear itself
                    self.vehicle.ad.modes[AutoDrive.MODE_UNLOAD]:notifyAboutFailedPathfinder()
                    self.vehicle.ad.pathFinderModule:startPathPlanningToNetwork(self.vehicle.ad.stateModule:getSecondWayPoint())
                    self.vehicle.ad.pathFinderModule:addDelayTimer(10000)
                else
                    self.vehicle.ad.pathFinderModule:startPathPlanningToNetwork(self.vehicle.ad.stateModule:getSecondWayPoint())
                end

                Logging.error("[AutoDrive] Could not calculate path - shutting down")
                self.vehicle.ad.taskModule:abortAllTasks()
                self.vehicle:stopAutoDrive()
                AutoDriveMessageEvent.sendMessageOrNotification(self.vehicle, ADMessagesManager.messageTypes.ERROR, "$l10n_AD_Driver_of; %s $l10n_AD_cannot_find_path;", 5000, self.vehicle.ad.stateModule:getName())
            else
                self.vehicle.ad.drivePathModule:setWayPoints(self.wayPoints)
                --self.vehicle.ad.drivePathModule:appendPathTo(self.wayPoints[#self.wayPoints], self.destinationID)
                self.state = UnloadAtDestinationTask.STATE_DRIVING
            end
        else
            self.vehicle.ad.pathFinderModule:update(dt)
            self.vehicle.ad.specialDrivingModule:stopVehicle()
            self.vehicle.ad.specialDrivingModule:update(dt)
        end
    elseif self.state == UnloadAtDestinationTask.STATE_DRIVING then
        if not self.isContinued then
            self.vehicle.ad.trailerModule:update(dt)
        end
        if self.vehicle.ad.drivePathModule:isTargetReached() then
            --AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtDestinationTask:update isTargetReached")
            if not self.vehicle.ad.trailerModule:isActiveAtTrigger() then
                --AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtDestinationTask:update isTargetReached isActiveAtTrigger")
                AutoDrive.setTrailerCoverOpen(self.vehicle, self.trailers, true)
                local fillLevel = AutoDrive.getAllFillLevels(self.trailers)
                if fillLevel < 0.1 or self.isContinued or (((AutoDrive.getSetting("rotateTargets", self.vehicle) == AutoDrive.RT_ONLYDELIVER or AutoDrive.getSetting("rotateTargets", self.vehicle) == AutoDrive.RT_PICKUPANDDELIVER) and AutoDrive.getSetting("useFolders")) and (not ((self.vehicle.ad.drivePathModule:getIsReversing() and self.vehicle.ad.trailerModule:getBunkerTrigger() ~= nil)))) then
                    --AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "UnloadAtDestinationTask:update fillLevel < 0.1")
                    AutoDrive.setAugerPipeOpen(self.trailers, false)
                    self:finished()
                else
                   -- AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtDestinationTask:update Wait at unload point until unloaded somehow")
                    -- Wait at unload point until unloaded somehow
                    --Keep motor running. Maybe we could check if the current trailer need Power to be unloaded or not
                    self.vehicle.ad.specialDrivingModule.motorShouldNotBeStopped = true

                    self.vehicle.ad.specialDrivingModule:stopVehicle()
                    self.vehicle.ad.specialDrivingModule:update(dt)
                    if self.vehicle.ad.trailerModule:getHasAL() == true then
                    	-- AutoLoad
                        AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtDestinationTask:update unloadALAll start")
                        if AutoDrive.getSetting("ALUnloadWaitTime", self.vehicle) > 0 and AutoDrive.getSetting("ALUnload", self.vehicle) > 0 then
                            -- wait only if unload is not disabled and wait time > 0
                            self.waitForALUnload = true
                            self.waitForALUnloadTimer:timer(false)
                            self.state = UnloadAtDestinationTask.STATE_WAIT_FOR_AL_UNLOAD
                        end
                        AutoDrive:unloadALAll(self.vehicle)
                    end
                end
            else
                --AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtDestinationTask:update isTargetReached NOT isActiveAtTrigger")
                if self.vehicle.ad.trailerModule:isUnloadingToBunkerSilo() then
                    --AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtDestinationTask:update isTargetReached NOT isActiveAtTrigger isUnloadingToBunkerSilo")
                    self.vehicle.ad.drivePathModule:update(dt)
                else
                    --AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtDestinationTask:update isTargetReached NOT isActiveAtTrigger stopVehicle")
                    self.vehicle.ad.specialDrivingModule.motorShouldNotBeStopped = true
                    self.vehicle.ad.specialDrivingModule:stopVehicle()
                    self.vehicle.ad.specialDrivingModule:update(dt)
                end
            end
        else
            if self.vehicle.ad.trailerModule:isActiveAtTrigger() then
                --AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtDestinationTask:update isActiveAtTrigger")
                if self.vehicle.ad.trailerModule:isUnloadingToBunkerSilo() then
                    --AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtDestinationTask:update isActiveAtTrigger isUnloadingToBunkerSilo")
                    self.vehicle.ad.drivePathModule:update(dt)
                else
                    --AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtDestinationTask:update isActiveAtTrigger stopVehicle")
                    self.isReverseTriggerReached = self.vehicle.ad.drivePathModule:getIsReversing()
                    self.vehicle.ad.specialDrivingModule:stopVehicle()
                    self.vehicle.ad.specialDrivingModule:update(dt)
                end
            else
                --AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtDestinationTask:update isActiveAtTrigger drivePathModule:update")
                if self.isReverseTriggerReached then
                    self:finished()
                else
                    self.vehicle.ad.drivePathModule:update(dt)
                end
            end
        end
    else -- UnloadAtDestinationTask.STATE_WAIT_FOR_AL_UNLOAD
        local waitForALUnloadTime = AutoDrive.getSetting("ALUnloadWaitTime", self.vehicle)
        if (waitForALUnloadTime >= 0 and self.waitForALUnloadTimer:timer(self.waitForALUnload, waitForALUnloadTime, dt)) or self.isContinued then
            -- used to wait for AutoLoader to unload
            self.waitForALUnloadTimer:timer(false)
            AutoDrive.setAugerPipeOpen(self.trailers, false)
            self:finished()
            self.waitForALUnload = false
        end
        if self.waitForALUnload then
            -- AutoLoad - stop driving for the wait time, let autoloaded objects disappear
            self.vehicle.ad.specialDrivingModule:stopVehicle()
            self.vehicle.ad.specialDrivingModule:update(dt)
            return
        end
    end
end

function UnloadAtDestinationTask:abort()
end

function UnloadAtDestinationTask:continue()
    self.vehicle.ad.trailerModule:stopUnloading()
    self.isContinued = true
end

function UnloadAtDestinationTask:finished()
    self.vehicle.ad.taskModule:setCurrentTaskFinished()
end

function UnloadAtDestinationTask:getI18nInfo()
    if self.state == UnloadAtDestinationTask.STATE_PATHPLANNING then
        local actualState, maxStates = self.vehicle.ad.pathFinderModule:getCurrentState()
        return "$l10n_AD_task_pathfinding;" .. string.format(" %d / %d ", actualState, maxStates)
    else
        return "$l10n_AD_task_drive_to_unload_point;"
    end
end
