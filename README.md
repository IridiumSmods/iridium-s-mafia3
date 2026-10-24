# IRIDIUM S — Mafia III: Definitive Edition

In-game trainer (F4) and first-person camera for **Mafia III: Definitive Edition**, built on [Mafia3ScriptHook](https://github.com/Kamzik123/Mafia3ScriptHook) by Kamzik123.

**Nexus mod page:** https://www.nexusmods.com/mafia3/mods/289

## Repository layout

| Path | Contents |
|------|----------|
| `fp_camera/` | Table patcher for game-native first person (`build_fp_camera.py`, `sdsxml.py`, `fp_rules.json`, install scripts) |
| `Mafia3ScriptHook/` | C++ ASI (menu overlay, Lua loader, input bridge) |
| `lua/` | Trainer scripts (`safe_trainer`, `trainer`) |
| `BUILD.md` | **Build steps for Nexus / security review** |

## Quick start (developers)

See **[BUILD.md](BUILD.md)** for:

- Running or building the camera patcher (including `fp_camera.exe` via PyInstaller)
- Building `Mafia3ScriptHook.asi` with Visual Studio 2022

Player-facing install and features: use the README bundled with the Nexus downloads.

## Contact

Author: **IRIDIUM S** (Nexus: **IridiumSmods**)
