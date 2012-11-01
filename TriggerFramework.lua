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
			return a or fn(...)
		end
		return function() return fn(unpack(args)) end
	end,
	And = function(...)
		local args = {...}
		local fn = function(a, ...)
			if not a then return false end
			return a and fn(...)
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
