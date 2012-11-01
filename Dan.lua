local Name, T = ...

if T.Dan then return end

T.Dan = {
	Actions = {
		DungeonReady = 0,
		QueueDamage = 1,
		QueueHealer = 2,
		QueueTank = 3,
		QueueTalk = 4,
		AoeDamage = 5,
		DungeonFinish = 6,
		BossKill = 7,
		PlayerDeath = 8,
		GroupDeath = 9,
		LootNinja = 10, -- Player needed on loot that isn't appropriate for them
		LootWin = 11, -- Player needed and won on loot that is appropriate for them
		LootLose = 12 -- Player needed and lost on loot that is appropriate for them
	}
}

local Dan = {
	Initialized = false,
	DefaultDisplayID = 1541,
	DefaultZoom = 0.7,
	DefaultFacing = -0.2,
	SoundFolder = "Interface\\AddOns\\" .. Name .. "\\Sounds\\",
	Actions = T.Dan.Actions,
	Animations = {
		Idle = 0,
		Talk = 60,
		Question = 65,
		Yell = 81,
		Gasp = 64,
		Cheer = 68,
		Roar = 74,
		Shout = 55,
		Laugh = 70,
		Dance = 69,
		Point = 84,
		Wave = 67,
		Bow = 66,
		Rude = 73,
		Eat = 61,
		Kiss = 76,
		Cry = 77,
		Chicken = 78,
		Beg = 79,
		Clap = 80,
		Flex = 82,
		Shy = 83,
		Spin = 126
	},
	PlayingSound = false,
	LastSound = {},
	Sequence = {
		Running = false,
		Time = 0,
		Target = 0,
		DefaultDelay = 5,
		Timer = nil,
		Action = nil,
		Index = nil,
	}
}

Dan.DefaultAnimation = Dan.Animations.Idle

Dan.Sounds = {
	[Dan.Actions.DungeonReady] = {
		Master = true,
		{"VO_DUNGEON_READY_1", 2},
		{"VO_DUNGEON_READY_2", 2},
		{"VO_DUNGEON_READY_3", 2},
		{"VO_DUNGEON_READY_4", 2}
	},
	[Dan.Actions.AoeDamage] = {
		{"VO_AOE_1", 3},
		{"VO_AOE_2", 2},
		{"VO_AOE_3", 2},
		{"VO_AOE_4", 2}
	}
}

Dan.Sequences = {
	[Dan.Actions.DungeonReady] = {
		[1] = {
			Time = 0,
			Animation = Dan.Animations.Gasp,
			Sound = true,
			Repeating = true
		}
	},
	[Dan.Actions.AoeDamage] = {
		[1] = {
			Time = 0,
			Animation = Dan.Animations.Gasp,
			Sound = true
		}
	}
}

local function FormatSoundPath(name)
	return ("%s%s%s"):format(Dan.SoundFolder, name, ".ogg")
end

function Dan:GetSound(action)
	local i = math.random(1, #self.Sounds[action])

	if #self.Sounds[action] == 1 then
		return self.Sounds[action][i][1], self.Sounds[action][i][2], self.Sounds[action].Master
	end

	while i == self.LastSound[action] do
		i = math.random(1, #self.Sounds[action])
	end

	self.LastSound[action] = i
	return self.Sounds[action][i][1], self.Sounds[action][i][2], self.Sounds[action].Master
end

local SoundCooldownFrame = CreateFrame("Frame")

function Dan:PlaySound(file, master, override)
	override = override or master
	if self.PlayingSound and not override then return end

	local duration
	if type(file) == "number" then
		file, duration, master = self:GetSound(file)
	end

	PlaySoundFile(FormatSoundPath(file), master and "Master" or nil)

	if duration then
		self.PlayingSound = true
		SoundCooldownFrame.t = 0
		SoundCooldownFrame:SetScript("OnUpdate", function(f, e)
			f.t = f.t + e
			if f.t >= duration then
				f:SetScript("OnUpdate", nil)
				Dan.PlayingSound = false
			end
		end)
	end
	return duration
end

local FrameBackdrop = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	edgeSize = 16,
	tileSize = 32,
	insets = {
		left = 2.5,
		right = 2.5,
		top = 2.5,
		bottom = 2.5
	}
}

function Dan:Init()
	if self.Frame then return end

	-- Create container frame
	self.Frame = CreateFrame("Frame", nil, UIParent)
	local frame = self.Frame
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetSize(250, 250)
	frame:SetBackdrop(FrameBackdrop)
	frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -100)

	frame:SetScript("OnMouseDown", function(f) f:StartMoving() end)
	frame:SetScript("OnMouseUp", function(f) f:StopMovingOrSizing() end)

	frame.Model = CreateFrame("PlayerModel", nil, frame)
	local model = frame.Model
	model:EnableMouse(false)
	model:SetPoint("TOP", frame, "TOP")
	model:SetPoint("BOTTOM", frame, "BOTTOM")
	model:SetPoint("LEFT", frame, "LEFT")
	model:SetPoint("RIGHT", frame, "RIGHT")
	model:SetDisplayInfo(self.DefaultDisplayID)
	model:SetPortraitZoom(self.DefaultZoom)
	model:SetFacing(self.DefaultFacing)

	model:SetScript("OnAnimFinished", function(f) self:OnAnimFinished(f) end)

	self.Initialized = true
