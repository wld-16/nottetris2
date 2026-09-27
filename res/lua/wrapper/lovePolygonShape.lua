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
    self.id = o.id or 0
    self.points = o.points or {}
    self.body = o.body or {}
    return o
end

function lovePolygonShape:setData(v)
    self.data = v
end

function lovePolygonShape:setFriction(friction)
    self.friction = friction
end

return lovePolygonShape