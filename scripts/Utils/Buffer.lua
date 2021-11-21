Buffer = {}

function Buffer:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.items = {}
    o.itemsCount = 0
    return o
end

function Buffer:Insert(item)
    table.insert(self.items, item)
    self.itemsCount = self.itemsCount + 1
end

function Buffer:InsertItems(items)
    for _, item in pairs(items) do
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
