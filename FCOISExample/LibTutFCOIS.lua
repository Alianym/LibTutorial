LibTutFCOISDemo = {}

local function LoopCallbackForSubMenu(control, requestOpen)
	if not control then return end

	while control:GetName() ~= "GuiRoot" and control do
		if control.open ~= nil then
			if control.disabled then return end
			if control.open == requestOpen then 
				return end

			control.open = not control.open
			if requestOpen then
				control.animation:PlayFromStart()
			else
				control.animation:PlayFromEnd()
			end
		end

		control = control:GetParent()
	end
end

local fcoisTutorialStepsExample
function LibTutFCOISDemo.DemoTutFCOISStepsExampleData()
	local LAM = LibAddonMenu2
	fcoisTutorialStepsExample = {
		options = {
			showStepNumInTitle = true,
			tutorialType = LIB_TUTORIAL_TYPE_POINTER_BOX,
			isLAMPanel = true,
		},
		[1] = {
			id = "libtutfcois",													
			title = "Test Tutorial Sequence",							
			text = "Test text for this tutorial!",								
			anchorToControlData = {LEFT, "LAMCombobox2", RIGHT, 0},	

			iniCustomCallback = function() 
				local control = GetControl("LAMCombobox2")
				LibTutorialSetSubMenuContainerIsOpen(control, true)
			end,

			nextCustomCallback = function(nextTutStepId) 
				local control = GetControl("LAMCombobox2")
				LibTutorialSetSubMenuContainerIsOpen(control, false)
			end,

			exitCustomCallback = function(nextTutStepId) 
				local control = GetControl("LAMCombobox2")
				LibTutorialSetSubMenuContainerIsOpen(control, false)
			end,
		},
		[2] = {
			id = "libtutfcoistwo",
			title = "Test Tutorial Sequence",
			text = "Test text for this tutorial at the second in sequence!",
			anchorToControlData = "LAMCombobox5",

			iniCustomCallback = function() 
				local control = GetControl("LAMCombobox5")
				LibTutorialSetSubMenuContainerIsOpen(control, true)
			end,

			nextCustomCallback = function(nextTutStepId) 
				local control = GetControl("LAMCombobox5")
				LibTutorialSetSubMenuContainerIsOpen(control, false)
			end,

			exitCustomCallback = function(nextTutStepId) 
				local control = GetControl("LAMCombobox5")
				LibTutorialSetSubMenuContainerIsOpen(control, false)
			end,
		},
		--[[[3] = {
			id = "libtutfcoisthree",
			title = "Test Tutorial Sequence",
			text = "Test text for this tutorial at the third in sequence!",
			anchorToControlData = "LAMCombobox11",
			fragment = LAM:GetAddonSettingsFragment(),
			iniCustomCallback = function() 
				local control = GetControl("LAMCombobox11")
				LoopCallbackForSubMenu(control, true)
			end,
			nextCustomCallback = function(nextTutStepId) 
				local control = GetControl("LAMCombobox11")
				LoopCallbackForSubMenu(control, false)
			end,

			--exitCustomCallback = function(currTutStepId) end,
		},
		[4] = {
			id = "libtutfcoisfour",
			title = "Test Tutorial Sequence",
			text = "Test text for this tutorial at the fourth in sequence!",
			anchorToControlData = "",
			fragment = LAM:GetAddonSettingsFragment(),
			--nextCustomCallback = function(nextTutStepId) end,
			--exitCustomCallback = function(currTutStepId) end,
		},]]
	}
end

--Setup
local libTutFCOISExample = LibTutorialSetup.New()
LIB_TUTORIAL_FCOIS_EXAMPLE = libTutFCOISExample

--Example Slash Command + Function
local function DisplayFCOISTutorialExampleSequence()
	local tutorialSteps = fcoisTutorialStepsExample
	libTutFCOISExample:StartTutorialSequence(tutorialSteps) --This is the main function you'd use to display a tutorial route.
end
SLASH_COMMANDS["/libtutfcois"] = DisplayFCOISTutorialExampleSequence

local function onAddOnLoaded(_, addOnName)
	if addOnName ~= LibTutorialSetup.name then return end

	LibTutFCOISDemo.DemoTutFCOISStepsExampleData()

	EVENT_MANAGER:UnregisterForEvent(LibTutorialSetup.name, EVENT_ADD_ON_LOADED)
end

EVENT_MANAGER:RegisterForEvent(LibTutorialSetup.name.."FCOISDemo", EVENT_ADD_ON_LOADED, onAddOnLoaded)

-----
--This is an example onAddOnLoaded for FCOIS
--Will need to run the above function at AddOn load or it will bug
-----

--[[
	local function onAddOnLoaded(_, addOnName)
		if addOnName ~= libName then return end

		--Create the data
		LibTutFCOISDemo.DemoTutFCOISStepsExampleData()

		EVENT_MANAGER:UnregisterForEvent(libName, EVENT_ADD_ON_LOADED)
	end
	EVENT_MANAGER:RegisterForEvent(libName, EVENT_ADD_ON_LOADED, onAddOnLoaded)
]]