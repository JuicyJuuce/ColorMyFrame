local thisAddonName = "ColorMyFrame"
local thisAddonTitle = "Color My Frame"

local defaults = {
  someOption = true,
  r = 255/255, g = 200/255, b = 0/255, -- yellow-orange
}

local f = CreateFrame("Frame")

function f:OnEvent(event, ...)
  self[event](self, event, ...)
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", f.OnEvent)

-- this function is the actual meat of the addon
function f:myUpdateHealthColor(frame)
  if ( UnitIsUnit(frame.unit, "player") ) then
    local r, g, b = self.db.r, self.db.g, self.db.b
    if ( r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b ) then
      frame.healthBar:SetStatusBarColor(r, g, b);
    end
  end
end

function f:ADDON_LOADED(event, addOnName)
  print(event, addOnName)
  if addOnName == thisAddonName then
    ColorMyFrameDB = ColorMyFrameDB or CopyTable(defaults)
    self.db = ColorMyFrameDB
    self:InitializeOptions()
    hooksecurefunc("JumpOrAscendStart", function()
      if self.db.someOption then
        print("Your character jumped.")
      end
    end)
    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
      self:myUpdateHealthColor(frame)
    end)
  end
end

function f:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
  print(event, isLogin, isReload)
end

function f:CHAT_MSG_CHANNEL(event, text, playerName, _, channelName)
  print(event, text, playerName, channelName)
end

function f:InitializeOptions()
  self.optionsPanel = CreateFrame("Frame")
  self.optionsPanel.name = thisAddonName

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

--  do
--    local data = { };
--    local initializer = Settings.CreatePanelInitializer("RaidFramePreviewTemplate", data);
--    layout:AddInitializer(initializer);
--  end

  local function setOptionsPanelColor()
    colorText:SetText("Your raid frame color: r = "..self.db.r..", g = "..self.db.g..", b = "..self.db.b)
    t:SetColorTexture(self.db.r, self.db.g, self.db.b);
  end
  setOptionsPanelColor()

  local function ShowColorPicker(r, g, b, changedCallback)
   local info = {}
   info.r, info.g, info.b = r, g, b
   info.swatchFunc, info.func, info.opacityFunc, info.cancelFunc = changedCallback, changedCallback, changedCallback, changedCallback;
   ColorPickerFrame:SetupColorPickerAndShow(info)
  end

  local function myColorCallback(restore)
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

  btn:SetScript("OnClick", function()
    print("You clicked me!")
    ShowColorPicker(self.db.r, self.db.g, self.db.b, myColorCallback);
  end)

  InterfaceOptions_AddCategory(self.optionsPanel)
end

SLASH_CMF1 = "/cmf"
SLASH_CMF2 = "/colormyframe"

SlashCmdList.CMF = function(msg, editBox)
  InterfaceOptionsFrame_OpenToCategory(f.optionsPanel)
end

function ColorMyFrame_OnAddonCompartmentClick(addonName, buttonName, menuButtonFrame)
  InterfaceOptionsFrame_OpenToCategory(f.optionsPanel)
end
