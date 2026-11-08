# Agamotto inventory snapshot, 2026-11-07

Parsed from Tim's FindAll plugin cache (`config/plugins/findall/cache/Agamotto_112818.bin`) with
`.claude/skills/ffxi-gear-lua/scripts/parse-findall.py`. The cache holds whatever the client has received: Mog House containers are only as fresh as his last Mog House visit. Names are the in-game short names from the Windower item resource, which is what LuAshitacast matches on. Equipment only; consumables, crafting materials and key items left out. 'BLU' means the item's job list includes Blue Mage per that resource, which predates Horizon's own job-list changes, so treat it as a hint.

Items per container: Inventory 52, Safe 70, Storage 77, Satchel 49, Wardrobe 80, Wardrobe2 80, Wardrobe3 20, Wardrobe8 35. Empty in the cache: Locker, Sack, Case, Safe2, Wardrobe4-7. A second export taken after Tim opened every container and zoned held the same items, so those are truly empty. Temporary is never written.

Container names are Ashita's names for container ids 0-16. The first version of this table (2026-11-07) was off by one from the Locker onward because the parser did not skip the Temporary slot the writer skips; Tim spotted the mislabelling. The four containers that hold nothing but equipment are the wardrobes, which is the check that the mapping is now right.

| Slot | Item | Lv | BLU | Where |
|---|---|---|---|---|
| Main | Bravura | 99 |  | Wardrobe |
| Main | Bahamut's Staff | 75 |  | Wardrobe2 |
| Main | Kirin's Pole | 75 |  | Storage |
| Main/Sub | Relic Dagger | 75 |  | Storage |
| Main/Sub | Demon Slayer | 73 | yes | Wardrobe3 |
| Main/Sub | Devil Slayer | 73 | yes | Wardrobe3 |
| Main/Sub | Maneater | 73 |  | Wardrobe |
| Main/Sub | X's Knife | 72 |  | Wardrobe |
| Main/Sub | Unsho | 71 |  | Safe |
| Main/Sub | Fudo | 70 |  | Safe |
| Main/Sub | Joyeuse | 70 |  | Safe |
| Main/Sub | Sirocco Kukri | 69 |  | Wardrobe |
| Main/Sub | Insect Slayer | 65 | yes | Satchel |
| Main/Sub | Marine Slayer | 65 | yes | Satchel |
| Main/Sub | Tungi | 60 |  | Storage |
| Main/Sub | Wis.Wiz. Anelace | 55 | yes | Storage |
| Main | Apollo's Staff | 51 | yes | Wardrobe2 |
| Main | Aquilo's Staff | 51 | yes | Wardrobe2 |
| Main | Auster's Staff | 51 | yes | Wardrobe2 |
| Main | Jupiter's Staff | 51 | yes | Wardrobe2 |
| Main | Neptune's Staff | 51 | yes | Wardrobe2 |
| Main | Pluto's Staff | 51 | yes | Wardrobe2 |
| Main | Terra's Staff | 51 | yes | Wardrobe2 |
| Main | Vulcan's Staff | 51 | yes | Wardrobe2 |
| Main/Sub | Anju | 40 |  | Storage |
| Main/Sub | Barbaroi Axe | 40 |  | Wardrobe |
| Main | Chanter's Staff | 40 |  | Wardrobe |
| Main | Dragon Staff | 40 |  | Storage |
| Main/Sub | Immortal's Scimitar | 40 | yes | Satchel |
| Main/Sub | Paper Knife | 40 |  | Storage |
| Main/Sub | Zushio | 40 |  | Storage |
| Main/Sub | Warp Cudgel | 36 | yes | Inventory |
| Main/Sub | Tomahawk +1 | 25 |  | Storage |
| Main/Sub | Battleaxe +1 | 20 |  | Storage |
| Main | Treat Staff II | 2 | yes | Wardrobe8 |
| Main | Trick Staff II | 2 | yes | Wardrobe8 |
| Main | Chaosbringer | 1 |  | Storage |
| Main/Sub | Club Hammer | 1 | yes | Wardrobe8 |
| Main/Sub | Dream Bell | 1 | yes | Wardrobe8 |
| Main | Mumeito | 1 |  | Storage |
| Main | Ophidian Sword | 1 | yes | Wardrobe8 |
| Main | Pitchfork | 1 | yes | Wardrobe8 |
| Main | Pitchfork +1 | 1 | yes | Wardrobe8 |
| Main | Treat Staff | 1 | yes | Wardrobe8 |
| Main | Trick Staff | 1 | yes | Wardrobe8 |
| Sub | Genbu's Shield | 74 | yes | Wardrobe |
| Sub | Tatami Shield | 72 |  | Wardrobe |
| Sub | Viking Shield | 45 |  | Wardrobe |
| Sub | Varlet's Targe | 30 | yes | Inventory |
| Range | Donderbuss | 99 |  | Safe |
| Range | Gjallarhorn | 75 |  | Wardrobe2 |
| Range | Ungur Boomerang | 70 |  | Wardrobe |
| Range | Nursemaid's Harp | 60 |  | Wardrobe2 |
| Range | Jr.Msk.Chakram +2 | 43 | yes | Wardrobe3 |
| Range | Thug's Zamburak | 40 |  | Satchel |
| Range | Animator | 1 | yes | Satchel |
| Range | Ebisu Fishing Rod | 1 | yes | Satchel |
| Ammo | Nokizaru Shuriken | 73 |  | Wardrobe |
| Ammo | Pet Food Zeta | 72 | yes | Satchel |
| Ammo | Pet Food Zeta | 72 | yes | Satchel |
| Ammo | Phtm. Tathlum | 66 | yes | Wardrobe2 |
| Ammo | Pet Fd. Epsilon | 60 | yes | Satchel |
| Ammo | C. Carrion Broth | 53 |  | Satchel |
| Ammo | Pet Food Delta | 48 | yes | Satchel |
| Ammo | S. Herbal Broth | 43 |  | Satchel |
| Ammo | Pet Fd. Gamma | 36 | yes | Satchel |
| Ammo | Pet Food Beta | 24 | yes | Satchel |
| Ammo | Fish Oil Broth | 23 |  | Satchel |
| Ammo | Sleep Bolt | 20 |  | Satchel |
| Ammo | Fly Lure | 1 | yes | Safe |
| Ammo | Fortune Egg | 1 | yes | Wardrobe8 |
| Ammo | Frog Lure | 1 | yes | Safe |
| Ammo | Happy Egg | 1 | yes | Wardrobe8 |
| Ammo | Minnow | 1 | yes | Safe |
| Ammo | Shrimp Lure | 1 | yes | Satchel |
| Ammo | Sinking Minnow | 1 | yes | Safe |
| Ammo | Worm Lure | 1 | yes | Safe |
| Head | Chass. Tricorne +1 | 99 |  | Storage |
| Head | Laksa. Tricorne +2 | 99 |  | Wardrobe |
| Head | Pill. Bonnet +2 | 99 |  | Wardrobe |
| Head | Pummeler's Mask +2 | 99 |  | Wardrobe2 |
| Head | Genbu's Kabuto | 75 |  | Wardrobe2 |
| Head | Homam Zucchetto | 75 | yes | Wardrobe |
| Head | Mirage Keffiyeh | 75 | yes | Wardrobe3 |
| Head | Nashira Turban | 75 | yes | Safe |
| Head | Summoner's Horn | 75 |  | Wardrobe2 |
| Head | Ace's Helm | 74 |  | Safe |
| Head | Koga Hatsuburi | 73 |  | Wardrobe2 |
| Head | Bard's Roundlet | 72 |  | Wardrobe2 |
| Head | Panther Mask | 72 |  | Wardrobe |
| Head | Assassin's Bonnet | 71 |  | Wardrobe |
| Head | Yasha Jinpachi +1 | 71 |  | Wardrobe |
| Head | Black Ribbon | 70 | yes | Wardrobe2 |
| Head | Hydra Salade | 70 |  | Storage |
| Head | Optical Hat | 70 | yes | Wardrobe |
| Head | Opo-opo Crown | 65 | yes | Safe |
| Head | President. Hairpin | 65 |  | Safe |
| Head | Arh. Jinpachi +1 | 63 |  | Wardrobe2 |
| Head | Magus Keffiyeh | 60 | yes | Wardrobe3 |
| Head | Reraise Hairpin | 60 | yes | Inventory |
| Head | Ninja Hatsuburi | 56 |  | Wardrobe2 |
| Head | Rogue's Bonnet | 54 |  | Wardrobe |
| Head | Blue Ribbon | 50 | yes | Storage |
| Head | Empress Hairpin | 24 | yes | Wardrobe |
| Head | Dream Hat | 1 | yes | Wardrobe8 |
| Head | Egg Helm | 1 | yes | Wardrobe8 |
| Head | Goblin Masque | 1 | yes | Wardrobe8 |
| Head | Horror Head | 1 | yes | Wardrobe8 |
| Head | Horror Head II | 1 | yes | Wardrobe8 |
| Head | Korrigan Beret | 1 | yes | Wardrobe8 |
| Head | Mandra. Masque | 1 | yes | Wardrobe8 |
| Head | Pumpkin Head | 1 | yes | Wardrobe8 |
| Head | Pumpkin Head II | 1 | yes | Wardrobe8 |
| Head | Shaded Specs. | 1 | yes | Wardrobe |
| Head | Wh. Rarab Cap | 1 | yes | Wardrobe8 |
| Neck | Hope Torque | 73 | yes | Wardrobe2 |
| Neck | Love Torque | 73 | yes | Wardrobe |
| Neck | Prudence Torque | 73 | yes | Wardrobe |
| Neck | Harmonia's Torque | 72 | yes | Wardrobe |
| Neck | Jeweled Collar +1 | 70 | yes | Wardrobe2 |
| Neck | Uggalepih Pendant | 70 | yes | Wardrobe2 |
| Neck | Ninjutsu Torque | 65 | yes | Wardrobe2 |
| Neck | Smn. Torque | 65 | yes | Wardrobe3 |
| Neck | String Torque | 65 | yes | Wardrobe2 |
| Neck | Wind Torque | 65 | yes | Wardrobe2 |
| Neck | Star Necklace | 59 | yes | Storage |
| Neck | Checkered Scarf | 55 | yes | Wardrobe2 |
| Neck | Shield Pendant | 35 | yes | Inventory |
| Neck | Peacock Amulet | 33 | yes | Wardrobe |
| Neck | Spike Necklace | 21 | yes | Wardrobe3 |
| Neck | Justice Badge | 7 | yes | Inventory |
| Ear | Brutal Earring | 75 | yes | Wardrobe3 |
| Ear | Loquac. Earring | 75 | yes | Wardrobe2 |
| Ear | Beastly Earring | 72 | yes | Wardrobe |
| Ear | Magnetic Earring | 72 | yes | Wardrobe2 |
| Ear | Musical Earring | 70 | yes | Wardrobe |
| Ear | Stealth Earring | 70 | yes | Wardrobe2 |
| Ear | Crimson Earring | 67 | yes | Inventory |
| Ear | Relaxing Earring | 65 | yes | Wardrobe2 |
| Ear | Merman's Earring | 63 | yes | Wardrobe |
| Ear | Insomnia Earring | 50 | yes | Wardrobe3 |
| Ear | Velocity Earring | 50 | yes | Wardrobe3 |
| Ear | Moldavite Earring | 47 | yes | Wardrobe |
| Ear | Intruder Earring | 40 | yes | Storage |
| Ear | Ninjutsu Earring | 35 | yes | Wardrobe2 |
| Ear | Dodge Earring | 29 | yes | Wardrobe |
| Ear | Dodge Earring | 29 | yes | Wardrobe |
| Ear | Reraise Earring | 24 | yes | Satchel |
| Ear | Federation Earring | 20 | yes | Satchel |
| Ear | Kingdom Earring | 20 | yes | Satchel |
| Ear | Republic Earring | 20 | yes | Satchel |
| Ear | Cassie Earring | 1 | yes | Wardrobe3 |
| Body | Chasseur's Frac | 99 |  | Storage |
| Body | Laksa. Frac +2 | 99 |  | Safe |
| Body | Homam Corazza | 75 | yes | Wardrobe2 |
| Body | Kirin's Osode | 75 |  | Wardrobe |
| Body | Mirage Jubbah +1 | 75 | yes | Wardrobe3 |
| Body | Nashira Manteel | 75 | yes | Wardrobe3 |
| Body | Summoner's Dblt. | 74 |  | Wardrobe2 |
| Body | Hecatomb Harness | 73 |  | Wardrobe |
| Body | Errant Hpl. | 72 | yes | Wardrobe2 |
| Body | Monster Jackcoat | 72 |  | Wardrobe |
| Body | Sha'ir Manteel | 72 |  | Wardrobe2 |
| Body | Yinyang Robe | 71 |  | Wardrobe2 |
| Body | Arhat's Gi +1 | 64 |  | Wardrobe2 |
| Body | Minstrel's Coat | 62 | yes | Wardrobe2 |
| Body | Choral Jstcorps | 58 |  | Storage |
| Body | Magus Jubbah | 58 | yes | Wardrobe3 |
| Body | Rogue's Vest | 58 |  | Wardrobe |
| Body | Scp. Harness +1 | 57 | yes | Wardrobe |
| Body | Gaudy Harness | 50 |  | Safe |
| Body | Rapparee Harness | 50 |  | Wardrobe2 |
| Body | Brigandine | 45 | yes | Wardrobe |
| Body | Wonder Kaftan | 33 | yes | Wardrobe |
| Body | Angler's Tunica | 15 | yes | Wardrobe |
| Body | Worker Tunica | 15 | yes | Inventory |
| Body | Eerie Cloak | 1 | yes | Wardrobe8 |
| Body | Fisherman's Apron | 1 | yes | Safe |
| Body | Goblin Suit | 1 | yes | Wardrobe8 |
| Body | Goldsmith's Apron | 1 | yes | Wardrobe |
| Body | Lord's Yukata | 1 | yes | Wardrobe8 |
| Body | Mandra. Suit | 1 | yes | Wardrobe8 |
| Body | Onoko Yukata | 1 | yes | Wardrobe8 |
| Body | Taru. Maillot +1 | 1 | yes | Wardrobe8 |
| Body | Tarutaru Maillot | 1 | yes | Wardrobe8 |
| Body | Wonder Maillot +1 | 1 | yes | Wardrobe8 |
| Hands | Assassin's Armlets | 75 |  | Wardrobe |
| Hands | Carbuncle's Cuffs | 75 | yes | Wardrobe2 |
| Hands | Homam Manopolas | 75 | yes | Wardrobe2 |
| Hands | Koga Tekko | 75 |  | Wardrobe2 |
| Hands | Nashira Gages | 75 | yes | Wardrobe2 |
| Hands | Seiryu's Kote | 75 |  | Wardrobe2 |
| Hands | Chl. Cuffs +1 | 74 |  | Wardrobe2 |
| Hands | Bandomusha Kote | 73 |  | Wardrobe |
| Hands | Bard's Cuffs | 73 |  | Storage |
| Hands | Hecatomb Mittens | 73 |  | Wardrobe |
| Hands | Dusk Gloves | 72 | yes | Wardrobe |
| Hands | Sheikh Gages | 72 |  | Wardrobe2 |
| Hands | Summoner's Brcr. | 72 |  | Wardrobe2 |
| Hands | Hydra Gloves | 70 |  | Storage |
| Hands | Ogre Gloves | 70 |  | Wardrobe |
| Hands | Creek M Mitts | 62 | yes | Wardrobe |
| Hands | Ninja Tekko | 60 |  | Wardrobe2 |
| Hands | Magus Bazubands | 56 | yes | Wardrobe3 |
| Hands | Rogue's Armlets | 52 |  | Wardrobe |
| Hands | Wonder Mitts | 27 | yes | Wardrobe |
| Hands | Mycophile Cuffs | 25 |  | Storage |
| Hands | Carbuncle Mitts | 20 |  | Wardrobe2 |
| Hands | Angler's Gloves | 15 | yes | Wardrobe |
| Hands | Worker Gloves | 15 | yes | Inventory |
| Hands | Ryl.Ftm. Gloves | 10 | yes | Wardrobe |
| Hands | Dream Mittens +1 | 1 | yes | Wardrobe8 |
| Ring | Snow Ring | 74 | yes | Wardrobe |
| Ring | Snow Ring | 74 | yes | Wardrobe |
| Ring | Angel's Ring | 72 | yes | Wardrobe2 |
| Ring | Spinel Ring | 72 | yes | Satchel |
| Ring | Spinel Ring | 72 | yes | Satchel |
| Ring | Triumph Ring | 72 | yes | Wardrobe2 |
| Ring | Triumph Ring | 72 | yes | Wardrobe2 |
| Ring | Evoker's Ring | 71 |  | Wardrobe2 |
| Ring | Altep Ring | 65 | yes | Storage |
| Ring | Altep Ring | 65 | yes | Satchel |
| Ring | Dem Ring | 65 | yes | Satchel |
| Ring | Mea Ring | 65 | yes | Satchel |
| Ring | Yhoat Ring | 65 | yes | Satchel |
| Ring | Bloodbead Ring | 62 | yes | Wardrobe |
| Ring | Tavnazian Ring | 60 | yes | Wardrobe2 |
| Ring | Bomb Queen Ring | 57 | yes | Wardrobe2 |
| Ring | Toreador's Ring | 57 | yes | Wardrobe |
| Ring | Toreador's Ring | 57 | yes | Wardrobe |
| Ring | Minstrel's Ring | 50 |  | Wardrobe2 |
| Ring | Ether Ring | 40 | yes | Wardrobe2 |
| Ring | Sattva Ring | 30 | yes | Wardrobe |
| Ring | Astral Ring | 10 | yes | Wardrobe2 |
| Ring | Astral Ring | 10 | yes | Wardrobe2 |
| Ring | Bastokan Ring | 1 | yes | Storage |
| Ring | Chariot Band | 1 | yes | Inventory |
| Ring | San d'Orian Ring | 1 | yes | Storage |
| Ring | Windurstian Ring | 1 | yes | Storage |
| Back | Shadow Mantle | 75 | yes | Wardrobe |
| Back | Astute Cape | 73 | yes | Wardrobe2 |
| Back | Forager's Mantle | 71 | yes | Wardrobe |
| Back | Gigant Mantle | 70 | yes | Wardrobe |
| Back | Jester's Cape +1 | 54 | yes | Wardrobe2 |
| Back | Resentment Cape | 40 | yes | Satchel |
| Back | Warlock's Mantle | 30 | yes | Wardrobe |
| Back | Night Cape | 21 | yes | Wardrobe |
| Waist | Scouter's Rope | 73 | yes | Satchel |
| Waist | Hierarch Belt | 71 | yes | Wardrobe |
| Waist | Koga Sarashi | 70 |  | Wardrobe2 |
| Waist | Steppe Sash | 70 | yes | Wardrobe |
| Waist | Muscle Belt +1 | 67 |  | Wardrobe2 |
| Waist | Earth Belt | 65 | yes | Satchel |
| Waist | Gleeman's Belt | 60 |  | Wardrobe2 |
| Waist | Ryl.Kgt. Belt | 50 | yes | Storage |
| Waist | Swift Belt | 50 | yes | Wardrobe |
| Waist | Life Belt | 48 | yes | Wardrobe |
| Waist | Swordbelt +1 | 43 | yes | Inventory |
| Waist | Warrior's Belt +1 | 15 | yes | Wardrobe |
| Legs | Pill. Culottes +2 | 99 |  | Wardrobe |
| Legs | Bard's Cannions | 75 |  | Wardrobe2 |
| Legs | Byakko's Haidate | 75 |  | Wardrobe2 |
| Legs | Homam Cosciales | 75 | yes | Wardrobe2 |
| Legs | Nashira Seraweels | 75 | yes | Storage |
| Legs | Assassin's Culottes | 74 |  | Wardrobe |
| Legs | Chl. Cannions +1 | 74 |  | Wardrobe2 |
| Legs | Evk. Spats +1 | 74 |  | Wardrobe2 |
| Legs | Blood Cuisses | 73 | yes | Wardrobe3 |
| Legs | Koga Hakama | 71 |  | Wardrobe2 |
| Legs | Summoner's Spats | 71 |  | Wardrobe2 |
| Legs | Yasha Hakama +1 | 71 |  | Wardrobe2 |
| Legs | Hydra Brais | 70 |  | Storage |
| Legs | Choral Cannions | 56 |  | Storage |
| Legs | Rogue's Culottes | 56 |  | Storage |
| Legs | Magus Shalwar | 54 | yes | Wardrobe3 |
| Legs | Capri. Subligar | 50 |  | Safe |
| Legs | Sagit. Subligar | 50 |  | Safe |
| Legs | Taurus Subligar | 50 |  | Safe |
| Legs | Wonder Braccae | 31 | yes | Wardrobe |
| Legs | Baron's Slops | 20 | yes | Storage |
| Legs | Angler's Hose | 15 | yes | Wardrobe |
| Legs | Dream Trousers | 1 | yes | Wardrobe8 |
| Legs | Dream Trousers +1 | 1 | yes | Wardrobe8 |
| Legs | Taru. Trunks +1 | 1 | yes | Wardrobe8 |
| Legs | Tarutaru Trunks | 1 | yes | Wardrobe8 |
| Feet | Laksa. Bottes +1 | 99 |  | Wardrobe3 |
| Feet | Homam Gambieras | 75 | yes | Wardrobe |
| Feet | Kog. Kyahan +1 | 75 |  | Wardrobe2 |
| Feet | Mirage Charuqs +1 | 75 | yes | Wardrobe3 |
| Feet | Nashira Crackows | 75 | yes | Wardrobe2 |
| Feet | Rostrum Pumps | 75 |  | Wardrobe2 |
| Feet | Suzaku's Sune-Ate | 75 |  | Wardrobe |
| Feet | Evk. Pigaches +1 | 74 |  | Wardrobe2 |
| Feet | Monster Gaiters | 74 |  | Wardrobe |
| Feet | Nin. Kyahan +1 | 74 |  | Wardrobe2 |
| Feet | Hct. Leggings | 73 |  | Wardrobe |
| Feet | Summoner's Pgch. | 73 |  | Wardrobe2 |
| Feet | Dusk Ledelsens | 72 | yes | Wardrobe |
| Feet | Bard's Slippers | 71 |  | Storage |
| Feet | Evoker's Boots | 71 |  | Wardrobe2 |
| Feet | Root Sabots | 69 | yes | Inventory |
| Feet | Rogue's Poulaines | 60 |  | Wardrobe |
| Feet | Choral Slippers | 52 |  | Storage |
| Feet | Magus Charuqs | 52 | yes | Wardrobe3 |
| Feet | Powder Boots | 38 | yes | Inventory |
| Feet | Powder Boots | 38 | yes | Inventory |
| Feet | Powder Boots | 38 | yes | Inventory |
| Feet | Powder Boots | 38 | yes | Inventory |
| Feet | Powder Boots | 38 | yes | Inventory |
| Feet | Powder Boots | 38 | yes | Satchel |
| Feet | Wonder Clomps | 29 | yes | Wardrobe |
| Feet | Trotter Boots | 20 |  | Wardrobe |
| Feet | Worker Boots | 15 | yes | Inventory |
| Feet | Bounding Boots | 7 | yes | Wardrobe |
| Feet | Dream Boots +1 | 1 | yes | Wardrobe8 |
| Feet | Waders | 1 | yes | Wardrobe |
