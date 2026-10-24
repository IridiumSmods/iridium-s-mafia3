# Build instructions — IRIDIUM S (Mafia III: Definitive Edition)

This repository is the **full source** for the Nexus mod [IRIDIUM S — Trainer M3 and First Person](https://www.nexusmods.com/mafia3/mods/289).

It matches the optional **First Person Camera** patchers (with and without `fp_camera.exe`) and the **Trainer M3** ASI + Lua.

---

## 1. First Person Camera patcher (quarantined Nexus files)

**What it does:** reads `fp_rules.json`, patches camera values in a copy of `tables.sds`, writes output. **Local files only** — no network, no telemetry.

**Requirements:** Python **3.10+** on Windows. Optional: `zopfli` if a block needs stronger compression.

### Run from source (No-EXE package)

```bat
python fp_camera\build_fp_camera.py fp_camera\fp_rules.json path\to\backup_tables.sds path\to\output.sds
```

Exit codes: `0` OK, `1` error, `3` needs zopfli (`python -m pip install zopfli`, then retry).

### Player install (after extracting the mod into the game folder)

1. Close Mafia III.
2. Run `fp_camera\INSTALL_FP_CAMERA.bat` (uses Python, or `fp_camera.exe` if present next to the script).
3. Uninstall: `fp_camera\UNINSTALL_FP_CAMERA.bat`.

### Reproduce `fp_camera.exe` (EXE optional download)

From a directory that contains `build_fp_camera.py` and `sdsxml.py`:

```bat
python -m pip install pyinstaller zopfli
pyinstaller --onefile --name fp_camera --paths . build_fp_camera.py
```

The executable is a **PyInstaller one-file** bundle of the same script. Antivirus heuristics often flag it; the No-EXE upload uses Python only.

---

## 2. Mafia3ScriptHook.asi (Trainer M3 main file)

**Requirements:** Windows 10/11, **Visual Studio 2022** with **Desktop development with C++** and **Windows 10/11 SDK**, **x64**.

```bat
cd Mafia3ScriptHook
msbuild Mafia3ScriptHook.vcxproj /t:Rebuild /p:Configuration=Release /p:Platform=x64
```

Output: `Mafia3ScriptHook\bin\Release\Mafia3ScriptHook.asi`

Install into the game: `scripts\Mafia3ScriptHook.asi`. The release also ships **Ultimate ASI Loader** as `dinput8.dll` (third party, MIT — not built from this repo).

---

## 3. Trainer Lua

Copy `lua\safe_trainer` and `lua\trainer` into the game:

`ScriptHook\lua\safe_trainer` and `ScriptHook\lua\trainer`

No compile step. Loaded by Mafia3ScriptHook at runtime.

---

## Licenses

- IRIDIUM S additions: MIT — `IRIDIUM_S_MIT.txt`
- Mafia3ScriptHook base: MIT — `Mafia3ScriptHook\LICENSE`
- Third-party libraries: `THIRD_PARTY.md`
