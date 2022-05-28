
--- Connects two waypoints.
---@class ADBrushCurve : ADBrushStraightLine
ADBrushCurve = {
	imageFilename ="textures/input_record_4.dds",
	name = "curve",
	DELAY = 100,
	MIN_OFFSET = -1,
	MAX_OFFSET = 1,
	MIN_CENTER = 0,
	MAX_CENTER = 1,
	START_CENTER = 0.5,
	START_OFFSET = 0,
}
local ADBrushCurve_mt = Class(ADBrushCurve,ADBrushStraightLine)
function ADBrushCurve.new(customMt,cursor)
	local self =  ADBrushStraightLine.new(customMt or ADBrushCurve_mt, cursor)
	self.supportsSecondaryAxis = true
	self.secondaryAxisIsContinuous = true
	self.primaryAxisIsContinuous = true

	self.offset = 0
	self.center = self.START_CENTER
	
	return self
end

--- De-Casteljau algorithm
function ADBrushCurve:getNextPoint(t,points)
	local q0_x, q0_y = (1-t) * points[1][1] + t * points[2][1],
					(1-t) * points[1][2] + t * points[2][2]
	local q1_x, q1_y = (1-t) * points[2][1] + t * points[3][1],
					(1-t) * points[2][2] + t * points[3][2]
	
	return (1-t)*q0_x + t*q1_x, (1-t)*q0_y + t*q1_y
end

function ADBrushCurve:moveWaypoints()
	local x, y, z = self.cursor:getPosition()
	if x == nil then 
		return
	end

	local firstWayPoint = ADGraphManager:getWayPointById(self.sortedWaypoints[1])
	local tx, tz = firstWayPoint.x, firstWayPoint.z

	local dist = MathUtil.vector2Length(x-tx,z-tz)

	--- 0-1
	local dt = 2/dist

	local spacing = 2

	local nx, nz = MathUtil.vector2Normalize(x-tx, z-tz)
	if nx == nil or nz == nil then 
		nx = 0
		nz = 1
	end
	
	local distCenter = dist*self.center

	
	local ax, az = tx + nx * distCenter, tz + nz * distCenter

	--- Rotation
	local ncx = nx  * math.cos(math.pi/2) - nz  * math.sin(math.pi/2)
	local ncz = nx  * math.sin(math.pi/2) + nz  * math.cos(math.pi/2)

	--- Translation
	local cx, cz = ax + ncx * self.offset * dist, az + ncz * self.offset * dist

	local halfDist = MathUtil.vector2Length(cx - tx, cz - tz)

	local n = math.ceil(halfDist/spacing)
	spacing = halfDist/n

	local points = {
		{
			tx,
			tz
		},
		{
			cx,
			cz
		},
		{
			x,
			z
		}
	}

	local dx, dz
	local i = 1
	for t=dt , 1, dt do 
		dx, dz = ADBrushCurve:getNextPoint(t,points)
		self:moveSingleWaypoint(i, dx, y, dz)
		i = i + 1
	end
	self:deleteNotUsedWaypoints(i-1)

end

function ADBrushCurve:onButtonSecondary()
	
end

function ADBrushCurve:onAxisPrimary(inputValue)
	self.offset = MathUtil.clamp(self.offset+inputValue/50,self.MIN_OFFSET,self.MAX_OFFSET)
	self:setInputTextDirty()
end

function ADBrushCurve:onAxisSecondary(inputValue)
	self.center = MathUtil.clamp(self.center+inputValue/50,self.MIN_CENTER,self.MAX_CENTER)
	self:setInputTextDirty()
end


function ADBrushCurve:activate()
	self.waypoints = {}
	self.sortedWaypoints = {}
	ADBrushCurve:superClass().activate(self)
end

function ADBrushCurve:deactivate()
	self.waypoints = {}
	self.sortedWaypoints = {}
	ADBrushCurve:superClass().deactivate(self)
end

function ADBrushCurve:getButtonPrimaryText()
	return self:getTranslation(self.primaryButtonText)
end

function ADBrushCurve:getAxisPrimaryText()
	return self:getTranslation(self.primaryAxisText, self.offset) 
end

function ADBrushCurve:getAxisSecondaryText()
	return self:getTranslation(self.secondaryAxisText, self.center)
end
