-- Simple config UI (vanilla safe, PFUI-inspired layout)
StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS
SCE._moduleLoaded = SCE._moduleLoaded or {}
SCE._moduleLoaded.gui = true

-- Don't cache SCE functions at load time - they may not be defined yet
-- Access them directly via SCE.functionName() inside functions

local function printMsg(msg)
  if SCE.printMsg then
    SCE.printMsg(msg)
  elseif DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00" .. (SCE.ADDON or "SCE") .. "|r " .. (msg or ""))
  end
end

local function refreshUI()
  if SCE.refreshUI then
    SCE.refreshUI()
  end
end

local function setLocked(val)
  if SCE.setLocked then
    SCE.setLocked(val)
  end
end

local function layout()
  if SCE.layout then
    SCE.layout()
  end
end

local ConfigFrame
local ConfigPanels = {}
local ConfigMenuButtons = {}
local ConfigRefreshers = {}
local ReloadNeeded = false
local ReloadPrompt
local ReloadNotice
local updateReloadLabel
local cfgId = 0

local function refreshConfig()
  if ConfigFrame and ConfigFrame:IsShown() then
    for _, fn in ipairs(ConfigRefreshers) do
      fn()
    end
    updateReloadLabel()
  end
end

local function newName(prefix)
  cfgId = cfgId + 1
  return prefix .. cfgId
end

-- Store active color picker callback
local activeColorCallback = nil
local activeColorPrev = nil

local function openColorPicker(current, onChanged)
  if not current then return end
  local prev = { r = current[1] or 1, g = current[2] or 1, b = current[3] or 1, a = current[4] or 1 }
  activeColorPrev = prev
  activeColorCallback = onChanged
  
  local function setFromPicker()
    local r, g, b = ColorPickerFrame:GetColorRGB()
    local a = 1
    if ColorPickerFrame.hasOpacity and OpacitySliderFrame and OpacitySliderFrame.GetValue then
      local v = OpacitySliderFrame:GetValue()
      a = 1 - v
    end
    if activeColorCallback then
      activeColorCallback({ r, g, b, a })
    end
  end
  
  ColorPickerFrame.func = setFromPicker
  ColorPickerFrame.opacityFunc = setFromPicker
  ColorPickerFrame.cancelFunc = function()
    if activeColorCallback and activeColorPrev then
      activeColorCallback({ activeColorPrev.r, activeColorPrev.g, activeColorPrev.b, activeColorPrev.a })
    end
  end
  
  if current[4] then
    ColorPickerFrame.hasOpacity = true
    ColorPickerFrame.opacity = 1 - current[4]
  else
    ColorPickerFrame.hasOpacity = false
  end
  ColorPickerFrame:SetColorRGB(prev.r, prev.g, prev.b)
  ColorPickerFrame:Show()
end

local function setSwatch(btn, c)
  if not btn or not btn.tex then return end
  btn.tex:SetTexture(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
end

-- Convert RGB color to hex string (without #)
local function colorToHex(c)
  if not c then return "FFFFFF" end
  local r = math.floor((c[1] or 1) * 255 + 0.5)
  local g = math.floor((c[2] or 1) * 255 + 0.5)
  local b = math.floor((c[3] or 1) * 255 + 0.5)
  return string.format("%02X%02X%02X", r, g, b)
end

-- Convert hex string to RGB color table
local function hexToColor(hex, existingAlpha)
  if not hex then return nil end
  -- Remove # if present
  hex = string.gsub(hex, "^#", "")
  if string.len(hex) ~= 6 then return nil end
  
  local r = tonumber(string.sub(hex, 1, 2), 16)
  local g = tonumber(string.sub(hex, 3, 4), 16)
  local b = tonumber(string.sub(hex, 5, 6), 16)
  
  if not r or not g or not b then return nil end
  
  return { r / 255, g / 255, b / 255, existingAlpha or 1 }
end

updateReloadLabel = function()
  if not ReloadNotice then return end
  if ReloadNeeded then
    ReloadNotice:SetText("|cffff5555[!] Reload required|r")
    ReloadNotice:Show()
  else
    ReloadNotice:SetText("")
    ReloadNotice:Hide()
  end
end

local function showReloadPopup()
  if ReloadPrompt and ReloadPrompt:IsShown() then return end
  if not ReloadPrompt then
    ReloadPrompt = CreateFrame("Frame", "StupidComboEnergyReloadPrompt", UIParent)
    ReloadPrompt:SetWidth(320)
    ReloadPrompt:SetHeight(120)
    ReloadPrompt:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    ReloadPrompt:SetFrameStrata("DIALOG")
    if ReloadPrompt.SetBackdrop then
      ReloadPrompt:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
      })
      ReloadPrompt:SetBackdropColor(0.05, 0.08, 0.1, 0.95)
      ReloadPrompt:SetBackdropBorderColor(0.2, 0.7, 0.7, 0.9)
    end

    local msg = ReloadPrompt:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    msg:SetPoint("TOP", ReloadPrompt, "TOP", 0, -16)
    msg:SetText("Some settings need to reload the UI to take effect.\nDo you want to reload now?")

    local yes = CreateFrame("Button", newName("SCEButton"), ReloadPrompt, "UIPanelButtonTemplate")
    yes:SetPoint("BOTTOMLEFT", ReloadPrompt, "BOTTOMLEFT", 24, 16)
    yes:SetWidth(110)
    yes:SetHeight(24)
    yes:SetText("Yes")
    yes:SetScript("OnClick", function() ReloadUI() end)

    local no = CreateFrame("Button", newName("SCEButton"), ReloadPrompt, "UIPanelButtonTemplate")
    no:SetPoint("BOTTOMRIGHT", ReloadPrompt, "BOTTOMRIGHT", -24, 16)
    no:SetWidth(110)
    no:SetHeight(24)
    no:SetText("No")
    no:SetScript("OnClick", function() ReloadPrompt:Hide() end)

    ReloadPrompt.msg = msg
  end
  ReloadPrompt:Show()
end

local function triggerReloadNeeded()
  ReloadNeeded = true
  updateReloadLabel()
  showReloadPopup()
end

