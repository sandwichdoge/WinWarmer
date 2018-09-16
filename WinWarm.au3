;WinWarmer 1.0
;Makes your screen colors warmer based on time of day.
;sandwichdoge@gmail.com
;http://github.com/sandwichdoge

#include-once
#include <WinAPI.au3>
#include <Array.au3>

Opt("TrayMenuMode", 1 + 2)
Opt("TrayOnEventMode", 1)

HotKeySet("!{PGDN}", "LowerGamma")
HotKeySet("!{PGUP}", "IncreaseGamma")
HotKeySet("!{END}", "Toggle")


TrayCreateItem("Dim (Alt-PageDown)", -1, -1, 0)
TrayItemSetOnEvent(-1, "LowerGamma")
TrayCreateItem("Brighten (Alt-PageUp)", -1, -1, 0)
TrayItemSetOnEvent(-1, "IncreaseGamma")
$hTrayToggle = TrayCreateItem("Disable (Alt-End)", -1, -1, 0)
TrayItemSetOnEvent(-1, "Toggle")
TrayCreateItem("")
TrayCreateItem("About")
TrayItemSetOnEvent(-1, "About")
TrayCreateItem("Exit")
TrayItemSetOnEvent(-1, "ExitS")

OnAutoItExitRegister(ExitS)


$GDI_DLL = DllOpen("gdi32.dll")
If $GDI_DLL < 0 Then
	MsgBox(16, "Error", "Cannot open gdi32.dll. Aborting..")
	Exit
EndIf

Dim Const $nDawn = 7, $nDay = 10, $nAfternoon = 15, $nEvening = 18, $nDark = 22
Dim Const $nDarkBase = 70, $nEveningBase = 90, $nAfternoonBase = 100, $nDayBase = 128, $nDawnBase = 95

Global $aRGB[3], $g_bEnabled = True
Global $g_Red_Old, $g_Green_Old, $g_Blue_Old


While 1
	$nHour = @HOUR
	If $nHour > $nDark Or $nHour < $nDawn Then ;DARK
		FillArray($aRGB, $nDarkBase)
	ElseIf $nHour < $nDay Then ;DAWN
		FillArray($aRGB, $nDawnBase)
	ElseIf $nHour < $nAfternoon Then ;DAY
		FillArray($aRGB, $nDayBase)
	ElseIf $nHour < $nEvening Then ;AFTERNOON
		FillArray($aRGB, $nAfternoonBase)
	ElseIf $nHour < $nDark Then ;EVENING
		FillArray($aRGB, $nEveningBase)
	EndIf
	If $aRGB[2] < 0 Then $aRGB[2] = 0
	
	EqualizeGammaAray($aRGB) ;Give the color a light orange tint
	_SetDeviceGammaRamp($aRGB[0], $aRGB[1], $aRGB[2], $GDI_DLL)
	Sleep(180000) ; Update every 3 minutes
WEnd



Func FillArray(ByRef $aDest, $nValue)
	;Fill $aDest with $nValue
	If UBound($aDest) < 3 Then Return
	$aDest[0] = $nValue
	$aDest[1] = $nValue
	$aDest[2] = $nValue
EndFunc   ;==>FillArray


Func EqualizeGammaAray(ByRef $aRGB)
	;Give the color in $aRGB a light orange tint
	If UBound($aRGB) < 3 Then Return
	$aRGB[0] = Round($aRGB[0] * 1.4)
	$aRGB[1] = Round($aRGB[1] * 1)
	$aRGB[2] = Round($aRGB[2] * 0.1)
	If $aRGB[2] < 10 Then $aRGB[2] = 0 ;Eliminate blue light
EndFunc   ;==>EqualizeGammaAray


Func LowerGamma()
	;Global variable $aRGB is modified
	For $i = 0 To UBound($aRGB) - 1
		$aRGB[$i] -= 25
		If $aRGB[$i] < 0 Then $aRGB[$i] = 0
		If $aRGB[$i] > 255 Then $aRGB[$i] = 255
	Next
	
	EqualizeGammaAray($aRGB) ;Give the color a light orange tint
	_SetDeviceGammaRamp($aRGB[0], $aRGB[1], $aRGB[2])
EndFunc   ;==>LowerGamma


