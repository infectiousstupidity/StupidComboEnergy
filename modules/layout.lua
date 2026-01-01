StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS
SCE._moduleLoaded = SCE._moduleLoaded or {}
SCE._moduleLoaded.layout = true

-- Don't cache SCE.defaults or SCE.clamp at load time - access them when needed
local UnitPowerType = UnitPowerType
local UnitManaMax = UnitManaMax
local UnitMana = UnitMana
local UnitClass = UnitClass
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

local function getPowerType()
  if UnitPowerType then
    local ptype, ptoken = UnitPowerType("player")
    return ptype, ptoken
  end
  return nil, nil
end

local function isEnergy()
  local ptype, ptoken = getPowerType()
  if ptype ~= nil then
    return ptype == 3 or ptoken == "ENERGY"
  end
  local maxv = UnitManaMax("player") or 0
  return maxv <= 120
end

local function isRage()
  local ptype, ptoken = getPowerType()
  if ptype ~= nil then
    return ptype == 1 or ptoken == "RAGE"
  end
  return false
end

local function shouldShowEnergy(db)
  db = db or StupidComboEnergyDB or {}
  return db.showEnergyBar ~= "0"
end

local function shouldShowCombo(db)
  db = db or StupidComboEnergyDB or {}
  if db.showComboBar == "0" then return false end
  if UnitClass then
    local _, class = UnitClass("player")
    if class == "ROGUE" then return true end
    if class == "DRUID" then return isEnergy() end
  end
  return false
end

local function getEnergyPalette(db)
  local defaults = SCE.defaults or {}
  db = db or StupidComboEnergyDB or {}
  local style = db.energyStyle or defaults.energyStyle or "solid"
  local fill1 = db.energyFill or defaults.energyFill
  local fill2 = db.energyFill2 or defaults.energyFill2
  local empty = db.energyEmpty or defaults.energyEmpty

  if not isEnergy() and isRage() then
    fill1 = db.rageFill or defaults.rageFill or fill1
    fill2 = db.rageFill2 or defaults.rageFill2 or fill2
    empty = db.rageEmpty or defaults.rageEmpty or empty
  end

  return style, fill1, fill2, empty
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
Energy.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
Energy.text = Energy:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

Energy.ticker = Energy:CreateTexture(nil, "OVERLAY")
Energy.ticker:Hide()

local CP = CreateFrame("Frame", nil, UI)
CP.segs = {}
CP:RegisterForDrag("LeftButton")
local EnergyBorder = createBorder(Energy, "BORDER")
local CPBorder = createBorder(CP, "BORDER")
local GroupGapLine = CreateFrame("Frame", nil, UIParent)
GroupGapLine:Hide()
GroupGapLine:SetFrameStrata("DIALOG")
GroupGapLine:EnableMouse(false)
GroupGapLine.tex = GroupGapLine:CreateTexture(nil, "OVERLAY")
GroupGapLine.tex:SetAllPoints()

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
SCE.shouldShowEnergy = shouldShowEnergy
SCE.shouldShowCombo = shouldShowCombo
SCE.getEnergyPalette = getEnergyPalette

