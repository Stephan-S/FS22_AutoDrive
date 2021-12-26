UnloadAtMode = ADInheritsFrom(AbstractMode)

UnloadAtMode.STATE_TO_TARGET = 1
UnloadAtMode.STATE_FINISHED = 2
UnloadAtMode.STATE_EXIT_FIELD = 3
UnloadAtMode.STATE_PARK = 4

function UnloadAtMode:new(vehicle)
    local o = UnloadAtMode:create()
    o.vehicle = vehicle
    UnloadAtMode.reset(o)
    return o
end

function UnloadAtMode:reset()
    self.state = UnloadAtMode.STATE_TO_TARGET
    self.activeTask = nil
    self.vehicle.ad.trailerModule:reset()
end

function UnloadAtMode:start()
    if not self.vehicle.ad.stateModule:isActive() then
        self.vehicle:startAutoDrive()
    end

    if self.vehicle.ad.stateModule:getFirstMarker() == nil then
        return
    end

    self:reset()
    self.activeTask = self:getNextTask()
    if self.activeTask ~= nil then
        self.vehicle.ad.taskModule:addTask(self.activeTask)
    end
end

function UnloadAtMode:monitorTasks(dt)
end

function UnloadAtMode:handleFinishedTask()
    self.vehicle.ad.trailerModule:reset()
    self.activeTask = self:getNextTask()
    if self.activeTask ~= nil then
        self.vehicle.ad.taskModule:addTask(self.activeTask)
    end
end

function UnloadAtMode:stop()
end

function UnloadAtMode:getNextTask()
	AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtMode:getNextTask start self.state %s", tostring(self.state))
    local nextTask

	if self.state == UnloadAtMode.STATE_TO_TARGET then
		-- STATE_TO_TARGET - drive to unload destination
		AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtMode:getNextTask STATE_TO_TARGET UnloadAtDestinationTask...")

        if self.vehicle.ad.stateModule:getAutomaticUnloadTarget() then
            local sellingStation = ADTriggerManager:getHighestPayingSellStation(self.vehicle.ad.stateModule:getFillType())
            if sellingStation ~= nil then
                local wpId = ADTriggerManager:getMarkerAtStation(sellingStation, self.vehicle)
                if wpId > 0 then                    
                    self.vehicle.ad.stateModule:setFirstMarkerByWayPointId(wpId)
                end
            end
        end

		nextTask = UnloadAtDestinationTask:new(self.vehicle, self.vehicle.ad.stateModule:getFirstMarker().id)
		self.state = UnloadAtMode.STATE_PARK
    elseif self.state == UnloadAtMode.STATE_PARK then
        -- job done - drive to park position
        AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtMode:getNextTask STATE_PARK ParkTask...")
        nextTask = ParkTask:new(self.vehicle, self.vehicle.ad.stateModule:getFirstMarker().id)
        self.state = UnloadAtMode.STATE_FINISHED
        -- message for reached park position send by ParkTask as only there the correct destination is known
	else
		-- self.state == UnloadAtMode.STATE_FINISHED then
		AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_PATHINFO, "UnloadAtMode:getNextTask STATE_FINISHED StopAndDisableADTask...")
		nextTask = StopAndDisableADTask:new(self.vehicle, ADTaskModule.DONT_PROPAGATE)
    end
    return nextTask
end

function UnloadAtMode:shouldUnloadAtTrigger()
    return (self.state == UnloadAtMode.STATE_PARK)
end
