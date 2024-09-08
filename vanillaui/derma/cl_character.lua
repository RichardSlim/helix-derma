
local gradient = surface.GetTextureID("vgui/gradient-d")
local audioFadeInTime = 2
local animationTime = 0.5
local matrixZScale = Vector(1, 1, 0.0001)

-- character menu panel
DEFINE_BASECLASS("ixSubpanelParent")
local PANEL = {}

function PANEL:Init()
	self:SetSize(self:GetParent():GetSize())
	self:SetPos(0, 0)

	self.childPanels = {}
	self.subpanels = {}
	self.activeSubpanel = ""

	self.currentDimAmount = 0
	self.currentY = 0
	self.currentScale = 1
	self.currentAlpha = 255
	self.targetDimAmount = 255
	self.targetScale = 1.1
end

function PANEL:Dim(length, callback)
	length = length or animationTime
	self.currentDimAmount = 0

	self:CreateAnimation(length, {
		target = {
			currentDimAmount = self.targetDimAmount,
			currentScale = self.targetScale
		},
		easing = "outCubic",
		OnComplete = callback
	})

	self:OnDim()
end

function PANEL:Undim(length, callback)
	length = length or animationTime
	self.currentDimAmount = self.targetDimAmount

	self:CreateAnimation(length, {
		target = {
			currentDimAmount = 0,
			currentScale = 1
		},
		easing = "outCubic",
		OnComplete = callback
	})

	self:OnUndim()
end

function PANEL:OnDim()
end

function PANEL:OnUndim()
end

function PANEL:Paint(width, height)
	local amount = self.currentDimAmount
	local bShouldScale = self.currentScale != 1
	local matrix

	-- draw child panels with scaling if needed
	if (bShouldScale) then
		matrix = Matrix()
		matrix:Scale(matrixZScale * self.currentScale)
		matrix:Translate(Vector(
			ScrW() * 0.5 - (ScrW() * self.currentScale * 0.5),
			ScrH() * 0.5 - (ScrH() * self.currentScale * 0.5),
			1
		))

		cam.PushModelMatrix(matrix)
		self.currentMatrix = matrix
	end

	BaseClass.Paint(self, width, height)

	if (bShouldScale) then
		cam.PopModelMatrix()
		self.currentMatrix = nil
	end

	if (amount > 0) then
		local color = Color(0, 0, 0, amount)

		surface.SetDrawColor(color)
		surface.DrawRect(0, 0, width, height)
	end
end

vgui.Register("ixCharMenuPanel", PANEL, "ixSubpanelParent")

-- character menu main button list
PANEL = {}

function PANEL:Init()
	local parent = self:GetParent()
	self:SetSize(parent:GetWide() * 0.25, parent:GetTall())

	self:GetVBar():SetWide(0)
	self:GetVBar():SetVisible(false)
end

function PANEL:Add(name)
	local panel = vgui.Create(name, self)
	panel:Dock(TOP)

	return panel
end

function PANEL:SizeToContents()
	self:GetCanvas():InvalidateLayout(true)

	--if the canvas has extra space, forcefully dock to the bottom so it doesn't anchor to the top
	if (self:GetTall() > self:GetCanvas():GetTall()) then
		self:GetCanvas():Dock(TOP)
	else
		self:GetCanvas():Dock(NODOCK)
	end
end

vgui.Register("ixCharMenuButtonList", PANEL, "DScrollPanel")

-- main character menu panel
PANEL = {}

AccessorFunc(PANEL, "bUsingCharacter", "UsingCharacter", FORCE_BOOL)

local backTexture = Material("halfliferp/backgrounds/background1.png")
local barTexture = Material("gui/gradient_down.png");