local function layout()
  local db = StupidComboEnergyDB
  local pixel = (SCE.getPerfectPixel and SCE.getPerfectPixel()) or nil
  local function snap(v)
    if SCE.snapToPixel then
      return SCE.snapToPixel(v, pixel)
    end
    return v
  end
  local gap = db.gap or 0
  local energyWidth = db.width or 0
  local energyHeight = db.heightEnergy or 0
  local cpWidth = db.width or 0
  local cpHeight = db.heightCP or 0
  local energyBorderSize = db.energyBorderSize or 0
  local cpBorderSize = db.cpBorderSize or 1
  if pixel then
    gap = snap(gap)
    energyWidth = snap(energyWidth)
    energyHeight = snap(energyHeight)
    cpWidth = snap(cpWidth)
    cpHeight = snap(cpHeight)
    energyBorderSize = snap(energyBorderSize)
    cpBorderSize = snap(cpBorderSize)
  end
  if db.showOnlyActiveCombo == "1" and db.hideComboWhenEmpty == "1" then
    cpBorderSize = 0
  end

  local showEnergy = shouldShowEnergy(db)
  local showCombo = shouldShowCombo(db)
  
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
  if showEnergy then
    Energy:Show()
  else
    Energy:Hide()
  end
  if showCombo then
    CP:Show()
  else
    CP:Hide()
  end
  
  Energy:ClearAllPoints()
  CP:ClearAllPoints()
  
  if db.grouped == "1" then
    local mainX = db.x or 0
    local mainY = db.y or 0
    local energyOffset = (cpHeight + gap) / 2
    local cpOffset = (energyHeight + gap) / 2
    if showEnergy and showCombo then
      if db.energyFirst == "1" then
        Energy:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY + energyOffset)
        CP:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY - cpOffset)
        if Energy.SetFrameLevel and CP.SetFrameLevel then
          Energy:SetFrameLevel((db.frameLevel or 200) + 2)
          CP:SetFrameLevel((db.frameLevel or 200) + 1)
        end
      else
        CP:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY + cpOffset)
        Energy:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY - energyOffset)
        if Energy.SetFrameLevel and CP.SetFrameLevel then
          CP:SetFrameLevel((db.frameLevel or 200) + 2)
          Energy:SetFrameLevel((db.frameLevel or 200) + 1)
        end
      end
    elseif showEnergy and not showCombo then
      if db.energyFirst == "1" then
        Energy:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY + energyOffset)
      else
        Energy:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY - energyOffset)
      end
      CP:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY - cpOffset)
      if Energy.SetFrameLevel then
        Energy:SetFrameLevel((db.frameLevel or 200) + 1)
      end
    elseif showCombo and not showEnergy then
      if db.energyFirst == "1" then
        CP:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY - cpOffset)
      else
        CP:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY + cpOffset)
      end
      Energy:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY + energyOffset)
      if CP.SetFrameLevel then
        CP:SetFrameLevel((db.frameLevel or 200) + 1)
      end
    else
      Energy:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY)
      CP:SetPoint("CENTER", UIParent, "CENTER", mainX, mainY)
    end
  else
    Energy:SetPoint(db.energyPoint, UIParent, db.energyRelativePoint, db.energyX, db.energyY)
    CP:SetPoint(db.cpPoint, UIParent, db.cpRelativePoint, db.cpX, db.cpY)
    
    if Energy.SetFrameLevel and CP.SetFrameLevel then
      Energy:SetFrameLevel(db.frameLevel or 200)
      CP:SetFrameLevel(db.frameLevel or 200)
    end
  end
  
  setSize(Energy, energyWidth, energyHeight)
  setSize(CP, cpWidth, cpHeight)
  
  Energy:SetHeight(energyHeight)
  Energy.text:ClearAllPoints()
  Energy.text:SetPoint("CENTER", Energy, "CENTER", db.energyTextOffsetX or 0, db.energyTextOffsetY or 0)

  Energy.bg:SetAllPoints()
  local energyStyle, energyFill, energyFill2, energyEmpty = getEnergyPalette(db)
  setColor(Energy.bg, energyEmpty)
  setBarColor(Energy, energyStyle, energyFill, energyFill2)

  local showGapLine = (db.grouped == "1" and db.groupGapLine == "1" and gap > 0 and showEnergy and showCombo)
  if showGapLine then
    local lineSize = db.groupGapLineSize or 0
    if lineSize <= 0 then lineSize = gap end
    if lineSize > gap then lineSize = gap end
    if pixel then lineSize = snap(lineSize) end
    if lineSize <= 0 then
      GroupGapLine:Hide()
    else
      local topFrame = (db.energyFirst == "1") and Energy or CP
      local borderExtent = 0
      if energyBorderSize > borderExtent then borderExtent = energyBorderSize end
      if cpBorderSize > borderExtent then borderExtent = cpBorderSize end
      local offset = (gap - lineSize) / 2
      if pixel then offset = snap(offset) end
      GroupGapLine:ClearAllPoints()
      GroupGapLine:SetPoint("TOP", topFrame, "BOTTOM", 0, -offset)
      GroupGapLine:SetPoint("LEFT", topFrame, "LEFT", -borderExtent, 0)
      GroupGapLine:SetPoint("RIGHT", topFrame, "RIGHT", borderExtent, 0)
      GroupGapLine:SetHeight(lineSize)
      GroupGapLine:SetFrameStrata(db.frameStrata or "DIALOG")
      if GroupGapLine.SetFrameLevel then
        GroupGapLine:SetFrameLevel((db.frameLevel or 200) + 3)
      end
      local c = db.groupGapLineColor or (SCE.defaults and SCE.defaults.groupGapLineColor) or {0,0,0,1}
      GroupGapLine.tex:SetTexture(c[1], c[2], c[3], c[4] or 1)
      GroupGapLine:Show()
    end
  else
    GroupGapLine:Hide()
  end
  
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

  CP:SetHeight(cpHeight)
  
  local separatorStyle = db.cpSeparatorStyle or "gap"
  local cpSeparatorWidth = db.cpSeparatorWidth or 2
  local cpGap, segW
  
  if separatorStyle == "border" then
    cpGap = 0
    segW = cpWidth / 5
  else
    cpGap = db.cpGap or 4
    segW = (cpWidth - (4 * cpGap)) / 5
  end
  
  if pixel then
    cpSeparatorWidth = snap(cpSeparatorWidth)
    cpGap = snap(cpGap)
    segW = snap(segW)
  end
  local segWLast = cpWidth - (segW * 4) - (cpGap * 4)
  if segWLast < 0 then segWLast = segW end
  
  local sepX = {}
  local x = 0
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
    seg:SetPoint("LEFT", CP, "LEFT", x, 0)
    local w = (i == 5) and segWLast or segW
    setSize(seg, w, cpHeight)
    seg:SetMinMaxValues(0, 1)
    seg:SetValue(0)

    setColor(seg.bg, db.cpEmpty)
    setBarColor(seg, db.cpStyle, db.cpFill, db.cpFill2)
    
    x = x + w + cpGap
    if i < 5 then
      sepX[i] = x - cpGap
    end
  end
  
  local separatorColor = db.cpSeparatorColor or (SCE.defaults and SCE.defaults.cpSeparatorColor) or {0,0,0,1}
  for i = 1, 4 do
    local sepFrame = CP.separators[i]
    if sepFrame then
      if separatorStyle == "border" or (separatorStyle == "gapline" and cpGap > 0) then
        sepFrame:ClearAllPoints()
        local sx = sepX[i] or (segW * i)
        local sepWidth = cpSeparatorWidth
        if separatorStyle == "gapline" then
          if not sepWidth or sepWidth <= 0 then sepWidth = cpGap end
          if sepWidth > cpGap then sepWidth = cpGap end
          if pixel then
            sepWidth = snap(sepWidth)
          end
          if cpGap > sepWidth then
            local offset = (cpGap - sepWidth) / 2
            if pixel then offset = snap(offset) end
            sx = sx + offset
          end
        end
        sepFrame:SetPoint("TOPLEFT", CP, "TOPLEFT", sx, 0)
        sepFrame:SetPoint("BOTTOMLEFT", CP, "BOTTOMLEFT", sx, 0)
        sepFrame:SetWidth(sepWidth)
        if sepFrame.tex then
          sepFrame.tex:SetTexture(separatorColor[1], separatorColor[2], separatorColor[3], separatorColor[4] or 1)
        end
        sepFrame:Show()
      else
        sepFrame:Hide()
      end
    end
  end

  applyBorder(EnergyBorder, energyBorderSize, db.energyBorderColor or (SCE.defaults and SCE.defaults.energyBorderColor) or {0,0,0,1})
  applyBorder(CPBorder, cpBorderSize, db.cpBorderColor or (SCE.defaults and SCE.defaults.cpBorderColor) or {0,0,0,1})
