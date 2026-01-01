StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS
SCE._moduleLoaded = SCE._moduleLoaded or {}
SCE._moduleLoaded.layout = true

-- Don't cache SCE.defaults or SCE.clamp at load time - access them when needed
local UnitPowerType = UnitPowerType
local UnitManaMax = UnitManaMax
local UnitMana = UnitMana
local CreateFrame = CreateFrame
local UIParent = UIParent

local function setSize(frame, w, h)
  if frame.SetSize then
    frame:SetSize(w, h)
  else
    frame:SetWidth(w)
    frame:SetHeight(h)
  end
end

local function setColor(texOrBar, c)
  if texOrBar.SetStatusBarColor then
    texOrBar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
  elseif texOrBar.SetVertexColor then
    texOrBar:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
  end
end

local function setBarColor(bar, style, c1, c2)
  if not bar then return end
  
  if style == "gradient" and c2 then
    bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    local tex = bar:GetStatusBarTexture()
    if tex then
      tex:SetVertexColor(c1[1], c1[2], c1[3], c1[4] or 1)
      if tex.SetGradientAlpha then
        tex:SetGradientAlpha("HORIZONTAL",
          c1[1], c1[2], c1[3], c1[4] or 1,
          c2[1], c2[2], c2[3], c2[4] or 1)
      elseif tex.SetGradient then
        tex:SetGradient("HORIZONTAL", c1[1], c1[2], c1[3], c2[1], c2[2], c2[3])
      end
    end
  else
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    setColor(bar, c1)
  end
end

local function createBorder(parent, layer)
  local b = {}
  b.parent = parent
  local l = layer or "BORDER"
  b.top = parent:CreateTexture(nil, l)
  b.bottom = parent:CreateTexture(nil, l)
  b.left = parent:CreateTexture(nil, l)
  b.right = parent:CreateTexture(nil, l)
  return b
end

local function applyBorder(border, size, c)
  if not border or not border.parent then return end
  size = size or 0
  if size <= 0 then
    border.top:Hide()
    border.bottom:Hide()
    border.left:Hide()
    border.right:Hide()
    return
  end

  local r, g, b = c[1] or 0, c[2] or 0, c[3] or 0
  local a = c[4] or 1
  local p = border.parent

  border.top:Show(); border.bottom:Show(); border.left:Show(); border.right:Show()

  border.top:SetTexture(r, g, b, a)
  border.top:ClearAllPoints()
  border.top:SetPoint("TOPLEFT", p, "TOPLEFT", -size, size)
  border.top:SetPoint("TOPRIGHT", p, "TOPRIGHT", size, size)
  border.top:SetHeight(size)

  border.bottom:SetTexture(r, g, b, a)
  border.bottom:ClearAllPoints()
  border.bottom:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", -size, -size)
  border.bottom:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", size, -size)
  border.bottom:SetHeight(size)

  border.left:SetTexture(r, g, b, a)
  border.left:ClearAllPoints()
  border.left:SetPoint("TOPLEFT", p, "TOPLEFT", -size, 0)
  border.left:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", -size, 0)
  border.left:SetWidth(size)

  border.right:SetTexture(r, g, b, a)
  border.right:ClearAllPoints()
  border.right:SetPoint("TOPRIGHT", p, "TOPRIGHT", size, 0)
  border.right:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", size, 0)
  border.right:SetWidth(size)
end

local function isEnergy()
  if UnitPowerType then
    local ptype, ptoken = UnitPowerType("player")
    if ptype ~= nil then
      return ptype == 3 or ptoken == "ENERGY"
    end
  end
  local maxv = UnitManaMax("player") or 0
  return maxv <= 120
end

local UI = CreateFrame("Frame", "StupidComboEnergyFrame", UIParent)
UI:SetFrameStrata("DIALOG")
if UI.SetFrameLevel then
  UI:SetFrameLevel(200)
end
UI:Hide()
UI:RegisterForDrag("LeftButton")

UI.bg = UI:CreateTexture(nil, "BACKGROUND")
UI.bg:SetAllPoints()

local Energy = CreateFrame("StatusBar", nil, UI)
Energy:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
Energy:RegisterForDrag("LeftButton")

Energy.bg = Energy:CreateTexture(nil, "BACKGROUND")
Energy.bg:SetAllPoints()
Energy.text = Energy:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

Energy.ticker = Energy:CreateTexture(nil, "OVERLAY")
Energy.ticker:Hide()

