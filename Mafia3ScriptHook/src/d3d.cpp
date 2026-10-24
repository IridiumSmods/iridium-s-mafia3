#include "gui.h"
#include "hooks.h"
#include "lua_mod_loader.h"
#include "menu_system.h"
#include "input_bridge.h"
#include "glass.h"
#include "logger.h"
#include <Windows.h>
#include <d3d11.h>
#include <dxgi1_2.h>
#include <dinput.h>
#include "../vendor/kiero/kiero.h"
#include "../vendor/minhook/include/MinHook.h"
#include "../vendor/imgui/imgui.h"
#include "../vendor/imgui/imgui_impl_win32.h"
#include "../vendor/imgui/imgui_impl_dx11.h"

typedef HRESULT(__stdcall* Present_fn)(IDXGISwapChain* pSwapChain, UINT SyncInterval, UINT Flags);
typedef HRESULT(__stdcall* Present1_fn)(IDXGISwapChain* pSwapChain, UINT SyncInterval, UINT Flags, const DXGI_PRESENT_PARAMETERS* pPresentParameters);
typedef HRESULT(__stdcall* ResizeBuffers_fn)(IDXGISwapChain* pSwapChain, UINT BufferCount, UINT Width, UINT Height, DXGI_FORMAT NewFormat, UINT SwapChainFlags);
typedef LRESULT(CALLBACK* WNDPROC)(HWND, UINT, WPARAM, LPARAM);

// Input blocking hooks
typedef BOOL(WINAPI* ClipCursor_fn)(const RECT*);
typedef BOOL(WINAPI* GetCursorPos_fn)(LPPOINT);
typedef HRESULT(WINAPI* DirectInput8Create_fn)(HINSTANCE, DWORD, REFIID, LPVOID*, LPUNKNOWN);
typedef HRESULT(__stdcall* GetDeviceState_fn)(IDirectInputDevice8A*, DWORD, LPVOID);
typedef HRESULT(__stdcall* GetDeviceData_fn)(IDirectInputDevice8A*, DWORD, LPDIDEVICEOBJECTDATA, LPDWORD, DWORD);

static ClipCursor_fn oClipCursor = nullptr;
static GetCursorPos_fn oGetCursorPos = nullptr;
static GetDeviceState_fn oKbdGetDeviceState = nullptr;
static GetDeviceData_fn oKbdGetDeviceData = nullptr;
static GetDeviceState_fn oMouseGetDeviceState = nullptr;
static GetDeviceData_fn oMouseGetDeviceData = nullptr;
static POINT g_frozenCursorPos = {};
static bool g_cursorFrozen = false;

extern LRESULT ImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

static Present_fn oPresent = nullptr;
static Present1_fn oPresent1 = nullptr;
static ResizeBuffers_fn oResizeBuffers = nullptr;
static int g_presentDepth = 0;
static bool g_loggedOverlay = false;
static WNDPROC oWndProc = nullptr;
static HWND window = nullptr;
static ID3D11Device* pDevice = nullptr;
static ID3D11DeviceContext* pContext = nullptr;
static ID3D11RenderTargetView* pRenderTargetView = nullptr;
static bool imguiInitialized = false;
static bool open = false;

// The game functions were not found at start (Hooks::InstallFailed): the Lua
// mods never start and F4 does nothing, which looked like a broken install. Said
// on screen for the first 40 seconds of the overlay.
static void DrawUnsupportedNotice() {
    static double shownFrom = -1.0;
    double now = ImGui::GetTime();
    if (shownFrom < 0.0)
        shownFrom = now;
    if (now - shownFrom > 40.0)
        return;
    const char* lines[] = {
        "IRIDIUM S / Mafia3ScriptHook: this game version is not supported (game functions not found, a game update?).",
        "The F4 menu and the first-person extras are off; the game runs as usual. Details: ScriptHook\\ScriptHook.log",
    };
    const float pad = 10.0f, gap = 3.0f;
    float w = 0.0f, h = 0.0f;
    for (const char* line : lines) {
        ImVec2 size = ImGui::CalcTextSize(line);
        if (size.x > w)
            w = size.x;
        h += size.y + gap;
    }
    ImDrawList* dl = ImGui::GetForegroundDrawList();
    ImVec2 a(24.0f, 24.0f), b(24.0f + w + 2.0f * pad, 24.0f + h - gap + 2.0f * pad);
    dl->AddRectFilled(a, b, IM_COL32(18, 18, 22, 225), 6.0f);
    dl->AddRect(a, b, IM_COL32(235, 165, 60, 255), 6.0f, 0, 1.5f);
    float y = a.y + pad;
    for (const char* line : lines) {
        dl->AddText(ImVec2(a.x + pad, y), IM_COL32(255, 232, 205, 255), line);
        y += ImGui::CalcTextSize(line).y + gap;
    }
}

