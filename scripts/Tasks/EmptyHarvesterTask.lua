EmptyHarvesterTask = ADInheritsFrom(AbstractTask)
EmptyHarvesterTask.debug = false

EmptyHarvesterTask.STATE_PATHPLANNING = {}
EmptyHarvesterTask.STATE_DRIVING = {}
EmptyHarvesterTask.STATE_UNLOADING = {}
EmptyHarvesterTask.STATE_REVERSING = {}
EmptyHarvesterTask.STATE_WAITING = {}
EmptyHarvesterTask.STATE_UNLOADING_FINISHED = {}

EmptyHarvesterTask.REVERSE_TIME = 30000
EmptyHarvesterTask.WAITING_TIME = 7000

function EmptyHarvesterTask:new(vehicle, combine)
    local o = EmptyHarvesterTask:create()
    o.vehicle = vehicle
    o.combine = combine
    o.state = EmptyHarvesterTask.STATE_PATHPLANNING
    o.wayPoints = nil
    o.reverseStartLocation = nil
    o.reverseTimer = AutoDriveTON:new()
    o.waitTimer = AutoDriveTON:new()
    o.holdCPCombineTimer = AutoDriveTON:new()
    o.trailers = nil
    o.trailerCount = 0
    o.tractorTrainLength = 0
    EmptyHarvesterTask.setStateNames(o)
    return o
end

function EmptyHarvesterTask:setUp()
    EmptyHarvesterTask.debugMsg(self.vehicle, "EmptyHarvesterTask:setUp")
    self.vehicle.ad.pathFinderModule:startPathPlanningToPipe(self.combine, false)
    self.trailers, self.trailerCount = AutoDrive.getAllUnits(self.vehicle)
    self.tractorTrainLength = AutoDrive.getTractorTrainLength(self.vehicle, true, false)
    AutoDrive.setTrailerCoverOpen(self.vehicle, self.trailers, true)
end

