/*
  Portable Panda
  Portable Panda is a script that makes a simple menu for portable apps.
  The way it works is by searching a specific folder that contains a speficic folder structure, ie:
  Apps
  | --- Internet
  |     | --- FirefoxPortable
  |           | --- FirefoxPortable.exe
  | --- Utilities
  |     | --- CPU-ZPortable
  |           | --- CPU-ZPortable.exe
  |     | --- GPU-ZPortable
  |           | --- GPU-ZPortable.exe
 
  The name of the folder that contais the app, for example, "FirefoxPortable" has to have the same name has it's exe, or Else it won't work.
  Because of this, it CANNOT have duplicates, has theres no way right now to detect it.
  I did fix it but is disabled for now: every program as a number , for example, " 11 | FirefoxPortable", this is a dirty way to check which program is selected when the menu is open
  It's not pretty, and I'll Try to find another way of doing things in the future,but for now this is just a proof-of-concept, and it's disable for the sake of a cleaner interface.
  There's some weird behaviour on Windows 11, showing a entry 'D'. I don't know what's the cause but tried to fix it and it seems fix right now, but YMMV
  
  Menu functions:
    Shift + Left Click	-> Opens entry as admin
    Ctrl + Left Click 	-> Opens entry's folder on File Explorer
  
  Hotkeys avaiable: (This can be disable on settings.ini)
    Windows Key + j 		-> Opens current user downloadsd folder
    Windows Key + Esc		-> Closes current windows, like Alt+F4
    Windows Key + Space 	-> Toggles Always on Top on the current open window
    Windows Key + Mouse Middle Button -> Toggles Always on Top on the current open window
    Shift + Enter 			-> Opens a program with the default app on settings.ini
      If Caps Lock is ON, it will open as admin.
    F1                  -> Search for apps
    F3                  -> Open Menu
  
  TODO
    [X] - Make a settings gui
    [] - Make a 'Open recent Documents' menu entry
    [] - Make default folders for the apps if Applications for is empty
    [X] - Make a default settings.ini in case it's missing / with errors
    [] - Make some kind of system to check file integraty, .ahk or .exe, with MD5 or SHA
    
  Changelog
  - v 0.1
    finally decided to put this on github
    docs folder
      settings should now have a doc file associated with it, meaning it will now be much easier understand what each different settings is.
    code restructure
      settings will now use a ListView to be more space efficient. Each section of settings.ini will be a different tab
      changed some of the ini settings names
      new ScriptSettings section on settings.ini. is hidden by default because some of those values can 'brick' the script
      all windows should now be more predictable when they are created
    added new main menu. it is the exact same as the icon tray, but it's show with an hotkey F3 and at mouse pointer.
  
  - v 0.0.7
    added option "Open...". This is open a dialog to open a file with the default app set on settings.ini. Option to click with Ctrl-click on menu to open a window to drag n drop to do the same thing.
    added super simple and barebones search with F1 and with a tray menu entry.
    change the name from the placeholder 'SPM - Simple Portable Menu' to 'Portable Panda'. Why? I think it's cute. logo is from OpenMoji.
    REGRESSION: can no longer sort dirs because I found a major bug, that only certain folder name works. will Try to fix this ASAP.
    FIXED: needs testing. i remove from the path everything that repeats, meaning the path, leaving only the folder name, and that's the only part that we sort ie C:\Apps\test0, C:\Apps\test1, now we sort just ...\test0, ...\test1 . then we do the same thing for the subfolders. 
  
  - v 0.0.6
    code and script folder restructure
	  by default, Apps is now called Applications and is now under Data folder
      settings.ini is now under Data folder
	  new folder called App, that will contain scripts, app, etc... that will be need to run the script
	  new folder called Other, that will contain misc files reports etc...
	  script can now disable hotkeys with the flag ENABLEHOTKEYS on settings.ini
    applications are now sorted alphabeticly by default, and we can change it with a flag A_ApplicationsSortingOptions on settings.ini
    added simple loadbar and icon change when loading
	
  - v 0.0.5
    added ability to hide tools menu from app with flag from ini SHOWAPPTOOLS
    added ability to add icon to menu entries, just add and .ico to the folder with the same name
    added some menu icons
    added shift and ctrl click
      Shitft Click a entry : runs as admin
      Ctrl Click an entry : open it's folder
    added more system properties shortcuts
    added current user downloads folder - meta+j
    added close current window - meta+esc
    added toggle always on top - meta+space
    cleaned some code
 
  - v 0.0.4
    added fix for duplicates but it's disabled fow now
  - v 0.0.1, 0.0.2, 0.0.3
    minor fixes
  - v 0.0.1
    initial release
*/
#Requires AutoHotkey v2.0
Persistent

; settings the default values as globals
setDefaults() {
  Global
  SCRIPTVERSION := "v0.1"
  SCRIPTNAME := "Portable Panda"
  AUTHOR := "Rui 'rtxx' Teixeira @ 2023"
  AUTHORLINK := "https://github.com/rtxx"
  TOPMENUNAME := SCRIPTNAME . " - " . SCRIPTVERSION
  A_IconTip := TOPMENUNAME

  quotationMark := chr(34)
  ; default strings for the msgbox
  MSGBOXDEFAULTITLE := SCRIPTNAME
  MSGBOXGENERICERRORTEXT := "Oh no! Something went wrong!`n`n"

  ; icons locations, useful for icons and to get a cleaner looking code
  SHELL32DLLPATH := "C:\Windows\System32\shell32.dll"
  SYNCCENTERDLLPATH := "C:\Windows\System32\SyncCenter.dll"

  ; setting the settings ini path
  SETTINGSPATH := A_ScriptDir . "\Data\" . "settings.ini"
  DOCSPATH := A_ScriptDir . "\app\docs"
  If not FileExist(SETTINGSPATH) {
    MsgBox MSGBOXGENERICERRORTEXT . "Can't find settings.ini.`n`nCheck If exists.", MSGBOXDEFAULTITLE, 16
    MsgBox "Making a new one. Open the app again please.", MSGBOXDEFAULTITLE
    makeSettingsIni
    ExitApp
  }
  Else {
    Global INIVARS := Map()
    ; loads settings.ini
    initIniFile(INIVARS)
  }
  
  ; if theres arguments, then script will be runned in ''cmd'' mode. it runs and exits after.
  If A_Args.Length > 0 {
    CMDRUN := "TRUE"
    ; add here the functions to be run as ''cmd''
    
    ExitApp
  }
  
  ; declaring the ICONTRAY
  ICONTRAY := A_TrayMenu
  MAINMENU := Menu()
  ; deleting the default entries
  ICONTRAY.delete
  ; sets the icon tray, if icon is not existent, defaults to shell icon nº 1
  If FileExist(INIVARS["A_scriptIcon"])
    TraySetIcon(INIVARS["A_scriptIcon"])
  Else
    TraySetIcon(SHELL32DLLPATH,1)

  ;FOLDERLIST is an 'array' that contais all the programs names and its respectives categories
  FOLDERLIST := Map()

  ; TEST: processList is a map with all the current process that were launched with spm
  ;processList := Map()
}
/*
  the menu has the following sctructure:
  ----------------
  Top Menu Entries
  ----------------
  Portable apps
  ----------------
  Bottom Menu Entries
  ----------------
*/
topMenuEntries() {
  ; Icon Tray
  ICONTRAY.Add(SCRIPTNAME, MenuHandler)
  ICONTRAY.SetIcon(SCRIPTNAME, INIVARS["A_scriptIcon"])
  ICONTRAY.Default := SCRIPTNAME
  If INIVARS["showAppTools"] == "TRUE" {
    ICONTRAY.Add()
    toolsSubMenu
  }
  ICONTRAY.Add()
  
  ;Main Menu
  MAINMENU.Add(SCRIPTNAME, MenuHandler)
  MAINMENU.SetIcon(SCRIPTNAME, INIVARS["A_scriptIcon"])
  MAINMENU.Default := SCRIPTNAME
  If INIVARS["showAppTools"] == "TRUE" {
    MAINMENU.Add()
    toolsSubMenuB
  }
  MAINMENU.Add()  
  Return
}

bottomMenuEntries() {
  ; Icon Tray
  ICONTRAY.Add()
  ICONTRAY.Add("Open...",MenuHandler)
  /* Initial test for recent opened documents 
  if FileExist(INIVARS["APPDATAPATH"] . "\fileHistory.txt") {
    FileContents := FileRead(INIVARS["APPDATAPATH"] . "\fileHistory.txt")
    Loop parse, FileContents, "`n", "`r" { ; Specifying `n prior to `r allows both Windows and Unix files to be parsed.
      ICONTRAY.Add(A_LoopField,MenuHandler) 
    }
  }
  */
  ICONTRAY.Add("Settings", MenuHandler)
  ICONTRAY.Add("Exit", MenuHandler)
  ICONTRAY.SetIcon("Exit", SHELL32DLLPATH,28)
  
  ;Main Menu
  MAINMENU.Add()
  MAINMENU.Add("Open...",MenuHandler)
  MAINMENU.Add("Settings", MenuHandler)
  MAINMENU.Add("Exit", MenuHandler)
  MAINMENU.SetIcon("Exit", SHELL32DLLPATH,28)  

  Return
}

