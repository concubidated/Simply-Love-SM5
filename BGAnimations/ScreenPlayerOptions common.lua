-- ----------------------------------------------------------
-- helper functions local to this file

-- this prepares and returns a string to be used by the helper BitmapText
-- that shows players their effective scrollspeed

local CalculateScrollSpeed = function(player)
	player   = player or GAMESTATE:GetMasterPlayerNumber()
	local pn = ToEnumShortString(player)

	local StepsOrTrail = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)
	local MusicRate    = SL.Global.ActiveModifiers.MusicRate or 1

	local SpeedModType = SL[pn].ActiveModifiers.SpeedModType
	local SpeedMod     = SL[pn].ActiveModifiers.SpeedMod

	local bpms = GetDisplayBPMs(player, StepsOrTrail, MusicRate)
	if not (bpms and bpms[1] and bpms[2]) then return "" end

	if SpeedModType=="X" then
		bpms[1] = bpms[1] * SpeedMod
		bpms[2] = bpms[2] * SpeedMod

	elseif SpeedModType=="M" then
		bpms[1] = bpms[1] * (SpeedMod/bpms[2])
		bpms[2] = SpeedMod

	elseif SpeedModType=="C" then
		bpms[1] = SpeedMod
		bpms[2] = SpeedMod
	end

	-- format as strings
	bpms[1] = ("%.0f"):format(bpms[1])
	bpms[2] = ("%.0f"):format(bpms[2])

	if bpms[1] == bpms[2] then
		return bpms[1]
	end

	return ("%s-%s"):format(bpms[1], bpms[2])
end

-- ----------------------------------------------------------
local common_overlay

local af = Def.ActorFrame{
	Name="PlayerOptionsCommonOverlay",
	InitCommand=function(self)
		common_overlay = self
		self:xy(_screen.cx,0)
	end,

	-- this is broadcast from [OptionRow] TitleGainFocusCommand in metrics.ini
	-- we use it to color the active OptionRow's title appropriately by PlayerColor()
	OptionRowChangedMessageCommand=function(self, params)
		local CurrentRowIndex = {"P1", "P2"}

		-- There is always the possibility that a diffuseshift is still active;
		-- cancel it now (and re-apply below, if applicable).
		params.Title:stopeffect()

		-- get the index of PLAYER_1's current row
		if GAMESTATE:IsPlayerEnabled(PLAYER_1) then
			CurrentRowIndex.P1 = SCREENMAN:GetTopScreen():GetCurrentRowIndex(PLAYER_1)
		end

		-- get the index of PLAYER_2's current row
		if GAMESTATE:IsPlayerEnabled(PLAYER_2) then
			CurrentRowIndex.P2 = SCREENMAN:GetTopScreen():GetCurrentRowIndex(PLAYER_2)
		end

		local optionRow = params.Title:GetParent():GetParent()

		-- color the active optionrow's title appropriately
		if optionRow:HasFocus(PLAYER_1) then
			params.Title:diffuse(PlayerColor(PLAYER_1))
		end

		if optionRow:HasFocus(PLAYER_2) then
			params.Title:diffuse(PlayerColor(PLAYER_2))
		end

		if CurrentRowIndex.P1 and CurrentRowIndex.P2 then
			if CurrentRowIndex.P1 == CurrentRowIndex.P2 then
				params.Title:diffuseshift()
				params.Title:effectcolor1(PlayerColor(PLAYER_1))
				params.Title:effectcolor2(PlayerColor(PLAYER_2))
			end
		end

	end
}

-- attach NoteSkin actors and Judgment graphic sprites and Combo bitmaptexts here
-- the player won't see these; they'll each be hidden immediately via visible(false)
-- and referred to as needed via ActorProxy in ./Graphics/OptionRow Frame.lua
LoadActor(THEME:GetPathB("ScreenPlayerOptions", "overlay/NoteSkinPreviews.lua"), af)
LoadActor(THEME:GetPathB("ScreenPlayerOptions", "overlay/JudgmentGraphicPreviews.lua"), af)
LoadActor(THEME:GetPathB("ScreenPlayerOptions", "overlay/ComboFontPreviews.lua"), af)

-- basic properties of the active-mods frame
local props = {
	w = WideScale(270,330),
	h = 50,
	margin  = 4,
	padding = 4,
	offset  = 60,
}

for player in ivalues(GAMESTATE:GetHumanPlayers()) do
	local pn = ToEnumShortString(player)

	local frame = Def.ActorFrame{
		Name="ActiveMods"..pn,
		InitCommand=function(self)
			self:y(59.5)

			if player==PLAYER_1 then
				self:x(-props.w/2 + props.offset )
			else
				self:x( props.w/2 + props.offset + props.margin)
			end
		end
	}

	-- per-player Quad at the top of the screen behind list of active modifiers
	frame[#frame+1] = Def.Quad{
		Name="Background",
		InitCommand=function(self)
			self:diffuse(0,0,0,0):setsize(props.w, props.h)
		end,
		OnCommand=function(self) self:linear(0.2):diffuse(BrighterOptionRows() and {0,0,0,0.9} or {0.25, 0.25, 0.25, 1}) end,
	}

	-- the large block text at the top that shows each player their current scroll speed
	frame[#frame+1] = LoadFont("_wendy small")..{
		Name=pn.."SpeedModHelper",
		Text="",
		InitCommand=function(self)
			self:diffuse(PlayerColor(player)):diffusealpha(0)
			self:zoom(0.5):horizalign(left):shadowlength(0.55)
			self:y(-12):x(-props.w/2 + props.padding + 30)
		end,
		OnCommand=function(self) self:linear(0.4):diffusealpha(1) end,
		RefreshCommand=function(self)
			self:settext( ("%s%s"):format(SL[pn].ActiveModifiers.SpeedModType, CalculateScrollSpeed(player)) )
		end
	}

	-- noteskin preview
	frame[#frame+1] = Def.ActorProxy{
		InitCommand=function(self)
			self:zoom(0.35):y(-12)
			self:x(-props.w/2 + props.padding + 10)
		end,
		NoteSkinChangedMessageCommand=function(self, params)
			if player == params.Player then
				-- attempt to find the hidden NoteSkin actor added by ./BGAnimations/ScreenPlayerOptions overlay.lua
				local noteskin_actor = common_overlay:GetChild("NoteSkin_"..params.NoteSkin)
				-- ensure that that NoteSkin actor exists before attempting to set it as the target of this ActorProxy
				if noteskin_actor then self:SetTarget( noteskin_actor ) end
			end
		end
	}

	-- judgment graphic preview
	frame[#frame+1] = Def.ActorProxy{
		InitCommand=function(self)
			self:zoom(0.4):y(12)
			self:x(-props.w/2 + props.padding + 45)
		end,
		JudgmentGraphicChangedMessageCommand=function(self, params)
			if player == params.Player then
				-- attempt to find the hidden judgment sprite added by ./BGAnimations/ScreenPlayerOptions overlay.lua
				local judgment_sprite = common_overlay:GetChild("JudgmentGraphic_"..params.JudgmentGraphic)
				-- ensure that that judgment sprite exists before attempting to set it as the target of this ActorProxy
				if judgment_sprite then
					self:SetTarget( judgment_sprite )

					-- Alas, that love, so gentle in his view,
					-- Should be so tyrannous and rough in proof!
					self:y(params.JudgmentGraphic=="Love" and 9 or 12)
				end
			end
		end
	}

	af[#af+1] = frame
end

return af