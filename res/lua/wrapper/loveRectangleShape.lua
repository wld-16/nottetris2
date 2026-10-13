local loveRectangleShape = {
    id = 0,
    body = 0,
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    angle = 0,
    data = {}
}

function loveRectangleShape:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.id = o.id or 0
    o.body = o.body or {}
    o.body:addShape(o)
    o.x = o.x or 0
    o.y = o.y or 0
    o.width = o.width or 0
    o.height = o.height or 0
    o.angle = o.angle or 0
    return o
end

function loveRectangleShape:setData(v)
    self.data = v
    Physics.setShapeData(self.id, v)
end

function loveRectangleShape:getWidth()
    return self.width
end

function loveRectangleShape:getHeight()
    return self.height
end

function loveRectangleShape:getPoints()
    local numbers = Physics.getPoints(self.id)
    return unpack(numbers)
end

function loveRectangleShape:testSegment( x1, y1, x2, y2)
    return Physics.testSegment(self.id, x1, y1, x2, y2)
end

function loveRectangleShape:destroy()
    Physics.destroyShape(self.id)
end

function loveRectangleShape:testPoint(x, y)
    return Physics.testPoint(self.id, x, y)
end

function loveRectangleShape:setDensity(density)
    Physics.setDensity(self.id, density)
end

function loveRectangleShape:getId()
    return self.id
end

return loveRectangleShape