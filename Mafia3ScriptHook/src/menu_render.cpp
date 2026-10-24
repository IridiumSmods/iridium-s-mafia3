#include "menu_render.h"
#include "glass.h"
#include "../vendor/imgui/imgui.h"
#include "../vendor/imgui/imgui_internal.h"
#include <cctype>
#include <cfloat>
#include <cmath>
#include <cstdlib>
#include <cstring>

// IRIDIUM S / Trainer M3: a neutral overlay in the manner of the Steam, NVIDIA
// and Xbox Game Bar overlays (2026-10-21). Acrylic over the blurred game frame:
// its brightness squeezed into a band first (darker under the dark theme,
// lighter under the light one), then a thin neutral tint and a faint grain, so
// the game shows through while text keeps its contrast; a 1 px border and one
// soft shadow. Segoe UI and the Windows icon font; one flat accent per theme
// (the Windows 11 blue) for the brand mark, the selection bar, switches that
// are on, the list position and the search field being typed in. Motion only
// answers input.
//   dark  - #121315 at 62 % over the frame at half its brightness;
//   light - #F4F2ED at 62 % over the frame lifted to the upper half.
// That is the "medium" transparency; the setting goes from a solid panel to
// three quarters of the game showing through (GlassLevels).
// Notices stay dark in both, so they read over any scene.
// It replaced the IRIDIUM S look: an iridescent gradient that drifted all the
// time, a sweeping glare, lit and iridescent rims, a coloured glow under the
// selection, icon tiles and letter-spaced captions.

namespace {
    // --- Strings ---

    enum Lang { En, De, Es, Fr, It, Pt, Pl, Tr, Cs, LangCount };
    Lang g_lang = En;

    const char* const Strings[(int)MenuRender::Str::Count][LangCount] = {
        { "IRIDIUM S", "IRIDIUM S", "IRIDIUM S", "IRIDIUM S", "IRIDIUM S", "IRIDIUM S", "IRIDIUM S", "IRIDIUM S", "IRIDIUM S" },
        { "Trainer M3", "Trainer M3", "Trainer M3", "Trainer M3", "Trainer M3", "Trainer M3", "Trainer M3", "Trainer M3", "Trainer M3" },
        { "select", "Auswahl", "elegir", "choisir", "seleziona", "selecionar", "wybierz", "seç", "vybrat" },
        { "OK", "OK", "aceptar", "valider", "OK", "OK", "OK", "tamam", "OK" },
        { "value", "Wert", "valor", "valeur", "valore", "valor", "wartość", "değer", "hodnota" },
        { "back", "zurück", "atrás", "retour", "indietro", "voltar", "wstecz", "geri", "zpět" },
        { "close", "schließen", "cerrar", "fermer", "chiudi", "fechar", "zamknij", "kapat", "zavřít" },
        { "Search", "Suche", "Buscar", "Rechercher", "Cerca", "Buscar", "Szukaj", "Ara", "Hledat" },
        { "Nothing found", "Nichts gefunden", "Sin resultados", "Aucun résultat",
          "Nessun risultato", "Nada encontrado", "Nic nie znaleziono", "Sonuç yok", "Nic nenalezeno" },
        { "Empty", "Leer", "Vacío", "Vide", "Vuoto", "Vazio", "Pusto", "Boş", "Prázdné" },
        { "Enter — done     Esc — cancel", "Enter — fertig     Esc — abbrechen",
          "Enter — listo     Esc — cancelar", "Entrée — valider     Échap — annuler",
          "Invio — fatto     Esc — annulla", "Enter — pronto     Esc — cancelar", "Enter — gotowe     Esc — anuluj",
          "Enter — tamam     Esc — iptal", "Enter — hotovo     Esc — zrušit" },
        { "Main menu", "Hauptmenü", "Menú principal", "Menu principal",
          "Menu principale", "Menu principal", "Menu główne", "Ana menü", "Hlavní menu" },
    };

    // --- Palette ---

    struct Rgb { float r, g, b; };

    // Colours of a theme. Text is opaque, so its contrast does not depend on the
    // scene behind the panel; alphas are for fills and lines only.
    struct Theme {
        bool light;
        Rgb panel;                // acrylic tint over the blurred frame (its opacity: GlassLevels)
        float bgScale, bgLift;    // the blurred frame's brightness: frame * scale + lift
        Rgb hi;                   // titles, the selected row
        Rgb main;                 // rows
        Rgb soft;                 // descriptions, values, icons, the path
        Rgb mute;                 // section captions, footer, chevrons
        Rgb line; float aLine;    // hairlines and the border
        Rgb fill; float aFill;    // keycaps, the search field
        Rgb sel; float aSel;      // the selected row
        Rgb accent;               // selection bar, switch on, list position, search focus
        Rgb onAccent;             // knob on an accent track
        float aShadow;
    };

    // With the frame's brightness squeezed, the faintest text (captions, footer)
    // still keeps about 4.5:1 over a white sky (dark) or a black alley (light).
    const Theme Dark = {
        false,
        { 18, 19, 21 },
        0.5f, 0.0f,
        { 243, 243, 243 },
        { 232, 232, 232 },
        { 196, 198, 203 },
        { 163, 166, 171 },
        { 255, 255, 255 }, 0.10f,
        { 255, 255, 255 }, 0.07f,
        { 255, 255, 255 }, 0.12f,
        { 96, 205, 255 },
        { 0, 0, 0 },
        0.40f,
    };

