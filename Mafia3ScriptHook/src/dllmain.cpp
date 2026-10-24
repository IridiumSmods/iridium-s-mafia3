#include <Windows.h>
#include <DbgHelp.h>
#include "hooks.h"
#include "logger.h"
#include "gui.h"
#include "../vendor/minhook/include/MinHook.h"

#pragma comment(lib, "DbgHelp.lib")

static HMODULE g_hModule = nullptr;

static void CrashWrite(FILE* f, const char* fmt, ...) {
    char buf[1024];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);

    if (f) { fprintf(f, "%s\n", buf); fflush(f); }
    Logger::Log("%s", buf);
    OutputDebugStringA(buf);
    OutputDebugStringA("\n");
}

static LONG WINAPI CrashHandler(PEXCEPTION_POINTERS ex) {
    switch (ex->ExceptionRecord->ExceptionCode) {
    case EXCEPTION_ACCESS_VIOLATION:
    case EXCEPTION_STACK_OVERFLOW:
    case EXCEPTION_ILLEGAL_INSTRUCTION:
    case EXCEPTION_INT_DIVIDE_BY_ZERO:
    case EXCEPTION_PRIV_INSTRUCTION:
    case EXCEPTION_GUARD_PAGE:
        break;
    default:
        return EXCEPTION_CONTINUE_SEARCH;
    }

    std::string crashPath = Logger::GetGameDir() + "ScriptHook\\crash.log";
    FILE* f = fopen(crashPath.c_str(), "w");

    CrashWrite(f, "========== CRASH DETECTED ==========");

    uintptr_t addr = (uintptr_t)ex->ExceptionRecord->ExceptionAddress;
    uintptr_t gameBase = (uintptr_t)GetModuleHandleA("Mafia3DefinitiveEdition.exe");
    uintptr_t hookBase = (uintptr_t)g_hModule;

    HMODULE crashModule = nullptr;
    GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, (LPCSTR)addr, &crashModule);

    char modName[MAX_PATH] = "unknown";
    if (crashModule) GetModuleFileNameA(crashModule, modName, MAX_PATH);
    const char* modShort = strrchr(modName, '\\');
    modShort = modShort ? modShort + 1 : modName;

    uintptr_t modBase = crashModule ? (uintptr_t)crashModule : 0;

    CrashWrite(f, "Exception 0x%08X at 0x%p", ex->ExceptionRecord->ExceptionCode, (void*)addr);
    CrashWrite(f, "Module: %s (base 0x%p, offset +0x%llX)", modShort, (void*)modBase, addr - modBase);
    CrashWrite(f, "Game base: 0x%p | ScriptHook base: 0x%p", (void*)gameBase, (void*)hookBase);

    if (crashModule == g_hModule)
        CrashWrite(f, ">>> CRASH IS INSIDE SCRIPTHOOK <<<");
    else if (crashModule == (HMODULE)gameBase)
        CrashWrite(f, ">>> CRASH IS INSIDE GAME EXE <<<");

    if (ex->ExceptionRecord->ExceptionCode == EXCEPTION_ACCESS_VIOLATION && ex->ExceptionRecord->NumberParameters >= 2) {
        const char* op = ex->ExceptionRecord->ExceptionInformation[0] == 0 ? "reading" : "writing";
        CrashWrite(f, "Access violation %s address 0x%p", op, (void*)ex->ExceptionRecord->ExceptionInformation[1]);
    }

    CrashWrite(f, "RAX=%p RBX=%p RCX=%p RDX=%p",
        (void*)ex->ContextRecord->Rax, (void*)ex->ContextRecord->Rbx,
        (void*)ex->ContextRecord->Rcx, (void*)ex->ContextRecord->Rdx);
    CrashWrite(f, "RSI=%p RDI=%p RSP=%p RBP=%p",
        (void*)ex->ContextRecord->Rsi, (void*)ex->ContextRecord->Rdi,
        (void*)ex->ContextRecord->Rsp, (void*)ex->ContextRecord->Rbp);
    CrashWrite(f, "R8=%p  R9=%p  R10=%p R11=%p",
        (void*)ex->ContextRecord->R8, (void*)ex->ContextRecord->R9,
        (void*)ex->ContextRecord->R10, (void*)ex->ContextRecord->R11);

    SymInitialize(GetCurrentProcess(), nullptr, TRUE);

    STACKFRAME64 frame = {};
    frame.AddrPC.Offset = ex->ContextRecord->Rip;
    frame.AddrPC.Mode = AddrModeFlat;
    frame.AddrFrame.Offset = ex->ContextRecord->Rbp;
    frame.AddrFrame.Mode = AddrModeFlat;
    frame.AddrStack.Offset = ex->ContextRecord->Rsp;
    frame.AddrStack.Mode = AddrModeFlat;

    CONTEXT ctx = *ex->ContextRecord;

    CrashWrite(f, "Stack trace:");
    for (int i = 0; i < 20; i++) {
        if (!StackWalk64(IMAGE_FILE_MACHINE_AMD64, GetCurrentProcess(), GetCurrentThread(),
            &frame, &ctx, nullptr, SymFunctionTableAccess64, SymGetModuleBase64, nullptr))
            break;
        if (frame.AddrPC.Offset == 0) break;

        uintptr_t pc = frame.AddrPC.Offset;
        HMODULE mod = nullptr;
        GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, (LPCSTR)pc, &mod);

        char mn[MAX_PATH] = "?";
        if (mod) GetModuleFileNameA(mod, mn, MAX_PATH);
        const char* ms = strrchr(mn, '\\');
        ms = ms ? ms + 1 : mn;

        uintptr_t mb = mod ? (uintptr_t)mod : 0;
        CrashWrite(f, "  [%2d] 0x%p  %s+0x%llX", i, (void*)pc, ms, pc - mb);
    }

    SymCleanup(GetCurrentProcess());
    CrashWrite(f, "====================================");

    if (f) fclose(f);

    return EXCEPTION_CONTINUE_SEARCH;
}

static DWORD WINAPI InitThread(LPVOID) {
    char exePath[MAX_PATH];
    GetModuleFileNameA(nullptr, exePath, MAX_PATH);
    std::string gameDir(exePath);
    size_t lastSlash = gameDir.find_last_of("\\/");
    if (lastSlash != std::string::npos)
        gameDir = gameDir.substr(0, lastSlash + 1);

    Logger::Init(gameDir);
    Logger::Verbose("Mafia3ScriptHook v2.0 initializing...");

    AddVectoredExceptionHandler(1, CrashHandler);

    if (Hooks::Install()) {
        Logger::Log("Waiting for game to initialize Lua state.");
    } else {
        Logger::Log("FATAL: Failed to install hooks. This game version is not supported by this build "
            "(a game update?): the Lua mods and the F4 menu stay off, the game runs as usual.");
        Hooks::MarkInstallFailed();
    }

    return 0;
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) {
        g_hModule = hModule;
        DisableThreadLibraryCalls(hModule);
        MH_Initialize();
        CreateThread(nullptr, 0, (LPTHREAD_START_ROUTINE)D3DThread, nullptr, 0, nullptr);
        CreateThread(nullptr, 0, InitThread, nullptr, 0, nullptr);
    } else if (reason == DLL_PROCESS_DETACH) {
        RemoveVectoredExceptionHandler(CrashHandler);
        Hooks::Remove();
        MH_Uninitialize();
        Logger::Close();
    }
    return TRUE;
}
