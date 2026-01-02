StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS
SCE._moduleLoaded = SCE._moduleLoaded or {}
SCE._moduleLoaded.castbar = true

local GetTime = GetTime
local GetNetStats = GetNetStats
local floor = math.floor

local castState = {
  spell = nil,
  texture = nil,
  start = nil,
  duration = nil,
  channel = nil,
  delay = 0,
}

local pfEnv = nil
local function mod(a, b)
  if b == 0 then return 0 end
  if math.fmod then
    return math.fmod(a, b)
  end
  if math.mod then
    return math.mod(a, b)
  end
  return a - floor(a / b) * b
end

local function isEnabled(val, defaultOn)
  if val == nil then
    return defaultOn and true or false
  end
  return val == "1" or val == 1 or val == true
end

local function clearCastState()
  castState.spell = nil
  castState.texture = nil
  castState.start = nil
  castState.duration = nil
  castState.channel = nil
  castState.delay = 0
end

local function getPfUICastInfo()
  if not pfUI or not pfUI.api or not pfUI.api.libcast then return nil end
  local libcast = pfUI.api.libcast
  if not libcast.db then return nil end

  local playerName = UnitName and UnitName("player") or nil
  local _, guid = UnitExists and UnitExists("player")
  local db = nil
  if guid and libcast.db[guid] then
    db = libcast.db[guid]
  elseif playerName and libcast.db[playerName] then
    db = libcast.db[playerName]
  end

  if not db or not db.cast or not db.start or not db.casttime then return nil end
  if db.start + (db.casttime / 1000) <= GetTime() then return nil end

  local start = db.start
  local finish = start + (db.casttime / 1000)
  return db.cast, db.icon, start, finish, db.channel, nil, true
end

local function getSpellTextureSafe(spell)
  if not spell then return nil end
  if _G.GetSpellTexture then
    local ok, tex = pcall(_G.GetSpellTexture, spell)
    if ok and tex then return tex end
  end
  if _G.GetSpellInfo then
    local ok, _, _, tex = pcall(_G.GetSpellInfo, spell)
    if ok then
      return tex
    end
  end
  return nil
end

local function normalizeCastTimes(startTime, endTime)
  local s = tonumber(startTime)
  local e = tonumber(endTime)
  if not s or not e then return nil, nil end
  if e > 100000 then
    return s / 1000, e / 1000
  end
  return s, e
end

local function initCastbar()
  local bar = SCE.Castbar
  if not bar then return end
  if bar.textLeft then return end

  bar.textLeft = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  bar.textLeft:SetPoint("LEFT", bar, "LEFT", 4, 0)
  bar.textLeft:SetJustifyH("LEFT")

  bar.textRight = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  bar.textRight:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
  bar.textRight:SetJustifyH("RIGHT")

  bar.icon = CreateFrame("Frame", nil, bar)
  bar.icon:SetPoint("LEFT", bar, "LEFT", 0, 0)
  bar.icon.tex = bar.icon:CreateTexture(nil, "OVERLAY")
  bar.icon.tex:SetAllPoints()

  bar.lag = bar:CreateTexture(nil, "OVERLAY")
  bar.lag:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
  bar.lag:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

  if pfUI and pfUI.api and pfUI.api.CreateBackdrop then
    pfUI.api.CreateBackdrop(bar.icon, nil, true)
    if pfUI.api.CreateBackdropShadow then
      pfUI.api.CreateBackdropShadow(bar.icon)
    end
  end
end

local function getEventCastInfo()
  if not castState.spell or not castState.start or not castState.duration then
    return nil
  end
  if GetTime() > (castState.start + castState.duration + 0.25) then
    clearCastState()
    return nil
  end
  return castState.spell, castState.texture, castState.start, castState.start + castState.duration, castState.channel, castState.delay, true
end

