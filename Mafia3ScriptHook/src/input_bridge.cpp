#include "input_bridge.h"
#include <Windows.h>
#include <atomic>
#include <cstring>

// DirectInput DIK_Q (dinput.h)
static constexpr std::size_t kDikQ = 0x10;

static std::atomic<bool> g_mouseSideEdge{ false };
static std::atomic<bool> g_prevMouseSideDown{ false };
static std::atomic<int> g_meleePulseFrames{ 0 };
static std::atomic<bool> g_hasApi{ true };
static std::atomic<bool> g_aimHeld{ false };
static std::atomic<int> g_meleeBlockFrames{ 0 };
// Frames since Q (the takedown input) went down; kNever until it first does.
static constexpr int kNever = 1 << 20;
static std::atomic<int> g_meleeAge{ kNever };
static std::atomic<bool> g_prevMeleeDown{ false };
// The game gets the input and no trainer UI is open (KeyDown).
static std::atomic<bool> g_gameKeys{ false };

bool InputBridge::HasInputApi() {
    return g_hasApi.load(std::memory_order_relaxed);
}

void InputBridge::Poll(bool focused, bool blockForUi, bool gameBlocked) {
    g_gameKeys.store(focused && !blockForUi && !gameBlocked, std::memory_order_relaxed);
    // The melee block lapses by itself unless the brawl mode renews it.
    int frames = g_meleeBlockFrames.load(std::memory_order_relaxed);
    if (frames > 0)
        g_meleeBlockFrames.store(frames - 1, std::memory_order_relaxed);
    // The aim follows what the game gets: with the trainer menu open it still
    // aims, and reading "not held" then put the first-person camera's hip place
    // and angle on the sights while the menu was open (2026-10-21).
    g_aimHeld.store(focused && !gameBlocked && (GetAsyncKeyState(VK_RBUTTON) & 0x8000) != 0,
        std::memory_order_relaxed);
    // Q as the game gets it, for the first-person takedowns: the controls
    // locking just after Q is a takedown, not a scene.
    int age = g_meleeAge.load(std::memory_order_relaxed);
    if (age < kNever)
        g_meleeAge.store(age + 1, std::memory_order_relaxed);
    bool q = focused && !gameBlocked && (GetAsyncKeyState('Q') & 0x8000) != 0;
    if (q && !g_prevMeleeDown.exchange(q, std::memory_order_relaxed))
        g_meleeAge.store(0, std::memory_order_relaxed);
    else
        g_prevMeleeDown.store(q, std::memory_order_relaxed);
    if (!focused || blockForUi) {
        g_prevMouseSideDown.store(false, std::memory_order_relaxed);
        return;
    }
    bool down = (GetAsyncKeyState(VK_XBUTTON1) & 0x8000) != 0 || (GetAsyncKeyState(VK_XBUTTON2) & 0x8000) != 0;
    bool prev = g_prevMouseSideDown.exchange(down, std::memory_order_relaxed);
    if (down && !prev)
        g_mouseSideEdge.store(true, std::memory_order_relaxed);
}

bool InputBridge::ConsumeMouse4() {
    return g_mouseSideEdge.exchange(false, std::memory_order_relaxed);
}

bool InputBridge::IsAimHeld() {
    return g_aimHeld.load(std::memory_order_relaxed);
}

int InputBridge::MeleeAge() {
    return g_meleeAge.load(std::memory_order_relaxed);
}

bool InputBridge::KeyDown(int vk) {
    if (vk <= 0 || vk > 0xFE || !g_gameKeys.load(std::memory_order_relaxed))
        return false;
    return (GetAsyncKeyState(vk) & 0x8000) != 0;
}

void InputBridge::BlockMelee(int frames) {
    g_meleeBlockFrames.store(frames > 0 ? frames : 0, std::memory_order_relaxed);
}

bool InputBridge::IsMeleeBlocked() {
    return g_meleeBlockFrames.load(std::memory_order_relaxed) > 0;
}

void InputBridge::DropMeleeFromKeyboard(unsigned char* keyState, std::size_t byteCount) {
    if (keyState != nullptr && byteCount > kDikQ && IsMeleeBlocked())
        keyState[kDikQ] = 0;
}

unsigned long InputBridge::DropMeleeRecords(void* records, unsigned long stride, unsigned long count) {
    if (records == nullptr || stride < 8 || !IsMeleeBlocked())
        return count;
    auto* base = static_cast<unsigned char*>(records);
    unsigned long kept = 0;
    for (unsigned long i = 0; i < count; i++) {
        unsigned char* rec = base + i * stride;
        unsigned long ofs = 0, data = 0;
        std::memcpy(&ofs, rec, 4);       // DIDEVICEOBJECTDATA::dwOfs (the DIK code)
        std::memcpy(&data, rec + 4, 4);  // ::dwData, 0x80 = pressed
        // Only presses: a release must still reach the game, or Q would stay held.
        if (ofs == kDikQ && (data & 0x80) != 0)
            continue;
        if (kept != i)
            std::memmove(base + kept * stride, rec, stride);
        kept++;
    }
    return kept;
}

void InputBridge::RequestMeleePulse() {
    g_meleePulseFrames.store(6, std::memory_order_relaxed);
}

void InputBridge::ApplyMeleePulseToKeyboard(unsigned char* keyState, std::size_t byteCount) {
    if (keyState == nullptr || byteCount <= kDikQ)
        return;
    int frames = g_meleePulseFrames.load(std::memory_order_relaxed);
    if (frames <= 0)
        return;
    g_meleePulseFrames.store(frames - 1, std::memory_order_relaxed);
    keyState[kDikQ] = 0x80;
}
