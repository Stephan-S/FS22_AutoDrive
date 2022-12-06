ADCollSensor = ADInheritsFrom(ADSensor)

--[[
https://gdn.giants-software.com/thread.php?categoryId=22&threadId=9694
0: "DEFAULT: The default bit",

# main collisions
1: "STATIC_WORLD: Collision with terrain, terrainHeight and static objects",
3: "STATIC_OBJECTS: Collision with static objects",
5: "AI_BLOCKING: Blocks the AI",
4: "STATIC_OBJECT: A static object",
8: "TERRAIN: Collision with terrain",
9: "TERRAIN_DELTA: Collision with terrain delta",

# identifiers
11: "TREE: A tree",
12: "DYNAMIC_OBJECT: A dynamic object",
13: "VEHICLE: A vehicle",
14: "PLAYER: A player",
15: "BLOCKED_BY_PLAYER: Object that's blocked by a player",
16: "ANIMAL: An animal",
18: "AI_DRIVABLE: AI can drive over this node",
19: "GROUND_TIP_BLOCKING: Bit to block the ground tipping at this position",

# triggers
20: "TRIGGER_PLAYER: A trigger for players",
21: "TRIGGER_VEHICLE: A trigger for vehicles!",
24: "TRIGGER_DYNAMIC_OBJECT: A dynamic object",
25: "TRIGGER_TRAFFIC_VEHICLE_BLOCKING: A trigger that blocks the traffic vehicles",
27: "TRIGGER_FORK: A trigger for fork object mounting",
28: "TRIGGER_ANIMAL: A trigger for animals",

30: "FILLABLE: A fillable node. Used in trailers and unload triggers",

# deprecated
2: "STATIC_WORLD_WITHOUT_DELTA: Deprecated in FS22: Do not use it anymore!",
6: "TRACTOR: Deprecated in FS22: Do not use it anymore!",
7: "COMBINE: Deprecated in FS22: Do not use it anymore!",
22: "TRIGGER_COMBINE: Deprecated in FS22: Do not use it anymore!",
23: "TRIGGER_FILLABLE: Deprecated in FS22: Do not use it anymore!",
26: "TRIGGER_CUTTER: Deprecated in FS22: Do not use it anymore!",
]]

-- ADCollSensor.collisionMask = 239
ADCollSensor.mask_Non_Pushable_1 = 1
ADCollSensor.mask_Non_Pushable_2 = 2
ADCollSensor.mask_static_world_1 = 3
ADCollSensor.mask_static_world_2 = 4
ADCollSensor.mask_tractors = 6
ADCollSensor.mask_combines = 7
ADCollSensor.mask_trailers = 8
-- ADCollSensor.mask_dynamic_objects = 12
-- ADCollSensor.mask_dynamic_objects_machines = 13
-- ADCollSensor.mask_trigger_player = 20
-- ADCollSensor.mask_trigger_tractor = 21
-- ADCollSensor.mask_trigger_combines = 22
-- ADCollSensor.mask_trigger_fillables = 23
-- ADCollSensor.mask_trigger_dynamic_objects = 24
-- ADCollSensor.mask_trigger_trafficVehicles = 25
-- ADCollSensor.mask_trigger_cutters = 26
-- ADCollSensor.mask_kinematic_objects_wo_coll = 30


-- ?? 0:
-- # main collisions
ADCollSensor.mask_STATIC_WORLD = 1
-- 2: "STATIC_WORLD_WITHOUT_DELTA: Deprecated in FS22: Do not use it anymore!",
ADCollSensor.mask_STATIC_OBJECTS = 3
ADCollSensor.mask_STATIC_OBJECT = 4
ADCollSensor.mask_AI_BLOCKING = 5
-- 6: "TRACTOR: Deprecated in FS22: Do not use it anymore!",
-- 7: "COMBINE: Deprecated in FS22: Do not use it anymore!",
ADCollSensor.mask_TERRAIN = 8
ADCollSensor.mask_TERRAIN_DELTA = 9
-- # identifiers
-- ?? 10:
ADCollSensor.mask_TREE = 11
ADCollSensor.mask_DYNAMIC_OBJECT = 12
ADCollSensor.mask_VEHICLE = 13
ADCollSensor.mask_PLAYER = 14
ADCollSensor.mask_BLOCKED_BY_PLAYER = 15
ADCollSensor.mask_ANIMAL = 16
-- ?? 17:
ADCollSensor.mask_AI_DRIVABLE = 18
ADCollSensor.mask_GROUND_TIP_BLOCKING = 19
-- # triggers
ADCollSensor.mask_TRIGGER_PLAYER = 20
ADCollSensor.mask_TRIGGER_VEHICLE = 21
-- 22: "TRIGGER_COMBINE: Deprecated in FS22: Do not use it anymore!",
-- 23: "TRIGGER_FILLABLE: Deprecated in FS22: Do not use it anymore!",
ADCollSensor.mask_TRIGGER_DYNAMIC_OBJECT = 24
ADCollSensor.mask_TRIGGER_TRAFFIC_VEHICLE_BLOCKING = 25
-- 26: "TRIGGER_CUTTER: Deprecated in FS22: Do not use it anymore!",
ADCollSensor.mask_TRIGGER_FORK = 27
ADCollSensor.mask_TRIGGER_ANIMAL = 28
-- ?? 29:
ADCollSensor.mask_FILLABLE = 30