static void CreateRenderTarget(IDXGISwapChain* pSwapChain) {
    ID3D11Texture2D* pBackBuffer = nullptr;
    if (SUCCEEDED(pSwapChain->GetBuffer(0, __uuidof(ID3D11Texture2D), (void**)&pBackBuffer))) {
        pDevice->CreateRenderTargetView(pBackBuffer, nullptr, &pRenderTargetView);
        pBackBuffer->Release();
    }
}

static void CleanupRenderTarget() {
    if (pRenderTargetView) {
        pRenderTargetView->Release();
        pRenderTargetView = nullptr;
    }
}

static void ApplyGlassStyle() {
    ImGuiStyle& st = ImGui::GetStyle();
    st.WindowRounding = 16.0f;
    st.FrameRounding = 10.0f;
    st.ChildRounding = 10.0f;
    st.ScrollbarRounding = 10.0f;
    st.WindowBorderSize = 1.0f;
    st.FrameBorderSize = 1.0f;
    st.WindowPadding = ImVec2(16, 14);
    st.FramePadding = ImVec2(10, 7);
    ImVec4* c = st.Colors;
    c[ImGuiCol_Text] = ImVec4(0.09f, 0.10f, 0.12f, 1.0f);
    c[ImGuiCol_TextDisabled] = ImVec4(0.40f, 0.43f, 0.48f, 1.0f);
    c[ImGuiCol_WindowBg] = ImVec4(0.94f, 0.95f, 0.97f, 0.62f);
    c[ImGuiCol_ChildBg] = ImVec4(1.0f, 1.0f, 1.0f, 0.0f);
    c[ImGuiCol_Border] = ImVec4(1.0f, 1.0f, 1.0f, 0.55f);
    c[ImGuiCol_FrameBg] = ImVec4(1.0f, 1.0f, 1.0f, 0.48f);
    c[ImGuiCol_FrameBgHovered] = ImVec4(1.0f, 1.0f, 1.0f, 0.62f);
    c[ImGuiCol_FrameBgActive] = ImVec4(1.0f, 1.0f, 1.0f, 0.72f);
    c[ImGuiCol_TextSelectedBg] = ImVec4(0.55f, 0.60f, 0.68f, 0.45f);
    c[ImGuiCol_Separator] = ImVec4(0.55f, 0.58f, 0.63f, 0.45f);
    c[ImGuiCol_ScrollbarBg] = ImVec4(0, 0, 0, 0);
    c[ImGuiCol_ScrollbarGrab] = ImVec4(0.55f, 0.58f, 0.63f, 0.55f);
}

static void InitImGui() {
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.IniFilename = nullptr;
    io.LogFilename = nullptr;

    UiFonts::Load();

    ApplyGlassStyle();
    ImGui_ImplWin32_Init(window);
    ImGui_ImplDX11_Init(pDevice, pContext);
}

static void ShutdownImGui() {
    ImGui_ImplDX11_Shutdown();
    ImGui_ImplWin32_Shutdown();
    ImGui::DestroyContext();
}

// --- Input blocking hooks ---

// Returns true when any UI that needs input blocking is active
static bool ShouldBlockInput() {
    return open || MenuSystem::IsTextInputActive();
}

static BOOL WINAPI hkClipCursor(const RECT* lpRect) {
    if (ShouldBlockInput()) return TRUE;
    return oClipCursor(lpRect);
}

