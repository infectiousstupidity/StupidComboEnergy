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

local function clampFrameLevel(level)
  local n = tonumber(level) or 2
  if n < 1 then return 1 end
  if n > 5 then return 5 end
  return n
end

local function getPowerType()
  if UnitPowerType then
    local ptype, ptoken = UnitPowerType("player")
    return ptype, ptoken
  end
  return nil, nil
end

local function isEnabled(val, defaultOn)
  if val == nil then
    return defaultOn and true or false
  end
  return val == "1" or val == 1 or val == true
end

local function isEnergy()
  local ptype, ptoken = getPowerType()
  if ptype ~= nil then
    return ptype == 3 or ptoken == "ENERGY"
  end
  local maxv = UnitManaMax("player") or 0
  return maxv <= 120
end

local function isMana()
  local ptype, ptoken = getPowerType()
  if ptype ~= nil then
    return ptype == 0 or ptoken == "MANA"
  end
  local maxv = UnitManaMax("player") or 0
  return maxv > 120
end

local function isRage()
  local ptype, ptoken = getPowerType()
  if ptype ~= nil then
    return ptype == 1 or ptoken == "RAGE"
  end
  return false
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

local function shouldShowHealth(db)
  db = db or StupidComboEnergyDB or {}
  return db.showHealthBar == "1"
end

local function shouldShowPower(db)
  db = db or StupidComboEnergyDB or {}
  if db.showPowerBar == "0" then return false end
  if isMana() or isEnergy() or isRage() then return true end
  return (db.showWhenNotPower or db.showWhenNotEnergy) == "1"
end

local function shouldShowDruidMana(db)
  db = db or StupidComboEnergyDB or {}
  if db.showDruidManaBar ~= "1" then return false end
  if UnitClass then
    local _, class = UnitClass("player")
    return class == "DRUID" and not isMana()
  end
  return false
end

local function shouldShowCastbar(db)
  db = db or StupidComboEnergyDB or {}
  return db.showCastbar == "1"
end

local function shouldShowShiftIndicator(db)
  db = db or StupidComboEnergyDB or {}
  if db.showShiftIndicator ~= "1" then return false end
  if UnitClass then
    local _, class = UnitClass("player")
    if class ~= "DRUID" then return false end
  end
  local attach = db.shiftIndicatorAttach or "power"
  if attach == "health" then
    return shouldShowHealth(db)
  elseif attach == "power" then
    return shouldShowPower(db)
  elseif attach == "druidmana" then
    return shouldShowDruidMana(db)
  elseif attach == "healthpower" then
    return shouldShowHealth(db) or shouldShowPower(db)
  elseif attach == "healthdruid" then
    return shouldShowHealth(db) or shouldShowDruidMana(db)
  elseif attach == "powerdruid" then
    return shouldShowPower(db) or shouldShowDruidMana(db)
  elseif attach == "healthpowerdruid" then
    return shouldShowHealth(db) or shouldShowPower(db) or shouldShowDruidMana(db)
  end
  return shouldShowPower(db)
end

local function getPowerPalette(db)
  local defaults = SCE.defaults or {}
  db = db or StupidComboEnergyDB or {}
  local style = db.powerStyle or defaults.powerStyle or "solid"
  local fill1 = db.powerFill or defaults.powerFill
  local fill2 = db.powerFill2 or defaults.powerFill2
  local empty = db.powerEmpty or defaults.powerEmpty

  if isMana() then
    fill1 = db.manaFill or defaults.manaFill or fill1
    fill2 = db.manaFill2 or defaults.manaFill2 or fill2
    empty = db.manaEmpty or defaults.manaEmpty or empty
  elseif not isEnergy() and isRage() then
    fill1 = db.rageFill or defaults.rageFill or fill1
    fill2 = db.rageFill2 or defaults.rageFill2 or fill2
    empty = db.rageEmpty or defaults.rageEmpty or empty
  end

  return style, fill1, fill2, empty
end

local UI = CreateFrame("Frame", "StupidComboEnergyFrame", UIParent)
UI:SetFrameStrata("MEDIUM")
if UI.SetFrameLevel then
  UI:SetFrameLevel(2)
end
UI:Hide()
UI:RegisterForDrag("LeftButton")

UI.bg = UI:CreateTexture(nil, "BACKGROUND")
UI.bg:SetAllPoints()

local Health = CreateFrame("StatusBar", nil, UI)
Health:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
Health:RegisterForDrag("LeftButton")
Health.bg = Health:CreateTexture(nil, "BACKGROUND")
Health.bg:SetAllPoints()
Health.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
Health.textLeft = Health:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
Health.textCenter = Health:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
Health.textRight = Health:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
Health.text = Health.textCenter

local Power = CreateFrame("StatusBar", nil, UI)
Power:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
Power:RegisterForDrag("LeftButton")
Power.bg = Power:CreateTexture(nil, "BACKGROUND")
Power.bg:SetAllPoints()
Power.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
Power.textLeft = Power:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
Power.textCenter = Power:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
Power.textRight = Power:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
Power.text = Power.textCenter
Power.ticker = Power:CreateTexture(nil, "OVERLAY")
Power.ticker:Hide()

local DruidMana = CreateFrame("StatusBar", nil, UI)
DruidMana:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
DruidMana:RegisterForDrag("LeftButton")
DruidMana.bg = DruidMana:CreateTexture(nil, "BACKGROUND")
DruidMana.bg:SetAllPoints()
DruidMana.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
DruidMana.textLeft = DruidMana:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
DruidMana.textCenter = DruidMana:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
DruidMana.textRight = DruidMana:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
DruidMana.text = DruidMana.textCenter

local Castbar = CreateFrame("StatusBar", nil, UI)
Castbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
Castbar:RegisterForDrag("LeftButton")
Castbar.bg = Castbar:CreateTexture(nil, "BACKGROUND")
Castbar.bg:SetAllPoints()
Castbar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")

local ShiftIndicator = CreateFrame("Frame", nil, UI)
ShiftIndicator.icon = ShiftIndicator:CreateTexture(nil, "BACKGROUND")
ShiftIndicator.icon:SetAllPoints()
ShiftIndicator.text = ShiftIndicator:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

