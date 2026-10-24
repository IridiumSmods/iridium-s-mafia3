#include "gui.h"
#include "lua_mod_loader.h"
#include "logger.h"
#include "hooks.h"
#include "../vendor/imgui/imgui.h"
#include <string>
#include <vector>
#include <cstring>
#include <deque>

static std::deque<std::string> g_consoleLog;
static const size_t MAX_LOG_LINES = 256;
static char g_inputBuf[256] = {};
static bool g_scrollToBottom = false;
static bool g_focusInput = true;

// Command history
static std::vector<std::string> g_history;
static int g_historyPos = -1; // -1 = new input, 0+ = browsing history
static std::string g_savedInput; // Saves current input when browsing history

void Gui::AddToConsole(const char* fmt, ...) {
    char buf[512];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    g_consoleLog.push_back(buf);
    if (g_consoleLog.size() > MAX_LOG_LINES)
        g_consoleLog.pop_front();
    g_scrollToBottom = true;
}

void Gui::FocusInput() {
    g_focusInput = true;
}

static void ConsoleAddLine(const char* fmt, ...) {
    char buf[512];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    g_consoleLog.push_back(buf);
    if (g_consoleLog.size() > MAX_LOG_LINES)
        g_consoleLog.pop_front();
    g_scrollToBottom = true;
}

static void ExecuteCommand(const char* cmd) {
    ConsoleAddLine("> %s", cmd);

    std::string input(cmd);
    size_t start = input.find_first_not_of(" \t");
    if (start == std::string::npos) return;
    input = input.substr(start);

    // Add to history (avoid duplicating last entry)
    if (g_history.empty() || g_history.back() != input)
        g_history.push_back(input);
    g_historyPos = -1;

    if (input == "reloadall") {
        ConsoleAddLine("Reloading all mods (queued on game thread)...");
        ModLoader::RequestReloadAll();
        ConsoleAddLine("Queued — watch log for Done.");
    }
    else if (input.rfind("reload ", 0) == 0) {
        std::string modName = input.substr(7);
        // Trim the mod name
        size_t s = modName.find_first_not_of(" \t");
        if (s != std::string::npos) modName = modName.substr(s);
        size_t e = modName.find_last_not_of(" \t");
        if (e != std::string::npos) modName = modName.substr(0, e + 1);

        if (modName.empty()) {
            ConsoleAddLine("Usage: reload <modName>");
        } else {
            ConsoleAddLine("Reloading mod '%s' (queued)...", modName.c_str());
            ModLoader::RequestReloadMod(modName);
            ConsoleAddLine("Queued — watch log for Done.");
        }
    }
    else if (input == "mods") {
        auto mods = ModLoader::GetLoadedMods();
        ConsoleAddLine("Loaded mods (%zu):", mods.size());
        for (const auto& m : mods)
            ConsoleAddLine("  %s", m.c_str());
    }
    else if (input == "help") {
        ConsoleAddLine("Commands:");
        ConsoleAddLine("  reloadall          - Reload all mods");
        ConsoleAddLine("  reload <modName>   - Reload a specific mod");
        ConsoleAddLine("  mods               - List loaded mods");
        ConsoleAddLine("  clear              - Clear console");
        ConsoleAddLine("  help               - Show this help");
    }
    else if (input == "clear") {
        g_consoleLog.clear();
    }
    else {
        ConsoleAddLine("Unknown command: %s (type 'help' for commands)", input.c_str());
    }
}

namespace Gui
{
    void Render()
    {
        ImGuiIO& io = ImGui::GetIO();
        ImGui::SetNextWindowPos(ImVec2(0, 0), ImGuiCond_Always);
        ImGui::SetNextWindowSize(ImVec2(io.DisplaySize.x, io.DisplaySize.y * 0.25f), ImGuiCond_Always);
        ImGui::Begin("ScriptHook Console", nullptr,
            ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoTitleBar);

        // Log area — selectable/copyable read-only text box
        float footerHeight = ImGui::GetStyle().ItemSpacing.y + ImGui::GetFrameHeightWithSpacing();

        static std::string g_logText;
        g_logText.clear();
        for (const auto& line : g_consoleLog) {
            g_logText += line;
            g_logText += '\n';
        }

        static std::vector<char> g_textBuf;
        if (g_textBuf.size() < g_logText.size() + 1)
            g_textBuf.resize(g_logText.size() + 256);
        memcpy(g_textBuf.data(), g_logText.c_str(), g_logText.size() + 1);

        struct ScrollCB {
            static int Callback(ImGuiInputTextCallbackData* data) {
                bool* scroll = (bool*)data->UserData;
                if (*scroll) {
                    data->CursorPos = data->BufTextLen;
                    data->SelectionStart = data->SelectionEnd = data->CursorPos;
                    *scroll = false;
                }
                return 0;
            }
        };

        ImGui::InputTextMultiline("##log", g_textBuf.data(), g_textBuf.size(),
            ImVec2(-1, -footerHeight),
            ImGuiInputTextFlags_ReadOnly | ImGuiInputTextFlags_CallbackAlways,
            ScrollCB::Callback, &g_scrollToBottom);

        // Input line with history
        ImGui::Separator();

        struct HistoryHelper {
            static int Callback(ImGuiInputTextCallbackData* data) {
                if (data->EventFlag == ImGuiInputTextFlags_CallbackHistory) {
                    if (g_history.empty()) return 0;

                    if (data->EventKey == ImGuiKey_UpArrow) {
                        if (g_historyPos == -1) {
                            g_savedInput = std::string(data->Buf, data->BufTextLen);
                            g_historyPos = (int)g_history.size() - 1;
                        } else if (g_historyPos > 0) {
                            g_historyPos--;
                        }
                    } else if (data->EventKey == ImGuiKey_DownArrow) {
                        if (g_historyPos != -1) {
                            g_historyPos++;
                            if (g_historyPos >= (int)g_history.size())
                                g_historyPos = -1;
                        }
                    }

                    const char* entry = (g_historyPos >= 0) ? g_history[g_historyPos].c_str() : g_savedInput.c_str();
                    data->DeleteChars(0, data->BufTextLen);
                    data->InsertChars(0, entry);
                }
                return 0;
            }
        };

        bool reclaim_focus = false;
        ImGuiInputTextFlags flags = ImGuiInputTextFlags_EnterReturnsTrue | ImGuiInputTextFlags_CallbackHistory;
        if (ImGui::InputText("##input", g_inputBuf, sizeof(g_inputBuf), flags, HistoryHelper::Callback)) {
            if (g_inputBuf[0] != '\0')
                ExecuteCommand(g_inputBuf);
            g_inputBuf[0] = '\0';
            reclaim_focus = true;
        }

        // Auto-focus on first frame or after command
        if (g_focusInput || reclaim_focus) {
            ImGui::SetKeyboardFocusHere(-1);
            g_focusInput = false;
        }

        ImGui::End();
    }
}
