LIB_TUTORIAL_TYPE_POINTER_BOX = HashString("LIB_TUTORIAL_TYPE_POINTER_BOX")
local POINTER_BOX_DESC_FMT = "<<<Z:1>>>\n\n<<2>>"

-----
--Pointer Box Manager
-----

LibTut_PointerBoxManager = ZO_Object:Subclass()

function LibTut_PointerBoxManager:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function LibTut_PointerBoxManager:Initialize()
    local function Factory(pool)
        local control = ZO_ObjectPool_CreateNamedControl("LibTut_PointerBox_KeyboardControl", "LibTut_PointerBox_KeyboardControl", pool, GuiRoot)
        return ZO_PointerBox_Keyboard:New(control)
    end
    self.pool = ZO_ObjectPool:New(Factory, ZO_ObjectPool_DefaultResetObject)
end

function LibTut_PointerBoxManager:Acquire()
    local pointerBox, poolKey = self.pool:AcquireObject()
    pointerBox:SetPoolKey(poolKey)
    return pointerBox
end

function LibTut_PointerBoxManager:Release(pointerBox)
    self.pool:ReleaseObject(pointerBox:GetPoolKey())
end

LIB_TUT_POINTER_BOXES = LibTut_PointerBoxManager:New()

LibTutorial_PointerBox = ZO_TutorialHandlerBase:Subclass()

function LibTutorial_PointerBox:Initialize(parent)
	self.tutorial = CreateControlFromVirtual(parent:GetName(), parent, "LibTut_PointerBoxTutorialTip", "LibTutorialPointerBoxTip")
end

do
	libTut_triggerLayoutInfo = {}

	function LibTutorial_PointerBox:RegisterTriggerLayoutInfo(tutorialTrigger, parent, fragment, anchor, optionalParams)
		libTut_triggerLayoutInfo[tutorialTrigger] =
		{
			parent = parent,
			fragment = fragment,
			anchor = anchor,
			optionalParams = optionalParams,
		}
	end

	function LibTutorial_PointerBox:GetTriggerLayoutInfo(tutorialTrigger)
		return libTut_triggerLayoutInfo[tutorialTrigger]
	end
end

function LibTutorial_PointerBox:SuppressTutorials(suppress, reason)
	--Suppression is disabled in LibTutorial_PointerBox
end

function LibTutorial_PointerBox:GetTutorialInfo(tutorialId)
	--Currently Unused
end

function LibTutorial_PointerBox:SetTutorialSeen(tutorialId)
	--User Overridden
end

function LibTutorial_PointerBox:DisplayTutorial(tutorialId, title, desc, tutorialType, tutorialDetails)
	self.tutorialId = tutorialId
	local title = (tutorialDetails and tutorialDetails.title) or title
	local description = (tutorialDetails and tutorialDetails.desc) or desc
	local trigger = tutorialType
	local layoutInfo = self:GetTriggerLayoutInfo(trigger)

	description = (title and zo_strformat(POINTER_BOX_DESC_FMT, title, description)) or description
	self.tutorial:SetText(description)

	self.pointerBox = LIB_TUT_POINTER_BOXES:Acquire()
	self.pointerBox:SetContentsControl(self.tutorial)
	self.pointerBox:SetParent(layoutInfo.parent)
	self.pointerBox:SetCloseable(true)
	self.pointerBox:SetReleaseOnHidden(true)

	self.pointerBox:SetOnHiddenCallback(function()
		self.pointerBox = nil
		self:RemoveTutorial(tutorialId)
	end)

	layoutInfo.anchor:Set(self.pointerBox)
	if layoutInfo.fragment then
		self.pointerBox:SetHideWithFragment(layoutInfo.fragment)
	end
	self:SetOptionalPointerBoxParams(layoutInfo.optionalParams)
	self.pointerBox:Commit()
	self.pointerBox:Show()

	local parent = self.tutorial:GetParent()
	if tutorialDetails then
		parent:SetHandler("OnMouseUp", function(control, button, upInside)
			if upInside and self.pointerBox.closeable then
				local ANIMATE = false
				self.pointerBox:Hide(ANIMATE)

				if tutorialDetails then
					tutorialDetails.tutObj:OnTutorialCurrentStepFin(tutorialDetails)
					local nextTutorialStepIndex = tutorialDetails.nextTutorialStepIndex

					if button == MOUSE_BUTTON_INDEX_LEFT then
						zo_callLater(function()
							if tutorialDetails.nextCustomCallback and tutorialDetails.tutSteps[nextTutorialStepIndex] then
								tutorialDetails.nextCustomCallback(tutorialDetails.tutSteps[nextTutorialStepIndex].id)
							end
							tutorialDetails.tutObj:StartTutorialSequence(tutorialDetails.tutSteps, tutorialDetails.nextTutorialStepIndex)
						end, 1000)	
					elseif MOUSE_BUTTON_INDEX_RIGHT then
						if tutorialDetails.exitCustomCallback then
							tutorialDetails.exitCustomCallback(tutorialDetails.tutSteps[nextTutorialStepIndex-1].id)
						end
					end
				end
			end
		end, LibTutorialSetup.name)
	end

	self.tutorialDetails = tutorialDetails

	self:SetTutorialSeen(tutorialId)
	self:SetCurrentlyDisplayedTutorialIndex(tutorialId, trigger)

	return true
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

function LibTutorial_PointerBox:OnDisplayTutorial(tutorialId, priority, title, desc, tutorialType, tutorialDetails)
	 if tutorialId ~= self:GetCurrentlyDisplayedTutorialIndex() then
		if self:CanShowTutorial() then
			if tutorialDetails then
				if tutorialDetails.iniCustomCallback then
					tutorialDetails.iniCustomCallback()
				end

				if tutorialDetails.scrollToCtrl then
					zo_callLater(function() tutorialDetails.scrollToCtrl() end, 100)
				end

				tutorialDetails.backdropCtrl:SetHidden(false)
			end

			return self:DisplayTutorial(tutorialId, title, desc, tutorialType, tutorialDetails)
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

function LibTutorial_PointerBox:RemoveTutorial(tutorialId)
	if self:GetCurrentlyDisplayedTutorialIndex() == tutorialId then
		if self.tutorialDetails then 
			self.tutorialDetails.tutObj:OnTutorialCurrentStepFin(self.tutorialDetails)
		end

		self:SetCurrentlyDisplayedTutorialIndex(nil)
		if self.pointerBox then
			self.pointerBox:Hide()
		end
	end
end

function LibTutorial_PointerBox:GetTutorialType()
	return LIB_TUTORIAL_TYPE_POINTER_BOX
end

function LibTutorial_PointerBox:ClearAll()
	self:SetCurrentlyDisplayedTutorialIndex(nil)
end