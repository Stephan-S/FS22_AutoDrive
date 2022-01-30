LoadAtDestinationTask = ADInheritsFrom(AbstractTask)

LoadAtDestinationTask.STATE_PATHPLANNING = 1
LoadAtDestinationTask.STATE_DRIVING = 2

LoadAtDestinationTask.LOAD_RETRY_TIME = 3000

function LoadAtDestinationTask:new(vehicle, destinationID)
    local o = LoadAtDestinationTask:create()
    o.vehicle = vehicle
    o.destinationID = destinationID
    o.trailers = nil
    return o
end

function LoadAtDestinationTask:setUp()
    if ADGraphManager:getDistanceFromNetwork(self.vehicle) > 30 then
        self.state = LoadAtDestinationTask.STATE_PATHPLANNING
        --if self.vehicle.ad.restartCP == true then
            --if self.vehicle.ad.stateModule:getMode() == AutoDrive.MODE_LOAD then
                --self.vehicle.ad.pathFinderModule:startPathPlanningToWayPoint(self.vehicle.ad.stateModule:getFirstWayPoint(), self.destinationID)
            --else
                --self.vehicle.ad.pathFinderModule:startPathPlanningToWayPoint(self.vehicle.ad.stateModule:getSecondWayPoint(), self.destinationID)
            --end
        --else
            self.vehicle.ad.pathFinderModule:startPathPlanningToNetwork(self.destinationID)
        --end
    else
        self.state = LoadAtDestinationTask.STATE_DRIVING
        self.vehicle.ad.drivePathModule:setPathTo(self.destinationID)
    end
    if self.loadRetryTimer == nil then
        self.loadRetryTimer = AutoDriveTON:new()
    else
        self.loadRetryTimer:timer(false)      -- clear timer
    end
    self.trailers, _ = AutoDrive.getAllUnits(self.vehicle)
    self.vehicle.ad.trailerModule:reset()
    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "LoadAtDestinationTask:setUp end self.state %s", tostring(self.state))
end

