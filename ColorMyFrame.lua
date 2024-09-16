-- KNOWN BUGS:
--   preview frame in settings is not live updating
--      (workaround: reload ui)
--   fix "Defaults" button in addon settings
--      (workaround: delete \World of Warcraft\_retail_\WTF\Account\<account name>\SavedVariables\ColorMyFrame.lua)
--
-- TO DO:
--   maybe raid preview frame will update if you change the event here:
--     CompactUnitFrame_SetUpdateAllEvent(self.RaidFrame, "GROUP_ROSTER_UPDATE");
--   addSearchTags?
--   check if my use of UnitIsEnemy(unit, "player") correctly detects arena frames
--   onSettingsChanged, RegisterAddonSetting
--   maybe disable the secure hook if both color options are unchecked?
--   align color texture previews with buttons
--   maybe register all settings with Settings.RegisterAddOnSetting() ?

local thisAddonName, ns = ...
local thisAddonTitle = "Color My Frame"

local alternateAddonName = thisAddonTitle --"NEW Color My Frame"
--print(thisAddonName, ns.foo)

local oldDefaults = {
    someOption = true,
    r = 255/255, g = 200/255, b = 0/255, -- yellow-orange
}

local defaults = {
    recolorOthers = false,
    player = {r = 255/255, g = 200/255, b = 0/255}, -- yellow-orange
    others = {r = 0/255, g = 255/255, b = 0/255}, -- green
}

local function myPrintTable(yourTable, recurseLevel, maxRecurseLevel)
    if type(yourTable) == "table" then
        recurseLevel = recurseLevel or 0
        maxRecurseLevel = maxRecurseLevel or 0
        indentString = string.rep("  ", recurseLevel)    
        for key, value in pairs(yourTable) do
            if type(value) == "table" then
                print(indentString, key.." is table:")
                if (maxRecurseLevel == 0 or recurseLevel < maxRecurseLevel) then
                    myPrintTable(value, recurseLevel + 1, maxRecurseLevel)
                end
            else
                print(indentString, key, value)
            end
        end
    else
        print(indentString, " is not a table.")
    end
end

local function myPrintTable2(yourTable, recurseLevel, maxRecurseLevel, searchString, showParentKey, parentKey)
    if type(yourTable) == "table" then
        print("myPrintTable2 was sent a table")
        recurseLevel = recurseLevel or 0
        maxRecurseLevel = maxRecurseLevel or 0
        searchString = searchString or ""
        showParentKey = showParentKey or false
        parentKey = showParentKey and (parentKey or "") or ""
        indentString = string.rep("  ", recurseLevel) 
        local stringFound
        for key, value in pairs(yourTable) do
            print("myPrintTable2 in loop")
            if (searchString ~= "") then
                print("searchString is ", searchString, ", parentKey is ", parentKey, ", key is ", key)
                stringFound = string.find(indentString, searchString)
            else
                stringFound = nil
            end
            if type(value) == "table" then
                print(indentString, parentKey, key.." is table:")
                if (maxRecurseLevel == 0 or recurseLevel < maxRecurseLevel) then
                    myPrintTable2(value, recurseLevel + 1, maxRecurseLevel, searchString, showParentKey, key)
                end
            elseif (not searchString or (stringFound)) then
                    if (stringFound) then
                        indentString = indentString.."    ---->  "
                    end
                    print(parentKey, indentString, key, value)
            end
        end
    else
        print(indentString, " is not a table.")
    end
end