static BOOL WINAPI hkGetCursorPos(LPPOINT lpPoint) {
    if (ShouldBlockInput()) {
        if (!g_cursorFrozen) {
            oGetCursorPos(&g_frozenCursorPos);
            g_cursorFrozen = true;
        }
        if (lpPoint) *lpPoint = g_frozenCursorPos;
        return TRUE;
    }
    g_cursorFrozen = false;
    return oGetCursorPos(lpPoint);
}

static HRESULT __stdcall hkKbdGetDeviceState(IDirectInputDevice8A* pDev, DWORD cbData, LPVOID lpvData) {
    HRESULT hr = oKbdGetDeviceState(pDev, cbData, lpvData);
    if (SUCCEEDED(hr) && lpvData != nullptr && !ShouldBlockInput()) {
        InputBridge::ApplyMeleePulseToKeyboard(static_cast<unsigned char*>(lpvData), cbData);
        InputBridge::DropMeleeFromKeyboard(static_cast<unsigned char*>(lpvData), cbData);
    }
    if (ShouldBlockInput() && SUCCEEDED(hr))
        memset(lpvData, 0, cbData);
    return hr;
}

static HRESULT __stdcall hkKbdGetDeviceData(IDirectInputDevice8A* pDev, DWORD cbObjectData, LPDIDEVICEOBJECTDATA rgdod, LPDWORD pdwInOut, DWORD dwFlags) {
    HRESULT hr = oKbdGetDeviceData(pDev, cbObjectData, rgdod, pdwInOut, dwFlags);
    if (ShouldBlockInput() && SUCCEEDED(hr))
        *pdwInOut = 0;
    else if (SUCCEEDED(hr) && rgdod != nullptr && pdwInOut != nullptr)
        *pdwInOut = InputBridge::DropMeleeRecords(rgdod, cbObjectData, *pdwInOut);
    return hr;
}

static HRESULT __stdcall hkMouseGetDeviceState(IDirectInputDevice8A* pDev, DWORD cbData, LPVOID lpvData) {
    HRESULT hr = oMouseGetDeviceState(pDev, cbData, lpvData);
    if (ShouldBlockInput() && SUCCEEDED(hr))
        memset(lpvData, 0, cbData);
    return hr;
}

static HRESULT __stdcall hkMouseGetDeviceData(IDirectInputDevice8A* pDev, DWORD cbObjectData, LPDIDEVICEOBJECTDATA rgdod, LPDWORD pdwInOut, DWORD dwFlags) {
    HRESULT hr = oMouseGetDeviceData(pDev, cbObjectData, rgdod, pdwInOut, dwFlags);
    if (ShouldBlockInput() && SUCCEEDED(hr))
        *pdwInOut = 0;
    return hr;
}

static void InstallInputHooks() {
    // Hook cursor functions
    MH_CreateHookApi(L"user32.dll", "ClipCursor", &hkClipCursor, (LPVOID*)&oClipCursor);
    MH_CreateHookApi(L"user32.dll", "GetCursorPos", &hkGetCursorPos, (LPVOID*)&oGetCursorPos);

    // Create temporary DI8 devices to grab vtables, then hook them
    // Keyboard and mouse have separate vtables so both need hooking
    HMODULE hDI = GetModuleHandleA("dinput8.dll");
    if (!hDI) hDI = LoadLibraryA("dinput8.dll");
    if (hDI) {
        auto pCreate = (DirectInput8Create_fn)GetProcAddress(hDI, "DirectInput8Create");
        if (pCreate) {
            IDirectInput8A* pDI = nullptr;
            if (SUCCEEDED(pCreate(GetModuleHandleA(NULL), DIRECTINPUT_VERSION, IID_IDirectInput8A, (LPVOID*)&pDI, NULL))) {
                IDirectInputDevice8A* pTempDev = nullptr;

                // Hook keyboard vtable
                if (SUCCEEDED(pDI->CreateDevice(GUID_SysKeyboard, &pTempDev, NULL))) {
                    void** vtable = *(void***)pTempDev;
                    MH_CreateHook(vtable[9], &hkKbdGetDeviceState, (LPVOID*)&oKbdGetDeviceState);
                    MH_CreateHook(vtable[10], &hkKbdGetDeviceData, (LPVOID*)&oKbdGetDeviceData);
                    pTempDev->Release();
                    pTempDev = nullptr;
                }

                // Hook mouse vtable
                if (SUCCEEDED(pDI->CreateDevice(GUID_SysMouse, &pTempDev, NULL))) {
                    void** vtable = *(void***)pTempDev;
                    MH_CreateHook(vtable[9], &hkMouseGetDeviceState, (LPVOID*)&oMouseGetDeviceState);
                    MH_CreateHook(vtable[10], &hkMouseGetDeviceData, (LPVOID*)&oMouseGetDeviceData);
                    pTempDev->Release();
                }

                pDI->Release();
            }
        }
    }

    MH_EnableHook(MH_ALL_HOOKS);
}

