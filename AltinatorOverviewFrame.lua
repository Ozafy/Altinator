local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(C["Name"])

local AltinatorOverviewFrame = {}
AltinatorNS.AltinatorOverviewFrame = AltinatorOverviewFrame

local function GetProfessionCooldownTooltip(tooltip, profession)
   local cooldowns = AltinatorNS.AltinatorData:GetProfessionCooldowns(profession)
   if #cooldowns > 0 then
         for i, cd in ipairs(cooldowns) do
         tooltip:AddLine(cd.Name .. ": " .. AltinatorNS:LongTimeSpanToString(cd.CooldownEndTime - time()))
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
      AltinatorNS.AltinatorTooltip:SetOwner(contentFrame, "ANCHOR_CURSOR")
      AltinatorNS.AltinatorTooltip:SetText(profession.Name)
      GetProfessionCooldownTooltip(AltinatorNS.AltinatorTooltip, profession)
      AltinatorNS.AltinatorTooltip:Show()
   end)
   contentFrame.ProfessionIcons[charIndex][profIndex]:SetScript("OnLeave", function(self)
      AltinatorNS.AltinatorTooltip:Hide()
   end)

   contentFrame.ProfessionTexts = contentFrame.ProfessionTexts or {}
   contentFrame.ProfessionTexts[charIndex] = contentFrame.ProfessionTexts[charIndex] or {}
   contentFrame.ProfessionTexts[charIndex][profIndex] = contentFrame.ProfessionTexts[charIndex][profIndex] or contentFrame:CreateFontString("Profession_Text_" .. id, "ARTWORK", "GameFontHighlight")
   contentFrame.ProfessionTexts[charIndex][profIndex]:SetPoint("LEFT", anchor, "LEFT", baseOffset + 20 + (profPosition * 80), 0)
   contentFrame.ProfessionTexts[charIndex][profIndex]:SetText(profession.Skill.."/"..profession.SkillMax)

   contentFrame.ProfessionTexts[charIndex][profIndex]:SetScript("OnEnter", function(self)
      AltinatorNS.AltinatorTooltip:SetOwner(contentFrame, "ANCHOR_CURSOR")
      AltinatorNS.AltinatorTooltip:SetText(profession.Name)
      GetProfessionCooldownTooltip(AltinatorNS.AltinatorTooltip, profession)
      AltinatorNS.AltinatorTooltip:Show()
   end)
   contentFrame.ProfessionTexts[charIndex][profIndex]:SetScript("OnLeave", function(self)
      AltinatorNS.AltinatorTooltip:Hide()
   end)
end

function AltinatorOverviewFrame:Initialize(self)
    local _PADDING = 5
    local _ICON_SIZE = 15
    local _HEIGHT = _ICON_SIZE + 5

    self.NameHeader = self.NameHeader or self:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
    self.NameHeader:SetPoint("TOPLEFT", _PADDING, -10)
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

    local scrollFrame = self.ScrollFrame or AltinatorNS:CreateScrollFrame(self)

    local totalCharacters = 0
    local totalMoney = 0
    local characters = AltinatorNS:GetRealmCharactersSorted()
    scrollFrame.content.FactionIcons = scrollFrame.content.FactionIcons or {}
    scrollFrame.content.RaceIcons = scrollFrame.content.RaceIcons or {}
    scrollFrame.content.ClassIcons = scrollFrame.content.ClassIcons or {}
    scrollFrame.content.CharNames = scrollFrame.content.CharNames or {}
    scrollFrame.content.GuildNames = scrollFrame.content.GuildNames or {}
    scrollFrame.content.MoneyTexts = scrollFrame.content.MoneyTexts or {}
    scrollFrame.content.LevelTexts = scrollFrame.content.LevelTexts or {}
    for i, name in ipairs(characters) do
        local char = AltinatorDB.global.characters[name]
        AltinatorNS:CreateCharacterName(scrollFrame.content, i, char, scrollFrame.content, _PADDING, _HEIGHT, _ICON_SIZE)

        scrollFrame.content.GuildNames[i] = scrollFrame.content.GuildNames[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
        scrollFrame.content.GuildNames[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 165, 0)
        if char.Guild then
            scrollFrame.content.GuildNames[i]:SetText(char.Guild.Name)
        else
            scrollFrame.content.GuildNames[i]:SetText("")
        end
        

        scrollFrame.content.MoneyTexts[i] = scrollFrame.content.MoneyTexts[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
        scrollFrame.content.MoneyTexts[i]:SetPoint("RIGHT", scrollFrame.content.FactionIcons[i], "LEFT", 495, 0)
        scrollFrame.content.MoneyTexts[i]:SetText(AltinatorNS:MoneyToGoldString(char.Money))
        totalMoney = totalMoney + char.Money

        scrollFrame.content.LevelTexts[i] = scrollFrame.content.LevelTexts[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
        scrollFrame.content.LevelTexts[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 505, 0)
        local level = char.Level
        local r, g, b, hex = C_Item.GetItemQualityColor(math.floor(level/10))
        scrollFrame.content.LevelTexts[i]:SetTextColor(r, g, b)
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

        scrollFrame.content.LevelTexts[i]:SetText(level)

        local profIndex = 0;
        for id, profession in pairs(char.Professions) do
            CreateProfessionTexture(scrollFrame.content, i, scrollFrame.content.FactionIcons[i], 585, _ICON_SIZE, profIndex, id, profession)
            profIndex = profIndex+1
        end
        for id, profession in pairs(char.ProfessionsSecondairy) do
            CreateProfessionTexture(scrollFrame.content, i, scrollFrame.content.FactionIcons[i], 585, _ICON_SIZE, profIndex, id, profession)
            profIndex = profIndex+1
        end
        totalCharacters = totalCharacters + 1
    end

    scrollFrame.content.TotalName = scrollFrame.content.TotalName or scrollFrame.content:CreateFontString("TotalsName", "ARTWORK", "GameFontHighlight")
    scrollFrame.content.TotalName:SetPoint("TOPLEFT", self.NameHeader, "BOTTOMLEFT", 0, _HEIGHT * -1 * (totalCharacters+2))
    scrollFrame.content.TotalName:SetText(L["Totals"])

    scrollFrame.content.TotalMoneyString = scrollFrame.content.TotalMoneyString or scrollFrame.content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    scrollFrame.content.TotalMoneyString:SetPoint("RIGHT", scrollFrame.content.TotalName, "LEFT", 495, 0)
    scrollFrame.content.TotalMoneyString:SetText(AltinatorNS:MoneyToGoldString(totalMoney))

    scrollFrame.content:SetSize(C["Width"], _HEIGHT * (totalCharacters + 2))
end