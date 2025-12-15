local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(C["Name"])

local AltinatorDB = AltinatorNS.AltinatorDB
local AltinatorLDB = AltinatorNS.AltinatorLDB

local icon = LibStub("LibDBIcon-1.0")

local AltinatorFrame

AltinatorNS.AltinatorCache = {}

local AltinatorAddon = LibStub("AceAddon-3.0"):NewAddon(C["Name"], "AceEvent-3.0", "AceTimer-3.0")
AltinatorNS.AltinatorAddon = AltinatorAddon

SLASH_ALTINATOR1, SLASH_ALTINATOR2 = "/alt", "/altinator"

SlashCmdList.ALTINATOR = function(msg, editBox)
   if msg == "options" or msg == "o" then
      Settings.OpenToCategory(AltinatorNS.AltinatorOptions.Category:GetID())
   else
      AltinatorAddon:ToggleFrame()
   end
end

function AltinatorAddon:OnInitialize()
	-- Assuming you have a ## SavedVariables: AltinatorDB line in your TOC
	AltinatorDB = LibStub("AceDB-3.0"):New("AltinatorDB", {
		profile = {
			minimap = {
				hide = false,
			},
         settings = {
            hideRecipeTooltips = false,
         }
		},
      global = {
         characters = {}
      }
	})
   AltinatorNS.AltinatorDB = AltinatorDB
	icon:Register(C["Name"], AltinatorLDB, AltinatorDB.profile.minimap)
   if AltinatorDB.global.dbversion ~= C["MajorDBVersion"] then
      AltinatorDB.global.characters = {}
      AltinatorDB.global.dbversion = C["MajorDBVersion"]
   end
   AltinatorAddon.CurrentCharacter = {}
   self:RegisterEvent("PLAYER_ENTERING_WORLD")
   self:RegisterEvent("PLAYER_LOGOUT")
   self:RegisterEvent("TIME_PLAYED_MSG")
   self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
   self:RegisterEvent("PLAYER_MONEY")
   self:RegisterEvent("PLAYER_LEVEL_UP")
   self:RegisterEvent("PLAYER_XP_UPDATE")
   self:RegisterEvent("PLAYER_UPDATE_RESTING")
   self:RegisterEvent("PLAYER_GUILD_UPDATE")
   self:RegisterEvent("TRADE_SKILL_SHOW")
   self:RegisterEvent("TRADE_SKILL_UPDATE")
   self:RegisterEvent("CRAFT_UPDATE")
   AltinatorNS.AltinatorOptions:Initialize()
   RequestTimePlayed()
   AltinatorNS.AltinatorGameTooltip:Initialize()
   hooksecurefunc("DoTradeSkill", function()
			AltinatorNS.AltinatorCache.updateCooldowns = true
	end)
end

function AltinatorAddon:OnDisable()
   self:UnregisterEvent("PLAYER_ENTERING_WORLD")
   self:UnregisterEvent("PLAYER_LOGOUT")
   self:UnregisterEvent("TIME_PLAYED_MSG")
   self:UnregisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
   self:UnregisterEvent("PLAYER_MONEY")
   self:UnregisterEvent("PLAYER_LEVEL_UP")
   self:UnregisterEvent("PLAYER_XP_UPDATE")
   self:UnregisterEvent("PLAYER_UPDATE_RESTING")
   self:UnregisterEvent("PLAYER_GUILD_UPDATE")
   self:UnregisterEvent("TRADE_SKILL_SHOW")
   self:UnregisterEvent("TRADE_SKILL_UPDATE")
   self:UnregisterEvent("CRAFT_UPDATE")
end

function AltinatorAddon:PLAYER_ENTERING_WORLD(self, isLogin, isReload)
   if isLogin or isReload then
      AltinatorNS.AltinatorData:SavePlayerDataLogin()
   end
end

function AltinatorAddon:PLAYER_LOGOUT()
   AltinatorNS.AltinatorData:SavePlayerDataLogout()