-- Helper to split string by delimiter (strsplit doesn't exist in Vanilla)
local function splitString(delimiter, str)
  local pos = string.find(str, delimiter, 1, true)
  if pos then
    return string.sub(str, 1, pos - 1), string.sub(str, pos + 1)
  end
  return str, nil
end

-- Available fonts list (like pfUI)
local availableFonts = {
  "Fonts\\FRIZQT__.TTF:FRIZQT",
  "Fonts\\ARIALN.TTF:ARIALN",
  "Fonts\\MORPHEUS.TTF:MORPHEUS",
  "Fonts\\SKURRI.TTF:SKURRI",
}

-- Add pfUI fonts if available
if pfUI then
  availableFonts = {
    "Interface\\AddOns\\pfUI\\fonts\\BigNoodleTitling.ttf:BigNoodleTitling",
    "Interface\\AddOns\\pfUI\\fonts\\Continuum.ttf:Continuum",
    "Interface\\AddOns\\pfUI\\fonts\\DieDieDie.ttf:DieDieDie",
    "Interface\\AddOns\\pfUI\\fonts\\Expressway.ttf:Expressway",
    "Interface\\AddOns\\pfUI\\fonts\\Homespun.ttf:Homespun",
    "Interface\\AddOns\\pfUI\\fonts\\Hooge.ttf:Hooge",
    "Interface\\AddOns\\pfUI\\fonts\\Myriad-Pro.ttf:Myriad-Pro",
    "Interface\\AddOns\\pfUI\\fonts\\PT-Sans-Narrow-Bold.ttf:PT-Sans-Narrow-Bold",
    "Interface\\AddOns\\pfUI\\fonts\\PT-Sans-Narrow-Regular.ttf:PT-Sans-Narrow-Regular",
    "Fonts\\FRIZQT__.TTF:FRIZQT",
    "Fonts\\ARIALN.TTF:ARIALN",
    "Fonts\\MORPHEUS.TTF:MORPHEUS",
  }
end

-- Create backdrop helper (minimal version if pfUI not available)
local function createSimpleBackdrop(frame)
  if pfUI and pfUI.api and pfUI.api.CreateBackdrop then
    pfUI.api.CreateBackdrop(frame, nil, true)
  elseif frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 8, edgeSize = 8,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
  end
end

local function addNumberField(panel, label, getter, setter, y, requiresReload)
  -- Frame container for hover effect
  local frame = CreateFrame("Frame", nil, panel)
  frame:SetHeight(22)
  frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, y)
  frame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, y)
  
  -- Hover background
  frame.tex = frame:CreateTexture(nil, "BACKGROUND")
  frame.tex:SetTexture(1, 1, 1, 0.05)
  frame.tex:SetAllPoints()
  frame.tex:Hide()
  frame:SetScript("OnEnter", function() this.tex:Show() end)
  frame:SetScript("OnLeave", function() this.tex:Hide() end)
  
  -- Label on the left
  local text = frame:CreateFontString(nil, "ARTWORK", "GameFontWhite")
  if pfUI and pfUI.font_default then
    text:SetFont(pfUI.font_default, 12)
  else
    text:SetFont("Fonts\\FRIZQT__.TTF", 12)
  end
  text:SetPoint("LEFT", frame, "LEFT", 5, 0)
  text:SetJustifyH("LEFT")
  if requiresReload then
    text:SetText(label .. " |cffff5555[!]|r")
  else
    text:SetText(label)
  end

  -- Input box on the right
  local eb = CreateFrame("EditBox", nil, frame)
  createSimpleBackdrop(eb)
  eb:SetAutoFocus(false)
  eb:SetHeight(18)
  eb:SetWidth(80)
  eb:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
  eb:SetJustifyH("RIGHT")
  eb:SetTextInsets(5, 5, 0, 0)
  eb:SetFontObject(GameFontNormal)
  eb:SetTextColor(0.2, 1, 0.8, 1)
  eb:SetText(getter() or "")
  eb:SetScript("OnEnterPressed", function()
    local v = tonumber(this:GetText())
    if v then
      setter(v)
      if requiresReload then
        triggerReloadNeeded()
      else
        refreshUI()
      end
    end
    this:ClearFocus()
  end)
  eb:SetScript("OnEscapePressed", function()
    this:SetText(getter() or "")
    this:ClearFocus()
  end)
  table.insert(ConfigRefreshers, function()
    eb:SetText(getter() or "")
  end)
  return y - 23
end

local function addTextField(panel, label, getter, setter, y, width, requiresReload)
  local frame = CreateFrame("Frame", nil, panel)
  frame:SetHeight(22)
  frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, y)
  frame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, y)
  
  frame.tex = frame:CreateTexture(nil, "BACKGROUND")
  frame.tex:SetTexture(1, 1, 1, 0.05)
  frame.tex:SetAllPoints()
  frame.tex:Hide()
  frame:SetScript("OnEnter", function() this.tex:Show() end)
  frame:SetScript("OnLeave", function() this.tex:Hide() end)
  
  local text = frame:CreateFontString(nil, "ARTWORK", "GameFontWhite")
  if pfUI and pfUI.font_default then
    text:SetFont(pfUI.font_default, 12)
  else
    text:SetFont("Fonts\\FRIZQT__.TTF", 12)
  end
  text:SetPoint("LEFT", frame, "LEFT", 5, 0)
  text:SetJustifyH("LEFT")
  if requiresReload then
    text:SetText(label .. " |cffff5555[!]|r")
  else
    text:SetText(label)
  end

  local eb = CreateFrame("EditBox", nil, frame)
  createSimpleBackdrop(eb)
  eb:SetAutoFocus(false)
  eb:SetHeight(18)
  eb:SetWidth(width or 180)
  eb:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
  eb:SetJustifyH("RIGHT")
  eb:SetTextInsets(5, 5, 0, 0)
  eb:SetFontObject(GameFontNormal)
  eb:SetTextColor(0.2, 1, 0.8, 1)
  eb:SetText(getter() or "")
  eb:SetScript("OnEnterPressed", function()
    local v = this:GetText()
    if v and v ~= "" then
      setter(v)
      if requiresReload then
        triggerReloadNeeded()
      else
        refreshUI()
      end
    end
    this:ClearFocus()
  end)
  eb:SetScript("OnEscapePressed", function()
    this:SetText(getter() or "")
    this:ClearFocus()
  end)
  table.insert(ConfigRefreshers, function()
    eb:SetText(getter() or "")
  end)
  return y - 23
end

-- Checkbox field for boolean settings (pfUI style)
local function addBoolField(panel, label, configKey, y, onChanged)
  local frame = CreateFrame("Frame", nil, panel)
  frame:SetHeight(22)
  frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, y)
  frame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, y)
  
  frame.tex = frame:CreateTexture(nil, "BACKGROUND")
  frame.tex:SetTexture(1, 1, 1, 0.05)
  frame.tex:SetAllPoints()
  frame.tex:Hide()
  frame:SetScript("OnEnter", function() this.tex:Show() end)
  frame:SetScript("OnLeave", function() this.tex:Hide() end)
  
  local text = frame:CreateFontString(nil, "ARTWORK", "GameFontWhite")
  if pfUI and pfUI.font_default then
    text:SetFont(pfUI.font_default, 12)
  else
    text:SetFont("Fonts\\FRIZQT__.TTF", 12)
  end
  text:SetPoint("LEFT", frame, "LEFT", 5, 0)
  text:SetJustifyH("LEFT")
  text:SetText(label)
  
  -- Checkbox on the right
  local cb = CreateFrame("CheckButton", newName("SCECheck"), frame, "UICheckButtonTemplate")
  cb:SetNormalTexture("")
  cb:SetPushedTexture("")
  cb:SetHighlightTexture("")
  cb:SetWidth(14)
  cb:SetHeight(14)
  cb:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
  createSimpleBackdrop(cb)
  cb.configKey = configKey
  
  cb:SetScript("OnClick", function()
    if this:GetChecked() then
      StupidComboEnergyDB[this.configKey] = "1"
    else
      StupidComboEnergyDB[this.configKey] = "0"
    end
    refreshUI()
    if onChanged then
      onChanged()
    end
    refreshConfig()
  end)
  
  local function apply()
    local val = StupidComboEnergyDB[configKey]
    cb:SetChecked(val == "1")
  end
  
  apply()
  table.insert(ConfigRefreshers, apply)
  return y - 23
