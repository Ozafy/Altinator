local AddonName, AltinatorNS = ...

local C = AltinatorNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local Altinatoricon = LibStub("LibDBIcon-1.0")
local AltinatorOptionsCategory, AltinatorOptionsLayout = Settings.RegisterVerticalLayoutCategory(AddonName)
local AltinatorHideCharacterCategory, AltinatorHideCharacterLayout = Settings.RegisterVerticalLayoutSubcategory(AltinatorOptionsCategory, L["OptionHideCharacter"])


local AltinatorOptions = {}
AltinatorNS.AltinatorOptions = AltinatorOptions
AltinatorNS.AltinatorOptions.Category = AltinatorOptionsCategory
AltinatorNS.AltinatorOptions.Layout = AltinatorOptionsLayout
AltinatorNS.AltinatorOptions.HideCharacterCategory = AltinatorHideCharacterCategory
AltinatorNS.AltinatorOptions.HideCharacterLayout = AltinatorHideCharacterLayout

local function OnMinimapSettingChanged(setting, value)
   if value then
      Altinatoricon:Hide(AddonName)
   else
      Altinatoricon:Show(AddonName)
   end
end

local charToDelete = ""

local function GetCharacterToDelete()
   return charToDelete
end

local function SetCharacterToDelete(value)
   charToDelete = value
end

local function GetAllCharactersSortedByRealm()
   local characterNames = {}
   for key, char in pairs(AltinatorNS.AltinatorDB.global.characters) do
         table.insert(characterNames, char.Realm .. "-" .. char.Name)
   end
   table.sort(characterNames)

   return characterNames
end

local function GetAllCharactersSortedByRealmContainer()
   local characterNames = GetAllCharactersSortedByRealm()

   local container = Settings.CreateControlTextContainer()
   container:Add("", L["OptionSelectCharacter"])
   for i, char in ipairs(characterNames) do
         container:Add(char, char)
   end
   return container:GetData()
end

local function DeleteCharacter()
   if charToDelete == "" then
      return
   else
      local realm, name = strsplit("-", charToDelete, 2)
      local char = AltinatorNS.AltinatorDB.global.characters[name .. "-" .. realm]
      if char == nil then
         print("Character '" .. name .. "' from realm '" .. realm .. "' not found in Altinator database.")
         Settings.SetValue("Altinator_Character_To_Delete", "")
         return
      end
      local cr, cg, cb, web = GetClassColor(char.Class.File)
      print("Deleting '\124c" .. web .. name .. "\124r' from realm '" .. realm .. "' from Altinator database.")
      AltinatorNS.AltinatorDB.global.characters[name .. "-" .. realm] = nil
      Settings.SetValue("Altinator_Character_To_Delete", "")
   end
end

function CreateOptionsCategory()
    local name = L["OptionsSettingsHeader"];
    local data = { name = name };
    local initializer = Settings.CreateSettingInitializer("SettingsListSectionHeaderTemplate", data);
    AltinatorOptionsLayout:AddInitializer(initializer);

	local minimapSetting = Settings.RegisterAddOnSetting(
      AltinatorOptionsCategory,
      "Altinator_Minimap_Toggle",
      "hide",
      AltinatorNS.AltinatorDB.profile.minimap,
      Settings.VarType.Boolean,
      L["OptionMinimap"],
      Settings.Default.False
   )
	minimapSetting:SetValueChangedCallback(OnMinimapSettingChanged)
	Settings.CreateCheckbox(AltinatorOptionsCategory, minimapSetting, L["OptionMinimap"])

	local tooltipSetting = Settings.RegisterAddOnSetting(
      AltinatorOptionsCategory,
      "Altinator_Tooltip_Toggle",
      "hideRecipeTooltips",
      AltinatorNS.AltinatorDB.profile.settings,
      Settings.VarType.Boolean,
      L["OptionTooltip"],
      Settings.Default.False
   )
	Settings.CreateCheckbox(AltinatorOptionsCategory, tooltipSetting, L["OptionTooltipText"])

    local name = L["OptionsDeleteHeader"];
    local data = { name = name };
    local initializer = Settings.CreateSettingInitializer("SettingsListSectionHeaderTemplate", data);
    AltinatorOptionsLayout:AddInitializer(initializer);

	local deleteCharacterSetting = Settings.RegisterProxySetting(
		AltinatorOptionsCategory,
		"Altinator_Character_To_Delete",
		Settings.VarType.String,
		L["OptionSelectCharacterToDelete"],
		"",
		GetCharacterToDelete,
		SetCharacterToDelete
	)
	Settings.CreateDropdown(AltinatorOptionsCategory, deleteCharacterSetting, GetAllCharactersSortedByRealmContainer)

	local deleteButtonInitializer = CreateSettingsButtonInitializer(
		L["OptionDeleteSelected"], -- name
		L["OptionDelete"], -- buttonText
		DeleteCharacter,
		L["OptionDeleteTooltip"],
		true,
		nil,
		nil
	)

	local addonLayout = SettingsPanel:GetLayout(AltinatorOptionsCategory)
	addonLayout:AddInitializer(deleteButtonInitializer)

   Settings.RegisterAddOnCategory(AltinatorOptionsCategory)
end

function CreateHideCharacterCategory()
   local characters = GetAllCharactersSortedByRealm();
   for i, name in ipairs(characters) do
      local realm, name = strsplit("-", name, 2)
      local char = name .. "-" .. realm
      local hideCharacterSetting = Settings.RegisterAddOnSetting(
         AltinatorHideCharacterCategory,
         "Altinator_Character_To_Hide" .. i,
         char,
         AltinatorNS.AltinatorDB.global.hiddenCharacters,
         Settings.VarType.Boolean,
         char,
         Settings.Default.False
      )
      Settings.CreateCheckbox(AltinatorHideCharacterCategory, hideCharacterSetting, L["OptionHideCharacterTooltipText"])
   end
   Settings.RegisterAddOnCategory(AltinatorHideCharacterCategory)
end

function AltinatorOptions:Initialize()
      CreateOptionsCategory()
      CreateHideCharacterCategory()
end