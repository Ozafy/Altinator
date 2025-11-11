local AddonName, Addon = ...

local _WIDTH = 1024
local _HEIGHT = 576
local _ZINDEX = 9000

local L = LibStub("AceLocale-3.0"):GetLocale("Altinator")
local C = Addon.C

local AltinatorAddon = LibStub("AceAddon-3.0"):NewAddon("Altinator", "AceEvent-3.0")
local AltinatorLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Altinator", {  
	type = "data source",  
	text = "Altinator",  
	icon = "Interface\\Icons\\inv_scroll_03",  
	OnClick = function() AltinatorAddon.ToggleFrame() end,  
}) 
local icon = LibStub("LibDBIcon-1.0")
local AltinatorDB
local AltinatorFrame
local AltinatorTooltip

local function SavePlayerData()
   local name, realm = UnitFullName("player")
   local data = {}
   data.Name = name
   data.Realm = realm
   data.Sex = UnitSex("player")
   data.Level = UnitLevel("player")
   data.Faction = UnitFactionGroup("player")
   data.Money = GetMoney()

   local className, classFilename, classId = UnitClass("player")
   data.Class={}
   data.Class.Name=className
   data.Class.File=classFilename
   data.Class.Id=classId

   local raceName, raceFile, raceID = UnitRace("player")
   data.Race={}
   data.Race.Name=raceName
   data.Race.File=raceFile
   data.Race.Id=raceID


   local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo("player")
   data.Guild={}
   data.Guild.Name=guildName
   data.Guild.Rank=guildRankName

   data.XP={}
   data.XP.Current=UnitXP("player")
   data.XP.Needed=UnitXPMax("player")
   data.XP.Rested=GetXPExhaustion()

   data.Professions={}
   data.ProfessionsSecondairy={}
   local profNames_rev = tInvert(L["ProfessionIDs"])
   for i = 1, GetNumSkillLines() do
    local name, _, _, skillRank, _, _, skillMaxRank = GetSkillLineInfo(i)
    if profNames_rev[name] then
      local profId=profNames_rev[name]
      
      if C["SecondairyProfession"][profId] then
         data.ProfessionsSecondairy[profId]={}
         data.ProfessionsSecondairy[profId].Name=name
         data.ProfessionsSecondairy[profId].File=C["ProfessionIcons"][profNames_rev[name]]
         data.ProfessionsSecondairy[profId].Skill=skillRank
         data.ProfessionsSecondairy[profId].SkillMax=skillMaxRank
      else
         data.Professions[profId]={}
         data.Professions[profId].Name=name
         data.Professions[profId].File=C["ProfessionIcons"][profNames_rev[name]]
         data.Professions[profId].Skill=skillRank
         data.Professions[profId].SkillMax=skillMaxRank
      end

    end
   end
   AltinatorDB.global.characters[name .. "-" .. realm] = data
end

function AltinatorAddon:OnInitialize()
	-- Assuming you have a ## SavedVariables: AltinatorDB line in your TOC
	AltinatorDB = LibStub("AceDB-3.0"):New("AltinatorDB", {
		profile = {
			minimap = {
				hide = false,
			},
		},
      global = {
         characters = {}
      }
	})
	icon:Register("Altinator", AltinatorLDB, AltinatorDB.profile.minimap)
   self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function AltinatorAddon:PLAYER_ENTERING_WORLD()
	SavePlayerData()
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

local function MoneyToGoldString(money)
	local copper = (("%02d"):format(money % 100))
	local silver = (("%02d"):format((money / 100) % 100))
	local gold = (("%02d"):format(money / 100 / 100))
	local ccoin = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t "	
	local scoin = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t "
	local gcoin = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t "	
	return (gold..gcoin..silver..scoin..copper..ccoin)
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
   local r, g, b, _ = C_Item.GetItemQualityColor(itemQuality)
   frame.iborder:SetBackdropBorderColor(r, g, b)
	return frame.iborder
end

local function CreateProfessionTexture(contentFrame, anchor, baseOffset, profIndex, id, profession)
   local professionTexture = contentFrame:CreateTexture("Profession_Icon_" .. id, "BACKGROUND")
   professionTexture:SetWidth(15)
   professionTexture:SetHeight(15)
   professionTexture:SetPoint("LEFT", anchor,"LEFT", baseOffset + (profIndex * 80), 0)
   professionTexture:SetTexture("Interface\\ICONS\\" .. profession.File)

   local professionText = contentFrame:CreateFontString("Profession_Text_" .. id, "ARTWORK", "GameFontHighlight")
   professionText:SetPoint("LEFT", anchor, "LEFT", baseOffset + 20 + (profIndex * 80), 0)
   professionText:SetText(profession.Skill.."/"..profession.SkillMax)
