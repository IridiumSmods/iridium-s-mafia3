#pragma once

#include <cstdint>
#include <cstddef>

typedef void* lua_State;
typedef int(__fastcall* lua_CFunction)(lua_State* L);

// Function pointer typedefs
typedef __int64(__fastcall* ResetState_fn)(void* thisPtr, char async, uint64_t timeout);
typedef __int64(__fastcall* Tick_fn)(__int64 a1);
typedef int(__fastcall* luaL_loadfile_fn)(lua_State* L, const char* filename);
typedef int(__fastcall* lua_pcall_fn)(lua_State* L, int nargs, int nresults, int errfunc);
typedef int(__fastcall* luaL_loadbuffer_fn)(lua_State* L, const char* buff, size_t sz, const char* name);
typedef void(__fastcall* hks_pushcclosure_fn)(lua_State* L, lua_CFunction fn, int nupvalues, const char* debugname, int unk1, int unk2);
typedef void(__fastcall* hksi_lua_setfield_fn)(lua_State* L, int idx, const char* k);
typedef void(__fastcall* hksi_lua_pushlstring_fn)(lua_State* L, const char* s, size_t len);
typedef const char*(__fastcall* luaL_checklstring_fn)(lua_State* L, int narg, size_t* len);
typedef const char*(__fastcall* hks_obj_tolstring_fn)(lua_State* L, void* obj, size_t* len);

// C_ScriptMachine lua_State offset
constexpr uintptr_t LUA_STATE_OFFSET = 0xD0;

// HavokScript globals index (standard Lua 5.1 value)
constexpr int HKS_GLOBALSINDEX = -10002;

// AOB patterns for version-independent function resolution
// ?? = wildcard byte (matches anything, used for relative offsets)
namespace Patterns {
    // C_ScriptGameMachine::ResetState — calls base ResetState, compares result to 3
    constexpr const char* GameResetState =
        "48 89 5C 24 08 57 48 83 EC 20 48 8B F9 E8 ?? ?? ?? ?? 8B D8 83 F8 03 75";

    // C_ScriptMachine::Tick — reads lua_State from this+0xD0, calls hks_tick
    constexpr const char* ScriptMachineTick =
        "40 53 48 83 EC 20 48 8B D9 48 8B 89 D0 00 00 00 48 85 C9 74";

    // C_ScriptMachine::ResetState — large function with distinctive prologue
    constexpr const char* ScriptMachineResetState =
        "48 8B C4 57 41 54 41 55 41 56 41 57 48 81 EC 10 01 00 00 48 C7 44 24 40 FE FF FF FF";

    // hksi_lua_pcall — saves many registers, movsxd r14, edx
    constexpr const char* HksiLuaPcall =
        "48 89 5C 24 18 55 56 57 41 54 41 55 41 56 41 57 48 83 EC 50 4C 63 F2";

    // luaL_loadfile — tail: mov rdx,[rbx+10h] / mov r8,rdi / add rdx,558h
    // Use FindFunctionEntry to walk back to the prologue
    constexpr const char* LuaLLoadfileInner =
        "48 8B 53 10 4C 8B C7 48 81 C2 58 05 00 00";

    // luaL_loadbuffer — tail: add rdx,558h / mov [rsp+20h],rdi / mov r8,rbp / mov rcx,rbx / call / restore rbx from [rsp+40h]
    constexpr const char* LuaLLoadbufferInner =
        "48 81 C2 58 05 00 00 48 89 7C 24 20 4C 8B C5 48 8B CB E8 ?? ?? ?? ?? 48 8B 5C 24 40";

    // hksi_hks_pushcclosure — 4+3 register saves with 40h stack, movsxd
    constexpr const char* HksPushcclosure =
        "48 89 5C 24 08 48 89 6C 24 10 48 89 74 24 18 48 89 7C 24 20 41 54 41 56 41 57 48 83 EC 40 49 63";

    // hksi_lua_setfield — reads [rcx+48h], lea [rcx+20h], cmp with [rbx+58h]
    constexpr const char* HksiLuaSetfield =
        "48 89 5C 24 08 48 89 6C 24 10 48 89 74 24 18 57 48 83 EC 20 48 8B D9 49 8B F8 48 8B 49 48 8B EA 48 8D 41 20 48 3B 43 58";

    // hksi_lua_pushlstring — mov edi, 1Fh then distinctive lea with constant 6B6F7265h
    constexpr const char* HksiLuaPushlstring =
        "48 89 5C 24 08 48 89 6C 24 10 48 89 74 24 18 57 48 83 EC 40 BF 1F 00 00 00 45 8D 88 65 72 6F 6B";

    // hksi_luaL_checklstring — 3 register saves, 30h stack, takes index as int
    constexpr const char* LuaLChecklstring =
        "48 89 5C 24 08 48 89 74 24 10 57 48 83 EC 30 49 8B D8 8B F2 48 8B F9 48 85 C9 75";

    // hks_obj_tolstring — sub rsp, 130h (distinctive large stack)
    constexpr const char* HksObjTolstring =
        "40 53 48 81 EC 30 01 00 00 48 89 B4 24 48 01 00 00 48 8B F1 48 8B DA 48 85 C9 75";
}

struct HksApi {
    luaL_loadfile_fn luaL_loadfile = nullptr;
    lua_pcall_fn lua_pcall = nullptr;
    luaL_loadbuffer_fn luaL_loadbuffer = nullptr;
    hks_pushcclosure_fn hks_pushcclosure = nullptr;
    hksi_lua_setfield_fn lua_setfield = nullptr;
    hksi_lua_pushlstring_fn lua_pushlstring = nullptr;
    luaL_checklstring_fn luaL_checklstring = nullptr;
    hks_obj_tolstring_fn obj_tolstring = nullptr;

    // Resolved via pattern scan — see hooks.cpp
    bool Resolve();
};

extern HksApi g_hks;
