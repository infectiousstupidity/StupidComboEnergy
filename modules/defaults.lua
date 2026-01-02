StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS

SCE.ADDON = "StupidComboEnergy"
SCE.debugEnabled = false
SCE_DEBUG_LOG = SCE_DEBUG_LOG or {}
SCE._moduleLoaded = SCE._moduleLoaded or {}
SCE._moduleLoaded.defaults = true

function SCE.debugMsg(msg)
  if not SCE.debugEnabled then return end
  local line = (SCE.ADDON or "SCE") .. " DEBUG: " .. (msg or "")
  table.insert(SCE_DEBUG_LOG, line)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff" .. line .. "|r")
  elseif ChatFrame1 then
    ChatFrame1:AddMessage("|cff66ccff" .. line .. "|r")
  elseif UIErrorsFrame and UIErrorsFrame.AddMessage then
    UIErrorsFrame:AddMessage(line, 1, 0.6, 0.6, 1)
  end
end

-- Saved variables are declared in the TOC. Vanilla (Turtle) doesn't expose _G, so use direct globals.
StupidComboEnergyDB = StupidComboEnergyDB or {}

SCE.defaults = {
  point = "CENTER",
  relativePoint = "CENTER",
  x = 0,
  y = -140,

  width = 320,
  heightCP = 10,
  healthWidth = 320,
  healthHeight = 14,
  powerWidth = 320,
  powerHeight = 14,
  druidManaWidth = 320,
  druidManaHeight = 8,
  castbarWidth = 320,
  castbarHeight = 14,
  gap = 4,
  cpGap = 4,
  frameStrata = "MEDIUM",
  frameLevel = 2,
  
  -- Positioning mode (use "1"/"0" strings for Vanilla compatibility)
  grouped = "1",
  powerFirst = "1",
  groupAnchor = "CENTER",
  barOrderMode = "fixed",
  groupGapLine = "0",
  groupGapLineSize = 0, -- 0 = auto (use gap)
  groupGapLineColor = { 0.00, 0.00, 0.00, 1.0 },
  
  -- Separate positioning (when grouped = false)
  healthPoint = "CENTER",
  healthRelativePoint = "CENTER",
  healthX = 0,
  healthY = -100,

  powerPoint = "CENTER",
  powerRelativePoint = "CENTER",
  powerX = 0,
  powerY = -130,

  druidManaPoint = "CENTER",
  druidManaRelativePoint = "CENTER",
  druidManaX = 0,
  druidManaY = -100,

  castbarPoint = "CENTER",
  castbarRelativePoint = "CENTER",
  castbarX = 0,
  castbarY = -170,

  cpPoint = "CENTER",
  cpRelativePoint = "CENTER",
  cpX = 0,
  cpY = -150,

  -- Colors are {r,g,b,a} in 0..1
  powerFill = { 0.90, 0.85, 0.20, 0.95 },
  powerFill2 = { 0.75, 0.70, 0.15, 0.95 },
  powerStyle = "solid",
  powerEmpty = { 0.10, 0.10, 0.10, 0.70 },
  manaFill = { 0.20, 0.60, 0.90, 0.95 },
  manaFill2 = { 0.10, 0.40, 0.70, 0.95 },
  manaEmpty = { 0.10, 0.10, 0.10, 0.70 },
  rageFill = { 0.80, 0.20, 0.20, 0.95 },
  rageFill2 = { 0.65, 0.10, 0.10, 0.95 },
  rageEmpty = { 0.12, 0.06, 0.06, 0.70 },
  powerBorderColor = { 0.00, 0.00, 0.00, 0.85 },
  powerBorderSize = 1,
  powerTextFont = "Fonts\\FRIZQT__.TTF",
  powerTextSize = 12,
  powerTextColor = { 1.0, 1.0, 1.0, 1.0 },
  powerTextOffsetX = 0,
  powerTextOffsetY = 0,
  powerTextMode = "dynamic",
  powerTextLeft = "none",
  powerTextCenter = "powerdyn",
  powerTextRight = "none",
  powerTextLeftMana = "none",
  powerTextCenterMana = "powerdyn",
  powerTextRightMana = "none",
  powerTextLeftEnergy = "none",
  powerTextCenterEnergy = "powerdyn",
  powerTextRightEnergy = "none",
  powerTextLeftRage = "none",
  powerTextCenterRage = "powerdyn",
  powerTextRightRage = "none",
  powerTextLeftOffsetX = 0,
  powerTextLeftOffsetY = 0,
  powerTextCenterOffsetX = 0,
  powerTextCenterOffsetY = 0,
  powerTextRightOffsetX = 0,
  powerTextRightOffsetY = 0,
  powerAnchor = "CENTER",

  healthFill = { 0.20, 0.90, 0.20, 0.95 },
  healthFill2 = { 0.10, 0.70, 0.10, 0.95 },
  healthStyle = "solid",
  healthEmpty = { 0.10, 0.10, 0.10, 0.70 },
  healthBorderColor = { 0.00, 0.00, 0.00, 0.85 },
  healthBorderSize = 1,
  healthTextFont = "Fonts\\FRIZQT__.TTF",
  healthTextSize = 12,
  healthTextColor = { 1.0, 1.0, 1.0, 1.0 },
  healthTextOffsetX = 0,
  healthTextOffsetY = 0,
  healthTextLeft = "none",
  healthTextCenter = "healthminmaxperc",
  healthTextRight = "none",
  healthTextLeftOffsetX = 0,
  healthTextLeftOffsetY = 0,
  healthTextCenterOffsetX = 0,
  healthTextCenterOffsetY = 0,
  healthTextRightOffsetX = 0,
  healthTextRightOffsetY = 0,
  invertHealthBar = "0",
  verticalHealthBar = "0",

  druidManaFill = { 0.20, 0.60, 0.90, 0.95 },
  druidManaFill2 = { 0.10, 0.40, 0.70, 0.95 },
  druidManaStyle = "solid",
  druidManaEmpty = { 0.10, 0.10, 0.10, 0.70 },
  druidManaBorderColor = { 0.00, 0.00, 0.00, 0.85 },
  druidManaBorderSize = 1,
  druidManaTextFont = "Fonts\\FRIZQT__.TTF",
  druidManaTextSize = 12,
  druidManaTextColor = { 1.0, 1.0, 1.0, 1.0 },
  druidManaTextOffsetX = 0,
  druidManaTextOffsetY = 0,
  druidManaTextLeft = "none",
  druidManaTextCenter = "powerdyn",
  druidManaTextRight = "none",
  druidManaTextLeftOffsetX = 0,
  druidManaTextLeftOffsetY = 0,
  druidManaTextCenterOffsetX = 0,
  druidManaTextCenterOffsetY = 0,
  druidManaTextRightOffsetX = 0,
  druidManaTextRightOffsetY = 0,

  castbarStyle = "solid",
  castbarFill = { 0.70, 0.70, 0.90, 0.95 },
  castbarFill2 = { 0.50, 0.50, 0.70, 0.95 },
  castbarChannelFill = { 0.90, 0.90, 0.70, 0.95 },
  castbarChannelFill2 = { 0.70, 0.70, 0.50, 0.95 },
  castbarEmpty = { 0.10, 0.10, 0.10, 0.70 },
  castbarBorderColor = { 0.00, 0.00, 0.00, 0.85 },
  castbarBorderSize = 1,
  castbarTextFont = "Fonts\\FRIZQT__.TTF",
  castbarTextSize = 12,
  castbarTextColor = { 1.0, 1.0, 1.0, 1.0 },
  castbarTimeColor = { 1.0, 1.0, 1.0, 1.0 },
  castbarTextOffsetX = 0,
  castbarTextOffsetY = 0,
  castbarShowIcon = "1",
  castbarShowSpell = "1",
  castbarShowTime = "1",
  castbarShowLag = "1",
  castbarLagColor = { 1.0, 0.2, 0.2, 0.3 },
  castbarIconSide = "left",
  castbarTextPosition = "left",
  castbarReplaceCombo = "0",

  cpFill   = { 0.95, 0.75, 0.10, 0.95 },
  cpFill2  = { 0.80, 0.60, 0.05, 0.95 },
  cpStyle  = "solid",
  cpEmpty  = { 0.25, 0.25, 0.25, 0.70 },
  cpColorMode = "unified", -- "unified", "finisher", "split"
  cpFillBase = { 0.95, 0.75, 0.10, 0.95 },
  cpFillBase2 = { 0.80, 0.60, 0.05, 0.95 },
  cpFillMid = { 0.90, 0.55, 0.10, 0.95 },
  cpFillMid2 = { 0.70, 0.40, 0.10, 0.95 },
  cpFillFinisher = { 0.90, 0.15, 0.15, 0.95 },
  cpFillFinisher2 = { 0.70, 0.10, 0.10, 0.95 },
  cpBorderColor = { 0.00, 0.00, 0.00, 0.85 },
  cpBorderSize = 1,

  frameBg  = { 0.00, 0.00, 0.00, 0.35 },

  debugEnabled = "0",
  showPowerBar = "1",
  showComboBar = "1",
  showHealthBar = "0",
  showDruidManaBar = "0",
  showCastbar = "0",
  showShiftIndicator = "0",
  hideComboWhenEmpty = "0",
  showOnlyActiveCombo = "0",
  showWhenNotPower = "1",
  notPowerAlpha = 0.35,
  testMode = "0",
  
  showPowerTicker = "0",
  powerTickerColor = { 1.0, 1.0, 1.0, 0.8 },
  powerTickerGlow = "1",  -- "1" for spark/glow, "0" for solid line
  powerTickerWidth = 16,   -- Width of ticker (larger for glow effect)
  
  -- Combo point separator style: "gap" for gaps between, "gapline" for lines inside gaps, "border" for separator lines
  cpSeparatorStyle = "gap",
  cpSeparatorWidth = 2,  -- Width of separator lines (border style)
  cpSeparatorColor = { 0.00, 0.00, 0.00, 1.0 },  -- Separator line color

  -- Smoothing model:
  -- Vanilla energy regen is usually 20 energy per 2 seconds = 10 per second.
  powerRegenPerSec = 10,
  powerTickSeconds = 2.0,

  locked = "1",

  shiftIndicatorAttach = "power",
  shiftIndicatorAttachMode = "fixed",
  shiftIndicatorAttachMana = "power",
  shiftIndicatorAttachEnergy = "power",
  shiftIndicatorAttachRage = "power",
  shiftIndicatorAnchor = "LEFT",
  shiftIndicatorSpacing = 2,
  shiftIndicatorOffsetX = 0,
  shiftIndicatorOffsetY = 0,
  shiftIndicatorSize = 0,
  shiftIndicatorTextOffsetX = 0,
  shiftIndicatorTextOffsetY = 0,
  shiftIndicatorIconMode = "bear",
  shiftIndicatorCustomIcon = "",
  shiftIndicatorDesaturate = "1",
  shiftIndicatorShowZero = "1",
  shiftIndicatorUpdateInterval = 0.5,
  shiftIndicatorFont = "Fonts\\FRIZQT__.TTF",
  shiftIndicatorFontSize = 20,
  shiftIndicatorTextColor = { 1.0, 0.82, 0.0, 1.0 },
  shiftIndicatorBorderSize = 0,
  shiftIndicatorBorderColor = { 0.00, 0.00, 0.00, 0.85 },
}

