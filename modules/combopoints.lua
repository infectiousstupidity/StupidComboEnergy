StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS
SCE._moduleLoaded = SCE._moduleLoaded or {}
SCE._moduleLoaded.combopoints = true

-- Don't cache SCE.CP or SCE.clamp at load time - they may not be defined yet

local function setComboPoints(cp)
  local CP = SCE.CP  -- Access at call time
  local clamp = SCE.clamp or function(x, lo, hi) if x < lo then return lo end if x > hi then return hi end return x end
  
  if not CP or not CP.segs then return end
  
  cp = clamp(cp or 0, 0, 5)
  for i = 1, 5 do
    local seg = CP.segs[i]
    if seg then
      if i <= cp then
        seg:SetValue(1)
      else
        seg:SetValue(0)
      end
    end
  end
end

SCE.setComboPoints = setComboPoints

if SCE.debugMsg then
  SCE.debugMsg("Loaded module: combopoints.lua")
end
