local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local AltinatorOverviewFrame = {}
AltinatorNS.AltinatorOverviewFrame = AltinatorOverviewFrame

local function bagsort(a, b)
   if not a or not b then
       return false
   end
   local bagA = tonumber(AltinatorNS:SplitString(a, "_")[2])
   local bagB = tonumber(AltinatorNS:SplitString(b, "_")[2])
   return bagA < bagB
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

    self.ItemLevelHeader = self.ItemLevelHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.ItemLevelHeader:SetPoint("LEFT", self.LevelHeader, "LEFT", 85, 0)
    self.ItemLevelHeader:SetText(L["ItemLevel"])

    self.BagsHeader = self.BagsHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.BagsHeader:SetPoint("LEFT", self.ItemLevelHeader, "LEFT", 80, 0)
    self.BagsHeader:SetText(L["Bags"])

    self.BankBagsHeader = self.BankBagsHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.BankBagsHeader:SetPoint("LEFT", self.BagsHeader, "LEFT", 115, 0)
    self.BankBagsHeader:SetText(L["BankBags"])


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
            tmpRested = tmpRested + ((char.XP.Needed * (C["RestedXPBonus"] / multiplier * timeResting)))
            local RestPercent = (tmpRested/char.XP.Needed * 100)
            if RestPercent>150 then
            RestPercent = 150
            end
            level = (("%.1f \124cnHIGHLIGHT_LIGHT_BLUE:(%d%%)\124r"):format(level + (char.XP.Current/char.XP.Needed), RestPercent))
         end

         scrollFrame.content.LevelTexts[i]:SetText(level)

         scrollFrame.content.ItemLevelTexts = scrollFrame.content.ItemLevelTexts or {}
         scrollFrame.content.ItemLevelTexts[i] = scrollFrame.content.ItemLevelTexts[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         scrollFrame.content.ItemLevelTexts[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 590, 0)
         if char.ItemLevel then
            local r, g, b, hex = C_Item.GetItemQualityColor(0)
            if char.ItemLevel.Equipped >= 60 then
               if char.ItemLevel.Equipped < 100 then
                  local levelPerc = (char.ItemLevel.Equipped - 55)/25*100
                  levelPerc = levelPerc/10*5
                  r, g, b, hex = C_Item.GetItemQualityColor(math.floor(levelPerc/10))
               else
                  r, g, b, hex = C_Item.GetItemQualityColor(8)
               end
            end
            scrollFrame.content.ItemLevelTexts[i]:SetTextColor(r, g, b)
            scrollFrame.content.ItemLevelTexts[i]:SetText(("%.1f (%.1f)"):format(char.ItemLevel.Equipped or 0,char.ItemLevel.Overall or 0))
         else
            scrollFrame.content.ItemLevelTexts[i]:SetText(L["NoData"])
         end

         scrollFrame.content.BagTexts = scrollFrame.content.BagTexts or {}
         scrollFrame.content.BagTexts[i] = scrollFrame.content.BagTexts[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         scrollFrame.content.BagTexts[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 670, 0)

         scrollFrame.content.BankBagTexts = scrollFrame.content.BankBagTexts or {}
         scrollFrame.content.BankBagTexts[i] = scrollFrame.content.BankBagTexts[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         scrollFrame.content.BankBagTexts[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 785, 0)
        if char.Containers then
            
            local bags = {}
            for  key in pairs(char.Containers.Bags) do
                table.insert(bags, key)
            end
            table.sort(bags, bagsort)

            local bankBags = {}
            for  key in pairs(char.Containers.Bank) do
                table.insert(bankBags, key)
            end
            table.sort(bankBags, bagsort)

            local bagText = ""
            for i, key in ipairs(bags) do
               local bag = char.Containers.Bags[key]
               if i > 1 then
                  bagText = bagText .. "/"
               end
               bagText = bagText .. bag.Slots
            end

            scrollFrame.content.BagTexts[i]:SetText(bagText)

            local bankText = ""
            if #bankBags > 0 then
               for i, key in ipairs(bankBags) do
                  local bag = char.Containers.Bank[key]
                  if i > 1 then
                     bankText = bankText .. "/"
                  end
                  bankText = bankText .. bag.Slots
               end
            else
               bankText = L["NoData"]
            end

            scrollFrame.content.BankBagTexts[i]:SetText(bankText)
            
         else
            scrollFrame.content.BagTexts[i]:SetText(L["NoData"])
            scrollFrame.content.BankBagTexts[i]:SetText(L["NoData"])
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