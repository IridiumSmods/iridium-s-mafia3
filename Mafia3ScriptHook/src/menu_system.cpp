#include "menu_system.h"
#include "hooks.h"
#include "logger.h"
#include "glass.h"
#include "menu_render.h"
#include "input_bridge.h"
#include "../vendor/imgui/imgui.h"
#include "../vendor/imgui/imgui_internal.h"
#include <Windows.h>
#include <algorithm>
#include <cfloat>
#include <cmath>
#include <cstring>
#include <deque>
#include <map>
#include <mutex>

static lua_State* g_L = nullptr;
static bool g_open = false;
static bool g_ready = false;
static int g_nextMenuId = 1;
static int g_activeMenuId = 0; // menuId of the current stack top
static double g_openedAt = 0.0;

// The menu stack is changed by Lua on the game thread and drawn on the render thread.
static std::recursive_mutex g_menuMutex;
using MenuLock = std::lock_guard<std::recursive_mutex>;

// Text input dialog state
static bool g_textInputActive = false;
static char g_textInputBuf[256] = {};
static std::string g_textInputPrompt;
static int g_textInputCallbackId = 0;
static bool g_textInputFocus = false;

static void FlushKeyStates();

// --- Menu filter ---

static bool CaseInsensitiveContains(const std::string& str, const char* filter) {
    if (!filter || filter[0] == '\0') return true;
    std::string lower = str;
    std::string lowerFilter = filter;
    for (auto& c : lower) c = (char)tolower((unsigned char)c);
    for (auto& c : lowerFilter) c = (char)tolower((unsigned char)c);
    return lower.find(lowerFilter) != std::string::npos;
}

void Menu::RebuildFilter() {
    filteredIndices.clear();
    bool searching = hasSearch && searchBuffer[0] != '\0';
    for (int i = 0; i < (int)entries.size(); i++) {
        if (entries[i].type == EntryType::Search) continue; // Don't show search entry itself in results
        if (searching) {
            if (entries[i].type == EntryType::Header) continue;
            if (!CaseInsensitiveContains(entries[i].label, searchBuffer))
                continue;
        }
        filteredIndices.push_back(i);
    }
    if (selectedIndex >= (int)filteredIndices.size())
        selectedIndex = filteredIndices.empty() ? 0 : (int)filteredIndices.size() - 1;
}

int Menu::GetFilteredEntryIndex(int filteredPos) const {
    if (filteredPos < 0 || filteredPos >= (int)filteredIndices.size()) return -1;
    return filteredIndices[filteredPos];
}

int Menu::GetFilteredCount() const {
    return (int)filteredIndices.size();
}

bool Menu::IsSelectable(int filteredPos) const {
    int i = GetFilteredEntryIndex(filteredPos);
    return i >= 0 && entries[i].type != EntryType::Header;
}

static int NextSelectable(const Menu& m, int from, int dir, bool wrap) {
    int n = m.GetFilteredCount();
    for (int step = 1; step <= n; step++) {
        int i = from + dir * step;
        if (wrap) i = ((i % n) + n) % n;
        else if (i < 0 || i >= n) return from;
        if (m.IsSelectable(i)) return i;
    }
    return from;
}

static void FixSelection(Menu& m) {
    int n = m.GetFilteredCount();
    if (n == 0) { m.selectedIndex = 0; return; }
    m.selectedIndex = ImClamp(m.selectedIndex, 0, n - 1);
    if (!m.IsSelectable(m.selectedIndex)) {
        int next = NextSelectable(m, m.selectedIndex, 1, true);
        m.selectedIndex = next;
    }
}

static std::deque<Menu> g_menuStack;
static Menu g_pendingMenu;
static bool g_buildingMenu = false;
static int g_pendingSelectEntry = -1;

// Last selected row per menu path, restored when the same submenu is opened again.
static std::map<std::string, int> g_lastSelection;

static std::string StackKey(size_t depth, const std::string& title) {
    std::string key;
    for (size_t i = 0; i < depth && i < g_menuStack.size(); i++) {
        key += g_menuStack[i].title;
        key += '\x1F';
    }
    return key + title;
}

static void PopMenu() {
    if (g_menuStack.empty()) return;
    const Menu& top = g_menuStack.back();
    if (!top.hasSearch)
        g_lastSelection[StackKey(g_menuStack.size() - 1, top.title)] = top.selectedIndex;
    g_menuStack.pop_back();
    if (!g_menuStack.empty()) g_activeMenuId = g_menuStack.back().menuId;
}

struct RootEntry {
    std::string name;
    std::string description;
    int callbackId;
    unsigned int icon;
};
static std::vector<RootEntry> g_rootEntries;

static Menu BuildRoot() {
    Menu root;
    root.title = MenuRender::Text(MenuRender::Str::Home);
    root.isRoot = true;
    for (const auto& entry : g_rootEntries) {
        MenuEntry me;
        me.label = entry.name;
        me.hint = entry.description;
        me.icon = entry.icon;
        me.submenu = true;
        me.callbackId = entry.callbackId;
        me.type = EntryType::Button;
        root.entries.push_back(me);
    }
    root.menuId = g_nextMenuId++;
    root.RebuildFilter();
    return root;
}

// --- Helpers ---

constexpr int HKS_TNIL = 0;
constexpr int HKS_TNUMBER = 3;
constexpr int HKS_TSTRING = 4;

static int ArgCount(lua_State* L) {
    uintptr_t base = *(uintptr_t*)((uintptr_t)L + 80);
    uintptr_t top = *(uintptr_t*)((uintptr_t)L + 72);
    return (int)((top - base) / 16);
}

static int ArgTag(lua_State* L, int idx) {
    if (idx > ArgCount(L)) return HKS_TNIL;
    uintptr_t base = *(uintptr_t*)((uintptr_t)L + 80);
    return *(int*)(base + (idx - 1) * 16) & 0xF;
}

static float ReadNumberArg(lua_State* L, int idx) {
    if (ArgTag(L, idx) != HKS_TNUMBER) return 0.0f;
    uintptr_t base = *(uintptr_t*)((uintptr_t)L + 80);
    uintptr_t obj = base + (idx - 1) * 16;
    return *(float*)(obj + 8);
}

static std::string ReadStringArg(lua_State* L, int idx) {
    if (ArgTag(L, idx) != HKS_TSTRING) return "";
    size_t len = 0;
    const char* s = g_hks.luaL_checklstring(L, idx, &len);
    return s ? std::string(s, len) : std::string();
}

