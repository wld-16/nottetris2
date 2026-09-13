--
-- Created by IntelliJ IDEA.
-- User: spacewave
-- Date: 08.03.2021
-- Time: 17:25
-- To change this template use File | Settings | File Templates.
--

local loveImage = {
    id = 0,
    filterHeigth = "",
    filterWidth = ""
}

function loveImage:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.id = o.id or 0
    self.filterHeigth = o.filterHeigth or 0
    self.filterWidth = o.filterWidth or 0
    return o
end

function loveImage:setFilter (filterWidth, filterHeigth)
	self.filterWidth = filterWidth
	self.filterHeigth = filterHeigth
end

function loveImage:toString() 
	return "id: " .. loveImage.id .. "\nfilterHeigth: " .. loveImage.filterHeigth .. "\nfilterWidth: " .. loveImage.filterWidth
end

return loveImage