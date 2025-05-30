#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_Outfile=siege gain tracker_x86.exe
#AutoIt3Wrapper_Outfile_x64=siege gain tracker_x64.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****


#include <WinAPI.au3>
#include <WindowsConstants.au3>
#include <WinAPISysWin.au3>

#include <Constants.au3>
#include <MsgBoxConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiButton.au3>
#include <Date.au3>
#include <File.au3>
#include <Sound.au3>
#include <Misc.au3>

HotKeySet("^!q", "MyQuit")
HotKeySet("^!t", "test_bind")

$dict = ObjCreate("Scripting.Dictionary")
$bindings = ObjCreate("Scripting.Dictionary")

Opt("GUICloseOnESC", 0)

$winwidth = 150
$defaultx = 1920 - $winwidth
$defaulty = 4
$winx = $defaultx
$winy = $defaulty
$fpath = "C:\Program Files (x86)\Electronic Arts\Ultima Online Enhanced\logs\chat.log"
$classic = False
$minh = 30
Global $guu
$max_skills = 9
$chars_back_inloop = 600
$clicking = False
$used_clicks=0
Global $click_string=""

Global $gui_lines[$max_skills + 1]
Global $gui_time[$max_skills + 1]
Global $gui_sound[$max_skills + 1]
Global $time_and_skill[$max_skills + 1][2]
Global $skill_lines = -1
Global $settingfd = FileOpen("settings.txt", $FO_READ)
Global $create_binding_button, $AFK_button, $save_button, $load_button
Global $binding_skill
Global $binding_key
Global $bindings_label
Global $binding_count = 0
Global $bindstr = ""
$winx = Int(read_setting())
$winy = Int(read_setting())
$chars_back_inloop = read_setting()
$classic = Int(read_setting())
$use_binds = Int(read_setting())
$bind_delay = Int(read_setting())
$under70 = Int(read_setting())
$use_alarm = Int(read_setting())
$beep_delay = Int(read_setting())
$epath = read_setting()
$cpath = read_setting()
$alarm_path = read_setting()
$fpath = $epath
$click_delay = 1200
If $classic == 1 Then
	$fpath = $cpath
EndIf

if $use_alarm == 1 Then
	Global $alarm_sound=_SoundOpen($alarm_path)
	if $alarm_sound==0 Then
		error_quit("alarm file failed to open")
	EndIf
EndIf
FileClose($settingfd)


$line_dist = 30
$AFK = False
redo_gui()
$70 = 1
$80 = 5 * 60
$90 = 8 * 60
$100 = 12 * 60
$INF = 15 * 60
$poll_freq = 40
$poll_cnt = 0
$charback = 10000
$afk_delay = 5 * 60 * 1000
$last_press = TimerInit()
$last_AFK = TimerInit()
$last_beep=TimerInit()
$last_click=TimerInit()
$hDLL = DllOpen("user32.dll")
Global $click_s
Global $last_down = False
Global $last_dbl

