A program to track or automate getting gains on the ultima online shard "siege perilous"

Features:
  * Enhanced client:
    * Track gains
    * Automate keypresses !!!only while the window has focus!!!
  
  * Classic Client:
    * Track gains (journal does not have timestamps, so must be running when the gain is gotten to track it accurately)
    * Automate keypresses, including in the background
    * Automate mouse clicks, including in the background

--run the program once for the settings file to be generated--\
Settings:
  * WINDOWX: where the window is placed at startup
  * WINDOWY: where the window is placed at startup
  * SEARCHCHARS: how far back in the log file the script will look, may need to be increased if getting double gains that cause 2 skill losses as well
  * INITALSEARCHCHARS: same as above but only the first time.  useful high if you want to catch a previous session.  Useful low if you need to not
  * USECLASSIC: whether or not the classic client is being used
  * USEBINDS: whether or not the bind system should be used in order to be able to automatically attempt gains for certain skills once they are ready
  * BINDDELAY: how long in miliseconds to wait between sending binds
  * USEFOR<70: if you wish to use this script to get gains before the siege ruleset kicks in - this setting will treat under 70 skills as having a 1 second cooldown between gains
  * USEALARM: whether or not the alarm system sould be used in order to alert the player when a gain is available   - individual skills can have their alarms muted
  * ALARMDELAY: How frequently the same skill will beep if it has still not gained while available
  * ENHANCEDPATH: the path to the EC log file (chat.log)
  * CLASSICPATH: the path to the CC journal file (must be set up manually)
  * ALARMPATH: which alarm to use

Setup:
  * for CC, journal logging must be turned on manually
  * navigate to the classic client directory, most likely: C:\Program Files (x86)\Electronic Arts\Ultima Online Classic
  * open uo.cfg with admin privledges in some text editor
  * ensure SaveJournal is set to "on"
  * add the following line
  * JournalSaveFile=\<wherever the journal should save to\>
  * I do C:\Program Files (x86)\Electronic Arts\Ultima Online Classic\Journal\Journal.txt
  * launch and enter the game and cause some journal entries to be logged.

Hotkeys:
  * Ctrl+Alt+Q: Close the tracker
  * Ctrl+Alt+T: execute the binding associated with the string currently in the skill input field

Bindings:
  * MUST BE RAN IN ADMINISTRATOR MODE
  * type the skill into the left input field, and the desired keypress into the right input field.
  * then click "Create" to add this binding, now if the skill on the left ever has a gain to get, the key on the right will be sent in an attempt to gain it
  * There are a few special phrases that can be entered into the key field:
    * F\<1-12\> for example "F8", will be sent as the function key
    * putting ^ before another key for example "^a", will be interpreted as Alt+key
    * putting ! before another key for example "!^a", will be interpreted as Ctrl+key
    * putting "click" or "Click" and then pressing "Create" will bring up a new menu for inputting a click stream:
      * use your mouse to target where you would want the script to click, then press s for a single click or hold it until the ':' appears for a double click
      * once done setting click locations, press esc
  * The "Save" button will save the current bindings to "bindings.txt"
  * The "Load" button will add all of the bindings in "bindings.txt" to the currently running instance

AFK:
  * When bindings are enabled, click this button to make sure some inputs are sent frequently enough for the client to avoid being AFK kicked from the shard
  * Turns green when active

Alarms:
  * When alarms are enabled, each skill that is being tracked will have a speaker icon next to it, that icon can be clicked to toggle whether or not that individual skill will play sounds when its gain is ready
    
    
    
