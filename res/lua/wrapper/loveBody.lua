local loveBody = {
    id = 0,
    world = {},
    x = 0,
    y = 0,
    m = 0,
    i = 0,
    ld = 0,
    lvx = 0,
    lvy = 0,
    shapes = {},
    isBullet = false
}

function loveBody:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.id = o.id or 0
    o.world = o.world
    o.x = o.x or 0
    o.y = o.y or 0
    o.m = o.m or 0
    o.i = o.i or 0
    o.shapes = {}
    return o
end

function loveBody:getX()
    return Physics.getX(self.id)
end

function loveBody:getY()
    return Physics.getY(self.id)
end

function loveBody:getAngle()
    return Physics.getAngle(self.id)
end

function loveBody:getMass()
    return Physics.getMass(self.id)
end

function loveBody:setLinearDamping(ld)
    Physics.setLinearDamping(self.id, ld)
    self.ld = ld
end

function loveBody:setMassFromShapes()
    Physics.setMassFromShapes(self.id)
end

function loveBody:addShape(shape)
    table.insert(self.shapes, shape)
end

function loveBody:setBullet(status)
    if(status == true) then
        Physics.setBullet(self.id, 1)
    else
        Physics.setBullet(self.id, 0)
    end
    self.isBullet = status
end

function loveBody:setLinearVelocity(lvx, lvy)
    Physics.setLinearVelocity(self.id, lvx, lvy)
    self.lvx = lvx
    self.lvy = lvy
end

function loveBody:getLinearVelocity()
    local x = Physics.getLinearVelocityX(self.id)
    local y = Physics.getLinearVelocityY(self.id)
    return x, y
end

function loveBody:applyForce(fx, fy, x, y)
    Physics.applyForce(self.id, fx, fy, x, y)
end

function loveBody:getWorldCenter()
    local x = Physics.getWorldCenterX(self.id)
    local y = Physics.getWorldCenterY(self.id)
    return x, y
end

function loveBody:getAngularVelocity()
    return Physics.getAngularVelocity(self.id)
end

function loveBody:setAngularVelocity(angularVelocity)
    return Physics.setAngularVelocity(self.id, angularVelocity)
end

function loveBody:applyTorque(torque)
    Physics.applyTorque(self.id, torque)
end

function loveBody:getLocalPoint(wx, wy)
    local lx, ly = Physics.getLocalPoint(self.id, wx, wy)
    return lx, ly
end

function loveBody:getWorldPoint(lx, ly)
    local wx, wy = Physics.getWorldPoint(self.id, lx, ly)
    return wx, wy
end

function loveBody:destroy()
    Physics.destroyBody(self.id)
end

function loveBody:setAngle(angle)
    Physics.setAngle(self.id, angle)
end

return loveBody