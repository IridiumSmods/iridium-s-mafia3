#include "glass.h"
#include "logger.h"
#include <d3d11.h>
#include <d3dcompiler.h>
#include <cstring>

ImFont* UiFonts::Body = nullptr;
ImFont* UiFonts::Semibold = nullptr;
ImFont* UiFonts::Icons = nullptr;

// ImGui 1.92 rasterises glyphs at the size they are drawn at, so the sizes here
// are only defaults: text stays sharp at 1440p and 4K.
void UiFonts::Load() {
    ImGuiIO& io = ImGui::GetIO();
    // The built-in font has only basic Latin: accented and other letters were drawn as '?'.
    ImFont* font = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\segoeui.ttf", 19.0f);
    if (!font)
        font = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\arial.ttf", 18.0f);
    if (!font) {
        Logger::Log("Segoe UI and Arial not found: letters beyond basic Latin will show as ?");
        font = io.Fonts->AddFontDefault();
    }
    Body = font;
    Semibold = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\seguisb.ttf", 19.0f);
    // Segoe Fluent Icons (Windows 11) has the same code points as Segoe MDL2
    // Assets (Windows 10), in the newer drawing.
    Icons = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\SegoeIcons.ttf", 18.0f);
    if (!Icons)
        Icons = io.Fonts->AddFontFromFileTTF("C:\\Windows\\Fonts\\segmdl2.ttf", 18.0f);
    if (!Semibold) Semibold = font;
}

namespace Glass {
    static ID3D11Device* g_device = nullptr;
    static ID3D11DeviceContext* g_context = nullptr;
    static ID3D11Texture2D* g_tex = nullptr;
    static ID3D11ShaderResourceView* g_srv = nullptr;
    static ID3D11PixelShader* g_ps = nullptr;
    static ID3D11SamplerState* g_sampler = nullptr; // ImGui's sampler clamps MaxLOD to 0
    static ID3D11Buffer* g_cb = nullptr;
    static ID3D11Buffer* g_savedCb = nullptr;
    static UINT g_w = 0, g_h = 0;
    static DXGI_FORMAT g_fmt = DXGI_FORMAT_UNKNOWN;
    static bool g_disabled = false;

    struct Params {
        float tint[4];   // acrylic tint (0-1) and its opacity
        float look[4];   // blur mip, grain, scale and lift of the blurred frame's brightness
    };

    // ImGui's vertex shader output layout. Acrylic, as in Windows 11: a low mip
    // of the frame blurred, its brightness squeezed into a band (darker under a
    // dark tint, lighter under a light one: the "luminosity" layer, so a thin
    // tint still keeps text readable over a bright sky or a dark alley), the tint
    // over it, a faint grain on top. The frame's alpha, which games often leave
    // at zero, is ignored; the vertex alpha fades the whole slab in and out.
    static const char* BlurShader = R"(
struct PS_INPUT { float4 pos : SV_POSITION; float4 col : COLOR0; float2 uv : TEXCOORD0; };
cbuffer GlassParams : register(b0) { float4 tint; float4 look; };
sampler sampler0;
Texture2D texture0;

float3 blur(float2 uv, float2 stp, float lod) {
    float3 sum = 0;
    float wsum = 0;
    [unroll] for (int y = -2; y <= 2; y++) {
        [unroll] for (int x = -2; x <= 2; x++) {
            float wt = exp(-(x * x + y * y) / 4.5);
            float2 t = clamp(uv + float2(x, y) * stp, 0.0005, 0.9995);
            sum += texture0.SampleLevel(sampler0, t, lod).rgb * wt;
            wsum += wt;
        }
    }
    return sum / wsum;
}

float grain(float2 p) {
    return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453) - 0.5;
}