function PANEL:Init()
	local parent = self:GetParent()
	local padding = self:GetPadding()
	local quarterWidth = ScrW() * 0.25
	local halfWidth = ScrW() * 0.5
	local thirdWidth = ScrW() * 0.75
	local halfPadding = padding * 0.5
	local bHasCharacter = #ix.characters > 0

	self.bUsingCharacter = LocalPlayer().GetCharacter and LocalPlayer():GetCharacter()

	local backPanel = self:Add("Panel")
	backPanel:SetSize(ScrW(), ScrH())
	backPanel:SetPos(0, 0)
	backPanel.Paint = function(panel, width, height)
		surface.SetDrawColor(80, 80, 80, 255)
		surface.SetMaterial(backTexture);
		surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
	end

	local topPanel = self:Add("Panel")
	topPanel:SetSize(ScrW(), ScrH() * 0.062)
	topPanel:SetPos(0, 0)
	topPanel.Paint = function(panel, width, height)
		local matrix = self.currentMatrix
		local x, y = x, 0

		-- don't scale the background because it fucks the blur
		if (matrix) then
			cam.PopModelMatrix()
		end

		local newHeight = Lerp(1 - (0 / 255), 0, height)
		local y = height * 0.5 - newHeight * 0.5
		local _, screenY = panel:LocalToScreen(0, 0)
		screenY = screenY + y

		-- background dim

		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, y, width, newHeight)

		surface.SetDrawColor(40, 40, 40, 255)
		surface.SetMaterial(barTexture);
		surface.DrawTexturedRect(0, y, width, newHeight * 1.5)

		-- border lines
		surface.SetDrawColor(255, 255, 255, 50)
		surface.DrawRect(0, y + newHeight - 1, width, 1)
	end

	local logoPanel = self:Add("Panel")
	logoPanel:SetSize(ScrW(), ScrH() * 0.35)
	logoPanel:SetPos(0, ScrH() * 0.35)

	-- draw schema logo material instead of text if available
	local logo = Schema.logo and ix.util.GetMaterial(Schema.logo)

	if (logo and !logo:IsError()) then
		local newHeight = padding
		local subtitle = L2("schemaDesc") or Schema.description
		local author = Schema.author
		local logoImage = logoPanel:Add("DImage")
		logoImage:SetMaterial(logo)
		logoImage:SetSize(ScrW()*0.2667, ScrH()*0.1185)
		logoImage:SetPos(halfWidth - logoImage:GetWide() * 0.5, logoImage:GetTall() * 0.5)
		logoImage:SetPaintedManually(true)

		logoPanel:SetTall(logoImage:GetTall() + padding * 1.4)
		

		if (subtitle) then
			local subtitleLabel = logoPanel:Add("DLabel")
			subtitleLabel:SetTextColor(color_white)
			subtitleLabel:SetFont("cwSubtitleFont")
			subtitleLabel:SetText(string.upper(subtitle))
			subtitleLabel:SizeToContents()
			subtitleLabel:SetPos(halfWidth - subtitleLabel:GetWide() * 0.5, 0)
			subtitleLabel:MoveBelow(logoImage)
			subtitleLabel:SetPaintedManually(true)

			local authorLabel = logoPanel:Add("DLabel")
			authorLabel:SetTextColor(color_white)
			authorLabel:SetFont("cwAuthorFont")
			authorLabel:SetText("DEVELOPED BY "..string.upper(author))
			authorLabel:SizeToContents()
			authorLabel:SetPos(ScrW()*0.75 - authorLabel:GetWide() * 1.25, 0)
			authorLabel:MoveBelow(subtitleLabel)
			authorLabel:SetPaintedManually(true)
			newHeight = newHeight + authorLabel:GetTall()
		end
	else
		local newHeight = padding
		local subtitle = L2("schemaDesc") or Schema.description
		local author = Schema.author

		local titleLabel = logoPanel:Add("DLabel")
		titleLabel:SetTextColor(color_white)
		titleLabel:SetFont("cwTitleFont")
		titleLabel:SetText(string.upper(L2("schemaName") or Schema.name or L"unknown"))
		titleLabel:SizeToContents()
		titleLabel:SetPos(halfWidth - titleLabel:GetWide() * 0.5, titleLabel:GetTall() * 0.5)
		titleLabel:SetPaintedManually(true)
		newHeight = newHeight + titleLabel:GetTall()

		if (subtitle) then
			local subtitleLabel = logoPanel:Add("DLabel")
			subtitleLabel:SetTextColor(color_white)
			subtitleLabel:SetFont("cwSubtitleFont")
			subtitleLabel:SetText(string.upper(subtitle))
			subtitleLabel:SizeToContents()
			subtitleLabel:SetPos(halfWidth - subtitleLabel:GetWide() * 0.5, 0)
			subtitleLabel:MoveBelow(titleLabel)
			subtitleLabel:SetPaintedManually(true)
			newHeight = newHeight + subtitleLabel:GetTall()

			local authorLabel = logoPanel:Add("DLabel")
			authorLabel:SetTextColor(color_white)
			authorLabel:SetFont("cwAuthorFont")
			authorLabel:SetText("DEVELOPED BY "..string.upper(author))
			authorLabel:SizeToContents()
			authorLabel:SetPos(ScrW()*0.615 - authorLabel:GetWide() * 0.5, 0)
			authorLabel:MoveBelow(subtitleLabel)
			authorLabel:SetPaintedManually(true)
			newHeight = newHeight + authorLabel:GetTall()
		end

		logoPanel:SetTall(newHeight)
	end

	-- create character button

	self.createButton = self:Add("cwMenuButton")
	self.createButton:SetText("NEW")
	self.createButton:SizeToContents()
	self.createButton:SetPos(quarterWidth - self.createButton:GetWide() * 0.5, ScrH()*0.01 )	
	self.createButton.DoClick = function()
		local maximum = hook.Run("GetMaxPlayerCharacter", LocalPlayer()) or ix.config.Get("maxCharacters", 5)
		-- don't allow creation if we've hit the character limit
		if (#ix.characters >= maximum) then
			self:GetParent():ShowNotice(3, L("maxCharacters"))
			return
		end

		self:Dim()
		parent.newCharacterPanel:SetActiveSubpanel("faction", 0)
		parent.newCharacterPanel:SlideUp()
	end

	-- load character button
	self.loadButton = self:Add("cwMenuButton")
	self.loadButton:SetText("LOAD")
	self.loadButton:SizeToContents()
	self.loadButton:SetPos(thirdWidth - self.loadButton:GetWide() * 0.70, ScrH()*0.01 )
	self.loadButton.DoClick = function()
		self:Dim()
		parent.loadCharacterPanel:SlideUp()
	end

	if (!bHasCharacter) then
		self.loadButton:SetDisabled(true)
	end

	-- leave/return button
	self.returnButton = self:Add("cwMenuButton")
	self:UpdateReturnButton()
	self.returnButton:SetPos(halfWidth - self.returnButton:GetWide() * 0.5, ScrH()*0.01 )
	self.returnButton.DoClick = function()
		if (self.bUsingCharacter) then
			parent:Close()
		else
			RunConsoleCommand("disconnect")
		end
	end

	self.extraButton = self:Add("DHTML")
		self.extraButton:SetPos(ScrW()*0.01, ScrH()*0.89)
		self.extraButton:SetSize(120, 120)
		self.extraButton:SetHTML([[
			<html>
				<body style="margin: 0; padding: 0; overflow: hidden;">
					<img src="]]..ix.config.Get("logo", "https://assets-global.website-files.com/6257adef93867e50d84d30e2/636e0a6ca814282eca7172c6_icon_clyde_white_RGB.svg")..[[" width="120" height="120" />
				</body>
			</html>
		]])
		self.extraButton:SetToolTip(ix.config.Get("communityURL", "http://nutscript.net"))
	
		self.extraButton.click = self.extraButton:Add("DButton")
		self.extraButton.click:Dock(FILL)
		self.extraButton.click.DoClick = function(this)
			gui.OpenURL(ix.config.Get("communityURL", "http://nutscript.net"))
			
		end
		self.extraButton.click:SetAlpha(0)
		self.extraButton:SetAlpha(150)

	--self.mainButtonList:SizeToContents()
end

function PANEL:UpdateReturnButton(bValue)
	if (bValue != nil) then
		self.bUsingCharacter = bValue
	end

	self.returnButton:SetText(self.bUsingCharacter and "RETURN" or "LEAVE")
	self.returnButton:SizeToContents()
end

function PANEL:OnDim()
	-- disable input on this panel since it will still be in the background while invisible - prone to stray clicks if the
	-- panels overtop slide out of the way
	self:SetMouseInputEnabled(false)
	self:SetKeyboardInputEnabled(false)
end

function PANEL:OnUndim()
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)

	-- we may have just deleted a character so update the status of the return button
	self.bUsingCharacter = LocalPlayer().GetCharacter and LocalPlayer():GetCharacter()
	self:UpdateReturnButton()
