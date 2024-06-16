-- TO DO:
--   addSearchTags?
--   fixdefaultsbutton

local thisAddonName, ns = ...
local alternateAddonName = "NEW Color My Frame"
--print(thisAddonName, ns.foo)

local thisAddonTitle = "Color My Frame"

local defaults = {
    someOption = true,
    r = 255/255, g = 200/255, b = 0/255, -- yellow-orange
}

local newDefaults = {
    recolorOthers = false,
    slider = 140,
    selection = 1,
    r = 255/255, g = 200/255, b = 0/255, -- yellow-orange
    othersR = 0/255, othersG = 255/255, othersB = 0/255, -- green
}

local function myPrintTable(yourTable, recurseLevel, maxRecurseLevel, searchString, showParentKey, parentKey)
    if 1 then return else
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
ManyRaidFramesPreviewMixin = { };

function ManyRaidFramesPreviewMixin:OnLoad()
    --print("in ManyRaidFramesPreviewMixin:OnLoad()")
    CompactUnitFrame_SetUpFrame(self.RaidFrame, DefaultCompactUnitFrameSetup);
    CompactUnitFrame_SetUnit(self.RaidFrame, "player");
end

function f:doNewADDON_LOADED(event, addOnName)
    --ColorMyFrame_SavedVars = {}
    ColorMyFrame_SavedVars = ColorMyFrame_SavedVars or CopyTable(newDefaults)
    --print("printing ColorMyFrame_SavedVars:")
    --myPrintTable(ColorMyFrame_SavedVars)
    self.newDb = ColorMyFrame_SavedVars

    -- am i using this?
    local function OnSettingChanged(_, setting, value)
        local variable = setting:GetVariable()
        ColorMyFrame_SavedVars[variable] = value
        --print("print OnSettingsChanged(): ColorMyFrame_SavedVars")
        --myPrintTable(ColorMyFrame_OnAddonCompartmentClick)
    end

    --function Settings.SetupCVarDropdown(category, variable, variableType, options, label, tooltip)

    f.category, f.layout = Settings.RegisterVerticalLayoutCategory(alternateAddonName)

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
        self.newDb.r, self.newDb.g, self.newDb.b = newRGB(restore)
        -- And update any UI elements that use this color...
        CompactRaidFrameContainer:TryUpdate()
        --CompactUnitFrameProfiles:ApplyCurrentSettings()
    end

    local function othersColorCallback(restore)
        -- Update our internal storage.
        self.newDb.othersR, self.newDb.othersG, self.newDb.othersB = newRGB(restore)
        -- And update any UI elements that use this color...
        CompactRaidFrameContainer:TryUpdate()
        --CompactUnitFrameProfiles:ApplyCurrentSettings()
    end

-- Select user's color
    do
        local function OnButtonClick()
            print("button: Select Your Color")
            ShowColorPicker(self.newDb.r, self.newDb.g, self.newDb.b, userColorCallback);
        end

        local addSearchTags = true;
        local tooltip = "Select the color that you want your own raid frame to be. Note: due to how raid frames are shaded, the result will appear a little darker."
        local initializer = CreateSettingsButtonInitializer("Your raid frame color", "Select Color", OnButtonClick, tooltip, addSearchTags);
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
            --print("print self.newDb:")
            --myPrintTable(self.newDb)
            ShowColorPicker(self.newDb.othersR, self.newDb.othersG, self.newDb.othersB, othersColorCallback);
        end

        local variable = "recolorOthers"
        local name = "Re-color Other Players"
        local tooltip = "Change the colors of _other_ player's frames. Class colors must be disabled."
        local defaultValue = false
        local value = ColorMyFrame_SavedVars[variable] or defaultValue

        local setting = Settings.RegisterAddOnSetting(f.category, name, variable, type(value), value)
        --Settings.CreateCheckBox(f.category, setting, tooltip)
        local initializer = CreateSettingsCheckBoxWithButtonInitializer(setting, "Select Color", OnButtonClick, true, "Your raid frame color") --addSearchTags?
        Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
        self.layout:AddInitializer(initializer);
    end

    do
        local variable = "slider"
        local name = "Test Slider"
        local tooltip = "This is a tooltip for the slider."
        local defaultValue = 180
        --print("ColorMyFrame_SavedVars[variable] is "..(ColorMyFrame_SavedVars[variable] or "nil"))
        local value = ColorMyFrame_SavedVars[variable] or defaultValue
        local minValue = 90
        local maxValue = 360
        local step = 10

        local setting = Settings.RegisterAddOnSetting(f.category, name, variable, type(value), value)
        local options = Settings.CreateSliderOptions(minValue, maxValue, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
        Settings.CreateSlider(f.category, setting, options, tooltip)
        Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
    end

    do
        local variable = "selection"
        local defaultValue = 2  -- Corresponds to "Option 2" below.
        local value = ColorMyFrame_SavedVars[variable] or defaultValue
        local name = "Test Dropdown"
        local tooltip = "This is a tooltip for the dropdown."

        local function GetOptions()
            local container = Settings.CreateControlTextContainer()
            container:Add(1, "Option 1")
            container:Add(2, "Option 2")
            container:Add(3, "Option 3")
            return container:GetData()
        end

        local setting = Settings.RegisterAddOnSetting(f.category, name, variable, type(value), value)
        Settings.CreateDropDown(f.category, setting, GetOptions, tooltip)
        Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
    end

    -- Raid Frame Preview
    do
        local data = { };
        local initializer = Settings.CreatePanelInitializer("ManyRaidFramesPreviewTemplate", data);
        self.layout:AddInitializer(initializer);
    end

    Settings.RegisterAddOnCategory(f.category)
end
--]]