Func IncreaseGamma()
	;Global variable $aRGB is modified
	For $i = 0 To UBound($aRGB) - 1
		$aRGB[$i] += 25
		If $aRGB[$i] < 0 Then $aRGB[$i] = 0
		If $aRGB[$i] > 255 Then $aRGB[$i] = 255
	Next
	
	EqualizeGammaAray($aRGB) ;Give the color a light orange tint
	_SetDeviceGammaRamp($aRGB[0], $aRGB[1], $aRGB[2])
EndFunc   ;==>IncreaseGamma


Func Toggle()
	If $g_bEnabled = True Then ;Disable WinWarm
		Global $g_Red_Old = $aRGB[0], $g_Green_Old = $aRGB[1], $g_Blue_Old = $aRGB[2]
		FillArray($aRGB, 128) ;Default brightness values
		TrayItemSetText($hTrayToggle, "Enable")
	Else ;Enable WinWarm
		$aRGB[0] = $g_Red_Old
		$aRGB[1] = $g_Green_Old
		$aRGB[2] = $g_Blue_Old
		TrayItemSetText($hTrayToggle, "Disable")
	EndIf
	$g_bEnabled = Not $g_bEnabled
	_SetDeviceGammaRamp($aRGB[0], $aRGB[1], $aRGB[2])
EndFunc   ;==>Toggle


Func About()
	MsgBox(64, "WinWarmer", "Make your screen colors warmer based on time of day." & @CRLF & @CRLF & "sandwichdoge@gmail.com" & @CRLF & "http://github.com/sandwichdoge")
EndFunc   ;==>About


Func ExitS()
	_SetDeviceGammaRamp()
	DllClose($GDI_DLL)
	Exit
EndFunc   ;==>ExitS

; -----------------------------------------------------------------------------------------------------
; Func _SetDeviceGammaRamp($nRed = 128, $nGreen = 128, $nBlue = 128)
;
; Sets GammaRamps for Red, Green, and Blue.  If all 3 inputs are equal, the net effect
; is that the brightness is adjusted.
;
; $nRed = value from 0 - 255
; $nGreen = value from 0 - 255
; $nBlue = value from 0 - 255
;
; Author: noctis*, Ascend4nt (fixes)
;
; *Original AutoIt version (before fixes) appears to be available at:
; 'Schnelltasten erstellen' (Create shortcuts)
; @ http://autoit.de/index.php?page=Thread&postID=83474#post83474
; https://docs.microsoft.com/en-us/windows/desktop/api/wingdi/nf-wingdi-setdevicegammaramp
; -----------------------------------------------------------------------------------------------------
Func _SetDeviceGammaRamp($nRed = 128, $nGreen = 128, $nBlue = 128, $hGDI32 = DllOpen("gdi32.dll"))
	Local $tColorRamp, $rVar, $gVar, $bVar, $aRet, $i, $hDC, $nErr

	If ($nRed < 0 Or $nRed > 255) Or _
			($nGreen < 0 Or $nGreen > 255) Or _
			($nBlue < 0 Or $nBlue > 255) Then
		Return SetError(1, 0, -1) ; Invalid value for one of the colors
	EndIf

	$tColorRamp = DllStructCreate("short[" & (256 * 3) & "]")

	For $i = 0 To 255
		$rVar = $i * ($nRed + 128)
		If $rVar > 65535 Then $rVar = 65535
		$gVar = $i * ($nGreen + 128)
		If $gVar > 65535 Then $gVar = 65535
		$bVar = $i * ($nBlue + 128)
		If $bVar > 65535 Then $bVar = 65535
		; +1 in account for 1-based index in a 0-255 based loop
		DllStructSetData($tColorRamp, 1, Int($rVar), $i + 1) ;red
		DllStructSetData($tColorRamp, 1, Int($gVar), $i + 1 + 256) ;green
		DllStructSetData($tColorRamp, 1, Int($bVar), $i + 1 + 512) ;blue
	Next

	$hDC = _WinAPI_GetDC(0)
	If ($hDC = 0) Then Return SetError(-1, @error, -1)

	$aRet = DllCall($hGDI32, "bool", "SetDeviceGammaRamp", "ptr", $hDC, "ptr", DllStructGetPtr($tColorRamp))
	$nErr = @error
	_WinAPI_ReleaseDC(0, $hDC)

	If $nErr Or Not $aRet[0] Then Return SetError(-1, $nErr, -1)

	Return 0
EndFunc   ;==>_SetDeviceGammaRamp
