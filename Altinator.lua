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

local function SavePlayerDataLogin()
   local name, realm = UnitFullName("player")
   local data = AltinatorDB.global.characters[name .. "-" .. realm] or {}
   data.Name = name
   data.Realm = realm
   data.Sex = UnitSex("player")
   data.Level = UnitLevel("player")
   data.Faction = UnitFactionGroup("player")
   data.Money = GetMoney()
   data.LastLogin = time()

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

   data.Mail = data.Mail or {}
   for i=#data.Mail,1,-1 do
      if data.Mail[i].ExpiryTime < time() then
         AutoReturnMail(data.Mail)
         table.remove(data.Mail, i)
      end
   end

   AltinatorDB.global.characters[name .. "-" .. realm] = data
end

local function ClearPlayerMailData()
   local name, realm = UnitFullName("player")
   local data = AltinatorDB.global.characters[name .. "-" .. realm] or {}
   data.Mail = data.Mail or {}
   for i=#data.Mail,1,-1 do
      if data.Mail[i].ArrivalTime < time() then
         table.remove(data.Mail, i)
      end
   end
   AltinatorDB.global.characters[name .. "-" .. realm] = data
end

local function SavePlayerDataLogout()
   local name, realm = UnitFullName("player")
   local data = AltinatorDB.global.characters[name .. "-" .. realm] or {}
   local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo("player")
   data.Guild= data.Guild or {}
   data.Guild.Name=guildName
   data.Guild.Rank=guildRankName
   data.LastLogin = time()
   data.Resting = IsResting()
   data.XP=data.XP or{}
   data.XP.Current=UnitXP("player")
   data.XP.Needed=UnitXPMax("player")
   data.XP.Rested=GetXPExhaustion()
   AltinatorDB.global.characters[name .. "-" .. realm] = data
end


local function SavePlayerTimePlayed(total, level)
   local name, realm = UnitFullName("player")
   if realm then
      local data = AltinatorDB.global.characters[name .. "-" .. realm] or {}
      data.TimePlayed = {}
      data.TimePlayed.Total = total
      data.TimePlayed.Level = level
      AltinatorDB.global.characters[name .. "-" .. realm] = data
   end
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
   if AltinatorDB.global.dbversion ~= C["MajorDBVersion"] then
      AltinatorDB.global.characters = {}
      AltinatorDB.global.dbversion = C["MajorDBVersion"]
   end
   self:RegisterEvent("PLAYER_ENTERING_WORLD")
   self:RegisterEvent("PLAYER_LOGOUT")
   self:RegisterEvent("TIME_PLAYED_MSG")
   self:RegisterEvent("MAIL_CLOSED")
end

function AltinatorAddon:PLAYER_ENTERING_WORLD(self, event, isLogin, isReload)
   if isLogin or isReload then
      SavePlayerDataLogin()
      RequestTimePlayed()
   end
end

function AltinatorAddon:PLAYER_LOGOUT()
   SavePlayerDataLogout()
end

function AltinatorAddon:MAIL_CLOSED()
   ClearPlayerMailData()
end

function AltinatorAddon:TIME_PLAYED_MSG(self, total, level)
	SavePlayerTimePlayed(total, level)
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
   local name, realm = UnitFullName("player")
   local recipientName, recipientRealm = strsplit("-", recipient)
   recipientRealm = recipientRealm or GetNormalizedRealmName()
   local data = AltinatorDB.global.characters[recipientName .. "-" .. recipientRealm] or nil
   if data then
      local attachments = HasAttachments()
      local moneySent = GetSendMailMoney()
      local arrivalTime = time()
      if moneySent>0 or attachments then
         arrivalTime = arrivalTime + (C["MailDelivery"] * 3600)
      end
      data.Mail = data.Mail or {}
      table.insert(data.Mail, {
         Sender = name .. "-" .. realm,
         Subject = subject,
         Body = body or "",
         Time = time(),
         ArrivalTime = arrivalTime,
         ExpiryTime = time() + C["MailExpiry"] * 86400,
         HasAttachments = attachments,
         Money = moneySent,
         Returned = false
      })
      AltinatorDB.global.characters[recipientName .. "-" .. recipientRealm] = data
   end
