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
--Local library info
-----

--Library global setup table
local libTutSetup = {
	name 	= 	"LibTutorial",
	author  =   "Alianym",
	version = 	"1.10",

	tutorialHandlers = {}
}
--Library global variable
LibTutorialSetup = libTutSetup
local LAM

-----
--Local variables
-----

--local ref. variables for performance gain on re-used _G table variables
local tos = tostring
local zostrfor = zo_strformat

--ZOs controls
local zoTutorialCtrl = ZO_Tutorial

--ZOs tables/objects
local EM = EVENT_MANAGER
local CR = CHAT_ROUTER
local TUTSYS = TUTORIAL_SYSTEM

--Library locals
local libName = libTutSetup.name
local chatErrorColorPrefix = "|cFF0000[ERROR]"
local chatColorSuffix = "|r"
local chatLibPrefix = "<" .. libName ..">"

-----
--Local functions
-----

local function chatOutputToUser(msgText, isError)
	if not msgText then return end
	isError = isError or false
	msgText = (isError and (chatErrorColorPrefix .. msgText .. chatColorSuffix)) or msgText
	CR:AddSystemMessage(chatLibPrefix .. msgText)
end

local function addTutorialHandler(tutorialTypeClass, tutorialControl)
	tutorialControl = tutorialControl or zoTutorialCtrl
	TUTSYS:AddTutorialHandler(tutorialTypeClass:New(tutorialControl))
end


-----
--Classes
-----

--Class of library
local LibTutorial = ZO_Object:Subclass()


-----
--Library LibTutorial object creation
-----

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
	self.highlightCtrls = {}
	self:RegisterTutorials(tutorialArray)
end

function LibTutorial:SetTutorialSeen(tutorialId)
	--Should be overriden in subclasses
end