local function updateCastbar()
  local bar = SCE.Castbar
  if not bar then return end
  initCastbar()

  local db = StupidComboEnergyDB or {}
  local showSpell = isEnabled(db.castbarShowSpell, true)
  local showTime = isEnabled(db.castbarShowTime, true)
  local showIcon = isEnabled(db.castbarShowIcon, true)
  local showLag = isEnabled(db.castbarShowLag, true)
  local cast, texture, startTime, endTime, channel, delay, timesAreSeconds
  if db.testMode == "1" then
    local maxv = 2.0
    local now = GetTime()
    local cur = mod(now, maxv)
    cast = "Test Cast"
    texture = "Interface\\Icons\\INV_Misc_QuestionMark"
    startTime = now - cur
    endTime = startTime + maxv
    channel = nil
    delay = 0
    timesAreSeconds = true
  else
    cast, texture, startTime, endTime, channel, delay, timesAreSeconds = getPfUICastInfo()
  end

  local envCasting, envChannel = nil, nil
  if not cast and pfUI and pfUI.GetEnvironment then
    if not pfEnv then
      pfEnv = pfUI:GetEnvironment()
    end
    envCasting = pfEnv and pfEnv.UnitCastingInfo or nil
    envChannel = pfEnv and pfEnv.UnitChannelInfo or nil
  end

  if not cast and envCasting then
    cast, _, _, texture, startTime, endTime = envCasting("player")
    timesAreSeconds = nil
  end
  if not cast and envChannel then
    channel, _, _, texture, startTime, endTime = envChannel("player")
    cast = channel
    timesAreSeconds = nil
  end

  local unitCasting = _G.UnitCastingInfo
  local unitChannel = _G.UnitChannelInfo
  if not cast and unitCasting then
    cast, _, _, texture, startTime, endTime = unitCasting("player")
    timesAreSeconds = nil
  end
  if not cast and unitChannel then
    channel, _, _, texture, startTime, endTime = unitChannel("player")
    cast = channel
    timesAreSeconds = nil
  end
  if not cast then
    cast, texture, startTime, endTime, channel, delay, timesAreSeconds = getEventCastInfo()
  end
  if not cast and CastingBarFrame and (CastingBarFrame.casting or CastingBarFrame.channeling) then
    channel = CastingBarFrame.channeling or nil
    cast = CastingBarFrame.spellName
    if not cast and CastingBarFrame.text then
      cast = CastingBarFrame.text:GetText()
    end
    if CastingBarFrame.icon then
      texture = CastingBarFrame.icon:GetTexture()
    end
    startTime = CastingBarFrame.startTime
    if CastingBarFrame.startTime and CastingBarFrame.maxValue then
      endTime = CastingBarFrame.startTime + CastingBarFrame.maxValue
    end
    timesAreSeconds = true
  end

  if not cast then
    bar:SetAlpha(0)
    bar._active = false
    bar:SetScript("OnUpdate", nil)
    if bar.textLeft then bar.textLeft:SetText("") end
    if bar.textRight then bar.textRight:SetText("") end
    if bar.icon then bar.icon:Hide() end
    if bar.lag then bar.lag:Hide() end
    return
  end

  bar:SetAlpha(1)
  bar._active = true
  if not bar:GetScript("OnUpdate") then
    bar:SetScript("OnUpdate", function()
      if SCE.updateCastbar then
        SCE.updateCastbar()
      end
    end)
  end

  local startSec, endSec
  if timesAreSeconds then
    startSec = tonumber(startTime)
    endSec = tonumber(endTime)
  else
    startSec, endSec = normalizeCastTimes(startTime, endTime)
  end
  if not startSec or not endSec then return end
  if not texture then
    texture = getSpellTextureSafe(cast)
  end
  local maxv = endSec - startSec
  if maxv <= 0 then maxv = 0.1 end
  local cur
  if channel then
    cur = endSec - GetTime()
  else
    cur = GetTime() - startSec
  end
  if cur < 0 then cur = 0 end
  if cur > maxv then cur = maxv end

  bar:SetMinMaxValues(0, maxv)
  bar:SetValue(cur)

  local style = db.castbarStyle or "solid"
  local c1, c2
  if channel then
    c1 = db.castbarChannelFill or (SCE.defaults and SCE.defaults.castbarChannelFill) or { 0.9, 0.9, 0.7, 0.95 }
    c2 = db.castbarChannelFill2 or (SCE.defaults and SCE.defaults.castbarChannelFill2) or { 0.7, 0.7, 0.5, 0.95 }
  else
    c1 = db.castbarFill or (SCE.defaults and SCE.defaults.castbarFill) or { 0.7, 0.7, 0.9, 0.95 }
    c2 = db.castbarFill2 or (SCE.defaults and SCE.defaults.castbarFill2) or { 0.5, 0.5, 0.7, 0.95 }
  end
  if SCE.setBarColor then
    SCE.setBarColor(bar, style, c1, c2)
  end

  if showSpell and bar.textLeft then
    bar.textLeft:SetText(cast)
  elseif bar.textLeft then
    bar.textLeft:SetText("")
  end

  if showTime and bar.textRight then
    if delay and delay > 0 then
      bar.textRight:SetText(string.format("+%.1f %.1f / %.1f", delay, cur, maxv))
    else
      bar.textRight:SetText(string.format("%.1f / %.1f", cur, maxv))
    end
  elseif bar.textRight then
    bar.textRight:SetText("")
  end

  if showIcon and bar.icon then
    local size = bar:GetHeight()
    if size <= 0 then size = 16 end
    bar.icon:SetWidth(size)
    bar.icon:SetHeight(size)
    bar.icon:Show()
    bar.icon:ClearAllPoints()
    if pfUI and pfUI.api and pfUI.api.GetBorderSize then
      local _, border = pfUI.api.GetBorderSize("unitframes")
      local spacing = (border or 1) * 2
      bar.icon:SetPoint("TOPRIGHT", bar, "TOPLEFT", -spacing, 0)
      bar.icon:SetPoint("BOTTOMRIGHT", bar, "BOTTOMLEFT", -spacing, 0)
    else
      bar.icon:SetPoint("LEFT", bar, "LEFT", 0, 0)
    end
    bar.icon.tex:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    bar.icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if bar.textLeft then
      bar.textLeft:ClearAllPoints()
      bar.textLeft:SetPoint("LEFT", bar, "LEFT", 4, 0)
    end
  else
    if bar.icon then bar.icon:Hide() end
    if bar.textLeft then
      bar.textLeft:ClearAllPoints()
      bar.textLeft:SetPoint("LEFT", bar, "LEFT", 4, 0)
    end
  end

  if showLag and bar.lag and GetNetStats then
    local _, _, lag = GetNetStats()
    local width = bar:GetWidth() * (lag / 1000) / maxv
    if width < 0 then width = 0 end
    if width > bar:GetWidth() then width = bar:GetWidth() end
    bar.lag:SetWidth(width)
    local c = db.castbarLagColor or (SCE.defaults and SCE.defaults.castbarLagColor) or { 1.0, 0.2, 0.2, 0.3 }
    bar.lag:SetTexture(c[1], c[2], c[3], c[4] or 0.3)
    bar.lag:Show()
  elseif bar.lag then
    bar.lag:Hide()
  end
