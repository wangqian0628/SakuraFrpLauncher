﻿#define AppName "SakuraFrp 启动器"
#define AppVersion ""

#define MainExecutable "SakuraLauncher.exe"

#define LibraryNameNet ".NET Framework 4.8"
#define LibraryNameVC "Visual C++ 2015-2019 Redistributable (x86)"

[Setup]
; Basics
AppId=SakuraFrpLauncher
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} v{#GetFileVersion("_publish\SakuraLibrary\SakuraLibrary.dll")}
AppCopyright=Copyright © FENGberd 2020-2021

AppPublisher=SakuraFrp
AppPublisherURL=https://www.natfrp.com/
AppSupportURL=https://www.natfrp.com/

; Wizard
WizardStyle=modern
LicenseFile=LICENSE
ShowComponentSizes=yes
AlwaysShowDirOnReadyPage=yes
UninstallDisplayName={#AppName}
ArchitecturesInstallIn64BitMode=x64

DefaultDirName={autopf}\SakuraFrpLauncher
DefaultGroupName={#AppName}

DisableDirPage=yes
DisableProgramGroupPage=yes

; Output
OutputDir=bin
OutputBaseFilename=SakuraLauncher

; Compression
Compression=lzma2
SolidCompression=yes
LZMANumBlockThreads=18
LZMAUseSeparateProcess=yes

[Languages]
Name: "ChineseSimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Types]
Name: "default"; Description: "默认设置";
Name: "custom"; Description: "自定义"; Flags: iscustom;

[Components]
Name: "frpc"; Description: "frpc"; Types: default custom; Flags: fixed
Name: "frpc\x86"; Description: "frpc (32 位)"; Check: IsX86; Types: default custom; Flags: exclusive fixed
Name: "frpc\x64"; Description: "frpc (64 位)"; Check: IsX64; Types: default custom; Flags: exclusive fixed

Name: "launcher"; Description: "守护进程"; Types: default custom; Flags: fixed
Name: "launcher\service"; Description: "安装为系统服务";

Name: "launcher_ui"; Description: "用户界面"; Types: default custom; Flags: fixed
Name: "launcher_ui\wpf"; Description: "WPF 界面"; Types: default; Flags: exclusive
Name: "launcher_ui\legacy"; Description: "传统界面 (不推荐)"; Types: custom; Flags: exclusive

Name: "updater"; Description: "自动更新程序"; Types: default custom

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
Source: "_publish\sign\frpc_windows_386.exe"; DestDir: "{app}"; DestName: "frpc.exe"; Flags: ignoreversion; Components: "frpc\x86"
Source: "_publish\sign\frpc_windows_386.exe.sig"; DestDir: "{app}"; DestName: "frpc.exe.sig"; Flags: ignoreversion; Components: "frpc\x86"
Source: "_publish\sign\frpc_windows_amd64.exe"; DestDir: "{app}"; DestName: "frpc.exe"; Flags: ignoreversion; Components: "frpc\x64"
Source: "_publish\sign\frpc_windows_amd64.exe.sig"; DestDir: "{app}"; DestName: "frpc.exe.sig"; Flags: ignoreversion; Components: "frpc\x64"

Source: "_publish\SakuraLibrary\*"; DestDir: "{app}"; Flags: ignoreversion; Components: "launcher"
Source: "_publish\SakuraFrpService\*"; DestDir: "{app}"; Flags: ignoreversion; Components: "launcher"

Source: "_publish\SakuraLauncher\*"; DestDir: "{app}"; Flags: ignoreversion; Components: "launcher_ui\wpf"
Source: "_publish\LegacyLauncher\*"; DestDir: "{app}"; Flags: ignoreversion; Components: "launcher_ui\legacy"

Source: "SakuraFrpService\Resources\Updater.exe"; DestDir: "{app}"; Flags: ignoreversion; Components: "updater"

[Icons]
; Start Menu
Name: "{group}\{#AppName}"; Filename: "{app}\SakuraLauncher.exe"; Components: "launcher_ui\wpf"
Name: "{group}\{#AppName}"; Filename: "{app}\LegacyLauncher.exe"; Components: "launcher_ui\legacy"

Name: "{group}\访问 SakuraFrp 管理面板"; Filename: "https://www.natfrp.com/user/"

Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"

; Desktop Icon
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\SakuraLauncher.exe"; Components: "launcher_ui\wpf"; Tasks: "desktopicon"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\LegacyLauncher.exe"; Components: "launcher_ui\legacy"; Tasks: "desktopicon"

[Run]
; Service
Filename: "{app}\SakuraFrpService.exe"; Parameters: "--install"; StatusMsg: "正在安装系统服务..."; Components: "launcher\service"

; Post Install Actions
Filename: "{app}\SakuraLauncher.exe"; Description: "{cm:LaunchProgram,{#AppName}}"; Components: "launcher_ui\wpf"; Flags: nowait postinstall skipifsilent
Filename: "{app}\LegacyLauncher.exe"; Description: "{cm:LaunchProgram,{#AppName}}"; Components: "launcher_ui\legacy"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{app}\SakuraFrpService.exe"; Parameters: "--uninstall"; RunOnceId: "RemoveService"; Components: "launcher\service"

[UninstallDelete]
Type: files; Name: "{app}\InstallUtil.InstallLog"
Type: files; Name: "{app}\SakuraFrpService.InstallLog"

Type: dirifempty; Name: "{app}"

[Code]
var
	requiresRestart: Boolean;
	downloadPage: TDownloadWizardPage;

	installVC: Boolean;
	installNet: Boolean;
	
function IsX64: Boolean;
begin
	Result := Is64BitInstallMode and (ProcessorArchitecture = paX64);
end;

function IsX86: Boolean;
begin
	Result := (Is64BitInstallMode=false) and (ProcessorArchitecture = paX86);
end;

function TryInstall(const Name, File, Args: String): String;
var
	resultCode: Integer;
	outputPage: TOutputProgressWizardPage;
begin
	outputPage := CreateOutputProgressPage('安装运行环境', '正在安装 ' + Name);
	outputPage.ProgressBar.Style := npbstMarquee;
	outputPage.ProgressBar.Visible := True;
	outputPage.Show;
	
	if not Exec(ExpandConstant('{tmp}\' + File), Args, '', SW_SHOW, ewWaitUntilTerminated, resultCode) then
	begin
		Result := Name + ' 安装失败: ' + SysErrorMessage(resultCode);
	end else begin
		case resultCode of
			0: ;
			1641, 3010: requiresRestart := True;
			else begin
				Result := Name + ' 安装失败: 错误代码 ' + IntToStr(resultCode);
			end;
		end;
	end;
	
	outputPage.Hide;
end;

//// Install Events ///////////////////////////////////////////

procedure InitializeWizard;
var
	version: Cardinal;
begin
	downloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), SetupMessage(msgPreparingDesc), nil);
	
	installVC := not FileExists(ExpandConstant('{syswow64}\msvcp140.dll'));
	installNet := (not RegQueryDWordValue(HKLM, 'SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full', 'Release', version)) or (version < 378389);
end;

function UpdateReadyMemo(const Space, NewLine, MemoUserInfoInfo, MemoDirInfo, MemoTypeInfo, MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
begin
	Result := '';
	
	if installVC or installNet then begin
		Result := Result + '运行环境 (需要联网下载):';
		
		if installNet then
			Result := Result + Newline + Space + '{#LibraryNameNet}';
	
		if installVC then
			Result := Result + Newline + Space + '{#LibraryNameVC}';
	
		Result := Result + Newline + NewLine;
	end;
	
	if MemoUserInfoInfo <> '' then
		Result := Result + MemoUserInfoInfo + Newline + NewLine;

	if MemoDirInfo <> '' then
		Result := Result + MemoDirInfo + Newline + NewLine;

	if MemoTypeInfo <> '' then
		Result := Result + MemoTypeInfo + Newline + NewLine;

	if MemoComponentsInfo <> '' then
		Result := Result + MemoComponentsInfo + Newline + NewLine;

	if MemoGroupInfo <> '' then
		Result := Result + MemoGroupInfo + Newline + NewLine;

	if MemoTasksInfo <> '' then
		Result := Result + MemoTasksInfo + Newline + NewLine;
end;

function NextButtonClick(const CurPageID: Integer): Boolean;
var
	retry: Boolean;
begin
	Result := True;
	if (CurPageID = wpReady) and (installNet or installVC) then begin
		try
			downloadPage.Show;
			downloadPage.Clear;
			
			if installNet then
				downloadPage.Add('https://download.visualstudio.microsoft.com/download/pr/014120d7-d689-4305-befd-3cb711108212/1f81f3962f75eff5d83a60abd3a3ec7b/ndp48-web.exe', 'dotnet.exe', 'b9821f28facfd6b11ffbf3703ff3f218cc3c31b85d6503d5c20570751ff08876');
			
			if installVC then
				downloadPage.Add('https://aka.ms/vs/16/release/vc_redist.x86.exe', 'vcredist.exe', '50a3e92ade4c2d8f310a2812d46322459104039b9deadbd7fdd483b5c697c0c8');
			
			retry := True;
			while retry do begin
				retry := False;
				try
					downloadPage.Download;
				except
					if GetExceptionMessage = SetupMessage(msgErrorDownloadAborted) then
						Result := False
					else case SuppressibleMsgBox(AddPeriod(GetExceptionMessage), mbError, MB_RETRYCANCEL, IDCANCEL) of
						IDRETRY: retry := True;
						IDCANCEL: Result := False;
					end;
				end;
			end;
		finally
			downloadPage.Hide;
		end;
	end;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
	if installNet then
		Result := TryInstall('{#LibraryNameNet}', 'dotnet.exe', '/passive /norestart /showrmui /showfinalerror');

	if (Result = '') and installVC then
		Result := TryInstall('{#LibraryNameVC}', 'vcredist.exe', '/passive /norestart');
end;

function NeedRestart(): Boolean;
begin
	Result := requiresRestart;
end;

//// Uninstall Events ///////////////////////////////////////////

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
	// Not sure if this is really appropriate, especially for LegacyLauncher dir
//	if CurUninstallStep = usPostUninstall and MsgBox('删除启动器配置文件?', mbConfirmation, MB_YESNO) = IDYES then
//		DelTree(ExpandConstant('{userappdata}\SakuraLauncher'), True, True, True);
//		DelTree(ExpandConstant('{userappdata}\LegacyaLauncher'), True, True, True);
//		DelTree(ExpandConstant('{userappdata}\SakuraFrpService'), True, True, True);
//	end;
end; 
