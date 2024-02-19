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
$bindings = ObjCreate("Scripting.Dictionary")


$winwidth=150
$defaultx=1920-$winwidth
$defaulty=4
$winx=$defaultx
$winy=$defaulty
$fpath="C:\Program Files (x86)\Electronic Arts\Ultima Online Enhanced\logs\chat.log"
$classic=False
$minh=30
global $guu
$max_skills=9
$chars_back_inloop=600


Global $gui_lines[$max_skills+1]
Global $gui_time[$max_skills+1]
Global $time_and_skill[$max_skills+1][2]
Global $skill_lines=0
Global $settingfd = FileOpen("settings.txt", $FO_READ)
Global $create_binding_button, $AFK_button
Global $binding_skill
Global $binding_key
Global $bindings_label
Global $binding_count=0
Global $bindstr=""
$winx=int(read_setting())
$winy=int(read_setting())
$chars_back_inloop=read_setting()
$classic=int(read_setting())
$use_binds=int(read_setting())
$epath=read_setting()
$cpath=read_setting()
$fpath=$epath
if $classic==1 Then
	$fpath=$cpath
EndIf
FileClose($settingfd)


$line_dist=30
$AFK=False
redo_gui()
$80 = 5 * 60
$90 = 8 * 60
$100 = 12 * 60
$INF = 15 * 60
$poll_freq=40
$poll_cnt=0
$charback=6000
$bind_delay=6000
$afk_delay=5 * 60 * 1000
$last_press = TimerInit()
$last_AFK = TimerInit()


While True
	$idMsg = GUIGetMsg()
	if $idMsg == $GUI_EVENT_CLOSE Then
		MyQuit()
	ElseIf $idMsg == $create_binding_button Then
		bind()
	ElseIf $idMsg == $AFK_button Then
		$AFK= not $AFK
		if $AFK Then
			GUICtrlSetColor($AFK_button,0x8CD248)
		Else
			GUICtrlSetColor($AFK_button,0x000000)
		EndIf
	EndIf
	if $AFK Then
		if TimerDiff($last_AFK) > $afk_delay Then
			if $classic Then
				ControlSend("Ultima Online","","","{LEFT}")
				sleep(100)
				ControlSend("Ultima Online","","","{LEFT}")
				sleep(100)
				ControlSend("Ultima Online","","","{RIGHT}")
				sleep(100)
				ControlSend("Ultima Online","","","{RIGHT}")
			Else
				Send("{LEFT}")
				sleep(100)
				Send("{LEFT}")
				sleep(100)
				Send("{RIGHT}")
				sleep(100)
				Send("{RIGHT}")
			EndIf
			$last_AFK=TimerInit()
		EndIf
	EndIf
	if $poll_cnt==0 Then
		$fd = FileOpen($fpath)
		if $fd == -1 Then
			error_quit("log file failed to open")
		EndIf
		FileSetPos($fd,-$charback,$FILE_END)
		$charback=$chars_back_inloop
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
						if $classic Then
							$time=@YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
						Else
							$time=convert_enhanced_timestamp(StringMid($l,1,20))
						EndIf
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
		sort()
		for $i=0 to $skill_lines
			if $gui_lines[$i]==0 Then
				$gui_lines[$i]=GUICtrlCreateLabel("",35,$i*$line_dist+5,$winwidth,25)
				$gui_time[$i]=GUICtrlCreateLabel("",1,$i*$line_dist+5,30,25)
			EndIf
			$s=$time_and_skill[$i][1]
			GUICtrlSetData($gui_lines[$i],$s)
			$s=StringSplit($s," ",$STR_NOCOUNT)[0]
			$t=$time_and_skill[$i][0]
			if $t < 0 Then
				$t="GAIN"
				GUICtrlSetColor($gui_time[$i],0x8CD248)
				if $bindings.Exists($s) Then
					$bind=$bindings.Item($s)
					if TimerDiff($last_press) > $bind_delay Then
						$k=$bind
						if StringLeft($bind,1) == 'F' Then
							$k="{"&$bind&"}"
						Else
						if $classic Then
							ControlSend("Ultima Online","","",$k)
						Else
							Send($k)
							;ControlSend("UOSA","","",$k)
						EndIf
						;ConsoleWrite("Sending: " & $k & @CRLF)
						$last_press=TimerInit()
					EndIf
				EndIf
			Else
				$display_mins=int($t/60)
				$display_seconds=$t-60*$display_mins
				$t=$display_mins&':'&$display_seconds
				GUICtrlSetColor($gui_time[$i],0xff0000)
			EndIf
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
	$add=0
	if $use_binds Then
		$add=3
	EndIf
	$guu = GUICreate("uover",$winwidth, ($skill_lines+$add)*$line_dist+$minh,$winx, $winy)
	WinSetOnTop($guu,"",$WINDOWS_ONTOP)
	GUISetState(@sw_show, $guu)
	For $i=0 to $skill_lines
		$gui_lines[$i]=0
		$gui_time[$i]=0
	Next
	if $use_binds Then
		$create_binding_button=GUICtrlCreateButton("create binding",12,($skill_lines+1)*$line_dist+5)
		$AFK_button=GUICtrlCreateButton("AFK",90,($skill_lines+1)*$line_dist+5)
		if $AFK Then
			GUICtrlSetColor($AFK_button,0x8CD248)
		EndIf
		;$AFKcheckbox=GUICtrlCreateCheckbox("",120,($skill_lines+1)*$line_dist+7,20,20)
		$binding_skill=GUICtrlCreateInput("Skill",4,($skill_lines+2)*$line_dist+5,50,20)
		GUICtrlCreateLabel("->",58,($skill_lines+2)*$line_dist+5)
		$binding_key=GUICtrlCreateInput("key",70,($skill_lines+2)*$line_dist+5,50,20)
		$bindings_label=GUICtrlCreateLabel($bindstr,4,($skill_lines+3)*$line_dist+5,$winwidth-8,25)
	EndIf
