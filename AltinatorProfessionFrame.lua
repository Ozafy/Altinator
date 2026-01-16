local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local AltinatorProfessionFrame = {}
AltinatorNS.AltinatorProfessionFrame = AltinatorProfessionFrame

local function GetMaxSkillForLevel(level)
   local maxSkill = 0
   for _, bracket in ipairs(C["ProfessionBrackets"]) do
      if level >= bracket.minLevel then
         maxSkill = bracket.maxSkill
      end
   end
   return maxSkill
end

local function GetProfessionCooldownTooltip(tooltip, cooldowns)
   if #cooldowns > 0 then
         for i, cd in ipairs(cooldowns) do
         tooltip:AddLine(cd.Name .. ": " .. AltinatorNS:LongTimeSpanToString(cd.CooldownEndTime - time()))
      end
   else
      tooltip:AddLine(L["ProfessionNoCooldowns"])
   end
end

local function CreateProfessionTexture(char, contentFrame, charIndex, anchor, baseOffset, iconSize, profIndex, id, profession)
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

   contentFrame.ProfessionTexts = contentFrame.ProfessionTexts or {}
   contentFrame.ProfessionTexts[charIndex] = contentFrame.ProfessionTexts[charIndex] or {}
   contentFrame.ProfessionTexts[charIndex][profIndex] = contentFrame.ProfessionTexts[charIndex][profIndex] or contentFrame:CreateFontString("Profession_Text_" .. id, "ARTWORK", "GameFontHighlight")
   contentFrame.ProfessionTexts[charIndex][profIndex]:SetPoint("LEFT", anchor, "LEFT", baseOffset + 20 + (profPosition * 80), 0)
   contentFrame.ProfessionTexts[charIndex][profIndex]:SetText(profession.Skill.."/"..profession.SkillMax)
   local levelPerc = profession.Skill/profession.SkillMax*100
   local brackets = 5
   local maxSkill = GetMaxSkillForLevel(char.Level)
   if profession.SkillMax==maxSkill and profession.Skill==maxSkill then
      brackets = 6
   end
   levelPerc = levelPerc/10*brackets
   local r, g, b, hex = C_Item.GetItemQualityColor(math.floor(levelPerc/10))
   contentFrame.ProfessionTexts[charIndex][profIndex]:SetTextColor(r, g, b)
end

function AltinatorProfessionFrame:Initialize(self)
    local _PADDING = 5
    local _ICON_SIZE = 15
    local _HEIGHT = _ICON_SIZE + 5

    self.NameHeader = self.NameHeader or self:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
    self.NameHeader:SetPoint("TOPLEFT", _PADDING, -10)
    self.NameHeader:SetText(L["Characters"])

    self.ProfessionsHeader = self.ProfessionsHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.ProfessionsHeader:SetPoint("LEFT", self.NameHeader, "LEFT", 165, 0)
    self.ProfessionsHeader:SetText(L["Professions"])

    self.CooldownHeader = self.CooldownHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.CooldownHeader:SetPoint("LEFT", self.ProfessionsHeader, "LEFT", 450, 0)
    self.CooldownHeader:SetText(L["ProfessionCooldowns"])

    local scrollFrame = self.ScrollFrame or AltinatorNS:CreateScrollFrame(self)

    local totalCharacters = 0
    local characters = AltinatorNS:GetRealmCharactersSorted()
    scrollFrame.content.FactionIcons = scrollFrame.content.FactionIcons or {}
    scrollFrame.content.RaceIcons = scrollFrame.content.RaceIcons or {}
    scrollFrame.content.ClassIcons = scrollFrame.content.ClassIcons or {}
    scrollFrame.content.CharNames = scrollFrame.content.CharNames or {}
    for i, name in ipairs(characters) do
         local char = AltinatorDB.global.characters[name]
         AltinatorNS:CreateCharacterName(scrollFrame.content, i, char, scrollFrame.content, _PADDING, _HEIGHT, _ICON_SIZE)
         
         local cooldowns = {}
         local profIndex = 0;
         for id, profession in pairs(char.Professions) do
            CreateProfessionTexture(char, scrollFrame.content, i, scrollFrame.content.FactionIcons[i], 165, _ICON_SIZE, profIndex, id, profession)
            local profCooldowns = AltinatorNS.AltinatorData:GetProfessionCooldowns(profession)
            for _, cd in ipairs(profCooldowns) do
               --print("CD found for " .. name .. " profession " .. profession.Name)
               table.insert(cooldowns, cd)
            end
            profIndex = profIndex+1
         end
         for id, profession in pairs(char.ProfessionsSecondairy) do
            CreateProfessionTexture(char, scrollFrame.content, i, scrollFrame.content.FactionIcons[i], 165, _ICON_SIZE, profIndex, id, profession)
            local secCooldowns = AltinatorNS.AltinatorData:GetProfessionCooldowns(profession)
            for _, cd in ipairs(secCooldowns) do
               --print("Secondairy CD found for " .. name .. " profession " .. profession.Name)
               table.insert(cooldowns, cd)
            end
            profIndex = profIndex+1
         end

         scrollFrame.content.ProfessionCooldownTexts = scrollFrame.content.ProfessionCooldownTexts or {}
         scrollFrame.content.ProfessionCooldownTexts[i] = scrollFrame.content.ProfessionCooldownTexts[i] or scrollFrame.content:CreateFontString("Profession_Cooldown_Text_" .. i, "ARTWORK", "GameFontHighlight")
         scrollFrame.content.ProfessionCooldownTexts[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 615, 0)
         if #cooldowns > 0 then
            scrollFrame.content.ProfessionCooldownTexts[i]:SetScript("OnEnter", function(self)
               AltinatorNS.AltinatorTooltip:SetOwner(scrollFrame.content, "ANCHOR_CURSOR")
               AltinatorNS.AltinatorTooltip:SetText(L["ProfessionCooldowns"])
               GetProfessionCooldownTooltip(AltinatorNS.AltinatorTooltip, cooldowns)
               AltinatorNS.AltinatorTooltip:Show()
            end)
            scrollFrame.content.ProfessionCooldownTexts[i]:SetScript("OnLeave", function(self)
               AltinatorNS.AltinatorTooltip:Hide()
            end)

            if #cooldowns == 1 then
               scrollFrame.content.ProfessionCooldownTexts[i]:SetText(#cooldowns .. " " .. L["ProfessionCooldown"])
            else
               scrollFrame.content.ProfessionCooldownTexts[i]:SetText(#cooldowns .. " " .. L["ProfessionCooldowns"])
            end
         else
            scrollFrame.content.ProfessionCooldownTexts[i]:SetText(L["ProfessionNoCooldowns"])
         end
        totalCharacters = totalCharacters + 1
    end

    scrollFrame.content:SetSize(C["Width"], _HEIGHT * (totalCharacters + 2))
end