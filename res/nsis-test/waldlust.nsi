; Waldlust 원격지원 — Defender 오탐(Bearfoos.B!ml) A/B 테스트용 NSIS 인스톨러.
; 목적: 자체제작 자기추출 패커(rustdesk-portable-packer) 대신, 세상에 흔히 쓰이는
; NSIS 표준 인스톨러 스텁으로 감싸면 Defender ML 휴리스틱 반응이 달라지는지 확인.
; 앱 자체(--silent-install 등)는 전혀 안 건드림 — "설치 파일 형식" 하나만 바꿔서 비교.
!include "MUI2.nsh"

Name "Waldlust 원격지원"
OutFile "waldlust-1.4.8-x86_64-nsis-test.exe"
InstallDir "$PROGRAMFILES64\Waldlust"
RequestExecutionLevel admin
Unicode true

!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Korean"

Section "Install"
  SetOutPath "$INSTDIR"
  ; 빌드시 이 스크립트와 같은 폴더에 배치되는 flutter 빌드 산출물(rustdesk/ 폴더 내용) 전체 포함.
  File /r "rustdesk\*.*"

  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; 표준 인스톨러다운 제거정보 등록(정상 소프트웨어 신호로도 도움).
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Waldlust" \
    "DisplayName" "Waldlust 원격지원"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Waldlust" \
    "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Waldlust" \
    "Publisher" "Waldlust Co., Ltd."
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Waldlust" \
    "DisplayVersion" "1.4.8"

  ; 앱 자체의 무인 설치(서비스 등록)를 그대로 트리거 — 동작은 기존과 완전히 동일하게 유지.
  ExecWait '"$INSTDIR\wald-remote.exe" --silent-install'
SectionEnd

Section "Uninstall"
  ExecWait '"$INSTDIR\wald-remote.exe" --uninstall'
  RMDir /r "$INSTDIR"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Waldlust"
SectionEnd
