local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local AltinatorDB = AltinatorNS.AltinatorDB
local AltinatorLDB = AltinatorNS.AltinatorLDB

local icon = LibStub("LibDBIcon-1.0")

local AltinatorFrame

AltinatorNS.AltinatorCache = {}

local AltinatorAddon = LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceEvent-3.0", "AceTimer-3.0")
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
	icon:Register(AddonName, AltinatorLDB, AltinatorDB.profile.minimap)
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
   self:RegisterEvent("BANKFRAME_OPENED")
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
   self:UnregisterEvent("BANKFRAME_OPENED")
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

function AltinatorAddon:BANKFRAME_OPENED()
   AltinatorAddon:ScheduleTimer(AltinatorNS.AltinatorData.ScanBank, 0.5)	
end

function AltinatorAddon:GetMainFrame()
   return AltinatorFrame or AltinatorAddon:CreateMainFrame()
end

function AltinatorAddon:ToggleFrame()
   local frame = AltinatorAddon:GetMainFrame()
   frame:SetShown(not frame:IsShown())
   if frame:IsShown() then
      for i = 1, #AltinatorNS.Tabs do
         local tab = AltinatorNS.Tabs[i]
         if tab.content:IsShown() and tab.content.Refresh then
            tab.content:Refresh(tab.content)
         end
      end
   end
end

local function Tab_OnClick(self)
   PanelTemplates_SetTab(self:GetParent(), self:GetID())

   for i = 1, #AltinatorNS.Tabs do
      local tab = AltinatorNS.Tabs[i]
      if tab.content:IsShown() then
         tab.content:Hide()
      end
   end
   SetTitle("Altinator - " .. self.Name)
   self.content:LoadContent(self.content)
   self.content:Show()
end

local function CreateTabs(frame,  ...)
   local args = {...}
   AltinatorNS.Tabs = AltinatorNS.Tabs or {}
   local frameName = frame:GetName()
   for i, name in ipairs(args) do
      local tab = CreateFrame("Button", frameName.."Tab"..i, frame, "CharacterFrameTabButtonTemplate")
      tab:SetID(i)
      tab:SetText(name)
      tab.Name = name
      tab:SetScript("OnClick", Tab_OnClick)

      tab.content = CreateFrame("Frame", nil, frame)      
      tab.content:SetSize(C["Width"], C["Height"])
      tab.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28)
      tab.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 6)
      tab.content:Hide()
      
      table.insert(AltinatorNS.Tabs, tab)

      if(i==1) then
         tab:SetPoint("TOPLEFT", AltinatorFrame, "BOTTOMLEFT", 0, 2)
      else
         tab:SetPoint("TOPLEFT", AltinatorNS.Tabs[i-1], "TOPRIGHT", -14, 0)
      end
   end
   frame.numTabs = #AltinatorNS.Tabs
   return unpack(AltinatorNS.Tabs)
end

function SetTitle(title)
   AltinatorFrame.Title:SetText(title)
end

function AltinatorAddon:CreateMainFrame()
   AltinatorFrame = CreateFrame("Frame", "AltinatorFrame", UIParent, "BasicFrameTemplateWithInset")
   AltinatorFrame:SetSize(C["Width"], C["Height"])
   AltinatorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
   AltinatorFrame:SetToplevel(true)
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

   AltinatorNS.AltinatorTooltip = CreateFrame("GameTooltip", "AltinatorTooltipFrame", AltinatorFrame, "GameTooltipTemplate")
   AltinatorNS.AltinatorTooltip:SetFrameStrata("TOOLTIP")

   AltinatorFrame.TitleBg:SetHeight(30)
   AltinatorFrame.Title = AltinatorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
   AltinatorFrame.Title:SetPoint("CENTER", AltinatorFrame.TitleBg, "CENTER", 0, 6)
   SetTitle(AddonName)

   AltinatorFrame.OptionsButton = AltinatorFrame.OptionsButton or CreateFrame("Button", nil, AltinatorFrame, "GameMenuButtonTemplate");
   AltinatorFrame.OptionsButton:SetPoint("TOPRIGHT", AltinatorFrame, "TOPRIGHT", -23, 2);
   AltinatorFrame.OptionsButton:SetSize(24, 24);
   AltinatorFrame.OptionsButton:SetText("|TInterface\\Buttons\\UI-OptionsButton:0|t");
   AltinatorFrame.OptionsButton:SetNormalFontObject("GameFontNormal");
   AltinatorFrame.OptionsButton:SetHighlightFontObject("GameFontHighlight");
   AltinatorFrame.OptionsButton:SetScript("OnClick", function(button)
      Settings.OpenToCategory(AltinatorNS.AltinatorOptions.Category:GetID())
   end)

   local overView, activityView, gearView, AttunementView, searchView = CreateTabs(AltinatorFrame, L["Overview"], L["Activity"], L["Gear"], L["Attunement"], L["Search"])
   overView.content.LoadContent = AltinatorNS.AltinatorOverviewFrame.Initialize
   overView.content.Refresh = AltinatorNS.AltinatorOverviewFrame.Initialize
   activityView.content.LoadContent = AltinatorNS.AltinatorActivityFrame.Initialize
   activityView.content.Refresh = AltinatorNS.AltinatorActivityFrame.Initialize
   gearView.content.LoadContent = AltinatorNS.AltinatorGearFrame.Initialize
   gearView.content.Refresh = AltinatorNS.AltinatorGearFrame.Initialize
   AttunementView.content.LoadContent = AltinatorNS.AltinatorAttunementFrame.Initialize
   AttunementView.content.Refresh = AltinatorNS.AltinatorAttunementFrame.Initialize
   searchView.content.LoadContent = AltinatorNS.AltinatorSearchFrame.Initialize


   Tab_OnClick(overView)
   tinsert(UISpecialFrames, "AltinatorFrame");
   AltinatorFrame:Hide()
   return AltinatorFrame
end


