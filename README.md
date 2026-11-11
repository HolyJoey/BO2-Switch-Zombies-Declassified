# Zombies Declassified (DLC5) – Nintendo Switch (BO2 Requiem NX) fix

Fixes for **Zombies Declassified 2.0.5** (the DLC5 port by **Logo2K**, with **Fr0sty**'s BETA 2 patches) so it runs properly on Black Ops II on the Nintendo Switch through **Requiem NX**.
All credit for Zombies Declassified goes to Logo2K, Fr0sty and everyone in their credits. This repo only contains what was changed to make it work on the Switch.

Tested on Requiem NX 0.3.1.

## Which download do I need?

**Do you already have the latest DLC5 from the Requiem Discord (Zombies Declassified 2.0.5, the "Nov 3 version") on your Switch?**

- **Yes** → you only need the **hotfix** (15 MB). Install it, then delete **one file**: `switch/t6game/mods/dlc5/mods.iwd`. See [Install: hotfix](#install-hotfix-upgrade-from-the-discord-version).
- **No**, you have no DLC5, or an older version → download the **full fixed DLC5**. It already contains the hotfix and leaves out that one file. See [Install: full version](#install-full-version).

Not sure which version you have? Open `switch/t6game/mods/dlc5/mod.json` on your SD card. 2.0.5 says `"version": "2.0.5"` and `"author": "Logo2K, Fr0sty"`. Anything else: take the full version.

| Download | For who | Where |
|---|---|---|
| **Full DLC5, fixed** | No DLC5 yet, or an older version | [Requiem_DLC5_fixed.zip on Gofile](https://gofile.io/d/xdoDXE5b) (8.9 GB) |
| **DLC5 hotfix** (`DLC5_Hotfix_Switch.zip`) | DLC5 2.0.5 from the Requiem Discord already installed | [Releases](../../releases) |

## What is fixed

| Problem on Switch | Fix |
|---|---|
| Game closes when you open **Kino**'s map screen (UI Error 80076) | Extra start locations are only added when the menu has a position for them. |
| Game closes when you **open the scoreboard, die or end the game** | `Engine.GetCustomTeamName()` returns `nil` on Requiem; added a `nil` check. |
| **Checkerboard** on the DLC5 loading screens | Loading screens use their own images in `t6game/images/`, so the artwork shows right away. |
| **Raw map name** on the loading screen (`zm_cosmodrome`) | Replaced with DLC5's own names ("ASCENSION GROUP FACILITY"). |
| **Raw lobby options** (`MENU_MINPLAYERS_CAPS` …) | Now MIN PLAYERS, CHEATS and PERMA PERKS. |
| Moon's **No Man's Land** start can't be selected | Selectable again, with its own map art and loading screen. |
| Kino's **stage** start (Grief / Turned) can't be selected | Selectable again. |
| Old map art and a blocky lobby background | The new 2.0.5 map-screen art for Kino, Moon, Five, Ascension and Shangri-La. |
| DLC5 maps load slowly | ~20 seconds faster per map without `mods/dlc5/mods.iwd` (see below). |

**Why:** in the menu, Requiem only loads a mod's `mod_load.ff`. `mod.ff` and `mod_patch.ff` load when a map starts. DLC5 2.0.5 put its new menu content (game-mode table, map art, lobby texts) in `mod_patch.ff`, so the menu never saw it.

### Compared to Logo2K's and Fr0sty's 2.0.5

3 patched DLC5 Lua files and 30 images. The images are copies of DLC5's own art, not new art.

- **`mainlobby.lua`**: no crash on missing start spots; feeds the menu the missing Moon/Kino rows; points to the new map art.
- **`scoreboard.lua`**: fixes the `nil` team-name crash; loading screens show their art and map names right away.
- **`privategamelobby_project.lua`**: readable lobby option names.
- **`images/`**: the art those fixes use.

### Compared to the "Nov 3 version" on the Requiem Discord

The DLC5 currently shared on the Requiem Discord (the **Nov 3 version**) already contains an earlier version of my fixes. This version adds:

- **New map art for Five, Ascension and Shangri-La** too (the Nov 3 version only had it for Moon and Kino), so the lobby background is sharp on those maps as well. That's 9 more images (21 → 30).
- **~20 seconds faster loading per DLC5 map** by deleting `mods/dlc5/mods.iwd` (see the install steps).
- Temporary debug code removed from `mainlobby.lua`, and the Lua files use DLC5's own line endings again.

To update the Nov 3 version, install the hotfix (see below) and delete `mods.iwd`.

## Install: full version

For anyone without DLC5, or with a version older than 2.0.5. If you have an older DLC5, delete `switch/t6game/mods/dlc5/` first: unzipping over it doesn't remove old files.

1. Download [`Requiem_DLC5_fixed.zip`](https://gofile.io/d/xdoDXE5b) (8.9 GB) and unzip it. If the link is dead, open an [issue](../../issues).
2. Copy everything into `switch/t6game/` on your SD card.
3. Start BO2 (Requiem NX), open **Mods** and pick **Zombies Declassified**.

## Install: hotfix (upgrade from the Discord version)

Only for **Zombies Declassified 2.0.5**: the Nov 3 version from the Requiem Discord, or Logo2K's and Fr0sty's plain 2.0.5.

1. Download `DLC5_Hotfix_Switch.zip` from [Releases](../../releases) and unzip it.
2. Copy the `switch` folder to the **root of your SD card** and let it replace the existing files. This replaces 3 menu scripts in `switch/t6game/mods/dlc5/` and adds 30 images to `switch/t6game/images/`.
3. **Delete one file:** `switch/t6game/mods/dlc5/mods.iwd`. A zip can't delete files, so you have to do this by hand.
   Requiem never loads the scripts inside it, but any `.iwd` in the mod folder switches off Requiem's fast image lookup, so every DLC5 map loads about **20 seconds slower** (Five: images 43 s → 20 s). The game sounds and plays the same without it. The full version above already leaves it out.

## Files in this repo

| File | What |
|---|---|
| `t6game/mods/dlc5/ui/t6/mainlobby.lua` | Kino crash, No Man's Land, Kino stage, new map art |
| `t6game/mods/dlc5/ui_mp/t6/hud/scoreboard.lua` | Scoreboard / death / End Game crash, loading screens, map names |
| `t6game/mods/dlc5/ui_mp/t6/menus/privategamelobby_project.lua` | Lobby option names |
| `t6game/images/loadscreen_dlc5_*.iwi`, `menu_dlc5_*.iwi` | Loading screens and map art the fixed scripts point to |

Every change in the Lua files is marked with `[local fix]`.

**Going back:** reinstall DLC5 2.0.5's original 3 Lua files and delete `images/loadscreen_dlc5_*` and `images/menu_dlc5_*`.

## Credits

- **Zombies Declassified** by **Logo2K**: https://github.com/Logo-2K/zombies-declassified (GPL v3)
- **BETA 2 patches** by **Fr0sty**: https://github.com/Fr0styProductions/Zombies-Declassified-Patches (MIT, see `licenses/Fr0sty-patches-MIT.txt`). Fr0sty asks for credit in videos made with the patches: "@fr0sty_7952 on Youtube, @fr0s_ty_ on Discord".
- Everyone in [Logo2K's credits](https://github.com/Logo-2K/zombies-declassified/blob/main/CREDITS.md): Kevin Sherwood (music), Plutonium, OpenAssetTools (Laupetin and contributors), GabsPuNs (BO2 X360 Patches), NickB_05 (menu art), Ronan (shader/icon art).
- **BO2 Requiem NX** by HDErick: https://github.com/HDErick/BO2-Requiem-NX
- Call of Duty: Black Ops II and all game assets: Treyarch / Activision. Fan project, not affiliated with or endorsed by Activision.

## License

The scripts in this repo are based on Zombies Declassified and are released under the **GNU GPL v3**, the same as the original (see `LICENSE`).
