StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS
SCE._moduleLoaded = SCE._moduleLoaded or {}
SCE._moduleLoaded.commands = true

-- Don't cache SCE functions at load time - they may not be defined yet
-- Access them directly via SCE.functionName() inside functions

local function handleSlashCmd(msg)
  if SCE.debugMsg then SCE.debugMsg("Slash command invoked: " .. (msg or "")) end
  msg = msg or ""
  local _, _, cmd, rest = string.find(msg, "^(%S+)%s*(.-)%s*$")
  if cmd then
    cmd = string.lower(cmd)
  else
    cmd = ""
    rest = ""
  end

  if cmd == "" then
    if SCE.toggleConfig then
      SCE.toggleConfig()
    else
      SCE.printMsg("Config UI not available.")
    end
    return
  end
  
  if cmd == "help" then
    SCE.printMsg("Commands:")
    SCE.printMsg("/sce (open settings)")
    SCE.printMsg("/sce unlock | lock")
    SCE.printMsg("/sce reset")
    SCE.printMsg("/sce reset pos")
    return
  end

  if cmd == "unlock" then
    SCE.setLocked(false)
    SCE.printMsg("Unlocked. Drag to move.")
    return
  end

  if cmd == "lock" then
    SCE.setLocked(true)
    SCE.printMsg("Locked.")
    return
  end

  if cmd == "config" or cmd == "settings" or cmd == "ui" then
    if SCE.toggleConfig then
      SCE.toggleConfig()
    else
      SCE.printMsg("Config UI not available.")
    end
    return
  end

  if cmd == "reset" then
    StupidComboEnergyDB = nil
    SCE.ensureDB()
    SCE.layout()
    SCE.applyFonts()
    SCE.applyColors()
    SCE.setLocked(StupidComboEnergyDB.locked)
    SCE.updateAll()
    if SCE.clearReloadNeeded then
      SCE.clearReloadNeeded()
    end
    if SCE.updateReloadLabel then
      SCE.updateReloadLabel()
    end
    SCE.printMsg("Reset to defaults.")
    return
  end
  
  if cmd == "resetpos" or (cmd == "reset" and (rest == "pos" or rest == "position")) then
    local db = StupidComboEnergyDB
    local defaults = SCE.defaults or {}
    db.point = defaults.point
    db.relativePoint = defaults.relativePoint
    db.x = defaults.x
    db.y = defaults.y
    db.energyPoint = defaults.energyPoint
    db.energyRelativePoint = defaults.energyRelativePoint
    db.energyX = defaults.energyX
    db.energyY = defaults.energyY
    db.cpPoint = defaults.cpPoint
    db.cpRelativePoint = defaults.cpRelativePoint
    db.cpX = defaults.cpX
    db.cpY = defaults.cpY
    SCE.layout()
    SCE.printMsg("Reset positions to default.")
    return
  end

  SCE.printMsg("Unknown command. /sce help")
end
SCE.handleSlashCmd = handleSlashCmd

if SCE.debugMsg then
  SCE.debugMsg("Loaded module: commands.lua")
end
