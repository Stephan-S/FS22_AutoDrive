function AutoDrive:checkForVehicleCollision(vehicle,boundingBox, excludedVehicles)
    if excludedVehicles == nil then
        excludedVehicles = {}
    end
    table.insert(excludedVehicles, vehicle)
    return AutoDrive.checkForVehiclesInBox(boundingBox, excludedVehicles)
end

function AutoDrive.checkForVehiclesInBox(boundingBox, excludedVehicles)
    for _, otherVehicle in pairs(g_currentMission.vehicles) do
        local isExcluded = false
        if excludedVehicles ~= nil and otherVehicle ~= nil then
            for _, excludedVehicle in pairs(excludedVehicles) do
                if excludedVehicle == otherVehicle or AutoDrive:checkIsConnected(excludedVehicle, otherVehicle) then
                    isExcluded = true
                end
            end
        end

        if (not isExcluded) and otherVehicle ~= nil and otherVehicle.components ~= nil and otherVehicle.size.width ~= nil and otherVehicle.size.length ~= nil and otherVehicle.rootNode ~= nil then
            local x, _, z = getWorldTranslation(otherVehicle.components[1].node)
            local distance = MathUtil.vector2Length(boundingBox[1].x - x, boundingBox[1].z - z)
            if distance < 50 then
                if AutoDrive.boxesIntersect(boundingBox, AutoDrive.getBoundingBoxForVehicle(otherVehicle)) == true then
                    return true
                end
            end
        end
    end

    return false
end

