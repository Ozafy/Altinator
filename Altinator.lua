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

local pendingTimers = {}
-- (re)starts a timer for key, so a burst of events results in a single call
local function ScheduleOnce(key, func, delay)
   if pendingTimers[key] then
      AltinatorAddon:CancelTimer(pendingTimers[key])
   end
   pendingTimers[key] = AltinatorAddon:ScheduleTimer(function()
      pendingTimers[key] = nil
      -- events can fire during loading, before the character data is set up
      if AltinatorAddon.CurrentCharacter.FullName then
         func()
      end
   end, delay)
end

local bankOpen = false

local function BagsChanged()
   AltinatorNS.AltinatorData:SavePlayerBags()
   AltinatorNS.AltinatorData:SavePlayerItemLevel() -- overall item level includes items in bags
   AltinatorNS.AltinatorData:SavePlayerAttunements()
   if bankOpen then
      AltinatorNS.AltinatorData:ScanBank()
   end
end

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
         characters = {},
         hiddenCharacters = {}
      }
	})
   AltinatorNS.AltinatorDB = AltinatorDB
	icon:Register(AddonName, AltinatorLDB, AltinatorDB.profile.minimap)
   if AltinatorDB.global.dbversion ~= C["MajorDBVersion"] then
      AltinatorDB.global.characters = {}
      AltinatorDB.global.hiddenCharacters = {}
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
   self:RegisterEvent("ZONE_CHANGED")
   self:RegisterEvent("ZONE_CHANGED_INDOORS")
   self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
   self:RegisterEvent("PLAYER_GUILD_UPDATE")
   self:RegisterEvent("TRADE_SKILL_SHOW")
   self:RegisterEvent("TRADE_SKILL_UPDATE")
   self:RegisterEvent("CRAFT_UPDATE")
   self:RegisterEvent("CHAT_MSG_SKILL")
   self:RegisterEvent("SKILL_LINES_CHANGED")
   self:RegisterEvent("BANKFRAME_OPENED")
   self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
   self:RegisterEvent("BAG_UPDATE_DELAYED")
   self:RegisterEvent("BAG_UPDATE_COOLDOWN")
   self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
   self:RegisterEvent("BANKFRAME_CLOSED")
   self:RegisterEvent("PLAYER_PVP_KILLS_CHANGED")
   self:RegisterEvent("PLAYER_PVP_RANK_CHANGED")
   self:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
   self:RegisterEvent("QUEST_TURNED_IN")
   self:RegisterEvent("UNIT_SPELLCAST_START")
   self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
   self:RegisterEvent("UNIT_SPELLCAST_STOP")
   self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
   AltinatorNS.AltinatorOptions:Initialize()
   RequestTimePlayed()
   AltinatorNS.AltinatorGameTooltip:Initialize()
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
   self:UnregisterEvent("ZONE_CHANGED")
   self:UnregisterEvent("ZONE_CHANGED_INDOORS")
   self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
   self:UnregisterEvent("PLAYER_GUILD_UPDATE")
   self:UnregisterEvent("TRADE_SKILL_SHOW")
   self:UnregisterEvent("TRADE_SKILL_UPDATE")
   self:UnregisterEvent("CRAFT_UPDATE")
   self:UnregisterEvent("CHAT_MSG_SKILL")
   self:UnregisterEvent("SKILL_LINES_CHANGED")
   self:UnregisterEvent("BANKFRAME_OPENED")
   self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
   self:UnregisterEvent("BAG_UPDATE_DELAYED")
   self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
   self:UnregisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
   self:UnregisterEvent("BANKFRAME_CLOSED")
   self:UnregisterEvent("PLAYER_PVP_KILLS_CHANGED")
   self:UnregisterEvent("PLAYER_PVP_RANK_CHANGED")
   self:UnregisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
   self:UnregisterEvent("QUEST_TURNED_IN")
   self:UnregisterEvent("UNIT_SPELLCAST_START")
   self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
   self:UnregisterEvent("UNIT_SPELLCAST_STOP")
   self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
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

function AltinatorAddon:PLAYER_LEVEL_UP(event, level)
   AltinatorNS.AltinatorData:SavePlayerXP(level)
end

function AltinatorAddon:PLAYER_XP_UPDATE()
   AltinatorNS.AltinatorData:SavePlayerXP()
end

function AltinatorAddon:PLAYER_UPDATE_RESTING()
   AltinatorNS.AltinatorData:SavePlayerResting()
end

function AltinatorAddon:ZONE_CHANGED()
   ScheduleOnce("location", AltinatorNS.AltinatorData.SavePlayerLocation, 0.5)
end

function AltinatorAddon:ZONE_CHANGED_INDOORS()
   ScheduleOnce("location", AltinatorNS.AltinatorData.SavePlayerLocation, 0.5)
end