local CP = CreateFrame("Frame", nil, UI)
CP.segs = {}
CP:RegisterForDrag("LeftButton")
local HealthBorder = createBorder(Health, "BORDER")
local PowerBorder = createBorder(Power, "BORDER")
local DruidManaBorder = createBorder(DruidMana, "BORDER")
local CastbarBorder = createBorder(Castbar, "BORDER")
local ShiftIndicatorBorder = createBorder(ShiftIndicator, "BORDER")
local CPBorder = createBorder(CP, "BORDER")
local GroupGapLine = CreateFrame("Frame", nil, UIParent)
GroupGapLine:Hide()
GroupGapLine:SetFrameStrata("MEDIUM")
if GroupGapLine.SetFrameLevel then
  GroupGapLine:SetFrameLevel(2)
end
GroupGapLine:EnableMouse(false)
GroupGapLine.tex = GroupGapLine:CreateTexture(nil, "OVERLAY")
GroupGapLine.tex:SetAllPoints()

CP.separators = {}
for i = 1, 4 do
  local sepFrame = CreateFrame("Frame", nil, CP)
  if sepFrame.SetFrameLevel then
    sepFrame:SetFrameLevel(2)
  end
  local sep = sepFrame:CreateTexture(nil, "OVERLAY")
  sep:SetAllPoints(sepFrame)
  sepFrame:Hide()
  sepFrame.tex = sep
  CP.separators[i] = sepFrame
end

