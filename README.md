# TF2 Halloween Potions
This simple plugin allows for more possible chaos to be unleashed after a player is killed. Upon a players death, there is a 50/50 chance for a potion to be spawned from their corpse. There is 6 Potions that all share a balanced chance of occuring. To consume a potion, simply walk over one and gain its effects instantly for a limited duration.

## List of Potions
- 4 seconds of Crits
- 8 seconds of Speed Buff
- 6 seconds of Defense Buff
- 4 seconds of Uber
- 6 seconds of Self-Heal Buff
- 4 seconds of PowerPlay

## Note for Server Hosts
In order to compile, download and setup a stable Windows Branch of Sourcemod 1.9 or later. Place this .sp file into the same folder that compile.exe is located. Once you've placed the file there, either double click compile.exe or drag and drop the .sp file into the exe. If that doesn't help, consult with Alliedmodders documentation.

Set ConVar "sv_halloween_potions_enable" to "1" to enable on all maps. Set to "0" to only allow maps to use it.

## Note for Mappers
If you want your map to use this feature on any servers that support it. Add an "info_target" to your map and name it "tf_halloween_potions_logic".

## Will Valve add this???
No. This is a plugin, written in SourcePawn that hijacks an existing entity. If Valve was to add this, they would need to convert my code into an actual entity. Which is unlikely so this is just a fun concept thingy for community servers.
