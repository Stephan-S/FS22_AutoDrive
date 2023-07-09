function AutoDrive.getDriverRadius(vehicle, onlyVehicle)
    local minTurnRadius = AIVehicleUtil.getAttachedImplementsMaxTurnRadius(vehicle) -- return -1 or getAITurnRadiusLimitation -> see xml value getAITurnRadiusLimitation

    --if minTurnRadius ~= nil then
      --  print("getAttachedImplementsMaxTurnRadius: " .. minTurnRadius)
    --end

    local maxToolRadius = 0
    if vehicle.getAttachedImplements ~= nil then
        for _, implement in pairs(vehicle:getAttachedImplements()) do
            maxToolRadius = math.max(maxToolRadius, AIVehicleUtil.getMaxToolRadius(implement))
        end
    end

    --if maxToolRadius ~= nil then
      --  print("getMaxToolRadius: " .. maxToolRadius)
    --end

    minTurnRadius = math.max(minTurnRadius, maxToolRadius)

    if  vehicle.getAttachedImplements ~= nil and #vehicle:getAttachedImplements() > 0 then
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

