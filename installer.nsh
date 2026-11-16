!ifndef BUILD_UNINSTALLER
  !include "MUI2.nsh"
  !include "nsDialogs.nsh"
  !include "LogicLib.nsh"

  Var AssocPdfCheckbox
  Var AssocPdfState
  Var DesktopShortcutCheckbox
  Var DesktopShortcutState
  Var StartMenuShortcutCheckbox
  Var StartMenuShortcutState

  ; ---------- Halaman: asosiasi file PDF ----------
  Function pdfAssocPageCreate
    !insertmacro MUI_HEADER_TEXT "File Association" "Choose whether BV Reader should open PDF files."
    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
      Abort
    ${EndIf}

    ${NSD_CreateLabel} 0 0 100% 36u "If you select this option, PDF files will be listed with BV Reader in Windows. You can change the default PDF app later in Windows Settings > Apps > Default apps."
    Pop $0

    ${NSD_CreateCheckbox} 0 44u 100% 12u "Associate .PDF files with BV Reader"
    Pop $AssocPdfCheckbox
    ${NSD_SetState} $AssocPdfCheckbox $AssocPdfState

    nsDialogs::Show
  FunctionEnd

  Function pdfAssocPageLeave
    ${NSD_GetState} $AssocPdfCheckbox $AssocPdfState
  FunctionEnd

  ; ---------- Halaman: shortcut Desktop dan Start Menu ----------
  Function shortcutPageCreate
    !insertmacro MUI_HEADER_TEXT "Shortcuts" "Choose where to create shortcuts for BV Reader."
    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
      Abort
    ${EndIf}

    ${NSD_CreateLabel} 0 0 100% 24u "Select the shortcuts you want. Click Install to start the installation."
    Pop $0

    ${NSD_CreateCheckbox} 0 32u 100% 12u "Create a Desktop shortcut"
    Pop $DesktopShortcutCheckbox
    ${NSD_SetState} $DesktopShortcutCheckbox $DesktopShortcutState

    ${NSD_CreateCheckbox} 0 50u 100% 12u "Create a Start Menu shortcut"
    Pop $StartMenuShortcutCheckbox
    ${NSD_SetState} $StartMenuShortcutCheckbox $StartMenuShortcutState

    ; Halaman ini adalah halaman terakhir sebelum instalasi
    GetDlgItem $0 $HWNDPARENT 1
    SendMessage $0 ${WM_SETTEXT} 0 "STR:$(^InstallBtn)"

    nsDialogs::Show
  FunctionEnd

  Function shortcutPageLeave
    ${NSD_GetState} $DesktopShortcutCheckbox $DesktopShortcutState
    ${NSD_GetState} $StartMenuShortcutCheckbox $StartMenuShortcutState
  FunctionEnd
!endif


; Nilai awal semua pilihan = tercentang (juga dipakai saat instalasi senyap /S)
!macro customInit
  StrCpy $AssocPdfState ${BST_CHECKED}
  StrCpy $DesktopShortcutState ${BST_CHECKED}
  StrCpy $StartMenuShortcutState ${BST_CHECKED}
!macroend

; Urutan halaman: License -> Folder instalasi -> (dua halaman di bawah) -> Install
!macro customPageAfterChangeDir
  Page custom pdfAssocPageCreate pdfAssocPageLeave
  Page custom shortcutPageCreate shortcutPageLeave
!macroend

!macro customInstall
  ; ----- Asosiasi PDF (hanya jika dicentang) -----
  ${If} $AssocPdfState == ${BST_CHECKED}
    WriteRegStr SHCTX "Software\Classes\.pdf\OpenWithProgids" "id.bellavoz.bvreader.pdf" ""
    WriteRegStr SHCTX "Software\Classes\id.bellavoz.bvreader.pdf" "" "PDF Document"
    WriteRegStr SHCTX "Software\Classes\id.bellavoz.bvreader.pdf\DefaultIcon" "" "$INSTDIR\${APP_EXECUTABLE_FILENAME},0"
    WriteRegStr SHCTX "Software\Classes\id.bellavoz.bvreader.pdf\shell\open\command" "" '"$INSTDIR\${APP_EXECUTABLE_FILENAME}" "%1"'

    ; Supaya BV Reader muncul di Windows Settings > Default apps
    WriteRegStr SHCTX "Software\BellaVoz\BV Reader\Capabilities" "ApplicationName" "BV Reader"
    WriteRegStr SHCTX "Software\BellaVoz\BV Reader\Capabilities" "ApplicationDescription" "PDF reader and slide show"
    WriteRegStr SHCTX "Software\BellaVoz\BV Reader\Capabilities\FileAssociations" ".pdf" "id.bellavoz.bvreader.pdf"
    WriteRegStr SHCTX "Software\RegisteredApplications" "BV Reader" "Software\BellaVoz\BV Reader\Capabilities"

    System::Call 'Shell32::SHChangeNotify(i 0x8000000, i 0, i 0, i 0)'
  ${EndIf}

  ; ----- Shortcut Desktop (hanya jika dicentang) -----
  ${If} $DesktopShortcutState == ${BST_CHECKED}
    CreateShortCut "$newDesktopLink" "$appExe" "" "$appExe" 0 "" "" "${APP_DESCRIPTION}"
    ClearErrors
    WinShell::SetLnkAUMI "$newDesktopLink" "${APP_ID}"
  ${EndIf}

  ; ----- Shortcut Start Menu (hanya jika dicentang) -----
  ${If} $StartMenuShortcutState == ${BST_CHECKED}
    CreateShortCut "$newStartMenuLink" "$appExe" "" "$appExe" 0 "" "" "${APP_DESCRIPTION}"
    ClearErrors
    WinShell::SetLnkAUMI "$newStartMenuLink" "${APP_ID}"
    StrCpy $launchLink "$newStartMenuLink"
  ${EndIf}
!macroend

; Bersihkan shortcut dan registry saat di-uninstall
!macro customUnInstall
  WinShell::UninstShortcut "$oldDesktopLink"
  Delete "$oldDesktopLink"
  WinShell::UninstShortcut "$oldStartMenuLink"
  Delete "$oldStartMenuLink"

  DeleteRegValue SHCTX "Software\Classes\.pdf\OpenWithProgids" "id.bellavoz.bvreader.pdf"
  DeleteRegKey SHCTX "Software\Classes\id.bellavoz.bvreader.pdf"
  DeleteRegValue SHCTX "Software\RegisteredApplications" "BV Reader"
  DeleteRegKey SHCTX "Software\BellaVoz\BV Reader"
  DeleteRegKey /ifempty SHCTX "Software\BellaVoz"
  System::Call 'Shell32::SHChangeNotify(i 0x8000000, i 0, i 0, i 0)'
!macroend