    const Theme Light = {
        true,
        { 244, 242, 237 },
        0.5f, 0.5f,
        { 22, 23, 26 },
        { 30, 32, 36 },
        { 63, 66, 73 },
        { 84, 87, 94 },
        { 0, 0, 0 }, 0.10f,
        { 0, 0, 0 }, 0.05f,
        { 0, 95, 184 }, 0.16f,
        { 0, 95, 184 },
        { 255, 255, 255 },
        0.18f,
    };

    const Theme* g_t = &Dark;

    // "Transparency": the tint's opacity over the blurred game, and how far the
    // frame's brightness band narrows (band times the theme's bgScale). The more
    // of the game shows, the narrower the band, as the luminosity layer of
    // acrylic does: at the most the faintest text still keeps about 3:1 and the
    // rows about 6:1 over a white sky (dark) or a black alley (light). "medium"
    // is the look the panel had before it could be chosen; under "none" the
    // panel is solid, and the frame is not even copied (UsesGlass).
    struct GlassLevel { const char* code; float tint; float band; };
    const GlassLevel GlassLevels[] = {
        { "none", 1.00f, 1.00f },
        { "low", 0.80f, 1.00f },
        { "medium", 0.62f, 1.00f },
        { "high", 0.44f, 0.93f },
        { "max", 0.25f, 0.86f },
    };
    int g_glass = 2;

    // --- State ---

    float g_s = 1.0f;          // UI scale: 1.0 at 1080p, times the size from the settings
    float g_a = 1.0f;          // alpha of whatever is being drawn now
    float g_user = 1.0f;       // "Interface size": 0.9 / 1.0 / 1.15 / 1.3
    bool g_right = false;      // panel on the right of the screen
    bool g_calm = false;       // less motion: no slides, quick fades
    int g_hiMenuId = -1;
    float g_hiTop = 0.0f, g_hiBot = 0.0f;
    float g_scrollTarget = 0.0f;
    float g_panelH = 0.0f;
    double g_menuShownAt = 0.0;
    int g_lastDepth = 0;
    float g_slideDir = 1.0f;
    int g_hintSel = -1;
    double g_hintAt = 0.0;

    const char* const Sep = "  \xC2\xB7  ";
    const char* const PathSep = "  \xE2\x80\xBA  ";
    const char* const Ellipsis = "\xE2\x80\xA6";

    ImU32 Rgba(int r, int g, int b, float a) {
        a = ImClamp(a * g_a, 0.0f, 1.0f);
        return IM_COL32(r, g, b, (int)(a * 255.0f + 0.5f));
    }

    ImU32 Col(const Rgb& c, float a) { return Rgba((int)c.r, (int)c.g, (int)c.b, a); }

    ImU32 Hi(float k = 1.0f) { return Col(g_t->hi, k); }
    ImU32 Main(float k = 1.0f) { return Col(g_t->main, k); }
    ImU32 Soft(float k = 1.0f) { return Col(g_t->soft, k); }
    ImU32 Mute(float k = 1.0f) { return Col(g_t->mute, k); }
    ImU32 Line(float k = 1.0f) { return Col(g_t->line, g_t->aLine * k); }
    ImU32 Fill(float k = 1.0f) { return Col(g_t->fill, g_t->aFill * k); }
    ImU32 Accent(float k = 1.0f) { return Col(g_t->accent, k); }

    ImVec2 V(float x, float y) { return ImVec2(x, y); }
    ImVec2 Measure(ImFont* f, float size, const char* s) { return f->CalcTextSizeA(size, FLT_MAX, 0.0f, s); }
    float Follow(float dt, float rate) { return 1.0f - expf(-dt * rate); }
    float EaseOut(float k) { k = ImClamp(k, 0.0f, 1.0f); return 1.0f - (1.0f - k) * (1.0f - k) * (1.0f - k); }

    float ScaleFor(const ImGuiIO& io) { return ImClamp(io.DisplaySize.y / 1080.0f, 0.75f, 2.0f) * g_user; }

    void SoftShadow(ImDrawList* dl, ImVec2 a, ImVec2 b, float r, float spread, float alpha, float drop) {
        const int layers = 12;
        for (int i = layers; i >= 1; i--) {
            float k = (float)i / layers;
            float e = spread * k;
            float dy = spread * drop;
            dl->AddRectFilled(V(a.x - e, a.y - e + dy), V(b.x + e, b.y + e + dy),
                Rgba(0, 0, 0, alpha * (1.0f - k) * (1.0f - k) * 0.36f), r + e);
        }
    }

    // The panel and the notices: one shadow, acrylic, a 1 px border.
    void Panel(ImDrawList* dl, ImVec2 a, ImVec2 b, float r) {
        SoftShadow(dl, a, b, r, 26.0f * g_s, g_t->aShadow, 0.30f);
        const GlassLevel& gl = GlassLevels[g_glass];
        // the band keeps its dark end under the dark theme, its light end under the light one
        const float scale = g_t->bgScale * gl.band;
        const float lift = g_t->bgLift + (g_t->light ? g_t->bgScale - scale : 0.0f);
        Glass::Acrylic(dl, a, b, r, g_a, IM_COL32((int)g_t->panel.r, (int)g_t->panel.g, (int)g_t->panel.b, 255), gl.tint,
            scale, lift);
        dl->AddRect(a, b, Line(1.2f), r, 0, 1.0f * g_s);
    }

    // The selection, in the manner of Windows 11 lists: a faint fill and a short
    // accent bar at its start. Nothing else marks it.
    void Selection(ImDrawList* dl, ImVec2 a, ImVec2 b, float r) {
        dl->AddRectFilled(a, b, Col(g_t->sel, g_t->aSel), r);
        float bh = ImMin(18.0f * g_s, b.y - a.y - 8.0f * g_s), cy = (a.y + b.y) * 0.5f;
        if (bh > 2.0f * g_s)
            dl->AddRectFilled(V(a.x + 1.0f * g_s, cy - bh * 0.5f), V(a.x + 4.0f * g_s, cy + bh * 0.5f), Accent(), 1.5f * g_s);
    }