end

local function setupCastbarScripts()
  local bar = SCE.Castbar
  if not bar then return end
  initCastbar()
  if SCE.applyFonts then
    SCE.applyFonts()
  end

  bar:RegisterEvent("SPELLCAST_START")
  bar:RegisterEvent("SPELLCAST_STOP")
  bar:RegisterEvent("SPELLCAST_FAILED")
  bar:RegisterEvent("SPELLCAST_INTERRUPTED")
  bar:RegisterEvent("SPELLCAST_DELAYED")
  bar:RegisterEvent("SPELLCAST_CHANNEL_START")
  bar:RegisterEvent("SPELLCAST_CHANNEL_STOP")
  bar:RegisterEvent("SPELLCAST_CHANNEL_UPDATE")
  bar:RegisterEvent("UNIT_SPELLCAST_START")
  bar:RegisterEvent("UNIT_SPELLCAST_STOP")
  bar:RegisterEvent("UNIT_SPELLCAST_FAILED")
  bar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
  bar:RegisterEvent("UNIT_SPELLCAST_DELAYED")
  bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
  bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
  bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
  bar:SetScript("OnEvent", function()
    local evt = event
    if not evt then return end

    if evt == "UNIT_SPELLCAST_START" or evt == "UNIT_SPELLCAST_CHANNEL_START" then
      if arg1 and arg1 ~= "player" then return end
      local unitCasting = _G.UnitCastingInfo
      local unitChannel = _G.UnitChannelInfo
      local cast, _, _, texture, startTime, endTime
      local channel = nil
      if evt == "UNIT_SPELLCAST_CHANNEL_START" and unitChannel then
        channel, _, _, texture, startTime, endTime = unitChannel("player")
        cast = channel
      elseif unitCasting then
        cast, _, _, texture, startTime, endTime = unitCasting("player")
      end
      if cast and startTime and endTime then
        local startSec, endSec = normalizeCastTimes(startTime, endTime)
        castState.spell = cast
        castState.texture = texture or getSpellTextureSafe(cast)
        castState.start = startSec
        castState.duration = endSec - startSec
        castState.channel = (evt == "UNIT_SPELLCAST_CHANNEL_START") and true or nil
        castState.delay = 0
      end
    elseif evt == "UNIT_SPELLCAST_STOP" or evt == "UNIT_SPELLCAST_FAILED" or evt == "UNIT_SPELLCAST_INTERRUPTED" or evt == "UNIT_SPELLCAST_CHANNEL_STOP" then
      if arg1 and arg1 ~= "player" then return end
      clearCastState()
    elseif evt == "UNIT_SPELLCAST_DELAYED" then
      if arg1 and arg1 ~= "player" then return end
      if castState.spell and not castState.channel and _G.UnitCastingInfo then
        local cast, _, _, _, startTime, endTime = _G.UnitCastingInfo("player")
        if cast and startTime and endTime then
          local startSec, endSec = normalizeCastTimes(startTime, endTime)
          castState.start = startSec
          castState.duration = endSec - startSec
        end
      end
    elseif evt == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
      if arg1 and arg1 ~= "player" then return end
      if castState.spell and castState.channel and _G.UnitChannelInfo then
        local cast, _, _, _, startTime, endTime = _G.UnitChannelInfo("player")
        if cast and startTime and endTime then
          local startSec, endSec = normalizeCastTimes(startTime, endTime)
          castState.start = startSec
          castState.duration = endSec - startSec
        end
      end
    elseif evt == "SPELLCAST_START" then
      castState.spell = arg1
      castState.texture = getSpellTextureSafe(arg1)
      castState.start = GetTime()
      castState.duration = (tonumber(arg2) or 0) / 1000
      castState.channel = nil
      castState.delay = 0
    elseif evt == "SPELLCAST_STOP" or evt == "SPELLCAST_FAILED" or evt == "SPELLCAST_INTERRUPTED" then
      clearCastState()
    elseif evt == "SPELLCAST_DELAYED" then
      if castState.spell and not castState.channel then
        local delay = (tonumber(arg1) or 0) / 1000
        castState.start = (castState.start or GetTime()) + delay
        castState.delay = (castState.delay or 0) + delay
      end
    elseif evt == "SPELLCAST_CHANNEL_START" then
      castState.spell = arg2
      castState.texture = getSpellTextureSafe(arg2)
      castState.start = GetTime()
      castState.duration = (tonumber(arg1) or 0) / 1000
      castState.channel = true
      castState.delay = 0
    elseif evt == "SPELLCAST_CHANNEL_UPDATE" then
      if castState.spell and castState.channel then
        local remaining = (tonumber(arg1) or 0) / 1000
        if castState.duration and castState.duration > 0 then
          castState.start = GetTime() + remaining - castState.duration
        end
      end
    elseif evt == "SPELLCAST_CHANNEL_STOP" then
      if castState.channel then
        clearCastState()
      end
    end

    if SCE.updateCastbar then
      SCE.updateCastbar()
    end
  end)
end

SCE.updateCastbar = updateCastbar
SCE.setupCastbarScripts = setupCastbarScripts

if SCE.debugMsg then
  SCE.debugMsg("Loaded module: castbar.lua")
end