end

local function LoadOverViewFrame(self)
   local ICON_HEIGHT = 15
   local ROW_HEIGHT = ICON_HEIGHT + 5

   local nameHeader = self:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
   nameHeader:SetPoint("TOPLEFT", 5, -10)
   nameHeader:SetText(L["Characters"])

   local guildHeader = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   guildHeader:SetPoint("LEFT", nameHeader, "LEFT", 165, 0)
   guildHeader:SetText(L["Guild"])

   local moneyHeader = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   moneyHeader:SetPoint("LEFT", guildHeader, "LEFT", 200, 0)
   moneyHeader:SetText(L["Gold"])

   local levelHeader = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   levelHeader:SetPoint("LEFT", moneyHeader, "LEFT", 140, 0)
   levelHeader:SetText(L["Level"])

   local professionsHeader = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   professionsHeader:SetPoint("LEFT", levelHeader, "LEFT", 80, 0)
   professionsHeader:SetText(L["Professions"])

   local totalCharacters = 0
   local totalMoney = 0
   local characters = GetRealmCharactersSorted()
   for i, name in ipairs(characters) do
      local char = AltinatorDB.global.characters[name]
      local factionIcon = self:CreateTexture("Faction_Icon_" .. i, "BACKGROUND")
      factionIcon:SetSize(ICON_HEIGHT, ICON_HEIGHT)
      factionIcon:SetPoint("TOPLEFT", nameHeader, "BOTTOMLEFT", 0, ROW_HEIGHT * -1 * (totalCharacters+1))
      local banner = "inv_bannerpvp_01"
      if(char.Faction == "Alliance") then
         banner = "inv_bannerpvp_02"
      end
      factionIcon:SetTexture("Interface\\ICONS\\" .. banner)

      local raceIcon = self:CreateTexture("Race_Icon_" .. i, "BACKGROUND")
      raceIcon:SetSize(ICON_HEIGHT, ICON_HEIGHT)
      raceIcon:SetPoint("LEFT", factionIcon, "LEFT", 15, 0)
      raceIcon:SetTexture("Interface\\ICONS\\Achievement_character_" .. char.Race.File .. "_" .. C["Genders"][char.Sex])

      local classIcon = self:CreateTexture("Class_Icon_" .. i, "BACKGROUND")
      classIcon:SetSize(ICON_HEIGHT, ICON_HEIGHT)
      classIcon:SetPoint("LEFT", raceIcon, "LEFT", 15, 0)
      classIcon:SetTexture("Interface\\ICONS\\classicon_" .. char.Class.File)

      local charName = self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
      charName:SetPoint("LEFT", classIcon, "LEFT", 20, 0)
      charName:SetText(char.Name)
      local cr, cg, cb, web = GetClassColor(char.Class.File)
      charName:SetTextColor(cr, cg, cb)

      local guildName = self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
      guildName:SetPoint("LEFT", factionIcon, "LEFT", 165, 0)
      if char.Guild then
         guildName:SetText(char.Guild.Name)
      else
         guildName:SetText("")
      end
      

      local moneyText = self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
      moneyText:SetPoint("RIGHT", factionIcon, "LEFT", 495, 0)
      moneyText:SetText(MoneyToGoldString(char.Money))
      totalMoney = totalMoney + char.Money

      local levelText = self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
      levelText:SetPoint("LEFT", factionIcon, "LEFT", 505, 0)
      local level = char.Level
      if(level~=60) then
         level = (("%.1f (\124cnHIGHLIGHT_LIGHT_BLUE:%d%%\124r)"):format(level + (char.XP.Current/char.XP.Needed), (char.XP.Rested/char.XP.Needed * 100)))
      end
      levelText:SetText(level)

      local profIndex = 0;
      for id, profession in pairs(char.Professions) do
         CreateProfessionTexture(self, factionIcon, 585, profIndex, id, profession)
         profIndex = profIndex+1
      end
      for id, profession in pairs(char.ProfessionsSecondairy) do
         CreateProfessionTexture(self, factionIcon, 585, profIndex, id, profession)
         profIndex = profIndex+1
      end
      totalCharacters = totalCharacters + 1
   end

   local totalName = self:CreateFontString("TotalsName", "ARTWORK", "GameFontHighlight")
   totalName:SetPoint("TOPLEFT", nameHeader, "BOTTOMLEFT", 0, ROW_HEIGHT * -1 * (totalCharacters+2))
   totalName:SetText(L["Totals"])

   local totalMoneyString = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   totalMoneyString:SetPoint("RIGHT", totalName, "LEFT", 495, 0)
   totalMoneyString:SetText(MoneyToGoldString(totalMoney))

   self:SetSize(_WIDTH - 50, ROW_HEIGHT * (totalCharacters + 3))
