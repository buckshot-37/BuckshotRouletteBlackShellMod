# Buckshot Roulette Black Shell Mod - User Guide

> Version: v1.0 | Game: Buckshot Roulette v2.2.0.6 (Steam, build 16736575)
> Platform: Windows 10 / 11 | Install: double-click `install.bat` (no Python required)

---

## 1. What This Is

This mod adds a brand-new **black shell** to *Buckshot Roulette*:

- **Shoot yourself -> your health bar is emptied instantly, immediate death**
- **Shoot the dealer -> the dealer's health bar is emptied instantly, immediate round win**

Apart from adding this one shell type, the game's textures, sounds, models and animations are **completely untouched** - the black shell is rendered at runtime by duplicating the retail red live-shell material and darkening it. No art asset is added or modified.

---

## 2. Effects at a Glance

| Shot | Result |
|---|---|
| You shoot yourself with a black shell | Health set to 0 -> immediate death sequence |
| You shoot the dealer with a black shell | Dealer health set to 0 -> immediate round win |
| The dealer shoots you with a black shell | Your health set to 0 -> immediate death |
| The dealer shoots himself with a black shell | Dealer health set to 0 -> you win the round immediately |

> Whoever fires and whoever is hit, a black shell always empties the entire health bar on hit. There is no surviving it with high health.

---

## 3. Black Shell Spawn Rules

| Rule | Detail |
|---|---|
| At most 1 per round | The code only ever adds one shell; two can never appear |
| Less likely than red and blue | It is only added when the round already contains **both live and blank shells**. With N live+blank shells in that round: P(black) = 0.5/(N+1), while P(live) >= 1/(N+1) and P(blank) >= 1/(N+1) - so the black shell is **always less likely** than a red or a blue one |
| Never in round 1 | The tutorial (first) round never gets one |
| Announced when present | The opening summary gets `+1 BLACK` appended, e.g. `1 LIVE ROUND. 2 BLANKS.  +1 BLACK` |

---

## 4. Requirements

- Windows 10 / 11 with the built-in PowerShell 5.1 (no Python required)
- A Steam copy of the game, version **v2.2.0.6 (build 16736575)**
  - The installer validates the scripts' MD5s; on a different version it **refuses to install** and leaves the game untouched
- The game must be **completely closed** (including background processes) before installing

---

## 5. Installation

### Option A: one-click (recommended)

1. Unzip the package (zip files downloaded from the internet may be blocked by Windows - see section 8)
2. **Fully exit the game**
3. Double-click `install.bat`
   - It searches your Steam libraries automatically (multiple drives and Steam libraries are supported)
   - Success looks like this:
     ```
     Installed 7 script(s). Executable grew by 47072 bytes. Verified OK.
     ```
4. Launch the game from Steam

### Option B: specify the game folder manually

If auto-detection fails, drag the folder that contains `Buckshot Roulette.exe` onto `install.bat`, or run in a command prompt:

```bat
install.bat "H:\SteamLibrary\steamapps\common\Buckshot Roulette\Buckshot Roulette_windows"
```

### Option C: use PowerShell directly

```powershell
powershell -ExecutionPolicy Bypass -File "patch.ps1" -Action patch -ExePath "<game folder>\Buckshot Roulette.exe"
```

### Confirming success

- `install_backup.json` is created next to the installer (needed by the uninstaller)
- Running `install.bat` again prints `Mod is already installed - nothing to do.` - this is normal and nothing is rewritten

---

## 6. Uninstall / Restore

### Option A: double-click `uninstall.bat`

- Requires `install_backup.json` (created at install time; do not delete it)
- It first verifies that the files really are this mod's version; if not, it **refuses to run** and changes nothing
- `Restored 7 PCK entr(ies).` means it is back to the original scripts

### Option B: Steam "Verify integrity of game files"

Steam -> Library -> right-click the game -> Properties -> Installed Files -> **Verify integrity of game files**.
This restores the official executable and is equivalent to uninstalling.

> After uninstalling, the exe remains a few tens of KB larger (the appended data stays at the end of the file but is no longer referenced). This **does not affect the game**; use Option B for a byte-perfect restore.

---

## 7. Playing

1. Play normally and reach round 2 or later (round 1 never has a black shell)
2. Look at the shell tray while the shells are loaded: **a black shell** (red = live, blue = blank, black = black shell)
3. The opening summary shows `+1 BLACK`
4. On your turn:
   - **Take the shotgun -> aim at yourself -> fire**: if it is the black shell, you die immediately
   - **Take the shotgun -> aim at the dealer -> fire**: if it is the black shell, the dealer dies immediately and you win the round
