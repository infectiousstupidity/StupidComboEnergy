StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS
SCE._moduleLoaded = SCE._moduleLoaded or {}
SCE._moduleLoaded.shapeshiftindicator = true

local GetTime = GetTime
local UnitClass = UnitClass
local UnitPowerType = UnitPowerType
local UnitMana = UnitMana
local UnitManaMax = UnitManaMax
local GetNumSpellTabs = GetNumSpellTabs
local GetSpellTabInfo = GetSpellTabInfo
local GetSpellTexture = GetSpellTexture
local GetShapeshiftForm = GetShapeshiftForm
local GetShapeshiftFormInfo = GetShapeshiftFormInfo

local tooltip = CreateFrame("GameTooltip", "SCE_ShiftIndicatorTooltip", nil, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")
if tooltip.SetFrameStrata then
  tooltip:SetFrameStrata("MEDIUM")
end
if tooltip.SetFrameLevel then
  tooltip:SetFrameLevel(1)
end

local state = {
  cost = 0,
  lastCostCheck = 0,
}

local iconLookup = {
  ["Interface\\Icons\\Ability_Racial_BearForm"] = true,
  ["Interface\\Icons\\Ability_Druid_CatForm"] = true,
  ["Interface\\Icons\\Ability_Druid_DireBearForm"] = true,
}

local function getDruidMana()
  if SUPERWOW_VERSION then
    local _, realMana = UnitMana("player")
    local _, realMax = UnitManaMax("player")
    if realMana and realMax then
      return realMana, realMax
    end
  end
  if AceLibrary and AceLibrary.HasInstance and AceLibrary:HasInstance("DruidManaLib-1.0") then
    local lib = AceLibrary("DruidManaLib-1.0")
    if lib and lib.GetMana then
      return lib:GetMana()
    end
  end
  if UnitPowerType and UnitPowerType("player") == 0 then
    return UnitMana("player") or 0, UnitManaMax("player") or 0
  end
  return nil, nil
end

local function readTooltipManaCost()
  local lines = tooltip:NumLines() or 0
  local manaToken = string.lower(MANA or "mana")
  for i = 2, lines do
    local line = _G["SCE_ShiftIndicatorTooltipTextLeft" .. i]
    line = line and line:GetText() or nil
    if line then
      local lower = string.lower(line)
      if string.find(lower, manaToken, 1, true) then
        local cost = string.match(line, "(%d+)")
        if cost then
          return tonumber(cost) or 0
        end
      end
    end
  end
  return nil
end

local function findShapeshiftCost()
  local tabs = GetNumSpellTabs and GetNumSpellTabs() or 0
  for tab = 1, tabs do
    local _, _, offset, numSpells = GetSpellTabInfo(tab)
    for i = 1, numSpells do
      local spellIndex = offset + i
      local texture = GetSpellTexture(spellIndex, BOOKTYPE_SPELL)
      if texture and iconLookup[texture] then
        tooltip:ClearLines()
        tooltip:SetSpell(spellIndex, BOOKTYPE_SPELL)
        local cost = readTooltipManaCost()
        if cost and cost > 0 then
          return cost
        end
      end
    end
  end
  return 0
end

local function updateCost(force)
  local now = GetTime()
  if not force and state.lastCostCheck > 0 and (now - state.lastCostCheck) < 5 then
    return
  end
  state.lastCostCheck = now
  state.cost = findShapeshiftCost()
end

local function resolveIcon(db)
  local mode = db.shiftIndicatorIconMode or "bear"
  if mode == "custom" then
    local path = db.shiftIndicatorCustomIcon
    if path and path ~= "" then
      return path
    end
    mode = "bear"
  end
  if mode == "current" and GetShapeshiftForm and GetShapeshiftFormInfo then
    local form = GetShapeshiftForm()
    if form and form > 0 then
      local _, _, tex = GetShapeshiftFormInfo(form)
      if tex then
        return tex
      end
    end
    mode = "bear"
  end
  if mode == "cat" then
    return "Interface\\Icons\\Ability_Druid_CatForm"
  end
  return "Interface\\Icons\\Ability_Racial_BearForm"
end

local function updateShiftIndicator()
  local db = StupidComboEnergyDB or {}

  if (state.cost or 0) <= 0 then
    updateCost(false)
  end
  local mana = 0
  local cost = state.cost or 0
  local curMana = getDruidMana()
  if curMana then mana = curMana end

  local casts = 0
  if cost > 0 and mana then
    casts = math.floor(mana / cost)
  end
  SCE.shiftCasts = casts

  local frame = SCE.ShiftIndicator
  if not frame then return end
  if SCE.shouldShowShiftIndicator and not SCE.shouldShowShiftIndicator(db) then
    frame:Hide()
    return
  end

  if frame.icon then
    frame.icon:SetTexture(resolveIcon(db))
    if frame.icon.SetTexCoord then
      frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    if frame.icon.SetDesaturated then
      if db.shiftIndicatorDesaturate == "1" and casts <= 0 then
        frame.icon:SetDesaturated(true)
      else
        frame.icon:SetDesaturated(false)
      end
    end
  end
  if frame.text then
    if casts > 0 or db.shiftIndicatorShowZero == "1" then
      frame.text:SetText(tostring(casts))
    else
      frame.text:SetText("")
    end
  end
end

local function setupShiftIndicatorScripts()
  local frame = SCE.ShiftIndicator
  if not frame then return end

  local _, class = UnitClass("player")
  if class ~= "DRUID" then return end

  local eventFrame = CreateFrame("Frame")
  if eventFrame.SetFrameStrata then
    eventFrame:SetFrameStrata("MEDIUM")
  end
  if eventFrame.SetFrameLevel then
    eventFrame:SetFrameLevel(1)
  end
  eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
  eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
  eventFrame:RegisterEvent("SPELLS_CHANGED")
  eventFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")
  eventFrame:RegisterEvent("UNIT_MANA")
  eventFrame:RegisterEvent("UNIT_MAXMANA")
  eventFrame:RegisterEvent("UNIT_DISPLAYPOWER")
  eventFrame:SetScript("OnEvent", function()
    if event == "UNIT_MANA" or event == "UNIT_MAXMANA" or event == "UNIT_DISPLAYPOWER" then
      if arg1 and arg1 ~= "player" then return end
    else
      updateCost(true)
    end
    updateShiftIndicator()
  end)

  eventFrame:SetScript("OnUpdate", function()
    local db = StupidComboEnergyDB or {}
    if frame and not frame:IsShown() and not (SCE.usesShiftText and SCE.usesShiftText(db)) then
      return
    end
    if SCE.shouldShowShiftIndicator and not SCE.shouldShowShiftIndicator(db) then
      if not (SCE.usesShiftText and SCE.usesShiftText(db)) then
        return
      end
    end
    local interval = tonumber(db.shiftIndicatorUpdateInterval) or 0.5
    if interval < 0.05 then interval = 0.05 end
    if not this.nextTick or this.nextTick <= GetTime() then
      this.nextTick = GetTime() + interval
      updateShiftIndicator()
    end
  end)
end

SCE.updateShiftIndicator = updateShiftIndicator
SCE.setupShiftIndicatorScripts = setupShiftIndicatorScripts

if SCE.debugMsg then
  SCE.debugMsg("Loaded module: shapeshiftindicator.lua")
end
