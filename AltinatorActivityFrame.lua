local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local AltinatorActivityFrame = {}
AltinatorNS.AltinatorActivityFrame = AltinatorActivityFrame

function AltinatorActivityFrame:Initialize(self)
    if Syndicator and Syndicator.API.IsReady() then
        local _PADDING = 5
        local _ICON_SIZE = 15
        local _HEIGHT = _ICON_SIZE + 5

        local data = AltinatorNS.AltinatorAddon.CurrentCharacter

        self.NameHeader = self.NameHeader or self:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
        self.NameHeader:SetPoint("TOPLEFT", _PADDING, -10)
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

        self.LastLogoutHeader = self.LastLogoutHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.LastLogoutHeader:SetPoint("LEFT", self.PlayedHeader, "LEFT", 150, 0)
        self.LastLogoutHeader:SetText(L["LastLogout"])

        self.HonourHeader = self.HonourHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.HonourHeader:SetPoint("LEFT", self.LastLogoutHeader, "LEFT", 150, 0)
        self.HonourHeader:SetText(L["Honour"])

        local scrollFrame = self.ScrollFrame or AltinatorNS:CreateScrollFrame(self)

        local currentTime = time()
        local totalCharacters = 0
        local totalMail = 0
        local totalAuctions = 0
        local totalAuctionItems = 0
        local totalPlayed = 0
        local characters = AltinatorNS:GetRealmCharactersSorted()
        scrollFrame.content.FactionIcons = scrollFrame.content.FactionIcons or {}
        scrollFrame.content.RaceIcons = scrollFrame.content.RaceIcons or {}
        scrollFrame.content.ClassIcons = scrollFrame.content.ClassIcons or {}
        scrollFrame.content.CharNames = scrollFrame.content.CharNames or {}
        scrollFrame.content.MailTexts = scrollFrame.content.MailTexts or {}
        scrollFrame.content.AuctionTexts = scrollFrame.content.AuctionTexts or {}
        scrollFrame.content.PlayedTexts = scrollFrame.content.PlayedTexts or {}
        scrollFrame.content.LastPlayed = scrollFrame.content.LastPlayed or {}
        scrollFrame.content.HonourTexts = scrollFrame.content.HonourTexts or {}
        for i, name in ipairs(characters) do
            local char = AltinatorDB.global.characters[name]
            local charSyndicator = Syndicator.API.GetByCharacterFullName(name)
            if charSyndicator then
            AltinatorNS:CreateCharacterName(scrollFrame.content, i, char, scrollFrame.content, _PADDING, _HEIGHT, _ICON_SIZE)

            scrollFrame.content.MailTexts[i] = scrollFrame.content.MailTexts[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            scrollFrame.content.MailTexts[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 165, 0)
            local charMails = 0
            local charMailsInTransit = {}
            char.Mail = char.Mail or {}
            for i=#char.Mail,1,-1 do
                if char.Mail[i].ArrivalTime < time() then
                    charMails = charMails + 1
                else
                    table.insert(charMailsInTransit, char.Mail[i].ArrivalTime)
                end
            end
            totalMail = totalMail + charMails + #charMailsInTransit
            if charMails>0 or #charMailsInTransit>0 then
                scrollFrame.content.MailTexts[i]:SetText("\124cnGREEN_FONT_COLOR:" .. charMails .. "\124r (\124cnYELLOW_FONT_COLOR:" .. #charMailsInTransit .. "\124r)")
                if #charMailsInTransit>0 then
                    scrollFrame.content.MailTexts[i]:SetScript("OnEnter", function(self)
                        AltinatorNS.AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
                        AltinatorNS.AltinatorTooltip:SetText(L["MailInTransit"])
                        for _, arrivalTime in ipairs(charMailsInTransit) do
                            AltinatorNS.AltinatorTooltip:AddLine(L["MailInTransit_ArrivesIn"] .. " " .. AltinatorNS:LongTimeSpanToString(arrivalTime - time()), 1, 1, 1)
                        end
                        AltinatorNS.AltinatorTooltip:Show()
                    end)
                    scrollFrame.content.MailTexts[i]:SetScript("OnLeave", function(self)
                        AltinatorNS.AltinatorTooltip:Hide()
                    end)
                end
            else
                scrollFrame.content.MailTexts[i]:SetText(charMails)
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

            scrollFrame.content.AuctionTexts[i] = scrollFrame.content.AuctionTexts[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            scrollFrame.content.AuctionTexts[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 315, 0)
            if auctionCount>0 then
                scrollFrame.content.AuctionTexts[i]:SetText("\124cnGREEN_FONT_COLOR:" .. auctionCount .. " (" .. auctionItems .. " " .. L["AuctionItems"] .. ")\124r")
            else
                scrollFrame.content.AuctionTexts[i]:SetText(auctionCount .. " (" .. auctionItems .. " " .. L["AuctionItems"] .. ")")
            end
            

            scrollFrame.content.PlayedTexts[i] = scrollFrame.content.PlayedTexts[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            scrollFrame.content.PlayedTexts[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 465, 0)
            scrollFrame.content.PlayedTexts[i]:SetText(char.TimePlayed and AltinatorNS:LongTimeSpanToString(char.TimePlayed.Total) or "")
            totalPlayed = totalPlayed + (char.TimePlayed and char.TimePlayed.Total or 0)

            local lastPlayed = (char.LastLogout or char.LastLogin)
            scrollFrame.content.LastPlayed[i] = scrollFrame.content.LastPlayed[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            scrollFrame.content.LastPlayed[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 615, 0)
            if name == data.FullName then
                scrollFrame.content.LastPlayed[i]:SetText("\124cnGREEN_FONT_COLOR:" .. L["Online"] .. "\124r")
            else
                scrollFrame.content.LastPlayed[i]:SetText(AltinatorNS:ShortTimeSpanToString(currentTime - lastPlayed))
            end

            scrollFrame.content.HonourTexts[i] = scrollFrame.content.HonourTexts[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            scrollFrame.content.HonourTexts[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 765, 0)
            char.Honour = char.Honour or { HKs = 0, Points = 0 }
            
            if AltinatorNS:GetLastReset() > lastPlayed then
                char.Honour.HKs = 0
                char.Honour.Points = 0
            end

            if char.Honour.HKs>=15 then
                scrollFrame.content.HonourTexts[i]:SetText(char.Honour.Points .. " (\124cnGREEN_FONT_COLOR:" .. char.Honour.HKs .. "\124r " .. L["Kills"] .. ")")
            else
                scrollFrame.content.HonourTexts[i]:SetText(L["HonourNotEnoughKills"] .. " (" .. char.Honour.HKs .. "/15)")
            end

            totalCharacters = totalCharacters + 1
            end
        end

        scrollFrame.content.TotalName = scrollFrame.content.TotalName or scrollFrame.content:CreateFontString("TotalsName", "ARTWORK", "GameFontHighlight")
        scrollFrame.content.TotalName:SetPoint("TOPLEFT", self.NameHeader, "BOTTOMLEFT", 0, _HEIGHT * -1 * (totalCharacters+2))
        scrollFrame.content.TotalName:SetText(L["Totals"])

        scrollFrame.content.TotalMailString = scrollFrame.content.TotalMailString or scrollFrame.content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        scrollFrame.content.TotalMailString:SetPoint("LEFT", scrollFrame.content.TotalName, "LEFT", 165, 0)
        scrollFrame.content.TotalMailString:SetText(totalMail)

        scrollFrame.content.TotalAuctionsString = scrollFrame.content.TotalAuctionsString or scrollFrame.content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        scrollFrame.content.TotalAuctionsString:SetPoint("LEFT", scrollFrame.content.TotalName, "LEFT", 315, 0)
        scrollFrame.content.TotalAuctionsString:SetText(totalAuctions .. " (" .. totalAuctionItems .. " " .. L["AuctionItems"] .. ")")

        scrollFrame.content.TotalPlayedString = scrollFrame.content.TotalPlayedString or scrollFrame.content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        scrollFrame.content.TotalPlayedString:SetPoint("LEFT", scrollFrame.content.TotalName, "LEFT", 465, 0)
        scrollFrame.content.TotalPlayedString:SetText(AltinatorNS:LongTimeSpanToString(totalPlayed))
        scrollFrame.content:SetSize(C["Width"], _HEIGHT * (totalCharacters + 2))
    else
        self.NoDataFrame = self.NoDataFrame or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.NoDataFrame:SetPoint("CENTER", 0, 0)
        self.NoDataFrame:SetText(L["Syndicator_Not_Ready"])

        self:SetSize(C["Width"]-42, C["Height"] -50)
    end
end