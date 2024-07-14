Buffer = {}

function Buffer:new(maxSize)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.items = {}
    o.itemsCount = 0
    if maxSize == nil or maxSize == 0 then
        o.maxSize = 10000
    else
        o.maxSize = maxSize
    end
    return o
end

function Buffer:Insert(item)
    if self.itemsCount == self.maxSize then
        table.remove(self.items, 1)
        self.itemsCount = self.itemsCount - 1
    end

    table.insert(self.items, item)
    self.itemsCount = self.itemsCount + 1
end

function Buffer:InsertItems(items)
    for _, item in pairs(items) do
        if self.itemsCount == self.maxSize then
            table.remove(self.items, 1)
            self.itemsCount = self.itemsCount - 1
        end
        table.insert(self.items, item)
        self.itemsCount = self.itemsCount + 1
    end
end

function Buffer:Get()
    if self:Count() > 0 then
        self.itemsCount = self.itemsCount - 1
        return table.remove(self.items)
    end
end

function Buffer:Peek()
    if self:Count() > 0 then
        return self.items[table.maxn(self.items)]
    end
end

function Buffer:PeekAhead(steps)
    if self:Count() > 0 then
        return self.items[self.itemsCount - steps]
    end
end

function Buffer:Clear()
    self.items = {}
    self.itemsCount = 0
end

function Buffer:GetAll()
    return self.items
end

function Buffer:Count()
    return self.itemsCount
end

function Buffer:Contains(item)
    return table.contains(self.items, item)
end
