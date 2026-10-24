#pragma once
#include <Windows.h>

DWORD D3DThread();

namespace Gui {
    void Render();
    void AddToConsole(const char* fmt, ...);
    void FocusInput();
}