// All Lua calls are queued and executed on the game thread via hooked lua_pcall
static void RunLuaCode(const char* code, const char* name) {
    if (!g_L) return;
    if (g_hks.luaL_loadbuffer(g_L, code, strlen(code), name) == 0) {
        g_hks.lua_pcall(g_L, 0, 0, 0);
    }
}

static void ExecuteCallback(int callbackId) {
    if (!g_L || callbackId <= 0) return;

    Hooks::QueueLuaCall([callbackId]() {
        char code[256];
        snprintf(code, sizeof(code),
            "local fn = _SH_callbacks[%d]\n"
            "if fn then\n"
            "  local ok, result = pcall(fn)\n"
            "  if not ok then print('CB ERROR: ' .. tostring(result)) end\n"
            "  if ok and type(result) == 'table' and result._isMenu then\n"
            "    _SH_pushMenuToCpp(result)\n"
            "  end\n"
            "end", callbackId);
        RunLuaCode(code, "menu_cb");
    });
}

static void ExecuteListCallback(int callbackId, int listIndex, const std::string& listValue) {
    if (!g_L || callbackId <= 0) return;

    std::string value;
    for (char c : listValue) {
        if (c == '"' || c == '\\') value += '\\';
        if (c != '\n' && c != '\r') value += c;
    }
    Hooks::QueueLuaCall([callbackId, listIndex, value]() {
        char code[640];
        snprintf(code, sizeof(code),
            "local fn = _SH_callbacks[%d]\n"
            "if fn then\n"
            "  local ok, err = pcall(fn, nil, nil, nil, nil, %d, \"%s\")\n"
            "  if not ok then print('LIST CB ERROR: ' .. tostring(err)) end\n"
            "end", callbackId, listIndex, value.c_str());
        RunLuaCode(code, "list_cb");
    });
}

static DWORD g_lastUpdateTick = 0;

static void CallOnUpdate(int onUpdateId) {
    if (!g_L || onUpdateId <= 0) return;

    DWORD now = GetTickCount();
    if (now - g_lastUpdateTick < 33) return;
    g_lastUpdateTick = now;

    // Capture the menu ID so the update only applies if this menu is still on top
    int capturedMenuId = g_activeMenuId;
    Hooks::QueueLuaCall([onUpdateId, capturedMenuId]() {
        {
            MenuLock lock(g_menuMutex);
            if (g_menuStack.empty() || g_menuStack.back().menuId != capturedMenuId) return;
        }
        char code[128];
        snprintf(code, sizeof(code), "local f = _SH_callbacks[%d]; if f then f() end", onUpdateId);
        RunLuaCode(code, "menu_update");
    });
}

// --- Lua C functions ---

static int __fastcall LuaUiBeginMenu(lua_State* L) {
    MenuLock lock(g_menuMutex);
    g_pendingMenu = Menu{};
    g_pendingMenu.title = ReadStringArg(L, 1);
    g_pendingSelectEntry = -1;
    g_buildingMenu = true;
    return 0;
}

// _ui_add_entry(label, callbackId, typeInt, listCallbackId, value, searchPlaceholder, hint, flags, icon, iconKey)
// typeInt: 0=button, 1=checkbox, 2=list, 3=search, 4=section header.
// flags: 1 = opens a submenu, 2 = checkbox starts checked, 4 = starts disabled
static int __fastcall LuaUiAddEntry(lua_State* L) {
    MenuLock lock(g_menuMutex);
    if (!g_buildingMenu) return 0;

    MenuEntry entry;
    entry.label = ReadStringArg(L, 1);
    entry.callbackId = (int)ReadNumberArg(L, 2);
    int typeInt = (int)ReadNumberArg(L, 3);
    entry.type = (typeInt >= 0 && typeInt <= 4) ? (EntryType)typeInt : EntryType::Button;
    entry.listCallbackId = (int)ReadNumberArg(L, 4);
    entry.value = ReadStringArg(L, 5);
    entry.searchPlaceholder = ReadStringArg(L, 6);
    entry.hint = ReadStringArg(L, 7);
    int flags = (int)ReadNumberArg(L, 8);
    entry.submenu = (flags & 1) != 0;
    entry.checked = (flags & 2) != 0;
    entry.enabled = (flags & 4) == 0;
    entry.icon = (unsigned int)ReadNumberArg(L, 9);
    entry.iconKey = ReadStringArg(L, 10);

    if (entry.type == EntryType::Search)
        g_pendingMenu.hasSearch = true;

    g_pendingMenu.entries.push_back(entry);
    return 0;
}

static int __fastcall LuaUiSetOnUpdate(lua_State* L) {
    MenuLock lock(g_menuMutex);
    if (!g_buildingMenu) return 0;
    g_pendingMenu.onUpdateId = (int)ReadNumberArg(L, 1);
    return 0;
}

// _ui_set_selected(entryIdx) — row the menu being built opens on
static int __fastcall LuaUiSetSelected(lua_State* L) {
    MenuLock lock(g_menuMutex);
    if (g_buildingMenu) g_pendingSelectEntry = (int)ReadNumberArg(L, 1) - 1;
    return 0;
}

static int __fastcall LuaUiEndMenu(lua_State* L) {
    MenuLock lock(g_menuMutex);
    if (!g_buildingMenu) return 0;
    g_buildingMenu = false;
    g_pendingMenu.menuId = g_nextMenuId++;
    g_pendingMenu.RebuildFilter();
    bool placed = false;
    if (g_pendingSelectEntry >= 0) {
        for (int pos = 0; pos < g_pendingMenu.GetFilteredCount(); pos++) {
            if (g_pendingMenu.GetFilteredEntryIndex(pos) == g_pendingSelectEntry) {
                g_pendingMenu.selectedIndex = pos;
                placed = true;
                break;
            }
        }
        g_pendingSelectEntry = -1;
    }
    if (!placed && !g_pendingMenu.hasSearch) {
        auto it = g_lastSelection.find(StackKey(g_menuStack.size(), g_pendingMenu.title));
        if (it != g_lastSelection.end()) g_pendingMenu.selectedIndex = it->second;
    }
    FixSelection(g_pendingMenu);
    g_menuStack.push_back(g_pendingMenu);
    g_activeMenuId = g_pendingMenu.menuId;
    FlushKeyStates();
    return 0;
}

