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
