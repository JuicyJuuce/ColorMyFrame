-- TO DO:
--   addSearchTags?
--   fixdefaultsbutton
--   check if my use of UnitIsEnemy(unit, "player") correctly detects arena frames
--   onSettingsChanged, RegisterAddonSetting
--   make your preview frame in settings live update
--   add text below the preview frame indicating that user needs to join a party or raid to preview others' colors.
--     "Preview your frame color:"
--     "Note: no preview available for re-coloring party/raid frames of others. Join a party or raid to see the
--      effects. Tip: you can join an NPC party at any time by queueing for a follower dungeon."
--   maybe disable the secure hook if both color options are unchecked?
--   align color texture previews with buttons

local thisAddonName, ns = ...
local thisAddonTitle = "Color My Frame"

local alternateAddonName = thisAddonTitle --"NEW Color My Frame"
--print(thisAddonName, ns.foo)

local defaults = {
    someOption = true,
    r = 255/255, g = 200/255, b = 0/255, -- yellow-orange
}

local newDefaults = {
    recolorOthers = false,
    r = 255/255,
    g = 200/255,
    b = 0/255, -- yellow-orange
    othersR = 0/255,
    othersG = 255/255,
    othersB = 0/255, -- green
}

local function myPrintTable(yourTable, recurseLevel, maxRecurseLevel, searchString, showParentKey, parentKey)
--[[
    if type(yourTable) == "table" then
        recurseLevel = recurseLevel or 0
        maxRecurseLevel = maxRecurseLevel or 0
        searchString = searchString or ""
        showParentKey = showParentKey or false
        parentKey = showParentKey and (parentKey or "") or ""
        indentString = string.rep("  ", recurseLevel) 
        local classStrFound
        for key, value in pairs(yourTable) do
            if (searchString ~= "") then
                print("searchString is ", searchString, ", parentKey is ", parentKey, ", key is ", key)
                classStrFound = string.find(indentString, searchString)
            else
                classStrFound = nil
            end
            if type(value) == "table" then
                --print(indentString, parentKey, key.." is table:")
                if (maxRecurseLevel == 0 or recurseLevel < maxRecurseLevel) then
                    myPrintTable(value, recurseLevel + 1, maxRecurseLevel, showParentKey, key)
                end
            elseif (not searchString or (classStrFound)) then
                    if (classStrFound) then
                        indentString = indentString.."    ---->  "
                    end
                    print(parentKey, indentString, key, value)
            end
        end
    else
        print(indentString, " is not a table.")
    end
--]]
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

    self.UserColorPreview:SetColorTexture(f.db.r, f.db.g, f.db.b);
    self.OthersColorPreview:SetColorTexture(f.db.othersR, f.db.othersG, f.db.othersB);

--[[
    CompactUnitFrame_SetUpFrame(self.RaidFrame2, DefaultCompactUnitFrameSetup);
    CompactUnitFrame_SetUnit(self.RaidFrame2, "player");
    CompactUnitFrame_SetUpdateAllEvent(self.RaidFrame2, "GROUP_ROSTER_UPDATE");
--]]
end

function f:doNewADDON_LOADED(event, addOnName)
    --ColorMyFrame_SavedVars = {}
    ColorMyFrame_SavedVars = ColorMyFrame_SavedVars or CopyTable(newDefaults)
    --print("printing ColorMyFrame_SavedVars:")
    --myPrintTable(ColorMyFrame_SavedVars)
    self.db = ColorMyFrame_SavedVars

    -- am i using this?
    local function OnSettingChanged(_, setting, value)
        local variable = setting:GetVariable()
        ColorMyFrame_SavedVars[variable] = value
        --print("print OnSettingsChanged(): ColorMyFrame_SavedVars")
        --myPrintTable(ColorMyFrame_OnAddonCompartmentClick)
    end

    --function Settings.SetupCVarDropdown(category, variable, variableType, options, label, tooltip)

    self.category, self.layout = Settings.RegisterVerticalLayoutCategory(alternateAddonName)

    --layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(PING_SYSTEM_LABEL));

    local function ShowColorPicker(r, g, b, changedCallback)
        local info = {}
        info.r, info.g, info.b = r, g, b
        info.swatchFunc, info.func, info.opacityFunc, info.cancelFunc = changedCallback, changedCallback, changedCallback, changedCallback;
        --print("info:")
        --myPrintTable(info)
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
        self.db.r, self.db.g, self.db.b = newRGB(restore)
        -- And update any UI elements that use this color...
        CompactRaidFrameContainer:TryUpdate()
        --CompactUnitFrameProfiles:ApplyCurrentSettings()
    end

    local function othersColorCallback(restore)
        -- Update our internal storage.
        self.db.othersR, self.db.othersG, self.db.othersB = newRGB(restore)
        -- And update any UI elements that use this color...
        CompactRaidFrameContainer:TryUpdate()
        --CompactUnitFrameProfiles:ApplyCurrentSettings()
    end

