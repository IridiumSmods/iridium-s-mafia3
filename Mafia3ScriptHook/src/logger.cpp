#include "logger.h"
#include "settings.h"
#include <Windows.h>
#include <cstdio>
#include <cstdarg>

static FILE* g_logFile = nullptr;
static FILE* g_console = nullptr;
static CRITICAL_SECTION g_cs;
static std::string g_gameDir;

static void WriteOutput(const char* fmt, va_list args, bool fileOnly) {
    EnterCriticalSection(&g_cs);

    SYSTEMTIME st;
    GetLocalTime(&st);
    char timestamp[32];
    snprintf(timestamp, sizeof(timestamp), "[%02d:%02d:%02d.%03d] ",
        st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);

    va_list argsCopy;

    if (g_logFile) {
        fprintf(g_logFile, "%s", timestamp);
        va_copy(argsCopy, args);
        vfprintf(g_logFile, fmt, argsCopy);
        va_end(argsCopy);
        fprintf(g_logFile, "\n");
        fflush(g_logFile);
    }

    if (g_console && !fileOnly) {
        fprintf(g_console, "%s", timestamp);
        va_copy(argsCopy, args);
        vfprintf(g_console, fmt, argsCopy);
        va_end(argsCopy);
        fprintf(g_console, "\n");
    }

    LeaveCriticalSection(&g_cs);
}

void Logger::Init(const std::string& gameDir) {
    g_gameDir = gameDir;
    InitializeCriticalSection(&g_cs);

    Settings::Load(gameDir);

    if (Settings::ConsoleWindow()) {
        AllocConsole();
        SetConsoleTitleA("Mafia III ScriptHook");
        freopen_s(&g_console, "CONOUT$", "w", stdout);

        HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
        DWORD mode = 0;
        GetConsoleMode(hOut, &mode);
        SetConsoleMode(hOut, mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING);

        HWND consoleWnd = GetConsoleWindow();
        if (consoleWnd) {
            int screenW = GetSystemMetrics(SM_CXSCREEN);
            int conW = 852, conH = 480;
            SetWindowPos(consoleWnd, nullptr, screenW - conW, 0, conW, conH, SWP_NOZORDER | SWP_SHOWWINDOW);
        }
    }

    std::string hookDir = g_gameDir + "ScriptHook\\";
    CreateDirectoryA(hookDir.c_str(), nullptr);

    std::string logPath = hookDir + "ScriptHook.log";
    g_logFile = fopen(logPath.c_str(), "w");

    Log("=== Mafia3ScriptHook v2.0 ===");
    Verbose("Console window: %s", Settings::ConsoleWindow() ? "on" : "off");
    Verbose("Verbose logging: %s", Settings::VerboseLogging() ? "on" : "off");
}

void Logger::Log(const char* fmt, ...) {
    va_list args;
    va_start(args, fmt);
    WriteOutput(fmt, args, false);
    va_end(args);
}

void Logger::Verbose(const char* fmt, ...) {
    va_list args;
    va_start(args, fmt);
    // Verbose: always write to file, but only to console if verbose mode is on
    WriteOutput(fmt, args, !Settings::VerboseLogging());
    va_end(args);
}

void Logger::Close() {
    Log("Shutting down.");
    if (g_logFile) {
        fclose(g_logFile);
        g_logFile = nullptr;
    }
    if (g_console) {
        fclose(g_console);
        g_console = nullptr;
    }
    FreeConsole();
    DeleteCriticalSection(&g_cs);
}

const std::string& Logger::GetGameDir() {
    return g_gameDir;
}
