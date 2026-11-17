====================================================================
 Buckshot Roulette — Black Shell Mod v1.0
====================================================================

WHAT IT ADDS
  * A third shell type: the BLACK SHELL.
  * Shooting yourself empties your whole health bar at once (instant death).
  * Shooting the dealer empties the dealer's health bar at once (instant win).
  * No artwork is touched: the black shell is drawn by duplicating the retail
    "live" shell material at runtime and darkening it.

SPAWN RULES
  * At most ONE black shell per round.
  * Added only when the round already has >=1 live and >=1 blank shell, so
        P(black) = 0.5/(N+1)  <  P(live) and < P(blank)
  * Never in the first (tutorial) round.
  * Announced in the shell summary: "2 LIVE ROUNDS. 3 BLANKS.  +1 BLACK"

SINGLE-PLAYER ONLY
  Only scripts/*.gd (single-player) are patched. Multiplayer uses a separate
  script set (multiplayer/scripts/...) which is untouched.

--------------------------------------------------------------------
INSTALL (same steps for your friends)
--------------------------------------------------------------------
  1. Close the game completely.
  2. Unzip and double-click install.bat.
     - It auto-detects the game through the Steam registry and
       libraryfolders.vdf (works with any drive / multiple libraries).
     - If detection fails, drag the folder that contains
       "Buckshot Roulette.exe" onto install.bat, or run:
           install.bat "D:\Steam\steamapps\common\Buckshot Roulette\Buckshot Roulette_windows"
  3. Success looks like: "Installed 7 script(s) ... Verified OK."

  Troubleshooting
   - "access denied"    -> right-click install.bat, Run as administrator
   - "game is running"  -> close the game (and its background process)
   - "different game version" -> this mod targets v2.2.0.6 only
   - antivirus warning  -> allow it (the patcher writes into the exe)
   - Files from the internet are blocked by Windows: right-click the .zip,
     Properties, check "Unblock", then unzip.

UNINSTALL
  Double-click uninstall.bat (uses install_backup.json written at install time).
  Steam "Verify integrity of game files" also restores the original game.
  The uninstaller verifies the installed files really are this mod's version
  before restoring, so it can never damage a different build.

RE-INSTALL / GAME UPDATES
  * Running install.bat again is safe ("already installed").
  * A Steam update overwrites the exe - just run install.bat again.
  * If the build number changed, the installer refuses to patch and tells you.

FILES
  install.bat / uninstall.bat   one-click scripts
  patch.ps1                     patcher (built-in Windows PowerShell, no Python)
  mod\scripts\*.gd              7 modified GDScript files
  install_backup.json           created on install, used by the uninstaller

HOW IT WORKS
  Godot 4.1.1 game; all data, including GDScript sources, is inside a PCK
  embedded in the PE section "pck" of Buckshot Roulette.exe. The installer
  parses the PCK file table and replaces 7 scripts: smaller files are
  overwritten in place, larger ones are appended and their table entry
  (offset/size/md5) repointed. Nothing is moved; uninstall restores the
  original table entries.

NOTES
  Modifies the executable; Steam "Verify integrity" reverts it. Single-player
  use; achievements may be affected on some platforms.
====================================================================
