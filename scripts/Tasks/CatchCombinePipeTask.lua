CatchCombinePipeTask = ADInheritsFrom(AbstractTask)

CatchCombinePipeTask.TARGET_DISTANCE = 15

CatchCombinePipeTask.STATE_PATHPLANNING = 1
CatchCombinePipeTask.STATE_DRIVING = 2
CatchCombinePipeTask.STATE_REVERSING = 3
CatchCombinePipeTask.STATE_DELAY_PATHPLANNING = 4
CatchCombinePipeTask.STATE_WAIT_BEFORE_FINISH = 5
CatchCombinePipeTask.STATE_FINISHED = 6

CatchCombinePipeTask.MAX_REVERSE_DISTANCE = 18
CatchCombinePipeTask.MIN_COMBINE_DISTANCE = 25
CatchCombinePipeTask.MAX_REVERSE_TIME = 5000
CatchCombinePipeTask.MAX_STUCK_TIME = 60000
CatchCombinePipeTask.MAX_COUNT_NEW_PATHFINDING = 20

function CatchCombinePipeTask:new(vehicle, combine)
    local o = CatchCombinePipeTask:create()
    o.vehicle = vehicle
    o.combine = combine
    o.state = CatchCombinePipeTask.STATE_DELAY_PATHPLANNING
    o.wayPoints = nil
    o.stuckTimer = AutoDriveTON:new()
    o.reverseTimer = AutoDriveTON:new()
    o.waitTimer = AutoDriveTON:new()
    o.waitForCheckTimer = AutoDriveTON:new()
    o.waitForCheckTimer.elapsedTime = 4000
    o.taskType = "CatchCombinePipeTask"
    o.newPathFindingCounter = 0
    o.trailers = nil
    return o
end

function CatchCombinePipeTask:setUp()
    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_COMBINEINFO, "CatchCombinePipeTask:setUp()")
    local angleToCombineHeading = self.vehicle.ad.modes[AutoDrive.MODE_UNLOAD]:getAngleToCombineHeading()
    local angleToCombine = self.vehicle.ad.modes[AutoDrive.MODE_UNLOAD]:getAngleToCombine()

    if angleToCombineHeading < 35 and angleToCombine < 90 and AutoDrive.getDistanceBetween(self.vehicle, self.combine) < 60 then
        self:finished()
    end
    self.trailers, _ = AutoDrive.getAllUnits(self.vehicle)
    AutoDrive.setTrailerCoverOpen(self.vehicle, self.trailers, true)
end

