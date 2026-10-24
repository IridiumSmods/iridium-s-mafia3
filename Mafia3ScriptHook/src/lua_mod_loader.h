#pragma once

#include "hks_types.h"
#include <string>
#include <vector>

namespace ModLoader {
    void OnLuaStateReady(lua_State* L);
    void Tick();
    void ReloadAll();
    void RequestReloadAll();
    void ReloadMod(const std::string& modName);
    void RequestReloadMod(const std::string& modName);
    void PollReloadRequest();
    std::vector<std::string> GetLoadedMods();
}
