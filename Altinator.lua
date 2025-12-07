local AddonName, Addon = ...

local _WIDTH = 1024
local _HEIGHT = 576

local L = LibStub("AceLocale-3.0"):GetLocale("Altinator")
local C = Addon.C

local AltinatorAddon = LibStub("AceAddon-3.0"):NewAddon("Altinator", "AceEvent-3.0", "AceTimer-3.0")
local AltinatorLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Altinator", {  
	type = "data source",  
	text = "Altinator",  
	icon = "Interface\\Icons\\inv_scroll_03",  
	OnClick = function() AltinatorAddon.ToggleFrame() end,  
}) 
local icon = LibStub("LibDBIcon-1.0")
local recipeLib = LibStub("LibRecipes-3.0")
local AltinatorDB
local AltinatorFrame
local AltinatorTooltip
local AltinatorCache = {}
local AltinatorSettingsCategory, AltinatorSettingsLayout = Settings.RegisterVerticalLayoutCategory("Altinator")
SLASH_ALTINATOR1, SLASH_ALTINATOR2 = "/alt", "/altinator"

SlashCmdList.ALTINATOR = function(msg, editBox)
   if msg == "options" or msg == "o" then
      Settings.OpenToCategory(AltinatorSettingsCategory:GetID())
   else
      AltinatorAddon:ToggleFrame()
   end
end

function MergeObjects(mergeInto, mergeFrom)
    for k, v in pairs(mergeFrom) do
        if (type(v) == "table") and (type(mergeInto[k] or false) == "table") then
            MergeObjects(mergeInto[k], mergeFrom[k])
        else
            mergeInto[k] = v
        end
    end
    return mergeInto
end

local function OnMinimapSettingChanged(setting, value)
   if value then
      AltinatorDB.profile.minimap.hide = true
      icon:Hide("Altinator")
   else
      AltinatorDB.profile.minimap.hide = false
      icon:Show("Altinator")
   end
end

local function OnRecipeTooltipSettingChanged(setting, value)
   if value then
      AltinatorDB.profile.settings.showRecipeTooltips = true
   else
      AltinatorDB.profile.settings.showRecipeTooltips = false
   end
end

local charToDelete = ""

local function GetCharacterToDelete()
   return charToDelete
end

local function SetCharacterToDelete(value)
   charToDelete = value
end

local function GetAllCharactersSortedByRealm()
   local characterNames = {}
   for key, char in pairs(AltinatorDB.global.characters) do
         table.insert(characterNames, char.Realm .. "-" .. char.Name)
   end
   table.sort(characterNames)

   local container = Settings.CreateControlTextContainer()
   container:Add("", L["OptionSelectCharacter"])
   for i, char in ipairs(characterNames) do
         container:Add(char, char)
   end
   return container:GetData()
end

local function DeleteCharacter()
   if charToDelete == "" then
      return
   else
      local realm, name = strsplit("-", charToDelete, 2)
      local char = AltinatorDB.global.characters[name .. "-" .. realm]
      if char == nil then
         print("Character '" .. name .. "' from realm '" .. realm .. "' not found in Altinator database.")
         Settings.SetValue("Altinator_Character_To_Delete", "")
         return
      end
      local cr, cg, cb, web = GetClassColor(char.Class.File)
      print("Deleting '\124c" .. web .. name .. "\124r' from realm '" .. realm .. "' from Altinator database.")
      AltinatorDB.global.characters[name .. "-" .. realm] = nil
      Settings.SetValue("Altinator_Character_To_Delete", "")
   end
end

local function LoadOptionsViewFrame()
    local name = L["OptionsSettingsHeader"];
    local data = { name = name };
    local initializer = Settings.CreateSettingInitializer("SettingsListSectionHeaderTemplate", data);
    AltinatorSettingsLayout:AddInitializer(initializer);

	local minimapSetting = Settings.RegisterAddOnSetting(
      AltinatorSettingsCategory,
      "Altinator_Minimap_Toggle",
      "hide",
      AltinatorDB.profile.minimap,
      Settings.VarType.Boolean,
      L["OptionMinimap"],
      Settings.Default.False
   )
	minimapSetting:SetValueChangedCallback(OnMinimapSettingChanged)
	Settings.CreateCheckbox(AltinatorSettingsCategory, minimapSetting, L["OptionMinimap"])

	local tooltipSetting = Settings.RegisterAddOnSetting(
      AltinatorSettingsCategory,
      "Altinator_Tooltip_Toggle",
      "hideRecipeTooltips",
      AltinatorDB.profile.settings,
      Settings.VarType.Boolean,
      L["OptionTooltip"],
      Settings.Default.False
   )
	tooltipSetting:SetValueChangedCallback(OnRecipeTooltipSettingChanged)
	Settings.CreateCheckbox(AltinatorSettingsCategory, tooltipSetting, L["OptionTooltipText"])

    local name = L["OptionsDeleteHeader"];
    local data = { name = name };
    local initializer = Settings.CreateSettingInitializer("SettingsListSectionHeaderTemplate", data);
    AltinatorSettingsLayout:AddInitializer(initializer);

	local deleteCharacterSetting = Settings.RegisterProxySetting(
		AltinatorSettingsCategory,
		"Altinator_Character_To_Delete",
		Settings.VarType.String,
		L["OptionSelectCharacterToDelete"],
		"",
		GetCharacterToDelete,
		SetCharacterToDelete
	)
	Settings.CreateDropdown(AltinatorSettingsCategory, deleteCharacterSetting, GetAllCharactersSortedByRealm)

	local deleteButtonInitializer = CreateSettingsButtonInitializer(
		L["OptionDeleteSelected"], -- name
		L["OptionDelete"], -- buttonText
		DeleteCharacter,
		L["OptionDeleteTooltip"],
		true,
		nil,
		nil
	)

	local addonLayout = SettingsPanel:GetLayout(AltinatorSettingsCategory)
	addonLayout:AddInitializer(deleteButtonInitializer)

   Settings.RegisterAddOnCategory(AltinatorSettingsCategory)
end

local function SavePlayerDataLogin()
   local name, realm = UnitFullName("player")
   local data = MergeObjects(AltinatorDB.global.characters[name .. "-" .. realm] or {}, AltinatorAddon.CurrentCharacter)
   AltinatorDB.global.characters[name .. "-" .. realm] = data
   AltinatorAddon.CurrentCharacter = data
   data.Name = name
   data.Realm = realm
   data.FullName= name .. "-" .. realm
   data.Sex = UnitSex("player")
   data.Level = UnitLevel("player")
   data.Faction = UnitFactionGroup("player")
      
   data.Rank = data.Rank or {}
   data.Rank.Value = UnitPVPRank("player")
   data.Rank.Name = GetPVPRankInfo(data.Rank.Value)
   local hk, points = GetPVPThisWeekStats()
   data.Honour = data.Honour or {}
   data.Honour.HKs = hk
   data.Honour.Points = points

   data.Money = GetMoney()
   data.LastLogin = time()
   data.LastLogout = data.LastLogout or time()

   local className, classFilename, classId = UnitClass("player")
   data.Class= data.Class or {}
   data.Class.Name=className
   data.Class.File=classFilename
   data.Class.Id=classId

   local raceName, raceFile, raceID = UnitRace("player")
   data.Race= data.Race or {}
   data.Race.Name=raceName
   data.Race.File=raceFile
   data.Race.Id=raceID

   local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo("player")
   data.Guild= data.Guild or {}
   data.Guild.Name=guildName
   data.Guild.Rank=guildRankName

   data.XP=data.XP or{}
   data.XP.Current=UnitXP("player")
   data.XP.Needed=UnitXPMax("player")
   data.XP.Rested=GetXPExhaustion()

   data.Professions=data.Professions or {}
   data.ProfessionsSecondairy=data.ProfessionsSecondairy or {}
   local profNames_rev = tInvert(L["ProfessionIDs"])
   local skillsFound = 0
   for i = 1, GetNumSkillLines() do
    local name, _, _, skillRank, _, _, skillMaxRank = GetSkillLineInfo(i)
    if profNames_rev[name] then
      local profId=profNames_rev[name]
      skillsFound = skillsFound + 1
      if C["SecondairyProfession"][profId] then
         data.ProfessionsSecondairy[profId]= data.ProfessionsSecondairy[profId] or {}
         data.ProfessionsSecondairy[profId].Name=name
         data.ProfessionsSecondairy[profId].File=C["ProfessionIcons"][profNames_rev[name]]
         data.ProfessionsSecondairy[profId].Skill=skillRank
         data.ProfessionsSecondairy[profId].SkillMax=skillMaxRank
         data.ProfessionsSecondairy[profId].Spells= data.ProfessionsSecondairy[profId].Spells or {}
         data.ProfessionsSecondairy[profId].Items= data.ProfessionsSecondairy[profId].Items or {}
      else
         data.Professions[profId]= data.Professions[profId] or {}
         data.Professions[profId].Name=name
         data.Professions[profId].File=C["ProfessionIcons"][profNames_rev[name]]
         data.Professions[profId].Skill=skillRank
         data.Professions[profId].SkillMax=skillMaxRank
         data.Professions[profId].Spells= data.Professions[profId].Spells or {}
         data.Professions[profId].Items= data.Professions[profId].Items or {}
      end
    end
   end

   data.Mail = data.Mail or {}
   for i=#data.Mail,1,-1 do
      if data.Mail[i].ExpiryTime < time() then
         AutoReturnMail(data.Mail)
         table.remove(data.Mail, i)
      end
   end
