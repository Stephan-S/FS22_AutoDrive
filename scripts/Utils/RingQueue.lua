--[[
Provide a ring queue for items with number of items given or default 10000
]]
RingQueue = {}

function RingQueue:new(size)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    if size == nil or size == 0 then
        o.size = 10000
    else
        o.size = size
    end
    o.items = {}
    o.itemsCount = 0
    return o
end

function RingQueue:Enqueue(item)
    if self:Count() > self.size then
        self:Dequeue()
    end
    table.insert(self.items, item)
    self.itemsCount = self.itemsCount + 1
end

function RingQueue:Dequeue()
    if self:Count() > 0 then
        self.itemsCount = self.itemsCount - 1
        return table.remove(self.items, 1)
    end
    return nil
end

function RingQueue:Clear()
    self.items = {}
    self.itemsCount = 0
end

function RingQueue:GetItems()
    return self.items
end

function RingQueue:Count()
    return self.itemsCount
end

function RingQueue:Contains(item)
    return table.contains(self.items, item)
end