local function dump(o,level)
    level = level or 1
    if type(o) == 'table' then
        local s = {}
        s[1] = '{ '
        o_sorted = {}
        for n in pairs(o) do
            table.insert(o_sorted, n)
        end
        table.sort(o_sorted)
        for i,k in ipairs(o_sorted) do
            local v = o[k]
            if type(k) ~= 'number' then 
                k = '"'..k..'"' 
            end
            s[#s+1] = string.rep('  ',level).. '['..k..'] = ' .. dump(v, level+1) .. ','
        end
        s[#s+1] = string.rep('  ',level) .. '} '
        return table.concat(s , "\n")
    else
        return tostring(o or 'nil')
    end
end

local function myPrintTable3(o)
    for i in string.gmatch(dump(o), "[^\n]+") do
        print(i)
    end
end

local f = CreateFrame("Frame")
f.category = {}

--[[
local frame = CreateFrame("Frame")
local background = frame:CreateTexture()
background:SetAllPoints(frame)
background:SetColorTexture(1, 0, 1, 0.5)

local category = Settings.RegisterCanvasLayoutCategory(frame, "My AddOn")
Settings.RegisterAddOnCategory(category)
]]

---[[
ColorMyFrame_RaidFramePreviewMixin = { };

function ColorMyFrame_RaidFramePreviewMixin:OnLoad()
    --print("in ColorMyFrame_RaidFramePreviewMixin:OnLoad()")
    CompactUnitFrame_SetUpFrame(self.RaidFrame, DefaultCompactUnitFrameSetup);
    CompactUnitFrame_SetUnit(self.RaidFrame, "player");
    CompactUnitFrame_SetUpdateAllEvent(self.RaidFrame, "GROUP_ROSTER_UPDATE");

    self.UserColorPreview:SetColorTexture(f.db.player.r, f.db.player.g, f.db.player.b);
    self.OthersColorPreview:SetColorTexture(f.db.others.r, f.db.others.g, f.db.others.b);

    --print("self in ColorMyFrame_RaidFramePreviewMixin:")
    --myPrintTable(self, 0, 1)
    --print("end self in ColorMyFrame_RaidFramePreviewMixin")
--[[
    CompactUnitFrame_SetUpFrame(self.RaidFrame2, DefaultCompactUnitFrameSetup);
    CompactUnitFrame_SetUnit(self.RaidFrame2, "player");
    CompactUnitFrame_SetUpdateAllEvent(self.RaidFrame2, "GROUP_ROSTER_UPDATE");
--]]
end

--function ColorMyFrame_OnUpdate(self, elapsed)
--end

function ColorMyFrame_RaidFramePreviewMixin:OnUpdate(elapsed)
    print("in ColorMyFrame_RaidFramePreviewMixin:OnUpdate()")
    self.UserColorPreview:SetColorTexture(f.db.player.r, f.db.player.g, f.db.player.b);
    self.OthersColorPreview:SetColorTexture(f.db.others.r, f.db.others.g, f.db.others.b);
    self.RaidFrame.needsUpdate = true
    self.RaidFrame:TryUpdate()
end
--[[
function SettingsCategoryListButtonMixin:Init(initializer)
	local category = initializer.data.category;

	self.Label:SetText(category:GetName());
	self.Toggle:SetShown(category:HasSubcategories());
	
	local anyNew = false;
	local layout = SettingsPanel:GetLayout(category);
	if layout and layout:IsVerticalLayout() then
		for _, initializer in layout:EnumerateInitializers() do
			local setting = initializer.data.setting;
			if setting and IsNewSettingInCurrentVersion(setting:GetVariable()) then
				anyNew = true;
				break;
			end
		end
	end

	self.NewFeature.BGLabel:SetPoint("RIGHT", 0.5, -0.5);
	self.NewFeature.Label:SetPoint("RIGHT", 0, 0);
	self.NewFeature:SetShown(anyNew);

	self:SetExpanded(category.expanded);
	self:SetSelected(g_selectionBehavior:IsSelected(self));
end
--]]
function f:doNewADDON_LOADED(event, addOnName)
    ColorMyFrame_SavedVars = ColorMyFrame_SavedVars or CopyTable(defaults)
    --print("printing ColorMyFrame_SavedVars:")
    --myPrintTable3(ColorMyFrame_SavedVars)
    self.db = ColorMyFrame_SavedVars
    --print("in f:doNewADDON_LOADED, printing self.db:")
    --myPrintTable3(self.db)

    local function OnSettingChanged(_, setting, value)
        local variable = setting:GetVariable()
        ColorMyFrame_SavedVars[variable] = value
        print("print OnSettingsChanged(): ColorMyFrame_SavedVars")
        myPrintTable3(ColorMyFrame_SavedVars)
    end

    --function Settings.SetupCVarDropdown(category, variable, variableType, options, label, tooltip)

    self.category, self.layout = Settings.RegisterVerticalLayoutCategory(alternateAddonName)

    --layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(PING_SYSTEM_LABEL));

    local function ShowColorPicker(r, g, b, changedCallback)
        local info = {}
        info.r, info.g, info.b = r, g, b
        info.swatchFunc, info.func, info.opacityFunc, info.cancelFunc = changedCallback, changedCallback, changedCallback, changedCallback;
        --print("in ShowColorPicker, info:")
        --myPrintTable3(info)
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end

    local function newRGB(restore)
        if restore then
            -- User canceled (probably)
            return restore.r, restore.g, restore.b
        else
            -- Something changed
            return ColorPickerFrame:GetColorRGB();
        end
    end

    local function userColorCallback(restore)
        -- Update our internal storage.
        local p = self.db.player
        p.r, p.g, p.b = newRGB(restore)
        -- And update any UI elements that use this color...
        -- EventRegistry:TriggerEvent("ActionBarShownSettingUpdated")
        CompactPartyFrame:RefreshMembers()
        CompactRaidFrameContainer:TryUpdate()

        --local data = { };
        --local initializer = Settings.CreatePanelInitializer("ColorMyFrame_RaidFramePreviewTemplate", data);
        --self.layout:AddInitializer(initializer);


        --print("ColorMyFrame_RaidFramePreviewTemplate in userColorCallback: ")
        --myPrintTable3(ColorMyFrame_RaidFramePreviewTemplate)
        --print("end ColorMyFrame_RaidFramePreviewTemplate in userColorCallback")
        --print(ColorMyFrame_RaidFramePreviewTemplate)
        --print("self.OthersColorPreview")
        --myPrintTable3(self.OthersColorPreview)
        --print(" end self.OthersColorPreview")
        --print(self.OthersColorPreview)
        --self.RaidFrame:TryUpdate()
        --print("ColorMyFrame_RaidFramePreviewMixin: ")
        --myPrintTable(ColorMyFrame_RaidFramePreviewMixin, 0, 2)
        --print("self.layout: ")
        --myPrintTable(self.layout, 0, 3)
        --CompactUnitFrameProfiles:ApplyCurrentSettings()
    end

    local function othersColorCallback(restore)
        -- Update our internal storage.
        local o = self.db.others
        o.r, o.g, o.b = newRGB(restore)
        -- And update any UI elements that use this color...
        CompactPartyFrame:RefreshMembers()
        CompactRaidFrameContainer:TryUpdate()
        --self.RaidFrame:TryUpdate()
        --CompactUnitFrameProfiles:ApplyCurrentSettings()
    end

-- Select user's color
    do
        local function OnButtonClick()
            --print("button: Your Raid Frame Color")
            --print("print self.db:")
            --myPrintTable3(self.db)
            --print("self.layout.settings: ")
            --myPrintTable3(self.layout.settings)
            --print("button: Select Your Color")
            ShowColorPicker(self.db.player.r, self.db.player.g, self.db.player.b, userColorCallback);
            --print("print self.db after ShowColorPicker():")
            --myPrintTable3(self.db)
        end

        local addSearchTags = true;
        local tooltip = "Select the color that you want your own raid frame to be. Note: due to how raid frames are shaded, the result will appear a little darker."
        local initializer = CreateSettingsButtonInitializer("Your Raid Frame Color", "Select Color", OnButtonClick, tooltip, addSearchTags);
        self.layout:AddInitializer(initializer);
    end
--[[
    do
        local setting = Settings.RegisterCVarSetting(category, "showPingsInChat", Settings.VarType.Boolean, SHOW_PINGS_IN_CHAT);
        local function OnButtonClick()
                ShowUIPanel(ChatConfigFrame);
                ChatConfigFrameChatTabManager:UpdateSelection(DEFAULT_CHAT_FRAME:GetID());
        end;
        local initializer = CreateSettingsCheckboxWithButtonInitializer(setting, PING_CHAT_SETTINGS, OnButtonClick, true, OPTION_TOOLTIP_SHOW_PINGS_IN_CHAT);
        local initializer = CreateSettingsCheckboxWithButtonInitializer("Your raid frame color", "Select Color", OnButtonClick, tooltip, addSearchTags);
    end
]]
    -- Select other players's color
    do
        local function OnButtonClick()
            --print("button: Re-color Other Players")
            --print("print self.db:")
            --myPrintTable3(self.db)
            --print("self.layout.settings: ")
            --print(self.layout.settings)
            ShowColorPicker(self.db.others.r, self.db.others.g, self.db.others.b, othersColorCallback);
        end

        local variable = "recolorOthers"
        local name = "Re-color Other Players"
        local tooltip = "Change the colors of OTHER players' frames. Class colors must be disabled."
        local defaultValue = defaults.recolorOthers
        local value = ColorMyFrame_SavedVars[variable] or defaultValue

        local variableColor = "others"
        local nameColor = "Re-color Other Players"
        local tooltipColor = "The color other players frames will be set to."
        local defaultValueColor = {defaults.othersR, defaults.othersG, defaults.othersB}
        local valueColor = ColorMyFrame_SavedVars[variableColor] or defaultValueColor

        --function Settings.RegisterAddOnSetting(categoryTbl, name, variable, variableType, defaultValue)
		assert(type(ColorMyFrame_SavedVars) == "table", "hey man, 'variableTbl' argument must be a table.");
        local setting = Settings.RegisterAddOnSetting(self.category, variable, variable, ColorMyFrame_SavedVars, type(value), name, defaultValue)
        local settingColor = Settings.RegisterAddOnSetting(self.category, variableColor, variableColor, ColorMyFrame_SavedVars, type(valueColor), nameColor, defaultValueColor)
        --Settings.CreateCheckBox(self.category, setting, tooltip)
        local initializer = CreateSettingsCheckboxWithButtonInitializer(setting, "Select Color", OnButtonClick, true, tooltip) --addSearchTags?
        Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
        self.layout:AddInitializer(initializer);
    end
--[[
	do
		local colorText2 = self:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		colorText2:SetText("Yourrrrrrrrrrrrr raid frame color: r = "..self.db.player.r..", g = "..self.db.player.g..", b = "..self.db.player.b);
		colorText2:SetPoint("TOP", bddddddtn, 0, -8);
	end

    do
        local colorText = self:CreateFontString("ARTWORK", nil, "GameFontNormal")
        colorText:SetPoint("TOPLEFT", 0, -40)
        colorText:SetText("Your raiddddddddd frame color: r = "..self.db.player.r..", g = "..self.db.player.g..", b = "..self.db.player.b)
    end

    local splot = CreateFrame('Frame', nil, self);
    splot:SetSize(64, 64);
    splot:SetPoint("TOPLEFT", 0, -100);
    local t = splot:CreateTexture(nil, 'ARTWORK');
    t:SetAllPoints(splot);
    t:SetColorTexture(self.db.player.r, self.db.player.g, self.db.player.b);
--]]
    -- Raid Frame Preview
    do
        local data = { };
        local initializer = Settings.CreatePanelInitializer("ColorMyFrame_RaidFramePreviewTemplate", data);
        self.layout:AddInitializer(initializer);
    end

    Settings.RegisterAddOnCategory(self.category)
end
--]]

function f:OnEvent(event, ...)
    self[event](self, event, ...)
end

f:RegisterEvent("ADDON_LOADED")
--f:RegisterEvent("PLAYER_ENTERING_WORLD")
--f:RegisterEvent("CHAT_MSG_CHANNEL")
f:SetScript("OnEvent", f.OnEvent)

-- this function is the actual meat of the addon
function f:myUpdateHealthColor(frame)
    local unit = frame.unit
    local useClassColors = CVarCallbackRegistry:GetCVarValueBool("raidFramesDisplayClassColor")
    local pvpUseClassColors = CVarCallbackRegistry:GetCVarValueBool("pvpFramesDisplayClassColor")
    --print("useClassColors is ", useClassColors)
    --print("pvpUseClassColors is ", pvpUseClassColors)
    --print('UnitIsFriend(unit, "player") is ', UnitIsFriend(unit, "player"))
    --print('UnitIsEnemy(unit, "player") is ', UnitIsEnemy(unit, "player"))

    -- color user's frame
    if ( UnitIsUnit(unit, "player") ) then
        --print("frame in myUpdateHealthColor:", unit, ", r,g,b = ", r, ",",g,",",b,", recolorOthers = ", self.db.recolorOthers)
        --print("printing frame:")
        --myPrintTable(frame, 0, 1)
        --print("in UnitIsUnit, printing self.db:")
        --myPrintTable3(self.db)
        --print("end")
        local r, g, b = self.db.player.r, self.db.player.g, self.db.player.b
        if ( r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b ) then
            frame.healthBar:SetStatusBarColor(r, g, b);
        end
    -- color other players' frames
    elseif  ( self.db.recolorOthers and (not useClassColors and UnitIsFriend(unit, "player") or not pvpUseClassColors and UnitIsEnemy(unit, "player")) ) then
        --print("frame in myUpdateHealthColor:", unit, ", r,g,b = ", r, ",",g,",",b,", recolorOthers = ", self.db.recolorOthers)
        --myPrintTable2(frame, 0, 1, "lass", true)
        local r, g, b = self.db.others.r, self.db.others.g, self.db.others.b
        if ( r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b ) then
            frame.healthBar:SetStatusBarColor(r, g, b);
        end
    end
end

function f:ADDON_LOADED(event, addOnName)
    if addOnName == thisAddonName then
        self:doNewADDON_LOADED(event, addOnName)
--[[
        ColorMyFrameDB = ColorMyFrameDB or CopyTable(oldDefaults)
        --print("printing ColorMyFrameDB:")
        --myPrintTable3(ColorMyFrameDB)
        self.oldDb = ColorMyFrameDB
        self:InitializeOptions()
        hooksecurefunc("JumpOrAscendStart", function()
            if self.oldDb.someOption then
                --print("Your character jumped.")
            end
        end)
--]]
        hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
            self:myUpdateHealthColor(frame)
        end)
    end
