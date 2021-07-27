local AUTO_CLOSE_MS = 1 * 10 * 1000
LIB_TUTORIAL_TYPE_HUD_BRIEF = HashString("LIB_TUTORIAL_TYPE_HUD_BRIEF")

LibTutorial_BriefHud = ZO_TutorialHandlerBase:Subclass()

function LibTutorial_BriefHud:Initialize(parent)    
    self.tutorial = CreateControlFromVirtual(parent:GetName(), parent, "ZO_BriefHudTutorialTip", "LibTutorialBriefHudTip")
    
    local function UpdateDescription()
        local tutorialIndex = self:GetCurrentlyDisplayedTutorialIndex()
        if tutorialIndex then
            local title, description = GetTutorialInfo(tutorialIndex) --Grab the Gamepad/Keyboard binding
            self.tutorial:SetText(description)
        end
    end

    local function UpdateTemplate()
        UpdateDescription()
        if IsInGamepadPreferredMode() then
            self.tutorial:SetWidth(850)
            self.tutorial:SetFont("ZoFontGamepad42")
            self.tutorial:ClearAnchors()
            self.tutorial:SetAnchor(BOTTOM, nil, BOTTOM, 0, ZO_COMMON_INFO_DEFAULT_GAMEPAD_BOTTOM_OFFSET_Y)
        else
            self.tutorial:SetWidth(650)
            self.tutorial:SetFont("ZoInteractionPrompt")
            self.tutorial:ClearAnchors()
            self.tutorial:SetAnchor(BOTTOM, nil, BOTTOM, 0, ZO_COMMON_INFO_DEFAULT_KEYBOARD_BOTTOM_OFFSET_Y)
        end
    end

    self.tutorial:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, UpdateTemplate)
    --in case the player changes the keybind or resets to default while a tutorial is up.
    self.tutorial:RegisterForEvent(EVENT_KEYBINDING_SET, UpdateDescription)
    self.tutorial:RegisterForEvent(EVENT_KEYBINDINGS_LOADED, UpdateDescription)
    
    self.tutorialAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("HudBriefTutorialAnimation", self.tutorial)
    self.tutorialAnimation:SetHandler("OnStop", function(timeline) 
        if not timeline:IsPlayingBackward() then 
            FireTutorialHiddenEvent(self.tutorialIndex)
            SHARED_INFORMATION_AREA:SetHidden(self.tutorial, true) 
        end 
    end)

    EVENT_MANAGER:RegisterForUpdate(self.tutorial:GetName() .. "OnUpdate", 0, function() self:OnUpdate() end)
    EVENT_MANAGER:RegisterForEvent("BriefHudTutorial", EVENT_PLAYER_DEAD, function() self:ClearAll() end)

    SHARED_INFORMATION_AREA:AddTutorial(self.tutorial)

    UpdateTemplate()
    self:ClearAll()
end

function LibTutorial_BriefHud:SetHidden(hide)
    self.tutorial:SetHidden(hide)
end

function LibTutorial_BriefHud:GetTutorialType()
    return LIB_TUTORIAL_TYPE_HUD_BRIEF
end

function LibTutorial_BriefHud:SuppressTutorials(suppress, reason)
    -- Suppression is disabled since we're potentially disabling 
    -- input so the player ought to know why
end

--Could use a "Must Implement"?
function LibTutorial_BriefHud:SetTutorialSeen(tutorialIndex)
    SetTutorialSeen(tutorialIndex)
    d("Tutorial Set to Seen")
end

function LibTutorial_BriefHud:DisplayTutorial(tutorialIndex, title, desc)
	local title, description = title, desc

	self:SetTutorialSeen(tutorialIndex)
	self.tutorial:SetText(description)
	self.tutorialAnimation:PlayBackward()
    self:SetCurrentlyDisplayedTutorialIndex(tutorialIndex)

    self.displayedTutorialIsActionRequired = false --IsTutorialActionRequired(tutorialIndex)
    self.currentlyDisplayedTutorialTimeLeft = (not self.displayedTutorialIsActionRequired) and AUTO_CLOSE_MS

	SHARED_INFORMATION_AREA:SetHidden(self.tutorial, false)
end

function LibTutorial_BriefHud:OnDisplayTutorial(tutorialIndex, priority, title, desc)
     if tutorialIndex ~= self:GetCurrentlyDisplayedTutorialIndex() then
        if not self:CanShowTutorial() then
            self:ClearAll()
        end
        self:DisplayTutorial(tutorialIndex, title, desc)
    end
end

function LibTutorial_BriefHud:RemoveTutorial(tutorialIndex)
    if self:GetCurrentlyDisplayedTutorialIndex() == tutorialIndex then
        if self.displayedTutorialIsActionRequired then
            self.displayedTutorialIsActionRequired = nil
        end

        self:SetCurrentlyDisplayedTutorialIndex(nil)
        self.currentlyDisplayedTutorialTimeLeft = nil
        self.tutorialAnimation:PlayForward()
    end
end

function LibTutorial_BriefHud:OnUpdate()
    if self.displayedTutorialIsActionRequired then return end

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

function LibTutorial_BriefHud:ClearAll()
    self:SetCurrentlyDisplayedTutorialIndex(nil)
    self.currentlyDisplayedTutorialTimeLeft = nil
    self.tutorialAnimation:PlayForward()

    if self.displayedTutorialIsActionRequired then
        self.displayedTutorialIsActionRequired = nil
        ClearActiveActionRequiredTutorial()        
    end

    self.queue = {}
end