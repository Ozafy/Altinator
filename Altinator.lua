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

local framePool = {}
local function Removeframe(f)
   f:Hide()
   tinsert(framePool, f)
end

local function Getframe()
   local f = tremove(framePool)
   if not f then
      f = CreateFrame("Frame", nil, self)
   else
      --revert any unique changes you may have made to the frame before sticking it in the framepool
   end
   return f
end

local function CreateProfessionTexture(row, baseOffset, profIndex, id, profession)
   row["Profession_"..profIndex.."_texture"] = row:CreateTexture("Profession_Icon_" .. id, "BACKGROUND")
   row["Profession_"..profIndex.."_texture"]:SetWidth(15)
   row["Profession_"..profIndex.."_texture"]:SetHeight(15)
   row["Profession_"..profIndex.."_texture"]:SetPoint("TOPLEFT", baseOffset + (profIndex * 80), -6)
   row["Profession_"..profIndex.."_texture"]:SetTexture("Interface\\ICONS\\" .. profession.File)

   row["Profession_"..profIndex.."_text"] = row:CreateFontString("Profession_Text_" .. id,"ARTWORK","GameFontHighlight")
   row["Profession_"..profIndex.."_text"]:SetPoint("LEFT", baseOffset + 20 + (profIndex * 80), -4)
   row["Profession_"..profIndex.."_text"]:SetText(profession.Skill.."/"..profession.SkillMax)

end

local function LoadOverViewFrame(self)
   local ROW_WIDTH = _WIDTH-50
   local ROW_HEIGHT = 20

   
   local header = self.Header or CreateFrame("Frame", nil, self)
   self.Header = header
   header:SetSize(ROW_WIDTH, ROW_HEIGHT)
   header:SetPoint("TOPLEFT",0, 0)

   header.Name = header:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
   header.Name:SetPoint("LEFT", 5, -6)
   header.Name:SetText(L["Characters"])

   header.Guild = header:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   header.Guild:SetPoint("LEFT", 170, -6)
   header.Guild:SetText(L["Guild"])

   header.Money = header:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   header.Money:SetPoint("LEFT", 370, -6)
   header.Money:SetText(L["Gold"])

   header.Level = header:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   header.Level:SetPoint("LEFT", 510, -6)
   header.Level:SetText(L["Level"])

   header.Professions = header:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   header.Professions:SetPoint("LEFT", 590, -6)
   header.Professions:SetText(L["Professions"])

   local totalCharacters = 0
   local totalMoney = 0
   local characters = GetRealmCharactersSorted()
   for i, name in ipairs(characters) do
         local char = AltinatorDB.global.characters[name]
         local row = CreateFrame("Frame",nil,self)
         row:SetSize(ROW_WIDTH, ROW_HEIGHT)
         row:SetPoint("TOPLEFT", 0, -(totalCharacters + 2) * ROW_HEIGHT)

         row.FactionIcon = row:CreateTexture("Faction_Icon_" .. i, "BACKGROUND")
         row.FactionIcon:SetWidth(15)
         row.FactionIcon:SetHeight(15)
         row.FactionIcon:SetPoint("TOPLEFT", 5, -6)
         local banner = "inv_bannerpvp_01"
         if(char.Faction == "Alliance") then
            banner = "inv_bannerpvp_02"
         end
         row.FactionIcon:SetTexture("Interface\\ICONS\\" .. banner)

         row.RaceIcon = row:CreateTexture("Race_Icon_" .. i, "BACKGROUND")
         row.RaceIcon:SetWidth(15)
         row.RaceIcon:SetHeight(15)
         row.RaceIcon:SetPoint("TOPLEFT", 20, -6)
         row.RaceIcon:SetTexture("Interface\\ICONS\\Achievement_character_" .. char.Race.File .. "_" .. C["Genders"][char.Sex])

         row.ClassIcon = row:CreateTexture("Class_Icon_" .. i, "BACKGROUND")
         row.ClassIcon:SetWidth(15)
         row.ClassIcon:SetHeight(15)
         row.ClassIcon:SetPoint("TOPLEFT", 35, -6)
         row.ClassIcon:SetTexture("Interface\\ICONS\\classicon_" .. char.Class.File)

         row.Name = row:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         row.Name:SetPoint("LEFT", 55, -4)
         row.Name:SetText(char.Name)
         local cr, cg, cb, web = GetClassColor(char.Class.File)
         row.Name:SetTextColor(cr, cg, cb)

         row.Name = row:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         row.Name:SetPoint("LEFT", 170, -4)
         if char.Guild then
            row.Name:SetText(char.Guild.Name)
         else
            row.Name:SetText("")
         end
         

         row.Name = row:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         row.Name:SetPoint("RIGHT", "Faction_Icon_" .. i, "LEFT", 490, 0)
         row.Name:SetText(MoneyToGoldString(char.Money))
         totalMoney = totalMoney + char.Money

         row.Name = row:CreateFontString(nil,"ARTWORK","GameFontHighlight")
         row.Name:SetPoint("LEFT", 510, -4)
         local level = char.Level
         if(level~=60) then
            level = (("%.1f (\124cnHIGHLIGHT_LIGHT_BLUE:%d%%\124r)"):format(level + (char.XP.Current/char.XP.Needed), (char.XP.Rested/char.XP.Needed * 100)))
         end
         row.Name:SetText(level)

         local profIndex = 0;
         for id, profession in pairs(char.Professions) do
            CreateProfessionTexture(row, 590, profIndex, id, profession)
            profIndex = profIndex+1
         end
         for id, profession in pairs(char.ProfessionsSecondairy) do
            CreateProfessionTexture(row, 590, profIndex, id, profession)
            profIndex = profIndex+1
         end

         row:Show()

         totalCharacters = totalCharacters + 1
   end

   local totals = self.Totals or CreateFrame("Frame", nil, self)
   self.Totals = totals
   totals:SetSize(ROW_WIDTH, ROW_HEIGHT)
   totals:SetPoint("TOPLEFT", 0, -(totalCharacters + 3) * ROW_HEIGHT)

   totals.Name = totals:CreateFontString("TotalsName", "ARTWORK", "GameFontHighlight")
   totals.Name:SetPoint("LEFT", 5, -6)
   totals.Name:SetText(L["Totals"])

   totals.Guild = totals:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   totals.Guild:SetPoint("LEFT", 170, -6)
   totals.Guild:SetText("")

   totals.Money = totals:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   totals.Money:SetPoint("RIGHT", "TotalsName", "LEFT", 490, 0)
   totals.Money:SetText(MoneyToGoldString(totalMoney))

   totals.Level = totals:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   totals.Level:SetPoint("LEFT", 510, -6)
   totals.Level:SetText("")

   totals.Professions = totals:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
   totals.Professions:SetPoint("LEFT", 590, -6)
   totals.Professions:SetText("")

   self:SetSize(_WIDTH-42, ROW_HEIGHT * (totalCharacters + 2))