SCE.UI = UI
SCE.Health = Health
SCE.Power = Power
SCE.DruidMana = DruidMana
SCE.Castbar = Castbar
SCE.ShiftIndicator = ShiftIndicator
SCE.CP = CP
SCE.HealthBorder = HealthBorder
SCE.PowerBorder = PowerBorder
SCE.DruidManaBorder = DruidManaBorder
SCE.CastbarBorder = CastbarBorder
SCE.ShiftIndicatorBorder = ShiftIndicatorBorder
SCE.CPBorder = CPBorder
SCE.setColor = setColor
SCE.setBarColor = setBarColor
SCE.applyBorder = applyBorder
SCE.isEnergy = isEnergy
SCE.isMana = isMana
SCE.isRage = isRage
SCE.shouldShowCombo = shouldShowCombo
SCE.shouldShowHealth = shouldShowHealth
SCE.shouldShowPower = shouldShowPower
SCE.shouldShowDruidMana = shouldShowDruidMana
SCE.shouldShowCastbar = shouldShowCastbar
SCE.shouldShowShiftIndicator = shouldShowShiftIndicator
SCE.getPowerPalette = getPowerPalette

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
  local cpWidth = db.width or 0
  local cpHeight = db.heightCP or 0
  local healthWidth = db.healthWidth or db.width or 0
  local healthHeight = db.healthHeight or 0
  local powerWidth = db.powerWidth or db.width or 0
  local powerHeight = db.powerHeight or 0
  local druidManaWidth = db.druidManaWidth or db.width or 0
  local druidManaHeight = db.druidManaHeight or 0
  local castbarWidth = db.castbarWidth or db.width or 0
  local castbarHeight = db.castbarHeight or 0
  local healthWidthTotal = 0
  local powerWidthTotal = 0
  local druidManaWidthTotal = 0
  local shiftAttach = db.shiftIndicatorAttach or "power"
  local shiftAnchor = db.shiftIndicatorAnchor or "LEFT"
  local shiftSpacing = db.shiftIndicatorSpacing or 0
  local shiftSize = db.shiftIndicatorSize or 0
  local healthShiftOffsetX = 0
  local powerShiftOffsetX = 0
  local druidShiftOffsetX = 0
  local castbarIconWidth = 0
  local castbarIconSpacing = 0
  if isEnabled(db.castbarShowIcon, true) then
    castbarIconWidth = castbarHeight or 0
    if pfUI and pfUI.api and pfUI.api.GetBorderSize then
      local _, border = pfUI.api.GetBorderSize("unitframes")
      castbarIconSpacing = (border or 1) * 2
    end
  end
  local castbarBarWidth = castbarWidth - (castbarIconWidth + castbarIconSpacing)
  if castbarBarWidth < 0 then castbarBarWidth = 0 end
  local castbarOffsetX = 0
  if castbarIconWidth > 0 or castbarIconSpacing > 0 then
    castbarOffsetX = (castbarIconWidth + castbarIconSpacing) / 2
  end
  local healthBorderSize = db.healthBorderSize or 0
  local powerBorderSize = db.powerBorderSize or 0
  local druidManaBorderSize = db.druidManaBorderSize or 0
  local castbarBorderSize = db.castbarBorderSize or 0
  local shiftBorderSize = db.shiftIndicatorBorderSize or 0
  local cpBorderSize = db.cpBorderSize or 1
  if pixel then
    gap = snap(gap)
    cpWidth = snap(cpWidth)
    cpHeight = snap(cpHeight)
    healthWidth = snap(healthWidth)
    healthHeight = snap(healthHeight)
    powerWidth = snap(powerWidth)
    powerHeight = snap(powerHeight)
    druidManaWidth = snap(druidManaWidth)
    druidManaHeight = snap(druidManaHeight)
    castbarWidth = snap(castbarWidth)
    castbarHeight = snap(castbarHeight)
    healthBorderSize = snap(healthBorderSize)
    powerBorderSize = snap(powerBorderSize)
    druidManaBorderSize = snap(druidManaBorderSize)
    castbarBorderSize = snap(castbarBorderSize)
    shiftBorderSize = snap(shiftBorderSize)
    cpBorderSize = snap(cpBorderSize)
  end
  if db.showOnlyActiveCombo == "1" and db.hideComboWhenEmpty == "1" then
    cpBorderSize = 0
  end

  local showCombo = shouldShowCombo(db)
  local showHealth = shouldShowHealth(db)
  local showPower = shouldShowPower(db)
  local showDruidMana = shouldShowDruidMana(db)
  local showCastbar = shouldShowCastbar(db)
  local showShiftIndicator = shouldShowShiftIndicator(db)
  local baseLevel = clampFrameLevel(db.frameLevel)

  local attachHealth = (shiftAttach == "health" or shiftAttach == "healthpower" or shiftAttach == "healthdruid" or shiftAttach == "healthpowerdruid")
  local attachPower = (shiftAttach == "power" or shiftAttach == "healthpower" or shiftAttach == "powerdruid" or shiftAttach == "healthpowerdruid")
  local attachDruid = (shiftAttach == "druidmana" or shiftAttach == "healthdruid" or shiftAttach == "powerdruid" or shiftAttach == "healthpowerdruid")
  local attachCount = 0
  if attachHealth and showHealth then attachCount = attachCount + 1 end
  if attachPower and showPower then attachCount = attachCount + 1 end
  if attachDruid and showDruidMana then attachCount = attachCount + 1 end

  healthWidthTotal = healthWidth
  powerWidthTotal = powerWidth
  druidManaWidthTotal = druidManaWidth

  shiftSpacing = tonumber(shiftSpacing) or 0
  shiftSize = tonumber(shiftSize) or 0
  if pixel then
    shiftSpacing = snap(shiftSpacing)
  end

  if showShiftIndicator and attachCount > 0 then
    local spanHeight = 0
    if attachHealth and showHealth then spanHeight = spanHeight + healthHeight end
    if attachPower and showPower then spanHeight = spanHeight + powerHeight end
    if attachDruid and showDruidMana then spanHeight = spanHeight + druidManaHeight end
    if attachCount > 1 then
      local spanGap = (db.grouped == "1") and (gap or 0) or 0
      spanHeight = spanHeight + (attachCount - 1) * spanGap
    end

    if shiftSize <= 0 then
      shiftSize = spanHeight
    end
    if shiftSize < 0 then shiftSize = 0 end
    if pixel then
      shiftSize = snap(shiftSize)
    end

    local shiftSpan = shiftSize + shiftSpacing
    if shiftSpan < 0 then shiftSpan = 0 end
    local shiftOffsetX = (shiftAnchor == "RIGHT") and -shiftSpan / 2 or shiftSpan / 2
    if attachHealth and showHealth then
      healthWidth = healthWidth - shiftSpan
      healthShiftOffsetX = shiftOffsetX
    end
    if attachPower and showPower then
      powerWidth = powerWidth - shiftSpan
      powerShiftOffsetX = shiftOffsetX
    end
    if attachDruid and showDruidMana then
      druidManaWidth = druidManaWidth - shiftSpan
      druidShiftOffsetX = shiftOffsetX
    end
    if healthWidth < 0 then healthWidth = 0 end
    if powerWidth < 0 then powerWidth = 0 end
    if druidManaWidth < 0 then druidManaWidth = 0 end
  else
    shiftSize = 0
  end

  local groupBaseWidth = 0
  if showHealth and healthWidthTotal > 0 then
    groupBaseWidth = healthWidthTotal
  else
    groupBaseWidth = math.max(powerWidthTotal, cpWidth, druidManaWidthTotal, castbarWidth)
  end
  if groupBaseWidth <= 0 then groupBaseWidth = powerWidth end
  local powerAnchor = db.powerAnchor or "CENTER"
  local powerAnchorOffsetX = 0
  if powerAnchor == "LEFT" or powerAnchor == "TOPLEFT" then
    powerAnchorOffsetX = -(groupBaseWidth - powerWidthTotal) / 2
  elseif powerAnchor == "RIGHT" or powerAnchor == "TOPRIGHT" then
    powerAnchorOffsetX = (groupBaseWidth - powerWidthTotal) / 2
  end
  
  UI:SetFrameStrata("MEDIUM")
  Health:SetFrameStrata("MEDIUM")
  Power:SetFrameStrata("MEDIUM")
  DruidMana:SetFrameStrata("MEDIUM")
  Castbar:SetFrameStrata("MEDIUM")
  ShiftIndicator:SetFrameStrata("MEDIUM")
  CP:SetFrameStrata("MEDIUM")
  if UI.SetFrameLevel then
    UI:SetFrameLevel(baseLevel)
  end
  if Power.SetFrameLevel then
    Health:SetFrameLevel(baseLevel)
    Power:SetFrameLevel(baseLevel)
    DruidMana:SetFrameLevel(baseLevel)
    Castbar:SetFrameLevel(baseLevel)
    ShiftIndicator:SetFrameLevel(baseLevel)
    CP:SetFrameLevel(baseLevel)
  end
  
  UI:Hide()
  
  Health:SetParent(UIParent)
  Power:SetParent(UIParent)
  DruidMana:SetParent(UIParent)
  Castbar:SetParent(UIParent)
  ShiftIndicator:SetParent(UIParent)
  CP:SetParent(UIParent)
  if showHealth then
    Health:Show()
  else
    Health:Hide()
  end
  if showPower then
    Power:Show()
  else
    Power:Hide()
  end
  if showDruidMana then
    DruidMana:Show()
  else
    DruidMana:Hide()
  end
  if showCastbar then
    Castbar:Show()
  else
    Castbar:Hide()
  end
  if showShiftIndicator then
    ShiftIndicator:Show()
  else
    ShiftIndicator:Hide()
  end
  if showCombo then
    CP:Show()
  else
    CP:Hide()
  end
  
  Health:ClearAllPoints()
  Power:ClearAllPoints()
  DruidMana:ClearAllPoints()
  Castbar:ClearAllPoints()
  ShiftIndicator:ClearAllPoints()
  CP:ClearAllPoints()

  local barCenters = {}
  
  local powerComboAdjacent = false
  local powerComboTopFrame = nil

  if db.grouped == "1" then
    local mainX = db.x or 0
    local mainY = db.y or 0
    local items = {}
    local function addItem(name, frame, height)
      if frame and height and height > 0 then
        table.insert(items, { name = name, frame = frame, height = height })
      end
    end

    if showHealth then addItem("health", Health, healthHeight) end
    if showDruidMana then addItem("druidmana", DruidMana, druidManaHeight) end

    if showPower and showCombo then
      if db.powerFirst == "1" then
        addItem("power", Power, powerHeight)
        addItem("combo", CP, cpHeight)
        if Power.SetFrameLevel and CP.SetFrameLevel then
          local high = math.min(baseLevel + 2, 5)
          local mid = math.min(baseLevel + 1, 5)
          Power:SetFrameLevel(high)
          CP:SetFrameLevel(mid)
        end
      else
        addItem("combo", CP, cpHeight)
        addItem("power", Power, powerHeight)
        if Power.SetFrameLevel and CP.SetFrameLevel then
          local high = math.min(baseLevel + 2, 5)
          local mid = math.min(baseLevel + 1, 5)
          CP:SetFrameLevel(high)
          Power:SetFrameLevel(mid)
        end
      end
    else
      if showPower then addItem("power", Power, powerHeight) end
      if showCombo then addItem("combo", CP, cpHeight) end
    end

    if showCastbar then addItem("castbar", Castbar, castbarHeight) end

    local totalHeight = 0
    local powerIndex, comboIndex
    for i = 1, table.getn(items) do
      totalHeight = totalHeight + items[i].height
      if i > 1 then totalHeight = totalHeight + gap end
      if items[i].name == "power" then powerIndex = i end
      if items[i].name == "combo" then comboIndex = i end
    end

    if powerIndex and comboIndex and math.abs(powerIndex - comboIndex) == 1 then
      powerComboAdjacent = true
      if powerIndex < comboIndex then
        powerComboTopFrame = Power
      else
        powerComboTopFrame = CP
      end
    end
    SCE.powerComboAdjacent = powerComboAdjacent

    local currentTop = mainY + totalHeight / 2
    for i = 1, table.getn(items) do
      local entry = items[i]
      local centerY = currentTop - entry.height / 2
      local offsetX = mainX
      if entry.name == "health" then
        offsetX = offsetX + healthShiftOffsetX
      elseif entry.name == "power" then
        offsetX = offsetX + powerAnchorOffsetX + powerShiftOffsetX
      elseif entry.name == "druidmana" then
        offsetX = offsetX + druidShiftOffsetX
      elseif entry.name == "castbar" then
        offsetX = offsetX + castbarOffsetX
      end
      entry.frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, centerY)
      if entry.name == "health" or entry.name == "power" or entry.name == "druidmana" then
        barCenters[entry.name] = { x = offsetX, y = centerY }
      end
      currentTop = centerY - entry.height / 2 - gap
    end
  else
    CP:SetPoint(db.cpPoint, UIParent, db.cpRelativePoint, db.cpX, db.cpY)
    Health:SetPoint(db.healthPoint, UIParent, db.healthRelativePoint, (db.healthX or 0) + healthShiftOffsetX, db.healthY)
    Power:SetPoint(db.powerPoint, UIParent, db.powerRelativePoint, (db.powerX or 0) + powerShiftOffsetX, db.powerY)
    DruidMana:SetPoint(db.druidManaPoint, UIParent, db.druidManaRelativePoint, (db.druidManaX or 0) + druidShiftOffsetX, db.druidManaY)
    Castbar:SetPoint(db.castbarPoint, UIParent, db.castbarRelativePoint, (db.castbarX or 0) + castbarOffsetX, db.castbarY)

    barCenters.health = { x = (db.healthX or 0) + healthShiftOffsetX, y = db.healthY or 0 }
    barCenters.power = { x = (db.powerX or 0) + powerShiftOffsetX, y = db.powerY or 0 }
    barCenters.druidmana = { x = (db.druidManaX or 0) + druidShiftOffsetX, y = db.druidManaY or 0 }
    
    if Power.SetFrameLevel and CP.SetFrameLevel then
      Power:SetFrameLevel(baseLevel)
      CP:SetFrameLevel(baseLevel)
    end
  end
  SCE.powerComboAdjacent = powerComboAdjacent

  if Health.SetFrameLevel then
    Health:SetFrameLevel(baseLevel)
  end
  if Power.SetFrameLevel then
    Power:SetFrameLevel(baseLevel)
  end
  if DruidMana.SetFrameLevel then
    DruidMana:SetFrameLevel(baseLevel)
  end
  if Castbar.SetFrameLevel then
    Castbar:SetFrameLevel(baseLevel)
  end
  if ShiftIndicator.SetFrameLevel then
    ShiftIndicator:SetFrameLevel(baseLevel)
  end

  if CP.separators then
    local sepLevel = math.min((CP.GetFrameLevel and CP:GetFrameLevel() or baseLevel) + 1, 5)
    for i = 1, 4 do
      local sepFrame = CP.separators[i]
      if sepFrame and sepFrame.SetFrameLevel then
        sepFrame:SetFrameLevel(sepLevel)
      end
    end
  end
  
  setSize(CP, cpWidth, cpHeight)
  setSize(Health, healthWidth, healthHeight)
  if Health.SetOrientation then
    if db.verticalHealthBar == "1" then
      Health:SetOrientation("VERTICAL")
    else
      Health:SetOrientation("HORIZONTAL")
    end
  end
  setSize(Power, powerWidth, powerHeight)
  setSize(DruidMana, druidManaWidth, druidManaHeight)
  setSize(Castbar, castbarBarWidth, castbarHeight)
  setSize(ShiftIndicator, shiftSize, shiftSize)
  
  local hLeftX = db.healthTextLeftOffsetX or 0
  local hLeftY = db.healthTextLeftOffsetY or 0
  local hCenterX = db.healthTextCenterOffsetX
  if hCenterX == nil then hCenterX = db.healthTextOffsetX or 0 end
  local hCenterY = db.healthTextCenterOffsetY
  if hCenterY == nil then hCenterY = db.healthTextOffsetY or 0 end
  local hRightX = db.healthTextRightOffsetX or 0
  local hRightY = db.healthTextRightOffsetY or 0

  if Health.textLeft then
    Health.textLeft:ClearAllPoints()
    Health.textLeft:SetPoint("TOPLEFT", Health, "TOPLEFT", hLeftX, hLeftY)
    Health.textLeft:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", hLeftX, hLeftY)
    Health.textLeft:SetJustifyH("LEFT")
  end
  if Health.textCenter then
    Health.textCenter:ClearAllPoints()
    Health.textCenter:SetPoint("CENTER", Health, "CENTER", hCenterX, hCenterY)
    Health.textCenter:SetJustifyH("CENTER")
  end
  if Health.textRight then
    Health.textRight:ClearAllPoints()
    Health.textRight:SetPoint("TOPLEFT", Health, "TOPLEFT", hRightX, hRightY)
    Health.textRight:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", hRightX, hRightY)
    Health.textRight:SetJustifyH("RIGHT")
  end

  local pLeftX = db.powerTextLeftOffsetX or 0
  local pLeftY = db.powerTextLeftOffsetY or 0
  local pCenterX = db.powerTextCenterOffsetX
  if pCenterX == nil then pCenterX = db.powerTextOffsetX or 0 end
  local pCenterY = db.powerTextCenterOffsetY
  if pCenterY == nil then pCenterY = db.powerTextOffsetY or 0 end
  local pRightX = db.powerTextRightOffsetX or 0
  local pRightY = db.powerTextRightOffsetY or 0

  if Power.textLeft then
    Power.textLeft:ClearAllPoints()
    Power.textLeft:SetPoint("TOPLEFT", Power, "TOPLEFT", pLeftX, pLeftY)
    Power.textLeft:SetPoint("BOTTOMRIGHT", Power, "BOTTOMRIGHT", pLeftX, pLeftY)
    Power.textLeft:SetJustifyH("LEFT")
  end
  if Power.textCenter then
    Power.textCenter:ClearAllPoints()
    Power.textCenter:SetPoint("CENTER", Power, "CENTER", pCenterX, pCenterY)
    Power.textCenter:SetJustifyH("CENTER")
  end
  if Power.textRight then
    Power.textRight:ClearAllPoints()
    Power.textRight:SetPoint("TOPLEFT", Power, "TOPLEFT", pRightX, pRightY)
    Power.textRight:SetPoint("BOTTOMRIGHT", Power, "BOTTOMRIGHT", pRightX, pRightY)
    Power.textRight:SetJustifyH("RIGHT")
  end
  if ShiftIndicator.text then
    ShiftIndicator.text:ClearAllPoints()
    ShiftIndicator.text:SetPoint("CENTER", ShiftIndicator, "CENTER",
      db.shiftIndicatorTextOffsetX or 0, db.shiftIndicatorTextOffsetY or 0)
  end
  local dLeftX = db.druidManaTextLeftOffsetX or 0
  local dLeftY = db.druidManaTextLeftOffsetY or 0
  local dCenterX = db.druidManaTextCenterOffsetX
  if dCenterX == nil then dCenterX = db.druidManaTextOffsetX or 0 end
  local dCenterY = db.druidManaTextCenterOffsetY
  if dCenterY == nil then dCenterY = db.druidManaTextOffsetY or 0 end
  local dRightX = db.druidManaTextRightOffsetX or 0
  local dRightY = db.druidManaTextRightOffsetY or 0

  if DruidMana.textLeft then
    DruidMana.textLeft:ClearAllPoints()
    DruidMana.textLeft:SetPoint("TOPLEFT", DruidMana, "TOPLEFT", dLeftX, dLeftY)
    DruidMana.textLeft:SetPoint("BOTTOMRIGHT", DruidMana, "BOTTOMRIGHT", dLeftX, dLeftY)
    DruidMana.textLeft:SetJustifyH("LEFT")
  end
  if DruidMana.textCenter then
    DruidMana.textCenter:ClearAllPoints()
    DruidMana.textCenter:SetPoint("CENTER", DruidMana, "CENTER", dCenterX, dCenterY)
    DruidMana.textCenter:SetJustifyH("CENTER")
  end
  if DruidMana.textRight then
    DruidMana.textRight:ClearAllPoints()
    DruidMana.textRight:SetPoint("TOPLEFT", DruidMana, "TOPLEFT", dRightX, dRightY)
    DruidMana.textRight:SetPoint("BOTTOMRIGHT", DruidMana, "BOTTOMRIGHT", dRightX, dRightY)
    DruidMana.textRight:SetJustifyH("RIGHT")
  end

  Health.bg:SetAllPoints()
  local healthEmpty = db.healthEmpty or (SCE.defaults and SCE.defaults.healthEmpty) or { 0, 0, 0, 0.7 }
  setColor(Health.bg, healthEmpty)
  setBarColor(Health, db.healthStyle, db.healthFill, db.healthFill2)

  Power.bg:SetAllPoints()
  local powerStyle, powerFill, powerFill2, powerEmpty = getPowerPalette(db)
  setColor(Power.bg, powerEmpty)
  setBarColor(Power, powerStyle, powerFill, powerFill2)

  DruidMana.bg:SetAllPoints()
  local druidEmpty = db.druidManaEmpty or (SCE.defaults and SCE.defaults.druidManaEmpty) or { 0, 0, 0, 0.7 }
  setColor(DruidMana.bg, druidEmpty)
  setBarColor(DruidMana, db.druidManaStyle, db.druidManaFill, db.druidManaFill2)

  Castbar.bg:SetAllPoints()
  local castEmpty = db.castbarEmpty or (SCE.defaults and SCE.defaults.castbarEmpty) or { 0, 0, 0, 0.7 }
  setColor(Castbar.bg, castEmpty)
  setBarColor(Castbar, db.castbarStyle, db.castbarFill, db.castbarFill2)

  if showShiftIndicator and attachCount > 0 then
    local anchorName = nil
    if attachHealth and showHealth then
      anchorName = "health"
    elseif attachPower and showPower then
      anchorName = "power"
    elseif attachDruid and showDruidMana then
      anchorName = "druidmana"
    end

    local center = anchorName and barCenters[anchorName] or nil
    if center then
      local anchorWidth = powerWidth
      if anchorName == "health" then
        anchorWidth = healthWidth
      elseif anchorName == "druidmana" then
        anchorWidth = druidManaWidth
      end

      local spacing = shiftSpacing or 0
      local offsetX = db.shiftIndicatorOffsetX or 0
      local offsetY = db.shiftIndicatorOffsetY or 0
      local iconCenterX = center.x
      if shiftAnchor == "RIGHT" then
        iconCenterX = iconCenterX + (anchorWidth / 2) + spacing + (shiftSize / 2)
      else
        iconCenterX = iconCenterX - (anchorWidth / 2) - spacing - (shiftSize / 2)
      end

      local iconCenterY = center.y
      if attachCount > 1 then
        local topY, bottomY
        if attachHealth and showHealth and barCenters.health then
          local y = barCenters.health.y
          local top = y + healthHeight / 2
          local bottom = y - healthHeight / 2
          topY = topY and math.max(topY, top) or top
          bottomY = bottomY and math.min(bottomY, bottom) or bottom
        end
        if attachPower and showPower and barCenters.power then
          local y = barCenters.power.y
          local top = y + powerHeight / 2
          local bottom = y - powerHeight / 2
          topY = topY and math.max(topY, top) or top
          bottomY = bottomY and math.min(bottomY, bottom) or bottom
        end
        if attachDruid and showDruidMana and barCenters.druidmana then
          local y = barCenters.druidmana.y
          local top = y + druidManaHeight / 2
          local bottom = y - druidManaHeight / 2
          topY = topY and math.max(topY, top) or top
          bottomY = bottomY and math.min(bottomY, bottom) or bottom
        end
        if topY and bottomY then
          iconCenterY = (topY + bottomY) / 2
        end
      end

      ShiftIndicator:ClearAllPoints()
      ShiftIndicator:SetPoint("CENTER", UIParent, "CENTER", iconCenterX + offsetX, iconCenterY + offsetY)
    end
  end

  local showGapLine = (db.grouped == "1" and db.groupGapLine == "1" and gap > 0 and powerComboAdjacent)
  if showGapLine then
    local lineSize = db.groupGapLineSize or 0
    if lineSize <= 0 then lineSize = gap end
    if lineSize > gap then lineSize = gap end
    if pixel then lineSize = snap(lineSize) end
    if lineSize <= 0 then
      GroupGapLine:Hide()
    else
      local topFrame = powerComboTopFrame or Power
      local borderExtent = 0
      if powerBorderSize > borderExtent then borderExtent = powerBorderSize end
      if cpBorderSize > borderExtent then borderExtent = cpBorderSize end
      local offset = (gap - lineSize) / 2
      if pixel then offset = snap(offset) end
      GroupGapLine:ClearAllPoints()
      GroupGapLine:SetPoint("TOP", topFrame, "BOTTOM", 0, -offset)
      GroupGapLine:SetPoint("LEFT", topFrame, "LEFT", -borderExtent, 0)
      GroupGapLine:SetPoint("RIGHT", topFrame, "RIGHT", borderExtent, 0)
      GroupGapLine:SetHeight(lineSize)
      GroupGapLine:SetFrameStrata("MEDIUM")
      if GroupGapLine.SetFrameLevel then
        GroupGapLine:SetFrameLevel(math.min(baseLevel + 1, 5))
      end
      local c = db.groupGapLineColor or (SCE.defaults and SCE.defaults.groupGapLineColor) or {0,0,0,1}
      GroupGapLine.tex:SetTexture(c[1], c[2], c[3], c[4] or 1)
      GroupGapLine:Show()
    end
  else
    GroupGapLine:Hide()
  end
  
  if db.showPowerTicker == "1" then
    local tickerHeight = powerHeight + 10
    local tickerWidth = db.powerTickerWidth or 16
    
    if db.powerTickerGlow == "1" then
      Power.ticker:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
      Power.ticker:SetBlendMode("ADD")
      Power.ticker:SetHeight(tickerHeight)
      Power.ticker:SetWidth(tickerWidth)
    else
      Power.ticker:SetTexture(1, 1, 1, 1)
      Power.ticker:SetBlendMode("BLEND")
      Power.ticker:SetHeight(powerHeight)
      Power.ticker:SetWidth(tickerWidth)
    end
    
    if db.powerTickerColor then
      Power.ticker:SetVertexColor(db.powerTickerColor[1], db.powerTickerColor[2], db.powerTickerColor[3], db.powerTickerColor[4] or 1)
    end
  else
    Power.ticker:Hide()
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

  applyBorder(HealthBorder, healthBorderSize, db.healthBorderColor or (SCE.defaults and SCE.defaults.healthBorderColor) or {0,0,0,1})
  applyBorder(PowerBorder, powerBorderSize, db.powerBorderColor or (SCE.defaults and SCE.defaults.powerBorderColor) or {0,0,0,1})
  applyBorder(DruidManaBorder, druidManaBorderSize, db.druidManaBorderColor or (SCE.defaults and SCE.defaults.druidManaBorderColor) or {0,0,0,1})
  applyBorder(CastbarBorder, castbarBorderSize, db.castbarBorderColor or (SCE.defaults and SCE.defaults.castbarBorderColor) or {0,0,0,1})
  applyBorder(ShiftIndicatorBorder, shiftBorderSize, db.shiftIndicatorBorderColor or {0,0,0,1})
  applyBorder(CPBorder, cpBorderSize, db.cpBorderColor or (SCE.defaults and SCE.defaults.cpBorderColor) or {0,0,0,1})
