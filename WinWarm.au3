;WinWarmer 1.0
;Makes your screen colors warmer based on time of day.
;sandwichdoge@gmail.com
;http://github.com/sandwichdoge

#include-once
#include <WinAPI.au3>
#include <Misc.au3>

Opt("TrayMenuMode", 1 + 2)
Opt("TrayOnEventMode", 1)

If _Singleton("WINWARMER", 1) = 0 Then 
	Exit
EndIf	

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
Dim Const $nDarkBrightness = 75, $nEveningBrightness = 90, $nAfternoonBrightness = 110, $nDayBrightness = 128, $nDawnBrightness = 95
Dim Const $aDarkTint[] = [1.2, 0.2], $aDawnTint[] = [1.1, 0.6], $aDayTint[] = [1, 1], $aAfternoonTint[] = [1, 0.9], $aEveningTint[] = [1.2, 0.4]

Global $g_nUpdateFrequency = 180000
Global $g_aRGB[3], $g_bEnabled = True
Global $g_Red_Old, $g_Green_Old, $g_Blue_Old
Global $g_aTint[2] = [1, 1]


While 1
	$nHour = @HOUR
	If $nHour >= $nDark Or $nHour <= $nDawn Then ;DARK
		FillArray($g_aRGB, $nDarkBrightness)
		DupArray($g_aTint, $aDarkTint)
	ElseIf $nHour <= $nDay Then ;DAWN
		FillArray($g_aRGB, $nDawnBrightness)
		DupArray($g_aTint, $aDawnTint)
	ElseIf $nHour <= $nAfternoon Then ;DAY
		FillArray($g_aRGB, $nDayBrightness)
		DupArray($g_aTint, $aDayTint)
	ElseIf $nHour <= $nEvening Then ;AFTERNOON
		FillArray($g_aRGB, $nAfternoonBrightness)
		DupArray($g_aTint, $aAfternoonTint)
	ElseIf $nHour <= $nDark Then ;EVENING
		FillArray($g_aRGB, $nEveningBrightness)
		DupArray($g_aTint, $aEveningTint)
	EndIf
	If $g_aRGB[2] < 0 Then $g_aRGB[2] = 0
	
	EqualizeGammaAray($g_aRGB, $g_aTint[0], 1, $g_aTint[1]) ;Give the color a light orange tint
	_SetDeviceGammaRamp($g_aRGB[0], $g_aRGB[1], $g_aRGB[2], $GDI_DLL)
	Sleep($g_nUpdateFrequency) ; Update every 3 minutes
WEnd



Func FillArray(ByRef $aDest, $nValue)
	;Fill $aDest with $nValue
	For $i = 0 To UBound($aDest) - 1
		$aDest[$i] = $nValue
	Next
EndFunc   ;==>FillArray


Func DupArray(ByRef $aDest, $aSrc)
	If UBound($aDest) < UBound($aSrc) Then Return SetError(-1)
	For $i = 0 To UBound($aDest) - 1
		$aDest[$i] = $aSrc[$i]
	Next
EndFunc	


Func EqualizeGammaAray(ByRef $g_aRGB, $fRedTint = 1.4, $fGreenTint = 1, $fBlueTint = 0.2) ; red tint range: 0 - 1.6
	;Give the color in $g_aRGB a light orange tint
	If UBound($g_aRGB) < 3 Then Return
	$g_aRGB[0] = Round($g_aRGB[0] * $fRedTint)
	$g_aRGB[1] = Round($g_aRGB[1] * 1)
	$g_aRGB[2] = Round($g_aRGB[2] * $fBlueTint)
EndFunc   ;==>EqualizeGammaAray


Func LowerGamma()
	;Global variable $g_aRGB is modified
	For $i = 0 To UBound($g_aRGB) - 1
		$g_aRGB[$i] -= 25
		If $g_aRGB[$i] < 0 Then $g_aRGB[$i] = 0
		If $g_aRGB[$i] > 255 Then $g_aRGB[$i] = 255
	Next
	
	EqualizeGammaAray($g_aRGB, $g_aTint[0], 1, $g_aTint[1]) ;Give the color a light orange tint
	_SetDeviceGammaRamp($g_aRGB[0], $g_aRGB[1], $g_aRGB[2])
	Sleep(60000 * 60) ;Dim for 1 hour
EndFunc   ;==>LowerGamma


Func IncreaseGamma()
	;Global variable $g_aRGB is modified
	For $i = 0 To UBound($g_aRGB) - 1
		$g_aRGB[$i] += 25
		If $g_aRGB[$i] < 0 Then $g_aRGB[$i] = 0
		If $g_aRGB[$i] > 255 Then $g_aRGB[$i] = 255
	Next
	
	EqualizeGammaAray($g_aRGB, $g_aTint[0], 1, $g_aTint[1]) ;Give the color a light orange tint
	_SetDeviceGammaRamp($g_aRGB[0], $g_aRGB[1], $g_aRGB[2])
	Sleep(60000 * 60) ;Brighten for 1 hour
EndFunc   ;==>IncreaseGamma


Func Toggle()
	If $g_bEnabled = True Then ;Disable WinWarm
		Global $g_Red_Old = $g_aRGB[0], $g_Green_Old = $g_aRGB[1], $g_Blue_Old = $g_aRGB[2]
		FillArray($g_aRGB, 128) ;Default brightness values
		TrayItemSetText($hTrayToggle, "Enable (Alt-End)")
		Sleep(60000 * 60) ;Disable for 1 hour
	Else ;Enable WinWarm
		$g_aRGB[0] = $g_Red_Old
		$g_aRGB[1] = $g_Green_Old
		$g_aRGB[2] = $g_Blue_Old
		TrayItemSetText($hTrayToggle, "Disable (Alt-End)")
	EndIf
	$g_bEnabled = Not $g_bEnabled
	_SetDeviceGammaRamp($g_aRGB[0], $g_aRGB[1], $g_aRGB[2])
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
