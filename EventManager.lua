local _, T = ...

if T.Events then return end

T.Events = {}

local _events = {}

local frame = CreateFrame("Frame")

local function Handle(event, ...)
	if type(_events[event]) == "table" then
		for _, v in pairs(_events[event]) do
			if type(v) == "function" then
				v(T, event, ...)
			end
		end
	end
end

local function Register(event, func)
	if type(_events[event]) ~= "table" then
		_events[event] = {}
	end
	_events[event][#_events[event] + 1] = func
	if frame:IsEventRegistered(event) then return end
	frame:RegisterEvent(event)
end

local function Unregister(event)
	if type(_events[event]) == "table" then
		for i,_ in ipairs(_events[event]) do
			_events[event][i] = nil
		end
		_events[event] = nil
	end
	if not frame:IsEventRegistered(event) then return end
	frame:UnregisterEvent(event)
end

local mt = {}
__index = function(t, k) error("Events table is write-only", 2) end
mt.__newindex = function(t, k, v)
	if type(v) == "function" then
		Register(k, v)
	else
		Unregister(k)
	end
end
mt.__metatable = "Nope"

T.Events = setmetatable({}, mt)

frame:SetScript("OnEvent", function(s, e, ...) Handle(e, ...) end)
