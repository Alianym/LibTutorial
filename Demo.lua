 -- TutorialType -->
-- TUTORIAL_TYPE_HUD_BRIEF
-- TUTORIAL_TYPE_HUD_INFO_BOX
-- TUTORIAL_TYPE_POINTER_BOX
-- TUTORIAL_TYPE_UI_INFO_BOX

ZO_CreateStringId("LIBTUTORIAL_EXAMPLE_TITLE", "Test Tutorial Heading")
ZO_CreateStringId("LIBTUTORIAL_EXAMPLE_TEXT_SHORT", "This is test tutorial text so you can see how this works.")
ZO_CreateStringId("LIBTUTORIAL_EXAMPLE_TEXT_LONG", "This is some longer test tutorial text so you can see how this works with more text in the example.")

LibTutorial.ExampleList = {
	["hudbrief"] = {
		--title = GetString(LIBTUTORIAL_EXAMPLE_TITLE), --No title displayed nor needed for this Tutorial Type.
		text = GetString(LIBTUTORIAL_EXAMPLE_TEXT_SHORT), --(string)
		tutorialType = LIB_TUTORIAL_TYPE_HUD_BRIEF, --LibTutorial Global
		displayPriority = 1, 
	},
	["hudinfo"] = {
		title = GetString(LIBTUTORIAL_EXAMPLE_TITLE), 
		text = GetString(LIBTUTORIAL_EXAMPLE_TEXT_LONG),
		tutorialType = LIB_TUTORIAL_TYPE_HUD_INFO, 
		displayPriority = 1, 
	},
	["uiinfo"] = {
		title = GetString(LIBTUTORIAL_EXAMPLE_TITLE), 
		text = GetString(LIBTUTORIAL_EXAMPLE_TEXT_LONG),
		tutorialType = LIB_TUTORIAL_TYPE_UI_INFO_BOX, 
		displayPriority = 1, 
	},
}

LIB_TUTORIAL_EXAMPLE = LibTutorialSetup:New(LibTutorial.ExampleList)

local function DisplayTutorialExample(tutorialIndex)
	local obj = LIB_TUTORIAL_EXAMPLE
	LibTutorialSetup:DisplayTutorial(obj, tutorialIndex) --This is the main function you'd use to display your tutorial.
end
SLASH_COMMANDS["/libtutorialexample"] = DisplayTutorialExample