function SCE.clamp(x, lo, hi)
  if x < lo then return lo end
  if x > hi then return hi end
  return x
end

function SCE.round(x, places)
  local mult = 10 ^ (places or 0)
  return math.floor(x * mult + 0.5) / mult
end

function SCE.abbreviate(num)
  if pfUI and pfUI.api and pfUI.api.Abbreviate then
    return tostring(pfUI.api.Abbreviate(num))
  end
  local sign = num < 0 and -1 or 1
  local n = math.abs(num)
  if n >= 1000000 then
    return tostring(SCE.round(n / 1000000 * sign, 2)) .. "m"
  elseif n >= 1000 then
    return tostring(SCE.round(n / 1000 * sign, 2)) .. "k"
  end
  return tostring(num)
end

function SCE.getUnitHealth(unit)
  local cur1, cur2 = UnitHealth(unit)
  local max1, max2 = UnitHealthMax(unit)
  local cur = cur1
  local maxv = max1

  if max2 ~= nil then
    maxv = max2
    if cur2 ~= nil and cur2 ~= maxv then
      cur = cur2
    else
      cur = cur1
    end
  elseif max1 == nil and cur2 ~= nil then
    maxv = cur2
  end

  return cur or 0, maxv or 0
end

function SCE.getUnitPower(unit)
  local cur1, cur2 = UnitMana(unit)
  local max1, max2 = UnitManaMax(unit)
  local cur = cur1
  local maxv = max1

  if cur2 ~= nil and max2 ~= nil and cur1 == max1 and type(cur1) == "number" and cur1 >= 0 and cur1 <= 4 then
    cur = cur2
    maxv = max2
  elseif max1 == nil and cur2 ~= nil then
    cur = cur1
    maxv = cur2
  end

  return cur or 0, maxv or 0
