#pragma once

#include <string>

namespace Settings {
    void Load(const std::string& gameDir);

    bool ConsoleWindow();   // Show external console window (default: true)
    bool VerboseLogging();  // Verbose log output (default: false)
}