// --- WndProc ---

static LRESULT WINAPI WndProc(const HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    // Always let F1 toggle through
    if (uMsg == WM_KEYDOWN && wParam == VK_F1)
        return CallWindowProc(oWndProc, hWnd, uMsg, wParam, lParam);

    if (ImGui_ImplWin32_WndProcHandler(hWnd, uMsg, wParam, lParam))
        return true;

    // Block all input from reaching the game when UI needs exclusive input
    if (ShouldBlockInput()) {
        switch (uMsg) {
        case WM_KEYDOWN: case WM_KEYUP: case WM_SYSKEYDOWN: case WM_SYSKEYUP:
        case WM_CHAR: case WM_SYSCHAR:
        case WM_MOUSEMOVE: case WM_MOUSEWHEEL: case WM_MOUSEHWHEEL:
        case WM_LBUTTONDOWN: case WM_LBUTTONUP: case WM_LBUTTONDBLCLK:
        case WM_RBUTTONDOWN: case WM_RBUTTONUP: case WM_RBUTTONDBLCLK:
        case WM_MBUTTONDOWN: case WM_MBUTTONUP: case WM_MBUTTONDBLCLK:
        case WM_XBUTTONDOWN: case WM_XBUTTONUP: case WM_XBUTTONDBLCLK:
        case WM_INPUT:
            return 0;
        }
    }

    return CallWindowProc(oWndProc, hWnd, uMsg, wParam, lParam);
}

static HRESULT WINAPI hkResizeBuffers(IDXGISwapChain* pSwapChain, UINT BufferCount, UINT Width, UINT Height, DXGI_FORMAT NewFormat, UINT SwapChainFlags) {
    // The anniversary update may resize its swap chain before the first
    // Present call. At that point ImGui and the D3D device are not initialized
    // yet, so there is no render target to release or recreate.
    if (imguiInitialized) {
        CleanupRenderTarget();
    }

    HRESULT hr = oResizeBuffers(pSwapChain, BufferCount, Width, Height, NewFormat, SwapChainFlags);

    // Recreate the target only after hkPresent has acquired the D3D device.
    if (SUCCEEDED(hr) && imguiInitialized && pDevice) {
        CreateRenderTarget(pSwapChain);
    }

    return hr;
}

static bool GameWindowFocused(HWND gameWindow) {
    if (!gameWindow)
        return false;

    // Exclusive fullscreen often does not report the swap chain window as
    // the foreground window. The ScriptHook console is the same process, so
    // a strict HWND compare also drops F4 while that console exists.
    HWND fg = GetForegroundWindow();
    if (!fg)
        return !IsIconic(gameWindow);
    if (fg == gameWindow)
        return true;

    DWORD pid = 0;
    GetWindowThreadProcessId(fg, &pid);
    return pid == GetCurrentProcessId();
}

