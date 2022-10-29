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
			self:SetHiddenForReason("inactive", true)
			if #self.queue > 0 then
				local nextTutorialId = table.remove(self.queue, 1)
				return self:DisplayTutorial(nextTutorialId)
			end
		end
	end)
end

function LibTutorial_HudInfo:GetTutorialType()
	return LIB_TUTORIAL_TYPE_HUD_INFO
end

function LibTutorial_HudInfo:GetTutorialInfo(tutorialId)
	--Currently Unused
end

function LibTutorial_HudInfo:SetTutorialSeen(tutorialId)
	--User Overridden
end

local BASE_TUTORIAL_HEIGHT = 170
function LibTutorial_HudInfo:DisplayTutorial(tutorialId, title, desc)
	self.tutorialId = tutorialId
	local isInGamepadMode = IsInGamepadPreferredMode()
	if isInGamepadMode then
		self.tutorial = self.tutorialGamepad
		self.tutorialAnimation = self.tutorialAnimationGamepad
	else
		self.tutorial = self.tutorialKeyboard
		self.tutorialAnimation = self.tutorialAnimationKeyboard
	end

	title = title or self.queueData[tutorialId].title
	local description = desc or self.queueData[tutorialId].desc
	local helpCategoryIndex, helpIndex = nil --GetTutorialLinkedHelpInfo(tutorialId)
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
	self:SetCurrentlyDisplayedTutorialIndex(tutorialId)
	self.currentlyDisplayedTutorialTimeLeft = AUTO_CLOSE_MS

	PlaySound(SOUNDS.TUTORIAL_INFO_SHOWN)

	return true
end

function LibTutorial_HudInfo:OnDisplayTutorial(tutorialId, priority, title, desc)
	if not self:IsTutorialDisplayedOrQueued(tutorialId) then
		if not self:CanShowTutorial() then
			local _, insertPosition = zo_binarysearch(priority, self.queue, BinaryInsertComparer)
			table.insert(self.queue, insertPosition, tutorialId)
			self.queueData[tutorialId] = {title = title, desc = desc}
		else
			return self:DisplayTutorial(tutorialId, title, desc)
		end
	end
end

function LibTutorial_HudInfo:RemoveTutorial(tutorialId)
	if self:GetCurrentlyDisplayedTutorialIndex() == tutorialId then
		self:SetTutorialSeen(tutorialId)

		self:SetCurrentlyDisplayedTutorialIndex(nil)
		self.currentlyDisplayedTutorialTimeLeft = nil
		self.tutorialAnimation:PlayForward()
	else
		self.queueData[tutorialId] = nil
		self:RemoveFromQueue(self.queue, tutorialId)
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