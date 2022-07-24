---
layout: project
title: PokeCarde
date: 2022-07-23
---

This is a fork of hatschky's decomp repo.

It is a disassembly of the e-Reader cards released for Pokémon Ruby and Sapphire. Hatschky's repo includes the English release of the Pokémon Battle e series, and the Eon Ticket.

I have added the Japanese version of the cards and translated the Japanese-only cards to English. Additionally, I have made 2 branches. The emerald branch has converted all the cards to work the same on Pokemon Emerald, though you still will need to reactivate Mystery Event functionality in Emerald. The emerald-expansion branch goes even further beyond and is for use with a slightly modified pokeemerald-expansion. These cards allow you to use all the pokemon, items and move from the expansion as well as up to 6 Pokemon for each Trainer card and selecting hidden abilities for Pokemon.

RGBDS is needed to compile the Z80 binary for each card. To build a working e-Reader card, you will need to compress the binary and add the card metadata using nedcmake from the nedclib package, which is unfortunately Windows-only.

## Helpful Links
* My post on [customising e-Reader Cards](https://www.pokecommunity.com/showthread.php?t=455241)
* Hatschky's [repo](https://github.com/hatschky/pokecarde)
* My [fork](https://github.com/Artrios/pokecarde)
* [The original archived thread by hatschky on glitchcity](https://archives.glitchcity.info/forums/board-76/thread-7114/page-0.html)
* [Information from that thread in case archive gets deleted](/projects/eCard-Information/)