// _ui_register_root(name, description, callbackId, icon)
static int __fastcall LuaUiRegisterRoot(lua_State* L) {
    MenuLock lock(g_menuMutex);
    RootEntry entry;
    entry.name = ReadStringArg(L, 1);
    entry.description = ReadStringArg(L, 2);
    entry.callbackId = (int)ReadNumberArg(L, 3);
    entry.icon = (unsigned int)ReadNumberArg(L, 4);
    g_rootEntries.push_back(entry);
    return 0;
}

static int __fastcall LuaUiClearRoots(lua_State* L) {
    MenuLock lock(g_menuMutex);
    g_rootEntries.clear();
    return 0;
}

// _ui_reset_to_root(selectIndex) — rebuilds the root (after a language change) and shows it.
static int __fastcall LuaUiResetToRoot(lua_State* L) {
    MenuLock lock(g_menuMutex);
    int sel = (int)ReadNumberArg(L, 1) - 1;
    g_menuStack.clear();
    g_lastSelection.clear();
    Menu root = BuildRoot();
    root.selectedIndex = ImMax(sel, 0);
    FixSelection(root);
    g_menuStack.push_back(root);
    g_activeMenuId = root.menuId;
    return 0;
}

static int __fastcall LuaUiSetLanguage(lua_State* L) {
    MenuLock lock(g_menuMutex);
    std::string code = ReadStringArg(L, 1);
    MenuRender::SetLanguage(code.c_str());
    if (!g_menuStack.empty() && g_menuStack.front().isRoot)
        g_menuStack.front().title = MenuRender::Text(MenuRender::Str::Home);
    return 0;
}

static std::string SettingsPath() {
    return Logger::GetGameDir() + "ScriptHook\\ScriptHook.ini";
}

// _ui_set_theme("dark" | "light") — the panel look; Lua saves the choice itself.
static int __fastcall LuaUiSetTheme(lua_State* L) {
    MenuLock lock(g_menuMutex);
    std::string code = ReadStringArg(L, 1);
    MenuRender::SetTheme(code.c_str());
    return 0;
}

// _ui_set_look(key, value) — "scale" ("90" | "100" | "115" | "130"), "side"
// ("left" | "right"), "motion" ("full" | "reduced"), "transparency" ("none" |
// "low" | "medium" | "high" | "max"); Lua saves the choice itself.
static int __fastcall LuaUiSetLook(lua_State* L) {
    MenuLock lock(g_menuMutex);
    std::string key = ReadStringArg(L, 1);
    std::string value = ReadStringArg(L, 2);
    MenuRender::SetLook(key.c_str(), value.c_str());
    return 0;
}

// The look is known before any Lua runs, so the first F4 already has it.
static void LoadLookSettings() {
    const std::string path = SettingsPath();
    char buf[32] = {};
    GetPrivateProfileStringA("Trainer", "Theme", "dark", buf, sizeof(buf), path.c_str());
    MenuRender::SetTheme(buf);
    GetPrivateProfileStringA("Trainer", "UiScale", "100", buf, sizeof(buf), path.c_str());
    MenuRender::SetLook("scale", buf);
    GetPrivateProfileStringA("Trainer", "PanelSide", "left", buf, sizeof(buf), path.c_str());
    MenuRender::SetLook("side", buf);
    GetPrivateProfileStringA("Trainer", "Motion", "full", buf, sizeof(buf), path.c_str());
    MenuRender::SetLook("motion", buf);
    GetPrivateProfileStringA("Trainer", "Transparency", "medium", buf, sizeof(buf), path.c_str());
    MenuRender::SetLook("transparency", buf);
}

// _ui_get_setting(key) — string from [Trainer] in ScriptHook.ini, nothing if absent.
static int __fastcall LuaUiGetSetting(lua_State* L) {
    std::string key = ReadStringArg(L, 1);
    if (key.empty()) return 0;
    char buf[256] = {};
    DWORD n = GetPrivateProfileStringA("Trainer", key.c_str(), "", buf, sizeof(buf), SettingsPath().c_str());
    if (n == 0) return 0;
    g_hks.lua_pushlstring(L, buf, n);
    return 1;
}

static int __fastcall LuaUiSetSetting(lua_State* L) {
    std::string key = ReadStringArg(L, 1);
    std::string value = ReadStringArg(L, 2);
    if (!key.empty())
        WritePrivateProfileStringA("Trainer", key.c_str(), value.c_str(), SettingsPath().c_str());
    return 0;
}

// _input_consume_mouse4() -> true once per Mouse 4 press
static int __fastcall LuaInputConsumeMouse4(lua_State* L) {
    uintptr_t Laddr = (uintptr_t)L;
    uintptr_t top = *(uintptr_t*)(Laddr + 72);
    uintptr_t limit = *(uintptr_t*)(Laddr + 88);
    if (top + 16 > limit)
        return 0;
    float v = InputBridge::ConsumeMouse4() ? 1.0f : 0.0f;
    *(int*)top = HKS_TNUMBER;
    *(float*)(top + 8) = v;
    *(uintptr_t*)(Laddr + 72) = top + 16;
    return 1;
}

static int __fastcall LuaInputPulseMelee(lua_State* L) {
    (void)L;
    InputBridge::RequestMeleePulse();
    return 0;
}

static int __fastcall LuaInputHasMouse4(lua_State* L) {
    uintptr_t Laddr = (uintptr_t)L;
    uintptr_t top = *(uintptr_t*)(Laddr + 72);
    uintptr_t limit = *(uintptr_t*)(Laddr + 88);
    if (top + 16 > limit)
        return 0;
    float v = InputBridge::HasInputApi() ? 1.0f : 0.0f;
    *(int*)top = HKS_TNUMBER;
    *(float*)(top + 8) = v;
    *(uintptr_t*)(Laddr + 72) = top + 16;
    return 1;
}

// _input_block_melee(frames) — keeps Q (melee) from the game for that many frames; 0 lets it through
static int __fastcall LuaInputBlockMelee(lua_State* L) {
    InputBridge::BlockMelee((int)ReadNumberArg(L, 1));
    return 0;
}

// _input_aim_held() -> 1 while the right mouse button (the game's aim) is held, else 0;
// read with the trainer menu open too, which leaves the game the mouse
static int __fastcall LuaInputAimHeld(lua_State* L) {
    uintptr_t Laddr = (uintptr_t)L;
    uintptr_t top = *(uintptr_t*)(Laddr + 72);
    uintptr_t limit = *(uintptr_t*)(Laddr + 88);
    if (top + 16 > limit)
        return 0;
    float v = InputBridge::IsAimHeld() ? 1.0f : 0.0f;
    *(int*)top = HKS_TNUMBER;
    *(float*)(top + 8) = v;
    *(uintptr_t*)(Laddr + 72) = top + 16;
    return 1;
}

