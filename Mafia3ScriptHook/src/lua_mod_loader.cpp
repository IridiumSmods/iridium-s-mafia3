#include "lua_mod_loader.h"
#include "menu_system.h"
#include "logger.h"
#include "settings.h"
#include "gui.h"
#include "hooks.h"
#include "scanner.h"
#include <Windows.h>
#include <string>
#include <vector>
#include <algorithm>

// Current mod directory for include() path resolution
static std::string g_currentModDir;
static lua_State* g_luaState = nullptr;
static std::vector<std::string> g_loadedMods;

// Read error message from the Lua stack top after a failed pcall/loadfile
static const char* GetStackError(lua_State* L) {
    uintptr_t Laddr = (uintptr_t)L;
    uintptr_t top = *(uintptr_t*)(Laddr + 72);   // stack top
    uintptr_t base = *(uintptr_t*)(Laddr + 80);   // stack base
    if (top <= base) return "(empty stack)";

    // The error object is at top - 16 (last pushed HksObject, 16 bytes each)
    void* errObj = (void*)(top - 16);
    size_t len = 0;
    const char* msg = g_hks.obj_tolstring(L, errObj, &len);
    return msg ? msg : "(non-string error)";
}

// HavokScript type tags
constexpr int HKS_TNIL = 0;
constexpr int HKS_TBOOLEAN = 2;
constexpr int HKS_TNUMBER = 3;
constexpr int HKS_TSTRING = 4;

// Build a string from Lua stack args
static std::string BuildPrintString(lua_State* L) {
    uintptr_t Laddr = (uintptr_t)L;
    uintptr_t top = *(uintptr_t*)(Laddr + 72);
    uintptr_t base = *(uintptr_t*)(Laddr + 80);
    int nargs = (int)((top - base) / 16);

    if (nargs == 0) return "";

    if (nargs == 1) {
        size_t len = 0;
        const char* s = g_hks.luaL_checklstring(L, 1, &len);
        return s ? std::string(s, len) : "nil";
    }

    std::string line;
    for (int i = 0; i < nargs; i++) {
        if (i > 0) line += "\t";
        uintptr_t obj = base + i * 16;
        int typeTag = *(int*)obj & 0xF;
        switch (typeTag) {
        case HKS_TSTRING: {
            size_t slen = 0;
            const char* s = g_hks.luaL_checklstring(L, i + 1, &slen);
            line.append(s ? s : "nil", s ? slen : 3);
            break;
        }
        case HKS_TNUMBER: {
            float val = *(float*)(obj + 8);
            if (val == (float)(int)val)
                line += std::to_string((int)val);
            else
                line += std::to_string(val);
            break;
        }
        case HKS_TBOOLEAN:
            line += *(float*)(obj + 8) != 0.0f ? "true" : "false";
            break;
        case HKS_TNIL:
            line += "nil";
            break;
        default:
            line += "<type:" + std::to_string(typeTag) + ">";
            break;
        }
    }
    return line;
}

// print() — outputs to in-game console always, external console only in verbose mode
static int __fastcall LuaPrint(lua_State* L) {
    std::string msg = BuildPrintString(L);
    Gui::AddToConsole("[Lua] %s", msg.c_str());
    Logger::Verbose("[Lua] %s", msg.c_str());
    return 0;
}

// _scripthook_log() — single string arg, used internally by Lua code
static int __fastcall LuaLogRaw(lua_State* L) {
    size_t len = 0;
    const char* s = g_hks.luaL_checklstring(L, 1, &len);
    const char* msg = (s && len > 0) ? s : "";
    Gui::AddToConsole("[Lua] %s", msg);
    Logger::Verbose("[Lua] %s", msg);
    return 0;
}