end

function Dan:SetAnimation(anim)
	self.Frame.Model:SetAnimation(anim)
end

function Dan:SetDefaultAnimation(anim)
	self.DefaultAnimation = anim
end

function Dan:ResetAnimation()
	self:SetDefaultAnimation(self.Animations.Idle)
	self:SetAnimation(self.DefaultAnimation)
end

function Dan:OnAnimFinished(frame)
	frame:SetAnimation(self.DefaultAnimation)
end

function Dan:DoAction(action, override)
	if not self.Sequence.Timer then
		self.Sequence.Timer = CreateFrame("Frame")
	end
	if self.Sequence.Running and not override then return end
	if override then
		self:StopAction()
	end
	self.Sequence.Running = true
	self.Sequence.Action = action
	self.Sequence.Index = 1
	self.Sequence.Time = 0
	self.Sequence.Target = self.Sequences[self.Sequence.Action][self.Sequence.Index].Time
	self.Sequence.Timer:SetScript("OnUpdate", function(frame, elapsed) Dan:UpdateAction(frame, elapsed) end)
end

function Dan:StopAction()
	if not self.Sequence.Running then return end
	self.Sequence.Timer:SetScript("OnUpdate", nil)
	self.Sequence.Running = false
	self.Sequence.Time = 0
	self.Sequence.Target = 0
	self:ResetAnimation()
end

function Dan:UpdateAction(frame, elapsed)
	if not self.Sequence.Running then
		frame:SetScript("OnUpdate", nil)
	end

	self.Sequence.Time = self.Sequence.Time + elapsed
	if self.Sequence.Time >= self.Sequence.Target then

		local s = self.Sequences[self.Sequence.Action][self.Sequence.Index]

		local soundDuration = nil

		if s.Sound == true then
			soundDuration = self:PlaySound(self.Sequence.Action)
		elseif type(s.Sound) == "table" then
			soundDuration = self:PlaySound(s.Sound[1], s.Sound[2])
		elseif type(s.Sound) == "function" then
			soundDuration = s.Sound()
		end

		if not soundDuration then soundDuration = 0 end

		if s.Animation then
			self:SetAnimation(s.Animation)
		end

		if s.ChangeDefault then
			self:SetDefaultAnimation(s.ChangeDefault)
		end

		local nextIndex = self.Sequence.Index + 1

		if s.Repeating then
			if not soundDuration or soundDuration == 0 then
				soundDuration = self.Sequence.DefaultDelay
			end
			self.Sequence.Time = 0
			self.Sequence.Target = soundDuration
		elseif s.Skip then
			self.Sequence.Index = s.Skip[1]
			self.Sequence.Target = s.Skip[2]
		elseif #self.Sequences[self.Sequence.Action] >= nextIndex then
			if self.Sequence.Index == 1 then
				self.Sequence.Time = s.Time
			end
			self.Sequence.Index = nextIndex
			self.Sequence.Target = self.Sequences[self.Sequence.Action][self.Sequence.Index].Time
		else
			frame:SetScript("OnUpdate", nil)
			self.Sequence.Time = 0
			self:SetDefaultAnimation(self.Animations.Idle)
			if soundDuration > 0 then
				local f = CreateFrame("Frame")
				f.t = 0
				f:SetScript("OnUpdate", function(f, e)
					f.t = f.t + e
					if f.t >= soundDuration then
						f:SetScript("OnUpdate", nil)
						Dan.Sequence.Running = false
					end
				end)
			else
				self.Sequence.Running = false
			end
		end
	end
end

function T:CreateDan()
	Dan:Init()

	if self.Settings.Debug then
		_G.DungeonDanDebug_Dan = Dan
	end
end

function T.Dan:DoAction(action)
	if not Dan.Initialized then return end
	Dan:DoAction(action)
end

function T.Dan:StopAction()
	if not Dan.Initialized then return end
	Dan:StopAction()
end
