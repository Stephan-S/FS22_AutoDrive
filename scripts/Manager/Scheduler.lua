ADScheduler = {}
ADScheduler.UPDATE_TIME = 3000 -- time interval for calculation/check
ADScheduler.FRAMES_TO_CHECK_FOR_ACTUAL_FPS = 10 -- number of frames to calculate actual FPS
ADScheduler.FRAMES_TO_CHECK_FOR_AVERAGE_FPS = 60 * 60 -- number of frames to calculate average FPS
ADScheduler.MIN_STEPS_PER_FRAME = 8 -- min steps for pathfinder per frame
ADScheduler.MAX_STEPS_PER_FRAME = 8 -- max steps for pathfinder per frame
ADScheduler.FPS_DIFFERENCE = 0.1   -- 10 % difference to average for calculation/check
ADScheduler.MIN_FPS = 20 -- min FPS where stepsPerFrame will always be decreased
ADScheduler.MAX_FPS = 60 -- max FPS for some calculations

function ADScheduler:load()
    self.actual_values = {}
    self.actual_counter = 0
    self.actual_fps = 0

    self.average_values = {}
    self.average_counter = 0
    self.average_fps = 0

    self.stepsPerFrame = ADScheduler.MAX_STEPS_PER_FRAME
    self.pathFinderVehicles = {}
    self.activePathFindervehicle = nil
    self.updateTimer = AutoDriveTON:new()
end

function ADScheduler:update(dt)
    self.updateTimer:timer(true, ADScheduler.UPDATE_TIME, dt)

    self.actual_counter = self.actual_counter + 1
    if self.actual_counter > ADScheduler.FRAMES_TO_CHECK_FOR_ACTUAL_FPS then
        self.actual_counter = 1
    end
    self.actual_values[self.actual_counter] = dt

    self.average_counter = self.average_counter + 1
    if self.average_counter > ADScheduler.FRAMES_TO_CHECK_FOR_AVERAGE_FPS then
        self.average_counter = 1
    end
    self.average_values[self.average_counter] = dt
    if (self.average_counter == ADScheduler.FRAMES_TO_CHECK_FOR_AVERAGE_FPS) and (self.average_fps > (ADScheduler.MAX_FPS - ADScheduler.MIN_FPS) / 2 + ADScheduler.MIN_FPS) then
        -- if average FPS is high we can increase in longer periods to reach the max stepsPerFrame somehow if feasible
        self.stepsPerFrame = math.min(ADScheduler.MAX_STEPS_PER_FRAME, self.stepsPerFrame + 1)
    end

    if self.updateTimer:done() then
        self.updateTimer:timer(false)

        if self.average_values[ADScheduler.FRAMES_TO_CHECK_FOR_AVERAGE_FPS] ~= nil and self.average_values[ADScheduler.FRAMES_TO_CHECK_FOR_AVERAGE_FPS] ~= 0 then
            -- average table filled - we can start the update
            self:updateAverageFPS()
        end

        if self.actual_values[ADScheduler.FRAMES_TO_CHECK_FOR_ACTUAL_FPS] ~= nil and self.actual_values[ADScheduler.FRAMES_TO_CHECK_FOR_ACTUAL_FPS] ~= 0 then
            -- actual table filled - we can start
            self:updateActualFPS()

            local averagefps = 0
            if self.average_fps == 0 then
                -- on start of game we set the average somehow until the average table is filled
                averagefps = (ADScheduler.MAX_FPS - ADScheduler.MIN_FPS) / 2 + ADScheduler.MIN_FPS
            else
                -- the average is calculated, so use it from now onwards
                averagefps = self.average_fps
            end
            AutoDrive.debugPrint(nil, AutoDrive.DC_PATHINFO, "Scheduler update self.actual_fps %.1f averagefps %.1f self.stepsPerFrame %s", self.actual_fps, averagefps, tostring(self.stepsPerFrame))

            if self.actual_fps > averagefps * (1 + ADScheduler.FPS_DIFFERENCE) then
                -- actual FPS is higher than average, so we can increase stepsPerFrame
                self.stepsPerFrame = math.min(ADScheduler.MAX_STEPS_PER_FRAME, self.stepsPerFrame + 1)
            elseif self.actual_fps < averagefps * (1 - ADScheduler.FPS_DIFFERENCE) then
                -- actual FPS is lower than average, so we have to decrease stepsPerFrame
                self.stepsPerFrame = math.max(ADScheduler.MIN_STEPS_PER_FRAME, self.stepsPerFrame - 1)
            elseif self.actual_fps < ADScheduler.MIN_FPS then
                -- if FPS drift sligthly below MIN_FPS, reduce the stepsPerFrame
                self.stepsPerFrame = math.max(ADScheduler.MIN_STEPS_PER_FRAME, self.stepsPerFrame - 1)
            end
        end
        self:updateActiveVehicle() -- activate the next vehicle in queue
    end