end

local function ClearPlayerMailData()
   local data = AltinatorAddon.CurrentCharacter
   data.Mail = data.Mail or {}
   for i=#data.Mail,1,-1 do
      if data.Mail[i].ArrivalTime < time() then
         table.remove(data.Mail, i)
      end
   end
   data.Money = GetMoney() -- update money in case mail had money attached
end

local function SavePlayerDataLogout()
   local data = AltinatorAddon.CurrentCharacter
   data.LastLogout = time()
end


local function SavePlayerTimePlayed(total, level)
   local data = AltinatorAddon.CurrentCharacter
   data.TimePlayed = {}
   data.TimePlayed.Total = total
   data.TimePlayed.Level = level
end

local function SavePlayerMoney(total, level)
   local data = AltinatorAddon.CurrentCharacter
   data.Money = GetMoney()
end

local function SavePlayerXP()
   local data = AltinatorAddon.CurrentCharacter
   data.XP=data.XP or{}
   data.XP.Current=UnitXP("player")
   data.XP.Needed=UnitXPMax("player")
   data.XP.Rested=GetXPExhaustion()
end

local function SavePlayerResting()
   local data = AltinatorAddon.CurrentCharacter
   data.Resting = IsResting()
end

local function SavePlayerGuild()
   local data = AltinatorAddon.CurrentCharacter
   local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo("player")
   data.Guild= data.Guild or {}
   data.Guild.Name=guildName
   data.Guild.Rank=guildRankName
end

function CountInString(string, pattern)
    return select(2, string.gsub(base, pattern, ""))
end

local function GetRealmCharactersSorted()
   local characterNames = {}
   local realm = GetNormalizedRealmName()
   for key, char in pairs(AltinatorDB.global.characters) do
      if char.Realm == realm then
         table.insert(characterNames, key)
      end
   end
   table.sort(characterNames)
   return characterNames
end

local function GetCharacterProfession(char, profId)
   return char.Professions[profId] or char.ProfessionsSecondairy[profId] or nil
end

local function CharacterProfessionRecipeKnownOrLearnable(profId, spellId, itemId)
   local characters = GetRealmCharactersSorted()
   local charactersThatKnow = {}
   local charactersThatCouldLearn = {}
   for i, name in ipairs(characters) do
      local char = AltinatorDB.global.characters[name]
      if char then
         local prof = GetCharacterProfession(char, profId)
         if prof then
            local known = false
            if spellId and prof.Spells and prof.Spells[spellId] then
               known = true
               table.insert(charactersThatKnow, char)
            end
            if itemId and prof.Items and prof.Items[itemId] then
               known = true
               table.insert(charactersThatKnow, char)
            end
            if not known  then
               table.insert(charactersThatCouldLearn, char)
            end
         end
      end
   end
   return charactersThatKnow, charactersThatCouldLearn
end

local function GetRecipeLevel(link)
   local AltinatorFrame = AltinatorFrame or AltinatorAddon:CreateMainFrame()
   AltinatorTooltip:SetOwner(AltinatorFrame, "ANCHOR_LEFT")
	AltinatorTooltip:ClearLines()
	AltinatorTooltip:SetHyperlink(link)
	
	local tooltipName = AltinatorTooltip:GetName()
	
	for i = 2, AltinatorTooltip:NumLines(), 1 do
		local tooltipText = _G[tooltipName .. "TextLeft" .. i]:GetText()
		if tooltipText then
			local _, _, rLevel = string.find(tooltipText, "%((%d+)%)")
			if rLevel then
            AltinatorTooltip:Hide()
            --print("Recipe required level: " .. rLevel)
				return tonumber(rLevel)
			end
		end
	end
end

local function CreateCharacterKnownByTooltipLines(chars)
   local knownBy = {
      "Already known by:",
   }
   if chars and #chars > 0 then
      for i, char in ipairs(chars) do
         local cr, cg, cb, web = GetClassColor(char.Class.File)
         table.insert(knownBy, "\124c" .. web .. char.Name .. "\124r")
      end
      return knownBy
   end
   return nil
end

local function CreateCharacterLearnTooltipLines(charsCouldLearn, profId, requiredSkill)
   local learnedBy = {
      "Could be learned by:"
   }
   if charsCouldLearn and #charsCouldLearn > 0 then
      for i, char in ipairs(charsCouldLearn) do
         local cr, cg, cb, web = GetClassColor(char.Class.File)
         local prof = GetCharacterProfession(char, profId)
         --print("prof for " .. char.Name .. ": " .. (prof and prof.Name or "nil") .. ", skill: " .. (prof and prof.Skill or "nil") .. ", requiredSkill: " .. (requiredSkill or "nil"))
         if prof and prof.Skill > requiredSkill then
            table.insert(learnedBy, "\124c" .. web .. char.Name .. "\124r (" .. prof.Skill .. ")")
         else
            table.insert(learnedBy, "\124c" .. web .. char.Name .. "\124r (\124cnIMPOSSIBLE_DIFFICULTY_COLOR:" .. prof.Skill .. "\124r)")
         end
         
      end
      return learnedBy
   end
   return nil
end

local GameTooltipReady = false

local function GameTooltip_Add(tooltip, itemLink)

   if AltinatorDB.profile.settings.hideRecipeTooltips then
      return
   end

	local itemString = itemLink:match("item[%-?%d:]+")
	local _, itemId = strsplit(":", itemString)

   if not itemId or itemId == "" or itemId == "0" then
      return
   end

   local name, _, _, _, _, _, _, _, _, _, _, classId, subclassID = GetItemInfo(tonumber(itemId))
   if classId ~= C["RecipeClassId"] then
      return
   end
   local profId = C["ProfessionSubclassIdToProfessionId"][subclassID]
   local success, spellId, createdItemId = pcall(function()
      return recipeLib:GetRecipeInfo(tonumber(itemId))
   end)
   local requiredSkill = GetRecipeLevel(itemLink)
   if success then
      if spellId or itemId then
         local knownChars, couldLearnChars, knownText, learnText
         AltinatorCache.Recipes = AltinatorCache.Recipes or {}
         if spellId then
            AltinatorCache.Recipes.Spells = AltinatorCache.Recipes.Spells or {}
            AltinatorCache.Recipes.Spells[spellId] = AltinatorCache.Recipes.Spells[spellId] or {}
            if not AltinatorCache.Recipes.Spells[spellId].knownText and not AltinatorCache.Recipes.Spells[spellId].learnText then
               knownChars, couldLearnChars = CharacterProfessionRecipeKnownOrLearnable(profId, spellId, createdItemId)
               AltinatorCache.Recipes.Spells[spellId].knownText = CreateCharacterKnownByTooltipLines(knownChars)
               AltinatorCache.Recipes.Spells[spellId].learnText = CreateCharacterLearnTooltipLines(couldLearnChars, profId, requiredSkill)
            end
            knownText = AltinatorCache.Recipes.Spells[spellId].knownText or nil
            learnText = AltinatorCache.Recipes.Spells[spellId].learnText or nil
         end
         if itemId then
            AltinatorCache.Recipes.Items = AltinatorCache.Recipes.Items or {}
            AltinatorCache.Recipes.Items[itemId] = AltinatorCache.Recipes.Items[itemId] or {}
            if not AltinatorCache.Recipes.Items[itemId].knownText and not AltinatorCache.Recipes.Items[itemId].learnText then
               knownChars, couldLearnChars = knownChars, couldLearnChars or CharacterProfessionRecipeKnownOrLearnable(profId, spellId, createdItemId)
               AltinatorCache.Recipes.Items[itemId].knownText = CreateCharacterKnownByTooltipLines(knownChars)
               AltinatorCache.Recipes.Items[itemId].learnText = CreateCharacterLearnTooltipLines(couldLearnChars, profId, requiredSkill)
            end
            knownText = AltinatorCache.Recipes.Items[itemId].knownText or nil
            learnText = AltinatorCache.Recipes.Items[itemId].learnText or nil
         end

         if not knownText and not learnText then
            return
         end
         tooltip:AddLine(" ")
         if knownText then
            tooltip:AddLine(knownText[1])
            local tempString = ""
            for i = 2, #knownText do
               tempString = tempString .. knownText[i]
               if (i-1)%3 == 0 then
                  tooltip:AddLine(tempString)
                  tempString = ""
               elseif i < #knownText then
                  tempString = tempString .. ", "
               end
            end
            if tempString ~= "" then
               tooltip:AddLine(tempString)
            end
            tooltip:AddLine(" ")
         end
         if learnText then
            tooltip:AddLine(learnText[1])
            local tempString = ""
            for i = 2, #learnText do
               tempString = tempString .. learnText[i]
               if (i-1)%3 == 0 then
                  tooltip:AddLine(tempString)
                  tempString = ""
               elseif i < #learnText then
                  tempString = tempString .. ", "
               end
            end
            if tempString ~= "" then
               tooltip:AddLine(tempString)
            end
            tooltip:AddLine(" ")
         end
      end
   end
