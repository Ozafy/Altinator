local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local ICON_SIZE = 32

local AltinatorSearchFrame = {}
AltinatorNS.AltinatorSearchFrame = AltinatorSearchFrame

local function Compare(item1, iterm2)
    if item1["itemName"] == iterm2["itemName"] then
        return item1["source"]["character"] < iterm2["source"]["character"]
    end
    return item1["itemName"] < iterm2["itemName"]
end


local function SearchResult(result)
    local frame = AltinatorNS.AltinatorSearchFrame
    frame.Frames = frame.Frames or {}
    local totalResults = 0

    local _HEIGHT = 40

    for i, f in pairs(frame.Frames) do
        f:Hide()
    end

    if #result>0 then
        if frame.NoResultsFrame then
            frame.NoResultsFrame:Hide()
        end
    else
        frame.NoResultsFrame = frame.NoResultsFrame or frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        frame.NoResultsFrame:SetPoint("CENTER", 0, 0)
        frame.NoResultsFrame:SetText(L["SearchNoResults"])
        frame.NoResultsFrame:Show()
        frame:SetSize(C["Width"], _HEIGHT )
        return
    end
    local itemTotals = {}
    for i, item in pairs(result) do
        itemTotals[item["itemID"]] = itemTotals[item["itemID"]] or 0
        itemTotals[item["itemID"]] = itemTotals[item["itemID"]] + item["itemCount"]
        local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(item["itemID"])
        item["itemName"] = itemName
        item["itemTexture"] = itemTexture
    end
    table.sort(result, Compare)
    for i, item in pairs(result) do
        local char = AltinatorDB.global.characters[item["source"]["character"]]
        if char and not AltinatorDB.global.hiddenCharacters[item["source"]["character"]] and char.Realm==AltinatorNS.AltinatorAddon.CurrentCharacter.Realm then
            --local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(item["itemID"])
            frame.Frames[totalResults] = frame.Frames[totalResults] or CreateFrame("BUTTON", nil, frame)
            frame.Frames[totalResults].Frames = frame.Frames[totalResults].Frames or {}
            frame.Frames[totalResults]:Show()
            frame.Frames[totalResults]:SetSize(ICON_SIZE, ICON_SIZE)
            frame.Frames[totalResults]:SetPoint("TOPLEFT", 5, (_HEIGHT * -1 * (totalResults)))
            AltinatorNS:CreateInnerBorder(frame.Frames[totalResults], item["quality"])
            frame.Frames[totalResults].Frames["texture"] = frame.Frames[totalResults].Frames["texture"] or frame.Frames[totalResults]:CreateTexture(nil, "BACKGROUND")
            frame.Frames[totalResults].Frames["texture"]:SetSize(ICON_SIZE, ICON_SIZE)
            frame.Frames[totalResults].Frames["texture"]:SetPoint("CENTER")
            if item["itemTexture"] then
                frame.Frames[totalResults].Frames["texture"]:SetTexture(item["itemTexture"])
            else
                frame.Frames[totalResults].Frames["texture"]:SetTexture(136235)
            end

            frame.Frames[totalResults].TooltipItemLink = item["itemLink"]
            frame.Frames[totalResults]:RegisterForClicks("AnyUp")
            frame.Frames[totalResults]:SetScript("OnClick", function(self, button, down)
                AltinatorNS:ItemOnClick(self)
            end)
            frame.Frames[totalResults]:SetScript("OnEnter", function(self)
                AltinatorNS:ItemOnEnter(self)
            end)
                frame.Frames[totalResults]:SetScript("OnLeave", function(self)
                AltinatorNS:ItemOnLeave(self)
            end)

            frame.Frames[totalResults].Frames["itemNameString"] = frame.Frames[totalResults].Frames["itemNameString"] or frame.Frames[totalResults]:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            frame.Frames[totalResults].Frames["itemNameString"]:SetPoint("LEFT", frame.Frames[totalResults].Frames["texture"], "LEFT", ICON_SIZE + 10, 0)
            local r, g, b, _ = C_Item.GetItemQualityColor(item["quality"])
            frame.Frames[totalResults].Frames["itemNameString"]:SetText(item["itemName"])
            frame.Frames[totalResults].Frames["itemNameString"]:SetTextColor(r, g, b)

            frame.Frames[totalResults].Frames["charName"] = frame.Frames[totalResults].Frames["charName"] or frame.Frames[totalResults]:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            frame.Frames[totalResults].Frames["charName"]:SetPoint("LEFT", frame.Frames[totalResults].Frames["texture"], "LEFT", ICON_SIZE + 300, 0)
            frame.Frames[totalResults].Frames["charName"]:SetText(char.Name)
            local r, g, b, _ = GetClassColor(char.Class.File)
            frame.Frames[totalResults].Frames["charName"]:SetTextColor(r, g, b)

            frame.Frames[totalResults].Frames["itemLocationString"] = frame.Frames[totalResults].Frames["itemLocationString"] or frame.Frames[totalResults]:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            frame.Frames[totalResults].Frames["itemLocationString"]:SetPoint("LEFT", frame.Frames[totalResults].Frames["texture"], "LEFT", ICON_SIZE + 450, 0)
            frame.Frames[totalResults].Frames["itemLocationString"]:SetText(item["source"]["container"])

            frame.Frames[totalResults].Frames["itemCountString"] = frame.Frames[totalResults].Frames["itemCountString"] or frame.Frames[totalResults]:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            frame.Frames[totalResults].Frames["itemCountString"]:SetPoint("LEFT", frame.Frames[totalResults].Frames["texture"], "LEFT", ICON_SIZE + 550, 0)
            frame.Frames[totalResults].Frames["itemCountString"]:SetText(item["itemCount"])

            frame.Frames[totalResults].Frames["itemTotalCountString"] = frame.Frames[totalResults].Frames["itemTotalCountString"] or frame.Frames[totalResults]:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            frame.Frames[totalResults].Frames["itemTotalCountString"]:SetPoint("LEFT", frame.Frames[totalResults].Frames["texture"], "LEFT", ICON_SIZE + 650, 0)
            frame.Frames[totalResults].Frames["itemTotalCountString"]:SetText(itemTotals[item["itemID"]])

            totalResults = totalResults + 1
        end
    end
    frame:SetSize(C["Width"], _HEIGHT * (totalResults))
