local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local AltinatorGearFrame = {}
AltinatorNS.AltinatorGearFrame = AltinatorGearFrame

function AltinatorGearFrame:Initialize(self)
    if Syndicator and Syndicator.API.IsReady() then
        local _PADDING = 5
        local _WIDTH = C["Width"]-50
        local _HEIGHT = 40
        local _ICON_PADDING = 10
        local _ICON_SIZE = 32
        
        self.Header = self.Header or self:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
        self.Header:SetPoint("TOPLEFT", _PADDING, -10)
        self.Header:SetText(L["GearTitle"])

        self.Frames = self.Frames or {}
        for i=1,19 do
            self.Frames["EmptyTextureFrame" .. i] = self.Frames["EmptyTextureFrame" .. i] or CreateFrame("Frame", nil, self)
            self.Frames["EmptyTextureFrame" .. i]:SetSize(_ICON_SIZE, _ICON_SIZE)
            self.Frames["EmptyTextureFrame" .. i]:SetPoint("LEFT", self.Header, "LEFT", ((i+1)*(_ICON_SIZE+_ICON_PADDING))+96, 0)
            AltinatorNS:CreateInnerBorder(self.Frames["EmptyTextureFrame" .. i], 6)

            self.Frames["EmptyTextureFrame" .. i].EmptyTexture = self.Frames["EmptyTextureFrame" .. i].EmptyTexture or self.Frames["EmptyTextureFrame" .. i]:CreateTexture(nil, "BACKGROUND")
            self.Frames["EmptyTextureFrame" .. i].EmptyTexture:SetSize(_ICON_SIZE, _ICON_SIZE)
            self.Frames["EmptyTextureFrame" .. i].EmptyTexture:SetPoint("CENTER")
            self.Frames["EmptyTextureFrame" .. i].EmptyTexture:SetTexture(C:GetEquipmentSlotIcon(i))

            self.Frames["EmptyTextureFrame" .. i].TooltipText = L["EquipmentSlots"][i]
            self.Frames["EmptyTextureFrame" .. i]:SetScript("OnEnter", function(self)
                AltinatorNS.AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
                AltinatorNS.AltinatorTooltip:SetText(self.TooltipText)
            end)
            self.Frames["EmptyTextureFrame" .. i]:SetScript("OnLeave", function(self)
                AltinatorNS.AltinatorTooltip:Hide()
            end)
        end

        local scrollFrame = self.ScrollFrame or AltinatorNS:CreateScrollFrame(self, nil, (_ICON_SIZE * -1)-_ICON_PADDING)

        local totalCharacters = 0
        local characters = AltinatorNS:GetRealmCharactersSorted()
        scrollFrame.content.ClassFrames = scrollFrame.content.ClassFrames or {}
        scrollFrame.content.CharNames = scrollFrame.content.CharNames or {}

        for i, name in ipairs(characters) do
            local char = AltinatorDB.global.characters[name]
            local charSyndicator = Syndicator.API.GetByCharacterFullName(name)
            if (charSyndicator) then
                local equipment = charSyndicator["equipped"]

                scrollFrame.content.ClassFrames[i] = scrollFrame.content.ClassFrames[i] or scrollFrame.content:CreateTexture(nil, "BACKGROUND")
                scrollFrame.content.ClassFrames[i]:SetSize(_ICON_SIZE, _ICON_SIZE)
                scrollFrame.content.ClassFrames[i]:SetPoint("TOPLEFT", _PADDING, (_HEIGHT * -1 * (i-1)) - _HEIGHT)
                scrollFrame.content.ClassFrames[i]:SetTexture("Interface\\ICONS\\classicon_" .. char.Class.File)
                
                scrollFrame.content.CharNames[i] = scrollFrame.content.CharNames[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
                scrollFrame.content.CharNames[i]:SetPoint("LEFT", scrollFrame.content.ClassFrames[i], "LEFT", _ICON_SIZE + _ICON_PADDING, 0)
                scrollFrame.content.CharNames[i]:SetText(char.Name)
                local cr, cg, cb, web = GetClassColor(char.Class.File)
                scrollFrame.content.CharNames[i]:SetTextColor(cr, cg, cb)

                for j = 2, 20 do
                    local item = equipment[j]
                    scrollFrame.content["item" .. i .. "i" .. j] = scrollFrame.content["item" .. i .. "i" .. j] or CreateFrame("BUTTON", nil, scrollFrame.content)
                    scrollFrame.content["item" .. i .. "i" .. j]:SetSize(_ICON_SIZE, _ICON_SIZE)
                    scrollFrame.content["item" .. i .. "i" .. j]:SetPoint("LEFT", scrollFrame.content.ClassFrames[i], "LEFT", (j*(_ICON_SIZE+_ICON_PADDING))+96, 0)
                    if item["quality"] then
                        AltinatorNS:CreateInnerBorder(scrollFrame.content["item" .. i .. "i" .. j], item["quality"])
                    else
                        AltinatorNS:CreateInnerBorder(scrollFrame.content["item" .. i .. "i" .. j], -1)
                    end
                    scrollFrame.content["item" .. i .. "i" .. j].Texture = scrollFrame.content["item" .. i .. "i" .. j].Texture or scrollFrame.content["item" .. i .. "i" .. j]:CreateTexture(nil, "BACKGROUND")
                    scrollFrame.content["item" .. i .. "i" .. j].Texture:SetSize(_ICON_SIZE, _ICON_SIZE)
                    scrollFrame.content["item" .. i .. "i" .. j].Texture:SetPoint("CENTER")
                    if item["iconTexture"] then
                        scrollFrame.content["item" .. i .. "i" .. j].Texture:SetTexture(item["iconTexture"])
                    else
                        scrollFrame.content["item" .. i .. "i" .. j].Texture:SetTexture(C:GetEquipmentSlotIcon(j-1))
                    end

                    if item["quality"] then
                        scrollFrame.content["item" .. i .. "i" .. j].TooltipItemLink = item["itemLink"]
                        scrollFrame.content["item" .. i .. "i" .. j]:RegisterForClicks("AnyUp")
                        scrollFrame.content["item" .. i .. "i" .. j]:SetScript("OnClick", function(self, button, down)
                            if IsModifiedClick() and ChatFrame1EditBox and ChatFrame1EditBox:IsVisible() then
                                ChatFrame1EditBox:Insert(self.TooltipItemLink)
                            end
                        end)
                        scrollFrame.content["item" .. i .. "i" .. j]:SetScript("OnEnter", function(self)
                            AltinatorNS.AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
                            AltinatorNS.AltinatorTooltip:SetHyperlink(self.TooltipItemLink)
                        end)
                        scrollFrame.content["item" .. i .. "i" .. j]:SetScript("OnLeave", function(self)
                            AltinatorNS.AltinatorTooltip:Hide()
                        end)
                    else
                        scrollFrame.content["item" .. i .. "i" .. j]:SetScript("OnEnter", nil)
                        scrollFrame.content["item" .. i .. "i" .. j]:SetScript("OnLeave", nil)
                    end
                end

                totalCharacters = totalCharacters + 1
            end


        end
        scrollFrame.content:SetSize(C["Width"]-42, _HEIGHT * totalCharacters)
    else
        self.NoDataFrame = self.NoDataFrame or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.NoDataFrame:SetPoint("CENTER", 0, 0)
        self.NoDataFrame:SetText(L["Syndicator_Not_Ready"])

        self:SetSize(C["Width"]-42, C["Height"] -50)
    end
end