end

local function GameTooltip_OnTooltipSetItem(tooltip)
   if not GameTooltipReady then
      return
   end
   GameTooltipReady = false
	local _, link = tooltip:GetItem()
	if not link then return; end
	
	GameTooltip_Add(tooltip, link)
end

local function GameTooltip_OnTooltipCleared(tooltip)
   GameTooltipReady = true
end

local function GameTooltip_SetCraftItem(tooltip, recipeIndex, reagentIndex)
	local link = GetCraftReagentItemLink(recipeIndex, reagentIndex)
	if not link then return; end
	GameTooltip_Add(tooltip, link)
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
	icon:Register("Altinator", AltinatorLDB, AltinatorDB.profile.minimap)
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
   LoadOptionsViewFrame()
   RequestTimePlayed()
   GameTooltipReady = true
   GameTooltip:HookScript("OnTooltipSetItem", GameTooltip_OnTooltipSetItem)
   GameTooltip:HookScript("OnTooltipCleared", GameTooltip_OnTooltipCleared)
   hooksecurefunc(GameTooltip, "SetCraftItem", GameTooltip_SetCraftItem)
   hooksecurefunc("DoTradeSkill", function()
			AltinatorCache.updateCooldowns = true
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
      SavePlayerDataLogin()
   end
end

function AltinatorAddon:PLAYER_LOGOUT()
   SavePlayerDataLogout()
end

function AltinatorAddon:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(self, type)
   if(type == 17) then
      ClearPlayerMailData()
   end
end

function AltinatorAddon:TIME_PLAYED_MSG(self, total, level)
	SavePlayerTimePlayed(total, level)
end

function AltinatorAddon:PLAYER_MONEY()
   SavePlayerMoney()
end

function AltinatorAddon:PLAYER_LEVEL_UP()
   SavePlayerXP()
end

function AltinatorAddon:PLAYER_XP_UPDATE()
   SavePlayerXP()
end

function AltinatorAddon:PLAYER_UPDATE_RESTING()
   SavePlayerResting()
end

function AltinatorAddon:PLAYER_GUILD_UPDATE()
   SavePlayerGuild()
end

function AltinatorAddon:PLAYER_GUILD_UPDATE()
   SavePlayerGuild()
end

function AltinatorAddon:PLAYER_GUILD_UPDATE()
   SavePlayerGuild()
end

local function ScanEnchantingRecipes()
	local tradeskillName = GetCraftDisplaySkillLine()
   local profNames_rev = tInvert(L["ProfessionIDs"])
   local profId = 0
   if profNames_rev[tradeskillName] then
      profId=profNames_rev[tradeskillName]
      --print("Tradeskill Name: " .. (tradeskillName or "nil") .. ", profId: " .. (profId or "nil"))
      for i = 1, GetNumCrafts() do
         local skillName, _, skillType = GetCraftInfo(i)			-- Ex: Runed Copper Rod
         local _, _, icon, _, _, _, spellID = GetSpellInfo(skillName)		-- Gets : icon = 135225, spellID = 7421
         --print(format("name: %s, skillType: %s, spellID: %d, icon: %d", name or "nil", skillType or "nil", spellID or 0, icon or 0))
         local prof = GetCharacterProfession(AltinatorAddon.CurrentCharacter, profId)
         if prof then
            prof.Spells = prof.Spells or {}
            prof.Spells[spellID] = {
               Name = skillName,
               SkillType = skillType,
               Icon = icon
            }
         end

      end
   end
end

local function ScanTradeSkills()
   local tradeskillName = GetTradeSkillLine()
   local profNames_rev = tInvert(L["ProfessionIDs"])
   local profId = 0
   if profNames_rev[tradeskillName] then
      profId=profNames_rev[tradeskillName]
      --print("Tradeskill Name: " .. (tradeskillName or "nil") .. ", profId: " .. (profId or "nil"))
      local numTradeSkills = GetNumTradeSkills()
      local skillName, skillType, _, _, altVerb = GetTradeSkillInfo(1)	-- test the first line and abort if not valid
      if not tradeskillName or not numTradeSkills
         or	tradeskillName == "UNKNOWN"
         or	numTradeSkills == 0
         or (skillType ~= "header" and skillType ~= "subheader") then
         return
      end

      for i = 1, numTradeSkills do
         local link
         local itemID
         skillName, skillType, _, _, altVerb = GetTradeSkillInfo(i)
         local cooldown = GetTradeSkillCooldown(i)
         link = GetTradeSkillItemLink(i)
         if link  then
            itemID = tonumber(link:match("item:(%d+)"))
         end
         if itemID and skillType ~= "header" then
            local prof = GetCharacterProfession(AltinatorAddon.CurrentCharacter, profId)
            if prof then
               prof.Items = prof.Items or {}
               prof.Items[itemID] = {
                  Name = skillName,
                  SkillType = skillType,
                  Cooldown = cooldown or 0,
                  CooldownEndTime = (cooldown and cooldown>0) and (time() + cooldown) or 0
               }
            end
         end
      end
   end
end

local function ScanCooldowns()
	local tradeskillName = GetTradeSkillLine()

   local profNames_rev = tInvert(L["ProfessionIDs"])
   local profId = 0
   if profNames_rev[tradeskillName] then
      profId=profNames_rev[tradeskillName]
      profession = GetCharacterProfession(AltinatorAddon.CurrentCharacter, profId)

      for i = 1, GetNumTradeSkills() do
         local skillName, skillType = GetTradeSkillInfo(i)
         if skillType ~= "header" then
            local cooldown = GetTradeSkillCooldown(i)
            if cooldown then
               link = GetTradeSkillItemLink(i)
               if link  then
                  itemID = tonumber(link:match("item:(%d+)"))
                  if itemID then
                     if profession then
                        profession.Items = profession.Items or {}
                        profession.Items[itemID] = {
                           Name = skillName,
                           SkillType = skillType,
                           Cooldown = cooldown or 0,
                           CooldownEndTime = (cooldown and cooldown>0) and (time() + cooldown) or 0
                        }
                     end
                  end
               end
            end
         end
      end
   end
end

function AltinatorAddon:TRADE_SKILL_SHOW()
   AltinatorAddon:ScheduleTimer(ScanTradeSkills, 0.5)	
end

function AltinatorAddon:TRADE_SKILL_UPDATE()
	if AltinatorCache.updateCooldowns then
		ScanCooldowns()
		AltinatorCache.updateCooldowns = false
	end	
   
end

function AltinatorAddon:CRAFT_UPDATE()
   AltinatorAddon:ScheduleTimer(ScanEnchantingRecipes, 0.5)	
end

local function HasAttachments()
	for attachmentIndex = 1, ATTACHMENTS_MAX_SEND do		-- mandatory, loop through all 12 slots, since attachments could be anywhere (ex: slot 4,5,8)
	   local item, itemID, icon, count = GetSendMailItem(attachmentIndex)
		if item then
         return true
		end
	end
   return false
end

hooksecurefunc("SendMail", function(recipient, subject, body, ...)
   local recipientName, recipientRealm = strsplit("-", recipient)
   recipientRealm = recipientRealm or GetNormalizedRealmName()
   local data = AltinatorDB.global.characters[recipientName .. "-" .. recipientRealm]
   if data then
      local attachments = HasAttachments()
      local moneySent = GetSendMailMoney()
      local arrivalTime = time()
      if moneySent>0 or attachments then
         arrivalTime = arrivalTime + (C["MailDelivery"] * 3600)
      end
      data.Mail = data.Mail or {}
      table.insert(data.Mail, {
         Sender = AltinatorAddon.CurrentCharacter.FullName,
         Subject = subject,
         Body = body or "",
         Time = time(),
         ArrivalTime = arrivalTime,
         ExpiryTime = time() + C["MailExpiry"] * 86400,
         HasAttachments = attachments,
         Money = moneySent,
         Returned = false
      })
   end
end)

hooksecurefunc("ReturnInboxItem", function(index, ...)
	local _, stationaryIcon, mailSender, mailSubject, moneySent, _, _, numAttachments = GetInboxHeaderInfo(index)
   local recipientName, recipientRealm = strsplit("-", mailSender)
   recipientRealm = recipientRealm or GetNormalizedRealmName()
   local data = AltinatorDB.global.characters[recipientName .. "-" .. recipientRealm]
   if data then
      data.Mail = data.Mail or {}
      table.insert(data.Mail, {
         Sender = AltinatorAddon.CurrentCharacter.FullName,
         Subject = subject,
         Body = body or "",
         Time = time(),
         ArrivalTime = time(),
         ExpiryTime = time() + C["MailExpiry"] * 86400,
         HasAttachments = numAttachments>0,
         Money = moneySent,
         Returned = true
      })
   end
end)

local function AutoReturnMail(mailData)
   if mailData.Returned then
      return
   end
   local data = AltinatorDB.global.characters[mailData.Sender]
   if data then
      table.insert(data.Mail, {
         Sender = AltinatorAddon.CurrentCharacter.FullName,
         Subject = mailData.Subject,
         Body = mailData.Body,
         Time = time(),
         ArrivalTime = time(),
         ExpiryTime = time() + C["MailExpiry"] * 86400,
         HasAttachments = mailData.HasAttachments,
         Money = mailData.Money,
         Returned = true
      })
   end
end

local function MoneyToGoldString(money)
	local copper = (("%02d"):format(money % 100))
	local silver = (("%02d"):format((money / 100) % 100))
	local gold = (("%02d"):format(money / 100 / 100))
	local ccoin = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t "	
	local scoin = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t "
	local gcoin = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t "	
	return (gold..gcoin..silver..scoin..copper..ccoin)
end

local function ShortTimeSpanToString(span)
   local days = math.floor(span / 86400)
   span = span - (days * 86400)
   local hours = math.floor(span / 3600)
   span = span - (hours * 3600)
   local minutes = math.floor(span / 60)
   span = span - (minutes * 60)
   local seconds = span

   if days>0 then
      if days == 1 then
         return days .. " " .. L["Day"]
      else
         return days .. " " .. L["Days"]
      end
   end
   if hours>0 then
      if hours == 1 then
         return hours .. " " .. L["Hour"]
      else
         return hours .. " " .. L["Hours"]
      end
   end
   if minutes>0 then
      if minutes == 1 then
         return minutes .. " " .. L["Minute"]
      else
         return minutes .. " " .. L["Minutes"]
      end
   end
   if seconds>0 then
      if seconds == 1 then
         return seconds .. " " .. L["Second"]
      else
         return seconds .. " " .. L["Seconds"]
      end
   end
   return ""
end

function LongTimeSpanToString(span)
   local days = math.floor(span / 86400)
   span = span - (days * 86400)
   local hours = math.floor(span / 3600)
   span = span - (hours * 3600)
   local minutes = math.floor(span / 60)
   span = span - (minutes * 60)
   local seconds = span

   local timeString = ""
   if days>0 then
      timeString = timeString .. days .. "\124cnADVENTURES_COMBAT_LOG_YELLOW:" .. L["DaysShort"] .. "\124r "
   end
   if hours>0 then
      timeString = timeString .. hours .. "\124cnADVENTURES_COMBAT_LOG_YELLOW:" .. L["HoursShort"] .. "\124r "
   end
   if minutes>0 then
      timeString = timeString .. minutes .. "\124cnADVENTURES_COMBAT_LOG_YELLOW:" .. L["MinutesShort"] .. "\124r "
   end
   return timeString
end

local function GetLastReset()
   local reset = C["ResetTimes"][GetCurrentRegion()]
   local weekday = C_DateAndTime.GetCurrentCalendarTime().weekday
   local today = time()
   local daysBack = (weekday + 7 - reset.day) % 7
   local lastReset = today - (daysBack * 86400)
   local resetHour = reset.hour
   local lastResetDate = date("*t", lastReset)
   lastResetDate.hour = resetHour
   lastResetDate.min = 0
   lastResetDate.sec = 0
   lastReset = time(lastResetDate)
   if lastReset > today then
      lastReset = lastReset - (7 * 86400)
   end
   return lastReset
end

local function CreateInnerBorder(frame, itemQuality)
   local iborder = frame.iborder or CreateFrame("Frame", nil, frame, "BackdropTemplate")
   frame.iborder = iborder
   frame.iborder:SetPoint("TOPLEFT", 1, -1)
   frame.iborder:SetPoint("BOTTOMRIGHT", -1, 1)
   frame.iborder:SetFrameLevel(frame:GetFrameLevel())
   frame.iborder:SetBackdrop({
      edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
      insets = { left = -1, right = -1, top = -1, bottom = -1}
   })
   local r, g, b, alpha = 0, 0, 0, 0
   if itemQuality > -1 then
      r, g, b, _ = C_Item.GetItemQualityColor(itemQuality)
      alpha = 1
   end
   frame.iborder:SetBackdropBorderColor(r, g, b, alpha)
	return frame.iborder
end

local function GetProfessionCooldowns(profession)
   local cooldowns = {}
   if profession.Items then
      for itemId, itemData in pairs(profession.Items) do
         if itemData.Cooldown and itemData.Cooldown>0 and itemData.CooldownEndTime and itemData.CooldownEndTime>time() then
            table.insert(cooldowns, {
               Name = itemData.Name,
               Cooldown = itemData.Cooldown,
               CooldownEndTime = itemData.CooldownEndTime
            })
         end
      end
   end
   return cooldowns
end

local function GetProfessionCooldownTooltip(tooltip, profession)
   local cooldowns = GetProfessionCooldowns(profession)
   if #cooldowns > 0 then
         for i, cd in ipairs(cooldowns) do
         tooltip:AddLine(cd.Name .. ": " .. ShortTimeSpanToString(cd.CooldownEndTime - time()))
      end
   else
      tooltip:AddLine(L["ProfessionNoCooldowns"])
   end
end

local function CreateProfessionTexture(contentFrame, charIndex, anchor, baseOffset, iconSize, profIndex, id, profession)
   local profPosition = profIndex
   if C["SecondairyProfession"][id] then
      profPosition = C["SecondairyProfessionOrder"][id] + 1 -- secondairy professions start after 2 normal professions
   end
   contentFrame.ProfessionIcons = contentFrame.ProfessionIcons or {}
   contentFrame.ProfessionIcons[charIndex] = contentFrame.ProfessionIcons[charIndex] or {}
   contentFrame.ProfessionIcons[charIndex][profIndex] = contentFrame.ProfessionIcons[charIndex][profIndex] or contentFrame:CreateTexture("Profession_Icon_" .. id, "BACKGROUND")
   contentFrame.ProfessionIcons[charIndex][profIndex]:SetWidth(iconSize)
   contentFrame.ProfessionIcons[charIndex][profIndex]:SetHeight(iconSize)
   contentFrame.ProfessionIcons[charIndex][profIndex]:SetPoint("LEFT", anchor,"LEFT", baseOffset + (profPosition * 80), 0)
   contentFrame.ProfessionIcons[charIndex][profIndex]:SetTexture("Interface\\ICONS\\" .. profession.File)

   contentFrame.ProfessionIcons[charIndex][profIndex]:SetScript("OnEnter", function(self)
      AltinatorTooltip:SetOwner(contentFrame, "ANCHOR_CURSOR")
      AltinatorTooltip:SetText(profession.Name)
      GetProfessionCooldownTooltip(AltinatorTooltip, profession)
      AltinatorTooltip:Show()
   end)
   contentFrame.ProfessionIcons[charIndex][profIndex]:SetScript("OnLeave", function(self)
      AltinatorTooltip:Hide()
   end)

   contentFrame.ProfessionTexts = contentFrame.ProfessionTexts or {}
   contentFrame.ProfessionTexts[charIndex] = contentFrame.ProfessionTexts[charIndex] or {}
   contentFrame.ProfessionTexts[charIndex][profIndex] = contentFrame.ProfessionTexts[charIndex][profIndex] or contentFrame:CreateFontString("Profession_Text_" .. id, "ARTWORK", "GameFontHighlight")
   contentFrame.ProfessionTexts[charIndex][profIndex]:SetPoint("LEFT", anchor, "LEFT", baseOffset + 20 + (profPosition * 80), 0)
   contentFrame.ProfessionTexts[charIndex][profIndex]:SetText(profession.Skill.."/"..profession.SkillMax)

   contentFrame.ProfessionTexts[charIndex][profIndex]:SetScript("OnEnter", function(self)
      AltinatorTooltip:SetOwner(contentFrame, "ANCHOR_CURSOR")
      AltinatorTooltip:SetText(profession.Name)
      GetProfessionCooldownTooltip(AltinatorTooltip, profession)
      AltinatorTooltip:Show()
   end)
   contentFrame.ProfessionTexts[charIndex][profIndex]:SetScript("OnLeave", function(self)
      AltinatorTooltip:Hide()
   end)
end

local function GetCharacterIcons(char)
   local faction = "h"
   local factionIcon = "inv_bannerpvp_01"
   local showRank = false
   if(char.Faction == "Alliance") then
      faction = "a"
      factionIcon = "inv_bannerpvp_02"
   end
   if(char.Rank and char.Rank.Value>=5) then
      factionIcon = "achievement_pvp_" .. faction .. "_"..string.format("%02d", char.Rank.Value-4)
      showRank = true
   end
   factionIcon = "Interface\\ICONS\\" .. factionIcon
   local raceIcon = "Interface\\ICONS\\Achievement_character_" .. char.Race.File .. "_" .. C["Genders"][char.Sex]
   local classIcon = "Interface\\ICONS\\classicon_" .. char.Class.File
   return factionIcon, raceIcon, classIcon, showRank
end

local function CreateCharacterName(contentFrame, charIndex, char, anchor, baseOffset, iconSize)
   contentFrame.FactionIcons[charIndex] = contentFrame.FactionIcons[charIndex] or contentFrame:CreateTexture("Faction_Icon_" .. charIndex, "BACKGROUND")
   contentFrame.FactionIcons[charIndex]:SetSize(iconSize, iconSize)
   contentFrame.FactionIcons[charIndex]:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, baseOffset * -1 * charIndex)
   local factionIcon, raceIcon, classIcon, showRank = GetCharacterIcons(char)
   if showRank then
      contentFrame.FactionIcons[charIndex]:SetScript("OnEnter", function(self)
         AltinatorTooltip:SetOwner(contentFrame, "ANCHOR_CURSOR")
         AltinatorTooltip:SetText(char.Rank.Name)
      end)
      contentFrame.FactionIcons[charIndex]:SetScript("OnLeave", function(self)
         AltinatorTooltip:Hide()
      end)
   else
      contentFrame.FactionIcons[charIndex]:SetScript("OnEnter", nil)
      contentFrame.FactionIcons[charIndex]:SetScript("OnLeave", nil)
   end
   contentFrame.FactionIcons[charIndex]:SetTexture(factionIcon)

   contentFrame.RaceIcons[charIndex] = contentFrame.RaceIcons[charIndex] or contentFrame:CreateTexture("Race_Icon_" .. charIndex, "BACKGROUND")
   contentFrame.RaceIcons[charIndex]:SetSize(iconSize, iconSize)
   contentFrame.RaceIcons[charIndex]:SetPoint("LEFT", contentFrame.FactionIcons[charIndex], "LEFT", 15, 0)
   contentFrame.RaceIcons[charIndex]:SetTexture(raceIcon)

   contentFrame.ClassIcons[charIndex] = contentFrame.ClassIcons[charIndex] or contentFrame:CreateTexture("Class_Icon_" .. charIndex, "BACKGROUND")
   contentFrame.ClassIcons[charIndex]:SetSize(iconSize, iconSize)
   contentFrame.ClassIcons[charIndex]:SetPoint("LEFT", contentFrame.RaceIcons[charIndex], "LEFT", 15, 0)
   contentFrame.ClassIcons[charIndex]:SetTexture(classIcon)

   contentFrame.CharNames[charIndex] = contentFrame.CharNames[charIndex] or contentFrame:CreateFontString(nil,"ARTWORK","GameFontHighlight")
   contentFrame.CharNames[charIndex]:SetPoint("LEFT", contentFrame.ClassIcons[charIndex], "LEFT", 20, 0)
   contentFrame.CharNames[charIndex]:SetText(char.Name)
   local cr, cg, cb, web = GetClassColor(char.Class.File)
   contentFrame.CharNames[charIndex]:SetTextColor(cr, cg, cb)
