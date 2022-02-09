--Set up a Must Implement (SetTutorialSeen)

-----
--Initialize
-----

LibTutorialSetup = {}
local LibTutorial = ZO_Object:Subclass()

function LibTutorialSetup.New(tutorialArray)
	local libTutorial = ZO_Object:New(LibTutorial)
	libTutorial:Initialize(tutorialArray)
	return libTutorial
end

function LibTutorial:Initialize(tutorialArray)
	self.highlightCtrls = {}
	self:RegisterTutorials(tutorialArray)

	local obj = self
	function LibTutorial_HudInfo:SetTutorialSeen(tutorialIndex)
		obj:SetTutorialSeen(tutorialIndex)
	end
	function LibTutorial_BriefHud:SetTutorialSeen(tutorialIndex)
		obj:SetTutorialSeen(tutorialIndex)
	end
	function LibTutorial_UiInfoBox:SetTutorialSeen(tutorialIndex)
		obj:SetTutorialSeen(tutorialIndex)
	end
end

function LibTutorial:SetTutorialSeen(tutorialIndex)
	--Should Override
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

function LibTutorial:DisplayTutorial(tutorialIndex)
	local tutorialIndex = HashString(tutorialIndex)

	if not self.tutorials[tutorialIndex] then 
		CHAT_ROUTER:AddDebugMessage("<LibTutorial> No tutorialIndex found.")
	return end

	local tutorialType = self:GetLibTutorialType(tutorialIndex)

	if tutorialType == LIB_TUTORIAL_TYPE_UI_INFO_BOX then
		LibTutorial_TutorialDialog:ClearAnchors()
		LibTutorial_TutorialDialog:SetAnchor(CENTER, GuiRoot)
	end

	if TUTORIAL_SYSTEM.tutorialHandlers[tutorialType] then
		local priority = self:GetLibTutorialDisplayPriority(tutorialIndex)
		local title, desc = self:GetLibTutorialInfo(tutorialIndex)
		TUTORIAL_SYSTEM.tutorialHandlers[tutorialType]:OnDisplayTutorial(tutorialIndex, priority, title, desc)
	end
end

-----
--New 'Get' Functions
-----

function LibTutorial:GetLibTutorialType(tutorialIndex)
	return self.tutorials[tutorialIndex].tutorialType
end

function LibTutorial:GetLibTutorialInfo(tutorialIndex)
	local title = self.tutorials[tutorialIndex].title
	local text = self.tutorials[tutorialIndex].text

	return title, text
end

function LibTutorial:GetLibTutorialDisplayPriority(tutorialIndex)
	return self.tutorials[tutorialIndex].displayPriority
end

-----
--Tutorial sequence handling (could probably wind up usable for any controls)
-----