end

local function SearchItems(searchTerm)
    searchTerm = string.lower(searchTerm)
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

        self.ItemHeader = self.ItemHeader or self:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
        self.ItemHeader:SetPoint("TOPLEFT", 5, -2 * _HEIGHT)
        self.ItemHeader:SetText(L["SearchItemName"])

        self.CharacterHeader = self.CharacterHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.CharacterHeader:SetPoint("LEFT", self.ItemHeader, "LEFT", ICON_SIZE + 300, 0)
        self.CharacterHeader:SetText(L["SearchItemCharacter"])
        
        self.LocationHeader = self.LocationHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.LocationHeader:SetPoint("LEFT", self.ItemHeader, "LEFT", ICON_SIZE + 450, 0)
        self.LocationHeader:SetText(L["SearchItemLocation"])

        self.TotalInStackHeader = self.TotalInStackHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.TotalInStackHeader:SetPoint("LEFT", self.ItemHeader, "LEFT", ICON_SIZE + 550, 0)
        self.TotalInStackHeader:SetText(L["SearchItemTotalInStack"])

        self.TotalOwnedHeader = self.TotalOwnedHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.TotalOwnedHeader:SetPoint("LEFT", self.ItemHeader, "LEFT", ICON_SIZE + 650, 0)
        self.TotalOwnedHeader:SetText(L["SearchItemTotalOwned"])

        local scrollFrame = self.ScrollFrame or AltinatorNS:CreateScrollFrame(self, nil, _HEIGHT * -3, nil, nil)
        AltinatorNS.AltinatorSearchFrame = scrollFrame.content

        self:SetSize(C["Width"] - 42, C["Height"] - 50)
    else
        self.NoDataFrame = self.NoDataFrame or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.NoDataFrame:SetPoint("CENTER", 0, 0)
        self.NoDataFrame:SetText(L["Syndicator_Not_Ready"])

        self:SetSize(C["Width"] - 42, C["Height"] - 50)
    end
end