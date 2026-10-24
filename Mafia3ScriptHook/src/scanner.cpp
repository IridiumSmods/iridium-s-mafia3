#include "scanner.h"
#include <Windows.h>
#include <vector>
#include <cstring>

struct PatternByte {
    uint8_t value;
    bool wildcard;
};

static std::vector<PatternByte> ParsePattern(const char* pattern) {
    std::vector<PatternByte> bytes;
    const char* p = pattern;
    while (*p) {
        while (*p == ' ') p++;
        if (!*p) break;

        if (p[0] == '?' && p[1] == '?') {
            bytes.push_back({ 0, true });
            p += 2;
        } else {
            char hex[3] = { p[0], p[1], 0 };
            bytes.push_back({ (uint8_t)strtoul(hex, nullptr, 16), false });
            p += 2;
        }
    }
    return bytes;
}

uintptr_t Scanner::Find(const char* pattern, uintptr_t start, size_t size) {
    auto bytes = ParsePattern(pattern);
    if (bytes.empty()) return 0;

    size_t patLen = bytes.size();
    const uint8_t* data = (const uint8_t*)start;

    for (size_t i = 0; i <= size - patLen; i++) {
        bool match = true;
        for (size_t j = 0; j < patLen; j++) {
            if (!bytes[j].wildcard && data[i + j] != bytes[j].value) {
                match = false;
                break;
            }
        }
        if (match) return start + i;
    }
    return 0;
}

uintptr_t Scanner::FindFunctionEntry(const char* innerPattern, uintptr_t searchFrom) {
    HMODULE mod = GetModuleHandleA("Mafia3DefinitiveEdition.exe");
    if (!mod) mod = GetModuleHandleA(nullptr);
    auto* dos = (IMAGE_DOS_HEADER*)mod;
    auto* nt = (IMAGE_NT_HEADERS*)((uint8_t*)mod + dos->e_lfanew);
    auto* section = IMAGE_FIRST_SECTION(nt);
    for (int i = 0; i < nt->FileHeader.NumberOfSections; i++, section++) {
        if (memcmp(section->Name, ".text", 5) == 0) {
            uintptr_t start = (uintptr_t)mod + section->VirtualAddress;
            size_t totalSize = section->Misc.VirtualSize;
            size_t offset = (searchFrom > start) ? (searchFrom - start) : 0;
            uintptr_t match = Find(innerPattern, start + offset, totalSize - offset);
            if (!match) return 0;
            const uint8_t* p = (const uint8_t*)match;
            for (int j = 1; j < 1024; j++) {
                if (p[-j] == 0xCC && p[-j - 1] == 0xCC)
                    return (uintptr_t)(p - j + 1);
            }
            return 0;
        }
    }
    return 0;
}

uintptr_t Scanner::FindFunctionEntry(const char* innerPattern) {
    uintptr_t match = Find(innerPattern);
    if (!match) return 0;

    // Walk backward looking for at least 2 consecutive CC bytes (int3 padding)
    // The function entry is the first non-CC byte after the padding
    const uint8_t* p = (const uint8_t*)match;
    for (int i = 1; i < 1024; i++) {
        if (p[-i] == 0xCC && p[-i - 1] == 0xCC) {
            // Found CC CC padding — function starts at p[-i+1]
            return (uintptr_t)(p - i + 1);
        }
    }
    return 0;
}

uintptr_t Scanner::Find(const char* pattern) {
    HMODULE mod = GetModuleHandleA("Mafia3DefinitiveEdition.exe");
    if (!mod) mod = GetModuleHandleA(nullptr);

    auto* dos = (IMAGE_DOS_HEADER*)mod;
    auto* nt = (IMAGE_NT_HEADERS*)((uint8_t*)mod + dos->e_lfanew);
    auto* section = IMAGE_FIRST_SECTION(nt);

    // Scan .text section only
    for (int i = 0; i < nt->FileHeader.NumberOfSections; i++, section++) {
        if (memcmp(section->Name, ".text", 5) == 0) {
            uintptr_t start = (uintptr_t)mod + section->VirtualAddress;
            size_t size = section->Misc.VirtualSize;
            return Find(pattern, start, size);
        }
    }

    // Fallback: scan entire image
    uintptr_t base = (uintptr_t)mod;
    size_t imageSize = nt->OptionalHeader.SizeOfImage;
    return Find(pattern, base, imageSize);
}