local CP = CreateFrame("Frame", nil, UI)
CP.segs = {}
CP:RegisterForDrag("LeftButton")
local EnergyBorder = createBorder(Energy, "BORDER")
local CPBorder = createBorder(CP, "BORDER")

CP.separators = {}
for i = 1, 4 do
  local sepFrame = CreateFrame("Frame", nil, CP)
  sepFrame:SetFrameLevel((CP:GetFrameLevel() or 0) + 10)
  local sep = sepFrame:CreateTexture(nil, "OVERLAY")
  sep:SetAllPoints(sepFrame)
  sepFrame:Hide()
  sepFrame.tex = sep
  CP.separators[i] = sepFrame
end

SCE.UI = UI
SCE.Energy = Energy
SCE.CP = CP
SCE.EnergyBorder = EnergyBorder
SCE.CPBorder = CPBorder
SCE.setColor = setColor
SCE.setBarColor = setBarColor
SCE.applyBorder = applyBorder
SCE.isEnergy = isEnergy

local function layout()
  local db = StupidComboEnergyDB
  
  UI:SetFrameStrata(db.frameStrata or "DIALOG")
  Energy:SetFrameStrata(db.frameStrata or "DIALOG")
  CP:SetFrameStrata(db.frameStrata or "DIALOG")
  if UI.SetFrameLevel and db.frameLevel then
    UI:SetFrameLevel(db.frameLevel)
  end
  if Energy.SetFrameLevel and db.frameLevel then
    Energy:SetFrameLevel(db.frameLevel)
    CP:SetFrameLevel(db.frameLevel)
  end
  
  UI:Hide()
  
  Energy:SetParent(UIParent)
  CP:SetParent(UIParent)
  Energy:Show()
  CP:Show()
  
  Energy:ClearAllPoints()
  CP:ClearAllPoints()
  
  if db.grouped == "1" then
    local mainX = db.x or 0
    local mainY = db.y or 0
    if db.energyFirst == "1" then
      local energyOffset = (db.heightCP + db.gap) / 2
      local cpOffset = (db.heightEnergy + db.gap) / 2
      
      Energy:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY + energyOffset)
      CP:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY - cpOffset)
      if Energy.SetFrameLevel and CP.SetFrameLevel then
        Energy:SetFrameLevel((db.frameLevel or 200) + 2)
        CP:SetFrameLevel((db.frameLevel or 200) + 1)
      end
    else
      local cpOffset = (db.heightEnergy + db.gap) / 2
      local energyOffset = (db.heightCP + db.gap) / 2
      
      CP:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY + cpOffset)
      Energy:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY - energyOffset)
      if Energy.SetFrameLevel and CP.SetFrameLevel then
        CP:SetFrameLevel((db.frameLevel or 200) + 2)
        Energy:SetFrameLevel((db.frameLevel or 200) + 1)
      end
    end
  else
    Energy:SetPoint(db.energyPoint, UIParent, db.energyRelativePoint, db.energyX, db.energyY)
    CP:SetPoint(db.cpPoint, UIParent, db.cpRelativePoint, db.cpX, db.cpY)
    
    if Energy.SetFrameLevel and CP.SetFrameLevel then
      Energy:SetFrameLevel(db.frameLevel or 200)
      CP:SetFrameLevel(db.frameLevel or 200)
    end
  end
  
  setSize(Energy, db.width, db.heightEnergy)
  setSize(CP, db.width, db.heightCP)
  
  Energy:SetHeight(db.heightEnergy)
  Energy.text:ClearAllPoints()
  Energy.text:SetPoint("CENTER", Energy, "CENTER", db.energyTextOffsetX or 0, db.energyTextOffsetY or 0)

  Energy.bg:SetAllPoints()
  setColor(Energy.bg, db.energyBg)
  setBarColor(Energy, db.energyStyle, db.energyFill, db.energyFill2)
  
  if db.showEnergyTicker == "1" then
    local tickerHeight = db.heightEnergy + 10
    local tickerWidth = db.energyTickerWidth or 16
    
    if db.energyTickerGlow == "1" then
      Energy.ticker:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
      Energy.ticker:SetBlendMode("ADD")
      Energy.ticker:SetHeight(tickerHeight)
      Energy.ticker:SetWidth(tickerWidth)
    else
      Energy.ticker:SetTexture(1, 1, 1, 1)
      Energy.ticker:SetBlendMode("BLEND")
      Energy.ticker:SetHeight(db.heightEnergy)
      Energy.ticker:SetWidth(tickerWidth)
    end
    
    if db.energyTickerColor then
      Energy.ticker:SetVertexColor(db.energyTickerColor[1], db.energyTickerColor[2], db.energyTickerColor[3], db.energyTickerColor[4] or 1)
    end
  else
    Energy.ticker:Hide()
  end

  CP:SetHeight(db.heightCP)
  
  local separatorStyle = db.cpSeparatorStyle or "gap"
  local cpBorderSize = db.cpBorderSize or 1
  local cpSeparatorWidth = db.cpSeparatorWidth or 2
  local cpGap, segW
  
  if separatorStyle == "border" then
    cpGap = 0
    segW = db.width / 5
  else
    cpGap = db.cpGap or 4
    segW = (db.width - (4 * cpGap)) / 5
  end
  
  for i = 1, 5 do
    local seg = CP.segs[i]
    if not seg then
      seg = CreateFrame("StatusBar", nil, CP)
      seg:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")

      seg.bg = seg:CreateTexture(nil, "BACKGROUND")
      seg.bg:SetAllPoints()
      seg.bg:SetTexture("Interface\\Buttons\\WHITE8X8")

      CP.segs[i] = seg
    end

    seg:ClearAllPoints()
    if i == 1 then
      seg:SetPoint("LEFT", CP, "LEFT", 0, 0)
    else
      seg:SetPoint("LEFT", CP.segs[i-1], "RIGHT", cpGap, 0)
    end
    setSize(seg, segW, db.heightCP)
    seg:SetMinMaxValues(0, 1)
    seg:SetValue(0)

    setColor(seg.bg, db.cpEmpty)
    setBarColor(seg, db.cpStyle, db.cpFill, db.cpFill2)
  end
  
  local separatorColor = db.cpSeparatorColor or (SCE.defaults and SCE.defaults.cpSeparatorColor) or {0,0,0,1}
  for i = 1, 4 do
    local sepFrame = CP.separators[i]
    if sepFrame then
      if separatorStyle == "border" then
        sepFrame:ClearAllPoints()
        sepFrame:SetPoint("CENTER", CP.segs[i], "RIGHT", 0, 0)
        sepFrame:SetWidth(cpSeparatorWidth)
        sepFrame:SetHeight(db.heightCP + (cpBorderSize * 2))
        if sepFrame.tex then
          sepFrame.tex:SetTexture(separatorColor[1], separatorColor[2], separatorColor[3], separatorColor[4] or 1)
        end
        sepFrame:Show()
      else
        sepFrame:Hide()
      end
    end
  end

  applyBorder(EnergyBorder, db.energyBorderSize or 0, db.energyBorderColor or (SCE.defaults and SCE.defaults.energyBorderColor) or {0,0,0,1})
  applyBorder(CPBorder, cpBorderSize, db.cpBorderColor or (SCE.defaults and SCE.defaults.cpBorderColor) or {0,0,0,1})
