--[===[
The MIT License (MIT)

Copyright (c) 2020 Damian Monogue

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]===]

demonwalker = demonwalker or {}
demonwalker.saveFile = getMudletHomeDir() .. "/demonwalkerconfig.lua"
demonwalker.timerName = "demonwalkerPerfTimer"
demonwalker.config = demonwalker.config or {}
if demonwalker.enabled == nil then
  demonwalker.enabled = false
end

function demonwalker:echo(msg)
  cecho(string.format("\n<blue>(<green>Demonwalker<blue>):<white> %s", msg))
end

function demonwalker:save()
  table.save(demonwalker.saveFile, demonwalker.config)
end

function demonwalker:load()
  local config = {}
  local cfg = {}
  local existingSave = io.exists(demonwalker.saveFile)
  if existingSave then
    table.load(demonwalker.saveFile, cfg)
  end
  if cfg.returnToStart == nil then
    config.returnToStart = true
  else
    config.returnToStart = true
  end
  config.avoidList = cfg.avoidList or {}
  config.breadth = cfg.breadth or 10
  if not _comp(config, cfg) then
    -- there is a new value which was not in the save file, or there is no savefile yet
    demonwalker:save()
  end
  demonwalker.config = config
end

function demonwalker:addAvoidRoom(roomID)
  local ridType = type(roomID)
  local avoidList = demonwalker.config.avoidList
  if ridType == "number" then
    avoidList[roomID] = true
  elseif ridType == "table" then
    for _,rid in ipairs(roomID) do
      avoidList[rid] = true
    end
  elseif ridType == "string" then
    local rid = tonumber(roomID)
    if rid then
      avoidList[rid] = true
    end
  end
  demonwalker:save()
end

function demonwalker:removeAvoidRoom(roomID)
  local ridType = type(roomID)
  local avoidList = demonwalker.config.avoidList
  if ridType == "number" then
    avoidList[roomID] = nil
  elseif ridType == "table" then
    for _,rid in ipairs(roomID) do
      avoidList[rid] = nil
    end
  elseif ridType == "string" then
    local rid = tonumber(roomID)
    if rid then
      avoidList[rid] = nil
    end
  end
  demonwalker:save()
end

function demonwalker:removeUnreachable()
  local rooms = {}
  for room,_ in pairs(demonwalker.remainingRooms) do
    local ok,_ = getPath(demonwalker.currentRoom, room)
    if ok then
      rooms[room] = true
    end
  end
  demonwalker.remainingRooms = rooms
end

