local AddonName, AltinatorNS = ...

local C = AltinatorNS.C

local AltinatorLDB = LibStub("LibDataBroker-1.1"):NewDataObject(AddonName, {  
	type = "data source",  
	text = AddonName,  
	icon = "Interface\\Icons\\inv_scroll_03",  
	OnClick = function() AltinatorNS.AltinatorAddon.ToggleFrame() end,  
}) 
AltinatorNS.AltinatorLDB = AltinatorLDB

function AltinatorLDB:OnTooltipShow(tooltip)
   self:AddLine(AddonName, 255, 255, 255)
   self:AddLine(" ")
   self:AddLine("Gold:")
   local totalmoney = 0
   local characters = AltinatorNS:GetRealmCharactersSorted()
   for i, name in ipairs(characters) do
      local char = AltinatorNS.AltinatorDB.global.characters[name]
      local factionIcon, raceIcon, classIcon, showRank = AltinatorNS:GetCharacterIcons(char)
      local money = char.Money
      totalmoney = totalmoney + money
      local cr, cg, cb, ca = GetClassColor(char.Class.File)
      self:AddDoubleLine("|T"..factionIcon..":0|t" .. "|T"..raceIcon..":0|t".. "|T"..classIcon..":0|t" .. " " .. char.Name .. " (" .. char.Level .. ")", AltinatorNS:MoneyToGoldString(char.Money), cr, cg, cb)
   end
   self:AddLine(" ")
   self:AddDoubleLine("Total", AltinatorNS:MoneyToGoldString(totalmoney))
   self:AddTexture("Interface\\Icons\\Inv_misc_coin_02")
end

function AltinatorLDB:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	self.OnTooltipShow(GameTooltip)
	GameTooltip:Show()
end

function AltinatorLDB:OnLeave()
	GameTooltip:Hide()
end