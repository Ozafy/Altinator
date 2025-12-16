local AddonName, AltinatorNS = ...

local C = AltinatorNS.C

local recipeLib = LibStub("LibRecipes-3.0")

AltinatorNS.AltinatorGameTooltip = {}
local AltinatorGameTooltip = AltinatorNS.AltinatorGameTooltip

local GameTooltipReady = false

local function GetRecipeLevel(link)
    local AltinatorFrame = AltinatorNS.AltinatorAddon:GetMainFrame()
    AltinatorNS.AltinatorTooltip:SetOwner(AltinatorFrame, "ANCHOR_LEFT")
    AltinatorNS.AltinatorTooltip:ClearLines()
    AltinatorNS.AltinatorTooltip:SetHyperlink(link)
	
	local tooltipName = AltinatorNS.AltinatorTooltip:GetName()
	
   for i = 1, select("#", AltinatorNS.AltinatorTooltip:GetRegions()) do
      local region = select(i, AltinatorNS.AltinatorTooltip:GetRegions())
      if region and region:GetObjectType() == "FontString" then
         local tooltipText = region:GetText()
         if tooltipText then
            local _, _, rLevel = string.find(tooltipText, "%((%d+)%)")
            if rLevel then
               AltinatorNS.AltinatorTooltip:Hide()
               --print("Recipe required level: " .. rLevel)
               return tonumber(rLevel)
            end
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
         local prof = AltinatorNS.AltinatorData:GetCharacterProfession(char, profId)
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

local function GameTooltip_Add(tooltip, itemLink)

   if AltinatorNS.AltinatorDB.profile.settings.hideRecipeTooltips then
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
         AltinatorNS.AltinatorCache.Recipes = AltinatorNS.AltinatorCache.Recipes or {}
         if spellId then
            AltinatorNS.AltinatorCache.Recipes.Spells = AltinatorNS.AltinatorCache.Recipes.Spells or {}
            AltinatorNS.AltinatorCache.Recipes.Spells[spellId] = AltinatorNS.AltinatorCache.Recipes.Spells[spellId] or {}
            if not AltinatorNS.AltinatorCache.Recipes.Spells[spellId].knownText and not AltinatorNS.AltinatorCache.Recipes.Spells[spellId].learnText then
               knownChars, couldLearnChars = AltinatorNS.AltinatorData:CharacterProfessionRecipeKnownOrLearnable(profId, spellId, createdItemId)
               AltinatorNS.AltinatorCache.Recipes.Spells[spellId].knownText = CreateCharacterKnownByTooltipLines(knownChars)
               AltinatorNS.AltinatorCache.Recipes.Spells[spellId].learnText = CreateCharacterLearnTooltipLines(couldLearnChars, profId, requiredSkill)
            end
            knownText = AltinatorNS.AltinatorCache.Recipes.Spells[spellId].knownText or nil
            learnText = AltinatorNS.AltinatorCache.Recipes.Spells[spellId].learnText or nil
         end
         if itemId then
            AltinatorNS.AltinatorCache.Recipes.Items = AltinatorNS.AltinatorCache.Recipes.Items or {}
            AltinatorNS.AltinatorCache.Recipes.Items[itemId] = AltinatorNS.AltinatorCache.Recipes.Items[itemId] or {}
            if not AltinatorNS.AltinatorCache.Recipes.Items[itemId].knownText and not AltinatorNS.AltinatorCache.Recipes.Items[itemId].learnText then
               knownChars, couldLearnChars = knownChars, couldLearnChars or AltinatorNS.AltinatorData:CharacterProfessionRecipeKnownOrLearnable(profId, spellId, createdItemId)
               AltinatorNS.AltinatorCache.Recipes.Items[itemId].knownText = CreateCharacterKnownByTooltipLines(knownChars)
               AltinatorNS.AltinatorCache.Recipes.Items[itemId].learnText = CreateCharacterLearnTooltipLines(couldLearnChars, profId, requiredSkill)
            end
            knownText = AltinatorNS.AltinatorCache.Recipes.Items[itemId].knownText or nil
            learnText = AltinatorNS.AltinatorCache.Recipes.Items[itemId].learnText or nil
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

function AltinatorGameTooltip:Initialize()
   GameTooltip:HookScript("OnTooltipSetItem", GameTooltip_OnTooltipSetItem)
   GameTooltip:HookScript("OnTooltipCleared", GameTooltip_OnTooltipCleared)
   hooksecurefunc(GameTooltip, "SetCraftItem", GameTooltip_SetCraftItem)
   GameTooltipReady = true
end