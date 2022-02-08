local AUTO_CLOSE_MS = 15 * 1000
LIB_TUTORIAL_TYPE_HUD_INFO = HashString("LIB_TUTORIAL_TYPE_HUD_INFO")

LibTutorial_HudInfo = ZO_TutorialHandlerBase:Subclass()

function LibTutorial_HudInfo:Initialize(parent)
	self:SetupTutorial(parent, "ZO_HudInfoBoxTutorialTip_Gamepad", "LibTutorialHudInfoTipGamepad")
	self.tutorialGamepad = self.tutorial
	self.tutorialAnimationGamepad = self.tutorialAnimation

	self:SetupTutorial(parent, "ZO_HudInfoBoxTutorialTip", "LibTutorialHudInfoTipKeyboard")
	self.tutorialKeyboard = self.tutorial
	self.tutorialAnimationKeyboard = self.tutorialAnimation

	EVENT_MANAGER:RegisterForUpdate(self.tutorial:GetName() .. "OnUpdate", 0, function() self:OnUpdate() end)

	self:ClearAll()

	ZO_Keybindings_RegisterLabelForBindingUpdate(self.tutorial.helpKey, "TOGGLE_HELP")
	ZO_Keybindings_RegisterLabelForBindingUpdate(self.tutorialGamepad.helpKey, "TOGGLE_HELP")

	self:SetHiddenForReason("inactive", true)
end

function LibTutorial_HudInfo:SetupTutorial(parent, template, name)
	self.tutorial = CreateControlFromVirtual(parent:GetName(), parent, template, name)

	self.tutorialAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("HudInfoBoxTutorialAnimation", self.tutorial)
	self.tutorialAnimation:SetHandler("OnStop", function(timeline) 
		if not timeline:IsPlayingBackward() then
			FireTutorialHiddenEvent(self.tutorialIndex)
			self:SetHiddenForReason("inactive", true)
			if #self.queue > 0 then
				local nextTutorialIndex = table.remove(self.queue, 1)
				self:DisplayTutorial(nextTutorialIndex)
			end
		end
	end)
end

function LibTutorial_HudInfo:GetTutorialType()
	return LIB_TUTORIAL_TYPE_HUD_INFO
end

function LibTutorial_HudInfo:GetTutorialInfo(tutorialIndex)
	--Currently Unused
end

function LibTutorial_HudInfo:SetTutorialSeen(tutorialIndex)
	--User Overridden
end

local BASE_TUTORIAL_HEIGHT = 170
function LibTutorial_HudInfo:DisplayTutorial(tutorialIndex, title, desc)
	self.tutorialIndex = tutorialIndex
	local isInGamepadMode = IsInGamepadPreferredMode()
	if isInGamepadMode then
		self.tutorial = self.tutorialGamepad
		self.tutorialAnimation = self.tutorialAnimationGamepad
	else
		self.tutorial = self.tutorialKeyboard
		self.tutorialAnimation = self.tutorialAnimationKeyboard
	end

	local title = title or self.queueData[tutorialIndex].title
	local description = desc or self.queueData[tutorialIndex].desc
	local helpCategoryIndex, helpIndex = nil --GetTutorialLinkedHelpInfo(tutorialIndex)
	local hasHelp = helpCategoryIndex ~= nil and helpIndex ~= nil
	self.tutorial.title:SetText(title)
	self.tutorial.description:SetText(description)
	
	local showHelpLabel = hasHelp and not isInGamepadMode
	self.tutorial.helpLabel:SetHidden(not showHelpLabel)
	self.tutorial.helpKey:SetHidden(not showHelpLabel)

	if not isInGamepadMode then
		local textHeight = self.tutorial.description:GetTextHeight()
		if hasHelp then
			textHeight = textHeight + self.tutorial.helpLabel:GetHeight()
		end
		self.tutorial:SetHeight(BASE_TUTORIAL_HEIGHT + textHeight)
	end

	self.tutorialAnimation:PlayBackward()
	self:SetHiddenForReason("inactive", false)
	self:SetCurrentlyDisplayedTutorialIndex(tutorialIndex)
	self.currentlyDisplayedTutorialTimeLeft = AUTO_CLOSE_MS

	PlaySound(SOUNDS.TUTORIAL_INFO_SHOWN)
end

function LibTutorial_HudInfo:OnDisplayTutorial(tutorialIndex, priority, title, desc)
	if not self:IsTutorialDisplayedOrQueued(tutorialIndex) then
		if not self:CanShowTutorial() then
			local _, insertPosition = zo_binarysearch(priority, self.queue, BinaryInsertComparer)
			table.insert(self.queue, insertPosition, tutorialIndex)
			self.queueData[tutorialIndex] = {title = title, desc = desc}
		else
			self:DisplayTutorial(tutorialIndex, title, desc)
		end
	end
end

function LibTutorial_HudInfo:RemoveTutorial(tutorialIndex)
	if self:GetCurrentlyDisplayedTutorialIndex() == tutorialIndex then
		self:SetTutorialSeen(tutorialIndex)

		self:SetCurrentlyDisplayedTutorialIndex(nil)
		self.currentlyDisplayedTutorialTimeLeft = nil
		self.tutorialAnimation:PlayForward()
	else
		self.queueData[tutorialIndex] = nil
		self:RemoveFromQueue(self.queue, tutorialIndex)
	end
end

function LibTutorial_HudInfo:SetHidden(hide)
	self.tutorial:SetHidden(hide)
end

function LibTutorial_HudInfo:OnUpdate()
	local now = GetFrameTimeMilliseconds()
	local delta = now - (self.lastUpdate or now)

	if self:GetCurrentlyDisplayedTutorialIndex() and not self.tutorial:IsHidden() then
		self.currentlyDisplayedTutorialTimeLeft = self.currentlyDisplayedTutorialTimeLeft - delta
		if self.currentlyDisplayedTutorialTimeLeft < 0 then
			self:RemoveTutorial(self:GetCurrentlyDisplayedTutorialIndex())
		end
	end

	self.lastUpdate = now
end

function LibTutorial_HudInfo:ClearAll()
	self:SetCurrentlyDisplayedTutorialIndex(nil)
	self.currentlyDisplayedTutorialTimeLeft = nil
	self.tutorialAnimationGamepad:PlayForward()
	self.tutorialAnimationKeyboard:PlayForward()

	self.queue = {}
	self.queueData = {}
end

function LibTutorial_HudInfo:ShowHelp()
	if self:GetCurrentlyDisplayedTutorialIndex() and not IsInGamepadPreferredMode() then
		local helpCategoryIndex, helpIndex = GetTutorialLinkedHelpInfo(self:GetCurrentlyDisplayedTutorialIndex())
		if helpCategoryIndex and helpIndex then
			self:RemoveTutorial(self:GetCurrentlyDisplayedTutorialIndex())

			HELP:ShowSpecificHelp(helpCategoryIndex, helpIndex)
			return true
		end
	end
end