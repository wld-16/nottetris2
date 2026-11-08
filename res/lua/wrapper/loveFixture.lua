local loveFixture = {
    id = 0,
    body = {},
    shape = {},
    data = "",
    friction = 0.0
}

function loveFixture:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.id = o.id or 0
    o.body = o.body or {}
    o.shape = o.shape or {}
    return o
end

function loveFixture:setUserData(data)
    self.data = data
    Physics.setShapeData(self.id, data)
end

function loveFixture:setFriction(friction)
    Physics.setFriction(self.id, friction)
end

function loveFixture:getUserData()
    return Physics.getShapeData(self.id)
end

return loveFixture