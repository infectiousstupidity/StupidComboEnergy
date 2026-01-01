StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS
SCE._moduleLoaded = SCE._moduleLoaded or {}
SCE._moduleLoaded.powerbar = true

local GetTime = GetTime
local floor = math.floor

local state = {
  lastPower = 0,
  lastPowerMax = 100,
  tickStart = nil,
  tickDuration = 2,
}

local function getPowerTextModes(db, isMana, isRage)
  if isMana then
    return db.powerTextLeftMana or db.powerTextLeft or "none",
      db.powerTextCenterMana or db.powerTextCenter or db.powerTextMode or "powerdyn",
      db.powerTextRightMana or db.powerTextRight or "none"
  elseif isRage then
    return db.powerTextLeftRage or db.powerTextLeft or "none",
      db.powerTextCenterRage or db.powerTextCenter or db.powerTextMode or "powerdyn",
      db.powerTextRightRage or db.powerTextRight or "none"
  end
  return db.powerTextLeftEnergy or db.powerTextLeft or "none",
    db.powerTextCenterEnergy or db.powerTextCenter or db.powerTextMode or "powerdyn",
    db.powerTextRightEnergy or db.powerTextRight or "none"
end

local function formatPowerText(mode, cur, maxv, forceMana)
  if not mode or mode == "none" then return "" end
  local isMana = forceMana or (SCE.isMana and SCE.isMana()) or false
  local curNum = math.floor((cur or 0) + 0.5)
  local maxNum = math.floor((maxv or 0) + 0.5)
  local pct = 0
  if maxNum > 0 then
    pct = math.floor((curNum / maxNum) * 100 + 0.5)
  end
  local abbreviate = SCE.abbreviate or function(n) return tostring(n) end
  local curText = abbreviate(curNum)
  local maxText = abbreviate(maxNum)

  if mode == "powerdyn" or mode == "dynamic" then
    if isMana and curNum < maxNum then
      return curText .. " - " .. tostring(pct) .. "%"
    end
    return curText
  elseif mode == "power" or mode == "current" then
    return curText
  elseif mode == "powermax" then
    return maxText
  elseif mode == "powerperc" or mode == "percent" then
    return tostring(pct) .. "%"
  elseif mode == "powermiss" then
    local miss = maxNum - curNum
    if miss < 0 then miss = 0 end
    return abbreviate(miss)
  elseif mode == "powerminmax" or mode == "minmax" then
    return curText .. " / " .. maxText
  elseif mode == "shiftcasts" then
    if SCE.getShiftCastsText then
      return SCE.getShiftCastsText()
    end
    return ""
  end
  return curText
end

local function updatePowerText(cur, maxv)
  local bar = SCE.Power
  if not bar or not bar.text then return end
  local db = StupidComboEnergyDB or {}
  local isMana = (SCE.isMana and SCE.isMana()) or false
  local isRage = (SCE.isRage and SCE.isRage()) or false
  local leftMode, centerMode, rightMode = getPowerTextModes(db, isMana, isRage)

  if bar.textLeft then
    local text = formatPowerText(leftMode, cur, maxv, isMana)
    bar.textLeft:SetText(text)
    if text ~= "" and bar.textLeft.Show then bar.textLeft:Show() end
  end
  if bar.textCenter then
    local text = formatPowerText(centerMode, cur, maxv, isMana)
    bar.textCenter:SetText(text)
    if text ~= "" and bar.textCenter.Show then bar.textCenter:Show() end
  end
  if bar.textRight then
    local text = formatPowerText(rightMode, cur, maxv, isMana)
    bar.textRight:SetText(text)
    if text ~= "" and bar.textRight.Show then bar.textRight:Show() end
  end
end

local function readPower()
  local clamp = SCE.clamp or function(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
  end

  local cur, maxv
  if SCE.getUnitPower then
    cur, maxv = SCE.getUnitPower("player")
  else
    cur = UnitMana("player") or 0
    maxv = UnitManaMax("player") or 100
  end

  if maxv <= 0 then maxv = 100 end
  cur = clamp(cur, 0, maxv)
  return cur, maxv
end

local function hardSyncPower()
  local bar = SCE.Power
  if not bar then return end
  local cur, maxv = readPower()
  state.lastPower = cur
  state.lastPowerMax = maxv
  state.tickStart = GetTime()
  bar:SetMinMaxValues(0, maxv)
  bar:SetValue(cur)
  updatePowerText(cur, maxv)
end

local function onUpdate()
  local bar = SCE.Power
  if not bar or not bar:IsShown() then return end

  local cur, maxv = readPower()
  local db = StupidComboEnergyDB or {}
  local isEnergy = true
  if SCE.isEnergy then
    isEnergy = SCE.isEnergy()
  end

  if maxv ~= state.lastPowerMax then
    state.lastPowerMax = maxv
    bar:SetMinMaxValues(0, maxv)
  end

  if cur > state.lastPower then
    state.tickStart = GetTime()
  end

  if cur ~= state.lastPower then
    state.lastPower = cur
    bar:SetValue(cur)
    updatePowerText(cur, maxv)
  end

  local tickSeconds = db.powerTickSeconds
  if tickSeconds and tickSeconds > 0 then
    state.tickDuration = tickSeconds
  end

  if db.showPowerTicker == "1" and bar.ticker and isEnergy then
    if cur >= maxv then
      bar.ticker:Hide()
    else
      if not state.tickStart then
        state.tickStart = GetTime()
      end

      local elapsed = GetTime() - state.tickStart
      if elapsed > state.tickDuration then
        state.tickStart = GetTime()
        elapsed = 0
      end

      local progress = elapsed / state.tickDuration
      local barWidth = bar:GetWidth() or 0
      local tickerWidth = db.powerTickerWidth or 16
      local tickerPos = barWidth * progress - (tickerWidth / 2)

      bar.ticker:ClearAllPoints()
      bar.ticker:SetPoint("LEFT", bar, "LEFT", tickerPos, 0)
      bar.ticker:Show()
    end
  elseif bar.ticker then
    bar.ticker:Hide()
  end
end

local function updatePower()
  hardSyncPower()
end

local function setupPowerScripts()
  local bar = SCE.Power
  if not bar then return end

  bar:SetScript("OnUpdate", onUpdate)
  bar:SetScript("OnEvent", function()
    if event == "UNIT_MANA" or event == "UNIT_ENERGY" or event == "UNIT_DISPLAYPOWER" then
      if arg1 and arg1 ~= "player" then return end
    end
    if SCE.updateAll then
      SCE.updateAll()
    end
  end)
end

SCE.updatePowerText = updatePowerText
SCE.formatPowerText = formatPowerText
SCE.readPower = readPower
SCE.hardSyncPower = hardSyncPower
SCE.updatePower = updatePower
SCE.setupPowerScripts = setupPowerScripts

if SCE.debugMsg then
  SCE.debugMsg("Loaded module: powerbar.lua")
end
