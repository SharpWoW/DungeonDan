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
	if not Dan then
		self:CreateDan()

		Dan = self.Dan
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
