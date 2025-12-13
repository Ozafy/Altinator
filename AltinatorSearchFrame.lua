local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(C["Name"])

local AltinatorSearchFrame = {}
AltinatorNS.AltinatorSearchFrame = AltinatorSearchFrame

local function SearchResult(result)
    local frame = _G["searchResult"]
    frame.Frames = frame.Frames or {}
    local totalResults = 0
    local ICON_SIZE = 32
    local _HEIGHT = 40
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
            frame.Frames[i]:SetPoint("TOPLEFT", 5, (_HEIGHT * -1 * totalResults))
            AltinatorNS:CreateInnerBorder(frame.Frames[i], item["quality"])
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
            AltinatorNS.AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
            AltinatorNS.AltinatorTooltip:SetHyperlink(self.TooltipItemLink)
            end)
            frame.Frames[i].Frames["texture"]:SetScript("OnLeave", function(self)
            AltinatorNS.AltinatorTooltip:Hide()
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
    frame:SetSize(C["Width"]-50, _HEIGHT * (totalResults + 2))
end

local function SearchItems(searchTerm)
    Syndicator.Search.RequestSearchEverywhereResults(searchTerm, SearchResult)
end

function AltinatorSearchFrame:Initialize(self)
    local _WIDTH = C["Width"]-50
    local _HEIGHT = 20
    if Syndicator and Syndicator.API.IsReady() then
        self.Header = self.Header or self:CreateFontString("SearchTitle", "ARTWORK", "GameFontHighlight")
        self.Header:SetPoint("TOPLEFT", 5, -10)
        self.Header:SetText(L["SearchLabel"])

        self.SearchBox = self.SearchBox or CreateFrame("EditBox", nil, self, "InputBoxTemplate")
        self.SearchBox:SetSize(300, _HEIGHT)
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
        self.SearchButton:SetSize(100, _HEIGHT+2);
        self.SearchButton:SetText(L["SearchButton"]);
        self.SearchButton:SetNormalFontObject("GameFontNormal");
        self.SearchButton:SetHighlightFontObject("GameFontHighlight");
        self.SearchButton:SetScript("OnClick", function(button)
            SearchItems(self.SearchBox:GetText())
            self.SearchBox:ClearFocus()
        end)

        self.SearchResult = self.SearchResult or CreateFrame("Frame", "searchResult", self)
        self.SearchResult:SetPoint("TOPLEFT", 0, -2 * _HEIGHT)

        self:SetSize(C["Width"] - 42, C["Height"] - 50)
    else
        self.NoDataFrame = self.NoDataFrame or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.NoDataFrame:SetPoint("CENTER", 0, 0)
        self.NoDataFrame:SetText(L["Syndicator_Not_Ready"])

        self:SetSize(C["Width"]-42, C["Height"] -50)
    end
end