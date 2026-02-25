[Setup]
AppId={{5D0E0E2C-8B1A-4B6A-912A-18A3FD7C1F21}
AppName=DNS Changer
AppVersion=1.0.0
AppPublisher=KnoxPlus
AppPublisherURL=https://github.com/knoxplus/dnsc
AppSupportURL=https://github.com/knoxplus/dnsc
AppUpdatesURL=https://github.com/knoxplus/dnsc
DefaultDirName={autopf}\DNS Changer
DisableProgramGroupPage=yes
PrivilegesRequired=admin
OutputDir=.\
OutputBaseFilename=DNSChanger_Installer
SetupIconFile=.\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: ".\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\DNS Changer"; Filename: "{app}\dnschanger.exe"
Name: "{autodesktop}\DNS Changer"; Filename: "{app}\dnschanger.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\dnschanger.exe"; Description: "{cm:LaunchProgram,DNS Changer}"; Flags: nowait postinstall skipifsilent shellexec