end

local function addDependentBoolField(panel, label, configKey, requiredKey, y)
  local frame = CreateFrame("Frame", nil, panel)
  frame:SetHeight(22)
  frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, y)
  frame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, y)
  
  frame.tex = frame:CreateTexture(nil, "BACKGROUND")
  frame.tex:SetTexture(1, 1, 1, 0.05)
  frame.tex:SetAllPoints()
  frame.tex:Hide()
  frame:SetScript("OnEnter", function() this.tex:Show() end)
  frame:SetScript("OnLeave", function() this.tex:Hide() end)
  
  local text = frame:CreateFontString(nil, "ARTWORK", "GameFontWhite")
  if pfUI and pfUI.font_default then
    text:SetFont(pfUI.font_default, 12)
  else
    text:SetFont("Fonts\\FRIZQT__.TTF", 12)
  end
  text:SetPoint("LEFT", frame, "LEFT", 5, 0)
  text:SetJustifyH("LEFT")
  text:SetText(label)
  
  local cb = CreateFrame("CheckButton", newName("SCECheck"), frame, "UICheckButtonTemplate")
  cb:SetNormalTexture("")
  cb:SetPushedTexture("")
  cb:SetHighlightTexture("")
  cb:SetWidth(14)
  cb:SetHeight(14)
  cb:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
  createSimpleBackdrop(cb)
  cb.configKey = configKey
  
  cb:SetScript("OnClick", function()
    if this:GetChecked() then
      StupidComboEnergyDB[this.configKey] = "1"
      StupidComboEnergyDB[requiredKey] = "1"
    else
      StupidComboEnergyDB[this.configKey] = "0"
    end
    refreshUI()
    refreshConfig()
  end)
  
  local function apply()
    local required = (StupidComboEnergyDB[requiredKey] == "1")
    if not required and StupidComboEnergyDB[configKey] == "1" then
      StupidComboEnergyDB[configKey] = "0"
    end
    cb:SetChecked(StupidComboEnergyDB[configKey] == "1")
    if required then
      if cb.Enable then cb:Enable() else cb:EnableMouse(true) end
      cb:SetAlpha(1)
      text:SetTextColor(1, 1, 1, 1)
    else
      if cb.Disable then cb:Disable() else cb:EnableMouse(false) end
      cb:SetAlpha(0.4)
      text:SetTextColor(0.6, 0.6, 0.6, 0.9)
    end
  end
  
  apply()
  table.insert(ConfigRefreshers, apply)
  return y - 23
end

-- Dropdown field (pfUI style: text on left, small arrow box on right, right-aligned)
local function addCycleField(panel, label, values, getter, setter, y, requiresReload)
  local frame = CreateFrame("Frame", nil, panel)
  frame:SetHeight(22)
  frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, y)
  frame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, y)
  
  frame.tex = frame:CreateTexture(nil, "BACKGROUND")
  frame.tex:SetTexture(1, 1, 1, 0.05)
  frame.tex:SetAllPoints()
  frame.tex:Hide()
  frame:SetScript("OnEnter", function() this.tex:Show() end)
  frame:SetScript("OnLeave", function() this.tex:Hide() end)

  -- Label on the left
  local text = frame:CreateFontString(nil, "ARTWORK", "GameFontWhite")
  if pfUI and pfUI.font_default then
    text:SetFont(pfUI.font_default, 12)
  else
    text:SetFont("Fonts\\FRIZQT__.TTF", 12)
  end
  text:SetPoint("LEFT", frame, "LEFT", 5, 0)
  text:SetJustifyH("LEFT")
  if requiresReload then
    text:SetText(label .. " |cffff5555[!]|r")
  else
    text:SetText(label)
  end

  -- Create dropdown button container
  local btn = CreateFrame("Button", newName("SCEDrop"), frame)
  btn:SetHeight(18)
  btn:SetWidth(120)
  btn:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
  createSimpleBackdrop(btn)
  
  -- Arrow button on the right side of dropdown
  local arrow = CreateFrame("Button", nil, btn)
  arrow:SetWidth(16)
  arrow:SetHeight(16)
  arrow:SetPoint("RIGHT", btn, "RIGHT", -1, 0)
  createSimpleBackdrop(arrow)
  arrow.icon = arrow:CreateTexture(nil, "OVERLAY")
  arrow.icon:SetPoint("TOPLEFT", arrow, "TOPLEFT", 4, -4)
  arrow.icon:SetPoint("BOTTOMRIGHT", arrow, "BOTTOMRIGHT", -4, 4)
  if pfUI and pfUI.media and pfUI.media["img:down"] then
    arrow.icon:SetTexture(pfUI.media["img:down"])
  else
    arrow.icon:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    arrow.icon:SetTexCoord(0.25, 0.75, 0.25, 0.75)
  end
  arrow.icon:SetVertexColor(1, 0.9, 0.1, 0.8)
  
  -- Text showing current selection (right-aligned, to the left of arrow)
  local selText = btn:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  if pfUI and pfUI.font_default then
    selText:SetFont(pfUI.font_default, 11, "OUTLINE")
  else
    selText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
  end
  selText:SetPoint("RIGHT", arrow, "LEFT", -4, 0)
  selText:SetJustifyH("RIGHT")
  btn.selText = selText
  
  -- Menu frame
  local menuframe = CreateFrame("Frame", newName("SCEMenu"), UIParent)
  menuframe:SetFrameStrata("FULLSCREEN_DIALOG")
  menuframe:SetFrameLevel(1000)
  menuframe.elements = {}
  menuframe:Hide()
  createSimpleBackdrop(menuframe)
  
  btn.menuframe = menuframe
  btn.values = values
  btn.getter = getter
  btn.setter = setter
  btn.requiresReload = requiresReload
  
  -- Helper to create menu item function (fixes Lua 5.0 closure issue)
  local function makeMenuFunc(value)
    return function()
      btn.setter(value)
      btn.selText:SetText(value)
      btn.menuframe:Hide()
      if btn.requiresReload then
        triggerReloadNeeded()
      else
        refreshUI()
      end
    end
  end
  
  local function showMenu()
    -- Position menu below button
    menuframe:ClearAllPoints()
    menuframe:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
    menuframe:SetWidth(btn:GetWidth())
    
    -- Clear old elements
    for _, elem in ipairs(menuframe.elements) do
      elem:Hide()
    end
    
    -- Create menu entries
    local currentVal = btn.getter()
    for i, v in ipairs(btn.values) do
      local entry = menuframe.elements[i]
      if not entry then
        entry = CreateFrame("Button", nil, menuframe)
        entry:SetHeight(20)
        entry:SetScript("OnEnter", function() this.hover:Show() end)
        entry:SetScript("OnLeave", function() this.hover:Hide() end)
        
        entry.hover = entry:CreateTexture(nil, "BACKGROUND")
        entry.hover:SetAllPoints()
        entry.hover:SetTexture(0.4, 0.4, 0.4, 0.4)
        entry.hover:Hide()
        
        entry.text = entry:CreateFontString(nil, "OVERLAY", "GameFontWhite")
        if pfUI and pfUI.font_default then
          entry.text:SetFont(pfUI.font_default, 11, "OUTLINE")
        else
          entry.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        end
        entry.text:SetPoint("RIGHT", entry, "RIGHT", -20, 0)
        entry.text:SetJustifyH("RIGHT")
        
        entry.check = entry:CreateTexture(nil, "OVERLAY")
        entry.check:SetPoint("RIGHT", entry, "RIGHT", -2, 0)
        entry.check:SetWidth(16)
        entry.check:SetHeight(16)
        entry.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        
        menuframe.elements[i] = entry
      end
      
      entry:ClearAllPoints()
      entry:SetPoint("TOPLEFT", menuframe, "TOPLEFT", 2, -(i-1)*20 - 2)
      entry:SetPoint("TOPRIGHT", menuframe, "TOPRIGHT", -2, -(i-1)*20 - 2)
      entry.text:SetText(v)
      entry:SetScript("OnClick", makeMenuFunc(v))
      
      if v == currentVal then
        entry.check:Show()
      else
        entry.check:Hide()
      end
      
      entry:Show()
    end
    
    menuframe:SetHeight(table.getn(btn.values) * 20 + 4)
    menuframe:Show()
  end
  
  local function hideMenu()
    menuframe:Hide()
  end
  
  local function toggleMenu()
    if menuframe:IsShown() then
      hideMenu()
    else
      showMenu()
    end
  end
  
  btn:SetScript("OnClick", toggleMenu)
  arrow:SetScript("OnClick", toggleMenu)
  
  -- Auto-hide menu when mouse leaves
  menuframe:SetScript("OnUpdate", function()
    if not MouseIsOver(this, 50, -50, -50, 50) and not MouseIsOver(btn) then
      this:Hide()
    end
  end)
  
  local function apply()
    local val = getter()
    btn.selText:SetText(val or "")
  end
  
  apply()
  table.insert(ConfigRefreshers, apply)
  return y - 23
