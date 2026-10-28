#define AppVersion "1.0.0"
[Setup]
AppId={{7C4A1E92-3B6D-4F58-9E21-A5D0C7B4F831}
AppName=Waylore 客行录
AppVersion={#AppVersion}
AppPublisher=Waylore
DefaultDirName={localappdata}\Programs\客行录
DefaultGroupName=客行录
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
OutputDir=..\dist\unified-release
OutputBaseFilename=Kexinglu-Setup-1.0.0
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\客行录.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked
[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Excludes: "Waylore.exe"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "build\windows\x64\runner\Release\Waylore.exe"; DestDir: "{app}"; DestName: "客行录.exe"; Flags: ignoreversion
[Icons]
Name: "{group}\客行录"; Filename: "{app}\客行录.exe"
Name: "{autodesktop}\客行录"; Filename: "{app}\客行录.exe"; Tasks: desktopicon
[Run]
Filename: "{app}\客行录.exe"; Description: "Launch Waylore"; Flags: nowait postinstall skipifsilent
