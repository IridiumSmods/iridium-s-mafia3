#pragma once

#include "hks_types.h"
#include <string>
#include <vector>

// Header is a non-selectable section caption; navigation skips it.
enum class EntryType { Button, Checkbox, List, Search, Header };

struct MenuEntry {
    std::string label;
    std::string value;     // Optional value passed to callback (3-arg AddButton)
    std::string hint;      // Description of the item, shown while it is selected
    std::string iconKey;   // Untranslated label, used to pick an icon when none is given
    unsigned int icon = 0; // Segoe MDL2 code point, 0 = derive from iconKey/label
    bool submenu = false;  // Opens another menu: drawn with a chevron
    int callbackId = 0;
    EntryType type = EntryType::Button;
    bool enabled = true;

    // Checkbox
    bool checked = false;

    // List
    std::vector<std::string> listItems;
    int listSelectedIndex = 0;
    int listCallbackId = 0;

    // Search
    std::string searchPlaceholder;
};

struct Menu {
    std::string title;
    std::vector<MenuEntry> entries;
    int selectedIndex = 0;
    int onUpdateId = 0;
    int menuId = 0; // Unique ID to prevent cross-menu updates
    float scroll = 0.0f; // First visible row, eased toward the selection
    bool isRoot = false;

    // Search state
    bool hasSearch = false;
    char searchBuffer[128] = {};
    std::vector<int> filteredIndices; // Indices into entries that match filter

    void RebuildFilter();
    int GetFilteredEntryIndex(int filteredPos) const;
    int GetFilteredCount() const;
    bool IsSelectable(int filteredPos) const;
};

namespace MenuSystem {
    void Init(lua_State* L);
    void Finalize(lua_State* L);
    void Render();
    void HandleInput();
    bool IsOpen();
    bool IsReady();
    bool IsTextInputActive();
    void Toggle();
    void PrepareForReload();

    // Short notices from Lua, drawn under the menu (thread-safe).
    void PushToast(const std::string& text);
    void RenderToasts();
    bool WantsGlass();
}