end

-- Font dropdown (like pfUI's font picker)
local function addFontField(panel, label, getter, setter, y, requiresReload)
  local frame = CreateFrame("Frame", nil, panel)
  frame:SetHeight(22)
  frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, y)
  frame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, y)
  
  frame.tex = frame:CreateTexture(nil, "BACKGROUND")
  frame.tex:SetTexture(1, 1, 1, 0.05)
  frame.tex:SetAllPoints()
  frame.tex:Hide()
  frame:SetScript("OnEnter", function() this.tex:Show() end)
  frame:SetScript("OnLeave", function() this.tex:Hide() end)

  local text = frame:CreateFontString(nil, "ARTWORK", "GameFontWhite")
  if pfUI and pfUI.font_default then
    text:SetFont(pfUI.font_default, 12)
  else
    text:SetFont("Fonts\\FRIZQT__.TTF", 12)
  end
  text:SetPoint("LEFT", frame, "LEFT", 5, 0)
  text:SetJustifyH("LEFT")
  if requiresReload then
    text:SetText(label .. " |cffff5555[!]|r")
  else
    text:SetText(label)
  end

  local btn = CreateFrame("Button", newName("SCEDrop"), frame)
  btn:SetHeight(18)
  btn:SetWidth(150)
  btn:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
  createSimpleBackdrop(btn)
  
  local arrow = CreateFrame("Button", nil, btn)
  arrow:SetWidth(16)
  arrow:SetHeight(16)
  arrow:SetPoint("RIGHT", btn, "RIGHT", -1, 0)
  createSimpleBackdrop(arrow)
  arrow.icon = arrow:CreateTexture(nil, "OVERLAY")
  arrow.icon:SetPoint("TOPLEFT", arrow, "TOPLEFT", 4, -4)
  arrow.icon:SetPoint("BOTTOMRIGHT", arrow, "BOTTOMRIGHT", -4, 4)
  if pfUI and pfUI.media and pfUI.media["img:down"] then
    arrow.icon:SetTexture(pfUI.media["img:down"])
  else
    arrow.icon:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    arrow.icon:SetTexCoord(0.25, 0.75, 0.25, 0.75)
  end
  arrow.icon:SetVertexColor(1, 0.9, 0.1, 0.8)
  
  local selText = btn:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  if pfUI and pfUI.font_default then
    selText:SetFont(pfUI.font_default, 11, "OUTLINE")
  else
    selText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
  end
  selText:SetPoint("RIGHT", arrow, "LEFT", -4, 0)
  selText:SetJustifyH("RIGHT")
  btn.selText = selText
  
  local menuframe = CreateFrame("Frame", newName("SCEMenu"), UIParent)
  menuframe:SetFrameStrata("FULLSCREEN_DIALOG")
  menuframe:SetFrameLevel(1000)
  menuframe.elements = {}
  menuframe:Hide()
  createSimpleBackdrop(menuframe)
  
  btn.menuframe = menuframe
  btn.getter = getter
  btn.setter = setter
  btn.requiresReload = requiresReload
  
  -- Get display name from path
  local function getDisplayName(path)
    for _, entry in ipairs(availableFonts) do
      local p, name = splitString(":", entry)
      if p == path then
        return name
      end
    end
    -- Fallback: extract filename
    local name = string.gsub(path, ".*\\", "")
    name = string.gsub(name, "%.ttf$", "")
    return name
  end
  
  local function makeMenuFunc(path, displayName)
    return function()
      btn.setter(path)
      btn.selText:SetText(displayName)
      btn.menuframe:Hide()
      if btn.requiresReload then
        triggerReloadNeeded()
      else
        refreshUI()
      end
    end
  end
  
  local function showMenu()
    menuframe:ClearAllPoints()
    menuframe:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
    menuframe:SetWidth(btn:GetWidth())
    
    for _, elem in ipairs(menuframe.elements) do
      elem:Hide()
    end
    
    local currentVal = btn.getter()
    for i, entry in ipairs(availableFonts) do
      local path, displayName = splitString(":", entry)
      
      local elem = menuframe.elements[i]
      if not elem then
        elem = CreateFrame("Button", nil, menuframe)
        elem:SetHeight(20)
        elem:SetScript("OnEnter", function() this.hover:Show() end)
        elem:SetScript("OnLeave", function() this.hover:Hide() end)
        
        elem.hover = elem:CreateTexture(nil, "BACKGROUND")
        elem.hover:SetAllPoints()
        elem.hover:SetTexture(0.4, 0.4, 0.4, 0.4)
        elem.hover:Hide()
        
        elem.text = elem:CreateFontString(nil, "OVERLAY", "GameFontWhite")
        elem.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        elem.text:SetPoint("RIGHT", elem, "RIGHT", -20, 0)
        elem.text:SetJustifyH("RIGHT")
        
        elem.check = elem:CreateTexture(nil, "OVERLAY")
        elem.check:SetPoint("RIGHT", elem, "RIGHT", -2, 0)
        elem.check:SetWidth(16)
        elem.check:SetHeight(16)
        elem.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        
        menuframe.elements[i] = elem
      end
      
      elem:ClearAllPoints()
      elem:SetPoint("TOPLEFT", menuframe, "TOPLEFT", 2, -(i-1)*20 - 2)
      elem:SetPoint("TOPRIGHT", menuframe, "TOPRIGHT", -2, -(i-1)*20 - 2)
      elem.text:SetText(displayName)
      elem:SetScript("OnClick", makeMenuFunc(path, displayName))
      
      if path == currentVal then
        elem.check:Show()
      else
        elem.check:Hide()
      end
      
      elem:Show()
    end
    
    menuframe:SetHeight(table.getn(availableFonts) * 20 + 4)
    menuframe:Show()
  end
  
  local function toggleMenu()
    if menuframe:IsShown() then
      menuframe:Hide()
    else
      showMenu()
    end
  end
  
  btn:SetScript("OnClick", toggleMenu)
  arrow:SetScript("OnClick", toggleMenu)
  
  menuframe:SetScript("OnUpdate", function()
    if not MouseIsOver(this, 50, -50, -50, 50) and not MouseIsOver(btn) then
      this:Hide()
    end
  end)
  
  local function apply()
    local val = getter()
    btn.selText:SetText(getDisplayName(val or ""))
  end
  
  apply()
  table.insert(ConfigRefreshers, apply)
  return y - 23
