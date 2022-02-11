-----
--Documentation
-----
--LibTutorial
--An ESO AddOn library for creating Tutorial notifications
--Version: 1.10
--Author: Alianym


-----
--TODOs
-----
--Set up a Must Implement (SetTutorialSeen)


-----
--Local variables
-----

--local ref. variables for performance gain on re-used _G table variables
local tos = tostring
local zostrfor = zo_strformat

local TUTSYS = TUTORIAL_SYSTEM


-----
--Local functions
-----


-----
--Classes
-----

--Class of library
local LibTutorial = ZO_Object:Subclass()


-----
--Library LibTutorial object creation
-----

--Library global setup table
local libTutSetup = {
	name 	= 	"LibTutorial",
	author  =   "Alianym",
	version = 	"1.10"
}
LibTutorialSetup = libTutSetup
local libName = libTutSetup.name

--Library object creation function. Use this to create a new instance of the LibTutorial class for your addon.
--Returns: objectTable LibTutorialObject
function libTutSetup.New(tutorialArray)
	local libTutorialObject = ZO_Object:New(LibTutorial)
	libTutorialObject:Initialize(tutorialArray)
	return libTutorialObject
end


-----
--Initialize class
-----
function LibTutorial:Initialize(tutorialArray)
	local obj = self
	obj.highlightCtrls = {}
	obj:RegisterTutorials(tutorialArray)

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
	--Should be overriden in subclasses
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
	local tutorialIndexHashed = HashString(tutorialIndex)

	if not self.tutorials[tutorialIndexHashed] then
		d("<LibTutorial> No tutorialIndex found: " ..tos(tutorialIndex))
	return end

	local tutorialType = self:GetLibTutorialType(tutorialIndexHashed)

	if tutorialType == LIB_TUTORIAL_TYPE_UI_INFO_BOX then
		LibTutorial_TutorialDialog:ClearAnchors()
		LibTutorial_TutorialDialog:SetAnchor(CENTER, GuiRoot)
	end

	if TUTSYS.tutorialHandlers[tutorialType] then
		local priority = self:GetLibTutorialDisplayPriority(tutorialIndexHashed)
		local title, desc = self:GetLibTutorialInfo(tutorialIndexHashed)
		TUTSYS.tutorialHandlers[tutorialType]:OnDisplayTutorial(tutorialIndexHashed, priority, title, desc, nil)
	end
end

-----
--New 'Get' Functions
-----

function LibTutorial:GetLibTutorialType(tutorialIndex)
	return self.tutorials[tutorialIndex].tutorialType
end

function LibTutorial:GetLibTutorialInfo(tutorialIndex)
	local tutsData = self.tutorials[tutorialIndex]
	local title = tutsData.title
	local text = tutsData.text

	return title, text
end

function LibTutorial:GetLibTutorialDisplayPriority(tutorialIndex)
	return self.tutorials[tutorialIndex].displayPriority
end

-----
--Tutorial sequence handling (could probably wind up usable for any controls)
-----

function LibTutorial:OnTutorialCurrentStepFin(tutorialDetails)
	tutorialDetails.backdropCtrl:SetHidden(true)
end