// _input_melee_age() -> frames since Q (melee, the takedown input) last went
// down; a very large number until it first does
static int __fastcall LuaInputMeleeAge(lua_State* L) {
    uintptr_t Laddr = (uintptr_t)L;
    uintptr_t top = *(uintptr_t*)(Laddr + 72);
    uintptr_t limit = *(uintptr_t*)(Laddr + 88);
    if (top + 16 > limit)
        return 0;
    *(int*)top = HKS_TNUMBER;
    *(float*)(top + 8) = (float)InputBridge::MeleeAge();
    *(uintptr_t*)(Laddr + 72) = top + 16;
    return 1;
}

// _input_key_down(vk) -> 1 while that key (a Windows virtual-key code) is held,
// else 0; always 0 while a trainer UI is open or the game has no input
static int __fastcall LuaInputKeyDown(lua_State* L) {
    int vk = (int)ReadNumberArg(L, 1);
    uintptr_t Laddr = (uintptr_t)L;
    uintptr_t top = *(uintptr_t*)(Laddr + 72);
    uintptr_t limit = *(uintptr_t*)(Laddr + 88);
    if (top + 16 > limit)
        return 0;
    *(int*)top = HKS_TNUMBER;
    *(float*)(top + 8) = InputBridge::KeyDown(vk) ? 1.0f : 0.0f;
    *(uintptr_t*)(Laddr + 72) = top + 16;
    return 1;
}

// _ui_add_list_entry(entryIdx, text)
static int __fastcall LuaUiAddListEntry(lua_State* L) {
    MenuLock lock(g_menuMutex);
    if (!g_buildingMenu) return 0;
    int entryIdx = (int)ReadNumberArg(L, 1) - 1; // Lua 1-based
    if (entryIdx >= 0 && entryIdx < (int)g_pendingMenu.entries.size())
        g_pendingMenu.entries[entryIdx].listItems.push_back(ReadStringArg(L, 2));
    return 0;
}

// _ui_select_list_entry(entryIdx, itemIdx)
static int __fastcall LuaUiSelectListEntry(lua_State* L) {
    MenuLock lock(g_menuMutex);
    if (!g_buildingMenu) return 0;
    int entryIdx = (int)ReadNumberArg(L, 1) - 1;
    int itemIdx = (int)ReadNumberArg(L, 2) - 1;

    if (entryIdx >= 0 && entryIdx < (int)g_pendingMenu.entries.size()) {
        g_pendingMenu.entries[entryIdx].listSelectedIndex = itemIdx;
    }
    return 0;
}

// _ui_text_input(prompt, callbackId)
static int __fastcall LuaUiTextInput(lua_State* L) {
    MenuLock lock(g_menuMutex);
    g_textInputPrompt = ReadStringArg(L, 1);
    g_textInputCallbackId = (int)ReadNumberArg(L, 2);
    g_textInputBuf[0] = '\0';
    g_textInputActive = true;
    g_textInputFocus = true;
    return 0;
}

static MenuEntry* TopEntry(lua_State* L) {
    int entryIdx = (int)ReadNumberArg(L, 1) - 1;
    if (g_menuStack.empty()) return nullptr;
    auto& menu = g_menuStack.back();
    if (entryIdx < 0 || entryIdx >= (int)menu.entries.size()) return nullptr;
    return &menu.entries[entryIdx];
}

// _ui_set_enabled(entryIdx, enabled)
static int __fastcall LuaUiSetEnabled(lua_State* L) {
    MenuLock lock(g_menuMutex);
    if (MenuEntry* e = TopEntry(L)) e->enabled = ReadNumberArg(L, 2) != 0.0f;
    return 0;
}

// _ui_set_checked(entryIdx, checked) — for live updates from OnUpdate
static int __fastcall LuaUiSetChecked(lua_State* L) {
    MenuLock lock(g_menuMutex);
    if (MenuEntry* e = TopEntry(L)) e->checked = ReadNumberArg(L, 2) != 0.0f;
    return 0;
}

// _ui_update_entry(entryIdx, text)
static int __fastcall LuaUiUpdateEntry(lua_State* L) {
    MenuLock lock(g_menuMutex);
    if (MenuEntry* e = TopEntry(L)) e->label = ReadStringArg(L, 2);
    return 0;
}

// _ui_update_hint(entryIdx, text)
static int __fastcall LuaUiUpdateHint(lua_State* L) {
    MenuLock lock(g_menuMutex);
    if (MenuEntry* e = TopEntry(L)) e->hint = ReadStringArg(L, 2);
    return 0;
}

// _ui_update_icon(entryIdx, codepoint) — the icon font glyph of a row of the open menu
static int __fastcall LuaUiUpdateIcon(lua_State* L) {
    MenuLock lock(g_menuMutex);
    if (MenuEntry* e = TopEntry(L)) e->icon = (unsigned int)ReadNumberArg(L, 2);
    return 0;
}

// _ui_select_list_live(entryIdx, itemIdx) — moves a list of the open menu without firing its callback
static int __fastcall LuaUiSelectListLive(lua_State* L) {
    MenuLock lock(g_menuMutex);
    if (MenuEntry* e = TopEntry(L)) {
        int itemIdx = (int)ReadNumberArg(L, 2) - 1;
        if (itemIdx >= 0 && itemIdx < (int)e->listItems.size()) e->listSelectedIndex = itemIdx;
    }
    return 0;
}

// --- Lua bootstrap ---

static const char* MENU_BOOTSTRAP = R"(
_SH_callbacks = {}
_SH_nextCbId = 1

function _SH_storeCallback(fn)
    if not fn then return 0 end
    local id = _SH_nextCbId
    _SH_callbacks[id] = fn
    _SH_nextCbId = id + 1
    return id
end

-- A mod may set _SH_translate(text) -> text to localise menus it did not build.
function _SH_T(s)
    if type(s) ~= "string" or s == "" or _SH_translate == nil then return s end
    local ok, r = pcall(_SH_translate, s)
    if ok and type(r) == "string" then return r end
    return s
end

