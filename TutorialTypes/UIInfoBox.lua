LibTutorial_UiInfoBox = ZO_TutorialHandlerBase:Subclass()
LIB_TUTORIAL_TYPE_UI_INFO_BOX = HashString("LIB_TUTORIAL_TYPE_UI_INFO_BOX")

local TUTORIAL_SEEN = true
local TUTORIAL_NOT_SEEN = false

--Allow extra space for icons and keybind backgrounds that can extend above and below the top and bottom lines.
ZO_TUTORIAL_DIALOG_DESCRIPTION_EDGE_PADDING_Y = 6
ZO_TUTORIAL_DIALOG_DESCRIPTION_TOTAL_PADDING_Y = ZO_TUTORIAL_DIALOG_DESCRIPTION_EDGE_PADDING_Y * 2
ZO_TUTORIAL_DIALOG_SOFT_MAX_HEIGHT = 350
ZO_TUTORIAL_DIALOG_HARD_MAX_HEIGHT = 360

function LibTutorial_UiInfoBox:Initialize()
	self:ClearAll()

	local dialogControl = LibTutorial_TutorialDialog
	dialogControl:GetNamedChild("ModalUnderlay"):SetHidden(true)
	self.dialogPane = dialogControl:GetNamedChild("Pane")
	self.dialogScrollChild = self.dialogPane:GetNamedChild("ScrollChild")
	self.dialogDescription = self.dialogScrollChild:GetNamedChild("Description")
	self.dialogInfo =
	{
		title = {},
		customControl = dialogControl,
		noChoiceCallback = function(dialog)
			local tutorialDetails = dialog.data.tutorialDetails
			local nextTutorialStepIndex = tutorialDetails.nextTutorialStepIndex
			
			if tutorialDetails.exitCustomCallback then
				tutorialDetails.exitCustomCallback(tutorialDetails.tutSteps[nextTutorialStepIndex-1].id)
			end

			dialog.data.owner:RemoveTutorial(dialog.data.tutorialIndex, TUTORIAL_SEEN)
		end,
		finishedCallback = function(dialog)
			local tutorialDetails = dialog.data.tutorialDetails
			tutorialDetails.tutObj:OnTutorialCurrentStepFin(tutorialDetails)

			if dialog.data then
				FireTutorialHiddenEvent(dialog.data.tutorialIndex)
			end
		end,
		buttons =
		{
			{
				control = dialogControl:GetNamedChild("Next"),
				text = SI_GAMEPAD_PREVIEW_NEXT,
				keybind = "DIALOG_PRIMARY",
				clickSound = SOUNDS.DIALOG_ACCEPT,
				callback =  function(dialog)
					local tutorialDetails = dialog.data.tutorialDetails
					local nextTutorialStepIndex = tutorialDetails.nextTutorialStepIndex
					
					zo_callLater(function()
						if tutorialDetails.nextCustomCallback and tutorialDetails.tutSteps[nextTutorialStepIndex] then
							tutorialDetails.nextCustomCallback(tutorialDetails.tutSteps[nextTutorialStepIndex].id)
						end
						tutorialDetails.tutObj:StartTutorialSequence(tutorialDetails.tutSteps, tutorialDetails.nextTutorialStepIndex)
					end, 1)
					dialog.data.owner:RemoveTutorial(dialog.data.tutorialIndex, TUTORIAL_SEEN)
				end,
			},
			{
				control = dialogControl:GetNamedChild("Cancel"),
				text = SI_EXIT_BUTTON,
				keybind = "DIALOG_NEGATIVE",
				clickSound = SOUNDS.DIALOG_ACCEPT,
				callback =  function(dialog)
					local tutorialDetails = dialog.data.tutorialDetails
					local nextTutorialStepIndex = tutorialDetails.nextTutorialStepIndex

					if tutorialDetails.exitCustomCallback then
						tutorialDetails.exitCustomCallback(tutorialDetails.tutSteps[nextTutorialStepIndex-1].id)
					end

					dialog.data.owner:RemoveTutorial(dialog.data.tutorialIndex, TUTORIAL_SEEN)
				end,
			},
		}
	}

	ZO_Dialogs_RegisterCustomDialog("LIB_TUTORIAL_UI_INFO", self.dialogInfo)

	ZO_Dialogs_RegisterCustomDialog("LIB_TUTORIAL_UI_INFO_GAMEPAD",
		{
			canQueue = true,
			setup = function(dialog)
				dialog:setupFunc()
			end,
			gamepadInfo =
			{
				dialogType = GAMEPAD_DIALOGS.CENTERED,
			},
			title =
			{
				text = function()
					return self.title
				end,
			},
			mainText = 
			{
				text = function()
					return self.description
				end,
			},
			buttons =
			{
				{
					name = "Gamepad Tutorial Accept",
					ethereal = true,
					keybind =    "DIALOG_PRIMARY",
					clickSound = SOUNDS.DIALOG_ACCEPT,
					callback =  function(dialog)
						--It might be worth examining how this will work with GP tutorial chains/queues
						local tutorialDetails = dialog.data.tutorialDetails
						local nextTutorialStepIndex = tutorialDetails.nextTutorialStepIndex

						zo_callLater(function()
							if tutorialDetails.nextCustomCallback then
								tutorialDetails.nextCustomCallback(tutorialDetails.tutSteps[nextTutorialStepIndex].id)
							end
							tutorialDetails.tutObj:StartTutorialSequence(tutorialDetails.tutSteps, tutorialDetails.nextTutorialStepIndex)
						end, 1)
						dialog.data.owner:RemoveTutorial(dialog.data.tutorialIndex, TUTORIAL_SEEN)
					end,
				}
			},
			noChoiceCallback = function(dialog)
				if dialog.data then
					local tutorialDetails = dialog.data.tutorialDetails
					local nextTutorialStepIndex = tutorialDetails.nextTutorialStepIndex

					if tutorialDetails.exitCustomCallback then
						tutorialDetails.exitCustomCallback(tutorialDetails.tutSteps[nextTutorialStepIndex-1].id)
					end

					dialog.data.owner:RemoveTutorial(dialog.data.tutorialIndex, TUTORIAL_SEEN)
				end
			end,
			finishedCallback = function(dialog)
				if dialog.data then
					local tutorialDetails = dialog.data.tutorialDetails
					tutorialDetails.tutObj:OnTutorialCurrentStepFin(tutorialDetails)
					
					FireTutorialHiddenEvent(dialog.data.tutorialIndex)
				end
			end,
			removedFromQueueCallback = function(data)
				if data then
					data.owner:RemoveTutorial(data.tutorialIndex, TUTORIAL_NOT_SEEN)
				end
			end,
		}
	)

	self.gamepadMode = false