    // Text cut to maxW with an ellipsis: the end is dropped, or with keepEnd the
    // start (a path keeps its last, most specific part).
    std::string FitText(ImFont* f, float size, const std::string& text, float maxW, bool keepEnd) {
        if (Measure(f, size, text.c_str()).x <= maxW) return text;
        std::vector<size_t> starts;
        for (size_t i = 0; i < text.size(); i++)
            if (((unsigned char)text[i] & 0xC0) != 0x80) starts.push_back(i);
        if (keepEnd) {
            for (size_t k = 1; k < starts.size(); k++) {
                std::string t = std::string(Ellipsis) + text.substr(starts[k]);
                if (Measure(f, size, t.c_str()).x <= maxW) return t;
            }
        } else {
            for (size_t k = starts.size(); k-- > 1;) {
                std::string t = text.substr(0, starts[k]) + Ellipsis;
                if (Measure(f, size, t.c_str()).x <= maxW) return t;
            }
        }
        return Ellipsis;
    }

    // Case mapping for ASCII, Latin-1 letters and Cyrillic.
    std::string MapCase(const std::string& in, bool upper) {
        std::string out;
        out.reserve(in.size());
        for (size_t i = 0; i < in.size(); i++) {
            unsigned char c = (unsigned char)in[i];
            if (c < 0x80) { out += (char)(upper ? toupper(c) : tolower(c)); continue; }
            if (i + 1 < in.size()) {
                unsigned char d = (unsigned char)in[i + 1];
                if (upper) {
                    if (c == 0xC3 && d >= 0xA0 && d <= 0xBE && d != 0xB7) { out += (char)0xC3; out += (char)(d - 0x20); i++; continue; }
                    if (c == 0xD0 && d >= 0xB0 && d <= 0xBF) { out += (char)0xD0; out += (char)(d - 0x20); i++; continue; }
                    if (c == 0xD1 && d >= 0x80 && d <= 0x8F) { out += (char)0xD0; out += (char)(d + 0x20); i++; continue; }
                    if (c == 0xD1 && d == 0x91) { out += (char)0xD0; out += (char)0x81; i++; continue; }
                } else {
                    if (c == 0xC3 && d >= 0x80 && d <= 0x9E && d != 0x97) { out += (char)0xC3; out += (char)(d + 0x20); i++; continue; }
                    if (c == 0xD0 && d >= 0x90 && d <= 0x9F) { out += (char)0xD0; out += (char)(d + 0x20); i++; continue; }
                    if (c == 0xD0 && d >= 0xA0 && d <= 0xAF) { out += (char)0xD1; out += (char)(d - 0x20); i++; continue; }
                    if (c == 0xD0 && d == 0x81) { out += (char)0xD1; out += (char)0x91; i++; continue; }
                }
            }
            out += (char)c;
        }
        return out;
    }

    struct IconRule { const char* key; unsigned int glyph; };

    // Windows icon font glyphs for menus that do not give their own icons,
    // matched against the lowercased untranslated label.
    const IconRule LabelIcons[] = {
        { "freecam", 0xE722 }, { "camera", 0xE722 }, { "eye", 0xE890 }, { "1st person", 0xE890 }, { "fov", 0xE890 },
        { "hide player", 0xE890 }, { "weather", 0xE753 }, { "time", 0xE823 }, { "hour", 0xE823 },
        { "repair", 0xE90F }, { "reset", 0xE81C }, { "vehicle", 0xE804 }, { "car ", 0xE804 }, { "wheel", 0xE804 },
        { "weapon", 0xE81D }, { "ammo", 0xE81D }, { "police", 0xEC1B }, { "wanted", 0xEC1B }, { "player", 0xE77B },
        { "model", 0xE77B }, { "noclip", 0xE945 }, { "speed", 0xE945 }, { "info", 0xE946 }, { "print", 0xE946 },
        { "position", 0xE707 }, { "direction", 0xE707 }, { "rotation", 0xE707 }, { "color", 0xE790 }, { "tint", 0xE790 },
        { "setting", 0xE713 }, { "offset", 0xE7AD }, { "lock", 0xE72E }, { "foot", 0xE7AD }, { "disable", 0xE71A },
        { "focus", 0xE890 }, { "depth", 0xE890 }, { "tags", 0xE8EC },
    };

    unsigned int IconFor(const MenuEntry& e) {
        if (e.icon) return e.icon;
        std::string lower = MapCase(e.iconKey.empty() ? e.label : e.iconKey, false);
        for (const auto& rule : LabelIcons)
            if (lower.find(rule.key) != std::string::npos) return rule.glyph;
        return 0;
    }

    std::string Utf8(unsigned int cp) {
        char buf[8] = {};
        ImTextCharToUtf8(buf, cp);
        return buf;
    }

    void SplitLabel(const std::string& label, std::string& main, std::string& value) {
        size_t p = label.find(Sep);
        if (p == std::string::npos) { main = label; value.clear(); return; }
        main = label.substr(0, p);
        value = label.substr(p + strlen(Sep));
    }

    void GlyphCentered(ImDrawList* dl, ImFont* f, float size, ImVec2 c, ImU32 col, const char* text) {
        ImVec2 ts = Measure(f, size, text);
        dl->AddText(f, size, V(floorf(c.x - ts.x * 0.5f + 0.5f), floorf(c.y - ts.y * 0.5f + 0.5f)), col, text);
    }

