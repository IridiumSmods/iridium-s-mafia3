#include "hooks.h"
#include "hks_types.h"
#include "scanner.h"
#include "logger.h"
#include "lua_mod_loader.h"
#include <Windows.h>
#include <atomic>
#include <queue>
#include <mutex>
#include "../vendor/minhook/include/MinHook.h"

HksApi g_hks;

static std::atomic<bool> g_installFailed{ false };

static ResetState_fn g_origResetState = nullptr;
static Tick_fn g_origTick = nullptr;
static DWORD g_gameThreadId = 0;

// Mutex to prevent concurrent Lua access between our code and game worker threads
typedef int(__fastcall* hksi_lua_pcall_fn)(lua_State* L, int nargs, unsigned int nresults, int errfunc);
static hksi_lua_pcall_fn g_origHksiPcall = nullptr;
static CRITICAL_SECTION g_luaMutex;
static bool g_luaMutexInit = false;
static volatile bool g_draining = false;

// Scanned addresses
static uintptr_t g_addrGameResetState = 0;
static uintptr_t g_addrTick = 0;

// Deferred load
static void* g_pendingScriptMachine = nullptr;
static volatile int g_deferFrames = -1;

// Lua call queue
static std::mutex g_queueMutex;
static std::queue<std::function<void()>> g_luaQueue;

// Helper: scan and log
static uintptr_t ScanFor(const char* name, const char* pattern) {
    uintptr_t addr = Scanner::Find(pattern);
    if (addr)
        Logger::Verbose("  %s: 0x%p", name, (void*)addr);
    else
        Logger::Log("  %s: NOT FOUND", name);
    return addr;
}

bool HksApi::Resolve() {
    Logger::Verbose("Scanning for HavokScript functions...");

    uintptr_t loadfileAddr = Scanner::FindFunctionEntry(Patterns::LuaLLoadfileInner);
    if (loadfileAddr)
        Logger::Verbose("  %s: 0x%p", "luaL_loadfile", (void*)loadfileAddr);
    else
        Logger::Log("  %s: NOT FOUND", "luaL_loadfile");
    luaL_loadfile    = (luaL_loadfile_fn)loadfileAddr;
    lua_pcall        = (lua_pcall_fn)ScanFor("hksi_lua_pcall", Patterns::HksiLuaPcall);
    // Scan from near luaL_loadfile to skip false positive (hksi_lua_load has same tail)
    uintptr_t loadbufSearchFrom = loadfileAddr ? loadfileAddr - 0x200 : 0;
    uintptr_t loadbufAddr = Scanner::FindFunctionEntry(Patterns::LuaLLoadbufferInner, loadbufSearchFrom);
    if (loadbufAddr)
        Logger::Verbose("  %s: 0x%p", "luaL_loadbuffer", (void*)loadbufAddr);
    else
        Logger::Log("  %s: NOT FOUND", "luaL_loadbuffer");
    luaL_loadbuffer  = (luaL_loadbuffer_fn)loadbufAddr;
    hks_pushcclosure = (hks_pushcclosure_fn)ScanFor("hks_pushcclosure", Patterns::HksPushcclosure);
    lua_setfield     = (hksi_lua_setfield_fn)ScanFor("lua_setfield", Patterns::HksiLuaSetfield);
    lua_pushlstring  = (hksi_lua_pushlstring_fn)ScanFor("lua_pushlstring", Patterns::HksiLuaPushlstring);
    luaL_checklstring = (luaL_checklstring_fn)ScanFor("luaL_checklstring", Patterns::LuaLChecklstring);
    obj_tolstring    = (hks_obj_tolstring_fn)ScanFor("hks_obj_tolstring", Patterns::HksObjTolstring);

    return luaL_loadfile && lua_pcall && luaL_loadbuffer && hks_pushcclosure &&
           lua_setfield && lua_pushlstring && luaL_checklstring && obj_tolstring;
}

void Hooks::QueueLuaCall(std::function<void()> fn) {
    std::lock_guard<std::mutex> lock(g_queueMutex);
    g_luaQueue.push(std::move(fn));
}

// The queue lock is not held while the calls run: they take the menu lock,
// which the render thread holds while it queues calls.
static void DrainLuaQueue() {
    std::queue<std::function<void()>> work;
    {
        std::lock_guard<std::mutex> lock(g_queueMutex);
        std::swap(work, g_luaQueue);
    }
    while (!work.empty()) {
        auto fn = std::move(work.front());
        work.pop();
        fn();
    }
}

static VOID CALLBACK DeferredLoadTimer(PVOID, BOOLEAN) {
    g_deferFrames = 0;
}

