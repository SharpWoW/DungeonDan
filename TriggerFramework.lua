--[[
	* Copyright (c) 2012 by Adam Hellberg <private@f16gaming.com> and Bjørn Tore Håvie <itsbth@itsbth.com>
	*
	* Permission is hereby granted, free of charge, to any person obtaining a copy of
	* this software and associated documentation files (the "Software"), to deal in
	* the Software without restriction, including without limitation the rights to use,
	* copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
	* the Software, and to permit persons to whom the Software is furnished to do so,
	* subject to the following conditions:
	* 
	* The above copyright notice and this permission notice shall be included in all
	* copies or substantial portions of the Software.
	* 
	* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
	* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR
	* A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
	* COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
	* IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
	* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

local Name, T = ...

T.TriggerFramework = {}

local F = T.TriggerFramework

local Comparison = {
	ge = function(a, b) return a >= b end,
	le = function(a, b) return a <= b end,
	gt = function(a, b) return a > b end,
	lt = function(a, b) return a < b end,
	eq = function(a, b) return a == b end
}

F.Logic = {
	Or = function(...)
		local args = {...}
		local fn = function(a, ...)
			if not a then return false end
			return a() or fn(...)
		end
		return function() return fn(unpack(args)) end
	end,
	And = function(...)
		local args = {...}
		local fn = function(a, ...)
			if not a then return false end
			return a() and fn(...)
		end
		return function() return fn(unpack(args)) end
	end,
	Not = function(cond)
		return function() return not cond() end
	end
}

F.Player = {
	Class = function(arg)
		local classes = type(arg) == "table" and arg or {arg}
		return function()
			for _,v in pairs(classes) do
				if UnitClass("player") == v then return true end
			end
			return false
		end
	end,
	Level = function(arg)
		return function()
			local pLvl = UnitLevel("player")
			if type(arg) == "number" then return pLvl == arg end
			for o, n in pairs(arg) do
				if not Comparison[o](n, pLvl) then return false end
			end
			return true
		end
	end,
	Race = function(arg)
		local races = type(arg) == "table" and arg or {arg}
		return function()
			local race = UnitRace("player")
			for _,v in pairs(races) do
				if v == race then return true end
			end
			return false
		end
	end
}

F.World = {
	MapID = function(id)
		return function()
			return id == GetCurrentMapAreaID()
		end
	end
}