end

local function updateAlpha()
  local db = StupidComboEnergyDB or {}
  local showCombo = shouldShowCombo(db)
  local showHealth = shouldShowHealth(db)
  local showPower = shouldShowPower(db)
  local showDruidMana = shouldShowDruidMana(db)
  local showCastbar = shouldShowCastbar(db)
  local showShiftIndicator = shouldShowShiftIndicator(db)
  local cpCount = SCE.comboPoints or 0
  local hideComboEmpty = (db.hideComboWhenEmpty == "1" and cpCount <= 0)
  local comboVisible = showCombo and not hideComboEmpty
  local alpha = 1

  local isPrimaryPower = isMana() or isEnergy() or isRage()
  if not isPrimaryPower then
    if (db.showWhenNotPower or db.showWhenNotEnergy) == "1" then
      alpha = db.notPowerAlpha or db.notEnergyAlpha or 0.35
    else
      alpha = 0
    end
  end

  if showPower then
    if alpha > 0 then
      Power:SetAlpha(alpha)
      Power:Show()
    else
      Power:SetAlpha(0)
      Power:Hide()
    end
  else
    Power:Hide()
  end

  if showHealth then
    Health:SetAlpha(1)
  end
  if showDruidMana then
    DruidMana:SetAlpha(1)
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

  if showShiftIndicator then
    local attach = db.shiftIndicatorAttach or "power"
    local targetAlpha = 1
    if attach == "power" or attach == "healthpower" or attach == "powerdruid" or attach == "healthpowerdruid" then
      targetAlpha = alpha
    end
    ShiftIndicator:SetAlpha(targetAlpha)
    if targetAlpha > 0 then
      ShiftIndicator:Show()
    else
      ShiftIndicator:Hide()
    end
  else
    ShiftIndicator:Hide()
  end

  if GroupGapLine then
    if showPower and comboVisible and SCE.powerComboAdjacent and db.grouped == "1" and db.groupGapLine == "1" and (db.gap or 0) > 0 and alpha > 0 then
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
  setColor(Health.bg, db.healthEmpty or (SCE.defaults and SCE.defaults.healthEmpty) or { 0, 0, 0, 0.7 })
  setBarColor(Health, db.healthStyle, db.healthFill, db.healthFill2)
  if db.healthTextColor then
    if Health.textLeft then
      Health.textLeft:SetTextColor(db.healthTextColor[1], db.healthTextColor[2], db.healthTextColor[3], db.healthTextColor[4] or 1)
    end
    if Health.textCenter then
      Health.textCenter:SetTextColor(db.healthTextColor[1], db.healthTextColor[2], db.healthTextColor[3], db.healthTextColor[4] or 1)
    end
    if Health.textRight then
      Health.textRight:SetTextColor(db.healthTextColor[1], db.healthTextColor[2], db.healthTextColor[3], db.healthTextColor[4] or 1)
    end
  end
  local powerStyle, powerFill, powerFill2, powerEmpty = getPowerPalette(db)
  setColor(Power.bg, powerEmpty)
  setBarColor(Power, powerStyle, powerFill, powerFill2)
  if db.powerTextColor then
    if Power.textLeft then
      Power.textLeft:SetTextColor(db.powerTextColor[1], db.powerTextColor[2], db.powerTextColor[3], db.powerTextColor[4] or 1)
    end
    if Power.textCenter then
      Power.textCenter:SetTextColor(db.powerTextColor[1], db.powerTextColor[2], db.powerTextColor[3], db.powerTextColor[4] or 1)
    end
    if Power.textRight then
      Power.textRight:SetTextColor(db.powerTextColor[1], db.powerTextColor[2], db.powerTextColor[3], db.powerTextColor[4] or 1)
    end
  end
  setColor(DruidMana.bg, db.druidManaEmpty or (SCE.defaults and SCE.defaults.druidManaEmpty) or { 0, 0, 0, 0.7 })
  setBarColor(DruidMana, db.druidManaStyle, db.druidManaFill, db.druidManaFill2)
  if db.druidManaTextColor then
    if DruidMana.textLeft then
      DruidMana.textLeft:SetTextColor(db.druidManaTextColor[1], db.druidManaTextColor[2], db.druidManaTextColor[3], db.druidManaTextColor[4] or 1)
    end
    if DruidMana.textCenter then
      DruidMana.textCenter:SetTextColor(db.druidManaTextColor[1], db.druidManaTextColor[2], db.druidManaTextColor[3], db.druidManaTextColor[4] or 1)
    end
    if DruidMana.textRight then
      DruidMana.textRight:SetTextColor(db.druidManaTextColor[1], db.druidManaTextColor[2], db.druidManaTextColor[3], db.druidManaTextColor[4] or 1)
    end
  end
  if db.shiftIndicatorTextColor and ShiftIndicator.text then
    ShiftIndicator.text:SetTextColor(db.shiftIndicatorTextColor[1], db.shiftIndicatorTextColor[2], db.shiftIndicatorTextColor[3], db.shiftIndicatorTextColor[4] or 1)
  end
  setColor(Castbar.bg, db.castbarEmpty or (SCE.defaults and SCE.defaults.castbarEmpty) or { 0, 0, 0, 0.7 })
  setBarColor(Castbar, db.castbarStyle, db.castbarFill, db.castbarFill2)
  if Castbar.textLeft and db.castbarTextColor then
    Castbar.textLeft:SetTextColor(db.castbarTextColor[1], db.castbarTextColor[2], db.castbarTextColor[3], db.castbarTextColor[4] or 1)
  end
  if Castbar.textRight and db.castbarTimeColor then
    Castbar.textRight:SetTextColor(db.castbarTimeColor[1], db.castbarTimeColor[2], db.castbarTimeColor[3], db.castbarTimeColor[4] or 1)
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
  local healthBorderSize = db.healthBorderSize or 0
  local powerBorderSize = db.powerBorderSize or 0
  local druidManaBorderSize = db.druidManaBorderSize or 0
  local castbarBorderSize = db.castbarBorderSize or 0
  local shiftBorderSize = db.shiftIndicatorBorderSize or 0
  local cpBorderSize = db.cpBorderSize or 0
  if pixel and SCE.snapToPixel then
    healthBorderSize = SCE.snapToPixel(healthBorderSize, pixel)
    powerBorderSize = SCE.snapToPixel(powerBorderSize, pixel)
    druidManaBorderSize = SCE.snapToPixel(druidManaBorderSize, pixel)
    castbarBorderSize = SCE.snapToPixel(castbarBorderSize, pixel)
    shiftBorderSize = SCE.snapToPixel(shiftBorderSize, pixel)
    cpBorderSize = SCE.snapToPixel(cpBorderSize, pixel)
  end
  if db.showOnlyActiveCombo == "1" and db.hideComboWhenEmpty == "1" then
    cpBorderSize = 0
  end
  applyBorder(HealthBorder, healthBorderSize, db.healthBorderColor or (SCE.defaults and SCE.defaults.healthBorderColor) or {0,0,0,1})
  applyBorder(PowerBorder, powerBorderSize, db.powerBorderColor or (SCE.defaults and SCE.defaults.powerBorderColor) or {0,0,0,1})
  applyBorder(DruidManaBorder, druidManaBorderSize, db.druidManaBorderColor or (SCE.defaults and SCE.defaults.druidManaBorderColor) or {0,0,0,1})
  applyBorder(CastbarBorder, castbarBorderSize, db.castbarBorderColor or (SCE.defaults and SCE.defaults.castbarBorderColor) or {0,0,0,1})
  applyBorder(ShiftIndicatorBorder, shiftBorderSize, db.shiftIndicatorBorderColor or {0,0,0,1})
  applyBorder(CPBorder, cpBorderSize, db.cpBorderColor or (SCE.defaults and SCE.defaults.cpBorderColor) or {0,0,0,1})