end)

hooksecurefunc("ReturnInboxItem", function(index, ...)
   local name, realm = UnitFullName("player")
	local _, stationaryIcon, mailSender, mailSubject, moneySent, _, _, numAttachments = GetInboxHeaderInfo(index)
   local recipientName, recipientRealm = strsplit("-", mailSender)
   recipientRealm = recipientRealm or GetNormalizedRealmName()
   local data = AltinatorDB.global.characters[recipientName .. "-" .. recipientRealm] or nil
   if data then
      data.Mail = data.Mail or {}
      table.insert(data.Mail, {
         Sender = name .. "-" .. realm,
         Subject = subject,
         Body = body or "",
         Time = time(),
         ArrivalTime = time(),
         ExpiryTime = time() + C["MailExpiry"] * 86400,
         HasAttachments = numAttachments>0,
         Money = moneySent,
         Returned = true
      })
      AltinatorDB.global.characters[recipientName .. "-" .. recipientRealm] = data
   end
end)

local function AutoReturnMail(mailData)
   if mailData.Returned then
      return
   end
   local name, realm = UnitFullName("player")
   local data = AltinatorDB.global.characters[mailData.Sender] or nil
   if data then
      table.insert(data.Mail, {
         Sender = name .. "-" .. realm,
         Subject = mailData.Subject,
         Body = mailData.Body,
         Time = time(),
         ArrivalTime = time(),
         ExpiryTime = time() + C["MailExpiry"] * 86400,
         HasAttachments = mailData.HasAttachments,
         Money = mailData.Money,
         Returned = true
      })
      AltinatorDB.global.characters[recipientName .. "-" .. recipientRealm] = data
   end
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

local function CreateProfessionTexture(contentFrame, charIndex, anchor, baseOffset, profIndex, id, profession)
   contentFrame.ProfessionIcons = contentFrame.ProfessionIcons or {}
   contentFrame.ProfessionIcons[charIndex] = contentFrame.ProfessionIcons[charIndex] or {}
   contentFrame.ProfessionIcons[charIndex][profIndex] = contentFrame.ProfessionIcons[charIndex][profIndex] or contentFrame:CreateTexture("Profession_Icon_" .. id, "BACKGROUND")
   contentFrame.ProfessionIcons[charIndex][profIndex]:SetWidth(15)
   contentFrame.ProfessionIcons[charIndex][profIndex]:SetHeight(15)
   contentFrame.ProfessionIcons[charIndex][profIndex]:SetPoint("LEFT", anchor,"LEFT", baseOffset + (profIndex * 80), 0)
   contentFrame.ProfessionIcons[charIndex][profIndex]:SetTexture("Interface\\ICONS\\" .. profession.File)

   contentFrame.ProfessionTexts = contentFrame.ProfessionTexts or {}
   contentFrame.ProfessionTexts[charIndex] = contentFrame.ProfessionTexts[charIndex] or {}
   contentFrame.ProfessionTexts[charIndex][profIndex] = contentFrame.ProfessionTexts[charIndex][profIndex] or contentFrame:CreateFontString("Profession_Text_" .. id, "ARTWORK", "GameFontHighlight")
   contentFrame.ProfessionTexts[charIndex][profIndex]:SetPoint("LEFT", anchor, "LEFT", baseOffset + 20 + (profIndex * 80), 0)
   contentFrame.ProfessionTexts[charIndex][profIndex]:SetText(profession.Skill.."/"..profession.SkillMax)
end