function _SH_pushMenuToCpp(menu)
    _ui_begin_menu(_SH_T(menu._title or ""))
    for i, entry in ipairs(menu._entries) do
        local label = tostring(entry.label or "")
        _ui_add_entry(
            _SH_T(label),
            entry.callbackId or 0,
            entry.typeInt or 0,
            entry.listCallbackId or 0,
            type(entry.value) == "string" and entry.value or "",
            _SH_T(entry.searchPlaceholder or ""),
            _SH_T(entry.hint or ""),
            (entry.submenu and 1 or 0) + (entry.checked and 2 or 0) + (entry.disabled and 4 or 0),
            entry.icon or 0,
            label
        )
        if entry.listItems then
            for _, item in ipairs(entry.listItems) do
                _ui_add_list_entry(i, _SH_T(tostring(item)))
            end
        end
        if entry.listSelectedIndex then
            _ui_select_list_entry(i, entry.listSelectedIndex)
        end
    end
    if menu._onUpdateId and menu._onUpdateId > 0 then
        _ui_set_on_update(menu._onUpdateId)
    end
    if menu._selected then
        _ui_set_selected(menu._selected)
    end
    _ui_end_menu()
    menu._shown = true
end

UI = {}

function UI.SimpleMenu()
    local menu = {
        _isMenu = true,
        _title = "",
        _entries = {},
        _onUpdateId = 0,
    }

    function menu:SetTitle(title)
        self._title = title
        return self
    end

    function menu:AddButton(label, callbackOrValue, callbackIfValue)
        local cb, val
        if callbackIfValue then
            -- AddButton(label, value, callback)
            val = callbackOrValue
            cb = callbackIfValue
        else
            -- AddButton(label, callback)
            cb = callbackOrValue
            val = nil
        end
        -- Wrap callback to receive (menu, label, value) like the game API
        local wrappedCb = cb
        if cb then
            local capturedLabel = label
            local capturedVal = val
            wrappedCb = function() return cb(nil, capturedLabel, capturedVal) end
        end
        local entry = {
            label = label,
            callbackId = _SH_storeCallback(wrappedCb),
            typeInt = 0,
            value = val,
        }
        table.insert(self._entries, entry)
        return #self._entries
    end

    function menu:AddSearch(label, placeholder)
        local entry = {
            label = label,
            callbackId = 0,
            typeInt = 3,
            searchPlaceholder = placeholder or "",
        }
        table.insert(self._entries, entry)
        return #self._entries
    end

    function menu:AddCheckbox(label, descOrCallback, callback)
        -- AddCheckbox(label, description, callback) or AddCheckbox(label, callback)
        local cb = callback or descOrCallback
        local entry = {
            label = label,
            callbackId = _SH_storeCallback(cb),
            typeInt = 1,
            hint = callback and type(descOrCallback) == "string" and descOrCallback or nil,
        }
        table.insert(self._entries, entry)
        return #self._entries
    end

    function menu:AddList(label, callback)
        local entry = {
            label = label,
            callbackId = 0,
            typeInt = 2,
            listCallbackId = _SH_storeCallback(callback),
            listItems = {},
            listSelectedIndex = 1,
        }
        table.insert(self._entries, entry)
        return #self._entries
    end

    -- Non-selectable caption that groups the rows below it.
    function menu:AddSection(label)
        table.insert(self._entries, { label = label, callbackId = 0, typeInt = 4 })
        return #self._entries
    end

    -- Description, icon (MDL2 code point) and submenu chevron of an entry, set before the menu is shown.
    function menu:Decorate(entryIdx, hint, icon, submenu)
        local e = self._entries[entryIdx]
        if e then
            if hint ~= nil then e.hint = hint end
            if icon ~= nil then e.icon = icon end
            if submenu ~= nil then e.submenu = submenu end
        end
        return entryIdx
    end

    function menu:AddListEntry(listIdx, text)
        if self._entries[listIdx] then
            table.insert(self._entries[listIdx].listItems, text)
        end
    end

    function menu:SelectListEntryByValue(listIdx, value)
        if self._entries[listIdx] and self._entries[listIdx].listItems then
            for i, v in ipairs(self._entries[listIdx].listItems) do
                if v == value then
                    self._entries[listIdx].listSelectedIndex = i
                    return
                end
            end
        end
    end

    -- The setters below change the starting state before the menu is shown and
    -- the open menu afterwards; the live calls only reach the menu on top.
    function menu:SelectListEntryLive(listIdx, itemIdx)
        local e = self._entries[listIdx]
        if e and e.listItems and e.listItems[itemIdx] ~= nil then e.listSelectedIndex = itemIdx end
        if self._shown then _ui_select_list_live(listIdx, itemIdx) end
    end

    function menu:SetChecked(entryIdx, checked)
        local e = self._entries[entryIdx]
        if e then e.checked = checked and true or false end
        if self._shown then _ui_set_checked(entryIdx, checked and 1 or 0) end
    end

    function menu:SetSelected(entryIdx)
        self._selected = entryIdx
    end

    function menu:SetEntryEnabled(entryIdx, enabled)
        local e = self._entries[entryIdx]
        if e then e.disabled = not enabled end
        if self._shown then _ui_set_enabled(entryIdx, enabled and 1 or 0) end
    end

    function menu:SetEntryText(entryId, text)
        if self._entries[entryId] then
            self._entries[entryId].label = text
        end
        if self._shown then _ui_update_entry(entryId, _SH_T(tostring(text))) end
    end

    function menu:SetEntryHint(entryId, text)
        if self._entries[entryId] then
            self._entries[entryId].hint = text
        end
        if self._shown then _ui_update_hint(entryId, _SH_T(tostring(text))) end
    end

    function menu:SetEntryIcon(entryId, icon)
        if self._entries[entryId] then
            self._entries[entryId].icon = icon
        end
        if self._shown then _ui_update_icon(entryId, icon or 0) end
    end

    function menu:OnUpdate(fn)
        self._onUpdateId = _SH_storeCallback(fn)
    end

    return menu
end

TrainerMenuItems = {}

function UI.SimpleTextInput(prompt, callback)
    local cbId = _SH_storeCallback(function(success, text)
        if callback then callback(success, text) end
    end)
    _ui_text_input(_SH_T(prompt or ""), cbId)
end

-- Root items: { name, description, builder, icon = code point }; name and
-- description may be functions so a language switch can re-register them.
function _SH_finalizeMenus()
    _ui_clear_roots()
    for _, item in ipairs(TrainerMenuItems) do
        local name, desc = item[1], item[2]
        if type(name) == "function" then name = name() end
        if type(desc) == "function" then desc = desc() end
        if item._cbId == nil then item._cbId = _SH_storeCallback(item[3]) end
        _ui_register_root(_SH_T(tostring(name or "")), _SH_T(tostring(desc or "")), item._cbId, item.icon or 0)
    end
