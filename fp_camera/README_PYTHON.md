# IRIDIUM S — First Person Camera (Python installer)

This download has **no `fp_camera.exe`**. Nexus and some antivirus tools often block PyInstaller executables; the patcher runs with **Python 3** instead.

## Requirements

- **Mafia III: Definitive Edition** (Steam), game **closed** during install.
- **IRIDIUM S — Trainer M3** installed (first-person view in the trainer uses this patch on foot).
- **Python 3** from [python.org/downloads](https://www.python.org/downloads/) (not only the Microsoft Store stub).
  - In the installer, enable **“Add python.exe to PATH”**.
  - Open a new Command Prompt and check: `python --version`.

## Install

1. Extract this archive into the game folder (where `Mafia3DefinitiveEdition.exe` is), so you have `IRIDIUM\fp_camera\`.
2. Close the game.
3. Run `IRIDIUM\fp_camera\INSTALL_FP_CAMERA.bat`.
4. If the script asks for **zopfli**, run: `python -m pip install zopfli`, then run the installer again.
5. Start the game. First-person view turns on after load; **F5** switches first/third person; **F4 → Camera** has settings.

## Uninstall

Run `IRIDIUM\fp_camera\UNINSTALL_FP_CAMERA.bat`, or verify game files in Steam.

## Files

- `build_fp_camera.py`, `sdsxml.py`, `fp_rules.json` — patcher (MIT; see `IRIDIUM\LICENSES`).
- `INSTALL_FP_CAMERA.bat` / `UNINSTALL_FP_CAMERA.bat` — backup, patch, restore `sds_retail\tables\tables.sds`.

Only camera values in your copy of `tables.sds` change; the original is kept for rollback.