function AutoDrive.checkForVehiclePathInBox(boundingBox, minTurnRadius, searchingVehicle, currentVec)
    for _, otherVehicle in pairs(g_currentMission.vehicles) do
        if otherVehicle ~= nil and otherVehicle ~= searchingVehicle and otherVehicle.components ~= nil and otherVehicle.size.width ~= nil and otherVehicle.size.length ~= nil and otherVehicle.rootNode ~= nil then                            
            if minTurnRadius ~= nil and otherVehicle.ad ~= nil and otherVehicle.ad.drivePathModule ~= nil and otherVehicle.ad.stateModule:isActive() then
                local otherWPs, otherCurrentWp = otherVehicle.ad.drivePathModule:getWayPoints()
                local lastWp = nil
                -- check for other pathfinder steered vehicles and avoid any intersection with their routes
                if otherWPs ~= nil and otherWPs[otherCurrentWp] ~= nil and otherWPs[otherCurrentWp].isPathFinderPoint then
                    for index, wp in pairs(otherWPs) do
                        if lastWp ~= nil and wp.id == nil and index >= otherCurrentWp and wp.isPathFinderPoint and index > 2 and index < (#otherWPs - 5) then
                            local widthOfColBox = minTurnRadius
                            local sideLength = widthOfColBox / 1.66

                            local vectorX = lastWp.x - wp.x
                            local vectorZ = lastWp.z - wp.z
                            local angleRad = math.atan2(-vectorZ, vectorX)
                            angleRad = AutoDrive.normalizeAngle(angleRad)
                            local length = math.sqrt(math.pow(vectorX, 2) + math.pow(vectorZ, 2)) + widthOfColBox

                            local leftAngle = AutoDrive.normalizeAngle(angleRad + math.rad(-90))
                            local rightAngle = AutoDrive.normalizeAngle(angleRad + math.rad(90))

                            local cornerX = wp.x - math.cos(leftAngle) * sideLength
                            local cornerZ = wp.z + math.sin(leftAngle) * sideLength

                            local corner2X = lastWp.x - math.cos(leftAngle) * sideLength
                            local corner2Z = lastWp.z + math.sin(leftAngle) * sideLength

                            local corner3X = lastWp.x - math.cos(rightAngle) * sideLength
                            local corner3Z = lastWp.z + math.sin(rightAngle) * sideLength

                            local corner4X = wp.x - math.cos(rightAngle) * sideLength
                            local corner4Z = wp.z + math.sin(rightAngle) * sideLength
                            local cellBox = AutoDrive.boundingBoxFromCorners(cornerX, cornerZ, corner2X, corner2Z, corner3X, corner3Z, corner4X, corner4Z)

                            local anglesSimilar = false
                            if currentVec ~= nil then
                                local dirVec = { x=vectorX, z = vectorZ}
                                local angleBetween = AutoDrive.angleBetween(dirVec, currentVec)
                                anglesSimilar = math.abs(angleBetween) < 20 or math.abs(angleBetween) > 160
                            end

                            if AutoDrive.boxesIntersect(boundingBox, cellBox) == true and anglesSimilar then
                                return true
                            end
                        end
                        lastWp = wp
                    end
                end
            end
        end
    end

    return false
end

function AutoDrive.getBoundingBoxForVehicleAtPosition(vehicle, position)
    local x, y, z = position.x, position.y, position.z
    local rx, _, rz = localDirectionToWorld(vehicle.components[1].node, 0, 0, 1)
    local width = vehicle.size.width
    local length = vehicle.size.length
    local frontToolLength = 0 --AutoDrive.getFrontToolLength(vehicle)
    local vehicleVector = {x = rx, z = rz}
    local ortho = {x = -vehicleVector.z, z = vehicleVector.x}

    local boundingBox = {}
    boundingBox[1] = {
        x = x + (width / 2) * ortho.x - (length / 2) * vehicleVector.x,
        y = y + 2,
        z = z + (width / 2) * ortho.z - (length / 2) * vehicleVector.z
    }
    boundingBox[2] = {
        x = x - (width / 2) * ortho.x - (length / 2) * vehicleVector.x,
        y = y + 2,
        z = z - (width / 2) * ortho.z - (length / 2) * vehicleVector.z
    }
    boundingBox[3] = {
        x = x - (width / 2) * ortho.x + (length / 2) * vehicleVector.x,
        y = y + 2,
        z = z - (width / 2) * ortho.z + (length / 2) * vehicleVector.z
    }
    boundingBox[4] = {
        x = x + (width / 2) * ortho.x + (length / 2) * vehicleVector.x,
        y = y + 2,
        z = z + (width / 2) * ortho.z + (length / 2) * vehicleVector.z
    }

    --ADDrawingManager:addLineTask(boundingBox[1].x, boundingBox[1].y, boundingBox[1].z, boundingBox[2].x, boundingBox[2].y, boundingBox[2].z, 1, 1, 0)
    --ADDrawingManager:addLineTask(boundingBox[2].x, boundingBox[2].y, boundingBox[2].z, boundingBox[3].x, boundingBox[3].y, boundingBox[3].z, 1, 1, 0)
    --ADDrawingManager:addLineTask(boundingBox[3].x, boundingBox[3].y, boundingBox[3].z, boundingBox[4].x, boundingBox[4].y, boundingBox[4].z, 1, 1, 0)
    --ADDrawingManager:addLineTask(boundingBox[4].x, boundingBox[4].y, boundingBox[4].z, boundingBox[1].x, boundingBox[1].y, boundingBox[1].z, 1, 1, 0)

    return boundingBox
end

function AutoDrive.getBoundingBoxForVehicle(vehicle)
    local x, y, z = getWorldTranslation(vehicle.components[1].node)

    local position = {x = x, y = y, z = z}

    return AutoDrive.getBoundingBoxForVehicleAtPosition(vehicle, position)
end

function AutoDrive.getDistanceBetween(vehicleOne, vehicleTwo)
    local x1, _, z1 = getWorldTranslation(vehicleOne.components[1].node)
    local x2, _, z2 = getWorldTranslation(vehicleTwo.components[1].node)

    return math.sqrt(math.pow(x2 - x1, 2) + math.pow(z2 - z1, 2))
end

function AutoDrive.debugDrawBoundingBoxForVehicles()
    local vehicle = g_currentMission.controlledVehicle
    if vehicle ~= nil and vehicle.getIsEntered ~= nil and vehicle:getIsEntered() then
        local PosX, _, PosZ = getWorldTranslation(vehicle.components[1].node)
        local maxDistance = AutoDrive.drawDistance
        for _, otherVehicle in pairs(g_currentMission.vehicles) do
            if otherVehicle ~= nil and otherVehicle.components ~= nil and otherVehicle.components[1].node ~= nil and otherVehicle.size.width ~= nil and otherVehicle.size.length ~= nil and otherVehicle.rootNode ~= nil then
                local x, _, z = getWorldTranslation(otherVehicle.components[1].node)
                local distance = MathUtil.vector2Length(PosX - x, PosZ - z)
                if distance < maxDistance then
                    local boundingBox = AutoDrive.getBoundingBoxForVehicle(otherVehicle)
                    ADDrawingManager:addLineTask(boundingBox[1].x, boundingBox[1].y, boundingBox[1].z, boundingBox[2].x, boundingBox[2].y, boundingBox[2].z, 1, 1, 0)
                    ADDrawingManager:addLineTask(boundingBox[2].x, boundingBox[2].y, boundingBox[2].z, boundingBox[3].x, boundingBox[3].y, boundingBox[3].z, 1, 1, 0)
                    ADDrawingManager:addLineTask(boundingBox[3].x, boundingBox[3].y, boundingBox[3].z, boundingBox[4].x, boundingBox[4].y, boundingBox[4].z, 1, 1, 0)
                    ADDrawingManager:addLineTask(boundingBox[4].x, boundingBox[4].y, boundingBox[4].z, boundingBox[1].x, boundingBox[1].y, boundingBox[1].z, 1, 1, 0)
                end
            end
        end
    end
end
