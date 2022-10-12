--
-- Created by IntelliJ IDEA.
-- User: spacewave
-- Date: 08.03.2021
-- Time: 16:28
-- To change this template use File | Settings | File Templates.
--

local loveSound = {
	id = 0,
	volume = 0,
	isLooping = false
}

function loveSound:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.id = o.id
	self.volume = o.volume
	self.isLooping = o.isLooping
	return o
end

function loveSound:setVolume (volume)
	self.volume = volume
end

function loveSound:setLooping (isLooping)
	self.isLooping = isLooping
end

function loveSound:toString()
	return "id: " .. loveSound.id .. "\nvolume: " .. loveSound.volume .. "\nisLooping: " .. tostring(loveSound.isLooping)
end

return loveSound