end

local function applyFonts()
  local db = StupidComboEnergyDB
  local font = db.powerTextFont or (SCE.defaults and SCE.defaults.powerTextFont) or "Fonts\\FRIZQT__.TTF"
  local size = db.powerTextSize or (SCE.defaults and SCE.defaults.powerTextSize) or 12
  if font and size then
    if Power.textLeft and Power.textLeft.SetFont then
      Power.textLeft:SetFont(font, size, "OUTLINE")
    end
    if Power.textCenter and Power.textCenter.SetFont then
      Power.textCenter:SetFont(font, size, "OUTLINE")
    end
    if Power.textRight and Power.textRight.SetFont then
      Power.textRight:SetFont(font, size, "OUTLINE")
    end
  end

  local hfont = db.healthTextFont or (SCE.defaults and SCE.defaults.healthTextFont) or font
  local hsize = db.healthTextSize or (SCE.defaults and SCE.defaults.healthTextSize) or size
  if hfont and hsize then
    if Health.textLeft and Health.textLeft.SetFont then
      Health.textLeft:SetFont(hfont, hsize, "OUTLINE")
    end
    if Health.textCenter and Health.textCenter.SetFont then
      Health.textCenter:SetFont(hfont, hsize, "OUTLINE")
    end
    if Health.textRight and Health.textRight.SetFont then
      Health.textRight:SetFont(hfont, hsize, "OUTLINE")
    end
  end

  local dfont = db.druidManaTextFont or (SCE.defaults and SCE.defaults.druidManaTextFont) or font
  local dsize = db.druidManaTextSize or (SCE.defaults and SCE.defaults.druidManaTextSize) or size
  if dfont and dsize then
    if DruidMana.textLeft and DruidMana.textLeft.SetFont then
      DruidMana.textLeft:SetFont(dfont, dsize, "OUTLINE")
    end
    if DruidMana.textCenter and DruidMana.textCenter.SetFont then
      DruidMana.textCenter:SetFont(dfont, dsize, "OUTLINE")
    end
    if DruidMana.textRight and DruidMana.textRight.SetFont then
      DruidMana.textRight:SetFont(dfont, dsize, "OUTLINE")
    end
  end

  local cfont = db.castbarTextFont or (SCE.defaults and SCE.defaults.castbarTextFont) or font
  local csize = db.castbarTextSize or (SCE.defaults and SCE.defaults.castbarTextSize) or size
  if Castbar.textLeft and Castbar.textLeft.SetFont then
    Castbar.textLeft:SetFont(cfont, csize, "OUTLINE")
  end
  if Castbar.textRight and Castbar.textRight.SetFont then
    Castbar.textRight:SetFont(cfont, csize, "OUTLINE")
  end

  local sfont = db.shiftIndicatorFont or (SCE.defaults and SCE.defaults.shiftIndicatorFont) or font
  local ssize = db.shiftIndicatorFontSize or (SCE.defaults and SCE.defaults.shiftIndicatorFontSize) or size
  if ShiftIndicator.text and ShiftIndicator.text.SetFont then
    ShiftIndicator.text:SetFont(sfont, ssize, "OUTLINE")
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
  
  Health:EnableMouse(not isLocked)
  Health:SetMovable(not isLocked)
  Power:EnableMouse(not isLocked)
  Power:SetMovable(not isLocked)
  DruidMana:EnableMouse(not isLocked)
  DruidMana:SetMovable(not isLocked)
  Castbar:EnableMouse(not isLocked)
  Castbar:SetMovable(not isLocked)
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
  groupStartX = nil,
  groupStartY = nil,
}