end
)";

// --- Public API ---

void MenuSystem::Init(lua_State* L) {
    {
        MenuLock lock(g_menuMutex);
        g_L = L;
        g_ready = false;
        g_open = false;
        g_rootEntries.clear();
        g_menuStack.clear();
        g_lastSelection.clear();
    }

    auto reg = [&](const char* name, lua_CFunction fn) {
        g_hks.hks_pushcclosure(L, fn, 0, name, 1, 0);
        g_hks.lua_setfield(L, HKS_GLOBALSINDEX, name);
    };

    reg("_ui_begin_menu", LuaUiBeginMenu);
    reg("_ui_add_entry", LuaUiAddEntry);
    reg("_ui_set_on_update", LuaUiSetOnUpdate);
    reg("_ui_end_menu", LuaUiEndMenu);
    reg("_ui_set_selected", LuaUiSetSelected);
    reg("_ui_register_root", LuaUiRegisterRoot);
    reg("_ui_clear_roots", LuaUiClearRoots);
    reg("_ui_reset_to_root", LuaUiResetToRoot);
    reg("_ui_set_language", LuaUiSetLanguage);
    reg("_ui_set_theme", LuaUiSetTheme);
    reg("_ui_set_look", LuaUiSetLook);
    LoadLookSettings();
    reg("_ui_get_setting", LuaUiGetSetting);
    reg("_ui_set_setting", LuaUiSetSetting);
    reg("_ui_add_list_entry", LuaUiAddListEntry);
    reg("_ui_select_list_entry", LuaUiSelectListEntry);
    reg("_ui_select_list_live", LuaUiSelectListLive);
    reg("_ui_set_checked", LuaUiSetChecked);
    reg("_ui_set_enabled", LuaUiSetEnabled);
    reg("_ui_text_input", LuaUiTextInput);
    reg("_ui_update_entry", LuaUiUpdateEntry);
    reg("_ui_update_hint", LuaUiUpdateHint);
    reg("_ui_update_icon", LuaUiUpdateIcon);
    reg("_input_consume_mouse4", LuaInputConsumeMouse4);
    reg("_input_pulse_melee", LuaInputPulseMelee);
    reg("_input_has_mouse4", LuaInputHasMouse4);
    reg("_input_aim_held", LuaInputAimHeld);
    reg("_input_melee_age", LuaInputMeleeAge);
    reg("_input_key_down", LuaInputKeyDown);
    reg("_input_block_melee", LuaInputBlockMelee);

    if (g_hks.luaL_loadbuffer(L, MENU_BOOTSTRAP, strlen(MENU_BOOTSTRAP), "menu_bootstrap") == 0) {
        if (g_hks.lua_pcall(L, 0, 0, 0) != 0) {
            Logger::Log("WARNING: Menu bootstrap failed");
        }
    } else {
        Logger::Log("WARNING: Menu bootstrap load failed");
    }
}

void MenuSystem::Finalize(lua_State* L) {
    const char* code = "if _SH_finalizeMenus then _SH_finalizeMenus() end";
    if (g_hks.luaL_loadbuffer(L, code, strlen(code), "menu_finalize") == 0) {
        g_hks.lua_pcall(L, 0, 0, 0);
    }
    g_ready = true;
    Logger::Verbose("Menu system: %zu root entries registered", g_rootEntries.size());
}

void MenuSystem::PrepareForReload() {
    MenuLock lock(g_menuMutex);
    g_open = false;
    g_ready = false;
    g_textInputActive = false;
    g_menuStack.clear();
    g_lastSelection.clear();
}

bool MenuSystem::IsOpen() {
    MenuLock lock(g_menuMutex);
    return g_open && !g_menuStack.empty();
}
bool MenuSystem::IsReady() { return g_ready; }
bool MenuSystem::IsTextInputActive() { return g_textInputActive; }

static const int RepeatKeys[] = { VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT, VK_PRIOR, VK_NEXT };

struct KeyRepeat { bool down = false; DWORD next = 0; };
static KeyRepeat g_repeat[IM_ARRAYSIZE(RepeatKeys)];

static void FlushKeyStates() {
    // Consume stale key presses so they don't trigger on menu open
    GetAsyncKeyState(VK_RETURN);
    GetAsyncKeyState(VK_BACK);
    GetAsyncKeyState(VK_ESCAPE);
    GetAsyncKeyState(VK_HOME);
    GetAsyncKeyState(VK_END);
    GetAsyncKeyState(VK_F4);
    for (int i = 0; i < IM_ARRAYSIZE(RepeatKeys); i++) {
        GetAsyncKeyState(RepeatKeys[i]);
        g_repeat[i].down = (GetAsyncKeyState(RepeatKeys[i]) & 0x8000) != 0;
        g_repeat[i].next = GetTickCount() + 400;
    }
    for (int k = 'A'; k <= 'Z'; k++) GetAsyncKeyState(k);
    for (int k = '0'; k <= '9'; k++) GetAsyncKeyState(k);
    GetAsyncKeyState(VK_SPACE);
    GetAsyncKeyState(VK_OEM_MINUS);
    GetAsyncKeyState(VK_OEM_PERIOD);
}

// Fires on press, then repeats while held: after 380 ms, every 55 ms.
static bool KeyFired(int slot) {
    SHORT st = GetAsyncKeyState(RepeatKeys[slot]);
    bool held = (st & 0x8000) != 0;
    bool tapped = (st & 1) != 0;
    KeyRepeat& r = g_repeat[slot];
    DWORD now = GetTickCount();
    if (!held) {
        bool fire = tapped && !r.down;
        r.down = false;
        return fire;
    }
    if (!r.down) {
        r.down = true;
        r.next = now + 380;
        return true;
    }
    if ((LONG)(now - r.next) >= 0) {
        r.next = now + 55;
        return true;
    }
    return false;
}

void MenuSystem::Toggle() {
    MenuLock lock(g_menuMutex);
    g_open = !g_open;
    if (!g_open) return;
    g_openedAt = ImGui::GetTime();
    FlushKeyStates();
    if (g_menuStack.empty()) {
        Menu root = BuildRoot();
        g_menuStack.push_back(root);
        g_activeMenuId = root.menuId;
    }
}

