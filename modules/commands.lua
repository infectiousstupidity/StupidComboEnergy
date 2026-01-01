StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS
SCE._moduleLoaded = SCE._moduleLoaded or {}
SCE._moduleLoaded.commands = true

-- Don't cache SCE functions at load time - they may not be defined yet
-- Access them directly via SCE.functionName() inside functions

local function parseRGBA(args)
  local clamp = SCE.clamp or function(x, lo, hi) if x < lo then return lo end if x > hi then return hi end return x end
  local t = {}
  for v in string.gfind(args or "", "%S+") do
    local num = tonumber(v)
    if num then
      table.insert(t, num)
    end
  end
  if table.getn(t) < 3 then return nil end
  local r = clamp(t[1], 0, 1)
  local g = clamp(t[2], 0, 1)
  local b = clamp(t[3], 0, 1)
  local a = clamp(t[4] or 1, 0, 1)
  return { r, g, b, a }
end

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

  if cmd == "" or cmd == "help" then
    SCE.printMsg("Commands:")
    SCE.printMsg("/sce unlock | lock")
    SCE.printMsg("/sce config")
    SCE.printMsg("/sce energyempty r g b [a]")
    SCE.printMsg("/sce reset")
    SCE.printMsg("/sce resetpos")
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
  
  if cmd == "resetpos" then
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

  local c = parseRGBA(rest)
  if not c then
    SCE.printMsg("Invalid color. Use 0..1 floats: r g b [a]")
    return
  end

  if cmd == "energycolor" then
    StupidComboEnergyDB.energyFill = c
  elseif cmd == "energyempty" then
    StupidComboEnergyDB.energyEmpty = c
  elseif cmd == "cpfill" then
    StupidComboEnergyDB.cpFill = c
  elseif cmd == "cpempty" then
    StupidComboEnergyDB.cpEmpty = c
  elseif cmd == "framebg" then
    StupidComboEnergyDB.frameBg = c
  else
    SCE.printMsg("Unknown command. /sce help")
    return
  end

  SCE.applyColors()
  SCE.printMsg("Updated " .. cmd .. ".")
end

SCE.parseRGBA = parseRGBA
SCE.handleSlashCmd = handleSlashCmd

if SCE.debugMsg then
  SCE.debugMsg("Loaded module: commands.lua")
end
