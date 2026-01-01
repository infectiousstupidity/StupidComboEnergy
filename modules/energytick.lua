StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS
SCE._moduleLoaded = SCE._moduleLoaded or {}
SCE._moduleLoaded.energytick = true

-- Don't cache SCE.Energy or SCE.clamp at load time - they may not be defined yet

local UnitMana = UnitMana
local UnitManaMax = UnitManaMax
local GetTime = GetTime

local floor = math.floor

local state = {
  lastEnergy = 0,
  lastEnergyTime = 0,
  smoothEnergy = 0,
  lastEnergyMax = 100,
  tickStart = nil,
  tickDuration = 2,
}

SCE.state = state

local function updateEnergyText(val)
  local Energy = SCE.Energy  -- Access at call time
  if not Energy or not Energy.text then return end
  local num = floor((val or 0) + 0.5)
  Energy.text:SetText(num)
end

local function readEnergy()
  local clamp = SCE.clamp or function(x, lo, hi) if x < lo then return lo end if x > hi then return hi end return x end
  local cur = UnitMana("player") or 0
  local maxv = UnitManaMax("player") or 100
  if maxv <= 0 then maxv = 100 end
  if maxv > 2000 then maxv = 100 end
  cur = clamp(cur, 0, maxv)
  return cur, maxv
end

local function hardSyncEnergy()
  local Energy = SCE.Energy
  if not Energy then return end
  local cur, maxv = readEnergy()
  state.lastEnergy = cur
  state.lastEnergyMax = maxv
  state.lastEnergyTime = GetTime()
  state.smoothEnergy = cur
  Energy:SetMinMaxValues(0, maxv)
  Energy:SetValue(cur)
  updateEnergyText(cur)
end

local function onUpdate()
  local Energy = SCE.Energy
  if not Energy or not Energy:IsShown() then return end

  local cur, maxv = readEnergy()
  local db = StupidComboEnergyDB
  local isEnergy = true
  if SCE.isEnergy then
    isEnergy = SCE.isEnergy()
  end

  if maxv ~= state.lastEnergyMax then
    state.lastEnergyMax = maxv
    Energy:SetMinMaxValues(0, maxv)
  end

  if cur > state.lastEnergy then
    state.tickStart = GetTime()
  end

  if cur ~= state.lastEnergy then
    state.lastEnergy = cur
    Energy:SetValue(cur)
    updateEnergyText(cur)
  end
  
  if db.showEnergyTicker == "1" and Energy.ticker and isEnergy then
    if cur >= maxv then
      Energy.ticker:Hide()
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
      local barWidth = db.width or 200
      local tickerWidth = db.energyTickerWidth or 16
      local tickerPos = barWidth * progress - (tickerWidth / 2)
      
      Energy.ticker:ClearAllPoints()
      Energy.ticker:SetPoint("LEFT", Energy, "LEFT", tickerPos, 0)
      Energy.ticker:Show()
    end
  elseif Energy.ticker then
    Energy.ticker:Hide()
  end
end

-- Set scripts after frames are created (called from main file or layout)
local function setupEnergyScripts()
  local Energy = SCE.Energy
  if not Energy then return end
  
  Energy:SetScript("OnUpdate", onUpdate)

  Energy:SetScript("OnEvent", function()
    if event == "UNIT_MANA" or event == "UNIT_ENERGY" or event == "UNIT_DISPLAYPOWER" then
      if arg1 and arg1 ~= "player" then return end
    end
    if SCE.updateAll then
      SCE.updateAll()
    end
  end)
end

SCE.updateEnergyText = updateEnergyText
SCE.readEnergy = readEnergy
SCE.hardSyncEnergy = hardSyncEnergy
SCE.onUpdate = onUpdate
SCE.setupEnergyScripts = setupEnergyScripts

if SCE.debugMsg then
  SCE.debugMsg("Loaded module: energytick.lua")
end

-- Scripts will be set up by main file after layout() creates the frames
