function AutoDrive.getDriverRadius(vehicle, onlyVehicle)
    local minTurnRadius = AIVehicleUtil.getAttachedImplementsMaxTurnRadius(vehicle)

    --if minTurnRadius ~= nil then
      --  print("getAttachedImplementsMaxTurnRadius: " .. minTurnRadius)
    --end

    local maxToolRadius = 0
    for _, implement in pairs(vehicle:getAttachedAIImplements()) do
        maxToolRadius = math.max(maxToolRadius, AIVehicleUtil.getMaxToolRadius(implement))
    end

    --if maxToolRadius ~= nil then
      --  print("getMaxToolRadius: " .. maxToolRadius)
    --end

    minTurnRadius = math.max(minTurnRadius, maxToolRadius)

    if #vehicle:getAttachedAIImplements() > 0 then
        if minTurnRadius <= 5 then
            minTurnRadius = PathFinderModule.PP_CELL_X
            --if minTurnRadius ~= nil then
              --  print("PathFinderModule.PP_CELL_X: " .. PathFinderModule.PP_CELL_X)
            --end
        end
    else
        if vehicle.maxTurningRadius ~= nil then
            minTurnRadius = math.max(minTurnRadius, vehicle.maxTurningRadius)
            if onlyVehicle then
                minTurnRadius = vehicle.maxTurningRadius
            end
            --if maxToolRadius ~= nil then
              --  print("vehicle.maxTurningRadius: " .. vehicle.maxTurningRadius)
            --end
        end
    end

    return minTurnRadius
end

function AutoDrive.boundingBoxFromCorners(cornerX, cornerZ, corner2X, corner2Z, corner3X, corner3Z, corner4X, corner4Z)
    local boundingBox = {}
    boundingBox[1] = {
        x = cornerX,
        y = 0,
        z = cornerZ
    }
    boundingBox[2] = {
        x = corner2X,
        y = 0,
        z = corner2Z
    }
    boundingBox[3] = {
        x = corner3X,
        y = 0,
        z = corner3Z
    }
    boundingBox[4] = {
        x = corner4X,
        y = 0,
        z = corner4Z
    }

    return boundingBox
end

AutoDrive.implementsAllowedForReverseDriving = {
"trailer"
,"trailerlow"
}


function AutoDrive.isImplementAllowedForReverseDriving(vehicle,implement)
-- return true for implements allowed move reverse
    local ret = false

    if implement ~= nil and implement.spec_attachable ~= nil and implement.spec_attachable.attacherJoint ~= nil and implement.spec_attachable.attacherJoint.jointType ~= nil then
        for i, name in ipairs(AutoDrive.implementsAllowedForReverseDriving) do
            local key = "JOINTTYPE_"..string.upper(name)
            
            if AttacherJoints[key] ~= nil and AttacherJoints[key] == implement.spec_attachable.attacherJoint.jointType then
                -- Logging.info("[AD] isImplementAllowedForReverseDriving implement allowed %s ", tostring(key))
                return true
            end
        end
    end

    if implement ~= nil and implement.spec_attachable ~= nil 
        and AttacherJoints.JOINTTYPE_IMPLEMENT == implement.spec_attachable.attacherJoint.jointType 
    then
        local breakforce = implement.spec_attachable:getBrakeForce()
        -- Logging.info("[AD] isImplementAllowedForReverseDriving implement breakforce %s ", tostring(breakforce))
        if breakforce ~= nil and breakforce > 0.07 * 10
            and not (implement ~= nil and implement.getName ~= nil and implement:getName() == "GL 420")     -- Grimme GL 420 needs special handling, as it has breakforce >0.07, but no trailed wheel
        then
            return true
        end
    end

    if implement ~= nil and implement.spec_attachable ~= nil 
        and AttacherJoints.JOINTTYPE_SEMITRAILER == implement.spec_attachable.attacherJoint.jointType 
    then
        local implementX, implementY, implementZ = getWorldTranslation(implement.components[1].node)
        local _, _, diffZ = worldToLocal(vehicle.components[1].node, implementX, implementY, implementZ)
        if diffZ < -3 then
            return true
        end
    end

    return ret
end

