--
-- Created by IntelliJ IDEA.
-- User: spacewave
-- Date: 08.03.2021
-- Time: 17:25
-- To change this template use File | Settings | File Templates.
--

local loveImage = {
    id = 0,
    min = "",
    mag = ""
}

function loveImage:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.id = o.id or 0
    o.min = o.min or 0
    o.mag = o.mag or 0
    return o
end

function loveImage:setFilter(min, mag)
    local min_number = 0
    local mag_number = 0
    if(min == "nearest") then
        min_number = 0
    end
    if(mag == "nearest") then
        mag_number = 0
    end
	Graphics.setFilter(self.id, min_number, mag_number)
end

function loveImage:toString() 
	return "id: " .. loveImage.id .. "\nmin: " .. loveImage.min .. "\nmag: " .. loveImage.mag
end

return loveImage