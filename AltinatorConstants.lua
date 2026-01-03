local AddonName, AltinatorNS = ...

local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local C = setmetatable({ }, {__index = function(t, k)
	local v = tostring(k)
	rawset(t, k, v)
	return v
end})

AltinatorNS.C = C


C["MajorDBVersion"] = 1
C["Width"] = 1024
C["Height"] = 576
C["ProfessionBrackets"] = {
	[1] = {
		name = "Apprentice",
		maxSkill = 75,
		minLevel = 1
	},
	[2] = {
		name = "Journeyman",
		maxSkill = 150,
		minLevel = 10
	},
	[3] = {
		name = "Expert",
		maxSkill = 225,
		minLevel = 20
	},
	[4] = {
		name = "Artisan",
		maxSkill = 300,
		minLevel = 35
	}
}
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
C["RecipeClassId"] = 9
C["ProfessionSubclassIdToProfessionId"]= {
    [7] = 129,
    [4] = 164,
    [1] = 165,
    [6] = 171,
    [5] = 185,
    [2] = 197,
    [3] = 202,
    [8] = 333,
    [9] = 356
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
C["Attunements"] = {
	[1] = {
		name = "Scarlet Monestary",
		type = 3,
		attunementItem = 7146,
		iconTexture = "Interface\\Icons\\inv_misc_key_01"
	},
	[2] = {
		name = "Gnomeregan",
		type = 3,
		attunementItem = 6893,
		iconTexture = "Interface\\Icons\\inv_misc_key_06"
	},
	[3] = {
		name = "Zul'Farrak",
		type = 1,
		attunementItem = 9240,
		iconTexture = "Interface\\Icons\\inv_hammer_19"
	},
	[4] = {
		name = "Temple of Atal'Hakkar",
		type = 1,
		attunementItem = 10818,
		iconTexture = "Interface\\Icons\\inv_scroll_02"
	},
	[5] = {
		name = "Maraudon",
		type = 1,
		attunementItem = 17191,
		iconTexture = "Interface\\Icons\\inv_staff_16"
	},
	[6] = {
		name = "Blackrock Depths",
		type = 3,
		attunementItem = 11000,
		iconTexture = "Interface\\Icons\\inv_misc_key_08"
	},
	[7] = {
		name = "Dire Maul",
		type = 3,
		attunementItem = 18249,
		iconTexture = "Interface\\Icons\\inv_misc_key_10"
	},
	[8] = {
		name = "Scholomance",
		type = 3,
		attunementItem = 13704,
		iconTexture = "Interface\\Icons\\inv_misc_key_11"
	},
	[9] = {
		name = "Stratholme",
		type = 3,
		attunementItem = 12382,
		iconTexture = "Interface\\Icons\\inv_misc_key_13"
	},
	[10] = {
		name = "Upper Blackrock Spire",
		type = 1,
		attunementItem = 12344,
		iconTexture = "Interface\\Icons\\inv_jewelry_ring_01"
	},
	[11] = {
		name = "Onyxia's Lair",
		type = 1,
		attunementItem = 16309,
		iconTexture = "Interface\\Icons\\inv_jewelry_talisman_11"
	},
	[12] = {
		name = "Molten Core",
		type = 2,
		attunementQuests = {7848},
		iconTexture = "Interface\\Icons\\inv_hammer_unique_sulfuras"
	},
	[13] = {
		name = "Blackwing Lair",
		type = 2,
		attunementQuests = {7761},
		iconTexture = "Interface\\Icons\\inv_misc_head_dragon_black"
	},
	[14] = {
		name = "Naxxramas",
		type = 2,
		attunementQuests = {9121,9122,9123},
		iconTexture = "Interface\\Icons\\spell_holy_senseundead"
	},
}