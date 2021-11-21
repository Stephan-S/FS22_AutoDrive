WaitForCallTask = ADInheritsFrom(AbstractTask)

function WaitForCallTask:new(vehicle)
    local o = WaitForCallTask:create()
    o.vehicle = vehicle
    return o
end

function WaitForCallTask:setUp()
    ADHarvestManager:registerAsUnloader(self.vehicle)
    self.vehicle.ad.specialDrivingModule:stopVehicle()
end

function WaitForCallTask:update(dt)
    self.vehicle.ad.specialDrivingModule:stopVehicle()
    self.vehicle.ad.specialDrivingModule:update(dt)
end

function WaitForCallTask:abort()
end

function WaitForCallTask:finished()
    self.vehicle.ad.taskModule:setCurrentTaskFinished(self.propagate)
end

function WaitForCallTask:getInfoText()
    return g_i18n:getText("AD_task_wait_for_call")
end

function WaitForCallTask:getI18nInfo()
    return "$l10n_AD_task_wait_for_call;"
end
