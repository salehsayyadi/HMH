; HMH Windows Setup Installer Inno Setup Script
; Imam Hossein Schools Central Amphitheater Reservation System
#define MyAppName "HMH Amphitheater Reservation"
#define MyAppPersianName "سامانه رزرو آمفی‌تئاتر مدارس امام حسین (ع)"
#define MyAppVersion "1.0.9"
#define MyAppPublisher "Imam Hossein Charitable Cultural and Educational Institute"
#define MyAppURL "https://reserve.salehvip-clud.ir"
#define MyAppExeName "hmh_windows_app.exe"

[Setup]
AppId={{D4B39A01-C72E-4D6E-9E8F-87E5C3A12345}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\..\..\app\Windows\Setup
OutputBaseFilename=HMH-Setup-x64
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=lowest
SetupIconFile=..\..\windows_app\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\..\app\Windows\Portable\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppPersianName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppPersianName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
