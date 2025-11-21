local AddonName, Addon = ...

local C = setmetatable({ }, {__index = function(t, k)
	local v = tostring(k)
	rawset(t, k, v)
	return v
end})

Addon.C = C

C["MajorDBVersion"] = 1

C["ProfessionIcons"]= {
    [129] = "spell_holy_sealofsacrifice",
    [164] = "trade_blacksmithing",
    [165] = "inv_misc_armorkit_17",
    [171] = "trade_alchemy",
    [182] = "trade_herbalism",
    [185] = "inv_misc_food_15",
    [186] = "trade_mining",
    [197] = "trade_tailoring",
    [202] = "trade_engineering",
    [333] = "trade_engraving",
    [356] = "trade_fishing",
    [393] = "inv_misc_pelt_wolf_01"
}
C["SecondairyProfession"] = { [129]=true, [185]=true, [356]=true }
C["SecondairyProfessionOrder"] = { [129]=1, [185]=2, [356]=3 }
C["Genders"] = {"unknown", "male", "female"}


C["EquipmentSlotIcons"]  = {
	"Head",
	"Neck",
	"Shoulder",
	"Shirt",
	"Chest",
	"Waist",
	"Legs",
	"Feet",
	"Wrists",
	"Hands",
	"Finger",
	"Finger",
	"Trinket",
	"Trinket",
	"Chest",
	"MainHand",
	"SecondaryHand",
	"Ranged",
	"Tabard"
}
C["MailDelivery"] = 1 -- in hours
C["MailExpiry"] = 30 -- in days
C["RestedXPBonus"] = 5/100 -- in percent
C["RestedXPTimeSpan"] = 8 -- time in hours to gain the percent bonus
C["RestedXPTimeSpanNotResting"] = 32 -- time in hours to gain the percent bonus outside resting areas

function C:GetEquipmentSlotIcon(index)
	if index and C["EquipmentSlotIcons"][index] then
		return "Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. C["EquipmentSlotIcons"][index]
	end
end

C["ResetTimes"] = {
	[1] = {
		day = 3,
		hour = 15,
	},
	[3] = {
		day = 4,
		hour = 4,
	},
}