end

function AltinatorAddon:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(self, type)
   if(type == 17) then
      AltinatorNS.AltinatorData:ClearPlayerMailData()
   end
end

function AltinatorAddon:TIME_PLAYED_MSG(self, total, level)
	AltinatorNS.AltinatorData:SavePlayerTimePlayed(total, level)
end

function AltinatorAddon:PLAYER_MONEY()
   AltinatorNS.AltinatorData:SavePlayerMoney()
end

function AltinatorAddon:PLAYER_LEVEL_UP()
   AltinatorNS.AltinatorData:SavePlayerXP()
end

function AltinatorAddon:PLAYER_XP_UPDATE()
   AltinatorNS.AltinatorData:SavePlayerXP()
end

function AltinatorAddon:PLAYER_UPDATE_RESTING()
   AltinatorNS.AltinatorData:SavePlayerResting()
end

function AltinatorAddon:PLAYER_GUILD_UPDATE()
   AltinatorNS.AltinatorData:SavePlayerGuild()
end

function AltinatorAddon:PLAYER_GUILD_UPDATE()
   AltinatorNS.AltinatorData:SavePlayerGuild()
end

function AltinatorAddon:PLAYER_GUILD_UPDATE()
   AltinatorNS.AltinatorData:SavePlayerGuild()
end

function AltinatorAddon:TRADE_SKILL_SHOW()
   AltinatorAddon:ScheduleTimer(AltinatorNS.AltinatorData.ScanTradeSkills, 0.5)	
end

function AltinatorAddon:TRADE_SKILL_UPDATE()
	if AltinatorNS.AltinatorCache.updateCooldowns then
		AltinatorNS.AltinatorData:ScanCooldowns()
		AltinatorNS.AltinatorCache.updateCooldowns = false
	end	
   
end

function AltinatorAddon:CRAFT_UPDATE()
   AltinatorAddon:ScheduleTimer(AltinatorNS.AltinatorData.ScanEnchantingRecipes, 0.5)	
end

function AltinatorAddon:GetMainFrame()
   return AltinatorFrame or AltinatorAddon:CreateMainFrame()
end

function AltinatorAddon:ToggleFrame()
   local f = AltinatorAddon:GetMainFrame()
   f:SetShown(not f:IsShown())
end

local function Tab_OnClick(self)
   PanelTemplates_SetTab(self:GetParent(), self:GetID())

   --[[local scrollChild = AltinatorFrame.ScrollFrame:GetScrollChild()
   if(scrollChild) then
      scrollChild:Hide()
   end
   AltinatorFrame.ScrollFrame:SetScrollChild(self.content);]]--
   for i = 1, self:GetParent().numTabs do
      local tab = _G[self:GetParent():GetName().."Tab"..i]
      tab.content:Hide()
   end
   SetTitle("Altinator - " .. self.Name)
   self.content:LoadContent(self.content)
   self.content:Show()
end

local function CreateTabs(frame,  ...)
   local numTabs = 0
   local args = {...}
   local contents = {}
   local frameName = frame:GetName()
   for i, name in ipairs(args) do
      numTabs = i
      local tab = CreateFrame("Button", frameName.."Tab"..i, frame, "CharacterFrameTabButtonTemplate")
      tab:SetID(i)
      tab:SetText(name)
      tab.Name = name
      tab:SetScript("OnClick", Tab_OnClick)

      --[[tab.content = CreateFrame("Frame", nil, AltinatorFrame.ScrollFrame)
      tab.content:SetSize(C["Width"]-42, C["Height"])
      tab.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -28)
      tab.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 6)]]--
      tab.content = CreateFrame("Frame", nil, frame)      
      tab.content:SetSize(C["Width"], C["Height"])
      tab.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28)
      tab.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 6)
      tab.content:Hide()
      
      table.insert(contents, tab.content)

      if(i==1) then
         tab:SetPoint("TOPLEFT", AltinatorFrame, "BOTTOMLEFT", 0, 2)
      else
         tab:SetPoint("TOPLEFT", _G[frameName.."Tab"..(i-1)], "TOPRIGHT", -14, 0)
      end
   end
   frame.numTabs = numTabs
   return unpack(contents)
