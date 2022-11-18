StopAndDisableADTask = ADInheritsFrom(AbstractTask)

function StopAndDisableADTask:new(vehicle, propagate, restart)
    local o = StopAndDisableADTask:create()
    o.vehicle = vehicle
    o.propagate = propagate
    o.restart = restart
    o.trailers = nil
    return o
end

function StopAndDisableADTask:setUp()
    self.vehicle.ad.specialDrivingModule:stopVehicle()
    self.trailers, _ = AutoDrive.getAllUnits(self.vehicle)
    AutoDrive.setTrailerCoverOpen(self.vehicle, self.trailers, false)
    if self.vehicle.spec_locomotive then
        self.vehicle:raiseActive()
    end
end

function StopAndDisableADTask:update(dt)
    if math.abs(self.vehicle.lastSpeedReal) < 0.0015 then
        self.vehicle:stopAutoDrive()
        if self.restart ~= nil and self.restart == true then
            self.vehicle.ad.stateModule:getCurrentMode():start()
        end
        self:finished()
    else
        self.vehicle.ad.specialDrivingModule:update(dt)
    end
end

function StopAndDisableADTask:abort()
end

function StopAndDisableADTask:finished()
    self.vehicle.ad.taskModule:setCurrentTaskFinished(self.propagate)
end

function StopAndDisableADTask:getI18nInfo()
    return "$l10n_AD_task_stop_and_disable;"
end