end

local function addColorField(panel, label, getter, setter, y, requiresReload)
  local frame = CreateFrame("Frame", nil, panel)
  frame:SetHeight(22)
  frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, y)
  frame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, y)
  
  frame.tex = frame:CreateTexture(nil, "BACKGROUND")
  frame.tex:SetTexture(1, 1, 1, 0.05)
  frame.tex:SetAllPoints()
  frame.tex:Hide()
  frame:SetScript("OnEnter", function() this.tex:Show() end)
  frame:SetScript("OnLeave", function() this.tex:Hide() end)

  local text = frame:CreateFontString(nil, "ARTWORK", "GameFontWhite")
  if pfUI and pfUI.font_default then
    text:SetFont(pfUI.font_default, 12)
  else
    text:SetFont("Fonts\\FRIZQT__.TTF", 12)
  end
  text:SetPoint("LEFT", frame, "LEFT", 5, 0)
  text:SetJustifyH("LEFT")
  if requiresReload then
    text:SetText(label .. " |cffff5555[!]|r")
  else
    text:SetText(label)
  end

  -- Color swatch button
  local btn = CreateFrame("Button", newName("SCEButton"), frame)
  btn:SetHeight(18)
  btn:SetWidth(36)
  btn:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
  createSimpleBackdrop(btn)
  
  btn.tex = btn:CreateTexture(nil, "OVERLAY")
  btn.tex:SetPoint("TOPLEFT", btn, "TOPLEFT", 3, -3)
  btn.tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3, 3)
  setSwatch(btn, getter())

  -- Hex input box (pfUI style - to the left of swatch)
  local hexBox = CreateFrame("EditBox", newName("SCEHex"), frame)
  hexBox:SetHeight(18)
  hexBox:SetWidth(60)
  hexBox:SetPoint("RIGHT", btn, "LEFT", -4, 0)
  hexBox:SetAutoFocus(false)
  hexBox:SetMaxLetters(6)
  createSimpleBackdrop(hexBox)
  
  -- Set font
  if pfUI and pfUI.font_default then
    hexBox:SetFont(pfUI.font_default, 11, "OUTLINE")
  else
    hexBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
  end
  hexBox:SetTextColor(1, 1, 1, 1)
  hexBox:SetText(colorToHex(getter()))
  hexBox:SetJustifyH("CENTER")
  hexBox:SetTextInsets(4, 4, 0, 0)
  
  -- Store references for updating
  btn.hexBox = hexBox
  hexBox.btn = btn
  hexBox.getter = getter
  hexBox.setter = setter
  hexBox.requiresReload = requiresReload
  
  hexBox:SetScript("OnEnterPressed", function()
    local hex = this:GetText()
    local currentColor = this.getter()
    local newColor = hexToColor(hex, currentColor[4])
    if newColor then
      this.setter(newColor)
      setSwatch(this.btn, newColor)
      if this.requiresReload then
        triggerReloadNeeded()
      else
        refreshUI()
      end
    else
      -- Invalid hex, reset to current value
      this:SetText(colorToHex(this.getter()))
    end
    this:ClearFocus()
  end)
  
  hexBox:SetScript("OnEscapePressed", function()
    this:SetText(colorToHex(this.getter()))
    this:ClearFocus()
  end)

  btn:SetScript("OnClick", function()
    local cur = getter()
    openColorPicker(cur, function(newc)
      setter(newc)
      setSwatch(btn, newc)
      if btn.hexBox then
        btn.hexBox:SetText(colorToHex(newc))
      end
      if requiresReload then
        triggerReloadNeeded()
      else
        refreshUI()
      end
    end)
  end)

  table.insert(ConfigRefreshers, function()
    local c = getter()
    setSwatch(btn, c)
    if btn.hexBox then
      btn.hexBox:SetText(colorToHex(c))
    end
  end)

  return y - 23
end

local function showConfigPanel(name)
  for k, p in pairs(ConfigPanels) do
    if k == name then
      p:Show()
      if p.scroll and p.scroll.SetVerticalScroll then
        p.scroll:SetVerticalScroll(0)
        local child = p.scroll:GetScrollChild()
        if child then
          local w = p.scroll:GetWidth()
          if not w or w < 40 then w = 480 end
          child:SetWidth(w)
        end
      end
      -- Highlight selected button (pfUI style)
      if ConfigMenuButtons[k] then
        local btn = ConfigMenuButtons[k]
        if btn.text then
          btn.text:SetTextColor(0.2, 1, 0.8, 1)
        end
        if btn.bg and btn.bg.SetGradientAlpha then
          btn.bg:SetTexture(1, 1, 1, 1)
          btn.bg:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0, 1, 1, 1, 0.05)
        end
      end
    else
      p:Hide()
      -- Unhighlight button
      if ConfigMenuButtons[k] then
        local btn = ConfigMenuButtons[k]
        if btn.text then
          btn.text:SetTextColor(1, 1, 1, 1)
        end
        if btn.bg then
          btn.bg:SetTexture(0, 0, 0, 0)
        end
      end
    end
  end
end