While True
	$idMsg = GUIGetMsg()
	If $idMsg == $GUI_EVENT_CLOSE Then
		MyQuit()
	ElseIf $idMsg == $create_binding_button Then
		bind()
	ElseIf $idMsg == $save_button Then
		save_bindings()
	ElseIf $idMsg == $load_button Then
		load_bindings()
	ElseIf $idMsg == $AFK_button Then
		$AFK = Not $AFK
		If $AFK Then
			GUICtrlSetColor($AFK_button, 0x8CD248)
		Else
			GUICtrlSetColor($AFK_button, 0x000000)
		EndIf
	EndIf
	if $clicking Then
		If _IsPressed("0D", $hDLL) Then
			conclude_points()
		EndIf
		If _IsPressed("1B", $hDLL) Then
			abandon_points()
		EndIf
		If _IsPressed("4C", $hDLL) Then
			if $last_down and TimerDiff($last_click)>700 Then
				convert_last_to_double()
			ElseIf not $last_down Then
				add_point()
				$last_click=TimerInit()
			EndIf
		EndIf
		If _IsPressed("52", $hDLL) Then
			if $last_down and TimerDiff($last_click)>700 Then
				convert_last_to_double()
			ElseIf not $last_down Then
				add_point(True)
				$last_click=TimerInit()
			EndIf
		EndIf
		$last_down=_IsPressed("4C", $hDLL) or _IsPressed("52", $hDLL)
		ContinueLoop
	EndIf
	for $i = 0 to $skill_lines
		If $idMsg == $gui_sound[$i] Then
			$s = $time_and_skill[$i][1]
			$s = StringSplit($s, ":", $STR_NOCOUNT)[0]
			$old=StringSplit($dict.Item($s),",",$STR_NOCOUNT)
			if $old[3]=="1" Then
				GUICtrlSetImage($gui_sound[$i], "mute.ico")
				$dict.Item($s)=$old[0] & "," &  $old[1] & "," & $old[2] & "," & "0"
			Else
				GUICtrlSetImage($gui_sound[$i], "sound.ico")
				$dict.Item($s)=$old[0] & "," &  $old[1] & "," & $old[2] & "," & "1"
			EndIf
			ExitLoop
		EndIf
	Next
	If $AFK Then
		If TimerDiff($last_AFK) > $afk_delay Then
			If $classic Then
				ControlSend("Ultima Online", "", "", "{LEFT}")
				Sleep(100)
				ControlSend("Ultima Online", "", "", "{LEFT}")
				Sleep(100)
				ControlSend("Ultima Online", "", "", "{RIGHT}")
				Sleep(100)
				ControlSend("Ultima Online", "", "", "{RIGHT}")
			Else
				Send("{LEFT}")
				Sleep(100)
				Send("{LEFT}")
				Sleep(100)
				Send("{RIGHT}")
				Sleep(100)
				Send("{RIGHT}")
			EndIf
			$last_AFK = TimerInit()
		EndIf
	EndIf
	If $poll_cnt == 0 Then
		$fd = FileOpen($fpath)
		If $fd == -1 Then
			error_quit("log file failed to open")
		EndIf
		FileSetPos($fd, -$charback, $FILE_END)
		$charback = $chars_back_inloop
		;ConsoleWrite("reading log -- " & @CRLF)
		FileReadLine($fd)
		$l = FileReadLine($fd)
		While $l <> ""
			;ConsoleWrite($l & @CRLF)
			$sk = StringInStr($l, "Your skill in ")
			If $sk Then
				$skill_and_after = StringMid($l, $sk + 14)
				$post_skill = StringInStr($skill_and_after, " has")
				$skill = StringMid($skill_and_after, 1, $post_skill - 1)

				$up = StringInStr($skill_and_after, "inc")
				if $up <> 0 Then
					$new_val = StringRight($skill_and_after,7)
					$new_val=StringLeft($new_val,5)
					if StringLeft($new_val,1) == "w" Then
						$new_val=StringRight($new_val,3)
					ElseIf StringLeft($new_val,1) == " " Then
						$new_val=StringRight($new_val,4)
					EndIf
					$new_val=Number($new_val)
					If $new_val > 70 or $under70 Then
						$old = "0,,,1"
						If $dict.Exists($skill) Then
							$old = $dict.Item($skill)
						EndIf
						$old = StringSplit($old, ",", $STR_NOCOUNT)
						$old_val = Number($old[0])
						;ConsoleWrite($old_val & @CRLF)
						;ConsoleWrite($new_val & @CRLF)
						If $old_val < $new_val Then
							ConsoleWrite("skill gain in " & $skill & ": " & $old_val & "->" & $new_val & @CRLF)
							If $classic Then
								$time = @YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
							Else
								$time = convert_enhanced_timestamp(StringMid($l, 1, 20))
							EndIf
							$dict.Item($skill) = $new_val & "," & $time & "," & $time & "," & $old[3]
						EndIf
					EndIf
				EndIf
			EndIf
			$l = FileReadLine($fd)
		WEnd
		FileClose($fd)
		$i = 0
		For $vKey In $dict
			$vals = StringSplit($dict($vKey), ",", $STR_NOCOUNT)
			$t = get_time_req($vals[0]) - CalculateTimeDifferenceInSeconds($vals[1])
			$time_and_skill[$i][0] = $t
			$time_and_skill[$i][1] = $vkey & ":->:" & $vals[0]
			$i += 1
		Next
		If $i -1  > $skill_lines Then
			$skill_lines = $i -1
			GUIDelete($guu)
			redo_gui()
		EndIf
		sort()
		for $i =0 to $skill_lines
			;ConsoleWrite("loop " & $i & @CRLF)
			If $gui_lines[$i] == 0 Then
				$gui_lines[$i] = GUICtrlCreateLabel("", 35, $i * $line_dist + 5, $winwidth-35-20, 25)
				$gui_time[$i] = GUICtrlCreateLabel("", 1, $i * $line_dist + 5, 30, 25)
				if $use_alarm Then
					$gui_sound[$i] = GUICtrlCreateButton("", $winwidth-20, $i * $line_dist + 3,20,20,$BS_ICON)
					GUICtrlSetImage($gui_sound[$i], "sound.ico")
				EndIf
			EndIf
			$s = $time_and_skill[$i][1]
			$skill_split=StringSplit($s,":",$STR_NOCOUNT)
			GUICtrlSetData($gui_lines[$i], StringLeft($skill_split[0],10) & " " & $skill_split[1] & " " & $skill_split[2])
			$s = $skill_split[0]
			if $use_alarm Then
				$this_skill_beep=True
				;$old=StringSplit($dict.Item($s),",",$STR_NOCOUNT)
				if StringSplit($dict.Item($s),",",$STR_NOCOUNT)[3] == "1" Then
					GUICtrlSetImage($gui_sound[$i], "sound.ico")
				Else
					GUICtrlSetImage($gui_sound[$i], "mute.ico")
					$this_skill_beep=False
				EndIf
			EndIf
			$t = $time_and_skill[$i][0]
			If $t < 0 Then
				$t = "GAIN"
				GUICtrlSetColor($gui_time[$i], 0x8CD248)
				If $bindings.Exists($s) Then
					$bind = $bindings.Item($s)
					If TimerDiff($last_press) > $bind_delay Then
						follow_bind($bind)
						;ConsoleWrite("doing bind" & @CRLF)
						$last_press = TimerInit()
					EndIf
				else
					if $use_alarm and $this_skill_beep Then
						$last_val=StringSplit($dict.Item($s),",",$STR_NOCOUNT)
						If TimerDiff($last_val[2]) > $beep_delay Then
							$dict.Item($s)=$last_val[0] & "," &  $last_val[1] & "," & TimerInit() & "," & $last_val[3]
							_SoundPlay($alarm_sound)
						EndIf
					EndIf
				EndIf
			Else
				$display_mins = Int($t / 60)
				$display_seconds = $t - 60 * $display_mins
				if StringLen($display_seconds)==1 Then
					$display_seconds="0"&$display_seconds
				EndIf
				$t = $display_mins & ':' & $display_seconds
				GUICtrlSetColor($gui_time[$i], 0xff0000)
			EndIf
			GUICtrlSetData($gui_time[$i], $t)
		Next
	EndIf
	Sleep(10)
	$poll_cnt += 1
	If $poll_cnt > $poll_freq Then
		$poll_cnt = 0
	EndIf
