local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(C["Name"])

function AltinatorNS:GetRealmCharactersSorted()
   local characterNames = {}
   local realm = GetNormalizedRealmName()
   for key, char in pairs(self.AltinatorDB.global.characters) do
      if char.Realm == realm then
         table.insert(characterNames, key)
      end
   end
   table.sort(characterNames)
   return characterNames
end

function AltinatorNS:GetCharacterIcons(char)
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

function AltinatorNS:MoneyToGoldString(money)
	local copper = (("%02d"):format(money % 100))
	local silver = (("%02d"):format((money / 100) % 100))
	local gold = (("%02d"):format(money / 100 / 100))
	local ccoin = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t "	
	local scoin = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t "
	local gcoin = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t "	
	return (gold..gcoin..silver..scoin..copper..ccoin)
end

function AltinatorNS:MergeObjects(mergeInto, mergeFrom)
    for k, v in pairs(mergeFrom) do
        if (type(v) == "table") and (type(mergeInto[k] or false) == "table") then
            self:MergeObjects(mergeInto[k], mergeFrom[k])
        else
            mergeInto[k] = v
        end
    end
    return mergeInto
end

function AltinatorNS:ShortTimeSpanToString(span)
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

function AltinatorNS:LongTimeSpanToString(span)
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

function AltinatorNS:GetLastReset()
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

function AltinatorNS:CreateInnerBorder(frame, itemQuality)
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

function AltinatorNS:CreateCharacterName(contentFrame, charIndex, char, anchor, OffsetX, baseOffsetY, iconSize)
   contentFrame.FactionIcons[charIndex] = contentFrame.FactionIcons[charIndex] or contentFrame:CreateTexture("Faction_Icon_" .. charIndex, "BACKGROUND")
   contentFrame.FactionIcons[charIndex]:SetSize(iconSize, iconSize)
   contentFrame.FactionIcons[charIndex]:SetPoint("TOPLEFT", anchor, "TOPLEFT", OffsetX, baseOffsetY * -1 * (charIndex-1))
   local factionIcon, raceIcon, classIcon, showRank = AltinatorNS:GetCharacterIcons(char)
   if showRank then
      contentFrame.FactionIcons[charIndex]:SetScript("OnEnter", function(self)
         AltinatorNS.AltinatorTooltip:SetOwner(contentFrame, "ANCHOR_CURSOR")
         AltinatorNS.AltinatorTooltip:SetText(char.Rank.Name)
      end)
      contentFrame.FactionIcons[charIndex]:SetScript("OnLeave", function(self)
         AltinatorNS.AltinatorTooltip:Hide()
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

function AltinatorNS:CreateScrollFrame(parent, topX, topY, bottomX, bottomY, contentFrameName)

   if not topX then topX = 0 end
   if not topY then topY = -32 end
   if not bottomX then bottomX = -22 end
   if not bottomY then bottomY = 0 end

   parent.ScrollFrame = parent.ScrollFrame or CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
   parent.ScrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", topX, topY)
   parent.ScrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", bottomX, bottomY)
   parent.ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
      AltinatorNS:ScrollFrame_OnMouseWheel(self, delta)
   end)
   parent.ScrollFrame:EnableMouse(true)

   parent.ScrollFrame.content = parent.ScrollFrame.content or CreateFrame("Frame", contentFrameName, parent.ScrollFrame)
   parent.ScrollFrame.content:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
   parent.ScrollFrame.content:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

   parent.ScrollFrame:SetScrollChild(parent.ScrollFrame.content);
   return parent.ScrollFrame
end

function AltinatorNS:ScrollFrame_OnMouseWheel(self, delta)
   local newValue = self:GetVerticalScroll() - (delta * 20)
   if (newValue < 0) then
      newValue = 0
   elseif (newValue > self:GetVerticalScrollRange()) then
      newValue = self:GetVerticalScrollRange()
   end
   self:SetVerticalScroll(newValue)
end