end

function LibTutorial_UiInfoBox:GetDialog()
	return self.dialogs[self.gamepadMode]
end

function LibTutorial_UiInfoBox:SuppressTutorials(suppress, reason)
	-- Suppression is disabled in LibTutorial_UiInfoBox
end

function LibTutorial_UiInfoBox:GetTutorialType()
	return LIB_TUTORIAL_TYPE_UI_INFO_BOX
end

function LibTutorial_UiInfoBox:DisplayTutorial(tutorialIndex, tutorialDetails)
	self.title, self.description = tutorialDetails.title, tutorialDetails.desc

	self:SetCurrentlyDisplayedTutorialIndex(tutorialIndex)
	self.gamepadMode = IsInGamepadPreferredMode()

	if self.gamepadMode then
		ZO_Dialogs_ShowGamepadDialog("LIB_TUTORIAL_UI_INFO_GAMEPAD", { tutorialIndex = tutorialIndex, owner = self, tutorialDetails = tutorialDetails})
	else
		self.dialogInfo.title.text = self.title
		self.dialogDescription:SetText(self.description)
		local descriptionHeight = self.dialogDescription:GetTextHeight() + ZO_TUTORIAL_DIALOG_DESCRIPTION_TOTAL_PADDING_Y
		self.dialogScrollChild:SetHeight(descriptionHeight)

		local paneHeight = descriptionHeight
		if paneHeight > ZO_TUTORIAL_DIALOG_HARD_MAX_HEIGHT then
			paneHeight = ZO_TUTORIAL_DIALOG_SOFT_MAX_HEIGHT
		end
		self.dialogPane:SetHeight(paneHeight)

		ZO_Scroll_ResetToTop(self.dialogPane)
		ZO_Dialogs_ShowDialog("LIB_TUTORIAL_UI_INFO", { tutorialIndex = tutorialIndex, owner = self, tutorialDetails = tutorialDetails })
	end
end

function LibTutorial_UiInfoBox:OnDisplayTutorial(tutorialIndex, priority, tutorialDetails)
	--if not IsGameCameraActive() or SCENE_MANAGER:IsInUIMode() then
		if not self:IsTutorialDisplayedOrQueued(tutorialIndex) then
			if self:CanShowTutorial() then
				self:DisplayTutorial(tutorialIndex, tutorialDetails)
			end
		end
	--end
end

function LibTutorial_UiInfoBox:OnRemoveTutorial(tutorialIndex)
	self:RemoveTutorial(tutorialIndex, TUTORIAL_SEEN)
end

function LibTutorial_UiInfoBox:SetTutorialSeen(tutorialIndex)
	--Overridden
end

function LibTutorial_UiInfoBox:RemoveTutorial(tutorialIndex, seen)
	if self:GetCurrentlyDisplayedTutorialIndex() == tutorialIndex then
		if seen then
			self:SetTutorialSeen(tutorialIndex)
		end

		self:SetCurrentlyDisplayedTutorialIndex(nil)
		ZO_Dialogs_ReleaseDialog("LIB_TUTORIAL_UI_INFO")
		ZO_Dialogs_ReleaseDialog("LIB_TUTORIAL_UI_INFO_GAMEPAD")
	else
		self:RemoveFromQueue(self.queue, tutorialIndex)
	end
end

function LibTutorial_UiInfoBox:ClearAll()
	self:SetCurrentlyDisplayedTutorialIndex(nil)
	self.queue = {}
end
