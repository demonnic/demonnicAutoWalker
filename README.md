# Demonnic Auto Walker

## What is this thing

This Mudlet package ties in to the events and functions presented by the IRE mudlet mapper script. It will walk to every room in an area, raising an event when it gets to the target room and waiting for you to raise an event telling it to move to the next room. Alternately you can pass it a table of room IDs to visit and it will visit those room IDs specifically rather than every room in an area.

So you could, for instance, use this to write a set of scripts and triggers which moved to a room, checks that room for a gemstone node and if it sees one sends "mine gemstone", if it does not sends the event to move on to the next unchecked room. Then the auto walker will determine which of the next unchecked rooms is closest, move to it, and tell you it has arrived in a new unchecked room. 

If it can't get to a room, it just moves on to the next.

## Usage

1. Call the function demonnic.autowalker:init()
1. listen for event "demonwalker.arrived" (It will call it for the current room you're in first before moving)
1. do whatever you need to do
1. `raiseEvent("demonwalker.move")`
1. listen for event "demonwalker.arrived"
1. do whatever you need to do
1. etc etc

## Stop moving now, please

`raiseEvent("demonwalker.stop")`

## Configuration

* demonnic.autowalker.config.returnToStart
  * when true, will go back to the room where you started the autowalker when it is done (either all rooms visited, or demonwalker.stop event received)

## Porting

It wouldn't be too difficult to port this to other mappers, but it would need:

* a function to call which starts the scripts autowalk procedure (mmp.gotoRoom in IRE mapper)
* a variable which holds the current roomID for checking (mmp.currentroom in IRE mapper)
* an event which is raised when an autowalk completes successfully ("mmapper arrived" in IRE mapper)
* an event which is raised when an autowalk fails ("mmapper failed path" in IRE mapper)

That's really it, everything else is handled by the autowalker. 

TODO:

* Make function called to start the autowalk, variable which holds the current roomID, and events raised for completed autowalk and failed autowalk configuration options
* Make it work with the generic mapping script that ships with Mudlet itself (may require adjustments to the generic mapping script)
