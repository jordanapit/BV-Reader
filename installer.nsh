!include "nsDialogs.nsh"
!include "LogicLib.nsh"

Var AssociatePdfCheckbox
Var AssociatePdfState

; Set default tercentang (BST_CHECKED) saat installer dibuka
!macro customInit
  StrCpy $AssociatePdfState ${BST_CHECKED}
!macroend

; Tambahkan halaman opsi "Associate PDF with BV Reader" setelah halaman pilih folder
Page custom pdfAssocPageCreate pdfAssocPageLeave

Function pdfAssocPageCreate
  !insertmacro MUI_HEADER_TEXT "File Associations" "Choose whether to associate PDF files with BV Reader."
  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 24u "Select the file association option below. Click Install to start the installation."
  Pop $0

  ${NSD_CreateCheckbox} 0 30u 100% 12u "Associate .PDF files with BV Reader"
  Pop $AssociatePdfCheckbox
  ${NSD_SetState} $AssociatePdfCheckbox $AssociatePdfState

  nsDialogs::Show
FunctionEnd

Function pdfAssocPageLeave
  ${NSD_GetState} $AssociatePdfCheckbox $AssociatePdfState
FunctionEnd

; Daftarkan ekstensi .pdf di Windows Registry HANYA jika user mencentang checkbox
!macro customInstall
  ${If} $AssociatePdfState == ${BST_CHECKED}
    WriteRegStr SHCTX "Software\Classes\.pdf\OpenWithProgids" "id.bellavoz.bvreader.pdf" ""
    WriteRegStr SHCTX "Software\Classes\id.bellavoz.bvreader.pdf" "" "PDF Document"
    WriteRegStr SHCTX "Software\Classes\id.bellavoz.bvreader.pdf\DefaultIcon" "" "$INSTDIR\${APP_EXECUTABLE_FILENAME},0"
    WriteRegStr SHCTX "Software\Classes\id.bellavoz.bvreader.pdf\shell\open\command" "" '"$INSTDIR\${APP_EXECUTABLE_FILENAME}" "%1"'
    System::Call 'Shell32::SHChangeNotify(i 0x8000000, i 0, i 0, i 0)'
  ${EndIf}
!macroend

; Bersihkan registry saat di-uninstall
!macro customUnInstall
  DeleteRegValue SHCTX "Software\Classes\.pdf\OpenWithProgids" "id.bellavoz.bvreader.pdf"
  DeleteRegKey SHCTX "Software\Classes\id.bellavoz.bvreader.pdf"
!macroend