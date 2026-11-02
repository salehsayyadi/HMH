#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);

  // Calculate screen resolution and center the window with balanced square proportions
  int screenWidth = ::GetSystemMetrics(SM_CXSCREEN);
  int screenHeight = ::GetSystemMetrics(SM_CYSCREEN);

  // Balanced near-square proportion that fits desktop screens comfortably
  int windowHeight = (screenHeight > 980) ? 920 : static_cast<int>(screenHeight * 0.88);
  int windowWidth = windowHeight + 80; // square-like ratio (approx 1:1)

  int x = (screenWidth - windowWidth) / 2;
  int y = (screenHeight - windowHeight) / 2;
  if (x < 0) x = 20;
  if (y < 0) y = 20;

  Win32Window::Point origin(x, y);
  Win32Window::Size size(windowWidth, windowHeight);

  // Persian title encoded via explicit 16-bit Unicode escape literals
  // to guarantee exact rendering without any compiler ANSI/Windows-1252 mojibake
  const wchar_t* persianTitle = L"\u0633\u0627\u0645\u0627\u0646\u0647 \u0631\u0632\u0631\u0648 \u0622\u0645\u0641\u06cc\u200c\u062a\u0626\u0627\u062a\u0631 \u0645\u062f\u0627\u0631\u0633 \u0627\u0645\u0627\u0645 \u062d\u0633\u06cc\u0646 (\u0639) \u06cc\u0632\u062f";

  if (!window.Create(persianTitle, origin, size)) {
    return EXIT_FAILURE;
  }

  ::SetWindowTextW(window.GetHandle(), persianTitle);

  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