end

function PANEL:OnClose()
	for _, v in pairs(self:GetChildren()) do
		if (IsValid(v)) then
			v:SetVisible(false)
		end
	end
end

function PANEL:PerformLayout(width, height)
	--[[local padding = self:GetPadding()

	self.mainButtonList:SetPos(padding, height - self.mainButtonList:GetTall() - padding)--]]
end

vgui.Register("ixCharMenuMain", PANEL, "ixCharMenuPanel")

-- container panel
PANEL = {}

function PANEL:Init()
	if (IsValid(ix.gui.loading)) then
		ix.gui.loading:Remove()
	end

	if (IsValid(ix.gui.characterMenu)) then
		if (IsValid(ix.gui.characterMenu.channel)) then
			ix.gui.characterMenu.channel:Stop()
		end

		ix.gui.characterMenu:Remove()
	end

	self:SetSize(ScrW(), ScrH())
	self:SetPos(0, 0)

	-- main menu panel
	self.mainPanel = self:Add("ixCharMenuMain")

	-- new character panel
	self.newCharacterPanel = self:Add("ixCharMenuNew")
	self.newCharacterPanel:SlideDown(0)

	-- load character panel
	self.loadCharacterPanel = self:Add("ixCharMenuLoad")
	self.loadCharacterPanel:SlideDown(0)

	-- notice bar
	self.notice = self:Add("ixNoticeBar")

	-- finalization
	self:MakePopup()
	self.currentAlpha = 255
	self.volume = 0

	ix.gui.characterMenu = self

	if (!IsValid(ix.gui.intro)) then
		self:PlayMusic()
	end

	hook.Run("OnCharacterMenuCreated", self)
