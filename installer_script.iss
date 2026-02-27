[Setup]
AppName=DNS Changer
AppVersion=1.2.0
AppPublisher=KnoxPlus
DefaultDirName={autopf}\DNS Changer
DefaultGroupName=DNS Changer
OutputDir=.\
OutputBaseFilename=DNSChanger_Setup_v1.2.0
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin
SetupIconFile=.\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\dnschanger.exe

[Files]
Source: ".\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\DNS Changer"; Filename: "{app}\dnschanger.exe"
Name: "{autodesktop}\DNS Changer"; Filename: "{app}\dnschanger.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

[Run]
Filename: "{app}\dnschanger.exe"; Description: "Launch DNS Changer"; Flags: nowait postinstall skipifsilent runascurrentuser
