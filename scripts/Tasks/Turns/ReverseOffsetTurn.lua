ReverseOffsetTurn = ADInheritsFrom(AbstractTurn)

ReverseOffsetTurn.MAX_INITIAL_REVERSING_DISTANCE = 18

-- TODO - Handle non rectangular field properly and reverse along fruit edge
function ReverseOffsetTurn:new(turnParameters)
    local o = ReverseOffsetTurn:create()
    o.generationStep = 0
    o.turnGenerated = false
    o.turnParameters = turnParameters
    o.path = {}
    o.task = o.turnParameters.handleHarvesterTask
    o.failed = false
    return o
end

function ReverseOffsetTurn.checkValidity(turnParameters)
    return turnParameters.angle > 165 and turnParameters.angle < 195
end

function ReverseOffsetTurn:update(dt)
    if self.failed then        
        --print("ReverseOffsetTurn:update failed already") 
        return false
    end

    if not self.turnGenerated then
        self:generateTurn()
    end

    if self.turnGenerated then
        return true
    end

    return false
end

function ReverseOffsetTurn:getWayPoints()
    return self.path
end

function ReverseOffsetTurn:generateTurn()
    local vehicle = self.turnParameters.vehicle
    if self.generationStep == 0 then
        self.path = {}
        self.generationStep = 1
    elseif self.generationStep == 1 then        
        local vehX, vehY, vehZ = getWorldTranslation(vehicle.components[1].node)
        local dirX, _, dirZ = localDirectionToWorld(vehicle.components[1].node, 0, 0, -1)
        local reverseNodes = self.task:generateStraight({x=vehX, y=vehY, z=vehZ}, {x=dirX, z=dirZ}, AutoDrive.getTractorTrainLength(vehicle, true, true) + ReverseOffsetTurn.MAX_INITIAL_REVERSING_DISTANCE, true)
        for i, node in pairs(reverseNodes) do
            table.insert(self.path, node)
        end
        self.generationStep = 2
    elseif self.generationStep == 2 then
        local dirX, _, dirZ = localDirectionToWorld(vehicle.components[1].node, 0, 0, 1)
        local startDirZ = {x=dirX, z=dirZ}
        dirX, _, dirZ = localDirectionToWorld(vehicle.components[1].node, 1, 0, 0)
        local startDirX = {x=dirX, z=dirZ}
        local reversedLength = ReverseOffsetTurn.MAX_INITIAL_REVERSING_DISTANCE
        local turnStart = AutoDrive.createWayPointRelativeToVehicle(vehicle, 0, -reversedLength)
        local uturnNodes = self.task:generateUTurn(turnStart, startDirX, startDirZ, self.turnParameters.targetLeft)
        for i, node in pairs(uturnNodes) do
            table.insert(self.path, node)
            self.generationStep = 3
        end
        if uturnNodes == nil or #uturnNodes == 0 then
            self.failed = true
        end
    elseif self.generationStep == 3 then
        local dirX, _, dirZ = localDirectionToWorld(vehicle.components[1].node, 0, 0, -1)
        local straightenTrailerNodes = self.task:generateStraight(self.path[#self.path], {x=dirX, z=dirZ}, (ReverseOffsetTurn.MAX_INITIAL_REVERSING_DISTANCE + AutoDrive.getTractorTrainLength(vehicle, true, true)) * 0.75, false)
        for i, node in pairs(straightenTrailerNodes) do
            table.insert(self.path, node)
        end
        self.generationStep = 4
    elseif self.generationStep == 4 then
        local reverseToCombineSection = self.task:generateReverseToCombineSection(self.targetLeft)
        for i, node in pairs(reverseToCombineSection) do
            table.insert(self.path, node)
        end

        self.generationStep = 5
        self.turnGenerated = true
    end    
end