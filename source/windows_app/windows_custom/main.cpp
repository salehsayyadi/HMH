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

  if (!window.Create(L"سامانه رزرواسیون آمفی‌تئاتر مدارس امام حسین (ع) یزد", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
