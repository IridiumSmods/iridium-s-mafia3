#pragma once

#include "hks_types.h"
#include <functional>

namespace Hooks {
    bool Install();
    void Remove();
    bool IsGameThread();
    void QueueLuaCall(std::function<void()> fn);

    // Install() failed: the game functions were not found, most likely after a
    // game update the byte patterns no longer fit. The Lua mods never start, so
    // the overlay says so on screen (d3d.cpp), not only in ScriptHook.log.
    void MarkInstallFailed();
    bool InstallFailed();
}
