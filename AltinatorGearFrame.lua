local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(C["Name"])

local AltinatorGearFrame = {}
AltinatorNS.AltinatorGearFrame = AltinatorGearFrame

function AltinatorGearFrame:Initialize(self)
    if Syndicator and Syndicator.API.IsReady() then
        local _WIDTH = C["Width"]-50
        local _HEIGHT = 40
        local ICON_SIZE = 32
        
        self.Header = self.Header or self:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
        self.Header:SetPoint("TOPLEFT", 5, -10)
        self.Header:SetText(L["GearTitle"])

        self.Frames = self.Frames or {}
        for s=1,19 do
            self.Frames["EmptyTextureFrame" .. s] = self.Frames["EmptyTextureFrame" .. s] or CreateFrame("Frame", nil, self)
            self.Frames["EmptyTextureFrame" .. s]:SetSize(ICON_SIZE, ICON_SIZE)
            self.Frames["EmptyTextureFrame" .. s]:SetPoint("LEFT", self.Header, "LEFT", ((s+1)*(ICON_SIZE+8))+96, 0)
            AltinatorNS:CreateInnerBorder(self.Frames["EmptyTextureFrame" .. s], 6)

            self.Frames["EmptyTextureFrame" .. s].EmptyTexture = self.Frames["EmptyTextureFrame" .. s].EmptyTexture or self.Frames["EmptyTextureFrame" .. s]:CreateTexture(nil, "BACKGROUND")
            self.Frames["EmptyTextureFrame" .. s].EmptyTexture:SetSize(ICON_SIZE, ICON_SIZE)
            self.Frames["EmptyTextureFrame" .. s].EmptyTexture:SetPoint("CENTER")
            self.Frames["EmptyTextureFrame" .. s].EmptyTexture:SetTexture(C:GetEquipmentSlotIcon(s))

            self.Frames["EmptyTextureFrame" .. s].TooltipText = L["EquipmentSlots"][s]
            self.Frames["EmptyTextureFrame" .. s]:SetScript("OnEnter", function(self)
            AltinatorNS.AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
            AltinatorNS.AltinatorTooltip:SetText(self.TooltipText)
            end)
            self.Frames["EmptyTextureFrame" .. s]:SetScript("OnLeave", function(self)
            AltinatorNS.AltinatorTooltip:Hide()
            end)
        end

        local totalCharacters = 0
        local characters = AltinatorNS:GetRealmCharactersSorted()
        self.ClassFrames = self.ClassFrames or {}
        self.CharNames = self.CharNames or {}
        for i, name in ipairs(characters) do
            local char = AltinatorDB.global.characters[name]
            local charSyndicator = Syndicator.API.GetByCharacterFullName(name)
            if (charSyndicator) then
                local equipment = charSyndicator["equipped"]

                self.ClassFrames[i]= self.ClassFrames[i] or self:CreateTexture(nil, "BACKGROUND")
                self.ClassFrames[i]:SetSize(ICON_SIZE, ICON_SIZE)
                self.ClassFrames[i]:SetPoint("LEFT", self.Header, "LEFT", 0, (_HEIGHT * -1 * (totalCharacters+1)) - _HEIGHT)
                self.ClassFrames[i]:SetTexture("Interface\\ICONS\\classicon_" .. char.Class.File)
                
                self.CharNames[i] = self.CharNames[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
                self.CharNames[i]:SetPoint("LEFT", self.ClassFrames[i], "LEFT", ICON_SIZE + 10, 0)
                self.CharNames[i]:SetText(char.Name)
                local cr, cg, cb, web = GetClassColor(char.Class.File)
                self.CharNames[i]:SetTextColor(cr, cg, cb)

                for j = 2, 20 do
                    local item = equipment[j]
                    self.Frames["item" .. totalCharacters .. "i" .. j] = self.Frames["item" .. totalCharacters .. "i" .. j] or CreateFrame("Frame", nil, self)
                    self.Frames["item" .. totalCharacters .. "i" .. j]:SetSize(ICON_SIZE, ICON_SIZE)
                    self.Frames["item" .. totalCharacters .. "i" .. j]:SetPoint("LEFT", self.ClassFrames[i], "LEFT", (j*(ICON_SIZE+8))+96, 0)
                    if item["quality"] then
                        AltinatorNS:CreateInnerBorder(self.Frames["item" .. totalCharacters .. "i" .. j], item["quality"])
                    else
                        AltinatorNS:CreateInnerBorder(self.Frames["item" .. totalCharacters .. "i" .. j], -1)
                    end
                    self.Frames["item" .. totalCharacters .. "i" .. j].Texture = self.Frames["item" .. totalCharacters .. "i" .. j].Texture or self.Frames["item" .. totalCharacters .. "i" .. j]:CreateTexture(nil, "BACKGROUND")
                    self.Frames["item" .. totalCharacters .. "i" .. j].Texture:SetSize(ICON_SIZE, ICON_SIZE)
                    self.Frames["item" .. totalCharacters .. "i" .. j].Texture:SetPoint("CENTER")
                    if item["iconTexture"] then
                        self.Frames["item" .. totalCharacters .. "i" .. j].Texture:SetTexture(item["iconTexture"])
                    else
                        self.Frames["item" .. totalCharacters .. "i" .. j].Texture:SetTexture(C:GetEquipmentSlotIcon(j-1))
                    end

                    if item["quality"] then
                        self.Frames["item" .. totalCharacters .. "i" .. j].TooltipItemLink = item["itemLink"]
                        self.Frames["item" .. totalCharacters .. "i" .. j]:SetScript("OnEnter", function(self)
                        AltinatorNS.AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
                        AltinatorNS.AltinatorTooltip:SetHyperlink(self.TooltipItemLink)
                        end)
                        self.Frames["item" .. totalCharacters .. "i" .. j]:SetScript("OnLeave", function(self)
                        AltinatorNS.AltinatorTooltip:Hide()
                        end)
                    else
                        self.Frames["item" .. totalCharacters .. "i" .. j]:SetScript("OnEnter", nil)
                        self.Frames["item" .. totalCharacters .. "i" .. j]:SetScript("OnLeave", nil)
                    end
                end

                totalCharacters = totalCharacters + 1
            end


        end
        self:SetSize(C["Width"]-42, _HEIGHT * (totalCharacters + 2))
    else
        self.NoDataFrame = self.NoDataFrame or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.NoDataFrame:SetPoint("CENTER", 0, 0)
        self.NoDataFrame:SetText(L["Syndicator_Not_Ready"])

        self:SetSize(C["Width"]-42, C["Height"] -50)
    end
end