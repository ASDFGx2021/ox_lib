if not _VERSION:find('5.4') then
	error('^1Lua 5.4 must be enabled in the resource manifest!^0', 3)
end

-----------------------------------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------------------------------

-- env
local lualib = 'ox_lib'

-- micro-optimise
local LoadResourceFile = LoadResourceFile
local file = IsDuplicityVersion() and 'server' or 'client'
local rawset = rawset
local rawget = rawget

local function loadModule(self, module)
	local dir = ('imports/%s'):format(module)
	local chunk = LoadResourceFile(lualib, ('%s/%s.lua'):format(dir, file))
	local shared = LoadResourceFile(lualib, ('%s/shared.lua'):format(dir))

	if shared then
		chunk = (chunk and ('%s\n%s'):format(shared, chunk)) or shared
	end

	if chunk then
		local err
		chunk, err = load(chunk, ('@@ox_lib/%s/%s.lua'):format(module, file))
		if err then
			error(('\n^1Error importing module (%s): %s^0'):format(dir, err), 3)
		else
			rawset(self, module, chunk())
			return self[module]
		end
	end
end

-----------------------------------------------------------------------------------------------
-- API
-----------------------------------------------------------------------------------------------

local function call(self, index, ...)
	local module = rawget(self, index)
	if not module then
		module = loadModule(self, index)

		if not module then
			local function method(...)
				return exports[lualib][index](nil, ...)
			end

			if not ... then
				rawset(self, index, method)
			end

			return method
		end
	end

	return module
end

lib = setmetatable({
	exports = {},
}, {
	__index = call,
	__call = call,

	__newindex = function()
		error('Cannot set index on lib')
	end,

	__tostring = function()
		return lualib
	end,
})
import = lib

local intervals = {}
--- Dream of a world where this PR gets accepted.
---@param callback function
---@param interval? number
---@param ... any
function SetInterval(callback, interval, ...)
	interval = interval or 0
	assert(type(interval) == 'number', ('Interval must be a number. Received %s'):format(json.encode(interval)))
	local cbType = type(callback)

	if cbType == 'number' and intervals[callback] then
		intervals[callback] = interval or 0
		return
	end

	assert(cbType == 'function', ('Callback must be a function. Received %s'):format(tostring(cbType)))
	local id
	local args = {...}

	Citizen.CreateThreadNow(function(ref)
		id = ref
		intervals[id] = interval or 0
		repeat
			interval = intervals[id]
			Wait(interval)
			callback(table.unpack(args))
		until interval < 0
		intervals[id] = nil
	end)

	return id
end

function ClearInterval(id)
	assert(type(id) == 'number', ('Interval id must be a number. Received %s'):format(json.encode(id)))
	assert(intervals[id], ('No interval exists with id %s'):format(id))
	intervals[id] = -1
end

-- ox_lib
-- Copyright (C) 2021	Linden <https://github.com/thelindat>

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <https://www.gnu.org/licenses/gpl-3.0.html>