static int __fastcall LuaInclude(lua_State* L) {
    size_t len = 0;
    const char* relPath = g_hks.luaL_checklstring(L, 1, &len);
    if (!relPath || len == 0) {
        Logger::Log("  include(): missing or invalid string argument");
        return 0;
    }

    // Build absolute path: currentModDir + relPath
    std::string fullPath = g_currentModDir + "\\" + std::string(relPath, len);
    for (auto& c : fullPath) {
        if (c == '/') c = '\\';
    }

    Logger::Verbose("  include(\"%s\")", fullPath.c_str());

    int loadResult = g_hks.luaL_loadfile(L, fullPath.c_str());
    if (loadResult != 0) {
        Logger::Log("  include() LOAD ERROR (code %d): %s", loadResult, GetStackError(L));
        Gui::AddToConsole("include() LOAD ERROR: %s", fullPath.c_str());
        return 0;
    }

    int callResult = g_hks.lua_pcall(L, 0, 0, 0);
    if (callResult != 0) {
        Logger::Log("  include() EXEC ERROR (code %d): %s", callResult, GetStackError(L));
        Gui::AddToConsole("include() EXEC ERROR: %s", fullPath.c_str());
        return 0;
    }

    return 0;
}

// Traffic density: the game keeps three multipliers on the traffic manager
// (+0x78 settings, +0x7C script, +0x80 extra). The effective value is their
// minimum, pushed to every generator by the manager's recompute function.
namespace TrafficDensity {
    constexpr const char* ObjPattern =
        "45 33 C0 33 D2 48 8B D9 E8 ?? ?? ?? ?? 48 8D 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 48 8B 43 48 F3 0F 11 40 08 C7 00 03 00 00 00";
    constexpr const char* SetterPattern =
        "F3 0F 11 49 78 E9 ?? ?? ?? ?? CC CC CC CC CC CC F3 0F 11 49 7C E9";
    constexpr float MaxValue = 3.0f;

    typedef void(__fastcall* Recompute_fn)(void* manager);

    static uintptr_t g_manager = 0;
    static Recompute_fn g_recompute = nullptr;
    static bool g_tried = false;

    static bool Resolve() {
        if (g_tried) return g_manager && g_recompute;
        g_tried = true;

        uintptr_t obj = Scanner::Find(ObjPattern);
        uintptr_t set = Scanner::Find(SetterPattern);
        if (!obj || !set) {
            Logger::Log("TrafficDensity: pattern not found (obj=%p set=%p)", (void*)obj, (void*)set);
            return false;
        }
        g_manager = obj + 20 + *(int32_t*)(obj + 16);
        g_recompute = (Recompute_fn)(set + 10 + *(int32_t*)(set + 6));
        Logger::Log("TrafficDensity: manager=%p recompute=%p", (void*)g_manager, (void*)g_recompute);
        return true;
    }

    static bool Apply(float value, float* effective) {
        __try {
            *(float*)(g_manager + 0x78) = value;
            *(float*)(g_manager + 0x7C) = value;
            *(float*)(g_manager + 0x80) = value;
            g_recompute((void*)g_manager);
            *effective = *(float*)(g_manager + 0x84);
            return true;
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            return false;
        }
    }
}

// Vehicle element limits, set through the same setter as the game's
// traffic:SetMaxVehicleElements. Density alone cannot exceed them.
// Human limits are never touched: tripling them overflowed the human pool.
namespace TrafficLimits {
    constexpr const char* SetterPattern =
        "48 83 EC 28 8B 44 24 58 44 8B 54 24 50 39 91 C8 00 00 00";
    constexpr const char* SingletonPattern =
        "88 51 50 0F 57 C0 48 8B 05 ?? ?? ?? ?? F3 0F 10 90 A8 00 00 00";
    constexpr float MaxScale = 1.5f;

    typedef void(__fastcall* SetVehicles_fn)(void* regulation, int movingCars, int parkedCars,
        int translocatedCars, int translocatedBoats, int movingBoats);

    // Field order matches the setter arguments.
    static const int Offsets[5] = { 0xC8, 0xC4, 0xBC, 0xC0, 0xD8 };