WEnd

Func test_bind()
	$s = GUICtrlRead($binding_skill)
	follow_bind($bindings.Item($s))
EndFunc

Func follow_bind($bind)
	$k = $bind
	$clicking_bind=false
	If StringLeft($bind, 1) == 'F' Then
		$k = "{" & $bind & "}"
	ElseIf StringLeft($bind, 5) == "Click" Then
		$clicking_bind=True
	EndIf
	If $classic Then
		$wind = WinGetHandle("Ultima Online")
		if @error <> 0 Then
			ConsoleWrite("can't find uo window")
		Else
			if $clicking_bind Then
				$clicks = StringSplit(StringSplit($k,"|",$STR_NOCOUNT)[1],";")
				Local $click
				Local $bd
				Local $right
				for $i = 1 to $clicks[0]
					$click=$clicks[$i]
					$db=false
					$right=False
					if StringLeft($click,1)==':' Then
						$click=StringMid($click,2)
						$db=true
					EndIf
					if StringLeft($click,1)=='r' Then
						$click=StringMid($click,2)
						$right=true
					EndIf
					$pts=StringSplit($click,",",$STR_NOCOUNT)
					if $db Then
						ConsoleWrite("double clicking: (" & $pts[0] & ", " & $pts[1] & ")" & @CRLF)
						if $right Then
							VirtualMouseDRClick($wind,$pts[0],$pts[1])
						Else
							VirtualMouseDClick($wind,$pts[0],$pts[1])
						EndIf
					Else
						ConsoleWrite("clicking: (" & $pts[0] & ", " & $pts[1] & ")" & @CRLF)
						if $right Then
							VirtualMouseRClick($wind,$pts[0],$pts[1])
						Else
							VirtualMouseClick($wind,$pts[0],$pts[1])
						EndIf
					EndIf
					sleep($click_delay)
				Next
			Else
				ControlSend($wind, "", "", $k)
			EndIf
		EndIf
	Else
		Send($k)
		;ControlSend("UOSA","","",$k)
	EndIf
	;ConsoleWrite("Sending: " & $k & @CRLF)