end

local function updateAlpha()
  local db = StupidComboEnergyDB or {}
  local showEnergy = shouldShowEnergy(db)
  local showCombo = shouldShowCombo(db)
  local cpCount = SCE.comboPoints or 0
  local hideComboEmpty = (db.hideComboWhenEmpty == "1" and cpCount <= 0)
  local comboVisible = showCombo and not hideComboEmpty
  local alpha = 1

  local isPrimaryPower = isEnergy() or isRage()
  if not isPrimaryPower then
    if db.showWhenNotEnergy == "1" then
      alpha = db.notEnergyAlpha or 0.35
    else
      alpha = 0
    end
  end

  if showEnergy then
    if alpha > 0 then
      Energy:SetAlpha(alpha)
      Energy:Show()
    else
      Energy:SetAlpha(0)
      Energy:Hide()
    end
  else
    Energy:Hide()
  end

  if comboVisible then
    if alpha > 0 then
      CP:SetAlpha(alpha)
      CP:Show()
    else
      CP:SetAlpha(0)
      CP:Hide()
    end
  else
    CP:Hide()
  end

  if GroupGapLine then
    if showEnergy and comboVisible and db.grouped == "1" and db.groupGapLine == "1" and (db.gap or 0) > 0 and alpha > 0 then
      GroupGapLine:SetAlpha(alpha)
      GroupGapLine:Show()
    else
      GroupGapLine:Hide()
    end
  end
