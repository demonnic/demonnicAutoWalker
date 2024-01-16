if not matches[2] then
  demonwalker:usage()
  return
end
local function toBool(value)
  if value == "true" or value == true then
    return true
  end
  return false
end
local args = matches[2]:split(" ")
local command = args[1]
local value = args[2]
if command == "report" then
  demonwalker:performanceReport()
  return
elseif command == "stop" then
  raiseEvent("demonwalker.stop")
  stopNamedEventHandler("demonwalker", "explore")
  return
elseif command == "move" then
  raiseEvent("demonwalker.move")
  return
elseif command == "config" then
  demonwalker:displayConfig()
  return
elseif command == "breadth" then
  value = tonumber(value)
  if value then
    demonwalker.config.breadth = value
  end
  demonwalker:save()
  return
elseif command == "returnToStart" then
  demonwalker.config.returnToStart = toBool(value)
  demonwalker:save()
  return
elseif command == "debug" then
  demonwalker.config.debug = toBool(value)
  demonwalker:save()
  return
elseif command == "avoid" then
  value = tonumber(value)
  if value then 
    demonwalker:addAvoidRoom(value)
    demonwalker:echo(string.format("Added %d to avoidList", value))
  end
  return
elseif command == "unavoid" then
  value = tonumber(value)
  if value then
    demonwalker:removeAvoidRoom(value)
    demonwalker:echo(string.format("Removed %s from avoidList", tostring(value)))
  end
  return
elseif command == "avoidList" then
  demonwalker:printAvoidList()
  return
elseif command == "load" then
  demonwalker:load()
  return
elseif command == "save" then
  demonwalker:save()
  return
elseif command == "explore" then
  demonwalker:echo("Time to explore!")
  registerNamedEventHandler("demonwalker", "explore", "demonwalker.arrived", function()
    raiseEvent("demonwalker.move")
  end)
  demonwalker:init()
  return
elseif command == "update" then
  uninstallPackage("demonnicAutoWalker")
  tempTimer(2, function()
    installPackage("https://github.com/demonnic/demonnicAutoWalker/releases/latest/download/demonnicAutoWalker.mpackage")
    demonwalker:echo("demonnicAutoWalker package updated")
  end)
  return
end
demonwalker:usage(matches[1])
