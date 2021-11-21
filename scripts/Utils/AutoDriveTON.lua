AutoDriveTON = {}

function AutoDriveTON:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.elapsedTime = 0
    o.time = 0
    return o
end

function AutoDriveTON:timer(signal, time, dt)
    if time ~= nil then
        self.time = time
    end
    if dt ~= nil then
        self.elapsedTime = self.elapsedTime + dt
    end
    if signal then
        return self.elapsedTime > self.time
    else
        self.elapsedTime = 0
    end
    return false
end

function AutoDriveTON:done()
    return self.elapsedTime > self.time
end
