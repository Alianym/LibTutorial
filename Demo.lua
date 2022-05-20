-- TutorialType Constants -->
-- LIB_TUTORIAL_TYPE_HUD_BRIEF
-- LIB_TUTORIAL_TYPE_HUD_INFO
-- LIB_TUTORIAL_TYPE_UI_INFO_BOX

ZO_CreateStringId("LIBTUTORIAL_EXAMPLE_TITLE_SHORT", "Test Tutorial")
ZO_CreateStringId("LIBTUTORIAL_EXAMPLE_TITLE_LONG", "Test Tutorial Expanded")
ZO_CreateStringId("LIBTUTORIAL_EXAMPLE_TEXT_SHORT", "This is test tutorial text so you can see how this works.")
ZO_CreateStringId("LIBTUTORIAL_EXAMPLE_TEXT_LONG", "This is some longer test tutorial text so you can see how this works with more text in the example.")

----------
--Simple Examples
----------
local tutorialExampleList = {
	["hudbrief"] = {											--ID must be at least (string) 5 characters or > (number) 9999
		title = "",												--(string) No title displayed nor needed for this Tutorial Type
		text = GetString(LIBTUTORIAL_EXAMPLE_TEXT_SHORT),		--(string)
		tutorialType = LIB_TUTORIAL_TYPE_HUD_BRIEF,				--LibTutorial Global
		displayPriority = nil,									--Not used for this Tutorial Type
	},
	["hudbrieftwo"] = {											--ID must be at least (string) 5 characters or > (number) 9999
		title = "",												--(string) No title displayed nor needed for this Tutorial Type
		text = GetString(LIBTUTORIAL_EXAMPLE_TEXT_LONG),		--(string)
		tutorialType = LIB_TUTORIAL_TYPE_HUD_BRIEF,				--LibTutorial Global
		displayPriority = nil,									--Not used for this Tutorial Type
	},
	["hudinfo"] = {												--ID must be at least (string) 5 characters or > (number) 9999
		title = GetString(LIBTUTORIAL_EXAMPLE_TITLE_SHORT),		--(string) 
		text = GetString(LIBTUTORIAL_EXAMPLE_TEXT_SHORT),		--(string)
		tutorialType = LIB_TUTORIAL_TYPE_HUD_INFO,				--LibTutorial Global
		displayPriority = 1,									--(number) Determines priority when inserted into the queue
	},
	["hudinfotwo"] = {											--ID must be at least (string) 5 characters or > (number) 9999
		title = GetString(LIBTUTORIAL_EXAMPLE_TITLE_LONG),		--(string)
		text = GetString(LIBTUTORIAL_EXAMPLE_TEXT_LONG),		--(string)
		tutorialType = LIB_TUTORIAL_TYPE_HUD_INFO,				--LibTutorial Global
		displayPriority = 2,									--(number) Determines priority relative to other queued tutorials when inserted into the queue
	},
	["uiinfo"] = {												--ID must be at least (string) 5 characters or > (number) 9999
		title = GetString(LIBTUTORIAL_EXAMPLE_TITLE_SHORT),		--(string)
		text = GetString(LIBTUTORIAL_EXAMPLE_TEXT_SHORT),		--(string)
		tutorialType = LIB_TUTORIAL_TYPE_UI_INFO_BOX,			--LibTutorial Global
		displayPriority = nil,									--Not used for this Tutorial Type
	},
	["uiinfotwo"] = {											--ID must be at least (string) 5 characters or > (number) 9999
		title = GetString(LIBTUTORIAL_EXAMPLE_TITLE_LONG),		--(string)
		text = GetString(LIBTUTORIAL_EXAMPLE_TEXT_LONG),		--(string)
		tutorialType = LIB_TUTORIAL_TYPE_UI_INFO_BOX,			--LibTutorial Global
		displayPriority = nil,									--Not used for this Tutorial Type
	},
	["pointerbox"] = {																	--ID must be at least (string) 5 characters or > (number) 9999
		--title = GetString(LIBTUTORIAL_EXAMPLE_TITLE_LONG),							--(string)
		text = GetString(LIBTUTORIAL_EXAMPLE_TEXT_LONG),								--(string)
		tutorialType = LIB_TUTORIAL_TYPE_POINTER_BOX,									--LibTutorial Global
		displayPriority = nil,															--Not used for this Tutorial Type
		anchorToControlData = {RIGHT, "ZO_PlayerInventoryTabsActive", LEFT, -10, 0},	--(myPoint, anchorTargetControl, anchorControlsPoint, offsetX, offsetY)	
		fragment = INVENTORY_FRAGMENT,													--Fragment to which to attach (optional), if used, will hide with fragment
	},
}

----------
--Tutorial Sequence Example
----------

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

