#pragma once

#include <cstdint>

namespace Scanner {
    // Scan the main module for a byte pattern with ?? wildcards
    // Returns absolute address or 0 if not found
    uintptr_t Find(const char* pattern);

    // Scan within a specific address range
    uintptr_t Find(const char* pattern, uintptr_t start, size_t size);

    // Find a pattern, then walk backward to find the function entry point
    // (looks for CC CC padding before the prologue)
    uintptr_t FindFunctionEntry(const char* innerPattern);

    // Same but starts searching from a specific address
    uintptr_t FindFunctionEntry(const char* innerPattern, uintptr_t searchFrom);
}