    void Chevron(ImDrawList* dl, float x, float cy, float size, ImU32 col, bool left = false) {
        float dx = left ? size : -size;
        dl->AddLine(V(x + dx, cy - size), V(x, cy), col, 1.5f * g_s);
        dl->AddLine(V(x, cy), V(x + dx, cy + size), col, 1.5f * g_s);
    }

    // Text with `track` more space after each letter, for the capitals of the
    // wordmark (capitals set solid look cramped). Returns where it ends.
    float Tracked(ImDrawList* dl, ImFont* f, float size, float x, float y, ImU32 col, const char* text, float track) {
        float end = x;
        for (const char* p = text; *p;) {
            unsigned int c = 0;
            int n = ImTextCharFromUtf8(&c, p, nullptr);
            if (n <= 0) break;
            dl->AddText(f, size, V(floorf(x + 0.5f), y), col, p, p + n);
            end = x + f->CalcTextSizeA(size, FLT_MAX, 0.0f, p, p + n).x;
            x = end + track;
            p += n;
        }
        return end;
    }

    // The brand mark: a cut stone, an outline with a solid core, in the accent.
    void BrandMark(ImDrawList* dl, float cx, float cy, float r) {
        float k = r * 0.4f;
        dl->AddQuad(V(cx, cy - r), V(cx + r, cy), V(cx, cy + r), V(cx - r, cy), Accent(), 1.25f * g_s);
        dl->AddQuadFilled(V(cx, cy - k), V(cx + k, cy), V(cx, cy + k), V(cx - k, cy), Accent());
    }

    float Keycap(ImDrawList* dl, float x, float y, const char* key, const char* what, ImFont* semi, ImFont* body) {
        float s = g_s, ks = 12.0f * s, h = 22.0f * s;
        ImVec2 sz = Measure(semi, ks, key);
        ImVec2 ka(x, y), kb(x + ImMax(sz.x + 12.0f * s, h), y + h);
        dl->AddRectFilled(ka, kb, Fill(), 4.0f * s);
        dl->AddRect(ka, kb, Line(1.4f), 4.0f * s, 0, 1.0f * s);
        dl->AddText(semi, ks, V(floorf((ka.x + kb.x - sz.x) * 0.5f), floorf(y + (h - ks) * 0.5f - 1.0f * s)), Main(), key);
        float tx = kb.x + 7.0f * s, ts = 13.5f * s;
        dl->AddText(body, ts, V(floorf(tx), floorf(y + (h - ts) * 0.5f - 1.0f * s)), Mute(), what);
        return tx + Measure(body, ts, what).x + 16.0f * s;
    }

    // Switch in the manner of Windows 11: on, an accent track with a knob in the
    // contrasting colour; off, an outlined track with a smaller knob.
    void Switch(ImDrawList* dl, float right, float cy, bool on, float alpha) {
        float s = g_s, w = 40.0f * s, h = 20.0f * s;
        ImVec2 ta(right - w, cy - h * 0.5f), tb(right, cy + h * 0.5f);
        float saved = g_a;
        g_a *= alpha;
        if (on) {
            dl->AddRectFilled(ta, tb, Accent(), h * 0.5f);
            dl->AddCircleFilled(V(tb.x - h * 0.5f, cy), h * 0.5f - 3.0f * s, Col(g_t->onAccent, 1.0f), 24);
        } else {
            dl->AddRect(ta, tb, Mute(), h * 0.5f, 0, 1.0f * s);
            dl->AddCircleFilled(V(ta.x + h * 0.5f, cy), h * 0.5f - 4.0f * s, Soft(), 24);
        }
        g_a = saved;
    }

    bool MenuHasHints(const Menu& menu) {
        for (const auto& e : menu.entries)
            if (e.type != EntryType::Header && e.type != EntryType::Search && !e.hint.empty()) return true;
        return false;
    }

    // Height of the tallest description, so the panel does not jump while moving
    // through rows and does not keep an empty band under a one-line hint.
    float TallestHint(const Menu& menu, ImFont* f, float size, float wrap) {
        float hmax = 0.0f;
        for (const auto& e : menu.entries) {
            if (e.type == EntryType::Header || e.type == EntryType::Search || e.hint.empty()) continue;
            hmax = ImMax(hmax, f->CalcTextSizeA(size, FLT_MAX, wrap, e.hint.c_str()).y);
        }
        return hmax;
    }

    bool MenuUsesIcons(const Menu& menu) {
        int rows = 0, withIcon = 0;
        for (const auto& e : menu.entries) {
            if (e.type == EntryType::Header || e.type == EntryType::Search) continue;
            rows++;
            if (IconFor(e)) withIcon++;
        }
        return rows > 0 && withIcon * 2 >= rows;
    }
}

void MenuRender::SetLanguage(const char* code) {
    static const char* const codes[LangCount] = { "en", "de", "es", "fr", "it", "pt", "pl", "tr", "cs" };
    g_lang = En;
    for (int i = 0; i < LangCount; i++)
        if (code && strcmp(code, codes[i]) == 0) g_lang = (Lang)i;
}

const char* MenuRender::Text(Str id) {
    return Strings[(int)id][g_lang];
}

void MenuRender::SetTheme(const char* code) {
    g_t = (code && strcmp(code, "light") == 0) ? &Light : &Dark;
}

bool MenuRender::IsLight() {
    return g_t->light;
}