    static uintptr_t* g_singleton = nullptr;
    static SetVehicles_fn g_set = nullptr;
    static bool g_tried = false;
    static int g_base[5] = {};
    static int g_written[5] = { -1, -1, -1, -1, -1 };

    static bool Resolve() {
        if (g_tried) return g_singleton && g_set;
        g_tried = true;

        uintptr_t set = Scanner::Find(SetterPattern);
        uintptr_t sng = Scanner::Find(SingletonPattern);
        if (!set || !sng) {
            Logger::Log("TrafficLimits: pattern not found (set=%p singleton=%p)", (void*)set, (void*)sng);
            return false;
        }
        g_set = (SetVehicles_fn)set;
        g_singleton = (uintptr_t*)(sng + 13 + *(int32_t*)(sng + 9));
        Logger::Log("TrafficLimits: setter=%p singleton=%p", (void*)g_set, (void*)g_singleton);
        return true;
    }

    static bool Apply(float scale, int* movingOut) {
        __try {
            uintptr_t reg = *g_singleton;
            if (!reg) return false;
            int now[5];
            bool ours = true;
            for (int i = 0; i < 5; i++) {
                now[i] = *(int*)(reg + Offsets[i]);
                if (now[i] != g_written[i]) ours = false;
            }
            // A mission or tuning profile changed the limits since our last write: adopt them as base.
            if (!ours) {
                for (int i = 0; i < 5; i++) {
                    if (now[i] < 0 || now[i] > 2000) {
                        Logger::Log("TrafficLimits: limits look wrong (%d/%d/%d/%d/%d), left alone",
                            now[0], now[1], now[2], now[3], now[4]);
                        return false;
                    }
                    g_base[i] = now[i];
                }
            }
            int want[5];
            for (int i = 0; i < 5; i++) want[i] = g_base[i];
            want[0] = (int)((float)g_base[0] * scale + 0.5f);
            want[2] = (int)((float)g_base[2] * scale + 0.5f);
            g_set((void*)reg, want[0], want[1], want[2], want[3], want[4]);
            for (int i = 0; i < 5; i++) g_written[i] = *(int*)(reg + Offsets[i]);
            *movingOut = g_written[0];
            Logger::Log("TrafficLimits: moving cars %d -> %d, translocated %d -> %d",
                g_base[0], g_written[0], g_base[2], g_written[2]);
            return true;
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            return false;
        }
    }
}

static void PushNumber(lua_State* L, float value) {
    uintptr_t Laddr = (uintptr_t)L;
    uintptr_t top = *(uintptr_t*)(Laddr + 72);
    uintptr_t limit = *(uintptr_t*)(Laddr + 88);
    if (top + 16 > limit) return;
    *(int*)top = 3;
    *(float*)(top + 8) = value;
    *(uintptr_t*)(Laddr + 72) = top + 16;
}

// SetTrafficLimits(scale) — 1.0 restores the base vehicle limits, capped at 1.5.
// Returns the moving car limit now in effect, or nothing on failure.
static int __fastcall LuaSetTrafficLimits(lua_State* L) {
    uintptr_t Laddr = (uintptr_t)L;
    uintptr_t top = *(uintptr_t*)(Laddr + 72);
    uintptr_t base = *(uintptr_t*)(Laddr + 80);
    if (top <= base || (*(int*)base & 0xF) != 3) return 0;

    float scale = *(float*)(base + 8);
    if (scale < 1.0f) scale = 1.0f;
    if (scale > TrafficLimits::MaxScale) scale = TrafficLimits::MaxScale;
    if (!TrafficLimits::Resolve()) return 0;

    int moving = 0;
    if (!TrafficLimits::Apply(scale, &moving)) {
        Logger::Log("SetTrafficLimits(%.2f) failed", scale);
        return 0;
    }
    PushNumber(L, (float)moving);
    return 1;
}

