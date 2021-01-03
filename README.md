# Demonwalker

## What is this thing

This Mudlet package ties in to the events and functions presented by the IRE mudlet mapper script. It will walk to every room in an area, raising an event when it gets to the target room and waiting for you to raise an event telling it to move to the next room. Alternately you can pass it a table of room IDs to visit and it will visit those room IDs specifically rather than every room in an area.

So you could, for instance, use this to write a set of scripts and triggers which moved to a room, checks that room for a gemstone node and if it sees one sends "mine gemstone", if it does not sends the event to move on to the next unchecked room. Then the auto walker will determine which of the next unchecked rooms is closest, move to it, and tell you it has arrived in a new unchecked room. 

If it can't get to a room, it just moves on to the next.

## Basic Usage

* `demonwalker:init()`
  * see entry for demonwalker:init() in [Functions](#functions) for more advanced usage. Called like this it will walk each room in the current area.
* start loop
* listen for event "demonwalker.arrived"
* do whatever you need to do in the demonwalker.arrived event handler
* `raiseEvent("demonwalker.move")`
* repeat loop

## Stop moving now, please

### Via lua

`raiseEvent("demonwalker.stop")`

### Via alias

`dwalk stop`

## Configuration

* demonwalker.config.returnToStart
  * when true, will go back to the room where you started the autowalker when it is done (either all rooms visited, or demonwalker.stop event received)
* demonwalker.config.breadth
  * When asked to find the next room to move to, it will search this many rooms away from your current room before falling back to checking the distance to all the remaining rooms and choosing the shortest one. Defaults to 10
* demonwalker.config.avoidList
  * list of roomIDs to avoid in **all** walks. demonwalker:addAvoidRoom(roomID) and demonwalker:removeAvoidRoom(roomID) to add/remove items from the list. This table uses roomIDs as keys, it's advised not to alter it directly. See also the dwalk alias below

## Alias

* `dwalk`
  * prints out the demonwalker configuration.
* `dwalk usage`
  * prints out usage information for dwalk alias set
* `dwalk report`
  * prints out the performance report for current walk, or last one completed if you're not currently using demonwalker.
* `dwalk stop`
  * stops demonwalker. Equivalent to raising the "demonwalker.stop" event
* `dwalk move`
  * Tells the walker to move on. Equivalent to raising the "demonwalker.move" event
* `dwalk avoidList`
  * prints out the global list of rooms to avoid in **all** walks
* `dwalk avoid <roomID>`
  * adds roomID to the global avoid list.
* `dwalk unavoid <roomID>`
  * removes roomID from the global avoid list.
* `dwalk breadth <newBreadth>`
  * Sets the number of rooms to search from your current one, before just checking all the remaining rooms for the closest. Defaults to 10, and you'll likely never need to change it.
* `dwalk returnToStart <true/false>`
  * Set returnToStart value. If true, will return to the room the walk started in when it's stopped/finished.
* `dwalk debug <true/false>`
  * Used to turn on/off debug. Will be kind of spammy if turned on, and mostly useful during development.

## Functions

* demonwalker:addAvoidRoom(roomID)
  * adds a room ID to the list of rooms to not include in **any** walks
* demonwalker:removeAvoidRoom(roomID)
  * removes a room ID from the list of rooms to not include in **any** walks
* demonwalker:init(options)
  * starts a walk. Options an optional table of options. Valid keys are
    * rooms: a list of roomIDs to visit. IE {1, 2, 4, 10} . If not provided will be the list of all rooms in the area.
    * avoidRooms: a list of roomIDs to make sure is not included in **this** walk. Not saved between walks.
    * searchTargets: a list of items to check for. IE {"a thief on a leaf", "a dracnari hunk", "a dracnari dreamer"}.
      * If this list is provided, then demonwalker will check every room for each of these items, and if any of them are found then and only then will it raise `demonwalker.arrived`. This makes it easy to automate looking for one or more creatures or items in an area, without worrying about stopping the walker yourself.
* demonwalker:performanceReport()
  * prints out some performance information on the current walk if still running a walk, or the last walk if one has been completed.

## Events

### Listens for

* demonwalker.move
  * when this event is raised, if mmp is paused it will unpause it so it starts walking again. If it is not paused, then it will choose the closest unvisited room and begin walking to it.
* demonwalker.stop
  * when this event is raise, the current walk will end, and if demonwalker.config.returnToStart is true it will move back to the room the walk began in.
* mmapper arrived
  * when this event is raised, it means the speedwalk has ended and we're at the room we were moving to. demonwalker then does some housekeeping and raises `demonwalker.arrived`
* mmapper failed path
  * when this event is raised it means the speedwalk could not continue, so we make sure to remove the room we were moving to and then pick the next one and move to it

### Raises

* demonwalker.arrived
  * raised when we have arrived at a new room, or a room which contains an item/mob we've been told to stop for. Should be listened for in order to signal that it is time to "do the thing", whatever that might be.
* demonwalker.finished
  * raised when the overall walk is finished, whether because it ran out of rooms to move to, or it was stopped using the `demonwalker.stop` event. Raised before the walk to the starting room is finished, to do something when that occurs listen for demonwalker.finished to register a one-time event handler for `mmapper arrived`

## Porting

It wouldn't be too difficult to port this to other mappers, but it would need:

* a function to call which starts the scripts autowalk procedure (mmp.gotoRoom in IRE mapper)
* a variable which holds the current roomID for checking (mmp.currentroom in IRE mapper)
* an event which is raised when an autowalk completes successfully ("mmapper arrived" in IRE mapper)
* an event which is raised when an autowalk fails ("mmapper failed path" in IRE mapper)
* a way to pause, unpause, and check the paused status of the walker
* game needs to use telnet GA or EOR so that prompt triggers function

That's really it, everything else is handled by the autowalker.

TODO:

* Make it work with the generic mapping script that ships with Mudlet itself (will require adjustments to the generic mapping script)

* Make implementing the porting items above easier by making them configuration options.