end

local function updateAlpha()
  local db = StupidComboEnergyDB
  if isEnergy() then
    UI:SetAlpha(1)
  else
    if db.showWhenNotEnergy == "1" then
      UI:SetAlpha(db.notEnergyAlpha)
    else
      UI:SetAlpha(0)
    end
  end
end

local function applyColors()
  local db = StupidComboEnergyDB
  setColor(UI.bg, db.frameBg)
  setColor(Energy.bg, db.energyBg)
  setBarColor(Energy, db.energyStyle, db.energyFill, db.energyFill2)
  if db.energyTextColor then
    Energy.text:SetTextColor(db.energyTextColor[1], db.energyTextColor[2], db.energyTextColor[3], db.energyTextColor[4] or 1)
  end
  for i = 1, 5 do
    local seg = CP.segs[i]
    setColor(seg.bg, db.cpEmpty)
    setBarColor(seg, db.cpStyle, db.cpFill, db.cpFill2)
  end
  applyBorder(EnergyBorder, db.energyBorderSize or 0, db.energyBorderColor or (SCE.defaults and SCE.defaults.energyBorderColor) or {0,0,0,1})
  applyBorder(CPBorder, db.cpBorderSize or 0, db.cpBorderColor or (SCE.defaults and SCE.defaults.cpBorderColor) or {0,0,0,1})
end

local function applyFonts()
  local db = StupidComboEnergyDB
  local font = db.energyTextFont or (SCE.defaults and SCE.defaults.energyTextFont) or "Fonts\\FRIZQT__.TTF"
  local size = db.energyTextSize or (SCE.defaults and SCE.defaults.energyTextSize) or 12
  if font and size and Energy.text.SetFont then
    Energy.text:SetFont(font, size, "OUTLINE")
  end