function CatchCombinePipeTask:update(dt)
    if self.combine ~= nil and g_currentMission.nodeToObject[self.combine.components[1].node] == nil then
        self:finished()
        return
    end

    if self.state == CatchCombinePipeTask.STATE_PATHPLANNING then
        if self.vehicle.ad.pathFinderModule:hasFinished() then
            AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_COMBINEINFO, "CatchCombinePipeTask:update - STATE_PATHPLANNING finished")
            self.newPathFindingCounter = 0
            self.wayPoints = self.vehicle.ad.pathFinderModule:getPath()
            if self.wayPoints == nil or #self.wayPoints < 1 then
                --restart
                self.vehicle.ad.modes[AutoDrive.MODE_UNLOAD]:notifyAboutFailedPathfinder()
                --AutoDriveMessageEvent.sendMessageOrNotification(self.vehicle, ADMessagesManager.messageTypes.WARN, "$l10n_AD_Driver_of; %s $l10n_AD_cannot_find_path; %s", 5000, self.vehicle.ad.stateModule:getName(), self.combine.ad.stateModule:getName())
                AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_COMBINEINFO, "CatchCombinePipeTask:update - STATE_PATHPLANNING restarting path finder - with delay")
                self.state = CatchCombinePipeTask.STATE_DELAY_PATHPLANNING
                return
            else
                self.vehicle.ad.drivePathModule:setWayPoints(self.wayPoints)
                self.stuckTimer:timer(false)
                self.state = CatchCombinePipeTask.STATE_DRIVING
            end
        else
            self.vehicle.ad.pathFinderModule:update(dt)
            self.vehicle.ad.specialDrivingModule:stopVehicle()
            self.vehicle.ad.specialDrivingModule:update(dt)
        end
    elseif self.state == CatchCombinePipeTask.STATE_DELAY_PATHPLANNING then
        if self.waitForCheckTimer:timer(true, 1000, dt) then
            if self:startNewPathFinding() then
                self.vehicle.ad.pathFinderModule:addDelayTimer(6000)
                self.state = CatchCombinePipeTask.STATE_PATHPLANNING
            end
            if self.newPathFindingCounter > self.MAX_COUNT_NEW_PATHFINDING then
                -- prevent deadlock
                self.state = CatchCombinePipeTask.STATE_FINISHED
                return
            end
        end        
        self.vehicle.ad.specialDrivingModule:stopVehicle()
        self.vehicle.ad.specialDrivingModule:update(dt)
    elseif self.state == CatchCombinePipeTask.STATE_DRIVING then
        -- check if this is still a clever path to follow
        -- do this by distance of the combine to the last location pathfinder started at
        local x, y, z = getWorldTranslation(self.combine.components[1].node)
        local combineTravelDistance = MathUtil.vector2Length(x - self.combinesStartLocation.x, z - self.combinesStartLocation.z)

        self.stuckTimer:timer(self.vehicle.lastSpeedReal <= 0.0002, self.MAX_STUCK_TIME, dt)
        if self.stuckTimer:done() 
            -- or AutoDrive.getDistanceBetween(self.vehicle, self.combine) < self.MIN_COMBINE_DISTANCE 
            then
            -- got stuck or to close to combine -> reverse
            self.stuckTimer:timer(false)
            local x, y, z = getWorldTranslation(self.vehicle.components[1].node)
            self.reverseStartLocation = {x = x, y = y, z = z}
            self.state = CatchCombinePipeTask.STATE_REVERSING
            return
        end

        if combineTravelDistance > 85 then
            AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_COMBINEINFO, "CatchCombinePipeTask:update - combine travelled - recalculate path")
            self.waitForCheckTimer.elapsedTime = 4000
            self.state = CatchCombinePipeTask.STATE_DELAY_PATHPLANNING
        else
            if self.vehicle.ad.drivePathModule:isTargetReached() then
                -- check if we have actually reached the target or not
                -- accept current location if we are in a good position to start chasing: distance and angle are important here
                local angleToCombine = self.vehicle.ad.modes[AutoDrive.MODE_UNLOAD]:getAngleToCombineHeading()
                local isCorrectSide = self.vehicle.ad.modes[AutoDrive.MODE_UNLOAD]:isUnloaderOnCorrectSide()

                if angleToCombine < 35 and AutoDrive.getDistanceBetween(self.vehicle, self.combine) < 80 and isCorrectSide then
                    self.state = CatchCombinePipeTask.STATE_FINISHED
                    return
                else
                    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_COMBINEINFO, "CatchCombinePipeTask:update - angle or distance to combine too high - recalculate path now")
                    self.state = CatchCombinePipeTask.STATE_DELAY_PATHPLANNING
                end
            else
                self.vehicle.ad.drivePathModule:update(dt)
            end
        end
    elseif self.state == CatchCombinePipeTask.STATE_REVERSING then
        local x, y, z = getWorldTranslation(self.vehicle.components[1].node)
        local distanceToReverseStart = MathUtil.vector2Length(x - self.reverseStartLocation.x, z - self.reverseStartLocation.z)
        self.reverseTimer:timer(true, self.MAX_REVERSE_TIME, dt)
        if distanceToReverseStart > self.MAX_REVERSE_DISTANCE or self.reverseTimer:done() then
            self.reverseTimer:timer(false)
            self.state = CatchCombinePipeTask.STATE_WAIT_BEFORE_FINISH
        else
            self.vehicle.ad.specialDrivingModule:driveReverse(dt, 15, 1, self.vehicle.ad.trailerModule:canBeHandledInReverse())
        end
    elseif self.state == CatchCombinePipeTask.STATE_WAIT_BEFORE_FINISH then
        self.waitTimer:timer(true, self.MAX_REVERSE_TIME, dt)
        if self.waitTimer:done() then
            self.waitTimer:timer(false)
            self.state = CatchCombinePipeTask.STATE_FINISHED
            return
        else
            self.vehicle.ad.specialDrivingModule:stopVehicle()
            self.vehicle.ad.specialDrivingModule:update(dt)
        end
    elseif self.state == CatchCombinePipeTask.STATE_FINISHED then
        self:finished()
        return
    end