function EmptyHarvesterTask:update(dt)
    if self.combine ~= nil and g_currentMission.nodeToObject[self.combine.components[1].node] == nil then
        self:finished()
        return
    end
    if self.lastState ~= self.state then
        EmptyHarvesterTask.debugMsg(self.vehicle, "EmptyHarvesterTask:update %s -> %s", tostring(self:getStateName(self.lastState)), tostring(self:getStateName()))
        self.lastState = self.state
    end

    if self.state == EmptyHarvesterTask.STATE_PATHPLANNING then
        if self.vehicle.ad.pathFinderModule:hasFinished() then
            self.wayPoints = self.vehicle.ad.pathFinderModule:getPath()
            self.vehicle.ad.drivePathModule:setWayPoints(self.wayPoints)
            if self.wayPoints == nil or #self.wayPoints == 0 then
                -- If the target/pipe location is blocked, we can issue a notification and stop the task - Otherwise we pause a moment and retry
                if self.vehicle.ad.pathFinderModule:isTargetBlocked() then
                    self:finished(ADTaskModule.DONT_PROPAGATE)
                    self.vehicle:stopAutoDrive()
                    AutoDriveMessageEvent.sendMessageOrNotification(self.vehicle, ADMessagesManager.messageTypes.WARN, "$l10n_AD_Driver_of; %s $l10n_AD_cannot_find_path; %s", 5000, self.vehicle.ad.stateModule:getName(), self.combine.ad.stateModule:getName())
                    return
                else
                    self.vehicle.ad.modes[AutoDrive.MODE_UNLOAD]:notifyAboutFailedPathfinder()
                    self.vehicle.ad.pathFinderModule:startPathPlanningToPipe(self.combine, false)
                    self.vehicle.ad.pathFinderModule:addDelayTimer(10000)
                end
            else
                self.state = EmptyHarvesterTask.STATE_DRIVING
            end
        else
            self.vehicle.ad.pathFinderModule:update(dt)
            self.vehicle.ad.specialDrivingModule:stopVehicle()
            self.vehicle.ad.specialDrivingModule:update(dt)
        end
    elseif self.state == EmptyHarvesterTask.STATE_DRIVING then
        if self.vehicle.ad.drivePathModule:isTargetReached() then
            self.state = EmptyHarvesterTask.STATE_UNLOADING
        else
            self.vehicle.ad.drivePathModule:update(dt)
        end
    elseif self.state == EmptyHarvesterTask.STATE_UNLOADING then
        self.vehicle.ad.specialDrivingModule.motorShouldNotBeStopped = true
        -- Stopping CP drivers for now
        AutoDrive:holdCPCombine(self.combine)
        --Check if the combine is moving / has already moved away and we are supposed to actively unload
        if self.combine.ad.driveForwardTimer.elapsedTime > 100 then
            EmptyHarvesterTask.debugMsg(self.vehicle, "EmptyHarvesterTask:update driveForwardTimer.elapsedTime > 100")
            if AutoDrive.isVehicleOrTrailerInCrop(self.vehicle, true) then
                EmptyHarvesterTask.debugMsg(self.vehicle, "EmptyHarvesterTask:update isVehicleOrTrailerInCrop")
                self:finished()
                return
            elseif self.combine.ad.driveForwardTimer.elapsedTime > 4000 then
                EmptyHarvesterTask.debugMsg(self.vehicle, "EmptyHarvesterTask:update driveForwardTimer.elapsedTime > 4000")
                self.vehicle.ad.modes[AutoDrive.MODE_UNLOAD].state = CombineUnloaderMode.STATE_ACTIVE_UNLOAD_COMBINE
                self.vehicle.ad.modes[AutoDrive.MODE_UNLOAD].breadCrumbs = Queue:new()
                self.vehicle.ad.modes[AutoDrive.MODE_UNLOAD].lastBreadCrumb = nil
                self.vehicle.ad.taskModule:addTask(FollowCombineTask:new(self.vehicle, self.combine))
                self.vehicle.ad.taskModule:setCurrentTaskFinished(ADTaskModule.DONT_PROPAGATE)
            end
        end

        local combineFillLevel, _, _ = AutoDrive.getObjectFillLevels(self.combine)

        if combineFillLevel > 0.1 and self.combine.getDischargeState ~= nil and self.combine:getDischargeState() ~= Dischargeable.DISCHARGE_STATE_OFF then
            self.vehicle.ad.specialDrivingModule:stopVehicle()
            self.vehicle.ad.specialDrivingModule:update(dt)
        else
            --Is the current trailer filled or is the combine empty?
            local _, _, filledToUnload = AutoDrive.getAllFillLevels(self.trailers)
            local distanceToCombine = AutoDrive.getDistanceBetween(self.vehicle, self.combine)

            if combineFillLevel <= 0.1 or filledToUnload then
                local x, y, z = getWorldTranslation(self.vehicle.components[1].node)
                self.reverseStartLocation = {x = x, y = y, z = z}
                self.state = EmptyHarvesterTask.STATE_UNLOADING_FINISHED
            else
                -- Drive forward with collision checks active and only for a limited distance
                if distanceToCombine > 30 then
                    EmptyHarvesterTask.debugMsg(self.vehicle, "EmptyHarvesterTask:update distanceToCombine > 30")
                    self:finished()
                    return
                else
                    self.vehicle.ad.specialDrivingModule:driveForward(dt)
                end
            end
        end
    elseif self.state == EmptyHarvesterTask.STATE_UNLOADING_FINISHED then
        EmptyHarvesterTask.debugMsg(self.vehicle, "EmptyHarvesterTask:update - STATE_UNLOADING_FINISHED getIsCPCombineInPocket %s", tostring(AutoDrive:getIsCPCombineInPocket(self.combine)))
        if AutoDrive:getIsCPCombineInPocket(self.combine) or AutoDrive.combineIsTurning(self.combine) then
            -- reverse if CP unload in a pocket or pullback position
            -- reverse if combine is turning
            self.state = EmptyHarvesterTask.STATE_REVERSING
        else
            self.state = EmptyHarvesterTask.STATE_WAITING
        end
    elseif self.state == EmptyHarvesterTask.STATE_REVERSING then
        self.vehicle.ad.specialDrivingModule.motorShouldNotBeStopped = false
        local x, y, z = getWorldTranslation(self.vehicle.components[1].node)
        local distanceToReversStart = MathUtil.vector2Length(x - self.reverseStartLocation.x, z - self.reverseStartLocation.z)
        local overallLength
        if self.trailerCount <= 1 then
            overallLength = math.max(self.vehicle.size.length * 2, 15) -- 2x tractor length, min. 15m
        else
            overallLength = self.tractorTrainLength -- complete train length
        end
        if AutoDrive:getIsCPActive(self.combine) then
            -- if CP harvester
            overallLength = overallLength + AutoDrive.getFrontToolWidth(self.combine)
        end
        if self.combine.trailingVehicle ~= nil then
            -- if the harvester is trailed reverse 5m more
            -- overallLength = overallLength + 5
        end
        self.holdCPCombineTimer:timer(true, EmptyHarvesterTask.REVERSE_TIME, dt)
        if not self.holdCPCombineTimer:done() then
            -- Stopping CP drivers while reverse driving
            AutoDrive:holdCPCombine(self.combine)
        end
        self.reverseTimer:timer(true, EmptyHarvesterTask.REVERSE_TIME, dt)
        if (distanceToReversStart > overallLength) or self.reverseTimer:done() then
            self.holdCPCombineTimer:timer(false)
            self.reverseTimer:timer(false)
            self.state = EmptyHarvesterTask.STATE_WAITING
        else
            self.vehicle.ad.specialDrivingModule:driveReverse(dt, 10, 1, self.vehicle.ad.trailerModule:canBeHandledInReverse())
        end
    elseif self.state == EmptyHarvesterTask.STATE_WAITING then
        local waitTime = EmptyHarvesterTask.WAITING_TIME
        if AutoDrive:getIsCPActive(self.combine) then
            -- wait some more time to let CP combine move away
            waitTime = 3 * EmptyHarvesterTask.WAITING_TIME
        end
        self.waitTimer:timer(true, waitTime, dt)
        if self.waitTimer:done() then
            self.waitTimer:timer(false)
            self:finished()
            return
        else
            self.vehicle.ad.specialDrivingModule:stopVehicle()
            self.vehicle.ad.specialDrivingModule:update(dt)
        end
    end
