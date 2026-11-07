# Installing these profiles on HorizonXI

For a friend starting from a working HorizonXI launcher install. About five minutes. Get the files from
<https://github.com/wingerman/horizonxi>: green **Code** button, **Download ZIP**, or `git clone https://github.com/wingerman/horizonxi.git`.

## 1. Locate the Game folder

The launcher installs to a folder containing `HorizonXI-Launcher.exe` and a `Game` subfolder.
Common locations: `C:\Program Files\HorizonXI\Game`, `C:\Users\<you>\AppData\Local\HorizonXI\Game`,
or a custom drive like `G:\horizonxi\HorizonXI\Game`. The right `Game` folder contains `addons`,
`config`, `scripts` and `polplugins`.

## 2. Get your character folder name

Log in. In the chat box:

```
/addon load luashitacast
/lac newlua
```

It prints the file it created. Browse to `Game\config\addons\luashitacast\` and you will see a
folder like `Pyka_204587`. That is your character folder name. Delete the blank job file it made
if you are about to copy a real one in.

## 3. Copy the files

From this repo, copy `luashitacast\common\` and `luashitacast\<Name>_<Id>\` into
`Game\config\addons\luashitacast\`. Result:

```
Game\config\addons\luashitacast\
    common\
    <Name>_<Id>\
        BLM.lua
        settings.lua
```

Or use the scripts in `scripts/` with your character folder and Game path as arguments.

## 4. Load it

In game: `/lac reload`. If your job matches a file in the folder it loads now; otherwise change job.
`/lac list` shows the sets it found. `/lac debug on` prints every swap so you can see it working.

## Troubleshooting

- **Nothing swaps.** `/addon list` should show luashitacast. If not, `/addon load luashitacast`.
  Check the folder name matches your character exactly, including the id.
- **Red error on load.** `/lac safecall` toggles error swallowing off so the real Lua error prints
  with a line number. Usually a missing comma or quote in a set.
- **A slot never changes.** The item name does not match inventory exactly, or the set uses an
  empty string (`''`), which LuAshitacast ignores. Use `'remove'` to clear a slot on purpose.
- **Swaps feel late or out of order.** Confirm the Sequencer plugin is loaded (`/load sequencer`
  is in Horizon's default.txt). Do not add PacketFlow; Horizon's addon page warns against it.
- **Crash when zoning or changing job.** Some profile sets report that setting `aliases.silent = 1`
  in `Game\config\boot\ashita.ini` (or via the `/ashita` menu) helps.
- **Wardrobes.** HorizonXI has inventory, satchel, sack, case and the first two wardrobes; the
  per-character `settings.lua` lists which bags LuAshitacast searches (`EquipBags`).