end

function SCE.copyColor(c)
  return { c[1], c[2], c[3], c[4] }
end

function SCE.buildDefaultBarOrder(db)
  local order = { "health", "druidmana" }
  if db and db.powerFirst == "0" then
    table.insert(order, "combo")
    table.insert(order, "power")
  else
    table.insert(order, "power")
    table.insert(order, "combo")
  end
  table.insert(order, "castbar")
  return order
end

function SCE.sanitizeBarOrder(order, db, fallback)
  local result = {}
  local seen = {}
  local hasNone = false
  if type(order) == "table" then
    for i = 1, table.getn(order) do
      local key = order[i]
      if key == "none" then
        table.insert(result, "none")
        hasNone = true
      elseif key == "health" or key == "power" or key == "druidmana" or key == "combo" or key == "castbar" then
        if not seen[key] then
          seen[key] = true
          table.insert(result, key)
        else
          table.insert(result, "none")
          hasNone = true
        end
      end
    end
  end

  if table.getn(result) < 5 then
    local fill = fallback
    if not fill and not hasNone then
      fill = SCE.buildDefaultBarOrder(db)
    end
    if fill then
      for i = 1, table.getn(fill) do
        local key = fill[i]
        if table.getn(result) >= 5 then break end
        if key and key ~= "none" and not seen[key] then
          seen[key] = true
          table.insert(result, key)
        end
      end
    end
  end

  while table.getn(result) < 5 do
    table.insert(result, "none")
  end
  while table.getn(result) > 5 do
    table.remove(result)
  end

  return result