static __int64 __fastcall HookedResetState(void* thisPtr, char async, uint64_t timeout) {
    __int64 result = g_origResetState(thisPtr, async, timeout);

    if (g_gameThreadId == 0 && result == 3)
        g_gameThreadId = GetCurrentThreadId();

    if (result == 3 && g_pendingScriptMachine == nullptr && g_deferFrames == -1) {
        lua_State* L = *(lua_State**)((uintptr_t)thisPtr + LUA_STATE_OFFSET);
        if (L) {
            Logger::Log("Lua state ready");
            g_pendingScriptMachine = thisPtr;
            g_deferFrames = 1;

            HANDLE hTimer = nullptr;
            CreateTimerQueueTimer(&hTimer, nullptr, DeferredLoadTimer, nullptr, 350, 0, WT_EXECUTEONLYONCE);
        }
    }

    return result;
}

// Hooked hksi_lua_pcall — acquires mutex to prevent concurrent access during our drain
static int __fastcall HookedHksiPcall(lua_State* L, int nargs, unsigned int nresults, int errfunc) {
    if (g_luaMutexInit && !g_draining) {
        EnterCriticalSection(&g_luaMutex);
        int result = g_origHksiPcall(L, nargs, nresults, errfunc);
        LeaveCriticalSection(&g_luaMutex);
        return result;
    }
    return g_origHksiPcall(L, nargs, nresults, errfunc);
}

static __int64 __fastcall HookedTick(__int64 a1) {
    // Drain our queue under the mutex — game worker threads will block on their lua_pcall
    if (g_luaMutexInit) EnterCriticalSection(&g_luaMutex);
    g_draining = true;

    if (g_pendingScriptMachine && g_deferFrames == 0) {
        void* sm = g_pendingScriptMachine;
        g_pendingScriptMachine = nullptr;
        g_deferFrames = -1;

        lua_State* L = *(lua_State**)((uintptr_t)sm + LUA_STATE_OFFSET);
        if (L) {
            Logger::Log("Loading mods...");
            ModLoader::OnLuaStateReady(L);
        }
    }

    DrainLuaQueue();
    ModLoader::Tick();

    g_draining = false;
    if (g_luaMutexInit) LeaveCriticalSection(&g_luaMutex);

    return g_origTick(a1);
}

bool Hooks::IsGameThread() {
    return g_gameThreadId != 0 && GetCurrentThreadId() == g_gameThreadId;
}

void Hooks::MarkInstallFailed() {
    g_installFailed.store(true, std::memory_order_relaxed);
}

bool Hooks::InstallFailed() {
    return g_installFailed.load(std::memory_order_relaxed);
}

bool Hooks::Install() {
    Logger::Verbose("Scanning for game functions...");
    g_addrGameResetState = ScanFor("GameResetState", Patterns::GameResetState);
    g_addrTick = ScanFor("ScriptMachineTick", Patterns::ScriptMachineTick);

    if (!g_addrGameResetState || !g_addrTick) {
        Logger::Log("FATAL: Required game functions not found");
        return false;
    }

    if (!g_hks.Resolve()) {
        Logger::Log("FATAL: Required HavokScript functions not found");
        return false;
    }

    InitializeCriticalSection(&g_luaMutex);
    g_luaMutexInit = true;

    MH_STATUS status = MH_CreateHook((void*)g_addrGameResetState, &HookedResetState, (LPVOID*)&g_origResetState);
    if (status != MH_OK) {
        Logger::Log("Hook ResetState failed: %s", MH_StatusToString(status));
        return false;
    }

    status = MH_CreateHook((void*)g_addrTick, &HookedTick, (LPVOID*)&g_origTick);
    if (status != MH_OK) {
        Logger::Log("Hook Tick failed: %s", MH_StatusToString(status));
        return false;
    }

    // Hook hksi_lua_pcall for mutual exclusion with game worker threads
    uintptr_t pcallAddr = ScanFor("hksi_lua_pcall", Patterns::HksiLuaPcall);
    if (pcallAddr) {
        status = MH_CreateHook((void*)pcallAddr, &HookedHksiPcall, (LPVOID*)&g_origHksiPcall);
        if (status != MH_OK)
            Logger::Log("Hook hksi_lua_pcall failed: %s (non-fatal)", MH_StatusToString(status));
    }

    status = MH_EnableHook(MH_ALL_HOOKS);
    if (status != MH_OK) {
        Logger::Log("EnableHook failed: %s", MH_StatusToString(status));
        return false;
    }

    Logger::Verbose("Hooks installed successfully");
    return true;
}

void Hooks::Remove() {
    MH_DisableHook(MH_ALL_HOOKS);
    if (g_luaMutexInit) {
        DeleteCriticalSection(&g_luaMutex);
        g_luaMutexInit = false;
    }
}