end

local function LoadActivityViewFrame(self)
   if Syndicator and Syndicator.API.IsReady() then
      local ICON_HEIGHT = 15
      local ROW_HEIGHT = ICON_HEIGHT + 5

      local nameHeader = self:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
      nameHeader:SetPoint("TOPLEFT", 5, -10)
      nameHeader:SetText(L["Characters"])

      local mailHeader = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      mailHeader:SetPoint("LEFT", nameHeader, "LEFT", 165, 0)
      mailHeader:SetText(L["Mail"])

      local auctionsHeader = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      auctionsHeader:SetPoint("LEFT", mailHeader, "LEFT", 100, 0)
      auctionsHeader:SetText(L["Auctions"])

      local playedHeader = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      playedHeader:SetPoint("LEFT", auctionsHeader, "LEFT", 140, 0)
      playedHeader:SetText(L["Played"])

      local lastLoginHeader = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      lastLoginHeader:SetPoint("LEFT", playedHeader, "LEFT", 80, 0)
      lastLoginHeader:SetText(L["LastLogin"])

      local totalCharacters = 0
      local totalMail = 0
      local totalAuctions = 0
      local totalAuctionItems = 0
      local totalPlayed = 0
      local characters = GetRealmCharactersSorted()
      for i, name in ipairs(characters) do
         local char = AltinatorDB.global.characters[name]
         local charSyndicator = Syndicator.API.GetByCharacterFullName(name)
         if charSyndicator then
            local factionIcon = self:CreateTexture("Faction_Icon_" .. i, "BACKGROUND")
            factionIcon:SetSize(ICON_HEIGHT, ICON_HEIGHT)
            factionIcon:SetPoint("TOPLEFT", nameHeader, "BOTTOMLEFT", 0, ROW_HEIGHT * -1 * (totalCharacters+1))
            local banner = "inv_bannerpvp_01"
            if(char.Faction == "Alliance") then
               banner = "inv_bannerpvp_02"
            end
            factionIcon:SetTexture("Interface\\ICONS\\" .. banner)

            local raceIcon = self:CreateTexture("Race_Icon_" .. i, "BACKGROUND")
            raceIcon:SetSize(ICON_HEIGHT, ICON_HEIGHT)
            raceIcon:SetPoint("LEFT", factionIcon, "LEFT", 15, 0)
            raceIcon:SetTexture("Interface\\ICONS\\Achievement_character_" .. char.Race.File .. "_" .. C["Genders"][char.Sex])

            local classIcon = self:CreateTexture("Class_Icon_" .. i, "BACKGROUND")
            classIcon:SetSize(ICON_HEIGHT, ICON_HEIGHT)
            classIcon:SetPoint("LEFT", raceIcon, "LEFT", 15, 0)
            classIcon:SetTexture("Interface\\ICONS\\classicon_" .. char.Class.File)

            local charName = self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            charName:SetPoint("LEFT", classIcon, "LEFT", 20, 0)
            charName:SetText(char.Name)
            local cr, cg, cb, web = GetClassColor(char.Class.File)
            charName:SetTextColor(cr, cg, cb)

            local mailText = self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            mailText:SetPoint("LEFT", factionIcon, "LEFT", 165, 0)
            mailText:SetText("NYI")

            local auctionCount = 0
            local auctionItems = 0
            for j, auction in pairs(charSyndicator["auctions"]) do
               if auction["itemCount"]>0 then
                  auctionCount = auctionCount + 1
                  auctionItems = auctionItems + auction["itemCount"]
               end
            end
            local auctionText = self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            auctionText:SetPoint("LEFT", factionIcon, "LEFT", 265, 0)
            auctionText:SetText(auctionCount .. " (" .. auctionItems .. " " .. L["AuctionItems"] .. ")")

            totalCharacters = totalCharacters + 1
         end
      end

      local totalName = self:CreateFontString("TotalsName", "ARTWORK", "GameFontHighlight")
      totalName:SetPoint("TOPLEFT", nameHeader, "BOTTOMLEFT", 0, ROW_HEIGHT * -1 * (totalCharacters+2))
      totalName:SetText(L["Totals"])

      local totalMailString = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      totalMailString:SetPoint("LEFT", totalName, "LEFT", 165, 0)
      totalMailString:SetText(totalMail)

      local totalAuctionsString = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      totalAuctionsString:SetPoint("LEFT", totalName, "LEFT", 265, 0)
      totalAuctionsString:SetText(totalAuctions .. " (" .. totalAuctionItems .. " " .. L["AuctionItems"] .. ")")

      self:SetSize(_WIDTH - 50, ROW_HEIGHT * (totalCharacters + 3))
   else
      local noDataFrame = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      noDataFrame:SetPoint("CENTER", 0, 0)
      noDataFrame:SetText(L["Syndicator_Not_Ready"])

      self:SetSize(_WIDTH-42, _HEIGHT -50)
   end