function ADCollSensor:new(vehicle, sensorParameters)
    local o = ADCollSensor:create()
    o:init(vehicle, ADSensor.TYPE_COLLISION, sensorParameters)
    o.hit = false
    o.newHit = false
    o.collisionHits = 0
    o.timeOut = AutoDriveTON:new()
    o.vehicle = vehicle; --test collbox and coll bits mode

    o.mask = ADCollSensor:buildMask()

    return o
end

function ADCollSensor:buildMask()
    if AutoDrive.getSetting("enableTrafficDetection") == 1 then
        return self:buildMask_FS22()
    else
        return self:buildMask_FS19()
    end
end

function ADCollSensor:buildMask_FS22()
    local mask = CollisionFlag.STATIC_WORLD; -- Collision with terrain, terrainHeight and static objects (bit 2)	
	
	mask = mask + CollisionFlag.STATIC_OBJECTS; -- Collision with static objects (bit 3)
	mask = mask + CollisionFlag.STATIC_OBJECT; -- A static object (bit 4)
	mask = mask + CollisionFlag.AI_BLOCKING; -- Blocks the AI (bit 5)
	mask = mask + CollisionFlag.TERRAIN; -- Collision with terrain (bit 8)
	mask = mask + CollisionFlag.TERRAIN_DELTA; -- Collision with terrain delta (bit 9)
	mask = mask + CollisionFlag.TREE; -- A tree (bit 11)
	mask = mask + CollisionFlag.DYNAMIC_OBJECT; -- A dynamic object (bit 12)
	mask = mask + CollisionFlag.VEHICLE; -- A vehicle (bit 13)

    return mask
end

function ADCollSensor:buildMask_FS19()
    local mask = 0

    mask = mask + math.pow(2, ADCollSensor.mask_Non_Pushable_1 - 1)
    mask = mask + math.pow(2, ADCollSensor.mask_Non_Pushable_2 - 1)
    mask = mask + math.pow(2, ADCollSensor.mask_static_world_1 - 1)
    mask = mask + math.pow(2, ADCollSensor.mask_static_world_2 - 1)
    mask = mask + math.pow(2, ADCollSensor.mask_tractors - 1)
    mask = mask + math.pow(2, ADCollSensor.mask_combines - 1)
    mask = mask + math.pow(2, ADCollSensor.mask_trailers - 1)
    --mask = mask + math.pow(2, ADCollSensor.mask_dynamic_objects - 1)
    --mask = mask + math.pow(2, ADCollSensor.mask_dynamic_objects_machines - 1)
    --mask = mask + math.pow(2, ADCollSensor.mask_trigger_trafficVehicles - 1)
    --mask = mask + math.pow(2, ADCollSensor.mask_trigger_dynamic_objects - 1)

    return mask
end

function ADCollSensor:onUpdate(dt)
    self.mask = self:buildMask()
    local box = self:getBoxShape()
    if self.collisionHits == 0 or self.timeOut:timer(true, 20000, dt) then
        self.timeOut:timer(false)
        self.hit = self.newHit
        self:setTriggered(self.hit)
        self.newHit = false

        local offsetCompensation = -math.tan(box.rx) * box.size[3]
		box.y = math.max(getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, box.x, 300, box.z), box.y) + offsetCompensation

        self.collisionHits = overlapBox(box.x, box.y, box.z, box.rx, box.ry, 0, box.size[1], box.size[2], box.size[3], "collisionTestCallback", self, self.mask, true, true, true) --AIVehicleUtil.COLLISION_MASK --16783599

        --for some reason, I have to call this again if collisionHits > 0 to trigger the callback functions, which check if the hit object is me or is attached to me
        if self.collisionHits > 0 then
            overlapBox(box.x, box.y, box.z, box.rx, box.ry, 0, box.size[1], box.size[2], box.size[3], "collisionTestCallback", self, self.mask, true, true, true)
        end
    end 
    
    self:onDrawDebug(box)
end

function ADCollSensor:collisionTestCallback(transformId)
    self.collisionHits = math.max(0, self.collisionHits - 1)
    local unloadDriver = ADHarvestManager:getAssignedUnloader(self.vehicle)
    local collisionObject = g_currentMission.nodeToObject[transformId]
    if collisionObject ~= nil then
        if collisionObject ~= self and collisionObject ~= self.vehicle and not AutoDrive:checkIsConnected(self.vehicle:getRootVehicle(), collisionObject) then
            if unloadDriver == nil or (collisionObject ~= unloadDriver and (not AutoDrive:checkIsConnected(unloadDriver:getRootVehicle(), collisionObject))) then
                self.newHit = true
            end
        end
    else
        self.newHit = true
    end
end