/*
  toolsSubMenu : tools menu
  Arguments
    nothing
  Returns
    nothing
*/
toolsSubMenu() {
  toolsSubMenu := Menu()
  toolsSubMenuName := "Tools"
  toolsSubMenuIconPath := SHELL32DLLPATH
  toolsSubMenuIconNumber := 36
  toolsSubMenu.add("Open 'God Mode'", MenuHandler)
  toolsSystemPropertiesMenu(toolsSubMenu)
  toolsSubMenu.add()
  ;toolsSubMenu.add("Get internal IP", MenuHandler)
  toolsSubMenu.add("Get external IPv4", MenuHandler)
  toolsSubMenu.add("Copy current user home folder", MenuHandler)
  toolsSubMenu.add()
  toolsSubMenu.add("Report: powercfg -energy", MenuHandler)
  toolsSubMenu.add("Report: powercfg -batteryreport", MenuHandler)
  ICONTRAY.add(toolsSubMenuName, toolsSubMenu)
  ;MAINMENU.add(toolsSubMenuName, toolsSubMenu)
  If FileExist(toolsSubMenuIconPath) {
    ICONTRAY.SetIcon(toolsSubMenuName, toolsSubMenuIconPath,toolsSubMenuIconNumber)
    ;MAINMENU.SetIcon(toolsSubMenuName, toolsSubMenuIconPath,toolsSubMenuIconNumber)
  }
}

/*
  toolsSubMenuB : tools menu (MAIN MENU)
  Arguments
    nothing
  Returns
    nothing
*/
toolsSubMenuB() {
  toolsSubMenu := Menu()
  toolsSubMenuName := "Tools"
  toolsSubMenuIconPath := SHELL32DLLPATH
  toolsSubMenuIconNumber := 36
  toolsSubMenu.add("Open 'God Mode'", MenuHandler)
  toolsSystemPropertiesMenu(toolsSubMenu)
  toolsSubMenu.add()
  ;toolsSubMenu.add("Get internal IP", MenuHandler)
  toolsSubMenu.add("Get external IPv4", MenuHandler)
  toolsSubMenu.add("Copy current user home folder", MenuHandler)
  toolsSubMenu.add()
  toolsSubMenu.add("Report: powercfg -energy", MenuHandler)
  toolsSubMenu.add("Report: powercfg -batteryreport", MenuHandler)
  ;ICONTRAY.add(toolsSubMenuName, toolsSubMenu)
  MAINMENU.add(toolsSubMenuName, toolsSubMenu)
  If FileExist(toolsSubMenuIconPath) {
    ICONTRAY.SetIcon(toolsSubMenuName, toolsSubMenuIconPath,toolsSubMenuIconNumber)
    MAINMENU.SetIcon(toolsSubMenuName, toolsSubMenuIconPath,toolsSubMenuIconNumber)
  }
}

/*
  toolsSystemPropertiesMenu : sub menu of tools : system
  Arguments
    sMenu -> "previous" menu, because we are doing a sub-sub-menu
  Returns
    nothing
*/
toolsSystemPropertiesMenu(sMenu){
  subMenu := Menu()
  
  ; submenu name and icon
  subMenuName := "System Tools"
  subMenuIconPath := SHELL32DLLPATH
  subMenuIconNumber := 22
  
  ; submenu entries and icons
  ; If the icon needs an icon number, please don't forget to add it, If it doenst need it set it to 0
  subMenuEntry1 := "About this computer"
  subMenuEntry1IconPath := SHELL32DLLPATH
  subMenuEntry1IconNumber := 16
  subMenuEntry2 := "Computer Management"
  subMenuEntry2IconPath := SHELL32DLLPATH
  subMenuEntry2IconNumber := 3
  subMenuEntry3 := "Windows Reliability Monitor"
  subMenuEntry3IconPath := "C:\Windows\System32\perfmon.exe"
  subMenuEntry3IconNumber := 0
  subMenuEntry4 := "Disk Cleanup"
  subMenuEntry4IconPath := "C:\Windows\System32\cleanmgr.exe"
  subMenuEntry4IconNumber := 0
  subMenuEntry5 := "Defragment and Optimize Drives"
  subMenuEntry5IconPath := "C:\Windows\System32\defrag.exe"
  subMenuEntry5IconNumber := 0
  
  ; adds the submeny entries
  subMenu.add(subMenuEntry1,MenuHandler)
  subMenu.add(subMenuEntry2,MenuHandler)
  subMenu.add(subMenuEntry3,MenuHandler)
  subMenu.add(subMenuEntry4,MenuHandler)
  subMenu.add(subMenuEntry5,MenuHandler)
  
  ; check If icon exists before adding it  
  If FileExist(subMenuEntry1IconPath)
    subMenu.SetIcon(subMenuEntry1, subMenuEntry1IconPath,subMenuEntry1IconNumber)
  If FileExist(subMenuEntry2IconPath)
    subMenu.SetIcon(subMenuEntry2, subMenuEntry2IconPath,subMenuEntry2IconNumber)
  If FileExist(subMenuEntry3IconPath)
    subMenu.SetIcon(subMenuEntry3, subMenuEntry3IconPath,subMenuEntry3IconNumber)
  If FileExist(subMenuEntry4IconPath)
    subMenu.SetIcon(subMenuEntry4, subMenuEntry4IconPath,subMenuEntry4IconNumber)
  If FileExist(subMenuEntry5IconPath)
    subMenu.SetIcon(subMenuEntry5, subMenuEntry5IconPath,subMenuEntry5IconNumber)
  
  ; add submenu and icon
  sMenu.add(subMenuName, subMenu)
  If FileExist(subMenuIconPath)
    sMenu.SetIcon(subMenuName, subMenuIconPath,subMenuIconNumber)
}

/*
  toolsSubMenuMenuHandler : handles the menu entries from tools sub menu
  Arguments
    currentMenuName -> menu entry that the user clicked
  Returns
    nothing
*/
toolsSubMenuMenuHandler(currentMenuName) {
  ; check submenu entries 1st
  toolsSystemPropertiesMenuHandler(currentMenuName)
  If currentMenuName = "Open 'God Mode'" {
    runApp(INIVARS["A_appDataPath"] . "GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}","USER")
  }  
  If currentMenuName = "Get external IPv4" {
    ip := runWaitOne("curl -4 icanhazip.com")
    Result := MsgBox("IP: " . ip . "`nWould you like to copy result to clipboard?",MSGBOXDEFAULTITLE, "YesNo 64")
    If Result = "Yes" {
      A_Clipboard := ip
	  }
  }
  
  ; makes a powercfg Report and saves it to the 'other' app folder
  If currentMenuName = "Report: powercfg -energy" {
    openReportWith := INIVARS["PDFEDITOR"]
    cDate := FormatTime("YYYYMMDD","yyyyMMddHHmm")
    reportPath := "powercfg-energy-report-" . cDate . "-" . A_ComputerName . ".html"
    command := " /c powercfg -energy -output" . A_Space . INIVARS["A_appOtherPath"] . reportPath
	  ;RunWait "*RunAs " A_ComSpec command ;, , "Min"
    RunWaitApp(A_ComSpec command,"ADMIN")
    If FileExist(INIVARS["A_appOtherPath"] . reportPath) {
      Result := MsgBox("Report done. Located at`n" . INIVARS["A_appOtherPath"] . reportPath . "`nWould you like to open it?",MSGBOXDEFAULTITLE, "YesNo 64")
      If Result = "Yes" {
        Run INIVARS["A_ApplicationsPath"] . openReportWith . A_Space . INIVARS["A_appOtherPath"] . reportPath
      }
    }
    Else {
      MsgBox MSGBOXGENERICERRORTEXT . "Report is not found, powercfg did not run successfully." ,MSGBOXDEFAULTITLE,16
    }
  }
  
  ; makes a powercfg Report and saves it to the 'other' app folder
  If currentMenuName = "Report: powercfg -batteryreport" {
    openReportWith := INIVARS["PDFEDITOR"]
    cDate := FormatTime("YYYYMMDD","yyyyMMddHHmm")
    reportPath := "powercfg-battery-report-" . cDate . "-" . A_ComputerName . ".html"
    command := " /c powercfg -batteryreport -output" . A_Space . INIVARS["A_appOtherPath"] . reportPath
	  ;RunWait "*RunAs " A_ComSpec command ;, , "Min"
    RunWaitApp(A_ComSpec command,"ADMIN")
    If FileExist(INIVARS["A_appOtherPath"] . reportPath) {
      Result := MsgBox("Report done. Located at`n" . INIVARS["A_appOtherPath"] . reportPath . "`nWould you like to open it?",MSGBOXDEFAULTITLE, "YesNo 64")
      If Result = "Yes" {
        Run INIVARS["A_ApplicationsPath"] . openReportWith . A_Space . INIVARS["A_appOtherPath"] . reportPath
      }
    }
    Else {
      MsgBox MSGBOXGENERICERRORTEXT . "Report is not found, powercfg did not run successfully.`npowercfg -batteryreport is only for > Windows 7." ,MSGBOXDEFAULTITLE,16
    }
  }
  
  ; copies current user home folder using a 3rd party script that uses INIVARS["A_teraCopyPath"], maybe I will change it to here
  If currentMenuName = "Copy current user home folder" {
    If ! FileExist(INIVARS["A_ApplicationsPath"] . INIVARS["A_teraCopyPath"]) {
      MsgBox MSGBOXGENERICERRORTEXT . "TeraCopy path is not valid, please validate it.`n`nPath: " . INIVARS["A_ApplicationsPath"] . INIVARS["A_teraCopyPath"],MSGBOXDEFAULTITLE,16
	  }
    Else {
      runApp(INIVARS["A_ahkExe"] . A_Space . INIVARS["A_appDataPath"] . "Scripts\copy-current-user-docs\copy-current-user-docs.ahk " INIVARS["A_ApplicationsPath"] . INIVARS["A_teraCopyPath"],"USER")
	  }
  }  
  Return
}