end

local function LoadGearViewFrame(self)
   if Syndicator and Syndicator.API.IsReady() then
      local ROW_WIDTH = _WIDTH-50
      local ROW_HEIGHT = 40
      local ICON_SIZE = 32
      if not self.Frames then
         self.Frames = {}
      end
      local header = self:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
      header:SetPoint("TOPLEFT", 5, -10)
      header:SetText(L["GearTitle"])

      for s=1,19 do
         local emptyTextureFrame = self.Frames["EmptyTextureFrame" .. s] or CreateFrame("Frame", nil, self)
         self.Frames["EmptyTextureFrame" .. s] = emptyTextureFrame
         emptyTextureFrame:SetSize(ICON_SIZE, ICON_SIZE)
         emptyTextureFrame:SetPoint("LEFT", header, "LEFT", ((s+1)*(ICON_SIZE+8))+96, 0)
         CreateInnerBorder(emptyTextureFrame, 6)

         local emptyTexture = emptyTextureFrame:CreateTexture(nil, "BACKGROUND")
         emptyTexture:SetSize(ICON_SIZE, ICON_SIZE)
         emptyTexture:SetPoint("CENTER")
         emptyTexture:SetTexture(C:GetEquipmentSlotIcon(s))

         emptyTextureFrame.TooltipText = L["EquipmentSlots"][s]
         emptyTextureFrame:SetScript("OnEnter", function(self)
            AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
            AltinatorTooltip:SetText(self.TooltipText)
         end)
         emptyTextureFrame:SetScript("OnLeave", function(self)
            AltinatorTooltip:Hide()
         end)
      end

      local totalCharacters = 0
      local characters = GetRealmCharactersSorted()
      for i, name in ipairs(characters) do
            local char = AltinatorDB.global.characters[name]
            local charSyndicator = Syndicator.API.GetByCharacterFullName(name)
            if (charSyndicator) then
               local equipment = charSyndicator["equipped"]

               local classFrame = self:CreateTexture(nil, "BACKGROUND")
               classFrame:SetSize(ICON_SIZE, ICON_SIZE)
               classFrame:SetPoint("LEFT", header, "LEFT", 0, (ROW_HEIGHT * -1 * (totalCharacters+1)) - ROW_HEIGHT)
               classFrame:SetTexture("Interface\\ICONS\\classicon_" .. char.Class.File)
               
               local charName = self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
               charName:SetPoint("LEFT", classFrame, "LEFT", ICON_SIZE + 10, 0)
               charName:SetText(char.Name)
               local cr, cg, cb, web = GetClassColor(char.Class.File)
               charName:SetTextColor(cr, cg, cb)

               for j, item in pairs(equipment) do
                  if item then
                     local textureFrame = self.Frames["item" .. totalCharacters .. j] or CreateFrame("Frame", nil, self)
                     self.Frames["item" .. totalCharacters .. j] = textureFrame
                     textureFrame:SetSize(ICON_SIZE, ICON_SIZE)
                     textureFrame:SetPoint("LEFT", classFrame, "LEFT", (j*(ICON_SIZE+8))+96, 0)
                     if item["quality"] then
                        CreateInnerBorder(textureFrame, item["quality"])
                     end
                     local texture = textureFrame:CreateTexture(nil, "BACKGROUND")
                     texture:SetSize(ICON_SIZE, ICON_SIZE)
                     texture:SetPoint("CENTER")
                     if item["iconTexture"] then
                        texture:SetTexture(item["iconTexture"])
                     else
                        texture:SetTexture(C:GetEquipmentSlotIcon(j-1))
                     end

                     if item["quality"] then
                        textureFrame.TooltipItemLink = item["itemLink"]
                        textureFrame:SetScript("OnEnter", function(self)
                           AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
                           AltinatorTooltip:SetHyperlink(self.TooltipItemLink)
                        end)
                        textureFrame:SetScript("OnLeave", function(self)
                           AltinatorTooltip:Hide()
                        end)
                     end
                  end
               end

               totalCharacters = totalCharacters + 1
            end


      end
      self:SetSize(_WIDTH-42, ROW_HEIGHT * (totalCharacters + 2))
   else
      local noDataFrame = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      noDataFrame:SetPoint("CENTER", 0, 0)
      noDataFrame:SetText(L["Syndicator_Not_Ready"])

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
         local textureFrame = frame.Frames[i] or CreateFrame("Frame", nil, frame)
         frame.Frames[i] = textureFrame
         textureFrame.Frames = textureFrame.Frames or {}
         textureFrame:Show()
         textureFrame:SetSize(ICON_SIZE, ICON_SIZE)
         textureFrame:SetPoint("TOPLEFT", 5, (ROW_HEIGHT * -1 * totalResults))
         CreateInnerBorder(textureFrame, item["quality"])
         local texture = textureFrame.Frames["texture"] or textureFrame:CreateTexture(nil, "BACKGROUND")
         textureFrame.Frames["texture"] = texture
         texture:SetSize(ICON_SIZE, ICON_SIZE)
         texture:SetPoint("CENTER")
         if itemTexture then
            texture:SetTexture(itemTexture)
         else
            texture:SetTexture(136235)
         end

         textureFrame.TooltipItemLink = item["itemLink"]
         textureFrame:SetScript("OnEnter", function(self)
            AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
            AltinatorTooltip:SetHyperlink(self.TooltipItemLink)
         end)
         textureFrame:SetScript("OnLeave", function(self)
            AltinatorTooltip:Hide()
         end)

         local itemNameString = textureFrame.Frames["itemNameString"] or textureFrame:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         textureFrame.Frames["itemNameString"] = itemNameString
         itemNameString:SetPoint("LEFT", texture, "LEFT", ICON_SIZE + 10, 0)
         local r, g, b, _ = C_Item.GetItemQualityColor(item["quality"])
         itemNameString:SetText(itemName)
         itemNameString:SetTextColor(r, g, b)

         local charName = textureFrame.Frames["charName"] or textureFrame:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         textureFrame.Frames["charName"] = charName
         charName:SetPoint("LEFT", texture, "LEFT", ICON_SIZE + 300, 0)
         charName:SetText(char.Name)
         local r, g, b, _ = GetClassColor(char.Class.File)
         charName:SetTextColor(r, g, b)

         local itemLocationString = textureFrame.Frames["itemLocationString"] or textureFrame:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         textureFrame.Frames["itemLocationString"] = itemLocationString
         itemLocationString:SetPoint("LEFT", texture, "LEFT", ICON_SIZE + 450, 0)
         itemLocationString:SetText(item["source"]["container"])

         local itemLocationString = textureFrame.Frames["itemLocationString"] or textureFrame:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         textureFrame.Frames["itemLocationString"] = itemLocationString
         itemLocationString:SetPoint("LEFT", texture, "LEFT", ICON_SIZE + 550, 0)
         itemLocationString:SetText(item["itemCount"])

         totalResults = totalResults + 1
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
      local header = self:CreateFontString("SearchTitle", "ARTWORK", "GameFontHighlight")
      header:SetPoint("TOPLEFT", 5, -10)
      header:SetText(L["SearchLabel"])

      local search = self.SearchBox or CreateFrame("EditBox", nil, self, "InputBoxTemplate")
      self.SearchBox = search
      search:SetSize(300, ROW_HEIGHT)
      search:SetPoint("LEFT", header, "RIGHT", 15, 0)
      search:SetAutoFocus(false);
      search:SetMultiLine(false);
      search:SetScript("OnKeyUp", function(self, key)
         if key == "ENTER" then
            SearchItems(search:GetText())
            search:ClearFocus()
         end
      end)

      local searchButton = self.SearchButton or CreateFrame("Button", nil, self, "GameMenuButtonTemplate");
      self.SearchButton = searchButton
      searchButton:SetPoint("LEFT", search, "RIGHT", 10, 0);
      searchButton:SetSize(100, ROW_HEIGHT+2);
      searchButton:SetText(L["SearchButton"]);
      searchButton:SetNormalFontObject("GameFontNormal");
      searchButton:SetHighlightFontObject("GameFontHighlight");
      searchButton:SetScript("OnClick", function(self)
            SearchItems(search:GetText())
            search:ClearFocus()
      end)

      local searchResult = self.SearchResult or CreateFrame("Frame", "searchResult", self)
      self.SearchResult = searchResult
      searchResult:SetPoint("TOPLEFT", 0, -2 * ROW_HEIGHT)

      self:SetSize(_WIDTH - 42, _HEIGHT - 50)
   else
      local noDataFrame = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      noDataFrame:SetPoint("CENTER", 0, 0)
      noDataFrame:SetText(L["Syndicator_Not_Ready"])

      self:SetSize(_WIDTH-42, _HEIGHT -50)
   end