-- Select user's color
    do
        local function OnButtonClick()
            print("button: Select Your Color")
            ShowColorPicker(self.db.r, self.db.g, self.db.b, userColorCallback);
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
        local initializer = CreateSettingsCheckBoxWithButtonInitializer(setting, PING_CHAT_SETTINGS, OnButtonClick, true, OPTION_TOOLTIP_SHOW_PINGS_IN_CHAT);
        local initializer = CreateSettingsCheckboxWithButtonInitializer("Your raid frame color", "Select Color", OnButtonClick, tooltip, addSearchTags);
    end
]]
    -- Select other players's color
    do
        local function OnButtonClick()
            print("button: Re-color Other Players")
            --print("print self.db:")
            --myPrintTable(self.db)
            ShowColorPicker(self.db.othersR, self.db.othersG, self.db.othersB, othersColorCallback);
        end

        local variable = "recolorOthers"
        local name = "Re-color Other Players"
        local tooltip = "Change the colors of OTHER players' frames. Class colors must be disabled."
        local defaultValue = false
        local value = ColorMyFrame_SavedVars[variable] or defaultValue

        local setting = Settings.RegisterAddOnSetting(self.category, name, variable, type(value), value)
        --Settings.CreateCheckBox(self.category, setting, tooltip)
        local initializer = CreateSettingsCheckBoxWithButtonInitializer(setting, "Select Color", OnButtonClick, true, tooltip) --addSearchTags?
        Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
        self.layout:AddInitializer(initializer);
    end
--[[
	do
		local colorText2 = self:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		colorText2:SetText("Yourrrrrrrrrrrrr raid frame color: r = "..self.db.r..", g = "..self.db.g..", b = "..self.db.b);
		colorText2:SetPoint("TOP", bddddddtn, 0, -8);
	end

    do
        local colorText = self:CreateFontString("ARTWORK", nil, "GameFontNormal")
        colorText:SetPoint("TOPLEFT", 0, -40)
        colorText:SetText("Your raiddddddddd frame color: r = "..self.db.r..", g = "..self.db.g..", b = "..self.db.b)
    end

    local splot = CreateFrame('Frame', nil, self);
    splot:SetSize(64, 64);
    splot:SetPoint("TOPLEFT", 0, -100);
    local t = splot:CreateTexture(nil, 'ARTWORK');
    t:SetAllPoints(splot);
    t:SetColorTexture(self.db.r, self.db.g, self.db.b);
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
        local r, g, b = self.db.r, self.db.g, self.db.b
        if ( r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b ) then
            frame.healthBar:SetStatusBarColor(r, g, b);
        end
    -- color other players' frames
    elseif  ( Settings.GetSetting("recolorOthers") and (not useClassColors and UnitIsFriend(unit, "player") or not pvpUseClassColors and UnitIsEnemy(unit, "player")) ) then
        print("frame in myUpdateHealthColor:")
        print(unit)
        myPrintTable(frame, 0, 1, "lass", true)
        local r, g, b = self.db.othersR, self.db.othersG, self.db.othersB
        if ( r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b ) then
            frame.healthBar:SetStatusBarColor(r, g, b);
        end
    end
end

function f:ADDON_LOADED(event, addOnName)
    if addOnName == thisAddonName then
        self:doNewADDON_LOADED(event, addOnName)
--[[
        ColorMyFrameDB = ColorMyFrameDB or CopyTable(defaults)
        --print("printing ColorMyFrameDB:")
        --myPrintTable(ColorMyFrameDB)
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