end

local function LoadOverViewFrame(self)
   local ICON_SIZE = 15
   local ROW_HEIGHT = ICON_SIZE + 5

   self.NameHeader = self.NameHeader or self:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
   self.NameHeader:SetPoint("TOPLEFT", 5, -10)
   self.NameHeader:SetText(L["Characters"])

   self.GuildHeader = self.GuildHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   self.GuildHeader:SetPoint("LEFT", self.NameHeader, "LEFT", 165, 0)
   self.GuildHeader:SetText(L["Guild"])

   self.MoneyHeader = self.MoneyHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   self.MoneyHeader:SetPoint("LEFT", self.GuildHeader, "LEFT", 200, 0)
   self.MoneyHeader:SetText(L["Gold"])

   self.LevelHeader = self.LevelHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   self.LevelHeader:SetPoint("LEFT", self.MoneyHeader, "LEFT", 140, 0)
   self.LevelHeader:SetText(L["Level"])

   self.ProfessionsHeader = self.ProfessionsHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   self.ProfessionsHeader:SetPoint("LEFT", self.LevelHeader, "LEFT", 80, 0)
   self.ProfessionsHeader:SetText(L["Professions"])

   local totalCharacters = 0
   local totalMoney = 0
   local characters = GetRealmCharactersSorted()
   self.FactionIcons = self.FactionIcons or {}
   self.RaceIcons = self.RaceIcons or {}
   self.ClassIcons = self.ClassIcons or {}
   self.CharNames = self.CharNames or {}
   self.GuildNames = self.GuildNames or {}
   self.MoneyTexts = self.MoneyTexts or {}
   self.LevelTexts = self.LevelTexts or {}
   for i, name in ipairs(characters) do
      local char = AltinatorDB.global.characters[name]
      CreateCharacterName(self, i, char, self.NameHeader, ROW_HEIGHT, ICON_SIZE)

      self.GuildNames[i] = self.GuildNames[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
      self.GuildNames[i]:SetPoint("LEFT", self.FactionIcons[i], "LEFT", 165, 0)
      if char.Guild then
         self.GuildNames[i]:SetText(char.Guild.Name)
      else
         self.GuildNames[i]:SetText("")
      end
      

      self.MoneyTexts[i] = self.MoneyTexts[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
      self.MoneyTexts[i]:SetPoint("RIGHT", self.FactionIcons[i], "LEFT", 495, 0)
      self.MoneyTexts[i]:SetText(MoneyToGoldString(char.Money))
      totalMoney = totalMoney + char.Money

      self.LevelTexts[i] = self.LevelTexts[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
      self.LevelTexts[i]:SetPoint("LEFT", self.FactionIcons[i], "LEFT", 505, 0)
      local level = char.Level
      if level~=60 then
         --local RestPercent = (char.XP.Rested/char.XP.Needed * 100)
         local tmpRested = char.XP.Rested or 0
         local timeResting = (time() - (char.LastLogout or char.LastLogin) )/3600
         local multiplier = C["RestedXPTimeSpan"]
         if not char.Resting then
            multiplier = C["RestedXPTimeSpanNotResting"]
         end
         tmpRested = tmpRested + ((char.XP.Needed * (C["RestedXPBonus"] / multiplier * timeResting)) )
         local RestPercent = (tmpRested/char.XP.Needed * 100)
         if RestPercent>150 then
            RestPercent = 150
         end
         level = (("%.1f (\124cnHIGHLIGHT_LIGHT_BLUE:%d%%\124r)"):format(level + (char.XP.Current/char.XP.Needed), RestPercent))
      end
      self.LevelTexts[i]:SetText(level)

      local profIndex = 0;
      for id, profession in pairs(char.Professions) do
         CreateProfessionTexture(self, i, self.FactionIcons[i], 585, ICON_SIZE, profIndex, id, profession)
         profIndex = profIndex+1
      end
      for id, profession in pairs(char.ProfessionsSecondairy) do
         CreateProfessionTexture(self, i, self.FactionIcons[i], 585, ICON_SIZE, profIndex, id, profession)
         profIndex = profIndex+1
      end
      totalCharacters = totalCharacters + 1
   end

   self.TotalName = self.TotalName or self:CreateFontString("TotalsName", "ARTWORK", "GameFontHighlight")
   self.TotalName:SetPoint("TOPLEFT", self.NameHeader, "BOTTOMLEFT", 0, ROW_HEIGHT * -1 * (totalCharacters+2))
   self.TotalName:SetText(L["Totals"])

   self.TotalMoneyString = self.TotalMoneyString or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   self.TotalMoneyString:SetPoint("RIGHT", self.TotalName, "LEFT", 495, 0)
   self.TotalMoneyString:SetText(MoneyToGoldString(totalMoney))

   self:SetSize(_WIDTH - 50, ROW_HEIGHT * (totalCharacters + 3))
end

local function LoadActivityViewFrame(self)
   if Syndicator and Syndicator.API.IsReady() then
      local ICON_SIZE = 15
      local ROW_HEIGHT = ICON_SIZE + 5

      local data = AltinatorAddon.CurrentCharacter

      self.NameHeader = self.NameHeader or self:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
      self.NameHeader:SetPoint("TOPLEFT", 5, -10)
      self.NameHeader:SetText(L["Characters"])

      self.MailHeader = self.MailHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      self.MailHeader:SetPoint("LEFT", self.NameHeader, "LEFT", 165, 0)
      self.MailHeader:SetText(L["Mail"])

      self.AuctionsHeader = self.AuctionsHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      self.AuctionsHeader:SetPoint("LEFT", self.MailHeader, "LEFT", 150, 0)
      self.AuctionsHeader:SetText(L["Auctions"])

      self.PlayedHeader = self.PlayedHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      self.PlayedHeader:SetPoint("LEFT", self.AuctionsHeader, "LEFT", 150, 0)
      self.PlayedHeader:SetText(L["Played"])

      self.LastLogoutHeader = self.LastLogoutHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      self.LastLogoutHeader:SetPoint("LEFT", self.PlayedHeader, "LEFT", 150, 0)
      self.LastLogoutHeader:SetText(L["LastLogout"])

      self.HonourHeader = self.HonourHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      self.HonourHeader:SetPoint("LEFT", self.LastLogoutHeader, "LEFT", 150, 0)
      self.HonourHeader:SetText(L["Honour"])

      local currentTime = time()
      local totalCharacters = 0
      local totalMail = 0
      local totalAuctions = 0
      local totalAuctionItems = 0
      local totalPlayed = 0
      local characters = GetRealmCharactersSorted()
      self.FactionIcons = self.FactionIcons or {}
      self.RaceIcons = self.RaceIcons or {}
      self.ClassIcons = self.ClassIcons or {}
      self.CharNames = self.CharNames or {}
      self.MailTexts = self.MailTexts or {}
      self.AuctionTexts = self.AuctionTexts or {}
      self.PlayedTexts = self.PlayedTexts or {}
      self.LastPlayed = self.LastPlayed or {}
      self.HonourTexts = self.HonourTexts or {}
      for i, name in ipairs(characters) do
         local char = AltinatorDB.global.characters[name]
         local charSyndicator = Syndicator.API.GetByCharacterFullName(name)
         if charSyndicator then
            CreateCharacterName(self, i, char, self.NameHeader, ROW_HEIGHT, ICON_SIZE)

            self.MailTexts[i] = self.MailTexts[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            self.MailTexts[i]:SetPoint("LEFT", self.FactionIcons[i], "LEFT", 165, 0)
            local charMails = 0
            local charMailsInTransit = 0
            char.Mail = char.Mail or {}
            for i=#char.Mail,1,-1 do
               if char.Mail[i].ArrivalTime < time() then
                  charMails = charMails + 1
               else
                  charMailsInTransit = charMailsInTransit + 1
               end
            end
            totalMail = totalMail + charMails + charMailsInTransit
            if charMails>0 or charMailsInTransit>0 then
               self.MailTexts[i]:SetText("\124cnGREEN_FONT_COLOR:" .. charMails .. "\124r (\124cnYELLOW_FONT_COLOR:" .. charMailsInTransit .. "\124r)")
            else
               self.MailTexts[i]:SetText(charMails)
            end

            local auctionCount = 0
            local auctionItems = 0
            for j, auction in pairs(charSyndicator["auctions"]) do
               if auction["itemCount"]>0 then
                  auctionCount = auctionCount + 1
                  auctionItems = auctionItems + auction["itemCount"]
               end
            end
            totalAuctions = totalAuctions + auctionCount
            totalAuctionItems = totalAuctionItems + auctionItems

            self.AuctionTexts[i] = self.AuctionTexts[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            self.AuctionTexts[i]:SetPoint("LEFT", self.FactionIcons[i], "LEFT", 315, 0)
            if auctionCount>0 then
               self.AuctionTexts[i]:SetText("\124cnGREEN_FONT_COLOR:" .. auctionCount .. " (" .. auctionItems .. " " .. L["AuctionItems"] .. ")\124r")
            else
               self.AuctionTexts[i]:SetText(auctionCount .. " (" .. auctionItems .. " " .. L["AuctionItems"] .. ")")
            end
            

            self.PlayedTexts[i] = self.PlayedTexts[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            self.PlayedTexts[i]:SetPoint("LEFT", self.FactionIcons[i], "LEFT", 465, 0)
            self.PlayedTexts[i]:SetText(char.TimePlayed and LongTimeSpanToString(char.TimePlayed.Total) or "")
            totalPlayed = totalPlayed + (char.TimePlayed and char.TimePlayed.Total or 0)

            local lastPlayed = (char.LastLogout or char.LastLogin)
            self.LastPlayed[i] = self.LastPlayed[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            self.LastPlayed[i]:SetPoint("LEFT", self.FactionIcons[i], "LEFT", 615, 0)
            if name == data.FullName then
               self.LastPlayed[i]:SetText("\124cnGREEN_FONT_COLOR:" .. L["Online"] .. "\124r")
            else
               self.LastPlayed[i]:SetText(ShortTimeSpanToString(currentTime - lastPlayed))
            end

            self.HonourTexts[i] = self.HonourTexts[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            self.HonourTexts[i]:SetPoint("LEFT", self.FactionIcons[i], "LEFT", 765, 0)
            char.Honour = char.Honour or { HKs = 0, Points = 0 }
            
            if GetLastReset() > lastPlayed then
               char.Honour.HKs = 0
               char.Honour.Points = 0
            end

            if char.Honour.HKs>=15 then
               self.HonourTexts[i]:SetText(char.Honour.Points .. " (\124cnGREEN_FONT_COLOR:" .. char.Honour.HKs .. "\124r " .. L["Kills"] .. ")")
            else
               self.HonourTexts[i]:SetText(L["HonourNotEnoughKills"] .. " (" .. char.Honour.HKs .. "/15)")
            end

            totalCharacters = totalCharacters + 1
         end
      end

      self.TotalName = self.TotalName or self:CreateFontString("TotalsName", "ARTWORK", "GameFontHighlight")
      self.TotalName:SetPoint("TOPLEFT", self.NameHeader, "BOTTOMLEFT", 0, ROW_HEIGHT * -1 * (totalCharacters+2))
      self.TotalName:SetText(L["Totals"])

      self.TotalMailString = self.TotalMailString or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      self.TotalMailString:SetPoint("LEFT", self.TotalName, "LEFT", 165, 0)
      self.TotalMailString:SetText(totalMail)

      self.TotalAuctionsString = self.TotalAuctionsString or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      self.TotalAuctionsString:SetPoint("LEFT", self.TotalName, "LEFT", 315, 0)
      self.TotalAuctionsString:SetText(totalAuctions .. " (" .. totalAuctionItems .. " " .. L["AuctionItems"] .. ")")

      self.TotalPlayedString = self.TotalPlayedString or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      self.TotalPlayedString:SetPoint("LEFT", self.TotalName, "LEFT", 465, 0)
      self.TotalPlayedString:SetText(LongTimeSpanToString(totalPlayed))

      self:SetSize(_WIDTH - 50, ROW_HEIGHT * (totalCharacters + 3))
   else
      self.NoDataFrame = self.NoDataFrame or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      self.NoDataFrame:SetPoint("CENTER", 0, 0)
      self.NoDataFrame:SetText(L["Syndicator_Not_Ready"])

      self:SetSize(_WIDTH-42, _HEIGHT -50)
   end
end

local function LoadGearViewFrame(self)
   if Syndicator and Syndicator.API.IsReady() then
      local ROW_WIDTH = _WIDTH-50
      local ROW_HEIGHT = 40
      local ICON_SIZE = 32
      
      self.Header = self.Header or self:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
      self.Header:SetPoint("TOPLEFT", 5, -10)
      self.Header:SetText(L["GearTitle"])

      self.Frames = self.Frames or {}
      for s=1,19 do
         self.Frames["EmptyTextureFrame" .. s] = self.Frames["EmptyTextureFrame" .. s] or CreateFrame("Frame", nil, self)
         self.Frames["EmptyTextureFrame" .. s]:SetSize(ICON_SIZE, ICON_SIZE)
         self.Frames["EmptyTextureFrame" .. s]:SetPoint("LEFT", self.Header, "LEFT", ((s+1)*(ICON_SIZE+8))+96, 0)
         CreateInnerBorder(self.Frames["EmptyTextureFrame" .. s], 6)

         self.Frames["EmptyTextureFrame" .. s].EmptyTexture = self.Frames["EmptyTextureFrame" .. s].EmptyTexture or self.Frames["EmptyTextureFrame" .. s]:CreateTexture(nil, "BACKGROUND")
         self.Frames["EmptyTextureFrame" .. s].EmptyTexture:SetSize(ICON_SIZE, ICON_SIZE)
         self.Frames["EmptyTextureFrame" .. s].EmptyTexture:SetPoint("CENTER")
         self.Frames["EmptyTextureFrame" .. s].EmptyTexture:SetTexture(C:GetEquipmentSlotIcon(s))

         self.Frames["EmptyTextureFrame" .. s].TooltipText = L["EquipmentSlots"][s]
         self.Frames["EmptyTextureFrame" .. s]:SetScript("OnEnter", function(self)
            AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
            AltinatorTooltip:SetText(self.TooltipText)
         end)
         self.Frames["EmptyTextureFrame" .. s]:SetScript("OnLeave", function(self)
            AltinatorTooltip:Hide()
         end)
      end

      local totalCharacters = 0
      local characters = GetRealmCharactersSorted()
      self.ClassFrames = self.ClassFrames or {}
      self.CharNames = self.CharNames or {}
      for i, name in ipairs(characters) do
            local char = AltinatorDB.global.characters[name]
            local charSyndicator = Syndicator.API.GetByCharacterFullName(name)
            if (charSyndicator) then
               local equipment = charSyndicator["equipped"]

               self.ClassFrames[i]= self.ClassFrames[i] or self:CreateTexture(nil, "BACKGROUND")
               self.ClassFrames[i]:SetSize(ICON_SIZE, ICON_SIZE)
               self.ClassFrames[i]:SetPoint("LEFT", self.Header, "LEFT", 0, (ROW_HEIGHT * -1 * (totalCharacters+1)) - ROW_HEIGHT)
               self.ClassFrames[i]:SetTexture("Interface\\ICONS\\classicon_" .. char.Class.File)
               
               self.CharNames[i] = self.CharNames[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
               self.CharNames[i]:SetPoint("LEFT", self.ClassFrames[i], "LEFT", ICON_SIZE + 10, 0)
               self.CharNames[i]:SetText(char.Name)
               local cr, cg, cb, web = GetClassColor(char.Class.File)
               self.CharNames[i]:SetTextColor(cr, cg, cb)

               for j = 2, 20 do
                  local item = equipment[j]
                  self.Frames["item" .. totalCharacters .. "i" .. j] = self.Frames["item" .. totalCharacters .. "i" .. j] or CreateFrame("Frame", nil, self)
                  self.Frames["item" .. totalCharacters .. "i" .. j]:SetSize(ICON_SIZE, ICON_SIZE)
                  self.Frames["item" .. totalCharacters .. "i" .. j]:SetPoint("LEFT", self.ClassFrames[i], "LEFT", (j*(ICON_SIZE+8))+96, 0)
                  if item["quality"] then
                     CreateInnerBorder(self.Frames["item" .. totalCharacters .. "i" .. j], item["quality"])
                  else
                     CreateInnerBorder(self.Frames["item" .. totalCharacters .. "i" .. j], -1)
                  end
                  self.Frames["item" .. totalCharacters .. "i" .. j].Texture = self.Frames["item" .. totalCharacters .. "i" .. j].Texture or self.Frames["item" .. totalCharacters .. "i" .. j]:CreateTexture(nil, "BACKGROUND")
                  self.Frames["item" .. totalCharacters .. "i" .. j].Texture:SetSize(ICON_SIZE, ICON_SIZE)
                  self.Frames["item" .. totalCharacters .. "i" .. j].Texture:SetPoint("CENTER")
                  if item["iconTexture"] then
                     self.Frames["item" .. totalCharacters .. "i" .. j].Texture:SetTexture(item["iconTexture"])
                  else
                     self.Frames["item" .. totalCharacters .. "i" .. j].Texture:SetTexture(C:GetEquipmentSlotIcon(j-1))
                  end

                  if item["quality"] then
                     self.Frames["item" .. totalCharacters .. "i" .. j].TooltipItemLink = item["itemLink"]
                     self.Frames["item" .. totalCharacters .. "i" .. j]:SetScript("OnEnter", function(self)
                        AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
                        AltinatorTooltip:SetHyperlink(self.TooltipItemLink)
                     end)
                     self.Frames["item" .. totalCharacters .. "i" .. j]:SetScript("OnLeave", function(self)
                        AltinatorTooltip:Hide()
                     end)
                  else
                     self.Frames["item" .. totalCharacters .. "i" .. j]:SetScript("OnEnter", nil)
                     self.Frames["item" .. totalCharacters .. "i" .. j]:SetScript("OnLeave", nil)
                  end
               end

               totalCharacters = totalCharacters + 1
            end


      end
      self:SetSize(_WIDTH-42, ROW_HEIGHT * (totalCharacters + 2))
   else
      self.NoDataFrame = self.NoDataFrame or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      self.NoDataFrame:SetPoint("CENTER", 0, 0)
      self.NoDataFrame:SetText(L["Syndicator_Not_Ready"])

      self:SetSize(_WIDTH-42, _HEIGHT -50)
   end
end

local function SearchResult(result)
   local frame = _G["searchResult"]
   frame.Frames = frame.Frames or {}
   local totalResults = 0
   local ICON_SIZE = 32
   local ROW_HEIGHT = 40
   for i, f in pairs(frame.Frames) do
      f:Hide()
   end
   for i, item in pairs(result) do
      local char = AltinatorDB.global.characters[item["source"]["character"]]
      if char then
         local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(item["itemID"])
         frame.Frames[i] = frame.Frames[i] or CreateFrame("Frame", nil, frame)
         frame.Frames[i].Frames = frame.Frames[i].Frames or {}
         frame.Frames[i]:Show()
         frame.Frames[i]:SetSize(ICON_SIZE, ICON_SIZE)
         frame.Frames[i]:SetPoint("TOPLEFT", 5, (ROW_HEIGHT * -1 * totalResults))
         CreateInnerBorder(frame.Frames[i], item["quality"])
         frame.Frames[i].Frames["texture"] = frame.Frames[i].Frames["texture"] or frame.Frames[i]:CreateTexture(nil, "BACKGROUND")
         frame.Frames[i].Frames["texture"]:SetSize(ICON_SIZE, ICON_SIZE)
         frame.Frames[i].Frames["texture"]:SetPoint("CENTER")
         if itemTexture then
            frame.Frames[i].Frames["texture"]:SetTexture(itemTexture)
         else
            frame.Frames[i].Frames["texture"]:SetTexture(136235)
         end

         frame.Frames[i].Frames["texture"].TooltipItemLink = item["itemLink"]
         frame.Frames[i].Frames["texture"]:SetScript("OnEnter", function(self)
            AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
            AltinatorTooltip:SetHyperlink(self.TooltipItemLink)
         end)
         frame.Frames[i].Frames["texture"]:SetScript("OnLeave", function(self)
            AltinatorTooltip:Hide()
         end)

         frame.Frames[i].Frames["itemNameString"] = frame.Frames[i].Frames["itemNameString"] or frame.Frames[i]:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         frame.Frames[i].Frames["itemNameString"]:SetPoint("LEFT", frame.Frames[i].Frames["texture"], "LEFT", ICON_SIZE + 10, 0)
         local r, g, b, _ = C_Item.GetItemQualityColor(item["quality"])
         frame.Frames[i].Frames["itemNameString"]:SetText(itemName)
         frame.Frames[i].Frames["itemNameString"]:SetTextColor(r, g, b)

         frame.Frames[i].Frames["charName"] = frame.Frames[i].Frames["charName"] or frame.Frames[i]:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         frame.Frames[i].Frames["charName"]:SetPoint("LEFT", frame.Frames[i].Frames["texture"], "LEFT", ICON_SIZE + 300, 0)
         frame.Frames[i].Frames["charName"]:SetText(char.Name)
         local r, g, b, _ = GetClassColor(char.Class.File)
         frame.Frames[i].Frames["charName"]:SetTextColor(r, g, b)

         frame.Frames[i].Frames["itemLocationString"] = frame.Frames[i].Frames["itemLocationString"] or frame.Frames[i]:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         frame.Frames[i].Frames["itemLocationString"]:SetPoint("LEFT", frame.Frames[i].Frames["texture"], "LEFT", ICON_SIZE + 450, 0)
         frame.Frames[i].Frames["itemLocationString"]:SetText(item["source"]["container"])

         frame.Frames[i].Frames["itemCountString"] = frame.Frames[i].Frames["itemCountString"] or frame.Frames[i]:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         frame.Frames[i].Frames["itemCountString"]:SetPoint("LEFT", frame.Frames[i].Frames["texture"], "LEFT", ICON_SIZE + 550, 0)
         frame.Frames[i].Frames["itemCountString"]:SetText(item["itemCount"])

         totalResults = totalResults + 1
      end
   end
   if totalResults == 0 then
      frame.NoResultsFrame = frame.NoResultsFrame or frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      frame.NoResultsFrame:SetPoint("CENTER", 0, 0)
      frame.NoResultsFrame:SetText(L["SearchNoResults"])
   else
      if frame.NoResultsFrame then
         frame.NoResultsFrame:Hide()
      end
   end   
   frame:SetSize(_WIDTH-50, ROW_HEIGHT * (totalResults + 2))
end

local function SearchItems(searchTerm)
   Syndicator.Search.RequestSearchEverywhereResults(searchTerm, SearchResult)
end

local function LoadSearchViewFrame(self)
   local ROW_WIDTH = _WIDTH-50
   local ROW_HEIGHT = 20
   if Syndicator and Syndicator.API.IsReady() then
      self.Header = self.Header or self:CreateFontString("SearchTitle", "ARTWORK", "GameFontHighlight")
      self.Header:SetPoint("TOPLEFT", 5, -10)
      self.Header:SetText(L["SearchLabel"])

      self.SearchBox = self.SearchBox or CreateFrame("EditBox", nil, self, "InputBoxTemplate")
      self.SearchBox:SetSize(300, ROW_HEIGHT)
      self.SearchBox:SetPoint("LEFT", self.Header, "RIGHT", 15, 0)
      self.SearchBox:SetAutoFocus(false);
      self.SearchBox:SetMultiLine(false);
      self.SearchBox:SetScript("OnKeyUp", function(self, key)
         if key == "ENTER" then
            SearchItems(self:GetText())
            self:ClearFocus()
         end
      end)

      self.SearchButton = self.SearchButton or CreateFrame("Button", nil, self, "GameMenuButtonTemplate");
      self.SearchButton:SetPoint("LEFT", self.SearchBox, "RIGHT", 10, 0);
      self.SearchButton:SetSize(100, ROW_HEIGHT+2);
      self.SearchButton:SetText(L["SearchButton"]);
      self.SearchButton:SetNormalFontObject("GameFontNormal");
      self.SearchButton:SetHighlightFontObject("GameFontHighlight");
      self.SearchButton:SetScript("OnClick", function(button)
            SearchItems(self.SearchBox:GetText())
            self.SearchBox:ClearFocus()
      end)

      self.SearchResult = self.SearchResult or CreateFrame("Frame", "searchResult", self)
      self.SearchResult:SetPoint("TOPLEFT", 0, -2 * ROW_HEIGHT)

      self:SetSize(_WIDTH - 42, _HEIGHT - 50)
   else
      self.NoDataFrame = self.NoDataFrame or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      self.NoDataFrame:SetPoint("CENTER", 0, 0)
      self.NoDataFrame:SetText(L["Syndicator_Not_Ready"])

      self:SetSize(_WIDTH-42, _HEIGHT -50)
   end
end



function AltinatorAddon:ToggleFrame()
   local f = AltinatorFrame or AltinatorAddon:CreateMainFrame()
   f:SetShown(not f:IsShown())
end

local function ScrollFrame_OnMouseWheel(self, delta)
   local newValue = self:GetVerticalScroll() - (delta * 20)
   if (newValue < 0) then
      newValue = 0
   elseif (newValue > self:GetVerticalScrollRange()) then
      newValue = self:GetVerticalScrollRange()
   end
   self:SetVerticalScroll(newValue)
end

local function Tab_OnClick(self)
   PanelTemplates_SetTab(self:GetParent(), self:GetID())

   local scrollChild = AltinatorFrame.ScrollFrame:GetScrollChild()
   if(scrollChild) then
      --scrollChild:UnloadContent()
      scrollChild:Hide()
   end
   AltinatorFrame.ScrollFrame:SetScrollChild(self.content);
   SetTitle("Altinator - " .. self.Name)
   self.content:LoadContent()
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

      tab.content = CreateFrame("Frame", nil, AltinatorFrame.ScrollFrame)
      tab.content:SetSize(_WIDTH-42, _HEIGHT)
      tab.content:Hide()
      
      table.insert(contents, tab.content)

      if(i==1) then
         tab:SetPoint("TOPLEFT", AltinatorFrame, "BOTTOMLEFT", 5, 7)
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
   AltinatorFrame = CreateFrame("Frame", "AltinatorFrame", UIParent, "UIPanelDialogTemplate")
   AltinatorTooltip = CreateFrame("GameTooltip", "AltinatorTooltipFrame", AltinatorFrame, "GameTooltipTemplate")
   AltinatorFrame:SetSize(_WIDTH, _HEIGHT)
   AltinatorFrame:SetFrameLevel(100)
   AltinatorFrame:SetPoint("CENTER")
   AltinatorFrame.Title:SetFontObject("GameFontHighlight")
   SetTitle("Altinator")
   AltinatorFrameClose:ClearAllPoints()
   AltinatorFrameClose:SetPoint("TOPRIGHT", AltinatorFrameTitleBG, "TOPRIGHT", 10, 8)
   AltinatorFrameClose:SetScript("OnClick", function()
      AltinatorFrame:Hide()
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
         local scrollChild = AltinatorFrame.ScrollFrame:GetScrollChild()
         if(scrollChild) then
            scrollChild:LoadContent()
            scrollChild:Show()
         end
   end)

   AltinatorFrame:SetScript("OnHide", function()
         PlaySound(808)
   end)
   tinsert(UISpecialFrames, "AltinatorFrame");

   AltinatorFrame.ScrollFrame = CreateFrame("ScrollFrame", "AltinatorScrollFrame", AltinatorFrame, "UIPanelScrollFrameTemplate")
   AltinatorFrame.ScrollFrame:SetPoint("TOPLEFT", AltinatorFrameDialogBG, "TOPLEFT", 4, -8)
   AltinatorFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", AltinatorFrameDialogBG, "BOTTOMRIGHT", -24, 2)
   AltinatorFrame.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel)
   AltinatorFrame.ScrollFrame:EnableMouse(true)

   local overView, activityView, gearView, searchView = CreateTabs(AltinatorFrame, L["Overview"], L["Activity"], L["Gear"], L["Search"])
   overView.LoadContent = LoadOverViewFrame
   activityView.LoadContent = LoadActivityViewFrame
   gearView.LoadContent = LoadGearViewFrame
   searchView.LoadContent = LoadSearchViewFrame

   Tab_OnClick(_G["AltinatorFrameTab1"])
   AltinatorFrame:Hide()
   return AltinatorFrame
end


function AltinatorLDB:OnTooltipShow(tooltip)
   self:AddLine("Altinator", 255, 255, 255)
   self:AddLine(" ")
   self:AddLine("Gold:")
   local totalmoney = 0
   local characters = GetRealmCharactersSorted()
   for i, name in ipairs(characters) do
      local char = AltinatorDB.global.characters[name]
      local factionIcon, raceIcon, classIcon, showRank = GetCharacterIcons(char)
      local money = char.Money
      totalmoney = totalmoney + money
      local cr, cg, cb, ca = GetClassColor(char.Class.File)
      self:AddDoubleLine("|T"..factionIcon..":0|t" .. "|T"..raceIcon..":0|t".. "|T"..classIcon..":0|t" .. " " .. char.Name .. " (" .. char.Level .. ")", MoneyToGoldString(char.Money), cr, cg, cb)
   end
   self:AddLine(" ")
   self:AddDoubleLine("Total", MoneyToGoldString(totalmoney))
   self:AddTexture("Interface\\Icons\\Inv_misc_coin_02")
end

function AltinatorLDB:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	AltinatorLDB.OnTooltipShow(GameTooltip)
	GameTooltip:Show()
end

function AltinatorLDB:OnLeave()
	GameTooltip:Hide()
end