---
layout: project
title: Frontier Expansion
date: 2022-07-23
tags: [decomp]
---

This branch uses the RHH master branch and modifies the Battle Frontier to have up to Gen 6 Pokémon (sorry if you want later gens).

Doing everything manually would be a lot of work so I automated some steps, it is currently not perfect but I'm happy with it and it's a good starting point.
I basically copied the smogon Gen 6 movesets and converted them to the format in [`src/data/battle_frontier/battle_frontier_mons.h`](https://github.com/Artrios/pokeemerald/blob/frontier_expansion/src/data/battle_frontier/battle_frontier_mons.h) with a script.
I will be tweaking and improving it when I can. Any suggestions or pull requests are welcome.


But because of how it was done here are a few things that should be noted:
* The moveset chosen from smogon is the first moveset in the highest tier that Pokémon is in (without holding a mega stone).
* Pokémon with no moveset had one chosen for them.
* Some movesets use a specific Hidden Power type. I added new moves for these that are copies of Hidden Power with a different type because IVs cannot be set for these Pokémon. The type can be seen but only in the Battle Factory (since it's the only facility where you use Frontier Pokémon).
* The moves Mimic, Sketch and Transform have been edited so they will use the regular Hidden Power instead. Metronome is banned from using them too.
* The Anticipation ability will be triggered by them, have not looked into this yet.
* Old Pokémons' movesets have not been altered except for a couple.
* Nearly every second new Pokémon added uses a Life Orb (I'll change most of them for diversity's sake).
* Similarly pretty much every Pokémon in the Little Cup tier held an Eviolite which has been removed and they're currently not holding anything.
* The Battle Frontier has it's own tier system (kinda separated out in [`include/constants/battle_frontier_mons.h`](https://github.com/Artrios/pokeemerald/blob/frontier_expansion/include/constants/battle_frontier_mons.h))
* Weak Pokémon have 1 entry
* Pokémon a bit stronger have 2
* Most last stage Pokémon have 4
* Some of the strongest non-legendaries have 8
* Legendaries have 6
* Dragonite and Tyranitar have 10
* The old Pokémon have variations of their movesets, new Pokémon have just the 1 for each of their entries (will be changed)
* New Pokémon were added to trainer semi-automatically. I chose a similar old Pokémon for each new Pokémon, every trainer capable of using the old Pokémon had the new Pokémon added to their roster. Eg. Every trainer with Caterpie now has Scatterbug too. Might make some changes to the rosters.
* Finally, I am not a competitive player so it is probably far from balanced :)