end

local function CreateInnerBorder(frame, itemQuality)
   if frame.iborder then return end
   frame.iborder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
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

local function LoadGearViewFrame(self)
   if Syndicator and Syndicator.API.IsReady() then
      local ROW_WIDTH = _WIDTH-50
      local ROW_HEIGHT = 40
      local ICON_SIZE = 32

      local header = self.Header or CreateFrame("Frame", nil, self)
      self.Header = header
      header:SetSize(ROW_WIDTH, ROW_HEIGHT)
      header:SetPoint("TOPLEFT", 0, 0)

      header.Name = header:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
      header.Name:SetPoint("CENTER", 0, -6)
      header.Name:SetText(L["GearTitle"])

      local emptyIconRow = CreateFrame("Frame", nil, self)
      emptyIconRow:SetSize(ROW_WIDTH, ROW_HEIGHT)
      emptyIconRow:SetPoint("TOPLEFT", 0, -1 * ROW_HEIGHT)

      for s=1,19 do
         local emptyTextureFrame = CreateFrame("Frame", nil, emptyIconRow)
         emptyTextureFrame:SetSize(ICON_SIZE, ICON_SIZE)
         emptyTextureFrame:SetPoint("TOPLEFT", ((s+1)*(ICON_SIZE+8))+96, 0)
         CreateInnerBorder(emptyTextureFrame, 6)

         local emptyTexture = emptyTextureFrame:CreateTexture(nil, "BACKGROUND")
         emptyTexture:SetSize(ICON_SIZE, ICON_SIZE)
         emptyTexture:SetPoint("CENTER")
         emptyTexture:SetTexture(C:GetEquipmentSlotIcon(s))

         emptyTextureFrame.Tooltip = CreateFrame("GameTooltip", "emptyTextureFrame"..s, AltinatorFrame, "GameTooltipTemplate")
         emptyTextureFrame.Tooltip.Text = L["EquipmentSlots"][s]
         emptyTextureFrame:SetScript("OnEnter", function(self)
            self.Tooltip:SetOwner(self, "ANCHOR_CURSOR")
            self.Tooltip:SetText(self.Tooltip.Text)
         end)
         emptyTextureFrame:SetScript("OnLeave", function(self)
            self.Tooltip:Hide()
         end)
      end

      local totalCharacters = 0
      local characters = GetRealmCharactersSorted()
      for i, name in ipairs(characters) do
            local char = AltinatorDB.global.characters[name]
            local charSyndicator = Syndicator.API.GetByCharacterFullName(name)
            if (charSyndicator) then
               local equipment = charSyndicator["equipped"]
               local row = CreateFrame("Frame", nil, self)
               row:SetSize(ROW_WIDTH, ROW_HEIGHT)
               row:SetPoint("TOPLEFT", 0, -(totalCharacters + 2) * ROW_HEIGHT)

               local classFrame = row:CreateTexture(nil, "BACKGROUND")
               classFrame:SetSize(ICON_SIZE, ICON_SIZE)
               classFrame:SetPoint("TOPLEFT", 5, 0)
               classFrame:SetTexture("Interface\\ICONS\\classicon_" .. char.Class.File)

               row.Name = row:CreateFontString(nil,"ARTWORK","GameFontHighlight")
               row.Name:SetPoint("LEFT", 45, 0)
               row.Name:SetText(char.Name)
               local cr, cg, cb, web = GetClassColor(char.Class.File)
               row.Name:SetTextColor(cr, cg, cb)

               for j, item in pairs(equipment) do
                  if item then
                     local textureFrame = CreateFrame("Frame", nil, row)
                     textureFrame:SetSize(ICON_SIZE, ICON_SIZE)
                     textureFrame:SetPoint("TOPLEFT", (j*(ICON_SIZE+8))+96, 0)
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
                        textureFrame.Tooltip = CreateFrame("GameTooltip", "GearOverViewTooltip"..i..j, AltinatorFrame, "GameTooltipTemplate")
                        textureFrame.Tooltip.ItemLink = item["itemLink"]
                        textureFrame:SetScript("OnEnter", function(self)
                           self.Tooltip:SetOwner(self, "ANCHOR_CURSOR")
                           self.Tooltip:SetHyperlink(self.Tooltip.ItemLink)
                        end)
                        textureFrame:SetScript("OnLeave", function(self)
                           self.Tooltip:Hide()
                        end)
                     end
                  end
               end
               row:Show()
               totalCharacters = totalCharacters + 1
            end


      end
      self:SetSize(_WIDTH-42, ROW_HEIGHT * (totalCharacters + 2))
   else
      local noDataFrame = CreateFrame("Frame", nil, self)
      noDataFrame:SetSize(ROW_WIDTH, ROW_HEIGHT)
      noDataFrame:SetPoint("CENTER",0, 0)

      noDataFrame.Text = noDataFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      noDataFrame.Text:SetPoint("CENTER", 0, 0)
      noDataFrame.Text:SetText(L["Syndicator_Not_Ready"])

      self:SetSize(_WIDTH-42, ROW_HEIGHT * 1)
   end
