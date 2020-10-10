# Demonnic Auto Walker
This Mudlet package ties in to the events and functions presented by the IRE mudlet mapper script. It will walk to every room in an area, raising an event when it gets to the target room and waiting for you to raise an event telling it to move to the next room. Alternately you can pass it a table of room IDs to visit and it will visit those room IDs specifically rather than every room in an area.

So you could, for instance, use this to write a set of scripts and triggers which moved to a room, checks that room for a gemstone node and if it sees one sends "mine gemstone", if it does not sends the event to move on to the next unchecked room. Then the auto walker will determine which of the next unchecked rooms is closest, move to it, and tell you it has arrived in a new unchecked room. 

If it can't get to a room, it just moves on to the next.

TODO:
* Document how to use the damn thing
* Document what would need to be present/changed in order to port it to other mapping scripts
* Make it work with the generic mapping script that ships with Mudlet itself (may require adjustments to the generic mapping script)