EndFunc

Func bind()
	$s=GUICtrlRead($binding_skill)
	$k=GUICtrlRead($binding_key)
	$bindings.Item($s)=$k
	GUICtrlSetData($binding_skill,"Skill")
	GUICtrlSetData($binding_key,"key")
	if $binding_count <> 0 Then
		$bindstr &= " | "
	EndIf
	$bindstr&=$s & "->" & $k
	GUICtrlSetData($bindings_label, $bindstr)
	$binding_count+=1

EndFunc

Func sort()
	Local $storet, $storemsg
	$i=-1
	$end=$skill_lines-1
	While $i<$end
		$i+=1
		if $time_and_skill[$i][0] > $time_and_skill[$i+1][0] Then
			$storet=$time_and_skill[$i][0]
			$storemsg=$time_and_skill[$i][1]
			$time_and_skill[$i][0]=$time_and_skill[$i+1][0]
			$time_and_skill[$i][1]=$time_and_skill[$i+1][1]
			$time_and_skill[$i+1][0]=$storet
			$time_and_skill[$i+1][1]=$storemsg
			$i=-1
		EndIf
	WEnd
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


Func convert_enhanced_timestamp($stamp)
	Local $timestampFormatted = StringRegExpReplace($stamp, "\]\[", " ")
	$timestampFormatted = "20" & StringRegExpReplace($timestampFormatted, "\]|\[", "")
	return($timestampFormatted)
EndFunc

Func CalculateTimeDifferenceInSeconds($timestamp)
	Local $currentDateTime = @YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
	Local $diffInSeconds = _DateDiff("s", $timestamp, $currentDateTime)
	Return $diffInSeconds
EndFunc

Func error_quit($error_string)
	MsgBox($MB_SYSTEMMODAL, "ERROR", $error_string)
	MyQuit()
EndFunc

Func read_setting()
	return(StringSplit(FileReadLine($settingfd), "=", $STR_NOCOUNT)[1])
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
	FileWriteLine($settingsfd,"WINDOWX="&$x)
	FileWriteLine($settingsfd,"WINDOWY="&$y)
	FileWriteLine($settingsfd,"SEARCHCHARS="&$chars_back_inloop)
	FileWriteLine($settingsfd,"USECLASSIC="&$classic)
	FileWriteLine($settingsfd,"USEBINDS="&$use_binds)
	FileWriteLine($settingsfd,"ENHANCEDPATH="&$epath)
	FileWriteLine($settingsfd,"CLASSICPATH="&$cpath)
	FileClose($settingsfd)
	Exit
EndFunc