void MenuRender::SetLook(const char* key, const char* value) {
    if (!key || !value) return;
    if (strcmp(key, "scale") == 0) {
        int pct = atoi(value);
        g_user = (pct >= 80 && pct <= 150) ? (float)pct / 100.0f : 1.0f;
    } else if (strcmp(key, "side") == 0) {
        g_right = strcmp(value, "right") == 0;
    } else if (strcmp(key, "motion") == 0) {
        g_calm = strcmp(value, "reduced") == 0;
    } else if (strcmp(key, "transparency") == 0) {
        g_glass = 2;
        for (int i = 0; i < IM_ARRAYSIZE(GlassLevels); i++)
            if (strcmp(value, GlassLevels[i].code) == 0) g_glass = i;
    }
}

bool MenuRender::UsesGlass() {
    return GlassLevels[g_glass].tint < 1.0f;
}

float MenuRender::Scale() {
    return ScaleFor(ImGui::GetIO());
}

void MenuRender::DrawMenu(Menu& menu, const std::vector<std::string>& crumbs, double openedAt) {
    ImGuiIO& io = ImGui::GetIO();
    const double now = ImGui::GetTime();
    const float dt = ImClamp(io.DeltaTime, 0.0f, 0.1f);
    const float ease = EaseOut((float)(now - openedAt) / (g_calm ? 0.12f : 0.20f));
    g_s = ScaleFor(io);
    g_a = ease;
    const float s = g_s;

    ImFont* body = UiFonts::Body ? UiFonts::Body : ImGui::GetFont();
    ImFont* semi = UiFonts::Semibold ? UiFonts::Semibold : body;
    const float bodySize = 18.0f * s, smallSize = 13.5f * s, titleSize = 25.0f * s, hintSize = 15.0f * s, capSize = 14.0f * s;

    const bool fresh = g_hiMenuId != menu.menuId;
    if (fresh) {
        int depth = (int)crumbs.size();
        g_slideDir = depth >= g_lastDepth ? 1.0f : -1.0f;
        g_lastDepth = depth;
        g_menuShownAt = now;
    }

    // Row geometry: section captions are shorter than items.
    const int count = menu.GetFilteredCount();
    const float rowH = 44.0f * s, headH = 34.0f * s;
    std::vector<float> rowTop((size_t)count + 1, 0.0f);
    for (int fi = 0; fi < count; fi++) {
        int ri = menu.GetFilteredEntryIndex(fi);
        bool head = ri >= 0 && menu.entries[ri].type == EntryType::Header;
        float h = head ? (fi == 0 ? headH - 8.0f * s : headH) : rowH;
        rowTop[fi + 1] = rowTop[fi] + h;
    }
    const float total = count > 0 ? rowTop[count] : rowH;

    const float W = 480.0f * s, R = 12.0f * s;
    const bool hasHints = MenuHasHints(menu);
    const bool icons = MenuUsesIcons(menu);
    const float pad = 10.0f * s;            // the selection's inset from the panel edge
    const float inset = 22.0f * s;          // header, description and footer text
    const float hintWrap = W - 2.0f * inset;
    const float headerH = 88.0f * s, searchH = menu.hasSearch ? 48.0f * s : 0.0f;
    const float descH = hasHints ? ImClamp(TallestHint(menu, body, hintSize, hintWrap) + 24.0f * s, 44.0f * s, 100.0f * s) : 0.0f;
    const float footerH = 50.0f * s;
    const float chrome = headerH + searchH + 8.0f * s + descH + footerH;
    // At a large interface size on a small screen fewer rows show, rather than
    // the panel running off the screen.
    const float viewH = ImMax(ImMin(ImMin(total, 11.0f * rowH), io.DisplaySize.y - 48.0f * s - chrome), ImMin(total, 3.0f * rowH));
    const float targetH = chrome + viewH;
    if (g_panelH <= 0.0f || ease < 1.0f || g_calm) g_panelH = targetH;
    g_panelH += (targetH - g_panelH) * Follow(dt, 18.0f);
    const float H = g_panelH;

    const float margin = 48.0f * s, slide = g_calm ? 0.0f : (1.0f - ease) * 16.0f * s;
    const float x0 = g_right ? io.DisplaySize.x - margin - W + slide : margin - slide;
    ImVec2 a(floorf(x0), floorf((io.DisplaySize.y - H) * 0.5f));
    ImVec2 b(a.x + W, a.y + H);

    ImDrawList* dl = ImGui::GetBackgroundDrawList();
    Panel(dl, a, b, R);
    dl->PushClipRect(a, b, true);

    // Header: the brand on a small line with where we are at its right end, the
    // menu's title under it. The brand is one fixed lockup in every menu: the
    // mark, "IRIDIUM" in the title's colour with its "S" in the accent, the
    // capitals spaced a little; a thin drawn slash (the font's, between two
    // spaces, was wide and as loud as the words); "Trainer M3" quieter. The path
    // gives way first and keeps its last part. It used to follow the brand on
    // the left, so the brand ran into it and moved with every menu (2026-10-21).
    const float hx = floorf(a.x + inset);
    const float textW = W - 2.0f * inset;
    {
        const float by = floorf(a.y + 18.0f * s), brandSize = 13.5f * s;
        // Segoe UI: capitals from 0.285 to 0.811 of the size below the top of the line
        const float capTop = by + 0.285f * brandSize, base = by + 0.811f * brandSize;
        const float mr = 5.25f * s;
        BrandMark(dl, floorf(hx + mr) + 0.5f, floorf((capTop + base) * 0.5f) + 0.5f, mr);
        float bx = floorf(hx + 2.0f * mr + 9.0f * s);
        const std::string name = Text(Str::RootTitle);
        const float track = 0.9f * s;
        const size_t cut = name.rfind(' ');
        if (cut == std::string::npos) {
            bx = Tracked(dl, semi, brandSize, bx, by, Hi(), name.c_str(), track);
        } else {
            bx = Tracked(dl, semi, brandSize, bx, by, Hi(), name.substr(0, cut).c_str(), track);
            bx = Tracked(dl, semi, brandSize, bx + Measure(semi, brandSize, " ").x + track, by, Accent(),
                name.substr(cut + 1).c_str(), track);
        }
        const float gap = 8.0f * s, sh = base - capTop + 4.0f * s, sw = sh * 0.36f;
        bx = floorf(bx + gap);
        dl->AddLine(V(bx, base + 2.0f * s), V(bx + sw, base + 2.0f * s - sh), Mute(), 1.0f * s);
        bx = floorf(bx + sw + gap);
        const char* brand = Text(Str::Brand);
        dl->AddText(body, brandSize, V(bx, by), Soft(), brand);
        bx = floorf(bx + Measure(body, brandSize, brand).x);
        std::string path;
        for (size_t i = 1; i < crumbs.size(); i++) path += (i > 1 ? PathSep : "") + crumbs[i];
        const float room = hx + textW - bx - 24.0f * s;
        if (!path.empty() && room > 40.0f * s) {
            path = FitText(body, smallSize, path, room, true);
            const float pw = Measure(body, smallSize, path.c_str()).x;
            dl->AddText(body, smallSize, V(floorf(hx + textW - pw), floorf(by + (brandSize - smallSize) * 0.5f)), Mute(), path.c_str());
        }
    }
    std::string title = FitText(semi, titleSize, menu.title.empty() ? Text(Str::Home) : menu.title, textW, false);
    dl->AddText(semi, titleSize, V(hx - 1.0f * s, floorf(a.y + 40.0f * s)), Hi(), title.c_str());
    dl->AddRectFilled(V(a.x, floorf(a.y + headerH) - 1.0f), V(b.x, floorf(a.y + headerH)), Line());

    float cy = a.y + headerH + 6.0f * s;

    if (menu.hasSearch) {
        ImVec2 sa(a.x + pad + 4.0f * s, cy + 4.0f * s), sb(b.x - pad - 4.0f * s, cy + 40.0f * s);
        bool empty = menu.searchBuffer[0] == '\0';
        dl->AddRectFilled(sa, sb, Fill(), 6.0f * s);
        dl->AddRect(sa, sb, empty ? Line(1.4f) : Accent(), 6.0f * s, 0, 1.0f * s);
        if (UiFonts::Icons)
            GlyphCentered(dl, UiFonts::Icons, 15.0f * s, V(sa.x + 18.0f * s, (sa.y + sb.y) * 0.5f), Soft(), Utf8(0xE721).c_str());
        float tx = sa.x + 36.0f * s, ty = floorf((sa.y + sb.y - bodySize) * 0.5f - 1.0f * s);
        std::string placeholder = Text(Str::Search);
        for (const auto& e : menu.entries)
            if (e.type == EntryType::Search && !e.searchPlaceholder.empty()) { placeholder += Sep + e.searchPlaceholder; break; }
        const char* shown = empty ? placeholder.c_str() : menu.searchBuffer;
        ImVec4 sclip(tx, sa.y, sb.x - 12.0f * s, sb.y);
        dl->AddText(body, bodySize, V(tx, ty), empty ? Mute() : Hi(), shown, nullptr, 0.0f, &sclip);
        if (fmodf((float)now, 1.0f) < 0.55f) {
            float cx = empty ? tx : tx + Measure(body, bodySize, shown).x + 2.0f * s;
            dl->AddRectFilled(V(cx, ty + 2.0f * s), V(cx + 1.5f * s, ty + bodySize), Hi(), 0.5f * s);
        }
        cy += searchH;
    }

    // Scroll so the selection, and the caption right above it, stay in view
    const float listTop = cy;
    const float listBot = listTop + viewH;
    const int sel = ImClamp(menu.selectedIndex, 0, ImMax(count - 1, 0));
    if (count > 0) {
        float selTop = rowTop[sel], selBot = rowTop[sel + 1];
        if (sel > 0 && !menu.IsSelectable(sel - 1)) selTop = rowTop[sel - 1];
        float margin2 = sel + 1 < count ? rowH * 0.6f : 0.0f;
        if (fresh) g_scrollTarget = menu.scroll;
        if (selTop - (sel > 0 ? rowH * 0.6f : 0.0f) < g_scrollTarget) g_scrollTarget = selTop - (sel > 0 ? rowH * 0.6f : 0.0f);
        if (selBot + margin2 > g_scrollTarget + viewH) g_scrollTarget = selBot + margin2 - viewH;
        g_scrollTarget = ImClamp(g_scrollTarget, 0.0f, ImMax(total - viewH, 0.0f));
        if (fresh || g_calm) menu.scroll = g_scrollTarget;
        menu.scroll += (g_scrollTarget - menu.scroll) * Follow(dt, 16.0f);
    }

    // The selection glides to its row in ~0.15 s.
    const float hiTop = listTop + rowTop[sel] - menu.scroll + 2.0f * s;
    const float hiBot = listTop + rowTop[ImMin(sel + 1, count)] - menu.scroll - 2.0f * s;
    if (fresh || g_calm) { g_hiTop = hiTop; g_hiBot = hiBot; }
    g_hiMenuId = menu.menuId;
    {
        float k = Follow(dt, 22.0f);
        g_hiTop += (hiTop - g_hiTop) * k;
        g_hiBot += (hiBot - g_hiBot) * k;
    }

    // Rows of a freshly opened menu slide in a little from the side we came from
    const float rowsIn = EaseOut((float)(now - g_menuShownAt) / (g_calm ? 0.10f : 0.18f));
    const float rowShift = g_calm ? 0.0f : (1.0f - rowsIn) * 12.0f * s * g_slideDir;
    g_a = ease * rowsIn;

    dl->PushClipRect(V(a.x, listTop - 1.0f * s), V(b.x, ImMin(listBot + 2.0f * s, b.y - footerH - descH)), true);

    if (count > 0 && menu.IsSelectable(sel)) {
        ImVec2 ha(a.x + pad, g_hiTop), hb(b.x - pad, ImMax(g_hiBot, g_hiTop + 8.0f * s));
        Selection(dl, ha, hb, 6.0f * s);
    }

    const float iconW = 20.0f * s;
    const float iconX = a.x + pad + 14.0f * s + iconW * 0.5f + rowShift;
    const float lx = icons ? iconX + iconW * 0.5f + 12.0f * s : a.x + pad + 14.0f * s + rowShift;
    const float rx = b.x - pad - 14.0f * s + rowShift;
    std::string main, value;
    for (int fi = 0; fi < count; fi++) {
        float ry = listTop + rowTop[fi] - menu.scroll;
        float rh = rowTop[fi + 1] - rowTop[fi];
        if (ry + rh < listTop - rowH || ry > listBot + rowH) continue;
        int realIdx = menu.GetFilteredEntryIndex(fi);
        if (realIdx < 0) continue;
        const auto& entry = menu.entries[realIdx];
        const float midY = ry + rh * 0.5f;

        if (entry.type == EntryType::Header) {
            ImVec4 cclip(a.x, ry, b.x - pad, ry + rh);
            dl->AddText(semi, capSize, V(floorf(a.x + pad + 14.0f * s + rowShift), floorf(ry + rh - capSize - 8.0f * s)), Soft(),
                entry.label.c_str(), nullptr, 0.0f, &cclip);
            continue;
        }

        const bool selected = (fi == sel);
        const float textA = !entry.enabled ? 0.38f : 1.0f;
        SplitLabel(entry.label, main, value);
        ImU32 ink = selected ? Hi(textA) : Main(textA);

        if (icons) {
            unsigned int g = IconFor(entry);
            if (g && UiFonts::Icons)
                GlyphCentered(dl, UiFonts::Icons, 17.0f * s, V(iconX, midY), selected ? Hi(textA) : Soft(textA), Utf8(g).c_str());
        }

        float labelRight = rx;
        if (entry.type == EntryType::Checkbox) {
            Switch(dl, rx, midY, entry.checked, textA);
            labelRight = rx - 52.0f * s;
        } else if (entry.type == EntryType::List) {
            const char* val = "";
            int n = (int)entry.listItems.size();
            if (entry.listSelectedIndex >= 0 && entry.listSelectedIndex < n)
                val = entry.listItems[entry.listSelectedIndex].c_str();
            float vsz = bodySize * 0.92f;
            ImVec2 vs = Measure(semi, vsz, val);
            float arrows = 13.0f * s;
            float vx = rx - arrows - vs.x;
            bool dots = n > 1 && n <= 8;
            float vy = floorf(midY - vsz * 0.5f - (dots ? 4.0f : 1.0f) * s);
            dl->AddText(semi, vsz, V(floorf(vx), vy), ink, val);
            ImU32 ac = Mute(textA);
            float cs = 4.0f * s;
            Chevron(dl, vx - 11.0f * s, midY - (dots ? 3.0f : 0.0f) * s, cs, ac, true);
            Chevron(dl, rx, midY - (dots ? 3.0f : 0.0f) * s, cs, ac);
            if (dots) {
                float gap = 7.0f * s, dw = gap * (n - 1);
                float dx0 = vx + vs.x * 0.5f - dw * 0.5f, dy = midY + 11.0f * s;
                for (int i = 0; i < n; i++) {
                    bool cur = i == entry.listSelectedIndex;
                    dl->AddCircleFilled(V(dx0 + gap * i, dy), cur ? 2.2f * s : 1.6f * s, cur ? Accent(textA) : Mute(0.45f * textA), 12);
                }
            }
            labelRight = vx - 26.0f * s;
        } else {
            float vr = rx;
            if (entry.submenu) {
                Chevron(dl, rx, midY, 4.2f * s, Mute(textA));
                vr = rx - 18.0f * s;
            }
            if (!value.empty()) {
                float vsz = bodySize * 0.86f;
                float maxW = ImMax(vr - (lx + 90.0f * s), 20.0f * s);
                std::string shown = FitText(semi, vsz, value, maxW, false);
                float vw = Measure(semi, vsz, shown.c_str()).x;
                dl->AddText(semi, vsz, V(floorf(vr - vw), floorf(midY - vsz * 0.5f - 1.0f * s)), Soft(textA), shown.c_str());
                vr = vr - vw - 12.0f * s;
            }
            labelRight = vr;
        }

        ImVec4 clip(lx, ry, labelRight, ry + rh);
        dl->AddText(selected ? semi : body, bodySize, V(floorf(lx), floorf(midY - bodySize * 0.5f - 1.0f * s)), ink, main.c_str(),
            nullptr, 0.0f, &clip);
    }

    if (count == 0) {
        const char* msg = (menu.hasSearch && menu.searchBuffer[0] != '\0') ? Text(Str::NothingFound) : Text(Str::Empty);
        dl->AddText(body, bodySize, V(a.x + pad + 14.0f * s, floorf(listTop + (rowH - bodySize) * 0.5f)), Mute(), msg);
    }

    dl->PopClipRect();
    g_a = ease;

    if (total > viewH + 1.0f) {
        float trackTop = listTop + 6.0f * s, trackLen = viewH - 12.0f * s;
        float thumb = ImMax(trackLen * viewH / total, 24.0f * s);
        float k = menu.scroll / (total - viewH);
        float ty0 = trackTop + (trackLen - thumb) * ImClamp(k, 0.0f, 1.0f);
        float sx = b.x - 6.0f * s;
        dl->AddRectFilled(V(sx, ty0), V(sx + 3.0f * s, ty0 + thumb), Mute(0.55f), 1.5f * s);
    }

    // Description of the selected item
    const float fy = b.y - footerH;
    if (hasHints) {
        float dy = fy - descH;
        dl->AddRectFilled(V(a.x, dy), V(b.x, dy + 1.0f), Line());
        int ri = menu.GetFilteredEntryIndex(sel);
        if (ri != g_hintSel) { g_hintSel = ri; g_hintAt = now; }
        float k = ImClamp((float)(now - g_hintAt) / (g_calm ? 0.08f : 0.15f), 0.0f, 1.0f);
        if (ri >= 0 && !menu.entries[ri].hint.empty()) {
            float saved = g_a;
            g_a *= k;
            float iy = floorf(dy + 12.0f * s + (g_calm ? 0.0f : (1.0f - k) * 3.0f * s));
            ImVec4 dclip(a.x, dy + 4.0f * s, b.x - 18.0f * s, fy - 2.0f * s);
            dl->AddText(body, hintSize, V(hx, iy), Soft(), menu.entries[ri].hint.c_str(), nullptr, hintWrap, &dclip);
            g_a = saved;
        }
    }

    // Footer: key hints
    dl->AddRectFilled(V(a.x, fy), V(b.x, fy + 1.0f), Line());
    float kx = hx - 2.0f * s, ky = floorf(fy + (footerH - 22.0f * s) * 0.5f + 1.0f * s);
    kx = Keycap(dl, kx, ky, "\xE2\x86\x91\xE2\x86\x93", Text(Str::Select), semi, body);
    kx = Keycap(dl, kx, ky, "Enter", Text(Str::Ok), semi, body);
    int selReal = menu.GetFilteredEntryIndex(sel);
    bool onList = selReal >= 0 && menu.entries[selReal].type == EntryType::List;
    if (onList)
        kx = Keycap(dl, kx, ky, "\xE2\x86\x90\xE2\x86\x92", Text(Str::Value), semi, body);
    if (crumbs.empty()) {
        Keycap(dl, kx, ky, "Esc", Text(Str::Close), semi, body);
    } else {
        kx = Keycap(dl, kx, ky, "Esc", Text(Str::Back), semi, body);
        if (!onList)
            Keycap(dl, kx, ky, "F4", Text(Str::Close), semi, body);
    }

    dl->PopClipRect();
    g_a = 1.0f;
}

