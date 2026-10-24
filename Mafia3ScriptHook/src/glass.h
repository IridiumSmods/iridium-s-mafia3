#pragma once

#include "../vendor/imgui/imgui.h"

struct ID3D11Device;
struct ID3D11DeviceContext;
struct ID3D11Texture2D;

// Acrylic: the frame behind the overlay, blurred on the GPU under a tint.
namespace Glass {
    void Init(ID3D11Device* device, ID3D11DeviceContext* context);
    // Copies the finished frame (before the overlay is drawn) and builds its mip chain.
    void Capture(ID3D11Texture2D* frame);
    bool Available();
    // The blurred frame inside the rounded rect, its brightness taken to
    // frame * bgScale + bgLift, under `rgb` at `opacity`, with a faint grain;
    // alpha fades the whole slab. Without the blur, `rgb` nearly opaque; at
    // opacity 1, `rgb` solid without touching the blur.
    void Acrylic(ImDrawList* dl, const ImVec2& a, const ImVec2& b, float rounding, float alpha, ImU32 rgb, float opacity,
                 float bgScale, float bgLift);
}

namespace UiFonts {
    extern ImFont* Body;
    extern ImFont* Semibold;
    extern ImFont* Icons;
    // Loads the overlay fonts into the current ImGui context.
    void Load();
}
