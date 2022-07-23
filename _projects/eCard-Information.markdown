---
layout: project
title: eCard Information
date: 2022-07-23
---

This is all what hatschky wrote, not me.

For a long time, I didnt know anything about the e-Reader other than that it was a short-lived gimmick on Pokémon trading cards. Once I realized that it was basically a Nintendo-approved flash cart that can [install patches in games](http://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_Battle_e_Promotional_cards#Berry_Fix_cards), Ive really wanted to find out how it works and how to make my own cards for it.

Ive [made a disassembly](https://github.com/hatschky/pokecarde) of most of the English e-Reader cards released for Pokémon Ruby and Sapphire (excluding some promotional cards, but including the Eon Ticket). These programs are Z80 machine code which the e-Reader emulates on the GBA. The program communicates with the linked GBA running Ruby/Sapphire and sends Mystery Events data.

## Prologue
The first packet of data sent by a Mystery Events card is 60 bytes. It seems to be exactly the same for every card, except for two useless fields and a region code.
```
Offset Len  Description
$00    14   GameFreak inc. [sic] in ASCII
$0E    6    Unknown (00 00 00 00 00 00)
$14    4    Arbitrary number
$18    8    Arbitrary identifier in R/S charset
$24    10   Unknown (00 00 00 00 01 55 00 00 00 00)
$2A    1    01: Japanese; 02: English
$2B    1    Unknown (00)
$2C    14   GameFreak inc. [sic] in ASCII
$3A    2    Probably padding (00 00)
```
Apparently Generation III was a period in which Game Freak didnt know what their companys name was; its also spelled as one word on the title screens of the Japanese Generation III games, but as two words on the cartridge labels and most everywhere else.

On Battle e cards, the arbitrary number is $12345678 and the arbitrary identifier is Ｅ (an apparent typo for Card e). On the Gentleman Nils and Lady Astrid cards included in the American releases of Ruby and Sapphire, the arbitrary number is 0 and the arbitrary identifiers are NILS and ASTRID. On the Eon Ticket, the arbitrary number is 0 and the arbitrary identifier is e reader with no $FF terminator.

If the region code at offset $2A is wrong, the game will terminate the link with the message Loading error. Ending session., which is the same message used for checksum failures.

## Header
The second packet, which contains the actual card data, is either 3072 or 6144 bytes long, starting with a 24- or 32-byte header and ending by lazily copying about 20005000 bytes after the end of the data, including the cards entire Z80 program. Its almost a quine!
```
Offset Len  Description
$00  1    Unknown (01)
$01  4    Base address ($02000000)
            This is where the data gets loaded in RAM, and all subsequent
            pointers are based on this location.
$05  1    01: Japanese; 02: English
$06  1    Unknown (00)
$07  1    01: Japanese; 02: English
$08  9    Unknown (00 00 00 04 00 80 01 00 00)
$11  1    Data type
              2: Variable-length data (must be used inside type 16)
              5: Custom script, runs immediately (must be used inside type 16)
              6: Custom script, runs in-game (must be used inside type 16)
              7: Enigma Berry
              11: Mixing records gift item
              13: Battle Trainer
              16: Contains multiple types
```

God knows why they needed two more copies of the region code, but if either is incorrect, the message This data cannot be used in this version. will appear. The region code in the prologue must be correct to even reach this point, so this message is never seen when scanning a real card.

For simple cards such as the Enigma Berries or Battle Trainers, which consist of a single fixed-length chunk of data, the header finishes with six more bytes:
```
Offset Len  Description
$12    4    Pointer to data start (always $02000018)
$16    2    Unknown (02 00)
```
For cards with multiple data chunks (type 16), such as the Eon Ticket, the header instead finishes with twelve more bytes:
```
Offset Len  Description
$12    2    Data checksum
$14    2    Padding (00 00)
$16    4    Pointer to data start (always $0200001E)
$1A    4    Pointer to data end
```
Unlike Pokémon data, save data, other kinds of e-Reader cards, or anything else in these games, for which a trivial bytewise or wordwise sum is sufficient to preserve integrity, this particular card structure is SERIOUS GODDAMNED BUSINESS which demands the use of a grown-up CRC function found at $08041174 in the original English Ruby. Heres a C translation:
```c
uint16_t compound_card_crc(const char * data, uint16_t len)
{
    uint16_t x = 0x1121;
    for(uint16_t i = 0; i < len; ++i)
    {
        x ^= data[i];
        for(uint16_t j = 0; j < 8; ++j)
            if(x & 1)
                x = (x >> 1) ^ 0x8408;
            else
                x >>= 1;
    }
    return ~x;
}
```
This relatively impressive level of verification is used only at the time the data is transferred. Once loaded into the game, the separate chunks are protected only by a bytewise checksum preceding each one. Why did they even bother?

After the header, each chunk is declared with a type byte, followed by its data, the length of which is inferred from the type. If variable-length data (type 2) is included, it must come after all fixed-length chunks.

## Chunk Types

### Variable-length data (type 2)
This chunk is used to contain the actual script code for a chunk of type 5 or 6. It has no particular structure; those other chunks include pointers to the specific addresses of the data they need.

### Custom script, runs immediately (type 5)
This chunk is 4 bytes long; its just a pointer to a script stored in the type 2 chunk. The script is executed right away while still on the Mystery Events screen. The result of the script is given using the `setbyte` command ($0E):

* `setbyte 0` is a success state which displays the message The event was safely loaded.
* `setbyte 1` is a failure state which displays the message Loading error. Ending session.
* `setbyte 2` is a success state which displays the message at the address loaded with the `virtualloadpointer` command ($BE).
* `setbyte 3` is a failure state which displays the message at the address loaded with the `virtualloadpointer` command.

Both the Eon Ticket and the Japanese Decoration Present card (which gives the Regirock, Regice, and Registeel Dolls) use `setbyte 2` or `setbyte 3` to display custom messages, so The event was safely loaded. is never seen. The Eon Tickets script fails if the player already has the Eon Ticket item, if flag $00CE is set, or if the Key Items pocket is full. If the type 5 script fails, other chunks (i.e., the Norman event and the mixing records gift) will not be loaded into the save file.

### Custom script, runs in-game (type 6)
This 11-byte chunk gives pointers to the start and end of a script stored in the type 2 chunk, and the person event in the game to which this script should be attached. The script is copied into the save file and run whenever the player interacts with that person.
```
Offset Len  Description
$00    1    Map bank
$01    1    Map number
$02    1    Person event number
$03    4    Pointer to script start
$07    4    Pointer to script end
```
The Eon Ticket gives its script to Norman (map 8.1, person event 1), but it can just as easily be assigned to anyone in Hoenn:

![Desktop View](http://i.imgur.com/vyV61jU.png)
![Desktop View](http://i.imgur.com/TM2bLyz.png)
![Desktop View](http://i.imgur.com/jqLPvHp.png)
![Desktop View](http://i.imgur.com/1obUZCK.png)

The `killscript` command ($0D) deletes the script from the save file.

### Enigma Berry (type 7)
These cards define the properties of a berry which replaces the Enigma Berry as No. 43, triggering an in-game event where Norman gives you the berry at Petalburg Gym (unlike the Eon Ticket, this is hard-coded). The chunk is 1328 bytes long, most of which is just a pretty picture:
```
Offset Len  Description
$000  7    Berry name
$007  1    Firmness (from 1 very soft to 5 super hard)
$008  2    Size (in millimeters)
$00A  1    Maximum yield
$00B  1    Minimum yield
$00C  8    Always 00
$014  1    Hours per growth stage
$015  5    Flavor (Spicy, Dry, Sweet, Bitter, Sour)
$01A  1    Smoothness
$01B  1    Always 00
$01C  1152 Sprite (4848 px)
$49C  32   Palette (16 colors in 15-bit BGR format)
$4BC  45   Tag description line 1
$4E9  45   Tag description line 2
$516  10   Usage by trainer
$520  8    Unknown (always 00)
$528  1    Usage as held item
$529  3    Unknown (always 00)
$52C  4    Bytewise checksum
```
[JPAN on PokéCommunity documented this item-usage-by-trainer data structure](http://www.pokecommunity.com/showpost.php?p=6745155&postcount=11). It consists of a six-byte bitfield followed by parameters. [Parameters are included only if required](http://www.pokecommunity.com/showpost.php?p=8428708&postcount=13).

There could well an equally-sophisticated structure for defining held item usage, but I couldnt find information on that. The known values for offset $528 are:
```
$00: No effect
$04: Cures poison            (Drash Berry)
$05: Cures burn              (Japanese Yago Berry)
$06: Cures freeze            (Pumkin Berry)
$08: Cures confusion         (Japanese Touga Berry)
$17: Restores a lowered stat (Japanese Ginema Berry)
$1C: Cures infatuation       (Eggant Berry)
```
Incidentally, Bulbapedia claims the Kuo Berry cures a burn, but its actually the Yago Berry that does. Too bad its been closed to editing because of some new game that isnt half as exciting as this stuff. :P

### Mixing records gift item (type 11)
This chunk is written to the save file and causes an item to be received in other games when they mix records with this one. It is four bytes long:
```
Offset Len  Description
$00    1    Unknown (01)
$01    1    Distribution limit
$02    2    Item
```
For the Eon Ticket, the distribution limit is 30. This number is reduced by 1 each time the game mixes records, even if the item is not actually distributed (when mixing records with the same game again, or when the recipient does not have space for the item). Receiving the Eon Ticket in this manner automatically activates the Southern Island event.

This only seems to work with key items. Pokémon Emerald will accept key items offered in this manner from Ruby/Sapphire even if the item did not exist in the earlier games (index > $015C). However, receiving the MysticTicket, AuroraTicket, or Old Sea Map in this manner does not activate the corresponding event.

### Battle Trainer (type 13)
This 188-byte chunk is written to the save file and causes a trainer to appear at a house in Mossdeep City. It may also allow this trainer to appear in the Battle Tower. [Furlocks Forest previously documented](http://furlocks-forest.net/wiki/?page=Mossdeep_Trainer_Data) this data structure, but Ive learned a couple of new things about it.
```
Offset Len  Description
$00    1    Battle Tower appearance
              0: does not appear at Battle Tower, only in Mossdeep house
              50: appears in Battle Tower Lv50 challenge
              100: appears in Battle Tower Lv100 challenge
$01    1    Trainer class
$02    1    Battle Tower floor (0: does not appear at Battle Tower)
$03    1    Unknown (always 00)
$04    8    Trainer name
$0C    2    Trainer ID (always 00000)
$0E    2    Trainer SID (always 00000)
$10    12   Pre-battle text (six easy chat halfwords)
$1C    12   Victory text (six easy chat halfwords)
$28    12   Defeat text (six easy chat halfwords)
$34    44   Pokémon 1
$60    44   Pokémon 2
$8C    44   Pokémon 3
$B8    4    Wordwise checksum
```
The indices for trainer classes are different than those used for the in-game trainer data. I dont know if this list is used for anything other than e-Reader cards.
```
$00: *AQUA LEADER
$01: *TEAM AQUA    ()
$02: *TEAM AQUA    ()
$03:  AROMA LADY
$04:  RUIN MANIAC
$05: *INTERVIEWER
$06:  TUBER        ()
$07:  TUBER        ()
$08:  COOLTRAINER
$09:  COOLTRAINER
$0A:  HEX MANIAC
$0B:  LADY
$0C:  BEAUTY
$0D:  RICH BOY
$0E:  POKéMANIAC
$0F:  SWIMMER
$10:  BLACK BELT
$11:  GUITARIST
$12:  KINDLER
$13:  CAMPER
$14:  BUG MANIAC
$15:  PSYCHIC      ()
$16:  PSYCHIC      ()
$17:  GENTLEMAN
$18: *ELITE FOUR  (Sidney)
$19: *ELITE FOUR  (Phoebe)
$1A: *LEADER      (Roxanne)
$1B: *LEADER      (Brawly)
$1C: *LEADER      (Tate&Liza)
$1D:  SCHOOL KID  ()
$1E:  SCHOOL KID  ()
$1F: *SR. AND JR.
$20:  POKéFAN      ()
$21:  POKéFAN      ()
$22:  EXPERT      ()
$23:  EXPERT      ()
$24:  YOUNGSTER
$25: *CHAMPION
$26:  FISHERMAN
$27:  TRIATHLETE  ( cycling)
$28:  TRIATHLETE  ( cycling)
$29:  TRIATHLETE  ( running)
$2A:  TRIATHLETE  ( running)
$2B:  TRIATHLETE  ( swimming)
$2C:  TRIATHLETE  ( swimming)
$2D:  DRAGON TAMER
$2E:  BIRD KEEPER
$2F:  NINJA BOY
$30:  BATTLE GIRL
$31:  PARASOL LADY
$32:  SWIMMER
$33:  PICNICKER
$34: *TWINS
$35:  SAILOR
$36: *BOARDER      (Youngster)
$37: *BOARDER      (Youngster)
$38:  COLLECTOR
$39: *PKMN TRAINER (Wally)
$3A: *PKMN TRAINER (Brendan)
$3B: *PKMN TRAINER (Brendan)
$3C: *PKMN TRAINER (Brendan)
$3D: *PKMN TRAINER (May)
$3E: *PKMN TRAINER (May)
$3F: *PKMN TRAINER (May)
$40:  PKMN BREEDER ()
$41:  PKMN BREEDER ()
$42:  PKMN RANGER  ()
$43:  PKMN RANGER  ()
$44: *MAGMA LEADER
$45: *TEAM MAGMA  ()
$46: *TEAM MAGMA  ()
$47:  LASS
$48:  BUG CATCHER
$49:  HIKER
$4A: *YOUNG COUPLE
$4B: *OLD COUPLE
$4C: *SIS AND BRO
```
The classes AQUA ADMIN, MAGMA ADMIN, and WINSTRATE are apparently unavailable, as are the other five Leaders and two Elite Four members. Indices greater than $4C result in mismatches between the trainer class and sprite:

![Desktop View](http://i.imgur.com/7eaWivN.png)

This value also determines the overworld sprite shown in the Mossdeep house. Any class marked with an asterisk, and any value greater than $4C, will be shown in the overworld as a generic male NPC.

There are two identical entries for the unused BOARDER class in this list, implying that male and female versions were planned, and three identical entries each for Brendan and May, which might indicate that they were intended to have multiple sprites like the rivals in prior games.

The 44-byte substructure for Pokémon data is:
```
Offset Len  Description
$00    2    Species
$02    2    Held item
$04    8    Moves
$0C    1    Level
$0D    1    Its not very effective
$0E    6    Effort values
$14    2    OT ID (always 00000)
$16    2    OT SID (always 00000)
$18    4    Individual values (five bits each); bit 31: Ability
$1C    4    Personality value
$20    11   Nickname
$2B    1    Friendship (always 255, unless it knows Frustration)
```
Offset $0D represents the number of PP Ups applied, with two bits for each move. This byte is ultimately copied to offset $3B of the [battle data structure](http://www.pokecommunity.com/showpost.php?p=7156541&postcount=5), which is used to determine the moves maximum PP, but it is not taken into account when initializing the moves remaining PP at the start of the battle. For example, Collector Stuarts Wailord has 3 PP Ups applied to Hydro Pump and Blizzard, but these moves have only 5 out of 8 PP available in the battle. If this Pokémon were holding a Leppa Berry (which it isnt), it would be able to restore one of these moves to 8 PP after expending the original 5 PP, but otherwise PP Ups have no effect. PKMN Ranger Irazu is the other card affected by this glitch; his Pokémon each have three PP Ups for Return.

IVs and EVs seem to have been assigned a bit haphazardly in the Battle e series. Most Pokémon have two perfect IVs and four 15s except for level 100 Pokémon, which have 20s instead of 15s. A few have their IVs adjusted for the sake of Hidden Power, but there are several exceptions that appear to be by mistake, including some Pokémon with one 0 IV. EVs are generally assigned as either 252+252+6 or 255+255, but again there are a few exceptions, including one Pokémon (Psychic Natashas Starmie) that has an illegal EV spread of 6/0/6/252/252/0. Perfect IVs and EVs are sometimes given in the same two stats, but often not.

## Open questions

* Based on the numbering, there would appear to be around 710 other types of Mystery Event chunks which arent used in any e-Reader cards. (Notes: the berry glitch patch doesnt use Mystery Events, the Japanese Decoration Present card uses type 5 scripts to award the Regi dolls, and Altering Cave wasnt in Ruby and Sapphire.) Surely one of them was used for event Pokémon distributions, but Im very interested in finding out what the others are.
* The leaked German Ruby debug version contains some Mystery Event data, including a test Pokémon distribution. I did some searching through the ROM, and found the Eon Ticket script at $45DAE1. First impressions: the events text is translated into German, addresses are based on the ROM location rather than $02000000 (implying this can only work if transferred to another debug cartridge?), the header uses region code 4, offset $0E is set to 0 instead of 1, and the oh-so-important checksum is set to $0000. Theres definitely more to explore here.
* How is Mystery Event data structured in the save file?
* Even though the data itself is nothing special, it might be useful to disassemble the Regi doll card, because it features a basic menu system (for choosing which doll to send) that may be a helpful template for a custom interactive e-Reader program. I think itd be neat to make programs that can do things like customizing a Battle Trainer before you send it to your game.
* The popular conception seems to be that e-Reader support was removed from the Western releases of FireRed, LeafGreen, and Emerald, but there really isnt such a thing. The e-Reader can run any program that fits in a series of dotcodes, and a program can be made to access any of the networking features that exist in the game. Trainer Tower/Trainer Hill customization may have been removed, but theres no reason an e-Reader program couldnt be written to distribute Wonder Cards.


