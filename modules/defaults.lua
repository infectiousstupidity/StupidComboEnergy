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
  heightEnergy = 14,
  heightCP = 10,
  gap = 4,
  cpGap = 4,
  frameStrata = "DIALOG",
  frameLevel = 200,
  
  -- Positioning mode (use "1"/"0" strings for Vanilla compatibility)
  grouped = "1",
  energyFirst = "1",
  groupGapLine = "0",
  groupGapLineSize = 0, -- 0 = auto (use gap)
  groupGapLineColor = { 0.00, 0.00, 0.00, 1.0 },
  
  -- Separate positioning (when grouped = false)
  energyPoint = "CENTER",
  energyRelativePoint = "CENTER",
  energyX = 0,
  energyY = -130,
  
  cpPoint = "CENTER",
  cpRelativePoint = "CENTER",
  cpX = 0,
  cpY = -150,

  -- Colors are {r,g,b,a} in 0..1
  energyFill = { 0.90, 0.85, 0.20, 0.95 },
  energyFill2 = { 0.75, 0.70, 0.15, 0.95 },
  energyStyle = "solid",
  energyEmpty = { 0.10, 0.10, 0.10, 0.70 },
  rageFill = { 0.80, 0.20, 0.20, 0.95 },
  rageFill2 = { 0.65, 0.10, 0.10, 0.95 },
  rageEmpty = { 0.12, 0.06, 0.06, 0.70 },
  energyBorderColor = { 0.00, 0.00, 0.00, 0.85 },
  energyBorderSize = 1,
  energyTextFont = "Fonts\\FRIZQT__.TTF",
  energyTextSize = 12,
  energyTextColor = { 1.0, 1.0, 1.0, 1.0 },
  energyTextOffsetX = 0,
  energyTextOffsetY = 0,

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
  showEnergyBar = "1",
  showComboBar = "1",
  hideComboWhenEmpty = "0",
  showOnlyActiveCombo = "0",
  showWhenNotEnergy = "1",
  notEnergyAlpha = 0.35,
  
  showEnergyTicker = "0",
  energyTickerColor = { 1.0, 1.0, 1.0, 0.8 },
  energyTickerGlow = "1",  -- "1" for spark/glow, "0" for solid line
  energyTickerWidth = 16,   -- Width of ticker (larger for glow effect)
  
  -- Combo point separator style: "gap" for gaps between, "gapline" for lines inside gaps, "border" for separator lines
  cpSeparatorStyle = "gap",
  cpSeparatorWidth = 2,  -- Width of separator lines (border style)
  cpSeparatorColor = { 0.00, 0.00, 0.00, 1.0 },  -- Separator line color

  -- Smoothing model:
  -- Vanilla energy regen is usually 20 energy per 2 seconds = 10 per second.
  energyRegenPerSec = 10,
  energyTickSeconds = 2.0,

  locked = "1",
}

function SCE.clamp(x, lo, hi)
  if x < lo then return lo end
  if x > hi then return hi end
  return x
end

function SCE.copyColor(c)
  return { c[1], c[2], c[3], c[4] }
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
