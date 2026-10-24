#pragma once

#include <cstddef>

namespace InputBridge {
    // blockForUi: any trainer UI is open (no Mouse 4 then). gameBlocked: the game
    // itself gets no mouse (the console, a text field); the trainer menu leaves
    // it the mouse, so the game still aims with it open.
    void Poll(bool focused, bool blockForUi, bool gameBlocked);

    // One-shot edge on Mouse 4 or Mouse 5 (side buttons).
    bool ConsumeMouse4();

    // Right mouse button (the game's aim) held, whenever the game gets the mouse.
    bool IsAimHeld();

    // Frames since Q (melee, the takedown input) last went down, whenever the
    // game gets the keyboard; a very large number until it first does.
    int MeleeAge();

    // A key held (a Windows virtual-key code: 'V', VK_F5, VK_MBUTTON...), only
    // while the game gets the input and no trainer UI is open, so a letter typed
    // into the menu's search does not count: the first-person view's own keys.
    bool KeyDown(int vk);

    // Q (melee) kept from the game for the next `frames` frames; 0 lets it through.
    // The brawl mode renews it while a stunned enemy has not taken his hits yet.
    void BlockMelee(int frames);
    bool IsMeleeBlocked();
    void DropMeleeFromKeyboard(unsigned char* keyState, std::size_t byteCount);
    // Removes Q key-down records from a DirectInput buffer; returns how many are left.
    unsigned long DropMeleeRecords(void* records, unsigned long stride, unsigned long count);

    // Queue Q into DirectInput keyboard state for a few frames (SendInput does not reach the game).
    void RequestMeleePulse();
    void ApplyMeleePulseToKeyboard(unsigned char* keyState, std::size_t byteCount);

    bool HasInputApi();
}