end

function PANEL:PlayMusic()
	local path = "sound/" .. ix.config.Get("music")
	local url = path:match("http[s]?://.+")
	local play = url and sound.PlayURL or sound.PlayFile
	path = url and url or path

	play(path, "noplay", function(channel, error, message)
		if (!IsValid(self) or !IsValid(channel)) then
			return
		end

		channel:SetVolume(self.volume or 0)
		channel:Play()

		self.channel = channel

		self:CreateAnimation(audioFadeInTime, {
			index = 10,
			target = {volume = 1},

			Think = function(animation, panel)
				if (IsValid(panel.channel)) then
					panel.channel:SetVolume(self.volume * 0.5)
				end
			end
		})
	end)
end

function PANEL:ShowNotice(type, text)
	self.notice:SetType(type)
	self.notice:SetText(text)
	self.notice:Show()
end

function PANEL:HideNotice()
	if (IsValid(self.notice) and !self.notice:GetHidden()) then
		self.notice:Slide("up", 0.5, true)
	end
end

function PANEL:OnCharacterDeleted(character)
	if (#ix.characters == 0) then
		self.mainPanel.loadButton:SetDisabled(true)
		self.mainPanel:Undim() -- undim since the load panel will slide down
	else
		self.mainPanel.loadButton:SetDisabled(false)
	end

	self.loadCharacterPanel:OnCharacterDeleted(character)
end

function PANEL:OnCharacterLoadFailed(error)
	self.loadCharacterPanel:SetMouseInputEnabled(true)
	self.loadCharacterPanel:SlideUp()
	self:ShowNotice(3, error)
end

function PANEL:IsClosing()
	return self.bClosing
end

function PANEL:Close(bFromMenu)
	self.bClosing = true
	self.bFromMenu = bFromMenu

	local fadeOutTime = animationTime * 8

	self:CreateAnimation(fadeOutTime, {
		index = 1,
		target = {currentAlpha = 0},

		Think = function(animation, panel)
			panel:SetAlpha(panel.currentAlpha)
		end,

		OnComplete = function(animation, panel)
			panel:Remove()
		end
	})

	self:CreateAnimation(fadeOutTime - 0.1, {
		index = 10,
		target = {volume = 0},

		Think = function(animation, panel)
			if (IsValid(panel.channel)) then
				panel.channel:SetVolume(self.volume * 0.5)
			end
		end,

		OnComplete = function(animation, panel)
			if (IsValid(panel.channel)) then
				panel.channel:Stop()
				panel.channel = nil
			end
		end
	})

	-- hide children if we're already dimmed
	if (bFromMenu) then
		for _, v in pairs(self:GetChildren()) do
			if (IsValid(v)) then
				v:SetVisible(false)
			end
		end
	else
		-- fade out the main panel quicker because it significantly blocks the screen
		self.mainPanel.currentAlpha = 255

		self.mainPanel:CreateAnimation(animationTime * 2, {
			target = {currentAlpha = 0},
			easing = "outQuint",

			Think = function(animation, panel)
				panel:SetAlpha(panel.currentAlpha)
			end,

			OnComplete = function(animation, panel)
				panel:SetVisible(false)
			end
		})
	end

	-- relinquish mouse control
	self:SetMouseInputEnabled(false)
	self:SetKeyboardInputEnabled(false)
	gui.EnableScreenClicker(false)
end

function PANEL:Paint(width, height)
	surface.SetTexture(gradient)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawTexturedRect(0, 0, width, height)

	if (!ix.option.Get("cheapBlur", false)) then
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawTexturedRect(0, 0, width, height)
		ix.util.DrawBlur(self, Lerp((self.currentAlpha - 200) / 255, 0, 10))
	end
end

function PANEL:PaintOver(width, height)
	if (self.bClosing and self.bFromMenu) then
		surface.SetDrawColor(color_black)
		surface.DrawRect(0, 0, width, height)
	end
end

function PANEL:OnRemove()
	if (self.channel) then
		self.channel:Stop()
		self.channel = nil
	end
end

vgui.Register("ixCharMenu", PANEL, "EditablePanel")

if (IsValid(ix.gui.characterMenu)) then
	ix.gui.characterMenu:Remove()

	--TODO: REMOVE ME
	ix.gui.characterMenu = vgui.Create("ixCharMenu")
end