end

--[[
function f:OnDefault()
	print("f:OnDefault() ran!!!")
end

function f.category:OnDefault()
	print("f.category:OnDefault() ran!!!")
end

function f.layout:OnDefault()
	print("f.layout:OnDefault() ran!!!")
end

function ColorMyFrame_OnDefault()
	print("ColorMyFrame_OnDefault() ran!!!")
end

function f:OnRefresh()
	print("f:OnRefresh() ran!!!")
end

function f.category:OnRefresh()
	print("f.category:OnRefresh() ran!!!")
end

function f.layout:OnRefresh()
	print("f.layout:OnRefresh() ran!!!")
end

function ColorMyFrame_OnRefresh()
	print("ColorMyFrame_OnRefresh() ran!!!")
end

function f:OnCommit()
	print("f:OnCommit() ran!!!")
end

function f.category:OnCommit()
	print("f.category:OnCommit() ran!!!")
end

function f.layout:OnCommit()
	print("f.layout:OnCommit() ran!!!")
end

function ColorMyFrame_OnCommit()
	print("ColorMyFrame_OnCommit() ran!!!")
end
--]]

--[[
function f:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
    --print(event, isLogin, isReload)
end
--]]
--[[
function f:InitializeOptions()
    self.optionsPanel = CreateFrame("Frame")
    self.optionsPanel.name = thisAddonTitle

    local cb = CreateFrame("CheckButton", nil, self.optionsPanel, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 20, -20)
    cb.Text:SetText("Print when you jump")
    -- there already is an existing OnClick script that plays a sound, hook it
    cb:HookScript("OnClick", function(_, btn, down)
        self.oldDb.someOption = cb:GetChecked()
    end)
    cb:SetChecked(self.oldDb.someOption)

    local btn = CreateFrame("Button", nil, self.optionsPanel, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", cb, 0, -40)
    btn:SetText("Click me")
    btn:SetWidth(100)

    local colorText = self.optionsPanel:CreateFontString("ARTWORK", nil, "GameFontNormal")
    colorText:SetPoint("TOPLEFT", btn, 0, -40)

    local splot = CreateFrame('Frame', nil, self.optionsPanel);
    splot:SetSize(64, 64);
    splot:SetPoint("TOPLEFT", btn, 0, -100);
    local t = splot:CreateTexture(nil, 'ARTWORK');
    t:SetAllPoints(splot);

    local function setOptionsPanelColor()
        colorText:SetText("Your raid frameeeeeeee color: r = "..self.oldDb.r..", g = "..self.oldDb.g..", b = "..self.oldDb.b)
        t:SetColorTexture(self.oldDb.r, self.oldDb.g, self.oldDb.b);
    end
    setOptionsPanelColor()
--]]
--[[
    local function ShowColorPicker(r, g, b, changedCallback)
     local info = {}
     info.r, info.g, info.b = r, g, b
     info.swatchFunc, info.func, info.opacityFunc, info.cancelFunc = changedCallback, changedCallback, changedCallback, changedCallback;
     ColorPickerFrame:SetupColorPickerAndShow(info)
    end

    local function userColorCallback(restore)
        local newR, newG, newB;
        if restore then
            newR, newG, newB = restore.r, restore.g, restore.b
        else
            -- Something changed
            newR, newG, newB = ColorPickerFrame:GetColorRGB();
        end

        -- Update our internal storage.
        self.oldDb.r, self.oldDb.g, self.oldDb.b = newR, newG, newB;
        setOptionsPanelColor()
        -- And update any UI elements that use this color...
        CompactRaidFrameContainer:TryUpdate()
    end
--]]
--[[
    btn:SetScript("OnClick", function()
        print("You clicked me!")
        ShowColorPicker(self.oldDb.r, self.oldDb.g, self.oldDb.b, userColorCallback);
    end)
    InterfaceOptions_AddCategory(self.optionsPanel)
end
--]]
SLASH_CMF1 = "/cmf"
SLASH_CMF2 = "/colormyframe"

SlashCmdList.CMF = function(msg, editBox)
    Settings.OpenToCategory(f.category:GetID())
end

function ColorMyFrame_OnAddonCompartmentClick(addonName, buttonName, menuButtonFrame)
    Settings.OpenToCategory(f.category:GetID())
end