function LibTutorial:StartTutorialSequence(tutorialSteps, nextTutorialStepIndex)
	local tutorial
	local currentStepId
	local sequenceOptions = tutorialSteps.options

	if nextTutorialStepIndex and nextTutorialStepIndex > #tutorialSteps then
		d("<LibTutorial> Tutorial Sequence Finished.")
		return
	elseif nextTutorialStepIndex then
		tutorial = tutorialSteps[nextTutorialStepIndex]
		currentStepId = HashString(tutorial.id)
	else
		nextTutorialStepIndex = 1
		tutorial = tutorialSteps[1]
		currentStepId = HashString(tutorial.id)
		d("<LibTutorial> Tutorial Sequence Started.")
	end

	if not tutorial then 
		d("<LibTutorial> No tutorialSteps found.")
	return end

	local tutorialType = sequenceOptions.tutorialType or LIB_TUTORIAL_TYPE_UI_INFO_BOX
	local anchorToControlData = tutorial.anchorToControlData

	if not anchorToControlData or not tutorialType == LIB_TUTORIAL_TYPE_UI_INFO_BOX then 
		d("<LibTutorial> Missing data or wrong tutorial type.")
	return end

	local anchorPoint, anchorTargetCtrlStr, relativePoint, offsetX, offsetY
	local anchorToDataType = type(anchorToControlData)
	if anchorToDataType == "table" then
		anchorPoint, anchorTargetCtrlStr, relativePoint, offsetX, offsetY = unpack(anchorToControlData)
	elseif anchorToDataType == "string" then
		anchorPoint, anchorTargetCtrlStr, relativePoint, offsetX, offsetY = LEFT, anchorToControlData, RIGHT, 100
	end

	local anchorTargetCtrl = GetControl(anchorTargetCtrlStr)

	if not anchorTargetCtrl or anchorTargetCtrl:IsHidden() then
		d("<LibTutorial> anchorTargetCtrl doesn't exist or is not visible.")
	return end

	local tutorialCtrl = LibTutorial_TutorialDialog
	tutorialCtrl:ClearAnchors()
	tutorialCtrl:SetAnchor(anchorPoint or LEFT, anchorTargetCtrl, relativePoint, offsetX, offsetY)

	local anchorTargetCtrlX, anchorTargetCtrlY = anchorTargetCtrl:GetDimensions()

	local backdropName = anchorTargetCtrlStr.."Backdrop"
	local backdropCtrl = self.highlightCtrls[backdropName]
	if not backdropCtrl then
		backdropCtrl = CreateControl(backdropName, anchorTargetCtrl, CT_BACKDROP)
		self.highlightCtrls[backdropName] = backdropCtrl

		local r, g, b = ZO_HIGHLIGHT_TEXT:UnpackRGB()
		backdropCtrl:SetEdgeColor(r, g, b, 1)
		backdropCtrl:SetCenterColor(r, g, b, 0.1)
		backdropCtrl:SetPixelRoundingEnabled(true)
		backdropCtrl:SetAnchor(CENTER, anchorTargetCtrl, CENTER)
		backdropCtrl:SetDimensions(anchorTargetCtrlX, anchorTargetCtrlY)
	else
		backdropCtrl:SetHidden(false)
	end
	local tutTitle = tutorial.title
	local title = sequenceOptions.showStepNumInTitle and zostrfor("<<1>> <<2>>/<<3>>", tutTitle, nextTutorialStepIndex, #tutorialSteps) or tutTitle

	local tutorialDetails = {
		tutSteps = tutorialSteps,
		tutObj = self,
		nextCustomCallback = tutorial.nextCustomCallback,
		exitCustomCallback = tutorial.exitCustomCallback,
		backdropCtrl = backdropCtrl,
		title = title,
		desc = tutorial.text,
		nextTutorialStepIndex = nextTutorialStepIndex + 1
	}

	TUTSYS.tutorialHandlers[tutorialType]:OnDisplayTutorial(currentStepId, nil, nil, nil, tutorialDetails)
end

-----
--LAM Panel
-----

local panelData = {
	type = "panel",
	name = 			libName,
	displayName = 	libName,
	author = 		libTutSetup.author,
	version = 		libTutSetup.version,
	registerForDefaults = true,
}

local checkboxVal = false
local optionsTable = {
	{
		type = "header",
		name = "Example Header Name",
		width = "full",
		reference = "LibTutorialHeaderCtrl",
	},
	{
		type = "description",
		title = "Example Description Title",
		text = "Example Description Text",
		width = "full",
		reference = "LibTutorialDescriptionCtrl",
	},
	{
		type = "divider",
		width = "full",
		height = 10, -- (optional)
		alpha = 0.25, -- (optional)
		reference = "LibTutorialDividerCtrl",
	},
	{
		type = "checkbox",
		name = "Example Checkbox Name (1)",
		tooltip = "Example Checkbox Tooltip",
		getFunc = function() return checkboxVal end,
		setFunc = function(value) checkboxVal = value end,
		width = "full",
		default = false,
		--reference = "LibTutorialCheckBoxCtrl",
	},
	{
		type = "checkbox",
		name = "Example Checkbox Name (2)",
		tooltip = "Example Checkbox Tooltip",
		getFunc = function() return checkboxVal end,
		setFunc = function(value) checkboxVal = value end,
		width = "full",
		default = false,
		reference = "LibTutorialCheckBoxCtrl",
	},
	{
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
	if addOnName ~= libName then return end

	TUTSYS:AddTutorialHandler(LibTutorial_HudInfo:New(ZO_Tutorial))
	TUTSYS:AddTutorialHandler(LibTutorial_BriefHud:New(ZO_Tutorial))
	TUTSYS:AddTutorialHandler(LibTutorial_UiInfoBox:New(ZO_Tutorial))

	if LibAddonMenu2 then
		local LAM = LibAddonMenu2
		LAM:RegisterAddonPanel(addOnName, panelData)
		LAM:RegisterOptionControls(addOnName, optionsTable)
	end

	EVENT_MANAGER:UnregisterForEvent(libName, EVENT_ADD_ON_LOADED)
end
EVENT_MANAGER:RegisterForEvent(libName, EVENT_ADD_ON_LOADED, OnLoad)
