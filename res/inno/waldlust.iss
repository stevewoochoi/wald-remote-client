; Waldlust 원격지원 — 표준 Windows 설치 프로그램(Inno Setup).
;
; 설계 의도(중요):
;  - 자기추출 packer/requireAdministrator/자동 silent-install 을 버리고, "흔한 Inno 인스톨러"
;    한 개로 배포한다. Defender ML 이 가장 덜 의심하는 형태.
;  - 이 인스톨러는 파일 복사 + 제어판 등록 + 시작메뉴만 담당한다.
;  - 서비스 등록/방화벽/URL 프로토콜 같은 RustDesk 고유 작업은 앱 본체의
;    "wald-remote.exe --after-install" 을 호출해서 위임한다.
;  - 설치 경로는 반드시 {autopf}\Waldlust 로 고정한다. RustDesk 의 --after-install /
;    --uninstall 이 get_default_install_path()=="C:\Program Files\<APP_NAME=Waldlust>" 를
;    기준으로 exe 를 찾기 때문. (경로를 바꾸면 서비스 등록이 어긋난다 → DisableDirPage=yes)
;
; 빌드: ISCC.exe /DMyBuildDir=<flutter build 산출물 폴더> waldlust.iss

#ifndef MyAppVersion
  #define MyAppVersion "1.4.8"
#endif
#ifndef MyBuildDir
  #define MyBuildDir "rustdesk"
#endif

[Setup]
AppId={{C5B0E6A2-4B3D-4F1E-9A7C-WALDLUST0001}
AppName=Waldlust 원격지원
AppVersion={#MyAppVersion}
AppPublisher=Waldlust Co., Ltd.
AppPublisherURL=https://remote.waldpay.co.kr
DefaultDirName={autopf}\Waldlust
DisableDirPage=yes
DisableProgramGroupPage=yes
DefaultGroupName=Waldlust 원격지원
UninstallDisplayName=Waldlust 원격지원
UninstallDisplayIcon={app}\wald-remote.exe
OutputBaseFilename=waldlust-setup-{#MyAppVersion}-x86_64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=..\icon.ico
CloseApplications=yes
; 코드서명은 SignTool 을 등록해 두면 여기서 자동 적용된다(향후):
; SignTool=mysigner
; SignedUninstaller=yes

[Languages]
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"

[Files]
; flutter windows 빌드 산출물 폴더 전체(wald-remote.exe + DLL + data\ + 서비스 등)를 그대로 복사.
Source: "{#MyBuildDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\Waldlust 원격지원"; Filename: "{app}\wald-remote.exe"
Name: "{group}\Waldlust 원격지원 제거"; Filename: "{uninstallexe}"
; 바탕화면 숏컷(모든 사용자 공용 데스크톱). 관리자 설치라 {autodesktop}={commondesktop}.
Name: "{autodesktop}\Waldlust 원격지원"; Filename: "{app}\wald-remote.exe"; \
  IconFilename: "{app}\wald-remote.exe"; Comment: "Waldlust 원격지원"

[Run]
; RustDesk 고유 설치 후처리: 서비스(sc create) + 방화벽 예외 + rustdesk:// 프로토콜 등록.
; 파일이 이미 {app} 에 복사된 상태에서 호출해야 하며, 관리자 권한으로 실행된다(인스톨러가 admin).
Filename: "{app}\wald-remote.exe"; Parameters: "--after-install"; \
  StatusMsg: "서비스 등록 중..."; Flags: runhidden waituntilterminated
; 이중 보장(belt-and-suspenders): --after-install 의 서비스 시작이 타이밍/권한 문제로 실패해도
; 무인 원격이 끊기지 않도록 서비스 자동시작·즉시시작·크래시 자동복구를 인스톨러에서 한 번 더 확정한다.
; (이미 되어 있으면 무해 — sc start 는 이미 실행 중이면 1056 을 반환하고 끝. 서비스 미생성 시엔
;  config/start 가 1060 으로 실패하지만 위 --after-install 이 생성을 책임진다.)
Filename: "{sys}\sc.exe"; Parameters: "config Waldlust start= auto"; \
  StatusMsg: "서비스 자동시작 설정..."; Flags: runhidden waituntilterminated
Filename: "{sys}\sc.exe"; Parameters: "failure Waldlust reset= 86400 actions= restart/5000/restart/5000/restart/10000"; \
  Flags: runhidden waituntilterminated
Filename: "{sys}\sc.exe"; Parameters: "start Waldlust"; \
  StatusMsg: "서비스 시작 중..."; Flags: runhidden waituntilterminated
; 설치 완료 후 앱을 바로 띄우고 싶으면 아래 주석 해제(선택):
; Filename: "{app}\wald-remote.exe"; Description: "Waldlust 원격지원 실행"; \
;   Flags: nowait postinstall skipifsilent

[UninstallRun]
; 제거 시: 서비스 중지·삭제 + 방화벽 규칙 삭제 + 레지스트리 정리.
Filename: "{app}\wald-remote.exe"; Parameters: "--before-uninstall"; \
  Flags: runhidden waituntilterminated; RunOnceId: "WaldlustBeforeUninstall"
