local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(C["Name"])

local AltinatorActivityFrame = {}
AltinatorNS.AltinatorActivityFrame = AltinatorActivityFrame

function AltinatorActivityFrame:Initialize(self)
    if Syndicator and Syndicator.API.IsReady() then
        local ICON_SIZE = 15
        local _HEIGHT = ICON_SIZE + 5

        local data = AltinatorNS.AltinatorAddon.CurrentCharacter

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

        self.LastLogoutHeader = self.LastLogoutHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.LastLogoutHeader:SetPoint("LEFT", self.PlayedHeader, "LEFT", 150, 0)
        self.LastLogoutHeader:SetText(L["LastLogout"])

        self.HonourHeader = self.HonourHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.HonourHeader:SetPoint("LEFT", self.LastLogoutHeader, "LEFT", 150, 0)
        self.HonourHeader:SetText(L["Honour"])

        local currentTime = time()
        local totalCharacters = 0
        local totalMail = 0
        local totalAuctions = 0
        local totalAuctionItems = 0
        local totalPlayed = 0
        local characters = AltinatorNS:GetRealmCharactersSorted()
        self.FactionIcons = self.FactionIcons or {}
        self.RaceIcons = self.RaceIcons or {}
        self.ClassIcons = self.ClassIcons or {}
        self.CharNames = self.CharNames or {}
        self.MailTexts = self.MailTexts or {}
        self.AuctionTexts = self.AuctionTexts or {}
        self.PlayedTexts = self.PlayedTexts or {}
        self.LastPlayed = self.LastPlayed or {}
        self.HonourTexts = self.HonourTexts or {}
        for i, name in ipairs(characters) do
            local char = AltinatorDB.global.characters[name]
            local charSyndicator = Syndicator.API.GetByCharacterFullName(name)
            if charSyndicator then
            AltinatorNS:CreateCharacterName(self, i, char, self.NameHeader, _HEIGHT, ICON_SIZE)

            self.MailTexts[i] = self.MailTexts[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            self.MailTexts[i]:SetPoint("LEFT", self.FactionIcons[i], "LEFT", 165, 0)
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
                self.MailTexts[i]:SetText("\124cnGREEN_FONT_COLOR:" .. charMails .. "\124r (\124cnYELLOW_FONT_COLOR:" .. #charMailsInTransit .. "\124r)")
                if #charMailsInTransit>0 then
                    self.MailTexts[i]:SetScript("OnEnter", function(self)
                        AltinatorNS.AltinatorTooltip:SetOwner(self, "ANCHOR_CURSOR")
                        AltinatorNS.AltinatorTooltip:SetText(L["MailInTransit"])
                        for _, arrivalTime in ipairs(charMailsInTransit) do
                            AltinatorNS.AltinatorTooltip:AddLine(L["MailInTransit_ArrivesIn"] .. " " .. AltinatorNS:ShortTimeSpanToString(arrivalTime - time()), 1, 1, 1)
                        end
                        AltinatorNS.AltinatorTooltip:Show()
                    end)
                    self.MailTexts[i]:SetScript("OnLeave", function(self)
                        AltinatorNS.AltinatorTooltip:Hide()
                    end)
                end
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
            self.PlayedTexts[i]:SetText(char.TimePlayed and AltinatorNS:LongTimeSpanToString(char.TimePlayed.Total) or "")
            totalPlayed = totalPlayed + (char.TimePlayed and char.TimePlayed.Total or 0)

            local lastPlayed = (char.LastLogout or char.LastLogin)
            self.LastPlayed[i] = self.LastPlayed[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            self.LastPlayed[i]:SetPoint("LEFT", self.FactionIcons[i], "LEFT", 615, 0)
            if name == data.FullName then
                self.LastPlayed[i]:SetText("\124cnGREEN_FONT_COLOR:" .. L["Online"] .. "\124r")
            else
                self.LastPlayed[i]:SetText(AltinatorNS:ShortTimeSpanToString(currentTime - lastPlayed))
            end

            self.HonourTexts[i] = self.HonourTexts[i] or self:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            self.HonourTexts[i]:SetPoint("LEFT", self.FactionIcons[i], "LEFT", 765, 0)
            char.Honour = char.Honour or { HKs = 0, Points = 0 }
            
            if AltinatorNS:GetLastReset() > lastPlayed then
                char.Honour.HKs = 0
                char.Honour.Points = 0
            end

            if char.Honour.HKs>=15 then
                self.HonourTexts[i]:SetText(char.Honour.Points .. " (\124cnGREEN_FONT_COLOR:" .. char.Honour.HKs .. "\124r " .. L["Kills"] .. ")")
            else
                self.HonourTexts[i]:SetText(L["HonourNotEnoughKills"] .. " (" .. char.Honour.HKs .. "/15)")
            end

            totalCharacters = totalCharacters + 1
            end
        end

        self.TotalName = self.TotalName or self:CreateFontString("TotalsName", "ARTWORK", "GameFontHighlight")
        self.TotalName:SetPoint("TOPLEFT", self.NameHeader, "BOTTOMLEFT", 0, _HEIGHT * -1 * (totalCharacters+2))
        self.TotalName:SetText(L["Totals"])

        self.TotalMailString = self.TotalMailString or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.TotalMailString:SetPoint("LEFT", self.TotalName, "LEFT", 165, 0)
        self.TotalMailString:SetText(totalMail)

        self.TotalAuctionsString = self.TotalAuctionsString or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.TotalAuctionsString:SetPoint("LEFT", self.TotalName, "LEFT", 315, 0)
        self.TotalAuctionsString:SetText(totalAuctions .. " (" .. totalAuctionItems .. " " .. L["AuctionItems"] .. ")")

        self.TotalPlayedString = self.TotalPlayedString or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.TotalPlayedString:SetPoint("LEFT", self.TotalName, "LEFT", 465, 0)
        self.TotalPlayedString:SetText(AltinatorNS:LongTimeSpanToString(totalPlayed))

        self:SetSize(C["Width"] - 50, _HEIGHT * (totalCharacters + 3))
    else
        self.NoDataFrame = self.NoDataFrame or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.NoDataFrame:SetPoint("CENTER", 0, 0)
        self.NoDataFrame:SetText(L["Syndicator_Not_Ready"])

        self:SetSize(C["Width"]-42, C["Height"] -50)
    end
end