end

local setLocked

local function refreshUI()
  layout()
  applyFonts()
  applyColors()
  setLocked(StupidComboEnergyDB.locked)
  if SCE.updateAll then
    SCE.updateAll()
  end
end

setLocked = function(locked)
  local shouldLock
  if type(locked) == "string" then
    shouldLock = (locked == "1")
  else
    shouldLock = locked and true or false
  end
  
  StupidComboEnergyDB.locked = shouldLock and "1" or "0"
  
  local isLocked = shouldLock
  
  Energy:EnableMouse(not isLocked)
  Energy:SetMovable(not isLocked)
  CP:EnableMouse(not isLocked)
  CP:SetMovable(not isLocked)
  
  UI:EnableMouse(false)
  UI:SetMovable(false)
  
  if SCE.ConfigFrame and SCE.ConfigFrame.lockButton then
    if isLocked then
      SCE.ConfigFrame.lockButton:SetText("Unlock")
    else
      SCE.ConfigFrame.lockButton:SetText("Lock")
    end
  end
end

local dragState = {
  startX = nil,
  startY = nil,
  energyStartX = nil,
  energyStartY = nil,
  cpStartX = nil,
  cpStartY = nil,
}

local function getFrameOffset(frame)
  local cx, cy = frame:GetCenter()
  local ux, uy = UIParent:GetCenter()
  if not cx or not cy or not ux or not uy then return 0, 0 end
  return cx - ux, cy - uy
end

Energy:SetScript("OnDragStart", function()
  if StupidComboEnergyDB.locked == "1" then return end
  
  local db = StupidComboEnergyDB
  if db.grouped == "1" then
    dragState.energyStartX, dragState.energyStartY = getFrameOffset(Energy)
    dragState.cpStartX, dragState.cpStartY = getFrameOffset(CP)
  end
  
  this:StartMoving()
end)

Energy:SetScript("OnDragStop", function()
  this:StopMovingOrSizing()
  local db = StupidComboEnergyDB
  
  local newX, newY = getFrameOffset(Energy)
  
  if db.grouped == "1" then
    local deltaX = newX - (dragState.energyStartX or newX)
    local deltaY = newY - (dragState.energyStartY or newY)
    
    db.point = "CENTER"
    db.relativePoint = "CENTER"
    db.x = (db.x or 0) + deltaX
    db.y = (db.y or 0) + deltaY
  else
    db.energyPoint = "CENTER"
    db.energyRelativePoint = "CENTER"
    db.energyX = math.floor(newX + 0.5)
    db.energyY = math.floor(newY + 0.5)
  end
  
  layout()
end)

CP:SetScript("OnDragStart", function()
  if StupidComboEnergyDB.locked == "1" then return end
  
  local db = StupidComboEnergyDB
  if db.grouped == "1" then
    dragState.energyStartX, dragState.energyStartY = getFrameOffset(Energy)
    dragState.cpStartX, dragState.cpStartY = getFrameOffset(CP)
  end
  
  this:StartMoving()
end)

CP:SetScript("OnDragStop", function()
  this:StopMovingOrSizing()
  local db = StupidComboEnergyDB
  
  local newX, newY = getFrameOffset(CP)
  
  if db.grouped == "1" then
    local deltaX = newX - (dragState.cpStartX or newX)
    local deltaY = newY - (dragState.cpStartY or newY)
    
    db.point = "CENTER"
    db.relativePoint = "CENTER"
    db.x = (db.x or 0) + deltaX
    db.y = (db.y or 0) + deltaY
  else
    db.cpPoint = "CENTER"
    db.cpRelativePoint = "CENTER"
    db.cpX = math.floor(newX + 0.5)
    db.cpY = math.floor(newY + 0.5)
  end
  
  layout()
end)

local function updateAll()
  updateAlpha()

  if SCE.setComboPoints then
    local cp = 0
    if UnitExists("target") and UnitCanAttack("player", "target") then
      if GetComboPoints then
        cp = GetComboPoints() or 0
      end
    end
    SCE.setComboPoints(cp)
  end

  if SCE.hardSyncEnergy then
    SCE.hardSyncEnergy()
  end
end

SCE.layout = layout
SCE.applyColors = applyColors
SCE.applyFonts = applyFonts
SCE.setLocked = setLocked
SCE.refreshUI = refreshUI
SCE.updateAll = updateAll
SCE.updateAlpha = updateAlpha

if SCE.debugMsg then
  SCE.debugMsg("Loaded module: layout.lua (frames created)")
end
