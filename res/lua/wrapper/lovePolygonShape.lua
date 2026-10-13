local lovePolygonShape = {
    id = 0,
    body = {},
    points = {},
    data = {},
    friction = 0
}

function lovePolygonShape:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.id = o.id or 0
    o.points = o.points or {}
    o.body = o.body or {}
    o.body:addShape(o)
    return o
end

function lovePolygonShape:setData(v)
    self.data = v
    Physics.setShapeData(self.id, v)
end

function lovePolygonShape:setFriction(friction)
    Physics.setFriction(self.id, friction)
    self.friction = friction
end

function lovePolygonShape:getPoints()
    local numbers = Physics.getPoints(self.id)
    return unpack(numbers)
end

function lovePolygonShape:testSegment( x1, y1, x2, y2)
    return Physics.testSegment(self.id, x1, y1, x2, y2)
end

function lovePolygonShape:destroy()
    Physics.destroyShape(self.id)
end

function lovePolygonShape:testPoint(x, y)
    return Physics.testPoint(self.id, x, y)
end

function lovePolygonShape:setDensity(density)
    Physics.setDensity(self.id, density)
end

function lovePolygonShape:getId()
    return self.id
end

return lovePolygonShape