end

local function LoadOptionsViewFrame(self)
   local ROW_WIDTH = _WIDTH-50
   local ROW_HEIGHT = 20
   local header = CreateFrame("Frame", nil, self)
   header:SetSize(ROW_WIDTH, ROW_HEIGHT)
   header:SetPoint("TOPLEFT", 0, 0)

   header.Name = header:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
   header.Name:SetPoint("CENTER", 0, 0)
   header.Name:SetText(L["Options"])

   self:SetSize(_WIDTH-42, ROW_HEIGHT * 1)
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

function AltinatorAddon:CreateMainFrame()
   AltinatorFrame = CreateFrame("Frame", "AltinatorFrame", UIParent, "UIPanelDialogTemplate")
   AltinatorTooltip = CreateFrame("GameTooltip", "AltinatorTooltipFrame", AltinatorFrame, "GameTooltipTemplate")
   AltinatorFrame:SetSize(_WIDTH, _HEIGHT)
   AltinatorFrame:SetFrameLevel(_ZINDEX)
   AltinatorFrame:SetPoint("CENTER")
   AltinatorFrame.Title:SetFontObject("GameFontHighlight")
   AltinatorFrame.Title:SetText("Altinator")
   AltinatorFrameClose:ClearAllPoints()
   AltinatorFrameClose:SetPoint("TOPRIGHT", AltinatorFrameTitleBG, "TOPRIGHT", 10, 8)
   AltinatorFrame:EnableMouse(true)
   AltinatorFrame:SetMovable(true)
   AltinatorFrame:RegisterForDrag("LeftButton")
   AltinatorFrame:SetScript("OnDragStart", function(self)
      self:StartMoving()
   end)
   AltinatorFrame:SetScript("OnDragStop", function(self)
      self:StopMovingOrSizing()
   end)

   AltinatorFrame:SetScript("OnShow", function()
         PlaySound(808)
   end)

   AltinatorFrame:SetScript("OnHide", function()
         PlaySound(808)
   end)
   tinsert(UISpecialFrames, "AltinatorFrame");

   AltinatorFrame.ScrollFrame = CreateFrame("ScrollFrame", "AltinatorScrollFrame", AltinatorFrame, "UIPanelScrollFrameTemplate")
   AltinatorFrame.ScrollFrame:SetPoint("TOPLEFT", AltinatorFrameDialogBG, "TOPLEFT", 4, -8)
   AltinatorFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", AltinatorFrameDialogBG, "BOTTOMRIGHT", -4, 4)
   AltinatorFrame.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel)
   AltinatorFrame.ScrollFrame.ScrollBar:ClearAllPoints();
   AltinatorFrame.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", AltinatorFrame.ScrollFrame, "TOPRIGHT", -5, -16)
   AltinatorFrame.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", AltinatorFrame.ScrollFrame, "BOTTOMRIGHT", -5, 16)

   local overView, activityView, gearView, searchView, optionsView = CreateTabs(AltinatorFrame, L["Overview"], L["Activity"], L["Gear"], L["Search"], L["Options"])
   overView.LoadContent = LoadOverViewFrame
   activityView.LoadContent = LoadActivityViewFrame
   gearView.LoadContent = LoadGearViewFrame
   searchView.LoadContent = LoadSearchViewFrame
   optionsView.LoadContent = LoadOptionsViewFrame

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
      local money = char.Money
      totalmoney = totalmoney + money
      local cr, cg, cb, ca = GetClassColor(char.Class.File)
      self:AddDoubleLine(char.Name, MoneyToGoldString(char.Money), cr, cg, cb)
      self:AddTexture("Interface\\ICONS\\Achievement_character_" .. char.Race.File .. "_" .. C["Genders"][char.Sex])
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