end

function SCE.usesShiftText(db)
  db = db or StupidComboEnergyDB or {}
  local function isShift(mode)
    return mode == "shiftcasts"
  end

  if isShift(db.healthTextLeft) or isShift(db.healthTextCenter) or isShift(db.healthTextRight) then return true end
  if isShift(db.powerTextLeft) or isShift(db.powerTextCenter) or isShift(db.powerTextRight) then return true end
  if isShift(db.powerTextLeftMana) or isShift(db.powerTextCenterMana) or isShift(db.powerTextRightMana) then return true end
  if isShift(db.powerTextLeftEnergy) or isShift(db.powerTextCenterEnergy) or isShift(db.powerTextRightEnergy) then return true end
  if isShift(db.powerTextLeftRage) or isShift(db.powerTextCenterRage) or isShift(db.powerTextRightRage) then return true end
  if isShift(db.druidManaTextLeft) or isShift(db.druidManaTextCenter) or isShift(db.druidManaTextRight) then return true end
  return false
end

function SCE.getShiftCastsText(db)
  db = db or StupidComboEnergyDB or {}
  if UnitClass then
    local _, class = UnitClass("player")
    if class and class ~= "DRUID" then
      return ""
    end
  end
  local casts = tonumber(SCE.shiftCasts) or 0
  if casts <= 0 and db.shiftIndicatorShowZero ~= "1" then
    return ""
  end
  return tostring(casts)