5. How items interact with a black shell:
   - Magnifying glass: shows a black shell
   - Beer: ejects it normally (the ejected shell is black)
   - Inverter: **does not flip a black shell** (only red/blue shells are flipped)
   - Burner phone: reports it as a LIVE round (it is just as lethal)

> Tip: the dealer AI also treats a black shell as lethal, so on rounds that contain one it is more likely to shoot you - don't gamble.

---

## 8. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Cannot write to the game executable - it is most likely still running` | The game or one of its processes is still alive | Close the game completely (check Task Manager), then run again |
| `access denied` | The game is installed in a protected folder | Right-click `install.bat` -> **Run as administrator** |
| `These game scripts are from a different game version` | The game is not v2.2.0.6 | Update the game, or wait for a mod build for your version; the installer never damages the game |
| `Could not locate the game automatically` | The game folder was not found | Drag the game folder onto `install.bat`, or pass the path as in Option B |
| `Mod is already installed - nothing to do.` | It is already installed | Nothing to do; just start the game |
| Uninstall reports `The game files do not match this installation record` | The game was updated/reinstalled, so the record is stale | Restore with Steam "Verify integrity of game files" |
| Double-click does nothing / blocked | The file was marked as downloaded from the internet, or antivirus blocked it | Right-click the zip -> Properties -> check **Unblock** -> unzip again; allow it in your antivirus |
| No change in game | (1) install did not succeed (2) a game update overwrote the exe (3) a different Steam library is being launched | Check that `install_backup.json` exists; run `install.bat` again; confirm the Steam library path |
| Black shell never appears | It never spawns in round 1, and only rounds that contain both red and blue shells have a 50% chance | Play a few more rounds - this is normal |

---

## 9. Compatibility & Notes

- **Single-player only**: only the 7 single-player scripts are replaced. Multiplayer uses a separate script set (`multiplayer/scripts/`) which is completely untouched, so black shells never appear online.
- **Game updates break it**: a Steam update overwrites the exe. Just run `install.bat` again; if the version number changed you will need a mod build for that version.
- **Achievements**: the mod changes script logic, so some achievement checks may be affected (rounds containing a black shell skip the "equal live and blank shells" achievement).
- **Conflicts with other mods**: mods that modify the same scripts overwrite each other - the one installed last wins.
- **Use at your own risk**: this is a single-player mod that modifies game files. The game has no VAC anti-cheat, but please decide for yourself whether to use it.

---

## 10. Files

| File | Purpose |
|---|---|
| `install.bat` | One-click installer (auto-detects the game / accepts a dragged folder) |
| `uninstall.bat` | One-click uninstaller (verifies before restoring) |
| `patch.ps1` | The patcher itself (PowerShell, no Python needed) |
| `mod\scripts\*.gd` | The 7 modified scripts |
| `install_backup.json` | Created on install, used by the uninstaller; if deleted you can still use Steam's verify |
| `README_CN.txt` / `README_EN.txt` | Chinese / English readme |
| `VERIFY_REPORT.txt` | Build and verification report |
| `使用指南.txt` / `使用指南.md` | Chinese version of this guide (same content) |

The 7 modified scripts:

1. `ShellSpawner.gd` - decides whether this round gets one black shell, spawns the shells, builds the summary text
2. `ShellBranch.gd` - black appearance in the compartment tray
3. `ShellEjectManager.gd` - black appearance when ejecting
4. `ShellExamine.gd` - black appearance under the magnifying glass
5. `ShotgunShooting.gd` - player firing: black shell hits self/dealer -> health to 0
6. `DealerIntelligence.gd` - same handling for the dealer + AI knowledge
7. `ItemInteraction.gd` - the inverter never flips a black shell

---

## 11. Sharing with Friends

Send them the whole folder (or the zip) and let them follow section 5. They need:

1. The same game version (v2.2.0.6 / build 16736575)
2. Windows 10 / 11
3. The game closed before installing
4. To "Unblock" the zip if Windows marks it as downloaded
5. Administrator rights if the game is installed under `Program Files`

---

## 12. How It Works

*Buckshot Roulette* is built with Godot 4.1.1. All of its data - including the plain-text GDScript sources - is packed into a PCK embedded in `Buckshot Roulette.exe` (PE section named `pck`).

The installer parses the PCK file table and replaces those 7 scripts:

- if the new script is smaller than the original slot -> it is overwritten in place
- if the new script is larger -> it is appended to the end of the exe, and that file's offset / size / md5 in the table are rewritten

Not a single byte of existing data is moved; uninstalling simply restores the original table entries.

---

*Have fun - and remember: **a black shell kills you too**.*
