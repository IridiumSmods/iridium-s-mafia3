#include "settings.h"
#include <Windows.h>

static bool g_consoleWindow = true;
static bool g_verboseLogging = false;

// INI helper — reads a bool as 0/1 with a default
static bool ReadBool(const char* path, const char* section, const char* key, bool def) {
    return GetPrivateProfileIntA(section, key, def ? 1 : 0, path) != 0;
}

static void WriteBool(const char* path, const char* section, const char* key, bool val) {
    WritePrivateProfileStringA(section, key, val ? "1" : "0", path);
}

void Settings::Load(const std::string& gameDir) {
    std::string iniPath = gameDir + "ScriptHook\\ScriptHook.ini";

    // Create default file if it doesn't exist
    if (GetFileAttributesA(iniPath.c_str()) == INVALID_FILE_ATTRIBUTES) {
        CreateDirectoryA((gameDir + "ScriptHook").c_str(), nullptr);

        WriteBool(iniPath.c_str(), "General", "ConsoleWindow", true);
        WriteBool(iniPath.c_str(), "General", "VerboseLogging", false);

        // Write comments by prepending to the file
        FILE* f = fopen(iniPath.c_str(), "r");
        std::string content;
        if (f) {
            char buf[256];
            while (fgets(buf, sizeof(buf), f))
                content += buf;
            fclose(f);
        }

        f = fopen(iniPath.c_str(), "w");
        if (f) {
            fprintf(f, "; Mafia III ScriptHook Settings\n;\n");
            fprintf(f, "; ConsoleWindow - Show external console window (0 = off, 1 = on)\n");
            fprintf(f, "; VerboseLogging - Show all log messages including includes and Lua prints (0 = off, 1 = on)\n;\n");
            fprintf(f, "%s", content.c_str());
            fclose(f);
        }
    }

    g_consoleWindow = ReadBool(iniPath.c_str(), "General", "ConsoleWindow", true);
    g_verboseLogging = ReadBool(iniPath.c_str(), "General", "VerboseLogging", false);
}

bool Settings::ConsoleWindow() { return g_consoleWindow; }
bool Settings::VerboseLogging() { return g_verboseLogging; }