end

function SCE.applyDebugSetting()
  local db = StupidComboEnergyDB or {}
  SCE.debugEnabled = (db.debugEnabled == "1")
end

function SCE.getPerfectPixel()
  if pfUI and pfUI.api and pfUI.api.GetPerfectPixel then
    return pfUI.api.GetPerfectPixel()
  end

  if SCE._pixel then return SCE._pixel end

  local scale = tonumber(GetCVar("uiScale")) or 1
  local resolution = GetCVar("gxResolution") or ""
  local _, _, w, h = string.find(resolution, "(%d+)x(%d+)")
  local screenheight = tonumber(h) or 768

  local pixel = 768 / screenheight / scale
  if pixel > 1 then pixel = 1 end
  SCE._pixel = pixel
  return pixel
end

function SCE.snapToPixel(value, pixel)
  local p = pixel or SCE.getPerfectPixel()
  if not p or p == 0 then return value end
  return math.floor((value / p) + 0.5) * p
end

function SCE.ensureDB()
  if type(StupidComboEnergyDB) ~= "table" then
    StupidComboEnergyDB = {}
  end
  if StupidComboEnergyDB._powerbarMigrated ~= "1" then
    local db = StupidComboEnergyDB
    local function copyValue(src, dest)
      if db[src] ~= nil then
        db[dest] = db[src]
      end
    end
    local function copyColor(src, dest)
      if type(db[src]) == "table" then
        db[dest] = SCE.copyColor(db[src])
      end
    end

    copyValue("showEnergyBar", "showPowerBar")
    copyValue("energyFirst", "powerFirst")
    copyValue("energyPoint", "powerPoint")
    copyValue("energyRelativePoint", "powerRelativePoint")
    copyValue("energyX", "powerX")
    copyValue("energyY", "powerY")
    copyValue("heightEnergy", "powerHeight")

    copyValue("energyStyle", "powerStyle")
    copyColor("energyFill", "powerFill")
    copyColor("energyFill2", "powerFill2")
    copyColor("energyEmpty", "powerEmpty")
    copyColor("energyBorderColor", "powerBorderColor")
    copyValue("energyBorderSize", "powerBorderSize")
    copyValue("energyTextFont", "powerTextFont")
    copyValue("energyTextSize", "powerTextSize")
    copyColor("energyTextColor", "powerTextColor")
    copyValue("energyTextOffsetX", "powerTextOffsetX")
    copyValue("energyTextOffsetY", "powerTextOffsetY")

    copyValue("showWhenNotEnergy", "showWhenNotPower")
    copyValue("notEnergyAlpha", "notPowerAlpha")
    copyValue("showEnergyTicker", "showPowerTicker")
    copyColor("energyTickerColor", "powerTickerColor")
    copyValue("energyTickerGlow", "powerTickerGlow")
    copyValue("energyTickerWidth", "powerTickerWidth")
    copyValue("energyRegenPerSec", "powerRegenPerSec")
    copyValue("energyTickSeconds", "powerTickSeconds")

    db.showEnergyBar = nil
    db.energyFirst = nil
    db.energyPoint = nil
    db.energyRelativePoint = nil
    db.energyX = nil
    db.energyY = nil
    db.heightEnergy = nil
    db.energyStyle = nil
    db.energyFill = nil
    db.energyFill2 = nil
    db.energyEmpty = nil
    db.energyBorderColor = nil
    db.energyBorderSize = nil
    db.energyTextFont = nil
    db.energyTextSize = nil
    db.energyTextColor = nil
    db.energyTextOffsetX = nil
    db.energyTextOffsetY = nil
    db.showWhenNotEnergy = nil
    db.notEnergyAlpha = nil
    db.showEnergyTicker = nil
    db.energyTickerColor = nil
    db.energyTickerGlow = nil
    db.energyTickerWidth = nil
    db.energyRegenPerSec = nil
    db.energyTickSeconds = nil

    db._powerbarMigrated = "1"
  end

  if StupidComboEnergyDB.powerTextCenter == nil and StupidComboEnergyDB.powerTextMode then
    if StupidComboEnergyDB.powerTextMode == "dynamic" then
      StupidComboEnergyDB.powerTextCenter = "powerdyn"
    elseif StupidComboEnergyDB.powerTextMode == "current" then
      StupidComboEnergyDB.powerTextCenter = "power"
    elseif StupidComboEnergyDB.powerTextMode == "minmax" then
      StupidComboEnergyDB.powerTextCenter = "powerminmax"
    elseif StupidComboEnergyDB.powerTextMode == "percent" then
      StupidComboEnergyDB.powerTextCenter = "powerperc"
    end
  end

  if StupidComboEnergyDB.powerTextLeftMana == nil then
    StupidComboEnergyDB.powerTextLeftMana = StupidComboEnergyDB.powerTextLeft
  end
  if StupidComboEnergyDB.powerTextCenterMana == nil then
    StupidComboEnergyDB.powerTextCenterMana = StupidComboEnergyDB.powerTextCenter or "powerdyn"
  end
  if StupidComboEnergyDB.powerTextRightMana == nil then
    StupidComboEnergyDB.powerTextRightMana = StupidComboEnergyDB.powerTextRight
  end

  if StupidComboEnergyDB.powerTextLeftEnergy == nil then
    StupidComboEnergyDB.powerTextLeftEnergy = StupidComboEnergyDB.powerTextLeft
  end
  if StupidComboEnergyDB.powerTextCenterEnergy == nil then
    StupidComboEnergyDB.powerTextCenterEnergy = StupidComboEnergyDB.powerTextCenter or "powerdyn"
  end
  if StupidComboEnergyDB.powerTextRightEnergy == nil then
    StupidComboEnergyDB.powerTextRightEnergy = StupidComboEnergyDB.powerTextRight
  end

  if StupidComboEnergyDB.powerTextLeftRage == nil then
    StupidComboEnergyDB.powerTextLeftRage = StupidComboEnergyDB.powerTextLeft
  end
  if StupidComboEnergyDB.powerTextCenterRage == nil then
    StupidComboEnergyDB.powerTextCenterRage = StupidComboEnergyDB.powerTextCenter or "powerdyn"
  end
  if StupidComboEnergyDB.powerTextRightRage == nil then
    StupidComboEnergyDB.powerTextRightRage = StupidComboEnergyDB.powerTextRight
  end

  if StupidComboEnergyDB.druidManaTextLeft == nil then
    StupidComboEnergyDB.druidManaTextLeft = "none"
  end
  if StupidComboEnergyDB.druidManaTextCenter == nil then
    StupidComboEnergyDB.druidManaTextCenter = StupidComboEnergyDB.powerTextCenter or StupidComboEnergyDB.powerTextMode or "powerdyn"
  end
  if StupidComboEnergyDB.druidManaTextRight == nil then
    StupidComboEnergyDB.druidManaTextRight = "none"
  end

  if StupidComboEnergyDB.powerTextCenterOffsetX == nil and StupidComboEnergyDB.powerTextOffsetX ~= nil then
    StupidComboEnergyDB.powerTextCenterOffsetX = StupidComboEnergyDB.powerTextOffsetX
  end
  if StupidComboEnergyDB.powerTextCenterOffsetY == nil and StupidComboEnergyDB.powerTextOffsetY ~= nil then
    StupidComboEnergyDB.powerTextCenterOffsetY = StupidComboEnergyDB.powerTextOffsetY
  end
  if StupidComboEnergyDB.healthTextCenterOffsetX == nil and StupidComboEnergyDB.healthTextOffsetX ~= nil then
    StupidComboEnergyDB.healthTextCenterOffsetX = StupidComboEnergyDB.healthTextOffsetX
  end
  if StupidComboEnergyDB.healthTextCenterOffsetY == nil and StupidComboEnergyDB.healthTextOffsetY ~= nil then
    StupidComboEnergyDB.healthTextCenterOffsetY = StupidComboEnergyDB.healthTextOffsetY
  end
  if StupidComboEnergyDB.druidManaTextCenterOffsetX == nil and StupidComboEnergyDB.druidManaTextOffsetX ~= nil then
    StupidComboEnergyDB.druidManaTextCenterOffsetX = StupidComboEnergyDB.druidManaTextOffsetX
  end
  if StupidComboEnergyDB.druidManaTextCenterOffsetY == nil and StupidComboEnergyDB.druidManaTextOffsetY ~= nil then
    StupidComboEnergyDB.druidManaTextCenterOffsetY = StupidComboEnergyDB.druidManaTextOffsetY
  end

  if StupidComboEnergyDB._shiftIndicatorBorderMigrated ~= "1" then
    if StupidComboEnergyDB.shiftIndicatorBorderSize == 1 then
      StupidComboEnergyDB.shiftIndicatorBorderSize = 0
    end
    StupidComboEnergyDB._shiftIndicatorBorderMigrated = "1"
  end

  if type(StupidComboEnergyDB.barOrder) ~= "table" then
    if SCE.buildDefaultBarOrder then
      StupidComboEnergyDB.barOrder = SCE.buildDefaultBarOrder(StupidComboEnergyDB)
    else
      StupidComboEnergyDB.barOrder = { "health", "druidmana", "power", "combo", "castbar" }
    end
  elseif SCE.sanitizeBarOrder then
    StupidComboEnergyDB.barOrder = SCE.sanitizeBarOrder(StupidComboEnergyDB.barOrder, StupidComboEnergyDB)
  end

  if type(StupidComboEnergyDB.barOrder) == "table" then
    local powerIndex, comboIndex
    for i = 1, table.getn(StupidComboEnergyDB.barOrder) do
      local key = StupidComboEnergyDB.barOrder[i]
      if key == "power" then powerIndex = i end
      if key == "combo" then comboIndex = i end
    end
    if powerIndex and comboIndex then
      StupidComboEnergyDB.powerFirst = (powerIndex < comboIndex) and "1" or "0"
    end
  end

  if StupidComboEnergyDB.barOrderMode == nil then
    StupidComboEnergyDB.barOrderMode = "fixed"
  end
  if StupidComboEnergyDB.groupAnchor ~= "TOP" and StupidComboEnergyDB.groupAnchor ~= "BOTTOM" and StupidComboEnergyDB.groupAnchor ~= "CENTER" then
    StupidComboEnergyDB.groupAnchor = "CENTER"
  end
  if StupidComboEnergyDB.shiftIndicatorAttachMode ~= "fixed" and StupidComboEnergyDB.shiftIndicatorAttachMode ~= "power" then
    StupidComboEnergyDB.shiftIndicatorAttachMode = "fixed"
  end
  if StupidComboEnergyDB.shiftIndicatorAttachMana == nil then
    StupidComboEnergyDB.shiftIndicatorAttachMana = StupidComboEnergyDB.shiftIndicatorAttach or "power"
  end
  if StupidComboEnergyDB.shiftIndicatorAttachEnergy == nil then
    StupidComboEnergyDB.shiftIndicatorAttachEnergy = StupidComboEnergyDB.shiftIndicatorAttach or "power"
  end
  if StupidComboEnergyDB.shiftIndicatorAttachRage == nil then
    StupidComboEnergyDB.shiftIndicatorAttachRage = StupidComboEnergyDB.shiftIndicatorAttach or "power"
  end

  local function ensureOrderList(key, fallback)
    if type(StupidComboEnergyDB[key]) ~= "table" then
      StupidComboEnergyDB[key] = SCE.sanitizeBarOrder and SCE.sanitizeBarOrder(fallback, StupidComboEnergyDB, fallback) or fallback
    elseif SCE.sanitizeBarOrder then
      StupidComboEnergyDB[key] = SCE.sanitizeBarOrder(StupidComboEnergyDB[key], StupidComboEnergyDB, fallback)
    end
  end

  local baseOrder = StupidComboEnergyDB.barOrder
  if type(baseOrder) ~= "table" then
    baseOrder = SCE.buildDefaultBarOrder and SCE.buildDefaultBarOrder(StupidComboEnergyDB) or { "health", "druidmana", "power", "combo", "castbar" }
  end
  ensureOrderList("barOrderMana", baseOrder)
  ensureOrderList("barOrderEnergy", baseOrder)
  ensureOrderList("barOrderRage", baseOrder)

  if StupidComboEnergyDB.frameStrata ~= "MEDIUM" then
    StupidComboEnergyDB.frameStrata = "MEDIUM"
  end
  if StupidComboEnergyDB.frameLevel == nil or StupidComboEnergyDB.frameLevel < 1 or StupidComboEnergyDB.frameLevel > 5 then
    StupidComboEnergyDB.frameLevel = 2
  end
  for k, v in pairs(SCE.defaults) do
    if StupidComboEnergyDB[k] == nil then
      if type(v) == "table" then
        StupidComboEnergyDB[k] = SCE.copyColor(v)
      else
        StupidComboEnergyDB[k] = v
      end
    end
  end

  -- Migrate old combo color mode names and fields
  if StupidComboEnergyDB.cpColorMode == "single" then
    StupidComboEnergyDB.cpColorMode = "unified"
  elseif StupidComboEnergyDB.cpColorMode == "1to4_5" then
    StupidComboEnergyDB.cpColorMode = "finisher"
  elseif StupidComboEnergyDB.cpColorMode == "1to2_3to4_5" then
    StupidComboEnergyDB.cpColorMode = "split"
  end

  if StupidComboEnergyDB.cpFillBase == nil and StupidComboEnergyDB.cpFill1to4 then
    StupidComboEnergyDB.cpFillBase = SCE.copyColor(StupidComboEnergyDB.cpFill1to4)
  end
  if StupidComboEnergyDB.cpFillBase == nil and StupidComboEnergyDB.cpFill1to2 then
    StupidComboEnergyDB.cpFillBase = SCE.copyColor(StupidComboEnergyDB.cpFill1to2)
  end
  if StupidComboEnergyDB.cpFillMid == nil and StupidComboEnergyDB.cpFill3to4 then
    StupidComboEnergyDB.cpFillMid = SCE.copyColor(StupidComboEnergyDB.cpFill3to4)
  end
  if StupidComboEnergyDB.cpFillFinisher == nil and StupidComboEnergyDB.cpFill5 then
    StupidComboEnergyDB.cpFillFinisher = SCE.copyColor(StupidComboEnergyDB.cpFill5)
  end

  StupidComboEnergyDB.cpFill1to4 = nil
  StupidComboEnergyDB.cpFill1to2 = nil
  StupidComboEnergyDB.cpFill3to4 = nil
  StupidComboEnergyDB.cpFill5 = nil

  if SCE.applyDebugSetting then
    SCE.applyDebugSetting()
  end
end

function SCE.printMsg(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00" .. (SCE.ADDON or "SCE") .. "|r " .. (msg or ""))
  end
end

if SCE.debugMsg then
  SCE.debugMsg("Loaded module: defaults.lua")
end