end

function SetTitle(title)
   AltinatorFrame.Title:SetText(title)
end

function AltinatorAddon:CreateMainFrame()
   AltinatorFrame = CreateFrame("Frame", "AltinatorFrame", UIParent, "BasicFrameTemplateWithInset")
   AltinatorNS.AltinatorTooltip = CreateFrame("GameTooltip", "AltinatorNS.AltinatorTooltipFrame", AltinatorFrame, "GameTooltipTemplate")
   AltinatorFrame:SetSize(C["Width"], C["Height"])
   AltinatorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

   AltinatorFrame.TitleBg:SetHeight(30)
   AltinatorFrame.Title = AltinatorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
   AltinatorFrame.Title:SetPoint("CENTER", AltinatorFrame.TitleBg, "CENTER", 0, 6)
   SetTitle(C["Name"])

   AltinatorFrame.OptionsButton = AltinatorFrame.OptionsButton or CreateFrame("Button", nil, AltinatorFrame, "GameMenuButtonTemplate");
   AltinatorFrame.OptionsButton:SetPoint("TOPRIGHT", AltinatorFrame, "TOPRIGHT", -23, 2);
   AltinatorFrame.OptionsButton:SetSize(24, 24);
   AltinatorFrame.OptionsButton:SetText("|TInterface\\Buttons\\UI-OptionsButton:0|t");
   AltinatorFrame.OptionsButton:SetNormalFontObject("GameFontNormal");
   AltinatorFrame.OptionsButton:SetHighlightFontObject("GameFontHighlight");
   AltinatorFrame.OptionsButton:SetScript("OnClick", function(button)
      Settings.OpenToCategory(AltinatorNS.AltinatorOptions.Category:GetID())
   end)

   AltinatorFrame:SetClampedToScreen(true)
   AltinatorFrame:EnableMouse(true)
   AltinatorFrame:SetMovable(true)
   AltinatorFrame:RegisterForDrag("LeftButton")
   AltinatorFrame:SetScript("OnDragStart", function(self)
      AltinatorFrame:StartMoving()
   end)
   AltinatorFrame:SetScript("OnDragStop", function(self)
      AltinatorFrame:StopMovingOrSizing()
   end)

   AltinatorFrame:SetScript("OnShow", function()
         PlaySound(808)
   end)

   AltinatorFrame:SetScript("OnHide", function()
         PlaySound(808)
   end)
   

   --[[AltinatorFrame.ScrollFrame = CreateFrame("ScrollFrame", "AltinatorScrollFrame", AltinatorFrame, "UIPanelScrollFrameTemplate")
   AltinatorFrame.ScrollFrame:SetPoint("TOPLEFT", AltinatorFrame, "TOPLEFT", 10, -28)
   AltinatorFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", AltinatorFrame, "BOTTOMRIGHT", -32, 6)
   AltinatorFrame.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel)
   AltinatorFrame.ScrollFrame:EnableMouse(true)]]--

   local overView, activityView, gearView, searchView = CreateTabs(AltinatorFrame, L["Overview"], L["Activity"], L["Gear"], L["Search"])
   overView.LoadContent = AltinatorNS.AltinatorOverviewFrame.Initialize
   activityView.LoadContent = AltinatorNS.AltinatorActivityFrame.Initialize
   gearView.LoadContent = AltinatorNS.AltinatorGearFrame.Initialize
   searchView.LoadContent = AltinatorNS.AltinatorSearchFrame.Initialize

   Tab_OnClick(_G["AltinatorFrameTab1"])
   tinsert(UISpecialFrames, "AltinatorFrame");
   AltinatorFrame:Hide()
   return AltinatorFrame
end


