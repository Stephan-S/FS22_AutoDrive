DriveToVehicleTask = ADInheritsFrom(AbstractTask)

DriveToVehicleTask.TARGET_DISTANCE = 35

DriveToVehicleTask.STATE_PATHPLANNING = 1
DriveToVehicleTask.STATE_DRIVING = 2

function DriveToVehicleTask:new(vehicle, targetVehicle)
    local o = DriveToVehicleTask:create()
    o.vehicle = vehicle
    o.targetVehicle = targetVehicle
    o.state = DriveToVehicleTask.STATE_PATHPLANNING
    o.wayPoints = nil
    o.delayRestartTimer = 10000
    o.trailers = nil
    return o
end

function DriveToVehicleTask:setUp()
    self.vehicle.ad.pathFinderModule:reset()
    self.vehicle.ad.pathFinderModule:startPathPlanningToVehicle(self.targetVehicle, DriveToVehicleTask.TARGET_DISTANCE)
    self.trailers, _ = AutoDrive.getAllUnits(self.vehicle)
    AutoDrive.setTrailerCoverOpen(self.vehicle, self.trailers, false)
end

function DriveToVehicleTask:update(dt)
    if self.state == DriveToVehicleTask.STATE_PATHPLANNING then
        if self.vehicle.ad.pathFinderModule:hasFinished() then
            self.wayPoints = self.vehicle.ad.pathFinderModule:getPath()
            if self.wayPoints == nil or #self.wayPoints == 0 then
                --Don't just restart pathfinder here. We might not even have to go to the vehicle anymore.
                self.vehicle.ad.modes[AutoDrive.MODE_UNLOAD]:notifyAboutFailedPathfinder()
                if self.delayRestartTimer <= 0 then
                    self:finished()
                else
                    self.delayRestartTimer = self.delayRestartTimer - dt
                end
                --self.vehicle:stopAutoDrive()
                --self.vehicle.ad.pathFinderModule:startPathPlanningToVehicle(self.targetVehicle, DriveToVehicleTask.TARGET_DISTANCE)
            else
                self.vehicle.ad.drivePathModule:setWayPoints(self.wayPoints)
                self.state = DriveToVehicleTask.STATE_DRIVING
            end
        else
            self.vehicle.ad.pathFinderModule:update(dt)
            self.vehicle.ad.specialDrivingModule:stopVehicle()
            self.vehicle.ad.specialDrivingModule:update(dt)
        end
    elseif self.state == DriveToVehicleTask.STATE_DRIVING then
        if self.vehicle.ad.drivePathModule:isTargetReached() then
            self:finished()
        else
            self.vehicle.ad.drivePathModule:update(dt)
        end
    end
end

function DriveToVehicleTask:abort()
    self.targetVehicle.ad.modes[AutoDrive.MODE_UNLOAD]:unregisterFollowingUnloader()
end

function DriveToVehicleTask:finished(propagate)
    --Todo: Check for distance to breadcrumbs of active unloader and attach to them
    local closeToBreadCrumbs = false
    if self.targetVehicle ~= nil and self.targetVehicle.ad.modes[AutoDrive.MODE_UNLOAD]:getBreadCrumbs() ~= nil then
        local breadCrumbs = self.targetVehicle.ad.modes[AutoDrive.MODE_UNLOAD]:getBreadCrumbs()
        local x, _, z = getWorldTranslation(self.vehicle.components[1].node)        
        for _, breadCrumb in ipairs(breadCrumbs.items) do
            local _, _, diffZ = worldToLocal(self.vehicle.components[1].node, breadCrumb.x, breadCrumb.y, breadCrumb.z)
            if diffZ > 1 and MathUtil.vector2Length(x - breadCrumb.x, z - breadCrumb.z) < 5 then
                closeToBreadCrumbs = true
                break
            end
        end
    end
    if closeToBreadCrumbs then
        self.vehicle.ad.taskModule:addTask(FollowVehicleTask:new(self.vehicle, self.targetVehicle))
        self.vehicle.ad.taskModule:setCurrentTaskFinished(ADTaskModule.DONT_PROPAGATE)
    else
        self.targetVehicle.ad.modes[AutoDrive.MODE_UNLOAD]:unregisterFollowingUnloader()
        self.vehicle.ad.taskModule:setCurrentTaskFinished(propagate)
    end
end

function DriveToVehicleTask:getInfoText()
    if self.state == DriveToVehicleTask.STATE_PATHPLANNING then
        local actualState, maxStates = self.vehicle.ad.pathFinderModule:getCurrentState()
        return g_i18n:getText("AD_task_pathfinding") .. string.format(" %d / %d ", actualState, maxStates)
    else
        return g_i18n:getText("AD_task_drive_to_vehicle")
    end
end

function DriveToVehicleTask:getI18nInfo()
    if self.state == DriveToVehicleTask.STATE_PATHPLANNING then
        local actualState, maxStates, steps, max_pathfinder_steps = self.vehicle.ad.pathFinderModule:getCurrentState()
        return "$l10n_AD_task_pathfinding;" .. string.format(" %d / %d - %d / %d", actualState, maxStates, steps, max_pathfinder_steps)
    else
        return "$l10n_AD_task_drive_to_vehicle;"
    end
end