end

function ADScheduler:getStepsPerFrame()
    return self.stepsPerFrame
end

function ADScheduler:updateActualFPS()
    -- calculate actual FPS by using some frame values to avoid short time drops to have to much influence
    local dt_sum = 0
    for i = 1, ADScheduler.FRAMES_TO_CHECK_FOR_ACTUAL_FPS, 1 do
        dt_sum = dt_sum + self.actual_values[i]
    end
    self.actual_fps = 1000 / (dt_sum / ADScheduler.FRAMES_TO_CHECK_FOR_ACTUAL_FPS)
end

function ADScheduler:updateAverageFPS()
    -- calculate the average FPS with huge number of values
    local sum = 0
    for i = 1, ADScheduler.FRAMES_TO_CHECK_FOR_AVERAGE_FPS, 1 do
        sum = sum + self.average_values[i]
    end
    self.average_fps = 1000 / (sum / ADScheduler.FRAMES_TO_CHECK_FOR_AVERAGE_FPS)
end

function ADScheduler:addPathfinderVehicle(vehicle)
    -- add a vehicle in the queue
    if not table.contains(self.pathFinderVehicles, vehicle) then
        AutoDrive.debugPrint(vehicle, AutoDrive.DC_PATHINFO, "Scheduler addPathfinderVehicle ")
        table.insert(self.pathFinderVehicles, vehicle)
        -- set new vehicle a delay
        if table.getn(self.pathFinderVehicles) > 1 then
            AutoDrive.debugPrint(vehicle, AutoDrive.DC_PATHINFO, "Scheduler addPathfinderVehicle addDelayTimer 10000")
            -- if already vehicle in table, pause this new one
            vehicle.ad.pathFinderModule:addDelayTimer(10000)
        end
    end
end

function ADScheduler:removePathfinderVehicle(vehicle)
    -- remove a vehicle from the queue
    if table.contains(self.pathFinderVehicles, vehicle) then
        AutoDrive.debugPrint(vehicle, AutoDrive.DC_PATHINFO, "Scheduler removePathfinderVehicle")
        table.removeValue(self.pathFinderVehicles, vehicle)
    end
end

function ADScheduler:updateActiveVehicle()
    if self.activePathFinderVehicle ~= nil then
        -- pause current vehicle
        self.activePathFinderVehicle.ad.pathFinderModule:addDelayTimer(10000)
    end

    -- get next vehicle
    self.activePathFinderVehicle = self.pathFinderVehicles[1]

    if self.activePathFinderVehicle ~= nil then
        AutoDrive.debugPrint(self.activePathFinderVehicle, AutoDrive.DC_PATHINFO, "Scheduler updateActiveVehicle activePathFinderVehicle")
        -- found vehicle
        -- add this vehicle to end of queue
        self:removePathfinderVehicle(self.activePathFinderVehicle)
        self:addPathfinderVehicle(self.activePathFinderVehicle)
        -- unpause vehicle to continue pathfinder calculation
        self.activePathFinderVehicle.ad.pathFinderModule:addDelayTimer(0)
    end
end
