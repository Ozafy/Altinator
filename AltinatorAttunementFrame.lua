local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local AltinatorAttunementFrame = {}
AltinatorNS.AltinatorAttunementFrame = AltinatorAttunementFrame

function AltinatorAttunementFrame:Initialize(self)
    local _PADDING = 5
    local _WIDTH = C["Width"]-50
    local _HEIGHT = 40
    local _ICON_PADDING = 10
    local _ICON_SIZE = 32
    
    self.Header = self.Header or self:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
    self.Header:SetPoint("TOPLEFT", _PADDING, -10)
    self.Header:SetText(L["AttunementTitle"])

    self.Frames = self.Frames or {}
    for s, attunement in ipairs(C["Attunements"]) do
        self.Frames["EmptyTextureFrame" .. s] = self.Frames["EmptyTextureFrame" .. s] or CreateFrame("Frame", nil, self)
        self.Frames["EmptyTextureFrame" .. s]:SetSize(_ICON_SIZE, _ICON_SIZE)
        self.Frames["EmptyTextureFrame" .. s]:SetPoint("LEFT", self.Header, "LEFT", ((s+1)*(_ICON_SIZE+_ICON_PADDING))+96, 0)
        AltinatorNS:CreateInnerBorder(self.Frames["EmptyTextureFrame" .. s], 6)

        self.Frames["EmptyTextureFrame" .. s].EmptyTexture = self.Frames["EmptyTextureFrame" .. s].EmptyTexture or self.Frames["EmptyTextureFrame" .. s]:CreateTexture(nil, "BACKGROUND")
        self.Frames["EmptyTextureFrame" .. s].EmptyTexture:SetSize(_ICON_SIZE, _ICON_SIZE)
        self.Frames["EmptyTextureFrame" .. s].EmptyTexture:SetPoint("CENTER")
        self.Frames["EmptyTextureFrame" .. s].EmptyTexture:SetTexture(attunement.iconTexture)

        self.Frames["EmptyTextureFrame" .. s].TooltipText = L["AttunementDungeons"][s]
        self.Frames["EmptyTextureFrame" .. s]:SetScript("OnEnter", function(self)
            AltinatorNS.AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
            AltinatorNS.AltinatorTooltip:SetText(self.TooltipText)
        end)
        self.Frames["EmptyTextureFrame" .. s]:SetScript("OnLeave", function(self)
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
            scrollFrame.content.ClassFrames[i]:SetPoint("TOPLEFT", _PADDING, (_HEIGHT * -1 * (totalCharacters-1)) - _HEIGHT)
            scrollFrame.content.ClassFrames[i]:SetTexture("Interface\\ICONS\\classicon_" .. char.Class.File)
            
            scrollFrame.content.CharNames[i] = scrollFrame.content.CharNames[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            scrollFrame.content.CharNames[i]:SetPoint("LEFT", scrollFrame.content.ClassFrames[i], "LEFT", _ICON_SIZE + _ICON_PADDING, 0)
            scrollFrame.content.CharNames[i]:SetText(char.Name)
            local cr, cg, cb, web = GetClassColor(char.Class.File)
            scrollFrame.content.CharNames[i]:SetTextColor(cr, cg, cb)

            for j, attunement in ipairs(C["Attunements"]) do
                local item = equipment[j]
                scrollFrame.content["item" .. totalCharacters .. "i" .. j] = scrollFrame.content["item" .. totalCharacters .. "i" .. j] or CreateFrame("Frame", nil, scrollFrame.content)
                scrollFrame.content["item" .. totalCharacters .. "i" .. j]:SetSize(_ICON_SIZE, _ICON_SIZE)
                scrollFrame.content["item" .. totalCharacters .. "i" .. j]:SetPoint("LEFT", scrollFrame.content.ClassFrames[i], "LEFT", ((j+1)*(_ICON_SIZE+_ICON_PADDING))+96, 0)

                scrollFrame.content["item" .. totalCharacters .. "i" .. j].Texture = scrollFrame.content["item" .. totalCharacters .. "i" .. j].Texture or scrollFrame.content["item" .. totalCharacters .. "i" .. j]:CreateTexture(nil, "BACKGROUND")
                scrollFrame.content["item" .. totalCharacters .. "i" .. j].Texture:SetSize(_ICON_SIZE, _ICON_SIZE)
                scrollFrame.content["item" .. totalCharacters .. "i" .. j].Texture:SetPoint("CENTER")
                scrollFrame.content["item" .. totalCharacters .. "i" .. j].Texture:SetTexture(attunement.iconTexture)

                if char.Attunements and char.Attunements[j] and char.Attunements[j].Completed then
                    AltinatorNS:CreateInnerBorder(scrollFrame.content["item" .. totalCharacters .. "i" .. j], 2)
                else
                    AltinatorNS:CreateInnerBorder(scrollFrame.content["item" .. totalCharacters .. "i" .. j], -1)
                    scrollFrame.content["item" .. totalCharacters .. "i" .. j].Texture:SetAlpha(0.5)
                end
            end

            totalCharacters = totalCharacters + 1
        end


    end
    scrollFrame.content:SetSize(C["Width"]-42, _HEIGHT * totalCharacters)
end