function LibTutorial:RegisterTutorials(tutorialArray)
	if self.tutorials or not tutorialArray then return end
	local newTutorialArray = {}

	for id, values in pairs(tutorialArray) do
		local idType = type(id)
		assert((idType=="number" and id > 9999) or (idType=="string" and #id >= 5), "Invalid ID Value")
		newTutorialArray[HashString(id)] = values
	end

	self.tutorials = newTutorialArray
end

local function LibTutorial_PointerBoxSetup(tutorialType, anchorToControlData, fragment)
	if(not anchorToControlData) or tutorialType ~= LIB_TUTORIAL_TYPE_POINTER_BOX then 
		chatOutputToUser("Missing data or wrong tutorial type.", true)
	return end

	local anchorPoint, anchorTargetCtrlStr, relativePoint, offsetX, offsetY
	local anchorToDataType = type(anchorToControlData)
	if anchorToDataType == "table" then
		anchorPoint, anchorTargetCtrlStr, relativePoint, offsetX, offsetY = unpack(anchorToControlData)
	elseif anchorToDataType == "string" then
		anchorPoint, anchorTargetCtrlStr, relativePoint, offsetX, offsetY = LEFT, anchorToControlData, RIGHT, 0
	end

	local anchorTargetCtrl = GetControl(anchorTargetCtrlStr)

	if (not anchorTargetCtrl) or anchorTargetCtrl:IsHidden() then
		chatOutputToUser("anchorTargetCtrl doesn't exist or is not visible.", true)
	return end

	local fragment = fragment or nil
	local tutorialAnchor = ZO_Anchor:New(anchorPoint, anchorTargetCtrl, relativePoint, offsetX, offsetY)
	TUTSYS.tutorialHandlers[tutorialType]:RegisterTriggerLayoutInfo(tutorialType, GuiRoot, fragment, tutorialAnchor, optionalParams)

	return true, anchorTargetCtrlStr, anchorTargetCtrl
end

function LibTutorial:DisplayTutorial(tutorialId, anchorToControlData, fragment)
	local tutorialIdHashed = HashString(tutorialId)

	if not self.tutorials[tutorialIdHashed] then
		chatOutputToUser("No tutorialId found: " ..tos(tutorialId), true)
		return
	end

	local tutorialType = self:GetLibTutorialType(tutorialIdHashed)

	if TUTSYS.tutorialHandlers[tutorialType] then
		--Handles Pointer Box when not in a sequence
		if tutorialType == LIB_TUTORIAL_TYPE_POINTER_BOX then
			local tutsData = self.tutorials[tutorialIdHashed]

			local fragment = tutsData.fragment
			local anchorToControlData = tutsData.anchorToControlData

			if not LibTutorial_PointerBoxSetup(tutorialType, anchorToControlData, fragment) then 
				return end
		end

		local priority = self:GetLibTutorialDisplayPriority(tutorialIdHashed)
		local title, desc = self:GetLibTutorialInfo(tutorialIdHashed)
		return TUTSYS.tutorialHandlers[tutorialType]:OnDisplayTutorial(tutorialIdHashed, priority, title, desc, tutorialType)
	end
end

-----
--New 'Get' Functions
-----

function LibTutorial:GetLibTutorialType(tutorialId)
	return self.tutorials[tutorialId].tutorialType
end

function LibTutorial:GetLibTutorialInfo(tutorialId)
	local tutsData = self.tutorials[tutorialId]
	local title = tutsData.title
	local text = tutsData.text

	return title, text
end

function LibTutorial:GetLibTutorialDisplayPriority(tutorialId)
	return self.tutorials[tutorialId].displayPriority
end

-----
--Tutorial sequence handling (could probably wind up usable for any controls, but currently only works with LIB_TUTORIAL_TYPE_POINTER_BOX)
-----

function LibTutorialSetSubMenuContainerIsOpen(control, open)
	if not control then return end

	while control:GetName() ~= "GuiRoot" and control do
		if control.open ~= nil then
			if control.disabled then return end
			if control.open == open then 
				return end

			control.open = not control.open
			if open then
				control.animation:PlayFromStart()
			else
				control.animation:PlayFromEnd()
			end
		end

		control = control:GetParent()
	end	
end

function LibTutorial:OnTutorialCurrentStepFin(tutorialDetails)
	tutorialDetails.backdropCtrl:SetHidden(true)
end

function LibTutorial:StartTutorialSequence(tutorialSteps, nextTutorialStepIndex)
	local tutorial
	local currentStepId
	local sequenceOptions = tutorialSteps.options

	if nextTutorialStepIndex and nextTutorialStepIndex > #tutorialSteps then
		--chatOutputToUser("Tutorial Sequence Finished.")
		return
	elseif nextTutorialStepIndex then
		tutorial = tutorialSteps[nextTutorialStepIndex]
		currentStepId = HashString(tutorial.id)
		--chatOutputToUser("Tutorial Sequence Continuing.")
	else
		nextTutorialStepIndex = 1
		tutorial = tutorialSteps[1]
		currentStepId = HashString(tutorial.id)
		--chatOutputToUser("Tutorial Sequence Starting.")
	end

	if not tutorial then 
		--chatOutputToUser("No tutorialSteps found.", true)
	return end

	local tutorialType = LIB_TUTORIAL_TYPE_POINTER_BOX --sequenceOptions.tutorialType or LIB_TUTORIAL_TYPE_POINTER_BOX (currently this is enforced)
	local anchorToControlData = tutorial.anchorToControlData

	local fragment, scrollCtrl
	if sequenceOptions.isLAMPanel then
		fragment = LAM:GetAddonSettingsFragment()
	else
		fragment = tutorial.fragment
		scrollCtrl = tutorial.scrollCtrl
	end

	local result, anchorTargetCtrlStr, anchorTargetCtrl = LibTutorial_PointerBoxSetup(tutorialType, anchorToControlData, fragment)
	if not result then return end

	if sequenceOptions.isLAMPanel then
		tutorial.scrollToCtrl = function()
			for i=1, LAM.currentAddonPanel:GetNumChildren() do
				local child = LAM.currentAddonPanel:GetChild(i)
				if child then
					local childName = child:GetName()
					if childName:find("LAMAddonPanelContainer") then
						scrollCtrl = child
						break
					end
				end
			end

			if not scrollCtrl then chatOutputToUser("No LAM scrollCtrl found!", true) return end

			ZO_Scroll_ScrollControlIntoCentralView(scrollCtrl, anchorTargetCtrl)
		end
	elseif scrollCtrl and scrollCtrl.scroll then
		tutorial.scrollToCtrl = function()
			ZO_Scroll_ScrollControlIntoCentralView(scrollCtrl, anchorTargetCtrl)
		end
	else chatOutputToUser("scrollCtrl invalid!", true) end

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
	--else
		--backdropCtrl:SetHidden(false)
	end
	backdropCtrl:SetHidden(true)

	local tutTitle = tutorial.title
	local title = sequenceOptions.showStepNumInTitle and zostrfor("<<1>> (<<2>>/<<3>>)", tutTitle, nextTutorialStepIndex, #tutorialSteps) or tutTitle

	local tutorialDetails = {
		tutSteps = tutorialSteps,
		tutObj = self,
		iniCustomCallback = tutorial.iniCustomCallback,
		nextCustomCallback = tutorial.nextCustomCallback,
		exitCustomCallback = tutorial.exitCustomCallback,
		scrollToCtrl = tutorial.scrollToCtrl,
		backdropCtrl = backdropCtrl,
		title = title,
		desc = tutorial.text,
		nextTutorialStepIndex = nextTutorialStepIndex + 1
	}

	TUTSYS.tutorialHandlers[tutorialType]:OnDisplayTutorial(currentStepId, nil, nil, nil, tutorialType, tutorialDetails)
end

-----
--Plugin system
-----
--Load an external Tutorial Type (plugin system)
function LibTutorial:AddExternalTutorialType(newTutorialTypeClass, newTutorialTypeControl)
	assert(newTutorialTypeClass ~= nil and newTutorialTypeControl ~= nil, "Tutorial Type Class and/or Tutorial Type Control unknown!")
	local tutorialHandlers = libTutSetup.tutorialHandlers
	assert(tutorialHandlers[newTutorialTypeClass] == nil, "Tutorial Type Class already registered!")

	tutorialHandlers[newTutorialTypeClass] = newTutorialTypeControl
	addTutorialHandler(newTutorialTypeClass, newTutorialTypeControl)
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
		type = "button",
		name = "Run LibTut Sequence", -- string id or function returning a string
		func = function() LIB_TUTORIAL_EXAMPLE:DisplayTutorialExampleSequence() end,
		tooltip = "Example Button Tooltip Text", -- string id or function returning a string (optional)
		width = "half", -- or "half" (optional)
		--disabled = function() return db.someBooleanSetting end, -- or boolean (optional)
		--icon = "icon\\path.dds", -- (optional)
		isDangerous = false, -- boolean, if set to true, the button text will be red and a confirmation dialog with the button label and warning text will show on click before the callback is executed (optional)
		--warning = "Will need to reload the UI.", -- (optional)
		--helpUrl = "https://www.esoui.com/portal.php?id=218&a=faq", -- a string URL or a function that returns the string URL (optional)
		reference = "LibTutorialButtonCtrl", -- unique global reference to control (optional)
	},
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
		reference = "LibTutorialCheckBoxCtrl2",
	},
	{
		type = "editbox",
		name = "Example Editbox Name (1)",
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
	{
		type = "checkbox",
		name = "Example Checkbox Name (3)",
		tooltip = "Example Checkbox Tooltip",
		getFunc = function() return checkboxVal end,
		setFunc = function(value) checkboxVal = value end,
		width = "full",
		default = false,
		--reference = "LibTutorialCheckBoxCtrl",
	},
	{
		type = "checkbox",
		name = "Example Checkbox Name (4)",
		tooltip = "Example Checkbox Tooltip",
		getFunc = function() return checkboxVal end,
		setFunc = function(value) checkboxVal = value end,
		width = "full",
		default = false,
		reference = "LibTutorialCheckBoxCtrl4",
	},
	{
		type = "editbox",
		name = "Example Editbox Name (2)",
		getFunc = function() return  end,
		setFunc = function(text)  end,
		tooltip = "Example Editbox Tooltip",
		isMultiline = true, -- boolean (optional)
		isExtraWide = true, -- boolean (optional)
		maxChars = 3000, -- number (optional)
		textType = TEXT_TYPE_ALL, -- number (optional) or function returning a number. Valid TextType numbers: TEXT_TYPE_ALL, TEXT_TYPE_ALPHABETIC, TEXT_TYPE_ALPHABETIC_NO_FULLWIDTH_LATIN, TEXT_TYPE_NUMERIC, TEXT_TYPE_NUMERIC_UNSIGNED_INT, TEXT_TYPE_PASSWORD
		width = "full", -- or "half" (optional)
		warning = "Example Editbox Warning.", -- or string id or function returning a string (optional)
		reference = "LibTutorialEditBox2" -- unique global reference to control (optional)
	},
	{
		type = "checkbox",
		name = "Example Checkbox Name (5)",
		tooltip = "Example Checkbox Tooltip",
		getFunc = function() return checkboxVal end,
		setFunc = function(value) checkboxVal = value end,
		width = "full",
		default = false,
		--reference = "LibTutorialCheckBoxCtrl",
	},
	{
		type = "checkbox",
		name = "Example Checkbox Name (6)",
		tooltip = "Example Checkbox Tooltip",
		getFunc = function() return checkboxVal end,
		setFunc = function(value) checkboxVal = value end,
		width = "full",
		default = false,
		reference = "LibTutorialCheckBoxCtrl6",
	},
	{
		type = "editbox",
		name = "Example Editbox Name (3)",
		getFunc = function() return  end,
		setFunc = function(text)  end,
		tooltip = "Example Editbox Tooltip",
		isMultiline = true, -- boolean (optional)
		isExtraWide = true, -- boolean (optional)
		maxChars = 3000, -- number (optional)
		textType = TEXT_TYPE_ALL, -- number (optional) or function returning a number. Valid TextType numbers: TEXT_TYPE_ALL, TEXT_TYPE_ALPHABETIC, TEXT_TYPE_ALPHABETIC_NO_FULLWIDTH_LATIN, TEXT_TYPE_NUMERIC, TEXT_TYPE_NUMERIC_UNSIGNED_INT, TEXT_TYPE_PASSWORD
		width = "full", -- or "half" (optional)
		warning = "Example Editbox Warning.", -- or string id or function returning a string (optional)
		reference = "LibTutorialEditBox3" -- unique global reference to control (optional)
	},
	{
		type = "submenu",
		name = "Example Submenu Name",
		--icon = "path/to/my/icon.dds", -- or function returning a string (optional)
		--iconTextureCoords = {left, right, top, bottom}, -- or function returning a table (optional)
		tooltip = "Example Submenu Tooltip", -- or string id or function returning a string (optional)
		controls = {
			{
				type = "checkbox",
				name = "Example Checkbox Name (7)",
				tooltip = "Example Checkbox Tooltip",
				getFunc = function() return checkboxVal end,
				setFunc = function(value) checkboxVal = value end,
				width = "full",
				default = false,
				reference = "LibTutorialCheckBoxCtrl7",
			},
			{
				type = "editbox",
				name = "Example Editbox Name (4)",
				getFunc = function() return  end,
				setFunc = function(text)  end,
				tooltip = "Example Editbox Tooltip",
				isMultiline = true, -- boolean (optional)
				isExtraWide = true, -- boolean (optional)
				maxChars = 3000, -- number (optional)
				textType = TEXT_TYPE_ALL, -- number (optional) or function returning a number. Valid TextType numbers: TEXT_TYPE_ALL, TEXT_TYPE_ALPHABETIC, TEXT_TYPE_ALPHABETIC_NO_FULLWIDTH_LATIN, TEXT_TYPE_NUMERIC, TEXT_TYPE_NUMERIC_UNSIGNED_INT, TEXT_TYPE_PASSWORD
				width = "full", -- or "half" (optional)
				warning = "Example Editbox Warning.", -- or string id or function returning a string (optional)
				reference = "LibTutorialEditBox4" -- unique global reference to control (optional)
			}, 
		},-- used by LAM (optional)
		--disabled = function() return db.someBooleanSetting end, -- or boolean (optional)
		--disabledLabel = function() return db.someBooleanSetting end, -- or boolean (optional)
		--helpUrl = "https://www.esoui.com/portal.php?id=218&a=faq", -- a string URL or a function that returns the string URL (optional)
		reference = "LibTutorialSubmenu1" -- unique global reference to control (optional)
	},
}


-----
--- Loading the addon
-----


local function onAddOnLoaded(_, addOnName)
	if addOnName ~= libName then return end

	--Preparation for a tutorial type "plugin system": Add all tut handlers to a table which could be added to via e.g.
	--LibTutorialSetup:AddExternalTutorialType from external plugin files
	local tutorialHandlersToLoad = {
		[LibTutorial_HudInfo] = 	zoTutorialCtrl,
		[LibTutorial_BriefHud] = 	zoTutorialCtrl,
		[LibTutorial_UiInfoBox] = 	zoTutorialCtrl,
		[LibTutorial_PointerBox] =	zoTutorialCtrl,
	}
	--todo: Other plugins will need an # DependsOn: LibTutorial>=<versionWhereThePluginSystemWasAdded> and then need to
	--register their new Tutorial type LibTutorial_<newType> glbal via a function <theirLibTutorialSetup.NewObject>:AddExternalTutorialType(LibTutorial_<newType>, LibTutorial_<control>)
	--It will be added to the table libTutSetup.tutorialHandlers then and update it + load the tutorial via function
	--addTutorialHandler(tutType, tutCtrl) so it can be used after that within the library
	--Maybe any LAM settings menu needs an update than OR needs to load at EVENT_PLAYER_ACTIVATED once (unregister the event in this lib again) then to show all plugin loaded
	--data properly!
	libTutSetup.tutorialHandlers = tutorialHandlersToLoad

	--Add the tutorial types as handlers to the TUTORIAL_SYSTEM
	for k,v in pairs(tutorialHandlersToLoad) do
		addTutorialHandler(k, v)
	end

	if LibAddonMenu2 then
		LAM = LibAddonMenu2
		LAM:RegisterAddonPanel(addOnName, panelData)
		LAM:RegisterOptionControls(addOnName, optionsTable)

		CALLBACK_MANAGER:RegisterCallback("LAM-PanelClosed", function(panel)
			--We want to clear tutorials whenever a panel is closed, regardless of who's it is.
			local tutId = TUTSYS.tutorialHandlers[LIB_TUTORIAL_TYPE_POINTER_BOX]:GetCurrentlyDisplayedTutorialIndex()
			TUTSYS.tutorialHandlers[LIB_TUTORIAL_TYPE_POINTER_BOX]:RemoveTutorial(tutId)
		end)
	end

	LibTutDemo.DemoTutStepsExampleData()
	--LibTutFCOISDemo.DemoTutFCOISStepsExampleData()

	EM:UnregisterForEvent(libName, EVENT_ADD_ON_LOADED)
end
EM:RegisterForEvent(libName, EVENT_ADD_ON_LOADED, onAddOnLoaded)