local lastPowerType = nil
local lastComboVisible = nil
local lastHealthVisible = nil
local lastPowerVisible = nil
local lastDruidManaVisible = nil
local lastCastbarVisible = nil
local lastShiftIndicatorVisible = nil

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

local function handleDragStart(frame)
  if StupidComboEnergyDB.locked == "1" then return end
  if StupidComboEnergyDB.grouped == "1" then
    dragState.groupStartX, dragState.groupStartY = getFrameOffset(frame)
  end
  frame:StartMoving()
end

local function handleDragStop(frame, prefix)
  frame:StopMovingOrSizing()
  local db = StupidComboEnergyDB
  local newX, newY = getFrameOffset(frame)
  
  if db.grouped == "1" then
    local deltaX = newX - (dragState.groupStartX or newX)
    local deltaY = newY - (dragState.groupStartY or newY)
    
    db.point = "CENTER"
    db.relativePoint = "CENTER"
    db.x = (db.x or 0) + deltaX
    db.y = (db.y or 0) + deltaY
  else
    db[prefix .. "Point"] = "CENTER"
    db[prefix .. "RelativePoint"] = "CENTER"
    db[prefix .. "X"] = math.floor(newX + 0.5)
    db[prefix .. "Y"] = math.floor(newY + 0.5)
  end
  
  layout()