// Notify(text) — short message shown under the trainer menu.
static int __fastcall LuaNotify(lua_State* L) {
    size_t len = 0;
    const char* s = g_hks.luaL_checklstring(L, 1, &len);
    if (s && len > 0) {
        std::string msg(s, len);
        MenuSystem::PushToast(msg);
        Gui::AddToConsole("[Lua] %s", msg.c_str());
        Logger::Verbose("[Lua] %s", msg.c_str());
    }
    return 0;
}

// SetTrafficDensity(x) — 1.0 is the game default. Returns the effective multiplier or nothing on failure.
static int __fastcall LuaSetTrafficDensity(lua_State* L) {
    uintptr_t Laddr = (uintptr_t)L;
    uintptr_t top = *(uintptr_t*)(Laddr + 72);
    uintptr_t base = *(uintptr_t*)(Laddr + 80);
    if (top <= base || (*(int*)base & 0xF) != HKS_TNUMBER) {
        Gui::AddToConsole("SetTrafficDensity: number expected");
        return 0;
    }

    float value = *(float*)(base + 8);
    if (value < 0.0f) value = 0.0f;
    if (value > TrafficDensity::MaxValue) value = TrafficDensity::MaxValue;

    if (!TrafficDensity::Resolve()) {
        Gui::AddToConsole("SetTrafficDensity: traffic manager not found in this game build");
        return 0;
    }

    float effective = 0.0f;
    if (!TrafficDensity::Apply(value, &effective)) {
        Logger::Log("SetTrafficDensity: access violation, disabled");
        TrafficDensity::g_manager = 0;
        return 0;
    }
    Logger::Log("SetTrafficDensity(%.2f) -> %.2f", value, effective);

    uintptr_t limit = *(uintptr_t*)(Laddr + 88);
    if (top + 16 > limit) return 0;
    *(int*)top = HKS_TNUMBER;
    *(float*)(top + 8) = effective;
    *(uintptr_t*)(Laddr + 72) = top + 16;
    return 1;
}

static void RegisterGlobals(lua_State* L) {
    g_hks.hks_pushcclosure(L, LuaSetTrafficDensity, 0, "SetTrafficDensity", 1, 0);
    g_hks.lua_setfield(L, HKS_GLOBALSINDEX, "SetTrafficDensity");

    g_hks.hks_pushcclosure(L, LuaSetTrafficLimits, 0, "SetTrafficLimits", 1, 0);
    g_hks.lua_setfield(L, HKS_GLOBALSINDEX, "SetTrafficLimits");

    g_hks.hks_pushcclosure(L, LuaNotify, 0, "Notify", 1, 0);
    g_hks.lua_setfield(L, HKS_GLOBALSINDEX, "Notify");

    g_hks.hks_pushcclosure(L, LuaInclude, 0, "include", 1, 0);
    g_hks.lua_setfield(L, HKS_GLOBALSINDEX, "include");

    g_hks.hks_pushcclosure(L, LuaLogRaw, 0, "_scripthook_log", 1, 0);
    g_hks.lua_setfield(L, HKS_GLOBALSINDEX, "_scripthook_log");

    // Register print as a C function — works from any context including Present hook
    g_hks.hks_pushcclosure(L, LuaPrint, 0, "print", 1, 0);
    g_hks.lua_setfield(L, HKS_GLOBALSINDEX, "print");
}

