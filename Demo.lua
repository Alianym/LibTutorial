-- TutorialType -->
-- TUTORIAL_TYPE_HUD_BRIEF
-- TUTORIAL_TYPE_HUD_INFO_BOX
-- TUTORIAL_TYPE_POINTER_BOX
-- TUTORIAL_TYPE_UI_INFO_BOX

ZO_CreateStringId("LIBTUTORIAL_EXAMPLE_TITLE", "Test Tutorial Heading")
ZO_CreateStringId("LIBTUTORIAL_EXAMPLE_TEXT", "This is test tutorial text so you can see how this works.")

LibTutorial.ExampleName = "LibTutorial-ExampleName"
LibTutorial.Example = {
	["hudbrief"] = {
				title = GetString(LIBTUTORIAL_EXAMPLE_TITLE), 
				text = GetString(LIBTUTORIAL_EXAMPLE_TEXT),
				tutorialType = LIB_TUTORIAL_TYPE_HUD_BRIEF, 
				displayPriority = 1, 
	},
	["hudinfo"] = {
				title = GetString(LIBTUTORIAL_EXAMPLE_TITLE), 
				text = GetString(LIBTUTORIAL_EXAMPLE_TEXT),
				tutorialType = LIB_TUTORIAL_TYPE_HUD_INFO, 
				displayPriority = 1, 
	}
}

LIB_TUTORIAL_EXAMPLE = LibTutorialSetup:New(LibTutorial.Example)

local function DisplayTutorial(tutorialId) --, obj)
	local tutorialId = HashString(tutorialId)
	LibTutorialSetup:DisplayTutorial(LIB_TUTORIAL_EXAMPLE, tutorialId)
end
SLASH_COMMANDS["/libtutorialexample"] = DisplayTutorial