local thisAddonName = "ColorMyFrame"
local thisAddonTitle = "Color My Frame"

local f = CreateFrame("Frame")

local defaults = {
	someOption = true,
  r = 255/255,
  g = 200/255,
  b = 0/255, -- yellow-orange
  a = 1.0,
  --r, g, b = 255/255, 0/255, 255/255, -- magenta
  --r, g, b = 0/255, 255/255, 0/255, -- green
}

function f:OnEvent(event, ...)
	self[event](self, event, ...)
end

function f:myUpdateHealthColor(frame)
  --if ( UnitPlayerControlled(frame.unit) ) then
  if ( UnitIsUnit(frame.unit, "player") ) then
    local r, g, b, a = self.db.r, self.db.g, self.db.b, self.db.a
    --print("r,g,b,a = "..r..", "..g..", "..b..", "..a)
    --local r, g, b = 255/255, 200/255, 0/255; -- yellow-orange
    --local r, g, b = 255/255, 0/255, 255/255; -- magenta
    --local r, g, b = 0/255, 255/255, 0/255; -- green
    if ( r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b ) then
      frame.healthBar:SetStatusBarColor(r, g, b);
      --frame.healthBar.r, frame.healthBar.g, frame.healthBar.b = r, g, b;
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

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
--f:RegisterEvent("CHAT_MSG_CHANNEL")
f:SetScript("OnEvent", f.OnEvent)


--function f:OnEvent(event, addOnName)
--	if addOnName == thisAddonName then
--		ColorMyFrameDB = ColorMyFrameDB or CopyTable(defaults)
--		self.db = ColorMyFrameDB
--		self:InitializeOptions()
--		hooksecurefunc("JumpOrAscendStart", function()
--			if self.db.someOption then
--				print("Your character jumped.")
--			end
--		end)
--	end
--end
--
--f:RegisterEvent("ADDON_LOADED")
--f:SetScript("OnEvent", f.OnEvent)

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
  
  local function setOptionsPanelColor()
    colorText:SetText("Your raid frame color: r = "..self.db.r..", g = "..self.db.g..", b = "..self.db.b..", a = "..self.db.a)
    t:SetColorTexture(self.db.r, self.db.g, self.db.b, self.db.a);
  end
  setOptionsPanelColor()

  --local r,g,b,a = 1, 0, 0, 1;

  function ShowColorPicker(r, g, b, a, changedCallback)
   --print("r,g,b,a = "..r..", "..g..", "..b..", "..a)
   local info = {}
   info.hasOpacity, info.opacity = (a ~= nil), a;
   info.r, info.g, info.b = r, g, b
   info.swatchFunc, info.func, info.opacityFunc, info.cancelFunc = changedCallback, changedCallback, changedCallback, changedCallback;
   --ColorPickerFrame:SetColorRGB(r,g,b);
   --ColorPickerFrame:Hide(); -- Need to run the OnShow handler.
   --ColorPickerFrame:Show();
   ColorPickerFrame:SetupColorPickerAndShow(info)
  end

  local function myColorCallback(restore)
    local newR, newG, newB, newA;
    if restore then
      --print("restore:")
      --for key, value in pairs(restore) do
      --  print(key, value)
      --end
      -- The user bailed, we extract the old color from the table created by ShowColorPicker.
      newR, newG, newB, newA = restore.r, restore.g, restore.b, restore.a --unpack(restore);
      --print("if restore TRUE")
    else
      -- Something changed
      newA, newR, newG, newB = ColorPickerFrame:GetColorAlpha(), ColorPickerFrame:GetColorRGB();
      --print("if restore FALSE")
    end
    --print("newR = "..newR)
    --print("newG = "..newG)
    --print("newB = "..newB)
    --print("newA = "..newA)
    --if newA then
    --  --print("newR,newG,newB,newA = "..newR..", "..newG..", "..newB..", "..newA)
    --else
    --  print("newA is nil")
    --end
   
    -- Update our internal storage.
    self.db.r, self.db.g, self.db.b, self.db.a = newR, newG, newB, newA;
    setOptionsPanelColor()
    -- And update any UI elements that use this color...
    --CompactPartyFrameMixin:UpdateLayout() --CompactUnitFrame_UpdateAll(CompactPartyFrame)
    --RaidPullout_RenewFrames()
    CompactRaidFrameContainerMixin:TryUpdate()
  end
  
  --ShowColorPicker(self.db.r, self.db.g, self.db.b, self.db.a, myColorCallback);

	btn:SetScript("OnClick", function()
		print("You clicked me!")
    ShowColorPicker(self.db.r, self.db.g, self.db.b, self.db.a, myColorCallback);
	end)

	InterfaceOptions_AddCategory(self.optionsPanel)
end

SLASH_CMF1 = "/cmf"
SLASH_CMF2 = "/colormyframe"

SlashCmdList.CMF = function(msg, editBox)
	InterfaceOptionsFrame_OpenToCategory(f.optionsPanel)
end


--local optionsPanel = CreateFrame("Frame")
--optionsPanel.name = thisAddonTitle
--InterfaceOptions_AddCategory(optionsPanel)

--local title = optionsPanel:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
--title:SetPoint("TOPLEFT")
--title:SetText(thisAddonTitle)

--local footer = optionsPanel:CreateFontString("ARTWORK", nil, "GameFontNormal")
--footer:SetPoint("TOPLEFT", 0, 0)
--footer:SetText("This is 5000 below the top, so the optionsPanel automatically expanded.")

function ColorMyFrame_OnAddonCompartmentClick(addonName, buttonName, menuButtonFrame)
  print("Hello from the addon compartment, the '"..addonName.."' addon was clicked with "..buttonName)
  --InterfaceOptionsFrame_Show()
  InterfaceOptionsFrame_OpenToCategory(f.optionsPanel)
end
 