EndFunc

func conclude_points()
	_make_bind($click_s,"Click"&$used_clicks & "       |" & $click_string)
	abandon_points()
EndFunc

func abandon_points()
	$clicking=false
	GUIDelete($guu)
	redo_gui()
EndFunc


func add_point($right=false)
	$me=""
	if $used_clicks Then
		$me=";"
	EndIf
	if $right Then
		$me&="r"
	EndIf
	$a = WinGetPos("Ultima Online")
	$b = MouseGetPos()
	$me&=$b[0]-$a[0] - 8 & "," & $b[1]-$a[1] - 31
	$click_string&=$me
	ConsoleWrite($click_string & @CRLF)
	$last_dbl=false
	$olds=GUICtrlRead($bindings_label)
	GUICtrlSetData($bindings_label,$olds & "|")
	$used_clicks+=1
EndFunc

Func convert_last_to_double()
	if $last_dbl Then
		Return
	EndIf
	$all_clicks = StringSplit($click_string,";")
	$all_clicks[$all_clicks[0]]=":"&$all_clicks[$all_clicks[0]]
	$click_string=$all_clicks[1]
	for $i = 2 to $all_clicks[0]
		$click_string&=";"&$all_clicks[$i]
	Next
	ConsoleWrite($click_string & @CRLF)
	$last_dbl=true
	$olds=GUICtrlRead($bindings_label)
	GUICtrlSetData($bindings_label,StringLeft($olds,StringLen($olds)-1) & ":")
EndFunc

Func save_bindings()
	$bindingsfd = FileOpen("bindings.txt", $FO_OVERWRITE)
	$bs = StringSplit(GUICtrlRead($bindings_label),@CRLF,$STR_ENTIRESPLIT)
	Local $sstr
	for $i = 1 to $bs[0]
		$sstr = StringSplit($bs[$i],'-',$STR_NOCOUNT)[0]
		FileWriteLine($bindingsfd,$sstr & "->" & $bindings.Item($sstr))
	Next
EndFunc

Func load_bindings()
	$bindingsfd = FileOpen("bindings.txt", $FO_READ)
	Local $read
	while True
		$read=FileReadLine($settingfd)
		ConsoleWrite($read & @CRLF)
		if @error == -1 or $read == "" Then
			ExitLoop
		EndIf
		$strs=StringSplit($read,"->",3)
		_make_bind($strs[0],$strs[1])
	WEnd
EndFunc

