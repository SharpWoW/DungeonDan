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

if T.Dan then return end

T.Dan = {
	Actions = {
		Welcome = 0,
		DungeonReady = 1,
		QueueDamage = 2,
		QueueHealer = 3,
		QueueTank = 4,
		QueueTalk = 5,
		AoeDamage = 6,
		DungeonFinish = 7,
		BossKill = 8,
		BossWipe = 9,
		PlayerDeath = 10,
		GroupDeath = 11,
		LootNinja = 12, -- Player needed on loot that isn't appropriate for them
		LootWin = 13, -- Player needed and won on loot that is appropriate for them
		LootLose = 14 -- Player needed and lost on loot that is appropriate for them
	}
}

local Dan = {
	Initialized = false,
	Size = { Width = 400, Height = 350 },
	DefaultDisplayID = 1541,
	DefaultZoom = 0.5,
	DefaultFacing = -0.1,
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
	[Dan.Actions.Welcome] = {
		{"VO_WELCOME", 4}
	},
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
	[Dan.Actions.Welcome] = {
		[1] = {
			Time = 0,
			Animation = Dan.Animations.Talk,
			Sound = true
		},
		[2] = {
			Time = 1.9,
			Animation = Dan.Animations.Gasp,
			Sound = false
		}
	},
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
	self:LoadSavedVars()

	if self.Frame then return end

	-- Create container frame
	self.Frame = CreateFrame("Frame", nil, UIParent)
	local frame = self.Frame
	frame:SetSize(self.Size.Width, self.Size.Height)
	frame:SetBackdrop(FrameBackdrop)
	frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", self.Settings.Frame.OffsetX, self.Settings.Frame.OffsetY)

	frame:SetScript("OnShow", function() self.Hidden = false end)
	frame:SetScript("OnHide", function() self.Hidden = true end)

	if T.Settings.Debug then
		frame:EnableMouse(true)
		frame:SetMovable(true)
		frame:SetScript("OnMouseDown", function(f) f:StartMoving() end)
		frame:SetScript("OnMouseUp", function(f) f:StopMovingOrSizing() end)
	end

	frame.Model = CreateFrame("PlayerModel", nil, frame)
	local model = frame.Model
	model:EnableMouse(false)
	model:SetPoint("TOP", frame, "TOP", 0, -4)
	model:SetPoint("BOTTOM", frame, "BOTTOM", 0, 4)
	model:SetPoint("LEFT", frame, "LEFT")
	model:SetPoint("RIGHT", frame, "RIGHT")
	model:SetDisplayInfo(self.DefaultDisplayID)
	model:SetPortraitZoom(self.DefaultZoom)
	model:SetFacing(self.DefaultFacing)

	model:SetScript("OnAnimFinished", function(f) self:OnAnimFinished(f) end)

	frame.SlideOut = frame:CreateAnimationGroup()
	frame.SlideOut.Anim = frame.SlideOut:CreateAnimation("Translation")
	frame.SlideOut.Anim:SetOrder(1)
	frame.SlideOut.Anim:SetDuration(0.5)
	frame.SlideOut.Anim:SetOffset(self.Size.Width, 0)
	frame.SlideOut.Anim:SetSmoothing("OUT")
	frame.SlideOut:SetScript("OnPlay", function()
		self.Sliding = true
		local _, _, _, _, y = frame:GetPoint("TOPRIGHT")
		frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -self.Size.Width + self.Settings.Frame.OffsetX, y)
	end)
	frame.SlideOut:SetScript("OnFinished", function()
		local _, _, _, _, y = frame:GetPoint("TOPRIGHT")
		frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", self.Size.Width)
		frame:Hide()
		self.Sliding = false
	end)

	-- Weird skip to the left happens at the end of SlideIn animation, immediately skips to the right after (probably because of setting position in OnFinished)
	frame.SlideIn = frame:CreateAnimationGroup()
	frame.SlideIn.Anim = frame.SlideIn:CreateAnimation("Translation")
	frame.SlideIn.Anim:SetOrder(1)
	frame.SlideIn.Anim:SetDuration(0.5)
	frame.SlideIn.Anim:SetOffset(-400, 0)
	frame.SlideIn.Anim:SetSmoothing("IN")
	frame.SlideIn:SetScript("OnPlay", function()
		self.Sliding = true
		frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", self.Size.Width, self.Settings.Frame.OffsetY)
		frame:Show()
	end)
	frame.SlideIn:SetScript("OnFinished", function()
		frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", self.Settings.Frame.OffsetX, self.Settings.Frame.OffsetY)
		self.Sliding = false
	end)

	self.Initialized = true
end

function Dan:LoadSavedVars()
	if type(T.Settings.Dan) ~= "table" then
		T.Settings.Dan = {}
	end
	self.Settings = T.Settings.Dan

	if type(self.Settings.Frame) ~= "table" then
		self.Settings.Frame = {}
	end

	if type(self.Settings.Frame.OffsetX) ~= "number" then
		self.Settings.Frame.OffsetX = -30
	end

	if type(self.Settings.Frame.OffsetY) ~= "number" then
		self.Settings.Frame.OffsetY = -100
	end
end

function Dan:StopSliding()
	self.Frame.SlideOut:Stop()
	self.Frame.SlideIn:Stop()

function Dan:ResetModelSettings()
	self.Frame.Model:SetDisplayInfo(self.DefaultDisplayID)
	self.Frame.Model:SetPortraitZoom(self.DefaultZoom)
	self.Frame.Model:SetFacing(self.DefaultFacing)
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
	if (self.Sequence.Running or self.PlayingSound) and not override then return end
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

function Dan:Hide()
	if self.Hidden then return end
	if self.Sliding then self:StopSliding() end
	self.Frame.SlideOut:Play()
end

function Dan:Show()
	if not self.Hidden then return end
	if self.Sliding then self:StopSliding() end
	self.Frame.SlideIn:Play()
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

function T.Dan:ResetModelSettings()
	if not Dan.Initialized then return end
	Dan:ResetModelSettings()
end
