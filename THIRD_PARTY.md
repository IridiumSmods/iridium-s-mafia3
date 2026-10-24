# Third-party software in IRIDIUM S

| Component | Where | Author | License | Home |
|---|---|---|---|---|
| Mafia3ScriptHook and its trainer | `scripts\Mafia3ScriptHook.asi`, `ScriptHook\lua\trainer` | Kamzik123 | MIT, full text in `Mafia3ScriptHook_MIT.txt` | the Mafia3ScriptHook repository |
| Dear ImGui | inside `Mafia3ScriptHook.asi` | Omar Cornut | MIT | https://github.com/ocornut/imgui |
| MinHook | inside `Mafia3ScriptHook.asi` | Tsuda Kageyu | BSD 2-Clause | https://github.com/TsudaKageyu/minhook |
| Hacker Disassembler Engine 64 (in MinHook) | inside `Mafia3ScriptHook.asi` | Vyacheslav Patkov | BSD 2-Clause | part of MinHook |
| kiero | inside `Mafia3ScriptHook.asi` | Rebzzel | MIT | https://github.com/Rebzzel/kiero |
| Ultimate ASI Loader | `dinput8.dll` | ThirteenAG | MIT | https://github.com/ThirteenAG/Ultimate-ASI-Loader |
| PyInstaller bootloader (only when `fp_camera.exe` is shipped) | `IRIDIUM\fp_camera\fp_camera.exe` | the PyInstaller team | GPL 2.0 with an exception that allows bundling any program | https://pyinstaller.org |
| Python, its standard library and the libraries of its Windows build (only inside `fp_camera.exe`) | `IRIDIUM\fp_camera\fp_camera.exe` | Python Software Foundation and the authors named in the license file | PSF License Agreement and the licenses it lists, full text in `Python_LICENSE.txt` (in the First Person Camera file) | https://www.python.org |
| zopfli and its Python bindings (only inside `fp_camera.exe`) | `IRIDIUM\fp_camera\fp_camera.exe` | Google (zopfli), the py-zopfli authors | Apache 2.0, full text in `zopfli_LICENSE.txt` (in the First Person Camera file) | https://github.com/fonttools/py-zopfli |

## MIT License (Dear ImGui, kiero, Ultimate ASI Loader)

Copyright (c) 2014-2025 Omar Cornut (Dear ImGui)
Copyright (c) Rebzzel (kiero)
Copyright (c) ThirteenAG (Ultimate ASI Loader)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## MinHook

MinHook - The Minimalistic API Hooking Library for x64/x86
Copyright (C) 2009-2017 Tsuda Kageyu.
All rights reserved.

Portions of MinHook (the Hacker Disassembler Engine 64 C) are
Copyright (c) 2008-2009, Vyacheslav Patkov, under the same terms.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