local function LoadOverViewFrame(self)
   local ICON_HEIGHT = 15
   local ROW_HEIGHT = ICON_HEIGHT + 5

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
      self.FactionIcons[i] = self.FactionIcons[i] or self:CreateTexture("Faction_Icon_" .. i, "BACKGROUND")
      self.FactionIcons[i]:SetSize(ICON_HEIGHT, ICON_HEIGHT)
      self.FactionIcons[i]:SetPoint("TOPLEFT", self.NameHeader, "BOTTOMLEFT", 0, ROW_HEIGHT * -1 * (totalCharacters+1))
      local banner = "inv_bannerpvp_01"
      if(char.Faction == "Alliance") then
         banner = "inv_bannerpvp_02"
      end
      self.FactionIcons[i]:SetTexture("Interface\\ICONS\\" .. banner)

      self.RaceIcons[i] = self.RaceIcons[i] or self:CreateTexture("Race_Icon_" .. i, "BACKGROUND")
      self.RaceIcons[i]:SetSize(ICON_HEIGHT, ICON_HEIGHT)
      self.RaceIcons[i]:SetPoint("LEFT", self.FactionIcons[i], "LEFT", 15, 0)
      self.RaceIcons[i]:SetTexture("Interface\\ICONS\\Achievement_character_" .. char.Race.File .. "_" .. C["Genders"][char.Sex])

      self.ClassIcons[i] = self.ClassIcons[i] or self:CreateTexture("Class_Icon_" .. i, "BACKGROUND")
      self.ClassIcons[i]:SetSize(ICON_HEIGHT, ICON_HEIGHT)
      self.ClassIcons[i]:SetPoint("LEFT", self.RaceIcons[i], "LEFT", 15, 0)
      self.ClassIcons[i]:SetTexture("Interface\\ICONS\\classicon_" .. char.Class.File)

      self.CharNames[i] = self.CharNames[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
      self.CharNames[i]:SetPoint("LEFT", self.ClassIcons[i], "LEFT", 20, 0)
      self.CharNames[i]:SetText(char.Name)
      local cr, cg, cb, web = GetClassColor(char.Class.File)
      self.CharNames[i]:SetTextColor(cr, cg, cb)

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
         local tmpRested = char.XP.Rested
         local timeResting = (time() - (char.LastLogin) )/3600
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
         CreateProfessionTexture(self, i, self.FactionIcons[i], 585, profIndex, id, profession)
         profIndex = profIndex+1
      end
      for id, profession in pairs(char.ProfessionsSecondairy) do
         CreateProfessionTexture(self, i, self.FactionIcons[i], 585, profIndex, id, profession)
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
      local ICON_HEIGHT = 15
      local ROW_HEIGHT = ICON_HEIGHT + 5

      local currentName, currentRealm = UnitFullName("player")

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

      self.LastLoginHeader = self.LastLoginHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      self.LastLoginHeader:SetPoint("LEFT", self.PlayedHeader, "LEFT", 150, 0)
      self.LastLoginHeader:SetText(L["LastLogin"])

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
      for i, name in ipairs(characters) do
         local char = AltinatorDB.global.characters[name]
         local charSyndicator = Syndicator.API.GetByCharacterFullName(name)
         if charSyndicator then
            self.FactionIcons[i] = self.FactionIcons[i] or self:CreateTexture("Faction_Icon_" .. i, "BACKGROUND")
            self.FactionIcons[i]:SetSize(ICON_HEIGHT, ICON_HEIGHT)
            self.FactionIcons[i]:SetPoint("TOPLEFT", self.NameHeader, "BOTTOMLEFT", 0, ROW_HEIGHT * -1 * (totalCharacters+1))
            local banner = "inv_bannerpvp_01"
            if(char.Faction == "Alliance") then
               banner = "inv_bannerpvp_02"
            end
            self.FactionIcons[i]:SetTexture("Interface\\ICONS\\" .. banner)

            self.RaceIcons[i] = self.RaceIcons[i] or self:CreateTexture("Race_Icon_" .. i, "BACKGROUND")
            self.RaceIcons[i]:SetSize(ICON_HEIGHT, ICON_HEIGHT)
            self.RaceIcons[i]:SetPoint("LEFT", self.FactionIcons[i], "LEFT", 15, 0)
            self.RaceIcons[i]:SetTexture("Interface\\ICONS\\Achievement_character_" .. char.Race.File .. "_" .. C["Genders"][char.Sex])

            self.ClassIcons[i] = self.ClassIcons[i] or self:CreateTexture("Class_Icon_" .. i, "BACKGROUND")
            self.ClassIcons[i]:SetSize(ICON_HEIGHT, ICON_HEIGHT)
            self.ClassIcons[i]:SetPoint("LEFT", self.RaceIcons[i], "LEFT", 15, 0)
            self.ClassIcons[i]:SetTexture("Interface\\ICONS\\classicon_" .. char.Class.File)

            self.CharNames[i] = self.CharNames[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            self.CharNames[i]:SetPoint("LEFT", self.ClassIcons[i], "LEFT", 20, 0)
            self.CharNames[i]:SetText(char.Name)
            local cr, cg, cb, web = GetClassColor(char.Class.File)
            self.CharNames[i]:SetTextColor(cr, cg, cb)

            self.MailTexts[i] = self.MailTexts[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            self.MailTexts[i]:SetPoint("LEFT", self.FactionIcons[i], "LEFT", 165, 0)
            local charMails = 0
            char.Mail = char.Mail or {}
            for i=#char.Mail,1,-1 do
               if char.Mail[i].ArrivalTime < time() then
                  charMails = charMails + 1
               end
            end
            totalMail = totalMail + charMails
            if charMails>0 then
               self.MailTexts[i]:SetText("\124cnGREEN_FONT_COLOR:" .. charMails .. "\124r")
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

            self.LastPlayed[i] = self.LastPlayed[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            self.LastPlayed[i]:SetPoint("LEFT", self.FactionIcons[i], "LEFT", 615, 0)
            if name == currentName .. "-" .. currentRealm then
               self.LastPlayed[i]:SetText("\124cnGREEN_FONT_COLOR:" .. L["Online"] .. "\124r")
            else
               self.LastPlayed[i]:SetText(ShortTimeSpanToString(currentTime - char.LastLogin))
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

               for j, item in pairs(equipment) do
                  if item then
                     self.Frames["item" .. totalCharacters .. j] = self.Frames["item" .. totalCharacters .. j] or CreateFrame("Frame", nil, self)
                     self.Frames["item" .. totalCharacters .. j]:SetSize(ICON_SIZE, ICON_SIZE)
                     self.Frames["item" .. totalCharacters .. j]:SetPoint("LEFT", self.ClassFrames[i], "LEFT", (j*(ICON_SIZE+8))+96, 0)
                     if item["quality"] then
                        CreateInnerBorder(self.Frames["item" .. totalCharacters .. j], item["quality"])
                     end
                     self.Frames["item" .. totalCharacters .. j].Texture = self.Frames["item" .. totalCharacters .. j].Texture or self.Frames["item" .. totalCharacters .. j]:CreateTexture(nil, "BACKGROUND")
                     self.Frames["item" .. totalCharacters .. j].Texture:SetSize(ICON_SIZE, ICON_SIZE)
                     self.Frames["item" .. totalCharacters .. j].Texture:SetPoint("CENTER")
                     if item["iconTexture"] then
                        self.Frames["item" .. totalCharacters .. j].Texture:SetTexture(item["iconTexture"])
                     else
                        self.Frames["item" .. totalCharacters .. j].Texture:SetTexture(C:GetEquipmentSlotIcon(j-1))
                     end

                     if item["quality"] then
                        self.Frames["item" .. totalCharacters .. j].TooltipItemLink = item["itemLink"]
                        self.Frames["item" .. totalCharacters .. j]:SetScript("OnEnter", function(self)
                           AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
                           AltinatorTooltip:SetHyperlink(self.TooltipItemLink)
                        end)
                        self.Frames["item" .. totalCharacters .. j]:SetScript("OnLeave", function(self)
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

local function LoadOptionsViewFrame(self)
   local ROW_WIDTH = _WIDTH-50
   local ROW_HEIGHT = 20
   self.Header = self.Header or CreateFrame("Frame", nil, self)
   self.Header:SetSize(ROW_WIDTH, ROW_HEIGHT)
   self.Header:SetPoint("TOPLEFT", 0, 0)

   self.Header.Name = self.Header.Name or self.Header:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
   self.Header.Name:SetPoint("CENTER", 0, 0)
   self.Header.Name:SetText(L["Options"])

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