end

function EmptyHarvesterTask:abort()
end

function EmptyHarvesterTask:finished(propagate)
    EmptyHarvesterTask.debugMsg(self.vehicle, "EmptyHarvesterTask:finished()")
    self.vehicle.ad.specialDrivingModule.motorShouldNotBeStopped = false
    self.vehicle.ad.taskModule:setCurrentTaskFinished(propagate)
end

function EmptyHarvesterTask:getExcludedVehiclesForCollisionCheck()
    local excludedVehicles = {}
    if self.state == EmptyHarvesterTask.STATE_DRIVING then
        table.insert(excludedVehicles, self.combine:getRootVehicle())
    end
    return excludedVehicles
end

function EmptyHarvesterTask:setStateNames()
    if self.statesToNames == nil then
        self.statesToNames = {}
        for name, id in pairs(EmptyHarvesterTask) do
            if string.sub(name, 1, 6) == "STATE_" then
                self.statesToNames[id] = name
            end
        end
    end
end

function EmptyHarvesterTask:getStateName(state)
    local requestedState = state
    if requestedState == nil then
        requestedState = self.state
    end
    if requestedState == nil then
        Logging.error("[AD] EmptyHarvesterTask: Could not find name for state ->%s<- !", tostring(requestedState))
    end
    return self.statesToNames[requestedState] or ""
end

function EmptyHarvesterTask:getI18nInfo()
    local text = "$l10n_AD_task_unloading_combine;"
    if self.state == EmptyHarvesterTask.STATE_PATHPLANNING then
        local actualState, maxStates = self.vehicle.ad.pathFinderModule:getCurrentState()
        text = text .. " - " .. "$l10n_AD_task_pathfinding;" .. string.format(" %d / %d ", actualState, maxStates)
    elseif self.state == EmptyHarvesterTask.STATE_DRIVING then
        text = text .. " - " .. "$l10n_AD_task_drive_to_combine_pipe;"
    elseif self.state == EmptyHarvesterTask.STATE_UNLOADING then
        text = text .. " - " .. "$l10n_AD_task_unloading_combine;"
    elseif self.state == EmptyHarvesterTask.STATE_REVERSING then
        text = text .. " - " .. "$l10n_AD_task_reversing_from_combine;"
    elseif self.state == EmptyHarvesterTask.STATE_WAITING then
        text = text .. " - " .. "$l10n_AD_task_waiting_for_room;"
    end
    return text 
end

function EmptyHarvesterTask.debugMsg(vehicle, debugText, ...)
    if EmptyHarvesterTask.debug == true then
        AutoDrive.debugMsg(vehicle, debugText, ...)
    else
        AutoDrive.debugPrint(vehicle, AutoDrive.DC_COMBINEINFO, debugText, ...)
    end
end