Func redo_gui()
	$add = 0
	$add2=0
	If $use_binds Then
		$add = 2
		if $binding_count Then
			$add2 = 7
		EndIf
	EndIf
	$guu = GUICreate("uover", $winwidth, ($skill_lines + $add) * $line_dist + $minh + $binding_count*13+$add2, $winx, $winy)
	WinSetOnTop($guu, "", $WINDOWS_ONTOP)
	GUISetState(@SW_SHOW, $guu)
	if $clicking Then
		GUICtrlCreateLabel("press l/r to set pos" & @CRLF & "hold to double click" & @CRLF & "enter:add     esc:cancel",10,10)
		$bindings_label = GUICtrlCreateLabel("",10,48,600,15)
	Else
		For $i = 0 To $skill_lines
			$gui_lines[$i] = 0
			$gui_time[$i] = 0
			$gui_sound[$i] = -100
		Next
		If $use_binds Then
			$create_binding_button = GUICtrlCreateButton("Create", 5, ($skill_lines + 1) * $line_dist + 5)
			$save_button = GUICtrlCreateButton("Save", 45, ($skill_lines + 1) * $line_dist + 5)
			$load_button = GUICtrlCreateButton("Load", 80, ($skill_lines + 1) * $line_dist + 5)
			$AFK_button = GUICtrlCreateButton("AFK", 115, ($skill_lines + 1) * $line_dist + 5)
			If $AFK Then
				GUICtrlSetColor($AFK_button, 0x8CD248)
			EndIf
			;$AFKcheckbox=GUICtrlCreateCheckbox("",120,($skill_lines+1)*$line_dist+7,20,20)
			$binding_skill = GUICtrlCreateInput("Skill", 4, ($skill_lines + 2) * $line_dist + 5, 50, 20)
			GUICtrlCreateLabel("->", 58, ($skill_lines + 2) * $line_dist + 5)
			$binding_key = GUICtrlCreateInput("key", 70, ($skill_lines + 2) * $line_dist + 5, 50, 20)
			$bindings_label = GUICtrlCreateLabel($bindstr, 4, ($skill_lines + 3) * $line_dist + 5, $winwidth - 8, $binding_count*13)
		EndIf
	EndIf
EndFunc   ;==>redo_gui

Func bind()
	$s = GUICtrlRead($binding_skill)
	$k = GUICtrlRead($binding_key)
	if $k == "click" or $k == "Click" Then
		$clicking=True
		$used_clicks=0
		$click_string=""
		$click_s=$s
		GUIDelete($guu)
		redo_gui()
		return
	EndIf
	GUICtrlSetData($binding_skill, "Skill")
	GUICtrlSetData($binding_key, "key")
	_make_bind($s,$k)
EndFunc   ;==>bind

Func _make_bind($s,$k)
	$bindings.Item($s) = $k
	If $binding_count <> 0 Then
		$bindstr &= @CRLF
	EndIf
	$bindstr &= $s & "->" & StringSplit($k," ",$STR_NOCOUNT)[0]
	GUICtrlSetData($bindings_label, $bindstr)
	$binding_count += 1
	GUIDelete($guu)
	redo_gui()
EndFunc

Func sort()
	Local $storet, $storemsg
	$i = -1
	$end = $skill_lines - 1
	While $i < $end
		$i += 1
		If $time_and_skill[$i][0] > $time_and_skill[$i + 1][0] Then
			$storet = $time_and_skill[$i][0]
			$storemsg = $time_and_skill[$i][1]
			$time_and_skill[$i][0] = $time_and_skill[$i + 1][0]
			$time_and_skill[$i][1] = $time_and_skill[$i + 1][1]
			$time_and_skill[$i + 1][0] = $storet
			$time_and_skill[$i + 1][1] = $storemsg
			$i = -1
		EndIf
	WEnd
EndFunc   ;==>sort

Func get_time_req($skill_level)
	If $skill_level < 70 Then
		Return ($70)
	ElseIf $skill_level < 80 Then
		Return ($80)
	ElseIf $skill_level < 90 Then
		Return ($90)
	ElseIf $skill_level < 100 Then
		Return ($100)
	Else
		Return ($INF)
	EndIf
EndFunc   ;==>get_time_req

Func convert_enhanced_timestamp($stamp)
	Local $timestampFormatted = StringRegExpReplace($stamp, "\]\[", " ")
	$timestampFormatted = "20" & StringRegExpReplace($timestampFormatted, "\]|\[", "")
	Return ($timestampFormatted)
