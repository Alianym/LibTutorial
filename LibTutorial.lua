-----
--Initialize
-----

LibTutorial = ZO_Object:Subclass()
LibTutorialSetup = {}

function LibTutorialSetup:New(tutorialArray)
	local libTutorial = ZO_Object:New(LibTutorial)
	libTutorial:Initialize(tutorialArray)
	return libTutorial
end

function LibTutorial:Initialize(tutorialArray)
	self:RegisterTutorials(tutorialArray)
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

function LibTutorialSetup:DisplayTutorial(obj, tutorialIndex)
	if not obj.tutorials[tutorialIndex] then return end

	local tutorialType = obj:GetLibTutorialType(tutorialIndex)

	if TUTORIAL_SYSTEM.tutorialHandlers[tutorialType] then
		local priority = obj:GetLibTutorialDisplayPriority(tutorialIndex)
		local title, desc = obj:GetLibTutorialInfo(tutorialIndex)
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
-----

local function OnLoad(e, addOnName)
	if addOnName ~= "LibTutorial" then return end

	TUTORIAL_SYSTEM:AddTutorialHandler(LibTutorial_HudInfo:New(ZO_Tutorial))
	TUTORIAL_SYSTEM:AddTutorialHandler(LibTutorial_BriefHud:New(ZO_Tutorial))
	TUTORIAL_SYSTEM:AddTutorialHandler(LibTutorial_UiInfoBox:New(ZO_Tutorial))
	TUTORIAL_SYSTEM:AddTutorialHandler(LibTutorial_PointerBox:New(ZO_Tutorial))

	EVENT_MANAGER:UnregisterForEvent("LibTutorial", EVENT_ADD_ON_LOADED) 
end
EVENT_MANAGER:RegisterForEvent("LibTutorial", EVENT_ADD_ON_LOADED, OnLoad)