function demonwalker:init(options)
  if demonwalker.enabled then
    return
  end
  options = options or {}
  local rooms = options.rooms or {}
  local roomsToAvoid = options.avoidRooms or {}
  demonwalker.search = options.search or {}
  demonwalker.enabled = true
  local currentRoom = mmp.currentroom
  demonwalker.currentRoom = currentRoom
  demonwalker.startingRoom = currentRoom
  demonwalker.performanceTimes = {}
  local area = getRoomArea(currentRoom)
  demonwalker.area = area
  if #rooms ~= 0 then
    demonwalker.area = getRoomArea(rooms[1])
  else
    rooms = getAreaRooms(area)
    if rooms[0] then
      rooms[#rooms+1] = rooms[0]
      rooms[0] = nil
    end
  end
  demonwalker.remainingRooms = {}
  for _,roomID in ipairs(rooms) do
    demonwalker.remainingRooms[roomID] = true
  end
  for _,roomID in ipairs(demonwalker.config.avoidList) do
    demonwalker.remainingRooms[roomID] = nil
  end
  for _,roomID in ipairs(roomsToAvoid) do
    demonwalker.remainingRooms[roomID] = nil
  end
  demonwalker:removeUnreachable()
  demonwalker:registerEventHandlers()
  raiseEvent("demonwalker.arrived")
end

function demonwalker:stop()
  if not demonwalker.enabled then
    return
  end
  demonwalker.currentRoom = nil
  demonwalker.remainingRooms = nil
  demonwalker.enabled = false
  demonwalker:removeEventHandlers()
  raiseEvent("demonwalker.finished")
  if demonwalker.config.returnToStart then
    mmp.gotoRoom(demonwalker.startingRoom)
  end
end

function demonwalker:move()
  if not demonwalker.enabled then
    return
  end
  if mmp.paused then
    mmp.pause()
    return
  end
  demonwalker.nextRoom = demonwalker:closestRoom()
  if demonwalker.nextRoom ~= "" then
    tempTimer(0, function() mmp.gotoRoom(demonwalker.nextRoom) end)
  else
    raiseEvent("demonwalker.stop")
  end
end

function demonwalker:arrived()
  if tonumber(mmp.currentroom) == tonumber(demonwalker.nextRoom) then
    demonwalker.currentRoom = mmp.currentroom
    demonwalker.remainingRooms[mmp.currentroom] = nil
    raiseEvent("demonwalker.arrived")
  else
    debugc("demonwalker: Somehow, the mudlet mapper says we have arrived but it is not to the room we said to go to.")
  end
end

function demonwalker:failedPath()
  demonwalker.remainingRooms[demonwalker.nextRoom] = nil
  demonwalker.currentRoom = mmp.currentroom
  raiseEvent("demonwalker.move")
end

function demonwalker:removeEventHandlers()
  for _, handlerID in pairs(demonwalker.eventHandlers) do
    killAnonymousEventHandler(handlerID)
  end
end

function demonwalker:registerEventHandlers()
  demonwalker.eventHandlers = demonwalker.eventHandlers or {}
  demonwalker:removeEventHandlers()
  demonwalker.eventHandlers.move = registerAnonymousEventHandler("demonwalker.move", demonwalker.move)
  demonwalker.eventHandlers.stop = registerAnonymousEventHandler("demonwalker.stop", demonwalker.stop)
  demonwalker.eventHandlers.arrived = registerAnonymousEventHandler("mmapper arrived", demonwalker.arrived)
  demonwalker.eventHandlers.failedPath = registerAnonymousEventHandler("mmapper failed path", demonwalker.failedPath)
end

function demonwalker:getAdjacentRooms(roomID)
  local adjacentRooms = getSpecialExits(roomID)
  local exits = getRoomExits(roomID)
  for _,id in pairs(exits) do
    adjacentRooms[id] = true
  end
  return adjacentRooms
end

function demonwalker:extractFirstUnvisitedRoom(rooms)
  local remainingRooms = demonwalker.remainingRooms
  for id,_ in ipairs(rooms) do
    if remainingRooms[id] then
      return id
    end
  end
  return nil
end

function demonwalker:startPerfTimer()
  createStopWatch(demonwalker.timerName)
  resetStopWatch(demonwalker.timerName)
  startStopWatch(demonwalker.timerName)
end

function demonwalker:recordPerfTime(steps, checks)
  local perfTime = getStopWatchTime(demonwalker.timerName)
  stopStopWatch(demonwalker.timerName)
  demonwalker:echo(string.format("Took %.5f seconds to find our room at %d distance and %d checks\n", perfTime, steps, checks))
  demonwalker.performanceTimes[#demonwalker.performanceTimes+1] = {time = perfTime, steps = steps, checks = checks}
end

function demonwalker:performanceReport()
  local perfTable = demonwalker.performanceTimes
  local timesMoved = #perfTable
  if timesMoved == 0 then
    demonwalker:echo("No performance report to generate, have not moved")
    return
  end
  local steps = {}
  local times = {}
  local checks = {}
  local totalSteps = 0
  local totalTime = 0
  local totalChecks = 0
  for _, info in ipairs(perfTable) do
    totalSteps = totalSteps + info.steps
    totalTime = totalTime + info.time
    totalChecks = totalChecks + info.checks
    steps[#steps+1] = info.steps
    times[#times+1] = info.time
    checks[#checks+1] = info.checks
  end
  local averageTime = totalTime / timesMoved
  local averageSteps = totalSteps / timesMoved
  local averageChecks = totalChecks / timesMoved
  table.sort(steps)
  table.sort(times)
  table.sort(checks)
  local half = timesMoved / 2
  local medianSteps = 0
  local medianTime = 0
  local medianChecks = 0
  local roundedHalf = math.ceil(half)
  if roundedHalf > half then
    medianSteps = steps[roundedHalf]
    medianTime = times[roundedHalf]
    medianChecks = checks[roundedHalf]
  else
    medianSteps = (steps[half] + steps[half + 1]) / 2
    medianTime = (times[half] + times[half+1]) / 2
    medianChecks = (checks[half] + checks[half+1]) / 2
  end
  demonwalker:echo("Performance report of current demonwalk!")
  demonwalker:echo("Note: Number of steps actually taken may be more or less, as the walker does not always")
  demonwalker:echo("take the reported number of steps due to mmp overshooting or some interruption.")
  demonwalker:echo(string.format("Total times moved: %d", timesMoved))
  demonwalker:echo(string.format("Total steps taken: %d", totalSteps))
  demonwalker:echo(string.format("Avg steps per    : %.3f", averageSteps))
  demonwalker:echo(string.format("Median steps per : %.3f", medianSteps))
  demonwalker:echo(string.format("Total time calc. : %.3f", totalTime))
  demonwalker:echo(string.format("Avg time per     : %.3f", averageTime))
  demonwalker:echo(string.format("Median time per  : %.3f", medianTime))
  demonwalker:echo(string.format("Total checks     : %d", totalChecks))
  demonwalker:echo(string.format("Avg checks per   : %.3f", averageChecks))
  demonwalker:echo(string.format("Median checks per: %.3f", medianChecks))
end

function demonwalker:closestRoom()
  local remainingRooms = demonwalker.remainingRooms
  local startingRoom = mmp.currentroom
  if not remainingRooms or table.is_empty(remainingRooms) then return "" end
  demonwalker:startPerfTimer()
  local roomsToCheck = {
    [startingRoom] = true
  }
  local numberOfChecks = 0
  for iteration = 1, demonwalker.config.breadth do
    if demonwalker.config.debug then
      demonwalker:echo("Iteration: " .. iteration)
    end
    local newRooms = {}
    for room,_ in pairs(roomsToCheck) do
      if demonwalker.config.debug then
        demonwalker:echo("Checking adjacent rooms of :" .. room)
      end
      for id,_ in pairs(demonwalker:getAdjacentRooms(room)) do
        numberOfChecks = numberOfChecks + 1
        if remainingRooms[id] then
          demonwalker:recordPerfTime(iteration, numberOfChecks)
          return id
        end
        newRooms[id] = true
      end
    end
    roomsToCheck = newRooms
  end
  if demonwalker.config.debug then
    demonwalker:echo("Did not find a room within the configured breadth:" .. numberOfChecks)
  end
  -- we didn't find an unvisited room within demonwalker.config.breadth steps, so now let's loop the remaining rooms list
  local distance = 99999
  local minDistance = demonwalker.config.breadth + 1
  local targetRoom = ""
  for roomID,_ in pairs(remainingRooms) do
    numberOfChecks = numberOfChecks + 1
    local ok, pathLength = getPath(startingRoom, roomID)
    if ok and pathLength < distance then
      distance = pathLength
      targetRoom = roomID
      if distance <= minDistance then
        demonwalker:recordPerfTime(distance, numberOfChecks)
        return targetRoom
      end
    end
  end
  demonwalker:recordPerfTime(distance, numberOfChecks)
  return targetRoom
end

if _comp(demonwalker.config, {}) then demonwalker:load() end
