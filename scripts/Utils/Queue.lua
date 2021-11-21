Queue = {}

function Queue:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.items = {}
    o.itemsCount = 0
    return o
end

function Queue:Enqueue(item)
    table.insert(self.items, item)
    self.itemsCount = self.itemsCount + 1
end

function Queue:Dequeue()
    if self:Count() > 0 then
        self.itemsCount = self.itemsCount - 1
        return table.remove(self.items, 1)
    end
    return nil
end

function Queue:Peek()
    if self:Count() > 0 then
        self.itemsCount = self.itemsCount - 1
        return self.items[1]
    end
    return nil
end

function Queue:Clear()
    self.items = {}
    self.itemsCount = 0
end

function Queue:GetItems()
    return self.items
end

function Queue:Count()
    return self.itemsCount
end

function Queue:Contains(item)
    return table.contains(self.items, item)
end