EndFunc   ;==>convert_enhanced_timestamp

Func CalculateTimeDifferenceInSeconds($timestamp)
	Local $currentDateTime = @YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
	Local $diffInSeconds = _DateDiff("s", $timestamp, $currentDateTime)
	Return $diffInSeconds
EndFunc   ;==>CalculateTimeDifferenceInSeconds

Func error_quit($error_string)
	MsgBox($MB_SYSTEMMODAL, "ERROR", $error_string)
	MyQuit()
EndFunc   ;==>error_quit

Func read_setting()
	Return (StringSplit(FileReadLine($settingfd), "=", $STR_NOCOUNT)[1])
EndFunc   ;==>read_setting

Func VirtualMouseRClick($window,$x,$y)
    _WinAPI_PostMessage($window, $WM_RBUTTONDOWN, 1, _WinAPI_MakeLong($x, $y))
    _WinAPI_PostMessage($window, $WM_RBUTTONUP, 0, _WinAPI_MakeLong($x, $y))
EndFunc

Func VirtualMouseDRClick($window,$x,$y)
	_WinAPI_PostMessage($window, $WM_RBUTTONDOWN, 1, _WinAPI_MakeLong($x, $y))
    _WinAPI_PostMessage($window, $WM_RBUTTONUP, 0, _WinAPI_MakeLong($x, $y))
    _WinAPI_PostMessage($window, $WM_RBUTTONDOWN, 1, _WinAPI_MakeLong($x, $y))
    _WinAPI_PostMessage($window, $WM_RBUTTONUP, 0, _WinAPI_MakeLong($x, $y))
EndFunc

Func VirtualMouseClick($window,$x,$y)
    _WinAPI_PostMessage($window, $WM_LBUTTONDOWN, 1, _WinAPI_MakeLong($x, $y))
    _WinAPI_PostMessage($window, $WM_LBUTTONUP, 0, _WinAPI_MakeLong($x, $y))
EndFunc

Func VirtualMouseDClick($window,$x,$y)
	_WinAPI_PostMessage($window, $WM_LBUTTONDOWN, 1, _WinAPI_MakeLong($x, $y))
    _WinAPI_PostMessage($window, $WM_LBUTTONUP, 0, _WinAPI_MakeLong($x, $y))
    _WinAPI_PostMessage($window, $WM_LBUTTONDOWN, 1, _WinAPI_MakeLong($x, $y))
    _WinAPI_PostMessage($window, $WM_LBUTTONUP, 0, _WinAPI_MakeLong($x, $y))
EndFunc

Func MyQuit()
	if $use_alarm Then
		_SoundClose($alarm_sound)
	EndIf
	$settingsfd = FileOpen("settings.txt", $FO_OVERWRITE)
	$temp = WinGetPos($guu)
	$y = $temp[1]
	$x = $temp[0]
	If ($x == -32000) Then
		$x = $defaultx
		$y = $defaulty
	EndIf
	FileWriteLine($settingsfd, "WINDOWX=" & $x)
	FileWriteLine($settingsfd, "WINDOWY=" & $y)
	FileWriteLine($settingsfd, "SEARCHCHARS=" & $chars_back_inloop)
	FileWriteLine($settingsfd, "USECLASSIC=" & $classic)
	FileWriteLine($settingsfd, "USEBINDS=" & $use_binds)
	FileWriteLine($settingsfd, "BINDDELAY=" & $bind_delay)
	FileWriteLine($settingsfd, "USEFOR<70=" & $under70)
	FileWriteLine($settingsfd, "USEALARM=" & $use_alarm)
	FileWriteLine($settingsfd, "ALARMDELAY=" & $beep_delay)
	FileWriteLine($settingsfd, "ENHANCEDPATH=" & $epath)
	FileWriteLine($settingsfd, "CLASSICPATH=" & $cpath)
	FileWriteLine($settingsfd, "ALARMPATH=" & $alarm_path)
	FileClose($settingsfd)
	Exit
EndFunc   ;==>MyQuit
