StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS

local CreateFrame = CreateFrame

local function rawDebug(msg)
  if not SCE.debugEnabled then return end
  local line = "StupidComboEnergy DEBUG: " .. (msg or "")
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff" .. line .. "|r")
  elseif ChatFrame1 then
    ChatFrame1:AddMessage("|cff66ccff" .. line .. "|r")
  elseif UIErrorsFrame and UIErrorsFrame.AddMessage then
    UIErrorsFrame:AddMessage(line, 0.4, 0.8, 1, 1)
  end
end

if not SCE.debugMsg then
  SCE.debugMsg = rawDebug
end

rawDebug("StupidComboEnergy.lua loaded")

local initialized = false

local function init()
  if initialized then return end
  rawDebug("Init start")
  
  if SCE.ensureDB then SCE.ensureDB() else rawDebug("ensureDB missing") end
  if SCE.layout then SCE.layout() else rawDebug("layout missing") end
  if SCE.applyFonts then SCE.applyFonts() else rawDebug("applyFonts missing") end
  if SCE.applyColors then SCE.applyColors() else rawDebug("applyColors missing") end
  if SCE.setLocked then
    if StupidComboEnergyDB then
      SCE.setLocked(StupidComboEnergyDB.locked)
    else
      rawDebug("StupidComboEnergyDB missing")
    end
  else
    rawDebug("setLocked missing")
  end

  -- Set up power bar scripts after layout creates the frames
  if SCE.setupPowerScripts then
    SCE.setupPowerScripts()
    rawDebug("Power scripts set")
  end
  if SCE.setupHealthScripts then
    SCE.setupHealthScripts()
    rawDebug("Health scripts set")
  end
  if SCE.setupPowerScripts then
    SCE.setupPowerScripts()
    rawDebug("Power scripts set")
  end
  if SCE.setupDruidManaScripts then
    SCE.setupDruidManaScripts()
    rawDebug("Druid mana scripts set")
  end
  if SCE.setupShiftIndicatorScripts then
    SCE.setupShiftIndicatorScripts()
    rawDebug("Shift indicator scripts set")
  end
  if SCE.setupCastbarScripts then
    SCE.setupCastbarScripts()
    rawDebug("Castbar scripts set")
  end

  local UI = SCE.UI
  if UI then
    UI:Show()
    rawDebug("UI shown")
  else
    rawDebug("UI missing")
  end

  local Power = SCE.Power
  if Power then
    Power:RegisterEvent("PLAYER_ENTERING_WORLD")
    Power:RegisterEvent("PLAYER_TARGET_CHANGED")
    Power:RegisterEvent("UNIT_COMBO_POINTS")
    Power:RegisterEvent("PLAYER_AURAS_CHANGED")
    Power:RegisterEvent("UNIT_DISPLAYPOWER")
    Power:RegisterEvent("UNIT_MANA")
    Power:RegisterEvent("UNIT_ENERGY")
    rawDebug("Power events registered")
  else
    rawDebug("Power frame missing")
  end

  if SCE.updateAll then
    SCE.updateAll()
    rawDebug("Initial updateAll complete")
  else
    rawDebug("updateAll missing")
  end

  initialized = true
  rawDebug("Init complete")
end

SCE.init = init

local Loader = CreateFrame("Frame")
if Loader.SetFrameStrata then
  Loader:SetFrameStrata("MEDIUM")
end
if Loader.SetFrameLevel then
  Loader:SetFrameLevel(1)
end
Loader:RegisterEvent("VARIABLES_LOADED")
Loader:SetScript("OnEvent", function()
  if event ~= "VARIABLES_LOADED" then return end
  rawDebug("VARIABLES_LOADED")
  local mods = { "defaults", "layout", "healthbar", "powerbar", "druidmana", "shapeshiftindicator", "castbar", "combopoints", "gui", "commands" }
  for i = 1, table.getn(mods) do
    local name = mods[i]
    if SCE._moduleLoaded and SCE._moduleLoaded[name] then
      rawDebug("Module loaded: " .. name)
    else
      rawDebug("Module MISSING: " .. name)
    end
  end

  -- Register slash commands
  SLASH_STUPIDCOMBOENERGY1 = "/sce"
  SLASH_STUPIDCOMBOENERGY2 = "/stupidcomboenergy"
  SlashCmdList["STUPIDCOMBOENERGY"] = function(msg)
    if SCE.handleSlashCmd then
      SCE.handleSlashCmd(msg)
    else
      rawDebug("Slash handler missing")
    end
  end
  rawDebug("Slash commands registered")

  init()

  Loader:UnregisterEvent("VARIABLES_LOADED")
end)
