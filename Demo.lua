-- TutorialType Constants -->
-- LIB_TUTORIAL_TYPE_HUD_BRIEF
-- LIB_TUTORIAL_TYPE_HUD_INFO
-- LIB_TUTORIAL_TYPE_UI_INFO_BOX

ZO_CreateStringId("LIBTUTORIAL_EXAMPLE_TITLE_SHORT", "Test Tutorial")
ZO_CreateStringId("LIBTUTORIAL_EXAMPLE_TITLE_LONG", "Test Tutorial Expanded")
ZO_CreateStringId("LIBTUTORIAL_EXAMPLE_TEXT_SHORT", "This is test tutorial text so you can see how this works.")
ZO_CreateStringId("LIBTUTORIAL_EXAMPLE_TEXT_LONG", "This is some longer test tutorial text so you can see how this works with more text in the example.")

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
}

--Setup
LIB_TUTORIAL_EXAMPLE = LibTutorialSetup.New(tutorialExampleList)
function LIB_TUTORIAL_EXAMPLE:SetTutorialSeen(tutorialIndex)
	CHAT_ROUTER:AddDebugMessage("Tutorial Seen") --Replace this with SavedVar updates or however/if you want to track if a Tutorial has been seen.
end

--Example Slash Command + Function
local function DisplayTutorialExample(tutorialIndex)
	LIB_TUTORIAL_EXAMPLE:DisplayTutorial(tutorialIndex) --This is the main function you'd use to display your tutorial.
end
SLASH_COMMANDS["/libtutex"] = DisplayTutorialExample --E.G. Usage: /libtuteex hudinfo