StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS
SCE._moduleLoaded = SCE._moduleLoaded or {}
SCE._moduleLoaded.healthbar = true

local floor = math.floor
local GetTime = GetTime
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost

local function isDeadOrGhost(unit)
  if UnitIsDeadOrGhost then
    return UnitIsDeadOrGhost(unit)
  end
  if UnitIsDead and UnitIsDead(unit) then
    return true
  end
  if UnitIsGhost and UnitIsGhost(unit) then
    return true
  end
  return false
end

local function readHealth(unit)
  local cur1, cur2 = UnitHealth(unit)
  local max1, max2 = UnitHealthMax(unit)
  local cur = cur1 or 0
  local maxv = max1 or 0

  if max2 and max2 > maxv and max2 >= cur then
    maxv = max2
  end

  if maxv <= 0 then
    if cur2 and cur2 > 0 then
      maxv = cur2
    elseif max2 and max2 > 0 then
      maxv = max2
    else
      maxv = 1
    end
  elseif cur2 and cur2 > maxv then
    maxv = cur2
  end

  if cur < 0 then cur = 0 end
  if cur > maxv then cur = maxv end
  return cur, maxv
end

local function formatHealthValue(mode, cur, maxv, dead)
  if not mode or mode == "none" then return "" end
  if dead then return DEAD or "DEAD" end

  if maxv <= 0 then
    return tostring(cur)
  end

  local pct = floor((cur / maxv) * 100 + 0.5)
  local abbreviate = SCE.abbreviate or function(n) return tostring(n) end
  local curText = abbreviate(cur)
  local maxText = abbreviate(maxv)

  if mode == "healthdyn" then
    if cur < maxv then
      return curText .. " - " .. pct .. "%"
    end
    return curText
  elseif mode == "health" then
    return curText
  elseif mode == "healthmax" then
    return maxText
  elseif mode == "healthperc" then
    return pct .. "%"
  elseif mode == "healthmiss" then
    local miss = maxv - cur
    if miss < 0 then miss = 0 end
    return abbreviate(miss)
  elseif mode == "healthminmax" then
    return curText .. " / " .. maxText
  elseif mode == "healthminmaxperc" then
    return curText .. " / " .. maxText .. " (" .. pct .. "%)"
  end

  return ""
end

local function updateHealth()
  local bar = SCE.Health
  if not bar then return end
  local cur, maxv = readHealth("player")
  bar:SetMinMaxValues(0, maxv)
  local db = StupidComboEnergyDB or {}
  local barValue = cur
  if db.invertHealthBar == "1" then
    barValue = maxv - cur
    if barValue < 0 then barValue = 0 end
    if barValue > maxv then barValue = maxv end
  end
  bar:SetValue(barValue)
  local dead = isDeadOrGhost("player")
  cur = floor(cur + 0.5)
  maxv = floor(maxv + 0.5)
  local leftMode = db.healthTextLeft or "none"
  local centerMode = db.healthTextCenter or "none"
  local rightMode = db.healthTextRight or "none"

  if bar.textLeft then
    local text = formatHealthValue(leftMode, cur, maxv, dead)
    bar.textLeft:SetText(text)
    if text ~= "" and bar.textLeft.Show then bar.textLeft:Show() end
  end
  if bar.textCenter then
    local text = formatHealthValue(centerMode, cur, maxv, dead)
    bar.textCenter:SetText(text)
    if text ~= "" and bar.textCenter.Show then bar.textCenter:Show() end
  end
  if bar.textRight then
    local text = formatHealthValue(rightMode, cur, maxv, dead)
    bar.textRight:SetText(text)
    if text ~= "" and bar.textRight.Show then bar.textRight:Show() end
  end
end

local function setupHealthScripts()
  local bar = SCE.Health
  if not bar then return end
  bar:RegisterEvent("PLAYER_ENTERING_WORLD")
  bar:RegisterEvent("UNIT_HEALTH")
  bar:RegisterEvent("UNIT_MAXHEALTH")
  bar:SetScript("OnEvent", function(_, _, unit)
    local unitId = unit or arg1
    if unitId and unitId ~= "player" then return end
    if SCE.updateHealth then
      SCE.updateHealth()
    end
  end)
  bar:SetScript("OnUpdate", function(self)
    local frame = self or this
    if not frame then return end
    if not frame.tick or frame.tick < GetTime() then
      frame.tick = GetTime() + 0.2
      if SCE.updateHealth then
        SCE.updateHealth()
      end
    end
  end)
end

SCE.updateHealth = updateHealth
SCE.setupHealthScripts = setupHealthScripts

if SCE.debugMsg then
  SCE.debugMsg("Loaded module: healthbar.lua")
end