LibTutDemo = {}
local tutorialStepsExample
function LibTutDemo.DemoTutStepsExampleData()
	local LAM = LibAddonMenu2
	tutorialStepsExample = {
		options = {
			showStepNumInTitle = true,								--(boolean) Format title as "Title (#/n)"
			tutorialType = LIB_TUTORIAL_TYPE_POINTER_BOX,			--LibTutorial Global (must be LIB_TUTORIAL_TYPE_UI_INFO_BOX for Steps/Sequence)
		},
		[1] = {
			id = "libtutpb",														--ID must be at least (string) 5 characters or > (number) 9999
			title = "Test Tutorial Sequence",										--(string)
			text = "Test <LibTutorialDescriptionCtrl> Text!",						--(string)
			anchorToControlData = {LEFT, "LibTutorialDescriptionCtrl", RIGHT, 0},	--(myPoint, anchorTargetControl, anchorControlsPoint, offsetX, offsetY)	
			fragment = LAM:GetAddonSettingsFragment(),								--Fragment to which to attach (optional), if used, will hide with fragment

			--Callback that triggers just -before- the tutorial is displayed
			--Used here to open the SubMenu as the tutorial is displayed
			iniCustomCallback = function()
				local control = GetControl("LibTutorialDescriptionCtrl")
				LoopCallbackForSubMenu(control, true) --This control isn't a submenu or in a submenu, this call is just here to show it does what it should (nothing) if there is no submenu to be found
			end,

			--Callback that triggers when a user left-clicks on the tutorial popup
			--Displaying the next tutorial in sequence is handled by LibTutorial, but you can do other stuff here if you want 
				--(It will be called -before- the next tutorialStep is shown)
			nextCustomCallback = function(nextTutStepId) 
				local control = GetControl("LibTutorialDescriptionCtrl")
				LoopCallbackForSubMenu(control, false) --This control isn't a submenu or in a submenu, this call is just here to show it does what it should (nothing) if there is no submenu to be found
			end,

			--Callback that triggers when a user right-clicks on the tutorial pointer box
			exitCustomCallback = function(currTutStepId) d(zo_strformat("ID: <<1>>, exitCustomCallback", currTutStepId)) end,
		},
		[2] = {
			id = "libtutpbtwo",
			title = "Test Tutorial Sequence",
			text = "Test <LibTutorialCheckBoxCtrl> Text!",
			anchorToControlData = "LibTutorialCheckBoxCtrl6",
			fragment = LAM:GetAddonSettingsFragment(),

			iniCustomCallback = function()
				--
			end,

			--nextCustomCallback = function(nextTutStepId) end,
			--exitCustomCallback = function(currTutStepId) end,
		},
		[3] = {
			id = "libtutpbthree",
			title = "Test Tutorial Sequence",
			text = "Test <LibTutorialHeaderCtrl> Text!",
			anchorToControlData = "LibTutorialEditBox2",
			fragment = LAM:GetAddonSettingsFragment(),

			iniCustomCallback = function()
				--
			end,

			--nextCustomCallback = function(nextTutStepId) end,
			--exitCustomCallback = function(currTutStepId) end,
		},
		[4] = {
			id = "libtutpbfour",
			title = "Test Tutorial Sequence",
			text = "Test <LibTutorialEditBox> Text!",
			anchorToControlData = "LibTutorialEditBox3",
			fragment = LAM:GetAddonSettingsFragment(),

			iniCustomCallback = function()
				--
			end,

			--nextCustomCallback = function(nextTutStepId) end,
			--exitCustomCallback = function(currTutStepId) end,
		},
		[5] = {
			id = "libtutpbfive",
			title = "Test Tutorial Sequence",
			text = "Test <LibTutorialEditBox> Text!",
			anchorToControlData = "LibTutorialCheckBoxCtrl7",
			fragment = LAM:GetAddonSettingsFragment(),

			iniCustomCallback = function()
				local control = GetControl("LibTutorialCheckBoxCtrl7")
				LoopCallbackForSubMenu(control, true)
			end,

			--This callback won't fire because it's the last in the sequence, there is no "next"
			nextCustomCallback = function(nextTutStepId) 
				local control = GetControl("LibTutorialCheckBoxCtrl7")
				LoopCallbackForSubMenu(control, false)				
			end,

			exitCustomCallback = function(nextTutStepId) 
				local control = GetControl("LibTutorialCheckBoxCtrl7")
				LoopCallbackForSubMenu(control, false)				
			end,
		},
	}
end

----------
----------

--Setup
local libTutExample = LibTutorialSetup.New(tutorialExampleList)
LIB_TUTORIAL_EXAMPLE = libTutExample
function libTutExample:SetTutorialSeen(tutorialIndex)
	CHAT_ROUTER:AddDebugMessage("Tutorial Seen") --Replace this with SavedVar updates or however/if you want to track if a Tutorial has been seen.
end

--Example Tutorial Sequence Function (Triggered with the button in the LibTutorial LAM Panel)
function libTutExample:DisplayTutorialExampleSequence()
	local tutorialSteps = tutorialStepsExample
	libTutExample:StartTutorialSequence(tutorialSteps) --This is the main function you'd use to display a tutorial route.
end

--Example Slash Command + Function
local function DisplayTutorialExample(tutorialIndex)
	libTutExample:DisplayTutorial(tutorialIndex) --This is the main function you'd use to display your tutorial.
end
SLASH_COMMANDS["/libtutex"] = DisplayTutorialExample --E.G. Usage: /libtuteex hudinfo

--PointerBox
--Example Slash Command + Function
local function DisplayTutorialPointerBoxExample()
	libTutExample:DisplayTutorial("pointerbox")
end
SLASH_COMMANDS["/libtutpbsolo"] = DisplayTutorialPointerBoxExample