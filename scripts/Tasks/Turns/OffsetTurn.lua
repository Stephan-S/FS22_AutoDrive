OffsetTurn = ADInheritsFrom(AbstractTurn)

OffsetTurn.MAX_STRAIGHTENING_DISTANCE = 18

function OffsetTurn:new(turnParameters)
    local o = OffsetTurn:create()
    o.generationStep = 0
    o.turnGenerated = false
    o.turnParameters = turnParameters
    o.path = {}
    o.task = o.turnParameters.handleHarvesterTask
    o.failed = false
    return o
end

function OffsetTurn.checkValidity(turnParameters)
    return turnParameters.angle > 165 and turnParameters.angle < 195
end

function OffsetTurn:update(dt)
    if self.failed then
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

function OffsetTurn:getWayPoints()
    return self.path
end

function OffsetTurn:generateTurn()
    local vehicle = self.turnParameters.vehicle
    if self.generationStep == 0 then
        self.path = {}
        self.generationStep = self.generationStep + 1
    elseif self.generationStep == 1 then
        local uturnNodes = self.task:generateUTurn(self.turnParameters.startPosition, self.turnParameters.startDir.x, self.turnParameters.startDir.z, self.turnParameters.targetLeft)
        for i, node in pairs(uturnNodes) do
            table.insert(self.path, node)
        end
        self.generationStep = self.generationStep + 1
        if uturnNodes == nil or #uturnNodes == 0 then
            self.failed = true
        end
    elseif self.generationStep == 2 then
        local dirX, _, dirZ = localDirectionToWorld(vehicle.components[1].node, 0, 0, -1)
        local straightenTrailerNodes = self.task:generateStraight(self.path[#self.path], {x=dirX, z=dirZ}, (OffsetTurn.MAX_STRAIGHTENING_DISTANCE + AutoDrive.getTractorTrainLength(vehicle, true, true)) * 0.75, false)
        for i, node in pairs(straightenTrailerNodes) do
            table.insert(self.path, node)
        end
        self.generationStep = self.generationStep + 1
    elseif self.generationStep == 3 then
        local reverseToCombineSection = self.task:generateReverseToCombineSection(self.targetLeft)
        for i, node in pairs(reverseToCombineSection) do
            table.insert(self.path, node)
        end

        self.generationStep = self.generationStep + 1
        self.turnGenerated = true
    end    
end