end

CP:SetScript("OnDragStart", function() handleDragStart(CP) end)
CP:SetScript("OnDragStop", function() handleDragStop(CP, "cp") end)
Health:SetScript("OnDragStart", function() handleDragStart(Health) end)
Health:SetScript("OnDragStop", function() handleDragStop(Health, "health") end)
Power:SetScript("OnDragStart", function() handleDragStart(Power) end)
Power:SetScript("OnDragStop", function() handleDragStop(Power, "power") end)
DruidMana:SetScript("OnDragStart", function() handleDragStart(DruidMana) end)
DruidMana:SetScript("OnDragStop", function() handleDragStop(DruidMana, "druidMana") end)
Castbar:SetScript("OnDragStart", function() handleDragStart(Castbar) end)
Castbar:SetScript("OnDragStop", function() handleDragStop(Castbar, "castbar") end)

local function updateAll()
  local db = StupidComboEnergyDB or {}
  local showCombo = shouldShowCombo(db)
  local showHealth = shouldShowHealth(db)
  local showPower = shouldShowPower(db)
  local showDruidMana = shouldShowDruidMana(db)
  local showCastbar = shouldShowCastbar(db)
  local showShiftIndicator = shouldShowShiftIndicator(db)
  local cp = 0
  local powerKey = getPowerKey()
  if powerKey ~= lastPowerType
    or showCombo ~= lastComboVisible
    or showHealth ~= lastHealthVisible
    or showPower ~= lastPowerVisible
    or showDruidMana ~= lastDruidManaVisible
    or showCastbar ~= lastCastbarVisible
    or showShiftIndicator ~= lastShiftIndicatorVisible then
    lastPowerType = powerKey
    lastComboVisible = showCombo
    lastHealthVisible = showHealth
    lastPowerVisible = showPower
    lastDruidManaVisible = showDruidMana
    lastCastbarVisible = showCastbar
    lastShiftIndicatorVisible = showShiftIndicator
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

  if showHealth and SCE.updateHealth then
    SCE.updateHealth()
  end

  if showPower and SCE.updatePower then
    SCE.updatePower()
  end

  if showDruidMana and SCE.updateDruidMana then
    SCE.updateDruidMana()
  end

  if showCastbar and SCE.updateCastbar then
    SCE.updateCastbar()
  end
  
  if showShiftIndicator and SCE.updateShiftIndicator then
    SCE.updateShiftIndicator()
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