static void DrawOverlay(IDXGISwapChain* pSwapChain) {
    DXGI_SWAP_CHAIN_DESC sd;
    if (FAILED(pSwapChain->GetDesc(&sd)))
        return;
    if (sd.BufferDesc.Width < 320 || sd.BufferDesc.Height < 240)
        return;

    if (!imguiInitialized) {
        if (FAILED(pSwapChain->GetDevice(__uuidof(ID3D11Device), (void**)&pDevice)))
            return;

        pDevice->GetImmediateContext(&pContext);
        window = sd.OutputWindow;
        CreateRenderTarget(pSwapChain);
        oWndProc = (WNDPROC)SetWindowLongPtr(window, GWLP_WNDPROC, (LONG_PTR)WndProc);
        InitImGui();
        Glass::Init(pDevice, pContext);
        imguiInitialized = true;
        if (!g_loggedOverlay) {
            g_loggedOverlay = true;
            Logger::Log("IRIDIUM S / Trainer M3 overlay active (%ux%u). F4 opens the menu.",
                sd.BufferDesc.Width, sd.BufferDesc.Height);
        }
    }

    ImGui_ImplDX11_NewFrame();
    ImGui_ImplWin32_NewFrame();
    ImGui::NewFrame();

    // Win32 reports the window client size. After the flip-model fullscreen
    // resize that size can disagree with the buffer the game actually presents.
    ImGui::GetIO().DisplaySize = ImVec2(
        (float)sd.BufferDesc.Width, (float)sd.BufferDesc.Height);

    ModLoader::PollReloadRequest();

    bool focused = GameWindowFocused(window);

    InputBridge::Poll(focused, open || MenuSystem::IsOpen() || MenuSystem::IsTextInputActive(), ShouldBlockInput());

    if (focused) {
        if (GetAsyncKeyState(VK_F1) & 1) {

            open = !open;
            if (open) {
                if (oClipCursor) oClipCursor(nullptr);
                Gui::FocusInput();
            }
        }

        if (MenuSystem::IsReady() && (GetAsyncKeyState(VK_F4) & 1)) {
            MenuSystem::Toggle();
        }
    }

    if (open) {
        Gui::Render();
    }

    if (MenuSystem::IsOpen()) {
        if (focused)
            MenuSystem::HandleInput();
        MenuSystem::Render();
    }
    MenuSystem::RenderToasts();
    if (Hooks::InstallFailed())
        DrawUnsupportedNotice();

    ImGui::GetIO().MouseDrawCursor = open;
    ImGui::Render();

    if (MenuSystem::WantsGlass()) {
        ID3D11Texture2D* frame = nullptr;
        if (SUCCEEDED(pSwapChain->GetBuffer(0, __uuidof(ID3D11Texture2D), (void**)&frame))) {
            Glass::Capture(frame);
            frame->Release();
        }
    }

    if (pRenderTargetView) {
        pContext->OMSetRenderTargets(1, &pRenderTargetView, nullptr);
        ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
    }
}

static HRESULT WINAPI hkPresent(IDXGISwapChain* pSwapChain, UINT SyncInterval, UINT Flags) {
    if (g_presentDepth != 0)
        return oPresent(pSwapChain, SyncInterval, Flags);

    g_presentDepth++;
    DrawOverlay(pSwapChain);
    HRESULT hr = oPresent(pSwapChain, SyncInterval, Flags);
    g_presentDepth--;
    return hr;
}

static HRESULT WINAPI hkPresent1(IDXGISwapChain* pSwapChain, UINT SyncInterval, UINT Flags, const DXGI_PRESENT_PARAMETERS* pPresentParameters) {
    if (g_presentDepth != 0)
        return oPresent1(pSwapChain, SyncInterval, Flags, pPresentParameters);

    g_presentDepth++;
    DrawOverlay(pSwapChain);
    HRESULT hr = oPresent1(pSwapChain, SyncInterval, Flags, pPresentParameters);
    g_presentDepth--;
    return hr;
}

DWORD D3DThread() {
    bool init_hook = false;
    while (!init_hook) {
        if (kiero::init(kiero::RenderType::D3D11) == kiero::Status::Success) {
            if (kiero::bind(8, (void**)&oPresent, hkPresent) != kiero::Status::Success)
                Logger::Log("Present hook failed");
            if (kiero::bind(13, (void**)&oResizeBuffers, hkResizeBuffers) != kiero::Status::Success)
                Logger::Log("ResizeBuffers hook failed");

            uint150_t* methods = kiero::getMethodsTable();
            if (methods && methods[22] && methods[22] != methods[8]) {
                if (kiero::bind(22, (void**)&oPresent1, hkPresent1) == kiero::Status::Success)
                    Logger::Log("Present1 hook installed");
                else
                    Logger::Log("Present1 hook failed");
            } else {
                Logger::Log("Present1 slot missing");
            }

            InstallInputHooks();
            init_hook = true;
        } else {
            Sleep(100);
        }
    }
    return TRUE;
}