// Scan ScriptHook/lua/ for mod directories containing main.lua
static std::vector<std::string> DiscoverMods(const std::string& modsDir) {
    std::vector<std::string> mods;

    WIN32_FIND_DATAA findData;
    std::string searchPath = modsDir + "*";
    HANDLE hFind = FindFirstFileA(searchPath.c_str(), &findData);
    if (hFind == INVALID_HANDLE_VALUE) return mods;

    do {
        if (!(findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) continue;
        if (findData.cFileName[0] == '.') continue;

        std::string modName = findData.cFileName;
        std::string mainLua = modsDir + modName + "\\main.lua";

        if (GetFileAttributesA(mainLua.c_str()) != INVALID_FILE_ATTRIBUTES) {
            mods.push_back(modName);
        }
    } while (FindNextFileA(hFind, &findData));

    FindClose(hFind);
    std::sort(mods.begin(), mods.end());
    return mods;
}

static bool RunLuaChunk(lua_State* L, const char* code, const char* chunkName) {
    if (g_hks.luaL_loadbuffer(L, code, strlen(code), chunkName) != 0) {
        Logger::Log("  %s load error: %s", chunkName, GetStackError(L));
        return false;
    }
    if (g_hks.lua_pcall(L, 0, 0, 0) != 0) {
        Logger::Log("  %s error: %s", chunkName, GetStackError(L));
        return false;
    }
    return true;
}

static void PreReloadShutdown(lua_State* L) {
    static const char* code = R"(
if type(FpsLikeDisable) == "function" then pcall(FpsLikeDisable) end
if SafeTrainerPreReload then pcall(SafeTrainerPreReload) end
if type(OnReload) == "function" then pcall(OnReload) end
)";
    RunLuaChunk(L, code, "pre_reload_shutdown");
}

static void CallModEvent(lua_State* L, const char* funcName) {
    // Safely call a global function if it exists: if FuncName then FuncName() end
    char code[128];
    snprintf(code, sizeof(code), "if %s then %s() end", funcName, funcName);
    if (g_hks.luaL_loadbuffer(L, code, strlen(code), funcName) == 0) {
        if (g_hks.lua_pcall(L, 0, 0, 0) != 0) {
            Logger::Log("  %s() error: %s", funcName, GetStackError(L));
        }
    }
}

static bool LoadSingleMod(lua_State* L, const std::string& modsDir, const std::string& modName, bool isReload) {
    std::string modDir = modsDir + modName;
    std::string mainLua = modDir + "\\main.lua";

    Logger::Log("%s mod: %s", isReload ? "Reloading" : "Loading", modName.c_str());
    g_currentModDir = modDir;

    int loadResult = g_hks.luaL_loadfile(L, mainLua.c_str());
    if (loadResult != 0) {
        Logger::Log("  LOAD ERROR (code %d): %s", loadResult, GetStackError(L));
        Gui::AddToConsole("LOAD ERROR [%s]: %s", modName.c_str(), GetStackError(L));
        return false;
    }

    int callResult = g_hks.lua_pcall(L, 0, 0, 0);
    if (callResult != 0) {
        Logger::Log("  EXEC ERROR (code %d): %s", callResult, GetStackError(L));
        Gui::AddToConsole("EXEC ERROR [%s]: %s", modName.c_str(), GetStackError(L));
        return false;
    }

    CallModEvent(L, isReload ? "OnReload" : "OnLoad");

    Logger::Log("  OK");
    return true;
}

void ModLoader::OnLuaStateReady(lua_State* L) {
    g_luaState = L;
    g_loadedMods.clear();

    std::string modsDir = Logger::GetGameDir() + "ScriptHook\\lua\\";
    CreateDirectoryA((Logger::GetGameDir() + "ScriptHook").c_str(), NULL);
    CreateDirectoryA(modsDir.c_str(), NULL);

    auto mods = DiscoverMods(modsDir);
    if (mods.empty()) {
        Logger::Log("No mods found in %s", modsDir.c_str());
        return;
    }

    Logger::Log("Found %zu mod(s), loading...", mods.size());
    RegisterGlobals(L);
    MenuSystem::Init(L);

    int loaded = 0;
    for (const auto& modName : mods) {
        if (LoadSingleMod(L, modsDir, modName, false)) {
            g_loadedMods.push_back(modName);
            loaded++;
        }
    }

    MenuSystem::Finalize(L);
    Logger::Log("Loaded %d/%zu mod(s) successfully.", loaded, mods.size());
}

void ModLoader::Tick() {
    if (!g_luaState) return;

    static const char* code = "if OnTick then OnTick() end";
    if (g_hks.luaL_loadbuffer(g_luaState, code, strlen(code), "tick") == 0) {
        g_hks.lua_pcall(g_luaState, 0, 0, 0);
    }
}