end

local function applyColors()
  local db = StupidComboEnergyDB
  setColor(UI.bg, db.frameBg)
  local energyStyle, energyFill, energyFill2, energyEmpty = getEnergyPalette(db)
  setColor(Energy.bg, energyEmpty)
  setBarColor(Energy, energyStyle, energyFill, energyFill2)
  if db.energyTextColor then
    Energy.text:SetTextColor(db.energyTextColor[1], db.energyTextColor[2], db.energyTextColor[3], db.energyTextColor[4] or 1)
  end
  for i = 1, 5 do
    local seg = CP.segs[i]
    setColor(seg.bg, db.cpEmpty)
  end
  if SCE.setComboPoints then
    local cp = 0
    if UnitExists("target") and UnitCanAttack("player", "target") then
      if GetComboPoints then
        cp = GetComboPoints() or 0
      end
    end
    SCE.setComboPoints(cp)
  end
  local pixel = (SCE.getPerfectPixel and SCE.getPerfectPixel()) or nil
  local energyBorderSize = db.energyBorderSize or 0
  local cpBorderSize = db.cpBorderSize or 0
  if pixel and SCE.snapToPixel then
    energyBorderSize = SCE.snapToPixel(energyBorderSize, pixel)
    cpBorderSize = SCE.snapToPixel(cpBorderSize, pixel)
  end
  if db.showOnlyActiveCombo == "1" and db.hideComboWhenEmpty == "1" then
    cpBorderSize = 0
  end
  applyBorder(EnergyBorder, energyBorderSize, db.energyBorderColor or (SCE.defaults and SCE.defaults.energyBorderColor) or {0,0,0,1})
  applyBorder(CPBorder, cpBorderSize, db.cpBorderColor or (SCE.defaults and SCE.defaults.cpBorderColor) or {0,0,0,1})
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

local lastPowerType = nil
local lastEnergyVisible = nil
local lastComboVisible = nil

local function getPowerKey()
  local ptype = getPowerType()
  if ptype ~= nil then return ptype end
  return isEnergy() and "ENERGY" or "OTHER"
end

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
  local db = StupidComboEnergyDB or {}
  local showEnergy = shouldShowEnergy(db)
  local showCombo = shouldShowCombo(db)
  local cp = 0
  local powerKey = getPowerKey()
  if powerKey ~= lastPowerType or showEnergy ~= lastEnergyVisible or showCombo ~= lastComboVisible then
    lastPowerType = powerKey
    lastEnergyVisible = showEnergy
    lastComboVisible = showCombo
    layout()
    applyColors()
  end

  if showCombo then
    if UnitExists("target") and UnitCanAttack("player", "target") then
      if GetComboPoints then
        cp = GetComboPoints() or 0
      end
    end
    SCE.comboPoints = cp
    if SCE.setComboPoints then
      SCE.setComboPoints(cp)
    end
  else
    SCE.comboPoints = 0
  end

  if showEnergy and SCE.hardSyncEnergy then
    SCE.hardSyncEnergy()
  end

  updateAlpha()
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
