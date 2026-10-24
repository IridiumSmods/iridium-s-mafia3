#pragma once

#include <string>

namespace Logger {
    void Init(const std::string& gameDir);
    void Log(const char* fmt, ...);      // Always shown
    void Verbose(const char* fmt, ...);  // Only in verbose mode
    void Close();

    const std::string& GetGameDir();
}
