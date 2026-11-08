# wingerman-horizonxi

HorizonXI assets for Wingerman and friends: authored [LuAshitacast](https://github.com/ThornyFFXI/LuAshitacast)
gear-swap profiles, Ashita scripts, macro references and setup notes. Built so a friend can clone
it, copy their character folder into their install, and be swapping gear in a minute.

[HorizonXI](https://horizonxi.com/) is a 75-era FFXI private server. Its launcher ships Ashita v4
with LuAshitacast pre-installed. Everything here is approved-addon territory: gear swaps on your
own actions. Nothing here automates actions, which Horizon forbids.

## Layout

```
luashitacast/
  common/              shared libraries every profile may load (gFunc.LoadFile('common\\x.lua'))
  _template/           annotated starter profile to copy for a new job
  <Name>_<CharId>/     one folder per character, one <JOB>.lua per job, plus settings.lua
ashita-scripts/        text scripts for Game\scripts\, run in game with /exec <name>.txt
macros/                in-game macro palettes written out as reference
docs/                  setup and install guides, blue-magic-75.md (per-spell formulas and modifiers), gear-research/ (verified item tables)
scripts/               deploy.sh (WSL/Linux) and deploy.ps1 (Windows) to copy a character into an install
.claude/skills/       ffxi-gear-lua: how these profiles are researched, built, checked and deployed, for AI
                       agents (Claude Code loads it on demand) and humans; its scripts/ has the FindAll
                       inventory parser and the profile checker
```

## Install

Clone or download: <https://github.com/wingerman/horizonxi> (`git clone https://github.com/wingerman/horizonxi.git`).

1. Find your HorizonXI game folder. Default is `C:\Program Files\HorizonXI\Game` or wherever the
   launcher put it; the `Game` folder contains `addons`, `config`, `scripts`, `polplugins`.
2. Find your character folder name. In game, `/addon load luashitacast` then `/lac newlua` creates
   `Game\config\addons\luashitacast\<Name>_<Id>\<JOB>.lua`. The folder name is what you need.
3. Copy `luashitacast\common\` and your `luashitacast\<Name>_<Id>\` into
   `Game\config\addons\luashitacast\`. Or run a deploy script:

   ```powershell
   .\scripts\deploy.ps1 -Character Winger_103142 -GameDir "G:\horizonxi\HorizonXI\Game"
   ```
   ```bash
   scripts/deploy.sh Winger_103142 /mnt/g/horizonxi/HorizonXI/Game
   ```
4. In game: `/lac reload`. Change job and the matching `<JOB>.lua` loads on its own.

Full walkthrough with troubleshooting: [docs/install.md](docs/install.md).

## Adding a character

Make `luashitacast/<Name>_<Id>/`, copy `luashitacast/_template/TEMPLATE.lua` to `<JOB>.lua`, then
dress for each set in game and run `/lac addset <SetName>` to fill it. The template explains the
handler functions and the rules that bite. Commit the folder. Friends: send a pull request or hand
Winger the files.

## Conventions

- Item names match the inventory display name exactly, including abbreviations like `Smn. Torque`.
- Set names are `PascalCase`, variants use an underscore: `TP_Acc`, `TP_Atk`.
- Every alias or bind made in `OnLoad` is deleted in `OnUnload`.
- `settings.lua` is per character and is committed; it holds LuAshitacast's own settings, not gear.
- `backups/` folders are gitignored. LuAshitacast writes one on every addset; git is the history.

## Checking a profile before you deploy it

```bash
python3 .claude/skills/ffxi-gear-lua/scripts/check-profile.py luashitacast/<Name>_<Id>/<JOB>.lua
```

No Lua needed. It reports unbalanced braces, references to sets that do not exist, slots assigned twice,
`''` no-ops, Range/Ammo pairs the server will not allow together (it unequips one, the addon re-equips
it, and the two flicker), and a Range slot that differs between sets (any Range change zeroes TP, same as
Main and Sub). To list what a character owns from a FindAll cache export:

```bash
python3 .claude/skills/ffxi-gear-lua/scripts/parse-findall.py <Name>_<Id>.bin --items items.lua --job BLU --md inventory.md
```

`items.lua` is `resources_data/items.lua` from <https://github.com/Windower/Resources>.

## Related repos

- [horizonxi-luashitacast](../horizonxi-luashitacast/) is Winger's private working copy: raw
  profiles with level snapshots, vendored upstream code, and the LuAshitacast API docs as markdown.
  Profiles graduate from there into this repo once cleaned up and fit to share. The API docs live
  there, not here, so read them there when authoring.
- Community profile sets worth comparing against: [Rag's 75-era profiles](https://github.com/yzyii/luashitacast),
  [GetAwayCoxn](https://github.com/GetAwayCoxn/Luashitacast-Profiles).
- Approved addon list: <https://horizonxi.info/addons>.