end

function CatchCombinePipeTask:abort()
end

function CatchCombinePipeTask:finished(propagate)
    AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_COMBINEINFO, "CatchCombinePipeTask:finished()")
    self.vehicle.ad.taskModule:setCurrentTaskFinished(propagate)
end

function CatchCombinePipeTask:startNewPathFinding()
    local pipeChasePos, pipeChaseSide = self.vehicle.ad.modes[AutoDrive.MODE_UNLOAD]:getPipeChasePosition(true)
    local x, _, z = getWorldTranslation(self.combine.components[1].node)
    local targetFieldId = g_farmlandManager:getFarmlandIdAtWorldPosition(pipeChasePos.x, pipeChasePos.z)
    local combineFieldId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)

    -- Only chase the rear on low fill levels of the combine. This should prevent getting into unneccessarily tight spots for the final approach to the pipe.
    -- Also for small fields, there is often no purpose in chasing so far behind the combine as it will already start a turn soon

    local cfillLevel, cfillCapacity, _, cfillFreeCapacity = AutoDrive.getObjectFillLevels(self.combine)
    local cFillRatio = cfillCapacity > 0 and cfillLevel / cfillCapacity or 0

    if cFillRatio > 0.91 or cfillFreeCapacity < 0.1 then
        AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_COMBINEINFO, "CatchCombinePipeTask:startNewPathFinding() - Combine is almost full - dont chase for active unloading anymore")
        self:finished(ADTaskModule.DONT_PROPAGATE)
        self.vehicle.ad.modes[AutoDrive.MODE_UNLOAD]:setToWaitForCall()
        return false
    end

    self.newPathFindingCounter = self.newPathFindingCounter + 1 -- used to prevent deadlock

    if AutoDrive.getIsBufferCombine(self.combine) or (pipeChaseSide ~= AutoDrive.CHASEPOS_REAR or (targetFieldId == combineFieldId and cFillRatio <= 0.85)) then
    -- if self.combine:getIsBufferCombine() or (pipeChaseSide ~= AutoDrive.CHASEPOS_REAR and targetFieldId == combineFieldId and cFillRatio <= 0.85) then
        -- is chopper or chase not rear and harvester on correct field and filled < 85% - i.e. combine pipe not in fruit
        AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_COMBINEINFO, "CatchCombinePipeTask:startNewPathFinding() - chase pos looks good - calculate path to it...")
        self.vehicle.ad.pathFinderModule:startPathPlanningToPipe(self.combine, false)
        -- use false to enable pathfinder fallback
        self.combinesStartLocation = {}
        self.combinesStartLocation.x, self.combinesStartLocation.y, self.combinesStartLocation.z = getWorldTranslation(self.combine.components[1].node)
        return true
    else
        AutoDrive.debugPrint(self.vehicle, AutoDrive.DC_COMBINEINFO, "CatchCombinePipeTask:startNewPathFinding() - chase pos looks bad, is not on the same field or combine's fill level is approaching limit - aborting for now")
        self.waitForCheckTimer:timer(false)
    end
    return false
end

function CatchCombinePipeTask:getI18nInfo()
    local text = "$l10n_AD_task_catch_up_with_combine;"
    if self.state == CatchCombinePipeTask.STATE_PATHPLANNING then
        local actualState, maxStates = self.vehicle.ad.pathFinderModule:getCurrentState()
        text = text .. " - " .. "$l10n_AD_task_pathfinding;" .. string.format(" %d / %d ", actualState, maxStates)
    elseif self.state == CatchCombinePipeTask.STATE_DELAY_PATHPLANNING then
        text = text .. " - " .. "$l10n_AD_task_unload_area_in_fruit;"
    elseif self.state == CatchCombinePipeTask.STATE_REVERSING then
        text = text .. " - " .. "$l10n_AD_task_reversing_from_combine;"
    elseif self.state == CatchCombinePipeTask.STATE_WAIT_BEFORE_FINISH then
        text = text .. " - " .. "$l10n_AD_task_waiting_for_room;"
    end
    return text 
end

function CatchCombinePipeTask.debugMsg(vehicle, debugText, ...)
    if CatchCombinePipeTask.debug == true then
        AutoDrive.debugMsg(vehicle, debugText, ...)
    end
end
