local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)
local AltinatorData = {}
AltinatorNS.AltinatorData = AltinatorData

local function AutoReturnMail(mailData)
   if mailData.Returned then
      return
   end
   local data = AltinatorNS.AltinatorDB.global.characters[mailData.Sender]
   if data then
      table.insert(data.Mail, {
         Sender = AltinatorNS.AltinatorAddon.CurrentCharacter.FullName,
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
local function FindInBagSlot(bags, itemId)
   for _, bag in ipairs(bags) do
      for slot=1, C_Container.GetContainerNumSlots(bag) do
         local itemID = C_Container.GetContainerItemID(bag, slot)
         if itemID == itemId then
            return true
         end
      end
   end
   return false
end
function AltinatorData:SavePlayerDataLogin()
   local name, realm = UnitFullName("player")
   local data = AltinatorNS:MergeObjects(AltinatorNS.AltinatorDB.global.characters[name .. "-" .. realm] or {}, AltinatorNS.AltinatorAddon.CurrentCharacter)
   AltinatorNS.AltinatorDB.global.characters[name .. "-" .. realm] = data
   AltinatorNS.AltinatorAddon.CurrentCharacter = data
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

   data.Containers = data.Containers or {}
   data.Containers.Bags = data.Containers.Bags or {}
   data.Containers.Bank = data.Containers.Bank or {}


   data.Attunements = data.Attunements or {}
   for i, attunement in ipairs(C["Attunements"]) do
      data.Attunements[i] = data.Attunements[i] or {}
      if not data.Attunements[i].Completed then
         if attunement.type==1 then
            local bagSlots = {
            }
            for bag=0, NUM_BAG_SLOTS do
               table.insert(bagSlots, bag)
               local containerSlots = C_Container.GetContainerNumSlots(bag)
               if containerSlots then
                  data.Containers.Bags["bag_" .. bag] = data.Containers.Bags["bag_" .. bag] or {}
                  data.Containers.Bags["bag_" .. bag].Slots = containerSlots
               end
            end
            if attunement.attunementItem then
               local hasItem = FindInBagSlot(bagSlots, attunement.attunementItem)
               if hasItem then
                  data.Attunements[i].Completed = true
               end
            end
         elseif attunement.type==2 then
            for j=1, #attunement.attunementQuests do
               if C_QuestLog.IsQuestFlaggedCompleted(attunement.attunementQuests[j]) then
                  data.Attunements[i].Completed = true
                  break
               end
            end
         elseif attunement.type==3 then
            if attunement.attunementItem then
               local bagSlots = {
                  KEYRING_CONTAINER
               }
               local hasItem = FindInBagSlot(bagSlots, attunement.attunementItem)
               if hasItem then
                  data.Attunements[i].Completed = true
               end
            end
         end
      end
   end
end
function AltinatorData:ScanBank()
   local data = AltinatorNS.AltinatorAddon.CurrentCharacter
   local bankSlots = {
      BANK_CONTAINER,
   }
   for bag=NUM_BAG_SLOTS+1, NUM_BAG_SLOTS+NUM_BANKBAGSLOTS do
      table.insert(bankSlots, bag)
      local containerSlots = C_Container.GetContainerNumSlots(bag)
      if containerSlots then
         data.Containers.Bank["bank_" .. bag] = data.Containers.Bank["bank_" .. bag] or {}
         data.Containers.Bank["bank_" .. bag].Slots = containerSlots
      end
   end
   for i, attunement in ipairs(C["Attunements"]) do
      data.Attunements[i] = data.Attunements[i] or {}
      if not data.Attunements[i].Completed then
         if attunement.type==1 then
            if attunement.attunementItem then
               local hasItem = FindInBagSlot(bankSlots, attunement.attunementItem)
               if hasItem then
                  data.Attunements[i].Completed = true
               end
            end
         end
      end
   end
end
function AltinatorData:ClearPlayerMailData()
   local data = AltinatorNS.AltinatorAddon.CurrentCharacter
   data.Mail = data.Mail or {}
   for i=#data.Mail,1,-1 do
      if data.Mail[i].ArrivalTime < time() then
         table.remove(data.Mail, i)
      end
   end
   data.Money = GetMoney() -- update money in case mail had money attached
end

function AltinatorData:SavePlayerDataLogout()
   local data = AltinatorNS.AltinatorAddon.CurrentCharacter
   data.LastLogout = time()
end


function AltinatorData:SavePlayerTimePlayed(total, level)
   local data = AltinatorNS.AltinatorAddon.CurrentCharacter
   data.TimePlayed = {}
   data.TimePlayed.Total = total
   data.TimePlayed.Level = level
end

function AltinatorData:SavePlayerMoney(total, level)
   local data = AltinatorNS.AltinatorAddon.CurrentCharacter
   data.Money = GetMoney()
end

function AltinatorData:SavePlayerXP()
   local data = AltinatorNS.AltinatorAddon.CurrentCharacter
   data.Level = UnitLevel("player")
   data.XP=data.XP or{}
   data.XP.Current=UnitXP("player")
   data.XP.Needed=UnitXPMax("player")
   data.XP.Rested=GetXPExhaustion()
end

function AltinatorData:SavePlayerResting()
   local data = AltinatorNS.AltinatorAddon.CurrentCharacter
   data.Resting = IsResting()
end

function AltinatorData:SavePlayerGuild()
   local data = AltinatorNS.AltinatorAddon.CurrentCharacter
   local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo("player")
   data.Guild= data.Guild or {}
   data.Guild.Name=guildName
   data.Guild.Rank=guildRankName
end

function AltinatorData:GetCharacterProfession(char, profId)
   return char.Professions[profId] or char.ProfessionsSecondairy[profId] or nil
end

function AltinatorData:CharacterProfessionRecipeKnownOrLearnable(profId, spellId, itemId)
   local characters = AltinatorNS:GetRealmCharactersSorted()
   local charactersThatKnow = {}
   local charactersThatCouldLearn = {}
   for i, name in ipairs(characters) do
      local char = AltinatorNS.AltinatorDB.global.characters[name]
      if char then
         local prof = self:GetCharacterProfession(char, profId)
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

function AltinatorData:ScanEnchantingRecipes()
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
         local prof = AltinatorNS.AltinatorData:GetCharacterProfession(AltinatorNS.AltinatorAddon.CurrentCharacter, profId)
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

function AltinatorData:ScanTradeSkills()
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
            local prof = AltinatorNS.AltinatorData:GetCharacterProfession(AltinatorNS.AltinatorAddon.CurrentCharacter, profId)
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

function AltinatorData:ScanCooldowns()
	local tradeskillName = GetTradeSkillLine()

   local profNames_rev = tInvert(L["ProfessionIDs"])
   local profId = 0
   if profNames_rev[tradeskillName] then
      profId=profNames_rev[tradeskillName]
      profession = AltinatorNS.AltinatorData:GetCharacterProfession(AltinatorNS.AltinatorAddon.CurrentCharacter, profId)

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
   local data = AltinatorNS.AltinatorDB.global.characters[recipientName .. "-" .. recipientRealm]
   if data then
      local attachments = HasAttachments()
      local moneySent = GetSendMailMoney()
      local arrivalTime = time()
      if moneySent>0 or attachments then
         arrivalTime = arrivalTime + (C["MailDelivery"] * 3600)
      end
      data.Mail = data.Mail or {}
      table.insert(data.Mail, {
         Sender = AltinatorNS.AltinatorAddon.CurrentCharacter.FullName,
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
   local data = AltinatorNS.AltinatorDB.global.characters[recipientName .. "-" .. recipientRealm]
   if data then
      data.Mail = data.Mail or {}
      table.insert(data.Mail, {
         Sender = AltinatorNS.AltinatorAddon.CurrentCharacter.FullName,
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

function AltinatorData:GetProfessionCooldowns(profession)
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