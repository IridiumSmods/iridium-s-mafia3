#pragma once

#include "menu_system.h"
#include <string>
#include <vector>

// Drawing of the F4 menu and its notices. Kept apart from MenuSystem so the
// offline preview tool can render the same panel over a screenshot.
namespace MenuRender {
    struct ToastView {
        std::string text;
        double born;
    };

    // Strings drawn by the renderer itself (name, footer, search, empty states).
    // RootTitle and Brand: "IRIDIUM S" and "Trainer M3".
    enum class Str {
        RootTitle, Brand, Select, Ok, Value, Back, Close, Search, NothingFound, Empty, InputHint, Home, Count
    };

    // "en", "de", "es", "fr", "it", "pt", "pl", "tr", "cs"; English until set,
    // other codes fall back to English.
    void SetLanguage(const char* code);
    const char* Text(Str id);

    // "dark" (default) or "light".
    void SetTheme(const char* code);
    bool IsLight();
    // "scale": interface size in percent (80-150, default 100); "side": "left" or
    // "right"; "motion": "full" or "reduced" (no slides, quick fades);
    // "transparency": "none" (solid), "low", "medium" (default), "high", "max".
    void SetLook(const char* key, const char* value);
    // False when the panel is solid: the frame need not be copied and blurred.
    bool UsesGlass();
    // UI scale now: 1.0 at 1080p, times the interface size.
    float Scale();

    // crumbs: titles of the menus under the top one, outermost first.
    void DrawMenu(Menu& menu, const std::vector<std::string>& crumbs, double openedAt);
    void DrawToasts(const std::vector<ToastView>& toasts, double now, double life);
}