function LibTutorial:StartTutorialSequence(tutorialSteps, nextTutorialStepIndex)
	local tutorial
	local currentStepId
	local sequenceOptions = tutorialSteps.options

	if nextTutorialStepIndex and nextTutorialStepIndex > #tutorialSteps then
		CHAT_ROUTER:AddDebugMessage("<LibTutorial> Tutorial Sequence Finished.")
	elseif nextTutorialStepIndex then
		tutorial = tutorialSteps[nextTutorialStepIndex]
		currentStepId = HashString(tutorial.id)
	else
		nextTutorialStepIndex = 1
		tutorial = tutorialSteps[1]
		currentStepId = HashString(tutorial.id)
		CHAT_ROUTER:AddDebugMessage("<LibTutorial> Tutorial Sequence Started.")
	end

	if not tutorial then 
		CHAT_ROUTER:AddDebugMessage("<LibTutorial> No tutorialSteps found.")
	return end

	local tutorialType = sequenceOptions.tutorialType or LIB_TUTORIAL_TYPE_UI_INFO_BOX
	local anchorToControlData = tutorial.anchorToControlData

	if not anchorToControlData or not tutorialType == LIB_TUTORIAL_TYPE_UI_INFO_BOX then 
		CHAT_ROUTER:AddDebugMessage("<LibTutorial> Missing data or wrong tutorial type.")
	return end

	local anchorPoint, anchorTargetCtrlStr, relativePoint, offsetX, offsetY
	if type(anchorToControlData) == "table" then 
		anchorPoint, anchorTargetCtrlStr, relativePoint, offsetX, offsetY = unpack(anchorToControlData)
	elseif type(anchorToControlData) == "string" then
		anchorPoint, anchorTargetCtrlStr, relativePoint, offsetX, offsetY = LEFT, anchorToControlData, RIGHT, 100
	end

	local anchorTargetCtrl = GetControl(anchorTargetCtrlStr)

	if not anchorTargetCtrl or anchorTargetCtrl:IsHidden() then
		CHAT_ROUTER:AddDebugMessage("<LibTutorial> anchorTargetCtrl doesn't exist or is not visible.") 
	return end

	local tutorialCtrl = LibTutorial_TutorialDialog
	tutorialCtrl:ClearAnchors()
	tutorialCtrl:SetAnchor(anchorPoint or LEFT, anchorTargetCtrl, relativePoint, offsetX, offsetY)

	local anchorTargetCtrlX, anchorTargetCtrlY = anchorTargetCtrl:GetDimensions()

	local backdropCtrl = self.highlightCtrls[anchorTargetCtrlStr.."Backdrop"]
	if not backdropCtrl then
		backdropCtrl = CreateControl(anchorTargetCtrlStr.."Backdrop", anchorTargetCtrl, CT_BACKDROP)
		self.highlightCtrls[anchorTargetCtrlStr.."Backdrop"] = backdropCtrl

		local r, g, b = ZO_HIGHLIGHT_TEXT:UnpackRGB()
		backdropCtrl:SetEdgeColor(r, g, b, 1)
		backdropCtrl:SetCenterColor(r, g, b, 0.1)
		backdropCtrl:SetPixelRoundingEnabled(true)
		backdropCtrl:SetAnchor(CENTER, anchorTargetCtrl, CENTER)
		backdropCtrl:SetDimensions(anchorTargetCtrlX, anchorTargetCtrlY)
	else
		backdropCtrl:SetHidden(false)
	end

	local title = sequenceOptions.showStepNumInTitle and zo_strformat("<<1>> <<2>>/<<3>>", tutorial.title, nextTutorialStepIndex, #tutorialSteps) or tutorial.title

	local tutorialDetails = {tutSteps = tutorialSteps, tutObj = self, nextCustomCallback = tutorial.nextCustomCallback, backdropCtrl = backdropCtrl, title = title, desc = tutorial.text, nextTutorialStepIndex = nextTutorialStepIndex + 1}

	TUTORIAL_SYSTEM.tutorialHandlers[tutorialType]:OnDisplayTutorial(currentStepId, _, tutorialDetails)
end

-----
--LAM Panel
-----

local panelData = {
	type = "panel",
	name = 			"LibTutorial",
	displayName = 	"Lib Tutorial",
	author = 		"Alianym",
	version = 		"1.10",
	registerForDefaults = true,
}

local checkboxVal = false
local optionsTable = {
	[1] = {
		type = "header",
		name = "Example Header Name",
		width = "full",
		reference = "LibTutorialHeaderCtrl",
	},
	[2] = {
		type = "description",
		title = "Example Description Title",
		text = "Example Description Text",
		width = "full",
		reference = "LibTutorialDescriptionCtrl",
	},
	[3] = {
		type = "divider",
		width = "full",
		height = 10, -- (optional)
		alpha = 0.25, -- (optional)
		reference = "LibTutorialDividerCtrl",
	},
	[4] = {
		type = "checkbox",
		name = "Example Checkbox Name (1)",
		tooltip = "Example Checkbox Tooltip",
		getFunc = function() return checkboxVal end,
		setFunc = function(value) checkboxVal = value end,
		width = "full",
		default = false,
		--reference = "LibTutorialCheckBoxCtrl",
	},
	[5] = {
		type = "checkbox",
		name = "Example Checkbox Name (2)",
		tooltip = "Example Checkbox Tooltip",
		getFunc = function() return checkboxVal end,
		setFunc = function(value) checkboxVal = value end,
		width = "full",
		default = false,
		reference = "LibTutorialCheckBoxCtrl",
	},
	[6] = {
		type = "editbox",
		name = "Example Editbox Name",
		getFunc = function() return  end,
		setFunc = function(text)  end,
		tooltip = "Example Editbox Tooltip",
		isMultiline = true, -- boolean (optional)
		isExtraWide = true, -- boolean (optional)
		maxChars = 3000, -- number (optional)
		textType = TEXT_TYPE_ALL, -- number (optional) or function returning a number. Valid TextType numbers: TEXT_TYPE_ALL, TEXT_TYPE_ALPHABETIC, TEXT_TYPE_ALPHABETIC_NO_FULLWIDTH_LATIN, TEXT_TYPE_NUMERIC, TEXT_TYPE_NUMERIC_UNSIGNED_INT, TEXT_TYPE_PASSWORD
		width = "full", -- or "half" (optional)
		warning = "Example Editbox Warning.", -- or string id or function returning a string (optional)
		reference = "LibTutorialEditBox" -- unique global reference to control (optional)
	},
}

-----
-----

local function OnLoad(e, addOnName)
	if addOnName ~= "LibTutorial" then return end

	TUTORIAL_SYSTEM:AddTutorialHandler(LibTutorial_HudInfo:New(ZO_Tutorial))
	TUTORIAL_SYSTEM:AddTutorialHandler(LibTutorial_BriefHud:New(ZO_Tutorial))
	TUTORIAL_SYSTEM:AddTutorialHandler(LibTutorial_UiInfoBox:New(ZO_Tutorial))

	if LibAddonMenu2 then
		local LAM = LibAddonMenu2
		LAM:RegisterAddonPanel(addOnName, panelData)
		LAM:RegisterOptionControls(addOnName, optionsTable)
	end

	EVENT_MANAGER:UnregisterForEvent("LibTutorial", EVENT_ADD_ON_LOADED) 
end
EVENT_MANAGER:RegisterForEvent("LibTutorial", EVENT_ADD_ON_LOADED, OnLoad)