static void SearchAppendChar(Menu& menu, char ch) {
    size_t len = strlen(menu.searchBuffer);
    if (len < sizeof(menu.searchBuffer) - 1) {
        menu.searchBuffer[len] = ch;
        menu.searchBuffer[len + 1] = '\0';
        menu.RebuildFilter();
        menu.selectedIndex = 0;
        FixSelection(menu);
    }
}

static void FinishTextInput(bool success) {
    if (!g_textInputActive) return;
    g_textInputActive = false;

    int cbId = g_textInputCallbackId;
    std::string text = g_textInputBuf;
    g_textInputCallbackId = 0;

    Hooks::QueueLuaCall([cbId, success, text]() {
        char code[512];
        if (success) {
            // Escape quotes in the text
            std::string escaped = text;
            for (size_t i = 0; i < escaped.size(); i++) {
                if (escaped[i] == '"' || escaped[i] == '\\') {
                    escaped.insert(i, 1, '\\');
                    i++;
                }
            }
            snprintf(code, sizeof(code),
                "local fn = _SH_callbacks[%d]; if fn then fn(true, \"%s\") end",
                cbId, escaped.c_str());
        } else {
            snprintf(code, sizeof(code),
                "local fn = _SH_callbacks[%d]; if fn then fn(false, \"\") end", cbId);
        }
        RunLuaCode(code, "text_input_cb");
    });

    FlushKeyStates();
}

void MenuSystem::HandleInput() {
    MenuLock lock(g_menuMutex);
    if (!g_open) return;

    // Text input dialog takes priority
    if (g_textInputActive) {
        if (GetAsyncKeyState(VK_ESCAPE) & 1) {
            FinishTextInput(false);
        }
        // Enter is handled by ImGui InputText callback
        return;
    }

    // F4 also closes
    if (GetAsyncKeyState(VK_F4) & 1) {
        g_open = false;
        return;
    }

    if (g_menuStack.empty()) return;
    auto& menu = g_menuStack.back();

    // Backspace — search delete or menu back
    if (GetAsyncKeyState(VK_BACK) & 1) {
        if (menu.hasSearch && menu.searchBuffer[0] != '\0') {
            menu.searchBuffer[strlen(menu.searchBuffer) - 1] = '\0';
            menu.RebuildFilter();
            menu.selectedIndex = 0;
            FixSelection(menu);
        } else if (g_menuStack.size() > 1) {
            PopMenu();
        } else {
            g_open = false;
        }
        return;
    }

    // Escape also closes/goes back
    if (GetAsyncKeyState(VK_ESCAPE) & 1) {
        if (g_menuStack.size() > 1) {
            PopMenu();
        } else {
            g_open = false;
        }
        return;
    }

    // Search typing — only letters, digits, space, and common punctuation
    if (menu.hasSearch) {
        for (int key = 'A'; key <= 'Z'; key++) {
            if (GetAsyncKeyState(key) & 1) {
                char ch = (GetAsyncKeyState(VK_SHIFT) & 0x8000) ? (char)key : (char)(key + 32);
                SearchAppendChar(menu, ch);
            }
        }
        for (int key = '0'; key <= '9'; key++) {
            if (GetAsyncKeyState(key) & 1)
                SearchAppendChar(menu, (char)key);
        }
        if (GetAsyncKeyState(VK_SPACE) & 1)
            SearchAppendChar(menu, ' ');
        if (GetAsyncKeyState(VK_OEM_MINUS) & 1)
            SearchAppendChar(menu, '-');
        if (GetAsyncKeyState(VK_OEM_PERIOD) & 1)
            SearchAppendChar(menu, '.');
    }

    // Navigation
    bool up = KeyFired(0), down = KeyFired(1), left = KeyFired(2), right = KeyFired(3);
    bool pageUp = KeyFired(4), pageDown = KeyFired(5);
    bool home = (GetAsyncKeyState(VK_HOME) & 1) != 0, end = (GetAsyncKeyState(VK_END) & 1) != 0;

    int count = menu.GetFilteredCount();
    if (count == 0) return;
    FixSelection(menu);

    if (up) menu.selectedIndex = NextSelectable(menu, menu.selectedIndex, -1, true);
    if (down) menu.selectedIndex = NextSelectable(menu, menu.selectedIndex, 1, true);
    for (int i = 0; i < 8 && pageUp; i++) menu.selectedIndex = NextSelectable(menu, menu.selectedIndex, -1, false);
    for (int i = 0; i < 8 && pageDown; i++) menu.selectedIndex = NextSelectable(menu, menu.selectedIndex, 1, false);
    if (home) menu.selectedIndex = NextSelectable(menu, -1, 1, false);
    if (end) menu.selectedIndex = NextSelectable(menu, count, -1, false);
    FixSelection(menu);

    int realIdx = menu.GetFilteredEntryIndex(menu.selectedIndex);
    if (realIdx < 0 || menu.entries[realIdx].type == EntryType::Header) return;
    auto& entry = menu.entries[realIdx];

    if (GetAsyncKeyState(VK_RETURN) & 1) {
        if (entry.enabled) {
            // Checkbox: Lua owns state; OnUpdate syncs entry.checked (avoid double-toggle desync).
            if (entry.type == EntryType::List && !entry.listItems.empty()) {
                // Enter steps to the next value and wraps round: a deliberate cycle,
                // as it always was. Only the arrows stop at the ends (below).
                entry.listSelectedIndex = (entry.listSelectedIndex + 1) % (int)entry.listItems.size();
                ExecuteListCallback(entry.listCallbackId, entry.listSelectedIndex + 1,
                    entry.listItems[entry.listSelectedIndex]);
            } else {
                ExecuteCallback(entry.callbackId);
            }
        }
    }

    if (entry.enabled && entry.type == EntryType::List && !entry.listItems.empty() && (left || right)) {
        int n = (int)entry.listItems.size();
        int next = entry.listSelectedIndex + (right ? 1 : -1);
        // A list stops at its ends: wrapping round turned 0.12 into 0.00 (2026-10-21).
        if (next >= 0 && next < n) {
            entry.listSelectedIndex = next;
            ExecuteListCallback(entry.listCallbackId, entry.listSelectedIndex + 1,
                entry.listItems[entry.listSelectedIndex]);
        }
    } else if (entry.enabled && right && entry.submenu && entry.type == EntryType::Button) {
        ExecuteCallback(entry.callbackId);
    } else if (left && g_menuStack.size() > 1 && entry.type != EntryType::List) {
        PopMenu();
    }
}

// --- Rendering (drawing itself lives in menu_render.cpp) ---