local function buildEnergyPanel(parent)
  local y = -20
  y = addBoolField(parent, "Enable Energy Bar", "showEnergyBar", y)
  y = addBoolField(parent, "Grouped Mode", "grouped", y)
  y = addBoolField(parent, "Energy First (grouped)", "energyFirst", y)
  y = addNumberField(parent, "Position X", function() return StupidComboEnergyDB.x end, function(v) StupidComboEnergyDB.x = v end, y)
  y = addNumberField(parent, "Position Y", function() return StupidComboEnergyDB.y end, function(v) StupidComboEnergyDB.y = v end, y)
  y = addNumberField(parent, "Width", function() return StupidComboEnergyDB.width end, function(v) StupidComboEnergyDB.width = v end, y)
  y = addNumberField(parent, "Height", function() return StupidComboEnergyDB.heightEnergy end, function(v) StupidComboEnergyDB.heightEnergy = v end, y)
  y = addNumberField(parent, "Gap (when grouped)", function() return StupidComboEnergyDB.gap end, function(v) StupidComboEnergyDB.gap = v end, y)
  y = addBoolField(parent, "Gap Line (grouped)", "groupGapLine", y)
  y = addNumberField(parent, "Gap Line Size (0=auto)", function() return StupidComboEnergyDB.groupGapLineSize end, function(v) StupidComboEnergyDB.groupGapLineSize = v end, y)
  y = addColorField(parent, "Gap Line Color", function() return StupidComboEnergyDB.groupGapLineColor end, function(c) StupidComboEnergyDB.groupGapLineColor = c end, y)
  y = addCycleField(parent, "Frame Strata", {"BACKGROUND","LOW","MEDIUM","HIGH","DIALOG","FULLSCREEN","FULLSCREEN_DIALOG","TOOLTIP"}, function() return StupidComboEnergyDB.frameStrata end, function(v) StupidComboEnergyDB.frameStrata = v end, y)
  y = addNumberField(parent, "Frame Level", function() return StupidComboEnergyDB.frameLevel end, function(v) StupidComboEnergyDB.frameLevel = v end, y)
  y = addCycleField(parent, "Bar Style", {"solid","gradient"}, function() return StupidComboEnergyDB.energyStyle end, function(v) StupidComboEnergyDB.energyStyle = v end, y)
  y = addColorField(parent, "Fill Color", function() return StupidComboEnergyDB.energyFill end, function(c) StupidComboEnergyDB.energyFill = c end, y)
  y = addColorField(parent, "Gradient Color", function() return StupidComboEnergyDB.energyFill2 end, function(c) StupidComboEnergyDB.energyFill2 = c end, y)
  y = addColorField(parent, "Empty Color", function() return StupidComboEnergyDB.energyEmpty end, function(c) StupidComboEnergyDB.energyEmpty = c end, y)
  y = addColorField(parent, "Rage Fill Color", function() return StupidComboEnergyDB.rageFill end, function(c) StupidComboEnergyDB.rageFill = c end, y)
  y = addColorField(parent, "Rage Gradient Color", function() return StupidComboEnergyDB.rageFill2 end, function(c) StupidComboEnergyDB.rageFill2 = c end, y)
  y = addColorField(parent, "Rage Empty Color", function() return StupidComboEnergyDB.rageEmpty end, function(c) StupidComboEnergyDB.rageEmpty = c end, y)
  y = addNumberField(parent, "Border Size", function() return StupidComboEnergyDB.energyBorderSize end, function(v) StupidComboEnergyDB.energyBorderSize = v end, y)
  y = addColorField(parent, "Border Color", function() return StupidComboEnergyDB.energyBorderColor end, function(c) StupidComboEnergyDB.energyBorderColor = c end, y)
  y = addBoolField(parent, "Show Energy Ticker", "showEnergyTicker", y)
  y = addBoolField(parent, "Ticker Glow Effect", "energyTickerGlow", y)
  y = addNumberField(parent, "Ticker Width", function() return StupidComboEnergyDB.energyTickerWidth end, function(v) StupidComboEnergyDB.energyTickerWidth = v end, y)
  y = addColorField(parent, "Ticker Color", function() return StupidComboEnergyDB.energyTickerColor end, function(c) StupidComboEnergyDB.energyTickerColor = c end, y)
  y = addFontField(parent, "Font", function() return StupidComboEnergyDB.energyTextFont end, function(v) StupidComboEnergyDB.energyTextFont = v end, y, true)
  y = addNumberField(parent, "Font Size", function() return StupidComboEnergyDB.energyTextSize end, function(v) StupidComboEnergyDB.energyTextSize = v end, y)
  y = addColorField(parent, "Font Color", function() return StupidComboEnergyDB.energyTextColor end, function(c) StupidComboEnergyDB.energyTextColor = c end, y)
  y = addNumberField(parent, "Font Offset X", function() return StupidComboEnergyDB.energyTextOffsetX end, function(v) StupidComboEnergyDB.energyTextOffsetX = v end, y)
  y = addNumberField(parent, "Font Offset Y", function() return StupidComboEnergyDB.energyTextOffsetY end, function(v) StupidComboEnergyDB.energyTextOffsetY = v end, y)
  return y
end

local function buildComboPanel(parent)
  local y = -20
  y = addBoolField(parent, "Enable Combo Bar", "showComboBar", y)
  y = addBoolField(parent, "Hide When Empty", "hideComboWhenEmpty", y)
  y = addDependentBoolField(parent, "Show Only Active Points (requires Hide When Empty)", "showOnlyActiveCombo", "hideComboWhenEmpty", y)
  y = addNumberField(parent, "Width", function() return StupidComboEnergyDB.width end, function(v) StupidComboEnergyDB.width = v end, y)
  y = addNumberField(parent, "Height", function() return StupidComboEnergyDB.heightCP end, function(v) StupidComboEnergyDB.heightCP = v end, y)
  y = addCycleField(parent, "Color Mode", {"unified","finisher","split"}, function() return StupidComboEnergyDB.cpColorMode end, function(v) StupidComboEnergyDB.cpColorMode = v end, y)
  y = addColorField(parent, "Base Color (1-4 / 1-2)", function() return StupidComboEnergyDB.cpFillBase end, function(c) StupidComboEnergyDB.cpFillBase = c end, y)
  y = addColorField(parent, "Base Gradient 2", function() return StupidComboEnergyDB.cpFillBase2 end, function(c) StupidComboEnergyDB.cpFillBase2 = c end, y)
  y = addColorField(parent, "Mid Color (3-4)", function() return StupidComboEnergyDB.cpFillMid end, function(c) StupidComboEnergyDB.cpFillMid = c end, y)
  y = addColorField(parent, "Mid Gradient 2", function() return StupidComboEnergyDB.cpFillMid2 end, function(c) StupidComboEnergyDB.cpFillMid2 = c end, y)
  y = addColorField(parent, "Finisher Color (5)", function() return StupidComboEnergyDB.cpFillFinisher end, function(c) StupidComboEnergyDB.cpFillFinisher = c end, y)
  y = addColorField(parent, "Finisher Gradient 2", function() return StupidComboEnergyDB.cpFillFinisher2 end, function(c) StupidComboEnergyDB.cpFillFinisher2 = c end, y)
  y = addCycleField(parent, "Separator Style", {"gap","gapline","border"}, function() return StupidComboEnergyDB.cpSeparatorStyle end, function(v) StupidComboEnergyDB.cpSeparatorStyle = v end, y)
  y = addNumberField(parent, "Segment Gap (gap/gapline)", function() return StupidComboEnergyDB.cpGap end, function(v) StupidComboEnergyDB.cpGap = v end, y)
  y = addNumberField(parent, "Separator Width", function() return StupidComboEnergyDB.cpSeparatorWidth end, function(v) StupidComboEnergyDB.cpSeparatorWidth = v end, y)
  y = addColorField(parent, "Separator Color", function() return StupidComboEnergyDB.cpSeparatorColor end, function(c) StupidComboEnergyDB.cpSeparatorColor = c end, y)
  y = addCycleField(parent, "Bar Style", {"solid","gradient"}, function() return StupidComboEnergyDB.cpStyle end, function(v) StupidComboEnergyDB.cpStyle = v end, y)
  y = addColorField(parent, "Fill Color", function() return StupidComboEnergyDB.cpFill end, function(c) StupidComboEnergyDB.cpFill = c end, y)
  y = addColorField(parent, "Gradient Color", function() return StupidComboEnergyDB.cpFill2 end, function(c) StupidComboEnergyDB.cpFill2 = c end, y)
  y = addColorField(parent, "Empty Color", function() return StupidComboEnergyDB.cpEmpty end, function(c) StupidComboEnergyDB.cpEmpty = c end, y)
  y = addNumberField(parent, "Border Size", function() return StupidComboEnergyDB.cpBorderSize end, function(v) StupidComboEnergyDB.cpBorderSize = v end, y)
  y = addColorField(parent, "Border Color", function() return StupidComboEnergyDB.cpBorderColor end, function(c) StupidComboEnergyDB.cpBorderColor = c end, y)
  return y