/*
  toolsSystemPropertiesMenuHandler : handles the menu entries from System Properties sub sub menu
  Arguments
    currentMenuName -> menu entry that the user clicked
  Returns
    nothing
*/
toolsSystemPropertiesMenuHandler(currentMenuName) {
  If currentMenuName = "About this computer" {
	  Send "#{PAUSE}"
  }
  If currentMenuName = "Computer Management" {
	  Run "compmgmt.msc"
  }  
  If currentMenuName = "Windows Reliability Monitor" {
	  Run A_ComSpec " /c perfmon /rel", , "Min"
  }  
  If currentMenuName = "Disk Cleanup" {
	  Run "cleanmgr.exe"
  }
  If currentMenuName = "Defragment and Optimize Drives" {
	  Run "dfrgui.exe"
  }  
  Return
}

/*
  the "meat" of the script
  makeAppMenu : Makes the entries for the programs 
  Arguments
    nothing
  Returns
    nothing
  this is the way it works:
  1 - Loops trought the Apps folder.
  2 - When it finds a folder on Apps, makes a menu entry with the same name of the folder.
      Example: If the name of the folder is 'Utilities' it makes a menu entry named 'Utilities'
  3 - It then loops trough that new found folder.
      Example: It will loop trough the 'Utilities' folder
  4 - When it finds a folder on, for example, 'Utilities', it will make a sub menu entry on the 'Utilities' entry
      Example: If the name of the folder that finds is 'CPU-ZPortable', it will make a entry on the 'Utilities' submenu
  5 - It then repeats this folder all the folders it finds in, for example, 'Utilities' folder.
  6 - When it finishs this folder, it will go on the next 'top' folder, for example, 'Internet' and repeats the same process
*/
makeAppMenu() {
  ; make the top menu entries
  topMenuEntries
  ICONTRAY.Rename(SCRIPTNAME, "Loading, please wait...")
  MAINMENU.Rename(SCRIPTNAME, "Loading, please wait...")
  /*
    declares the top menu pos. this is useful because we need this to make sure when we click on the menu, it's an unique id
    Example: we can have a 'FirefoxPortable' in the folder 'Utilities' and another on the 'Internet'
    This is probably overkill now that I think about it. maybe I'll redo this bit.
    Edit: I indeed redid it. right now commented out the lines with the id and will test If it is necessary to have the id attach to the name.
	  the major difference is that WE CANNOT HAVE DUPLICATED NAMES.
	  TODO: ahk adds the paths by creating date or something, and not by name, so it will NOT sort them alphabeticly. I want to change it.
    EDIT: I dit it, but it needs testing.
  */

  ; this sorts alphabeticly the app categories ie the top menus
  appList := ""
  appListC := 1
  Loop Files, INIVARS["A_ApplicationsPath"] . "*.*", "D" {
    ;appList .= A_LoopFileFullPath "`n"
    SplitPath A_LoopFileFullPath, &outFileName
    appList .= outFileName . "`n"
	  appListC := (appListC + 1)
  }
  
  ; shows a progress bar
  loadBar := Gui("-dpiscale")
  loadBar.Opt("AlwaysOnTop -SysMenu ToolWindow -Caption")
  loadBar.Add("Picture", "w42 h-1", INIVARS["A_scriptIcon"])
  loadBar.Add("Text","vloadBarText w305 yp","")
  loadBar.Add("Progress", "w305 h20 vloadProgress ", 0)

  loadBarText := MSGBOXDEFAULTITLE . " loading "
  loadBar["loadBarText"].Text := loadBarText
  
  loadBar["loadProgress"].Opt("Smooth Range1-" . appListC)
  xMargin := 32
  yMargin := 64 
  loadBar.Show("Hide")
  loadBar.GetPos(,, &Width, &Height)
  loadBar.Move(A_ScreenWidth-Width-xMargin, A_ScreenHeight-Height-yMargin)
  loadBar.Show()
  
  ; final sorted app list
  ; BUG: cant use this until I figure it out. it only works depending on the folder name.
  ; FIXED: needs testing. i remove from the path everything that repeats, meaning the path, leaving only the folder name, and that's the only part that we sort ie C:\Apps\test0, C:\Apps\test1, now we sort just ...\test0, ...\test1 . then we do the same thing for the subfolders. 
  
  appList := Sort(appList,INIVARS["A_ApplicationsSortingOptions"])  
  tempAppList := ""
  Loop Parse, appList, "`n"  {
    tempAppList .= INIVARS["A_ApplicationsPath"] . A_LoopField . "`n"
  }  
  appList := tempAppList
  
  ; initiate the top menu entry numbers
  topMenuPos := 0
  ; loops trough the sorted app list
  Loop Parse, appList, "`n" {
    loadBar["loadProgress"].Value += 1  ; Increase the current position by 1.
    TraySetIcon(SYNCCENTERDLLPATH,23)
    ; get's only name of the folder
    SplitPath A_LoopField, &outFileName
    ;loadBar["loadBarText"].Text := loadBarText . ": " . outFileName
    ; because of the way we sort the folders, we get an empty line, so we check here and ignore it
    If outFileName == ""
      Continue
    ; updates the top menu entry number
    topMenuPos := topMenuPos + 1
    ; resets the sub menu entry pos
    subMenuPos := 0
    ; adds the top menu entry
    topMenuName := outFileName
    ICONTRAY.Add(topMenuName, MenuHandler)
    MAINMENU.Add(topMenuName, MenuHandler)
	  ; If a .ico file with the same name as the folder inside it, it makes it's icon
	  topMenuIcon := INIVARS["A_ApplicationsPath"] . topMenuName . "\" . topMenuName . ".ico"
	  If FileExist(topMenuIcon) {
	    ICONTRAY.SetIcon(topMenuName, topMenuIcon)
	    MAINMENU.SetIcon(topMenuName, topMenuIcon)
    }
    ; creates a new sub menu
    subMenu := Menu()   
    /*
      we need to sort the submenu entries too
    */
    subMenuAppList := ""
    Loop Files, A_LoopField . "\*.*", "D" {
      ;subMenuAppList .= A_LoopFileFullPath "`n"     
      SplitPath A_LoopFileFullPath, &outFileName, &outDir
      subMenuAppList .= outDir . "\" . outFileName . "`n"
    }
    ; final sorted sub menu app list
    ; BUG: cant use this until I figure it out. it only works depending on the folder name.
    ; FIXED: needs testing. i remove from the path everything that repeats, meaning the path, leaving only the folder name, and that's the only part that we sort ie C:\Apps\test0, C:\Apps\test1, now we sort just ...\test0, ...\test1 . then we do the same thing for the subfolders. 
    ;subMenuAppList := Sort(subMenuAppList,INIVARS["A_ApplicationsSortingOptions"])
    subMenuAppList := Sort(subMenuAppList,INIVARS["A_ApplicationsSortingOptions"])
    tempSubMenuAppList := ""
    Loop Parse, subMenuAppList, "`n"  {
      SplitPath A_LoopField, &outFileName, &outDir
      tempSubMenuAppList .= INIVARS["A_ApplicationsPath"] . "\" . outFileName . "\" . A_LoopField . "`n"
    }  
    subMenuAppList := tempSubMenuAppList
    
    Loop Parse, subMenuAppList, "`n" {
	    TraySetIcon(SYNCCENTERDLLPATH,24)
      ; get's only name of the folder
      SplitPath A_LoopField, &outFileName
      ; because of the way we sort the folders, we get an empty line, so we check here and ignore it
      ;MsgBox OutNameNoExt
      If outFileName == ""
        Continue 
      loadBar["loadBarText"].Text := loadBarText . ": " . outFileName
      ; updates the submenu pos
      subMenuPos := subMenuPos + 1
      ; sets the name of the app with a unique id, so we can have duplicates
      ;subMenuName := topMenuPos . subMenuPos . " | " . A_LoopFileName
      ; sets the name of the app with the same name of the folder, this way is cleaner but we CANNOT have duplicates
      subMenuName := outFileName
      ; sets the icon to be the same as the exe of the program
      subMenuIcon := INIVARS["A_ApplicationsPath"] . topMenuName . "\" . subMenuName . "\" . subMenuName . ".exe"
      ; adds the program to the menu
      subMenu.Add(subMenuName, MenuHandler)
      ; If the exe exists it sets the icon, useful because the program can be a executable but not a exe, like a .cmd
      If FileExist(subMenuIcon)
        subMenu.SetIcon(subMenuName, subMenuIcon)
      ; updates the folder 'array' with the new entry
      FOLDERLIST[subMenuName] := topMenuName
    }
    ; adds the submenu to the top menu
    ICONTRAY.add(topMenuName, subMenu)
    MAINMENU.add(topMenuName, subMenu)
  }
  ; make the bottom menu entries
  bottomMenuEntries
  ; makes the icon normal again and not the symbol for loading
  TraySetIcon(INIVARS["A_scriptIcon"])
  ; renames the default entry to the default again
  ICONTRAY.Rename("Loading, please wait...",SCRIPTNAME)
  MAINMENU.Rename("Loading, please wait...",SCRIPTNAME)
  ; simple notification to alert the user when the script is ready
  TrayTip MSGBOXDEFAULTITLE, "Ready."
  loadBar["loadBarText"].Text := "Ready."
  loadBar.Destroy()
  Return
}

