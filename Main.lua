local Name, T = ...

T.Name = Name
T.Version = GetAddOnMetadata(Name, "Version")

local Dan = nil

function T:OnLoad()
	self:LoadSavedVars()
	self.Loaded = true

	if self.Settings.Debug then
		DungeonDanDebug = self
	end
end

function T:LoadSavedVars()
	if type(_G.DUNGEONDAN) ~= "table" then
		_G.DUNGEONDAN = {}
	end

	self.Global = _G.DUNGEONDAN

	if type(self.Global.Settings) ~= "table" then
		self.Global.Settings = {}
	end

	self.Settings = self.Global.Settings

	if type(self.Settings.Debug) ~= "boolean" then
		self.Settings.Debug = false
	end
end

function T.Events.ADDON_LOADED(self, event, ...)
	if (select(1, ...)) == Name then
		self:OnLoad()
	end
end

function T.Events.PLAYER_ENTERING_WORLD(self, event, ...)
	if Dan then return end
	self:CreateDan()

	Dan = self.Dan

	local f = CreateFrame("Frame")
	f.t = 0
	f:SetScript("OnUpdate", function(s,e)
		s.t = s.t + e
		if s.t >= 2 then
			s:SetScript("OnUpdate", nil)
			Dan:ResetModelSettings()
			Dan:DoAction(Dan.Actions.Welcome, true)
		end
	end)

	-- Register callbacks on boss mod, if any

	local function bossKill()
		Dan:DoAction(Dan.Actions.BossKill)
	end

	local function bossWipe()
		Dan:DoAction(Dan.Actions.BossWipe)
	end

	if DBM then
		DBM:RegisterCallback("kill", bossKill)
		DBM:RegisterCallback("wipe", bossWipe)
	elseif DXE then
		DXE.RegisterCallback(T, "DXECallback", bossKill)
	elseif BigWigs then
		T.Events.CHAT_MSG_ADDON = function(s, e, prefix, message, type, sender)
			if prefix ~= "BigWigs" then return end
			local sync, rest = select(3, message:find("(%S+)%s*(.*)$"))
			if sync ~= "Death" then return end
			bossKill()
		end
	else -- LibBossIDs
		local lib = LibStub:GetLibrary("LibBossIDs-1.0", true)
		T.Events.COMBAT_LOG_EVENT_UNFILTERED = function(s, e, ...)
			local _, event = ...
			if event ~= "PARTY_KILL" then return end
			local id = tonumber((select(8, ...)):sub(6, 10), 16)
			if lib.BossIDs[id] then bossKill() end
		end
	end
end

function T.Events.LFG_PROPOSAL_SHOW(self, event, ...)
	Dan:DoAction(Dan.Actions.DungeonReady, true)
end

function T.Events.LFG_PROPOSAL_FAILED(self, event, ...)
	Dan:StopAction()
end

function T.Events.LFG_PROPOSAL_SUCCEEDED(self, event, ...)
	Dan:StopAction()
end

local validEvents = {
	"SPELL_DAMAGE",
	"SPELL_PERIODIC_DAMAGE",
	"SPELL_BUILDING_DAMAGE",
	"RANGE_DAMAGE"
}

local function IsValidEvent(event)
	for _,v in pairs(validEvents) do
		if event == v then return true end
	end
	return false
end

function T.Events.COMBAT_LOG_EVENT_UNFILTERED(self, event, ...)
	local _, event, _, _, _, _, _, _, destName = ...
	if destName ~= UnitName("player") then return end
	if IsValidEvent(event) then
		local id = (select(12, ...))
		if self.AoeSpells[tostring(id)] then Dan:DoAction(Dan.Actions.AoeDamage) end
	end
end
