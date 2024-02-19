#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_Outfile=siege gain tracker_x86.exe
#AutoIt3Wrapper_Outfile_x64=siege gain tracker_x64.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Constants.au3>
#include <MsgBoxConstants.au3>
#include <WinAPI.au3>
#include <GUIConstantsEx.au3>
#include <GuiButton.au3>
#include <Date.au3>
#include <File.au3>

HotKeySet("^!q", "MyQuit")

$dict = ObjCreate("Scripting.Dictionary")


$winwidth=150
$defaultx=1920-$winwidth
$defaulty=4
$winx=$defaultx
$winy=$defaulty
$fpath="C:\Program Files (x86)\Electronic Arts\Ultima Online Enhanced\logs\chat.log"
$minh=30
global $guu
$max_skills=9

Global $gui_lines[$max_skills+1]
Global $gui_time[$max_skills+1]
Global $time_and_skill[$max_skills+1][2]
Global $skill_lines=0

$settingfd = FileOpen("settings.txt", $FO_READ)
$winx=int(FileReadLine($settingfd))
$winy=int(FileReadLine($settingfd))
$fpath=FileReadLine($settingfd)
FileClose($settingfd)


$line_dist=30
redo_gui()
$80 = 5 * 60
$90 = 8 * 60
$100 = 12 * 60
$INF = 15 * 60
$poll_freq=40
$poll_cnt=0
$charback=6000
While True
	$idMsg = GUIGetMsg()
	if $idMsg == $GUI_EVENT_CLOSE Then
		MyQuit()
	EndIf
	if $poll_cnt==0 Then
		$fd = FileOpen($fpath)
		if $fd == -1 Then
			error_quit("log file failed to open")
		EndIf
		FileSetPos($fd,-$charback,$FILE_END)
		$charback=600
		;ConsoleWrite("reading log -- " & @CRLF)
		FileReadLine($fd)
		$l=FileReadLine($fd)
		While $l <> ""
			$sk=StringInStr($l,"Your skill in ")
			if $sk Then
				$skill_and_after=StringMid($l,$sk+14)
				$space=StringInStr($skill_and_after," ")
				$skill=StringMid($skill_and_after,1,$space-1)
				$new_val=StringMid($skill_and_after,35+$space,4)
				if $new_val>70 Then
					$old="0,"
					if $dict.Exists($skill) Then
						$old=$dict.Item($skill)
					EndIf
					$old=StringSplit($old,",",$STR_NOCOUNT)[0]
					if $old < $new_val Then
						ConsoleWrite("skill gain in " & $skill & ": " & $old& "->"& $new_val& @CRLF)
						$time=StringMid($l,1,20)
						$dict.Item($skill) = $new_val & "," & $time
					EndIf
				EndIf
			EndIf
			$l=FileReadLine($fd)
		WEnd
		FileClose($fd)
		$i=0
		For $vKey In $dict
			$vals=StringSplit($dict($vKey),",",$STR_NOCOUNT)
			$t=get_time_req($vals[0])-CalculateTimeDifferenceInSeconds($vals[1])
			$time_and_skill[$i][0]=$t
			$time_and_skill[$i][1]=$vkey & " -> " & $vals[0]
			$i+=1
		Next
		if $i-1 > $skill_lines Then
				$skill_lines=$i-1
				GUIDelete($guu)
				redo_gui()
			EndIf
		_ArraySort($time_and_skill,False,0,1,0)
		for $i=0 to $skill_lines
			if $gui_lines[$i]==0 Then
				$gui_lines[$i]=GUICtrlCreateLabel("",35,$i*$line_dist+5,$winwidth,25)
				$gui_time[$i]=GUICtrlCreateLabel("",1,$i*$line_dist+5,30,25)
			EndIf
			GUICtrlSetData($gui_lines[$i],$time_and_skill[$i][1])
			$t=$time_and_skill[$i][0]
			if $t < 0 Then
				$t="GAIN"
				GUICtrlSetColor($gui_time[$i],0x8CD248)
			Else
				GUICtrlSetColor($gui_time[$i],0xff0000)
			EndIf
			GUICtrlSetData($gui_time[$i],$t)
		Next
	EndIf
	sleep(10)
	$poll_cnt+=1
	if $poll_cnt>$poll_freq Then
		$poll_cnt=0
	EndIf
WEnd

func redo_gui()
	$guu = GUICreate("uover",$winwidth, ($skill_lines)*$line_dist+$minh,$winx, $winy)
	WinSetOnTop($guu,"",$WINDOWS_ONTOP)
	GUISetState(@sw_show, $guu)
	For $i=0 to $skill_lines
		$gui_lines[$i]=0
		$gui_time[$i]=0
	Next
EndFunc

func get_time_req($skill_level)
	if $skill_level < 80 Then
		return($80)
	ElseIf $skill_level < 90 Then
		Return($90)
	ElseIf $skill_level < 100 Then
		Return($100)
	Else
		Return($INF)
	EndIf
EndFunc

Func CalculateTimeDifferenceInSeconds($timestamp)
    Local $year, $month, $day, $hour, $minute, $second
    Local $timestampFormatted = StringRegExpReplace($timestamp, "\]\[", " ")
	$timestampFormatted = "20" & StringRegExpReplace($timestampFormatted, "\]|\[", "")
	Local $currentDateTime = @YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
	Local $diffInSeconds = _DateDiff("s", $timestampFormatted, $currentDateTime)
	Return $diffInSeconds
EndFunc

Func error_quit($error_string)
	MsgBox($MB_SYSTEMMODAL, "ERROR", $error_string)
	MyQuit()
EndFunc

Func MyQuit()
	$settingsfd = FileOpen("settings.txt", $FO_OVERWRITE )
	$temp=WinGetPos($guu)
	$y=$temp[1]
	$x=$temp[0]
	if($x==-32000) Then
		$x=$defaultx
		$y=$defaulty
	EndIf
	FileWriteLine($settingsfd,$x)
	FileWriteLine($settingsfd,$y)
	FileWriteLine($settingsfd,$fpath)
	FileClose($settingsfd)
	Exit
EndFunc