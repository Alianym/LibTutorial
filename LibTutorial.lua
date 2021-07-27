-----
--Initialize
-----

LibTutorial = ZO_Object:Subclass()
LibTutorialSetup = {}

function LibTutorialSetup:New(tutorialArray)
	local libTutorial = ZO_Object:New(LibTutorial)
	libTutorial:Initialize(tutorialArray)
	return libTutorial
end

function LibTutorialSetup:DisplayTutorial(obj, tutorialId)
    local tutorialType = obj:GetLibTutorialType(tutorialId)

    if TUTORIAL_SYSTEM.tutorialHandlers[tutorialType] then
        local priority = obj:GetLibTutorialDisplayPriority(tutorialId)
        local title, desc = obj:GetLibTutorialInfo(tutorialId)
        TUTORIAL_SYSTEM.tutorialHandlers[tutorialType]:OnDisplayTutorial(tutorialId, priority, title, desc)
    end
end

function LibTutorial:RegisterTutorials(tutorialArray)
    if self.tutorials then return end
    local newTutorialArray = {}

    for id, values in pairs(tutorialArray) do
        assert((type(id)=="number" and id > 9999) or (type(id)=="string" and #id >= 5), "Invalid ID Value")
        newTutorialArray[HashString(id)] = values
    end

    self.tutorials = newTutorialArray
end

function LibTutorial:Initialize(tutorialArray)
    self:RegisterTutorials(tutorialArray)
end

-----
--New 'Get' Functions
-----

function LibTutorial:GetLibTutorialType(tutorialId)
    return self.tutorials[tutorialId].tutorialType
end

function LibTutorial:GetLibTutorialDisplayPriority(tutorialId)
	return self.tutorials[tutorialId].displayPriority
end

function LibTutorial:GetLibTutorialInfo(tutorialId)
	local title = self.tutorials[tutorialId].title
	local text = self.tutorials[tutorialId].text

	return title, text
end

-----
--TUTORIAL_TYPE_HUD_BRIEF
-----

-----
--TUTORIAL_TYPE_HUD_INFO_BOX
-----

--[[function ZO_HudInfoTutorial:OnLCQUpdate()
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

local BASE_TUTORIAL_HEIGHT = 170
local AUTO_CLOSE_MS = 15 * 1000
function ZO_HudInfoTutorial:DisplayLCQTutorial(tutorialId)
    self.tutorialIndex = tutorialId
    local isInGamepadMode = IsInGamepadPreferredMode()
    if isInGamepadMode then
        self.tutorial = self.tutorialGamepad
        self.tutorialAnimation = self.tutorialAnimationGamepad
    else
        self.tutorial = self.tutorialKeyboard
        self.tutorialAnimation = self.tutorialAnimationKeyboard
    end

    local title, description = GetLCQTutorialInfo(tutorialId)
    local helpCategoryIndex, helpIndex = nil, nil --GetTutorialLinkedHelpInfo(tutorialId)
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
end

function ZO_HudInfoTutorial:OnDisplayLCQTutorial(tutorialId, priority)
    -- Can to be overriden for custom queueing behavior, occurs when a tutorial matching GetTutorialType() is requested to be displayed
    if not self:IsTutorialDisplayedOrQueued(tutorialId) then
        if not self:CanShowTutorial() then
            local _, insertPosition = zo_binarysearch(priority, self.queue, BinaryInsertComparer)
            table.insert(self.queue, insertPosition, tutorialId)
        else
            self:DisplayLCQTutorial(tutorialId)
        end
    end
end]]

-----
--TUTORIAL_TYPE_UI_INFO_BOX
-----

--[[function ZO_UiInfoBoxTutorial:DisplayLCQTutorial(tutorialId)
    self.title, self.description = GetLCQTutorialInfo(tutorialId)

    self:SetCurrentlyDisplayedTutorialIndex(tutorialId)
    self.gamepadMode = IsInGamepadPreferredMode()

    if self.gamepadMode then
        ZO_Dialogs_ShowGamepadDialog("UI_TUTORIAL_GAMEPAD", { tutorialIndex = tutorialId, owner = self })
    else
        self.dialogInfo.title.text = self.title
        self.dialogDescription:SetText(self.description)
        local descriptionHeight = self.dialogDescription:GetTextHeight() + ZO_TUTORIAL_DIALOG_DESCRIPTION_TOTAL_PADDING_Y
        self.dialogScrollChild:SetHeight(descriptionHeight)

        --To prevent having this pane scroll over a tiny amount of space we only force it to scroll if it hits the hard max height. This guarentees that it will scroll at least (hard - soft UI units).
        local paneHeight = descriptionHeight
        if paneHeight > ZO_TUTORIAL_DIALOG_HARD_MAX_HEIGHT then
            paneHeight = ZO_TUTORIAL_DIALOG_SOFT_MAX_HEIGHT
        end
        self.dialogPane:SetHeight(paneHeight)

        ZO_Scroll_ResetToTop(self.dialogPane)
        ZO_Dialogs_ShowDialog("UI_TUTORIAL", { tutorialIndex = tutorialId, owner = self })
    end
end

function ZO_UiInfoBoxTutorial:OnDisplayLCQTutorial(tutorialId, priority)
    if not IsGameCameraActive() or SCENE_MANAGER:IsInUIMode() then
        if not self:IsTutorialDisplayedOrQueued(tutorialId) then
            if self:CanShowTutorial() then
                self:DisplayLCQTutorial(tutorialId)
            end
        end
    end
end]]

-----
-----

local function OnLoad(e, addOnName)
	if addOnName ~= "LibTutorial" then return end

    TUTORIAL_SYSTEM:AddTutorialHandler(LibTutorial_BriefHud:New(ZO_Tutorial))
    TUTORIAL_SYSTEM:AddTutorialHandler(LibTutorial_HudInfo:New(ZO_Tutorial))

	EVENT_MANAGER:UnregisterForEvent("LibTutorial", EVENT_ADD_ON_LOADED) 
end
EVENT_MANAGER:RegisterForEvent("LibTutorial", EVENT_ADD_ON_LOADED, OnLoad)