float4 main(PS_INPUT input) : SV_Target {
    float w, h, levels;
    texture0.GetDimensions(0, w, h, levels);
    float lod = min(look.x, levels - 1.0);
    float2 stp = exp2(lod) / float2(w, h);
    float3 c = lerp(blur(input.uv, stp, lod) * look.z + look.w, tint.rgb, tint.a);
    c += grain(floor(input.pos.xy)) * look.y;
    return float4(saturate(c), input.col.a);
}
)";

    void Init(ID3D11Device* device, ID3D11DeviceContext* context) {
        g_device = device;
        g_context = context;
    }

    static void ReleaseTexture() {
        if (g_srv) { g_srv->Release(); g_srv = nullptr; }
        if (g_tex) { g_tex->Release(); g_tex = nullptr; }
        g_w = g_h = 0;
    }

    static bool EnsureShader() {
        if (g_ps) return true;
        ID3DBlob* blob = nullptr;
        ID3DBlob* err = nullptr;
        if (FAILED(D3DCompile(BlurShader, strlen(BlurShader), nullptr, nullptr, nullptr,
                "main", "ps_4_0", D3DCOMPILE_OPTIMIZATION_LEVEL3, 0, &blob, &err))) {
            Logger::Log("Glass: shader compile failed: %s", err ? (const char*)err->GetBufferPointer() : "?");
            if (err) err->Release();
            return false;
        }
        HRESULT hr = g_device->CreatePixelShader(blob->GetBufferPointer(), blob->GetBufferSize(), nullptr, &g_ps);
        blob->Release();
        if (FAILED(hr)) return false;

        D3D11_SAMPLER_DESC sd = {};
        sd.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
        sd.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
        sd.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
        sd.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
        sd.ComparisonFunc = D3D11_COMPARISON_ALWAYS;
        sd.MinLOD = 0.0f;
        sd.MaxLOD = D3D11_FLOAT32_MAX;
        if (FAILED(g_device->CreateSamplerState(&sd, &g_sampler))) return false;

        D3D11_BUFFER_DESC bd = {};
        bd.ByteWidth = sizeof(Params);
        bd.Usage = D3D11_USAGE_DYNAMIC;
        bd.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
        bd.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
        return SUCCEEDED(g_device->CreateBuffer(&bd, nullptr, &g_cb));
    }

    void Capture(ID3D11Texture2D* frame) {
        if (g_disabled || !g_device || !g_context || !frame) return;
        if (!EnsureShader()) { g_disabled = true; return; }

        D3D11_TEXTURE2D_DESC fd;
        frame->GetDesc(&fd);
        if (fd.SampleDesc.Count != 1) {
            Logger::Log("Glass: multisampled frame, blur disabled");
            g_disabled = true;
            return;
        }

        if (!g_tex || fd.Width != g_w || fd.Height != g_h || fd.Format != g_fmt) {
            ReleaseTexture();
            D3D11_TEXTURE2D_DESC td = {};
            td.Width = fd.Width;
            td.Height = fd.Height;
            td.MipLevels = 0;
            td.ArraySize = 1;
            td.Format = fd.Format;
            td.SampleDesc.Count = 1;
            td.Usage = D3D11_USAGE_DEFAULT;
            td.BindFlags = D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET;
            td.MiscFlags = D3D11_RESOURCE_MISC_GENERATE_MIPS;
            if (FAILED(g_device->CreateTexture2D(&td, nullptr, &g_tex)) ||
                FAILED(g_device->CreateShaderResourceView(g_tex, nullptr, &g_srv))) {
                Logger::Log("Glass: cannot create blur texture (format %d), blur disabled", (int)fd.Format);
                ReleaseTexture();
                g_disabled = true;
                return;
            }
            g_w = fd.Width;
            g_h = fd.Height;
            g_fmt = fd.Format;
            Logger::Log("Glass: blur texture %ux%u format %d", g_w, g_h, (int)g_fmt);
        }

        g_context->CopySubresourceRegion(g_tex, 0, 0, 0, 0, frame, 0, nullptr);
        g_context->GenerateMips(g_srv);
    }

    static void BeginGlass(const ImDrawList*, const ImDrawCmd* cmd) {
        D3D11_MAPPED_SUBRESOURCE mapped;
        if (SUCCEEDED(g_context->Map(g_cb, 0, D3D11_MAP_WRITE_DISCARD, 0, &mapped))) {
            memcpy(mapped.pData, cmd->UserCallbackData, sizeof(Params));
            g_context->Unmap(g_cb, 0);
        }
        // ImGui restores its own state afterwards but not pixel shader constant
        // buffers, so the game's slot b0 is put back in EndGlass.
        if (g_savedCb) { g_savedCb->Release(); g_savedCb = nullptr; }
        g_context->PSGetConstantBuffers(0, 1, &g_savedCb);
        g_context->PSSetConstantBuffers(0, 1, &g_cb);
        g_context->PSSetShader(g_ps, nullptr, 0);
        g_context->PSSetSamplers(0, 1, &g_sampler);
    }

    static void EndGlass(const ImDrawList*, const ImDrawCmd*) {
        g_context->PSSetConstantBuffers(0, 1, &g_savedCb);
        if (g_savedCb) { g_savedCb->Release(); g_savedCb = nullptr; }
    }

    bool Available() { return !g_disabled && g_srv && g_ps && g_sampler && g_cb; }

    void Acrylic(ImDrawList* dl, const ImVec2& a, const ImVec2& b, float rounding, float alpha, ImU32 rgb, float opacity,
                 float bgScale, float bgLift) {
        ImGuiIO& io = ImGui::GetIO();
        int ia = (int)(alpha * 255.0f);
        if (ia < 0) ia = 0;
        if (ia > 255) ia = 255;
        if (opacity >= 1.0f) {
            // Solid: nothing of the game would show, so no blur and no grain (the
            // frame is not copied then, and the blur texture may be stale).
            dl->AddRectFilled(a, b, (rgb & ~IM_COL32_A_MASK) | ((ImU32)ia << IM_COL32_A_SHIFT), rounding);
            return;
        }
        if (!Available() || io.DisplaySize.x < 1.0f || io.DisplaySize.y < 1.0f) {
            // Without the blur the game would show through sharp: nearly opaque instead.
            dl->AddRectFilled(a, b, (rgb & ~IM_COL32_A_MASK) | ((ImU32)(ia * 0.96f) << IM_COL32_A_SHIFT), rounding);
            return;
        }
        Params prm = {
            { ((rgb >> IM_COL32_R_SHIFT) & 0xFF) / 255.0f, ((rgb >> IM_COL32_G_SHIFT) & 0xFF) / 255.0f,
              ((rgb >> IM_COL32_B_SHIFT) & 0xFF) / 255.0f, opacity },
            { 2.75f, 0.018f, bgScale, bgLift },
        };
        ImVec2 uv0(a.x / io.DisplaySize.x, a.y / io.DisplaySize.y);
        ImVec2 uv1(b.x / io.DisplaySize.x, b.y / io.DisplaySize.y);
        dl->AddCallback(BeginGlass, &prm, sizeof(prm));
        dl->AddImageRounded(ImTextureRef((ImTextureID)(intptr_t)g_srv), a, b, uv0, uv1, IM_COL32(255, 255, 255, ia), rounding);
        dl->AddCallback(EndGlass, nullptr);
        dl->AddCallback(ImDrawCallback_ResetRenderState, nullptr);
    }
}
