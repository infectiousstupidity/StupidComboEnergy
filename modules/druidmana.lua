StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS
SCE._moduleLoaded = SCE._moduleLoaded or {}
SCE._moduleLoaded.druidmana = true

local UnitPowerType = UnitPowerType
local UnitClass = UnitClass
local floor = math.floor

local lastMana = 0
local lastMax = 1

local function getDruidManaFromLib()
  if not AceLibrary then return nil end
  if not AceLibrary.HasInstance or not AceLibrary:HasInstance("DruidManaLib-1.0") then return nil end
  local lib = AceLibrary("DruidManaLib-1.0")
  if lib and lib.GetMana then
    return lib:GetMana()
  end
  return nil
end

local function updateDruidMana()
  local bar = SCE.DruidMana
  if not bar then return end
  local cur, maxv = getDruidManaFromLib()

  if not cur or not maxv then
    if SUPERWOW_VERSION then
      local _, realMana = UnitMana("player")
      local _, realMax = UnitManaMax("player")
      if realMana and realMax then
        cur = realMana
        maxv = realMax
      end
    end
  end

  if not cur or not maxv then
    if UnitPowerType and UnitPowerType("player") == 0 then
      if SCE.getUnitPower then
        cur, maxv = SCE.getUnitPower("player")
      else
        cur = UnitMana("player") or 0
        maxv = UnitManaMax("player") or 1
      end
      lastMana = cur
      lastMax = maxv
    else
      cur = lastMana
      maxv = lastMax
    end
  end

  if not maxv or maxv <= 0 then maxv = 1 end
  if not cur or cur < 0 then cur = 0 end
  if cur > maxv then cur = maxv end

  bar:SetMinMaxValues(0, maxv)
  bar:SetValue(cur)
  if SCE.formatPowerText then
    local db = StupidComboEnergyDB or {}
    local leftMode = db.druidManaTextLeft or "none"
    local centerMode = db.druidManaTextCenter or db.powerTextCenter or db.powerTextMode or "powerdyn"
    local rightMode = db.druidManaTextRight or "none"

    if bar.textLeft then
      local text = SCE.formatPowerText(leftMode, cur, maxv, true)
      bar.textLeft:SetText(text)
      if text ~= "" and bar.textLeft.Show then bar.textLeft:Show() end
    end
    if bar.textCenter then
      local text = SCE.formatPowerText(centerMode, cur, maxv, true)
      bar.textCenter:SetText(text)
      if text ~= "" and bar.textCenter.Show then bar.textCenter:Show() end
    end
    if bar.textRight then
      local text = SCE.formatPowerText(rightMode, cur, maxv, true)
      bar.textRight:SetText(text)
      if text ~= "" and bar.textRight.Show then bar.textRight:Show() end
    end
  elseif bar.text then
    bar.text:SetText(floor(cur + 0.5))
  end
end

local function setupDruidManaScripts()
  local bar = SCE.DruidMana
  if not bar then return end
  if UnitClass then
    local _, class = UnitClass("player")
    if class ~= "DRUID" then return end
  end
  bar:RegisterEvent("PLAYER_ENTERING_WORLD")
  bar:RegisterEvent("UNIT_MANA")
  bar:RegisterEvent("UNIT_MAXMANA")
  bar:RegisterEvent("UNIT_DISPLAYPOWER")
  bar:SetScript("OnEvent", function()
    if arg1 and arg1 ~= "player" then return end
    if SCE.updateDruidMana then
      SCE.updateDruidMana()
    end
  end)

  if AceLibrary and AceLibrary.HasInstance and AceLibrary:HasInstance("DruidManaLib-1.0") then
    bar:SetScript("OnUpdate", function()
      if not bar:IsShown() then return end
      local now = GetTime()
      if not this.tick or this.tick < now then
        this.tick = now + 0.25
        if SCE.updateDruidMana then
          SCE.updateDruidMana()
        end
      end
    end)
  end
end

SCE.updateDruidMana = updateDruidMana
SCE.setupDruidManaScripts = setupDruidManaScripts

if SCE.debugMsg then
  SCE.debugMsg("Loaded module: druidmana.lua")
end