end

local function buildSettingsPanel(parent)
  local y = -20
  y = addBoolField(parent, "Enable Debug Logs", "debugEnabled", y, function()
    if SCE.applyDebugSetting then
      SCE.applyDebugSetting()
    end
  end)
  return y
end

local function buildAboutPanel(parent)
  local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", parent, "TOP", 0, -40)
  if pfUI and pfUI.font_default then
    title:SetFont(pfUI.font_default, 48, "OUTLINE")
  else
    title:SetFont("Fonts\\FRIZQT__.TTF", 48, "OUTLINE")
  end
  title:SetText("SCE")
  title:SetTextColor(0.2, 1, 0.8, 1)

  local infoFont = (pfUI and pfUI.font_default) or "Fonts\\FRIZQT__.TTF"
  local labelX = 180
  local valueX = 340
  local startY = -130
  local stepY = 22

  local function addInfoRow(labelText, row)
    local y = startY - (row * stepY)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    label:SetFont(infoFont, 12)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", labelX, y)
    label:SetText(labelText .. ":")

    local value = parent:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    value:SetFont(infoFont, 12)
    value:SetPoint("TOPLEFT", parent, "TOPLEFT", valueX, y)
    value:SetText("")
    return value
  end

  local versionValue = addInfoRow("Version", 0)
  local resValue = addInfoRow("Resolution", 1)
  local scaleValue = addInfoRow("Scaling", 2)
  local clientValue = addInfoRow("Gameclient", 3)
  local localeValue = addInfoRow("Language", 4)

  local function updateAbout()
    local version = "unknown"
    if GetAddOnMetadata then
      version = GetAddOnMetadata("StupidComboEnergy", "Version") or version
    end
    local resolution = GetCVar("gxResolution") or "unknown"
    local scale = GetCVar("uiScale") or "1"
    local client = "unknown"
    if GetBuildInfo then
      local v = GetBuildInfo()
      if v and v ~= "" then
        client = v
      end
    end
    local locale = (GetLocale and GetLocale()) or "unknown"

    versionValue:SetText(version)
    resValue:SetText(resolution)
    scaleValue:SetText(scale)
    clientValue:SetText(client)
    localeValue:SetText(locale)
  end

  updateAbout()
  table.insert(ConfigRefreshers, updateAbout)
  return -260
end