namespace {
    struct Toast { std::string text; double born; };
    std::mutex g_toastMutex;
    std::vector<Toast> g_toasts;
    constexpr double ToastLife = 5.0;
}

void MenuSystem::PushToast(const std::string& text) {
    std::lock_guard<std::mutex> lock(g_toastMutex);
    g_toasts.push_back({ text, -1.0 });
    if (g_toasts.size() > 8) g_toasts.erase(g_toasts.begin());
}

bool MenuSystem::WantsGlass() {
    // a solid panel ("Transparency: none") needs no copy of the frame
    if (!MenuRender::UsesGlass()) return false;
    if (IsOpen()) return true;
    std::lock_guard<std::mutex> lock(g_toastMutex);
    return !g_toasts.empty();
}

static int TextInputCallback(ImGuiInputTextCallbackData*) { return 0; }

void MenuSystem::Render() {
    MenuLock lock(g_menuMutex);
    if (g_menuStack.empty()) return;
    auto& menu = g_menuStack.back();

    CallOnUpdate(menu.onUpdateId);

    std::vector<std::string> crumbs;
    for (size_t i = 0; i + 1 < g_menuStack.size(); i++)
        crumbs.push_back(g_menuStack[i].title);
    MenuRender::DrawMenu(menu, crumbs, g_openedAt);

    if (!g_textInputActive) return;

    // Text input: a card in the panel's colours, the ImGui field on it.
    ImGuiIO& io = ImGui::GetIO();
    const float s = MenuRender::Scale();
    ImFont* body = UiFonts::Body ? UiFonts::Body : ImGui::GetFont();
    ImFont* semi = UiFonts::Semibold ? UiFonts::Semibold : body;
    const float w = 440.0f * s;

    ImGui::SetNextWindowPos(ImVec2(io.DisplaySize.x * 0.5f, io.DisplaySize.y * 0.42f), ImGuiCond_Always, ImVec2(0.5f, 0.5f));
    ImGui::SetNextWindowSize(ImVec2(w, 0), ImGuiCond_Always);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(22.0f * s, 20.0f * s));
    ImGui::PushStyleVar(ImGuiStyleVar_WindowRounding, 12.0f * s);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1.0f * s);
    ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 6.0f * s);
    ImGui::PushStyleVar(ImGuiStyleVar_FramePadding, ImVec2(12.0f * s, 9.0f * s));
    // The panel's colours: #121315 or #F4F2ED, the accent for the selected text.
    if (MenuRender::IsLight()) {
        ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.957f, 0.949f, 0.929f, 0.98f));
        ImGui::PushStyleColor(ImGuiCol_Border, ImVec4(0.0f, 0.0f, 0.0f, 0.11f));
        ImGui::PushStyleColor(ImGuiCol_FrameBg, ImVec4(0.0f, 0.0f, 0.0f, 0.045f));
        ImGui::PushStyleColor(ImGuiCol_FrameBgHovered, ImVec4(0.0f, 0.0f, 0.0f, 0.06f));
        ImGui::PushStyleColor(ImGuiCol_FrameBgActive, ImVec4(0.0f, 0.0f, 0.0f, 0.07f));
        ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.086f, 0.090f, 0.102f, 1.0f));
        ImGui::PushStyleColor(ImGuiCol_TextDisabled, ImVec4(0.388f, 0.400f, 0.431f, 1.0f));
        ImGui::PushStyleColor(ImGuiCol_TextSelectedBg, ImVec4(0.0f, 0.373f, 0.722f, 0.30f));
    } else {
        ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.071f, 0.075f, 0.082f, 0.98f));
        ImGui::PushStyleColor(ImGuiCol_Border, ImVec4(1.0f, 1.0f, 1.0f, 0.11f));
        ImGui::PushStyleColor(ImGuiCol_FrameBg, ImVec4(1.0f, 1.0f, 1.0f, 0.06f));
        ImGui::PushStyleColor(ImGuiCol_FrameBgHovered, ImVec4(1.0f, 1.0f, 1.0f, 0.08f));
        ImGui::PushStyleColor(ImGuiCol_FrameBgActive, ImVec4(1.0f, 1.0f, 1.0f, 0.10f));
        ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.953f, 0.953f, 0.953f, 1.0f));
        ImGui::PushStyleColor(ImGuiCol_TextDisabled, ImVec4(0.561f, 0.573f, 0.596f, 1.0f));
        ImGui::PushStyleColor(ImGuiCol_TextSelectedBg, ImVec4(0.376f, 0.804f, 1.0f, 0.35f));
    }
    ImGui::PushStyleColor(ImGuiCol_NavCursor, ImVec4(0, 0, 0, 0));
    ImGui::Begin("##TextInput", nullptr,
        ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove |
        ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings);

    ImGui::PushFont(semi, 18.0f * s);
    ImGui::PushTextWrapPos(w - 26.0f * s);
    ImGui::TextUnformatted(g_textInputPrompt.c_str());
    ImGui::PopTextWrapPos();
    ImGui::PopFont();
    ImGui::Dummy(ImVec2(0, 6.0f * s));

    if (g_textInputFocus) {
        ImGui::SetKeyboardFocusHere();
        g_textInputFocus = false;
    }

    ImGui::PushFont(body, 18.0f * s);
    ImGui::SetNextItemWidth(-1.0f);
    if (ImGui::InputText("##textinput", g_textInputBuf, sizeof(g_textInputBuf),
        ImGuiInputTextFlags_EnterReturnsTrue, TextInputCallback)) {
        FinishTextInput(true);
    }
    ImGui::PopFont();

    ImGui::Dummy(ImVec2(0, 4.0f * s));
    ImGui::PushFont(body, 14.0f * s);
    ImGui::TextDisabled("%s", MenuRender::Text(MenuRender::Str::InputHint));
    ImGui::PopFont();

    ImGui::End();
    ImGui::PopStyleColor(9);
    ImGui::PopStyleVar(5);
}

void MenuSystem::RenderToasts() {
    std::vector<MenuRender::ToastView> list;
    double now = ImGui::GetTime();
    {
        std::lock_guard<std::mutex> lock(g_toastMutex);
        for (auto& toast : g_toasts)
            if (toast.born < 0.0) toast.born = now;
        g_toasts.erase(std::remove_if(g_toasts.begin(), g_toasts.end(),
            [now](const Toast& x) { return now - x.born > ToastLife; }), g_toasts.end());
        for (const auto& toast : g_toasts)
            list.push_back({ toast.text, toast.born });
    }
    MenuRender::DrawToasts(list, now, ToastLife);
}
