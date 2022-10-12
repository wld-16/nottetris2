local loveBody = {
    id = 0
}

function loveEnvironment:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.id = o.id or 0
    return o
end

return loveEnvironment