end

local function SearchResult(result)
   local frame = _G["searchResult"]
   local totalResults = 0
   local ICON_SIZE = 32
   local ROW_HEIGHT = 40
   for i, item in pairs(result) do
      local textureFrame = CreateFrame("Frame", nil, frame)
      textureFrame:SetSize(ICON_SIZE, ICON_SIZE)
      textureFrame:SetPoint("TOPLEFT", (i*(ICON_SIZE+8))+96, 0)
      if item["quality"] then
         CreateInnerBorder(textureFrame, item["quality"])
      end
      local texture = textureFrame:CreateTexture(nil, "BACKGROUND")
      texture:SetSize(ICON_SIZE, ICON_SIZE)
      texture:SetPoint("CENTER")
      if item["iconTexture"] then
         texture:SetTexture(item["iconTexture"])
      else
         texture:SetTexture(C:GetEquipmentSlotIcon(i-1))
      end

      if item["quality"] then
         textureFrame.Tooltip = CreateFrame("GameTooltip", "SearchResultTooltip"..i, AltinatorFrame, "GameTooltipTemplate")
         textureFrame.Tooltip.ItemLink = item["itemLink"]
         textureFrame:SetScript("OnEnter", function(self)
            self.Tooltip:SetOwner(self, "ANCHOR_CURSOR")
            self.Tooltip:SetHyperlink(self.Tooltip.ItemLink)
         end)
         textureFrame:SetScript("OnLeave", function(self)
            self.Tooltip:Hide()
         end)
      end
      totalResults = totalResults + 1
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

      local header = CreateFrame("Frame", nil, self)
      header:SetSize(ROW_WIDTH, ROW_HEIGHT)
      header:SetPoint("TOPLEFT", 0, 0)

      header.Title = header:CreateFontString("SearchTitle", "ARTWORK", "GameFontHighlight")
      header.Title:SetPoint("LEFT", 5, -6)
      header.Title:SetText(L["SearchLabel"])

      local search = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
      search:SetSize(300, ROW_HEIGHT)
      search:SetPoint("LEFT", header.Title, "TOPRIGHT", 15, -6)
      search:SetAutoFocus(false);
      search:SetMultiLine(false);
      search:SetScript("OnKeyUp", function(self, key)
         if key == "ENTER" then
            SearchItems(search:GetText())
            search:ClearFocus()
         end
      end)

      local searchButton = CreateFrame("Button", nil, self, "GameMenuButtonTemplate");
      searchButton:SetPoint("LEFT", search, "RIGHT", 10, 0);
      searchButton:SetSize(100, ROW_HEIGHT+2);
      searchButton:SetText(L["SearchButton"]);
      searchButton:SetNormalFontObject("GameFontNormal");
      searchButton:SetHighlightFontObject("GameFontHighlight");
      searchButton:SetScript("OnClick", function(self)
            SearchItems(search:GetText())
            search:ClearFocus()
      end)

      local searchResult = CreateFrame("Frame", "searchResult", self)
      searchResult:SetSize(ROW_WIDTH, ROW_HEIGHT)
      searchResult:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 10, 0)

      self:SetSize(_WIDTH - 42, _HEIGHT - 50)
   else
      local noDataFrame = CreateFrame("Frame",nil,self)
      noDataFrame:SetSize(ROW_WIDTH, ROW_HEIGHT)
      noDataFrame:SetPoint("CENTER",0, 0)

      noDataFrame.Text = noDataFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      noDataFrame.Text:SetPoint("CENTER", 0, 0)
      noDataFrame.Text:SetText(L["Syndicator_Not_Ready"])

      self:SetSize(_WIDTH-42, ROW_HEIGHT * 1)
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

   AltinatorFrame:SetSize(_WIDTH, _HEIGHT)
   AltinatorFrame:SetFrameLevel(_ZINDEX)
   AltinatorFrame:SetPoint("CENTER")
   --AltinatorFrame.TitleBg:SetHeight(30)
   --AltinatorFrame.title = AltinatorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
   --AltinatorFrame.Title:ClearAllPoints()
   AltinatorFrame.Title:SetFontObject("GameFontHighlight")
   --AltinatorFrame.Title:SetPoint("LEFT", AltinatorFrameTitleBG, "LEFT", 6, 1)
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

   local overView, gearView, searchView, optionsView = CreateTabs(AltinatorFrame, L["Overview"], L["Gear"], L["Search"], L["Options"])
   overView.LoadContent = LoadOverViewFrame
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
 --[[self:AddLine("Altinator", 255, 255, 255)
 self:AddLine(" ")
 self:AddLine("Gold:")
 local totalmoney = 0
 local characterNames, characterData = GetRealmCharactersSorted()
 for _, characterName in ipairs(characterNames) do
  local money = characterData[characterName]["money"]
  totalmoney = totalmoney + money
  local gold, silver, copper = MoneyToGold(money)
  local cr, cg, cb, ca = GetClassColor(characterData[characterName]["details"]["className"])
  self:AddDoubleLine(characterName, format("%sg %02ds %02dc", gold, silver, copper), cr, cg, cb)
  local sex = "male"
  if characterData[characterName]["details"]["sex"]==3 then
   sex="female"
  end
  self:AddTexture("Interface\\ICONS\\Achievement_character_" .. characterData[characterName]["details"]["race"] .. "_" .. sex)
 end
 self:AddLine(" ")
 local totalgold, totalsilver, totalcopper = MoneyToGold(totalmoney)
 self:AddDoubleLine("Total", format("%sg %02ds %02dc", totalgold, totalsilver, totalcopper))
 self:AddTexture("Interface\\Icons\\Inv_misc_coin_02")]]--
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