function AltinatorAddon:ZONE_CHANGED_NEW_AREA()
   ScheduleOnce("location", AltinatorNS.AltinatorData.SavePlayerLocation, 0.5)
end

function AltinatorAddon:PLAYER_GUILD_UPDATE()
   AltinatorNS.AltinatorData:SavePlayerGuild()
end

function AltinatorAddon:TRADE_SKILL_SHOW()
   ScheduleOnce("tradeSkills", AltinatorNS.AltinatorData.ScanTradeSkills, 0.5)
end

-- TRADE_SKILL_UPDATE fires in bursts (crafting, bag changes, filtering), so rescan once things settle
-- this picks up skill ups (recipe colors) and cooldowns started by crafting
function AltinatorAddon:TRADE_SKILL_UPDATE()
   ScheduleOnce("tradeSkills", AltinatorNS.AltinatorData.ScanTradeSkills, 0.5)
end

function AltinatorAddon:CHAT_MSG_SKILL()
   ScheduleOnce("professions", AltinatorNS.AltinatorData.SavePlayerProfessions, 0.5)
end

function AltinatorAddon:SKILL_LINES_CHANGED()
   ScheduleOnce("professions", AltinatorNS.AltinatorData.SavePlayerProfessions, 0.5)
end

function AltinatorAddon:CRAFT_UPDATE()
   AltinatorAddon:ScheduleTimer(AltinatorNS.AltinatorData.ScanEnchantingRecipes, 0.5)	
end

function AltinatorAddon:BANKFRAME_OPENED()
   bankOpen = true
   AltinatorAddon:ScheduleTimer(AltinatorNS.AltinatorData.ScanBank, 0.5)	
end

function AltinatorAddon:BANKFRAME_CLOSED()
   bankOpen = false
end

function AltinatorAddon:PLAYERBANKBAGSLOTS_CHANGED()
   ScheduleOnce("bank", AltinatorNS.AltinatorData.ScanBank, 0.5)
end

function AltinatorAddon:BAG_UPDATE_DELAYED()
   ScheduleOnce("bags", BagsChanged, 0.5)
end

function AltinatorAddon:BAG_UPDATE_COOLDOWN()
   ScheduleOnce("itemCooldowns", AltinatorNS.AltinatorData.SaveProfessionItemCooldowns, 0.5)
end

function AltinatorAddon:PLAYER_EQUIPMENT_CHANGED()
   ScheduleOnce("itemLevel", AltinatorNS.AltinatorData.SavePlayerItemLevel, 0.5)
end

function AltinatorAddon:PLAYER_PVP_KILLS_CHANGED()
   ScheduleOnce("honour", AltinatorNS.AltinatorData.SavePlayerHonour, 1)
end

function AltinatorAddon:PLAYER_PVP_RANK_CHANGED()
   ScheduleOnce("honour", AltinatorNS.AltinatorData.SavePlayerHonour, 1)
end

function AltinatorAddon:CHAT_MSG_COMBAT_HONOR_GAIN()
   ScheduleOnce("honour", AltinatorNS.AltinatorData.SavePlayerHonour, 1)
end

-- the quest isn't always flagged as completed yet when this fires
function AltinatorAddon:QUEST_TURNED_IN()
   ScheduleOnce("attunements", AltinatorNS.AltinatorData.SavePlayerAttunements, 1)
end

function AltinatorAddon:UNIT_SPELLCAST_START(event, unit, castGUID, spellId)
   AltinatorNS.AltinatorData:SpellCastStart(unit, spellId)
end

function AltinatorAddon:UNIT_SPELLCAST_INTERRUPTED(event, unit, castGUID, spellId)
   AltinatorNS.AltinatorData:SpellCastStop(unit, spellId)
end

function AltinatorAddon:UNIT_SPELLCAST_STOP(event, unit, castGUID, spellId)
   AltinatorNS.AltinatorData:SpellCastStop(unit, spellId)
end

function AltinatorAddon:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellId)
   AltinatorNS.AltinatorData:SpellCastSucceeded(unit, spellId)
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

   local overView, activityView, professionView, gearView, AttunementView, searchView = CreateTabs(AltinatorFrame, L["Overview"], L["Activity"], L["Professions"], L["Gear"], L["Attunement"], L["Search"])
   overView.content.LoadContent = AltinatorNS.AltinatorOverviewFrame.Initialize
   overView.content.Refresh = AltinatorNS.AltinatorOverviewFrame.Initialize
   activityView.content.LoadContent = AltinatorNS.AltinatorActivityFrame.Initialize
   activityView.content.Refresh = AltinatorNS.AltinatorActivityFrame.Initialize
   professionView.content.LoadContent = AltinatorNS.AltinatorProfessionFrame.Initialize
   professionView.content.Refresh = AltinatorNS.AltinatorProfessionFrame.Initialize
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