local function buildConfigFrame()
  if ConfigFrame then return end
  if SCE.debugMsg then SCE.debugMsg("Build config frame start") end
  ConfigFrame = CreateFrame("Frame", "StupidComboEnergyConfig", UIParent)
  SCE.ConfigFrame = ConfigFrame
  ConfigFrame:SetWidth(720)
  ConfigFrame:SetHeight(430)
  ConfigFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  ConfigFrame:SetFrameStrata("DIALOG")
  ConfigFrame:SetMovable(true)
  ConfigFrame:EnableMouse(true)
  ConfigFrame:RegisterForDrag("LeftButton")
  ConfigFrame:SetScript("OnDragStart", function()
    this:StartMoving()
  end)
  ConfigFrame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
  end)
  
  -- Use pfUI styling if available, otherwise fallback to basic backdrop
  if pfUI and pfUI.api and pfUI.api.CreateBackdrop then
    pfUI.api.CreateBackdrop(ConfigFrame, nil, true, 0.92)
    if pfUI.api.CreateBackdropShadow then
      pfUI.api.CreateBackdropShadow(ConfigFrame)
    end
  elseif ConfigFrame.SetBackdrop then
    ConfigFrame:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 12,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    ConfigFrame:SetBackdropColor(0.04, 0.1, 0.1, 0.92)
    ConfigFrame:SetBackdropBorderColor(0, 0.6, 0.6, 0.8)
  end
  
  table.insert(UISpecialFrames, "StupidComboEnergyConfig")

  -- Title directly on ConfigFrame (pfUI style)
  local title = ConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetFontObject(GameFontWhite)
  title:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 8, -8)
  title:SetJustifyH("LEFT")
  if pfUI and pfUI.font_default then
    title:SetFont(pfUI.font_default, 12)
  else
    title:SetFont("Fonts\\FRIZQT__.TTF", 12)
  end
  title:SetText("StupidComboEnergy Settings")

  ReloadNotice = ConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  ReloadNotice:SetPoint("TOPRIGHT", ConfigFrame, "TOPRIGHT", -30, -8)
  ReloadNotice:SetText("")
  ReloadNotice:Hide()

  -- Reset Position button (bottom left)
  local resetPosBtn = CreateFrame("Button", newName("SCEButton"), ConfigFrame, "UIPanelButtonTemplate")
  resetPosBtn:SetText("Reset Position")
  resetPosBtn:SetWidth(100)
  resetPosBtn:SetHeight(20)
  resetPosBtn:SetPoint("BOTTOMLEFT", ConfigFrame, "BOTTOMLEFT", 7, 10)
  resetPosBtn:SetScript("OnClick", function()
    local db = StupidComboEnergyDB
    local defaults = SCE.defaults or {}
    -- Reset grouped position
    db.point = defaults.point
    db.relativePoint = defaults.relativePoint
    db.x = defaults.x
    db.y = defaults.y
    -- Reset separate positions
    db.energyPoint = defaults.energyPoint
    db.energyRelativePoint = defaults.energyRelativePoint
    db.energyX = defaults.energyX
    db.energyY = defaults.energyY
    db.cpPoint = defaults.cpPoint
    db.cpRelativePoint = defaults.cpRelativePoint
    db.cpX = defaults.cpX
    db.cpY = defaults.cpY
    layout()
    printMsg("Reset positions to default.")
  end)
  if pfUI and pfUI.api then
    local skinFunc = pfUI.api.SkinButton or (pfUI.skins and pfUI.skins.SkinButton)
    if skinFunc then
      skinFunc(resetPosBtn, .2, 1, .8)
    end
  end

  -- Unlock/Lock toggle button (pfUI style)
  local lockBtn = CreateFrame("Button", newName("SCEButton"), ConfigFrame, "UIPanelButtonTemplate")
  lockBtn:SetWidth(60)
  lockBtn:SetHeight(20)
  lockBtn:SetPoint("LEFT", resetPosBtn, "RIGHT", 5, 0)
  lockBtn:SetScript("OnClick", function()
    -- Toggle: if currently "1" (locked), unlock; otherwise lock
    local locked = (StupidComboEnergyDB.locked ~= "1")
    setLocked(locked)
    if locked then
      printMsg("Locked.")
    else
      printMsg("Unlocked. Drag to move.")
    end
  end)
  ConfigFrame.lockButton = lockBtn
  
  -- Set initial text based on current lock state
  if StupidComboEnergyDB.locked == "1" then
    lockBtn:SetText("Unlock")
  else
    lockBtn:SetText("Lock")
  end
  
  -- Add refresher to update button text when config is opened
  table.insert(ConfigRefreshers, function()
    if StupidComboEnergyDB.locked == "1" then
      lockBtn:SetText("Unlock")
    else
      lockBtn:SetText("Lock")
    end
  end)
  
  if pfUI and pfUI.api then
    local skinFunc = pfUI.api.SkinButton or (pfUI.skins and pfUI.skins.SkinButton)
    if skinFunc then
      skinFunc(lockBtn, .2, 1, .8)
    end
  end

  -- Close button (pfUI style)
  local close = CreateFrame("Button", newName("SCEButton"), ConfigFrame)
  close:SetPoint("TOPRIGHT", ConfigFrame, "TOPRIGHT", -7, -7)
  close:SetHeight(10)
  close:SetWidth(10)
  if pfUI and pfUI.api and pfUI.api.CreateBackdrop then
    pfUI.api.CreateBackdrop(close)
  end
  close.texture = close:CreateTexture(nil, "OVERLAY")
  close.texture:SetAllPoints(close)
  if pfUI and pfUI.media and pfUI.media["img:close"] then
    close.texture:SetTexture(pfUI.media["img:close"])
  else
    close.texture:SetTexture(1, 0.25, 0.25, 1)
  end
  close.texture:SetVertexColor(1, 0.25, 0.25, 1)
  close:SetScript("OnEnter", function()
    if this.backdrop and this.backdrop.SetBackdropBorderColor then
      this.backdrop:SetBackdropBorderColor(1, 0.25, 0.25, 1)
    end
  end)
  close:SetScript("OnLeave", function()
    if pfUI and pfUI.api and pfUI.api.CreateBackdrop then
      pfUI.api.CreateBackdrop(this)
    end
  end)
  close:SetScript("OnClick", function() ConfigFrame:Hide() end)

  local menu = CreateFrame("Frame", nil, ConfigFrame)
  menu:SetWidth(150)
  menu:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 7, -25)
  menu:SetPoint("BOTTOMLEFT", ConfigFrame, "BOTTOMLEFT", 7, 37)
  
  -- Menu background (no visible border, pfUI style)
  menu.bg = menu:CreateTexture(nil, "BACKGROUND")
  menu.bg:SetAllPoints()
  menu.bg:SetTexture(0, 0, 0, 0.2)

  local function addMenuButton(text, panelName, buildFunc, order)
    local btn = CreateFrame("Button", newName("SCEButton"), menu)
    btn:SetHeight(28)
    btn:SetWidth(140)
    btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -(order - 1) * 28)
    
    -- Background texture for highlight
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetTexture(0, 0, 0, 0)
    
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", btn, "LEFT", 8, 0)
    label:SetJustifyH("LEFT")
    if pfUI and pfUI.font_default then
      label:SetFont(pfUI.font_default, 12)
    else
      label:SetFont("Fonts\\FRIZQT__.TTF", 12)
    end
    label:SetTextColor(1, 1, 1, 1)
    label:SetText(text)
    btn.text = label
    
    btn:SetScript("OnClick", function()
      showConfigPanel(panelName)
    end)
    ConfigMenuButtons[panelName] = btn

    local container = CreateFrame("Frame", nil, ConfigFrame)
    container:SetPoint("TOPLEFT", menu, "TOPRIGHT", 0, 0)
    container:SetPoint("BOTTOMRIGHT", ConfigFrame, "BOTTOMRIGHT", -7, 37)
    
    -- Content area background (subtle, pfUI style)
    container.bg = container:CreateTexture(nil, "BACKGROUND")
    container.bg:SetAllPoints()
    container.bg:SetTexture(1, 1, 1, 0.05)

    local scroll, content
    if pfUI and pfUI.api and pfUI.api.CreateScrollFrame and pfUI.api.CreateScrollChild then
      local ok, s = pcall(pfUI.api.CreateScrollFrame, newName("SCEScroll"), container)
      if ok and s then
        scroll = s
        scroll:SetPoint("TOPLEFT", container, "TOPLEFT", 2, -2)
        scroll:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -2, 2)
        local okChild, child = pcall(pfUI.api.CreateScrollChild, newName("SCEContent"), scroll)
        if okChild and child then
          content = child
        end
      end
    end

    if not scroll then
      scroll = CreateFrame("ScrollFrame", newName("SCEScroll"), container, "UIPanelScrollFrameTemplate")
      scroll:SetPoint("TOPLEFT", container, "TOPLEFT", 2, -2)
      scroll:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -26, 2)
      content = CreateFrame("Frame", newName("SCEContent"), scroll)
      content:SetWidth(1)
      content:SetHeight(1)
      scroll:SetScrollChild(content)
    end
    container.scroll = scroll

    local function updateContentWidth()
      if not content.SetWidth then return end
      local w = scroll:GetWidth() or 480
      if not w or w < 40 then
        w = 480
      end
      content:SetWidth(w)
    end
    
    -- pfUI's scroll frame doesn't need OnShow/OnSizeChanged for width
    if not (pfUI and pfUI.api and pfUI.api.CreateScrollFrame) then
      scroll:SetScript("OnShow", updateContentWidth)
      scroll:SetScript("OnSizeChanged", updateContentWidth)
    end
    updateContentWidth()

    container:Hide()
    ConfigPanels[panelName] = container
    local lastY = buildFunc(content) or -20
    content:SetHeight(math.abs(lastY) + 40)
  end

  addMenuButton("About", "about", buildAboutPanel, 1)
  addMenuButton("Settings", "settings", buildSettingsPanel, 2)
  addMenuButton("Energy Bar", "energy", buildEnergyPanel, 3)
  addMenuButton("Combo Points", "combo", buildComboPanel, 4)

  showConfigPanel("about")
  SCE.ConfigFrame = ConfigFrame
  if SCE.debugMsg then SCE.debugMsg("Build config frame complete") end
end

local function toggleConfig()
  if SCE.debugMsg then SCE.debugMsg("Toggle config") end
  buildConfigFrame()
  if ConfigFrame and ConfigFrame:IsShown() then
    ConfigFrame:Hide()
    if SCE.debugMsg then SCE.debugMsg("Config hidden") end
  elseif ConfigFrame then
    for _, fn in ipairs(ConfigRefreshers) do
      fn()
    end
    updateReloadLabel()
    ConfigFrame:Show()
    if SCE.debugMsg then SCE.debugMsg("Config shown") end
  end
end

SCE.ConfigFrame = ConfigFrame
SCE.ConfigRefreshers = ConfigRefreshers
SCE.updateReloadLabel = updateReloadLabel
SCE.triggerReloadNeeded = triggerReloadNeeded
function SCE.clearReloadNeeded()
  ReloadNeeded = false
  updateReloadLabel()
end
SCE.buildConfigFrame = buildConfigFrame
SCE.toggleConfig = toggleConfig

if SCE.debugMsg then
  SCE.debugMsg("Loaded module: gui.lua")
end