function f:OnEvent(event, ...)
    self[event](self, event, ...)
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
--f:RegisterEvent("CHAT_MSG_CHANNEL")
f:SetScript("OnEvent", f.OnEvent)

--      local newList = CreateFrame("Button", "DropDownList"..UIDROPDOWNMENU_MAXLEVELS, nil, "UIDropDownListTemplate");


-- this function is the actual meat of the addon
function f:myUpdateHealthColor(frame)
    local unit = frame.unit
    --print("frame.useClassColors is ", frame.useClassColors)
    --print("frame.pvpUseClassColors is ", frame.pvpUseClassColors)
    --print('UnitIsFriend(unit, "player") is ', UnitIsFriend(unit, "player"))
    --print('UnitIsEnemy(unit, "player") is ', UnitIsEnemy(unit, "player"))

    if ( UnitIsUnit(unit, "player") ) then
        local r, g, b = self.newDb.r, self.newDb.g, self.newDb.b
        if ( r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b ) then
            frame.healthBar:SetStatusBarColor(r, g, b);
        end
    elseif  ( not frame.useClassColors and UnitIsFriend(unit, "player") or not frame.pvpUseClaseColors and UnitIsEnemy(unit, "player") ) then
        print("frame in myUpdateHealthColor:")
        print(unit)
        myPrintTable(frame, 0, 1, "lass", true)
        local r, g, b = self.newDb.othersR, self.newDb.othersG, self.newDb.othersB
        if ( r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b ) then
            frame.healthBar:SetStatusBarColor(r, g, b);
        end
    end
end

function f:ADDON_LOADED(event, addOnName)
    if addOnName == thisAddonName then
        self:doNewADDON_LOADED(event, addOnName)
        ColorMyFrameDB = ColorMyFrameDB or CopyTable(defaults)
        --print("printing ColorMyFrameDB:")
        --myPrintTable(ColorMyFrameDB)
        self.db = ColorMyFrameDB
        self:InitializeOptions()
        hooksecurefunc("JumpOrAscendStart", function()
            if self.db.someOption then
                --print("Your character jumped.")
            end
        end)
        hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
            self:myUpdateHealthColor(frame)
        end)
    end
end

function f:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
    --print(event, isLogin, isReload)
end

function f:InitializeOptions()
    self.optionsPanel = CreateFrame("Frame")
    self.optionsPanel.name = thisAddonTitle

    local cb = CreateFrame("CheckButton", nil, self.optionsPanel, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 20, -20)
    cb.Text:SetText("Print when you jump")
    -- there already is an existing OnClick script that plays a sound, hook it
    cb:HookScript("OnClick", function(_, btn, down)
        self.db.someOption = cb:GetChecked()
    end)
    cb:SetChecked(self.db.someOption)

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
        colorText:SetText("Your raid frame color: r = "..self.db.r..", g = "..self.db.g..", b = "..self.db.b)
        t:SetColorTexture(self.db.r, self.db.g, self.db.b);
    end
    setOptionsPanelColor()
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
        self.db.r, self.db.g, self.db.b = newR, newG, newB;
        setOptionsPanelColor()
        -- And update any UI elements that use this color...
        CompactRaidFrameContainer:TryUpdate()
    end
--]]
    btn:SetScript("OnClick", function()
        print("You clicked me!")
        ShowColorPicker(self.db.r, self.db.g, self.db.b, userColorCallback);
    end)

    InterfaceOptions_AddCategory(self.optionsPanel)
end

SLASH_CMF1 = "/cmf"
SLASH_CMF2 = "/colormyframe"

SlashCmdList.CMF = function(msg, editBox)
    InterfaceOptionsFrame_OpenToCategory(f.optionsPanel)
end

function ColorMyFrame_OnAddonCompartmentClick(addonName, buttonName, menuButtonFrame)
    --print("f.category:")
    --myPrintTable(f.category)
    InterfaceOptionsFrame_OpenToCategory(f.optionsPanel)
end