function LoadAtDestinationTask:update(dt)
    if self.state == LoadAtDestinationTask.STATE_PATHPLANNING then
        if self.vehicle.ad.pathFinderModule:hasFinished() then
            self.wayPoints = self.vehicle.ad.pathFinderModule:getPath()
            if self.wayPoints == nil or #self.wayPoints == 0 then
                Logging.error("[AutoDrive] Could not calculate path - shutting down")
                self.vehicle.ad.taskModule:abortAllTasks()
                self.vehicle:stopAutoDrive()
                AutoDriveMessageEvent.sendMessageOrNotification(self.vehicle, ADMessagesManager.messageTypes.ERROR, "$l10n_AD_Driver_of; %s $l10n_AD_cannot_find_path;", 5000, self.vehicle.ad.stateModule:getName())
            else
                self.vehicle.ad.drivePathModule:setWayPoints(self.wayPoints)
                --self.vehicle.ad.drivePathModule:appendPathTo(self.wayPoints[#self.wayPoints], self.destinationID)
                self.state = LoadAtDestinationTask.STATE_DRIVING
            end
        else
            self.vehicle.ad.pathFinderModule:update(dt)
            self.vehicle.ad.specialDrivingModule:stopVehicle()
            self.vehicle.ad.specialDrivingModule:update(dt)
        end
    else
        -- STATE_DRIVING
        AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "LoadAtDestinationTask:update self.state %s", tostring(self.state))
        if self.vehicle.ad.drivePathModule:isTargetReached() then
            --Check if we have actually loaded / tried to load
            AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "LoadAtDestinationTask:update isTargetReached")
            AutoDrive.setTrailerCoverOpen(self.vehicle, self.trailers, true)

            if (self.vehicle.ad.restartCP == true or (self.vehicle.ad.stateModule:getStartCP_AIVE())) and self.vehicle.ad.stateModule:getMode() == AutoDrive.MODE_PICKUPANDDELIVER then
                AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "LoadAtDestinationTask:update stopAutoDrive")
                -- pass over to CP
                self.vehicle:stopAutoDrive()
            else
                self.vehicle.ad.specialDrivingModule:stopVehicle()
                self.vehicle.ad.specialDrivingModule:update(dt)

                if self.vehicle.ad.trailerModule:wasAtSuitableTrigger() or ((AutoDrive.getSetting("rotateTargets", self.vehicle) == AutoDrive.RT_ONLYPICKUP or AutoDrive.getSetting("rotateTargets", self.vehicle) == AutoDrive.RT_PICKUPANDDELIVER) and AutoDrive.getSetting("useFolders")) then
                    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "LoadAtDestinationTask:update wasAtSuitableTrigger -> self:finished")
                    self:finished()
                else
                    if self.vehicle.ad.trailerModule:isActiveAtTrigger() then
                        -- update to catch if no longer active at trigger
                        self.vehicle.ad.trailerModule:update(dt)
                    else
                        -- try to load somehow while standing at destination
                        AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "LoadAtDestinationTask:update not isActiveAtTrigger")
                        self.loadRetryTimer:timer(true, LoadAtDestinationTask.LOAD_RETRY_TIME, dt)
                        if self.loadRetryTimer:done() then
                            -- performance: avoid to initiate loading while standing at destination to often
                            self.loadRetryTimer:timer(false)      -- clear timer
                            AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "LoadAtDestinationTask:update try loading somehow")
                            self.vehicle.ad.trailerModule:update(dt)

                            if not self.vehicle.ad.trailerModule:isActiveAtTrigger() then
                                -- check fill levels only if not still filling something
                                local _, _, isFull = AutoDrive.getAllFillLevels(self.trailers)
                                if isFull then
                                    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "LoadAtDestinationTask:update leftCapacity <= -> self:finished")
                                    self:finished()
                                end
                            end
                        end
                    end
                end
            end
        else
            AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "LoadAtDestinationTask:update NOT isTargetReached")
            if not ((self.vehicle.ad.restartCP == true or (self.vehicle.ad.stateModule:getStartCP_AIVE())) 
                    and self.vehicle.ad.stateModule:getMode() == AutoDrive.MODE_PICKUPANDDELIVER) then
                -- need to try loading if CP is not active
                self.vehicle.ad.trailerModule:update(dt)
            end
            if self.vehicle.ad.trailerModule:isActiveAtTrigger() then
                AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "LoadAtDestinationTask:update 2 isActiveAtTrigger -> specialDrivingModule:stopVehicle")
                self.vehicle.ad.specialDrivingModule:stopVehicle()
                self.vehicle.ad.specialDrivingModule:update(dt)
            else
                AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "LoadAtDestinationTask:update not isActiveAtTrigger -> drivePathModule:update")
                self.vehicle.ad.drivePathModule:update(dt)
            end
        end
    end
end

function LoadAtDestinationTask:continue()
    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "LoadAtDestinationTask:continue -> trailerModule:stopLoading")
    self.vehicle.ad.trailerModule:stopLoading()
    AutoDrive.deactivateALTrailers(self.vehicle, self.trailers)
end

function LoadAtDestinationTask:abort()
    AutoDrive.deactivateALTrailers(self.vehicle, self.trailers)
end

function LoadAtDestinationTask:finished()
    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_VEHICLEINFO, "LoadAtDestinationTask:finished -> specialDrivingModule:releaseVehicle / setCurrentTaskFinished")
    self.vehicle.ad.specialDrivingModule:releaseVehicle()
    AutoDrive.deactivateALTrailers(self.vehicle, self.trailers)
    self.vehicle.ad.taskModule:setCurrentTaskFinished()
end

function LoadAtDestinationTask:getI18nInfo()
    if self.state == LoadAtDestinationTask.STATE_PATHPLANNING then
        local actualState, maxStates = self.vehicle.ad.pathFinderModule:getCurrentState()
        return "$l10n_AD_task_pathfinding;" .. string.format(" %d / %d ", actualState, maxStates)
    else
        return "$l10n_AD_task_drive_to_load_point;"
    end
end
