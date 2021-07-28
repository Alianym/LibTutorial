LibTutorial_PointerBox = ZO_TutorialHandlerBase:Subclass()

function LibTutorial_PointerBox:Initialize(parent)
    self.tutorial = CreateControlFromVirtual(parent:GetName(), parent, "ZO_PointerBoxTutorialTip", "LibTutorialPointerBoxTip")
end

do
    local g_triggerLayoutInfo = {}

    function LibTutorial_PointerBox:RegisterTriggerLayoutInfo(tutorialTrigger, parent, fragment, anchor, optionalParams)
        g_triggerLayoutInfo[tutorialTrigger] =
        {
            parent = parent,
            fragment = fragment,
            anchor = anchor,
            optionalParams = optionalParams,
        }
    end

    function LibTutorial_PointerBox:GetTriggerLayoutInfo(tutorialTrigger)
        return g_triggerLayoutInfo[tutorialTrigger]
    end
end

function LibTutorial_PointerBox:SuppressTutorials(suppress, reason)
    -- Suppression is disabled in LibTutorial_PointerBox
end

function LibTutorial_PointerBox:DisplayTutorial(tutorialIndex)
    self.tutorialIndex = tutorialIndex
    local title, description = GetTutorialInfo(tutorialIndex)
    local trigger = GetTutorialTrigger(tutorialIndex)
    local layoutInfo = self:GetTriggerLayoutInfo(trigger)


    self.tutorial:SetText(description)

    self.pointerBox = POINTER_BOXES:Acquire()
    self.pointerBox:SetContentsControl(self.tutorial)
    self.pointerBox:SetParent(layoutInfo.parent)
    self.pointerBox:SetCloseable(true)
    self.pointerBox:SetReleaseOnHidden(true)

    self.pointerBox:SetOnHiddenCallback(function()
        self.pointerBox = nil
        self:RemoveTutorial(tutorialIndex)
    end)
    layoutInfo.anchor:Set(self.pointerBox)
    if layoutInfo.fragment then
        self.pointerBox:SetHideWithFragment(layoutInfo.fragment)
    end
    self:SetOptionalPointerBoxParams(layoutInfo.optionalParams)
    self.pointerBox:Commit()
    self.pointerBox:Show()

    SetTutorialSeen(tutorialIndex)
    self:SetCurrentlyDisplayedTutorialIndex(tutorialIndex, trigger)
end

do
    local DEFAULT_VERTICAL_ALIGNMENT = TEXT_ALIGN_TOP
    local DEFAULT_HORIZONTAL_ALIGNMENT = TEXT_ALIGN_CENTER
    local DEFAULT_WIDTH = 290
    local DEFAULT_HEIGHT = 0

    function LibTutorial_PointerBox:SetOptionalPointerBoxParams(optionalParams)
        if optionalParams then
            if optionalParams.dimensionConstraintsMinX or optionalParams.dimensionConstraintsMinY or optionalParams.dimensionConstraintsMaxX or optionalParams.dimensionConstraintsMaxY then
                self.tutorial:SetDimensionConstraints(optionalParams.dimensionConstraintsMinX or 0, optionalParams.dimensionConstraintsMinY or 0, optionalParams.dimensionConstraintsMaxX or 0, optionalParams.dimensionConstraintsMaxY or 0)
            else
                self.tutorial:SetDimensions(optionalParams.width or DEFAULT_WIDTH, optionalParams.height or DEFAULT_HEIGHT)
            end
            self.tutorial:SetVerticalAlignment(optionalParams.verticalAlignment or DEFAULT_VERTICAL_ALIGNMENT)
            self.tutorial:SetHorizontalAlignment(optionalParams.horizontalAlignment or DEFAULT_HORIZONTAL_ALIGNMENT)
        else
            self.tutorial:SetDimensionConstraints(0, 0, 0, 0)
            self.tutorial:SetDimensions(DEFAULT_WIDTH, DEFAULT_HEIGHT)
            self.tutorial:SetVerticalAlignment(DEFAULT_VERTICAL_ALIGNMENT)
            self.tutorial:SetHorizontalAlignment(DEFAULT_HORIZONTAL_ALIGNMENT)
        end
    end
end

function LibTutorial_PointerBox:OnDisplayTutorial(tutorialIndex, priority)
     if tutorialIndex ~= self:GetCurrentlyDisplayedTutorialIndex() then
        if self:CanShowTutorial() then
            self:DisplayTutorial(tutorialIndex)
        end
    end
end

function LibTutorial_PointerBox:SetCurrentlyDisplayedTutorialIndex(currentlyDisplayedTutorialIndex, currentlyDisplayedTutorialTrigger)
    self.currentlyDisplayedTutorialIndex = currentlyDisplayedTutorialIndex
    self.currentlyDisplayedTutorialTrigger = currentlyDisplayedTutorialTrigger
end

function LibTutorial_PointerBox:RemoveTutorialByTrigger(tutorialTrigger)
    if self.currentlyDisplayedTutorialTrigger == tutorialTrigger then
        self:RemoveTutorial(self:GetCurrentlyDisplayedTutorialIndex())
    end
end

function LibTutorial_PointerBox:RemoveTutorial(tutorialIndex)
    if self:GetCurrentlyDisplayedTutorialIndex() == tutorialIndex then
        self:SetCurrentlyDisplayedTutorialIndex(nil)
        if self.pointerBox then
            self.pointerBox:Hide()
        end
    end
end

function LibTutorial_PointerBox:GetTutorialType()
    return TUTORIAL_TYPE_POINTER_BOX
end

function LibTutorial_PointerBox:ClearAll()
    self:SetCurrentlyDisplayedTutorialIndex(nil)
end