void ModLoader::ReloadAll() {
    if (!g_luaState) {
        Logger::Log("ReloadAll: No lua_State available");
        return;
    }

    if (!Hooks::IsGameThread()) {
        Logger::Log("ReloadAll: wrong thread — use RequestReloadAll()");
        return;
    }

    Logger::Log("=== Reloading all mods ===");
    MenuSystem::PrepareForReload();
    PreReloadShutdown(g_luaState);

    g_loadedMods.clear();

    // Clean up old Lua state before reloading
    const char* cleanup = R"(
        _SH_callbacks = {}
        _SH_nextCbId = 1
        TrainerMenuItems = {}
        collectgarbage("collect")
        collectgarbage("collect")
    )";
    if (g_hks.luaL_loadbuffer(g_luaState, cleanup, strlen(cleanup), "reload_cleanup") == 0)
        g_hks.lua_pcall(g_luaState, 0, 0, 0);

    std::string modsDir = Logger::GetGameDir() + "ScriptHook\\lua\\";
    auto mods = DiscoverMods(modsDir);

    RegisterGlobals(g_luaState);
    MenuSystem::Init(g_luaState);

    int loaded = 0;
    for (const auto& modName : mods) {
        if (LoadSingleMod(g_luaState, modsDir, modName, true)) {
            g_loadedMods.push_back(modName);
            loaded++;
        }
    }

    MenuSystem::Finalize(g_luaState);
    Logger::Log("Reloaded %d/%zu mod(s) successfully.", loaded, mods.size());
    Gui::AddToConsole("Reloadall done (%d/%zu mods).", loaded, (int)mods.size());
}

void ModLoader::RequestReloadAll() {
    Hooks::QueueLuaCall([]() { ModLoader::ReloadAll(); });
}

void ModLoader::ReloadMod(const std::string& modName) {
    if (!g_luaState) {
        Logger::Log("ReloadMod: No lua_State available");
        return;
    }

    if (!Hooks::IsGameThread()) {
        Logger::Log("ReloadMod: wrong thread — use RequestReloadMod()");
        return;
    }

    MenuSystem::PrepareForReload();
    PreReloadShutdown(g_luaState);

    std::string modsDir = Logger::GetGameDir() + "ScriptHook\\lua\\";
    std::string mainLua = modsDir + modName + "\\main.lua";

    if (GetFileAttributesA(mainLua.c_str()) == INVALID_FILE_ATTRIBUTES) {
        Logger::Log("ReloadMod: Mod '%s' not found", modName.c_str());
        return;
    }

    Logger::Log("=== Reloading mod: %s ===", modName.c_str());

    // Run a GC cycle before reloading to clean up stale references
    const char* gc = "collectgarbage('collect') collectgarbage('collect')";
    if (g_hks.luaL_loadbuffer(g_luaState, gc, strlen(gc), "gc") == 0)
        g_hks.lua_pcall(g_luaState, 0, 0, 0);

    LoadSingleMod(g_luaState, modsDir, modName, true);
}

void ModLoader::RequestReloadMod(const std::string& modName) {
    std::string name = modName;
    Hooks::QueueLuaCall([name]() { ModLoader::ReloadMod(name); });
}

void ModLoader::PollReloadRequest() {
    static ULONGLONG lastCheck = 0;
    ULONGLONG now = GetTickCount64();
    if (now - lastCheck < 200)
        return;
    lastCheck = now;

    std::string path = Logger::GetGameDir() + "ScriptHook\\reloadall.request";
    if (GetFileAttributesA(path.c_str()) == INVALID_FILE_ATTRIBUTES)
        return;

    DeleteFileA(path.c_str());
    Logger::Log("reloadall.request — reloading all mods");
    Gui::AddToConsole("> reloadall (request file)");
    RequestReloadAll();
}

std::vector<std::string> ModLoader::GetLoadedMods() {
    return g_loadedMods;
}
