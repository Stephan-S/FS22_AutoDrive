BGAMode = ADInheritsFrom(AbstractMode)

function BGAMode:new(vehicle)
    local o = BGAMode:create()
    o.vehicle = vehicle
    BGAMode.reset(o)
    return o
end

function BGAMode:reset()
end

function BGAMode:start()
    if not self.vehicle.ad.stateModule:isActive() then
        self.vehicle:startAutoDrive()
    end

    self.vehicle.ad.taskModule:addTask(UnloadBGATask:new(self.vehicle))
end

function BGAMode:monitorTasks(dt)
end

function BGAMode:handleFinishedTask()
    --print("BGAMode:handleFinishedTask")
    self.vehicle.ad.taskModule:addTask(StopAndDisableADTask:new(self.vehicle, ADTaskModule.DONT_PROPAGATE))
end

function BGAMode:stop()
end
