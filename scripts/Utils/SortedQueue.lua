SortedQueue = {}

function SortedQueue:new(sortAttribute)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.items = {}
    o.itemsCount = 0
    o.sortAttribute = sortAttribute
    return o
end
--[[
function SortedQueue:enqueue(item)
    table.insert(self.items, item)

    local sort_func = function(a, b)
        return a[self.sortAttribute] < b[self.sortAttribute]
    end

    table.sort(self.items, sort_func)
    self.itemsCount = self.itemsCount + 1
end
--]]

function SortedQueue:dequeue()
    if self:count() > 0 then
        self.itemsCount = self.itemsCount - 1
        return table.remove(self.items, 1)
    end
    return nil
end

function SortedQueue:peek()
    if self:Count() > 0 then
        self.itemsCount = self.itemsCount - 1
        return self.items[1]
    end
    return nil
end

function SortedQueue:clear()
    self.items = {}
    self.itemsCount = 0
end

function SortedQueue:count()
    return self.itemsCount
end

function SortedQueue:empty()
    return self.itemsCount == 0
end

-- Avoid heap allocs for performance

function SortedQueue:enqueue(value)
    -- Initialise compare function
    local fcomp = function( a,b ) return a.distance < b.distance end
    --  Initialise numbers
    local iStart,iEnd,iMid,iState = 1,#self.items,1,0
    -- Get insert position
    while iStart <= iEnd do
        -- calculate middle
        iMid = math.floor( (iStart+iEnd)/2 )
        -- compare
        if fcomp( value,self.items[iMid] ) then
            iEnd,iState = iMid - 1,0
        else
            iStart,iState = iMid + 1,1
        end
    end
    table.insert(self.items,(iMid+iState),value )
    self.itemsCount = self.itemsCount + 1
    return (iMid+iState)
end