void MenuRender::DrawToasts(const std::vector<ToastView>& toasts, double now, double life) {
    if (toasts.empty()) return;
    ImGuiIO& io = ImGui::GetIO();
    g_s = ScaleFor(io);
    const float s = g_s;
    const Theme* theme = g_t;
    g_t = &Dark;
    ImFont* body = UiFonts::Body ? UiFonts::Body : ImGui::GetFont();
    ImFont* semi = UiFonts::Semibold ? UiFonts::Semibold : body;
    const float size = 16.0f * s;
    const float maxW = 560.0f * s;
    const float iconW = 18.0f * s;
    const float textX = 16.0f * s + iconW + 10.0f * s;
    const float wrap = maxW - textX - 18.0f * s;

    float y = 24.0f * s;
    ImDrawList* dl = ImGui::GetForegroundDrawList();

    size_t start = toasts.size() > 3 ? toasts.size() - 3 : 0;
    for (size_t i = start; i < toasts.size(); i++) {
        const ToastView& toast = toasts[i];
        float age = (float)(now - toast.born);
        float in = EaseOut(age / (g_calm ? 0.12f : 0.20f));
        float out = ImClamp(((float)life - age) / 0.4f, 0.0f, 1.0f);
        float k = ImMin(in, out);
        g_a = k;
        ImVec2 ts = semi->CalcTextSizeA(size, FLT_MAX, wrap, toast.text.c_str());
        float h = ImMax(ts.y + 22.0f * s, 44.0f * s);
        float w = ImMin(maxW, ts.x + textX + 18.0f * s);
        float x = floorf((io.DisplaySize.x - w) * 0.5f);
        float yy = floorf(y - (g_calm ? 0.0f : (1.0f - k) * 8.0f * s));
        ImVec2 a(x, yy), b(x + w, yy + h);
        float r = 10.0f * s;

        Panel(dl, a, b, r);
        dl->PushClipRect(a, b, true);
        // Time left: a thin line along the bottom
        float left = ImClamp(1.0f - age / (float)life, 0.0f, 1.0f);
        float x0 = a.x + r, x1 = a.x + r + (w - 2.0f * r) * left;
        if (x1 > x0 + 1.0f)
            dl->AddRectFilled(V(x0, b.y - 2.0f * s), V(x1, b.y - 1.0f * s), Accent(0.55f), 1.0f * s);
        if (UiFonts::Icons)
            GlyphCentered(dl, UiFonts::Icons, 16.0f * s, V(a.x + 16.0f * s + iconW * 0.5f, a.y + h * 0.5f), Accent(),
                Utf8(0xE946).c_str());
        dl->AddText(semi, size, V(floorf(a.x + textX), floorf(a.y + (h - ts.y) * 0.5f - 1.0f * s)), Hi(),
            toast.text.c_str(), nullptr, wrap);
        dl->PopClipRect();
        y += (h + 8.0f * s) * k;
    }
    g_a = 1.0f;
    g_t = theme;
}