/*
  MenuHandler : handles the menu entries 
  Arguments
    currentMenuName -> menu entry that the user clicked
    currentMenuPos -> menu entry position that the user clicked
    myMenu -> current menu that the user clicked
  Returns
    nothing
*/
MenuHandler(currentMenuName, currentMenuPos, myMenu) {
  If currentMenuName = "Exit" {
    ExitApp
  }
    
  If currentMenuName = "Reload" {
    Reload
    Sleep 1000 ; If successful, the reload will close this instance during the Sleep, so the line below will never be reached.
    MsgBox "Script failed to reload. Check AHK error msgbox for more info.", MSGBOXDEFAULTITLE, 16
    Return
  }
  
  If currentMenuName = SCRIPTNAME {
    ; shows sarch menu on double-click the tray icon because SCRIPTNAME is the default option
    xMargin := 32
    yMargin := 64
    showGUI := appSearchGUI()
    showGUI.Show("Hide")
    showGUI.GetPos(,, &Width, &Height)
    showGUI.Move(A_ScreenWidth-Width-xMargin, A_ScreenHeight-Height-yMargin)
    showGUI.Show()
    Return
  }

  If currentMenuName = "Search" {
    xMargin := 32
    yMargin := 64
    showGUI := appSearchGUI()
    showGUI.Show("Hide")
    showGUI.GetPos(,, &Width, &Height)
    showGUI.Move(A_ScreenWidth-Width-xMargin, A_ScreenHeight-Height-yMargin)
    showGUI.Show()
    Return
  }
  
  If currentMenuName = "Open..." {
    If GetKeyState("Ctrl") {          
      xMargin := 32
      yMargin := 64
      showGUI := appRunDragDropGUI()
      showGUI.Show("Hide")
      showGUI.GetPos(,, &Width, &Height)
      showGUI.Move(A_ScreenWidth-Width-xMargin, A_ScreenHeight-Height-yMargin)
      showGUI.Show()     
      Return
    }
    Else {
      ; gets file path from the current selected file on explorer
      filePath := FileSelect(3, A_ScriptDir, MSGBOXDEFAULTITLE . " : Select file to open with default application set on settings.ini")
      ;SplitPath Path , &OutFileName, &OutDir, &OutExtension, &OutNameNoExt, &OutDrive
      ; gets the extension from the filepath
      SplitPath filePath,,, &outExtension
      
      ; compares the current file extension to the lists from the ini
      ; If it finds it, sets the var openAppWith with the program to open it, wich is set on the settings.ini
      If compareExtension(outExtension,INIVARS["TEXTEDITOREXT"]) {
        openAppWith := INIVARS["TEXTEDITOR"]
      } Else If compareExtension(outExtension,INIVARS["DOCUMENTEDITOREXT"]) {   
         openAppWith := INIVARS["DOCUMENTEDITOR"] 
      } Else If compareExtension(outExtension,INIVARS["PDFEDITOREXT"]) {
         openAppWith := INIVARS["PDFEDITOR"]
      } Else If compareExtension(outExtension,INIVARS["MEDIAPLAYEREXT"]) {
         openAppWith := INIVARS["MEDIAPLAYER"]
      } Else If compareExtension(outExtension,INIVARS["COMPRESSIONAPPEXT"]) { 
         openAppWith := INIVARS["COMPRESSIONAPP"]
      } Else If (outExtension == "") {
          Return
      }
      ; If cant find a match, gives an error
      Else {
        MsgBox MSGBOXGENERICERRORTEXT . "Can't open the file:`n" . filePath . "`n`nNo program is set for this extension: '" . outExtension . "'.`nAdd it on settings.ini.", MSGBOXDEFAULTITLE, 64
        Return
      }
    
      ; check If the program exists before trying to open it, because it may be an user error putting the path on the settings.ini
      ; If it exists, then it runs it
      If not FileExist(INIVARS["A_ApplicationsPath"] . openAppWith) {
        MsgBox "Can't find the program to open this file.`n`nPath to the program:`n" . INIVARS["A_ApplicationsPath"] . openAppWith . "`n`n Check on settings.ini If the path to the program is correct.", MSGBOXDEFAULTITLE, 16   
      }
      Else {
        ; If CapsLock in ON then runs it as admin
        If GetKeyState("CapsLock","T") {
          runApp(INIVARS["A_ApplicationsPath"] . openAppWith . A_Space . quotationMark . filePath . quotationMark,"ADMIN")     
        }
        Else {
          runApp(INIVARS["A_ApplicationsPath"] . openAppWith . A_Space . quotationMark . filePath . quotationMark,"USER")     
        }
      }
      Return
    }
  }  
  
  If currentMenuName = "Settings" {
    xMargin := 32
    yMargin := 64
    showGUI := settingsGUI()
    showGUI.Show("Hide")
    showGUI.GetPos(,, &Width, &Height)
    showGUI.Move(A_ScreenWidth-Width-xMargin, A_ScreenHeight-Height-yMargin)
    showGUI.Show()
    Return
  }  
  
  ; checks tools submenu 
  toolsSubMenuMenuHandler(currentMenuName)
  
  ; when the user clicks on a menu entry, it loops trough the FOLDERLIST array and matches to the current menu entry
  For appID, menuAppName in FOLDERLIST {
    If currentMenuName = appID  {
      ; removes the id so it's easier to work, ie, " 11 | FirefoxPortable" -> "FirefoxPortable"
      ;appName := StrSplit(appID, "|")
      ;appName := Ltrim(appName[2])
      ; this way it's cleaner but AGAIN, we CANNOT have duplicates
      appName := appID
      ; sets the run path
      runAppPath := INIVARS["A_ApplicationsPath"] . menuAppName . "\" . appName . "\" . appName
      ; check If the program path exists
      ; If the program executable is diferent from it's folder name, it errors out, so this way we can Catch it
	    ; If the program is an ahk script, then runs it
	    If FileExist(runAppPath . ".ahk") {
	      If GetKeyState("Ctrl") {
          runApp(INIVARS["A_ApplicationsPath"] . menuAppName . "\" . appName . "\","USER")
		      Return
		    }
	      If GetKeyState("Shift") {
          runApp(INIVARS["A_ahkExe"] . A_Space . quotationMark . runAppPath . ".ahk" . quotationMark,"ADMIN")
		      Return
		    }
		    Else {
		      runApp(INIVARS["A_ahkExe"] . A_Space . quotationMark . runAppPath . ".ahk" . quotationMark,"USER")
		      Return
		    }
	    }
        If FileExist(runAppPath . ".*") {
	      ; If ctrl click, opens app folder
	      ; If shift click opens app as admin
		  ; tries and catches to have a more robust error handling
	      If GetKeyState("Ctrl") {
		      runApp(INIVARS["A_ApplicationsPath"] . menuAppName . "\" . appName . "\","USER")
          Return
		    }
	      If GetKeyState("Shift") {
          runApp(runAppPath,"ADMIN")
          Return
	      }
	      Else {
		      runApp(runAppPath,"USER")
		      Return
		    }
      }
	    Else {
	      ; this is BAD, but I don't know how to do better at this time
	      SetTimer changeMsgBoxButtonNamesToOKOpenFolder, 50
        resultMsgBox := MsgBox("Can't find the selected program:`n" . runAppPath . "`n`nCheck If the name of the executable is the same as it's folder.", MSGBOXDEFAULTITLE, 17)
		    If resultMsgBox == "Cancel" {
	        runApp(INIVARS["A_ApplicationsPath"] . menuAppName . "\" . appName . "\","USER")
		      Return
		    }
      }
    }
  }
  Return
}

/* 
  runApp : runs app with or without elevated privileges
  Arguments 
    appPath -> path to the app 
	  runType -> USER or ADMIN 
  Returns
    nothing
*/
runApp(appPath,runType) {
  If runType == "ADMIN" {
    Try {
      FileAppend appPath . "`n", INIVARS["A_appDataPath"] . "\fileHistory.txt" ; Initial test for recent opened documents
      Run "*RunAs " appPath,,,&outputPID
    }
    Catch as error {
      MsgBox(MSGBOXGENERICERRORTEXT . error.Message, MSGBOXDEFAULTITLE,16)
    }  
  }
  Else If runType == "USER" {
    Try {
      FileAppend appPath . "`n", INIVARS["A_appDataPath"] . "\fileHistory.txt" ; Initial test for recent opened documents
      Run appPath,,,&outputPID
	    
    }
    Catch as error {
      MsgBox(MSGBOXGENERICERRORTEXT . error.Message, MSGBOXDEFAULTITLE,16)
    }
  }
  Else {
    MsgBox("'runApp' function 'runType' must be 'ADMIN' or 'USER'.`n`n", MSGBOXDEFAULTITLE,16)
  }
  Return
}

/* 
  runWaitApp : runs app and wait until process is finished with or without elevated privileges
  Arguments 
    appPath -> path to the app 
	runType -> USER or ADMIN 
  Returns
    nothing
*/
runWaitApp(appPath,runType) {
  If runType == "ADMIN" {
    Try {
      FileAppend appPath . "`n", INIVARS["A_appDataPath"] . "\fileHistory.txt" ; Initial test for recent opened documents
      RunWait "*RunAs " appPath
    }
    Catch as error {
      MsgBox(MSGBOXGENERICERRORTEXT . error.Message, MSGBOXDEFAULTITLE,16)
    }  
  }
  Else If runType == "USER" {
    Try {
      FileAppend appPath . "`n", INIVARS["A_appDataPath"] . "\fileHistory.txt" ; Initial test for recent opened documents
      RunWait appPath
    }
    Catch as error {
      MsgBox(MSGBOXGENERICERRORTEXT . error.Message, MSGBOXDEFAULTITLE,16)
    }
  }
  Else {
    MsgBox("'runWaitApp' function 'runType' must be 'ADMIN' or 'USER'.`n`n", MSGBOXDEFAULTITLE,16)
  }
  Return
}

/*
  getFilePath : gets the file path of the current selected file in explorer with clipboard
  Arguments
    nothing
  Returns
    filePath -> File path of the current selected file
*/
getFilePath() {
  backupClipboard := A_Clipboard
  A_Clipboard := ""
  Send "^c"
  If !ClipWait(2) {
    MsgBox(MSGBOXGENERICERRORTEXT . "The attempt to get the filepath to open the selected app failed.", MSGBOXDEFAULTITLE,16)
    Return
  }
  filePath := A_Clipboard
  A_Clipboard := backupClipboard
  Return filePath
}

/*
  compareExtension : compares file extensions. returns true If selectedFileExtension is on iniExtensions list
  Arguments
    selectedFileExtension -> current selected file extension
    iniExtensions -> list of extensions
  Returns
    true -> returns true If selectedFileExtension is on iniExtensions list
*/
compareExtension(selectedFileExtension,iniExtensions) {
  Loop parse, iniExtensions, "|" {
    If (A_LoopField == selectedFileExtension)
      Return true
  }
}

; from https://www.autohotkey.com/docs/v2/scripts/index.htm#MsgBoxButtonNames
/*
  changeMsgBoxButtonNames : changes the default name of the msgbox to something custom
    WARNING: this is BAD, but I don't know how to do better at this time
  Arguments
    none
  Returns
    none
*/
changeMsgBoxButtonNamesToOKOpenFolder() {
  msgboxTitle := MSGBOXDEFAULTITLE
  button1 := "OK"
  button2 := "Open Folder"
  
  If !WinExist(msgboxTitle)
    Return  ; Keep waiting.
  SetTimer , 0
  WinActivate
  ControlSetText "&" . button1, "Button1"
  ControlSetText "&" . button2, "Button2"
}

; from https://www.autohotkey.com/docs/v2/lib/Run.htm
runWaitOne(command) {
    shell := ComObject("WScript.Shell")
    ; Execute a single command via cmd.exe
    exec := shell.Exec(A_ComSpec " /C " command)
    ; Read and Return the command's output
    Return exec.StdOut.ReadAll()
}

/*
  randomString -> makes a random string from a character pool
  Arguments
    stringLength -> number of loops ie lenght of desired string
  Returns
    resultString -> string with the desired number of characters
*/
randomString(stringLength) {
  charPool := "0123456789ABCDEF"
  resultString := ""
  Loop stringLength {
    ; picks a number between 1 and the lenght of the pool
    randomNumber := Random(1, StrLen(charPool))
    ; retrives a string with lenght 1 starting at a random position of the pool
    chosenChar := SubStr(charPool, randomNumber, 1)
    ; concates the char to the resulting string
    resultString .= chosenChar
  }
  Return resultString
}

/*
  settingsUI-> makes a simple settings window
  arguments
    none
  Returns
    aboutMenu -> gui object
*/
settingsGUI() {
  settingsMenu := Gui("-dpiscale")
  settingsMenu.Title := MSGBOXDEFAULTITLE . " : Settings"
  settingsMenu.Opt("AlwaysOnTop ToolWindow")
  settingsMenu.OnEvent("Close", closeWindow)
  settingsMenu.OnEvent("Escape", closeWindow)
  ;updates the INIVARS map because if the user changes the ini file directly, we can get the new values more reliable
  INIVARS.Clear
  initIniFile(INIVARS)
  
  ; each section on the settings.ini is it's own tab, except the About tab and ScriptSettings by default
  sections := IniRead(SETTINGSPATH)
  sectionsNames := Array()
  Loop Parse, sections, "`n" {
    ; sections to ignore
    If A_LoopField = "ScriptSettings" AND INIVARS["A_HideScriptSettings"] = "TRUE"
      Continue
    Else
      sectionsNames.Push A_LoopField
  }
  If INIVARS["A_ShowAbout"] = "TRUE"
    sectionsNames.Push "About..."
  tabControl := settingsMenu.AddTab3("", sectionsNames)
  
  /* about tab */
  If INIVARS["A_ShowAbout"] = "TRUE" {
    tabControl.UseTab("About...") 
    If FileExist(INIVARS["A_scriptIcon"])
      settingsMenu.Add("Picture", "h-1", INIVARS["A_scriptIcon"])
    settingsMenu.SetFont("bold")
    settingsMenu.Add("Text", "x+m", TOPMENUNAME)
    settingsMenu.SetFont()
    settingsMenu.Add("Text", "", "Portable menu with simplicity in mind.")
    settingsMenu.Add("Text", "", AUTHOR)
    settingsMenu.Add("Text", "", AUTHORLINK)
  }
  /* ini settings tabs
    loops the sections from settings.ini and adds only the entries that belong to them
  */
  for k, sectionName in sectionsNames {
    ; sections to ignore
    If sectionName != "About..." {
      tabControl.UseTab(sectionName)
      settingsList := settingsMenu.Add("ListView", "w400 +ReadOnly -Multi R12", ["Key","Value"])
      settingsList.OnEvent("DoubleClick", LV_doubleClick)
      ; loops INIVARS map and check if the key is the same as the current section
      For key, value in INIVARS {
        If getIniVarSection(INIVARS,key) = sectionName
          settingsList.Add(, key, value)
      }
      settingsList.ModifyCol
    }
  }
  
  /* buttons after tabs */  
  tabControl.UseTab()
  ;openIniButton := settingsMenu.Add("Button", "" ,"New entry")
  ;openIniButton.OnEvent("Click", newEntry)
  
  openIniButton := settingsMenu.Add("Button", "" ,"settings.ini")
  openIniButton.OnEvent("Click", openIni)

  openScriptFolderButton := settingsMenu.Add("Button", "x+m" ,"Script folder")
  openScriptFolderButton.OnEvent("Click", openScriptFolder)  
  
  reloadButton := settingsMenu.Add("Button", "x+m" ,"Reload script")
  reloadButton.OnEvent("Click", reloadScript)  

  reloadScript(*) {
    Reload
    Sleep 1000 ; If successful, the reload will close this instance during the Sleep, so the line below will never be reached.  
    MsgBox MSGBOXGENERICERRORTEXT . SCRIPTNAME . " failed to reload.", MSGBOXDEFAULTITLE, 16
    Return
  }
 
  openScriptFolder(*) {
    Run A_ScriptDir
    Return
  }
  
  openIni(*) {
    ; destroying the window and reloading INIVARS ensures more reliability, so we know for sure that the new values are loaded
    settingsMenu.Destroy()
    RunWait SETTINGSPATH
    INIVARS.Clear
    initIniFile(INIVARS)
    Return
  }
  
  newEntry(*) {
    Msgbox "To be implemented."
    Return
  }
  
  /* idea: have a docs folder that have a text file with the same name as the key, so we can have a simple documentation folder and show the user when it's changing it's value.
  */
  LV_doubleClick(settingsList, rowNumber) {
    key := settingsList.GetText(rowNumber) 
    value := settingsList.GetText(rowNumber,2)
    changeSettingGUI(rowNumber,key,value,settingsList)
    Return
  } 
  
  closeWindow(*) {
    INIVARS.Clear
    initIniFile(INIVARS)
    settingsMenu.Destroy()
    Return 
  }
 
  Return settingsMenu
}

/*
  changeSettingGUI-> simple settings changer window that shows info about them if docs file exists with the same name as the setting.
  arguments
    rowNumber ->
    key ->
    value ->
    ListControl ->
  Returns
    none
*/
changeSettingGUI(rowNumber,key,value,ListControl) {
  If Not FileExist(DOCSPATH . "\" . key . ".txt"){
    iBox := InputBox(key, MSGBOXDEFAULTITLE . " : Changing '" . key . "'", "w400 h100",value)
    If iBox.Result = "OK" {
      ListControl.Modify(rowNumber, "", key, iBox.value)
      iniVarWrite(INIVARS, "", key, iBox.value)
      ListControl.ModifyCol
      MsgBox "Saved!", MSGBOXDEFAULTITLE, 64
      Return
    }
    Else
      Return
  } 
  /*
    Initial code for reading the docs files. I need to improve this.
    The idea is:
      -> get the line number of each section
      -> load each section into a var until it reachs the next section
  */
  changeSettingGUI := Gui("-dpiscale")

  docText := FileRead(DOCSPATH . "\" . key . ".txt")
  docTextMap := Map()
  
  namePos := 0
  typePos := 0
  optionsPos := 0
  descPos := 0
  
  Loop Parse, docText, "`n" {
    docTextMap[A_Index] := A_LoopField
    If InStr(A_LoopField, "[name]") {
      namePos := A_Index 
    } Else If InStr(A_LoopField, "[type]") {
      typePos := A_Index 
    } Else If InStr(A_LoopField, "[options]") {
      optionsPos := A_Index 
    } Else If InStr(A_LoopField, "[desc]") {
      descPos := A_Index 
    } 
  }

  docTextLines := StrSplit(docText, '`n') 
  Loop {
    namePos := namePos + 1
    nameText .= docTextLines[namePos] 
  } Until namePos = (typePos - 1)

  Loop {
    typePos := typePos + 1
    typeText .= docTextLines[typePos]   
  } Until typePos = (optionsPos - 1)  
  
   Loop {
    optionsPos := optionsPos + 1
    optionsText .= docTextLines[optionsPos]    
  } Until optionsPos = (descPos - 1)  

   Loop {
    descPos := descPos + 1
    descText .= docTextLines[descPos]    
  } Until descPos = docTextLines.Length  
  
  namePos := ""
  typePos := ""
  optionsPos := ""
  descPos := ""
  docText := ""
  docTextMap := ""
  docTextLines := ""
  
  changeSettingGUI.Title := MSGBOXDEFAULTITLE . " : Changing '" . key . "'"
  changeSettingGUI.Opt("AlwaysOnTop ToolWindow ")
  changeSettingGUI.OnEvent("Escape", closeWindow)
  
  ; name section
  changeSettingGUI.SetFont("bold")
  changeSettingGUI.Add("Text","w305 y+2 R1","Name")
  changeSettingGUI.SetFont()
  changeSettingGUI.Add("Text","w305 y+2",nameText)
  
  ; type section
  changeSettingGUI.SetFont("bold")
  changeSettingGUI.Add("Text","w305 y+2 R1","Type")
  changeSettingGUI.SetFont()
  changeSettingGUI.Add("Text","w305 y+2",typeText)
  
  ; options section
  changeSettingGUI.SetFont("bold")
  changeSettingGUI.Add("Text","w305 y+2 R1","Options")
  changeSettingGUI.SetFont()
  changeSettingGUI.Add("Text","w305 y+2",optionsText)
  
  ; description section
  changeSettingGUI.SetFont("bold")
  changeSettingGUI.Add("Text","w305 y+2 R1","Description")
  changeSettingGUI.SetFont()
  changeSettingGUI.Add("Text","w305 y+2",descText)

  valueEdit := changeSettingGUI.Add("Edit","w305",value)
  saveButton := changeSettingGUI.Add("Button", "Default x+m" ,"Save")      
  saveButton.OnEvent("Click", closeAndSave) 
  changeSettingGUI.Show("Hide")
  changeSettingGUI.GetPos(,, &Width, &Height)

  changeSettingGUI.Move((A_ScreenWidth/2)-(Width/2), (A_ScreenHeight/2)-(Height/2))
  changeSettingGUI.Show()
  
  closeAndSave(*) {
    ; we do try here because we need to check if the settings menu is still open
    Try
      ListControl.Modify(rowNumber, "", key, valueEdit.value)     
    iniVarWrite(INIVARS, "", key, valueEdit.value)
    changeSettingGUI.Destroy()
    MsgBox "Saved!", MSGBOXDEFAULTITLE, 64
    Return
  }
  closeWindow(*) {
    changeSettingGUI.Destroy()
    Return 
  }
  Return
}

/*
  appRunDragDropGUI -> makes a simple window that allows drag and drop. the file will open with the default app set on settings.ini
    if the capslock is ON, the app is launched as administrador    
  arguments
    none
  Returns
    appDnD -> gui object
*/

appRunDragDropGUI() {
  appDnD := Gui("-dpiscale")
  appDnD.Title := "Drag'n'Drop"
  appDnD.Opt("AlwaysOnTop ToolWindow")
  appDnD.OnEvent("Escape", closeWindow)
  appDnD.OnEvent("DropFiles", dropFile)
  appDnD.Add("Picture", "w200 h-1", INIVARS["A_scriptIcon"])

  ;https://www.autohotkey.com/docs/v2/lib/GuiOnEvent.htm#DropFiles 
  dropFile(GuiObj, GuiCtrlObj, dropppedFileArray, X, Y) {
    appDnD.Destroy()
    for i, droppedFile in dropppedFileArray {
      ; gets file path from the current selected file on explorer
      filePath := droppedFile
      ;SplitPath Path , &OutFileName, &OutDir, &OutExtension, &OutNameNoExt, &OutDrive
      ; gets the extension from the filepath
      SplitPath filePath,,, &outExtension
      
      ; compares the current file extension to the lists from the ini
      ; If it finds it, sets the var openAppWith with the program to open it, wich is set on the settings.ini
      If compareExtension(outExtension,INIVARS["TEXTEDITOREXT"]) {
        openAppWith := INIVARS["TEXTEDITOR"]
      } Else If compareExtension(outExtension,INIVARS["DOCUMENTEDITOREXT"]) {   
         openAppWith := INIVARS["DOCUMENTEDITOR"] 
      } Else If compareExtension(outExtension,INIVARS["PDFEDITOREXT"]) {
         openAppWith := INIVARS["PDFEDITOR"]
      } Else If compareExtension(outExtension,INIVARS["MEDIAPLAYEREXT"]) {
         openAppWith := INIVARS["MEDIAPLAYER"]
      } Else If compareExtension(outExtension,INIVARS["COMPRESSIONAPPEXT"]) { 
         openAppWith := INIVARS["COMPRESSIONAPP"]
      } Else If (outExtension == "") {
          Return
      }
      ; If cant find a match, gives an error
      Else {
        MsgBox MSGBOXGENERICERRORTEXT . "Can't open the file:`n" . filePath . "`n`nNo program is set for this extension: '" . outExtension . "'.`nAdd it on settings.ini.", MSGBOXDEFAULTITLE, 64
        Return
      }
    
      ; check If the program exists before trying to open it, because it may be an user error putting the path on the settings.ini
      ; If it exists, then it runs it
      If not FileExist(INIVARS["A_ApplicationsPath"] . openAppWith) {
        MsgBox "Can't find the program to open this file.`n`nPath to the program:`n" . INIVARS["A_ApplicationsPath"] . openAppWith . "`n`n Check on settings.ini If the path to the program is correct.", MSGBOXDEFAULTITLE, 16   
      }
      Else {
        ; If CapsLock in ON then runs it as admin
        If GetKeyState("CapsLock","T") {
          runApp(INIVARS["A_ApplicationsPath"] . openAppWith . A_Space . quotationMark . filePath . quotationMark,"ADMIN")     
        }
        Else {
          runApp(INIVARS["A_ApplicationsPath"] . openAppWith . A_Space . quotationMark . filePath . quotationMark,"USER")     
        }
      }
    }
    Return
    }

  closeWindow(*) {
    appDnD.Destroy()
    Return
  } 
  Return appDnD
}

/*
  appSearchGUI -> makes window with a edit box and a list view that allows for a simple search of apps.
    the list view is updated everytime the user types on the edit box, eliminating the need for a search button   
    if the capslock is ON, the app is launched as administrador    
  arguments
    none
  Returns
    aboutMenu -> gui object
*/
appSearchGUI() {
  searchMenu := Gui("-dpiscale")
  searchMenu.Title := MSGBOXDEFAULTITLE . " : Start typing to search for application"
  searchMenu.Opt("AlwaysOnTop ToolWindow")
  searchMenu.OnEvent("Escape", closeWindow)
  searchEdit := searchMenu.Add("Edit", "vsearchEdit w320 -WantReturn", "")
  searchEdit.OnEvent("Change", processUserInput)
  
  ; this button is the default object, meaning we can press enter on the gui and it will be the default action
  searchBtn := searchMenu.Add("Button","Default vsearchBtn w70 ys", "OK")
  searchBtn.OnEvent("Click", btnClick)
  
  ; LV -> ListView
  LV := searchMenu.Add("ListView", "-hdr w400 xs", ["Name","Path"])
  LV.OnEvent("ItemFocus", LVItemFocus)
  LV.OnEvent("DoubleClick", LVdoubleClick)
  ; current selected app is stored here
  selectedAppFromListView := ""
  
  closeWindow(*) {
    searchMenu.Destroy()
    Return
  }
  
  ; gets the current focused row
  LVItemFocus(LV, RowNumber) {
    selectedAppFromListView := LV.GetText(RowNumber,2)
    Return
  }
  
  LVdoubleClick(LV, RowNumber) {
    selectedAppFromListView := LV.GetText(RowNumber,2)  ; Get the text from the row's second field.
    searchMenu.Destroy()
    If FileExist(selectedAppFromListView . ".ahk") {
      If GetKeyState("CapsLock","T") {
        runApp(INIVARS["A_ahkExe"] . A_Space . quotationMark . selectedAppFromListView . ".ahk" . quotationMark,"ADMIN")     
	    }
	    Else {
	      runApp(INIVARS["A_ahkExe"] . A_Space . quotationMark . selectedAppFromListView . ".ahk" . quotationMark,"USER")      
	    } 
      Return
    }
    If FileExist(selectedAppFromListView . ".exe") {
      If GetKeyState("CapsLock","T") {
        runApp(quotationMark . selectedAppFromListView . quotationMark,"ADMIN")     
	    }
	    Else {
	      runApp(quotationMark . selectedAppFromListView . quotationMark,"USER")   
	    }
    }
    Return
  }
  
  ; when the user press the button or press enter
  btnClick(*){
    ; if the current selected app from the list view is empty then we try to get it
    ; if it is NOT empty, then we know we got the value from LVItemFocus callback and the don't need to get it again
    ; this way, if it's empty, it will lauch the 1st result on the LV, SELECTED OR NOT, otherwise the lauch the current selected row
    If selectedAppFromListView = "" {
      ; we catch it because it will error out if LV is empty
      try {
        ; otherwise, we get the current value from the 1st row and second column
        selectedAppFromListView := LV.GetText(1,2)  ; Get the text from the row's second field.
      }
      ;if there's an error just return empty, so nothing happens
      catch as error
        return
    }
    searchMenu.Destroy()
    If FileExist(selectedAppFromListView . ".ahk") {
      If GetKeyState("CapsLock","T") {
        runApp(INIVARS["A_ahkExe"] . A_Space . quotationMark . selectedAppFromListView . ".ahk" . quotationMark,"ADMIN")     
	    }
	    Else {
	      runApp(INIVARS["A_ahkExe"] . A_Space . quotationMark . selectedAppFromListView . ".ahk" . quotationMark,"USER")      
	    } 
      Return
    }
    If FileExist(selectedAppFromListView . ".exe") {
      If GetKeyState("CapsLock","T") {
        runApp(quotationMark . selectedAppFromListView . quotationMark,"ADMIN")     
	    }
	    Else {
	      runApp(quotationMark . selectedAppFromListView . quotationMark,"USER")   
	    }
    }
    ; resets the current selected app
    selectedAppFromListView := ""
    Return
  }
    
  processUserInput(*) {
    LV.Delete
    ; searchs for the text in the edit box on the FOLDERLIST map array
    For appName, appPath in FOLDERLIST {
      If appName = "" or searchMenu["searchEdit"].Text = ""
        Return
      ; if theres a match with the edit and the name on the array, adds it to the LV
      If inStr(appName, searchMenu["searchEdit"].Text) {
        runAppPath := INIVARS["A_ApplicationsPath"] . appPath . "\" . appName . "\" . appName
        LV.Add(, appName, runAppPath)
      }
    }
    LV.ModifyCol
    ; resets the current selected app
    selectedAppFromListView := ""
    Return
  } 
  Return searchMenu
}

/*
  MAIN FUNCTION
*/
runScript() {
  setDefaults
  makeAppMenu
  Return
}
runScript

/*
  Hotkeys
*/

; check If hotkeys are enabled on settings.ini
If INIVARS["enableHotkeys"]  == "TRUE" {
  ; open current user download folder
  Hotkey "#j", openUserDownloadsFolder
  ; closes current open window
  Hotkey "#Esc", closeCurrentOpenWindow
  ; toggle active window always on top.
  Hotkey "#Space", toggleAlwaysOnTop
  Hotkey "#MButton", toggleAlwaysOnTop
  ; Shift+Enter to open a program with the default app on settings.ini
  Hotkey "+Enter", openWithDefaultApp
  ; F1 to open an app search window
  Hotkey "F1", appSearch
  ; F3 to open main menu
  Hotkey "F3", openMainMenu
}

; callback for open main menu
openMainMenu(ThisHotkey) { 
  MAINMENU.Show()
  Return
}

; callback for open current user download folder
openUserDownloadsFolder(ThisHotkey) { 
  Run "shell:Downloads"
  Return
}

; callback for closes current open window
closeCurrentOpenWindow(ThisHotkey) {
  Send "!{F4}"
  Return
}

; callback for toggle active window always on top.
toggleAlwaysOnTop(ThisHotkey) {
  activeWindow := WinGetTitle("A")
  WinSetAlwaysOnTop -1, activeWindow
  Return
}

/*
  callback for
  Shift+Enter to open a program with the default app on settings.ini
  If CapsLock is on, opens app as admin 
*/
openWithDefaultApp(ThisHotkey) {
  ; gets file path from the current selected file on explorer
  filePath := getFilePath() 
  ;SplitPath Path , &OutFileName, &OutDir, &OutExtension, &OutNameNoExt, &OutDrive
  ; gets the extension from the filepath
  SplitPath filePath,,, &outExtension ;, ,
  
  ; compares the current file extension to the lists from the ini
  ; If it finds it, sets the var openAppWith with the program to open it, wich is set on the settings.ini
  If compareExtension(outExtension,INIVARS["TEXTEDITOREXT"]) {
    openAppWith := INIVARS["TEXTEDITOR"]
  } Else If compareExtension(outExtension,INIVARS["DOCUMENTEDITOREXT"]) {   
     openAppWith := INIVARS["DOCUMENTEDITOR"] 
  } Else If compareExtension(outExtension,INIVARS["PDFEDITOREXT"]) {
     openAppWith := INIVARS["PDFEDITOR"]
  } Else If compareExtension(outExtension,INIVARS["MEDIAPLAYEREXT"]) {
     openAppWith := INIVARS["MEDIAPLAYER"]
  } Else If compareExtension(outExtension,INIVARS["COMPRESSIONAPPEXT"]) { 
     openAppWith := INIVARS["COMPRESSIONAPP"]
  } Else If (outExtension == "") {
      Return
  }
  ; If cant find a match, gives an error
  Else {
    MsgBox MSGBOXGENERICERRORTEXT . "Can't open the file:`n" . filePath . "`n`nNo program is set for this extension: '" . outExtension . "'.`nAdd it on settings.ini.", MSGBOXDEFAULTITLE, 64
    Return
  }
  
  ; check If the program exists before trying to open it, because it may be an user error putting the path on the settings.ini
  ; If it exists, then it runs it
  If not FileExist(INIVARS["A_ApplicationsPath"] . openAppWith) {
    MsgBox "Can't find the program to open this file.`n`nPath to the program:`n" . INIVARS["A_ApplicationsPath"] . openAppWith . "`n`n Check on settings.ini If the path to the program is correct.", MSGBOXDEFAULTITLE, 16   
  }
  Else {
    ; If CapsLock in ON then runs it as admin
    If GetKeyState("CapsLock","T") {
      runApp(INIVARS["A_ApplicationsPath"] . openAppWith . A_Space . quotationMark . filePath . quotationMark,"ADMIN")     
	  }
	  Else {
	    runApp(INIVARS["A_ApplicationsPath"] . openAppWith . A_Space . quotationMark . filePath . quotationMark,"USER")     
	  }
  }
  Return
}

; callback for the search window.
appSearch(ThisHotkey) {
  xMargin := 32
  yMargin := 64
  showGUI := appSearchGUI()
  showGUI.Show("Hide")
  showGUI.GetPos(,, &Width, &Height)
  showGUI.Move(A_ScreenWidth-Width-xMargin, A_ScreenHeight-Height-yMargin)
  showGUI.Show()
  Return
}

/*
  initIniFile : load ini file into a map
  Arguments
    iniMap -> map variable to hold the keys and values
  Returns
    nothing
  loads sections 1 by 1 from the ini file, using loadIniSection()
*/
initIniFile(iniMap) {
  sections := IniRead(SETTINGSPATH)
  Loop Parse, sections, "`n" {
    loadIniSection(iniMap,IniRead(SETTINGSPATH, A_LoopField))
  }
  Return
}

/*
  loadIniSection : load section of a ini file into a map variable
  Arguments
    iniMap -> map variable to hold the keys and values
    iniSection -> ini section to load to the iniMap variable
  Returns
    nothing
  How it works:
    1 - Parses the iniSection from IniRead(iniPath, "SECTION"), that returns a list of the key,values pairs separeted with a return '`n'
    2 - Parses the key,value pairs. they are separeted with an equal sign '='
    3 - Because we know that the 1,3,5,etc.. is ALWAYS the key and the 2,4,6,etc... is ALWAYS the value, we can do this:
        Example:
        ahkPath=C:\Apps\ahk.exe
        makeLog=TRUE
        Loop 1
          LoopField := ahkPath=C:\Apps\ahk.exe
            Loop 1
              if loop index (1) is odd
                iniMap["ahkPath"] := "" and sets the lastKey as 'ahkPath'
              if loop index (1) is even
                not even, continues
            Loop 2
              if loop index (2) is odd
                not odd, continues
              if loop index (2) is even
                iniMap[lastKey] == iniMap["ahkPath"] := "C:\Apps\ahk.exe"
          Reset lastKey var
          LoopField := makeLog=TRUE
            Loop 1
              if loop index (1) is odd
                iniMap["makeLog"] := "" and sets the lastKey as 'makeLog'
              if loop index (1) is even
                not even, continues
            Loop 2
              if loop index (2) is odd
                not odd, continues
              if loop index (2) is even
                iniMap[lastKey] == iniMap["makeLog"] := "TRUE"
    4 - we then can acess our ini settings with a map, like this, INIVARS["ahkPath"], INIVARS["makeLog"]
    Note: we CANNOT have duplicates with this aproach like this
        [SECTION1]
        foo=bar
        [SECTION2]
        foo=bar
    Im fine with it for now because I only use a small number of settings anyway, but I will try to make a better system in the future.
    
    UPDATE: MAJOR BUG DETECTED: if value has an equal = sign, it will not work because it thinks it's a new key.
    So now we split the string as soons as it found an equal sign, and uses the 1st 'part' as the key and the rest as the value. needs testing
    
*/
loadIniSection(iniMap,iniSection) {
  Loop Parse, iniSection, "`n" {
    currentKeyAndValue := StrSplit(A_LoopField , "=", "", 2) 
    Loop currentKeyAndValue.Length {
	    ; if odd is key
      if Mod(A_Index, 2) = 1 {
	      iniMap[currentKeyAndValue[A_Index]] := ""
        ; saves the key to next loop
	      lastKey := currentKeyAndValue[A_Index]
	    }
      ; if even is value    
      if Mod(A_Index, 2) = 0 {
	      iniMap[lastKey] := currentKeyAndValue[A_Index]
        lastKey := ""
      }
    }
  }
  Return
}

/*
  iniVarWrite : writes new value to the desired key to ini file and map variable
  Arguments
    iniPath -> path to the ini file
    iniMap -> map variable to hold the keys and values
    iniSection -> ini section to load to the iniMap variable. if section is empty it will try to loop it up and save to the 1st ocurrence, so we can't have duplicates keys across sections
    iniKey -> key name on the ini file
    newKeyValue -> new key that will be write to the file
  Returns
    nothing
*/
iniVarWrite(iniMap,iniSection,iniKey,newKeyValue) {
  iniPath := SETTINGSPATH
  /* change this IF to getIniVarSection*/
  If iniSection = "" {
    testValue := ""
    sections := IniRead(iniPath)
    Loop Parse, sections, "`n" {
      currentSection := A_LoopField
      testValue := IniRead(iniPath, currentSection, iniKey, "ERROR")
      If testValue != "ERROR" {
        IniWrite newKeyValue, iniPath, currentSection, iniKey
        iniMap[iniKey] := newKeyValue
        Break
      }
    }
  }
  Else {
    IniWrite newKeyValue, iniPath, iniSection, iniKey
    iniMap[iniKey] := newKeyValue  
  }
  Return
}

/*
  getIniVarSection : gets ini key's section name
  Arguments
    iniMap -> map variable to hold the keys and values
    iniKey -> key name on the ini file
  Returns
    currentSection -> ini key's section
*/
getIniVarSection(iniMap,iniKey) {
  testValue := ""
  sections := IniRead(SETTINGSPATH)
  Loop Parse, sections, "`n" {
    currentSection := A_LoopField
    testValue := IniRead(SETTINGSPATH, currentSection, iniKey, "ERROR")
    If testValue != "ERROR"
      Return currentSection
  }
  Else
    Return "ERROR"  
}

/*
  compareStrings : compares strings
  Arguments
    a -> string 1
    b -> string 2
  Returns
    true -> If strings are the same
    false -> If strings are different
*/
compareStrings(a,b) {
  If a = b
    Return "TRUE"
  Else
    Return "FALSE"
}

/*
  makeSettingsIni : makes a new settings.ini
  Arguments
    nothing
  Returns
    nothing
*/
makeSettingsIni() {
  FileAppend "
(
[Settings]
showAppTools =TRUE
enableHotkeys=FALSE

[DefaultApps]
TEXTEDITOR=
TEXTEDITOREXT=txt|csv|ahk|inf|ini|xml|cmd|bat|cfg|js|json|html|htm|css|c|ps
DOCUMENTEDITOR=
DOCUMENTEDITOREXT=doc|docx|rtf|odt
PDFEDITOR=
PDFEDITOREXT=pdf
MEDIAPLAYER=
MEDIAPLAYEREXT=mp3|wav|ogg|wma|mp4|mkv|div|divx|avi
COMPRESSIONAPP=
COMPRESSIONAPPEXT=zip|rar|7z|exe|iso|ZIP

; Please be careful about changing this settings!
; They are hidden by default, change A_HideScriptSettings to "FALSE" to change them on the script.
[ScriptSettings]
A_HideScriptSettings=TRUE
A_ShowAbout=TRUE
A_enableTrayMenu=TRUE
A_scriptIcon=App\Portable Panda.ico
A_dataPath=Data\
A_appDataPath=App\
A_appOtherPath=Other\
A_ApplicationsPath=Data\Applications\
A_ApplicationsSortingOptions=""
A_ahkExe=App\AutoHotkey64.exe
A_teraCopyPath=
)", SETTINGSPATH
  Return
}